import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum SwissButtonStyle { primary, outline, dark, danger }

class SwissButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final SwissButtonStyle style;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const SwissButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = SwissButtonStyle.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide border;

    switch (style) {
      case SwissButtonStyle.primary:
        bg = AppTheme.primary;
        fg = Colors.white;
        border = BorderSide.none;
        break;
      case SwissButtonStyle.outline:
        bg = AppTheme.surface;
        fg = AppTheme.text;
        border = BorderSide(
          color: AppTheme.border,
          width: AppTheme.borderWidth,
        );
        break;
      case SwissButtonStyle.dark:
        bg = AppTheme.text;
        fg = Colors.white;
        border = BorderSide.none;
        break;
      case SwissButtonStyle.danger:
        bg = AppTheme.surface;
        fg = AppTheme.primary;
        border = BorderSide(
          color: AppTheme.primary,
          width: AppTheme.borderWidth,
        );
        break;
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
        ],
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: fg,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );

    final buttonWidget = Container(
      width: width,
      decoration: BoxDecoration(
        color: onPressed == null ? AppTheme.border : bg,
        border: Border.fromBorderSide(border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          splashColor: Colors.black12,
          highlightColor: Colors.black.withValues(alpha: 0.05),
          child: Padding(
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Center(child: content),
          ),
        ),
      ),
    );

    return buttonWidget;
  }
}
