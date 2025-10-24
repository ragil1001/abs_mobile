// lib/data/models/pengajuan_izin_model.dart
import 'package:flutter/foundation.dart';
import '../../core/config/app_config.dart';

class PengajuanIzin {
  final int id;
  final String kategoriIzin; // UPDATED: kategori_izin
  final String? subKategoriIzin; // NEW: sub_kategori_izin
  final String deskripsiIzin; // NEW: deskripsi_izin
  final int? durasiOtomatis; // NEW: durasi_otomatis
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final int durasiHari;
  final String? keterangan;
  final String? fileUrl;
  final String status;
  final String statusText;
  final String? catatanAdmin;
  final DateTime? diprosesPada;
  final String? diprosesOleh;
  final DateTime createdAt;

  PengajuanIzin({
    required this.id,
    required this.kategoriIzin,
    this.subKategoriIzin,
    required this.deskripsiIzin,
    this.durasiOtomatis,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.durasiHari,
    this.keterangan,
    this.fileUrl,
    required this.status,
    required this.statusText,
    this.catatanAdmin,
    this.diprosesPada,
    this.diprosesOleh,
    required this.createdAt,
  });

  factory PengajuanIzin.fromJson(Map<String, dynamic> json) {
    try {
      String? getStringOrNull(dynamic value) {
        if (value == null) return null;
        if (value is String) return value.isEmpty ? null : value;
        return value.toString();
      }

      String? getFullFileUrl(dynamic fileUrlValue) {
        final fileUrl = getStringOrNull(fileUrlValue);
        if (fileUrl == null) return null;

        if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
          return fileUrl;
        }

        final cleanPath = fileUrl.startsWith('/')
            ? fileUrl.substring(1)
            : fileUrl;
        return '${AppConfig.baseUrl.replaceAll('/api', '')}/$cleanPath';
      }

      return PengajuanIzin(
        id: json['id'] as int,
        kategoriIzin: getStringOrNull(json['kategori_izin']) ?? 'izin',
        subKategoriIzin: getStringOrNull(json['sub_kategori_izin']),
        deskripsiIzin: getStringOrNull(json['deskripsi_izin']) ?? 'Izin',
        durasiOtomatis: json['durasi_otomatis'] as int?,
        tanggalMulai: DateTime.parse(json['tanggal_mulai'] as String),
        tanggalSelesai: DateTime.parse(json['tanggal_selesai'] as String),
        durasiHari: json['durasi_hari'] as int? ?? 0,
        keterangan: getStringOrNull(json['keterangan']),
        fileUrl: getFullFileUrl(json['file_url']),
        status: getStringOrNull(json['status']) ?? 'pending',
        statusText: getStringOrNull(json['status_text']) ?? 'Pending',
        catatanAdmin: getStringOrNull(json['catatan_admin']),
        diprosesPada: json['diproses_pada'] != null
            ? DateTime.parse(json['diproses_pada'] as String)
            : null,
        diprosesOleh: getStringOrNull(json['diproses_oleh']),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
    } catch (e) {
      // print('Error parsing PengajuanIzin: $e');
      // print('JSON data: $json');
      rethrow;
    }
  }

  // Helper methods
  bool get isPending => status == 'pending';
  bool get isDisetujui => status == 'disetujui';
  bool get isDitolak => status == 'ditolak';
  bool get isDibatalkan => status == 'dibatalkan';
  bool get canCancel => isPending;
  bool get canDelete => isDibatalkan || isDitolak;

  // NEW: Helper untuk cek kategori
  bool get isSakit => kategoriIzin == 'sakit';
  bool get isIzin => kategoriIzin == 'izin';
  bool get isCutiTahunan => kategoriIzin == 'cuti_tahunan';
  bool get isCutiKhusus => kategoriIzin == 'cuti_khusus';

  // Get downloadable file URL with token
  String? getDownloadUrl(String? token) {
    if (fileUrl == null) return null;

    if (fileUrl!.contains('/pengajuan-izin/') &&
        fileUrl!.contains('/download')) {
      return token != null ? '$fileUrl?token=$token' : fileUrl;
    }

    return fileUrl;
  }

  // NEW: Get display label
  String get kategoriLabel {
    switch (kategoriIzin) {
      case 'sakit':
        return 'Sakit';
      case 'izin':
        return 'Izin';
      case 'cuti_tahunan':
        return 'Cuti Tahunan';
      case 'cuti_khusus':
        return 'Cuti Khusus';
      default:
        return deskripsiIzin;
    }
  }
}

// NEW: Model untuk Kategori Izin
class KategoriIzin {
  final String value;
  final String label;
  final String kode;
  final bool hasSubKategori;
  final bool butuhDokumen;
  final int? maxHari;
  final int? sisaCuti;
  final String deskripsi;

  KategoriIzin({
    required this.value,
    required this.label,
    required this.kode,
    required this.hasSubKategori,
    required this.butuhDokumen,
    this.maxHari,
    this.sisaCuti,
    required this.deskripsi,
  });

  factory KategoriIzin.fromJson(Map<String, dynamic> json) {
    try {
      // ✅ FIX: Safe parsing dengan null checks dan type conversion
      return KategoriIzin(
        value: json['value']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        kode: json['kode']?.toString() ?? '',
        hasSubKategori: json['has_sub_kategori'] == true,
        butuhDokumen: json['butuh_dokumen'] == true,
        maxHari: json['max_hari'] != null
            ? int.tryParse(json['max_hari'].toString())
            : null,
        sisaCuti: json['sisa_cuti'] != null
            ? int.tryParse(json['sisa_cuti'].toString())
            : null,
        deskripsi: json['deskripsi']?.toString() ?? '',
      );
    } catch (e) {
      // ✅ DEBUG: Print error untuk debugging
      debugPrint('❌ Error parsing KategoriIzin: $e');
      debugPrint('   JSON: $json');
      rethrow;
    }
  }
}

// NEW: Model untuk Sub Kategori Cuti Khusus
class SubKategoriCutiKhusus {
  final String value;
  final String label;
  final int durasiHari;
  final String deskripsi;

  SubKategoriCutiKhusus({
    required this.value,
    required this.label,
    required this.durasiHari,
    required this.deskripsi,
  });

  factory SubKategoriCutiKhusus.fromJson(Map<String, dynamic> json) {
    return SubKategoriCutiKhusus(
      value: json['value'] ?? '',
      label: json['label'] ?? '',
      durasiHari: json['durasi_hari'] ?? 0,
      deskripsi: json['deskripsi'] ?? '',
    );
  }
}
