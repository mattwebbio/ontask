import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/example.dart';

part 'example_dto.freezed.dart';
part 'example_dto.g.dart';

/// Data-transfer object for an Example returned by the API.
///
/// Handles JSON deserialization. Maps to/from the domain [Example] model.
/// DTOs use plain freezed data classes — NOT union/sealed types (ARCH-19).
@freezed
abstract class ExampleDto with _$ExampleDto {
  const ExampleDto._();

  const factory ExampleDto({
    required String id,
    required String title,
    @Default(false) bool isCompleted,
  }) = _ExampleDto;

  factory ExampleDto.fromJson(Map<String, dynamic> json) =>
      _$ExampleDtoFromJson(json);

  /// Maps this DTO to the domain model.
  Example toDomain() => Example(
        id: id,
        title: title,
        isCompleted: isCompleted,
      );
}
