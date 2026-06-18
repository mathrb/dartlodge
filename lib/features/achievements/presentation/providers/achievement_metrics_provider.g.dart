// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement_metrics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The per-player achievement metric bundle (#526), mapping the statistics-owned
/// record from `achievementMetricsForPlayer` into the achievements domain
/// `AchievementMetrics` (statistics stays free of an achievements import).

@ProviderFor(achievementMetrics)
final achievementMetricsProvider = AchievementMetricsFamily._();

/// The per-player achievement metric bundle (#526), mapping the statistics-owned
/// record from `achievementMetricsForPlayer` into the achievements domain
/// `AchievementMetrics` (statistics stays free of an achievements import).

final class AchievementMetricsProvider
    extends
        $FunctionalProvider<
          AsyncValue<AchievementMetrics>,
          AchievementMetrics,
          FutureOr<AchievementMetrics>
        >
    with
        $FutureModifier<AchievementMetrics>,
        $FutureProvider<AchievementMetrics> {
  /// The per-player achievement metric bundle (#526), mapping the statistics-owned
  /// record from `achievementMetricsForPlayer` into the achievements domain
  /// `AchievementMetrics` (statistics stays free of an achievements import).
  AchievementMetricsProvider._({
    required AchievementMetricsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'achievementMetricsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$achievementMetricsHash();

  @override
  String toString() {
    return r'achievementMetricsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<AchievementMetrics> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AchievementMetrics> create(Ref ref) {
    final argument = this.argument as String;
    return achievementMetrics(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AchievementMetricsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$achievementMetricsHash() =>
    r'86196dff9df936a03de7d137c1c945ab845d50ba';

/// The per-player achievement metric bundle (#526), mapping the statistics-owned
/// record from `achievementMetricsForPlayer` into the achievements domain
/// `AchievementMetrics` (statistics stays free of an achievements import).

final class AchievementMetricsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<AchievementMetrics>, String> {
  AchievementMetricsFamily._()
    : super(
        retry: null,
        name: r'achievementMetricsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The per-player achievement metric bundle (#526), mapping the statistics-owned
  /// record from `achievementMetricsForPlayer` into the achievements domain
  /// `AchievementMetrics` (statistics stays free of an achievements import).

  AchievementMetricsProvider call(String playerId) =>
      AchievementMetricsProvider._(argument: playerId, from: this);

  @override
  String toString() => r'achievementMetricsProvider';
}
