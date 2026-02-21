import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skoring/models/types/chart.dart';
import 'package:skoring/screens/walikelas/widgets/chart_widgets.dart';
import '../utils/chart_colors.dart';

/// Thin wrapper so GrafikScreen can use the same chart as HomeScreen.
/// Converts [ChartDataItem] → the Map format ChartWidgets.buildBarChart expects.
class BarChart extends StatelessWidget {
  final List<ChartDataItem> data;
  final String chartType;

  const BarChart({super.key, required this.data, required this.chartType});

  @override
  Widget build(BuildContext context) {
    final mapped = data
        .map((e) => {'label': e.label, 'value': e.value})
        .toList();

    final gradient = LinearGradient(
      colors: ChartColors.gradient(chartType),
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    );

    return ChartWidgets.buildBarChart(mapped, gradient);
  }
}