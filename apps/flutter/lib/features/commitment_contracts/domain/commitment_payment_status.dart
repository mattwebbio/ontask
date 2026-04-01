import 'package:freezed_annotation/freezed_annotation.dart';

part 'commitment_payment_status.freezed.dart';

/// Domain model for the current user's payment method status.
///
/// Returned by GET /v1/payment-method and POST /v1/payment-method/confirm.
/// Used in [PaymentSettingsScreen] to show stored method details or the
/// "Set up payment method" CTA (FR23, FR64).
@freezed
abstract class CommitmentPaymentStatus with _$CommitmentPaymentStatus {
  const factory CommitmentPaymentStatus({
    required bool hasPaymentMethod,
    String? last4,
    String? brand,
    required bool hasActiveStakes,
  }) = _CommitmentPaymentStatus;
}
