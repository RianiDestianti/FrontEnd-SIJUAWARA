import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skoring/models/types/chart.dart';
import '../utils/chart_colors.dart';

class BarChart extends StatelessWidget {
  final List<ChartDataItem> data;
  final String chartType;

  const BarChart({super.key, required this.data, required this.chartType});

  @override
  Widget build(BuildContext context) {
    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final colors = ChartColors.gradient(chartType);

    return SizedBox(
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _yAxis(maxValue),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: data.map((item) {
                      final h = (item.value / maxValue) * 150;
                      return Container(
                        width: 32,
                        height: h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: colors,
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }).toList(),
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

  Widget _yAxis(double maxValue) {
    return SizedBox(
      width: 40,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [1.0, 0.75, 0.5, 0.25, 0.0].map((frac) {
          return Text(
            (maxValue * frac).toInt().toString(),
            style: GoogleFonts.poppins(fontSize: 10, color: ChartColors.textFaint),
          );
        }).toList(),
      ),
    );
  }

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