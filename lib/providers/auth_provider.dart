import 'package:flutter/foundation.dart';
import '../data/models/karyawan_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/dio_service.dart';
import '../data/services/storage_service.dart';
import '../data/services/cache_manager_service.dart';
import '../data/services/firebase_messaging_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  final StorageService _storageService = StorageService();

  AuthState _state = AuthState.initial;
  Karyawan? _currentUser;
  String? _errorMessage;
  String? _errorType;

  AuthState get state => _state;
  Karyawan? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  String? get errorType => _errorType;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  String? _token;
  String? get token => _token;

  /// Initialize auth state - NO SESSION EXPIRY
  Future<void> initAuth() async {
    try {
      _token = await _storageService.getToken();
      final isLoggedIn = await _authRepository.isLoggedIn();

      if (isLoggedIn) {
        _state = AuthState.loading;
        notifyListeners();

        try {
          // Verify token with server
          _currentUser = await _authRepository.getCurrentUser();
          _state = AuthState.authenticated;

          debugPrint('✅ Auth initialized - user logged in');
          debugPrint('👤 User: ${_currentUser?.nama}');

          // Send FCM token to backend
          await _sendFcmTokenToBackend();
        } catch (e) {
          debugPrint('❌ Token verification failed: $e');
          _state = AuthState.unauthenticated;
          _currentUser = null;
          _token = null;

          // Clear invalid session
          await _authRepository.clearSession();
        }
      } else {
        debugPrint('ℹ️ No saved session found');
        _state = AuthState.unauthenticated;
        _token = null;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Auth init error: $e');
      _state = AuthState.unauthenticated;
      _token = null;
      notifyListeners();
    }
  }

  /// Login - Creates unlimited session with detailed error handling
  Future<bool> login(
    String username,
    String password, {
    bool rememberMe = false,
  }) async {
    try {
      _state = AuthState.loading;
      _errorMessage = null;
      _errorType = null;
      notifyListeners();

      debugPrint('🔐 Login attempt for: $username');

      final authResponse = await _authRepository.login(username, password);
      _currentUser = authResponse.karyawan;
      _token = await _storageService.getToken();

      if (rememberMe) {
        await _authRepository.saveRememberMe(username, true);
      } else {
        await _authRepository.saveRememberMe('', false);
      }

      _state = AuthState.authenticated;
      notifyListeners();

      debugPrint('✅ Login successful');
      debugPrint('👤 User: ${_currentUser?.nama}');

      // Send FCM token to backend
      await _sendFcmTokenToBackend();

      return true;
    } on ApiException catch (e) {
      debugPrint('❌ Login failed: ${e.message}');
      debugPrint('❌ Error type: ${e.errorType}');
      debugPrint('❌ Status code: ${e.statusCode}');

      _state = AuthState.error;
      _errorMessage = e.message;
      _errorType = e.errorType;

      // Beri pesan spesifik untuk error login
      if (e.statusCode == 422 || e.statusCode == 401) {
        // Validation error atau unauthorized
        if (e.message.toLowerCase().contains('username') ||
            e.message.toLowerCase().contains('password') ||
            e.message.toLowerCase().contains('salah')) {
          _errorMessage = e.message;
        } else {
          _errorMessage = 'Username atau password yang Anda masukkan salah.';
        }
      } else if (e.errorType == 'timeout') {
        _errorMessage =
            'Koneksi timeout. Periksa koneksi internet Anda dan coba lagi.';
      } else if (e.errorType == 'connection_error') {
        _errorMessage =
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      } else if (e.errorType == 'server_error') {
        _errorMessage =
            'Server sedang mengalami gangguan. Silakan coba lagi nanti.';
      } else if (e.message.isEmpty) {
        _errorMessage = 'Terjadi kesalahan saat login. Silakan coba lagi.';
      }

      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ Login error: $e');
      _state = AuthState.error;
      _errorType = 'unknown';

      // Handle berbagai jenis error
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection') ||
          e.toString().contains('Network')) {
        _errorMessage =
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      } else if (e.toString().contains('TimeoutException') ||
          e.toString().contains('timeout')) {
        _errorMessage = 'Koneksi timeout. Silakan coba lagi.';
      } else {
        _errorMessage = 'Terjadi kesalahan tidak terduga. Silakan coba lagi.';
      }

      notifyListeners();
      return false;
    }
  }

  /// Send FCM token to backend
  Future<void> _sendFcmTokenToBackend() async {
    try {
      final fcmToken = await FirebaseMessagingService.getToken();

      if (fcmToken != null && _token != null) {
        debugPrint('📱 Sending FCM token to backend...');
        debugPrint('   Token: ${fcmToken.substring(0, 30)}...');

        await _authRepository.storeFcmToken(fcmToken);
        debugPrint('✅ FCM token sent to backend');
      } else {
        debugPrint('⚠️ FCM token or auth token is null');
      }
    } catch (e) {
      debugPrint('❌ Error sending FCM token: $e');
      // Non-critical error - continue anyway
    }
  }

  /// Logout - Manual only, no auto logout
  Future<void> logout() async {
    try {
      debugPrint('🚪 Starting logout process...');

      final karyawanId = _currentUser?.id;
      final userName = _currentUser?.nama;
      debugPrint('👤 Logging out user: $userName (ID: $karyawanId)');

      // Get FCM token for verification
      final fcmToken = await FirebaseMessagingService.getToken();
      if (fcmToken != null) {
        debugPrint('✅ FCM Token: ${fcmToken.substring(0, 30)}...');
      } else {
        debugPrint('⚠️ FCM Token is NULL!');
      }

      // Call backend logout (which deletes FCM tokens)
      debugPrint('🌐 Calling backend logout API...');
      await _authRepository.logout();
      debugPrint('✅ Backend logout API completed (FCM tokens deleted)');

      // Delete local FCM token
      debugPrint('🗑️ Deleting local FCM token...');
      try {
        await FirebaseMessagingService.deleteToken();
        debugPrint('✅ Local FCM token deleted');
      } catch (e) {
        debugPrint('❌ Error deleting local FCM: $e');
      }

      // Clear cache
      debugPrint('🗑️ Clearing cache...');
      try {
        await CacheManagerService.clearAllCache();
        debugPrint('✅ Cache cleared');
      } catch (e) {
        debugPrint('❌ Cache clear error: $e');
      }

      debugPrint('✅ Logout process completed successfully');
    } catch (e) {
      debugPrint('❌ Logout process error: $e');
      // Continue logout even if errors occur
    } finally {
      // Always clear local state
      _currentUser = null;
      _token = null;
      _state = AuthState.unauthenticated;
      notifyListeners();

      debugPrint('✅ Local session cleared');
    }
  }

  /// Refresh current user data
  Future<void> refreshUser() async {
    try {
      debugPrint('🔄 Refreshing user data...');
      _currentUser = await _authRepository.getCurrentUser();
      notifyListeners();
      debugPrint('✅ User data refreshed');
    } catch (e) {
      debugPrint('❌ User refresh failed: $e');
      // Token might be invalid - logout
      _state = AuthState.unauthenticated;
      _currentUser = null;
      _token = null;
      await _authRepository.clearSession();
      notifyListeners();
    }
  }

  /// Change password with detailed error handling
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      _errorMessage = null;
      _errorType = null;

      debugPrint('🔐 Changing password...');

      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      debugPrint('✅ Password changed successfully');

      // Clear session after password change
      _currentUser = null;
      _token = null;
      _state = AuthState.unauthenticated;
      notifyListeners();

      return true;
    } on ApiException catch (e) {
      debugPrint('❌ Password change failed: ${e.message}');

      _errorType = e.errorType;

      // Berikan pesan error yang spesifik
      if (e.message.toLowerCase().contains('password lama') ||
          e.message.toLowerCase().contains('current password')) {
        _errorMessage = 'Password lama tidak sesuai. Silakan coba lagi.';
      } else if (e.message.toLowerCase().contains('konfirmasi')) {
        _errorMessage = 'Konfirmasi password tidak sama dengan password baru.';
      } else if (e.message.toLowerCase().contains('minimal')) {
        _errorMessage = 'Password baru minimal 6 karakter.';
      } else if (e.errorType == 'timeout') {
        _errorMessage = 'Koneksi timeout. Silakan coba lagi.';
      } else if (e.errorType == 'connection_error') {
        _errorMessage =
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      } else {
        _errorMessage = e.message;
      }

      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ Password change error: $e');
      _errorType = 'unknown';

      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        _errorMessage =
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      } else if (e.toString().contains('timeout')) {
        _errorMessage = 'Koneksi timeout. Silakan coba lagi.';
      } else {
        _errorMessage = 'Terjadi kesalahan tidak terduga. Silakan coba lagi.';
      }

      notifyListeners();
      return false;
    }
  }

  /// Check if token is still valid (periodic check)
  Future<bool> isTokenValid() async {
    if (_token == null) return false;

    try {
      await _authRepository.getCurrentUser();
      return true;
    } catch (e) {
      debugPrint('⚠️ Token validation failed: $e');
      return false;
    }
  }

  Future<String?> getRememberedUsername() async {
    return await _authRepository.getRememberedUsername();
  }

  Future<bool> shouldRemember() async {
    return await _authRepository.shouldRemember();
  }

  void clearError() {
    _errorMessage = null;
    _errorType = null;
    notifyListeners();
  }
}
