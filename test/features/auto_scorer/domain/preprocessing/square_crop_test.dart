import 'package:dart_lodge/features/auto_scorer/domain/preprocessing/square_crop.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors the probe's `s=min(h,w); y0=(h-s)//2; x0=(w-s)//2` exactly (#378 §2).
void main() {
  test('landscape crops the width, centered', () {
    final c = SquareCrop.center(1200, 800);
    expect(c.size, 800);
    expect(c.x0, 200); // (1200-800)//2
    expect(c.y0, 0);
  });

  test('portrait crops the height, centered', () {
    final c = SquareCrop.center(720, 1280);
    expect(c.size, 720);
    expect(c.x0, 0);
    expect(c.y0, 280); // (1280-720)//2
  });

  test('square is identity', () {
    final c = SquareCrop.center(800, 800);
    expect(c.size, 800);
    expect(c.x0, 0);
    expect(c.y0, 0);
  });

  test('odd offset floors (integer division, matching Python //)', () {
    final c = SquareCrop.center(1001, 800);
    expect(c.size, 800);
    expect(c.x0, 100); // (1001-800)//2 = 100 (floor of 100.5)
  });
}
