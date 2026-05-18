import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('캘린더')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_rounded,
                size: 56, color: AppColors.textFaint),
            SizedBox(height: 12),
            Text('월간 복약 캘린더는 곧 추가됩니다.'),
          ],
        ),
      ),
    );
  }
}
