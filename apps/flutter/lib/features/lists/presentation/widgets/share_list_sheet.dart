import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../lists/data/sharing_repository.dart';

/// Modal bottom sheet for inviting someone to share a list (FR15).
///
/// Presents an email input and "Send invitation" button.
/// On success, shows an inline success message.
/// On error, shows an inline error message.
class ShareListSheet extends ConsumerStatefulWidget {
  const ShareListSheet({
    required this.listId,
    required this.listTitle,
    super.key,
  });

  final String listId;
  final String listTitle;

  @override
  ConsumerState<ShareListSheet> createState() => _ShareListSheetState();
}

class _ShareListSheetState extends ConsumerState<ShareListSheet> {
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final trimmed = email.trim();
    return trimmed.contains('@') && trimmed.contains('.');
  }

  Future<void> _sendInvitation() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !_isValidEmail(email)) {
      setState(() {
        _errorMessage = AppStrings.shareListErrorInvalidEmail;
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final repo = ref.read(sharingRepositoryProvider);
      await repo.shareList(widget.listId, email);
      if (mounted) {
        setState(() {
          _successMessage = AppStrings.shareListSuccessMessage
              .replaceAll('{email}', email);
          _emailController.clear();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = AppStrings.shareListErrorGeneric;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.lg),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: AppSpacing.xxxl,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              Text(
                AppStrings.shareListTitle,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: colors.textPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.listTitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Email input
              CupertinoTextField(
                controller: _emailController,
                placeholder: AppStrings.shareListEmailPlaceholder,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofocus: true,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.textPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Inline success message
              if (_successMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    _successMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.accentCompletion,
                        ),
                  ),
                ),

              // Inline error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.scheduleCritical,
                        ),
                  ),
                ),

              const SizedBox(height: AppSpacing.md),

              // Send button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: _isSubmitting ? null : _sendInvitation,
                  child: Text(
                    _isSubmitting
                        ? AppStrings.submittingIndicator
                        : AppStrings.shareListSendButton,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
