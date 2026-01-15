import 'package:flutter/material.dart';

class HistoryItem {
  final String id;
  final String type;
  final String description;
  final String date;
  final String time;
  final int points;
  final IconData icon;
  final Color color;
  final String? pemberi;
  final String? pelapor;
  final bool isNew;
  final bool isPelanggaran;
  final DateTime createdAt;
  final String? pelanggaranKe;
  final String kategori;

  HistoryItem({
    required this.id,
    required this.type,
    required this.description,
    required this.date,
    required this.time,
    required this.points,
    required this.icon,
    required this.color,
    this.pemberi,
    this.pelapor,
    required this.isNew,
    required this.isPelanggaran,
    required this.createdAt,
    this.pelanggaranKe,
    required this.kategori,
  });
}
