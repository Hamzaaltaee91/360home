import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Client-side image resizing and compression applied before upload.
///
/// Uploading full-resolution photos from modern phone cameras is wasteful:
/// a single image can exceed several megabytes, which slows uploads and
/// inflates storage costs. [ImageCompressor] downscales images to a
/// reasonable maximum dimension and re-encodes them as JPEG at a moderate
/// quality, dramatically reducing payload size while keeping them visually
/// acceptable for property listings.
///
/// Compression is best-effort: if the platform does not support it (for
/// example Flutter Web) or the operation fails, the original bytes are
/// returned unchanged so uploads never break.
class ImageCompressor {
  const ImageCompressor._();

  /// Longest edge, in pixels, that a compressed image may have.
  static const int defaultMaxDimension = 1600;

  /// JPEG quality (0-100) used when re-encoding.
  static const int defaultQuality = 80;

  /// Compresses [bytes], returning the smaller of the original and the
  /// compressed result.
  ///
  /// [maxDimension] caps the longest edge; [quality] controls JPEG quality.
  /// Returns the original bytes when compression is unsupported or fails.
  static Future<Uint8List> compress(
    Uint8List bytes, {
    int maxDimension = defaultMaxDimension,
    int quality = defaultQuality,
  }) async {
    if (bytes.isEmpty) return bytes;

    // flutter_image_compress has no web implementation; skip there.
    if (kIsWeb) return bytes;

    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: maxDimension,
        minHeight: maxDimension,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      final compressed = Uint8List.fromList(result);
      // Guard against pathological cases where compression grows the file.
      return compressed.length < bytes.length ? compressed : bytes;
    } catch (_) {
      return bytes;
    }
  }
}
