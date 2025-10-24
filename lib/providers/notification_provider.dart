import 'package:flutter/foundation.dart';
import '../data/models/notification_model.dart';
import '../data/repositories/notification_repository.dart';
import '../data/services/dio_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _errorType;
  int _unreadCount = 0;
  int _currentPage = 1;
  bool _hasMore = true;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  String? get errorType => _errorType;
  int get unreadCount => _unreadCount;
  bool get hasMore => _hasMore;

  static const int _maxNotifications = 100;

  /// Load notifications
  Future<void> loadNotifications({bool onlyUnread = false}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _errorType = null;
      _currentPage = 1;
      _hasMore = true;

      _notifications.clear();
      notifyListeners();

      final response = await _repository.getNotifications(
        page: _currentPage,
        onlyUnread: onlyUnread,
      );

      _notifications = response['notifications'];
      _unreadCount = response['unread_count'];
      _hasMore = response['has_more'];

      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      debugPrint('❌ Load notifications error: ${e.message}');
      debugPrint('❌ Error type: ${e.errorType}');

      _isLoading = false;
      _errorMessage = e.message;
      _errorType = e.errorType;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Load notifications error: $e');
      _isLoading = false;
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      _errorType = 'unknown';
      notifyListeners();
    }
  }

  /// Load more notifications (pagination)
  Future<void> loadMore({bool onlyUnread = false}) async {
    if (_isLoadingMore || !_hasMore) return;

    if (_notifications.length >= _maxNotifications) {
      debugPrint('⚠️ Max notifications reached, removing old ones');
      _notifications.removeRange(0, 20);
    }

    try {
      _isLoadingMore = true;
      notifyListeners();

      _currentPage++;

      final response = await _repository.getNotifications(
        page: _currentPage,
        onlyUnread: onlyUnread,
      );

      _notifications.addAll(response['notifications']);
      _hasMore = response['has_more'];

      _isLoadingMore = false;
      notifyListeners();
    } on ApiException {
      _isLoadingMore = false;
      _currentPage--;
      notifyListeners();
    } catch (e) {
      _isLoadingMore = false;
      _currentPage--;
      notifyListeners();
    }
  }

  /// Get unread count only
  Future<void> loadUnreadCount() async {
    try {
      _unreadCount = await _repository.getUnreadCount();
      notifyListeners();
    } catch (e) {
      debugPrint('Load unread count error: $e');
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      _errorMessage = null;
      _errorType = null;

      await _repository.markAsRead(notificationId);

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        _unreadCount = (_unreadCount - 1).clamp(0, 999);
        notifyListeners();
      }

      return true;
    } on ApiException catch (e) {
      debugPrint('❌ Mark as read error: ${e.message}');
      _errorMessage = e.message;
      _errorType = e.errorType;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ Mark as read error: $e');
      _errorMessage = 'Gagal menandai notifikasi';
      _errorType = 'unknown';
      notifyListeners();
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      _errorMessage = null;
      _errorType = null;

      await _repository.markAllAsRead();

      _notifications = _notifications.map((n) {
        if (!n.isRead) {
          return n.copyWith(isRead: true, readAt: DateTime.now());
        }
        return n;
      }).toList();

      _unreadCount = 0;
      notifyListeners();

      return true;
    } on ApiException catch (e) {
      debugPrint('❌ Mark all as read error: ${e.message}');
      _errorMessage = e.message;
      _errorType = e.errorType;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ Mark all as read error: $e');
      _errorMessage = 'Gagal menandai semua notifikasi';
      _errorType = 'unknown';
      notifyListeners();
      return false;
    }
  }

  /// Delete notification with proper error handling
  Future<bool> deleteNotification(int notificationId) async {
    try {
      _errorMessage = null;
      _errorType = null;

      debugPrint('🗑️ Deleting notification: $notificationId');

      await _repository.deleteNotification(notificationId);

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        if (!_notifications[index].isRead) {
          _unreadCount = (_unreadCount - 1).clamp(0, 999);
        }
        _notifications.removeAt(index);
        notifyListeners();
      }

      debugPrint('✅ Notification deleted successfully');
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ Delete notification error: ${e.message}');
      debugPrint('❌ Error type: ${e.errorType}');
      debugPrint('❌ Status code: ${e.statusCode}');

      _errorType = e.errorType;

      // Handle specific error types
      if (e.errorType == 'unauthorized' || e.statusCode == 401) {
        _errorMessage = 'Sesi Anda telah berakhir. Silakan login kembali.';
        _errorType = 'unauthorized';
      } else if (e.errorType == 'forbidden' || e.statusCode == 403) {
        _errorMessage =
            'Anda tidak memiliki akses untuk menghapus notifikasi ini.';
      } else if (e.errorType == 'not_found' || e.statusCode == 404) {
        _errorMessage = 'Notifikasi tidak ditemukan atau sudah dihapus.';
        // Remove from local list anyway
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          if (!_notifications[index].isRead) {
            _unreadCount = (_unreadCount - 1).clamp(0, 999);
          }
          _notifications.removeAt(index);
        }
      } else if (e.errorType == 'timeout') {
        _errorMessage = 'Koneksi timeout. Silakan coba lagi.';
      } else if (e.errorType == 'connection_error') {
        _errorMessage =
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      } else if (e.errorType == 'server_error') {
        _errorMessage = 'Server bermasalah. Silakan coba lagi nanti.';
      } else {
        _errorMessage = e.message;
      }

      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ Delete notification unexpected error: $e');
      _errorType = 'unknown';
      _errorMessage = 'Terjadi kesalahan tidak terduga. Silakan coba lagi.';
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    _errorType = null;
    notifyListeners();
  }

  /// Clear all data
  void clear() {
    _notifications.clear();
    _unreadCount = 0;
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;
    _errorType = null;
    notifyListeners();
  }
}
