/// Fixtures for image attachment tests.
///
/// Provides test image data for InputBar and related widget tests.
/// Uses valid PNG bytes so Image.memory can render them.
library;

import 'dart:typed_data';

import 'package:fspec_mobile/features/session/presentation/widgets/input_bar.dart';

/// Test fixtures for AttachedImage
class ImageFixtures {
  /// Minimal valid 1x1 PNG image bytes
  /// This is a valid PNG that Flutter's Image.memory can render
  static Uint8List get validPngBytes => Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
        0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT chunk
        0x54, 0x08, 0xD7, 0x63, 0xF8, 0xFF, 0xFF, 0x3F,
        0x00, 0x05, 0xFE, 0x02, 0xFE, 0xDC, 0xCC, 0x59,
        0xE7, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, // IEND chunk
        0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);

  /// Create a test AttachedImage
  static AttachedImage screenshotImage({
    String name = 'screenshot.png',
    String mimeType = 'image/png',
  }) {
    return AttachedImage(
      name: name,
      mimeType: mimeType,
      bytes: validPngBytes,
    );
  }

  /// Create a test AttachedImage with JPEG type
  static AttachedImage photoImage({
    String name = 'photo.jpg',
  }) {
    // Use same bytes but claim JPEG - for testing mime type handling
    return AttachedImage(
      name: name,
      mimeType: 'image/jpeg',
      bytes: validPngBytes,
    );
  }

  /// Create multiple test images for batch testing
  static List<AttachedImage> multipleImages({int count = 3}) {
    return List.generate(count, (i) => AttachedImage(
      name: 'image_$i.png',
      mimeType: 'image/png',
      bytes: validPngBytes,
    ));
  }
}
