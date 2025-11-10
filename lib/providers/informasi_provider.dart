// lib/providers/informasi_provider.dart
import 'package:flutter/foundation.dart';
import '../data/models/informasi_model.dart';
import '../data/repositories/informasi_repository.dart';
import '../data/services/dio_service.dart';

enum InformasiState { initial, loading, loaded, error }

class InformasiProvider with ChangeNotifier {
  final InformasiRepository _repository = InformasiRepository();

  InformasiState _state = InformasiState.initial;
  List<InformasiModel> _informasiList = [];
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _errorType;
  int _unreadCount = 0;
  int _currentPage = 1;
  bool _hasMore = true;

  InformasiState get state => _state;
  List<InformasiModel> get informasiList => _informasiList;
  bool get isLoading => _state == InformasiState.loading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  String? get errorType => _errorType;
  int get unreadCount => _unreadCount;
  bool get hasMore => _hasMore;

  static const int _maxInformasi = 100;

  // Filtered lists
  List<InformasiModel> get unreadList =>
      _informasiList.where((i) => !i.isRead).toList();
  List<InformasiModel> get readList =>
      _informasiList.where((i) => i.isRead).toList();

  /// Load informasi list
  Future<void> loadInformasiList({String? isRead, String? search}) async {
    try {
      _state = InformasiState.loading;
      _errorMessage = null;
      _errorType = null;
      _currentPage = 1;
      _hasMore = true;

      _informasiList.clear();
      notifyListeners();

      final response = await _repository.getInformasiList(
        page: _currentPage,
        isRead: isRead,
        search: search,
      );

      _informasiList = response['informasi'];
      _unreadCount = response['unread_count'];
      _hasMore = response['has_more'];

      _state = InformasiState.loaded;
      notifyListeners();
    } on ApiException catch (e) {
      debugPrint('❌ Load informasi error: ${e.message}');

      _state = InformasiState.error;
      _errorMessage = e.message;
      _errorType = e.errorType;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Load informasi error: $e');
      _state = InformasiState.error;
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      _errorType = 'unknown';
      notifyListeners();
    }
  }

  /// Load more informasi (pagination)
  Future<void> loadMore({String? isRead, String? search}) async {
    if (_isLoadingMore || !_hasMore) return;

    if (_informasiList.length >= _maxInformasi) {
      debugPrint('⚠️ Max informasi reached, removing old ones');
      _informasiList.removeRange(0, 20);
    }

    try {
      _isLoadingMore = true;
      notifyListeners();

      _currentPage++;

      final response = await _repository.getInformasiList(
        page: _currentPage,
        isRead: isRead,
        search: search,
      );

      _informasiList.addAll(response['informasi']);
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

  /// Get informasi detail
  Future<InformasiModel?> getDetail(int informasiKaryawanId) async {
    try {
      _errorMessage = null;
      _errorType = null;

      final informasi = await _repository.getInformasiDetail(
        informasiKaryawanId,
      );

      // Update in list if exists
      final index = _informasiList.indexWhere(
        (i) => i.id == informasiKaryawanId,
      );
      if (index != -1) {
        _informasiList[index] = informasi;
        if (informasi.isRead && !_informasiList[index].isRead) {
          _unreadCount = (_unreadCount - 1).clamp(0, 999);
        }
        notifyListeners();
      }

      return informasi;
    } on ApiException catch (e) {
      debugPrint('❌ Get detail error: ${e.message}');
      _errorMessage = e.message;
      _errorType = e.errorType;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('❌ Get detail error: $e');
      _errorMessage = 'Gagal memuat detail informasi';
      _errorType = 'unknown';
      notifyListeners();
      return null;
    }
  }

  /// Mark informasi as read
  Future<bool> markAsRead(int informasiKaryawanId) async {
    try {
      _errorMessage = null;
      _errorType = null;

      await _repository.markAsRead(informasiKaryawanId);

      final index = _informasiList.indexWhere(
        (i) => i.id == informasiKaryawanId,
      );
      if (index != -1 && !_informasiList[index].isRead) {
        _informasiList[index] = _informasiList[index].copyWith(
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
      _errorMessage = 'Gagal menandai informasi';
      _errorType = 'unknown';
      notifyListeners();
      return false;
    }
  }

  /// Mark all informasi as read
  Future<bool> markAllAsRead() async {
    try {
      _errorMessage = null;
      _errorType = null;

      await _repository.markAllAsRead();

      _informasiList = _informasiList.map((i) {
        if (!i.isRead) {
          return i.copyWith(isRead: true, readAt: DateTime.now());
        }
        return i;
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
      _errorMessage = 'Gagal menandai semua informasi';
      _errorType = 'unknown';
      notifyListeners();
      return false;
    }
  }

  /// Load unread count only
  Future<void> loadUnreadCount() async {
    try {
      _unreadCount = await _repository.getUnreadCount();
      notifyListeners();
    } catch (e) {
      debugPrint('Load unread count error: $e');
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
    _informasiList.clear();
    _unreadCount = 0;
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;
    _errorType = null;
    _state = InformasiState.initial;
    notifyListeners();
  }
}
