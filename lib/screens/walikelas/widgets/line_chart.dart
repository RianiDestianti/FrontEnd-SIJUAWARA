import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skoring/models/types/chart.dart';
import '../utils/chart_colors.dart';
import 'chart_painters.dart';

class LineChart extends StatelessWidget {
  final List<ChartDataItem> data;
  final String chartType;

  const LineChart({super.key, required this.data, required this.chartType});

  @override
  Widget build(BuildContext context) {
    final maxValue = data.map((e) => e.value).reduce(math.max);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;
    final base = ChartColors.base(chartType);

    return SizedBox(
      height: 220,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _yAxis(safeMax),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomPaint(
                    painter: LineChartPainter(
                      data: data,
                      maxValue: safeMax,
                      lineColor: base,
                      fillColor: base.withOpacity(0.15),
                      pointColor: base,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _xLabels(),
        ],
      ),
    );
  }

  Widget _yAxis(double max) => SizedBox(
        width: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [1.0, 0.75, 0.5, 0.25, 0.0].map((frac) {
            return Text(
              (max * frac).toInt().toString(),
              style: GoogleFonts.poppins(fontSize: 10, color: ChartColors.textFaint),
            );
          }).toList(),
        ),
      );

  Widget _xLabels() => Row(
        children: [
          const SizedBox(width: 52),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: data.map((item) => Text(
                    item.label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: ChartColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  )).toList(),
            ),
          ),
        ],
      );
}