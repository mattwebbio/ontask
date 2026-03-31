// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependencies_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier managing dependency state for a specific task.
///
/// Loads, adds, and removes dependencies via [TasksRepository].

@ProviderFor(Dependencies)
final dependenciesProvider = DependenciesFamily._();

/// Notifier managing dependency state for a specific task.
///
/// Loads, adds, and removes dependencies via [TasksRepository].
final class DependenciesProvider
    extends $AsyncNotifierProvider<Dependencies, DependencyState> {
  /// Notifier managing dependency state for a specific task.
  ///
  /// Loads, adds, and removes dependencies via [TasksRepository].
  DependenciesProvider._({
    required DependenciesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'dependenciesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dependenciesHash();

  @override
  String toString() {
    return r'dependenciesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  Dependencies create() => Dependencies();

  @override
  bool operator ==(Object other) {
    return other is DependenciesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dependenciesHash() => r'47aefac57673f995b0952eb13bd32e90798a8498';

/// Notifier managing dependency state for a specific task.
///
/// Loads, adds, and removes dependencies via [TasksRepository].

final class DependenciesFamily extends $Family
    with
        $ClassFamilyOverride<
          Dependencies,
          AsyncValue<DependencyState>,
          DependencyState,
          FutureOr<DependencyState>,
          String
        > {
  DependenciesFamily._()
    : super(
        retry: null,
        name: r'dependenciesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Notifier managing dependency state for a specific task.
  ///
  /// Loads, adds, and removes dependencies via [TasksRepository].

  DependenciesProvider call({required String taskId}) =>
      DependenciesProvider._(argument: taskId, from: this);

  @override
  String toString() => r'dependenciesProvider';
}

/// Notifier managing dependency state for a specific task.
///
/// Loads, adds, and removes dependencies via [TasksRepository].

abstract class _$Dependencies extends $AsyncNotifier<DependencyState> {
  late final _$args = ref.$arg as String;
  String get taskId => _$args;

  FutureOr<DependencyState> build({required String taskId});
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DependencyState>, DependencyState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DependencyState>, DependencyState>,
              AsyncValue<DependencyState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(taskId: _$args));
  }
}
