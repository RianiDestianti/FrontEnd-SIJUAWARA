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
        if (details.delta.dx > 5) {
          if (selectedTab > 0) {
            onTabChanged(selectedTab - 1);
            addLocalActivity(
              'Navigasi',
              'Tab Grafik',
              'Berpindah ke tab ${selectedTab == 0 ? 'Bulan' : 'Minggu'}',
            );
          }
        } else if (details.delta.dx < -5) {
          if (selectedTab < 1) {
            onTabChanged(selectedTab + 1);
            addLocalActivity(
              'Navigasi',
              'Tab Grafik',
              'Berpindah ke tab ${selectedTab == 0 ? 'Bulan' : 'Minggu'}',
            );
          }
        }
      },
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildChartButton('Minggu', selectedTab == 0, () => onTabChanged(0)),
            buildChartButton('Bulan', selectedTab == 1, () => onTabChanged(1)),
          ],
        ),
      ),
    );
  }

  static Widget buildChartButton(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: isActive ? const Color(0xFF1F2937) : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildBarChart(
    List<Map<String, dynamic>> data,
    Gradient gradient,
  ) {
    double maxValue = data.isNotEmpty
        ? data
            .map((e) => (e['value'] as double?) ?? 0.0)
            .reduce((a, b) => a > b ? a : b)
        : 1.0;

    return Container(
      height: 140,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 28,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${maxValue.toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(maxValue * 0.75).toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(maxValue * 0.5).toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(maxValue * 0.25).toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '0',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: data.map((item) {
                      double value = (item['value'] as double?) ?? 0.0;
                      double height = maxValue > 0 ? (value / maxValue) * 100 : 0;
                      return Container(
                        width: 20,
                        height: height,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 38),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: data.map((item) {
                    return Text(
                      (item['label'] as String?) ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}