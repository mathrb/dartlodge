/// The two renderings of [RecognitionState] (#739): a border halo around the
/// camera preview ([RecognitionHalo], [RecognitionHaloOverlay]) and a row of
/// four marker pips ([MarkerPips]).
library;

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/auto_scorer/domain/framing/recognition_state.dart';
import 'package:flutter/material.dart';

/// Halo thickness. Thick enough to read from throwing distance, thin enough not
/// to eat the ~140px band preview.
const double kRecognitionHaloWidth = 3.0;

/// Colour of the halo/pips for a grade. Red (nothing) → amber (getting there) →
/// green (good). Design tokens only: `error` from the scheme, `award` and
/// `success` from [AppTheme], so both themes stay accessible.
Color recognitionColor(BuildContext context, RecognitionGrade grade) {
  switch (grade) {
    case RecognitionGrade.none:
      return Theme.of(context).colorScheme.error;
    case RecognitionGrade.partial:
      return AppTheme.award(context);
    case RecognitionGrade.ready:
      return AppTheme.success(context);
  }
}

/// Slow enough that a marker flickering in and out of detection doesn't strobe
/// the border while the player is aiming.
const Duration _kHaloFade = Duration(milliseconds: 250);

BoxDecoration _haloDecoration(
        BuildContext context, RecognitionGrade grade, double radius) =>
    BoxDecoration(
      border: Border.all(
          color: recognitionColor(context, grade), width: kRecognitionHaloWidth),
      borderRadius: BorderRadius.circular(radius),
    );

/// Wraps [child] in a border whose colour grades the recognition state — for a
/// preview that is a box on the page (the in-game band and camera-first
/// layouts).
///
/// The halo is painted **around** the preview, never on top of it at a
/// detection coordinate: mapping detection space onto the YOLOView preview is
/// the geometric risk this design deliberately avoids, and it cannot be
/// validated without a device. The border carries the same "is it working?"
/// signal at no such risk, and it reads from the oche — which is what matters
/// once the preview collapses to a vignette during play (#480).
class RecognitionHalo extends StatelessWidget {
  const RecognitionHalo({
    super.key,
    required this.grade,
    required this.child,
    this.borderRadius = 8,
  });

  final RecognitionGrade grade;
  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: _kHaloFade,
        decoration: _haloDecoration(context, grade, borderRadius),
        child: ClipRRect(
          // Clip a hair inside the stroke so the child can't paint over it.
          borderRadius: BorderRadius.circular(borderRadius - 1),
          child: child,
        ),
      );
}

/// Border-only halo for a preview that fills its own surface (the fullscreen
/// aim view), stacked over it. Non-interactive: it must never intercept the
/// taps meant for the camera surface underneath.
class RecognitionHaloOverlay extends StatelessWidget {
  const RecognitionHaloOverlay(
      {super.key, required this.grade, this.borderRadius = 0});

  final RecognitionGrade grade;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedContainer(
          duration: _kHaloFade,
          decoration: _haloDecoration(context, grade, borderRadius),
        ),
      );
}

/// Four pips, one per board marker, in DeepDarts order. Replaces the raw
/// "{found}/4 markers" count: which marker is missing is information the count
/// never carried.
class MarkerPips extends StatelessWidget {
  const MarkerPips({super.key, required this.markers, this.size = 12});

  final List<MarkerRecognition> markers;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final m in markers)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size / 4),
            child: _Pip(marker: m, size: size),
          ),
      ],
    );
  }
}

class _Pip extends StatelessWidget {
  const _Pip({required this.marker, required this.size});

  final MarkerRecognition marker;
  final double size;

  @override
  Widget build(BuildContext context) {
    // A pip's colour is its own marker's state, on the same red/amber/green
    // scale as the halo: missing is the "nothing" colour, weak the "getting
    // there" one, found the "good" one.
    final color = recognitionColor(
        context,
        switch (marker) {
          MarkerRecognition.missing => RecognitionGrade.none,
          MarkerRecognition.weak => RecognitionGrade.partial,
          MarkerRecognition.found => RecognitionGrade.ready,
        });
    // Filled when the marker counts; hollow otherwise — so the state survives
    // for a colour-blind player and in a glance-sized preview.
    final filled = marker == MarkerRecognition.found;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : Colors.transparent,
        border: Border.all(color: color, width: 2),
      ),
    );
  }
}
