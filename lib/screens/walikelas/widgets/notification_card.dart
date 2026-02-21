import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_service.dart';
import '../utils/notif_colors.dart';

class NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;
  final double padding;
  final double fontSize;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.padding,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;
    final isUrgent = notification.isUrgent;
    final color = notification.typeColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: padding * 0.6),
        decoration: BoxDecoration(
          color: NotifColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? NotifColors.border : color.withOpacity(0.3),
            width: isRead ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isUrgent
                  ? NotifColors.dangerDark.withOpacity(0.1)
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
              _topRow(color, isRead),
              SizedBox(height: padding * 0.6),
              _bottomRow(isUrgent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topRow(Color color, bool isRead) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBox(color),
          SizedBox(width: padding * 0.8),
          Expanded(child: _info(color, isRead)),
        ],
      );

  Widget _iconBox(Color color) => Container(
        width: fontSize * 3,
        height: fontSize * 3,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(notification.typeIcon, color: color, size: fontSize * 1.5),
      );

  Widget _info(Color color, bool isRead) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _labelBadge(color),
              const Spacer(),
              if (!isRead)
                Container(
                  width: fontSize * 0.5,
                  height: fontSize * 0.5,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
          SizedBox(height: padding * 0.4),
          Text(
            notification.title,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: NotifColors.textPrimary,
            ),
          ),
          SizedBox(height: padding * 0.2),
          Text(
            notification.student,
            style: GoogleFonts.poppins(
              fontSize: fontSize * 0.9,
              fontWeight: FontWeight.w500,
              color: NotifColors.textMuted,
            ),
          ),
          if (notification.message.isNotEmpty) ...[
            SizedBox(height: padding * 0.4),
            Text(
              notification.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: fontSize * 0.8,
                color: NotifColors.textFaint,
                height: 1.4,
              ),
            ),
          ],
        ],
      );

  Widget _labelBadge(Color color) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: padding * 0.4,
          vertical: padding * 0.2,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          notification.typeLabel,
          style: GoogleFonts.poppins(
            fontSize: fontSize * 0.6,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _bottomRow(bool isUrgent) => Row(
        children: [
          Icon(Icons.access_time_rounded, size: fontSize * 0.75, color: NotifColors.textFaint),
          SizedBox(width: padding * 0.2),
          Text(
            notification.time,
            style: GoogleFonts.poppins(
              fontSize: fontSize * 0.7,
              fontWeight: FontWeight.w500,
              color: NotifColors.textFaint,
            ),
          ),
          if (isUrgent) ...[
            const Spacer(),
            _urgentBadge(),
          ],
        ],
      );

  Widget _urgentBadge() => Container(
        padding: EdgeInsets.symmetric(
          horizontal: padding * 0.4,
          vertical: padding * 0.2,
        ),
        decoration: BoxDecoration(
          color: NotifColors.dangerDark.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.priority_high, size: fontSize * 0.7, color: NotifColors.dangerDark),
            SizedBox(width: padding * 0.2),
            Text(
              'URGENT',
              style: GoogleFonts.poppins(
                fontSize: fontSize * 0.6,
                fontWeight: FontWeight.w800,
                color: NotifColors.dangerDark,
              ),
            ),
          ],
        ),
      );
}