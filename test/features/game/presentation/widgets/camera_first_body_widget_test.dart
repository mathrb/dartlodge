// #801 — the camera-first body shares a bounded height between the game
// content and the camera region: the content keeps its natural height and the
// camera gives way, down to a floor; below that the content scales down. It
// never scrolls (this reverses #769). The board pages cover it end to end; this
// covers the arithmetic directly, including the two branches a page cannot
// reach.

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

/// The painted rect, after any scaling — `getSize` reports the layout size,
/// which a scaled-down subtree does not change.
Rect paintedRect(WidgetTester tester, String key) =>
    tester.getRect(find.byKey(ValueKey(key)));

void main() {
  testWidgets('short content keeps its height and the camera takes the rest',
      (tester) async {
    // The #760 behaviour, unchanged: no dead zone between the two.
    await pump(tester, height: 500, contentHeight: 100);

    expect(heightOf(tester, 'content'), 100);
    expect(heightOf(tester, 'camera'), 400);
  });

  testWidgets('the camera gives way before the content does', (tester) async {
    // #801: the content no longer has a cap at body − 260. The camera shrinks
    // and the content renders whole, unscaled.
    await pump(tester, height: 500, contentHeight: 330);

    expect(paintedRect(tester, 'content').height, 330);
    expect(heightOf(tester, 'camera'), 170);
  });

  testWidgets(
      'content taller than its share scales down, never scrolls, camera keeps '
      'the floor', (tester) async {
    await pump(tester, height: 500, contentHeight: 900);

    expect(heightOf(tester, 'camera'), kMinCameraRegionHeight);
    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsNothing);
    // Whole and inside its half: scaled, not clipped.
    final content = paintedRect(tester, 'content');
    expect(content.top, greaterThanOrEqualTo(0));
    expect(content.bottom,
        lessThanOrEqualTo(500 - kMinCameraRegionHeight + 0.01));
    expect(content.height, lessThan(900));
  });

  testWidgets('on a body too short for the floor, the content still gets a share',
      (tester) async {
    // Honouring the floor outright here would scale the scores to a slit. The
    // fraction cap is what stops that.
    await pump(tester, height: 200, contentHeight: 900);

    expect(heightOf(tester, 'camera'), 200 * kMaxCameraRegionFraction);
    final content = paintedRect(tester, 'content');
    expect(content.height, greaterThan(0));
    expect(content.bottom,
        lessThanOrEqualTo(200 - 200 * kMaxCameraRegionFraction + 0.01));
  });

  testWidgets('a cramped body keeps the first content child, the hero, on top',
      (tester) async {
    // #769 anchored on the dart band and let the hero scroll off; #801 shows
    // every child, so the hero is fully visible at the top and the band is
    // fully visible above the camera.
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 400,
          child: CameraFirstBody(
            camera: SizedBox.expand(),
            content: [
              SizedBox(height: 300, child: Text('hero')),
              SizedBox(height: 100, child: Text('band')),
            ],
          ),
        ),
      ),
    ));

    const window = 400 - kMinCameraRegionHeight;
    final hero = tester.getRect(find.text('hero'));
    final band = tester.getRect(find.text('band'));
    expect(hero.top, closeTo(0, 0.01));
    expect(band.bottom, lessThanOrEqualTo(window + 0.01));
  });

  testWidgets('a tap on scaled content still reaches its target',
      (tester) async {
    // The band is the one part you touch (manual entry, correction); scaling
    // must not break hit-testing.
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 400,
          child: CameraFirstBody(
            camera: const SizedBox.expand(),
            content: [
              const SizedBox(height: 500),
              GestureDetector(
                key: const ValueKey('band'),
                onTap: () => taps++,
                child: const SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: ColoredBox(color: Color(0xFF00FF00))),
              ),
            ],
          ),
        ),
      ),
    ));

    await tester.tap(find.byKey(const ValueKey('band')));
    expect(taps, 1);
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
