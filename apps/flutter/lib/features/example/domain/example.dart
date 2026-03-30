import 'package:freezed_annotation/freezed_annotation.dart';

part 'example.freezed.dart';

/// Example domain model.
///
/// Domain models use freezed for value semantics and immutability.
/// No JSON serialisation here — that lives in the DTO (data layer).
@freezed
abstract class Example with _$Example {
  const factory Example({
    required String id,
    required String title,
    @Default(false) bool isCompleted,
  }) = _Example;
}
