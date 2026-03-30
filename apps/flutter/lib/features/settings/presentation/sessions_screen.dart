import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../data/settings_repository.dart';
import '../domain/session_model.dart';

/// Settings → Security → Active Sessions screen.
///
/// Shows a list of authenticated sessions. Each entry displays:
///   - Device name (bold)
///   - Approximate location + last-active timestamp (secondary)
///   - "This device" badge for the current session (AC #2)
///   - "Sign out this device" destructive button for non-current sessions (AC #3)
///
/// Tapping "Sign out this device" shows a [CupertinoAlertDialog] confirmation.
/// On confirmation, calls `DELETE /v1/auth/sessions/:sessionId` and removes the
/// session from the list on success (optimistic update). Error is surfaced in
/// plain language via [AppStrings.sessionsSignOutErrorMessage] (NFR-UX2).
class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  // Tracks sessions being revoked (shows loading indicator on the row).
  final Set<String> _revoking = {};

  Future<void> _confirmSignOut(SessionModel session) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(AppStrings.sessionsSignOutConfirmTitle),
        content: Text(AppStrings.sessionsSignOutConfirmMessage),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.sessionsSignOutCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.sessionsSignOutConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _revoking.add(session.sessionId));

    try {
      await ref
          .read(settingsRepositoryProvider)
          .deleteSession(session.sessionId);
      if (mounted) {
        ref.invalidate(activeSessionsProvider);
      }
    } catch (_) {
      if (mounted) {
        _showError();
      }
    } finally {
      if (mounted) {
        setState(() => _revoking.remove(session.sessionId));
      }
    }
  }

  void _showError() {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Text(AppStrings.sessionsSignOutErrorMessage),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.sessionsSignOutCancel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final sessionsAsync = ref.watch(activeSessionsProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(AppStrings.sessionsTitle),
        backgroundColor: colors.surfacePrimary,
      ),
      backgroundColor: colors.surfacePrimary,
      child: SafeArea(
        child: sessionsAsync.when(
          data: (sessions) => _buildSessionsList(sessions, colors),
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => Center(
            child: Text(
              AppStrings.sessionsSignOutErrorMessage,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionsList(List<SessionModel> sessions, OnTaskColors colors) {
    return ListView.builder(
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _SessionRow(
          session: session,
          isRevoking: _revoking.contains(session.sessionId),
          onSignOut: () => _confirmSignOut(session),
        );
      },
    );
  }
}

// ── Session Row ──────────────────────────────────────────────────────────────

/// A single session row.
///
/// Displays device name, location, last-active timestamp, and a "This device"
/// badge or "Sign out this device" button.
class _SessionRow extends StatelessWidget {
  final SessionModel session;
  final bool isRevoking;
  final VoidCallback onSignOut;

  const _SessionRow({
    required this.session,
    required this.isRevoking,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.surfaceSecondary, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.deviceName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${session.location} · '
                  '${AppStrings.sessionsLastActive} '
                  '${_formatLastActive(session.lastActiveAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (session.isCurrentDevice)
            _CurrentDeviceBadge(colors: colors)
          else if (isRevoking)
            const CupertinoActivityIndicator()
          else
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onSignOut,
              child: Text(
                AppStrings.sessionsSignOut,
                style: const TextStyle(
                  color: CupertinoColors.destructiveRed,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatLastActive(DateTime lastActiveAt) {
    final now = DateTime.now();
    final diff = now.difference(lastActiveAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Current Device Badge ─────────────────────────────────────────────────────

class _CurrentDeviceBadge extends StatelessWidget {
  final OnTaskColors colors;

  const _CurrentDeviceBadge({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.accentCompletion.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        AppStrings.sessionsCurrentDevice,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.accentCompletion,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
