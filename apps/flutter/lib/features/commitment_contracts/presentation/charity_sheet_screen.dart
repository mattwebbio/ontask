import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../data/commitment_contracts_repository.dart';
import '../domain/nonprofit.dart';
import 'widgets/charity_search_delegate.dart';

/// Modal bottom sheet for selecting a charity as the destination for missed stakes.
///
/// Presented via [showCupertinoModalPopup] from [StakeSheetScreen].
/// Returns the selected [Nonprofit] on confirm, or null if dismissed.
///
/// NOT added to AppRouter — presented as a CupertinoModalPopup only.
/// (Epic 6, Story 6.3, AC1–3)
class CharitySheetScreen extends ConsumerStatefulWidget {
  const CharitySheetScreen({
    super.key,
    this.currentCharityId,
  });

  /// The already-selected charityId (if any), used to pre-select in the list.
  final String? currentCharityId;

  @override
  ConsumerState<CharitySheetScreen> createState() => _CharitySheetScreenState();
}

class _CharitySheetScreenState extends ConsumerState<CharitySheetScreen> {
  List<Nonprofit> _nonprofits = [];
  bool _isLoading = false;
  Nonprofit? _selectedCharity;
  String _searchQuery = '';
  String? _selectedCategory;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadCharities();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCharities() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(commitmentContractsRepositoryProvider);
      final results = await repository.searchCharities(
        query: _searchQuery.isEmpty ? null : _searchQuery,
        category: _selectedCategory,
      );
      if (!mounted) return;
      setState(() {
        _nonprofits = results;
        // Pre-select if a currentCharityId was passed and we find it in results.
        if (widget.currentCharityId != null && _selectedCharity == null) {
          final match = results.where((n) => n.id == widget.currentCharityId);
          if (match.isNotEmpty) {
            _selectedCharity = match.first;
          }
        }
      });
    } on DioException catch (e) {
      if (!mounted) return;
      _showErrorDialog(AppStrings.charityLoadError, dioError: e);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(AppStrings.charityLoadError);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      setState(() => _searchQuery = query);
      _loadCharities();
    });
  }

  void _onCategoryChanged(String? category) {
    setState(() => _selectedCategory = category);
    _loadCharities();
  }

  Future<void> _onConfirm() async {
    final charity = _selectedCharity;
    if (charity == null || _isLoading) return;

    setState(() => _isLoading = true);
    try {
      final repository = ref.read(commitmentContractsRepositoryProvider);
      await repository.setDefaultCharity(charity.id, charity.name);
      if (mounted) {
        Navigator.pop(context, charity);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      _showErrorDialog(AppStrings.charitySetError, dioError: e);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(AppStrings.charitySetError);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message, {DioException? dioError}) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text(AppStrings.dialogErrorTitle),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.actionOk),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.charitySheetTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  CupertinoButton(
                    minimumSize: const Size(44, 44),
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context, null),
                    child: Icon(
                      CupertinoIcons.xmark,
                      color: colors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // ── Search delegate ────────────────────────────────────────────
            SizedBox(
              height: 400,
              child: CharitySearchDelegate(
                nonprofits: _nonprofits,
                isLoading: _isLoading,
                onSearchChanged: _onSearchChanged,
                onCategoryChanged: _onCategoryChanged,
                onSelected: (nonprofit) {
                  setState(() => _selectedCharity = nonprofit);
                },
                selectedCharityId: _selectedCharity?.id,
              ),
            ),

            // ── Confirm button ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  minimumSize: const Size(44, 44),
                  color: colors.accentPrimary,
                  onPressed: _selectedCharity == null ? null : (_isLoading ? null : _onConfirm),
                  child: _isLoading
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : const Text(AppStrings.charityConfirmButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
