import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/storage/onboarding_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../onboarding/presentation/widgets/pil_mascot.dart';

/// 부팅 직후 잠깐 노출되는 스플래시.
/// - 마스코트 페이드인 + 약한 부풀기 애니메이션
/// - 최소 노출 시간(_minDuration) 보장 후 라우터에 분기 결정 위임
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const Duration _minDuration = Duration(milliseconds: 1100);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 0.88,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _scheduleNavigation();
  }

  Future<void> _scheduleNavigation() async {
    await Future<void>.delayed(SplashScreen._minDuration);
    if (!mounted) return;
    final completed = ref.read(onboardingCompletedProvider);
    final next = completed ? AppRoute.home : AppRoute.onboarding;
    context.go(next);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PilMascot(size: 132),
                  const SizedBox(height: 20),
                  Text(
                    '필메이트',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.primary,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '복약을 잊지 않게 도와드릴게요',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
