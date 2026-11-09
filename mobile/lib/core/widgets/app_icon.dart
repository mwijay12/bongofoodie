import 'package:flutter/material.dart';
import '../icons/app_icon_key.dart';
import '../theme/app_tokens.dart';

/// A premium, theme-coloured replacement for an emoji. Icons are never below
/// 20dp, sit inline or in a tinted circle, and carry a semantics label.
class AppIcon extends StatelessWidget {
  const AppIcon({
    super.key,
    required this.iconKey,
    this.size = 20,
    this.color,
    this.tinted = false,
    this.semanticLabel,
  });

  final AppIconKey iconKey;
  final double size;
  final Color? color;
  final bool tinted;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    // Inherit the tab/list icon colour when the caller does not override it.
    final themeColor = color ??
        IconTheme.of(context).color ??
        Theme.of(context).colorScheme.primary;
    // Small emoji glyphs were hard to read; keep a 20dp floor.
    final iconSize = size < 20 ? 20.0 : size;
    final icon = Icon(iconKey.icon, size: iconSize, color: themeColor);
    final Widget body = tinted
        ? Container(
            width: iconSize + AppSpace.sm,
            height: iconSize + AppSpace.sm,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: icon,
          )
        : icon;
    return Semantics(
      label: semanticLabel ?? iconKey.label,
      child: body,
    );
  }
}
