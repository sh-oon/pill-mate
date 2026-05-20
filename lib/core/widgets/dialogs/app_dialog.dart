import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../app_buttons.dart';

// =============================================================================
// AppDialog — 컴파운드 컴포넌트(Compound Component) 다이얼로그 시스템.
//
// 모든 다이얼로그가 공유하는 shell(흰 surface · 라운드 모서리 · 360 max-width ·
// barrier 색)을 컨테이너가 책임지고, 안쪽은 작은 블록들을 자유롭게 조립.
//
// 사용 예:
//   AppDialog.show(
//     context,
//     child: AppDialog(
//       children: [
//         AppDialogIconBadge(icon: Icons.delete_outline, tone: AppDialogTone.danger),
//         AppDialogTitle('정말 삭제할까요?'),
//         AppDialogMessage('되돌릴 수 없어요.'),
//         AppDialogActionPair(
//           cancelLabel: '취소', confirmLabel: '삭제',
//           onCancel: () => Navigator.pop(ctx, false),
//           onConfirm: () => Navigator.pop(ctx, true),
//           destructive: true,
//         ),
//       ],
//     ),
//   );
//
// 블록들은 각자 자신의 padding을 관리하므로 컨테이너는 inset만 책임.
// 덕분에 Divider/Row/Action 같은 블록이 자연스럽게 모서리까지 닿음.
// =============================================================================

const Color _kBarrierColor = Color(0x80141428); // rgba(20,20,40,0.5)
const double _kRadius = 24;
const double _kMaxWidth = 360;

/// 다이얼로그 톤 — 아이콘 배지·강조 버튼 색을 결정.
enum AppDialogTone { neutral, primary, danger, success }

extension on AppDialogTone {
  Color tint() => switch (this) {
        AppDialogTone.primary => AppColors.primaryTint,
        AppDialogTone.danger => AppColors.missedTint,
        AppDialogTone.success => AppColors.successTint,
        AppDialogTone.neutral => AppColors.surfaceMuted,
      };

  Color accent() => switch (this) {
        AppDialogTone.primary => AppColors.primary,
        AppDialogTone.danger => AppColors.missed,
        AppDialogTone.success => AppColors.success,
        AppDialogTone.neutral => AppColors.textMuted,
      };
}

/// 컴파운드 다이얼로그 컨테이너 — 안쪽 padding 없이 children을 세로로 쌓음.
/// 각 자식 블록이 자신의 padding을 관리.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.children,
    this.maxWidth = _kMaxWidth,
  });

  final List<Widget> children;
  final double maxWidth;

  /// `showDialog`의 짧은 래퍼. barrier 색과 inset을 표준값으로 통일.
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    Color barrierColor = _kBarrierColor,
    EdgeInsets insetPadding =
        const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
  }) {
    return showDialog<T>(
      context: context,
      barrierColor: barrierColor,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: insetPadding,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(_kRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

// =============================================================================
// Header blocks
// =============================================================================

/// 상단 중앙 라운드 사각 아이콘 배지.
class AppDialogIconBadge extends StatelessWidget {
  const AppDialogIconBadge({
    super.key,
    required this.icon,
    this.tone = AppDialogTone.primary,
    this.size = 64,
    this.iconSize = 32,
    this.shape = BoxShape.rectangle,
    this.topPadding = 24,
  });

  final IconData icon;
  final AppDialogTone tone;
  final double size;
  final double iconSize;
  final BoxShape shape;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: tone.tint(),
            shape: shape,
            borderRadius:
                shape == BoxShape.rectangle ? BorderRadius.circular(18) : null,
          ),
          child: Icon(icon, size: iconSize, color: tone.accent()),
        ),
      ),
    );
  }
}

/// 다이얼로그 제목 — 중앙, w800.
class AppDialogTitle extends StatelessWidget {
  const AppDialogTitle(
    this.text, {
    super.key,
    this.topPadding = 14,
  });

  final String text;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPadding, 20, 0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.textStrong,
          letterSpacing: -0.3,
          height: 1.4,
        ),
      ),
    );
  }
}

/// 제목 아래 작은 보조 텍스트 (예: "버전 0.1.0").
class AppDialogSubtitle extends StatelessWidget {
  const AppDialogSubtitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// =============================================================================
// Body blocks
// =============================================================================

/// 중앙 정렬 본문 메시지.
class AppDialogMessage extends StatelessWidget {
  const AppDialogMessage(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textMuted,
          height: 1.5,
        ),
      ),
    );
  }
}

/// 자유로운 본문 컨테이너 — 임의 위젯을 좌우 padding과 함께 배치.
class AppDialogBody extends StatelessWidget {
  const AppDialogBody({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 0),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: padding, child: child);
  }
}

/// tint 배경 + 좌측 아이콘 + 본문이 들어가는 강조 카드.
class AppDialogInfoCard extends StatelessWidget {
  const AppDialogInfoCard({
    super.key,
    required this.icon,
    required this.text,
    this.tone = AppDialogTone.primary,
  });

  final IconData icon;
  final String text;
  final AppDialogTone tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: tone.tint(),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: tone.accent()),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: AppColors.textStrong,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Row · Divider
// =============================================================================

/// 좌→우 아이콘·라벨·chevron 클릭 행. edge-to-edge 자동.
class AppDialogRow extends StatelessWidget {
  const AppDialogRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textStrong,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textFaint,
            ),
          ],
        ),
      ),
    );
  }
}

/// 1px hairline divider — 좌우 margin 없이 모서리까지.
class AppDialogDivider extends StatelessWidget {
  const AppDialogDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: AppColors.border);
}

// =============================================================================
// Actions
// =============================================================================

/// 단일 close/dismiss 버튼 — 하단에 edge-to-edge, 모서리 라운드 자동.
class AppDialogCloseAction extends StatelessWidget {
  const AppDialogCloseAction({
    super.key,
    this.label = '닫기',
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textMuted,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(_kRadius),
            ),
          ),
        ),
        onPressed: onPressed ?? () => Navigator.of(context).pop(),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// 취소·확인 한 쌍 버튼 — 좌우 분할 + 표준 padding(22, 22, 22, 20).
class AppDialogActionPair extends StatelessWidget {
  const AppDialogActionPair({
    super.key,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    this.destructive = false,
  });

  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: cancelLabel,
              variant: AppButtonVariant.secondary,
              fullWidth: true,
              onPressed: onCancel,
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
              onPressed: onConfirm,
            ),
          ),
        ],
      ),
    );
  }
}
