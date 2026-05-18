import 'dart:io' show Platform;

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

/// 하단 탭 한 칸의 메타데이터.
///
/// iOS는 실제 UIKit `UITabBar`에 SF Symbol 이름을 그대로 전달.
/// Android는 Material 아이콘으로 직접 그림.
class TabItem {
  const TabItem({
    required this.label,
    required this.materialIcon,
    required this.sfSymbol,
    required this.sfSymbolActive,
  });

  final String label;
  final IconData materialIcon;
  final String sfSymbol;
  final String sfSymbolActive;
}

const tabItems = <TabItem>[
  TabItem(
    label: '홈',
    materialIcon: Icons.home_rounded,
    sfSymbol: 'house',
    sfSymbolActive: 'house.fill',
  ),
  TabItem(
    label: '약 서랍',
    materialIcon: Icons.medication_outlined,
    sfSymbol: 'pills',
    sfSymbolActive: 'pills.fill',
  ),
  TabItem(
    label: '리포트',
    materialIcon: Icons.bar_chart_rounded,
    sfSymbol: 'chart.bar',
    sfSymbolActive: 'chart.bar.fill',
  ),
  TabItem(
    label: '캘린더',
    materialIcon: Icons.calendar_month_rounded,
    sfSymbol: 'calendar',
    sfSymbolActive: 'calendar',
  ),
];

/// 플랫폼별 하단 탭바를 가진 셸.
///
/// iOS: `CNTabBar` — 실제 UIKit `UITabBar`를 PlatformView로 임베드.
///      iOS 26+에서는 Liquid Glass가 자동으로 적용됨.
/// Android: 시안 그대로 흰 라운드 pill 바.
///
/// 활성 탭을 다시 탭하면 해당 브랜치의 Navigator를 루트로 pop.
class TabShell extends StatelessWidget {
  const TabShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _onTap(int index) {
    shell.goBranch(
      index,
      initialLocation: index == shell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: shell,
      bottomNavigationBar: Platform.isIOS
          ? _IosNativeTabBar(
              currentIndex: shell.currentIndex,
              onTap: _onTap,
            )
          : _AndroidPillTabBar(
              currentIndex: shell.currentIndex,
              onTap: _onTap,
            ),
    );
  }
}

class _IosNativeTabBar extends StatelessWidget {
  const _IosNativeTabBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return CNTabBar(
      currentIndex: currentIndex,
      onTap: onTap,
      iconSize: 18,
      items: [
        for (final t in tabItems)
          CNTabBarItem(
            label: t.label,
            icon: CNSymbol(t.sfSymbol),
            activeIcon: CNSymbol(t.sfSymbolActive),
          ),
      ],
    );
  }
}

class _AndroidPillTabBar extends StatelessWidget {
  const _AndroidPillTabBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Row(
            children: [
              for (var i = 0; i < tabItems.length; i++)
                Expanded(
                  child: _AndroidTabItem(
                    item: tabItems[i],
                    active: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AndroidTabItem extends StatelessWidget {
  const _AndroidTabItem({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final TabItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textFaint;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.materialIcon, size: 24, color: color),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
