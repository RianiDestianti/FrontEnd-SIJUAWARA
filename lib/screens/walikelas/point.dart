import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skoring/models/types/point.dart';
import 'package:skoring/config/api.dart';

class PointUtils {
  static Future<Point?> submitPoint({
    required String type,
    required String studentName,
    required String nis,
    required String idPenilaian,
    required String idAspekPenilaian,
    required String date,
    required String category,
    required String description,
    required int points,
    required BuildContext context,
  }) async {
    if (idPenilaian.isEmpty ||
        nis.isEmpty ||
        idAspekPenilaian.isEmpty ||
        date.isEmpty ||
        category.isEmpty) {
      print('Validation failed: Some fields are empty');
      if (context.mounted) {
        showErrorSnackBar(
          context,
          'Mohon lengkapi semua field yang diperlukan',
        );
      }
      return null;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final nip = prefs.getString('walikelas_id') ?? '';
      final idKelas = prefs.getString('id_kelas') ?? '';

      if (nip.isEmpty || idKelas.isEmpty) {
        if (context.mounted) {
          showErrorSnackBar(
            context,
            'Data guru tidak lengkap. Silakan login ulang.',
          );
        }
        return null;
      }

      final endpoint =
          type == 'Apresiasi'
              ? '${ApiConfig.baseUrl}/skoring_penghargaan?nip=$nip&id_kelas=$idKelas'
              : '${ApiConfig.baseUrl}/skoring_pelanggaran?nip=$nip&id_kelas=$idKelas';

      print('Sending POST request to $endpoint');
      print(
        'Request body: ${jsonEncode({'id_penilaian': idPenilaian, 'nis': nis, 'id_aspekpenilaian': idAspekPenilaian, 'nip_walikelas': nip})}',
      );

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'id_penilaian': idPenilaian,
          'nis': nis,
          'id_aspekpenilaian': idAspekPenilaian,
          'nip_walikelas': nip,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['success'] == true ||
              (responseData['message']?.toString().contains('berhasil') ??
                  false)) {
            final pointData = Point(
              type: type,
              studentName: studentName,
              nis: nis,
              className: '',
              date: date,
              description: description,
              category: category,
              points: points,
              idPenilaian: idPenilaian,
            );

            if (context.mounted) {
              showSuccessSnackBar(
                context,
                'Poin $type berhasil ditambahkan untuk $studentName',
              );
            }
            return pointData;
          } else {
            if (context.mounted) {
              showErrorSnackBar(
                context,
                responseData['message'] ?? 'Gagal menambahkan poin',
              );
            }
            return null;
          }
        } catch (e) {
          print('JSON decode error: $e');
          if (context.mounted) {
            showErrorSnackBar(
              context,
              'Invalid server response: Expected JSON, received invalid data',
            );
          }
          return null;
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          if (context.mounted) {
            showErrorSnackBar(
              context,
              errorData['message'] ??
                  'Gagal menghubungi server: ${response.statusCode}',
            );
          }
        } catch (e) {
          if (context.mounted) {
            showErrorSnackBar(
              context,
              'Gagal menghubungi server: ${response.statusCode}',
            );
          }
        }
        return null;
      }
    } catch (e) {
      print('Error during HTTP request: $e');
      if (context.mounted) {
        showErrorSnackBar(context, 'Terjadi kesalahan: $e');
      }
      return null;
    }
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

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

class PointPopupState extends State<PointPopup> with TickerProviderStateMixin {
  late AnimationController animationController;
  late AnimationController slideController;
  late Animation<double> scaleAnimation;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;
  late Animation<double> rotateAnimation;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController nisController = TextEditingController();
  final TextEditingController classController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController idPenilaianController = TextEditingController();
  String selectedPointType = 'Pelanggaran';
  String selectedCategory = '';
  bool isSubmitting = false;
  bool isLoadingCategories = true;
  String? errorMessageCategories;
  List<Map<String, dynamic>> aspekPenilaian = [];
  final TextEditingController categorySearchController =
      TextEditingController();
  String categorySearch = '';

  @override
  void initState() {
    super.initState();
    initializeAnimations();
    nameController.text = widget.studentName;
    nisController.text = widget.nis;
    classController.text = widget.className;
    dateController.text = DateTime.now().toString().split(' ')[0];
    idPenilaianController.text = generateIdPenilaian();
    fetchAspekPenilaian();
  }

  void initializeAnimations() {
    animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.elasticOut),
    );
    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOut),
    );
    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOutCubic),
    );
    rotateAnimation = Tween<double>(begin: 0.1, end: 0.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOut),
    );

    animationController.forward();
  }

  String generateIdPenilaian() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final shortId = (timestamp % 1000000000).toString().padLeft(9, '0');
    return shortId;
  }

  Future<void> fetchAspekPenilaian() async {
    setState(() {
      isLoadingCategories = true;
      errorMessageCategories = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final nip = prefs.getString('walikelas_id') ?? '';
      final idKelas = prefs.getString('id_kelas') ?? '';

      if (nip.isEmpty || idKelas.isEmpty) {
        setState(() {
          errorMessageCategories =
              'Data guru tidak lengkap. Silakan login ulang.';
          isLoadingCategories = false;
        });
        return;
      }

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/aspekpenilaian?nip=$nip&id_kelas=$idKelas',
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success']) {
          setState(() {
            aspekPenilaian = List<Map<String, dynamic>>.from(jsonData['data']);
            if (aspekPenilaian.isNotEmpty) {
              selectedCategory =
                  aspekPenilaian
                      .firstWhere(
                        (aspek) => aspek['jenis_poin'] == selectedPointType,
                        orElse: () => aspekPenilaian[0],
                      )['id_aspekpenilaian']
                      .toString();
            }
            isLoadingCategories = false;
          });
        } else {
          setState(() {
            errorMessageCategories = jsonData['message'];
            isLoadingCategories = false;
          });
        }
      } else {
        setState(() {
          errorMessageCategories = 'Gagal mengambil data aspek penilaian';
          isLoadingCategories = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessageCategories = 'Terjadi kesalahan: $e';
        isLoadingCategories = false;
      });
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    slideController.dispose();
    nameController.dispose();
    nisController.dispose();
    classController.dispose();
    dateController.dispose();
    idPenilaianController.dispose();
    categorySearchController.dispose();
    super.dispose();
  }

  void closeDialog() {
    animationController.reverse().then((unused) => Navigator.of(context).pop());
  }

  void submitPoint() async {
    setState(() => isSubmitting = true);
    final selectedAspek = aspekPenilaian.firstWhere(
      (aspek) => aspek['id_aspekpenilaian'].toString() == selectedCategory,
      orElse: () => {},
    );
    if (selectedAspek.isEmpty) {
      setState(() => isSubmitting = false);
      PointUtils.showErrorSnackBar(context, 'Kategori tidak valid');
      return;
    }
    print(
      'Submitting point: type=$selectedPointType, nis=${nisController.text}, '
      'idPenilaian=${idPenilaianController.text}, idAspekPenilaian=$selectedCategory, '
      'category=${selectedAspek['kategori']}, description=${selectedAspek['uraian']}, '
      'points=${selectedAspek['indikator_poin']}',
    );
    final point = await PointUtils.submitPoint(
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
    setState(() => isSubmitting = false);
    if (point != null) {
      closeDialog();
    }
  }

  Future<void> pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF3B82F6)),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        dateController.text = pickedDate.toString().split(' ')[0];
      });
    }
  }

  void onPointTypeChanged(String value) {
    setState(() {
      selectedPointType = value;
      categorySearch = '';
      categorySearchController.clear();
      selectedCategory =
          aspekPenilaian
              .firstWhere(
                (aspek) => aspek['jenis_poin'] == selectedPointType,
                orElse:
                    () => aspekPenilaian.isNotEmpty ? aspekPenilaian[0] : {},
              )['id_aspekpenilaian']
              ?.toString() ??
          '';
    });
  }

  List<Map<String, dynamic>> get filteredAspekPenilaian {
    final query = categorySearch.toLowerCase();
    return aspekPenilaian
        .where((aspek) => aspek['jenis_poin'] == selectedPointType)
        .where(
          (aspek) =>
              query.isEmpty ||
              (aspek['kategori']?.toString().toLowerCase().contains(query) ??
                  false) ||
              (aspek['uraian']?.toString().toLowerCase().contains(query) ??
                  false) ||
              (aspek['kode']?.toString().toLowerCase().contains(query) ??
                  false),
        )
        .toList();
  }

  void onCategorySearchChanged(String value) {
    setState(() {
      categorySearch = value;
      final filtered = filteredAspekPenilaian;
      if (filtered.isNotEmpty &&
          !filtered.any(
            (aspek) =>
                aspek['id_aspekpenilaian'].toString() == selectedCategory,
          )) {
        selectedCategory = filtered.first['id_aspekpenilaian'].toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: SlideTransition(
            position: slideAnimation,
            child: RotationTransition(
              turns: rotateAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: Material(
                  color: Colors.transparent,
                  child: PointDialogContent(
                    nameController: nameController,
                    nisController: nisController,
                    classController: classController,
                    dateController: dateController,
                    idPenilaianController: idPenilaianController,
                    selectedPointType: selectedPointType,
                    selectedCategory: selectedCategory,
                    aspekPenilaian: filteredAspekPenilaian,
                    categorySearchController: categorySearchController,
                    onCategorySearchChanged: onCategorySearchChanged,
                    onPointTypeChanged: onPointTypeChanged,
                    onCategoryChanged:
                        (value) => setState(() => selectedCategory = value),
                    isSubmitting: isSubmitting,
                    isLoadingCategories: isLoadingCategories,
                    errorMessageCategories: errorMessageCategories,
                    onClose: closeDialog,
                    onSubmit: submitPoint,
                    onDateTap: pickDate,
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

class PointDialogContent extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController nisController;
  final TextEditingController classController;
  final TextEditingController dateController;
  final TextEditingController categorySearchController;
  final TextEditingController idPenilaianController;
  final String selectedPointType;
  final String selectedCategory;
  final List<Map<String, dynamic>> aspekPenilaian;
  final ValueChanged<String> onCategorySearchChanged;
  final ValueChanged<String> onPointTypeChanged;
  final ValueChanged<String> onCategoryChanged;
  final bool isSubmitting;
  final bool isLoadingCategories;
  final String? errorMessageCategories;
  final VoidCallback onClose;
  final VoidCallback onSubmit;
  final VoidCallback onDateTap;

  const PointDialogContent({
    Key? key,
    required this.nameController,
    required this.nisController,
    required this.classController,
    required this.dateController,
    required this.categorySearchController,
    required this.idPenilaianController,
    required this.selectedPointType,
    required this.selectedCategory,
    required this.aspekPenilaian,
    required this.onCategorySearchChanged,
    required this.onPointTypeChanged,
    required this.onCategoryChanged,
    required this.isSubmitting,
    required this.isLoadingCategories,
    required this.errorMessageCategories,
    required this.onClose,
    required this.onSubmit,
    required this.onDateTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.9;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      constraints: BoxConstraints(maxWidth: 420, maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HeaderSection(onClose: onClose),
              FormSection(
                nameController: nameController,
                nisController: nisController,
                classController: classController,
                dateController: dateController,
                idPenilaianController: idPenilaianController,
                selectedPointType: selectedPointType,
                selectedCategory: selectedCategory,
                aspekPenilaian: aspekPenilaian,
                categorySearchController: categorySearchController,
                onCategorySearchChanged: onCategorySearchChanged,
                onPointTypeChanged: onPointTypeChanged,
                onCategoryChanged: onCategoryChanged,
                onDateTap: onDateTap,
                isLoadingCategories: isLoadingCategories,
                errorMessageCategories: errorMessageCategories,
              ),
              ActionButtons(
                isSubmitting: isSubmitting,
                onCancel: onClose,
                onSubmit: onSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HeaderSection extends StatelessWidget {
  final VoidCallback onClose;

  const HeaderSection({Key? key, required this.onClose}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
            child: const Icon(
              Icons.add_circle_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tambah Poin',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Isi formulir di bawah ini',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
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
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class FormSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController nisController;
  final TextEditingController classController;
  final TextEditingController dateController;
  final TextEditingController categorySearchController;
  final TextEditingController idPenilaianController;
  final String selectedPointType;
  final String selectedCategory;
  final List<Map<String, dynamic>> aspekPenilaian;
  final ValueChanged<String> onCategorySearchChanged;
  final ValueChanged<String> onPointTypeChanged;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onDateTap;
  final bool isLoadingCategories;
  final String? errorMessageCategories;

  const FormSection({
    Key? key,
    required this.nameController,
    required this.nisController,
    required this.classController,
    required this.dateController,
    required this.categorySearchController,
    required this.idPenilaianController,
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
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CustomTextField(
            controller: nameController,
            hint: 'Nama Lengkap',
            icon: Icons.person_outline,
            readOnly: true,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: nisController,
            hint: 'NIS',
            icon: Icons.badge,
            readOnly: true,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: classController,
            hint: 'Kelas',
            icon: Icons.school_outlined,
            readOnly: true,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: idPenilaianController,
            hint: 'ID Penilaian',
            icon: Icons.badge,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: dateController,
            hint: 'Tanggal',
            icon: Icons.calendar_today_outlined,
            readOnly: true,
            onTap: onDateTap,
          ),
          const SizedBox(height: 16),
          PointTypeDropdown(
            selectedPointType: selectedPointType,
            onChanged: onPointTypeChanged,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: categorySearchController,
            hint: 'Cari kategori / uraian / kode',
            icon: Icons.search,
            onTap: () {},
            readOnly: false,
            onChanged: onCategorySearchChanged,
          ),
          const SizedBox(height: 12),
          CategoryDropdown(
            selectedCategory: selectedCategory,
            aspekPenilaian: aspekPenilaian,
            onChanged: onCategoryChanged,
            isLoading: isLoadingCategories,
            errorMessage: errorMessageCategories,
          ),
        ],
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final int maxLines;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF9CA3AF),
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(0xFF374151),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class PointTypeDropdown extends StatelessWidget {
  final String selectedPointType;
  final ValueChanged<String> onChanged;

  const PointTypeDropdown({
    Key? key,
    required this.selectedPointType,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pointTypes = ['Pelanggaran', 'Apresiasi'];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(
              selectedPointType == 'Pelanggaran'
                  ? Icons.warning_rounded
                  : Icons.star_rounded,
              color:
                  selectedPointType == 'Pelanggaran'
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFFBBF24),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedPointType,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF6B7280),
                  ),
                  items:
                      pointTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(
                            type,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF374151),
                            ),
                          ),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      onChanged(newValue);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryDropdown extends StatelessWidget {
  final String selectedCategory;
  final List<Map<String, dynamic>> aspekPenilaian;
  final ValueChanged<String> onChanged;
  final bool isLoading;
  final String? errorMessage;

  const CategoryDropdown({
    Key? key,
    required this.selectedCategory,
    required this.aspekPenilaian,
    required this.onChanged,
    required this.isLoading,
    this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return Text(
        errorMessage!,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(0xFFEF4444),
        ),
      );
    }
    if (aspekPenilaian.isEmpty) {
      return Text(
        'Tidak ada kategori ditemukan',
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(0xFF6B7280),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.category_outlined,
              color: Color(0xFF6B7280),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCategory.isEmpty ? null : selectedCategory,
                  isExpanded: true,
                  hint: Text(
                    'Pilih Kategori',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF6B7280),
                  ),
                  items:
                      aspekPenilaian.map((Map<String, dynamic> aspek) {
                        return DropdownMenuItem<String>(
                          value: aspek['id_aspekpenilaian'].toString(),
                          child: Text(
                            '${aspek['kategori']} - ${aspek['uraian']} (${aspek['indikator_poin']} poin)',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF374151),
                            ),
                          ),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      onChanged(newValue);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActionButtons extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const ActionButtons({
    Key? key,
    required this.isSubmitting,
    required this.onCancel,
    required this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: isSubmitting ? null : onCancel,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  'Batal',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: isSubmitting ? null : onSubmit,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child:
                    isSubmitting
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Text(
                          'Tambah Poin',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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

void showPointPopup(
  BuildContext context,
  String studentName,
  String nis,
  String className,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Material(
        color: Colors.transparent,
        child: PointPopup(
          studentName: studentName,
          nis: nis,
          className: className,
        ),
      );
    },
  );
}
