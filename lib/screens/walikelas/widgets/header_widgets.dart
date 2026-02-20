import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HeaderWidgets {

  static Widget buildCompactIconButton(
    IconData icon,
    VoidCallback onTap,
    bool isSmall,
  ) {
    final size = isSmall ? 36.0 : 40.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: isSmall ? 20 : 22,
        ),
      ),
    );
  }

  static Widget buildCompactProfileButton(VoidCallback onTap, bool isSmall) {
    final size = isSmall ? 36.0 : 40.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.person_rounded,
          color: const Color(0xFF0083EE),
          size: isSmall ? 20 : 22,
        ),
      ),
    );
  }

  static Widget buildCompactSearchBar(
    bool isSmall,
    Function(String) onChanged,
  ) {
    return Container(
      height: isSmall ? 44 : 48,
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmall ? 20 : 24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmall ? 6 : 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF61B8FF), Color(0xFF0083EE)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.search,
              color: Colors.white,
              size: isSmall ? 16 : 17,
            ),
          ),
          SizedBox(width: isSmall ? 10 : 12),
          
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Cari siswa atau kelas...',
                hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFF9CA3AF),
                  fontSize: isSmall ? 13 : 14,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: GoogleFonts.poppins(
                fontSize: isSmall ? 13 : 14,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildActionButton(
    String text,
    int index,
    int selectedTab,
    VoidCallback onTap,
  ) {
    bool isActive = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isActive && index == 0)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B6D), Color(0xFFFF8E8F)],
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              if (isActive && index == 2)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              if (isActive && index == 3)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B6D), Color(0xFFFF8E8F)],
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: isActive ? const Color(0xFF1F2937) : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}