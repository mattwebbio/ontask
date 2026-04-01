import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'proof_prefs_provider.g.dart';

/// Async provider that loads the user's proof retention default from
/// [SharedPreferences].
///
/// Defaults to `true` (keep proof) if no preference has been stored.
/// SharedPreferences key: `'proof_retain_default'`
///
/// keepAlive: prevents repeated SharedPreferences reads on every rebuild.
@Riverpod(keepAlive: true)
Future<bool> proofRetainDefault(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('proof_retain_default') ?? true;
}

/// Notifier for writing the proof retention default to [SharedPreferences].
///
/// Exposes [setRetainDefault] which persists the new value and invalidates
/// [proofRetainDefaultProvider] so the UI rebuilds immediately.
///
/// keepAlive: true — matches the read provider lifetime.
@Riverpod(keepAlive: true)
class ProofRetainSettings extends _$ProofRetainSettings {
  @override
  void build() {}

  Future<void> setRetainDefault(bool retain) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('proof_retain_default', retain);
    ref.invalidate(proofRetainDefaultProvider);
  }
}
