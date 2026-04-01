import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../templates/presentation/templates_screen.dart';
import '../domain/list_member.dart';
import 'create_list_screen.dart';
import 'list_members_provider.dart';
import 'lists_provider.dart';
import 'widgets/lists_empty_state.dart';

/// Lists tab screen.
///
/// Shows the user's lists from [ListsNotifier]. Each list taps into
/// [ListDetailScreen]. Shows "Create list" CTA. Falls back to
/// [ListsEmptyState] when no lists exist.
class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsState = ref.watch(listsProvider);
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surfacePrimary,
        middle: const Text(AppStrings.listsTitle),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).push(
            CupertinoPageRoute<void>(
              builder: (_) => const TemplatesScreen(),
            ),
          ),
          child: Text(
            AppStrings.templateLibraryTitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.accentPrimary,
                ),
          ),
        ),
      ),
      child: SafeArea(
        child: listsState.when(
          loading: () => const Center(
            child: CupertinoActivityIndicator(),
          ),
          error: (error, _) => Center(
            child: Text(
              AppStrings.listsError,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ),
          data: (lists) {
            if (lists.isEmpty) {
              return Column(
                children: [
                  const Expanded(child: ListsEmptyState()),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        onPressed: () => _showCreateList(context),
                        child: const Text(AppStrings.createListButton),
                      ),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: lists.length,
                    itemBuilder: (context, index) {
                      final list = lists[index];
                      return GestureDetector(
                        onTap: () => context.go('/lists/${list.id}'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: colors.surfaceSecondary,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      list.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: colors.textPrimary,
                                          ),
                                    ),
                                    _SharedIndicator(listId: list.id),
                                  ],
                                ),
                              ),
                              Icon(
                                CupertinoIcons.chevron_right,
                                size: 16,
                                color: colors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: () => _showCreateList(context),
                      child: const Text(AppStrings.createListButton),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showCreateList(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateListScreen(),
    );
  }
}

// ── Shared indicator row ─────────────────────────────────────────────────────

/// Shows member avatars if the list has 2 or more members (i.e., is shared).
///
/// Renders nothing (zero-height) when the list is personal (0–1 members)
/// or when member data is loading / erroring — preserves existing row layout.
class _SharedIndicator extends ConsumerWidget {
  const _SharedIndicator({required this.listId});

  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersState = ref.watch(listMembersProvider(listId));

    return membersState.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (members) {
        if (members.length < 2) return const SizedBox.shrink();

        final colors = Theme.of(context).extension<OnTaskColors>()!;
        final displayMembers = members.take(3).toList();

        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Row(
            children: [
              // Stacked avatar circles
              SizedBox(
                height: 20,
                width: (displayMembers.length * 14.0) + 6,
                child: Stack(
                  children: [
                    for (var i = 0; i < displayMembers.length; i++)
                      Positioned(
                        left: i * 14.0,
                        child: _MemberAvatar(
                          member: displayMembers[i],
                          colors: colors,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                AppStrings.listMemberCount
                    .replaceAll('{count}', '${members.length}'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A 20×20 circular avatar showing member initials (AC: 3).
///
/// Background: [OnTaskColors.accentPrimary], foreground: [OnTaskColors.surfacePrimary].
class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member, required this.colors});

  final ListMember member;
  final OnTaskColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.accentPrimary,
        border: Border.all(color: colors.surfacePrimary, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        member.avatarInitials.isEmpty
            ? '?'
            : member.avatarInitials.substring(
                0,
                member.avatarInitials.length > 2
                    ? 2
                    : member.avatarInitials.length,
              ),
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: colors.surfacePrimary,
          height: 1,
        ),
      ),
    );
  }
}
