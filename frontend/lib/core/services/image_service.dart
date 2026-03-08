import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Service untuk pick & compress gambar sebelum upload.
/// Target: max 800KB per gambar, max 1920px lebar.
class ImageService {
  static final _picker = ImagePicker();

  /// Konfigurasi kompresi
  static const int maxWidth = 1920;
  static const int maxHeight = 1920;
  static const int quality = 75; // JPEG quality 75% — balance size vs clarity

  /// Pick single image dari gallery, langsung compress
  static Future<File?> pickAndCompress() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxHeight.toDouble(),
      imageQuality: quality,
    );
    if (picked == null) return null;
    return _compressFile(File(picked.path));
  }

  /// Pick multiple images dari gallery, compress semua
  static Future<List<File>> pickMultipleAndCompress({
    int maxImages = 20,
  }) async {
    final picked = await _picker.pickMultiImage(
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxHeight.toDouble(),
      imageQuality: quality,
      limit: maxImages,
    );
    if (picked.isEmpty) return [];

    final List<File> compressed = [];
    for (final xFile in picked) {
      final file = await _compressFile(File(xFile.path));
      if (file != null) compressed.add(file);
    }
    return compressed;
  }

  /// Compress file menggunakan flutter_image_compress
  static Future<File?> _compressFile(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = p.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: 400,
        minHeight: 400,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        return File(result.path);
      }
      return file; // Fallback ke file asli jika compress gagal
    } catch (e) {
      return file; // Fallback
    }
  }

  /// Format ukuran file untuk display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
