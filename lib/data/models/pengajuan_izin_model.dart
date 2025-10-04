// lib/data/models/pengajuan_izin_model.dart
import '../../core/config/app_config.dart';

class PengajuanIzin {
  final int id;
  final String jenisIzin;
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
    required this.jenisIzin,
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
      // Helper function to safely get string value
      String? getStringOrNull(dynamic value) {
        if (value == null) return null;
        if (value is String) return value.isEmpty ? null : value;
        return value.toString();
      }

      // Helper to get full file URL
      String? getFullFileUrl(dynamic fileUrlValue) {
        final fileUrl = getStringOrNull(fileUrlValue);
        if (fileUrl == null) return null;

        // If it's already a full URL, return as is
        if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
          return fileUrl;
        }

        // If it's a relative path, convert to full URL
        // Remove leading slash if exists
        final cleanPath = fileUrl.startsWith('/')
            ? fileUrl.substring(1)
            : fileUrl;
        return '${AppConfig.baseUrl.replaceAll('/api', '')}/$cleanPath';
      }

      return PengajuanIzin(
        id: json['id'] as int,
        jenisIzin: getStringOrNull(json['jenis_izin']) ?? 'Izin',
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
      print('Error parsing PengajuanIzin: $e');
      print('JSON data: $json');
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

  // Get downloadable file URL with token
  String? getDownloadUrl(String? token) {
    if (fileUrl == null) return null;

    // If file URL contains download endpoint, add token as query param
    if (fileUrl!.contains('/pengajuan-izin/') &&
        fileUrl!.contains('/download')) {
      return token != null ? '$fileUrl?token=$token' : fileUrl;
    }

    return fileUrl;
  }
}
