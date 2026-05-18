import 'package:flutter/material.dart';

/// 32×32 원형 배경 + 가운데 아이콘.
///
/// 홈 4-스탯 셀의 "완료" 아이콘처럼 [filled]=true이면 원형 배경,
/// 나머지 셀처럼 [filled]=false이면 배경 없이 아이콘만.
class IconCircleBadge extends StatelessWidget {
  const IconCircleBadge({
    super.key,
    required this.icon,
    required this.iconColor,
    this.filled = false,
    this.backgroundColor,
    this.size = 32,
    this.iconSize,
  });

  final IconData icon;
  final Color iconColor;
  final bool filled;
  final Color? backgroundColor;
  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: filled
          ? BoxDecoration(
              color: backgroundColor ?? iconColor,
              shape: BoxShape.circle,
            )
          : null,
      child: Center(
        child: Icon(icon, size: iconSize ?? (filled ? 18 : 24), color: iconColor),
      ),
    );
  }
}
