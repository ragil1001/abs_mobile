// lib/data/repositories/auth_repository.dart
import 'dart:io';
import '../models/karyawan_model.dart';
import '../models/auth_response_model.dart';
import '../services/dio_service.dart';
import '../services/storage_service.dart';
import '../../core/config/app_config.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  final DioService _dioService = DioService();
  final StorageService _storageService = StorageService();

  /// Login karyawan - Creates unlimited session
  Future<AuthResponse> login(String username, String password) async {
    try {
      debugPrint('🌐 Sending login request...');

      final response = await _dioService.post(AppConfig.loginEndpoint, {
        'username': username,
        'password': password,
      });

      debugPrint('📥 Login response received: $response');

      // Cek apakah response null
      if (response == null) {
        throw ApiException(
          'Server tidak memberikan response',
          null,
          'server_error',
        );
      }

      // Cek success flag
      if (response['success'] != true) {
        final message = response['message'] ?? 'Login gagal';
        debugPrint('❌ Login failed: $message');

        // Tentukan error type berdasarkan message
        String errorType = 'validation';
        if (message.toLowerCase().contains('tidak aktif')) {
          errorType = 'account_inactive';
        }

        throw ApiException(message, 422, errorType);
      }

      // Cek data
      final data = response['data'];
      if (data == null) {
        throw ApiException('Data response kosong', null, 'server_error');
      }

      if (data is! Map<String, dynamic>) {
        throw ApiException(
          'Format data response tidak valid',
          null,
          'server_error',
        );
      }

      // Cek karyawan data
      if (data['karyawan'] == null) {
        throw ApiException(
          'Data karyawan tidak ditemukan',
          null,
          'server_error',
        );
      }

      if (data['karyawan'] is! Map<String, dynamic>) {
        throw ApiException(
          'Format data karyawan tidak valid',
          null,
          'server_error',
        );
      }

      // Parse response
      final authResponse = AuthResponse.fromJson(data);

      // Save token to local storage
      await _storageService.saveToken(authResponse.token);

      debugPrint('✅ Login response processed successfully');
      debugPrint('   Token saved to storage');

      return authResponse;
    } on ApiException {
      // Re-throw ApiException as is
      rethrow;
    } catch (e) {
      debugPrint('❌ Unexpected login error: $e');
      throw ApiException(
        'Terjadi kesalahan tidak terduga: ${e.toString()}',
        null,
        'unknown',
      );
    }
  }

  /// Get current user profile
  Future<Karyawan> getCurrentUser() async {
    try {
      debugPrint('🌐 Fetching current user profile...');

      final response = await _dioService.get(AppConfig.meEndpoint);

      if (response['success'] == true) {
        if (response['data'] == null) {
          throw ApiException('Data profil tidak ditemukan', null, 'not_found');
        }

        if (response['data'] is! Map<String, dynamic>) {
          throw ApiException(
            'Format data profil tidak valid',
            null,
            'server_error',
          );
        }

        debugPrint('✅ User profile fetched successfully');
        return Karyawan.fromJson(response['data']);
      } else {
        throw ApiException(
          response['message'] ?? 'Gagal mengambil data profil',
          null,
          'server_error',
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('❌ Get user error: $e');
      throw ApiException(
        'Gagal mengambil data profil: ${e.toString()}',
        null,
        'unknown',
      );
    }
  }

  /// Logout - Backend deletes FCM tokens
  Future<void> logout() async {
    try {
      debugPrint('🌐 Calling logout API endpoint (WITH TOKEN)...');

      // Call API FIRST (while token still exists)
      await _dioService
          .post(AppConfig.logoutEndpoint, {})
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⚠️ Logout API timeout - continuing anyway');
              return {'success': false, 'message': 'Timeout'};
            },
          );

      debugPrint('✅ Logout API call completed');
      debugPrint('   FCM tokens deleted by backend');
    } catch (e) {
      debugPrint('❌ Logout API error: $e');
      // Continue even if API fails - user wants to logout
    } finally {
      // Delete local token AFTER API call
      try {
        await _storageService.deleteToken();
        debugPrint('✅ Local token deleted');
      } catch (e) {
        debugPrint('❌ Error deleting local token: $e');
      }
    }
  }

  /// Clear local session (for token invalidation)
  Future<void> clearSession() async {
    try {
      await _storageService.deleteToken();
      debugPrint('✅ Local session cleared');
    } catch (e) {
      debugPrint('❌ Error clearing session: $e');
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      debugPrint('🌐 Sending change password request...');

      final response = await _dioService
          .post(AppConfig.changePasswordEndpoint, {
            'current_password': currentPassword,
            'new_password': newPassword,
            'new_password_confirmation': confirmPassword,
          });

      if (response['success'] != true) {
        final message = response['message'] ?? 'Gagal mengubah password';
        throw ApiException(message, 422, 'validation');
      }

      debugPrint('✅ Password changed successfully');

      // Clear token after password change
      await _storageService.deleteToken();
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('❌ Change password error: $e');
      throw ApiException(
        'Gagal mengubah password: ${e.toString()}',
        null,
        'unknown',
      );
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _storageService.getToken();
    final hasToken = token != null && token.isNotEmpty;

    debugPrint(
      '🔍 Checking login status: ${hasToken ? "Logged in" : "Not logged in"}',
    );

    return hasToken;
  }

  /// Save remember me preference
  Future<void> saveRememberMe(String username, bool remember) async {
    await _storageService.saveRememberMe(username, remember);
  }

  /// Get remembered username
  Future<String?> getRememberedUsername() async {
    return await _storageService.getRememberedUsername();
  }

  /// Check if should remember
  Future<bool> shouldRemember() async {
    return await _storageService.shouldRemember();
  }

  /// Store FCM token to backend
  Future<void> storeFcmToken(String fcmToken) async {
    try {
      String deviceType = 'android';
      String deviceName = '';

      if (Platform.isIOS) {
        deviceType = 'ios';
        deviceName = 'iOS Device';
      } else if (Platform.isAndroid) {
        deviceType = 'android';
        deviceName = 'Android Device';
      }

      debugPrint('📤 Storing FCM token to backend...');
      debugPrint('   Token: ${fcmToken.substring(0, 30)}...');
      debugPrint('   Device: $deviceType');

      final response = await _dioService.post(AppConfig.storeFcmTokenEndpoint, {
        'token': fcmToken,
        'device_type': deviceType,
        'device_name': deviceName,
      });

      if (response['success'] != true) {
        throw ApiException(
          response['message'] ?? 'Gagal menyimpan FCM token',
          null,
          'server_error',
        );
      }

      debugPrint('✅ FCM token stored successfully in backend');
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('❌ Store FCM token error: $e');
      throw ApiException(
        'Gagal menyimpan FCM token: ${e.toString()}',
        null,
        'unknown',
      );
    }
  }
}
