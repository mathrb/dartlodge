import 'dart:typed_data';

import 'package:dart_lodge/features/auto_scorer/data/preprocessing/square_crop.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  group('squareCrop', () {
    test('landscape → centred square of the short (height) side', () {
      final src = img.Image(width: 200, height: 100);
      final out = squareCrop(src);
      expect(out.width, 100);
      expect(out.height, 100);
    });

    test('portrait → centred square of the short (width) side', () {
      final src = img.Image(width: 100, height: 240);
      final out = squareCrop(src);
      expect(out.width, 100);
      expect(out.height, 100);
    });

    test('already square → unchanged dimensions', () {
      final src = img.Image(width: 128, height: 128);
      final out = squareCrop(src);
      expect(out.width, 128);
      expect(out.height, 128);
    });

    test('crop is centred (samples the middle, not a corner)', () {
      // Left half red, right half blue on a 200×100 image: the centred 100×100
      // square spans x∈[50,150), so its own left edge (x=0 → src x=50) is red and
      // its right edge (x=99 → src x=149) is blue — proving a centred crop.
      final src = img.Image(width: 200, height: 100);
      final red = img.ColorRgb8(255, 0, 0);
      final blue = img.ColorRgb8(0, 0, 255);
      for (var y = 0; y < 100; y++) {
        for (var x = 0; x < 200; x++) {
          src.setPixel(x, y, x < 100 ? red : blue);
        }
      }
      final out = squareCrop(src);
      expect(out.getPixel(0, 50).b, 0); // left of crop is still in the red half
      expect(out.getPixel(99, 50).r, 0); // right of crop is in the blue half
    });

    test('squareCropEncoded returns decodable PNG bytes', () {
      final src = img.Image(width: 60, height: 40);
      final bytes = squareCropEncoded(img.encodeJpg(src));
      expect(bytes, isNotNull);
      final decoded = img.decodeImage(bytes!);
      expect(decoded, isNotNull);
      expect(decoded!.width, 40);
      expect(decoded.height, 40);
    });

    test('squareCropEncoded returns null on undecodable bytes', () {
      expect(squareCropEncoded(Uint8List.fromList([1, 2, 3])), isNull);
    });
  });
}
