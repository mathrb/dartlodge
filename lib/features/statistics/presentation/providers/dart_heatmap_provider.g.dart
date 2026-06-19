// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dart_heatmap_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dartHeatmap)
final dartHeatmapProvider = DartHeatmapFamily._();

final class DartHeatmapProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DartPosition>>,
          List<DartPosition>,
          FutureOr<List<DartPosition>>
        >
    with
        $FutureModifier<List<DartPosition>>,
        $FutureProvider<List<DartPosition>> {
  DartHeatmapProvider._({
    required DartHeatmapFamily super.from,
    required DartHeatmapFilter super.argument,
  }) : super(
         retry: null,
         name: r'dartHeatmapProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dartHeatmapHash();

  @override
  String toString() {
    return r'dartHeatmapProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<DartPosition>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DartPosition>> create(Ref ref) {
    final argument = this.argument as DartHeatmapFilter;
    return dartHeatmap(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DartHeatmapProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dartHeatmapHash() => r'b3eaf2e033d6931b5f18627b624d0bff785fd3f2';

final class DartHeatmapFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<DartPosition>>,
          DartHeatmapFilter
        > {
  DartHeatmapFamily._()
    : super(
        retry: null,
        name: r'dartHeatmapProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DartHeatmapProvider call(DartHeatmapFilter filter) =>
      DartHeatmapProvider._(argument: filter, from: this);

  @override
  String toString() => r'dartHeatmapProvider';
}
