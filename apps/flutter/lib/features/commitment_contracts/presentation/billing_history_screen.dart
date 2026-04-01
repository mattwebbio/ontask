import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../data/commitment_contracts_repository.dart';
import '../domain/billing_entry.dart';
import '../../now/presentation/widgets/commitment_row.dart';

/// Screen showing the authenticated user's billing history.
///
/// Shown as Settings → Payments → Billing History.
/// Displays charge and cancellation entries, newest first.
/// Cancelled stakes show "cancelled — no charge" with no amount.
class BillingHistoryScreen extends ConsumerStatefulWidget {
  const BillingHistoryScreen({super.key});

  @override
  ConsumerState<BillingHistoryScreen> createState() =>
      _BillingHistoryScreenState();
}

class _BillingHistoryScreenState extends ConsumerState<BillingHistoryScreen> {
  bool _isLoading = false;
  List<BillingEntry>? _billingHistory;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBillingHistory();
  }

  Future<void> _loadBillingHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final repository = ref.read(commitmentContractsRepositoryProvider);
      final history = await repository.getBillingHistory();
      setState(() {
        _billingHistory = history;
      });
    } catch (e) {
      setState(() {
        _errorMessage = AppStrings.billingHistoryLoadError;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(AppStrings.billingHistoryTitle),
        backgroundColor: colors.surfacePrimary,
      ),
      backgroundColor: colors.surfacePrimary,
      child: SafeArea(
        child: _buildBody(colors),
      ),
    );
  }

  Widget _buildBody(OnTaskColors colors) {
    if (_isLoading && _billingHistory == null) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            style: TextStyle(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final history = _billingHistory;
    if (history == null) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            AppStrings.billingHistoryEmpty,
            style: TextStyle(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      children: history.map((entry) => _BillingEntryRow(entry: entry)).toList(),
    );
  }
}

/// A single row in the billing history list.
class _BillingEntryRow extends StatelessWidget {
  const _BillingEntryRow({required this.entry});

  final BillingEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final isCancelled = entry.disbursementStatus == 'cancelled';
    final isCompleted = entry.disbursementStatus == 'completed';

    final formattedDate = DateFormat('MMM d, y').format(entry.date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Leading: date ───────────────────────────────────────────────
          SizedBox(
            width: 80,
            child: Text(
              formattedDate,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // ── Middle: task name + subtitle ────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.taskName,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isCancelled
                      ? AppStrings.billingCancelledNoCharge
                      : (entry.charityName ?? ''),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    fontStyle:
                        isCancelled ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
                const SizedBox(height: 4),
                _DisbursementBadge(
                  status: entry.disbursementStatus,
                  colors: colors,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // ── Trailing: amount ────────────────────────────────────────────
          if (!isCancelled && entry.amountCents != null)
            Text(
              CommitmentRow.formatAmount(entry.amountCents!),
              style: TextStyle(
                color: isCompleted
                    ? colors.accentCompletion
                    : colors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

/// Small disbursement status badge text.
class _DisbursementBadge extends StatelessWidget {
  const _DisbursementBadge({
    required this.status,
    required this.colors,
  });

  final String status;
  final OnTaskColors colors;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'completed' => (AppStrings.billingStatusDonated, colors.accentCompletion),
      'pending' => (AppStrings.billingStatusPending, colors.textSecondary),
      'failed' => (AppStrings.billingStatusFailed, CupertinoColors.destructiveRed),
      'cancelled' => (AppStrings.billingStatusCancelled, colors.textSecondary),
      _ => (status, colors.textSecondary),
    };

    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
