import 'package:flutter/foundation.dart';
import '../data/models/karyawan_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/api_service.dart';
import '../data/services/storage_service.dart';
import '../data/services/firebase_messaging_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  final StorageService _storageService = StorageService();

  AuthState _state = AuthState.initial;
  Karyawan? _currentUser;
  String? _errorMessage;

  AuthState get state => _state;
  Karyawan? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  String? _token;

  // Add this getter
  String? get token => _token;

  /// Initialize auth state
  Future<void> initAuth() async {
    try {
      // Load token dari storage
      _token = await _storageService.getToken();

      final isLoggedIn = await _authRepository.isLoggedIn();

      if (isLoggedIn) {
        _state = AuthState.loading;
        notifyListeners();

        // Try to get current user
        try {
          _currentUser = await _authRepository.getCurrentUser();
          _state = AuthState.authenticated;
        } catch (e) {
          // Token might be expired
          _state = AuthState.unauthenticated;
          _currentUser = null;
          _token = null;
        }
      } else {
        _state = AuthState.unauthenticated;
        _token = null;
      }

      notifyListeners();
    } catch (e) {
      _state = AuthState.unauthenticated;
      _token = null;
      notifyListeners();
    }
  }

  /// Login
  Future<bool> login(
    String username,
    String password, {
    bool rememberMe = false,
  }) async {
    try {
      _state = AuthState.loading;
      _errorMessage = null;
      notifyListeners();

      final authResponse = await _authRepository.login(username, password);
      _currentUser = authResponse.karyawan;

      // Simpan token dari response
      _token = await _storageService.getToken();

      // Save remember me preference
      if (rememberMe) {
        await _authRepository.saveRememberMe(username, true);
      } else {
        await _authRepository.saveRememberMe('', false);
      }

      _state = AuthState.authenticated;
      notifyListeners();

      // Send FCM token ke backend setelah login berhasil
      await _sendFcmTokenToBackend();

      return true;
    } on ApiException catch (e) {
      _state = AuthState.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Send FCM token to backend
  Future<void> _sendFcmTokenToBackend() async {
    try {
      final fcmToken = await FirebaseMessagingService.getToken();
      if (fcmToken != null && _token != null) {
        await _authRepository.storeFcmToken(fcmToken);
        print('FCM token sent to backend successfully');
      }
    } catch (e) {
      print('Error sending FCM token to backend: $e');
      // Don't throw error, login should still succeed
    }
  }

  /// Logout - Optimized for instant UI feedback
  Future<void> logout() async {
    try {
      // Get FCM token sebelum logout
      final fcmToken = await FirebaseMessagingService.getToken();

      // Clear local state immediately for instant UI update
      _currentUser = null;
      _token = null;
      _state = AuthState.unauthenticated;
      notifyListeners();

      // Delete FCM token dari backend
      if (fcmToken != null) {
        try {
          await _authRepository.deleteFcmToken(fcmToken);
        } catch (e) {
          print('Error deleting FCM token from backend: $e');
        }
      }

      // Delete local FCM token
      try {
        await FirebaseMessagingService.deleteToken();
      } catch (e) {
        print('Error deleting local FCM token: $e');
      }

      // Then call API in background (won't block UI)
      await _authRepository.logout();
    } catch (e) {
      // Already cleared local state, so just log the error
      print('Logout error (already cleared locally): $e');
    }
  }

  /// Refresh current user data
  Future<void> refreshUser() async {
    try {
      _currentUser = await _authRepository.getCurrentUser();
      notifyListeners();
    } catch (e) {
      // If refresh fails, might need to re-login
      _state = AuthState.unauthenticated;
      _currentUser = null;
      _token = null;
      notifyListeners();
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      _errorMessage = null;

      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      // After password change, user needs to login again
      _currentUser = null;
      _token = null;
      _state = AuthState.unauthenticated;
      notifyListeners();

      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Get remembered username
  Future<String?> getRememberedUsername() async {
    return await _authRepository.getRememberedUsername();
  }

  /// Check if should remember
  Future<bool> shouldRemember() async {
    return await _authRepository.shouldRemember();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
