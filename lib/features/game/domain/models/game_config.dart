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
    @Default(1) int legsToWin,
    @Default(null) String? startingPlayerId,
  }) = X01GameConfig;

  const factory GameConfig.cricket({
    required String variant, // 'standard', 'cut-throat', 'no-score'
    required List<String> numbers, // ['15', '16', '17', '18', '19', '20', 'bull']
    required int pointsToWin,
    @Default(null) String? startingPlayerId,
  }) = CricketGameConfig;

  const factory GameConfig.aroundTheClock({
    @Default('standard') String variant, // 'standard', 'reverse', 'doublesOnly'
    @Default(null) String? startingPlayerId,
  }) = AroundTheClockGameConfig;
  const factory GameConfig.killer({
    @Default(null) String? startingPlayerId,
  }) = KillerGameConfig;
  const factory GameConfig.baseball({
    @Default(null) String? startingPlayerId,
  }) = BaseballGameConfig;
  const factory GameConfig.golf({
    @Default(null) String? startingPlayerId,
  }) = GolfGameConfig;
  const factory GameConfig.shanghai({
    @Default(7) int totalRounds,
    @Default(null) String? startingPlayerId,
  }) = ShanghaiGameConfig;
  const factory GameConfig.scram({
    @Default(null) String? startingPlayerId,
  }) = ScramGameConfig;
  const factory GameConfig.halveIt({
    @Default(null) String? startingPlayerId,
  }) = HalveItGameConfig;
  const factory GameConfig.highScore({
    @Default(null) String? startingPlayerId,
  }) = HighScoreGameConfig;
  const factory GameConfig.blindCricket({
    @Default(null) String? startingPlayerId,
  }) = BlindCricketGameConfig;
  const factory GameConfig.blindGolf({
    @Default(null) String? startingPlayerId,
  }) = BlindGolfGameConfig;
  const factory GameConfig.blindKiller({
    @Default(null) String? startingPlayerId,
  }) = BlindKillerGameConfig;
  const factory GameConfig.blindShanghai({
    @Default(null) String? startingPlayerId,
  }) = BlindShanghaiGameConfig;
  const factory GameConfig.chaseTheDragon({
    @Default(null) String? startingPlayerId,
  }) = ChaseTheDragonGameConfig;

  const factory GameConfig.catch40({
    required String startingPlayerId,
    @Default(8) int totalRounds,
    @Default([10, 15, 20, 25, 30, 35, 40, 45]) List<int> roundTargets,
  }) = Catch40GameConfig;

  const factory GameConfig.bobs27({
    required String startingPlayerId,
  }) = Bobs27GameConfig;

  const factory GameConfig.checkoutPractice({
    required String startingPlayerId,
    @Default(false) bool randomOrder,
  }) = CheckoutPracticeGameConfig;

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
  /// Supported formats: '20', 'D20', 'T20', 'SB', 'DB', 'MISS', '0'
  static Segment parse(String segmentString) {
    segmentString = segmentString.trim().toUpperCase();

    if (segmentString == 'SB') return const Segment.singleBull();
    if (segmentString == 'DB') return const Segment.doubleBull();
    if (segmentString == 'MISS' || segmentString == '0') return const Segment.miss();

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

  /// Check if this segment is a miss
  bool get isMiss {
    return when(
      single: (_) => false,
      doubleSegment: (_) => false,
      triple: (_) => false,
      singleBull: () => false,
      doubleBull: () => false,
      miss: () => true,
    );
  }
}