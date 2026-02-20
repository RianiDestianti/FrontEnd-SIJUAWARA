import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skoring/models/types/student.dart';
import 'package:skoring/models/api/api_activity.dart';
import 'student_card_widgets.dart';

class SectionWidgets {
  static Widget buildCompactSiswaTerbaikSection(
    bool isSmall,
    double padding,
    List<Student> filteredSiswaTerbaik,
    Function(Student) onStudentTap,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmall ? 16 : 18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isSmall ? 16 : 18),
                topRight: Radius.circular(isSmall ? 16 : 18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmall ? 8 : 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: isSmall ? 20 : 22,
                  ),
                ),
                SizedBox(width: isSmall ? 10 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PH (Penghargaan)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: isSmall ? 15 : 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Siswa dengan status PH1–PH3',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isSmall ? 10 : 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              children: filteredSiswaTerbaik.isEmpty
                  ? [
                      Text(
                        'Tidak ada hasil ditemukan',
                        style: GoogleFonts.poppins(
                          fontSize: isSmall ? 12 : 13,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ]
                  : filteredSiswaTerbaik.asMap().entries.map((entry) {
                      int index = entry.key;
                      Student siswa = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < filteredSiswaTerbaik.length - 1
                              ? (isSmall ? 10 : 12)
                              : 0,
                        ),
                        child: StudentCardWidgets.buildCompactSiswaTerbaikItem(
                          siswa,
                          isSmall,
                          () => onStudentTap(siswa),
                        ),
                      );
                    }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildCompactSiswaBeratSection(
    bool isSmall,
    double padding,
    List<Student> filteredSiswaBerat,
    Function(Student) onStudentTap,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmall ? 16 : 18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6D), Color(0xFFFF8E8F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isSmall ? 16 : 18),
                topRight: Radius.circular(isSmall ? 16 : 18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmall ? 8 : 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: isSmall ? 20 : 22,
                  ),
                ),
                SizedBox(width: isSmall ? 10 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SP (Pelanggaran)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: isSmall ? 15 : 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Siswa dengan status SP1–SP3',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isSmall ? 10 : 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              children: filteredSiswaBerat.isEmpty
                  ? [
                      Text(
                        'Tidak ada hasil ditemukan',
                        style: GoogleFonts.poppins(
                          fontSize: isSmall ? 12 : 13,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ]
                  : filteredSiswaBerat.asMap().entries.map((entry) {
                      int index = entry.key;
                      Student siswa = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < filteredSiswaBerat.length - 1
                              ? (isSmall ? 10 : 12)
                              : 0,
                        ),
                        child: StudentCardWidgets.buildCompactSiswaBeratItem(
                          siswa,
                          isSmall,
                          () => onStudentTap(siswa),
                        ),
                      );
                    }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildCompactChartCard(
    String title,
    String subtitle,
    IconData icon,
    Gradient gradient,
    Widget chart,
    int selectedTab,
    Function(int) onTabChanged,
    bool isFirst,
    bool isSmall,
    double padding,
    Widget chartButtons,
    VoidCallback onChartTap,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmall ? 16 : 18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isSmall ? 16 : 18),
                topRight: Radius.circular(isSmall ? 16 : 18),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(isSmall ? 8 : 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: isSmall ? 20 : 22),
                ),
                SizedBox(width: isSmall ? 10 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: isSmall ? 14 : 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: isSmall ? 10 : 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(padding, padding * 0.8, padding, 0),
            child: Row(
              children: [
                Text(
                  'Tampilkan:',
                  style: GoogleFonts.poppins(
                    fontSize: isSmall ? 11 : 12,
                    color: const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                chartButtons,
              ],
            ),
          ),

          // Chart area
          Padding(
            padding: EdgeInsets.fromLTRB(padding, padding * 0.5, padding, padding),
            child: GestureDetector(
              onTap: onChartTap,
              child: chart,
            ),
          ),
        ],
      ),
    );
  }

    static Widget buildCompactActivityCard(
    bool isSmall,
    double padding,
    List<Activity> activityData,
    VoidCallback onCardTap,
    Widget Function(Activity, bool) buildActivityItem,
  ) {
    return GestureDetector(
      onTap: onCardTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isSmall ? 16 : 18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmall ? 9 : 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF61B8FF), Color(0xFF0083EE)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.history,
                    color: Colors.white,
                    size: isSmall ? 18 : 19,
                  ),
                ),
                SizedBox(width: isSmall ? 10 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aktivitas Terkini',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: isSmall ? 15 : 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'Update terbaru',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: isSmall ? 10 : 11,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(isSmall ? 6 : 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: isSmall ? 12 : 13,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmall ? 14 : 16),
            if (activityData.isEmpty)
              Text(
                'Belum ada aktivitas skoring.',
                style: GoogleFonts.poppins(
                  fontSize: isSmall ? 11 : 12,
                  color: const Color(0xFF9CA3AF),
                ),
              )
            else
              ...activityData.take(3).map(
                    (activity) => Padding(
                      padding: EdgeInsets.only(bottom: isSmall ? 10 : 12),
                      child: buildActivityItem(activity, isSmall),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  static Widget buildCompactActivityItem(
    Activity activity,
    bool isSmall,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isSmall ? 10 : 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(isSmall ? 12 : 14),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: isSmall ? 40 : 44,
              height: isSmall ? 40 : 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: activity.gradient),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(activity.icon,
                  color: Colors.white, size: isSmall ? 20 : 22),
            ),
            SizedBox(width: isSmall ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: isSmall ? 13 : 14,
                      color: const Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isSmall ? 2 : 3),
                  Text(
                    activity.subtitle,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF6B7280),
                      fontSize: isSmall ? 10 : 11,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: isSmall ? 8 : 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${activity.time}',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF9CA3AF),
                    fontSize: isSmall ? 9 : 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: isSmall ? 4 : 5),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 6 : 7,
                    vertical: isSmall ? 2 : 3,
                  ),
                  decoration: BoxDecoration(
                    color: activity.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: activity.statusColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    activity.status,
                    style: GoogleFonts.poppins(
                      color: activity.statusColor,
                      fontSize: isSmall ? 7 : 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}