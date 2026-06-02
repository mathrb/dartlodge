import 'dart:typed_data';

import 'package:dart_lodge/features/auto_scorer/data/preprocessing/frame_preprocessor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  const pre = FramePreprocessor();

  test('output is always 800×800', () {
    for (final dims in const [[1200, 800], [720, 1280], [800, 800], [1001, 777]]) {
      final out = pre.preprocess(img.Image(width: dims[0], height: dims[1]));
      expect(out.width, 800);
      expect(out.height, 800);
    }
  });

  test('center crop keeps the centre content (longer axis trimmed)', () {
    // 1200×800: paint the centre square red, the cropped-away side strips blue.
    final src = img.Image(width: 1200, height: 800);
    img.fill(src, color: img.ColorRgb8(0, 0, 255)); // all blue
    // centre 800-wide square is x in [200,1000)
    img.fillRect(src,
        x1: 200, y1: 0, x2: 999, y2: 799, color: img.ColorRgb8(255, 0, 0));
    final out = pre.preprocess(src);
    // After cropping the centre square and resizing, the whole image is red.
    final c = out.getPixel(400, 400);
    expect(c.r, greaterThan(200));
    expect(c.b, lessThan(60));
  });

  test('a uniform image stays uniform through crop+resize', () {
    final src = img.Image(width: 1000, height: 600);
    img.fill(src, color: img.ColorRgb8(10, 200, 30));
    final out = pre.preprocess(src);
    final p = out.getPixel(0, 0);
    expect(p.r, closeTo(10, 2));
    expect(p.g, closeTo(200, 2));
    expect(p.b, closeTo(30, 2));
  });

  test('preprocessEncoded decodes, processes, and re-encodes to PNG', () {
    final src = img.Image(width: 900, height: 500);
    img.fill(src, color: img.ColorRgb8(120, 120, 120));
    final pngIn = img.encodePng(src);

    final out = pre.preprocessEncoded(pngIn);
    expect(out, isNotNull);
    final decoded = img.decodeImage(out!)!;
    expect(decoded.width, 800);
    expect(decoded.height, 800);
  });

  test('preprocessEncoded returns null on undecodable bytes', () {
    expect(pre.preprocessEncoded(img.encodePng(img.Image(width: 1, height: 1))),
        isNotNull); // sanity: valid tiny png decodes
    expect(
        pre.preprocessEncoded(
            Uint8List.fromList(const [1, 2, 3, 4, 5])), // garbage
        isNull);
  });
}
