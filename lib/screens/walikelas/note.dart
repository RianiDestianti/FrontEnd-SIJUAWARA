import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skoring/models/note.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NoteUtils {
  static Future<Note?> submitNote({
    required String nis,
    required String judulCatatan,
    required String className,
    required String date,
    required String isiCatatan,
    required BuildContext context,
  }) async {
    if (nis.isEmpty ||
        judulCatatan.isEmpty ||
        className.isEmpty ||
        date.isEmpty ||
        isiCatatan.isEmpty) {
      print('Validation failed: Some fields are empty');
      _showErrorSnackBar(context, 'Mohon lengkapi semua field yang diperlukan');
      return null;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final nip = prefs.getString('walikelas_id') ?? '';
      final idKelas = prefs.getString('id_kelas') ?? '';

      if (nip.isEmpty || idKelas.isEmpty) {
        _showErrorSnackBar(context, 'Data guru tidak lengkap. Silakan login ulang.');
        return null;
      }

      final url = Uri.parse(
        'http://sijuwara.student.smkn11bdg.sch.id/api/AddCatatan/$nis?nip=$nip&id_kelas=$idKelas',
      );

      print('Sending POST request to $url');
      print('Request body: ${jsonEncode({
            'judul_catatan': judulCatatan,
            'isi_catatan': isiCatatan,
          })}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'judul_catatan': judulCatatan,
          'isi_catatan': isiCatatan,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final noteData = Note(
            studentName: '',
            className: className,
            date: date,
            note: isiCatatan,
            title: judulCatatan,
          );

          _showSuccessSnackBar(context, 'Penanganan berhasil ditambahkan');
          return noteData;
        } else {
          _showErrorSnackBar(
            context,
            responseData['message'] ?? 'Gagal menambahkan penanganan',
          );
          return null;
        }
      } else {
        final responseData = jsonDecode(response.body);
        _showErrorSnackBar(
          context,
          responseData['message'] ?? 'Gagal menghubungi server: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      print('Error during HTTP request: $e');
      _showErrorSnackBar(context, 'Terjadi kesalahan: $e');
      return null;
    }
  }
}

void _showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
}

void _showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ),
  );
}

class BKNotePopup extends StatefulWidget {
  final String studentName;
  final String nis;
  final String className;

  const BKNotePopup({
    Key? key,
    required this.studentName,
    required this.nis,
    required this.className,
  }) : super(key: key);

  @override
  State<BKNotePopup> createState() => _BKNotePopupState();
}

class _BKNotePopupState extends State<BKNotePopup>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _nameController.text = widget.studentName;
    _classController.text = widget.className;
    _dateController.text = DateTime.now().toString().split(' ')[0];
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

  @override
  void dispose() {
    _animationController.dispose();
    _slideController.dispose();
    _nameController.dispose();
    _classController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _closeDialog() {
    _animationController.reverse().then((_) => Navigator.of(context).pop());
  }

  void _submitNote() async {
    print('Starting note submission...');
    setState(() => _isSubmitting = true);
    final note = await NoteUtils.submitNote(
      nis: widget.nis,
      judulCatatan: _titleController.text,
      className: _classController.text,
      date: _dateController.text,
      isiCatatan: _noteController.text,
      context: context,
    );
    print('Submission result: $note');
    setState(() => _isSubmitting = false);
    if (note != null) {
      print('Note submitted successfully, closing dialog');
      _closeDialog();
    } else {
      print('Note submission failed');
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
            colorScheme: const ColorScheme.light(primary: Color(0xFFEF4444)),
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
                  child: NoteDialogContent(
                    nameController: _nameController,
                    classController: _classController,
                    dateController: _dateController,
                    noteController: _noteController,
                    titleController: _titleController,
                    isSubmitting: _isSubmitting,
                    onClose: _closeDialog,
                    onSubmit: _submitNote,
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

class NoteDialogContent extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController classController;
  final TextEditingController dateController;
  final TextEditingController noteController;
  final TextEditingController titleController;
  final bool isSubmitting;
  final VoidCallback onClose;
  final VoidCallback onSubmit;
  final VoidCallback onDateTap;

  const NoteDialogContent({
    Key? key,
    required this.nameController,
    required this.classController,
    required this.dateController,
    required this.noteController,
    required this.titleController,
    required this.isSubmitting,
    required this.onClose,
    required this.onSubmit,
    required this.onDateTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      constraints: const BoxConstraints(maxWidth: 420),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HeaderSection(onClose: onClose),
          FormSection(
            nameController: nameController,
            classController: classController,
            dateController: dateController,
            noteController: noteController,
            titleController: titleController,
            onDateTap: onDateTap,
          ),
          ActionButtons(
            isSubmitting: isSubmitting,
            onCancel: onClose,
            onSubmit: onSubmit,
          ),
        ],
      ),
    );
  }
}

class FormSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController classController;
  final TextEditingController dateController;
  final TextEditingController noteController;
  final TextEditingController titleController;
  final VoidCallback onDateTap;

  const FormSection({
    Key? key,
    required this.nameController,
    required this.classController,
    required this.dateController,
    required this.noteController,
    required this.titleController,
    required this.onDateTap,
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
            controller: classController,
            hint: 'Kelas',
            icon: Icons.school_outlined,
            readOnly: true,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: titleController,
            hint: 'Judul Penanganan',
            icon: Icons.title,
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
          CustomTextField(
            controller: noteController,
            hint: 'Penanganan (perilaku, kondisi psikologi, dll)',
            icon: Icons.edit_note,
            maxLines: 4,
            fillColor: const Color(0xFFFEF2F2),
            borderColor: const Color(0xFFFECACA),
          ),
          const SizedBox(height: 24),
          const InfoCard(),
        ],
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
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
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
              Icons.psychology_outlined,
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
                  'Penanganan',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Catat hal penting untuk penanganan',
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

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;
  final Color? fillColor;
  final Color? borderColor;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.fillColor,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (fillColor == null ? Colors.black : const Color(0xFFEF4444))
                .withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF9CA3AF),
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: const Color(0xFFEF4444), size: 20),
          ),
          filled: true,
          fillColor: fillColor ?? Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: borderColor ?? const Color(0xFFE5E7EB),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: borderColor ?? const Color(0xFFE5E7EB),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
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

class InfoCard extends StatelessWidget {
  const InfoCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Penanganan ini akan diteruskan ke guru BK untuk tindak lanjut konseling',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF991B1B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.3),
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
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Kirim ke BK',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showBKNotePopup(
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
        child: BKNotePopup(
          studentName: studentName,
          nis: nis,
          className: className,
        ),
      );
    },
  );
}
