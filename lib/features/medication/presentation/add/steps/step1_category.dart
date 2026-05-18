import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../widgets/category_card.dart';

/// Step 1: 카테고리 선택 (약 / 영양제).
class Step1Category extends StatelessWidget {
  const Step1Category({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const _Header(),
        CategoryCard(
          title: '약',
          subtitle: '이름은 직접 입력해주세요',
          sampleMedName: '감기약',
          selected: selected == 'med',
          onTap: () => onSelect('med'),
        ),
        CategoryCard(
          title: '영양제',
          subtitle: '자주 먹는 영양제 추천해드려요',
          sampleMedName: '유산균',
          selected: selected == 'sup',
          onTap: () => onSelect('sup'),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
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
                TextSpan(text: '무엇을\n'),
                TextSpan(
                  text: '등록할까요?',
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '먼저 종류부터 골라주세요',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
