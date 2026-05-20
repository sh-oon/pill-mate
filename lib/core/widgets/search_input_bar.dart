import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// `.srch` — 회색 배경 검색 인풋 + 좌측 아이콘.
///
/// `controller`가 주어지면 입력에 값이 있을 때 우측에 clear(✕) 버튼을 자동
/// 노출 — 사용자가 한 번에 검색어를 비울 수 있도록.
class SearchInputBar extends StatefulWidget {
  const SearchInputBar({
    super.key,
    required this.hintText,
    this.controller,
    this.onChanged,
  });

  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  State<SearchInputBar> createState() => _SearchInputBarState();
}

class _SearchInputBarState extends State<SearchInputBar> {
  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(SearchInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  void _clear() {
    final c = widget.controller;
    if (c == null) return;
    c.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final hasText = (widget.controller?.text.isNotEmpty ?? false);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20, color: AppColors.textFaint),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: InputBorder.none,
                hintText: widget.hintText,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textFaint,
                ),
              ),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textStrong,
              ),
            ),
          ),
          if (hasText)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _clear,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Icon(
                  Icons.cancel_rounded,
                  size: 18,
                  color: AppColors.textFaint,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
