import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('리포트')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded, size: 56, color: AppColors.textFaint),
            SizedBox(height: 12),
            Text('복용 리포트는 곧 추가됩니다.'),
          ],
        ),
      ),
    );
  }
}
