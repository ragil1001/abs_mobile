// lib/data/models/pengajuan_lembur_model.dart
import '../../core/config/app_config.dart';

class PengajuanLembur {
  final int id;
  final DateTime tanggal;
  final String kodeHari; // ✅ NEW: K atau L
  final String kodeHariText; // ✅ NEW: Hari Kerja atau Hari Libur
  final String? jamMulai; // ✅ NEW: HH:mm (wajib jika kode_hari = L)
  final String? jamSelesai; // ✅ NEW: HH:mm (wajib jika kode_hari = L)
  final String? fileSklUrl;
  final String? keteranganKaryawan; // ✅ NEW: Keterangan opsional
  final String status;
  final String statusText;
  final String? catatanAdmin;
  final DateTime? diprosesPada;
  final String? diprosesOleh;
  final DateTime createdAt;

  PengajuanLembur({
    required this.id,
    required this.tanggal,
    required this.kodeHari,
    required this.kodeHariText,
    this.jamMulai,
    this.jamSelesai,
    this.fileSklUrl,
    this.keteranganKaryawan,
    required this.status,
    required this.statusText,
    this.catatanAdmin,
    this.diprosesPada,
    this.diprosesOleh,
    required this.createdAt,
  });

  factory PengajuanLembur.fromJson(Map<String, dynamic> json) {
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

      return PengajuanLembur(
        id: json['id'] as int,
        tanggal: DateTime.parse(json['tanggal'] as String),
        kodeHari: getStringOrNull(json['kode_hari']) ?? 'K', // ✅ NEW
        kodeHariText:
            getStringOrNull(json['kode_hari_text']) ?? 'Hari Kerja', // ✅ NEW
        jamMulai: getStringOrNull(json['jam_mulai']), // ✅ NEW
        jamSelesai: getStringOrNull(json['jam_selesai']), // ✅ NEW
        fileSklUrl: getFullFileUrl(json['file_skl_url']),
        keteranganKaryawan: getStringOrNull(
          json['keterangan_karyawan'],
        ), // ✅ NEW
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
      print('Error parsing PengajuanLembur: $e');
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

  // ✅ NEW: Helper untuk hari libur
  bool get isHariLibur => kodeHari == 'L';
  bool get isHariKerja => kodeHari == 'K';

  String? getDownloadUrl(String? token) {
    if (fileSklUrl == null) return null;

    if (fileSklUrl!.contains('/pengajuan-lembur/') &&
        fileSklUrl!.contains('/download')) {
      return token != null ? '$fileSklUrl?token=$token' : fileSklUrl;
    }

    return fileSklUrl;
  }
}
