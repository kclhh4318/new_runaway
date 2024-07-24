import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

class Base64ImageCache {  // 이름을 변경했다모
  static final Map<String, ui.Image> _cache = {};

  static Future<ui.Image> getImage(String base64String, int targetWidth, int targetHeight) async {
    if (_cache.containsKey(base64String)) {
      return _cache[base64String]!;
    }

    final strippedBase64 = base64String.replaceFirst(RegExp(r'data:image/[^;]+;base64,'), '');
    Uint8List bytes = base64Decode(strippedBase64);

    print('Decoded image bytes: ${bytes.length}');
    print('First 10 bytes: ${bytes.sublist(0, 10)}');

    final codec = await ui.instantiateImageCodec(bytes, targetWidth: targetWidth, targetHeight: targetHeight);
    final frame = await codec.getNextFrame();

    // 이미지의 픽셀 데이터 확인
    final byteData = await frame.image.toByteData();
    if (byteData != null) {
      final pixels = byteData.buffer.asUint8List();
      print('Resized image pixels: ${pixels.length}');
      print('First 10 pixels: ${pixels.sublist(0, 10)}');
    }

    _cache[base64String] = frame.image;
    return frame.image;
  }

  static void clearCache() {
    _cache.clear();
  }
}