import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skoring/config/api.dart';
import 'package:skoring/models/api/api_report.dart';
import 'package:skoring/widgets/faq.dart';

class LaporanDataService {
  static Future<Map<String, String?>> loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'walikelasId': prefs.getString('walikelas_id'),
      'idKelas': prefs.getString('id_kelas'),
    };
  }

  static Future<List<Kelas>> fetchKelas() async {
    final response = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/kelas'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success']) {
        final List<dynamic> data = jsonData['data'];
        return data.map((json) => Kelas.fromJson(json)).toList();
      }
      throw Exception(jsonData['message']);
    }
    throw Exception('Gagal mengambil data kelas: ${response.statusCode}');
  }

  static Future<List<Student>> fetchSiswa({
    required String walikelasId,
    required String idKelas,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/siswa?nip=$walikelasId&id_kelas=$idKelas',
    );
    final response = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
      if (jsonData['success']) {
        final List<dynamic> data = jsonData['data'];
        return data.map((json) => Student.fromJson(json, const [])).toList();
      }
      throw Exception(jsonData['message']);
    }
    throw Exception('Gagal mengambil data siswa: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> fetchAspekPenilaian() async {
    final response = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/aspekpenilaian'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success']) {
        final List<dynamic> data = jsonData['data'];
        final Map<String, dynamic> aspekMap = {};
        for (var item in data) {
          final key = item['id_aspekpenilaian']?.toString() ?? '';
          aspekMap[key] = item;
        }
        return aspekMap;
      }
      throw Exception(jsonData['message']);
    }
    throw Exception('Gagal mengambil aspek penilaian: ${response.statusCode}');
  }

  static Future<Map<String, FAQItem>> fetchFaqData() async {
    final aspekMap = await fetchAspekPenilaian();
    final Map<String, FAQItem> faqData = {};
    for (var entry in aspekMap.entries) {
      faqData[entry.key] = FAQItem.fromJson(entry.value);
    }
    return faqData;
  }

  static Future<List<StudentScore>> fetchStudentScores({
    required String nis,
    required String walikelasId,
    required String idKelas,
    required Map<String, dynamic> aspekPenilaianData,
  }) async {
    if (nis.isEmpty) return [];
    final List<StudentScore> scores = [];

    try {
      final penghargaanResponse = await http
          .get(Uri.parse(
            '${ApiConfig.baseUrl}/skoring_penghargaan?nis=$nis&nip=$walikelasId&id_kelas=$idKelas',
          ))
          .timeout(const Duration(seconds: 10));

      if (penghargaanResponse.statusCode == 200) {
        final jsonData = jsonDecode(penghargaanResponse.body);
        if (jsonData['penilaian']['data'].isNotEmpty) {
          final appreciationsResponse = await http
              .get(Uri.parse('${ApiConfig.baseUrl}/Penghargaan'))
              .timeout(const Duration(seconds: 10));

          if (appreciationsResponse.statusCode == 200) {
            final appreciationsData = jsonDecode(appreciationsResponse.body);
            if (appreciationsData['success']) {
              final List<dynamic> appreciations = appreciationsData['data'];
              final List<dynamic> studentEvaluations = jsonData['penilaian']['data']
                  .where((eval) => eval['nis'].toString() == nis)
                  .toList();

              for (var eval in studentEvaluations) {
                final aspek = aspekPenilaianData[eval['id_aspekpenilaian']?.toString()];
                if (aspek == null || aspek['jenis_poin']?.toString() != 'Apresiasi') continue;

                final appreciation = appreciations.firstWhere((a) {
                  if (eval['created_at'] == null || a['tanggal_penghargaan'] == null) return false;
                  try {
                    return DateTime.parse(a['tanggal_penghargaan']).isAtSameMomentAs(
                          DateTime.parse(eval['created_at'].substring(0, 10)),
                        ) ||
                        a['alasan'].toLowerCase().contains(aspek['uraian'].toLowerCase());
                  } catch (_) {
                    return false;
                  }
                }, orElse: () => null);

                if (appreciation != null) {
                  scores.add(StudentScore.fromPenghargaan(
                    appreciation,
                    aspek['indikator_poin'] ??
                        (appreciation['level_penghargaan'] == 'PH1' ? 10
                            : appreciation['level_penghargaan'] == 'PH2' ? 20 : 30),
                  ));
                }
              }
            }
          }
        }
      }

      final peringatanResponse = await http
          .get(Uri.parse(
            '${ApiConfig.baseUrl}/skoring_pelanggaran?nis=$nis&nip=$walikelasId&id_kelas=$idKelas',
          ))
          .timeout(const Duration(seconds: 10));

      if (peringatanResponse.statusCode == 200) {
        final jsonData = jsonDecode(peringatanResponse.body);
        if (jsonData['penilaian']['data'].isNotEmpty) {
          final violationsResponse = await http
              .get(Uri.parse('${ApiConfig.baseUrl}/peringatan'))
              .timeout(const Duration(seconds: 10));

          if (violationsResponse.statusCode == 200) {
            final violationsData = jsonDecode(violationsResponse.body);
            if (violationsData['success']) {
              final List<dynamic> violations = violationsData['data'];
              final List<dynamic> studentEvaluations = jsonData['penilaian']['data']
                  .where((eval) => eval['nis'].toString() == nis)
                  .toList();

              for (var eval in studentEvaluations) {
                final aspek = aspekPenilaianData[eval['id_aspekpenilaian']?.toString()];
                if (aspek == null || aspek['jenis_poin']?.toString() != 'Pelanggaran') continue;

                final violation = violations.firstWhere((v) {
                  if (eval['created_at'] == null || v['tanggal_sp'] == null) return false;
                  try {
                    return DateTime.parse(v['tanggal_sp']).isAtSameMomentAs(
                          DateTime.parse(eval['created_at'].substring(0, 10)),
                        ) ||
                        v['alasan'].toLowerCase().contains(aspek['uraian'].toLowerCase());
                  } catch (_) {
                    return false;
                  }
                }, orElse: () => null);

                if (violation != null) {
                  scores.add(StudentScore.fromPeringatan(
                    violation,
                    aspek['indikator_poin'] ??
                        (violation['level_sp'] == 'SP1' ? 5
                            : violation['level_sp'] == 'SP2' ? 10 : 20),
                  ));
                }
              }
            }
          }
        }
      }
    } catch (_) {}

    return scores;
  }
}