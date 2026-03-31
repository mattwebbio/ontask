// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prediction_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for task predicted completion.
///
/// Auto-invalidates every 30 seconds to simulate real-time updates (AC3).
/// In production, the scheduling engine pushes invalidations directly.
/// The timer approach is forward-compatible with that design.
///
/// Does NOT use keepAlive — per-entity providers dispose when the widget unmounts.

@ProviderFor(taskPrediction)
final taskPredictionProvider = TaskPredictionFamily._();

/// Provider for task predicted completion.
///
/// Auto-invalidates every 30 seconds to simulate real-time updates (AC3).
/// In production, the scheduling engine pushes invalidations directly.
/// The timer approach is forward-compatible with that design.
///
/// Does NOT use keepAlive — per-entity providers dispose when the widget unmounts.

final class TaskPredictionProvider
    extends
        $FunctionalProvider<
          AsyncValue<CompletionPrediction>,
          CompletionPrediction,
          FutureOr<CompletionPrediction>
        >
    with
        $FutureModifier<CompletionPrediction>,
        $FutureProvider<CompletionPrediction> {
  /// Provider for task predicted completion.
  ///
  /// Auto-invalidates every 30 seconds to simulate real-time updates (AC3).
  /// In production, the scheduling engine pushes invalidations directly.
  /// The timer approach is forward-compatible with that design.
  ///
  /// Does NOT use keepAlive — per-entity providers dispose when the widget unmounts.
  TaskPredictionProvider._({
    required TaskPredictionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'taskPredictionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$taskPredictionHash();

  @override
  String toString() {
    return r'taskPredictionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CompletionPrediction> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CompletionPrediction> create(Ref ref) {
    final argument = this.argument as String;
    return taskPrediction(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TaskPredictionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$taskPredictionHash() => r'1f3ff1028c128264d6c59a639b51ab4252b3d6c1';

/// Provider for task predicted completion.
///
/// Auto-invalidates every 30 seconds to simulate real-time updates (AC3).
/// In production, the scheduling engine pushes invalidations directly.
/// The timer approach is forward-compatible with that design.
///
/// Does NOT use keepAlive — per-entity providers dispose when the widget unmounts.

final class TaskPredictionFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CompletionPrediction>, String> {
  TaskPredictionFamily._()
    : super(
        retry: null,
        name: r'taskPredictionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for task predicted completion.
  ///
  /// Auto-invalidates every 30 seconds to simulate real-time updates (AC3).
  /// In production, the scheduling engine pushes invalidations directly.
  /// The timer approach is forward-compatible with that design.
  ///
  /// Does NOT use keepAlive — per-entity providers dispose when the widget unmounts.

  TaskPredictionProvider call(String taskId) =>
      TaskPredictionProvider._(argument: taskId, from: this);

  @override
  String toString() => r'taskPredictionProvider';
}

/// Provider for list predicted completion.
///
/// Auto-invalidates every 30 seconds to simulate real-time updates (AC3).

@ProviderFor(listPrediction)
final listPredictionProvider = ListPredictionFamily._();

/// Provider for list predicted completion.
///
/// Auto-invalidates every 30 seconds to simulate real-time updates (AC3).

final class ListPredictionProvider
    extends
        $FunctionalProvider<
          AsyncValue<CompletionPrediction>,
          CompletionPrediction,
          FutureOr<CompletionPrediction>
        >
    with
        $FutureModifier<CompletionPrediction>,
        $FutureProvider<CompletionPrediction> {
  /// Provider for list predicted completion.
  ///
  /// Auto-invalidates every 30 seconds to simulate real-time updates (AC3).
  ListPredictionProvider._({
    required ListPredictionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'listPredictionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$listPredictionHash();

  @override
  String toString() {
    return r'listPredictionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CompletionPrediction> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CompletionPrediction> create(Ref ref) {
    final argument = this.argument as String;
    return listPrediction(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ListPredictionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$listPredictionHash() => r'394c5fff473365953405b746279af9f7963c89df';

/// Provider for list predicted completion.
///
/// Auto-invalidates every 30 seconds to simulate real-time updates (AC3).

final class ListPredictionFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CompletionPrediction>, String> {
  ListPredictionFamily._()
    : super(
        retry: null,
        name: r'listPredictionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for list predicted completion.
  ///
  /// Auto-invalidates every 30 seconds to simulate real-time updates (AC3).

  ListPredictionProvider call(String listId) =>
      ListPredictionProvider._(argument: listId, from: this);

  @override
  String toString() => r'listPredictionProvider';
}

/// Provider for section predicted completion.
///
/// Auto-invalidates every 30 seconds to simulate real-time updates (AC3).

@ProviderFor(sectionPrediction)
final sectionPredictionProvider = SectionPredictionFamily._();

/// Provider for section predicted completion.
///
/// Auto-invalidates every 30 seconds to simulate real-time updates (AC3).

final class SectionPredictionProvider
    extends
        $FunctionalProvider<
          AsyncValue<CompletionPrediction>,
          CompletionPrediction,
          FutureOr<CompletionPrediction>
        >
    with
        $FutureModifier<CompletionPrediction>,
        $FutureProvider<CompletionPrediction> {
  /// Provider for section predicted completion.
  ///
  /// Auto-invalidates every 30 seconds to simulate real-time updates (AC3).
  SectionPredictionProvider._({
    required SectionPredictionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sectionPredictionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sectionPredictionHash();

  @override
  String toString() {
    return r'sectionPredictionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CompletionPrediction> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CompletionPrediction> create(Ref ref) {
    final argument = this.argument as String;
    return sectionPrediction(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SectionPredictionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sectionPredictionHash() => r'614c823fbbd186f861bfc4fc751d4e288d4bcd55';

/// Provider for section predicted completion.
///
/// Auto-invalidates every 30 seconds to simulate real-time updates (AC3).

final class SectionPredictionFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CompletionPrediction>, String> {
  SectionPredictionFamily._()
    : super(
        retry: null,
        name: r'sectionPredictionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for section predicted completion.
  ///
  /// Auto-invalidates every 30 seconds to simulate real-time updates (AC3).

  SectionPredictionProvider call(String sectionId) =>
      SectionPredictionProvider._(argument: sectionId, from: this);

  @override
  String toString() => r'sectionPredictionProvider';
}
