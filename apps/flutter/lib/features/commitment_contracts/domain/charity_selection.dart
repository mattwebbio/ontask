import 'package:freezed_annotation/freezed_annotation.dart';

part 'charity_selection.freezed.dart';

/// Domain model representing a user's default charity selection.
///
/// A null [charityId] means no default charity has been set.
/// Stored per-user in [commitment_contracts] (Epic 6, Story 6.3).
@freezed
abstract class CharitySelection with _$CharitySelection {
  const factory CharitySelection({
    String? charityId,
    String? charityName,
  }) = _CharitySelection;
}
