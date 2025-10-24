// lib/data/services/image_compression_service.dart
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageCompressionService {
  /// Compress foto presensi dengan target size maksimal 500KB
  static Future<File> compressPresensiPhoto(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Kompress dengan quality 70% dan max width 1200px
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 800,
        minHeight: 600,
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        throw Exception('Kompresi gagal');
      }

      final compressedFile = File(result.path);
      final compressedSize = await compressedFile.length();

      // Jika masih >500KB, compress lagi dengan quality lebih rendah
      if (compressedSize > 500 * 1024) {
        final result2 = await FlutterImageCompress.compressAndGetFile(
          result.path,
          targetPath.replaceAll('.jpg', '_final.jpg'),
          quality: 50,
          minWidth: 800,
          minHeight: 600,
        );

        if (result2 != null) {
          // Delete intermediate file
          await compressedFile.delete();
          return File(result2.path);
        }
      }

      return compressedFile;
    } catch (e) {
      throw Exception('Error kompres foto: $e');
    }
  }

  /// Compress file dokumen (PDF/Image) untuk izin/lembur
  static Future<File> compressDocument(File file) async {
    final extension = path.extension(file.path).toLowerCase();

    // Jika PDF, tidak perlu compress
    if (extension == '.pdf') {
      final fileSize = await file.length();
      // Validasi ukuran maksimal 10MB
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Ukuran PDF maksimal 10MB');
      }
      return file;
    }

    // Jika image, compress
    if (['.jpg', '.jpeg', '.png'].contains(extension)) {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        'doc_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 85,
        format: CompressFormat.jpeg,
      );

      if (result == null) throw Exception('Kompresi dokumen gagal');
      return File(result.path);
    }

    return file;
  }

  /// Clear temporary compressed files
  static Future<void> clearTempFiles() async {
    try {
      final dir = await getTemporaryDirectory();
      final files = dir.listSync();

      for (var file in files) {
        if (file is File) {
          final name = path.basename(file.path);
          if (name.startsWith('compressed_') || name.startsWith('doc_')) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      // Ignore errors
    }
  }
}
