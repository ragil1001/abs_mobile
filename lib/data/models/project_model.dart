class ProjectShift {
  final int id;
  final String kode;
  final String waktuMulai;
  final String waktuSelesai;

  ProjectShift({
    required this.id,
    required this.kode,
    required this.waktuMulai,
    required this.waktuSelesai,
  });

  factory ProjectShift.fromJson(Map<String, dynamic> json) {
    return ProjectShift(
      id: json['id'] ?? 0,
      kode: json['kode'] ?? '',
      waktuMulai: json['waktu_mulai'] ?? '',
      waktuSelesai: json['waktu_selesai'] ?? '',
    );
  }
}

class ProjectLokasi {
  final String nama;
  final double latitude;
  final double longitude;

  ProjectLokasi({
    required this.nama,
    required this.latitude,
    required this.longitude,
  });

  factory ProjectLokasi.fromJson(Map<String, dynamic> json) {
    return ProjectLokasi(
      nama: json['nama'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }
}

class Project {
  final int id;
  final String nama;
  final String bagian;
  final ProjectLokasi? lokasi; // Make nullable
  final int radius;
  final int waktuToleransi;
  final String tanggalAssign;
  final List<ProjectShift> shifts;

  Project({
    required this.id,
    required this.nama,
    required this.bagian,
    this.lokasi, // Make nullable
    required this.radius,
    required this.waktuToleransi,
    required this.tanggalAssign,
    required this.shifts,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    try {
      // Parse lokasi safely
      ProjectLokasi? parsedLokasi;
      if (json['lokasi'] != null && json['lokasi'] is Map) {
        parsedLokasi = ProjectLokasi.fromJson(
          json['lokasi'] as Map<String, dynamic>,
        );
      }

      // Parse shifts safely
      List<ProjectShift> parsedShifts = [];
      if (json['shifts'] != null && json['shifts'] is List) {
        parsedShifts = (json['shifts'] as List)
            .map(
              (shift) => ProjectShift.fromJson(shift as Map<String, dynamic>),
            )
            .toList();
      }

      return Project(
        id: json['id'] ?? 0,
        nama: json['nama'] ?? '',
        bagian: json['bagian'] ?? '',
        lokasi: parsedLokasi,
        radius: json['radius'] ?? 0,
        waktuToleransi: json['waktu_toleransi'] ?? 0,
        tanggalAssign: json['tanggal_assign'] ?? '',
        shifts: parsedShifts,
      );
    } catch (e) {
      // print('Error parsing Project: $e');
      // print('JSON data: $json');
      rethrow;
    }
  }
}
