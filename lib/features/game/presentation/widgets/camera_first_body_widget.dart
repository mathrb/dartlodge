import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The height below which the in-game camera region stops teaching the player
/// anything (#769).
///
/// Derived from what the region has to let you check, and from what the region
/// actually contains — measured, not estimated. In the ordinary running state
/// the camera bar takes 48dp, the hint line under it 16dp and the region's own
/// padding 12dp, so 260dp leaves the image 180dp. Letterboxed into a
/// phone-width region that renders the board roughly 110dp across, the size
/// #478 already settles on as readable at the oche. Below that the board is a
/// smudge and a dart in it is invisible, which is the state #769 was filed
/// about (73dp on a small screen, 0 with a large font).
///
/// The image is what gives way in the states that stack more chrome: the lost
/// calibration alert puts re-aim on its own row (#771), and a 150% system font
/// grows every row, together taking 164dp of this floor rather than 76dp. A
/// floor tall enough to keep 180dp of image even there would be about 400dp,
/// which on a 640dp screen is the whole board. The region cannot solve that
/// from the outside; shrinking the chrome is the auto-scorer's own business.
///
/// Hiding the preview instead is not an option: the preview IS the detector, so
/// removing it stops auto-scoring (epic #766).
const double kMinCameraRegionHeight = 260;

/// The most of the body the camera region may claim when the floor above cannot
/// be met outright.
///
/// Honouring [kMinCameraRegionHeight] on the smallest screen at the largest
/// font would leave the scores and the dart band a window too small to scroll
/// usefully. The game content keeps at least this much of the body in return —
/// the camera still gets far more than the 0-73dp it gets today, and both
/// halves stay usable.
const double kMaxCameraRegionFraction = 0.6;

/// The camera-first body of a board screen: the game content, then the camera
/// region (#769).
///
/// The four board screens shared one layout — content at its natural height,
/// camera in whatever was left — which had no floor under the camera and no
/// answer when the content alone outgrew the screen. Measured before the fix,
/// an X01 game at 320x568 with the system font at 150% overflowed by 51px and
/// gave the camera nothing at all.
///
/// So the two sides swap roles when space runs short: the camera region is
/// guaranteed [kMinCameraRegionHeight] (capped by [kMaxCameraRegionFraction]),
/// and the game content, which until now could only overflow, scrolls instead.
/// When there is room to spare nothing changes: the content sits at its natural
/// height and the camera takes all the rest, with no dead zone between them
/// (#760).
class CameraFirstBody extends StatelessWidget {
  const CameraFirstBody({
    super.key,
    required this.content,
    required this.camera,
  });

  /// The scores, banners and dart band, in order. Laid out at their natural
  /// height while they fit, scrollable once they do not.
  final List<Widget> content;

  /// The camera region — the preview and its bar. Never hidden, never shorter
  /// than the floor above.
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
            // below gets everything it leaves. The cap is what turns "the
            // content overflows" into "the content scrolls".
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: math.max(0, available - floor),
              ),
              child: SingleChildScrollView(
                // Anchored at the bottom, so what a cramped screen keeps in
                // view is the dart band: it is the only thing here you touch
                // (manual entry and correction), and it belongs next to the
                // camera it stands in for. The scores sit one flick up.
                // Inert when everything fits, since the scroll view is then
                // exactly as tall as its content.
                reverse: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: content,
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
