import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// "PillMate" 로고 + 우측 종 (선택적 빨간 dot) 헤더.
///
/// 홈/약 서랍/리포트/캘린더 4탭에서 공통 사용.
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.onBellTap,
    this.onSettingsTap,
    this.hasUnread = false,
    this.padding = const EdgeInsets.fromLTRB(22, 12, 12, 4),
  });

  final VoidCallback onBellTap;

  /// null이면 톱니 아이콘 비표시 (탭별 선택적 노출).
  final VoidCallback? onSettingsTap;
  final bool hasUnread;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'PillMate',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: -0.4,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 24,
                      color: AppColors.textStrong,
                      onPressed: onBellTap,
                      icon: const Icon(Icons.notifications_none_rounded),
                    ),
                    if (hasUnread)
                      Positioned(
                        top: 6,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.missed,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.background,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (onSettingsTap != null)
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 24,
                    color: AppColors.textStrong,
                    onPressed: onSettingsTap,
                    tooltip: '설정',
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
