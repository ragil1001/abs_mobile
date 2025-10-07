class TukarShiftRequest {
  final int id;
  final String status;
  final String jenis; // 'saya' atau 'orang_lain'
  final DateTime tanggalRequest;
  final ShiftInfo shiftSaya;
  final ShiftInfo shiftDiminta;
  final KaryawanTujuan karyawanTujuan;
  final String? catatan;
  final String? alasanPenolakan;
  final DateTime? tanggalDiproses;

  TukarShiftRequest({
    required this.id,
    required this.status,
    required this.jenis,
    required this.tanggalRequest,
    required this.shiftSaya,
    required this.shiftDiminta,
    required this.karyawanTujuan,
    this.catatan,
    this.alasanPenolakan,
    this.tanggalDiproses,
  });

  factory TukarShiftRequest.fromJson(Map<String, dynamic> json) {
    return TukarShiftRequest(
      id: json['id'] ?? 0,
      status: json['status'] ?? '',
      jenis: json['jenis'] ?? '',
      tanggalRequest: DateTime.parse(json['tanggal_request']),
      shiftSaya: ShiftInfo.fromJson(json['shift_saya']),
      shiftDiminta: ShiftInfo.fromJson(json['shift_diminta']),
      karyawanTujuan: KaryawanTujuan.fromJson(json['karyawan_tujuan']),
      catatan: json['catatan'],
      alasanPenolakan: json['alasan_penolakan'],
      tanggalDiproses: json['tanggal_diproses'] != null
          ? DateTime.parse(json['tanggal_diproses'])
          : null,
    );
  }
}

class ShiftInfo {
  final int jadwalId;
  final DateTime tanggal;
  final String hari;
  final String shiftCode;
  final String? waktuMulai;
  final String? waktuSelesai;
  final String? waktu;

  ShiftInfo({
    required this.jadwalId,
    required this.tanggal,
    required this.hari,
    required this.shiftCode,
    this.waktuMulai,
    this.waktuSelesai,
    this.waktu,
  });

  factory ShiftInfo.fromJson(Map<String, dynamic> json) {
    return ShiftInfo(
      jadwalId: json['jadwal_id'] ?? 0,
      tanggal: DateTime.parse(json['tanggal']),
      hari: json['hari'] ?? '',
      shiftCode: json['shift_code'] ?? '',
      waktuMulai: json['waktu_mulai'],
      waktuSelesai: json['waktu_selesai'],
      waktu: json['waktu'],
    );
  }
}

class KaryawanTujuan {
  final int id;
  final String nama;
  final String nik;
  final String noTelp;
  final String divisi;
  final String jabatan;

  KaryawanTujuan({
    required this.id,
    required this.nama,
    required this.nik,
    required this.noTelp,
    required this.divisi,
    required this.jabatan,
  });

  factory KaryawanTujuan.fromJson(Map<String, dynamic> json) {
    return KaryawanTujuan(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      nik: json['nik'] ?? '',
      noTelp: json['no_telp'] ?? '',
      divisi: json['divisi'] ?? '',
      jabatan: json['jabatan'] ?? '',
    );
  }
}

class JadwalShift {
  final int id;
  final DateTime tanggal;
  final String hari;
  final String shiftCode;
  final String? waktuMulai;
  final String? waktuSelesai;
  final bool isLibur;

  JadwalShift({
    required this.id,
    required this.tanggal,
    required this.hari,
    required this.shiftCode,
    this.waktuMulai,
    this.waktuSelesai,
    required this.isLibur,
  });

  factory JadwalShift.fromJson(Map<String, dynamic> json) {
    print('Parsing JadwalShift from JSON: $json'); // DEBUG

    // PERBAIKAN: Parse ID dengan benar dari berbagai tipe
    int parseId(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // PERBAIKAN: Parse tanggal dengan lebih robust
    DateTime parseTanggal(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('Error parsing date: $value, error: $e');
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    final parsedId = parseId(json['id'] ?? json['jadwal_id']);
    print(
      'Parsed ID: $parsedId from json[id]=${json['id']}, json[jadwal_id]=${json['jadwal_id']}',
    ); // DEBUG

    return JadwalShift(
      id: parsedId,
      tanggal: parseTanggal(json['tanggal']),
      hari: json['hari']?.toString() ?? '',
      shiftCode: json['shift_code']?.toString() ?? '',
      waktuMulai: json['waktu_mulai']?.toString(),
      waktuSelesai: json['waktu_selesai']?.toString(),
      isLibur:
          json['is_libur'] == true ||
          json['shift_code']?.toString().toUpperCase() == 'L',
    );
  }

  @override
  String toString() {
    return 'JadwalShift(id: $id, tanggal: $tanggal, hari: $hari, shiftCode: $shiftCode)';
  }
}

class KaryawanWithShift {
  final int id;
  final String nama;
  final String nik;
  final String noTelp;
  final String divisi;
  final String jabatan;
  final ShiftInfo shift;

  KaryawanWithShift({
    required this.id,
    required this.nama,
    required this.nik,
    required this.noTelp,
    required this.divisi,
    required this.jabatan,
    required this.shift,
  });

  factory KaryawanWithShift.fromJson(Map<String, dynamic> json) {
    return KaryawanWithShift(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      nik: json['nik'] ?? '',
      noTelp: json['no_telp'] ?? '',
      divisi: json['divisi'] ?? '',
      jabatan: json['jabatan'] ?? '',
      shift: ShiftInfo.fromJson(json['shift']),
    );
  }
}
