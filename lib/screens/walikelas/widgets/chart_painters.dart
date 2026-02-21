import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:skoring/models/types/chart.dart';

class PieChartPainter extends CustomPainter {
  final List<ChartDataItem> data;
  final double total;
  final List<Color> colors;
  final int? highlightIndex;

  const PieChartPainter({
    required this.data,
    required this.total,
    required this.colors,
    this.highlightIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2 * 0.82;
    double startAngle = -math.pi / 2;

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = total > 0 ? (data[i].value / total) * 2 * math.pi : 0.0;
      final color = colors[i % colors.length];
      final isHighlighted = highlightIndex == i;
      final radius = isHighlighted ? baseRadius * 1.08 : baseRadius;
      final rect = Rect.fromCircle(center: center, radius: radius);

      // Segment fill
      canvas.drawArc(rect, startAngle, sweepAngle, true,
          Paint()
            ..color = isHighlighted ? color : color.withOpacity(0.85)
            ..style = PaintingStyle.fill);

      // White divider stroke
      canvas.drawArc(rect, startAngle, sweepAngle, true,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = isHighlighted ? 3 : 2);

      startAngle += sweepAngle;
    }

    // Donut hole
    canvas.drawCircle(
      center,
      baseRadius * 0.5,
      Paint()..color = Colors.white..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant PieChartPainter old) =>
      old.data != data || old.total != total || old.highlightIndex != highlightIndex;
}

class LineChartPainter extends CustomPainter {
  final List<ChartDataItem> data;
  final double maxValue;
  final Color lineColor;
  final Color fillColor;
  final Color pointColor;

  const LineChartPainter({
    required this.data,
    required this.maxValue,
    required this.lineColor,
    required this.fillColor,
    required this.pointColor,
  });

  static const double _topPad = 16;
  static const double _botPad = 8;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final chartH = size.height - _topPad - _botPad;
    final n = data.length;
    final stepX = n > 1 ? size.width / (n - 1) : size.width / 2;
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    // Grid lines
    for (int i = 0; i <= 4; i++) {
      final y = _topPad + (chartH / 4 * i);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = const Color(0xFFE5E7EB)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    final pts = <Offset>[
      for (int i = 0; i < n; i++)
        Offset(
          n > 1 ? stepX * i : size.width / 2,
          _topPad + chartH - (data[i].value / safeMax * chartH),
        ),
    ];

    // Gradient fill under line
    final fillPath = Path()
      ..moveTo(pts.first.dx, size.height - _botPad);
    for (final p in pts) fillPath.lineTo(p.dx, p.dy);
    fillPath
      ..lineTo(pts.last.dx, size.height - _botPad)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          colors: [fillColor, Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill,
    );

    // Smooth line using cubic bezier
    if (pts.length > 1) {
      final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (int i = 0; i < pts.length - 1; i++) {
        final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
        final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
        linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i + 1].dx, pts[i + 1].dy);
      }
      canvas.drawPath(
        linePath,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Points + halos
    for (final p in pts) {
      canvas.drawCircle(p, 8, Paint()..color = pointColor.withOpacity(0.15)..style = PaintingStyle.fill);
      canvas.drawCircle(p, 4, Paint()..color = Colors.white..style = PaintingStyle.fill);
      canvas.drawCircle(p, 4, Paint()..color = pointColor..style = PaintingStyle.stroke..strokeWidth = 2.5);
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter old) =>
      old.data != data || old.maxValue != maxValue;
}