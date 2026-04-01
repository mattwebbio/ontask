// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_members_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier managing list member state for a given list.
///
/// Keyed by [listId]. Returns the member list for shared indicator display (FR15, FR16).

@ProviderFor(ListMembersNotifier)
final listMembersProvider = ListMembersNotifierFamily._();

/// Notifier managing list member state for a given list.
///
/// Keyed by [listId]. Returns the member list for shared indicator display (FR15, FR16).
final class ListMembersNotifierProvider
    extends $AsyncNotifierProvider<ListMembersNotifier, List<ListMember>> {
  /// Notifier managing list member state for a given list.
  ///
  /// Keyed by [listId]. Returns the member list for shared indicator display (FR15, FR16).
  ListMembersNotifierProvider._({
    required ListMembersNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'listMembersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$listMembersNotifierHash();

  @override
  String toString() {
    return r'listMembersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ListMembersNotifier create() => ListMembersNotifier();

  @override
  bool operator ==(Object other) {
    return other is ListMembersNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$listMembersNotifierHash() =>
    r'b3a01e3d70bb31855ec75ae49ccd91ed25005e79';

/// Notifier managing list member state for a given list.
///
/// Keyed by [listId]. Returns the member list for shared indicator display (FR15, FR16).

final class ListMembersNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ListMembersNotifier,
          AsyncValue<List<ListMember>>,
          List<ListMember>,
          FutureOr<List<ListMember>>,
          String
        > {
  ListMembersNotifierFamily._()
    : super(
        retry: null,
        name: r'listMembersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Notifier managing list member state for a given list.
  ///
  /// Keyed by [listId]. Returns the member list for shared indicator display (FR15, FR16).

  ListMembersNotifierProvider call(String listId) =>
      ListMembersNotifierProvider._(argument: listId, from: this);

  @override
  String toString() => r'listMembersProvider';
}

/// Notifier managing list member state for a given list.
///
/// Keyed by [listId]. Returns the member list for shared indicator display (FR15, FR16).

abstract class _$ListMembersNotifier extends $AsyncNotifier<List<ListMember>> {
  late final _$args = ref.$arg as String;
  String get listId => _$args;

  FutureOr<List<ListMember>> build(String listId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ListMember>>, List<ListMember>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ListMember>>, List<ListMember>>,
              AsyncValue<List<ListMember>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
