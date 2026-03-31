// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sections_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier managing sections for a given list.
///
/// Exposes create, update, delete methods.

@ProviderFor(SectionsNotifier)
final sectionsProvider = SectionsNotifierFamily._();

/// Notifier managing sections for a given list.
///
/// Exposes create, update, delete methods.
final class SectionsNotifierProvider
    extends $AsyncNotifierProvider<SectionsNotifier, List<Section>> {
  /// Notifier managing sections for a given list.
  ///
  /// Exposes create, update, delete methods.
  SectionsNotifierProvider._({
    required SectionsNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sectionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sectionsNotifierHash();

  @override
  String toString() {
    return r'sectionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SectionsNotifier create() => SectionsNotifier();

  @override
  bool operator ==(Object other) {
    return other is SectionsNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sectionsNotifierHash() => r'5e4faf813ac5d780671212a9245633ca473949ba';

/// Notifier managing sections for a given list.
///
/// Exposes create, update, delete methods.

final class SectionsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SectionsNotifier,
          AsyncValue<List<Section>>,
          List<Section>,
          FutureOr<List<Section>>,
          String
        > {
  SectionsNotifierFamily._()
    : super(
        retry: null,
        name: r'sectionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Notifier managing sections for a given list.
  ///
  /// Exposes create, update, delete methods.

  SectionsNotifierProvider call(String listId) =>
      SectionsNotifierProvider._(argument: listId, from: this);

  @override
  String toString() => r'sectionsProvider';
}

/// Notifier managing sections for a given list.
///
/// Exposes create, update, delete methods.

abstract class _$SectionsNotifier extends $AsyncNotifier<List<Section>> {
  late final _$args = ref.$arg as String;
  String get listId => _$args;

  FutureOr<List<Section>> build(String listId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Section>>, List<Section>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Section>>, List<Section>>,
              AsyncValue<List<Section>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
