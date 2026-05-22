import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import 'mockup_drawer_card.dart';
import 'mockup_drawer_screen.dart';
import 'mockup_step1_catalog.dart';
import 'mockup_step2_instance.dart';
import 'mockup_step3_alarm.dart';
import 'mockup_tracked_detail.dart';

/// Phase 3 디자인 mockup 모음.
///
/// 라우트: `/mockups` (dev only — release build에서는 안 보이게 settings 진입로 가림 권장).
/// 실제 구현 전 visual reference. 데이터는 모두 하드코딩.
class MockupsIndex extends StatelessWidget {
  const MockupsIndex({super.key});

  static const List<_MockupEntry> _entries = [
    _MockupEntry(
      title: 'Step 1 — 카탈로그 검색/선택',
      description: '50개 시드 + 사용자 추가 통합 검색. 결과 없으면 "직접 추가" CTA.',
      builder: _build1,
    ),
    _MockupEntry(
      title: 'Step 2 — 인스턴스 속성',
      description: '카탈로그 default 값 prefill + 사용자 override (복용량, 메모, 기간).',
      builder: _build2,
    ),
    _MockupEntry(
      title: 'Step 3 — 알람 (skip 가능)',
      description: '"건너뛰기" 버튼 동등 비중. tracked만 생성하고 알람 없이 등록.',
      builder: _build3,
    ),
    _MockupEntry(
      title: '약 서랍 카드 (알람 유무)',
      description: '알람 있음: alarm_on + 다음 시각. 알람 없음: alarm_off + drawer 전용.',
      builder: _build4,
    ),
    _MockupEntry(
      title: 'Tracked detail — 알람 추가 CTA',
      description: '알람 0개일 때 prominent "알람 추가" 섹션. 토글로 알람 있음/없음 미리보기.',
      builder: _build5,
    ),
    _MockupEntry(
      title: '약 서랍 — 전체 화면 (등록됨/비어있음/검색0건)',
      description: '헤더 + 검색 + 필터 chip(전체/알람있음/알람없음) + 정렬. 3가지 상태 토글로 미리보기.',
      builder: _build6,
    ),
  ];

  static Widget _build1(BuildContext c) => const MockupStep1Catalog();
  static Widget _build2(BuildContext c) => const MockupStep2Instance();
  static Widget _build3(BuildContext c) => const MockupStep3Alarm();
  static Widget _build4(BuildContext c) => const MockupDrawerCard();
  static Widget _build5(BuildContext c) => const MockupTrackedDetail();
  static Widget _build6(BuildContext c) => const MockupDrawerScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Phase 3 mockups'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        itemCount: _entries.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (i == 0) return const _Intro();
          return _MockupTile(entry: _entries[i - 1]);
        },
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Phase 3 visual reference', style: AppTypography.titleMedium.copyWith(color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(
            '실제 구현 전 디자인 참고용. 데이터는 모두 하드코딩, 동작은 SnackBar로 시뮬레이션.',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MockupTile extends StatelessWidget {
  const _MockupTile({required this.entry});
  final _MockupEntry entry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: entry.builder),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderHairline),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.title, style: AppTypography.titleMedium),
                    const SizedBox(height: 4),
                    Text(entry.description, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockupEntry {
  const _MockupEntry({
    required this.title,
    required this.description,
    required this.builder,
  });
  final String title;
  final String description;
  final Widget Function(BuildContext) builder;
}
