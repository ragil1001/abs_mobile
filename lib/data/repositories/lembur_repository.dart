// lib/data/repositories/lembur_repository.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/pengajuan_lembur_model.dart';
import '../services/dio_service.dart';
import '../services/storage_service.dart';
import '../../core/config/app_config.dart';

class LemburRepository {
  final DioService _dioService = DioService();
  final StorageService _storageService = StorageService();

  /// Get list pengajuan lembur karyawan
  Future<List<PengajuanLembur>> getMyPengajuan() async {
    try {
      final response = await _dioService.get(
        '${AppConfig.mobileApiPrefix}/pengajuan-lembur',
      );

      if (response['success'] == true) {
        final data = response['data'];

        if (data == null) {
          return [];
        }

        if (data is! List) {
          throw ApiException('Format data response tidak valid');
        }

        final List<PengajuanLembur> result = [];
        for (var i = 0; i < data.length; i++) {
          try {
            final item = data[i];
            if (item is Map<String, dynamic>) {
              result.add(PengajuanLembur.fromJson(item));
            }
          } catch (e) {
            print('Error parsing item $i: $e');
          }
        }

        return result;
      } else {
        throw ApiException(
          response['message'] ?? 'Gagal mengambil data pengajuan lembur',
        );
      }
    } catch (e) {
      print('Get my pengajuan lembur error: $e');
      rethrow;
    }
  }

  /// Get detail pengajuan lembur
  Future<PengajuanLembur> getDetailPengajuan(int id) async {
    try {
      final response = await _dioService.get(
        '${AppConfig.mobileApiPrefix}/pengajuan-lembur/$id',
      );

      if (response['success'] == true) {
        if (response['data'] == null) {
          throw ApiException('Data detail tidak ditemukan');
        }

        if (response['data'] is! Map<String, dynamic>) {
          throw ApiException('Format data detail tidak valid');
        }

        return PengajuanLembur.fromJson(response['data']);
      } else {
        throw ApiException(
          response['message'] ?? 'Gagal mengambil detail pengajuan lembur',
        );
      }
    } catch (e) {
      print('Get detail pengajuan lembur error: $e');
      rethrow;
    }
  }

  /// Ajukan lembur
  Future<PengajuanLembur> ajukanLembur({
    required DateTime tanggal,
    required File fileSkl,
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiException('Token tidak ditemukan. Silakan login kembali.');
      }

      final uri = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.mobileApiPrefix}/pengajuan-lembur',
      );

      var request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'X-Requested-With': 'FlutterApp',
      });

      // Add fields
      request.fields['tanggal'] = tanggal.toIso8601String().split('T')[0];

      // Add SKL file (WAJIB)
      final fileStream = http.ByteStream(fileSkl.openRead());
      final fileLength = await fileSkl.length();

      final multipartFile = http.MultipartFile(
        'file_skl',
        fileStream,
        fileLength,
        filename: fileSkl.path.split('/').last,
      );

      request.files.add(multipartFile);

      // Send request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final response = await http.Response.fromStream(streamedResponse);
      final responseData = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseData['success'] == true) {
          return PengajuanLembur.fromJson(responseData['data']);
        } else {
          throw ApiException(
            responseData['message'] ?? 'Gagal mengajukan lembur',
          );
        }
      } else {
        throw ApiException(
          responseData['message'] ?? 'Gagal mengajukan lembur',
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

  /// Batalkan pengajuan lembur
  Future<void> batalkanPengajuan(int id) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiException('Token tidak ditemukan. Silakan login kembali.');
      }

      final uri = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.mobileApiPrefix}/pengajuan-lembur/$id/batalkan',
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

  /// Hapus pengajuan lembur
  Future<void> hapusPengajuan(int id) async {
    try {
      final response = await _dioService.delete(
        '${AppConfig.mobileApiPrefix}/pengajuan-lembur/$id',
      );

      if (response['success'] != true) {
        throw ApiException(response['message'] ?? 'Gagal menghapus pengajuan');
      }
    } catch (e) {
      rethrow;
    }
  }
}
