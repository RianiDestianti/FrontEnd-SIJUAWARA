import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skoring/config/api.dart';
import 'package:skoring/models/types/chart.dart';
import 'package:skoring/screens/walikelas/utils/chart_utils.dart';

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
    final primaryEndpoint =
        isApresiasi ? 'skoring_penghargaan' : 'skoring_pelanggaran';
    final fallbackEndpoint = isApresiasi ? null : 'skoring_2pelanggaran';

    Future<http.Response> doRequest(String endpoint) => http.get(
          Uri.parse(
            '${ApiConfig.baseUrl}/$endpoint'
            '?nip=${creds.nipWalikelas}&id_kelas=${creds.teacherClassId}',
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

    // Filter to only students in this class
    final filtered = rawList
        .where((item) => siswaList.any(
              (s) =>
                  s['nis'].toString() == item['nis'].toString() &&
                  s['id_kelas'].toString() == creds.teacherClassId,
            ))
        .map((e) => e as Map<String, dynamic>)
        .toList();

    // Reuse ChartUtils aggregation — same logic as HomeScreen
    final aggregated = ChartUtils.aggregateChartData(filtered, selectedPeriod);

    return aggregated
        .map((e) => ChartDataItem(
              label: e['label'] as String,
              value: (e['value'] as double?) ?? 0.0,
              detail: 'Total: ${((e['value'] as double?) ?? 0.0).toInt()} kasus',
            ))
        .toList();
  }
}