// Game Configuration - Typed Configuration Classes
// Sealed class hierarchy for game configuration as specified in REPOSITORY_INTERFACES.md

import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_config.freezed.dart';
part 'game_config.g.dart';

/// Base Game Configuration
@freezed
abstract class GameConfig with _$GameConfig {
  const factory GameConfig.x01({
    required int startingScore,
    required String inStrategy, // 'straight', 'double', 'master'
    required String outStrategy, // 'straight', 'double', 'master'
  }) = X01GameConfig;

  const factory GameConfig.cricket({
    required String variant, // 'standard', 'cut-throat', 'no-score'
    required List<String> numbers, // ['15', '16', '17', '18', '19', '20', 'bull']
    required int pointsToWin,
  }) = CricketGameConfig;

  const factory GameConfig.aroundTheClock() = AroundTheClockGameConfig;
  const factory GameConfig.killer() = KillerGameConfig;
  const factory GameConfig.baseball() = BaseballGameConfig;
  const factory GameConfig.golf() = GolfGameConfig;
  const factory GameConfig.shanghai() = ShanghaiGameConfig;
  const factory GameConfig.scram() = ScramGameConfig;
  const factory GameConfig.halveIt() = HalveItGameConfig;
  const factory GameConfig.highScore() = HighScoreGameConfig;
  const factory GameConfig.blindCricket() = BlindCricketGameConfig;
  const factory GameConfig.blindGolf() = BlindGolfGameConfig;
  const factory GameConfig.blindKiller() = BlindKillerGameConfig;
  const factory GameConfig.blindShanghai() = BlindShanghaiGameConfig;
  const factory GameConfig.chaseTheDragon() = ChaseTheDragonGameConfig;

  factory GameConfig.fromJson(Map<String, dynamic> json) => _$GameConfigFromJson(json);
}

/// Canonical Segment Representation
/// Standardized format for dart board segments as specified in AGENTS.md
@freezed
abstract class Segment with _$Segment {
  const factory Segment.single(int number) = SingleSegment;
  const factory Segment.doubleSegment(int number) = DoubleSegment;
  const factory Segment.triple(int number) = TripleSegment;
  const factory Segment.singleBull() = SingleBullSegment;
  const factory Segment.doubleBull() = DoubleBullSegment;
  const factory Segment.miss() = MissSegment;

  const Segment._();

  /// Parse segment from canonical string format
  /// Supported formats: '20', 'D20', 'T20', 'SB', 'DB', 'MISS'
  static Segment parse(String segmentString) {
    segmentString = segmentString.trim().toUpperCase();

    if (segmentString == 'SB') return const Segment.singleBull();
    if (segmentString == 'DB') return const Segment.doubleBull();
    if (segmentString == 'MISS') return const Segment.miss();

    // Parse regular segments
    if (segmentString.startsWith('T') && segmentString.length > 1) {
      final number = int.tryParse(segmentString.substring(1));
      if (number != null && number >= 1 && number <= 20) {
        return Segment.triple(number);
      }
    } else if (segmentString.startsWith('D') && segmentString.length > 1) {
      final number = int.tryParse(segmentString.substring(1));
      if (number != null && number >= 1 && number <= 20) {
        return Segment.doubleSegment(number);
      }
    } else {
      final number = int.tryParse(segmentString);
      if (number != null && number >= 1 && number <= 20) {
        return Segment.single(number);
      }
    }

    throw FormatException('Invalid segment format: $segmentString');
  }

  /// Convert to canonical string format
  String toCanonicalString() {
    return when(
      single: (number) => number.toString(),
      doubleSegment: (number) => 'D$number',
      triple: (number) => 'T$number',
      singleBull: () => 'SB',
      doubleBull: () => 'DB',
      miss: () => 'MISS',
    );
  }

  /// Calculate score value
  int get scoreValue {
    return when(
      single: (number) => number,
      doubleSegment: (number) => number * 2,
      triple: (number) => number * 3,
      singleBull: () => 25,
      doubleBull: () => 50,
      miss: () => 0,
    );
  }

  /// Get multiplier (1 for single, 2 for double, 3 for triple)
  int get multiplier {
    return when(
      single: (_) => 1,
      doubleSegment: (_) => 2,
      triple: (_) => 3,
      singleBull: () => 1,
      doubleBull: () => 2,
      miss: () => 1,
    );
  }

  /// Get base number (1-20 for regular segments, 25 for bull)
  int get baseNumber {
    return when(
      single: (number) => number,
      doubleSegment: (number) => number,
      triple: (number) => number,
      singleBull: () => 25,
      doubleBull: () => 25,
      miss: () => 0,
    );
  }
}