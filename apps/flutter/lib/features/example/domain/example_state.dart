import 'package:freezed_annotation/freezed_annotation.dart';

import 'example.dart';

part 'example_state.freezed.dart';

/// Sealed union type representing the view-state for the example feature.
///
/// ARCH RULE (ARCH-19): freezed union/sealed types live ONLY in domain/ —
/// never in data/. DTOs in data/ use plain freezed data classes.
@freezed
sealed class ExampleState with _$ExampleState {
  /// Initial state before any load attempt.
  const factory ExampleState.initial() = ExampleStateInitial;

  /// Data loaded successfully.
  const factory ExampleState.loaded({required List<Example> examples}) =
      ExampleStateLoaded;

  /// Error state.
  const factory ExampleState.error({required String message}) =
      ExampleStateError;
}
