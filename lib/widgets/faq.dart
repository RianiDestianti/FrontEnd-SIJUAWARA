import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FaqWidget extends StatelessWidget {
  final Map<String, Map<String, dynamic>> faqData;
  final Map<String, bool> expandedSections;
  final String searchQuery;
  final Function(String, bool) onExpansionChanged;

  const FaqWidget({
    Key? key,
    required this.faqData,
    required this.expandedSections,
    required this.searchQuery,
    required this.onExpansionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filteredFaqData = filterFaqData();
    final apresiasiEntries = entriesForType(filteredFaqData, 'apresiasi');
    final pelanggaranEntries = entriesForType(filteredFaqData, 'pelanggaran');
    final otherEntries = entriesForOtherTypes(filteredFaqData);
    final apresiasiGroups = groupEntriesByTitle(apresiasiEntries);
    final pelanggaranGroups = groupEntriesByTitle(pelanggaranEntries);
    final otherGroups = groupEntriesByTitle(otherEntries);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (filteredFaqData.isEmpty && searchQuery.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada aturan ditemukan',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Coba ubah kata kunci pencarian',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          )
        else ...[
          if (searchQuery.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0083EE).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0083EE).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: const Color(0xFF0083EE), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Menampilkan ${filteredFaqData.length} hasil untuk "$searchQuery"',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0083EE),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (apresiasiEntries.isNotEmpty) ...[
            sectionTitle('Lembar 1 - Penghargaan dan Apresiasi'),
            buildCategoryTable(apresiasiGroups),
            const SizedBox(height: 24),
          ],
          if (pelanggaranEntries.isNotEmpty) ...[
            sectionTitle('Lembar 2 - Pelanggaran dan Sanksi'),
            buildCategoryTable(pelanggaranGroups),
            const SizedBox(height: 24),
          ],
          if (otherEntries.isNotEmpty) ...[
            sectionTitle('Lembar 3 - Lainnya'),
            buildCategoryTable(otherGroups),
            const SizedBox(height: 16),
          ],
          if (searchQuery.isEmpty) ...[
            Text(
              'Ketentuan Konversi Skor Penghargaan',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Skor penghargaan dapat dikonversi ke bentuk sertifikat, hadiah, atau gelar Anugerah Waluya Utama sesuai ketentuan sekolah.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Map<String, Map<String, dynamic>> filterFaqData() {
    if (searchQuery.isEmpty) {
      return faqData;
    }

    final filtered = <String, Map<String, dynamic>>{};
    final searchLower = searchQuery.toLowerCase();

    faqData.forEach((key, section) {
      final title = section['title']?.toString() ?? '';
      final items = section['items'] as List<dynamic>? ?? [];
      final titleMatches = title.toLowerCase().contains(searchLower);

      final matchingItems = <Map<String, dynamic>>[];
      for (final item in items) {
        if (item is! Map) {
          continue;
        }
        final text = item['text']?.toString().toLowerCase() ?? '';
        final points = item['points']?.toString().toLowerCase() ?? '';
        if (text.contains(searchLower) || points.contains(searchLower)) {
          matchingItems.add(Map<String, dynamic>.from(item));
        }
      }

      if (titleMatches || matchingItems.isNotEmpty) {
        filtered[key] = {
          'title': section['title'],
          'type': section['type'],
          'items': titleMatches ? items : matchingItems,
        };
      }
    });

    return filtered;
  }

  List<MapEntry<String, Map<String, dynamic>>> entriesForType(
    Map<String, Map<String, dynamic>> data,
    String type,
  ) {
    final expected = type.toLowerCase();
    return data.entries.where((entry) {
      final entryType = entry.value['type']?.toString().toLowerCase() ?? '';
      return entryType == expected;
    }).toList();
  }

  List<MapEntry<String, Map<String, dynamic>>> entriesForOtherTypes(
    Map<String, Map<String, dynamic>> data,
  ) {
    return data.entries.where((entry) {
      final entryType = entry.value['type']?.toString().toLowerCase() ?? '';
      return entryType != 'apresiasi' && entryType != 'pelanggaran';
    }).toList();
  }

  Map<String, List<_FaqRow>> groupEntriesByTitle(
    List<MapEntry<String, Map<String, dynamic>>> entries,
  ) {
    final Map<String, List<_FaqRow>> grouped = {};
    for (final entry in entries) {
      final title = entry.value['title']?.toString().trim();
      final keyTitle = (title == null || title.isEmpty) ? 'Lainnya' : title;
      final items = entry.value['items'] as List<dynamic>? ?? [];
      for (final item in items.whereType<Map>()) {
        final row = _FaqRow(
          code: entry.key,
          text: item['text']?.toString() ?? '',
          points: item['points']?.toString() ?? '',
        );
        grouped.putIfAbsent(keyTitle, () => []).add(row);
      }
    }
    return grouped;
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1F2937),
        ),
      ),
    );
  }

  Widget buildCategoryTable(Map<String, List<_FaqRow>> groups) {
    final borderColor = const Color(0xFFE5E7EB);
    if (groups.isEmpty) {
      return buildEmptyTable();
    }
    int itemIndex = 0;
    final children = <Widget>[
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0083EE).withValues(alpha: 0.08),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          border: Border(bottom: BorderSide(color: borderColor)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Text(
                'Kode',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(
                'Aturan',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 72,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Poin',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ];

    for (final group in groups.entries) {
      children.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: RichText(
            text: TextSpan(
              children: highlightSearchText(
                group.key,
                searchQuery,
                GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
          ),
        ),
      );

      for (final row in group.value) {
        final isStriped = itemIndex.isOdd;
        itemIndex += 1;
        children.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isStriped ? const Color(0xFFF9FAFB) : Colors.white,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 56,
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: highlightSearchText(
                        row.code,
                        searchQuery,
                        GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: RichText(
                    text: TextSpan(
                      children: highlightSearchText(
                        row.text,
                        searchQuery,
                        GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 72,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: RichText(
                        text: TextSpan(
                          children: highlightSearchText(
                            row.points,
                            searchQuery,
                            GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: children),
    );
  }

  Widget buildEmptyTable() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Text(
          'Tidak ada poin untuk bagian ini.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  List<TextSpan> highlightSearchText(
    String text,
    String searchQuery,
    TextStyle baseStyle,
  ) {
    if (searchQuery.isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    List<TextSpan> spans = [];
    String lowerText = text.toLowerCase();
    String lowerQuery = searchQuery.toLowerCase();

    int start = 0;
    int index = lowerText.indexOf(lowerQuery);

    while (index != -1) {
      if (index > start) {
        spans.add(
          TextSpan(text: text.substring(start, index), style: baseStyle),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + searchQuery.length),
          style: baseStyle.copyWith(
            backgroundColor: const Color(0xFFFFEB3B).withValues(alpha: 0.3),
            fontWeight: FontWeight.w700,
          ),
        ),
      );

      start = index + searchQuery.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: baseStyle));
    }

    return spans;
  }
}

class _FaqRow {
  final String code;
  final String text;
  final String points;

  const _FaqRow({
    required this.code,
    required this.text,
    required this.points,
  });
}
