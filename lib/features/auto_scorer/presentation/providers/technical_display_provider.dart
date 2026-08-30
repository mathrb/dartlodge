import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'technical_display_provider.g.dart';

const _kTechnicalDisplayKey = 'auto_scorer_technical_display';

/// The "Technical display" opt-in (#738 / design S1.3). When on, the YOLO plugin
/// paints its own detection boxes on the camera preview, labelled with the raw
/// class name and confidence (`cal1 82.4`, `dart 91.3`). That is debugging
/// output: a player aiming at their board reads machine-learning internals on
/// top of the picture, so the default is **off** and the plain preview is what
/// ships.
///
/// Accepted trade-off recorded in the design: with the boxes hidden the player
/// loses the information of *where* the camera sees the markers. The halo and
/// pips (S1.1/S1.2) replace that signal in player language.
@Riverpod(keepAlive: true)
class AutoScorerTechnicalDisplay extends _$AutoScorerTechnicalDisplay {
  @override
  Future<bool> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getBool(_kTechnicalDisplayKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_kTechnicalDisplayKey, enabled);
    state = AsyncData(enabled);
  }
}
