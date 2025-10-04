// lib/data/repositories/izin_repository.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/pengajuan_izin_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../../core/config/app_config.dart';

class IzinRepository {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  /// Get list pengajuan izin karyawan
  Future<List<PengajuanIzin>> getMyPengajuan() async {
    try {
      final response = await _apiService.get(
        '${AppConfig.mobileApiPrefix}/pengajuan-izin',
      );

      print('=== GET MY PENGAJUAN DEBUG ===');
      print('Response: $response');
      print('Success: ${response['success']}');
      print('Data type: ${response['data']?.runtimeType}');

      if (response['success'] == true) {
        final data = response['data'];

        if (data == null) {
          print('Data is null, returning empty list');
          return [];
        }

        if (data is! List) {
          print('ERROR: Data is not a List, it is: ${data.runtimeType}');
          throw ApiException('Format data response tidak valid');
        }

        print('Processing ${data.length} items');

        final List<PengajuanIzin> result = [];
        for (var i = 0; i < data.length; i++) {
          try {
            final item = data[i];
            if (item is Map<String, dynamic>) {
              result.add(PengajuanIzin.fromJson(item));
            } else {
              print('Item $i is not a Map: ${item.runtimeType}');
            }
          } catch (e) {
            print('Error parsing item $i: $e');
            // Continue with other items
          }
        }

        print('Successfully parsed ${result.length} pengajuan');
        return result;
      } else {
        throw ApiException(
          response['message'] ?? 'Gagal mengambil data pengajuan izin',
        );
      }
    } catch (e) {
      print('=== GET MY PENGAJUAN ERROR ===');
      print('Error: $e');
      rethrow;
    }
  }

  /// Get detail pengajuan izin
  Future<PengajuanIzin> getDetailPengajuan(int id) async {
    try {
      final response = await _apiService.get(
        '${AppConfig.mobileApiPrefix}/pengajuan-izin/$id',
      );

      print('=== GET DETAIL PENGAJUAN DEBUG ===');
      print('Response: $response');

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
      print('Get detail pengajuan error: $e');
      rethrow;
    }
  }

  /// Ajukan izin dengan file upload
  Future<PengajuanIzin> ajukanIzin({
    required String jenisIzin,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
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
        'X-Requested-With': 'FlutterApp', // Tambahkan ini
      });

      // Add fields
      request.fields['jenis_izin'] = jenisIzin;
      request.fields['tanggal_mulai'] = tanggalMulai.toIso8601String().split(
        'T',
      )[0];
      request.fields['tanggal_selesai'] = tanggalSelesai
          .toIso8601String()
          .split('T')[0];

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
              'X-Requested-With': 'FlutterApp', // Tambahkan ini
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
      final response = await _apiService.delete(
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
