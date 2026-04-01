import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../domain/charity_selection.dart';
import '../domain/commitment_payment_status.dart';
import '../domain/impact_milestone.dart';
import '../domain/impact_summary.dart';
import '../domain/nonprofit.dart';
import '../domain/task_stake.dart';

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

  // ── Stake methods (FR22, Story 6.2) ────────────────────────────────────────

  /// Fetches the current stake amount for a task.
  ///
  /// `GET /v1/tasks/:taskId/stake`
  Future<TaskStake> getTaskStake(String taskId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/v1/tasks/$taskId/stake',
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return TaskStake(
      taskId: data['taskId'] as String,
      stakeAmountCents: data['stakeAmountCents'] as int?,
    );
  }

  /// Sets or updates the stake amount on a task.
  ///
  /// `PUT /v1/tasks/:taskId/stake`
  /// Throws [DioException] with status 422 if no payment method is stored.
  Future<TaskStake> setTaskStake(String taskId, int stakeAmountCents) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      '/v1/tasks/$taskId/stake',
      data: {'taskId': taskId, 'stakeAmountCents': stakeAmountCents},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return TaskStake(
      taskId: data['taskId'] as String,
      stakeAmountCents: data['stakeAmountCents'] as int?,
    );
  }

  /// Removes the stake from a task.
  ///
  /// `DELETE /v1/tasks/:taskId/stake`
  Future<void> removeTaskStake(String taskId) async {
    await _client.dio.delete<Map<String, dynamic>>(
      '/v1/tasks/$taskId/stake',
    );
  }

  // ── Charity methods (FR26, Story 6.3) ───────────────────────────────────────

  /// Searches or browses nonprofits from the Every.org catalog.
  ///
  /// `GET /v1/charities`
  /// Pass [query] to search by name; pass [category] to filter by category.
  /// Omit both to load the default catalog.
  Future<List<Nonprofit>> searchCharities({
    String? query,
    String? category,
  }) async {
    final queryParams = <String, String>{
      if (query != null) 'search': query,
      if (category != null) 'category': category,
    };
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/v1/charities',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    final list = data['nonprofits'] as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return Nonprofit(
        id: m['id'] as String,
        name: m['name'] as String,
        description: m['description'] as String?,
        logoUrl: m['logoUrl'] as String?,
        categories: (m['categories'] as List<dynamic>).cast<String>(),
      );
    }).toList();
  }

  /// Fetches the user's current default charity.
  ///
  /// `GET /v1/charities/default`
  Future<CharitySelection> getDefaultCharity() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/v1/charities/default',
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return CharitySelection(
      charityId: data['charityId'] as String?,
      charityName: data['charityName'] as String?,
    );
  }

  /// Sets the user's default charity.
  ///
  /// `PUT /v1/charities/default`
  Future<CharitySelection> setDefaultCharity(
    String charityId,
    String charityName,
  ) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      '/v1/charities/default',
      data: {'charityId': charityId, 'charityName': charityName},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return CharitySelection(
      charityId: data['charityId'] as String?,
      charityName: data['charityName'] as String?,
    );
  }
  // ── Impact methods (FR27, Story 6.4) ────────────────────────────────────────

  /// Fetches the authenticated user's aggregated impact summary.
  ///
  /// `GET /v1/impact`
  /// Returns total donated, commitments kept/missed, charity breakdown,
  /// and earned milestones. Stub implementation in Story 6.4 — real aggregation
  /// deferred until Story 6.5 (Automated Charge Processing).
  Future<ImpactSummary> getImpactSummary() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/v1/impact',
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    final milestones = (data['milestones'] as List<dynamic>).map((e) {
      final m = e as Map<String, dynamic>;
      return ImpactMilestone(
        id: m['id'] as String,
        title: m['title'] as String,
        body: m['body'] as String,
        earnedAt: DateTime.parse(m['earnedAt'] as String),
        shareText: m['shareText'] as String,
      );
    }).toList();
    final breakdown = (data['charityBreakdown'] as List<dynamic>).map((e) {
      final m = e as Map<String, dynamic>;
      return CharityDonation(
        charityName: m['charityName'] as String,
        donatedCents: m['donatedCents'] as int,
      );
    }).toList();
    return ImpactSummary(
      totalDonatedCents: data['totalDonatedCents'] as int,
      commitmentsKept: data['commitmentsKept'] as int,
      commitmentsMissed: data['commitmentsMissed'] as int,
      charityBreakdown: breakdown,
      milestones: milestones,
    );
  }
}

/// Riverpod provider for [CommitmentContractsRepository].
@riverpod
CommitmentContractsRepository commitmentContractsRepository(Ref ref) {
  final client = ref.watch(apiClientProvider);
  return CommitmentContractsRepository(client);
}
