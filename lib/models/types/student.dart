import 'package:flutter/material.dart';

class Student {
  final String name;
  final String kelas;
  final String programKeahlian;
  final int poin;
  final String prestasi;
  final IconData avatar;
  final int rank;
  final String status;
  final int nis;
  final String? spLevel;
  final String? phLevel;

  Student({
    required this.name,
    required this.kelas,
    required this.programKeahlian,
    required this.poin,
    required this.prestasi,
    required this.avatar,
    required this.rank,
    required this.status,
    required this.nis,
    this.spLevel,
    this.phLevel,
  });
}
