import 'package:flutter/material.dart';

class ApiViolation {
  final int idSp;
  final String tanggalSp;
  final String levelSp;
  final String alasan;
  final String? createdAt;
  final String? updatedAt;

  ApiViolation({
    required this.idSp,
    required this.tanggalSp,
    required this.levelSp,
    required this.alasan,
    this.createdAt,
    this.updatedAt,
  });

  factory ApiViolation.fromJson(Map<String, dynamic> json) {
    return ApiViolation(
      idSp: json['id_sp'],
      tanggalSp: json['tanggal_sp'],
      levelSp: json['level_sp'],
      alasan: json['alasan'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class ApiAppreciation {
  final int idPenghargaan;
  final String tanggalPenghargaan;
  final String levelPenghargaan;
  final String alasan;
  final String? createdAt;
  final String? updatedAt;

  ApiAppreciation({
    required this.idPenghargaan,
    required this.tanggalPenghargaan,
    required this.levelPenghargaan,
    required this.alasan,
    this.createdAt,
    this.updatedAt,
  });

  factory ApiAppreciation.fromJson(Map<String, dynamic> json) {
    return ApiAppreciation(
      idPenghargaan: json['id_penghargaan'],
      tanggalPenghargaan: json['tanggal_penghargaan'],
      levelPenghargaan: json['level_penghargaan'],
      alasan: json['alasan'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class Student {
  final String name;
  final String nis;
  final String programKeahlian;
  final String kelas;
  final int poinApresiasi;
  final int poinPelanggaran;
  final int poinTotal;
  final String spLevel;
  final String phLevel;

  Student({
    required this.name,
    required this.nis,
    required this.programKeahlian,
    required this.kelas,
    required this.poinApresiasi,
    required this.poinPelanggaran,
    required this.poinTotal,
    required this.spLevel,
    required this.phLevel,
  });
}

class ViolationHistory {
  final String type;
  final String description;
  final String date;
  final String time;
  final int points;
  final IconData icon;
  final Color color;
  final String? pelanggaranKe;
  final String kategori;

  ViolationHistory({
    required this.type,
    required this.description,
    required this.date,
    required this.time,
    required this.points,
    required this.icon,
    required this.color,
    this.pelanggaranKe,
    required this.kategori,
  });
}

class AppreciationHistory {
  final String type;
  final String description;
  final String date;
  final String time;
  final int points;
  final IconData icon;
  final Color color;
  final String kategori;

  AppreciationHistory({
    required this.type,
    required this.description,
    required this.date,
    required this.time,
    required this.points,
    required this.icon,
    required this.color,
    required this.kategori,
  });
}

class AccumulationHistory {
  final String periode;
  final int pelanggaran;
  final int apresiasi;
  final int total;
  final String date;

  AccumulationHistory({
    required this.periode,
    required this.pelanggaran,
    required this.apresiasi,
    required this.total,
    required this.date,
  });
}
