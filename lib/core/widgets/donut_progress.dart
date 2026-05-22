import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// 홈 상단 요약 카드의 도넛 진행률.
///
/// [progress]는 0.0~1.0. 가운데 "{percent}%" + "완료" 라벨.
/// progress 변경 시 implicit하게 [animationDuration] 만큼 트윈 — arc와 중앙
/// percent 텍스트가 같은 값으로 동기 변화한다.
class DonutProgress extends StatelessWidget {
  const DonutProgress({
    super.key,
    required this.progress,
    this.size = 110,
    this.strokeWidth = 10,
    this.animationDuration = const Duration(milliseconds: 600),
    this.animationCurve = Curves.easeOutCubic,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Duration animationDuration;
  final Curve animationCurve;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      // begin: 0 — 첫 빌드에서 0→clamped 진입 효과.
      // 이후 progress 변경 시 TweenAnimationBuilder가 자동으로 이전 end → 새 end 트윈.
      tween: Tween<double>(begin: 0, end: clamped),
      duration: animationDuration,
      curve: animationCurve,
      builder: (context, value, _) {
        final percent = (value * 100).round();
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _DonutPainter(progress: value, strokeWidth: strokeWidth),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      text: '$percent',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        height: 1,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      children: const [
                        TextSpan(
                          text: '%',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '완료',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.progress, required this.strokeWidth});

  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = AppColors.lavenderRing;
    canvas.drawCircle(center, radius, bg);

    if (progress <= 0) return;
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = AppColors.primary;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, fg);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.progress != progress || old.strokeWidth != strokeWidth;
}
