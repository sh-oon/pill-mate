import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../widgets/labeled_text_input.dart';

/// Step 2: 이름 입력. 영양제는 자동완성, 약은 안내 배너.
class Step2Name extends StatefulWidget {
  const Step2Name({
    super.key,
    required this.isSupplement,
    required this.name,
    required this.onChange,
  });

  final bool isSupplement;
  final String name;
  final ValueChanged<String> onChange;

  @override
  State<Step2Name> createState() => _Step2NameState();
}

class _Step2NameState extends State<Step2Name> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.name);

  // 시안 SUG 배열 그대로.
  static const _suggestions = [
    '유산균', '유비퀴놀', '오메가3', '오메가-3', '비타민D', '비타민C',
    '종합비타민', '마그네슘', '루테인', '밀크씨슬', '아연', '콜라겐', '엽산',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    if (!widget.isSupplement || _ctrl.text.isEmpty) return const [];
    final q = _ctrl.text;
    return _suggestions
        .where((s) => s.startsWith(q))
        .take(4)
        .toList();
  }

  void _pick(String name) {
    _ctrl.text = name;
    _ctrl.selection = TextSelection.collapsed(offset: name.length);
    widget.onChange(name);
  }

  @override
  Widget build(BuildContext context) {
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
        if (_filtered.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
            child: _SuggestionList(
              query: _ctrl.text,
              suggestions: _filtered,
              onPick: _pick,
            ),
          ),
        if (!widget.isSupplement)
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 12, 22, 0),
            child: _MedInfoBanner(),
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
  final List<String> suggestions;
  final ValueChanged<String> onPick;

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
                suggestion: suggestions[i],
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
    required this.suggestion,
    required this.onTap,
  });

  final String query;
  final String suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rest = suggestion.startsWith(query)
        ? suggestion.substring(query.length)
        : suggestion;

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
            RichText(
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
