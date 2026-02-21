import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skoring/config/api.dart';
import 'package:skoring/models/types/chart.dart';

class ChartCredentials {
  final String teacherClassId;
  final String nipWalikelas;

  const ChartCredentials({
    required this.teacherClassId,
    required this.nipWalikelas,
  });

  bool get isValid => teacherClassId.isNotEmpty && nipWalikelas.isNotEmpty;
}

class ChartService {
  static Future<ChartCredentials> loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return ChartCredentials(
      teacherClassId: prefs.getString('id_kelas') ?? '',
      nipWalikelas: prefs.getString('walikelas_id') ?? '',
    );
  }

  static Future<List<ChartDataItem>> fetchChartData({
    required String chartType,
    required int selectedPeriod,
    required ChartCredentials creds,
  }) async {
    final isApresiasi = chartType == 'apresiasi';
    final primaryEndpoint = isApresiasi ? 'skoring_penghargaan' : 'skoring_pelanggaran';
    final fallbackEndpoint = isApresiasi ? null : 'skoring_2pelanggaran';

    Future<http.Response> doRequest(String endpoint) => http.get(
          Uri.parse(
            '${ApiConfig.baseUrl}/$endpoint?nip=${creds.nipWalikelas}&id_kelas=${creds.teacherClassId}',
          ),
          headers: {'Accept': 'application/json'},
        );

    http.Response response = await doRequest(primaryEndpoint);
    if (response.statusCode != 200 && fallbackEndpoint != null) {
      final retry = await doRequest(fallbackEndpoint);
      if (retry.statusCode == 200) response = retry;
    }

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil data (${response.statusCode})');
    }

    final jsonData = jsonDecode(response.body);
    final rawList = jsonData['penilaian']?['data'] as List<dynamic>? ?? [];
    final siswaList = (jsonData['siswa'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();

    if (rawList.isEmpty) {
      throw Exception(jsonData['message'] ?? 'Gagal memuat data');
    }

    final filtered = rawList.where((item) => siswaList.any(
          (s) =>
              s['nis'].toString() == item['nis'].toString() &&
              s['id_kelas'].toString() == creds.teacherClassId,
        ));

    final Map<String, double> weekly = {};
    final Map<String, double> monthly = {};
    final Map<String, double> yearly = {};

    for (final item in filtered) {
      final raw = (item as Map<String, dynamic>)['created_at'];
      if (raw == null) continue;
      final date = DateTime.tryParse(raw.toString());
      if (date == null) continue;

      final weekKey = '${date.year}-W${((date.day + 6) / 7).ceil().toString().padLeft(2, '0')}';
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final yearKey = date.year.toString();

      weekly[weekKey] = (weekly[weekKey] ?? 0) + 1;
      monthly[monthKey] = (monthly[monthKey] ?? 0) + 1;
      yearly[yearKey] = (yearly[yearKey] ?? 0) + 1;
    }

    return _buildChartItems(selectedPeriod, weekly, monthly, yearly);
  }

  static List<ChartDataItem> _buildChartItems(
    int period,
    Map<String, double> weekly,
    Map<String, double> monthly,
    Map<String, double> yearly,
  ) {
    switch (period) {
      case 0:
        final sorted = weekly.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
        return sorted.map((e) => ChartDataItem(
              value: e.value,
              label: e.key.split('-W')[1],
              detail: 'Total: ${e.value.toInt()} kasus',
            )).toList();
      case 1:
        final sorted = monthly.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
        return sorted.map((e) => ChartDataItem(
              value: e.value,
              label: _monthName(int.parse(e.key.split('-')[1])),
              detail: 'Total: ${e.value.toInt()} kasus',
            )).toList();
      default:
        final sorted = yearly.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
        return sorted.map((e) => ChartDataItem(
              value: e.value,
              label: e.key,
              detail: 'Total: ${e.value.toInt()} kasus',
            )).toList();
    }
  }

  static String _monthName(int month) {
    const names = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return names[month - 1];
  }
}