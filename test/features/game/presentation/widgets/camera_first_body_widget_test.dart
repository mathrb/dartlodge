// #769 — the camera-first body shares a bounded height between the game
// content and the camera region: the region keeps a floor, the content scrolls
// rather than overflowing. The board pages cover it end to end; this covers the
// arithmetic directly, including the two branches a page cannot reach.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/features/game/presentation/widgets/camera_first_body_widget.dart';

/// Hosts the body in a box of [height], with [contentHeight] worth of content.
Future<void> pump(
  WidgetTester tester, {
  required double height,
  required double contentHeight,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SizedBox(
        height: height,
        child: CameraFirstBody(
          camera: const ColoredBox(
            color: Color(0xFF000000),
            child: SizedBox.expand(key: ValueKey('camera')),
          ),
          content: [
            SizedBox(height: contentHeight, key: const ValueKey('content')),
          ],
        ),
      ),
    ),
  ));
}

double heightOf(WidgetTester tester, String key) =>
    tester.getSize(find.byKey(ValueKey(key))).height;

void main() {
  testWidgets('short content keeps its height and the camera takes the rest',
      (tester) async {
    // The #760 behaviour, unchanged: no dead zone between the two.
    await pump(tester, height: 500, contentHeight: 100);

    expect(heightOf(tester, 'content'), 100);
    expect(heightOf(tester, 'camera'), 400);
  });

  testWidgets('content taller than its share scrolls, camera keeps the floor',
      (tester) async {
    await pump(tester, height: 500, contentHeight: 900);

    expect(heightOf(tester, 'camera'), kMinCameraRegionHeight);
    // Not dropped, not overflowing: scrolled.
    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsOneWidget);
  });

  testWidgets('on a body too short for the floor, the content still gets a share',
      (tester) async {
    // Honouring the floor outright here would leave the scores a slit. The
    // fraction cap is what stops that.
    await pump(tester, height: 300, contentHeight: 900);

    expect(heightOf(tester, 'camera'), 300 * kMaxCameraRegionFraction);
    expect(heightOf(tester, 'content'), greaterThan(0));
  });

  testWidgets('what a cramped body keeps in view is the end of the content',
      (tester) async {
    // The dart band is last in every board's content list, and it is the half
    // that stays: it is the only part you touch.
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 400,
          child: CameraFirstBody(
            camera: SizedBox.expand(),
            content: [
              SizedBox(height: 500, child: Text('scores')),
              SizedBox(height: 100, child: Text('band')),
            ],
          ),
        ),
      ),
    ));

    // The cap binds at this height, so the content window is what it leaves.
    const window = 400 - 400 * kMaxCameraRegionFraction;
    final band = tester.getRect(find.text('band'));
    expect(band.bottom, closeTo(window, 0.01));
    expect(band.top, greaterThanOrEqualTo(0));
  });

  testWidgets('an unbounded host falls back to a plain column', (tester) async {
    // No height to share out, so there is no floor to compute: sizing off
    // infinity is what would throw.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CameraFirstBody(
            camera: const SizedBox(height: 120, key: ValueKey('camera')),
            content: const [
              SizedBox(height: 100, key: ValueKey('content')),
            ],
          ),
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
    expect(heightOf(tester, 'content'), 100);
    expect(heightOf(tester, 'camera'), 120);
  });
}
