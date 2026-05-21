import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/app_buttons.dart';
import '../core/widgets/med_pill_svg.dart';
import 'mockup_scaffold.dart';

/// Phase 3 — Step 2: 선택한 catalog의 인스턴스 속성 입력.
///
/// 카탈로그 default 값으로 prefill, 사용자가 override 가능. 메모/복용기간은 인스턴스 전용.
class MockupStep2Instance extends StatelessWidget {
  const MockupStep2Instance({super.key});

  @override
  Widget build(BuildContext context) {
    return MockupScaffold(
      label: 'Phase 3 · Step 2 — 인스턴스 속성',
      child: Column(
        children: [
          // 진행 표시.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                _StepIndicator(current: 2, total: 3),
                const Spacer(),
                Text('2/3', style: AppTypography.bodySmall),
              ],
            ),
          ),
          // 카탈로그 헤더 (선택한 항목 미리보기).
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const MedPillSvg(name: '비타민D', size: 40),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '비타민D',
                              style: AppTypography.titleMedium,
                            ),
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
                        ),
                        Text(
                          '영양제 · 1000 IU 기본',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 폼.
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                _FormSection(
                  title: '복용량',
                  hint: '기본값과 다르면 직접 입력하세요',
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _TextInput(hint: '1000', value: '1000'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: _TextInput(hint: 'IU', value: 'IU'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _FormSection(
                  title: '메모',
                  hint: '복용 이유, 처방 정보 등 (선택)',
                  child: _TextInput(
                    hint: '예: 아침에 식후 30분',
                    maxLines: 2,
                  ),
                ),
                const SizedBox(height: 20),
                _FormSection(
                  title: '복용 기간',
                  hint: '비워두면 무기한',
                  child: Row(
                    children: const [
                      Expanded(child: _DateChip(label: '시작', value: '오늘')),
                      SizedBox(width: 8),
                      Text('~', style: AppTypography.bodyMedium),
                      SizedBox(width: 8),
                      Expanded(child: _DateChip(label: '종료', value: '없음')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 하단 액션.
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: '이전',
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.lg,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    label: '다음',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.lg,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('→ Step 3 알람 설정')),
                      );
                    },
                  ),
                ),
              ],
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

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.hint, required this.child});
  final String title;
  final String hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.labelStrong),
        const SizedBox(height: 4),
        Text(hint, style: AppTypography.bodySmall),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({required this.hint, this.value, this.maxLines = 1});
  final String hint;
  final String? value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: TextField(
        controller: value != null ? TextEditingController(text: value) : null,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textFaint),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderHairline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$label  ', style: AppTypography.bodySmall),
            Text(value, style: AppTypography.bodyMedium),
          ],
        ),
      ),
    );
  }
}
