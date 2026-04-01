# Story 3.7: Natural Language Scheduling Nudges & Motion Tokens

Status: review

## Story

As a user,
I want to adjust my schedule using natural language and see smooth animations when it changes,
So that rescheduling feels conversational and changes are visually clear.

## Acceptance Criteria

1. **Given** a task is scheduled **When** the user types or speaks a natural language nudge (e.g. "move my gym session to tomorrow morning") **Then** the LLM interprets the nudge and proposes a new schedule for the affected task (FR14) **And** the proposed change is shown to the user for confirmation before applying **And** confirming updates the task schedule and the Google Calendar block

2. **Given** the schedule regenerates (any trigger) **When** tasks are shown for the first time in the day view **Then** "The reveal" motion token plays: tasks appear sequentially with a 50ms stagger (UX-DR20) **And** when the schedule updates mid-session, "The plan shifts" motion token plays on the changed items

3. **Given** the device has "Reduce Motion" enabled **When** any named motion token would play **Then** the animation is replaced by an instant state change with no movement (UX-DR20)

## Tasks / Subtasks

### Backend: NLP Nudge Parser in `packages/ai`

- [x] Implement `parseSchedulingNudge()` in `packages/ai/src/nudge-parser.ts` (AC: 1)
  - [x] Accept `NudgeInput { utterance: string; taskId: string; taskTitle: string; currentScheduledTime?: Date; windowStart: Date; windowEnd: Date }` and return `NudgeOutput { suggestedDate: Date; confidence: 'high' | 'low'; interpretation: string }`
  - [x] Call the Vercel AI SDK `generateObject()` with the AI Gateway provider (see `packages/ai/src/provider.ts` — implement this first, it is required for all AI calls)
  - [x] Prompt must resolve relative time expressions ("tomorrow morning", "after lunch", "in 30 minutes") relative to `windowStart` — pass `windowStart` as the "current time" reference in the prompt
  - [x] Return `confidence: 'low'` when the utterance is ambiguous or the resolved date falls outside `[windowStart, windowEnd]`
  - [x] Return type uses a Zod schema for structured output (Vercel AI SDK `generateObject` with `schema:` parameter)
  - [x] Export `parseSchedulingNudge` and all types from `packages/ai/src/index.ts`
  - [x] 100% test coverage in `packages/ai/src/test/nudge-parser.test.ts` — mock the AI provider (never call real LLM in unit tests)

- [x] Implement `packages/ai/src/provider.ts` (required prerequisite) (AC: 1)
  - [x] Configure `ai-gateway-provider` using the Cloudflare AI Gateway binding from `wrangler.toml` (binding name: `AI`)
  - [x] Export a factory function `createAIProvider(env: CloudflareBindings)` that returns the gateway-configured provider
  - [x] Fall back to direct OpenAI if AI Gateway binding is not available (local dev without `wrangler dev`)
  - [x] The model to use: `gpt-4o-mini` (cost-efficient, sufficient for date parsing)

### Backend: Nudge API Endpoint

- [x] Add `POST /v1/tasks/:id/schedule/nudge` route to `apps/api/src/routes/scheduling.ts` (AC: 1)
  - [x] Request body: `{ utterance: string }` — validated with Zod
  - [x] Calls `parseSchedulingNudge()` from `@ontask/ai` with `windowStart: new Date()` and `windowEnd: 14 days ahead`
  - [x] On success, calls `runScheduleForUser(userId, c.env)` with `suggestedDates: { [taskId]: nudgeOutput.suggestedDate }` in `ScheduleInput` — pass as `overrideSuggestedDates` parameter to `runScheduleForUser` (update the service to accept this)
  - [x] Returns 200 with `{ data: { taskId, proposedStartTime: ISO string, proposedEndTime: ISO string, interpretation: string, confidence: string } }` — does NOT apply the change; returns a proposal for client confirmation
  - [x] Does NOT write to Google Calendar on this call — proposal only
  - [x] Returns 404 if the task is not found in schedule output after nudge
  - [x] Returns 422 with `err('UNPROCESSABLE', 'Could not interpret scheduling request')` when `confidence: 'low'`
  - [x] Auth stub: `x-user-id` header (same pattern as existing scheduling routes)
  - [x] Register AFTER existing GET/POST routes to avoid route-order conflicts
  - [x] Add Zod schemas: `NudgeRequestSchema`, `NudgeResponseSchema`

- [x] Add `POST /v1/tasks/:id/schedule/nudge/confirm` route to `apps/api/src/routes/scheduling.ts` (AC: 1)
  - [x] Request body: `{ proposedStartTime: string }` (ISO 8601)
  - [x] Sets `task.lockedStartTime` to the proposed time by calling the task update service
  - [x] Re-runs `runScheduleForUser` so the calendar block is moved (triggers `syncScheduledBlocksToCalendar`)
  - [x] Returns 200 with the same shape as `POST /v1/tasks/:id/schedule` (existing scheduled block response)
  - [x] This is what actually commits the change and updates Google Calendar

- [x] Update `runScheduleForUser` in `apps/api/src/services/scheduling.ts` to accept optional `suggestedDates` override (AC: 1)
  - [x] Add optional param `options?: { suggestedDates?: Record<string, Date> }` to function signature
  - [x] Merge `options.suggestedDates` into `scheduleInput.suggestedDates` when provided
  - [x] Existing callers pass no options — no breaking change

### Flutter: Nudge Input UI

- [x] Create `apps/flutter/lib/features/scheduling/presentation/widgets/nudge_input_sheet.dart` (AC: 1)
  - [x] Bottom sheet widget `NudgeInputSheet` with a `CupertinoTextField` for utterance input and a "Suggest" CTA button
  - [x] On submit: calls `POST /v1/tasks/:id/schedule/nudge` via `SchedulingRepository`; shows a proposal preview card with the returned `proposedStartTime`, `proposedEndTime`, and `interpretation` string
  - [x] Proposal card: two actions — "Apply" (calls confirm endpoint + closes sheet + triggers `todayProvider.refresh()`) and "Cancel" (dismisses proposal, stays in sheet for re-entry)
  - [x] Loading state: `CupertinoActivityIndicator` centered while awaiting LLM response
  - [x] Error state: plain-language message; when confidence is low: "I couldn't understand that — try something like 'move to tomorrow morning'"
  - [x] `confidence: 'low'` → show inline warning rather than hard error (user can retry)
  - [x] All colours via `Theme.of(context).extension<OnTaskColors>()!` — `colors.textPrimary`, `colors.textSecondary`, `colors.surfacePrimary` (as per Story 3.6 debug log — no `backgroundPrimary`)
  - [x] Dismiss: swipe-down standard iOS bottom sheet (`showModalBottomSheet`)
  - [x] No hardcoded colours; no `Material` widgets except `showModalBottomSheet`

- [x] Add nudge repository methods to `apps/flutter/lib/features/scheduling/data/scheduling_repository.dart` (AC: 1)
  - [x] `proposeNudge(String taskId, String utterance) → Future<NudgeProposal>` — calls `POST /v1/tasks/:id/schedule/nudge`
  - [x] `confirmNudge(String taskId, DateTime proposedStartTime) → Future<void>` — calls `POST /v1/tasks/:id/schedule/nudge/confirm`
  - [x] Add DTO `NudgeProposalDto` (freezed, with `toDomain()`) in `apps/flutter/lib/features/scheduling/data/nudge_proposal_dto.dart`
  - [x] Add domain model `NudgeProposal` (freezed) in `apps/flutter/lib/features/scheduling/domain/nudge_proposal.dart`
  - [x] Generated files (`.freezed.dart`, `.g.dart`) committed — ran `dart run build_runner build --delete-conflicting-outputs` from `apps/flutter/`

- [x] Add "Reschedule with AI" entry point on `TodayTaskRow` in `apps/flutter/lib/features/today/presentation/widgets/today_task_row.dart` (AC: 1)
  - [x] Add optional `VoidCallback? onNudge` parameter (follows existing `onWhyHere`, `onReschedule` pattern)
  - [x] When `onNudge` is non-null and `rowState` is `upcoming` or `current`, expose "Reschedule" swipe action (trailing) that opens `NudgeInputSheet`
  - [x] The existing `onReschedule` swipe action from Story 2.6 opens a date/time picker — `onNudge` opens the NLP input sheet instead; both can coexist or `onNudge` replaces `onReschedule` depending on what the caller provides (caller decides)
  - [x] Add string constant to `apps/flutter/lib/core/l10n/strings.dart`: `todayRowNudge = 'Reschedule with AI'` and `nudgeSheetTitle = 'When would you like to move this?'`

### Flutter: Motion Tokens (UX-DR20)

- [x] Create `apps/flutter/lib/core/motion/motion_tokens.dart` (AC: 2, 3)
  - [x] Define constants and a helper function for each named motion token needed in this story:
    - `MotionTokens.revealStaggerMs = 50` — stagger delay between tasks in "The reveal"
    - `MotionTokens.revealDurationMs = 300` — individual task fade-in duration
    - `MotionTokens.planShiftsDurationMs = 400` — slide+fade for changed items
  - [x] Helper `bool isReducedMotion(BuildContext context)` → `MediaQuery.of(context).disableAnimations`
  - [x] No animation logic here — just constants and the helper

- [x] Implement "The reveal" motion token on Today tab task list (AC: 2, 3)
  - [x] In `apps/flutter/lib/features/today/presentation/today_screen.dart`, when the task list transitions from skeleton/loading to populated: animate each `TodayTaskRow` in with a fade + slight upward slide (matching chapter break screen pattern: `Offset(0, 0.04)` → `Offset.zero`)
  - [x] Use staggered `Future.delayed` per row with `MotionTokens.revealStaggerMs` (50ms) between each task via `_RevealAnimation` widget
  - [x] Each row's animation: `FadeTransition` + `SlideTransition`, duration `MotionTokens.revealDurationMs` (300ms), `Curves.easeOut`
  - [x] Reduce Motion: when `MediaQuery.of(context).disableAnimations` is true, render all rows at full opacity/position immediately — no stagger, no animation
  - [x] Only plays on initial load of the list (first build from loading → data state); does NOT replay when tasks update mid-session
  - [x] Use `AnimationController` with `SingleTickerProviderStateMixin` — matches chapter break screen pattern exactly

- [x] Implement "The plan shifts" motion token on changed task rows (AC: 2, 3)
  - [x] When `scheduleChangeBannerVisibleProvider` becomes true, the changed task rows play a colour flash via `_PlanShiftsAnimation` widget using `ColorFiltered`
  - [x] Changed task IDs read from `scheduleChangesProvider` (via `ref.listen` in `_TodayScreenState`)
  - [x] Reduce Motion: no colour flash; render instantly at normal state when `disableAnimations` is true
  - [x] The animation must NOT affect layout — uses `ColorFiltered` on background; no translate/scale
  - [x] Animation is one-shot per schedule change event — does not loop

- [x] Write widget tests for motion tokens (AC: 2, 3)
  - [x] `apps/flutter/test/features/today/today_reveal_animation_test.dart`
    - Test that with `disableAnimations: true`, rows render at full opacity immediately (no animation)
    - Test that with `disableAnimations: false`, `AnimationController` is initialized and forward is called
  - [x] `apps/flutter/test/core/motion/motion_tokens_test.dart` — verify constants have expected values

- [x] Write widget tests for nudge input sheet (AC: 1)
  - [x] `apps/flutter/test/features/scheduling/nudge_input_sheet_test.dart`
    - Loading state renders `CupertinoActivityIndicator`
    - Success state renders proposal card with proposedStartTime and interpretation
    - Low-confidence state renders inline warning
    - Error state renders plain-language error message
    - Used subclass `SchedulingRepository` fakes to control response

## Dev Notes

### CRITICAL: Architecture split — nudge is NOT in `packages/scheduling`

The architecture document (line 47) is explicit: "Nudging is a UI concern, not an NLP concern. The scheduling engine is a pure function that accepts an optional `suggestedDates` parameter alongside its standard inputs. Natural language input (if exposed) is a pre-processing tool that resolves to structured suggested dates before reaching the engine."

This means:
- `packages/scheduling` already has `applySuggestedDateConstraint()` in `constraints/suggested-dates.ts` — **do not modify it**
- `packages/scheduling/src/scheduler.ts` already reads `suggestedDates?.[task.id]` from `ScheduleInput` — **do not modify the engine**
- The NLP resolution lives in `packages/ai/src/nudge-parser.ts` (NEW)
- The API service (`runScheduleForUser`) bridges AI output → `ScheduleInput.suggestedDates`

### CRITICAL: `packages/ai` is a stub — bootstrap it in this story

`packages/ai/src/index.ts` is currently: `// Populated in Epic 4 (AI-Powered Task Capture) / export {}`

This story requires the first real AI call. Do NOT wait for Epic 4. Add only what this story needs:
- `packages/ai/src/provider.ts` — AI Gateway provider factory
- `packages/ai/src/nudge-parser.ts` — scheduling nudge interpreter

Do NOT implement `proof-verification.ts`, `watch-mode.ts`, or `nlp-parser.ts` — those are Epic 4+.

### CRITICAL: AI packages are already installed

From the architecture doc:
```
npm install ai @ai-sdk/openai @ai-sdk/anthropic ai-gateway-provider
```
- `ai` (Vercel AI SDK v6) — already listed as a dependency
- `ai-gateway-provider` — already listed

Check `packages/ai/package.json` before adding dependencies. Do NOT duplicate.

### CRITICAL: Vercel AI SDK v6 — `generateObject` usage

For structured output (the nudge resolver needs a typed date object back):
```typescript
import { generateObject } from 'ai'
import { z } from 'zod'

const NudgeResultSchema = z.object({
  suggestedDate: z.string().describe('ISO 8601 datetime string for the suggested slot'),
  confidence: z.enum(['high', 'low']),
  interpretation: z.string().describe('Human-readable confirmation e.g. "Tomorrow morning at 9 AM"'),
})

const { object } = await generateObject({
  model: provider('gpt-4o-mini'),
  schema: NudgeResultSchema,
  prompt: `...`,
})
```

Parse `object.suggestedDate` to `new Date(object.suggestedDate)` after generation.

### CRITICAL: `packages/ai` 100% test coverage — mock the AI provider

The existing CI coverage requirement in `packages/scheduling` (ARCH-23) likely extends to `packages/ai` given the project's 100%-coverage discipline. Check `packages/ai/vitest.config.ts` (create if not present). All AI calls must be mocked in unit tests — never call the real LLM. Use `vi.mock('ai', () => ({ generateObject: vi.fn() }))`.

### CRITICAL: Reduce Motion pattern — established in Story 2.13 (ChapterBreakScreen)

The authoritative pattern is in `apps/flutter/lib/features/chapter_break/presentation/chapter_break_screen.dart`:

```dart
// in didChangeDependencies():
final disableAnimations = MediaQuery.of(context).disableAnimations;
if (disableAnimations) {
  _controller.value = 1.0; // instant — no animation
} else {
  _controller.forward();
}
```

- Check `MediaQuery.of(context).disableAnimations` in `didChangeDependencies` — NOT in `initState` (inherited widgets not available during initState)
- Use `AnimationController.value = 1.0` for instant state — do NOT use `duration: Duration.zero`
- The skeleton widgets (`today_skeleton.dart`, `now_card_skeleton.dart`) also use this pattern for shimmer

### CRITICAL: Motion token scope — only "The reveal" and "The plan shifts" in this story

UX-DR20 defines 5 named motion tokens. Only two are in-scope for Story 3.7:
- "The reveal" — schedule generation animation (sequential task appearance, 50ms stagger) ✅
- "The plan shifts" — schedule change indication ✅
- "The vault close" — commitment lock → **Epic 6 scope**
- "The release" — stake released on completion → **Epic 6 scope**
- "The chapter break" — already implemented in Story 2.13 ✅

Do NOT implement vault close or release tokens here.

### CRITICAL: `scheduleChangeBannerVisibleProvider` pattern already established

Story 2.12 implemented `ScheduleChangeBanner` in `apps/flutter/lib/features/today/`. The "plan shifts" motion integrates with it:
- `scheduleChangeBannerVisibleProvider` — tracks banner visibility (Riverpod provider in `schedule_change_provider.dart`)
- `scheduleChangeProvider` — tracks the actual `ScheduleChange` objects including changed task IDs
- The Today screen already `ref.listen`s to `scheduleChangeBannerVisibleProvider` to manage an auto-dismiss timer
- For "The plan shifts": `ref.listen` to `scheduleChangeBannerVisibleProvider` in `TodayTaskList` (or the screen), and when it becomes `true`, animate rows whose taskId is in the change set

### CRITICAL: `OnTaskColors` — use `surfacePrimary` not `backgroundPrimary`

Story 3.6 debug log: "OnTaskColors does not have `backgroundPrimary` — using `surfacePrimary` instead (equivalent token)." Use `colors.surfacePrimary` for sheet/container backgrounds throughout this story.

### API: Nudge is a proposal-only endpoint

The nudge endpoint (`POST /v1/tasks/:id/schedule/nudge`) returns a PROPOSAL only. It must NOT:
- Modify the task in the database
- Update `lockedStartTime`
- Call `syncScheduledBlocksToCalendar`

Only `POST /v1/tasks/:id/schedule/nudge/confirm` commits the change. The confirm endpoint sets `lockedStartTime` on the task (equivalent to a manual pin) and re-runs the full schedule + calendar sync.

### API: Route registration order in `apps/api/src/routes/scheduling.ts`

Current route order (must be preserved):
1. `POST /v1/tasks/{id}/schedule` (existing)
2. `GET /v1/tasks/{id}/schedule` (added Story 3.6)
3. `POST /v1/tasks/{id}/schedule/nudge` (NEW — Story 3.7)
4. `POST /v1/tasks/{id}/schedule/nudge/confirm` (NEW — Story 3.7)

Hono matches routes in registration order. The more-specific `/nudge` and `/nudge/confirm` paths must not conflict with the existing `/{id}/schedule` routes. Using distinct trailing segments (`/nudge`, `/nudge/confirm`) prevents ambiguity.

### Flutter: "The reveal" animation — use staggered approach not `AnimatedList`

`AnimatedList` is designed for insert/remove animations, not initial-load stagger. Use the simpler approach:

```dart
// In _TodayScreenState, add a flag:
bool _hasPlayedReveal = false;

// When building rows:
for (int i = 0; i < tasks.length; i++) {
  final delay = _hasPlayedReveal ? Duration.zero : Duration(milliseconds: i * MotionTokens.revealStaggerMs);
  // Wrap TodayTaskRow in an AnimatedOpacity / SlideTransition driven by
  // a delayed AnimationController
}
// After first build: _hasPlayedReveal = true
```

Or: add a `revealIndex` parameter to `TodayTaskRow` that drives its own `AnimationController`. The simplest implementation that works without jank is acceptable — 60fps is required (NFR-P8).

### Flutter: Generated files must be committed

Story 3.6 established this. Run from `apps/flutter/`:
```bash
dart run build_runner build --delete-conflicting-outputs
```
Check that all `.freezed.dart` and `.g.dart` files for new models are in the commit diff.

### Flutter: `NudgeInputSheet` — bottom sheet presentation

Use `showModalBottomSheet` (not `showCupertinoModalPopup`) for consistency with `ScheduleExplanationSheet` established in Story 3.6. The sheet's internal structure should mirror `ScheduleExplanationSheet` (title using `textTheme.titleMedium` + `colors.textPrimary`).

### API: NFR-P3 — LLM must respond within 3 seconds

`NFR-P3: NLP task parsing and scheduling completes within 3 seconds of submission`. The nudge LLM call must respect this. Set a timeout of 2500ms on the `generateObject` call (leaving 500ms headroom for network + scheduling). If the LLM exceeds timeout, return 422 `UNPROCESSABLE` with message "Scheduling assistant timed out — try a simpler phrase".

### `packages/scheduling` — no changes needed

`applySuggestedDateConstraint` is already implemented and tested. `ScheduleInput.suggestedDates` is already typed. `scheduler.ts` already reads it. Do NOT touch `packages/scheduling` in this story — zero changes required there.

### Files to Create/Modify

**New (packages/ai):**
- `packages/ai/src/provider.ts` — AI Gateway provider factory
- `packages/ai/src/nudge-parser.ts` — `parseSchedulingNudge()` implementation
- `packages/ai/src/test/nudge-parser.test.ts` — unit tests (mock AI provider)
- `packages/ai/vitest.config.ts` — create if not present; enable 100% coverage threshold

**Modify (packages/ai):**
- `packages/ai/src/index.ts` — export `parseSchedulingNudge`, `NudgeInput`, `NudgeOutput`

**Modify (apps/api services):**
- `apps/api/src/services/scheduling.ts` — add optional `suggestedDates` override param to `runScheduleForUser`

**Modify (apps/api routes):**
- `apps/api/src/routes/scheduling.ts` — add `POST /v1/tasks/{id}/schedule/nudge` and `POST /v1/tasks/{id}/schedule/nudge/confirm` routes

**New (apps/api tests):**
- `apps/api/test/routes/scheduling-nudge.test.ts` — tests for both new nudge routes (mock `@ontask/ai`)

**New (apps/flutter — scheduling feature additions):**
- `apps/flutter/lib/features/scheduling/domain/nudge_proposal.dart`
- `apps/flutter/lib/features/scheduling/domain/nudge_proposal.freezed.dart` (generated)
- `apps/flutter/lib/features/scheduling/data/nudge_proposal_dto.dart`
- `apps/flutter/lib/features/scheduling/data/nudge_proposal_dto.freezed.dart` (generated)
- `apps/flutter/lib/features/scheduling/data/nudge_proposal_dto.g.dart` (generated)
- `apps/flutter/lib/features/scheduling/presentation/widgets/nudge_input_sheet.dart`

**Modify (apps/flutter — scheduling feature):**
- `apps/flutter/lib/features/scheduling/data/scheduling_repository.dart` — add `proposeNudge()`, `confirmNudge()` methods

**New (apps/flutter — motion system):**
- `apps/flutter/lib/core/motion/motion_tokens.dart` — constants and `isReducedMotion()` helper

**Modify (apps/flutter — today feature):**
- `apps/flutter/lib/features/today/presentation/today_screen.dart` — add "The reveal" animation on initial load; add "The plan shifts" animation on schedule change
- `apps/flutter/lib/features/today/presentation/widgets/today_task_row.dart` — add `onNudge` callback

**Modify (apps/flutter — l10n):**
- `apps/flutter/lib/core/l10n/strings.dart` — add `nudgeSheetTitle`, `todayRowNudge`, `nudgeConfidenceLow`, `nudgeError`

**New (apps/flutter tests):**
- `apps/flutter/test/features/scheduling/nudge_input_sheet_test.dart`
- `apps/flutter/test/features/today/today_reveal_animation_test.dart`
- `apps/flutter/test/core/motion/motion_tokens_test.dart`

**Update (sprint status):**
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

### Project Structure Notes

- `parseSchedulingNudge()` lives in `packages/ai/src/nudge-parser.ts` — NOT in `packages/scheduling` (scheduling engine is NLP-agnostic per ARCH-21)
- Motion token constants live in `apps/flutter/lib/core/motion/` — cross-feature concern, not under any single feature directory
- Nudge UI (`NudgeInputSheet`) lives in `apps/flutter/lib/features/scheduling/presentation/widgets/` — same feature directory established in Story 3.6
- New routes in `apps/api/src/routes/scheduling.ts` — do NOT create a new routes file
- No new database tables or migrations required
- No new Cloudflare KV bindings required — only the existing AI Gateway binding

### References

- FR14: Users can adjust scheduled tasks using natural language nudges
- NFR-P3: NLP task parsing and scheduling completes within 3 seconds
- NFR-P8: UI animations and transitions run at 60fps; no perceptible jank
- NFR-Q1: Scheduling engine — identical inputs always produce identical outputs (pure function; preserved)
- UX-DR20: Named motion tokens with reduced-motion variants — "The reveal" + "The plan shifts" in scope
- ARCH-21: `packages/scheduling` is a pure function — NLP preprocessing must not enter the engine
- Architecture §"Nudging is a UI concern" — line 47, architecture.md
- Architecture §`packages/ai/` — AI Pipeline Abstraction section
- Architecture §"AI pipeline abstraction" — Cloudflare AI Gateway + Vercel AI SDK v6
- `packages/scheduling/src/constraints/suggested-dates.ts` — existing nudge constraint (DO NOT MODIFY)
- `packages/core/src/types/scheduling.ts` — `ScheduleInput.suggestedDates`, `ScheduleTask.suggestedDate`
- `packages/ai/src/index.ts` — current stub to expand
- `apps/api/src/routes/scheduling.ts` — existing routes to extend
- `apps/api/src/services/scheduling.ts` — `runScheduleForUser` orchestrator
- `apps/flutter/lib/features/scheduling/` — scheduling feature established in Story 3.6
- `apps/flutter/lib/features/today/presentation/today_screen.dart` — task list render to animate
- `apps/flutter/lib/features/today/presentation/widgets/today_task_row.dart` — row to extend with `onNudge`
- `apps/flutter/lib/features/today/presentation/schedule_change_provider.dart` — for "plan shifts" trigger
- `apps/flutter/lib/features/chapter_break/presentation/chapter_break_screen.dart` — authoritative Reduce Motion pattern
- Story 3.6 Dev Notes — `OnTaskColors.surfacePrimary` (not `backgroundPrimary`), bottom sheet pattern, generated files discipline
- Story 2.12 Dev Notes — `ScheduleChangeBanner` + `scheduleChangeBannerVisibleProvider` + `scheduleChangeProvider`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- `packages/ai/package.json` was a stub with no dependencies. Added `ai` (Vercel AI SDK v4), `@ai-sdk/openai`, and `zod` (v3) as dependencies. The API uses zod v4 — no conflict as packages/ai has its own node_modules.
- `ai-gateway-provider` package from the architecture doc was not published. Used `@ai-sdk/openai` with `createOpenAI` and a `baseURL` override for the Cloudflare AI Gateway URL instead (equivalent pattern).
- `OnTaskColors.backgroundPrimary` does not exist — used `surfacePrimary` per Story 3.6 debug log.
- `ColorFiltered` was used for "The plan shifts" animation to avoid layout impact, but it applies to child widget tree. An `AnimatedBuilder` driving `ColorFilter.mode` with `BlendMode.srcOver` on `accentPrimary` at ~20% opacity achieves the required colour flash without translation/scale.
- `todayProvider.notifier.refresh()` confirmed to exist at line 39 in `today_provider.dart`.

### Completion Notes List

- Bootstrapped `packages/ai` with Vercel AI SDK v4 + OpenAI adapter. `createAIProvider()` uses `AI_GATEWAY_URL` env var for Cloudflare AI Gateway, falls back to direct OpenAI. 100% test coverage on both `nudge-parser.ts` and `provider.ts` (16 tests).
- `parseSchedulingNudge()` resolves natural language utterances to `NudgeOutput` using `generateObject` with a Zod schema. Returns `confidence: 'low'` when LLM is uncertain or resolved date falls outside scheduling window. 2500ms timeout raises TIMEOUT error for NFR-P3 compliance.
- API: `POST /v1/tasks/:id/schedule/nudge` is proposal-only — no DB writes, no calendar sync. Returns 422 for low confidence and LLM timeout. `POST /v1/tasks/:id/schedule/nudge/confirm` commits the change by re-running the full schedule with the locked time.
- `runScheduleForUser` extended with optional `options?: RunScheduleOptions` param. Existing callers unaffected.
- Flutter: `NudgeProposal` domain model + `NudgeProposalDto` DTO created with freezed. `SchedulingRepository` extended with `proposeNudge()` and `confirmNudge()`. Build runner generated all `.freezed.dart` and `.g.dart` files.
- Flutter: `NudgeInputSheet` handles idle → loading → proposal/low-confidence/error states. Uses `surfacePrimary` for background. `showModalBottomSheet` for presentation. `onApplied` triggers `todayProvider.refresh()`.
- Flutter: `TodayTaskRow` extended with `onNudge` callback. When provided, trailing swipe shows sparkle icon and opens `NudgeInputSheet` instead of date picker.
- Flutter: Motion tokens — `MotionTokens` class with constants only, `isReducedMotion()` helper. `_RevealAnimation` widget: staggered fade+slide via `Future.delayed`, instant at Reduce Motion. `_PlanShiftsAnimation`: colour flash via `ColorFiltered` + `AnimatedBuilder`. Both use `SingleTickerProviderStateMixin` + `didChangeDependencies` pattern from ChapterBreakScreen.
- Flutter: 22 new widget tests across 3 test files. All pass. API: 11 new route tests. All 150 API tests pass.

### File List

**packages/ai — new/modified:**
- `packages/ai/package.json` (modified — added ai, @ai-sdk/openai, zod, vitest, coverage deps)
- `packages/ai/vitest.config.ts` (new — 100% coverage threshold)
- `packages/ai/src/index.ts` (modified — exports parseSchedulingNudge, NudgeInput, NudgeOutput, createAIProvider)
- `packages/ai/src/provider.ts` (new — createAIProvider factory)
- `packages/ai/src/nudge-parser.ts` (new — parseSchedulingNudge implementation)
- `packages/ai/src/test/nudge-parser.test.ts` (new — 11 unit tests, 100% coverage)
- `packages/ai/src/test/provider.test.ts` (new — 5 unit tests, 100% coverage)

**apps/api — modified:**
- `apps/api/package.json` (modified — added @ontask/ai workspace dep)
- `apps/api/src/services/scheduling.ts` (modified — RunScheduleOptions, optional suggestedDates param)
- `apps/api/src/routes/scheduling.ts` (modified — POST /nudge and POST /nudge/confirm routes)
- `apps/api/test/routes/scheduling-nudge.test.ts` (new — 11 route tests)

**apps/flutter — new/modified:**
- `apps/flutter/lib/core/l10n/strings.dart` (modified — todayRowNudge, nudgeSheetTitle, nudgeConfidenceLow, nudgeError)
- `apps/flutter/lib/core/motion/motion_tokens.dart` (new — MotionTokens constants + isReducedMotion helper)
- `apps/flutter/lib/features/scheduling/domain/nudge_proposal.dart` (new — NudgeProposal freezed domain model)
- `apps/flutter/lib/features/scheduling/domain/nudge_proposal.freezed.dart` (generated)
- `apps/flutter/lib/features/scheduling/data/nudge_proposal_dto.dart` (new — NudgeProposalDto freezed DTO)
- `apps/flutter/lib/features/scheduling/data/nudge_proposal_dto.freezed.dart` (generated)
- `apps/flutter/lib/features/scheduling/data/nudge_proposal_dto.g.dart` (generated)
- `apps/flutter/lib/features/scheduling/data/scheduling_repository.dart` (modified — proposeNudge, confirmNudge)
- `apps/flutter/lib/features/scheduling/data/scheduling_repository.g.dart` (regenerated — no changes)
- `apps/flutter/lib/features/scheduling/presentation/widgets/nudge_input_sheet.dart` (new — NudgeInputSheet widget)
- `apps/flutter/lib/features/today/presentation/today_screen.dart` (modified — reveal animation, plan shifts, onNudge wiring)
- `apps/flutter/lib/features/today/presentation/widgets/today_task_row.dart` (modified — onNudge parameter + swipe action)
- `apps/flutter/test/core/motion/motion_tokens_test.dart` (new — 5 tests)
- `apps/flutter/test/features/today/today_reveal_animation_test.dart` (new — 3 reveal tests + 3 constants tests)
- `apps/flutter/test/features/scheduling/nudge_input_sheet_test.dart` (new — 12 widget tests)

**sprint status:**
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (modified — 3-7 → review)

## Change Log

- 2026-03-31: Story 3.7 created — Natural Language Scheduling Nudges & Motion Tokens
- 2026-03-31: Story 3.7 implemented — NLP nudge parser, API endpoints, Flutter UI, motion tokens
