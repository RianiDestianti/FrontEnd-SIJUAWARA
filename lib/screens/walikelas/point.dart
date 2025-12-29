import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skoring/models/point.dart';

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
        _showErrorSnackBar(
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
          _showErrorSnackBar(context, 'Data guru tidak lengkap. Silakan login ulang.');
        }
        return null;
      }

      final endpoint = type == 'Apresiasi'
          ? 'http://sijuwara.student.smkn11bdg.sch.id/api/skoring_penghargaan?nip=$nip&id_kelas=$idKelas'
          : 'http://sijuwara.student.smkn11bdg.sch.id/api/skoring_pelanggaran?nip=$nip&id_kelas=$idKelas';

      print('Sending POST request to $endpoint');
      print(
        'Request body: ${jsonEncode({
          'id_penilaian': idPenilaian,
          'nis': nis,
          'id_aspekpenilaian': idAspekPenilaian,
          'nip_walikelas': nip,
        })}',
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
              (responseData['message']?.toString().contains('berhasil') ?? false)) {
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
              _showSuccessSnackBar(
                context,
                'Poin $type berhasil ditambahkan untuk $studentName',
              );
            }
            return pointData;
          } else {
            if (context.mounted) {
              _showErrorSnackBar(
                context,
                responseData['message'] ?? 'Gagal menambahkan poin',
              );
            }
            return null;
          }
        } catch (e) {
          print('JSON decode error: $e');
          if (context.mounted) {
            _showErrorSnackBar(
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
            _showErrorSnackBar(
              context,
              errorData['message'] ?? 'Gagal menghubungi server: ${response.statusCode}',
            );
          }
        } catch (e) {
          if (context.mounted) {
            _showErrorSnackBar(
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
        _showErrorSnackBar(context, 'Terjadi kesalahan: $e');
      }
      return null;
    }
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
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

  static void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
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
  State<PointPopup> createState() => _PointPopupState();
}

class _PointPopupState extends State<PointPopup> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nisController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _idPenilaianController = TextEditingController();
  String _selectedPointType = 'Pelanggaran';
  String _selectedCategory = '';
  bool _isSubmitting = false;
  bool _isLoadingCategories = true;
  String? _errorMessageCategories;
  List<Map<String, dynamic>> _aspekPenilaian = [];
  final TextEditingController _categorySearchController =
      TextEditingController();
  String _categorySearch = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _nameController.text = widget.studentName;
    _nisController.text = widget.nis;
    _classController.text = widget.className;
    _dateController.text = DateTime.now().toString().split(' ')[0];
    _idPenilaianController.text = _generateIdPenilaian();
    fetchAspekPenilaian();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _rotateAnimation = Tween<double>(begin: 0.1, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  String _generateIdPenilaian() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final shortId = (timestamp % 1000000000).toString().padLeft(9, '0');
    return shortId;
  }

Future<void> fetchAspekPenilaian() async {
  setState(() {
    _isLoadingCategories = true;
    _errorMessageCategories = null;
  });

  try {
    final prefs = await SharedPreferences.getInstance();
    final nip = prefs.getString('walikelas_id') ?? '';
    final idKelas = prefs.getString('id_kelas') ?? '';

    if (nip.isEmpty || idKelas.isEmpty) {
      setState(() {
        _errorMessageCategories = 'Data guru tidak lengkap. Silakan login ulang.';
        _isLoadingCategories = false;
      });
      return;
    }

    final uri = Uri.parse(
      'http://sijuwara.student.smkn11bdg.sch.id/api/aspekpenilaian?nip=$nip&id_kelas=$idKelas',
    );

    final response = await http.get(uri, headers: {'Accept': 'application/json'});

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success']) {
        setState(() {
          _aspekPenilaian = List<Map<String, dynamic>>.from(jsonData['data']);
          if (_aspekPenilaian.isNotEmpty) {
            _selectedCategory = _aspekPenilaian
                .firstWhere(
                  (aspek) => aspek['jenis_poin'] == _selectedPointType,
                  orElse: () => _aspekPenilaian[0],
                )['id_aspekpenilaian']
                .toString();
          }
          _isLoadingCategories = false;
        });
      } else {
        setState(() {
          _errorMessageCategories = jsonData['message'];
          _isLoadingCategories = false;
        });
      }
    } else {
      setState(() {
        _errorMessageCategories = 'Gagal mengambil data aspek penilaian';
        _isLoadingCategories = false;
      });
    }
  } catch (e) {
    setState(() {
      _errorMessageCategories = 'Terjadi kesalahan: $e';
      _isLoadingCategories = false;
    });
  }
}

  @override
  void dispose() {
    _animationController.dispose();
    _slideController.dispose();
    _nameController.dispose();
    _nisController.dispose();
    _classController.dispose();
    _dateController.dispose();
    _idPenilaianController.dispose();
    _categorySearchController.dispose();
    super.dispose();
  }

  void _closeDialog() {
    _animationController.reverse().then((_) => Navigator.of(context).pop());
  }

  void _submitPoint() async {
    setState(() => _isSubmitting = true);
    final selectedAspek = _aspekPenilaian.firstWhere(
      (aspek) => aspek['id_aspekpenilaian'].toString() == _selectedCategory,
      orElse: () => {},
    );
    if (selectedAspek.isEmpty) {
      setState(() => _isSubmitting = false);
      PointUtils._showErrorSnackBar(context, 'Kategori tidak valid');
      return;
    }
    print(
      'Submitting point: type=$_selectedPointType, nis=${_nisController.text}, '
      'idPenilaian=${_idPenilaianController.text}, idAspekPenilaian=$_selectedCategory, '
      'category=${selectedAspek['kategori']}, description=${selectedAspek['uraian']}, '
      'points=${selectedAspek['indikator_poin']}',
    );
    final point = await PointUtils.submitPoint(
      type: _selectedPointType,
      studentName: _nameController.text,
      nis: _nisController.text,
      idPenilaian: _idPenilaianController.text,
      idAspekPenilaian: _selectedCategory,
      date: _dateController.text,
      category: selectedAspek['kategori'] ?? '',
      description: selectedAspek['uraian'] ?? '',
      points: int.parse(selectedAspek['indikator_poin'].toString()),
      context: context,
    );
    setState(() => _isSubmitting = false);
    if (point != null) {
      _closeDialog();
    }
  }

  Future<void> _pickDate() async {
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
        _dateController.text = pickedDate.toString().split(' ')[0];
      });
    }
  }

  void _onPointTypeChanged(String value) {
    setState(() {
      _selectedPointType = value;
      _categorySearch = '';
      _categorySearchController.clear();
      _selectedCategory =
          _aspekPenilaian
              .firstWhere(
                (aspek) => aspek['jenis_poin'] == _selectedPointType,
                orElse:
                    () => _aspekPenilaian.isNotEmpty ? _aspekPenilaian[0] : {},
              )['id_aspekpenilaian']
              ?.toString() ??
          '';
    });
  }

  List<Map<String, dynamic>> get _filteredAspekPenilaian {
    final query = _categorySearch.toLowerCase();
    return _aspekPenilaian
        .where((aspek) => aspek['jenis_poin'] == _selectedPointType)
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

  void _onCategorySearchChanged(String value) {
    setState(() {
      _categorySearch = value;
      final filtered = _filteredAspekPenilaian;
      if (filtered.isNotEmpty &&
          !filtered.any(
            (aspek) =>
                aspek['id_aspekpenilaian'].toString() == _selectedCategory,
          )) {
        _selectedCategory = filtered.first['id_aspekpenilaian'].toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: SlideTransition(
            position: _slideAnimation,
            child: RotationTransition(
              turns: _rotateAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Material(
                  color: Colors.transparent,
                  child: PointDialogContent(
                    nameController: _nameController,
                    nisController: _nisController,
                    classController: _classController,
                    dateController: _dateController,
                    idPenilaianController: _idPenilaianController,
                    selectedPointType: _selectedPointType,
                  selectedCategory: _selectedCategory,
                    aspekPenilaian: _filteredAspekPenilaian,
                    categorySearchController: _categorySearchController,
                    onCategorySearchChanged: _onCategorySearchChanged,
                    onPointTypeChanged: _onPointTypeChanged,
                    onCategoryChanged:
                        (value) => setState(() => _selectedCategory = value),
                    isSubmitting: _isSubmitting,
                    isLoadingCategories: _isLoadingCategories,
                    errorMessageCategories: _errorMessageCategories,
                    onClose: _closeDialog,
                    onSubmit: _submitPoint,
                    onDateTap: _pickDate,
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
            color: Colors.black.withOpacity(0.15),
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
              color: Colors.white.withOpacity(0.2),
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
                    color: Colors.white.withOpacity(0.8),
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
                color: Colors.white.withOpacity(0.2),
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
            color: Colors.black.withOpacity(0.05),
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
            color: Colors.black.withOpacity(0.05),
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
            color: Colors.black.withOpacity(0.05),
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
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
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
