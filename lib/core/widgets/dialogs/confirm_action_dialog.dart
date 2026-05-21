import 'package:flutter/material.dart';

import 'app_dialog.dart';

/// `.confirm-dlg` — 취소/확인 두 버튼이 있는 가운데 정렬 confirm 다이얼로그.
///
/// 호출: `final ok = await ConfirmActionDialog.show(...)`.
///
/// `AppDialog` 컴파운드 primitive들로 구성된 얇은 wrapper — destructive 액션에
/// 자주 반복되는 형태(아이콘 배지 + 제목 + 설명 + 취소/확인 페어)를 한 함수
/// 호출로 묶음.
class ConfirmActionDialog {
  const ConfirmActionDialog._();

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = '삭제',
    String cancelLabel = '취소',
    IconData icon = Icons.delete_outline,
    bool destructive = true,
  }) async {
    final tone = destructive ? AppDialogTone.danger : AppDialogTone.primary;
    // Builder로 dialog 내부 context를 캡처 — 외부 caller context의 element가
    // dispose된 뒤(예: Slidable confirmDismiss 도중) Navigator.of가 터지는
    // 케이스 방어.
    final ok = await AppDialog.show<bool>(
      context,
      child: Builder(
        builder: (dialogCtx) => AppDialog(
          children: [
            AppDialogIconBadge(
              icon: icon,
              tone: tone,
              size: 56,
              iconSize: 28,
              shape: BoxShape.circle,
            ),
            AppDialogTitle(title),
            AppDialogMessage(message),
            AppDialogActionPair(
              cancelLabel: cancelLabel,
              confirmLabel: confirmLabel,
              destructive: destructive,
              onCancel: () => Navigator.of(dialogCtx).pop<bool>(false),
              onConfirm: () => Navigator.of(dialogCtx).pop<bool>(true),
            ),
          ],
        ),
      ),
    );
    return ok ?? false;
  }
}
