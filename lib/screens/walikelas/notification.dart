import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'detail.dart';

import 'services/notification_service.dart';
import 'utils/notif_colors.dart';
import 'widgets/notification_card.dart';
import 'widgets/notification_detail_sheet.dart';
import 'widgets/filter_and_empty.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  String _filter = 'Semua';
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  String _headerStatus = 'Aman';

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('id', timeago.IdMessages());

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();

    _fetch();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ─── Data ─────────────────────────────────────────────────────────────────

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final result = await NotificationService.fetchNotifications();
      final status = result.items.any((n) => n.isUrgent) ? 'Bermasalah' : 'Aman';
      setState(() {
        _notifications = result.items;
        _headerStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  void _markAsRead(String id) async {
    setState(() {
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1) {
        _notifications = List.of(_notifications)
          ..[idx] = _notifications[idx].copyWith(isRead: true);
      }
    });
    await NotificationService.markAsRead(id);
  }

  void _markAllAsRead() async {
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
    await NotificationService.markAllAsRead(_notifications);
    if (!mounted) return;
    _showSnackBar('Semua notifikasi telah ditandai sebagai dibaca');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 14)),
        backgroundColor: isError ? NotifColors.danger : NotifColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── Computed ─────────────────────────────────────────────────────────────

  List<NotificationItem> get _filtered {
    return switch (_filter) {
      'Belum Dibaca' => _notifications.where((n) => !n.isRead).toList(),
      'Sudah Dibaca' => _notifications.where((n) => n.isRead).toList(),
      _ => _notifications,
    };
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  // ─── Navigation ───────────────────────────────────────────────────────────

  void _openDetail(NotificationItem notif) {
    if (!notif.isRead) _markAsRead(notif.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final size = MediaQuery.of(context).size;
        final padding = size.width * 0.05;
        final fontSize = size.width * 0.04;
        return NotificationDetailSheet(
          notification: notif,
          padding: padding,
          fontSize: fontSize,
          onStudentTap: () => _goToStudent(notif),
        );
      },
    );
  }

  void _goToStudent(NotificationItem notif) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(
          student: {
            'name': notif.student,
            'nis': notif.nis,
            'kelas': 'Kelas Tidak Diketahui',
            'programKeahlian': 'Program Tidak Diketahui',
            'points': 0,
            'poinApresiasi': 0,
            'poinPelanggaran': 0,
            'spLevel': null,
            'phLevel': null,
          },
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gradient = NotifColors.headerGradient(_headerStatus);
    final shadow = NotifColors.headerShadow(_headerStatus);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: NotifColors.surface,
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth > 600 ? 600.0 : constraints.maxWidth;
              final padding = maxW * 0.05;
              final fontSize = maxW * 0.04;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxW),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        _header(gradient, shadow, padding, fontSize),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(padding),
                            child: _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : _body(padding, fontSize),
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

  Widget _header(
    List<Color> gradient,
    Color shadow,
    double padding,
    double fontSize,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          padding,
          MediaQuery.of(context).padding.top + padding * 0.5,
          padding,
          padding * 1.5,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                if (_unreadCount > 0) _markAllButton(padding, fontSize),
              ],
            ),
            SizedBox(height: padding * 1.2),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(padding * 0.6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: padding * 0.8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      _unreadCount > 0 ? '$_unreadCount belum dibaca' : 'Semua sudah dibaca',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: fontSize * 0.9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _markAllButton(double padding, double fontSize) => GestureDetector(
        onTap: _markAllAsRead,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: padding * 0.8,
            vertical: padding * 0.4,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.done_all_rounded, color: Colors.white, size: 16),
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
      );

  Widget _body(double padding, double fontSize) {
    final items = _filtered;
    return Column(
      children: [
        _filterBar(items.length, padding, fontSize),
        SizedBox(height: padding),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetch,
            child: items.isEmpty
                ? ListView(children: [
                    SizedBox(height: padding),
                    NotifEmptyState(fontSize: fontSize, status: _headerStatus),
                  ])
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) => NotificationCard(
                      notification: items[i],
                      onTap: () => _openDetail(items[i]),
                      padding: padding,
                      fontSize: fontSize,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _filterBar(int count, double padding, double fontSize) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$count Notifikasi',
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: NotifColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => FilterBottomSheet(
                selectedFilter: _filter,
                onFilterSelected: (f) => setState(() => _filter = f),
                fontSize: fontSize,
              ),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: padding * 0.8,
                vertical: padding * 0.4,
              ),
              decoration: BoxDecoration(
                color: NotifColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: NotifColors.border),
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
                  Icon(Icons.filter_list_rounded, size: fontSize, color: NotifColors.textMuted),
                  SizedBox(width: padding * 0.4),
                  Text(
                    _filter,
                    style: GoogleFonts.poppins(
                      fontSize: fontSize * 0.8,
                      fontWeight: FontWeight.w600,
                      color: NotifColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: padding * 0.2),
                  Icon(Icons.keyboard_arrow_down_rounded, size: fontSize, color: NotifColors.textMuted),
                ],
              ),
            ),
          ),
        ],
      );
}