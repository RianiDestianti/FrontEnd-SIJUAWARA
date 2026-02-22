import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skoring/config/api_client.dart';
import 'package:skoring/models/api/api_detail.dart';

class StudentService {
  final String nipWalikelas;
  final String idKelas;

  StudentService({required this.nipWalikelas, required this.idKelas});

  Map<String, String> get _params => {'nip': nipWalikelas, 'id_kelas': idKelas};

  Future<List<dynamic>> fetchAspekPenilaian() async {
    final response = await ApiClient.get('aspekpenilaian', params: _params);
    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json['success'] == true) return json['data'] as List<dynamic>;
      throw Exception(json['message'] ?? 'Gagal memuat aspek penilaian');
    }
    throw Exception('Gagal mengambil data (${response.statusCode})');
  }

  Future<List<AppreciationHistory>> fetchAppreciations({
    required String nis,
    required List<dynamic> aspek,
  }) async {
    final response = await ApiClient.get('skoring_penghargaan', params: _params);
    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil penilaian (${response.statusCode})');
    }
    final json = jsonDecode(utf8.decode(response.bodyBytes));
    final evals = (json['penilaian']?['data'] as List? ?? [])
        .where((e) => e['nis'].toString() == nis)
        .toList();
    return _toAppreciation(evals, aspek);
  }

  Future<List<ViolationHistory>> fetchViolations({
    required String nis,
    required List<dynamic> aspek,
  }) async {
    var response = await ApiClient.get('skoring_pelanggaran', params: _params);
    if (response.statusCode != 200) {
      response = await ApiClient.get('skoring_2pelanggaran', params: _params);
    }
    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil penilaian (${response.statusCode})');
    }
    final json = jsonDecode(utf8.decode(response.bodyBytes));
    final evals = (json['penilaian']?['data'] as List? ?? [])
        .where((e) => e['nis'].toString() == nis)
        .toList();
    return _toViolation(evals, aspek);
  }

  List<AppreciationHistory> _toAppreciation(List evals, List<dynamic> aspek) {
    final items = evals.map((eval) {
      final a = _findAspek(aspek, eval['id_aspekpenilaian'], fallback: {
        'uraian': 'Apresiasi', 'indikator_poin': 0, 'kategori': 'Umum',
      });
      final dt = DateTime.tryParse(eval['created_at'] ?? '') ?? DateTime.now();
      return (dt: dt, h: AppreciationHistory(
        type: a['kategori']?.toString() ?? 'Apresiasi',
        description: a['uraian']?.toString() ?? 'Apresiasi',
        date: DateFormat('dd MMM yyyy').format(dt),
        time: DateFormat('HH:mm').format(dt),
        points: ((a['indikator_poin'] as num? ?? 0).abs()).toInt(),
        icon: Icons.star_rounded,
        color: const Color(0xFF10B981),
        kategori: a['kategori']?.toString() ?? 'Umum',
      ));
    }).toList()..sort((a, b) => b.dt.compareTo(a.dt));
    return items.map((e) => e.h).toList();
  }

  List<ViolationHistory> _toViolation(List evals, List<dynamic> aspek) {
    final items = evals.map((eval) {
      final a = _findAspek(aspek, eval['id_aspekpenilaian'], fallback: {
        'uraian': 'Pelanggaran', 'indikator_poin': 0, 'kategori': 'Umum',
      });
      final dt = DateTime.tryParse(eval['created_at'] ?? '') ?? DateTime.now();
      return (dt: dt, h: ViolationHistory(
        type: a['kategori']?.toString() ?? 'Pelanggaran',
        description: a['uraian']?.toString() ?? 'Pelanggaran',
        date: DateFormat('dd MMM yyyy').format(dt),
        time: DateFormat('HH:mm').format(dt),
        points: ((a['indikator_poin'] as num? ?? 0).abs()).toInt(),
        icon: Icons.warning_rounded,
        color: const Color(0xFFFF6B6D),
        kategori: a['kategori']?.toString() ?? 'Umum',
      ));
    }).toList()..sort((a, b) => b.dt.compareTo(a.dt));
    return items.map((e) => e.h).toList();
  }

  Map<String, dynamic> _findAspek(List<dynamic> data, dynamic id, {required Map<String, dynamic> fallback}) =>
      data.firstWhere(
        (a) => a['id_aspekpenilaian'].toString() == id.toString(),
        orElse: () => fallback,
      ) as Map<String, dynamic>;

  static AccumulationHistory buildAccumulation(
    List<AppreciationHistory> appreciations,
    List<ViolationHistory> violations,
  ) {
    final totalA = appreciations.fold(0, (s, i) => s + i.points);
    final totalV = violations.fold(0, (s, i) => s + i.points);
    return AccumulationHistory(
      periode: 'Total Keseluruhan',
      pelanggaran: totalV,
      apresiasi: totalA,
      total: totalA - totalV,
      date: 'Sampai ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
    );
  }
}