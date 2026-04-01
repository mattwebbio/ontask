import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../data/commitment_contracts_repository.dart';
import '../domain/impact_summary.dart';
import 'widgets/impact_milestone_cell.dart';

/// Impact Dashboard screen — accessible from Settings (profile icon).
///
/// Displays the user's impact using "evidence of who you've become" framing
/// (FR27, UX-DR19). Shows:
/// - Primary stat cells: commitments kept (large number) + total donated
/// - Milestone cells: meaningful earned milestones with share affordance
/// - Charity breakdown: secondary information
///
/// Design rules (UX-DR19):
/// - NO progress bars
/// - NO percentage-to-goal
/// - NO streak mechanics
/// - Milestones accumulate and never reset
/// - Copy is affirming even for missed commitments (UX-DR36)
///
/// Routed as `/settings/impact` (sub-route of settings branch in [AppRouter]).
class ImpactDashboardScreen extends ConsumerStatefulWidget {
  const ImpactDashboardScreen({super.key});

  @override
  ConsumerState<ImpactDashboardScreen> createState() =>
      _ImpactDashboardScreenState();
}

class _ImpactDashboardScreenState
    extends ConsumerState<ImpactDashboardScreen> {
  ImpactSummary? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImpact();
  }

  Future<void> _loadImpact() async {
    setState(() => _isLoading = true);
    try {
      final repository =
          ref.read(commitmentContractsRepositoryProvider);
      final summary = await repository.getImpactSummary();
      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        await showCupertinoDialog<void>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(AppStrings.dialogErrorTitle),
            content: Text(AppStrings.impactLoadError),
            actions: [
              CupertinoDialogAction(
                child: Text(AppStrings.actionOk),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(AppStrings.impactDashboardTitle),
        backgroundColor: colors.surfacePrimary,
      ),
      backgroundColor: colors.surfacePrimary,
      child: SafeArea(
        child: _buildBody(colors),
      ),
    );
  }

  Widget _buildBody(OnTaskColors colors) {
    // Loading state
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    // Empty state — summary loaded but no milestones yet
    if (_summary != null && _summary!.milestones.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            AppStrings.impactEmptyMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NewYork',
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: colors.textSecondary,
            ),
          ),
        ),
      );
    }

    // Loaded state with content
    if (_summary == null) {
      return const SizedBox.shrink();
    }

    final summary = _summary!;

    return ListView(
      children: [
        // ── Primary stat cells ──────────────────────────────────────────────
        _StatCell(
          value: summary.commitmentsKept.toString(),
          label: AppStrings.impactCommitmentsKeptLabel,
          colors: colors,
        ),
        _StatCell(
          value: '\$${summary.totalDonatedCents ~/ 100}',
          label: AppStrings.impactTotalDonatedLabel,
          colors: colors,
        ),

        // ── Milestone cells ─────────────────────────────────────────────────
        for (final milestone in summary.milestones)
          ImpactMilestoneCell(
            milestone: milestone,
            onShare: () => Share.share(milestone.shareText),
          ),

        // ── Charity breakdown section ───────────────────────────────────────
        if (summary.charityBreakdown.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              AppStrings.impactCharityBreakdownTitle,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final entry in summary.charityBreakdown)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom:
                      BorderSide(color: colors.surfaceSecondary, width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.charityName,
                    style: const TextStyle(fontSize: 15),
                  ),
                  Text(
                    '\$${(entry.donatedCents / 100).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 15,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

/// Full-width primary stat cell — large number in New York serif + SF Pro label.
class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.colors,
  });

  final String value;
  final String label;
  final OnTaskColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.surfaceSecondary, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large stat number — New York 34pt Regular
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'NewYork',
              fontSize: 34,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 2),
          // Stat label — SF Pro 13pt textSecondary
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
