import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../tasks/presentation/tasks_provider.dart';
import '../data/guided_chat_repository.dart';
import '../domain/chat_message.dart';
import '../domain/guided_chat_response.dart';
import '../domain/guided_chat_task_draft.dart';

/// Full-height modal sheet for guided chat task capture (FR14 / UX-DR15).
///
/// Opens as a full-height modal bottom sheet (not inline in [AddTabSheet]).
/// Conducts a multi-turn LLM conversation to collect task properties.
///
/// Architecture:
/// - Stateless server: each turn sends the full conversation history.
/// - Client-managed state: [_messages] holds the entire thread.
/// - On first frame, triggers the LLM's opening question automatically.
///
/// States: loading (typing indicator) → conversation active →
///   task complete (confirmation card) → dismissed without saving (AC: 2).
///
/// Draft/resume: NOT implemented in V1 (UX spec §11 line 1256 — V1.1 only).
class GuidedChatSheet extends ConsumerStatefulWidget {
  const GuidedChatSheet({super.key});

  @override
  ConsumerState<GuidedChatSheet> createState() => _GuidedChatSheetState();
}

class _GuidedChatSheetState extends ConsumerState<GuidedChatSheet> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  /// Full conversation thread shown in the UI.
  /// Each entry: `{'role': 'user'|'assistant', 'content': String, 'isError': bool?}`.
  final List<Map<String, dynamic>> _messages = [];

  bool _isLoading = false;
  bool _isSubmittingTask = false;
  GuidedChatResponse? _lastResponse;

  @override
  void initState() {
    super.initState();
    // Trigger the LLM's opening question on first frame (UX spec line 1254).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _sendMessage('');
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Scroll to bottom ─────────────────────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Send a message turn ───────────────────────────────────────────────────

  Future<void> _sendMessage(String userText) async {
    if (_isLoading) return;

    // Add user message to thread (skip for empty opening prompt)
    if (userText.trim().isNotEmpty) {
      setState(() {
        _messages.add({'role': 'user', 'content': userText.trim()});
        _inputController.clear();
      });
      _scrollToBottom();
    }

    setState(() => _isLoading = true);

    // Build message list for API — use all user/assistant messages so far.
    // The API schema requires messages.min(1), so seed with a greeting when
    // the thread is empty (i.e., the opening LLM turn before the user speaks).
    final apiMessages = _messages
        .where((m) => m['isError'] != true)
        .map((m) => ChatMessage(
              role: m['role'] as String,
              content: m['content'] as String,
            ))
        .toList();

    if (apiMessages.isEmpty) {
      apiMessages.add(ChatMessage(role: 'user', content: 'Hi, I need to create a task'));
    }

    try {
      final repo = ref.read(guidedChatRepositoryProvider);
      final response = await repo.sendMessage(apiMessages);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _lastResponse = response;
        _messages.add({'role': 'assistant', 'content': response.reply});
      });
      _scrollToBottom();

      // Announce the LLM's opening message via VoiceOver (UX spec line 1680)
      if (_messages.where((m) => m['role'] == 'assistant').length == 1) {
        SemanticsService.sendAnnouncement(
          View.of(context),
          response.reply,
          TextDirection.ltr,
        );
      }
    } on Exception catch (e) {
      if (!mounted) return;
      // Determine the error message based on type
      final errorMessage = e.toString().contains('timed out') || e.toString().contains('TIMEOUT')
          ? AppStrings.guidedChatTimeoutError
          : AppStrings.guidedChatError;

      setState(() {
        _isLoading = false;
        _messages.add({'role': 'assistant', 'content': errorMessage, 'isError': true});
      });
      _scrollToBottom();
    }
  }

  // ── Create the task ───────────────────────────────────────────────────────

  Future<void> _createTask() async {
    final draft = _lastResponse?.extractedTask;
    final title = draft?.title ?? '';
    if (title.isEmpty) return;

    setState(() => _isSubmittingTask = true);

    try {
      await ref
          .read(tasksProvider(listId: draft?.listId).notifier)
          .createTask(
            title: title,
            dueDate: draft?.dueDate,
            listId: draft?.listId,
            energyRequirement: draft?.energyRequirement,
          );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSubmittingTask = false;
          // Show inline error in the confirmation card area
          _messages.add({
            'role': 'assistant',
            'content': AppStrings.addTaskError,
            'isError': true,
          });
        });
        _scrollToBottom();
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final isComplete = _lastResponse?.isComplete ?? false;
    final draft = _lastResponse?.extractedTask;

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Drag handle ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Container(
                  width: AppSpacing.xxxl,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Message thread ───────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Typing indicator bubble
                    if (_isLoading && index == _messages.length) {
                      return _TypingIndicatorBubble(colors: colors);
                    }

                    final msg = _messages[index];
                    final isUser = msg['role'] == 'user';
                    final isError = msg['isError'] == true;

                    return _MessageBubble(
                      content: msg['content'] as String,
                      isUser: isUser,
                      isError: isError,
                      colors: colors,
                    );
                  },
                ),
              ),

              // ── Confirmation card (when isComplete) ──────────────────
              if (isComplete && draft != null)
                _ConfirmationCard(
                  draft: draft,
                  isSubmitting: _isSubmittingTask,
                  colors: colors,
                  onCreateTask: _createTask,
                ),

              // ── Input row ────────────────────────────────────────────
              if (!isComplete)
                Padding(
                  padding: EdgeInsets.only(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
                    top: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoTextField(
                          controller: _inputController,
                          placeholder: AppStrings.guidedChatInputPlaceholder,
                          enabled: !_isLoading,
                          style: TextStyle(
                            fontSize: 15,
                            color: colors.textPrimary,
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              _sendMessage(value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      CupertinoButton(
                        minimumSize: const Size(44, 44),
                        padding: EdgeInsets.zero,
                        onPressed: _isLoading
                            ? null
                            : () {
                                final text = _inputController.text.trim();
                                if (text.isNotEmpty) {
                                  _sendMessage(text);
                                }
                              },
                        child: Icon(
                          CupertinoIcons.arrow_up_circle_fill,
                          size: 32,
                          color: _isLoading
                              ? colors.textSecondary
                              : CupertinoColors.activeBlue,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _MessageBubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.content,
    required this.isUser,
    required this.isError,
    required this.colors,
  });

  final String content;
  final bool isUser;
  final bool isError;
  final OnTaskColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isUser ? colors.surfaceSecondary : colors.surfacePrimary,
            borderRadius: BorderRadius.circular(12),
            border: isError
                ? Border.all(color: CupertinoColors.destructiveRed.withAlpha(128))
                : isUser
                    ? null
                    : Border.all(color: colors.surfaceSecondary),
          ),
          child: Text(
            content,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ),
    );
  }
}

// ── _TypingIndicatorBubble ────────────────────────────────────────────────────

class _TypingIndicatorBubble extends StatelessWidget {
  const _TypingIndicatorBubble({required this.colors});

  final OnTaskColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surfacePrimary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.surfaceSecondary),
          ),
          child: const CupertinoActivityIndicator(),
        ),
      ),
    );
  }
}

// ── _ConfirmationCard ─────────────────────────────────────────────────────────

/// Card displayed when [GuidedChatResponse.isComplete] is true.
/// Shows extracted task fields for review and a "Create task" CTA.
class _ConfirmationCard extends StatelessWidget {
  const _ConfirmationCard({
    required this.draft,
    required this.isSubmitting,
    required this.colors,
    required this.onCreateTask,
  });

  final GuidedChatTaskDraft draft;
  final bool isSubmitting;
  final OnTaskColors colors;
  final VoidCallback onCreateTask;

  @override
  Widget build(BuildContext context) {
    // Build field rows to display
    final rows = <_FieldRow>[];

    final title = draft.title;
    if (title != null && title.isNotEmpty) {
      rows.add(_FieldRow(label: 'Task', value: title));
    }

    final dueDate = draft.dueDate;
    if (dueDate != null) {
      final date = DateTime.tryParse(dueDate);
      rows.add(_FieldRow(
        label: 'Due',
        value: date != null
            ? '${date.month}/${date.day}/${date.year}'
            : dueDate,
      ));
    }

    final energyRequirement = draft.energyRequirement;
    if (energyRequirement != null) {
      final label = energyRequirement == 'high_focus'
          ? 'High focus'
          : energyRequirement == 'low_energy'
              ? 'Low energy'
              : 'Flexible';
      rows.add(_FieldRow(label: 'Energy', value: label));
    }

    final duration = draft.estimatedDurationMinutes;
    if (duration != null) {
      rows.add(_FieldRow(label: 'Duration', value: '${duration}min'));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final row in rows) ...[
              _FieldRowWidget(row: row, colors: colors),
              const SizedBox(height: AppSpacing.xs),
            ],
            const SizedBox(height: AppSpacing.sm),
            CupertinoButton(
              color: CupertinoColors.activeBlue,
              minimumSize: const Size(double.infinity, 44),
              onPressed: isSubmitting ? null : onCreateTask,
              child: Text(
                isSubmitting
                    ? AppStrings.submittingIndicator
                    : AppStrings.guidedChatCreateButton,
                style: const TextStyle(color: CupertinoColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _FieldRow helpers ─────────────────────────────────────────────────────────

class _FieldRow {
  const _FieldRow({required this.label, required this.value});
  final String label;
  final String value;
}

class _FieldRowWidget extends StatelessWidget {
  const _FieldRowWidget({required this.row, required this.colors});

  final _FieldRow row;
  final OnTaskColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '${row.label}: ',
          style: TextStyle(
            fontSize: 12,
            color: colors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            row.value,
            style: TextStyle(
              fontSize: 12,
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
