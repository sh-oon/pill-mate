import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/permissions/permission_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/onboarding_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'widgets/feature_card.dart';
import 'widgets/pil_mascot.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _busy = false;

  Future<void> _start() async {
    if (_busy) return;
    setState(() => _busy = true);

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    PermissionReport? report;
    try {
      report = await ref.read(permissionServiceProvider).requestAll();
    } catch (_) {
      report = null;
    }

    await ref.read(onboardingCompletedProvider.notifier).complete();

    if (!mounted) return;

    final granted = report?.isFullyGranted ?? false;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          granted ? '알림이 허용되었어요' : '설정에서 언제든 켤 수 있어요',
        ),
      ),
    );

    router.go(AppRoute.home);
  }

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            viewPadding.top > 0 ? 24 : 60,
            24,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              const PilMascot(size: 120),
              const SizedBox(height: 24),
              const _Title(),
              const SizedBox(height: 12),
              Text(
                '매일 챙겨야 할 약과 영양제,\n제가 잊지 않도록 도와드릴게요.',
                style: AppTypography.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const _FeatureList(),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _start,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text('시작하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: AppTypography.displayLarge,
        children: const [
          TextSpan(text: '안녕하세요,\n'),
          TextSpan(
            text: '필이에요!',
            style: TextStyle(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList();

  static const List<_FeatureSpec> _items = [
    _FeatureSpec(
      icon: Icons.notifications_active_outlined,
      title: '시간에 맞춰 알려드려요',
      description: '원하는 시간을 직접 설정할 수 있어요',
    ),
    _FeatureSpec(
      icon: Icons.donut_large_outlined,
      title: '복용 기록을 보여드려요',
      description: '놓친 기록도 언제든 수정할 수 있어요',
    ),
    _FeatureSpec(
      icon: Icons.verified_user_outlined,
      title: '기록은 기기에만 저장돼요',
      description: '개인 정보를 외부로 보내지 않아요',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            FeatureCard(
              icon: _items[i].icon,
              title: _items[i].title,
              description: _items[i].description,
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureSpec {
  const _FeatureSpec({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
