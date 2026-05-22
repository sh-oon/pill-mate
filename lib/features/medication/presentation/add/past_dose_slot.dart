/// past-dose-edit backfill 후보 슬롯.
///
/// 신규 등록/시각 추가 직후, 오늘의 과거 + 활성 + 로그 미존재 슬롯을 묶어
/// `PastDosesBackfillSheet`에 전달하는 도메인 값 객체.
/// (cross-ref는 plain text — sheet 파일이 본 파일을 import하므로 순환 회피)
class PastDoseSlot {
  const PastDoseSlot({
    required this.medicationId,
    required this.scheduleId,
    required this.timeOfDay,
    required this.scheduledAt,
  });

  final int medicationId;
  final int scheduleId;
  final String timeOfDay; // "HH:mm"
  final DateTime scheduledAt;
}
