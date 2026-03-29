---
title: "Product Brief: On Task"
status: "complete"
created: "2026-03-29"
updated: "2026-03-29"
inputs: ["user-discovery-session", "competitive-research-web", "behavioral-economics-literature", "nuj-beeminder-payment-research", "epic-v-apple-research"]
---

# Product Brief: On Task

> *Stop planning. Start doing.*

## Executive Summary

Most people don't have a task *capture* problem — they have a task *execution* problem. The apps they use are excellent at collecting to-dos and miserable at actually getting them done. They hand the user a list of 50 items and leave them to figure out what to do next, when to do it, and how to get their partner to stop asking whose turn it is to call the plumber.

On Task is a task management and intelligent scheduling application for macOS and iOS that solves execution, not just organization. It automatically schedules work around your existing commitments, coordinates shared responsibilities between partners and friends with fairness built in, and — uniquely — lets users put real money on the line to ensure the things that matter actually happen. Missed a committed task? Fifty percent of your stake goes to a charity of your choice. The rest? A gentle but honest reminder that commitments have weight.

The market timing is exceptional. Motion has pivoted toward enterprise AI agents, vacating the personal user market. SkedPal proved the scheduling concept but never delivered on UX. Forfeit and Beeminder proved the accountability concept but never delivered a complete task management experience. On Task is the product all of them gestured toward but never built.

## The Problem

**Decision fatigue is the enemy of getting things done.** Research consistently identifies task *initiation* — not lack of desire or discipline — as the primary failure mode. Opening a task app, scanning a disorganized list, deciding what to prioritize, figuring out when to do it, and negotiating with a partner about who's responsible: these are not small cognitive costs. For the 20–30% of adults who experience meaningful executive dysfunction — including ADHD, autism, anxiety, depression, or simply the ambient pressure of modern life — they can be paralyzing.

Consider a realistic scenario: two partners sharing a home. One uses SkedPal for personal tasks. The other uses a notes app. Chores are assigned by whoever remembers first, creating invisible scorecards and ambient resentment. Neither knows what the other has planned for the weekend. A dog needs medication at 8am, a home renovation has fifteen subtasks with no clear owner, and neither person can see when any of it will actually get done.

The status quo costs real time, real relationship friction, and — for users who experience executive dysfunction — real psychological harm.

## The Solution

On Task is built around three interlocking ideas:

**1. Intelligent Scheduling.**
Users capture tasks — in natural language, by voice, or via the REST API or MCP server — and On Task schedules them. It reads your Google Calendar, finds available time, respects energy preferences and time-of-day constraints (e.g., "give the dog her medication at 8am"), and blocks time on your calendar. When meetings move or tasks slip, the schedule adapts. A "predicted completion date" on any task or section turns a looming unknown into a bounded fact; a Gantt-style view is available for power users managing longer projects.

**2. Shared Lists with Built-In Fairness.**
Any list can be shared with partners, family members, or friends. Recurring tasks are assigned to a group with configurable strategies: round-robin, least-busy, or AI-assisted balancing. On Task ensures the same task is never double-assigned in the same window. Each assignee's tasks integrate into their own personal schedule automatically. Accountability settings cascade from list to section to task — a household sets a default stake once and it's inherited everywhere, overridden only when a specific task warrants it.

**3. Commitment Contracts.**
When a task truly matters, users can attach a financial stake. They authorize an amount against a saved payment method — set up via web, charged server-side via Stripe, no Apple cut — and commit. If the task is verified complete, the charge does not occur. If it isn't, 50% of the stake is donated to a user-chosen charity (via Every.org), and 50% is retained by On Task. On Task is the charitable donor; users see a lifetime impact dashboard showing how much has gone to their cause of choice. A dispute flow handles contested AI verdicts; human review is available as a no-questions-asked escalation. Proof assets are not retained beyond the task lifecycle.

**Proof of completion** is deliberately flexible — the friction of proving a task should never exceed the friction of doing it:

- *Photo or video* — taken in-app, AI-verified against the task description
- *Watch Mode* — the camera runs passively while the user works, the AI monitors via periodic frames; the digital equivalent of body doubling, with nothing to start or stop. Available both as a proof mechanism for staked tasks and as a standalone focus mode.
- *Integration-verified* — tasks confirmed automatically via Apple HealthKit, Fitbit, or similar (a workout logged, medication recorded, activity completed)
- *Screenshot / document* — for tasks with digital outputs (email sent, bill paid, form submitted)

**Shared accountability** extends commitment contracts to groups. Modes:
- *Individual stakes, group-approved* — each member sets their own amount; the group reviews and approves the full arrangement before any commitment activates. If I fail my task, I pay my $5; others pay nothing.
- *Pool mode* — the group collectively stakes against a shared list or section; if any member fails their task, all members are charged according to their agreed stake.

All accountability modes can be layered with social enforcement: notify an accountability partner, text a friend, or post to social media.

## What Makes This Different

| Dimension | The Gap | On Task's Position |
|---|---|---|
| Auto-scheduling | SkedPal works; UX is broken. Motion pivoted to enterprise. | Consumer-grade UX + intelligent scheduling for personal users |
| Shared task coordination | No app pairs shared lists with fairness logic and personal scheduling | Built-in for couples, households, and friend groups |
| Financial accountability | Beeminder/Forfeit: accountability without task management | Complete task management *plus* opt-in financial commitment devices |
| Proof verification | No consumer app combines AI verification, Watch Mode, and integration-based auto-completion | Zero-friction proof for every task type |
| Executive dysfunction UX | Tiimo has beautiful design but no power; everyone else ignores this user | Minimized decision points, calm UI, body doubling built in |
| Platform incumbents | Apple Reminders + Calendar are free and native, but dumb | Depth Apple can't match without a full product redesign |

The moat is execution quality and the integration of features no competitor has combined. There is no technical barrier to replication — but building all of this well, in a single coherent consumer experience, is a significant execution advantage.

## Who This Serves

**Primary: The Organized-But-Overwhelmed Individual.**
A 28–45 year old who has tried multiple productivity apps and abandoned most of them. Often ADHD, autistic, anxious, or simply cognitively overloaded. They know *what* needs doing — they need the app to tell them *when* and to help them actually start. They want something that feels calm, not clinical.

**Primary: Coordinating Couples and Households.**
Two people managing a shared life. The problem isn't motivation — it's the mental load: invisible coordination overhead that accumulates unevenly and creates ambient friction. Shared consequences (both partners staked on a household task) make accountability a shared commitment rather than individual nagging.

**Secondary: Accountability-First Users.**
People who know financial commitment devices work for them but want a complete task management experience — not Beeminder's dated UI or Forfeit's thin feature set.

On Task is explicitly *not* designed for businesses managing employee workloads.

## Success Criteria

**User success signals:**
- Task completion rate, staked vs. unstaked (expect 2–3x lift per behavioral economics literature)
- Shared list adoption rate among new users
- Watch Mode activation rate (proxy for executive dysfunction user engagement)
- Scheduling acceptance rate (% of AI-suggested slots accepted)
- 30/60/90-day retention, with focus on users who have set at least one commitment stake

**Business metrics:**
- MRR and tier mix (Individual / Couple / Family & Friends)
- Commitment penalty revenue (validates accountability feature is actively used)
- Charitable impact total (marketing asset; On Task's charitable giving record)
- NPS among users who have completed at least one AI-verified task

## Scope: v1 (macOS + iOS)

**In:**
- Task capture, natural language, AI-powered
- Google Calendar two-way sync and intelligent scheduling
- Time-of-day constraints; infinitely nested sections and subtasks
- Shared lists with assignment strategies; accountability inheritance (list → section → task)
- Commitment contracts: Stripe off-session charges, 50/50 charity split via Every.org, impact dashboard
- Proof modes: photo/video (AI), Watch Mode (passive camera, focus + proof), HealthKit integration-verified
- Dispute flow with human review escalation
- Shared accountability: individual-stakes-group-approved and pool modes
- REST API (OpenAPI) and MCP server
- Predicted completion dates for tasks and sections
- Pricing tiers: Individual (~$5/mo), Couple, Family & Friends

## Scope: v2 (and beyond)

- Android, Windows, Linux, web clients (architecture supports from day one)
- Gantt timeline view
- Social enforcement modes (text friends, post to social)
- Anti-charity stakes option
- Pool payouts — competitive pool mode where forfeited stakes redistribute to the group based on completion performance (complete all your tasks: full refund; complete the most: highest share of the pool). Designed for households, roommates, and friend groups where a little healthy competition reinforces the fairness engine.
- Fitbit and additional health/fitness integrations
- Outlook calendar integration

## Roadmap Thinking

The natural next layer is full social accountability: partners who receive proof notifications and can confirm or dispute completion, plus social enforcement modes. Watch Mode as a standalone focus product — body doubling, on demand — opens a broader wellbeing angle and a distinct growth channel through the ADHD and neurodivergent community.

The MCP server and REST API are also distribution. On Task is the task manager that AI agents can natively read and write — the place work lands when a model identifies something that needs to happen. No competitor currently occupies this position.

The two-sided revenue model aligns incentives correctly: build tools that help users commit to the right things at the right stakes, because users who succeed stay, and the charitable impact record becomes a compounding brand asset.

---

*ontaskhq.com — For people who mean it.*
