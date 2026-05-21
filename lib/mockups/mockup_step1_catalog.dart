import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/med_pill_svg.dart';
import 'mockup_scaffold.dart';

/// Phase 3 — 등록 플로우 Step 1: 카탈로그 검색/선택.
///
/// 50개 시드 카탈로그 + 사용자 추가 항목을 통합 검색. 선택 시 step 2로 이동.
/// 결과가 없으면 "직접 추가" CTA로 catalog 진입.
class MockupStep1Catalog extends StatefulWidget {
  const MockupStep1Catalog({super.key});

  @override
  State<MockupStep1Catalog> createState() => _MockupStep1CatalogState();
}

class _MockupStep1CatalogState extends State<MockupStep1Catalog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((i) {
      if (_query.isEmpty) return true;
      return i.name.contains(_query) || (i.nameEn?.toLowerCase().contains(_query.toLowerCase()) ?? false);
    }).toList();

    return MockupScaffold(
      label: 'Phase 3 · Step 1 — 카탈로그 검색',
      child: Column(
        children: [
          // 상단 헤더 + 진행 표시.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const _StepIndicator(current: 1, total: 3),
                const Spacer(),
                Text('1/3', style: AppTypography.bodySmall),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textStrong,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(text: '어떤 약/영양제를\n'),
                      TextSpan(
                        text: '챙기시나요?',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '카탈로그에서 찾아보거나 직접 추가할 수 있어요.',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          // 검색 input.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.textFaint, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: const InputDecoration(
                        hintText: '비타민D, 오메가3, 약 이름...',
                        hintStyle: TextStyle(color: AppColors.textFaint),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.cancel, size: 18, color: AppColors.textFaint),
                      onPressed: () => setState(() => _query = ''),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
          ),
          // 결과 카운트.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                Text(
                  '카탈로그 ${filtered.length}개',
                  style: AppTypography.bodySmall,
                ),
                const Spacer(),
                if (_query.isNotEmpty && filtered.isEmpty)
                  Text(
                    '결과 없음',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.missed),
                  ),
              ],
            ),
          ),
          // 결과 리스트.
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              itemCount: filtered.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                if (i == filtered.length) return const _AddCustomCard();
                return _CatalogCard(item: filtered[i]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: i < current ? AppColors.primary : AppColors.borderHairline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ],
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({required this.item});
  final _CatalogItemMock item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('선택: ${item.name} → Step 2로 이동')),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderHairline),
        ),
        child: Row(
          children: [
            // 아이콘 (catalog 큐레이션 자산).
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: MedPillSvg(name: item.name, size: 36),
            ),
            const SizedBox(width: 12),
            // 이름 + 메타.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.name,
                          style: AppTypography.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.source == 'seed') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.successTint,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'seed',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.success,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (item.dosage != null) '${item.dosage}${item.unit ?? ''}',
                      ...item.tags,
                    ].join(' · '),
                    style: AppTypography.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textFaint),
          ],
        ),
      ),
    );
  }
}

class _AddCustomCard extends StatelessWidget {
  const _AddCustomCard();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('직접 추가 → Step 2 (이름/카테고리 입력 분기)')),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryTint.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), style: BorderStyle.solid, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.add, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '여기에 없어요, 직접 추가할게요',
                    style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '이름과 종류를 직접 입력해서 등록',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.primary.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogItemMock {
  const _CatalogItemMock({
    required this.name,
    this.nameEn,
    this.dosage,
    this.unit,
    this.tags = const [],
    this.source = 'seed',
  });

  final String name;
  final String? nameEn;
  final String? dosage;
  final String? unit;
  final List<String> tags;
  final String source;
}

// Mock data — 실제 시드 카탈로그(50개)에서 대표 항목 발췌.
const _items = <_CatalogItemMock>[
  _CatalogItemMock(
    name: '비타민D',
    nameEn: 'Vitamin D3',
    dosage: '1000',
    unit: 'IU',
    tags: ['면역', '뼈건강'],
  ),
  _CatalogItemMock(
    name: '오메가3',
    nameEn: 'Omega-3',
    dosage: '1000',
    unit: 'mg',
    tags: ['혈관', '뇌건강'],
  ),
  _CatalogItemMock(
    name: '유산균',
    nameEn: 'Probiotics',
    dosage: '100',
    unit: '억',
    tags: ['장건강'],
  ),
  _CatalogItemMock(
    name: '종합비타민',
    dosage: '1',
    unit: '정',
    tags: ['종합'],
  ),
  _CatalogItemMock(
    name: '마그네슘',
    nameEn: 'Magnesium',
    dosage: '500',
    unit: 'mg',
    tags: ['근육', '수면'],
  ),
  _CatalogItemMock(
    name: '내가 추가한 약',
    source: 'user',
    tags: ['직접 입력'],
  ),
];
