import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:skoring/config/api_client.dart';
import 'package:skoring/models/types/student.dart';
import 'package:skoring/models/api/api_activity.dart';

class WalikelasDataService {
  static Future<Map<String, dynamic>> fetchAllData({
    required String walikelasId,
    required String teacherClassId,
  }) async {
    try {
      final params = {'nip': walikelasId, 'id_kelas': teacherClassId};

      // ── Parallel fetch: kelas + siswa + apresiasi + pelanggaran ────────────
      final results = await Future.wait([
        ApiClient.get('kelas'),
        if (walikelasId.isNotEmpty && teacherClassId.isNotEmpty) ...[
          ApiClient.get('siswa', params: params),
          ApiClient.get('skoring_penghargaan', params: params),
          _fetchPelanggaran(params),
        ],
      ]);

      // ── Kelas ───────────────────────────────────────────────────────────────
      Map<String, String> kelasMap = {};
      Map<String, String> jurusanMap = {};
      List<Map<String, dynamic>> kelasData = [];

      final kelasRes = results[0];
      if (kelasRes.statusCode == 200) {
        kelasData = List<Map<String, dynamic>>.from(
          jsonDecode(kelasRes.body)['data'] ?? [],
        );
        kelasMap = {for (var k in kelasData) k['id_kelas'].toString(): k['nama_kelas'].toString()};
        jurusanMap = {for (var k in kelasData) k['id_kelas'].toString(): k['jurusan'].toString()};
      }

      List<Student> siswaTerbaik = [];
      List<Student> siswaBerat = [];
      List<Map<String, dynamic>> apresiasiRawData = [];
      List<Map<String, dynamic>> pelanggaranRawData = [];
      List<Activity> activityData = [];

      if (walikelasId.isNotEmpty && teacherClassId.isNotEmpty) {
        // ── Siswa ─────────────────────────────────────────────────────────────
        final siswaRes = results[1];
        if (siswaRes.statusCode == 200) {
          final siswaData = List<Map<String, dynamic>>.from(
            jsonDecode(siswaRes.body)['data'] ?? [],
          );
          final classStudents = siswaData.map((s) => _toStudent(s, kelasMap, jurusanMap)).toList();

          final phStudents = classStudents.where((s) => s.phLevel != null).toList()
            ..sort((a, b) => b.poin.compareTo(a.poin));
          final spStudents = classStudents.where((s) => s.spLevel != null).toList()
            ..sort((a, b) => a.poin.compareTo(b.poin));

          siswaTerbaik = _rankAndLabel(phStudents, isPh: true);
          siswaBerat = _rankAndLabel(spStudents, isPh: false);
        }

        // ── Apresiasi ─────────────────────────────────────────────────────────
        final apresiasiRes = results[2];
        Map<String, dynamic>? penghargaanJson;
        if (apresiasiRes.statusCode == 200) {
          penghargaanJson = jsonDecode(apresiasiRes.body);
          apresiasiRawData = _filterBySiswa(penghargaanJson!, teacherClassId);
        }

        // ── Pelanggaran ───────────────────────────────────────────────────────
        final pelanggaranRes = results[3];
        Map<String, dynamic>? pelanggaranJson;
        if (pelanggaranRes.statusCode == 200) {
          pelanggaranJson = jsonDecode(pelanggaranRes.body);
          pelanggaranRawData = _filterBySiswa(pelanggaranJson!, teacherClassId);
        }

        // ── Activity feed ─────────────────────────────────────────────────────
        if (penghargaanJson != null) {
          activityData.addAll(mapActivityLogsFromJson(
            json: penghargaanJson, category: 'Apresiasi', classId: teacherClassId,
          ));
        }
        if (pelanggaranJson != null) {
          activityData.addAll(mapActivityLogsFromJson(
            json: pelanggaranJson, category: 'Pelanggaran', classId: teacherClassId,
          ));
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
      debugPrint('WalikelasDataService error: $e');
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

  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// Tries skoring_pelanggaran first, falls back to skoring_2pelanggaran.
  static Future<dynamic> _fetchPelanggaran(Map<String, String> params) async {
    final res = await ApiClient.get('skoring_pelanggaran', params: params);
    if (res.statusCode == 200) return res;
    return ApiClient.get('skoring_2pelanggaran', params: params);
  }

  static List<Map<String, dynamic>> _filterBySiswa(
    Map<String, dynamic> json,
    String teacherClassId,
  ) {
    final siswaList = json['siswa'] as List<dynamic>? ?? [];
    final penilaian = json['penilaian']?['data'] as List<dynamic>? ?? [];
    return penilaian
        .where((item) => siswaList.any(
              (s) =>
                  s['nis'].toString() == item['nis'].toString() &&
                  s['id_kelas'].toString() == teacherClassId,
            ))
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  static Student _toStudent(
    Map<String, dynamic> s,
    Map<String, String> kelasMap,
    Map<String, String> jurusanMap,
  ) {
    final idKelas = s['id_kelas']?.toString() ?? '';
    final poin = int.tryParse(s['poin_total']?.toString() ?? '') ?? 0;
    return Student(
      name: s['nama_siswa']?.toString() ?? 'Unknown',
      kelas: kelasMap[idKelas] ?? idKelas,
      programKeahlian: jurusanMap[idKelas] ?? s['program_keahlian']?.toString() ?? 'Unknown',
      poin: poin,
      prestasi: '-',
      avatar: Icons.person,
      rank: 0,
      status: poin >= 0 ? 'Aman' : (poin <= -20 ? 'Prioritas' : 'Bermasalah'),
      nis: int.tryParse(s['nis']?.toString() ?? '') ?? 0,
      spLevel: _resolveSpLevel(poin, s['sp_level']?.toString()),
      phLevel: _resolvePhLevel(poin, s['ph_level']?.toString()),
    );
  }

  static String? _resolvePhLevel(int points, String? rawLevel) {
    if (points <= -25) return null;
    final ph = rawLevel?.trim();
    if (ph != null && ph.isNotEmpty && ph != '-') return ph;
    if (points >= 151) return 'PH3';
    if (points >= 126) return 'PH2';
    if (points >= 100) return 'PH1';
    return null;
  }

  static String? _resolveSpLevel(int points, String? rawLevel) {
    final sp = rawLevel?.trim();
    if (sp != null && sp.isNotEmpty && sp != '-') return sp;
    if (points <= -76) return 'SP3';
    if (points <= -51) return 'SP2';
    if (points <= -25) return 'SP1';
    return null;
  }

  static List<Student> _rankAndLabel(List<Student> students, {required bool isPh}) {
    return students.asMap().entries.map((entry) {
      final s = entry.value;
      final level = isPh ? s.phLevel : s.spLevel;
      return Student(
        name: s.name, kelas: s.kelas, programKeahlian: s.programKeahlian,
        poin: s.poin, prestasi: level != null ? 'Level $level' : s.prestasi,
        avatar: s.avatar, rank: entry.key + 1, status: s.status,
        nis: s.nis, spLevel: s.spLevel, phLevel: s.phLevel,
      );
    }).toList();
  }
}