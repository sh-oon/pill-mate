import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// 권한 일괄 요청/조회 헬퍼.
class PermissionService {
  const PermissionService();

  Future<PermissionReport> requestAll() async {
    final report = PermissionReport();

    final notif = await Permission.notification.request();
    report.notification = notif;

    if (Platform.isAndroid) {
      report.scheduleExactAlarm =
          await Permission.scheduleExactAlarm.request();
      report.ignoreBatteryOptimizations =
          await Permission.ignoreBatteryOptimizations.request();
    }

    return report;
  }

  Future<PermissionReport> status() async {
    final report = PermissionReport();
    report.notification = await Permission.notification.status;
    if (Platform.isAndroid) {
      report.scheduleExactAlarm = await Permission.scheduleExactAlarm.status;
      report.ignoreBatteryOptimizations =
          await Permission.ignoreBatteryOptimizations.status;
    }
    return report;
  }
}

class PermissionReport {
  PermissionStatus notification = PermissionStatus.denied;
  PermissionStatus scheduleExactAlarm = PermissionStatus.granted;
  PermissionStatus ignoreBatteryOptimizations = PermissionStatus.granted;

  bool get isFullyGranted =>
      notification.isGranted &&
      (scheduleExactAlarm.isGranted ||
          scheduleExactAlarm.isLimited) &&
      ignoreBatteryOptimizations.isGranted;
}

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return const PermissionService();
});
