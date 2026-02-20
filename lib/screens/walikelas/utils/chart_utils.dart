class ChartUtils {
  static List<Map<String, dynamic>> aggregateChartData(
    List<Map<String, dynamic>> data,
    int selectedTab, {
    String dateField = 'created_at',
  }) {
    if (selectedTab == 0) {
      return _buildWeeklyData(data, dateField);
    } else {
      return _buildMonthlyData(data, dateField);
    }
  }

  static List<Map<String, dynamic>> _buildMonthlyData(
    List<Map<String, dynamic>> data,
    String dateField,
  ) {
    final int currentYear = DateTime.now().year;

    final Map<int, double> monthlyData = {
      for (int m = 1; m <= 12; m++) m: 0,
    };

    bool hasData = false;

    for (var item in data) {
      final rawDate = item[dateField];
      if (rawDate == null) continue;
      final DateTime date = DateTime.parse(rawDate.toString());
      if (date.year == currentYear) {
        monthlyData[date.month] = (monthlyData[date.month] ?? 0) + 1;
        hasData = true;
      }
    }

    if (!hasData) return [];

    return List.generate(12, (i) {
      final int month = i + 1;
      return {
        'label': getMonthName(month),
        'value': monthlyData[month]!,
      };
    });
  }

  static List<Map<String, dynamic>> _buildWeeklyData(
    List<Map<String, dynamic>> data,
    String dateField,
  ) {
    final DateTime now = DateTime.now();
    final int currentYear = now.year;
    final int currentMonth = now.month;
    final int daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;
    final int totalWeeks = ((daysInMonth) / 7).ceil();

    final Map<int, double> weeklyData = {
      for (int w = 1; w <= totalWeeks; w++) w: 0,
    };

    bool hasData = false;

    for (var item in data) {
      final rawDate = item[dateField];
      if (rawDate == null) continue;
      final DateTime date = DateTime.parse(rawDate.toString());
      if (date.year == currentYear && date.month == currentMonth) {
        final int weekNum = ((date.day - 1) / 7).floor() + 1;
        weeklyData[weekNum] = (weeklyData[weekNum] ?? 0) + 1;
        hasData = true;
      }
    }

    if (!hasData) return [];

    return List.generate(totalWeeks, (i) {
      final int week = i + 1;
      return {
        'label': 'Minggu $week',
        'value': weeklyData[week]!,
      };
    });
  }

  static String getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return months[month - 1];
  }
}