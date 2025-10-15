// lib/data/repositories/notification_repository.dart
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../../core/config/app_config.dart';

class NotificationRepository {
  final ApiService _apiService = ApiService();

  /// Get notifications with pagination
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int perPage = 20,
    bool onlyUnread = false,
  }) async {
    try {
      final response = await _apiService.get(
        '${AppConfig.notificationsEndpoint}?page=$page&per_page=$perPage&only_unread=${onlyUnread ? 1 : 0}',
      );

      if (response['success'] == true) {
        final data = response['data'] as List;
        final notifications = data
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        final pagination = response['pagination'];
        final hasMore =
            pagination != null &&
            pagination['current_page'] < pagination['last_page'];

        return {
          'notifications': notifications,
          'unread_count': response['unread_count'] ?? 0,
          'has_more': hasMore,
        };
      } else {
        throw ApiException(response['message'] ?? 'Gagal memuat notifikasi');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.get(
        AppConfig.notificationUnreadCountEndpoint,
      );

      if (response['success'] == true) {
        return response['unread_count'] ?? 0;
      } else {
        throw ApiException(
          response['message'] ?? 'Gagal memuat jumlah notifikasi',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      final response = await _apiService.post(
        '${AppConfig.notificationsEndpoint}/$notificationId/read',
        {},
      );

      if (response['success'] != true) {
        throw ApiException(response['message'] ?? 'Gagal menandai notifikasi');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final response = await _apiService.post(
        '${AppConfig.notificationsEndpoint}/read-all',
        {},
      );

      if (response['success'] != true) {
        throw ApiException(
          response['message'] ?? 'Gagal menandai semua notifikasi',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      final response = await _apiService.delete(
        '${AppConfig.notificationsEndpoint}/$notificationId',
      );

      if (response['success'] != true) {
        throw ApiException(response['message'] ?? 'Gagal menghapus notifikasi');
      }
    } catch (e) {
      rethrow;
    }
  }
}
