class ChartUtils {
  static List<Map<String, dynamic>> aggregateChartData(
    List<Map<String, dynamic>> data,
    int selectedTab, {
    String dateField = 'created_at',
  }) {
    Map<String, double> weeklyData = {};
    Map<String, double> monthlyData = {};

    for (var item in data) {
      final rawDate = item[dateField];
      if (rawDate == null) continue;
      DateTime date = DateTime.parse(rawDate.toString());
      String weekKey =
          '${date.year}-W${((date.day + 6) / 7).ceil().toString().padLeft(2, '0')}';
      String monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

      weeklyData[weekKey] = (weeklyData[weekKey] ?? 0) + 1;
      monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + 1;
    }

    if (selectedTab == 0) {
      final weeklyEntries =
          weeklyData.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
      return weeklyEntries
          .map((e) => {'label': e.key.split('-W')[1], 'value': e.value})
          .toList();
    }

    final monthlyEntries =
        monthlyData.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return monthlyEntries
        .map(
          (e) => {
            'label': getMonthName(int.parse(e.key.split('-')[1])),
            'value': e.value,
          },
        )
        .toList();
  }

  static String getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return months[month - 1];
  }
}