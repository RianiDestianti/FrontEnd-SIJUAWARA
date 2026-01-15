import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Activity {
  final int id;
  final String type;
  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String subtitle;
  final String time;
  final String date;
  final DateTime fullDate;
  final String status;
  final Color statusColor;
  final String details;

  Activity({
    required this.id,
    required this.type,
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.date,
    required this.fullDate,
    required this.status,
    required this.statusColor,
    required this.details,
  });
}

String formatActivityDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  if (target == today) return 'Hari ini';
  if (target == today.subtract(const Duration(days: 1))) return 'Kemarin';
  return DateFormat('dd MMM yyyy').format(date);
}

List<Activity> mapActivityLogsFromJson({
  required Map<String, dynamic> json,
  required String category,
  required String classId,
}) {
  final siswaList = List<Map<String, dynamic>>.from(
    (json['siswa'] as List<dynamic>? ?? []).map(
      (e) => Map<String, dynamic>.from(e as Map),
    ),
  );
  final aspekList = List<Map<String, dynamic>>.from(
    (json['aspekPel'] as List<dynamic>? ?? []).map(
      (e) => Map<String, dynamic>.from(e as Map),
    ),
  );
  final penilaianList = List<Map<String, dynamic>>.from(
    ((json['penilaian']?['data']) as List<dynamic>? ?? []).map(
      (e) => Map<String, dynamic>.from(e as Map),
    ),
  );

  final siswaByNis = {
    for (var siswa in siswaList) siswa['nis'].toString(): siswa,
  };
  final aspekById = {
    for (var aspek in aspekList) aspek['id_aspekpenilaian'].toString(): aspek,
  };

  final lowerCategory = category.toLowerCase();
  final isApresiasi = lowerCategory == 'apresiasi';

  return penilaianList
      .where((item) {
        final nisKey = item['nis']?.toString();
        if (nisKey == null) return false;
        final siswa = siswaByNis[nisKey];
        if (siswa == null) return false;
        final kelasId = siswa['id_kelas']?.toString() ?? '';
        return classId.isEmpty || kelasId == classId;
      })
      .map((item) {
        final nis = item['nis']?.toString() ?? '-';
        final siswa = siswaByNis[nis];
        final nama = siswa?['nama_siswa']?.toString() ?? 'Siswa $nis';
        final aspek = aspekById[item['id_aspekpenilaian']?.toString()];
        final uraian =
            aspek?['uraian']?.toString() ??
            item['uraian']?.toString() ??
            'Skoring';
        final point = (aspek?['indikator_poin'] as num?)?.toInt() ?? 0;
        final createdRaw = item['created_at']?.toString() ?? '';
        final createdAt = DateTime.tryParse(createdRaw) ?? DateTime.now();
        final statusColor =
            isApresiasi ? const Color(0xFF10B981) : const Color(0xFFFF6B6D);
        final gradient =
            isApresiasi
                ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                : [const Color(0xFFFF6B6D), const Color(0xFFFF8E8F)];
        final icon =
            isApresiasi
                ? Icons.emoji_events_outlined
                : Icons.report_problem_outlined;
        final status = '${isApresiasi ? '+' : '-'}$point POIN';
        final detailPieces =
            [
              'NIS $nis',
              if (aspek?['kategori'] != null) aspek!['kategori'].toString(),
              if (aspek?['kode'] != null) 'Kode ${aspek!['kode']}',
            ].where((element) => element.isNotEmpty).toList();

        final parsedId =
            int.tryParse(item['id_penilaian']?.toString() ?? '') ??
            createdAt.millisecondsSinceEpoch;

        return Activity(
          id: parsedId,
          type: lowerCategory,
          icon: icon,
          gradient: gradient,
          title:
              isApresiasi
                  ? 'Penghargaan untuk $nama'
                  : 'Pelanggaran oleh $nama',
          subtitle: uraian,
          time: DateFormat('HH:mm').format(createdAt),
          date: formatActivityDate(createdAt),
          fullDate: createdAt,
          status: status,
          statusColor: statusColor,
          details: detailPieces.join(' • '),
        );
      })
      .toList();
}
