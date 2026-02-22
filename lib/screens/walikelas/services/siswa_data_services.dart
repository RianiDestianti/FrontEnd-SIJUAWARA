import 'dart:convert';
import 'package:skoring/config/api_client.dart';
import 'package:skoring/models/api/api_student.dart';
import 'package:skoring/models/api/api_class.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SiswaDataService {
  static Future<Map<String, String?>> loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'walikelasId': prefs.getString('walikelas_id'),
      'idKelas': prefs.getString('id_kelas'),
    };
  }

  static Future<List<Kelas>> fetchKelas({
    required String walikelasId,
    required String idKelas,
  }) async {
    final response = await ApiClient.get('kelas', params: {
      'nip': walikelasId,
      'id_kelas': idKelas,
    });

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
      if (jsonData['success']) {
        final List<dynamic> data = jsonData['data'];
        if (data.isNotEmpty) return data.map((j) => Kelas.fromJson(j)).toList();
        throw Exception('Tidak ada data kelas ditemukan');
      }
      throw Exception(jsonData['message'] ?? 'Gagal memuat kelas');
    }
    throw Exception('Gagal mengambil data kelas (${response.statusCode})');
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
            .map((j) => Student.fromJson(j))
            .toList();
      }
      throw Exception(jsonData['message'] ?? 'Gagal memuat data siswa');
    }
    throw Exception('Gagal mengambil data siswa (${response.statusCode})');
  }
}