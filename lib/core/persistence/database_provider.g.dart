// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(database)
final databaseProvider = DatabaseProvider._();

final class DatabaseProvider
    extends $FunctionalProvider<AsyncValue<dynamic>, dynamic, FutureOr<dynamic>>
    with $FutureModifier<dynamic>, $FutureProvider<dynamic> {
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
  $FutureProviderElement<dynamic> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<dynamic> create(Ref ref) {
    return database(ref);
  }
}

String _$databaseHash() => r'ef53a182f91de0d4e4ceabd6c422edf7b00dddb1';

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

String _$playerRepositoryHash() => r'f2736bab1daaa1468c86204623ecb4f33324a654';

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

String _$gameRepositoryHash() => r'083e9f6689b0b7ab344b51a60ee4d6f834c54eb9';

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
    r'fdd7ab1b41f3908f909ae4fa02e1f88078fc3f80';

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
    r'8b3290749051685f2f4b24bba6f9efad955f2208';

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
    r'69351339e1646555ed4e39dd7beb944daa1c58b8';

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
    r'ce3e43ff7caec4c1884ca2731374fd3dbd8b1dee';

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

String _$createGameUseCaseHash() => r'86611391ecef89b26d6bee8e7b688815809a9146';
