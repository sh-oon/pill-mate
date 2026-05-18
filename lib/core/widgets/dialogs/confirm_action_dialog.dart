import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../app_buttons.dart';

/// `.confirm-dlg` — 가운데 정렬 confirm 다이얼로그.
///
/// 호출: `final ok = await ConfirmActionDialog.show(...)`.
class ConfirmActionDialog extends StatelessWidget {
  const ConfirmActionDialog._({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.destructive = true,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final bool destructive;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = '삭제',
    String cancelLabel = '취소',
    IconData icon = Icons.delete_outline,
    bool destructive = true,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x80141428), // .bd rgba(20,20,40,0.5)
      builder: (_) => ConfirmActionDialog._(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
        iconBg: destructive ? AppColors.missedTint : AppColors.primaryTint,
        iconColor: destructive ? AppColors.missed : AppColors.primary,
        destructive: destructive,
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, size: 28, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: cancelLabel,
                    variant: AppButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: () => Navigator.of(context).pop<bool>(false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: confirmLabel,
                    variant: destructive
                        ? AppButtonVariant.danger
                        : AppButtonVariant.primary,
                    fullWidth: true,
                    onPressed: () => Navigator.of(context).pop<bool>(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

