// lib/data/repositories/izin_repository.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/pengajuan_izin_model.dart';
import '../services/dio_service.dart';
import '../services/storage_service.dart';
import '../../core/config/app_config.dart';

class IzinRepository {
  final DioService _dioService = DioService();
  final StorageService _storageService = StorageService();

  Future<List<KategoriIzin>> getKategoriIzinList({
    List<String>? enabledCategories,
  }) async {
    try {
      final response = await _dioService.get(
        '${AppConfig.mobileApiPrefix}/pengajuan-izin/kategori-list',
      );

      if (response['success'] == true) {
        final data = response['data'] as List;

        // ✅ FIX: Filter hanya kategori yang enabled = true
        return data
            .where((json) => json['enabled'] == true)
            .map((json) => KategoriIzin.fromJson(json))
            .toList();
      } else {
        throw ApiException(
          response['message'] ?? 'Gagal mengambil kategori izin',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<SubKategoriCutiKhusus>> getSubKategoriCutiKhususList({
    List<String>? enabledSubCategories,
  }) async {
    try {
      final response = await _dioService.get(
        '${AppConfig.mobileApiPrefix}/pengajuan-izin/sub-kategori-list',
      );

      if (response['success'] == true) {
        final data = response['data'] as List;

        // ✅ FIX: Filter hanya sub kategori yang enabled = true
        return data
            .where((json) => json['enabled'] == true)
            .map((json) => SubKategoriCutiKhusus.fromJson(json))
            .toList();
      } else {
        throw ApiException(
          response['message'] ?? 'Gagal mengambil sub kategori',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Hitung tanggal selesai otomatis untuk cuti khusus
  Future<Map<String, dynamic>> hitungTanggalSelesai({
    required DateTime tanggalMulai,
    required String subKategoriIzin,
  }) async {
    try {
      final response = await _dioService
          .post('${AppConfig.mobileApiPrefix}/pengajuan-izin/hitung-tanggal', {
            'tanggal_mulai': tanggalMulai.toIso8601String().split('T')[0],
            'sub_kategori_izin': subKategoriIzin,
          });

      if (response['success'] == true) {
        return response['data'];
      } else {
        throw ApiException(response['message'] ?? 'Gagal menghitung tanggal');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get list pengajuan izin karyawan
  Future<List<PengajuanIzin>> getMyPengajuan() async {
    try {
      final response = await _dioService.get(
        '${AppConfig.mobileApiPrefix}/pengajuan-izin',
      );

      if (response['success'] == true) {
        final data = response['data'];

        if (data == null) {
          return [];
        }

        if (data is! List) {
          throw ApiException('Format data response tidak valid');
        }

        final List<PengajuanIzin> result = [];
        for (var i = 0; i < data.length; i++) {
          try {
            final item = data[i];
            if (item is Map<String, dynamic>) {
              result.add(PengajuanIzin.fromJson(item));
            }
          } catch (e) {
            // Skip invalid items
          }
        }

        return result;
      } else {
        throw ApiException(
          response['message'] ?? 'Gagal mengambil data pengajuan izin',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get detail pengajuan izin
  Future<PengajuanIzin> getDetailPengajuan(int id) async {
    try {
      final response = await _dioService.get(
        '${AppConfig.mobileApiPrefix}/pengajuan-izin/$id',
      );

      if (response['success'] == true) {
        if (response['data'] == null) {
          throw ApiException('Data detail tidak ditemukan');
        }

        if (response['data'] is! Map<String, dynamic>) {
          throw ApiException('Format data detail tidak valid');
        }

        return PengajuanIzin.fromJson(response['data']);
      } else {
        throw ApiException(
          response['message'] ?? 'Gagal mengambil detail pengajuan izin',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Ajukan izin dengan kategori lengkap
  Future<PengajuanIzin> ajukanIzin({
    required String kategoriIzin,
    String? subKategoriIzin,
    String? deskripsiIzin,
    required DateTime tanggalMulai,
    DateTime? tanggalSelesai,
    String? keterangan,
    File? fileDokumen,
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiException('Token tidak ditemukan. Silakan login kembali.');
      }

      final uri = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.mobileApiPrefix}/pengajuan-izin',
      );

      var request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'X-Requested-With': 'FlutterApp',
      });

      // Add fields
      request.fields['kategori_izin'] = kategoriIzin;

      if (subKategoriIzin != null && subKategoriIzin.isNotEmpty) {
        request.fields['sub_kategori_izin'] = subKategoriIzin;
      }

      if (deskripsiIzin != null && deskripsiIzin.isNotEmpty) {
        request.fields['deskripsi_izin'] = deskripsiIzin;
      }

      request.fields['tanggal_mulai'] = tanggalMulai.toIso8601String().split(
        'T',
      )[0];

      if (tanggalSelesai != null) {
        request.fields['tanggal_selesai'] = tanggalSelesai
            .toIso8601String()
            .split('T')[0];
      }

      if (keterangan != null && keterangan.isNotEmpty) {
        request.fields['keterangan'] = keterangan;
      }

      // Add file if exists
      if (fileDokumen != null) {
        final fileStream = http.ByteStream(fileDokumen.openRead());
        final fileLength = await fileDokumen.length();

        final multipartFile = http.MultipartFile(
          'file_dokumen',
          fileStream,
          fileLength,
          filename: fileDokumen.path.split('/').last,
        );

        request.files.add(multipartFile);
      }

      // Send request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final response = await http.Response.fromStream(streamedResponse);
      final responseData = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseData['success'] == true) {
          return PengajuanIzin.fromJson(responseData['data']);
        } else {
          throw ApiException(
            responseData['message'] ?? 'Gagal mengajukan izin',
          );
        }
      } else {
        throw ApiException(
          responseData['message'] ?? 'Gagal mengajukan izin',
          response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException(
        'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan: ${e.toString()}');
    }
  }

  /// Batalkan pengajuan izin
  Future<void> batalkanPengajuan(int id) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiException('Token tidak ditemukan. Silakan login kembali.');
      }

      final uri = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.mobileApiPrefix}/pengajuan-izin/$id/batalkan',
      );

      final response = await http
          .patch(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
              'X-Requested-With': 'FlutterApp',
            },
          )
          .timeout(const Duration(seconds: 30));

      final responseData = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseData['success'] != true) {
          throw ApiException(
            responseData['message'] ?? 'Gagal membatalkan pengajuan',
          );
        }
      } else {
        throw ApiException(
          responseData['message'] ?? 'Gagal membatalkan pengajuan',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan: ${e.toString()}');
    }
  }

  /// Hapus pengajuan izin
  Future<void> hapusPengajuan(int id) async {
    try {
      final response = await _dioService.delete(
        '${AppConfig.mobileApiPrefix}/pengajuan-izin/$id',
      );

      if (response['success'] != true) {
        throw ApiException(response['message'] ?? 'Gagal menghapus pengajuan');
      }
    } catch (e) {
      rethrow;
    }
  }
}
