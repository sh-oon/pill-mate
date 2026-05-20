import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'app_dialog.dart';

/// `.about-dlg` — 앱 정보 다이얼로그.
///
/// 호출: `await AboutAppDialog.show(context, appName: ..., appVersion: ...)`.
///
/// `AppDialog` 컴파운드 primitive들로만 구성 — 같은 패턴을 따라 새 다이얼로그를
/// 만들 때 어떤 블록들이 있는지 보여주는 reference로도 활용.
class AboutAppDialog {
  const AboutAppDialog._();

  static Future<void> show(
    BuildContext context, {
    required String appName,
    required String appVersion,
    required String description,
    IconData appIcon = Icons.medication_rounded,
  }) {
    return AppDialog.show<void>(
      context,
      child: AppDialog(
        children: [
          AppDialogIconBadge(icon: appIcon, tone: AppDialogTone.primary),
          AppDialogTitle(appName),
          AppDialogSubtitle('버전 $appVersion'),
          AppDialogInfoCard(
            icon: Icons.shield_outlined,
            text: description,
            tone: AppDialogTone.primary,
          ),
          const SizedBox(height: 16),
          const AppDialogDivider(),
          AppDialogRow(
            icon: Icons.description_outlined,
            label: '오픈소스 라이선스',
            onTap: () {
              Navigator.of(context).pop();
              showLicensePage(
                context: context,
                applicationName: appName,
                applicationVersion: appVersion,
                applicationIcon: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(appIcon, size: 40, color: AppColors.primary),
                ),
              );
            },
          ),
          const AppDialogDivider(),
          const AppDialogCloseAction(),
        ],
      ),
    );
  }
}
