import 'package:flutter/material.dart';

class FAQItem {
  final String title;
  final String jenisPoin;
  final List<Map<String, String>> items;

  FAQItem({required this.title, required this.jenisPoin, required this.items});

  factory FAQItem.fromJson(Map<String, dynamic> json) {
    return FAQItem(
      title: json['kategori'] ?? 'Unknown',
      jenisPoin: json['jenis_poin']?.toString() ?? '',
      items: [
        {
          'text': json['uraian'] ?? 'No description',
          'points': '${json['indikator_poin'] ?? 0} poin',
        },
      ],
    );
  }
}

class StudentScore {
  final String keterangan;
  final String tanggal;
  final int poin;
  final String type;

  StudentScore({
    required this.keterangan,
    required this.tanggal,
    required this.poin,
    required this.type,
  });

  factory StudentScore.fromPenghargaan(Map<String, dynamic> json, int poin) {
    return StudentScore(
      keterangan: json['alasan']?.toString() ?? 'Unknown',
      tanggal: json['tanggal_penghargaan']?.toString() ?? 'Unknown',
      poin: poin,
      type: 'apresiasi',
    );
  }

  factory StudentScore.fromPeringatan(Map<String, dynamic> json, int poin) {
    return StudentScore(
      keterangan: json['alasan']?.toString() ?? 'Unknown',
      tanggal: json['tanggal_sp']?.toString() ?? 'Unknown',
      poin: poin,
      type: 'pelanggaran',
    );
  }
}

class Student {
  final String nis;
  final String name;
  final int totalPoin;
  final int apresiasi;
  final int pelanggaran;
  final bool isPositive;
  final Color color;
  final String avatar;
  final List<StudentScore> scores;
  final String idKelas;

  Student({
    required this.nis,
    required this.name,
    required this.totalPoin,
    required this.apresiasi,
    required this.pelanggaran,
    required this.isPositive,
    required this.color,
    required this.avatar,
    required this.scores,
    required this.idKelas,
  });

  factory Student.fromJson(
    Map<String, dynamic> json,
    List<StudentScore> scores,
  ) {
    final totalPoin = int.tryParse(json['poin_total']?.toString() ?? '') ?? 0;
    return Student(
      nis: json['nis']?.toString() ?? '',
      name: json['nama_siswa']?.toString() ?? 'Unknown',
      totalPoin: totalPoin,
      apresiasi: int.tryParse(json['poin_apresiasi']?.toString() ?? '') ?? 0,
      pelanggaran:
          int.tryParse(json['poin_pelanggaran']?.toString() ?? '') ?? 0,
      isPositive: totalPoin >= 0,
      color: totalPoin >= 0 ? const Color(0xFF10B981) : const Color(0xFFFF6B6D),
      avatar:
          (json['nama_siswa']?.toString() ?? 'U').substring(0, 2).toUpperCase(),
      scores: scores,
      idKelas: json['id_kelas']?.toString() ?? '',
    );
  }
}

class Kelas {
  final String idKelas;
  final String namaKelas;
  final String jurusan;

  Kelas({
    required this.idKelas,
    required this.namaKelas,
    required this.jurusan,
  });

  factory Kelas.fromJson(Map<String, dynamic> json) {
    return Kelas(
      idKelas: json['id_kelas']?.toString() ?? '',
      namaKelas: json['nama_kelas']?.toString() ?? 'Unknown',
      jurusan: json['jurusan']?.toString() ?? 'Unknown',
    );
  }
}
