import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 섹션 제목 + 우측 액션 영역.
///
/// 홈/리포트의 "오늘의 복용 일정 [전체보기 ›]" 같은 패턴.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.padding = const EdgeInsets.fromLTRB(22, 4, 22, 12),
  });

  final String title;
  final Widget? action;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
