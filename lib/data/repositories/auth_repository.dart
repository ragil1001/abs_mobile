import '../models/karyawan_model.dart';
import '../models/auth_response_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../../core/config/app_config.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  /// Login karyawan
  Future<AuthResponse> login(String username, String password) async {
    try {
      final response = await _apiService.post(AppConfig.loginEndpoint, {
        'username': username,
        'password': password,
      });

      print('=== LOGIN DEBUG ===');
      print('Full response: $response');
      print('Response type: ${response.runtimeType}');
      print('Success: ${response['success']}');
      print('Data: ${response['data']}');
      print('Data type: ${response['data']?.runtimeType}');

      if (response['success'] == true) {
        final data = response['data'];

        if (data == null) {
          throw ApiException('Data response kosong');
        }

        // Validate data is a Map
        if (data is! Map<String, dynamic>) {
          print('ERROR: Data is not a Map, it is: ${data.runtimeType}');
          throw ApiException('Format data response tidak valid');
        }

        print('Token: ${data['token']}');
        print('Karyawan data: ${data['karyawan']}');
        print('Karyawan type: ${data['karyawan']?.runtimeType}');

        // Validate karyawan data exists and is a Map
        if (data['karyawan'] == null) {
          throw ApiException('Data karyawan tidak ditemukan');
        }

        if (data['karyawan'] is! Map<String, dynamic>) {
          print(
            'ERROR: Karyawan is not a Map, it is: ${data['karyawan'].runtimeType}',
          );
          throw ApiException('Format data karyawan tidak valid');
        }

        final authResponse = AuthResponse.fromJson(data);

        // Save token to local storage
        await _storageService.saveToken(authResponse.token);

        print('Login successful!');
        return authResponse;
      } else {
        throw ApiException(response['message'] ?? 'Login gagal');
      }
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      print('=== LOGIN ERROR ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      throw ApiException('Terjadi kesalahan saat login: ${e.toString()}');
    }
  }

  /// Get current user profile
  Future<Karyawan> getCurrentUser() async {
    try {
      final response = await _apiService.get(AppConfig.meEndpoint);

      print('=== GET CURRENT USER DEBUG ===');
      print('Response: $response');

      if (response['success'] == true) {
        if (response['data'] == null) {
          throw ApiException('Data profil tidak ditemukan');
        }

        if (response['data'] is! Map<String, dynamic>) {
          throw ApiException('Format data profil tidak valid');
        }

        return Karyawan.fromJson(response['data']);
      } else {
        throw ApiException(
          response['message'] ?? 'Gagal mengambil data profil',
        );
      }
    } catch (e) {
      print('Get current user error: $e');
      rethrow;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      // Delete token first for instant logout feel
      await _storageService.deleteToken();

      // Then try to invalidate token on server (with timeout)
      await _apiService
          .post(AppConfig.logoutEndpoint, {})
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              // If server doesn't respond in 3 seconds, just continue
              print('Logout API timeout - continuing anyway');
              return {'success': true};
            },
          );
    } catch (e) {
      // Even if API call fails, token is already deleted locally
      print('Logout error: $e');
      // Don't rethrow - logout should always succeed locally
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _apiService
          .post(AppConfig.changePasswordEndpoint, {
            'current_password': currentPassword,
            'new_password': newPassword,
            'new_password_confirmation': confirmPassword,
          });

      if (response['success'] != true) {
        throw ApiException(response['message'] ?? 'Gagal mengubah password');
      }

      // Clear token after password change
      await _storageService.deleteToken();
    } catch (e) {
      rethrow;
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _storageService.getToken();
    return token != null && token.isNotEmpty;
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
}
