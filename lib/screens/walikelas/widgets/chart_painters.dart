import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:skoring/models/types/chart.dart';

class PieChartPainter extends CustomPainter {
  final List<ChartDataItem> data;
  final double total;
  final List<Color> colors;

  const PieChartPainter({
    required this.data,
    required this.total,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;
    double startAngle = -math.pi / 2;

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = total > 0 ? (data[i].value / total) * 2 * math.pi : 0.0;
      final color = colors[i % colors.length];
      final rect = Rect.fromCircle(center: center, radius: radius);

      canvas.drawArc(rect, startAngle, sweepAngle, true,
          Paint()..color = color..style = PaintingStyle.fill);

      canvas.drawArc(rect, startAngle, sweepAngle, true,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);

      startAngle += sweepAngle;
    }

    canvas.drawCircle(center, radius * 0.4,
        Paint()..color = Colors.white..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant PieChartPainter old) =>
      old.data != data || old.total != total;
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

  static const double _topPad = 10;
  static const double _botPad = 20;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final chartH = size.height - _topPad - _botPad;
    final n = data.length;
    final stepX = n > 1 ? size.width / (n - 1) : size.width;
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

  
    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = _topPad + (chartH / 4 * i);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }


    final pts = <Offset>[
      for (int i = 0; i < n; i++)
        Offset(stepX * i, _topPad + chartH - (data[i].value / safeMax * chartH)),
    ];


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


    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) linePath.lineTo(p.dx, p.dy);

    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    for (final p in pts) {
      canvas.drawCircle(p, 7,
          Paint()..color = pointColor.withOpacity(0.2)..style = PaintingStyle.fill);
      canvas.drawCircle(p, 4,
          Paint()..color = pointColor..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter old) =>
      old.data != data || old.maxValue != maxValue;
}