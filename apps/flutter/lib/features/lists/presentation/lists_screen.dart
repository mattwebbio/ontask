import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import 'create_list_screen.dart';
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
                                child: Text(
                                  list.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: colors.textPrimary,
                                      ),
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
