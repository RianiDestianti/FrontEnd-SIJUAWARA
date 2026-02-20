import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skoring/models/types/student.dart';
import '../utils/student_utils.dart';

class StudentCardWidgets {
  static Widget buildCompactSiswaTerbaikItem(
    Student siswa,
    bool isSmall,
    VoidCallback onTap,
  ) {
    Color rankColor = StudentUtils.getRankColor(siswa.rank);
    IconData rankIcon = StudentUtils.getRankIcon(siswa.rank);
    final avatarSize = isSmall ? 42.0 : 46.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isSmall ? 10 : 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(isSmall ? 12 : 14),
          border: Border.all(color: rankColor.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: rankColor.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: siswa.rank <= 3
                      ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                      : [const Color(0xFF61B8FF), const Color(0xFF0083EE)],
                ),
                borderRadius: BorderRadius.circular(avatarSize / 2),
                boxShadow: [
                  BoxShadow(
                    color: rankColor.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.person,
                      color: Colors.white, size: isSmall ? 20 : 22),
                  if (siswa.rank <= 3)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: isSmall ? 16 : 18,
                        height: isSmall ? 16 : 18,
                        decoration: BoxDecoration(
                          color: rankColor,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Icon(rankIcon,
                            color: Colors.white, size: isSmall ? 8 : 9),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: isSmall ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmall ? 6 : 7,
                          vertical: isSmall ? 2 : 3,
                        ),
                        decoration: BoxDecoration(
                          color: rankColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: rankColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '#${siswa.rank}',
                          style: GoogleFonts.poppins(
                            color: rankColor,
                            fontSize: isSmall ? 9 : 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: isSmall ? 6 : 8),
                      Expanded(
                        child: Text(
                          siswa.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: isSmall ? 13 : 14,
                            color: const Color(0xFF1F2937),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmall ? 3 : 4),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmall ? 5 : 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0083EE).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          siswa.kelas,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF0083EE),
                            fontSize: isSmall ? 9 : 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: isSmall ? 6 : 8),
                      Icon(
                        Icons.star,
                        color: const Color(0xFFFFD700),
                        size: isSmall ? 12 : 13,
                      ),
                      SizedBox(width: isSmall ? 3 : 4),
                      Text(
                        '${siswa.poin} poin',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF6B7280),
                          fontSize: isSmall ? 10 : 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: isSmall ? 8 : 10),
            Container(
              padding: EdgeInsets.all(isSmall ? 6 : 7),
              decoration: BoxDecoration(
                color: rankColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.trending_up,
                  color: rankColor, size: isSmall ? 16 : 18),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildCompactSiswaBeratItem(
    Student siswa,
    bool isSmall,
    VoidCallback onTap,
  ) {
    Color rankColor = StudentUtils.getRankColor(siswa.rank);
    final avatarSize = isSmall ? 42.0 : 46.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isSmall ? 10 : 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(isSmall ? 12 : 14),
          border: Border.all(color: rankColor.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: rankColor.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6D), Color(0xFFFF8E8F)],
                ),
                borderRadius: BorderRadius.circular(avatarSize / 2),
                boxShadow: [
                  BoxShadow(
                    color: rankColor.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.person,
                      color: Colors.white, size: isSmall ? 20 : 22),
                  if (siswa.rank <= 3)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: isSmall ? 16 : 18,
                        height: isSmall ? 16 : 18,
                        decoration: BoxDecoration(
                          color: rankColor,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Icon(
                          StudentUtils.getRankIcon(siswa.rank),
                          color: Colors.white,
                          size: isSmall ? 8 : 9,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: isSmall ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmall ? 6 : 7,
                          vertical: isSmall ? 2 : 3,
                        ),
                        decoration: BoxDecoration(
                          color: rankColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: rankColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '#${siswa.rank}',
                          style: GoogleFonts.poppins(
                            color: rankColor,
                            fontSize: isSmall ? 9 : 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: isSmall ? 6 : 8),
                      Expanded(
                        child: Text(
                          siswa.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: isSmall ? 13 : 14,
                            color: const Color(0xFF1F2937),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmall ? 3 : 4),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmall ? 5 : 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0083EE).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          siswa.kelas,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF0083EE),
                            fontSize: isSmall ? 9 : 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: isSmall ? 6 : 8),
                      Icon(
                        Icons.warning_amber_rounded,
                        color: const Color(0xFFFF6B6D),
                        size: isSmall ? 12 : 13,
                      ),
                      SizedBox(width: isSmall ? 3 : 4),
                      Text(
                        '${siswa.poin} poin',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFFF6B6D),
                          fontSize: isSmall ? 10 : 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: isSmall ? 8 : 10),
            Container(
              padding: EdgeInsets.all(isSmall ? 6 : 7),
              decoration: BoxDecoration(
                color: rankColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.trending_down,
                  color: rankColor, size: isSmall ? 16 : 18),
            ),
          ],
        ),
      ),
    );
  }
}