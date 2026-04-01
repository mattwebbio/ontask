import 'package:freezed_annotation/freezed_annotation.dart';

import 'impact_milestone.dart';

part 'impact_summary.freezed.dart';

/// Breakdown of how much was donated to a specific charity.
@freezed
abstract class CharityDonation with _$CharityDonation {
  const factory CharityDonation({
    required String charityName,
    required int donatedCents,
  }) = _CharityDonation;
}

/// Aggregated impact summary for the authenticated user (FR27, UX-DR19).
///
/// Primary display values are [commitmentsKept] and [totalDonatedCents].
/// [charityBreakdown] and detailed stats are secondary information.
/// [milestones] are the "evidence of who you've become" cells.
@freezed
abstract class ImpactSummary with _$ImpactSummary {
  const factory ImpactSummary({
    required int totalDonatedCents,
    required int commitmentsKept,
    required int commitmentsMissed,
    @Default([]) List<CharityDonation> charityBreakdown,
    @Default([]) List<ImpactMilestone> milestones,
  }) = _ImpactSummary;
}
