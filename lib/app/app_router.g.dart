// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RouterNotifier)
final routerProvider = RouterNotifierProvider._();

final class RouterNotifierProvider
    extends $NotifierProvider<RouterNotifier, GoRouter> {
  RouterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routerNotifierHash();

  @$internal
  @override
  RouterNotifier create() => RouterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$routerNotifierHash() => r'92895854c3f3fdb8839bb30060763054b69d071f';

abstract class _$RouterNotifier extends $Notifier<GoRouter> {
  GoRouter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<GoRouter, GoRouter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GoRouter, GoRouter>,
              GoRouter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
