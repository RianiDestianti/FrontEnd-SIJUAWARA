import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skoring/config/api_client.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final String type;
  final bool isRead;
  final String student;
  final String action;
  final String bkTeacher;
  final String statusChange;
  final String nis;

  const NotificationItem({
    required this.id, required this.title, required this.message,
    required this.time, required this.type, required this.isRead,
    required this.student, required this.action, required this.bkTeacher,
    required this.statusChange, required this.nis,
  });

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id, title: title, message: message, time: time, type: type,
        isRead: isRead ?? this.isRead, student: student, action: action,
        bkTeacher: bkTeacher, statusChange: statusChange, nis: nis,
      );

  bool get isUrgent => statusChange != 'Dalam Bimbingan';
  Color get typeColor => isUrgent ? const Color(0xFFEA580C) : const Color(0xFF3B82F6);
  IconData get typeIcon => isUrgent ? Icons.warning_rounded : Icons.psychology_rounded;
  String get typeLabel => isUrgent ? 'INTERVENSI' : 'PENANGANAN BK';
}

class NotificationResult {
  final List<NotificationItem> items;
  final String teacherClassId;
  final String walikelasId;

  const NotificationResult({
    required this.items, required this.teacherClassId, required this.walikelasId,
  });
}

class NotificationService {
  static Future<NotificationResult> fetchNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final teacherClassId = prefs.getString('id_kelas') ?? '';
    final walikelasId = prefs.getString('walikelas_id') ?? '';

    if (teacherClassId.isEmpty || walikelasId.isEmpty) {
      throw Exception('Data guru tidak lengkap. Silakan login ulang.');
    }

    final response = await ApiClient.get('notifikasi', params: {
      'nip': walikelasId,
      'id_kelas': teacherClassId,
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to load notifications: ${response.statusCode}');
    }

    final jsonData = jsonDecode(response.body);
    final notifications = jsonData['data'] as List<dynamic>? ?? [];
    final readStatuses = prefs.getStringList('notification_read_status') ?? [];

    final items = notifications.map((notif) {
      final m = notif as Map<String, dynamic>;
      final createdRaw = m['created_at'] ?? m['tanggal_Mulai_Perbaikan'] ??
          m['tanggal_sp'] ?? m['tanggal_penghargaan'] ?? DateTime.now().toString();
      final createdAt = DateTime.tryParse(createdRaw.toString()) ?? DateTime.now();
      final id = m['id_intervensi']?.toString() ?? m['id']?.toString() ??
          m['nis']?.toString() ?? createdAt.toIso8601String();
      final nis = m['nis']?.toString() ?? '-';

      return NotificationItem(
        id: id,
        title: m['nama_intervensi']?.toString() ?? m['judul']?.toString() ?? 'Notifikasi Siswa',
        message: m['isi_intervensi']?.toString() ?? m['isi']?.toString() ?? m['description']?.toString() ?? '',
        time: timeago.format(createdAt, locale: 'id'),
        type: m['kategori']?.toString() ?? 'bk_treatment',
        isRead: readStatuses.contains(id),
        student: m['nama_siswa']?.toString() ?? m['siswa']?.toString() ?? 'Siswa $nis',
        action: m['action']?.toString() ?? 'Penanganan BK / Intervensi',
        bkTeacher: m['nama_guru_bk']?.toString() ?? 'Guru BK NIP ${m['nip_bk'] ?? '-'}',
        statusChange: m['status']?.toString() ?? 'Dalam Bimbingan',
        nis: nis,
      );
    }).toList();

    return NotificationResult(items: items, teacherClassId: teacherClassId, walikelasId: walikelasId);
  }

  static Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final readStatuses = prefs.getStringList('notification_read_status') ?? [];
    if (!readStatuses.contains(id)) {
      readStatuses.add(id);
      await prefs.setStringList('notification_read_status', readStatuses);
    }
  }

  static Future<void> markAllAsRead(List<NotificationItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('notification_read_status', items.map((n) => n.id).toList());
  }
}