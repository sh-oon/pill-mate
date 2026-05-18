import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// `.srch` — 회색 배경 검색 인풋 + 좌측 아이콘.
class SearchInputBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: InputBorder.none,
                hintText: hintText,
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
        ],
      ),
    );
  }
}
