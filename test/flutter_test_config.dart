import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// Auto-discovered by `flutter test`. Disables continuous animations
/// (e.g. `PulsingNextButtonWidget`) so `pumpAndSettle` doesn't hang on
/// indefinite repeats. Tests that need real animation timing can flip
/// `accessibilityFeaturesTestValue` back per-test.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final binding = TestWidgetsFlutterBinding.instance;
  binding.platformDispatcher.accessibilityFeaturesTestValue =
      const _DisableAnimations();
  await testMain();
}

class _DisableAnimations implements AccessibilityFeatures {
  const _DisableAnimations();
  @override
  bool get accessibleNavigation => false;
  @override
  bool get boldText => false;
  @override
  bool get disableAnimations => true;
  @override
  bool get highContrast => false;
  @override
  bool get invertColors => false;
  @override
  bool get onOffSwitchLabels => false;
  @override
  bool get reduceMotion => false;
  @override
  bool get supportsAnnounce => false;
  // Added in Flutter 3.44 — mirror the real "no accessibility flags" defaults
  // (animated images/videos auto-play; cursor non-deterministic). Only
  // disableAnimations deviates, which is this fake's whole purpose.
  @override
  bool get autoPlayAnimatedImages => true;
  @override
  bool get autoPlayVideos => true;
  @override
  bool get deterministicCursor => false;
}
