import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/permissions/permission_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/onboarding_storage.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.read(permissionServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('알림 권한 요청'),
            subtitle: const Text('알림, 정확한 알람, 배터리 최적화 예외'),
            onTap: () async {
              final report = await permissions.requestAll();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    report.isFullyGranted
                        ? '모든 권한이 허용되었습니다.'
                        : '일부 권한이 거부되었습니다. 안정적 알람을 위해 모두 허용해주세요.',
                  ),
                ),
              );
            },
          ),
          const Divider(),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: '필메이트',
            applicationVersion: '0.1.0',
            applicationLegalese:
                '오프라인 복약 관리 · 모든 데이터는 디바이스에만 저장됩니다.',
          ),
          if (kDebugMode) ...[
            const Divider(),
            const ListTile(
              dense: true,
              title: Text(
                '개발자',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
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
}
