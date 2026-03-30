// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Root application router.
///
/// Routes are expanded in later stories (1.6 tab shell, 1.7 macOS layout,
/// 1.8 auth). For now a single placeholder route at '/' keeps the app
/// navigable without referencing yet-to-be-built screens.

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// Root application router.
///
/// Routes are expanded in later stories (1.6 tab shell, 1.7 macOS layout,
/// 1.8 auth). For now a single placeholder route at '/' keeps the app
/// navigable without referencing yet-to-be-built screens.

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// Root application router.
  ///
  /// Routes are expanded in later stories (1.6 tab shell, 1.7 macOS layout,
  /// 1.8 auth). For now a single placeholder route at '/' keeps the app
  /// navigable without referencing yet-to-be-built screens.
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'5174a444e795da9963b04ad7ef04397c53028a2e';
