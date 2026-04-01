import 'package:freezed_annotation/freezed_annotation.dart';

part 'nonprofit.freezed.dart';

/// Domain model for a nonprofit from the Every.org catalog (FR26).
///
/// [id] is the Every.org slug (e.g. 'american-red-cross').
/// [logoUrl] may be null if the nonprofit has no logo in the catalog.
/// [categories] is empty by default.
@freezed
abstract class Nonprofit with _$Nonprofit {
  const factory Nonprofit({
    required String id,
    required String name,
    String? description,
    String? logoUrl,
    @Default([]) List<String> categories,
  }) = _Nonprofit;
}
