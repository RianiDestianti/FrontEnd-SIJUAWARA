import 'package:flutter/material.dart';

class ApiActivity {
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

  ApiActivity({
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