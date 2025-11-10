class PresensiData {
  final StatistikPresensi statistik;
  final PresensiHariIni? presensiHariIni;
  final JadwalHariIni? jadwalHariIni;
  final ProjectInfo? projectInfo;
  final PeriodInfo? periodInfo;
  final MonthInfo? monthInfo;
  final List<String> enabledIzinCategories;
  final List<String> enabledSubKategoriIzin;

  PresensiData({
    required this.statistik,
    this.presensiHariIni,
    this.jadwalHariIni,
    this.projectInfo,
    this.periodInfo,
    this.monthInfo,
    this.enabledIzinCategories = const [],
    this.enabledSubKategoriIzin = const [],
  });

  factory PresensiData.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
    }

    return PresensiData(
      statistik: StatistikPresensi.fromJson(json['statistik'] ?? {}),
      presensiHariIni: json['presensi_hari_ini'] != null
          ? PresensiHariIni.fromJson(json['presensi_hari_ini'])
          : null,
      jadwalHariIni: json['jadwal_hari_ini'] != null
          ? JadwalHariIni.fromJson(json['jadwal_hari_ini'])
          : null,
      projectInfo: json['project_info'] != null
          ? ProjectInfo.fromJson(json['project_info'])
          : null,
      periodInfo: json['period_info'] != null
          ? PeriodInfo.fromJson(json['period_info'])
          : null,
      monthInfo:
          json['month_info'] !=
              null // ✅ NEW
          ? MonthInfo.fromJson(json['month_info'])
          : null,
      enabledIzinCategories: parseStringList(json['enabled_izin_categories']),
      enabledSubKategoriIzin: parseStringList(
        json['enabled_sub_kategori_izin'],
      ),
    );
  }
}

class MonthInfo {
  final String bulan;
  final String bulanDisplay;
  final String startDate;
  final String endDate;

  MonthInfo({
    required this.bulan,
    required this.bulanDisplay,
    required this.startDate,
    required this.endDate,
  });

  factory MonthInfo.fromJson(Map<String, dynamic> json) {
    return MonthInfo(
      bulan: json['bulan'] ?? '',
      bulanDisplay: json['bulan_display'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
    );
  }
}

class StatistikPresensi {
  final int hadir;
  final int izin;
  final int alpa;

  StatistikPresensi({
    required this.hadir,
    required this.izin,
    required this.alpa,
  });

  factory StatistikPresensi.fromJson(Map<String, dynamic> json) {
    return StatistikPresensi(
      hadir: json['hadir'] ?? 0,
      izin: json['izin'] ?? 0,
      alpa: json['alpa'] ?? 0,
    );
  }
}

class PresensiHariIni {
  final String? waktuMasuk;
  final String? waktuPulang;
  final String? statusMasuk;
  final String? statusPulang;
  final bool isAlpa;

  PresensiHariIni({
    this.waktuMasuk,
    this.waktuPulang,
    this.statusMasuk,
    this.statusPulang,
    this.isAlpa = false,
  });

  factory PresensiHariIni.fromJson(Map<String, dynamic> json) {
    return PresensiHariIni(
      waktuMasuk: json['waktu_masuk'],
      waktuPulang: json['waktu_pulang'],
      statusMasuk: json['status_masuk'],
      statusPulang: json['status_pulang'],
      isAlpa: json['is_alpa'] ?? false,
    );
  }
}

class JadwalHariIni {
  final String shiftCode;
  final String? waktuMulai;
  final String? waktuSelesai;
  final bool isLibur;

  JadwalHariIni({
    required this.shiftCode,
    this.waktuMulai,
    this.waktuSelesai,
    required this.isLibur,
  });

  factory JadwalHariIni.fromJson(Map<String, dynamic> json) {
    return JadwalHariIni(
      shiftCode: json['shift_code'] ?? '',
      waktuMulai: json['waktu_mulai'],
      waktuSelesai: json['waktu_selesai'],
      isLibur: json['is_libur'] ?? false,
    );
  }
}

class StatistikPeriode {
  final int hadir;
  final int izin;
  final int alpa;
  final int sakit;
  final int cuti;
  final int lembur;
  final int terlambat;
  final int pulangCepat;
  final int tidakPresensiPulang;
  final PeriodInfo periodInfo;

  StatistikPeriode({
    required this.hadir,
    required this.izin,
    required this.alpa,
    required this.sakit,
    required this.cuti,
    required this.lembur,
    required this.terlambat,
    required this.pulangCepat,
    required this.tidakPresensiPulang,
    required this.periodInfo,
  });

  factory StatistikPeriode.fromJson(Map<String, dynamic> json) {
    return StatistikPeriode(
      hadir: json['hadir'] ?? 0,
      izin: json['izin'] ?? 0,
      alpa: json['alpa'] ?? 0,
      sakit: json['sakit'] ?? 0,
      cuti: json['cuti'] ?? 0,
      lembur: json['lembur'] ?? 0,
      terlambat: json['terlambat'] ?? 0,
      pulangCepat: json['pulang_cepat'] ?? 0,
      tidakPresensiPulang: json['tidak_presensi_pulang'] ?? 0,
      periodInfo: PeriodInfo.fromJson(json['period_info'] ?? {}),
    );
  }
}

class PeriodInfo {
  final String startDate;
  final String endDate;
  final String bulan;
  final String? bulanDisplay;
  final bool? isCurrentPeriod; // ✅ NEW

  PeriodInfo({
    required this.startDate,
    required this.endDate,
    required this.bulan,
    this.bulanDisplay,
    this.isCurrentPeriod,
  });

  factory PeriodInfo.fromJson(Map<String, dynamic> json) {
    return PeriodInfo(
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      bulan: json['bulan'] ?? '',
      bulanDisplay: json['bulan_display'],
      isCurrentPeriod: json['is_current_period'], // ✅ NEW
    );
  }
}

class ProjectInfo {
  final int id;
  final String nama;
  final String tanggalMulai;

  ProjectInfo({
    required this.id,
    required this.nama,
    required this.tanggalMulai,
  });

  factory ProjectInfo.fromJson(Map<String, dynamic> json) {
    return ProjectInfo(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      tanggalMulai: json['tanggal_mulai'] ?? '',
    );
  }
}
