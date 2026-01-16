import 'dart:io';

import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfExport {
  static Future<String?> exportToPDF(
    List<Map<String, dynamic>> students,
    String fileName, {
    String? kelas,
    String? filterLabel,
    String? searchQuery,
  }) async {
    final pdf = pw.Document();
    final printedAt = DateTime.now();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Laporan Penilaian Siswa${kelas != null ? ' - $kelas' : ''}',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Text(
              'Filter: ${filterLabel ?? 'Semua'}'
              '${searchQuery != null && searchQuery.isNotEmpty ? ' | Pencarian: $searchQuery' : ''}'
              ' | Dicetak: ${printedAt.toLocal()}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Nama', 'Total Poin', 'Apresiasi', 'Pelanggaran'],
              data: students.map((student) => [
                    student['name'],
                    student['totalPoin'].toString(),
                    student['apresiasi'].toString(),
                    student['pelanggaran'].toString(),
                  ]).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Detail Nilai', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ...students.map((student) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 10),
                  pw.Text(student['name'], style: const pw.TextStyle(fontSize: 14)),
                  pw.TableHelper.fromTextArray(
                    headers: ['Keterangan', 'Tanggal', 'Poin', 'Tipe'],
                    data: (student['scores'] as List<Map<String, dynamic>>)
                        .map((score) => [
                              score['keterangan'],
                              score['tanggal'],
                              score['poin'].toString(),
                              score['type'],
                            ])
                        .toList(),
                  ),
                ],
              );
            }),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final trimmedName = fileName.trim().isEmpty ? 'laporan_siswa' : fileName;
    final dotIndex = trimmedName.lastIndexOf('.');
    String baseName = trimmedName;
    String ext = '';
    if (dotIndex > 0 && dotIndex < trimmedName.length - 1) {
      baseName = trimmedName.substring(0, dotIndex);
      ext = trimmedName.substring(dotIndex + 1);
    }
    if (ext.isEmpty) {
      ext = 'pdf';
    }

    if (Platform.isAndroid || Platform.isIOS) {
      return FileSaver.instance.saveAs(
        name: baseName,
        bytes: bytes,
        ext: ext,
        mimeType: MimeType.pdf,
      );
    }

    return FileSaver.instance.saveFile(
      name: baseName,
      bytes: bytes,
      ext: ext,
      mimeType: MimeType.pdf,
    );
  }
}
