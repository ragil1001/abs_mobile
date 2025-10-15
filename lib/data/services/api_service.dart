import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  final StorageService _storageService = StorageService();

  // Get headers with authentication
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Requested-With': 'FlutterApp',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Handle API response
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    }

    // Handle errors
    String errorMessage = 'Terjadi kesalahan';

    try {
      final errorData = json.decode(response.body);
      errorMessage = errorData['message'] ?? errorMessage;
    } catch (e) {
      // If response is not JSON
      errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
    }

    throw ApiException(errorMessage, statusCode);
  }

  // GET request
  Future<dynamic> get(String endpoint) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
      final headers = await _getHeaders();

      final response = await http
          .get(url, headers: headers)
          .timeout(AppConfig.connectionTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on TimeoutException {
      throw ApiException('Koneksi timeout. Silakan coba lagi.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan: ${e.toString()}');
    }
  }

  // POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
      final headers = await _getHeaders();

      final response = await http
          .post(url, headers: headers, body: json.encode(data))
          .timeout(AppConfig.connectionTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on TimeoutException {
      throw ApiException('Koneksi timeout. Silakan coba lagi.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan: ${e.toString()}');
    }
  }

  // PUT request
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
      final headers = await _getHeaders();

      final response = await http
          .put(url, headers: headers, body: json.encode(data))
          .timeout(AppConfig.connectionTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on TimeoutException {
      throw ApiException('Koneksi timeout. Silakan coba lagi.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan: ${e.toString()}');
    }
  }

  // DELETE request (dengan optional body untuk FCM token)
  Future<dynamic> delete(String endpoint, {Map<String, dynamic>? data}) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
      final headers = await _getHeaders();

      http.Response response;

      if (data != null && data.isNotEmpty) {
        // DELETE dengan body (untuk FCM token)
        response = await http
            .delete(url, headers: headers, body: json.encode(data))
            .timeout(AppConfig.connectionTimeout);
      } else {
        // DELETE tanpa body (normal)
        response = await http
            .delete(url, headers: headers)
            .timeout(AppConfig.connectionTimeout);
      }

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on TimeoutException {
      throw ApiException('Koneksi timeout. Silakan coba lagi.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan: ${e.toString()}');
    }
  }
}
