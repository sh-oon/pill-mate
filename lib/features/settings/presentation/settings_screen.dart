import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/permissions/permission_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/onboarding_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../data/data_reset_service.dart';
import '../data/notification_settings.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  PermissionReport? _perm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refreshPermissions() async {
    final r = await ref.read(permissionServiceProvider).status();
    if (!mounted) return;
    setState(() => _perm = r);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(notificationSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // -------- 알림 --------
          const _SectionHeader(title: '알림'),
          ListTile(
            leading: const Icon(Icons.snooze_outlined),
            title: const Text('스누즈 간격'),
            subtitle: Text('${settings.snoozeMinutes}분 후 다시 알림'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickSnooze,
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('사전 알림 (분)'),
            subtitle: const Text('약별로 설정 — 약 추가/편집 화면에서 변경'),
            enabled: false,
          ),

          const _SectionHeader(title: '권한'),
          _PermissionTile(
            icon: Icons.notifications_active_outlined,
            label: '알림',
            status: _perm?.notification,
            onRequest: () async {
              if (_perm?.notification.isPermanentlyDenied ?? false) {
                await openAppSettings();
              } else {
                await ref.read(permissionServiceProvider).requestAll();
              }
              await _refreshPermissions();
            },
          ),
          if (Platform.isAndroid) ...[
            _PermissionTile(
              icon: Icons.alarm_outlined,
              label: '정확한 알람',
              status: _perm?.scheduleExactAlarm,
              onRequest: () async {
                await Permission.scheduleExactAlarm.request();
                await _refreshPermissions();
              },
            ),
            _PermissionTile(
              icon: Icons.battery_saver_outlined,
              label: '배터리 최적화 예외',
              status: _perm?.ignoreBatteryOptimizations,
              onRequest: () async {
                await Permission.ignoreBatteryOptimizations.request();
                await _refreshPermissions();
              },
            ),
          ],

          // -------- 데이터 --------
          const _SectionHeader(title: '데이터'),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined,
                color: AppColors.missed),
            title: const Text('데이터 초기화',
                style: TextStyle(color: AppColors.missed)),
            subtitle: const Text('모든 약, 일정, 복용 기록과 예약된 알림 삭제'),
            onTap: _confirmReset,
          ),

          // -------- 앱 정보 --------
          const _SectionHeader(title: '앱 정보'),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: '필메이트',
            applicationVersion: '0.1.0',
            applicationLegalese:
                '오프라인 복약 관리 · 모든 데이터는 디바이스에만 저장됩니다.',
          ),

          if (kDebugMode) ...[
            const _SectionHeader(title: '개발자'),
            ListTile(
              leading: const Icon(Icons.restart_alt),
              title: const Text('온보딩 다시 보기'),
              subtitle: const Text('완료 플래그 초기화 후 스플래시로 이동'),
              onTap: () async {
                await ref
                    .read(onboardingCompletedProvider.notifier)
                    .reset();
                if (!context.mounted) return;
                context.go(AppRoute.splash);
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickSnooze() async {
    final current =
        ref.read(notificationSettingsProvider).snoozeMinutes;
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: RadioGroup<int>(
          groupValue: current,
          onChanged: (v) => Navigator.of(ctx).pop(v),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(22, 18, 22, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '스누즈 간격',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textStrong,
                    ),
                  ),
                ),
              ),
              for (final m in kSnoozeOptions)
                RadioListTile<int>(
                  value: m,
                  title: Text('$m분'),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (picked != null && picked != current) {
      await ref
          .read(notificationSettingsProvider.notifier)
          .setSnoozeMinutes(picked);
    }
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('데이터를 모두 삭제할까요?'),
        content: const Text(
          '약, 일정, 복용 기록과 예약된 알림이 모두 사라져요.\n'
          '이 작업은 되돌릴 수 없어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.missed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await ref.read(dataResetServiceProvider).resetAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('데이터가 초기화됐어요')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('초기화 실패: $e')),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.label,
    required this.status,
    required this.onRequest,
  });

  final IconData icon;
  final String label;
  final PermissionStatus? status;
  final Future<void> Function() onRequest;

  @override
  Widget build(BuildContext context) {
    final s = status;
    final granted = s != null && (s.isGranted || s.isLimited);
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(_subtitle(s)),
      trailing: granted
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : TextButton(
              onPressed: onRequest,
              child: Text(
                s?.isPermanentlyDenied == true ? '설정 열기' : '허용하기',
              ),
            ),
    );
  }

  static String _subtitle(PermissionStatus? s) {
    if (s == null) return '확인 중…';
    if (s.isGranted) return '허용됨';
    if (s.isLimited) return '제한적 허용';
    if (s.isPermanentlyDenied) return '거부됨 — 설정 앱에서 변경 필요';
    return '거부됨';
  }
}
