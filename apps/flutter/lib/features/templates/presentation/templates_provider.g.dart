// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'templates_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier managing the user's template library.
///
/// Exposes load, create, apply, delete methods.
/// Returns `AsyncValue<List<Template>>`.

@ProviderFor(TemplatesNotifier)
final templatesProvider = TemplatesNotifierProvider._();

/// Notifier managing the user's template library.
///
/// Exposes load, create, apply, delete methods.
/// Returns `AsyncValue<List<Template>>`.
final class TemplatesNotifierProvider
    extends $AsyncNotifierProvider<TemplatesNotifier, List<Template>> {
  /// Notifier managing the user's template library.
  ///
  /// Exposes load, create, apply, delete methods.
  /// Returns `AsyncValue<List<Template>>`.
  TemplatesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'templatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$templatesNotifierHash();

  @$internal
  @override
  TemplatesNotifier create() => TemplatesNotifier();
}

String _$templatesNotifierHash() => r'74cc0b6bbc4d7048b230d29cade0deae8ff378b5';

/// Notifier managing the user's template library.
///
/// Exposes load, create, apply, delete methods.
/// Returns `AsyncValue<List<Template>>`.

abstract class _$TemplatesNotifier extends $AsyncNotifier<List<Template>> {
  FutureOr<List<Template>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Template>>, List<Template>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Template>>, List<Template>>,
              AsyncValue<List<Template>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
