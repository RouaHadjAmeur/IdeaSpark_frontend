import 'dart:convert';
import 'package:flutter/material.dart';

class ImageHelper {
  /// Resolves the correct [ImageProvider] from a given string [source].
  /// Source can be a URL or a base64-encoded string (data:image/...).
  static ImageProvider getImageProvider(String? source) {
    // 1x1 transparent PNG to avoid 'Asset not found' or 'No host specified' errors
    // while still satisfying non-nullable ImageProvider requirements in DecorationImage.
    final transparentImage = MemoryImage(base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='));

    if (source == null || source.isEmpty) {
      return transparentImage;
    }

    if (source.startsWith('data:image')) {
      try {
        final String base64Data = source.split(',').last;
        return MemoryImage(base64Decode(base64Data));
      } catch (e) {
        debugPrint('ImageHelper error: failed to decode base64 image - $e');
        return transparentImage;
      }
    }

    // Default assumes it's a URL
    return NetworkImage(source);
  }
}
