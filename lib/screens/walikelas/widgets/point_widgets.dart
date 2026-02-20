import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PointHeaderWidget extends StatelessWidget {
  final VoidCallback onClose;

  const PointHeaderWidget({Key? key, required this.onClose}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add_circle_outline, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tambah Poin',
                  style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
                  ),
                ),
                Text(
                  'Isi formulir di bawah ini',
                  style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class PointTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;

  const PointTextField({
    Key? key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // FIX: readOnly fields get a distinct background so users know they can't edit them
    final fillColor = readOnly ? const Color(0xFFF3F4F6) : Colors.white;
    final textColor = readOnly ? const Color(0xFF6B7280) : const Color(0xFF374151);

    // FIX: readOnly fields never show a focused blue border — only the enabled grey one
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    );

    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      style: GoogleFonts.poppins(fontSize: 14, color: textColor, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF9CA3AF)),
        prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
        filled: true,
        fillColor: fillColor,
        border: baseBorder,
        enabledBorder: baseBorder,
        focusedBorder: readOnly
            ? baseBorder
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
              ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class PointTypeDropdownWidget extends StatelessWidget {
  final String selectedPointType;
  final ValueChanged<String> onChanged;

  const PointTypeDropdownWidget({
    Key? key,
    required this.selectedPointType,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isViolation = selectedPointType == 'Pelanggaran';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(
            isViolation ? Icons.warning_rounded : Icons.star_rounded,
            color: isViolation ? const Color(0xFFEF4444) : const Color(0xFFFBBF24),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedPointType,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
                items: ['Pelanggaran', 'Apresiasi'].map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(
                    type,
                    style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF374151),
                    ),
                  ),
                )).toList(),
                onChanged: (v) { if (v != null) onChanged(v); },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryDropdownWidget extends StatelessWidget {
  final String selectedCategory;
  final List<Map<String, dynamic>> aspekPenilaian;
  final ValueChanged<String> onChanged;
  final bool isLoading;
  final String? errorMessage;

  const CategoryDropdownWidget({
    Key? key,
    required this.selectedCategory,
    required this.aspekPenilaian,
    required this.onChanged,
    required this.isLoading,
    this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // FIX: loading state had no min height — layout collapsed to 0px
    if (isLoading) {
      return Container(
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Center(
          child: SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Color(0xFF3B82F6)),
            ),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                errorMessage!,
                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFEF4444)),
              ),
            ),
          ],
        ),
      );
    }

    if (aspekPenilaian.isEmpty) {
      return Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const Icon(Icons.category_outlined, color: Color(0xFF9CA3AF), size: 20),
            const SizedBox(width: 12),
            Text(
              'Tidak ada kategori ditemukan',
              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.category_outlined, color: Color(0xFF6B7280), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCategory.isEmpty ? null : selectedCategory,
                isExpanded: true,
                hint: Text(
                  'Pilih Kategori',
                  style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF9CA3AF)),
                ),
                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
                items: aspekPenilaian.map((aspek) => DropdownMenuItem(
                  value: aspek['id_aspekpenilaian'].toString(),
                  child: Text(
                    // FIX: long text now truncates with ellipsis instead of overflowing
                    '${aspek['kategori']} - ${aspek['uraian']} (${aspek['indikator_poin']} poin)',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF374151),
                    ),
                  ),
                )).toList(),
                onChanged: (v) { if (v != null) onChanged(v); },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PointFormWidget extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController nisController;
  final TextEditingController classController;
  final TextEditingController dateController;
  final TextEditingController idPenilaianController;
  final TextEditingController categorySearchController;
  final String selectedPointType;
  final String selectedCategory;
  final List<Map<String, dynamic>> aspekPenilaian;
  final ValueChanged<String> onCategorySearchChanged;
  final ValueChanged<String> onPointTypeChanged;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onDateTap;
  final bool isLoadingCategories;
  final String? errorMessageCategories;

  const PointFormWidget({
    Key? key,
    required this.nameController,
    required this.nisController,
    required this.classController,
    required this.dateController,
    required this.idPenilaianController,
    required this.categorySearchController,
    required this.selectedPointType,
    required this.selectedCategory,
    required this.aspekPenilaian,
    required this.onCategorySearchChanged,
    required this.onPointTypeChanged,
    required this.onCategoryChanged,
    required this.onDateTap,
    required this.isLoadingCategories,
    required this.errorMessageCategories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      // FIX: added bottom padding so CategoryDropdown doesn't sit flush against ActionButtons
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PointTextField(
            controller: nameController,
            hint: 'Nama Lengkap',
            icon: Icons.person_outline,
            readOnly: true,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: PointTextField(
                  controller: nisController,
                  hint: 'NIS',
                  icon: Icons.badge,
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PointTextField(
                  controller: classController,
                  hint: 'Kelas',
                  icon: Icons.school_outlined,
                  readOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: PointTextField(
                  controller: idPenilaianController,
                  hint: 'ID Penilaian',
                  icon: Icons.tag,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PointTextField(
                  controller: dateController,
                  hint: 'Tanggal',
                  icon: Icons.calendar_today_outlined,
                  readOnly: true,
                  onTap: onDateTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          PointTypeDropdownWidget(
            selectedPointType: selectedPointType,
            onChanged: onPointTypeChanged,
          ),
          const SizedBox(height: 14),
          PointTextField(
            controller: categorySearchController,
            hint: 'Cari kategori / uraian / kode...',
            icon: Icons.search,
            onChanged: onCategorySearchChanged,
          ),
          const SizedBox(height: 10),
          CategoryDropdownWidget(
            selectedCategory: selectedCategory,
            aspekPenilaian: aspekPenilaian,
            onChanged: onCategoryChanged,
            isLoading: isLoadingCategories,
            errorMessage: errorMessageCategories,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class PointActionButtons extends StatelessWidget {
  final bool isSubmitting;
  final String selectedPointType;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const PointActionButtons({
    Key? key,
    required this.isSubmitting,
    required this.selectedPointType,
    required this.onCancel,
    required this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isViolation = selectedPointType == 'Pelanggaran';
  
    final submitColors = isViolation
        ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
        : [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)];
    final submitShadowColor = isViolation
        ? const Color(0xFFEF4444)
        : const Color(0xFF3B82F6);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: isSubmitting ? null : onCancel,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  'Batal',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: isSubmitting ? null : onSubmit,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: submitColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: submitShadowColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: isSubmitting
                    ? const Center(
                        child: SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                      )
                    : Text(
                        'Tambah ${selectedPointType == 'Pelanggaran' ? 'Pelanggaran' : 'Apresiasi'}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}