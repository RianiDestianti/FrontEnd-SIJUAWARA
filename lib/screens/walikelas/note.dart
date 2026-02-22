import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skoring/models/types/note.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:skoring/config/api.dart';

class NoteUtils {
  static Future<Note?> submitNote({
    required String nis,
    required String judulCatatan,
    required String className,
    required String date,
    required String isiCatatan,
    required BuildContext context,
  }) async {
    if (nis.isEmpty || judulCatatan.isEmpty || className.isEmpty || date.isEmpty || isiCatatan.isEmpty) {
      _showSnackBar(context, 'Mohon lengkapi semua field yang diperlukan', isError: true);
      return null;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final nip = prefs.getString('walikelas_id') ?? '';
      final idKelas = prefs.getString('id_kelas') ?? '';

      if (nip.isEmpty || idKelas.isEmpty) {
        _showSnackBar(context, 'Data guru tidak lengkap. Silakan login ulang.', isError: true);
        return null;
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/AddCatatan/$nis?nip=$nip&id_kelas=$idKelas');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'judul_catatan': judulCatatan, 'isi_catatan': isiCatatan}),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          _showSnackBar(context, 'Penanganan berhasil ditambahkan');
          return Note(studentName: '', className: className, date: date, note: isiCatatan, title: judulCatatan);
        } else {
          _showSnackBar(context, responseData['message'] ?? 'Gagal menambahkan penanganan', isError: true);
          return null;
        }
      } else {
        final responseData = jsonDecode(response.body);
        _showSnackBar(context, responseData['message'] ?? 'Gagal menghubungi server: ${response.statusCode}', isError: true);
        return null;
      }
    } catch (e) {
      _showSnackBar(context, 'Terjadi kesalahan: $e', isError: true);
      return null;
    }
  }

  static void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: GoogleFonts.poppins(fontSize: 13))),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ─── Show Helper ─────────────────────────────────────────────────────────────

void showBKNotePopup(BuildContext context, String studentName, String nis, String className) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => BKNoteSheet(studentName: studentName, nis: nis, className: className),
  );
}

// ─── Bottom Sheet Widget ──────────────────────────────────────────────────────

class BKNoteSheet extends StatefulWidget {
  final String studentName;
  final String nis;
  final String className;

  const BKNoteSheet({Key? key, required this.studentName, required this.nis, required this.className})
      : super(key: key);

  @override
  State<BKNoteSheet> createState() => _BKNoteSheetState();
}

class _BKNoteSheetState extends State<BKNoteSheet> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _titleFocus = FocusNode();
  final _noteFocus = FocusNode();

  bool _isSubmitting = false;
  String? _titleError;
  String? _noteError;

  String _date = DateTime.now().toString().split(' ')[0];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _titleController.dispose();
    _noteController.dispose();
    _titleFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  void _close() {
    _animCtrl.reverse().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  bool _validate() {
    setState(() {
      _titleError = _titleController.text.trim().isEmpty ? 'Judul penanganan wajib diisi' : null;
      _noteError = _noteController.text.trim().isEmpty ? 'Isi catatan wajib diisi' : null;
    });
    return _titleError == null && _noteError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _isSubmitting = true);
    final note = await NoteUtils.submitNote(
      nis: widget.nis,
      judulCatatan: _titleController.text.trim(),
      className: widget.className,
      date: _date,
      isiCatatan: _noteController.text.trim(),
      context: context,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (note != null) _close();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFEF4444)),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked.toString().split(' ')[0]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomInset = mq.viewInsets.bottom;

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
            _SheetHeader(onClose: _close),

            // Scrollable body — respects keyboard inset
            Flexible(
              child: SingleChildScrollView(
                 padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 70),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Student info (read-only) ──────────────────
                    _SectionLabel(label: 'Informasi Siswa', icon: Icons.person_outline_rounded),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _ReadOnlyTile(
                            value: widget.studentName,
                            label: 'Nama Siswa',
                            icon: Icons.person_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _ReadOnlyTile(
                            value: widget.className,
                            label: 'Kelas',
                            icon: Icons.class_rounded,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Detail penanganan ─────────────────────────
                    _SectionLabel(label: 'Detail Penanganan', icon: Icons.edit_note_rounded),
                    const SizedBox(height: 8),

                    // Date picker
                    GestureDetector(
                      onTap: _pickDate,
                      child: _ReadOnlyTile(
                        value: _date,
                        label: 'Tanggal Penanganan',
                        icon: Icons.calendar_today_rounded,
                        trailingIcon: Icons.edit_calendar_rounded,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Title input
                    _InputField(
                      controller: _titleController,
                      focusNode: _titleFocus,
                      label: 'Judul Penanganan',
                      hint: 'cth: Perilaku Agresif di Kelas',
                      icon: Icons.title_rounded,
                      errorText: _titleError,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _noteFocus.requestFocus(),
                    ),

                    const SizedBox(height: 12),

                    // Note input
                    _InputField(
                      controller: _noteController,
                      focusNode: _noteFocus,
                      label: 'Isi Catatan',
                      hint: 'Deskripsikan perilaku, kondisi psikologi, atau situasi yang perlu ditangani...',
                      icon: Icons.notes_rounded,
                      maxLines: 5,
                      errorText: _noteError,
                      textInputAction: TextInputAction.done,
                    ),

                    const SizedBox(height: 16),

                    // Info banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFFEF4444), size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Penanganan ini akan diteruskan ke guru BK untuk tindak lanjut konseling.',
                              style: GoogleFonts.poppins(
                                fontSize: 12, color: const Color(0xFF991B1B), height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text('Batal',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFFCA5A5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(Colors.white)),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.send_rounded, size: 16),
                                      const SizedBox(width: 8),
                                      Text('Kirim ke BK',
                                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                    ],
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

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  final VoidCallback onClose;
  const _SheetHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.psychology_outlined, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tambah Penanganan',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                Text('Catat penanganan untuk siswa',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.white.withOpacity(0.85))),
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
          style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF9CA3AF),
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
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: const Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
                const SizedBox(height: 1),
                Text(value,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: const Color(0xFF374151), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (trailingIcon != null)
            Icon(trailingIcon, size: 15, color: const Color(0xFFEF4444)),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final String? errorText;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.errorText,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          maxLines: maxLines,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: GoogleFonts.poppins(
              fontSize: 14, color: const Color(0xFF111827), fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B7280)),
            hintText: hint,
            hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFD1D5DB)),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: errorText != null ? const Color(0xFFFFF1F2) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: errorText != null ? const Color(0xFFFCA5A5) : const Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: errorText != null ? const Color(0xFFFCA5A5) : const Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
                horizontal: 16, vertical: maxLines > 1 ? 14 : 0),
            alignLabelWithHint: maxLines > 1,
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 13, color: Color(0xFFEF4444)),
              const SizedBox(width: 4),
              Text(errorText!,
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFEF4444))),
            ],
          ),
        ],
      ],
    );
  }
}