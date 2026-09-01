/// The in-game rendering of [RecognitionState] (#739): a border halo around the
/// camera preview ([RecognitionHalo]).
///
/// The aim view used to have two more — a halo laid over the fullscreen preview
/// and a row of four pips — and has neither now (#759): with the phone in hand
/// the border said nothing that could be read, and the pips said which marker
/// was missing without saying where it was. Both gave way to a board diagram
/// inside the status banner.
library;

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/auto_scorer/domain/framing/recognition_state.dart';
import 'package:flutter/material.dart';

/// Halo thickness. Thick enough to read from throwing distance, thin enough not
/// to eat the ~140px band preview.
const double kRecognitionHaloWidth = 3.0;

/// Colour of a recognition grade — the in-game halo, and the aim view's status
/// banner. Red (nothing) → amber (getting there) →
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

/// Colour of a halo whose grade may be null — "say nothing" (#758): the border
/// still frames the preview, in the ordinary chrome outline, so suppressing the
/// alarm never shifts the layout.
Color _haloColor(BuildContext context, RecognitionGrade? grade) =>
    grade == null
        ? Theme.of(context).colorScheme.outlineVariant
        : recognitionColor(context, grade);

BoxDecoration _haloDecoration(
        BuildContext context, RecognitionGrade? grade, double radius) =>
    BoxDecoration(
      border: Border.all(
          color: _haloColor(context, grade), width: kRecognitionHaloWidth),
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
/// during play, at whatever height the board leaves the preview (#760).
class RecognitionHalo extends StatelessWidget {
  const RecognitionHalo({
    super.key,
    required this.grade,
    required this.child,
    this.borderRadius = 8,
  });

  /// Null paints the neutral border instead of a grade colour — see
  /// [haloGradeOf], which is what decides it in game (#758).
  final RecognitionGrade? grade;
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
