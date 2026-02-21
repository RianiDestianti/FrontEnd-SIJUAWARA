import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skoring/models/types/chart.dart';
import '../utils/chart_colors.dart';
import 'chart_painters.dart';

class PieChart extends StatelessWidget {
  final List<ChartDataItem> data;
  final String chartType;

  const PieChart({super.key, required this.data, required this.chartType});

  @override
  Widget build(BuildContext context) {
    final total = data.fold(0.0, (s, i) => s + i.value);
    final colors = ChartColors.pieColors(chartType);

    return SizedBox(
      height: 250,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: CustomPaint(
              size: const Size(150, 150),
              painter: PieChartPainter(data: data, total: total, colors: colors),
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: data.asMap().entries.map((entry) {
                final pct = total > 0 ? (entry.value.value / total) * 100 : 0.0;
                final color = colors[entry.key % colors.length];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.value.label,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ChartColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${pct.toInt()}%',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: ChartColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}