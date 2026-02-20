import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:skoring/config/api.dart';
import 'package:skoring/models/types/student.dart';
import 'package:skoring/models/api/api_activity.dart';

class WalikelasDataService {
  static Future<Map<String, dynamic>> fetchAllData({
    required String walikelasId,
    required String teacherClassId,
  }) async {
    try {
      // Fetch kelas data
      final kelasResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/kelas'),
      );
      
      Map<String, String> kelasMap = {};
      Map<String, String> jurusanMap = {};
      List<Map<String, dynamic>> kelasData = [];
      
      if (kelasResponse.statusCode == 200) {
        final kelasJson = jsonDecode(kelasResponse.body);
        kelasData = List<Map<String, dynamic>>.from(kelasJson['data']);
        kelasMap = {
          for (var kelas in kelasData)
            kelas['id_kelas'].toString(): kelas['nama_kelas'].toString(),
        };
        jurusanMap = {
          for (var kelas in kelasData)
            kelas['id_kelas'].toString(): kelas['jurusan'].toString(),
        };
      }

      List<Student> siswaTerbaik = [];
      List<Student> siswaBerat = [];
      
      if (walikelasId.isNotEmpty && teacherClassId.isNotEmpty) {
        final siswaResponse = await http.get(
          Uri.parse(
            '${ApiConfig.baseUrl}/siswa?nip=$walikelasId&id_kelas=$teacherClassId',
          ),
        );
        
        if (siswaResponse.statusCode == 200) {
          final siswaJson = jsonDecode(siswaResponse.body);
          final siswaData = List<Map<String, dynamic>>.from(
            siswaJson['data'] ?? [],
          );

          final classStudents = siswaData.map((siswa) {
            final idKelas = siswa['id_kelas']?.toString() ?? '';
            final poin =
                int.tryParse(siswa['poin_total']?.toString() ?? '') ?? 0;
            final spLevel = _resolveSpLevel(
              poin,
              siswa['sp_level']?.toString(),
            );
            final phLevel = _resolvePhLevel(
              poin,
              siswa['ph_level']?.toString(),
            );
            final status =
                poin >= 0
                    ? 'Aman'
                    : (poin <= -20 ? 'Prioritas' : 'Bermasalah');

            return Student(
              name: siswa['nama_siswa']?.toString() ?? 'Unknown',
              kelas: kelasMap[idKelas] ?? idKelas,
              programKeahlian:
                  jurusanMap[idKelas] ??
                  siswa['program_keahlian']?.toString() ??
                  'Unknown',
              poin: poin,
              prestasi: '-',
              avatar: Icons.person,
              rank: 0,
              status: status,
              nis: int.tryParse(siswa['nis']?.toString() ?? '') ?? 0,
              spLevel: spLevel,
              phLevel: phLevel,
            );
          }).toList();

          final phStudents =
              classStudents.where((s) => s.phLevel != null).toList()
                ..sort((a, b) => b.poin.compareTo(a.poin));
          final spStudents =
              classStudents.where((s) => s.spLevel != null).toList()
                ..sort((a, b) => a.poin.compareTo(b.poin));

          siswaTerbaik = _rankAndLabel(phStudents, isPh: true);
          siswaBerat = _rankAndLabel(spStudents, isPh: false);
        }
      }

      // Fetch apresiasi data
      Map<String, dynamic>? penghargaanJson;
      List<Map<String, dynamic>> apresiasiRawData = [];
      
      if (walikelasId.isNotEmpty && teacherClassId.isNotEmpty) {
        final penghargaanResponse = await http.get(
          Uri.parse(
            '${ApiConfig.baseUrl}/skoring_penghargaan?nip=$walikelasId&id_kelas=$teacherClassId',
          ),
        );
        
        if (penghargaanResponse.statusCode == 200) {
          penghargaanJson = Map<String, dynamic>.from(
            jsonDecode(penghargaanResponse.body),
          );
          final siswaData = (penghargaanJson['siswa'] as List<dynamic>? ?? []);
          final penilaianData =
              (penghargaanJson['penilaian']['data'] as List<dynamic>? ?? [])
                  .where(
                    (item) => siswaData.any(
                      (siswa) =>
                          siswa['nis'].toString() == item['nis'].toString() &&
                          siswa['id_kelas'].toString() == teacherClassId,
                    ),
                  )
                  .toList();
          apresiasiRawData = List<Map<String, dynamic>>.from(penilaianData);
        }
      }

      Map<String, dynamic>? pelanggaranJson;
      List<Map<String, dynamic>> pelanggaranRawData = [];
      
      if (walikelasId.isNotEmpty && teacherClassId.isNotEmpty) {
        var pelanggaranResponse = await http.get(
          Uri.parse(
            '${ApiConfig.baseUrl}/skoring_pelanggaran?nip=$walikelasId&id_kelas=$teacherClassId',
          ),
        );
        
        if (pelanggaranResponse.statusCode != 200) {
          pelanggaranResponse = await http.get(
            Uri.parse(
              '${ApiConfig.baseUrl}/skoring_2pelanggaran?nip=$walikelasId&id_kelas=$teacherClassId',
            ),
          );
        }
        
        if (pelanggaranResponse.statusCode == 200) {
          pelanggaranJson = Map<String, dynamic>.from(
            jsonDecode(pelanggaranResponse.body),
          );
          final siswaData = (pelanggaranJson['siswa'] as List<dynamic>? ?? []);
          final penilaianData =
              (pelanggaranJson['penilaian']['data'] as List<dynamic>? ?? [])
                  .where(
                    (item) => siswaData.any(
                      (siswa) =>
                          siswa['nis'].toString() == item['nis'].toString() &&
                          siswa['id_kelas'].toString() == teacherClassId,
                    ),
                  )
                  .toList();
          pelanggaranRawData = List<Map<String, dynamic>>.from(penilaianData);
        }
      }

      // Build activity data
      List<Activity> activityData = [];
      if (teacherClassId.isNotEmpty) {
        if (penghargaanJson != null) {
          activityData.addAll(
            mapActivityLogsFromJson(
              json: penghargaanJson,
              category: 'Apresiasi',
              classId: teacherClassId,
            ),
          );
        }
        if (pelanggaranJson != null) {
          activityData.addAll(
            mapActivityLogsFromJson(
              json: pelanggaranJson,
              category: 'Pelanggaran',
              classId: teacherClassId,
            ),
          );
        }
        activityData.sort((a, b) => b.fullDate.compareTo(a.fullDate));
      }

      return {
        'siswaTerbaik': siswaTerbaik,
        'siswaBerat': siswaBerat,
        'apresiasiRawData': apresiasiRawData,
        'pelanggaranRawData': pelanggaranRawData,
        'activityData': activityData,
        'kelasData': kelasData,
      };
    } catch (e) {
      print('Error fetching data: $e');
      return {
        'siswaTerbaik': <Student>[],
        'siswaBerat': <Student>[],
        'apresiasiRawData': <Map<String, dynamic>>[],
        'pelanggaranRawData': <Map<String, dynamic>>[],
        'activityData': <Activity>[],
        'kelasData': <Map<String, dynamic>>[],
      };
    }
  }

  static String? _resolvePhLevel(int points, String? rawLevel) {
    if (points <= -25) return null;
    final ph = rawLevel?.trim();
    if (ph != null && ph.isNotEmpty && ph != '-') {
      return ph;
    }
    if (points >= 151) return 'PH3';
    if (points >= 126) return 'PH2';
    if (points >= 100) return 'PH1';
    return null;
  }

  static String? _resolveSpLevel(int points, String? rawLevel) {
    final sp = rawLevel?.trim();
    if (sp != null && sp.isNotEmpty && sp != '-') {
      return sp;
    }
    if (points <= -76) return 'SP3';
    if (points <= -51) return 'SP2';
    if (points <= -25) return 'SP1';
    return null;
  }

  static List<Student> _rankAndLabel(List<Student> students, {required bool isPh}) {
    return students.asMap().entries.map((entry) {
      final siswa = entry.value;
      final level = isPh ? siswa.phLevel : siswa.spLevel;
      return Student(
        name: siswa.name,
        kelas: siswa.kelas,
        programKeahlian: siswa.programKeahlian,
        poin: siswa.poin,
        prestasi: level != null ? 'Level $level' : siswa.prestasi,
        avatar: siswa.avatar,
        rank: entry.key + 1,
        status: siswa.status,
        nis: siswa.nis,
        spLevel: siswa.spLevel,
        phLevel: siswa.phLevel,
      );
    }).toList();
  }
}