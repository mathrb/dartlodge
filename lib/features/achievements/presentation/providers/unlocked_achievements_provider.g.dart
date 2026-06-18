// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unlocked_achievements_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Reactive id → `unlockedAt` map for [playerId] (#526). Key presence = unlocked,
/// value = when. Backs the AchievementsPage unlocked state + the "recent first"
/// ordering.

@ProviderFor(unlockedAchievements)
final unlockedAchievementsProvider = UnlockedAchievementsFamily._();

/// Reactive id → `unlockedAt` map for [playerId] (#526). Key presence = unlocked,
/// value = when. Backs the AchievementsPage unlocked state + the "recent first"
/// ordering.

final class UnlockedAchievementsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, DateTime>>,
          Map<String, DateTime>,
          Stream<Map<String, DateTime>>
        >
    with
        $FutureModifier<Map<String, DateTime>>,
        $StreamProvider<Map<String, DateTime>> {
  /// Reactive id → `unlockedAt` map for [playerId] (#526). Key presence = unlocked,
  /// value = when. Backs the AchievementsPage unlocked state + the "recent first"
  /// ordering.
  UnlockedAchievementsProvider._({
    required UnlockedAchievementsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'unlockedAchievementsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$unlockedAchievementsHash();

  @override
  String toString() {
    return r'unlockedAchievementsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Map<String, DateTime>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, DateTime>> create(Ref ref) {
    final argument = this.argument as String;
    return unlockedAchievements(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UnlockedAchievementsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$unlockedAchievementsHash() =>
    r'670b35dcccf6a3931665a320455f2ac6644bef98';

/// Reactive id → `unlockedAt` map for [playerId] (#526). Key presence = unlocked,
/// value = when. Backs the AchievementsPage unlocked state + the "recent first"
/// ordering.

final class UnlockedAchievementsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Map<String, DateTime>>, String> {
  UnlockedAchievementsFamily._()
    : super(
        retry: null,
        name: r'unlockedAchievementsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Reactive id → `unlockedAt` map for [playerId] (#526). Key presence = unlocked,
  /// value = when. Backs the AchievementsPage unlocked state + the "recent first"
  /// ordering.

  UnlockedAchievementsProvider call(String playerId) =>
      UnlockedAchievementsProvider._(argument: playerId, from: this);

  @override
  String toString() => r'unlockedAchievementsProvider';
}
