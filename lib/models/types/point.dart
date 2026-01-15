class Point {
  final String type; 
  final String studentName;
  final String nis;
  final String className;
  final String date;
  final String description; 
  final String category; 
  final int? points; 
  final String? idPenilaian;

  Point({
    required this.type,
    required this.studentName,
    required this.nis,
    required this.className,
    required this.date,
    required this.description,
    required this.category,
    this.points,
    this.idPenilaian,
  });
}