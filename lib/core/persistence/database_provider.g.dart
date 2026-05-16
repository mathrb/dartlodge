// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          AsyncValue<SharedPreferences>,
          SharedPreferences,
          FutureOr<SharedPreferences>
        >
    with
        $FutureModifier<SharedPreferences>,
        $FutureProvider<SharedPreferences> {
  SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $FutureProviderElement<SharedPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SharedPreferences> create(Ref ref) {
    return sharedPreferences(ref);
  }
}

String _$sharedPreferencesHash() => r'ad13470fe866595ad0f58a3e26f11048d94ef22e';

@ProviderFor(database)
final databaseProvider = DatabaseProvider._();

final class DatabaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppDatabase>,
          AppDatabase,
          FutureOr<AppDatabase>
        >
    with $FutureModifier<AppDatabase>, $FutureProvider<AppDatabase> {
  DatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseHash();

  @$internal
  @override
  $FutureProviderElement<AppDatabase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AppDatabase> create(Ref ref) {
    return database(ref);
  }
}

String _$databaseHash() => r'327d82d59233f01964b65e2ecd9e98d66caab007';

@ProviderFor(playerRepository)
final playerRepositoryProvider = PlayerRepositoryProvider._();

final class PlayerRepositoryProvider
    extends
        $FunctionalProvider<
          PlayerRepository,
          PlayerRepository,
          PlayerRepository
        >
    with $Provider<PlayerRepository> {
  PlayerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playerRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playerRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlayerRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlayerRepository create(Ref ref) {
    return playerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlayerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlayerRepository>(value),
    );
  }
}

String _$playerRepositoryHash() => r'f6d5e27c2bf9b1868ebe3c18294e31cda2e8c540';

@ProviderFor(createPlayerUseCase)
final createPlayerUseCaseProvider = CreatePlayerUseCaseProvider._();

final class CreatePlayerUseCaseProvider
    extends
        $FunctionalProvider<
          CreatePlayerUseCase,
          CreatePlayerUseCase,
          CreatePlayerUseCase
        >
    with $Provider<CreatePlayerUseCase> {
  CreatePlayerUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createPlayerUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createPlayerUseCaseHash();

  @$internal
  @override
  $ProviderElement<CreatePlayerUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CreatePlayerUseCase create(Ref ref) {
    return createPlayerUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreatePlayerUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreatePlayerUseCase>(value),
    );
  }
}

String _$createPlayerUseCaseHash() =>
    r'f22f35d37ea4661153776e435437814a0026af8c';

@ProviderFor(gameRepository)
final gameRepositoryProvider = GameRepositoryProvider._();

final class GameRepositoryProvider
    extends $FunctionalProvider<GameRepository, GameRepository, GameRepository>
    with $Provider<GameRepository> {
  GameRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gameRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gameRepositoryHash();

  @$internal
  @override
  $ProviderElement<GameRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GameRepository create(Ref ref) {
    return gameRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GameRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GameRepository>(value),
    );
  }
}

String _$gameRepositoryHash() => r'5646b8aa7090375fec7f816e27c92b3fb9aaba2c';

@ProviderFor(dartThrowRepository)
final dartThrowRepositoryProvider = DartThrowRepositoryProvider._();

final class DartThrowRepositoryProvider
    extends
        $FunctionalProvider<
          DartThrowRepository,
          DartThrowRepository,
          DartThrowRepository
        >
    with $Provider<DartThrowRepository> {
  DartThrowRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dartThrowRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dartThrowRepositoryHash();

  @$internal
  @override
  $ProviderElement<DartThrowRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DartThrowRepository create(Ref ref) {
    return dartThrowRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DartThrowRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DartThrowRepository>(value),
    );
  }
}

String _$dartThrowRepositoryHash() =>
    r'07824732886f9cfd6c15b82cbf1525b4ff259485';

@ProviderFor(gameEventRepository)
final gameEventRepositoryProvider = GameEventRepositoryProvider._();

final class GameEventRepositoryProvider
    extends
        $FunctionalProvider<
          GameEventRepository,
          GameEventRepository,
          GameEventRepository
        >
    with $Provider<GameEventRepository> {
  GameEventRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gameEventRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gameEventRepositoryHash();

  @$internal
  @override
  $ProviderElement<GameEventRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GameEventRepository create(Ref ref) {
    return gameEventRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GameEventRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GameEventRepository>(value),
    );
  }
}

String _$gameEventRepositoryHash() =>
    r'906c11aaba24a7e2066f0646528b5eda218e4f6e';

@ProviderFor(computeLegStatsUseCase)
final computeLegStatsUseCaseProvider = ComputeLegStatsUseCaseProvider._();

final class ComputeLegStatsUseCaseProvider
    extends
        $FunctionalProvider<
          ComputeLegStatsUseCase,
          ComputeLegStatsUseCase,
          ComputeLegStatsUseCase
        >
    with $Provider<ComputeLegStatsUseCase> {
  ComputeLegStatsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'computeLegStatsUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$computeLegStatsUseCaseHash();

  @$internal
  @override
  $ProviderElement<ComputeLegStatsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ComputeLegStatsUseCase create(Ref ref) {
    return computeLegStatsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ComputeLegStatsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ComputeLegStatsUseCase>(value),
    );
  }
}

String _$computeLegStatsUseCaseHash() =>
    r'95edac98faa737aac4bcd1740fee798c856dc09f';

@ProviderFor(statisticsRepository)
final statisticsRepositoryProvider = StatisticsRepositoryProvider._();

final class StatisticsRepositoryProvider
    extends
        $FunctionalProvider<
          StatisticsRepository,
          StatisticsRepository,
          StatisticsRepository
        >
    with $Provider<StatisticsRepository> {
  StatisticsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'statisticsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$statisticsRepositoryHash();

  @$internal
  @override
  $ProviderElement<StatisticsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StatisticsRepository create(Ref ref) {
    return statisticsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StatisticsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StatisticsRepository>(value),
    );
  }
}

String _$statisticsRepositoryHash() =>
    r'28abdff3dde657f85c34b95ff81a514b97ca07aa';

@ProviderFor(x01Engine)
final x01EngineProvider = X01EngineProvider._();

final class X01EngineProvider
    extends
        $FunctionalProvider<
          StatelessX01Engine,
          StatelessX01Engine,
          StatelessX01Engine
        >
    with $Provider<StatelessX01Engine> {
  X01EngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'x01EngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$x01EngineHash();

  @$internal
  @override
  $ProviderElement<StatelessX01Engine> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StatelessX01Engine create(Ref ref) {
    return x01Engine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StatelessX01Engine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StatelessX01Engine>(value),
    );
  }
}

String _$x01EngineHash() => r'126e7436f179afa83ad44aafb9015041be29bff1';

@ProviderFor(processDartUseCase)
final processDartUseCaseProvider = ProcessDartUseCaseProvider._();

final class ProcessDartUseCaseProvider
    extends
        $FunctionalProvider<
          ProcessDartUseCase,
          ProcessDartUseCase,
          ProcessDartUseCase
        >
    with $Provider<ProcessDartUseCase> {
  ProcessDartUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'processDartUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$processDartUseCaseHash();

  @$internal
  @override
  $ProviderElement<ProcessDartUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProcessDartUseCase create(Ref ref) {
    return processDartUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProcessDartUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProcessDartUseCase>(value),
    );
  }
}

String _$processDartUseCaseHash() =>
    r'86971dd7466c710d1ec08b129845697e70f286cf';

@ProviderFor(undoLastDartUseCase)
final undoLastDartUseCaseProvider = UndoLastDartUseCaseProvider._();

final class UndoLastDartUseCaseProvider
    extends
        $FunctionalProvider<
          UndoLastDartUseCase,
          UndoLastDartUseCase,
          UndoLastDartUseCase
        >
    with $Provider<UndoLastDartUseCase> {
  UndoLastDartUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'undoLastDartUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$undoLastDartUseCaseHash();

  @$internal
  @override
  $ProviderElement<UndoLastDartUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UndoLastDartUseCase create(Ref ref) {
    return undoLastDartUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UndoLastDartUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UndoLastDartUseCase>(value),
    );
  }
}

String _$undoLastDartUseCaseHash() =>
    r'91fe21f3b9e8ae53cbf51fbce1f22ffdd569a074';

@ProviderFor(cricketEngine)
final cricketEngineProvider = CricketEngineProvider._();

final class CricketEngineProvider
    extends
        $FunctionalProvider<
          StatelessCricketEngine,
          StatelessCricketEngine,
          StatelessCricketEngine
        >
    with $Provider<StatelessCricketEngine> {
  CricketEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cricketEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cricketEngineHash();

  @$internal
  @override
  $ProviderElement<StatelessCricketEngine> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StatelessCricketEngine create(Ref ref) {
    return cricketEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StatelessCricketEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StatelessCricketEngine>(value),
    );
  }
}

String _$cricketEngineHash() => r'6419c2b51a8e480ef55b1f5a97c74a32c76246b9';

@ProviderFor(processCricketDartUseCase)
final processCricketDartUseCaseProvider = ProcessCricketDartUseCaseProvider._();

final class ProcessCricketDartUseCaseProvider
    extends
        $FunctionalProvider<
          ProcessCricketDartUseCase,
          ProcessCricketDartUseCase,
          ProcessCricketDartUseCase
        >
    with $Provider<ProcessCricketDartUseCase> {
  ProcessCricketDartUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'processCricketDartUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$processCricketDartUseCaseHash();

  @$internal
  @override
  $ProviderElement<ProcessCricketDartUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProcessCricketDartUseCase create(Ref ref) {
    return processCricketDartUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProcessCricketDartUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProcessCricketDartUseCase>(value),
    );
  }
}

String _$processCricketDartUseCaseHash() =>
    r'b111854dd94e7798a2b933e929ebf10f213be926';

@ProviderFor(undoCricketLastDartUseCase)
final undoCricketLastDartUseCaseProvider =
    UndoCricketLastDartUseCaseProvider._();

final class UndoCricketLastDartUseCaseProvider
    extends
        $FunctionalProvider<
          UndoLastDartUseCase,
          UndoLastDartUseCase,
          UndoLastDartUseCase
        >
    with $Provider<UndoLastDartUseCase> {
  UndoCricketLastDartUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'undoCricketLastDartUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$undoCricketLastDartUseCaseHash();

  @$internal
  @override
  $ProviderElement<UndoLastDartUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UndoLastDartUseCase create(Ref ref) {
    return undoCricketLastDartUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UndoLastDartUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UndoLastDartUseCase>(value),
    );
  }
}

String _$undoCricketLastDartUseCaseHash() =>
    r'8520dabcefb36cfdc47cde988c403063175f5b23';

@ProviderFor(createGameUseCase)
final createGameUseCaseProvider = CreateGameUseCaseProvider._();

final class CreateGameUseCaseProvider
    extends
        $FunctionalProvider<
          CreateGameUseCase,
          CreateGameUseCase,
          CreateGameUseCase
        >
    with $Provider<CreateGameUseCase> {
  CreateGameUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createGameUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createGameUseCaseHash();

  @$internal
  @override
  $ProviderElement<CreateGameUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CreateGameUseCase create(Ref ref) {
    return createGameUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateGameUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateGameUseCase>(value),
    );
  }
}

String _$createGameUseCaseHash() => r'a8811da823c99a54a68c98d26af38df6e303c645';

@ProviderFor(aroundTheClockEngine)
final aroundTheClockEngineProvider = AroundTheClockEngineProvider._();

final class AroundTheClockEngineProvider
    extends
        $FunctionalProvider<
          StatelessAroundTheClockEngine,
          StatelessAroundTheClockEngine,
          StatelessAroundTheClockEngine
        >
    with $Provider<StatelessAroundTheClockEngine> {
  AroundTheClockEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aroundTheClockEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aroundTheClockEngineHash();

  @$internal
  @override
  $ProviderElement<StatelessAroundTheClockEngine> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StatelessAroundTheClockEngine create(Ref ref) {
    return aroundTheClockEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StatelessAroundTheClockEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StatelessAroundTheClockEngine>(
        value,
      ),
    );
  }
}

String _$aroundTheClockEngineHash() =>
    r'27fabf95d10a168096cc53f5f69c0a7d525f55d9';

@ProviderFor(bobs27Engine)
final bobs27EngineProvider = Bobs27EngineProvider._();

final class Bobs27EngineProvider
    extends
        $FunctionalProvider<
          StatelessBobs27Engine,
          StatelessBobs27Engine,
          StatelessBobs27Engine
        >
    with $Provider<StatelessBobs27Engine> {
  Bobs27EngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bobs27EngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bobs27EngineHash();

  @$internal
  @override
  $ProviderElement<StatelessBobs27Engine> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StatelessBobs27Engine create(Ref ref) {
    return bobs27Engine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StatelessBobs27Engine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StatelessBobs27Engine>(value),
    );
  }
}

String _$bobs27EngineHash() => r'eda8a230a002679a84fe04ef8b74e2a9c708ec6b';

@ProviderFor(shanghaiEngine)
final shanghaiEngineProvider = ShanghaiEngineProvider._();

final class ShanghaiEngineProvider
    extends
        $FunctionalProvider<
          StatelessShanghaiEngine,
          StatelessShanghaiEngine,
          StatelessShanghaiEngine
        >
    with $Provider<StatelessShanghaiEngine> {
  ShanghaiEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shanghaiEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shanghaiEngineHash();

  @$internal
  @override
  $ProviderElement<StatelessShanghaiEngine> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StatelessShanghaiEngine create(Ref ref) {
    return shanghaiEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StatelessShanghaiEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StatelessShanghaiEngine>(value),
    );
  }
}

String _$shanghaiEngineHash() => r'6877e7087678d3c75d0f4f05b0e0b036a37f174f';

@ProviderFor(catch40Engine)
final catch40EngineProvider = Catch40EngineProvider._();

final class Catch40EngineProvider
    extends
        $FunctionalProvider<
          StatelessCatch40Engine,
          StatelessCatch40Engine,
          StatelessCatch40Engine
        >
    with $Provider<StatelessCatch40Engine> {
  Catch40EngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catch40EngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catch40EngineHash();

  @$internal
  @override
  $ProviderElement<StatelessCatch40Engine> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StatelessCatch40Engine create(Ref ref) {
    return catch40Engine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StatelessCatch40Engine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StatelessCatch40Engine>(value),
    );
  }
}

String _$catch40EngineHash() => r'748f37aee6aee73bbbf76e36c22d079916500d26';

@ProviderFor(checkoutPracticeEngine)
final checkoutPracticeEngineProvider = CheckoutPracticeEngineProvider._();

final class CheckoutPracticeEngineProvider
    extends
        $FunctionalProvider<
          StatelessCheckoutPracticeEngine,
          StatelessCheckoutPracticeEngine,
          StatelessCheckoutPracticeEngine
        >
    with $Provider<StatelessCheckoutPracticeEngine> {
  CheckoutPracticeEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkoutPracticeEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkoutPracticeEngineHash();

  @$internal
  @override
  $ProviderElement<StatelessCheckoutPracticeEngine> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StatelessCheckoutPracticeEngine create(Ref ref) {
    return checkoutPracticeEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StatelessCheckoutPracticeEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StatelessCheckoutPracticeEngine>(
        value,
      ),
    );
  }
}

String _$checkoutPracticeEngineHash() =>
    r'fb08d42d834f25bf3687caefde17644b3b12d511';

@ProviderFor(countUpEngine)
final countUpEngineProvider = CountUpEngineProvider._();

final class CountUpEngineProvider
    extends
        $FunctionalProvider<
          StatelessCountUpEngine,
          StatelessCountUpEngine,
          StatelessCountUpEngine
        >
    with $Provider<StatelessCountUpEngine> {
  CountUpEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'countUpEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$countUpEngineHash();

  @$internal
  @override
  $ProviderElement<StatelessCountUpEngine> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StatelessCountUpEngine create(Ref ref) {
    return countUpEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StatelessCountUpEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StatelessCountUpEngine>(value),
    );
  }
}

String _$countUpEngineHash() => r'8ab14edba24e93e64f03c2ebdfbe044431a033e4';

/// Count-up reuses the X01-shaped ProcessDartUseCase: DartThrown is purely
/// additive (no bust, no leg-end mid-dart), so the same scaffolding works.
/// Game-end detection happens on TurnEnded inside the count-up engine — see
/// ActiveCountUpNotifier._startNextTurn for the surrounding orchestration.

@ProviderFor(processCountUpDartUseCase)
final processCountUpDartUseCaseProvider = ProcessCountUpDartUseCaseProvider._();

/// Count-up reuses the X01-shaped ProcessDartUseCase: DartThrown is purely
/// additive (no bust, no leg-end mid-dart), so the same scaffolding works.
/// Game-end detection happens on TurnEnded inside the count-up engine — see
/// ActiveCountUpNotifier._startNextTurn for the surrounding orchestration.

final class ProcessCountUpDartUseCaseProvider
    extends
        $FunctionalProvider<
          ProcessDartUseCase,
          ProcessDartUseCase,
          ProcessDartUseCase
        >
    with $Provider<ProcessDartUseCase> {
  /// Count-up reuses the X01-shaped ProcessDartUseCase: DartThrown is purely
  /// additive (no bust, no leg-end mid-dart), so the same scaffolding works.
  /// Game-end detection happens on TurnEnded inside the count-up engine — see
  /// ActiveCountUpNotifier._startNextTurn for the surrounding orchestration.
  ProcessCountUpDartUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'processCountUpDartUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$processCountUpDartUseCaseHash();

  @$internal
  @override
  $ProviderElement<ProcessDartUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProcessDartUseCase create(Ref ref) {
    return processCountUpDartUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProcessDartUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProcessDartUseCase>(value),
    );
  }
}

String _$processCountUpDartUseCaseHash() =>
    r'ef5602835459a6ddab674f62fafc9d092919b4a0';

@ProviderFor(undoCountUpLastDartUseCase)
final undoCountUpLastDartUseCaseProvider =
    UndoCountUpLastDartUseCaseProvider._();

final class UndoCountUpLastDartUseCaseProvider
    extends
        $FunctionalProvider<
          UndoLastDartUseCase,
          UndoLastDartUseCase,
          UndoLastDartUseCase
        >
    with $Provider<UndoLastDartUseCase> {
  UndoCountUpLastDartUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'undoCountUpLastDartUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$undoCountUpLastDartUseCaseHash();

  @$internal
  @override
  $ProviderElement<UndoLastDartUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UndoLastDartUseCase create(Ref ref) {
    return undoCountUpLastDartUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UndoLastDartUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UndoLastDartUseCase>(value),
    );
  }
}

String _$undoCountUpLastDartUseCaseHash() =>
    r'e9438e4d3a09881708cbc112a7e451f7d93a04c1';

@ProviderFor(processAroundTheClockDartUseCase)
final processAroundTheClockDartUseCaseProvider =
    ProcessAroundTheClockDartUseCaseProvider._();

final class ProcessAroundTheClockDartUseCaseProvider
    extends
        $FunctionalProvider<
          ProcessPracticeDartUseCase,
          ProcessPracticeDartUseCase,
          ProcessPracticeDartUseCase
        >
    with $Provider<ProcessPracticeDartUseCase> {
  ProcessAroundTheClockDartUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'processAroundTheClockDartUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$processAroundTheClockDartUseCaseHash();

  @$internal
  @override
  $ProviderElement<ProcessPracticeDartUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProcessPracticeDartUseCase create(Ref ref) {
    return processAroundTheClockDartUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProcessPracticeDartUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProcessPracticeDartUseCase>(value),
    );
  }
}

String _$processAroundTheClockDartUseCaseHash() =>
    r'9d021330ebfcea010276e06ecc82f8d618e459d7';

@ProviderFor(processBobs27DartUseCase)
final processBobs27DartUseCaseProvider = ProcessBobs27DartUseCaseProvider._();

final class ProcessBobs27DartUseCaseProvider
    extends
        $FunctionalProvider<
          ProcessPracticeDartUseCase,
          ProcessPracticeDartUseCase,
          ProcessPracticeDartUseCase
        >
    with $Provider<ProcessPracticeDartUseCase> {
  ProcessBobs27DartUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'processBobs27DartUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$processBobs27DartUseCaseHash();

  @$internal
  @override
  $ProviderElement<ProcessPracticeDartUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProcessPracticeDartUseCase create(Ref ref) {
    return processBobs27DartUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProcessPracticeDartUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProcessPracticeDartUseCase>(value),
    );
  }
}

String _$processBobs27DartUseCaseHash() =>
    r'101c637d8f06c400e3b130236a67575c2c8a47e2';

@ProviderFor(processShanghaiDartUseCase)
final processShanghaiDartUseCaseProvider =
    ProcessShanghaiDartUseCaseProvider._();

final class ProcessShanghaiDartUseCaseProvider
    extends
        $FunctionalProvider<
          ProcessPracticeDartUseCase,
          ProcessPracticeDartUseCase,
          ProcessPracticeDartUseCase
        >
    with $Provider<ProcessPracticeDartUseCase> {
  ProcessShanghaiDartUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'processShanghaiDartUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$processShanghaiDartUseCaseHash();

  @$internal
  @override
  $ProviderElement<ProcessPracticeDartUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProcessPracticeDartUseCase create(Ref ref) {
    return processShanghaiDartUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProcessPracticeDartUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProcessPracticeDartUseCase>(value),
    );
  }
}

String _$processShanghaiDartUseCaseHash() =>
    r'2951fdd023f4baab5e7231551ec5addb9a76fe33';

@ProviderFor(processCatch40DartUseCase)
final processCatch40DartUseCaseProvider = ProcessCatch40DartUseCaseProvider._();

final class ProcessCatch40DartUseCaseProvider
    extends
        $FunctionalProvider<
          ProcessPracticeDartUseCase,
          ProcessPracticeDartUseCase,
          ProcessPracticeDartUseCase
        >
    with $Provider<ProcessPracticeDartUseCase> {
  ProcessCatch40DartUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'processCatch40DartUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$processCatch40DartUseCaseHash();

  @$internal
  @override
  $ProviderElement<ProcessPracticeDartUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProcessPracticeDartUseCase create(Ref ref) {
    return processCatch40DartUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProcessPracticeDartUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProcessPracticeDartUseCase>(value),
    );
  }
}

String _$processCatch40DartUseCaseHash() =>
    r'f2db2947223830c67f36699b1ce232051f297ae5';

@ProviderFor(processCheckoutPracticeDartUseCase)
final processCheckoutPracticeDartUseCaseProvider =
    ProcessCheckoutPracticeDartUseCaseProvider._();

final class ProcessCheckoutPracticeDartUseCaseProvider
    extends
        $FunctionalProvider<
          ProcessPracticeDartUseCase,
          ProcessPracticeDartUseCase,
          ProcessPracticeDartUseCase
        >
    with $Provider<ProcessPracticeDartUseCase> {
  ProcessCheckoutPracticeDartUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'processCheckoutPracticeDartUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$processCheckoutPracticeDartUseCaseHash();

  @$internal
  @override
  $ProviderElement<ProcessPracticeDartUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProcessPracticeDartUseCase create(Ref ref) {
    return processCheckoutPracticeDartUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProcessPracticeDartUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProcessPracticeDartUseCase>(value),
    );
  }
}

String _$processCheckoutPracticeDartUseCaseHash() =>
    r'adc22c6de4311d46aca7d08869ca9d940200b406';

@ProviderFor(undoPracticeAroundTheClockLastDartUseCase)
final undoPracticeAroundTheClockLastDartUseCaseProvider =
    UndoPracticeAroundTheClockLastDartUseCaseProvider._();

final class UndoPracticeAroundTheClockLastDartUseCaseProvider
    extends
        $FunctionalProvider<
          UndoLastDartUseCase,
          UndoLastDartUseCase,
          UndoLastDartUseCase
        >
    with $Provider<UndoLastDartUseCase> {
  UndoPracticeAroundTheClockLastDartUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'undoPracticeAroundTheClockLastDartUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$undoPracticeAroundTheClockLastDartUseCaseHash();

  @$internal
  @override
  $ProviderElement<UndoLastDartUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UndoLastDartUseCase create(Ref ref) {
    return undoPracticeAroundTheClockLastDartUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UndoLastDartUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UndoLastDartUseCase>(value),
    );
  }
}

String _$undoPracticeAroundTheClockLastDartUseCaseHash() =>
    r'452d2ed376b6847a7478fd65f637a4ed3963ac1b';

@ProviderFor(undoPracticeBobs27LastDartUseCase)
final undoPracticeBobs27LastDartUseCaseProvider =
    UndoPracticeBobs27LastDartUseCaseProvider._();

final class UndoPracticeBobs27LastDartUseCaseProvider
    extends
        $FunctionalProvider<
          UndoLastDartUseCase,
          UndoLastDartUseCase,
          UndoLastDartUseCase
        >
    with $Provider<UndoLastDartUseCase> {
  UndoPracticeBobs27LastDartUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'undoPracticeBobs27LastDartUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$undoPracticeBobs27LastDartUseCaseHash();

  @$internal
  @override
  $ProviderElement<UndoLastDartUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UndoLastDartUseCase create(Ref ref) {
    return undoPracticeBobs27LastDartUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UndoLastDartUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UndoLastDartUseCase>(value),
    );
  }
}

String _$undoPracticeBobs27LastDartUseCaseHash() =>
    r'8391824452b239a31ea42eff2e2e35dd172e1057';

@ProviderFor(undoPracticeShanghaiLastDartUseCase)
final undoPracticeShanghaiLastDartUseCaseProvider =
    UndoPracticeShanghaiLastDartUseCaseProvider._();

final class UndoPracticeShanghaiLastDartUseCaseProvider
    extends
        $FunctionalProvider<
          UndoLastDartUseCase,
          UndoLastDartUseCase,
          UndoLastDartUseCase
        >
    with $Provider<UndoLastDartUseCase> {
  UndoPracticeShanghaiLastDartUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'undoPracticeShanghaiLastDartUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$undoPracticeShanghaiLastDartUseCaseHash();

  @$internal
  @override
  $ProviderElement<UndoLastDartUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UndoLastDartUseCase create(Ref ref) {
    return undoPracticeShanghaiLastDartUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UndoLastDartUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UndoLastDartUseCase>(value),
    );
  }
}

String _$undoPracticeShanghaiLastDartUseCaseHash() =>
    r'196dfe86dac88c682949a460ae9e58cf92898626';

@ProviderFor(undoPracticeCatch40LastDartUseCase)
final undoPracticeCatch40LastDartUseCaseProvider =
    UndoPracticeCatch40LastDartUseCaseProvider._();

final class UndoPracticeCatch40LastDartUseCaseProvider
    extends
        $FunctionalProvider<
          UndoLastDartUseCase,
          UndoLastDartUseCase,
          UndoLastDartUseCase
        >
    with $Provider<UndoLastDartUseCase> {
  UndoPracticeCatch40LastDartUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'undoPracticeCatch40LastDartUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$undoPracticeCatch40LastDartUseCaseHash();

  @$internal
  @override
  $ProviderElement<UndoLastDartUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UndoLastDartUseCase create(Ref ref) {
    return undoPracticeCatch40LastDartUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UndoLastDartUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UndoLastDartUseCase>(value),
    );
  }
}

String _$undoPracticeCatch40LastDartUseCaseHash() =>
    r'b9a085b08d63f2f5e97554f694e2545fb0e5e141';

@ProviderFor(undoPracticeCheckoutPracticeLastDartUseCase)
final undoPracticeCheckoutPracticeLastDartUseCaseProvider =
    UndoPracticeCheckoutPracticeLastDartUseCaseProvider._();

final class UndoPracticeCheckoutPracticeLastDartUseCaseProvider
    extends
        $FunctionalProvider<
          UndoLastDartUseCase,
          UndoLastDartUseCase,
          UndoLastDartUseCase
        >
    with $Provider<UndoLastDartUseCase> {
  UndoPracticeCheckoutPracticeLastDartUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'undoPracticeCheckoutPracticeLastDartUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$undoPracticeCheckoutPracticeLastDartUseCaseHash();

  @$internal
  @override
  $ProviderElement<UndoLastDartUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UndoLastDartUseCase create(Ref ref) {
    return undoPracticeCheckoutPracticeLastDartUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UndoLastDartUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UndoLastDartUseCase>(value),
    );
  }
}

String _$undoPracticeCheckoutPracticeLastDartUseCaseHash() =>
    r'bf5a3bdf1267ef8c18d199488cee1ef1eb2c882f';

@ProviderFor(endPracticeUseCase)
final endPracticeUseCaseProvider = EndPracticeUseCaseProvider._();

final class EndPracticeUseCaseProvider
    extends
        $FunctionalProvider<
          EndPracticeUseCase,
          EndPracticeUseCase,
          EndPracticeUseCase
        >
    with $Provider<EndPracticeUseCase> {
  EndPracticeUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'endPracticeUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$endPracticeUseCaseHash();

  @$internal
  @override
  $ProviderElement<EndPracticeUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EndPracticeUseCase create(Ref ref) {
    return endPracticeUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EndPracticeUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EndPracticeUseCase>(value),
    );
  }
}

String _$endPracticeUseCaseHash() =>
    r'34a35681dc9f14a2a4c227aea98eac5c41aeec93';

/// Persists the last-used [GameConfig] per game category ('x01' or 'cricket').
/// Used by VariantSelectionPage to show a "Last Used" quick-start tile.

@ProviderFor(LastGameConfig)
final lastGameConfigProvider = LastGameConfigFamily._();

/// Persists the last-used [GameConfig] per game category ('x01' or 'cricket').
/// Used by VariantSelectionPage to show a "Last Used" quick-start tile.
final class LastGameConfigProvider
    extends $AsyncNotifierProvider<LastGameConfig, GameConfig?> {
  /// Persists the last-used [GameConfig] per game category ('x01' or 'cricket').
  /// Used by VariantSelectionPage to show a "Last Used" quick-start tile.
  LastGameConfigProvider._({
    required LastGameConfigFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lastGameConfigProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lastGameConfigHash();

  @override
  String toString() {
    return r'lastGameConfigProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LastGameConfig create() => LastGameConfig();

  @override
  bool operator ==(Object other) {
    return other is LastGameConfigProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lastGameConfigHash() => r'5a2f5e281db48e51c8b5bcc3a4a3e43276c3548e';

/// Persists the last-used [GameConfig] per game category ('x01' or 'cricket').
/// Used by VariantSelectionPage to show a "Last Used" quick-start tile.

final class LastGameConfigFamily extends $Family
    with
        $ClassFamilyOverride<
          LastGameConfig,
          AsyncValue<GameConfig?>,
          GameConfig?,
          FutureOr<GameConfig?>,
          String
        > {
  LastGameConfigFamily._()
    : super(
        retry: null,
        name: r'lastGameConfigProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Persists the last-used [GameConfig] per game category ('x01' or 'cricket').
  /// Used by VariantSelectionPage to show a "Last Used" quick-start tile.

  LastGameConfigProvider call(String category) =>
      LastGameConfigProvider._(argument: category, from: this);

  @override
  String toString() => r'lastGameConfigProvider';
}

/// Persists the last-used [GameConfig] per game category ('x01' or 'cricket').
/// Used by VariantSelectionPage to show a "Last Used" quick-start tile.

abstract class _$LastGameConfig extends $AsyncNotifier<GameConfig?> {
  late final _$args = ref.$arg as String;
  String get category => _$args;

  FutureOr<GameConfig?> build(String category);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<GameConfig?>, GameConfig?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GameConfig?>, GameConfig?>,
              AsyncValue<GameConfig?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(clearAllData)
final clearAllDataProvider = ClearAllDataProvider._();

final class ClearAllDataProvider
    extends
        $FunctionalProvider<
          Future<void> Function(),
          Future<void> Function(),
          Future<void> Function()
        >
    with $Provider<Future<void> Function()> {
  ClearAllDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clearAllDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clearAllDataHash();

  @$internal
  @override
  $ProviderElement<Future<void> Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<void> Function() create(Ref ref) {
    return clearAllData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<void> Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<void> Function()>(value),
    );
  }
}

String _$clearAllDataHash() => r'832d4722e4a303045c0c31a72f4a23da09fc72b8';
