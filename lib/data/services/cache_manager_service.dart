// lib/data/services/cache_manager_service.dart
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dio_service.dart';
import 'image_compression_service.dart';

class CacheManagerService {
  /// Clear semua cache aplikasi
  static Future<void> clearAllCache() async {
    try {
      // 1. Clear DIO cache
      await DioService().clearCache();

      // 2. Clear temporary files
      await _clearTempDirectory();

      // 3. Clear image compression temp files
      await ImageCompressionService.clearTempFiles();

      print('✅ All cache cleared successfully');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Clear old cache (>7 days)
  static Future<void> clearOldCache() async {
    try {
      // 1. Clear old DIO cache
      await DioService().clearOldCache();

      // 2. Clear old temp files
      await _clearOldTempFiles();

      // 3. Clear image temp files
      await ImageCompressionService.clearTempFiles();

      print('✅ Old cache cleared successfully');
    } catch (e) {
      print('Error clearing old cache: $e');
    }
  }

  /// Get total cache size
  static Future<int> getCacheSize() async {
    int totalSize = 0;

    try {
      // Check temp directory
      final tempDir = await getTemporaryDirectory();
      totalSize += await _getDirectorySize(tempDir);

      // Check application support directory (DIO cache)
      final appDir = await getApplicationSupportDirectory();
      totalSize += await _getDirectorySize(appDir);
    } catch (e) {
      print('Error getting cache size: $e');
    }

    return totalSize;
  }

  /// Clear temp directory
  static Future<void> _clearTempDirectory() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
        tempDir.createSync();
      }
    } catch (e) {
      print('Error clearing temp directory: $e');
    }
  }

  /// Clear old temp files (>7 days)
  static Future<void> _clearOldTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final now = DateTime.now();

      final files = tempDir.listSync(recursive: true);
      for (var file in files) {
        if (file is File) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);

          if (age.inDays > 7) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      print('Error clearing old temp files: $e');
    }
  }

  /// Get directory size
  static Future<int> _getDirectorySize(Directory directory) async {
    int size = 0;

    try {
      if (directory.existsSync()) {
        final files = directory.listSync(recursive: true);
        for (var file in files) {
          if (file is File) {
            size += await file.length();
          }
        }
      }
    } catch (e) {
      print('Error getting directory size: $e');
    }

    return size;
  }

  /// Auto cleanup on app start
  static Future<void> autoCleanup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCleanup = prefs.getInt('last_cleanup') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Cleanup every 7 days
      if (now - lastCleanup > Duration(days: 7).inMilliseconds) {
        await clearOldCache();
        await prefs.setInt('last_cleanup', now);
        print('🧹 Auto cleanup completed');
      }
    } catch (e) {
      print('Error in auto cleanup: $e');
    }
  }
}
