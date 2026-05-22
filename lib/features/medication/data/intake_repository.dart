import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/intake_logs.dart';
import '../../../core/database/tables/schedules.dart';
import '../../../core/notifications/medication_notification_manager.dart';

/// 특정 시점의 복용 한 건(스케줄+약+로그를 묶은 도메인).
///
/// [logId]가 null이면 아직 IntakeLog row가 없는 상태(=derived pending/missed).
class DoseInstance {
  const DoseInstance({
    required this.medicationId,
    required this.medicationName,
    required this.category,
    required this.quantityLabel,
    required this.scheduleId,
    required this.timeOfDay,
    required this.scheduledAt,
    required this.status,
    this.logId,
  });

  final int medicationId;
  final String medicationName;
  final String? category;
  final String quantityLabel;
  final int scheduleId;
  final String timeOfDay; // "HH:mm"
  final DateTime scheduledAt;
  final IntakeStatus status;
  final int? logId;
}

class IntakeRepository {
  IntakeRepository(this._db, this._notif);

  final AppDatabase _db;
  final MedicationNotificationManager _notif;

  /// 특정 날짜(자정 ~ 익일 자정)의 IntakeLog 들을 watch.
  Stream<List<IntakeLog>> watchDay(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (_db.select(_db.intakeLogs)
          ..where((l) =>
              l.scheduledAt.isBetweenValues(start, end)))
        .watch();
  }

  /// 범위 내 IntakeLog 일괄 조회 (리포트용 1회성).
  Future<List<IntakeLog>> getRange(DateTime startInclusive, DateTime endExclusive) {
    return (_db.select(_db.intakeLogs)
          ..where((l) =>
              l.scheduledAt.isBetweenValues(startInclusive, endExclusive)))
        .get();
  }

  /// 범위 내 IntakeLog 스트림 (캘린더용 — markTaken/markSkipped 후 자동 갱신).
  /// FutureProvider + getRange를 쓰면 홈에서 상태 변경 시 캘린더가 stale 표시.
  Stream<List<IntakeLog>> watchRange(
      DateTime startInclusive, DateTime endExclusive) {
    return (_db.select(_db.intakeLogs)
          ..where((l) =>
              l.scheduledAt.isBetweenValues(startInclusive, endExclusive)))
        .watch();
  }

  /// 특정 (medicationId, scheduleId, scheduledAt) 슬롯에 상태 기록.
  /// 기존 row가 있으면 update, 없으면 insert.
  Future<void> mark({
    required int medicationId,
    required int scheduleId,
    required DateTime scheduledAt,
    required IntakeStatus status,
  }) async {
    final existing = await (_db.select(_db.intakeLogs)
          ..where((l) =>
              l.scheduleId.equals(scheduleId) &
              l.scheduledAt.equals(scheduledAt)))
        .getSingleOrNull();

    final now = DateTime.now();
    if (existing == null) {
      await _db.into(_db.intakeLogs).insert(
            IntakeLogsCompanion.insert(
              medicationId: Value(medicationId),
              scheduleId: Value(scheduleId),
              scheduledAt: scheduledAt,
              status: Value(status),
              actedAt: Value(now),
            ),
          );
    } else {
      await (_db.update(_db.intakeLogs)
            ..where((l) => l.id.equals(existing.id)))
          .write(IntakeLogsCompanion(
        status: Value(status),
        actedAt: Value(now),
        updatedAt: Value(now),
      ));
    }

    // 1) 같은 슬롯의 urgent 재알림 즉시 취소 (사용자 액션 후 추가 발화 막음).
    await _notif.cancelUrgentForSchedule(scheduleId);
    // 2) interval 약: 액션 후 큐 +1 보강 위해 sync 재호출 (daily/weekly는 멱등).
    await _notif.syncSchedulesFor(medicationId);
  }

  Future<void> markTaken({
    required int medicationId,
    required int scheduleId,
    required DateTime scheduledAt,
  }) =>
      mark(
        medicationId: medicationId,
        scheduleId: scheduleId,
        scheduledAt: scheduledAt,
        status: IntakeStatus.taken,
      );

  Future<void> markSkipped({
    required int medicationId,
    required int scheduleId,
    required DateTime scheduledAt,
  }) =>
      mark(
        medicationId: medicationId,
        scheduleId: scheduleId,
        scheduledAt: scheduledAt,
        status: IntakeStatus.skipped,
      );
}

// =============================================================================
// 도메인 계산 헬퍼 (provider에서 재사용)
// =============================================================================

/// 스케줄이 [date] 일에 활성인지 판정.
///
/// - daily: 항상 활성
/// - weekly: daysOfWeekMask 비트 검사 (비트 0=일요일 ... 6=토요일)
/// - interval: startDate부터 N일 간격
bool isScheduleActiveOn(Schedule s, DateTime date) {
  if (date.isBefore(_dateOnly(s.startDate))) return false;
  if (s.endDate != null && date.isAfter(_dateOnly(s.endDate!))) return false;
  switch (s.repeatKind) {
    case RepeatKind.daily:
      return true;
    case RepeatKind.weekly:
      final mask = s.daysOfWeekMask ?? 0;
      // DateTime.weekday: Mon=1..Sun=7. 우리 비트는 일=0..토=6.
      final bitIndex = date.weekday == DateTime.sunday ? 0 : date.weekday;
      return (mask & (1 << bitIndex)) != 0;
    case RepeatKind.interval:
      final n = s.intervalDays ?? 1;
      if (n <= 0) return false;
      final diff = _dateOnly(date)
          .difference(_dateOnly(s.startDate))
          .inDays;
      return diff % n == 0;
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// "HH:mm" + 날짜 → DateTime.
DateTime combineDateAndTime(DateTime date, String hhmm) {
  final p = hhmm.split(':');
  return DateTime(date.year, date.month, date.day,
      int.parse(p[0]), int.parse(p[1]));
}

/// [date]일에 대해 schedule × time이 만들어내는 모든 dose 슬롯을 계산.
/// 로그 list와 매칭해서 상태/logId 채워 반환.
///
/// Phase 2C: tracked에서 카탈로그 메타(name/category/dosage/unit) 제거됨에 따라
/// [catalogByMedId]를 통해 catalog 정보 전달 받음. catalog NULL인 legacy는 폴백
/// 텍스트 사용.
List<DoseInstance> computeDosesForDay({
  required DateTime date,
  required List<TrackedMedication> meds,
  required Map<int, CatalogItem?> catalogByMedId,
  required List<Schedule> schedules,
  required List<IntakeLog> logs,
  DateTime? now,
}) {
  final medById = {for (final m in meds) m.id: m};
  final nowTime = now ?? DateTime.now();
  final isToday = _dateOnly(date) == _dateOnly(nowTime);

  String nameOf(TrackedMedication m) =>
      catalogByMedId[m.id]?.name ?? '(이름 없음)';
  String? categoryOf(TrackedMedication m) => catalogByMedId[m.id]?.category;
  String quantityOf(TrackedMedication m) {
    final c = catalogByMedId[m.id];
    final d = m.customDosage ?? c?.defaultDosage;
    final u = m.customUnit ?? c?.defaultUnit;
    if (d != null && u != null) return '$d$u';
    if (d != null) return d;
    return '1정';
  }

  final out = <DoseInstance>[];
  for (final s in schedules) {
    final m = medById[s.medicationId];
    if (m == null || m.archived) continue;
    if (!isScheduleActiveOn(s, date)) continue;

    final scheduledAt = combineDateAndTime(date, s.timeOfDay);
    final log = logs.firstWhere(
      (l) => l.scheduleId == s.id && l.scheduledAt == scheduledAt,
      orElse: () => _emptyLog,
    );
    final hasLog = identical(log, _emptyLog) == false;

    // 등록 시각 이전 슬롯(예: 14시 등록 + 08:00 시각)은 사용자가 실시간으로
    // 챙길 수 없었던 슬롯이라 자동 "놓침" 처리 X — pending으로 유지해 홈/캘린더
    // 리스트엔 보이되 리포트 놓침 카운트는 부풀리지 않음.
    final beforeStart = scheduledAt.isBefore(s.startDate);
    final IntakeStatus status;
    if (hasLog) {
      status = log.status;
    } else if (isToday &&
        !beforeStart &&
        nowTime.isAfter(scheduledAt.add(const Duration(minutes: 5)))) {
      status = IntakeStatus.missed;
    } else {
      status = IntakeStatus.pending;
    }

    out.add(DoseInstance(
      medicationId: m.id,
      medicationName: nameOf(m),
      category: categoryOf(m),
      quantityLabel: quantityOf(m),
      scheduleId: s.id,
      timeOfDay: s.timeOfDay,
      scheduledAt: scheduledAt,
      status: status,
      logId: hasLog ? log.id : null,
    ));
  }
  out.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  return out;
}

final _emptyLog = IntakeLog(
  id: -1,
  medicationId: -1,
  scheduleId: -1,
  scheduledAt: DateTime.fromMillisecondsSinceEpoch(0),
  status: IntakeStatus.pending,
  urgentFiredCount: 0,
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
);
