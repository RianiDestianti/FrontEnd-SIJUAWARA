class Student {
  final int nis;
  final String idKelas;
  final String namaSiswa;
  final int? poinApresiasi;
  final int? poinPelanggaran;
  final int? poinTotal;
  final String createdAt;
  final String updatedAt;
  final String? spLevel;
  final String? phLevel;

  Student({
    required this.nis,
    required this.idKelas,
    required this.namaSiswa,
    this.poinApresiasi,
    this.poinPelanggaran,
    this.poinTotal,
    required this.createdAt,
    required this.updatedAt,
    this.spLevel,
    this.phLevel,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      nis: int.tryParse(json['nis']?.toString() ?? '') ?? 0,
      idKelas: json['id_kelas']?.toString() ?? '',
      namaSiswa: json['nama_siswa']?.toString() ?? '',
      poinApresiasi: int.tryParse(json['poin_apresiasi']?.toString() ?? ''),
      poinPelanggaran: int.tryParse(json['poin_pelanggaran']?.toString() ?? ''),
      poinTotal: int.tryParse(json['poin_total']?.toString() ?? ''),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      spLevel: json['sp_level']?.toString(),
      phLevel: json['ph_level']?.toString(),
    );
  }

  String get status {
    int totalPoints = poinTotal ?? 0;
    if (totalPoints >= 0) {
      return 'Aman';
    } else if (totalPoints >= -20) {
      return 'Bermasalah';
    } else {
      return 'Prioritas';
    }
  }

  int get points => poinTotal ?? 0;

  String get spLevelDisplay {
    final sp = spLevel?.trim();
    if (sp != null && sp.isNotEmpty) {
      return sp;
    }
    final totalPoints = poinTotal ?? 0;
    if (totalPoints <= -76) return 'SP3';
    if (totalPoints <= -51) return 'SP2';
    if (totalPoints <= -25) return 'SP1';
    return '-';
  }

  String get phLevelDisplay {
    final totalPoints = poinTotal ?? 0;
    if (totalPoints <= -25) return '-';
    final ph = phLevel?.trim();
    if (ph != null && ph.isNotEmpty) {
      return ph;
    }
    if (totalPoints >= 151) return 'PH3';
    if (totalPoints >= 126) return 'PH2';
    if (totalPoints >= 100) return 'PH1';
    return '-';
  }
}
