import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:skoring/config/api.dart';
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
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/kelas?nip=$walikelasId&id_kelas=$idKelas',
    );

    final response = await http.get(uri, headers: {'Accept': 'application/json'});

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
      if (jsonData['success']) {
        final List<dynamic> data = jsonData['data'];
        if (data.isNotEmpty) {
          return data.map((json) => Kelas.fromJson(json)).toList();
        }
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
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/siswa?nip=$walikelasId&id_kelas=$idKelas',
    );

    final response = await http.get(uri, headers: {'Accept': 'application/json'});

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
      if (jsonData['success']) {
        final List<dynamic> data = jsonData['data'];
        return data.map((json) => Student.fromJson(json)).toList();
      }
      throw Exception(jsonData['message'] ?? 'Gagal memuat data siswa');
    }
    throw Exception('Gagal mengambil data siswa (${response.statusCode})');
  }
}