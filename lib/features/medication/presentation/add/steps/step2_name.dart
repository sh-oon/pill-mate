import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/database/app_database.dart';
import '../../../../../core/database/tables/catalog_items.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../catalog/data/catalog_providers.dart';
import '../widgets/labeled_text_input.dart';

/// Step 2: 이름 + 복용량 + 메모 입력.
///
/// 이름 자동완성은 catalog(시드 + 사용자가 이전에 등록한 항목)에서 가져옴.
/// 카테고리(med/sup) 일치 항목만 노출. 사용자가 picker로 항목 선택 시 부모에게
/// [onPickCatalog]로 알림 — 부모는 dosage/unit 같은 default 값을 prefill 가능.
class Step2Name extends ConsumerStatefulWidget {
  const Step2Name({
    super.key,
    required this.isSupplement,
    required this.name,
    required this.dosage,
    required this.unit,
    required this.memo,
    required this.onChange,
    required this.onChangeDosage,
    required this.onChangeUnit,
    required this.onChangeMemo,
    this.onPickCatalog,
  });

  final bool isSupplement;
  final String name;
  final String dosage;
  final String unit;
  final String memo;
  final ValueChanged<String> onChange;
  final ValueChanged<String> onChangeDosage;
  final ValueChanged<String> onChangeUnit;
  final ValueChanged<String> onChangeMemo;

  /// 카탈로그 자동완성에서 항목을 픽했을 때 (default 값 prefill 용).
  final ValueChanged<CatalogItem>? onPickCatalog;

  @override
  ConsumerState<Step2Name> createState() => _Step2NameState();
}

class _Step2NameState extends ConsumerState<Step2Name> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.name);
  late final TextEditingController _dosageCtrl =
      TextEditingController(text: widget.dosage);
  late final TextEditingController _unitCtrl =
      TextEditingController(text: widget.unit);
  late final TextEditingController _memoCtrl =
      TextEditingController(text: widget.memo);

  @override
  void dispose() {
    _ctrl.dispose();
    _dosageCtrl.dispose();
    _unitCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  /// 현재 카테고리 + 검색어에 매치되는 카탈로그 항목 상위 5개.
  List<CatalogItem> _filteredCatalog() {
    if (_ctrl.text.isEmpty) return const [];
    final cat = widget.isSupplement ? 'sup' : 'med';
    final all = ref.watch(catalogSearchProvider(_ctrl.text)).value ??
        const <CatalogItem>[];
    return all.where((c) => c.category == cat).take(5).toList();
  }

  void _pick(CatalogItem item) {
    _ctrl.text = item.name;
    _ctrl.selection = TextSelection.collapsed(offset: item.name.length);
    widget.onChange(item.name);
    widget.onPickCatalog?.call(item);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCatalog();
    return ListView(
      children: [
        _Header(isSupplement: widget.isSupplement),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: LabeledTextInput(
            label: '이름',
            controller: _ctrl,
            hintText: widget.isSupplement ? '예: 유산균' : '예: 아토르바스타틴',
            onChanged: (v) {
              widget.onChange(v);
              setState(() {});
            },
          ),
        ),
        if (filtered.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
            child: _SuggestionList(
              query: _ctrl.text,
              suggestions: filtered,
              onPick: _pick,
            ),
          ),
        if (!widget.isSupplement && filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 12, 22, 0),
            child: _MedInfoBanner(),
          ),
        const SizedBox(height: 18),
        // 복용량 (선택) — 숫자 + 단위 가로 배치.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: _DosageRow(
            dosageCtrl: _dosageCtrl,
            unitCtrl: _unitCtrl,
            isSupplement: widget.isSupplement,
            onChangeDosage: widget.onChangeDosage,
            onChangeUnit: widget.onChangeUnit,
          ),
        ),
        const SizedBox(height: 18),
        // 메모 (선택).
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: LabeledTextInput(
            label: '메모 (선택)',
            controller: _memoCtrl,
            hintText: '예: 아침에 식후 30분',
            maxLines: 2,
            onChanged: widget.onChangeMemo,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _DosageRow extends StatelessWidget {
  const _DosageRow({
    required this.dosageCtrl,
    required this.unitCtrl,
    required this.isSupplement,
    required this.onChangeDosage,
    required this.onChangeUnit,
  });

  final TextEditingController dosageCtrl;
  final TextEditingController unitCtrl;
  final bool isSupplement;
  final ValueChanged<String> onChangeDosage;
  final ValueChanged<String> onChangeUnit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '복용량 (선택)',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: dosageCtrl,
                keyboardType: TextInputType.text,
                onChanged: onChangeDosage,
                decoration: InputDecoration(
                  hintText: isSupplement ? '1000' : '1',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.4),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextField(
                controller: unitCtrl,
                onChanged: onChangeUnit,
                decoration: InputDecoration(
                  hintText: isSupplement ? 'mg' : '정',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.4),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isSupplement});
  final bool isSupplement;

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
                TextSpan(text: '이름을\n'),
                TextSpan(
                  text: '입력해주세요',
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSupplement
                ? '입력하는 동안 자동완성이 도와드려요'
                : '약은 자동완성을 제공하지 않아요',
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList({
    required this.query,
    required this.suggestions,
    required this.onPick,
  });

  final String query;
  final List<CatalogItem> suggestions;
  final ValueChanged<CatalogItem> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            for (var i = 0; i < suggestions.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, color: AppColors.border),
              _SuggestionItem(
                query: query,
                item: suggestions[i],
                onTap: () => onPick(suggestions[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuggestionItem extends StatelessWidget {
  const _SuggestionItem({
    required this.query,
    required this.item,
    required this.onTap,
  });

  final String query;
  final CatalogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final suggestion = item.name;
    final rest = suggestion.startsWith(query)
        ? suggestion.substring(query.length)
        : suggestion;
    final dosagePart = (item.defaultDosage != null)
        ? '${item.defaultDosage}${item.defaultUnit ?? ''}'
        : null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.primaryTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco, size: 14, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textStrong,
                      ),
                      children: [
                        TextSpan(
                          text: query,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(text: rest),
                      ],
                    ),
                  ),
                  if (dosagePart != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      dosagePart,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (item.source != CatalogSource.seed)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.history,
                    size: 14, color: AppColors.textFaint),
              ),
          ],
        ),
      ),
    );
  }
}

class _MedInfoBanner extends StatelessWidget {
  const _MedInfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.missedSoft,
        border: Border.all(color: AppColors.missedBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline,
                size: 16, color: AppColors.missed),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '약은 정확한 이름이 중요해서 직접 입력해주세요.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textStrong,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
