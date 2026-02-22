import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skoring/config/api_client.dart';
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
    final response = await ApiClient.get('kelas');
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success']) {
        return (jsonData['data'] as List<dynamic>)
            .map((j) => Kelas.fromJson(j))
            .toList();
      }
      throw Exception(jsonData['message']);
    }
    throw Exception('Gagal mengambil data kelas: ${response.statusCode}');
  }

  static Future<List<Student>> fetchSiswa({
    required String walikelasId,
    required String idKelas,
  }) async {
    final response = await ApiClient.get('siswa', params: {
      'nip': walikelasId,
      'id_kelas': idKelas,
    });
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
      if (jsonData['success']) {
        return (jsonData['data'] as List<dynamic>)
            .map((j) => Student.fromJson(j, const []))
            .toList();
      }
      throw Exception(jsonData['message']);
    }
    throw Exception('Gagal mengambil data siswa: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> fetchAspekPenilaian() async {
    final response = await ApiClient.get('aspekpenilaian');
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success']) {
        return {
          for (var item in jsonData['data'] as List<dynamic>)
            (item['id_aspekpenilaian']?.toString() ?? ''): item,
        };
      }
      throw Exception(jsonData['message']);
    }
    throw Exception('Gagal mengambil aspek penilaian: ${response.statusCode}');
  }

  static Future<Map<String, FAQItem>> fetchFaqData() async {
    final aspekMap = await fetchAspekPenilaian();
    return {
      for (var entry in aspekMap.entries)
        entry.key: FAQItem.fromJson(entry.value),
    };
  }

  static Future<List<StudentScore>> fetchStudentScores({
    required String nis,
    required String walikelasId,
    required String idKelas,
    required Map<String, dynamic> aspekPenilaianData,
  }) async {
    if (nis.isEmpty) return [];
    final params = {'nis': nis, 'nip': walikelasId, 'id_kelas': idKelas};
    final List<StudentScore> scores = [];

    try {
      // ── Apresiasi ───────────────────────────────────────────────────────────
      final apresiasiRes = await ApiClient.get('skoring_penghargaan', params: params);
      if (apresiasiRes.statusCode == 200) {
        final apresiasiJson = jsonDecode(apresiasiRes.body);
        if ((apresiasiJson['penilaian']['data'] as List).isNotEmpty) {
          final penghargaanRes = await ApiClient.get('Penghargaan');
          if (penghargaanRes.statusCode == 200) {
            final penghargaanData = jsonDecode(penghargaanRes.body);
            if (penghargaanData['success']) {
              final appreciations = penghargaanData['data'] as List<dynamic>;
              final evals = (apresiasiJson['penilaian']['data'] as List)
                  .where((e) => e['nis'].toString() == nis)
                  .toList();

              for (var eval in evals) {
                final aspek = aspekPenilaianData[eval['id_aspekpenilaian']?.toString()];
                if (aspek == null || aspek['jenis_poin']?.toString() != 'Apresiasi') continue;

                final appreciation = appreciations.firstWhere((a) {
                  if (eval['created_at'] == null || a['tanggal_penghargaan'] == null) return false;
                  try {
                    return DateTime.parse(a['tanggal_penghargaan']).isAtSameMomentAs(
                          DateTime.parse(eval['created_at'].substring(0, 10))) ||
                        a['alasan'].toLowerCase().contains(aspek['uraian'].toLowerCase());
                  } catch (_) { return false; }
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

      // ── Pelanggaran ─────────────────────────────────────────────────────────
      final pelanggaranRes = await ApiClient.get('skoring_pelanggaran', params: params);
      if (pelanggaranRes.statusCode == 200) {
        final pelanggaranJson = jsonDecode(pelanggaranRes.body);
        if ((pelanggaranJson['penilaian']['data'] as List).isNotEmpty) {
          final peringatanRes = await ApiClient.get('peringatan');
          if (peringatanRes.statusCode == 200) {
            final peringatanData = jsonDecode(peringatanRes.body);
            if (peringatanData['success']) {
              final violations = peringatanData['data'] as List<dynamic>;
              final evals = (pelanggaranJson['penilaian']['data'] as List)
                  .where((e) => e['nis'].toString() == nis)
                  .toList();

              for (var eval in evals) {
                final aspek = aspekPenilaianData[eval['id_aspekpenilaian']?.toString()];
                if (aspek == null || aspek['jenis_poin']?.toString() != 'Pelanggaran') continue;

                final violation = violations.firstWhere((v) {
                  if (eval['created_at'] == null || v['tanggal_sp'] == null) return false;
                  try {
                    return DateTime.parse(v['tanggal_sp']).isAtSameMomentAs(
                          DateTime.parse(eval['created_at'].substring(0, 10))) ||
                        v['alasan'].toLowerCase().contains(aspek['uraian'].toLowerCase());
                  } catch (_) { return false; }
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