// lib/data/repositories/informasi_repository.dart
import '../models/informasi_model.dart';
import '../services/dio_service.dart';
import '../../core/config/app_config.dart';

class InformasiRepository {
  final DioService _dioService = DioService();

  /// Get list informasi for karyawan
  Future<Map<String, dynamic>> getInformasiList({
    int page = 1,
    int perPage = 20,
    String? isRead, // 'true', 'false', atau 'all'
    String? search,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'per_page': perPage};

      if (isRead != null && isRead != 'all') {
        params['is_read'] = isRead;
      }

      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }

      final response = await _dioService.get(
        AppConfig.informasiEndpoint,
        queryParameters: params,
      );

      if (response['success'] == true) {
        final data = response['data'] as List;
        final informasiList = data
            .map((json) => InformasiModel.fromJson(json))
            .toList();

        final pagination = response['pagination'];
        final hasMore =
            pagination != null &&
            pagination['current_page'] < pagination['last_page'];

        return {
          'informasi': informasiList,
          'unread_count': response['unread_count'] ?? 0,
          'has_more': hasMore,
        };
      } else {
        throw ApiException(response['message'] ?? 'Gagal memuat informasi');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get detail informasi
  Future<InformasiModel> getInformasiDetail(int informasiKaryawanId) async {
    try {
      final response = await _dioService.get(
        '${AppConfig.informasiEndpoint}/$informasiKaryawanId',
      );

      if (response['success'] == true) {
        if (response['data'] == null) {
          throw ApiException(
            'Data informasi tidak ditemukan',
            null,
            'not_found',
          );
        }

        return InformasiModel.fromJson(response['data']);
      } else {
        throw ApiException(
          response['message'] ?? 'Gagal memuat detail informasi',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Mark informasi as read
  Future<void> markAsRead(int informasiKaryawanId) async {
    try {
      final response = await _dioService.post(
        '${AppConfig.informasiEndpoint}/$informasiKaryawanId/read',
        {},
      );

      if (response['success'] != true) {
        throw ApiException(response['message'] ?? 'Gagal menandai informasi');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Mark all informasi as read
  Future<void> markAllAsRead() async {
    try {
      final response = await _dioService.post(
        '${AppConfig.informasiEndpoint}/read-all',
        {},
      );

      if (response['success'] != true) {
        throw ApiException(
          response['message'] ?? 'Gagal menandai semua informasi',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    try {
      final response = await _dioService.get(
        '${AppConfig.informasiEndpoint}/unread-count',
      );

      if (response['success'] == true) {
        return response['unread_count'] ?? 0;
      } else {
        throw ApiException(
          response['message'] ?? 'Gagal memuat jumlah informasi',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
