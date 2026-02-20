class PointUtils {
  static String generateIdPenilaian() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return (timestamp % 1000000000).toString().padLeft(9, '0');
  }

  static List<Map<String, dynamic>> filterAspek({
    required List<Map<String, dynamic>> aspekPenilaian,
    required String pointType,
    required String searchQuery,
  }) {
    final query = searchQuery.toLowerCase();
    return aspekPenilaian
        .where((aspek) => aspek['jenis_poin'] == pointType)
        .where((aspek) =>
            query.isEmpty ||
            (aspek['kategori']?.toString().toLowerCase().contains(query) ?? false) ||
            (aspek['uraian']?.toString().toLowerCase().contains(query) ?? false) ||
            (aspek['kode']?.toString().toLowerCase().contains(query) ?? false))
        .toList();
  }

  static String defaultCategoryFor({
    required List<Map<String, dynamic>> aspekPenilaian,
    required String pointType,
  }) {
    final match = aspekPenilaian.firstWhere(
      (aspek) => aspek['jenis_poin'] == pointType,
      orElse: () => aspekPenilaian.isNotEmpty ? aspekPenilaian.first : {},
    );
    return match['id_aspekpenilaian']?.toString() ?? '';
  }
}