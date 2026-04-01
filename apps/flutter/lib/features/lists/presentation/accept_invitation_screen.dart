import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../data/sharing_repository.dart';

/// Screen shown when a user opens an invitation deep link (FR16).
///
/// Route: `/invite/:token` (top-level, no shell chrome).
/// Fetches invitation details, shows list name and inviter name,
/// then accepts or declines.
class AcceptInvitationScreen extends ConsumerStatefulWidget {
  const AcceptInvitationScreen({required this.token, super.key});

  final String token;

  @override
  ConsumerState<AcceptInvitationScreen> createState() =>
      _AcceptInvitationScreenState();
}

class _AcceptInvitationScreenState
    extends ConsumerState<AcceptInvitationScreen> {
  // Invitation details loaded on init
  String? _listTitle;
  String? _inviterName;
  bool _isLoading = true;
  bool _isExpired = false;
  bool _isAccepting = false;
  bool _isDeclining = false;

  @override
  void initState() {
    super.initState();
    _loadInvitationDetails();
  }

  Future<void> _loadInvitationDetails() async {
    try {
      final repo = ref.read(sharingRepositoryProvider);
      final details = await repo.getInvitationDetails(widget.token);
      if (mounted) {
        setState(() {
          _listTitle = details.listTitle;
          _inviterName = details.inviterName;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isExpired = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptInvitation() async {
    setState(() => _isAccepting = true);
    try {
      final repo = ref.read(sharingRepositoryProvider);
      await repo.acceptInvitation(widget.token);
      if (mounted) {
        // FR86: if not yet subscribed, route to onboarding/trial path.
        // Stub: always navigate to /lists.
        context.go('/lists');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isAccepting = false);
      }
    }
  }

  Future<void> _declineInvitation() async {
    setState(() => _isDeclining = true);
    try {
      final repo = ref.read(sharingRepositoryProvider);
      await repo.declineInvitation(widget.token);
      if (mounted) {
        context.go('/lists');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isDeclining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surfacePrimary,
        middle: const Text(AppStrings.inviteAcceptTitle),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _isExpired
                ? _buildExpiredState(context, colors)
                : _buildInvitationContent(context, colors),
      ),
    );
  }

  Widget _buildExpiredState(BuildContext context, OnTaskColors colors) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 56,
            color: colors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppStrings.inviteExpiredMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: () => context.go('/lists'),
              child: const Text(AppStrings.inviteGoToLists),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationContent(BuildContext context, OnTaskColors colors) {
    final subtitle = AppStrings.inviteAcceptSubtitle
        .replaceAll('{inviterName}', _inviterName ?? '');

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // List name
          Text(
            _listTitle ?? '',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: colors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),

          // "Invited by {name}"
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.xxxl),

          // Accept button
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: (_isAccepting || _isDeclining) ? null : _acceptInvitation,
              child: Text(
                _isAccepting
                    ? AppStrings.submittingIndicator
                    : AppStrings.inviteAcceptButton,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Decline button
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              onPressed: (_isAccepting || _isDeclining) ? null : _declineInvitation,
              child: Text(
                _isDeclining
                    ? AppStrings.submittingIndicator
                    : AppStrings.inviteDeclineButton,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
