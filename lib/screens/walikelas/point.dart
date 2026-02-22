import 'package:flutter/material.dart';
import 'package:skoring/screens/walikelas/services/point_services.dart';
import 'package:skoring/screens/walikelas/utils/point_utils.dart';
import 'package:skoring/screens/walikelas/widgets/point_widgets.dart';

// ─── Show Helper ─────────────────────────────────────────────────────────────

void showPointPopup(BuildContext context, String studentName, String nis, String className) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => PointSheet(studentName: studentName, nis: nis, className: className),
  );
}

// ─── Bottom Sheet Widget ──────────────────────────────────────────────────────

class PointSheet extends StatefulWidget {
  final String studentName;
  final String nis;
  final String className;

  const PointSheet({
    Key? key,
    required this.studentName,
    required this.nis,
    required this.className,
  }) : super(key: key);

  @override
  State<PointSheet> createState() => _PointSheetState();
}

class _PointSheetState extends State<PointSheet> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  final _categorySearchController = TextEditingController();

  String _selectedPointType = 'Pelanggaran';
  String _selectedCategory = '';
  String _categorySearch = '';
  String _date = DateTime.now().toString().split(' ')[0];

  bool _isSubmitting = false;
  bool _isLoadingCategories = true;
  String? _errorMessageCategories;
  List<Map<String, dynamic>> _aspekPenilaian = [];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _fetchAspekPenilaian();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _categorySearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAspekPenilaian() async {
    setState(() { _isLoadingCategories = true; _errorMessageCategories = null; });
    try {
      final data = await PointService.fetchAspekPenilaian();
      if (!mounted) return;
      setState(() {
        _aspekPenilaian = data;
        _selectedCategory = PointUtils.defaultCategoryFor(
          aspekPenilaian: _aspekPenilaian,
          pointType: _selectedPointType,
        );
        _isLoadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _errorMessageCategories = e.toString(); _isLoadingCategories = false; });
    }
  }

  void _close() {
    _animCtrl.reverse().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _onPointTypeChanged(String value) {
    setState(() {
      _selectedPointType = value;
      _categorySearch = '';
      _categorySearchController.clear();
      _selectedCategory = PointUtils.defaultCategoryFor(
        aspekPenilaian: _aspekPenilaian,
        pointType: _selectedPointType,
      );
    });
  }

  void _onCategorySearchChanged(String value) {
    setState(() {
      _categorySearch = value;
      final filtered = _filteredAspek;
      if (filtered.isNotEmpty &&
          !filtered.any((a) => a['id_aspekpenilaian'].toString() == _selectedCategory)) {
        _selectedCategory = filtered.first['id_aspekpenilaian'].toString();
      }
    });
  }

  List<Map<String, dynamic>> get _filteredAspek => PointUtils.filterAspek(
    aspekPenilaian: _aspekPenilaian,
    pointType: _selectedPointType,
    searchQuery: _categorySearch,
  );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF3B82F6)),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked.toString().split(' ')[0]);
    }
  }

  Future<void> _submitPoint() async {
    setState(() => _isSubmitting = true);

    final selectedAspek = _aspekPenilaian.firstWhere(
      (a) => a['id_aspekpenilaian'].toString() == _selectedCategory,
      orElse: () => {},
    );

    if (selectedAspek.isEmpty) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      PointSnackBar.error(context, 'Kategori tidak valid');
      return;
    }

    final point = await PointService.submitPoint(
      type: _selectedPointType,
      studentName: widget.studentName,
      nis: widget.nis,
      idPenilaian: PointUtils.generateIdPenilaian(),
      idAspekPenilaian: _selectedCategory,
      date: _date,
      category: selectedAspek['kategori'] ?? '',
      description: selectedAspek['uraian'] ?? '',
      points: int.parse(selectedAspek['indikator_poin'].toString()),
      context: context,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (point != null) _close();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomInset = mq.viewInsets.bottom;
    final isViolation = _selectedPointType == 'Pelanggaran';

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            PointSheetHeader(isViolation: isViolation, onClose: _close),

            // Scrollable body
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 70),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Student info (read-only) ──────────────────
                    const _SectionLabel(label: 'Informasi Siswa', icon: Icons.person_outline_rounded),
                    const SizedBox(height: 8),
                    _ReadOnlyTile(
                      value: widget.studentName,
                      label: 'Nama Siswa',
                      icon: Icons.person_rounded,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _ReadOnlyTile(
                            value: widget.nis,
                            label: 'NIS',
                            icon: Icons.badge_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ReadOnlyTile(
                            value: widget.className,
                            label: 'Kelas',
                            icon: Icons.class_rounded,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Penilaian ─────────────────────────────────
                    const _SectionLabel(label: 'Detail Penilaian', icon: Icons.assignment_rounded),
                    const SizedBox(height: 8),

                    // Date picker
                    GestureDetector(
                      onTap: _pickDate,
                      child: _ReadOnlyTile(
                        value: _date,
                        label: 'Tanggal Penilaian',
                        icon: Icons.calendar_today_rounded,
                        trailingIcon: Icons.edit_calendar_rounded,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Point type selector
                    PointTypeDropdownWidget(
                      selectedPointType: _selectedPointType,
                      onChanged: _onPointTypeChanged,
                    ),

                    const SizedBox(height: 20),

                    // ── Kategori ──────────────────────────────────
                    const _SectionLabel(label: 'Kategori Penilaian', icon: Icons.category_rounded),
                    const SizedBox(height: 8),

                    // Search field
                    PointTextField(
                      controller: _categorySearchController,
                      hint: 'Cari kategori atau uraian...',
                      icon: Icons.search_rounded,
                      onChanged: _onCategorySearchChanged,
                    ),
                    const SizedBox(height: 8),

                    // Category dropdown
                    CategoryDropdownWidget(
                      selectedCategory: _selectedCategory,
                      aspekPenilaian: _filteredAspek,
                      onChanged: (v) => setState(() => _selectedCategory = v),
                      isLoading: _isLoadingCategories,
                      errorMessage: _errorMessageCategories,
                    ),

                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting ? null : _close,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text('Batal',
                                style: const TextStyle().copyWith(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6B7280),
                                    fontSize: 14)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isViolation
                                    ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                                    : [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: (isViolation
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF3B82F6))
                                      .withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isSubmitting ? null : _submitPoint,
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  child: _isSubmitting
                                      ? const Center(
                                          child: SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation(Colors.white)),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              isViolation
                                                  ? Icons.warning_rounded
                                                  : Icons.star_rounded,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Tambah ${isViolation ? 'Pelanggaran' : 'Apresiasi'}',
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class PointSheetHeader extends StatelessWidget {
  final bool isViolation;
  final VoidCallback onClose;

  const PointSheetHeader({Key? key, required this.isViolation, required this.onClose})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gradientColors = isViolation
        ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
        : [const Color(0xFF10B981), const Color(0xFF059669)];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Container(
              key: ValueKey(isViolation),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isViolation ? Icons.warning_amber_rounded : Icons.star_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    key: ValueKey(isViolation),
                    isViolation ? 'Tambah Pelanggaran' : 'Tambah Apresiasi',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Poppins'),
                  ),
                ),
                Text(
                  'Isi data penilaian siswa',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.85),
                      fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
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

// ─── Shared private widgets (only used in this file) ─────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
              letterSpacing: 0.5),
        ),
      ],
    );
  }
}

class _ReadOnlyTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final IconData? trailingIcon;

  const _ReadOnlyTile({
    required this.value,
    required this.label,
    required this.icon,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: const Color(0xFFD1D5DB)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 1),
                Text(value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (trailingIcon != null)
            Icon(trailingIcon, size: 15, color: const Color(0xFF3B82F6)),
        ],
      ),
    );
  }
}