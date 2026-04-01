import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/sharing_repository.dart';
import '../domain/list_member.dart';

part 'list_members_provider.g.dart';

/// Notifier managing list member state for a given list.
///
/// Keyed by [listId]. Returns the member list for shared indicator display (FR15, FR16).
@riverpod
class ListMembersNotifier extends _$ListMembersNotifier {
  @override
  Future<List<ListMember>> build(String listId) async {
    final repo = ref.watch(sharingRepositoryProvider);
    return repo.getListMembers(listId);
  }
}
