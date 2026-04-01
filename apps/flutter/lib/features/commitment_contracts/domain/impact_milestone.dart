import 'package:freezed_annotation/freezed_annotation.dart';

part 'impact_milestone.freezed.dart';

/// Domain model for a single earned impact milestone (FR27, UX-DR19).
///
/// Milestones represent meaningful achievements using "evidence of who you've
/// become" framing — not a raw stats list. Examples: first donation, first
/// commitment kept, $100 total donated.
///
/// [title] and [body] are affirming — no punitive language (UX-DR36).
/// Even for missed-commitment milestones the copy is warm and courageous.
@freezed
abstract class ImpactMilestone with _$ImpactMilestone {
  const factory ImpactMilestone({
    required String id,
    required String title,
    required String body,
    required DateTime earnedAt,
    required String shareText,
  }) = _ImpactMilestone;
}
