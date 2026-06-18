import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum AppLoadingSize { small, medium, large }

enum AppLoadingColor { primary, onPrimary, adaptive }

/// Indicador de carga circular animado, consistente en toda la app.
class AppLoadingIndicator extends StatefulWidget {
  const AppLoadingIndicator({
    super.key,
    this.size = AppLoadingSize.medium,
    this.color = AppLoadingColor.adaptive,
  });

  const AppLoadingIndicator.small({
    super.key,
    this.color = AppLoadingColor.adaptive,
  }) : size = AppLoadingSize.small;

  const AppLoadingIndicator.large({
    super.key,
    this.color = AppLoadingColor.adaptive,
  }) : size = AppLoadingSize.large;

  final AppLoadingSize size;
  final AppLoadingColor color;

  static double dimensionFor(AppLoadingSize size) => switch (size) {
        AppLoadingSize.small => 22,
        AppLoadingSize.medium => 36,
        AppLoadingSize.large => 52,
      };

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _resolveColor(BuildContext context) {
    return switch (widget.color) {
      AppLoadingColor.primary => AppColors.primary,
      AppLoadingColor.onPrimary => Colors.white,
      AppLoadingColor.adaptive => Theme.of(context).colorScheme.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final dimension = AppLoadingIndicator.dimensionFor(widget.size);
    final color = _resolveColor(context);
    final strokeWidth = switch (widget.size) {
      AppLoadingSize.small => 2.0,
      AppLoadingSize.medium => 2.5,
      AppLoadingSize.large => 3.0,
    };

    return SizedBox(
      width: dimension,
      height: dimension,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _AppLoaderPainter(
              progress: _controller.value,
              color: color,
              strokeWidth: strokeWidth,
            ),
          );
        },
      ),
    );
  }
}

/// Pantalla o sección centrada con el indicador global.
class AppLoadingPage extends StatelessWidget {
  const AppLoadingPage({
    super.key,
    this.size = AppLoadingSize.large,
    this.color = AppLoadingColor.adaptive,
  });

  final AppLoadingSize size;
  final AppLoadingColor color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppLoadingIndicator(
        size: size,
        color: color,
      ),
    );
  }
}

class _AppLoaderPainter extends CustomPainter {
  _AppLoaderPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;

    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final arcPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: 0.15),
          color.withValues(alpha: 0.95),
          color.withValues(alpha: 0.15),
        ],
        stops: const [0, 0.5, 1],
        transform: GradientRotation(progress * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      progress * 2 * math.pi,
      math.pi * 1.35,
      false,
      arcPaint,
    );

    for (var i = 0; i < 3; i++) {
      final angle = progress * 2 * math.pi + i * (2 * math.pi / 3);
      final dotCenter = Offset(
        center.dx + math.cos(angle) * (radius - 1),
        center.dy + math.sin(angle) * (radius - 1),
      );
      final dotScale = 0.6 + 0.4 * ((math.sin(angle + progress * 4) + 1) / 2);
      final dotRadius = switch (strokeWidth) {
        <= 2 => 2.0,
        _ => 2.5,
      };

      canvas.drawCircle(
        dotCenter,
        dotRadius * dotScale,
        Paint()..color = color.withValues(alpha: 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AppLoaderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
