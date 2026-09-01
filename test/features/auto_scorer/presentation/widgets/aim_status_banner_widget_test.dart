import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/auto_scorer/domain/framing/recognition_state.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/aim_status_banner_widget.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/calibration_marker_diagram_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

RecognitionState _state(RecognitionGrade grade,
        {List<MarkerRecognition>? markers}) =>
    (
      markers: markers ??
          List.filled(4, grade == RecognitionGrade.none
              ? MarkerRecognition.missing
              : MarkerRecognition.found),
      grade: grade,
      foundCount: markers?.where((m) => m == MarkerRecognition.found).length ??
          (grade == RecognitionGrade.none ? 0 : 4),
    );

Future<BoxDecoration> _pump(
  WidgetTester tester,
  RecognitionState state, {
  String message = 'Ready to score.',
}) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: kSupportedLocales,
    home: Scaffold(
      body: AimStatusBanner(
        recognition: state,
        message: message,
        diagramSemanticsLabel: '2 of 4 board markers recognised',
      ),
    ),
  ));
  return tester
      .widget<Container>(find.byType(Container).first)
      .decoration! as BoxDecoration;
}

void main() {
  testWidgets('the block is opaque, whatever is behind the camera',
      (tester) async {
    // The whole point of the banner: the old white-on-camera text was legible
    // or not depending on the player's wall.
    for (final grade in RecognitionGrade.values) {
      final decoration = await _pump(tester, _state(grade));
      expect(decoration.color!.a, 1.0, reason: '$grade must be opaque');
    }
  });

  testWidgets('its colour carries the state, so no border has to',
      (tester) async {
    final colors = <Color>[
      for (final grade in RecognitionGrade.values)
        (await _pump(tester, _state(grade))).color!,
    ];
    expect(colors.toSet().length, RecognitionGrade.values.length);
  });

  testWidgets('it shows the message and the board diagram together',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      home: Scaffold(
        body: AimStatusBanner(
          recognition: _state(RecognitionGrade.partial, markers: const [
            MarkerRecognition.found,
            MarkerRecognition.weak,
            MarkerRecognition.missing,
            MarkerRecognition.found,
          ]),
          message: 'Reframe so all four markers show.',
          diagramSemanticsLabel: '2 of 4 board markers recognised',
        ),
      ),
    ));

    expect(find.text('Reframe so all four markers show.'), findsOneWidget);
    // The diagram is the live one and it is handed the per-marker states: a
    // static drawing could not say which of the four is missing.
    final diagram =
        tester.widget<CalibrationMarkerDiagram>(find.byType(CalibrationMarkerDiagram));
    expect(diagram.markers, const [
      MarkerRecognition.found,
      MarkerRecognition.weak,
      MarkerRecognition.missing,
      MarkerRecognition.found,
    ]);
    expect(find.bySemanticsLabel('2 of 4 board markers recognised'),
        findsOneWidget);
  });

  testWidgets('a long message wraps instead of overflowing', (tester) async {
    await _pump(tester, _state(RecognitionGrade.partial),
        message: 'Reframe so all four markers show. '
            'Any board rotation is fine, and the camera can sit anywhere.');
    expect(tester.takeException(), isNull);
  });

  test('the theme tokens behind the grades stay distinct', () {
    // Guards the premise of the colour test above: red / amber / green come
    // from three different tokens, not from one with opacity.
    expect(AppTheme.award, isNot(AppTheme.success));
  });

  testWidgets('without a message it is the board alone (#743 coexistence)',
      (tester) async {
    // While the escalation panel carries the words, the banner keeps showing
    // the live board above it: that is exactly when the player is nudging the
    // camera and wants to watch the markers arrive one by one.
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      home: Scaffold(
        body: AimStatusBanner(
          recognition: _state(RecognitionGrade.partial),
          message: null,
          diagramSemanticsLabel: '2 of 4 board markers recognised',
        ),
      ),
    ));

    expect(find.byType(CalibrationMarkerDiagram), findsOneWidget);
    expect(find.byType(Text), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
