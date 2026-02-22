import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skoring/config/api_client.dart';
import 'package:skoring/models/types/point.dart';

class PointService {
  static Future<Point?> submitPoint({
    required String type,
    required String studentName,
    required String nis,
    required String idPenilaian,
    required String idAspekPenilaian,
    required String date,
    required String category,
    required String description,
    required int points,
    required BuildContext context,
  }) async {
    if (idPenilaian.isEmpty || nis.isEmpty || idAspekPenilaian.isEmpty ||
        date.isEmpty || category.isEmpty) {
      if (context.mounted) PointSnackBar.error(context, 'Mohon lengkapi semua field yang diperlukan');
      return null;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final nip = prefs.getString('walikelas_id') ?? '';
      final idKelas = prefs.getString('id_kelas') ?? '';

      if (nip.isEmpty || idKelas.isEmpty) {
        if (context.mounted) PointSnackBar.error(context, 'Data guru tidak lengkap. Silakan login ulang.');
        return null;
      }

      final endpoint = type == 'Apresiasi'
          ? 'skoring_penghargaan'
          : 'skoring_pelanggaran';

      final response = await ApiClient.postJson(endpoint,
        params: {'nip': nip, 'id_kelas': idKelas},
        body: {
          'id_penilaian': idPenilaian,
          'nis': nis,
          'id_aspekpenilaian': idAspekPenilaian,
          'nip_walikelas': nip,
        },
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true ||
            (responseData['message']?.toString().contains('berhasil') ?? false)) {
          if (context.mounted) {
            PointSnackBar.success(context, 'Poin $type berhasil ditambahkan untuk $studentName');
          }
          return Point(
            type: type, studentName: studentName, nis: nis, className: '',
            date: date, description: description, category: category,
            points: points, idPenilaian: idPenilaian,
          );
        } else {
          if (context.mounted) PointSnackBar.error(context, responseData['message'] ?? 'Gagal menambahkan poin');
          return null;
        }
      } else {
        final errorMsg = _parseErrorMessage(response.body, response.statusCode);
        if (context.mounted) PointSnackBar.error(context, errorMsg);
        return null;
      }
    } catch (e) {
      if (context.mounted) PointSnackBar.error(context, 'Terjadi kesalahan: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAspekPenilaian() async {
    final prefs = await SharedPreferences.getInstance();
    final nip = prefs.getString('walikelas_id') ?? '';
    final idKelas = prefs.getString('id_kelas') ?? '';

    if (nip.isEmpty || idKelas.isEmpty) {
      throw Exception('Data guru tidak lengkap. Silakan login ulang.');
    }

    final response = await ApiClient.get('aspekpenilaian', params: {
      'nip': nip,
      'id_kelas': idKelas,
    });

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success']) return List<Map<String, dynamic>>.from(jsonData['data']);
      throw Exception(jsonData['message']);
    }
    throw Exception('Gagal mengambil data aspek penilaian');
  }

  static String _parseErrorMessage(String body, int statusCode) {
    try {
      final errorData = jsonDecode(body);
      return errorData['message'] ?? 'Gagal menghubungi server: $statusCode';
    } catch (_) {
      return 'Gagal menghubungi server: $statusCode';
    }
  }
}

class PointSnackBar {
  static void error(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(message,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500))),
      ]),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  static void success(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(message,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500))),
      ]),
      backgroundColor: const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }
}