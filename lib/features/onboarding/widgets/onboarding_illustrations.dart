import 'dart:math' as math;
import 'dart:ui' show ParagraphBuilder, ParagraphConstraints, ParagraphStyle;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum OnboardingIllustrationType { invoices, profit, business }

class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({
    super.key,
    required this.type,
    this.size = 280,
  });

  final OnboardingIllustrationType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _OnboardingIllustrationPainter(
          type: type,
          brightness: Theme.of(context).brightness,
        ),
      ),
    );
  }
}

class _OnboardingIllustrationPainter extends CustomPainter {
  _OnboardingIllustrationPainter({
    required this.type,
    required this.brightness,
  });

  final OnboardingIllustrationType type;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    _drawAmbientGlow(canvas, center, size);

    switch (type) {
      case OnboardingIllustrationType.invoices:
        _drawInvoices(canvas, size);
      case OnboardingIllustrationType.profit:
        _drawProfit(canvas, size);
      case OnboardingIllustrationType.business:
        _drawBusiness(canvas, size);
    }
  }

  void _drawAmbientGlow(Canvas canvas, Offset center, Size size) {
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: brightness == Brightness.dark ? 0.22 : 0.14),
          AppColors.primary.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.48));

    canvas.drawCircle(center, size.width * 0.42, glow);
  }

  void _drawInvoices(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    _drawFloatingOrb(canvas, Offset(cx - w * 0.28, cy - h * 0.22), 18,
        AppColors.accent.withValues(alpha: 0.35));
    _drawFloatingOrb(canvas, Offset(cx + w * 0.3, cy + h * 0.18), 12,
        AppColors.secondary.withValues(alpha: 0.3));

    final backRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx + 28, cy - 12),
        width: w * 0.42,
        height: h * 0.52,
      ),
      const Radius.circular(18),
    );
    canvas.drawRRect(
      backRect,
      Paint()..color = _surfaceVariant.withValues(alpha: 0.7),
    );

    final frontRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx - 18, cy + 8),
        width: w * 0.46,
        height: h * 0.56,
      ),
      const Radius.circular(20),
    );
    canvas.drawRRect(
      frontRect,
      Paint()
        ..color = _surface
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      frontRect,
      Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final docLeft = cx - w * 0.46 / 2 - 18;
    final docTop = cy + 8 - h * 0.56 / 2;

    final headerPaint = Paint()..color = AppColors.primary;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(docLeft, docTop, w * 0.46, 42),
        const Radius.circular(20),
      ),
      headerPaint,
    );

    final linePaint = Paint()
      ..color = _outline.withValues(alpha: 0.55)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 4; i++) {
      final y = docTop + 58 + i * 22.0;
      final lineW = w * (0.28 - i * 0.03);
      canvas.drawLine(
        Offset(docLeft + 20, y),
        Offset(docLeft + 20 + lineW, y),
        linePaint,
      );
    }

    final checkCircle = Offset(docLeft + w * 0.46 - 36, docTop + h * 0.56 - 44);
    canvas.drawCircle(checkCircle, 18, Paint()..color = AppColors.profit);
    _drawCheck(canvas, checkCircle, Colors.white, 10);

    final penPath = Path()
      ..moveTo(cx + w * 0.18, cy + h * 0.12)
      ..lineTo(cx + w * 0.34, cy - h * 0.04)
      ..lineTo(cx + w * 0.3, cy - h * 0.08)
      ..lineTo(cx + w * 0.14, cy + h * 0.08)
      ..close();
    canvas.drawPath(
      penPath,
      Paint()
        ..color = AppColors.secondary
        ..style = PaintingStyle.fill,
    );
  }

  void _drawProfit(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    _drawFloatingOrb(canvas, Offset(cx - w * 0.32, cy + h * 0.2), 14,
        AppColors.profit.withValues(alpha: 0.35));

    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 10), width: w * 0.72, height: h * 0.48),
      const Radius.circular(22),
    );
    canvas.drawRRect(cardRect, Paint()..color = _surface);
    canvas.drawRRect(
      cardRect,
      Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final chartLeft = cx - w * 0.28;
    final chartBottom = cy + h * 0.18;
    final barWidth = w * 0.09;
    final heights = [0.22, 0.34, 0.28, 0.48, 0.62];
    final colors = [
      AppColors.primary.withValues(alpha: 0.45),
      AppColors.primary.withValues(alpha: 0.55),
      AppColors.primary.withValues(alpha: 0.65),
      AppColors.primaryLight,
      AppColors.profit,
    ];

    for (var i = 0; i < heights.length; i++) {
      final barH = h * heights[i];
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          chartLeft + i * (barWidth + 10),
          chartBottom - barH,
          barWidth,
          barH,
        ),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, Paint()..color = colors[i]);
    }

    final trendPath = Path();
    final points = [
      Offset(chartLeft + 8, chartBottom - h * 0.18),
      Offset(chartLeft + w * 0.16, chartBottom - h * 0.3),
      Offset(chartLeft + w * 0.28, chartBottom - h * 0.24),
      Offset(chartLeft + w * 0.4, chartBottom - h * 0.42),
      Offset(chartLeft + w * 0.52, chartBottom - h * 0.58),
    ];
    trendPath.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cp = Offset((prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
      trendPath.quadraticBezierTo(prev.dx, prev.dy, cp.dx, cp.dy);
      if (i == points.length - 1) {
        trendPath.lineTo(curr.dx, curr.dy);
      }
    }

    canvas.drawPath(
      trendPath,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    for (final point in points) {
      canvas.drawCircle(point, 5, Paint()..color = AppColors.accent);
      canvas.drawCircle(point, 2.5, Paint()..color = Colors.white);
    }

    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx + w * 0.22, cy - h * 0.18),
        width: 88,
        height: 36,
      ),
      const Radius.circular(18),
    );
    canvas.drawRRect(badgeRect, Paint()..color = AppColors.profit);
    _drawText(canvas, '+24%', Offset(cx + w * 0.22, cy - h * 0.18), 14, Colors.white,
        FontWeight.w700);
  }

  void _drawBusiness(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    _drawFloatingOrb(canvas, Offset(cx + w * 0.3, cy - h * 0.24), 16,
        AppColors.secondary.withValues(alpha: 0.3));

    final hubCenter = Offset(cx, cy);
    canvas.drawCircle(
      hubCenter,
      38,
      Paint()..color = AppColors.primary,
    );
    canvas.drawCircle(
      hubCenter,
      30,
      Paint()..color = Colors.white.withValues(alpha: 0.15),
    );
    _drawIconPeople(canvas, hubCenter, 22, Colors.white);

    final nodes = [
      (Offset(cx - w * 0.3, cy - h * 0.2), IconsStyle.box, AppColors.secondary),
      (Offset(cx + w * 0.3, cy - h * 0.16), IconsStyle.person, AppColors.accent),
      (Offset(cx - w * 0.28, cy + h * 0.22), IconsStyle.receipt, AppColors.primaryLight),
      (Offset(cx + w * 0.28, cy + h * 0.24), IconsStyle.chart, AppColors.profit),
    ];

    for (final (offset, icon, color) in nodes) {
      _drawConnector(canvas, hubCenter, offset);
      _drawNode(canvas, offset, color, icon);
    }
  }

  void _drawConnector(Canvas canvas, Offset from, Offset to) {
    final path = Path();
    final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
    final ctrl = Offset(mid.dx, mid.dy - 12);

    path.moveTo(from.dx, from.dy);
    path.quadraticBezierTo(ctrl.dx, ctrl.dy, to.dx, to.dy);

    canvas.drawPath(
      path,
      Paint()
        ..color = _outline.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawNode(Canvas canvas, Offset center, Color color, IconsStyle icon) {
    canvas.drawCircle(center, 30, Paint()..color = _surface);
    canvas.drawCircle(
      center,
      30,
      Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      center,
      22,
      Paint()..color = color.withValues(alpha: 0.15),
    );

    switch (icon) {
      case IconsStyle.box:
        _drawMiniBox(canvas, center, color);
      case IconsStyle.person:
        _drawIconPeople(canvas, center, 16, color);
      case IconsStyle.receipt:
        _drawMiniReceipt(canvas, center, color);
      case IconsStyle.chart:
        _drawMiniChart(canvas, center, color);
    }
  }

  void _drawMiniBox(Canvas canvas, Offset c, Color color) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: 20, height: 18),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, Paint()..color = color);
    canvas.drawLine(
      Offset(c.dx - 6, c.dy - 2),
      Offset(c.dx + 6, c.dy - 2),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 2,
    );
  }

  void _drawMiniReceipt(Canvas canvas, Offset c, Color color) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: 16, height: 22),
      const Radius.circular(3),
    );
    canvas.drawRRect(rect, Paint()..color = color);
    for (var i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(c.dx - 5, c.dy - 4 + i * 5),
        Offset(c.dx + 5, c.dy - 4 + i * 5),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.75)
          ..strokeWidth = 1.5,
      );
    }
  }

  void _drawMiniChart(Canvas canvas, Offset c, Color color) {
    final base = c.dy + 8;
    final bars = [6.0, 10.0, 8.0, 14.0];
    for (var i = 0; i < bars.length; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(c.dx - 10 + i * 5.5, base - bars[i], 4, bars[i]),
          const Radius.circular(2),
        ),
        Paint()..color = color,
      );
    }
  }

  void _drawIconPeople(Canvas canvas, Offset c, double r, Color color) {
    canvas.drawCircle(Offset(c.dx, c.dy - r * 0.35), r * 0.35, Paint()..color = color);
    final body = Path()
      ..addArc(
        Rect.fromCenter(center: Offset(c.dx, c.dy + r * 0.55), width: r * 1.1, height: r * 0.9),
        math.pi,
        math.pi,
      );
    canvas.drawPath(body, Paint()..color = color);
  }

  void _drawCheck(Canvas canvas, Offset c, Color color, double size) {
    final path = Path()
      ..moveTo(c.dx - size * 0.4, c.dy)
      ..lineTo(c.dx - size * 0.05, c.dy + size * 0.35)
      ..lineTo(c.dx + size * 0.45, c.dy - size * 0.35);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawFloatingOrb(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(center, radius, Paint()..color = color);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize,
    Color color,
    FontWeight weight,
  ) {
    final builder = ParagraphBuilder(
      ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: fontSize,
        fontWeight: weight,
      ),
    )..addText(text);

    final paragraph = builder.build()
      ..layout(ParagraphConstraints(width: 120));

    canvas.drawParagraph(
      paragraph,
      Offset(center.dx - paragraph.maxIntrinsicWidth / 2, center.dy - fontSize / 2 - 2),
    );
  }

  Color get _surface =>
      brightness == Brightness.dark ? AppColors.darkSurface : AppColors.lightSurface;

  Color get _surfaceVariant => brightness == Brightness.dark
      ? AppColors.darkSurfaceVariant
      : AppColors.lightSurfaceVariant;

  Color get _outline => brightness == Brightness.dark
      ? const Color(0xFF2A3447)
      : const Color(0xFFE2E8F0);

  @override
  bool shouldRepaint(covariant _OnboardingIllustrationPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.brightness != brightness;
  }
}

enum IconsStyle { box, person, receipt, chart }
