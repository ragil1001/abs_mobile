// lib/providers/notification_provider.dart
import 'package:flutter/foundation.dart';
import '../data/models/notification_model.dart';
import '../data/repositories/notification_repository.dart';
import '../data/services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _unreadCount = 0;
  int _currentPage = 1;
  bool _hasMore = true;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _unreadCount;
  bool get hasMore => _hasMore;

  /// Load notifications
  Future<void> loadNotifications({bool onlyUnread = false}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _hasMore = true;
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
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Load more notifications (pagination)
  Future<void> loadMore({bool onlyUnread = false}) async {
    if (_isLoadingMore || !_hasMore) return;

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
    } on ApiException catch (e) {
      _isLoadingMore = false;
      _currentPage--;
      notifyListeners();
      print('Load more error: ${e.message}');
    } catch (e) {
      _isLoadingMore = false;
      _currentPage--;
      notifyListeners();
      print('Load more error: $e');
    }
  }

  /// Get unread count only
  Future<void> loadUnreadCount() async {
    try {
      _unreadCount = await _repository.getUnreadCount();
      notifyListeners();
    } catch (e) {
      print('Load unread count error: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      await _repository.markAsRead(notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        _unreadCount = (_unreadCount - 1).clamp(0, 999);
        notifyListeners();
      }
    } catch (e) {
      print('Mark as read error: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();

      // Update local state
      _notifications = _notifications.map((n) {
        if (!n.isRead) {
          return n.copyWith(isRead: true, readAt: DateTime.now());
        }
        return n;
      }).toList();

      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      print('Mark all as read error: $e');
      rethrow;
    }
  }

  /// Delete notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      await _repository.deleteNotification(notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        if (!_notifications[index].isRead) {
          _unreadCount = (_unreadCount - 1).clamp(0, 999);
        }
        _notifications.removeAt(index);
        notifyListeners();
      }
    } catch (e) {
      print('Delete notification error: $e');
      rethrow;
    }
  }

  /// Clear all data
  void clear() {
    _notifications = [];
    _unreadCount = 0;
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;
    notifyListeners();
  }
}
