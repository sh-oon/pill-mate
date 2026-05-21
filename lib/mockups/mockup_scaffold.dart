import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

/// 모든 mockup 화면 공통 wrapper.
///
/// 상단 라벨 + 뒤로가기. 실제 화면이 아닌 "참고용" 임을 명시.
class MockupScaffold extends StatelessWidget {
  const MockupScaffold({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Banner(label: label),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryTint,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => context.pop(),
            color: AppColors.primary,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'mockup · $label',
              style: AppTypography.labelStrong.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
