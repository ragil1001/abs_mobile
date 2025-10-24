// lib/data/services/dio_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/app_config.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorType;

  ApiException(this.message, [this.statusCode, this.errorType]);

  @override
  String toString() => message;
}

class DioService {
  static final DioService _instance = DioService._internal();
  factory DioService() => _instance;
  DioService._internal();

  late Dio _dio;
  final StorageService _storageService = StorageService();
  CacheOptions? _cacheOptions;

  Future<void> initialize() async {
    final cacheDir = await getTemporaryDirectory();
    final cacheStore = FileCacheStore(cacheDir.path);

    _cacheOptions = CacheOptions(
      store: cacheStore,
      policy: CachePolicy.request,
      hitCacheOnErrorExcept: [401, 403],
      maxStale: const Duration(days: 7),
      priority: CachePriority.normal,
      cipher: null,
      keyBuilder: CacheOptions.defaultCacheKeyBuilder,
      allowPostMethod: false,
    );

    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectionTimeout,
        receiveTimeout: AppConfig.connectionTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'FlutterApp',
        },
        // Anggap semua status code sebagai success, kita handle sendiri
        validateStatus: (status) => true,
      ),
    );

    _dio.interceptors.add(DioCacheInterceptor(options: _cacheOptions!));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Semua response akan masuk sini karena validateStatus: true
          // Kita handle error di _handleResponse
          return handler.next(response);
        },
        onError: (error, handler) {
          // Ini hanya untuk network error (timeout, connection error, dll)
          _handleDioError(error);
          return handler.next(error);
        },
      ),
    );
  }

  /// Handle response dengan error handling yang comprehensive
  dynamic _handleResponse(Response response, String endpoint) {
    final statusCode = response.statusCode ?? 500;

    debugPrint('📥 API Response from $endpoint:');
    debugPrint('   Status: $statusCode');
    debugPrint('   Body: ${response.data}');

    if (statusCode >= 200 && statusCode < 300) {
      if (response.data == null ||
          (response.data is String && response.data.isEmpty)) {
        return null;
      }
      return response.data;
    }

    // Handle errors dengan pesan spesifik
    String errorMessage = 'Terjadi kesalahan pada server';
    String errorType = 'server_error';

    try {
      if (response.data is Map) {
        final data = response.data as Map;

        // PRIORITAS 1: Cek Laravel validation errors
        if (data['errors'] != null && data['errors'] is Map) {
          final errors = data['errors'] as Map;
          if (errors.isNotEmpty) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              errorMessage = firstError[0];
            }
          }
          errorType = 'validation';
        }
        // PRIORITAS 2: Cek success = false
        else if (data['success'] == false && data['message'] != null) {
          errorMessage = data['message'];
        }
        // PRIORITAS 3: Cek message field
        else if (data['message'] != null) {
          errorMessage = data['message'];
        }
      } else if (response.data is String && response.data.isNotEmpty) {
        errorMessage = response.data;
      }

      // Tentukan tipe error berdasarkan status code
      if (statusCode == 401) {
        errorType = 'unauthorized';
        // Jika message kosong atau generic, set default message
        if (errorMessage == 'Terjadi kesalahan pada server' ||
            (!errorMessage.toLowerCase().contains('username') &&
                !errorMessage.toLowerCase().contains('password') &&
                !errorMessage.toLowerCase().contains('salah'))) {
          errorMessage = 'Sesi Anda telah berakhir. Silakan login kembali.';
        }
      } else if (statusCode == 403) {
        errorType = 'forbidden';
        if (errorMessage == 'Terjadi kesalahan pada server') {
          errorMessage = 'Anda tidak memiliki akses untuk melakukan aksi ini.';
        }
      } else if (statusCode == 404) {
        errorType = 'not_found';
        if (errorMessage == 'Terjadi kesalahan pada server') {
          errorMessage = 'Data tidak ditemukan.';
        }
      } else if (statusCode == 422) {
        errorType = 'validation';
        // errorMessage sudah diset dari validation errors atau message
      } else if (statusCode >= 500) {
        errorType = 'server_error';
        if (errorMessage == 'Terjadi kesalahan pada server') {
          errorMessage = 'Terjadi kesalahan pada server. Silakan coba lagi.';
        }
      }
    } catch (e) {
      debugPrint('❌ Error parsing response: $e');
      errorMessage = 'Terjadi kesalahan dalam memproses respons server.';
      errorType = 'parse_error';
    }

    throw ApiException(errorMessage, statusCode, errorType);
  }

  /// Handle Dio exceptions dengan pesan yang user-friendly dan spesifik
  void _handleDioError(DioException error) {
    String errorMessage = 'Terjadi kesalahan';
    String errorType = 'unknown';
    int? statusCode;

    debugPrint('❌ DIO Error Type: ${error.type}');
    debugPrint('❌ DIO Error Message: ${error.message}');

    if (error.response != null) {
      statusCode = error.response!.statusCode;
      final data = error.response!.data;

      debugPrint('❌ Response Status: $statusCode');
      debugPrint('❌ Response Data: $data');

      // Handle response dengan data
      if (data is Map) {
        // PRIORITAS 1: Cek validation errors dari Laravel
        if (data.containsKey('errors') && data['errors'] is Map) {
          final errors = data['errors'] as Map;
          if (errors.isNotEmpty) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              errorMessage = firstError[0];
            }
          }
        }
        // PRIORITAS 2: Cek message field
        else if (data.containsKey('message') && data['message'] != null) {
          errorMessage = data['message'];
        }
      } else if (data is String && data.isNotEmpty) {
        errorMessage = data;
      }

      // Set error type berdasarkan status code
      if (statusCode == 401) {
        errorType = 'unauthorized';
        if (!errorMessage.contains('Username') &&
            !errorMessage.contains('password') &&
            !errorMessage.contains('salah')) {
          errorMessage = 'Sesi Anda telah berakhir. Silakan login kembali.';
        }
      } else if (statusCode == 403) {
        errorType = 'forbidden';
        errorMessage = errorMessage.isEmpty
            ? 'Anda tidak memiliki akses untuk melakukan aksi ini.'
            : errorMessage;
      } else if (statusCode == 422) {
        errorType = 'validation';
        // Keep the validation error message from server
      } else if (statusCode! >= 500) {
        errorType = 'server_error';
        errorMessage =
            'Terjadi kesalahan pada server. Silakan coba lagi nanti.';
      }

      throw ApiException(errorMessage, statusCode, errorType);
    }

    // PRIORITAS 2: Tidak ada response, handle berdasarkan DioException type
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        errorMessage =
            'Koneksi timeout. Periksa koneksi internet Anda dan coba lagi.';
        errorType = 'timeout';
        break;

      case DioExceptionType.sendTimeout:
        errorMessage =
            'Waktu pengiriman data habis. Periksa koneksi internet Anda.';
        errorType = 'timeout';
        break;

      case DioExceptionType.receiveTimeout:
        errorMessage =
            'Waktu menerima data habis. Periksa koneksi internet Anda.';
        errorType = 'timeout';
        break;

      case DioExceptionType.badCertificate:
        errorMessage =
            'Sertifikat keamanan tidak valid. Hubungi administrator.';
        errorType = 'certificate_error';
        break;

      case DioExceptionType.cancel:
        errorMessage = 'Permintaan dibatalkan.';
        errorType = 'cancelled';
        break;

      case DioExceptionType.connectionError:
        if (error.error is SocketException) {
          errorMessage =
              'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
        } else {
          errorMessage =
              'Gagal terhubung ke server. Periksa koneksi internet Anda.';
        }
        errorType = 'connection_error';
        break;

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          final socketException = error.error as SocketException;
          if (socketException.osError?.errorCode == 7) {
            errorMessage =
                'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
          } else if (socketException.osError?.errorCode == 111) {
            errorMessage = 'Server tidak merespons. Silakan coba lagi nanti.';
          } else {
            errorMessage =
                'Gagal terhubung ke server. Periksa koneksi internet Anda.';
          }
          errorType = 'connection_error';
        } else if (error.error is HandshakeException) {
          errorMessage =
              'Gagal membuat koneksi aman. Periksa pengaturan jaringan Anda.';
          errorType = 'ssl_error';
        } else if (error.error is HttpException) {
          errorMessage = 'Terjadi kesalahan HTTP. Silakan coba lagi.';
          errorType = 'http_error';
        } else {
          errorMessage = 'Terjadi kesalahan tidak terduga. Silakan coba lagi.';
          errorType = 'unknown';
        }
        break;

      default:
        errorMessage = 'Terjadi kesalahan tidak terduga: ${error.message}';
        errorType = 'unknown';
    }

    throw ApiException(errorMessage, statusCode, errorType);
  }

  // GET with cache
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool forceRefresh = false,
  }) async {
    try {
      debugPrint('📤 GET Request to: ${AppConfig.baseUrl}$endpoint');
      if (queryParameters != null) {
        debugPrint('   Query Parameters: $queryParameters');
      }

      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: forceRefresh
            ? _cacheOptions!.copyWith(policy: CachePolicy.refresh).toOptions()
            : null,
      );

      return _handleResponse(response, endpoint);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Terjadi kesalahan tidak terduga: ${e.toString()}',
        null,
        'unknown',
      );
    }
  }

  // POST (no cache)
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      debugPrint('📤 POST Request to: ${AppConfig.baseUrl}$endpoint');
      debugPrint('   Body: $data');

      final response = await _dio.post(endpoint, data: data);
      return _handleResponse(response, endpoint);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Terjadi kesalahan tidak terduga: ${e.toString()}',
        null,
        'unknown',
      );
    }
  }

  // PUT (no cache)
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      debugPrint('📤 PUT Request to: ${AppConfig.baseUrl}$endpoint');
      debugPrint('   Body: $data');

      final response = await _dio.put(endpoint, data: data);
      return _handleResponse(response, endpoint);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Terjadi kesalahan tidak terduga: ${e.toString()}',
        null,
        'unknown',
      );
    }
  }

  // DELETE (no cache)
  Future<dynamic> delete(String endpoint, {Map<String, dynamic>? data}) async {
    try {
      // IMPORTANT: Check if token exists before making request
      final token = await _storageService.getToken();

      if (token == null || token.isEmpty) {
        debugPrint('❌ No token found for DELETE request');
        throw ApiException(
          'Sesi Anda telah berakhir. Silakan login kembali.',
          401,
          'unauthorized',
        );
      }

      debugPrint('📤 DELETE Request to: ${AppConfig.baseUrl}$endpoint');
      debugPrint('🔑 Token: ${token.substring(0, 30)}...');

      if (data != null && data.isNotEmpty) {
        debugPrint('   Body: $data');
      }

      final response = await _dio.delete(endpoint, data: data);
      return _handleResponse(response, endpoint);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Terjadi kesalahan tidak terduga: ${e.toString()}',
        null,
        'unknown',
      );
    }
  }

  /// Clear all cache
  Future<void> clearCache() async {
    try {
      await _cacheOptions?.store?.clean();
      debugPrint('✅ Cache cleared successfully');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }

  /// Clear old cache (>7 days)
  Future<void> clearOldCache() async {
    try {
      await _cacheOptions?.store?.clean(staleOnly: true);
      debugPrint('✅ Old cache cleared successfully');
    } catch (e) {
      debugPrint('❌ Error clearing old cache: $e');
    }
  }
}
