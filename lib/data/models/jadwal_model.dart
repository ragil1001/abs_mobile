class JadwalHarian {
  final int id;
  final String tanggal;
  final String hari;
  final String tanggalFormat;
  final String bulanFormat;
  final String tahun;
  final String shiftCode;
  final String? waktuMulai;
  final String? waktuSelesai;
  final bool isLibur;
  final bool isWeekend;
  final bool isDitukar; // TAMBAHAN: Flag untuk tukar shift
  final TukarShiftInfo? tukarShiftInfo; // TAMBAHAN: Info tukar shift

  JadwalHarian({
    required this.id,
    required this.tanggal,
    required this.hari,
    required this.tanggalFormat,
    required this.bulanFormat,
    required this.tahun,
    required this.shiftCode,
    this.waktuMulai,
    this.waktuSelesai,
    required this.isLibur,
    required this.isWeekend,
    this.isDitukar = false, // Default false
    this.tukarShiftInfo,
  });

  factory JadwalHarian.fromJson(Map<String, dynamic> json) {
    return JadwalHarian(
      id: json['id'] ?? 0,
      tanggal: json['tanggal'] ?? '',
      hari: json['hari'] ?? '',
      tanggalFormat: json['tanggal_format'] ?? '',
      bulanFormat: json['bulan_format'] ?? '',
      tahun: json['tahun'] ?? '',
      shiftCode: json['shift_code'] ?? '',
      waktuMulai: json['waktu_mulai'],
      waktuSelesai: json['waktu_selesai'],
      isLibur: json['is_libur'] ?? false,
      isWeekend: json['is_weekend'] ?? false,
      isDitukar: json['is_ditukar'] ?? false, // Parse dari backend
      tukarShiftInfo: json['tukar_shift_info'] != null
          ? TukarShiftInfo.fromJson(json['tukar_shift_info'])
          : null,
    );
  }
}

// Model untuk info tukar shift
class TukarShiftInfo {
  final int id;
  final String dengan; // Nama karyawan yang ditukar

  TukarShiftInfo({required this.id, required this.dengan});

  factory TukarShiftInfo.fromJson(Map<String, dynamic> json) {
    return TukarShiftInfo(id: json['id'] ?? 0, dengan: json['dengan'] ?? '');
  }
}

// Kelas lainnya tetap sama...
class JadwalBulan {
  final List<JadwalHarian> jadwals;
  final PeriodInfo periodInfo;
  final ProjectInfoJadwal projectInfo;

  JadwalBulan({
    required this.jadwals,
    required this.periodInfo,
    required this.projectInfo,
  });

  factory JadwalBulan.fromJson(Map<String, dynamic> json) {
    return JadwalBulan(
      jadwals:
          (json['data'] as List?)
              ?.map((item) => JadwalHarian.fromJson(item))
              .toList() ??
          [],
      periodInfo: PeriodInfo.fromJson(json['period_info'] ?? {}),
      projectInfo: ProjectInfoJadwal.fromJson(json['project_info'] ?? {}),
    );
  }
}

class ProjectInfoJadwal {
  final int id;
  final String nama;
  final String tanggalMulai;

  ProjectInfoJadwal({
    required this.id,
    required this.nama,
    required this.tanggalMulai,
  });

  factory ProjectInfoJadwal.fromJson(Map<String, dynamic> json) {
    return ProjectInfoJadwal(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      tanggalMulai: json['tanggal_mulai'] ?? '',
    );
  }
}

class PeriodInfo {
  final String startDate;
  final String endDate;
  final String bulan;
  final String bulanDisplay;

  PeriodInfo({
    required this.startDate,
    required this.endDate,
    required this.bulan,
    this.bulanDisplay = '',
  });

  factory PeriodInfo.fromJson(Map<String, dynamic> json) {
    return PeriodInfo(
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      bulan: json['bulan'] ?? '',
      bulanDisplay: json['bulan_display'] ?? '',
    );
  }
}
