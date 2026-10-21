import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The height the in-game camera region keeps when the game content above it
/// needs the room (#801, down from #769's 260).
///
/// #801 settled which half gives way: the game content never scrolls, the
/// camera shrinks first. #769 had it the other way round, guaranteeing the
/// camera 260dp and scrolling the content, and with three players on an
/// ordinary phone that scrolled the current player's score off the top: the
/// one number a player at the oche reads and cannot scroll back to.
///
/// So the floor only has to keep the region honest, not readable at distance.
/// In the ordinary running state the camera bar takes 48dp, the hint line under
/// it 16dp and the region's own padding 12dp, so 140dp leaves the image about
/// 64dp: enough to see at a glance that the board is still framed, not enough
/// to read a dart in it. Darts are read on the band above.
///
/// Hiding the preview instead is not an option: the preview IS the detector, so
/// removing it stops auto-scoring (epic #766).
const double kMinCameraRegionHeight = 140;

/// The most of the body the camera region may claim when the floor above cannot
/// be met outright.
///
/// Honouring [kMinCameraRegionHeight] on the smallest screen at the largest
/// font would scale the scores and the dart band down past legibility. The
/// game content keeps at least this much of the body in return.
const double kMaxCameraRegionFraction = 0.5;

/// The camera-first body of a board screen: the game content, then the camera
/// region (#769, #801).
///
/// The game content is laid out at its natural height and the camera region
/// takes everything it leaves, with no dead zone between them (#760). When the
/// content grows (more players, a larger system font, a smaller screen) the
/// camera gives way, down to [kMinCameraRegionHeight] (capped by
/// [kMaxCameraRegionFraction]). Past that point the content is scaled down as a
/// whole to fit above the floor: smaller, but every child stays on screen.
/// It never scrolls, because the player reads it from the oche (#801).
class CameraFirstBody extends StatelessWidget {
  const CameraFirstBody({
    super.key,
    required this.content,
    required this.camera,
  });

  /// The scores, banners and dart band, in order. Laid out at their natural
  /// height while they fit, scaled down as one block once they do not.
  final List<Widget> content;

  /// The camera region: the preview and its bar. Never hidden, never shorter
  /// than [kMinCameraRegionHeight], or than [kMaxCameraRegionFraction] of the
  /// body when that is less.
  final Widget camera;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxHeight;
        // A finite height is what makes the floor meaningful; inside a scroll
        // view there is nothing to share out, so fall back to the old
        // natural-height column rather than sizing off infinity.
        if (!available.isFinite) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [...content, camera],
          );
        }
        final floor = math.min(
          kMinCameraRegionHeight,
          available * kMaxCameraRegionFraction,
        );
        return Column(
          children: [
            // A non-flex child, so it takes its natural height and the camera
            // below gets everything it leaves. The cap is what stops the
            // content from pushing the camera under its floor.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: math.max(0, available - floor),
              ),
              // A no-op at scale 1, i.e. whenever the content fits. Otherwise
              // the whole block shrinks uniformly, hero included, so nothing is
              // pushed off screen (#801).
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                // FittedBox lays its child out unconstrained; pinning the width
                // keeps the content laid out exactly as it is unscaled.
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: content,
                  ),
                ),
              ),
            ),
            Expanded(child: camera),
          ],
        );
      },
    );
  }
}
