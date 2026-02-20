import 'package:flutter/material.dart';
import 'package:skoring/screens/walikelas/services/point_services.dart';
import 'package:skoring/screens/walikelas/utils/point_utils.dart';
import 'package:skoring/screens/walikelas/widgets/point_widgets.dart';

class PointPopup extends StatefulWidget {
  final String studentName;
  final String nis;
  final String className;

  const PointPopup({
    Key? key,
    required this.studentName,
    required this.nis,
    required this.className,
  }) : super(key: key);

  @override
  State<PointPopup> createState() => PointPopupState();
}

class PointPopupState extends State<PointPopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController nisController = TextEditingController();
  final TextEditingController classController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController idPenilaianController = TextEditingController();
  final TextEditingController categorySearchController = TextEditingController();

  String selectedPointType = 'Pelanggaran';
  String selectedCategory = '';
  String categorySearch = '';
  bool isSubmitting = false;
  bool isLoadingCategories = true;
  String? errorMessageCategories;
  List<Map<String, dynamic>> aspekPenilaian = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    nameController.text = widget.studentName;
    nisController.text = widget.nis;
    classController.text = widget.className;
    dateController.text = DateTime.now().toString().split(' ')[0];
    idPenilaianController.text = PointUtils.generateIdPenilaian();
    _fetchAspekPenilaian();
  }

  void _initAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 260),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  Future<void> _fetchAspekPenilaian() async {
    setState(() {
      isLoadingCategories = true;
      errorMessageCategories = null;
    });
    try {
      final data = await PointService.fetchAspekPenilaian();
      if (!mounted) return;
      setState(() {
        aspekPenilaian = data;
        selectedCategory = PointUtils.defaultCategoryFor(
          aspekPenilaian: aspekPenilaian,
          pointType: selectedPointType,
        );
        isLoadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessageCategories = e.toString();
        isLoadingCategories = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    nameController.dispose();
    nisController.dispose();
    classController.dispose();
    dateController.dispose();
    idPenilaianController.dispose();
    categorySearchController.dispose();
    super.dispose();
  }

  void _closeDialog() {
    _controller.reverse().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _onPointTypeChanged(String value) {
    setState(() {
      selectedPointType = value;
      categorySearch = '';
      categorySearchController.clear();
      selectedCategory = PointUtils.defaultCategoryFor(
        aspekPenilaian: aspekPenilaian,
        pointType: selectedPointType,
      );
    });
  }

  void _onCategorySearchChanged(String value) {
    setState(() {
      categorySearch = value;
      final filtered = _filteredAspek;
      if (filtered.isNotEmpty &&
          !filtered.any((a) => a['id_aspekpenilaian'].toString() == selectedCategory)) {
        selectedCategory = filtered.first['id_aspekpenilaian'].toString();
      }
    });
  }

  List<Map<String, dynamic>> get _filteredAspek => PointUtils.filterAspek(
        aspekPenilaian: aspekPenilaian,
        pointType: selectedPointType,
        searchQuery: categorySearch,
      );

  Future<void> _submitPoint() async {
    setState(() => isSubmitting = true);

    final selectedAspek = aspekPenilaian.firstWhere(
      (a) => a['id_aspekpenilaian'].toString() == selectedCategory,
      orElse: () => {},
    );

    if (selectedAspek.isEmpty) {
      if (!mounted) return;
      setState(() => isSubmitting = false);
      PointSnackBar.error(context, 'Kategori tidak valid');
      return;
    }

    final point = await PointService.submitPoint(
      type: selectedPointType,
      studentName: nameController.text,
      nis: nisController.text,
      idPenilaian: idPenilaianController.text,
      idAspekPenilaian: selectedCategory,
      date: dateController.text,
      category: selectedAspek['kategori'] ?? '',
      description: selectedAspek['uraian'] ?? '',
      points: int.parse(selectedAspek['indikator_poin'].toString()),
      context: context,
    );

    if (!mounted) return;
    setState(() => isSubmitting = false);
    if (point != null) _closeDialog();
  }

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
      setState(() => dateController.text = picked.toString().split(' ')[0]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final topPadding = mediaQuery.padding.top;
    final bottomInset = mediaQuery.viewInsets.bottom;
    final maxHeight = screenHeight - topPadding - bottomInset - 48;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: SafeArea(
          bottom: false,
          child: AnimatedPadding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: 420,
                      maxHeight: maxHeight.clamp(400, double.infinity),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PointHeaderWidget(onClose: _closeDialog),
                            PointFormWidget(
                              nameController: nameController,
                              nisController: nisController,
                              classController: classController,
                              dateController: dateController,
                              idPenilaianController: idPenilaianController,
                              categorySearchController: categorySearchController,
                              selectedPointType: selectedPointType,
                              selectedCategory: selectedCategory,
                              aspekPenilaian: _filteredAspek,
                              onCategorySearchChanged: _onCategorySearchChanged,
                              onPointTypeChanged: _onPointTypeChanged,
                              onCategoryChanged: (v) => setState(() => selectedCategory = v),
                              onDateTap: _pickDate,
                              isLoadingCategories: isLoadingCategories,
                              errorMessageCategories: errorMessageCategories,
                            ),
                            PointActionButtons(
                              isSubmitting: isSubmitting,
                              selectedPointType: selectedPointType,
                              onCancel: _closeDialog,
                              onSubmit: _submitPoint,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showPointPopup(
  BuildContext context,
  String studentName,
  String nis,
  String className,
) {
  showDialog(
    context: context,
    barrierDismissible: false,

    barrierColor: Colors.transparent,
    builder: (_) => Material(
      color: Colors.transparent,
      child: PointPopup(
        studentName: studentName,
        nis: nis,
        className: className,
      ),
    ),
  );
}