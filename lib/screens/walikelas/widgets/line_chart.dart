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
    final accentLight = base.withOpacity(0.1);
    final total = data.fold(0.0, (s, i) => s + i.value);
    final avg = data.isNotEmpty ? total / data.length : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary chips
        Row(children: [
          _chip('Total', total.toInt().toString(), base, accentLight),
          const SizedBox(width: 8),
          _chip('Tertinggi', maxValue.toInt().toString(), base, accentLight),
          const SizedBox(width: 8),
          _chip('Rata-rata', avg.toStringAsFixed(1), base, accentLight),
        ]),
        const SizedBox(height: 16),

        SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Y-axis: show actual values with 1 decimal if they're < 1
              SizedBox(
                width: 40,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [1.0, 0.75, 0.5, 0.25, 0.0].map((frac) {
                    final val = safeMax * frac;
                    // Show decimal if all values are < 2 to avoid all "0"
                    final label = safeMax < 2
                        ? val.toStringAsFixed(1)
                        : val.toInt().toString();
                    return Text(label,
                        style: GoogleFonts.poppins(
                            fontSize: 9, color: ChartColors.textFaint));
                  }).toList(),
                ),
              ),
              const SizedBox(width: 6),
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

        // X-axis labels — spaced to avoid overlap when many points
        Padding(
          padding: const EdgeInsets.only(left: 46, top: 6),
          child: _xLabels(data),
        ),

        // X-axis bottom border
        Container(
          margin: const EdgeInsets.only(left: 46, top: 2),
          height: 1,
          color: const Color(0xFFE5E7EB),
        ),
      ],
    );
  }

  /// Skips labels when there are too many to fit (> 7), showing every other one.
  Widget _xLabels(List<ChartDataItem> data) {
    final skipEvery = data.length > 7 ? 2 : 1;
    return LayoutBuilder(builder: (context, constraints) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: data.asMap().entries.map((entry) {
          final show = entry.key % skipEvery == 0;
          return Text(
            show ? entry.value.label : '',
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: show ? ChartColors.textMuted : Colors.transparent,
              fontWeight: FontWeight.w600,
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _chip(String label, String value, Color color, Color bg) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: color.withOpacity(0.6),
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: color,
                      fontWeight: FontWeight.w700,
                      height: 1.0)),
            ],
          ),
        ),
      );
}