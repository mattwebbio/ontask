import 'package:freezed_annotation/freezed_annotation.dart';

part 'billing_entry.freezed.dart';

/// Represents a single billing history entry for a user's charge or cancellation.
///
/// Used in the Billing History screen (Settings → Payments → Billing History).
/// Charged and pending entries have amountCents and charityName set.
/// Cancelled entries have amountCents=null, disbursementStatus='cancelled', and charityName=null.
@freezed
abstract class BillingEntry with _$BillingEntry {
  const factory BillingEntry({
    required String id,
    required String taskName,
    required DateTime date,
    int? amountCents,
    required String disbursementStatus, // 'pending' | 'completed' | 'failed' | 'cancelled'
    String? charityName,
  }) = _BillingEntry;
}
