class Kelas {
  final String idKelas;
  final String namaKelas;
  final String jurusan;
  final String? createdAt;
  final String? updatedAt;

  Kelas({
    required this.idKelas,
    required this.namaKelas,
    required this.jurusan,
    this.createdAt,
    this.updatedAt,
  });

  factory Kelas.fromJson(Map<String, dynamic> json) {
    return Kelas(
      idKelas: json['id_kelas'],
      namaKelas: json['nama_kelas'],
      jurusan: json['jurusan'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}