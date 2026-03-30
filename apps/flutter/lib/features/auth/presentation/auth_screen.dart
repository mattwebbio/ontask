import 'dart:async' show unawaited;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../data/auth_repository.dart';
import '../domain/auth_result.dart';
import 'auth_provider.dart';

/// Authentication screen — shown to unauthenticated users.
///
/// Layout (top → bottom):
///   1. On Task wordmark (SF Pro 28pt, textPrimary)
///   2. Subtitle in New York serif (textSecondary) — emotional voice copy only
///   3. Sign in with Apple button (MUST be topmost sign-in option — Apple HIG)
///   4. Sign in with Google button
///   5. Email / password fields + Sign In button
///   6. Forgot password? link
///   7. Error message (when present)
///
/// Design rules:
///   - New York serif is used ONLY for the subtitle (emotional/voice copy).
///     Never in error messages, button labels, or field labels.
///   - Error messages use plain language — no error codes (NFR-UX2).
///   - Loading state replaces the active sign-in button with a spinner;
///     other sign-in options remain interactive.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// Tracks which sign-in button is currently loading.
  _LoadingAction? _loadingAction;

  /// Current error message (null = no error).
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Auth actions
  // ---------------------------------------------------------------------------

  Future<void> _signInWithApple() async {
    _clearError();
    setState(() => _loadingAction = _LoadingAction.apple);

    final result =
        await ref.read(authRepositoryProvider.notifier).signInWithApple();

    if (mounted) {
      setState(() => _loadingAction = null);
      _handleResult(result, provider: 'apple');
    }
  }

  Future<void> _signInWithGoogle() async {
    _clearError();
    setState(() => _loadingAction = _LoadingAction.google);

    final result =
        await ref.read(authRepositoryProvider.notifier).signInWithGoogle();

    if (mounted) {
      setState(() => _loadingAction = null);
      _handleResult(result, provider: 'google');
    }
  }

  Future<void> _signInWithEmail() async {
    _clearError();
    setState(() => _loadingAction = _LoadingAction.email);

    final result = await ref.read(authRepositoryProvider.notifier).signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (mounted) {
      setState(() => _loadingAction = null);
      _handleResult(result, provider: 'email');
    }
  }

  void _handleResult(AuthResult result, {required String provider}) {
    switch (result) {
      case Authenticated(:final userId):
        unawaited(
          ref.read(authStateProvider.notifier).setAuthenticated(
            userId,
            provider: provider,
          ),
        );
      case Unauthenticated():
        // User cancelled — no error needed.
        break;
      case AuthError(:final message):
        setState(() => _errorMessage = message);
      case TwoFactorRequired(:final tempToken):
        // Email login returned a 2FA challenge — transition state so the router
        // redirects to /auth/2fa-verify. The temp token travels via auth state.
        ref.read(authStateProvider.notifier).setTwoFactorRequired(tempToken);
    }
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return CupertinoPageScaffold(
      backgroundColor: colors.surfacePrimary,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Wordmark ──────────────────────────────────────────────
                Text(
                  'On Task',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // ── Subtitle — New York serif (emotional/voice copy only) ─
                Text(
                  AppStrings.authSubtitle,
                  textAlign: TextAlign.center,
                  style: textTheme.displaySmall?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 48),

                // ── Sign in with Apple — MUST be first (Apple HIG) ────────
                _buildAppleButton(),
                const SizedBox(height: 12),

                // ── Sign in with Google ───────────────────────────────────
                _buildGoogleButton(colors),
                const SizedBox(height: 24),

                // ── Divider ───────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(child: Divider(color: colors.textSecondary.withValues(alpha: 0.3))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                      ),
                    ),
                    Expanded(child: Divider(color: colors.textSecondary.withValues(alpha: 0.3))),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Email field ───────────────────────────────────────────
                CupertinoTextField(
                  controller: _emailController,
                  placeholder: AppStrings.authEmailLabel,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  placeholderStyle: TextStyle(color: colors.textSecondary),
                  style: TextStyle(color: colors.textPrimary),
                ),
                const SizedBox(height: 12),

                // ── Password field ────────────────────────────────────────
                CupertinoTextField(
                  controller: _passwordController,
                  placeholder: AppStrings.authPasswordLabel,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _signInWithEmail(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  placeholderStyle: TextStyle(color: colors.textSecondary),
                  style: TextStyle(color: colors.textPrimary),
                ),
                const SizedBox(height: 16),

                // ── Sign In button ────────────────────────────────────────
                _buildEmailSignInButton(colors),

                // ── Forgot password ───────────────────────────────────────
                const SizedBox(height: 12),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    // TODO: Navigate to password reset screen (future story)
                  },
                  child: Text(
                    AppStrings.authForgotPassword,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.accentPrimary,
                    ),
                  ),
                ),

                // ── Error message ─────────────────────────────────────────
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.scheduleAtRisk,
                      // SF Pro only — no serif in error messages (UX spec)
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Button builders
  // ---------------------------------------------------------------------------

  Widget _buildAppleButton() {
    if (_loadingAction == _LoadingAction.apple) {
      return _LoadingPlaceholder(height: 44);
    }
    // Use the standard Apple-provided button — do NOT replace with a custom widget.
    return SignInWithAppleButton(
      onPressed: _signInWithApple,
    );
  }

  Widget _buildGoogleButton(OnTaskColors colors) {
    if (_loadingAction == _LoadingAction.google) {
      return _LoadingPlaceholder(height: 44);
    }
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _signInWithGoogle,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDDDDDD)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google "G" logo — rendered as styled text for simplicity
            // (replace with SVG asset if brand review requires it)
            const Text(
              'G',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4285F4),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              AppStrings.authSignInWithGoogle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3C4043),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailSignInButton(OnTaskColors colors) {
    if (_loadingAction == _LoadingAction.email) {
      return _LoadingPlaceholder(height: 50);
    }
    return CupertinoButton.filled(
      onPressed: _signInWithEmail,
      child: Text(AppStrings.authSignInButton),
    );
  }
}

/// Enum to track which sign-in action is currently loading.
enum _LoadingAction { apple, google, email }

/// Placeholder that shows a [CupertinoActivityIndicator] at the same height
/// as the sign-in button it replaces, keeping layout stable during loading.
class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(child: CupertinoActivityIndicator()),
    );
  }
}
