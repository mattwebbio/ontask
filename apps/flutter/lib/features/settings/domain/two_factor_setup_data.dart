/// Data returned from [POST /v1/auth/2fa/setup].
///
/// Contains the TOTP secret, the otpauth URI for QR code rendering,
/// and the list of one-time backup codes. This data is only available once —
/// the user must save the backup codes before confirming 2FA setup (FR92).
class TwoFactorSetupData {
  const TwoFactorSetupData({
    required this.secret,
    required this.otpauthUri,
    required this.backupCodes,
  });

  /// Base32-encoded TOTP secret — shown as manual entry fallback if QR scan fails.
  final String secret;

  /// Full otpauth:// URI for rendering as a QR code via `qr_flutter`.
  ///
  /// Format: `otpauth://totp/OnTask:<email>?secret=<secret>&issuer=OnTask`
  final String otpauthUri;

  /// List of one-time backup codes (10 codes, each usable once).
  ///
  /// Used to complete sign-in if the user loses access to their authenticator app.
  final List<String> backupCodes;
}
