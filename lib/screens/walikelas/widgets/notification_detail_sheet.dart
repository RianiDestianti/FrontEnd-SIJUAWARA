import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_service.dart';
import '../utils/notif_colors.dart';

class NotificationDetailSheet extends StatelessWidget {
  final NotificationItem notification;
  final double padding;
  final double fontSize;
  final VoidCallback onStudentTap;

  const NotificationDetailSheet({
    super.key,
    required this.notification,
    required this.padding,
    required this.fontSize,
    required this.onStudentTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = notification.typeColor;

    return Container(
      padding: EdgeInsets.all(padding * 1.2),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, color),
          SizedBox(height: padding * 1.2),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: padding),
                  _infoRow(),
                  SizedBox(height: padding),
                  _bkCard(),
                  SizedBox(height: padding),
                  _viewStudentButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, Color color) => Row(
        children: [
          Container(
            width: fontSize * 3.75,
            height: fontSize * 3.75,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(notification.typeIcon, color: color, size: fontSize * 1.9),
          ),
          SizedBox(width: padding * 0.8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: GoogleFonts.poppins(
                    fontSize: fontSize * 1.2,
                    fontWeight: FontWeight.w700,
                    color: NotifColors.textPrimary,
                  ),
                ),
                Text(
                  notification.time,
                  style: GoogleFonts.poppins(
                    fontSize: fontSize * 0.9,
                    color: NotifColors.textMuted,
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
      );

  Widget _infoRow() => Row(
        children: [
          Expanded(child: _infoBox(label: 'Siswa', value: notification.student)),
          SizedBox(width: padding * 0.6),
          Expanded(child: _infoBox(label: 'Aksi', value: notification.action)),
        ],
      );

  Widget _infoBox({required String label, required String value}) => Container(
        padding: EdgeInsets.all(padding * 0.8),
        decoration: BoxDecoration(
          color: NotifColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NotifColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: fontSize * 0.75,
                fontWeight: FontWeight.w500,
                color: NotifColors.textMuted,
              ),
            ),
            SizedBox(height: padding * 0.2),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: fontSize * 0.9,
                fontWeight: FontWeight.w600,
                color: NotifColors.textPrimary,
              ),
            ),
          ],
        ),
      );

  Widget _bkCard() => Container(
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
                Icon(Icons.psychology, size: fontSize, color: const Color(0xFF0284C7)),
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
              notification.bkTeacher,
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
                'Status: ${notification.statusChange}',
                style: GoogleFonts.poppins(
                  fontSize: fontSize * 0.7,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0284C7),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _viewStudentButton(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            onStudentTap();
          },
          icon: const Icon(Icons.person_search_rounded, color: Colors.white),
          label: Text(
            'Lihat Detail Siswa',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: NotifColors.primary,
            padding: EdgeInsets.symmetric(vertical: padding * 0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
}