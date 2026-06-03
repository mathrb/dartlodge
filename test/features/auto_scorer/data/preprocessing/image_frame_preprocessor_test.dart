import 'dart:typed_data';

import 'package:dart_lodge/features/auto_scorer/data/preprocessing/image_frame_preprocessor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  const pre = ImageFramePreprocessor();

  test('output is always 800×800', () {
    for (final dims in const [[1200, 800], [720, 1280], [800, 800], [1001, 777]]) {
      final out = pre.preprocess(img.Image(width: dims[0], height: dims[1]));
      expect(out.width, 800);
      expect(out.height, 800);
    }
  });

  test('letterbox preserves edge content and pads with grey (no crop)', () {
    // 1200×800: centre 800-wide square red, the side strips blue. Letterbox
    // scales the whole frame to fit 800 wide (→ 800×533) and pads top/bottom —
    // so the blue side strips SURVIVE (a crop would have discarded them).
    final src = img.Image(width: 1200, height: 800);
    img.fill(src, color: img.ColorRgb8(0, 0, 255)); // all blue
    img.fillRect(src,
        x1: 200, y1: 0, x2: 999, y2: 799, color: img.ColorRgb8(255, 0, 0));
    final out = pre.preprocess(src);
    // Centre maps to the red square.
    final centre = out.getPixel(400, 400);
    expect(centre.r, greaterThan(200));
    // A left-edge column maps to the BLUE side strip — preserved, not cropped.
    final edge = out.getPixel(40, 400);
    expect(edge.b, greaterThan(200));
    expect(edge.r, lessThan(60));
    // Top rows are the grey (114) letterbox padding.
    final pad = out.getPixel(400, 10);
    expect(pad.r, closeTo(114, 8));
    expect(pad.g, closeTo(114, 8));
    expect(pad.b, closeTo(114, 8));
  });

  test('a uniform image stays uniform inside the scaled region', () {
    final src = img.Image(width: 1000, height: 600);
    img.fill(src, color: img.ColorRgb8(10, 200, 30));
    final out = pre.preprocess(src);
    // Centre is inside the scaled image (not the letterbox padding).
    final p = out.getPixel(400, 400);
    expect(p.r, closeTo(10, 3));
    expect(p.g, closeTo(200, 3));
    expect(p.b, closeTo(30, 3));
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
