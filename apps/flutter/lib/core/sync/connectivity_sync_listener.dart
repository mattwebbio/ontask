import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/proof/data/proof_repository.dart';
import 'sync_manager.dart';

/// Wires [connectivity_plus] reconnect events to [SyncManager.processQueue].
///
/// Place high in the widget tree (above [MaterialApp] inside [ProviderScope])
/// so the listener is alive for the full app lifecycle.
///
/// This is a [ConsumerStatefulWidget] because it reads Riverpod providers
/// ([syncManagerProvider], [proofRepositoryProvider]) to trigger sync.
///
/// Triggers [processQueue] only on transition from offline → online (not on
/// consecutive online events). ARCH NOTE: [SyncManager] is intentionally
/// connectivity-unaware — this widget is the externally-wired caller.
/// (Epic 7, Story 7.6, AC: 2–3, ARCH-26)
class ConnectivitySyncListener extends ConsumerStatefulWidget {
  const ConnectivitySyncListener({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<ConnectivitySyncListener> createState() =>
      _ConnectivitySyncListenerState();
}

class _ConnectivitySyncListenerState
    extends ConsumerState<ConnectivitySyncListener> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _wasPreviouslyOnline = false;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    // Check current connectivity to initialise the baseline state.
    try {
      final results = await Connectivity().checkConnectivity();
      if (!mounted) return;
      _wasPreviouslyOnline = results.any((r) => r != ConnectivityResult.none);
    } catch (e) {
      debugPrint('ConnectivitySyncListener: init connectivity check error: $e');
    }

    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final isOnline = results.any((r) => r != ConnectivityResult.none);
        if (isOnline && !_wasPreviouslyOnline) {
          _wasPreviouslyOnline = true;
          _triggerSync();
        } else if (!isOnline) {
          _wasPreviouslyOnline = false;
        }
      },
    );
  }

  Future<void> _triggerSync() async {
    if (!mounted) return;
    try {
      final proofRepo = ref.read(proofRepositoryProvider);
      final syncManager = ref.read(syncManagerProvider.notifier);
      await syncManager.processQueue(
        serverStateResolver: (type, payload) async {
          if (type == 'SUBMIT_PROOF') {
            // Proof submission: task always exists on server (no tombstone logic).
            // Return a sentinel state so conflict resolution treats as noConflict.
            return {'lastModifiedAt': null};
          }
          return null; // Unknown type — drop the operation.
        },
        applyOperation: (type, payload) async {
          if (type == 'SUBMIT_PROOF') {
            final taskId = payload['taskId'] as String;
            final clientTs = DateTime.parse(
              payload['clientTimestamp'] as String? ??
                  DateTime.now().toIso8601String(),
            );
            await proofRepo.submitOfflineProof(taskId, clientTs);
          }
        },
      );
    } catch (e) {
      debugPrint('ConnectivitySyncListener: sync error: $e');
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
