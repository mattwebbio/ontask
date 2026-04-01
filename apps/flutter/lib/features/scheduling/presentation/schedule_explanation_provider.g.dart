// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_explanation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider that fetches the scheduling explanation for a given task.
///
/// Calls [SchedulingRepository.getScheduleExplanation] for the given [taskId].
/// Auto-disposes when the widget is removed — per-entity providers should not
/// be kept alive.

@ProviderFor(scheduleExplanation)
final scheduleExplanationProvider = ScheduleExplanationFamily._();

/// Provider that fetches the scheduling explanation for a given task.
///
/// Calls [SchedulingRepository.getScheduleExplanation] for the given [taskId].
/// Auto-disposes when the widget is removed — per-entity providers should not
/// be kept alive.

final class ScheduleExplanationProvider
    extends
        $FunctionalProvider<
          AsyncValue<ScheduleExplanation>,
          ScheduleExplanation,
          FutureOr<ScheduleExplanation>
        >
    with
        $FutureModifier<ScheduleExplanation>,
        $FutureProvider<ScheduleExplanation> {
  /// Provider that fetches the scheduling explanation for a given task.
  ScheduleExplanationProvider._({
    required ScheduleExplanationFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'scheduleExplanationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$scheduleExplanationHash();

  @override
  String toString() {
    return r'scheduleExplanationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ScheduleExplanation> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ScheduleExplanation> create(Ref ref) {
    final argument = this.argument as String;
    return scheduleExplanation(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ScheduleExplanationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$scheduleExplanationHash() => r'b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1';

/// Provider that fetches the scheduling explanation for a given task.

final class ScheduleExplanationFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ScheduleExplanation>, String> {
  ScheduleExplanationFamily._()
    : super(
        retry: null,
        name: r'scheduleExplanationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider that fetches the scheduling explanation for a given task.

  ScheduleExplanationProvider call(String taskId) =>
      ScheduleExplanationProvider._(argument: taskId, from: this);

  @override
  String toString() => r'scheduleExplanationProvider';
}
