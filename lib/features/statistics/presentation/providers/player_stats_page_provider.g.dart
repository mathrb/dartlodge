// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_stats_page_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PlayerStatsPage)
final playerStatsPageProvider = PlayerStatsPageFamily._();

final class PlayerStatsPageProvider
    extends $NotifierProvider<PlayerStatsPage, PlayerStatsPageState> {
  PlayerStatsPageProvider._({
    required PlayerStatsPageFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'playerStatsPageProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playerStatsPageHash();

  @override
  String toString() {
    return r'playerStatsPageProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PlayerStatsPage create() => PlayerStatsPage();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlayerStatsPageState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlayerStatsPageState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlayerStatsPageProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playerStatsPageHash() => r'c820b227faaafc17ecb4c2e8391da12ab8289852';

final class PlayerStatsPageFamily extends $Family
    with
        $ClassFamilyOverride<
          PlayerStatsPage,
          PlayerStatsPageState,
          PlayerStatsPageState,
          PlayerStatsPageState,
          String
        > {
  PlayerStatsPageFamily._()
    : super(
        retry: null,
        name: r'playerStatsPageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PlayerStatsPageProvider call(String playerId) =>
      PlayerStatsPageProvider._(argument: playerId, from: this);

  @override
  String toString() => r'playerStatsPageProvider';
}

abstract class _$PlayerStatsPage extends $Notifier<PlayerStatsPageState> {
  late final _$args = ref.$arg as String;
  String get playerId => _$args;

  PlayerStatsPageState build(String playerId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PlayerStatsPageState, PlayerStatsPageState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlayerStatsPageState, PlayerStatsPageState>,
              PlayerStatsPageState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(playerX01StartingScores)
final playerX01StartingScoresProvider = PlayerX01StartingScoresFamily._();

final class PlayerX01StartingScoresProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<int>>,
          List<int>,
          FutureOr<List<int>>
        >
    with $FutureModifier<List<int>>, $FutureProvider<List<int>> {
  PlayerX01StartingScoresProvider._({
    required PlayerX01StartingScoresFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'playerX01StartingScoresProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playerX01StartingScoresHash();

  @override
  String toString() {
    return r'playerX01StartingScoresProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<int>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<int>> create(Ref ref) {
    final argument = this.argument as String;
    return playerX01StartingScores(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlayerX01StartingScoresProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playerX01StartingScoresHash() =>
    r'310468c6b6c7317b55002e9b95fda28c50758983';

final class PlayerX01StartingScoresFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<int>>, String> {
  PlayerX01StartingScoresFamily._()
    : super(
        retry: null,
        name: r'playerX01StartingScoresProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PlayerX01StartingScoresProvider call(String playerId) =>
      PlayerX01StartingScoresProvider._(argument: playerId, from: this);

  @override
  String toString() => r'playerX01StartingScoresProvider';
}

@ProviderFor(playerCricketVariants)
final playerCricketVariantsProvider = PlayerCricketVariantsFamily._();

final class PlayerCricketVariantsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  PlayerCricketVariantsProvider._({
    required PlayerCricketVariantsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'playerCricketVariantsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playerCricketVariantsHash();

  @override
  String toString() {
    return r'playerCricketVariantsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    final argument = this.argument as String;
    return playerCricketVariants(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlayerCricketVariantsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playerCricketVariantsHash() =>
    r'19a28bfc6ba40c71a7ff8dcd7418e8990dea192a';

final class PlayerCricketVariantsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<String>>, String> {
  PlayerCricketVariantsFamily._()
    : super(
        retry: null,
        name: r'playerCricketVariantsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PlayerCricketVariantsProvider call(String playerId) =>
      PlayerCricketVariantsProvider._(argument: playerId, from: this);

  @override
  String toString() => r'playerCricketVariantsProvider';
}

@ProviderFor(filteredPlayerStats)
final filteredPlayerStatsProvider = FilteredPlayerStatsFamily._();

final class FilteredPlayerStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlayerStats>,
          PlayerStats,
          FutureOr<PlayerStats>
        >
    with $FutureModifier<PlayerStats>, $FutureProvider<PlayerStats> {
  FilteredPlayerStatsProvider._({
    required FilteredPlayerStatsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'filteredPlayerStatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filteredPlayerStatsHash();

  @override
  String toString() {
    return r'filteredPlayerStatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PlayerStats> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PlayerStats> create(Ref ref) {
    final argument = this.argument as String;
    return filteredPlayerStats(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredPlayerStatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filteredPlayerStatsHash() =>
    r'63ed687e8d03894e1b37eedd4527c9c6edac5af4';

final class FilteredPlayerStatsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PlayerStats>, String> {
  FilteredPlayerStatsFamily._()
    : super(
        retry: null,
        name: r'filteredPlayerStatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FilteredPlayerStatsProvider call(String playerId) =>
      FilteredPlayerStatsProvider._(argument: playerId, from: this);

  @override
  String toString() => r'filteredPlayerStatsProvider';
}

@ProviderFor(playerLegHistory)
final playerLegHistoryProvider = PlayerLegHistoryFamily._();

final class PlayerLegHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlayerLegSnapshot>>,
          List<PlayerLegSnapshot>,
          FutureOr<List<PlayerLegSnapshot>>
        >
    with
        $FutureModifier<List<PlayerLegSnapshot>>,
        $FutureProvider<List<PlayerLegSnapshot>> {
  PlayerLegHistoryProvider._({
    required PlayerLegHistoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'playerLegHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playerLegHistoryHash();

  @override
  String toString() {
    return r'playerLegHistoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PlayerLegSnapshot>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlayerLegSnapshot>> create(Ref ref) {
    final argument = this.argument as String;
    return playerLegHistory(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlayerLegHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playerLegHistoryHash() => r'567fb41c5b65f121c1de79e342d1af06353c97e6';

final class PlayerLegHistoryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PlayerLegSnapshot>>, String> {
  PlayerLegHistoryFamily._()
    : super(
        retry: null,
        name: r'playerLegHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PlayerLegHistoryProvider call(String playerId) =>
      PlayerLegHistoryProvider._(argument: playerId, from: this);

  @override
  String toString() => r'playerLegHistoryProvider';
}

@ProviderFor(filteredCricketStats)
final filteredCricketStatsProvider = FilteredCricketStatsFamily._();

final class FilteredCricketStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlayerStats>,
          PlayerStats,
          FutureOr<PlayerStats>
        >
    with $FutureModifier<PlayerStats>, $FutureProvider<PlayerStats> {
  FilteredCricketStatsProvider._({
    required FilteredCricketStatsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'filteredCricketStatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filteredCricketStatsHash();

  @override
  String toString() {
    return r'filteredCricketStatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PlayerStats> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PlayerStats> create(Ref ref) {
    final argument = this.argument as String;
    return filteredCricketStats(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredCricketStatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filteredCricketStatsHash() =>
    r'd83e6f17d0429c5b5ec55e89ba28e1c3228e215d';

final class FilteredCricketStatsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PlayerStats>, String> {
  FilteredCricketStatsFamily._()
    : super(
        retry: null,
        name: r'filteredCricketStatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FilteredCricketStatsProvider call(String playerId) =>
      FilteredCricketStatsProvider._(argument: playerId, from: this);

  @override
  String toString() => r'filteredCricketStatsProvider';
}

@ProviderFor(cricketLegHistory)
final cricketLegHistoryProvider = CricketLegHistoryFamily._();

final class CricketLegHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlayerLegSnapshot>>,
          List<PlayerLegSnapshot>,
          FutureOr<List<PlayerLegSnapshot>>
        >
    with
        $FutureModifier<List<PlayerLegSnapshot>>,
        $FutureProvider<List<PlayerLegSnapshot>> {
  CricketLegHistoryProvider._({
    required CricketLegHistoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cricketLegHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cricketLegHistoryHash();

  @override
  String toString() {
    return r'cricketLegHistoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PlayerLegSnapshot>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlayerLegSnapshot>> create(Ref ref) {
    final argument = this.argument as String;
    return cricketLegHistory(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CricketLegHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cricketLegHistoryHash() => r'00b89137334ea19c6746a4e29d14aa434991863b';

final class CricketLegHistoryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PlayerLegSnapshot>>, String> {
  CricketLegHistoryFamily._()
    : super(
        retry: null,
        name: r'cricketLegHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CricketLegHistoryProvider call(String playerId) =>
      CricketLegHistoryProvider._(argument: playerId, from: this);

  @override
  String toString() => r'cricketLegHistoryProvider';
}

@ProviderFor(filteredPracticeStats)
final filteredPracticeStatsProvider = FilteredPracticeStatsFamily._();

final class FilteredPracticeStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlayerStats>,
          PlayerStats,
          FutureOr<PlayerStats>
        >
    with $FutureModifier<PlayerStats>, $FutureProvider<PlayerStats> {
  FilteredPracticeStatsProvider._({
    required FilteredPracticeStatsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'filteredPracticeStatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filteredPracticeStatsHash();

  @override
  String toString() {
    return r'filteredPracticeStatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PlayerStats> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PlayerStats> create(Ref ref) {
    final argument = this.argument as String;
    return filteredPracticeStats(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredPracticeStatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filteredPracticeStatsHash() =>
    r'3af5d40f67c7abc0c3b02db34bc7d46b6fa70590';

final class FilteredPracticeStatsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PlayerStats>, String> {
  FilteredPracticeStatsFamily._()
    : super(
        retry: null,
        name: r'filteredPracticeStatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FilteredPracticeStatsProvider call(String playerId) =>
      FilteredPracticeStatsProvider._(argument: playerId, from: this);

  @override
  String toString() => r'filteredPracticeStatsProvider';
}

@ProviderFor(practiceDrillHistory)
final practiceDrillHistoryProvider = PracticeDrillHistoryFamily._();

final class PracticeDrillHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlayerLegSnapshot>>,
          List<PlayerLegSnapshot>,
          FutureOr<List<PlayerLegSnapshot>>
        >
    with
        $FutureModifier<List<PlayerLegSnapshot>>,
        $FutureProvider<List<PlayerLegSnapshot>> {
  PracticeDrillHistoryProvider._({
    required PracticeDrillHistoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'practiceDrillHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$practiceDrillHistoryHash();

  @override
  String toString() {
    return r'practiceDrillHistoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PlayerLegSnapshot>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlayerLegSnapshot>> create(Ref ref) {
    final argument = this.argument as String;
    return practiceDrillHistory(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PracticeDrillHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$practiceDrillHistoryHash() =>
    r'052d9bcb6453c90794e68358137a4e02d3327e09';

final class PracticeDrillHistoryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PlayerLegSnapshot>>, String> {
  PracticeDrillHistoryFamily._()
    : super(
        retry: null,
        name: r'practiceDrillHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PracticeDrillHistoryProvider call(String playerId) =>
      PracticeDrillHistoryProvider._(argument: playerId, from: this);

  @override
  String toString() => r'practiceDrillHistoryProvider';
}
