import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/notif_colors.dart';

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

  static const _filters = ['Semua', 'Belum Dibaca', 'Sudah Dibaca'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(fontSize, fontSize, fontSize, fontSize * 0.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Notifikasi',
              style: GoogleFonts.poppins(
                fontSize: fontSize * 1.1,
                fontWeight: FontWeight.w700,
                color: NotifColors.textPrimary,
              ),
            ),
            SizedBox(height: fontSize),
            ..._filters.map(
              (filter) => ListTile(
                title: Text(
                  filter,
                  style: GoogleFonts.poppins(
                    fontSize: fontSize * 0.9,
                    fontWeight: FontWeight.w500,
                    color: selectedFilter == filter
                        ? NotifColors.primary
                        : NotifColors.textPrimary,
                  ),
                ),
                leading: Radio<String>(
                  value: filter,
                  groupValue: selectedFilter,
                  onChanged: (value) {
                    onFilterSelected(value!);
                    Navigator.pop(context);
                  },
                  activeColor: NotifColors.primary,
                ),
                onTap: () {
                  onFilterSelected(filter);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotifEmptyState extends StatelessWidget {
  final double fontSize;
  final String status;

  const NotifEmptyState({
    super.key,
    required this.fontSize,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = NotifColors.headerGradient(status);
    final shadow = NotifColors.headerShadow(status);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: fontSize * 7.5,
            height: fontSize * 7.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(fontSize * 3.75),
              boxShadow: [
                BoxShadow(color: shadow, blurRadius: 20, offset: const Offset(0, 10)),
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
              color: NotifColors.textPrimary,
            ),
          ),
          SizedBox(height: fontSize * 0.5),
          Text(
            'Semua notifikasi akan muncul di sini',
            style: GoogleFonts.poppins(
              fontSize: fontSize * 0.9,
              color: NotifColors.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}