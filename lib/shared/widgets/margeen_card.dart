import 'package:flutter/material.dart';

import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_spacing.dart';

class MargeenCard extends StatelessWidget {
  const MargeenCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final decoration = AppDecorations.card(context: context, color: color);

    final content = Container(
      decoration: decoration,
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
        highlightColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.04),
        child: content,
      ),
    );
  }
}
