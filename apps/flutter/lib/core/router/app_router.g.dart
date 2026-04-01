// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Root application router.
///
/// Uses [StatefulShellRoute.indexedStack] (go_router ≥ 7.x, currently 15.1.x)
/// to preserve each tab's navigation state independently.
///
/// Tab branches: Now (/now), Today (/today), Add (/add — stub), Lists (/lists)
/// The Add branch is a stub; [AppShell] intercepts the tap before any navigation
/// occurs and opens [AddTabSheet] instead.
///
/// The `/auth/sign-in` route is a TOP-LEVEL route — NOT inside [StatefulShellRoute].
/// This ensures the auth screen renders without the shell (no tab bar, no sidebar).

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// Root application router.
///
/// Uses [StatefulShellRoute.indexedStack] (go_router ≥ 7.x, currently 15.1.x)
/// to preserve each tab's navigation state independently.
///
/// Tab branches: Now (/now), Today (/today), Add (/add — stub), Lists (/lists)
/// The Add branch is a stub; [AppShell] intercepts the tap before any navigation
/// occurs and opens [AddTabSheet] instead.
///
/// The `/auth/sign-in` route is a TOP-LEVEL route — NOT inside [StatefulShellRoute].
/// This ensures the auth screen renders without the shell (no tab bar, no sidebar).

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// Root application router.
  ///
  /// Uses [StatefulShellRoute.indexedStack] (go_router ≥ 7.x, currently 15.1.x)
  /// to preserve each tab's navigation state independently.
  ///
  /// Tab branches: Now (/now), Today (/today), Add (/add — stub), Lists (/lists)
  /// The Add branch is a stub; [AppShell] intercepts the tap before any navigation
  /// occurs and opens [AddTabSheet] instead.
  ///
  /// The `/auth/sign-in` route is a TOP-LEVEL route — NOT inside [StatefulShellRoute].
  /// This ensures the auth screen renders without the shell (no tab bar, no sidebar).
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

String _$appRouterHash() => r'a36d93c528570f74093f32b296ca24ebd456a64e';
