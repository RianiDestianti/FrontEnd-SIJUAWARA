import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChartWidgets {
  static Widget buildSwipeableChartButtons(
    int selectedTab,
    Function(int) onTabChanged,
    Function(String, String, String) addLocalActivity,
  ) {
    return GestureDetector(
      onPanUpdate: (details) {
        if (details.delta.dx > 5 && selectedTab > 0) onTabChanged(selectedTab - 1);
        else if (details.delta.dx < -5 && selectedTab < 1) onTabChanged(selectedTab + 1);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabButton('Minggu', selectedTab == 0, () => onTabChanged(0)),
          const SizedBox(width: 6),
          _buildTabButton('Bulan', selectedTab == 1, () => onTabChanged(1)),
        ],
      ),
    );
  }

  static Widget _buildTabButton(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0083EE) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [BoxShadow(color: const Color(0xFF0083EE).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: isActive ? Colors.white : const Color(0xFF6B7280),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static Widget buildBarChart(
    List<Map<String, dynamic>> data,
    Gradient gradient,
  ) {
    if (data.isEmpty) return _buildEmptyChart();

    final double maxValue = data
        .map((e) => (e['value'] as double?) ?? 0.0)
        .reduce((a, b) => a > b ? a : b)
        .clamp(1.0, double.infinity);

    final double total = data.fold(0.0, (sum, e) => sum + ((e['value'] as double?) ?? 0.0));
    final double avg = total / data.length;
    final int maxIndex = data.indexWhere(
      (e) => ((e['value'] as double?) ?? 0.0) == maxValue,
    );

    // Detect accent color from gradient
    final bool isBlue = gradient.toString().contains('0xFF0083EE') ||
        gradient.toString().contains('61B8FF');
    final Color accentColor = isBlue ? const Color(0xFF0083EE) : const Color(0xFFFF6B6D);
    final Color accentLight = isBlue
        ? const Color(0xFF0083EE).withOpacity(0.1)
        : const Color(0xFFFF6B6D).withOpacity(0.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSummaryChip('Total', total.toInt().toString(), accentColor, accentLight),
            const SizedBox(width: 8),
            _buildSummaryChip('Tertinggi', maxValue.toInt().toString(), accentColor, accentLight),
            const SizedBox(width: 8),
            _buildSummaryChip('Rata-rata', avg.toStringAsFixed(1), accentColor, accentLight),
          ],
        ),
        const SizedBox(height: 16),

      
        SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: data.asMap().entries.map((entry) {
              final int i = entry.key;
              final Map<String, dynamic> item = entry.value;
              final double value = (item['value'] as double?) ?? 0.0;
              final double heightRatio = maxValue > 0 ? value / maxValue : 0;
              final bool isPeak = i == maxIndex && value > 0;
              final String label = (item['label'] as String?) ?? '';

              return _buildBar(
                label: label,
                value: value,
                heightRatio: heightRatio,
                isPeak: isPeak,
                gradient: gradient,
                accentColor: accentColor,
              );
            }).toList(),
          ),
        ),

        // X-axis line
        Container(
          margin: const EdgeInsets.only(top: 6),
          height: 1,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  static Widget _buildBar({
    required String label,
    required double value,
    required double heightRatio,
    required bool isPeak,
    required Gradient gradient,
    required Color accentColor,
  }) {
    final double barHeight = (heightRatio * 100).clamp(4.0, 100.0);
    final bool isEmpty = value == 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Value label above bar — always visible
        Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: isPeak
              ? BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Text(
            isEmpty ? '' : value.toInt().toString(),
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isPeak ? Colors.white : const Color(0xFF9CA3AF),
            ),
          ),
        ),

        // Bar body
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          width: isPeak ? 24 : 18,
          height: barHeight,
          decoration: BoxDecoration(
            gradient: isEmpty ? null : gradient,
            color: isEmpty ? const Color(0xFFF3F4F6) : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: isPeak && !isEmpty
                ? [BoxShadow(color: accentColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: isPeak ? accentColor : const Color(0xFF9CA3AF),
            fontWeight: isPeak ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  static Widget _buildSummaryChip(String label, String value, Color color, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: color.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildEmptyChart() {
    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'Belum ada data',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }


  static Widget buildChartButton(String text, bool isActive, VoidCallback onTap) {
    return _buildTabButton(text, isActive, onTap);
  }
}