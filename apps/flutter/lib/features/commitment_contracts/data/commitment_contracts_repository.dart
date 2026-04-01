import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../domain/commitment_payment_status.dart';

part 'commitment_contracts_repository.g.dart';

/// Repository for payment method setup operations via the commitment contracts API.
///
/// Covers FR23 (payment method setup via Stripe SetupIntent) and
/// FR64 (view/update/remove stored payment method in Settings → Payments).
///
/// All endpoint calls are stubs in Story 6.1 — real Stripe integration deferred
/// until Story 13.1 (AASA + payment pages) is deployed.
class CommitmentContractsRepository {
  CommitmentContractsRepository(this._client);
  final ApiClient _client;

  /// Fetches the current user's stored payment method status.
  ///
  /// `GET /v1/payment-method`
  Future<CommitmentPaymentStatus> getPaymentStatus() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/v1/payment-method',
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return CommitmentPaymentStatus(
      hasPaymentMethod: data['hasPaymentMethod'] as bool,
      last4: data['paymentMethod']?['last4'] as String?,
      brand: data['paymentMethod']?['brand'] as String?,
      hasActiveStakes: data['hasActiveStakes'] as bool,
    );
  }

  /// Generates a short-lived setup session and returns the Stripe-hosted setup URL.
  ///
  /// `POST /v1/payment-method/setup-session`
  /// Returns raw map with `setupUrl` and `sessionToken`.
  Future<Map<String, dynamic>> createSetupSession() async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/v1/payment-method/setup-session',
      data: <String, dynamic>{},
    );
    return response.data!['data'] as Map<String, dynamic>;
  }

  /// Confirms the payment setup by exchanging the session token returned via Universal Link.
  ///
  /// `POST /v1/payment-method/confirm`
  /// Called after the Universal Link callback returns with `sessionToken`.
  /// TODO(impl): this will be called automatically by the AppRouter deep link handler
  /// once Story 13.1 (AASA deployment) is complete.
  Future<CommitmentPaymentStatus> confirmSetup(String sessionToken) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/v1/payment-method/confirm',
      data: {'sessionToken': sessionToken},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return CommitmentPaymentStatus(
      hasPaymentMethod: data['hasPaymentMethod'] as bool,
      last4: data['paymentMethod']?['last4'] as String?,
      brand: data['paymentMethod']?['brand'] as String?,
      hasActiveStakes: data['hasActiveStakes'] as bool,
    );
  }

  /// Removes the stored payment method.
  ///
  /// `DELETE /v1/payment-method`
  /// Throws [DioException] with status 422 if `hasActiveStakes = true`.
  Future<void> removePaymentMethod() async {
    await _client.dio.delete<Map<String, dynamic>>(
      '/v1/payment-method',
      data: <String, dynamic>{},
    );
  }
}

/// Riverpod provider for [CommitmentContractsRepository].
@riverpod
CommitmentContractsRepository commitmentContractsRepository(Ref ref) {
  final client = ref.watch(apiClientProvider);
  return CommitmentContractsRepository(client);
}
