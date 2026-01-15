import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:skoring/config/api_config.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'detail.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedFilter = 'Semua';
  List<Map<String, dynamic>> _notificationsData = [];
  bool _isLoading = true;
  String _mostCriticalStatus = 'Aman';
  String _teacherClassId = '';
  String _walikelasId = '';

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('id', timeago.IdMessages());
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      _teacherClassId = prefs.getString('id_kelas') ?? '';
      _walikelasId = prefs.getString('walikelas_id') ?? '';

      if (_teacherClassId.isEmpty || _walikelasId.isEmpty) {
        setState(() {
          _isLoading = false;
          _notificationsData = [];
          _mostCriticalStatus = 'Aman';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Data guru tidak lengkap. Silakan login ulang.',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            backgroundColor: const Color(0xFFFF6B6D),
          ),
        );
        return;
      }

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/notifikasi?nip=$_walikelasId&id_kelas=$_teacherClassId',
        ),
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final notifications = (jsonData['data'] as List<dynamic>? ?? []);

        final readStatuses =
            prefs.getStringList('notification_read_status') ?? [];

        final notificationList =
            notifications.map((notif) {
              final mapNotif = notif as Map<String, dynamic>;
              final createdRaw =
                  mapNotif['created_at'] ??
                      mapNotif['tanggal_Mulai_Perbaikan'] ??
                      mapNotif['tanggal_sp'] ??
                      mapNotif['tanggal_penghargaan'] ??
                      DateTime.now().toString();
              final createdAt = DateTime.tryParse(createdRaw.toString()) ??
                  DateTime.now();
              final time = timeago.format(createdAt, locale: 'id');
              final isRead = readStatuses.contains(
                mapNotif['id_intervensi']?.toString() ??
                    mapNotif['id']?.toString() ??
                    mapNotif['nis']?.toString() ??
                    createdAt.toIso8601String(),
              );
              final status = mapNotif['status']?.toString() ?? 'Dalam Bimbingan';
              final nis = mapNotif['nis']?.toString() ?? '-';
              final namaSiswa =
                  mapNotif['nama_siswa']?.toString() ??
                      mapNotif['siswa']?.toString() ??
                      'Siswa $nis';

              return {
                'id':
                    mapNotif['id_intervensi']?.toString() ??
                    mapNotif['id']?.toString() ??
                    mapNotif['nis']?.toString() ??
                    createdAt.toIso8601String(),
                'title':
                    mapNotif['nama_intervensi']?.toString() ??
                    mapNotif['judul']?.toString() ??
                    'Notifikasi Siswa',
                'message':
                    mapNotif['isi_intervensi']?.toString() ??
                    mapNotif['isi']?.toString() ??
                    mapNotif['description']?.toString() ??
                    '',
                'time': time,
                'type': mapNotif['kategori']?.toString() ?? 'bk_treatment',
                'isRead': isRead,
                'student': namaSiswa,
                'action':
                    mapNotif['action']?.toString() ?? 'Penanganan BK / Intervensi',
                'bkTeacher':
                    mapNotif['nama_guru_bk']?.toString() ??
                    'Guru BK NIP ${mapNotif['nip_bk'] ?? '-'}',
                'statusChange': status,
                'nis': nis,
              };
            }).toList();

        String mostCriticalStatus = 'Aman';
        if (notificationList.any(
          (n) => n['statusChange'] != 'Dalam Bimbingan',
        )) {
          mostCriticalStatus = 'Bermasalah';
        }

        setState(() {
          _notificationsData = notificationList;
          _mostCriticalStatus = mostCriticalStatus;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memuat notifikasi',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          backgroundColor: const Color(0xFFFF6B6D),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    return _selectedFilter == 'Semua'
        ? _notificationsData
        : _notificationsData
            .where(
              (notif) =>
                  _selectedFilter == 'Belum Dibaca'
                      ? !notif['isRead']
                      : notif['isRead'],
            )
            .toList();
  }

  int get _unreadCount =>
      _notificationsData.where((notif) => !notif['isRead']).length;

  void _markAsRead(String notificationId) async {
    setState(() {
      final index = _notificationsData.indexWhere(
        (notif) => notif['id'] == notificationId,
      );
      if (index != -1) _notificationsData[index]['isRead'] = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final readStatuses = prefs.getStringList('notification_read_status') ?? [];
    if (!readStatuses.contains(notificationId)) {
      readStatuses.add(notificationId);
      await prefs.setStringList('notification_read_status', readStatuses);
    }
  }

  void _markAllAsRead() async {
    setState(() {
      for (var notif in _notificationsData) {
        notif['isRead'] = true;
      }
    });
    final prefs = await SharedPreferences.getInstance();
    final readStatuses =
        _notificationsData.map((n) => n['id'].toString()).toList();
    await prefs.setStringList('notification_read_status', readStatuses);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Semua notifikasi telah ditandai sebagai dibaca',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _getStudentStatus(String status) {
    return status == 'Dalam Bimbingan' ? 'Aman' : 'Bermasalah';
  }

  List<Color> _getBackgroundGradient(String status) {
    return status == 'Aman'
        ? [const Color(0xFF61B8FF), const Color(0xFF0083EE)]
        : [const Color(0xFFFF6B6D), const Color(0xFFEA580C)];
  }

  Color _getBackgroundShadowColor(String status) {
    return status == 'Aman' ? const Color(0x200083EE) : const Color(0x20FF6B6D);
  }

  void _navigateToStudentDetail(Map<String, dynamic> notification) {
    final studentData = {
      'name': notification['student'],
      'status': _getStudentStatus(notification['statusChange']),
      'nis': notification['nis'],
      'class': 'Kelas Tidak Diketahui',
    };
  }

  @override
  Widget build(BuildContext context) {
    final backgroundGradient = _getBackgroundGradient(_mostCriticalStatus);
    final shadowColor = _getBackgroundShadowColor(_mostCriticalStatus);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth =
                  constraints.maxWidth > 600 ? 600.0 : constraints.maxWidth;
              final padding = maxWidth * 0.05;
              final fontSize = maxWidth * 0.04;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: backgroundGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(32),
                              bottomRight: Radius.circular(32),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: shadowColor,
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              padding,
                              MediaQuery.of(context).padding.top +
                                  padding * 0.5,
                              padding,
                              padding * 1.5,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const SizedBox(width: 40, height: 40),
                                    if (_unreadCount > 0)
                                      GestureDetector(
                                        onTap: _markAllAsRead,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: padding * 0.8,
                                            vertical: padding * 0.4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.done_all_rounded,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                              SizedBox(width: padding * 0.3),
                                              Text(
                                                'Tandai Semua',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: fontSize * 0.8,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: padding * 1.2),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(padding * 0.6),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: backgroundGradient,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.notifications_active_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    SizedBox(width: padding * 0.8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Notifikasi',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: fontSize * 1.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            _unreadCount > 0
                                                ? '$_unreadCount belum dibaca'
                                                : 'Semua sudah dibaca',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                              fontSize: fontSize * 0.9,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(padding),
                            child:
                                _isLoading
                                    ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                    : ContentWidget(
                                      filteredNotifications:
                                          _filteredNotifications,
                                      selectedFilter: _selectedFilter,
                                      onFilterChanged:
                                          (filter) => setState(
                                            () => _selectedFilter = filter,
                                          ),
                                      onRefresh: _fetchNotifications,
                                      onNotificationTap: (notif) {
                                        if (!notif['isRead'])
                                          _markAsRead(notif['id']);
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(20),
                                            ),
                                          ),
                                          builder:
                                              (
                                                context,
                                              ) => NotificationDetailWidget(
                                                notification: notif,
                                                padding: padding,
                                                fontSize: fontSize,
                                                onStudentTap:
                                                    () =>
                                                        _navigateToStudentDetail(
                                                          notif,
                                                        ),
                                              ),
                                        );
                                      },
                                      padding: padding,
                                      fontSize: fontSize,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ContentWidget extends StatelessWidget {
  final List<Map<String, dynamic>> filteredNotifications;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final Function(Map<String, dynamic>) onNotificationTap;
  final Future<void> Function() onRefresh;
  final double padding;
  final double fontSize;

  const ContentWidget({
    super.key,
    required this.filteredNotifications,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onNotificationTap,
    required this.onRefresh,
    required this.padding,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${filteredNotifications.length} Notifikasi',
              style: GoogleFonts.poppins(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            GestureDetector(
              onTap:
                  () => showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder:
                        (context) => FilterBottomSheet(
                          selectedFilter: selectedFilter,
                          onFilterSelected: onFilterChanged,
                          fontSize: fontSize,
                        ),
                  ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: padding * 0.8,
                  vertical: padding * 0.4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      size: fontSize,
                      color: const Color(0xFF6B7280),
                    ),
                    SizedBox(width: padding * 0.4),
                    Text(
                      selectedFilter,
                      style: GoogleFonts.poppins(
                        fontSize: fontSize * 0.8,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    SizedBox(width: padding * 0.2),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: fontSize,
                      color: const Color(0xFF6B7280),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: padding),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child:
                filteredNotifications.isEmpty
                    ? ListView(
                      children: [
                        SizedBox(height: padding),
                        EmptyStateWidget(
                          fontSize: fontSize,
                          status: 'Aman',
                        ),
                      ],
                    )
                    : ListView.builder(
                      itemCount: filteredNotifications.length,
                      itemBuilder:
                          (context, index) => NotificationCardWidget(
                            notification: filteredNotifications[index],
                            onTap:
                                () => onNotificationTap(
                                  filteredNotifications[index],
                                ),
                            padding: padding,
                            fontSize: fontSize,
                          ),
                    ),
          ),
        ),
      ],
    );
  }
}

class FilterBottomSheet extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;
  final double fontSize;

  const FilterBottomSheet({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(fontSize),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Notifikasi',
            style: GoogleFonts.poppins(
              fontSize: fontSize * 1.1,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: fontSize),
          ...['Semua', 'Belum Dibaca', 'Sudah Dibaca'].map(
            (filter) => ListTile(
              title: Text(
                filter,
                style: GoogleFonts.poppins(
                  fontSize: fontSize * 0.9,
                  fontWeight: FontWeight.w500,
                  color:
                      selectedFilter == filter
                          ? const Color(0xFF0083EE)
                          : const Color(0xFF1F2937),
                ),
              ),
              leading: Radio<String>(
                value: filter,
                groupValue: selectedFilter,
                onChanged: (value) {
                  onFilterSelected(value!);
                  Navigator.pop(context);
                },
                activeColor: const Color(0xFF0083EE),
              ),
              onTap: () {
                onFilterSelected(filter);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final double fontSize;
  final String status;

  const EmptyStateWidget({
    super.key,
    required this.fontSize,
    required this.status,
  });

  List<Color> _getBackgroundGradient(String status) {
    return status == 'Aman'
        ? [const Color(0xFF61B8FF), const Color(0xFF0083EE)]
        : [const Color(0xFFFF6B6D), const Color(0xFFEA580C)];
  }

  Color _getBackgroundShadowColor(String status) {
    return status == 'Aman' ? const Color(0x200083EE) : const Color(0x20FF6B6D);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: fontSize * 7.5,
            height: fontSize * 7.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: _getBackgroundGradient(status)),
              borderRadius: BorderRadius.circular(fontSize * 3.75),
              boxShadow: [
                BoxShadow(
                  color: _getBackgroundShadowColor(status),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: fontSize * 3.75,
              color: Colors.white,
            ),
          ),
          SizedBox(height: fontSize * 1.5),
          Text(
            'Tidak ada notifikasi',
            style: GoogleFonts.poppins(
              fontSize: fontSize * 1.1,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: fontSize * 0.5),
          Text(
            'Semua notifikasi akan muncul di sini',
            style: GoogleFonts.poppins(
              fontSize: fontSize * 0.9,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationCardWidget extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  final double padding;
  final double fontSize;

  const NotificationCardWidget({
    super.key,
    required this.notification,
    required this.onTap,
    required this.padding,
    required this.fontSize,
  });

  Color _getTypeColor(String status) {
    return status == 'Dalam Bimbingan'
        ? const Color(0xFF3B82F6)
        : const Color(0xFFEA580C);
  }

  IconData _getTypeIcon(String status) {
    return status == 'Dalam Bimbingan'
        ? Icons.psychology_rounded
        : Icons.warning_rounded;
  }

  String _getTypeLabel(String status) {
    return status == 'Dalam Bimbingan' ? 'PENANGANAN BK' : 'INTERVENSI';
  }

  @override
  Widget build(BuildContext context) {
    final isRead = notification['isRead'];
    final status = notification['statusChange'];
    final isUrgent = status != 'Dalam Bimbingan';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: padding * 0.6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isRead
                    ? const Color(0xFFE5E7EB)
                    : _getTypeColor(status).withOpacity(0.3),
            width: isRead ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isUrgent
                      ? const Color(0xFFEA580C).withOpacity(0.1)
                      : Colors.black.withOpacity(0.04),
              blurRadius: isUrgent ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(padding * 0.8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: fontSize * 3,
                    height: fontSize * 3,
                    decoration: BoxDecoration(
                      color: _getTypeColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getTypeIcon(status),
                      color: _getTypeColor(status),
                      size: fontSize * 1.5,
                    ),
                  ),
                  SizedBox(width: padding * 0.8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: padding * 0.4,
                                vertical: padding * 0.2,
                              ),
                              decoration: BoxDecoration(
                                color: _getTypeColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _getTypeLabel(status),
                                style: GoogleFonts.poppins(
                                  fontSize: fontSize * 0.6,
                                  fontWeight: FontWeight.w800,
                                  color: _getTypeColor(status),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (!isRead)
                              Container(
                                width: fontSize * 0.5,
                                height: fontSize * 0.5,
                                decoration: BoxDecoration(
                                  color: _getTypeColor(status),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: padding * 0.4),
                        Text(
                          notification['title'],
                          style: GoogleFonts.poppins(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        SizedBox(height: padding * 0.2),
                        Text(
                          notification['student'],
                          style: GoogleFonts.poppins(
                            fontSize: fontSize * 0.9,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        SizedBox(height: padding * 0.4),
                        if ((notification['message'] as String?)?.isNotEmpty ??
                            false)
                          Text(
                            notification['message'],
                            style: GoogleFonts.poppins(
                              fontSize: fontSize * 0.8,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF9CA3AF),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: padding * 0.6),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: fontSize * 0.75,
                    color: const Color(0xFF9CA3AF),
                  ),
                  SizedBox(width: padding * 0.2),
                  Text(
                    notification['time'],
                    style: GoogleFonts.poppins(
                      fontSize: fontSize * 0.7,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                  if (isUrgent) ...[
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: padding * 0.4,
                        vertical: padding * 0.2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.priority_high,
                            size: fontSize * 0.7,
                            color: const Color(0xFFEA580C),
                          ),
                          SizedBox(width: padding * 0.2),
                          Text(
                            'URGENT',
                            style: GoogleFonts.poppins(
                              fontSize: fontSize * 0.6,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFEA580C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationDetailWidget extends StatelessWidget {
  final Map<String, dynamic> notification;
  final double padding;
  final double fontSize;
  final VoidCallback onStudentTap;

  const NotificationDetailWidget({
    super.key,
    required this.notification,
    required this.padding,
    required this.fontSize,
    required this.onStudentTap,
  });

  Color _getTypeColor(String status) {
    return status == 'Dalam Bimbingan'
        ? const Color(0xFF3B82F6)
        : const Color(0xFFEA580C);
  }

  IconData _getTypeIcon(String status) {
    return status == 'Dalam Bimbingan'
        ? Icons.psychology_rounded
        : Icons.warning_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding * 1.2),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: fontSize * 3.75,
                height: fontSize * 3.75,
                decoration: BoxDecoration(
                  color: _getTypeColor(
                    notification['statusChange'],
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getTypeIcon(notification['statusChange']),
                  color: _getTypeColor(notification['statusChange']),
                  size: fontSize * 1.9,
                ),
              ),
              SizedBox(width: padding * 0.8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification['title'],
                      style: GoogleFonts.poppins(
                        fontSize: fontSize * 1.2,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      notification['time'],
                      style: GoogleFonts.poppins(
                        fontSize: fontSize * 0.9,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, size: fontSize * 1.5),
              ),
            ],
          ),
          SizedBox(height: padding * 1.2),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: padding),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(padding * 0.8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Siswa',
                                style: GoogleFonts.poppins(
                                  fontSize: fontSize * 0.75,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              SizedBox(height: padding * 0.2),
                              Text(
                                notification['student'],
                                style: GoogleFonts.poppins(
                                  fontSize: fontSize * 0.9,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: padding * 0.6),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(padding * 0.8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aksi',
                                style: GoogleFonts.poppins(
                                  fontSize: fontSize * 0.75,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              SizedBox(height: padding * 0.2),
                              Text(
                                notification['action'],
                                style: GoogleFonts.poppins(
                                  fontSize: fontSize * 0.9,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: padding),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(padding * 0.8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.psychology,
                              size: fontSize,
                              color: const Color(0xFF0284C7),
                            ),
                            SizedBox(width: padding * 0.4),
                            Text(
                              'Guru BK',
                              style: GoogleFonts.poppins(
                                fontSize: fontSize * 0.9,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: padding * 0.3),
                        Text(
                          notification['bkTeacher'],
                          style: GoogleFonts.poppins(
                            fontSize: fontSize * 0.8,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF0369A1),
                          ),
                        ),
                        SizedBox(height: padding * 0.4),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: padding * 0.4,
                            vertical: padding * 0.2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Status: ${notification['statusChange']}',
                            style: GoogleFonts.poppins(
                              fontSize: fontSize * 0.7,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0284C7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: padding),
        ],
      ),
    );
  }
}
