---
stepsCompleted: ['step-01-init', 'step-02-discovery', 'step-02b-vision', 'step-02c-executive-summary', 'step-03-success', 'step-04-journeys', 'step-05-domain', 'step-06-innovation', 'step-07-project-type', 'step-08-scoping', 'step-09-functional', 'step-10-nonfunctional', 'step-11-polish']
inputDocuments:
  - '_bmad-output/planning-artifacts/product-brief-ontask.md'
  - '_bmad-output/planning-artifacts/product-brief-ontask-distillate.md'
workflowType: 'prd'
briefCount: 2
researchCount: 0
brainstormingCount: 0
projectDocsCount: 0
classification:
  projectType: 'mobile_app+api_backend'
  domain: 'consumer-productivity-fintech'
  complexity: 'high'
  projectContext: 'greenfield'
---

# Product Requirements Document - ontask

**Author:** Matt
**Date:** 2026-03-29

## Executive Summary

On Task is a task management and intelligent scheduling application for macOS and iOS, built by and for people with executive dysfunction. The product addresses a specific, underserved failure mode: not the inability to capture tasks, but the inability to initiate them. Decision fatigue — *what do I do next, when do I do it, who's responsible* — is the real enemy. On Task eliminates those decisions before they happen.

Three interlocking capabilities define the product:

1. **Intelligent scheduling** — Tasks are auto-scheduled around existing calendar commitments using a deterministic constraint-based algorithm. Natural language capture (in-app or via MCP) feeds tasks directly into a personal schedule. Every task and section carries a calm, honest predicted completion date. When life shifts, the schedule adapts.

2. **Shared lists with built-in fairness** — Any list can be shared with partners, family, or friends. Recurring tasks are auto-assigned via configurable strategies (round-robin, least-busy, AI-assisted). The same task is never double-assigned. Each assignee's tasks integrate into their personal schedule automatically. Accountability settings cascade from list to section to task — one default, overridden only when needed.

3. **Commitment contracts** — When a task truly matters, users *lock it in*: they pre-authorize a financial stake via Stripe, set proof mode, and commit. At execution time, there are no decisions left — the choice was already made. If the task is verified complete, no charge occurs. If not, 50% of the stake goes to a user-chosen charity; 50% is retained by On Task. This is not a punishment mechanism — it is a cognitive offloading device that eliminates choice at the moment execution would otherwise fail.

**Who this is for:** The organized-but-overwhelmed individual (28–45, often ADHD, autistic, anxious, or experiencing executive dysfunction of any origin); coordinating couples and households where the invisible mental load accumulates unevenly; and accountability-first users who know commitment devices work for them but need a complete task management experience.

**What this is not:** An enterprise tool. A gamified system. A product that judges you. The tone is calm, not clinical. The stakes are *pre-made decisions*, not punishments.

**Why now:** Motion has pivoted to enterprise AI agents, vacating the personal user market. SkedPal proved the scheduling concept but stagnated. Beeminder and Forfeit proved commitment devices work but never delivered a complete experience. The Post-Epic v. Apple ruling enables smooth in-app links to web-based payment setup, unlocking the commitment contract UX. On Task occupies a gap that has been widening for two years.

### What Makes This Special

No competitor has combined intelligent auto-scheduling, shared household fairness, and financial commitment contracts in a single consumer experience. The moat is not technical novelty — it is execution quality and integration completeness.

The core insight: this is *cognitive offloading* software, not accountability software. The mental model is locking a game controller in a drawer — removing the choice so there is nothing to agonize over when the moment arrives. By the time a committed task is due, every decision has already been made: when it's scheduled, who's responsible, what the stake is, how completion will be verified. The user's only remaining job is the task itself.

This design philosophy pervades the product:
- Scheduling is automatic, not manual
- Accountability settings cascade by default
- Proof mode is chosen at commitment time, not at completion time
- Watch Mode requires nothing to start or stop — the camera runs, the AI monitors, the user just works

The primary distribution channels are the App Store (iOS/macOS) and AI assistant integrations via MCP server — making On Task the task manager that AI agents can natively read and write.

## Project Classification

| Dimension | Value |
|---|---|
| **Project Type** | Mobile app (iOS/macOS native) + REST API + MCP server |
| **Domain** | Consumer productivity with embedded fintech |
| **Complexity** | High — AI-verified proof, deterministic scheduling algorithm, two-way calendar sync, multi-user shared accountability, payment compliance (US-only due to regulatory uncertainty) |
| **Project Context** | Greenfield |

## Success Criteria

### User Success

- **NPS > 50** among users active for 30+ days — world-class consumer app territory; the product either delights or it doesn't
- **Staked task completion rate ≥ 2× unstaked** — validates the commitment contract mechanism against behavioral economics baseline
- **Scheduling acceptance rate** — high percentage of auto-scheduled time blocks kept without manual adjustment; tracks whether the scheduling engine earns user trust
- **30/60/90-day retention** — tracked with specific focus on users who have set at least one commitment stake, as these users have the strongest signal of intent
- **Month-over-month active user growth** — the user base is growing, not just signing up and churning

### Business Success

- **Subscription revenue covers unit economics** — per-user revenue (Individual tier target: ~$10/mo; Couple and Family & Friends TBD) must cover inference costs, backend infrastructure, and a small profit margin. Exact pricing to be validated during development once inference cost modeling is complete.
- **Tier mix** — tracked across Individual, Couple, and Family & Friends to understand adoption patterns and inform future pricing decisions
- **MRR growth** — month-over-month recurring revenue growth post-launch

> **Note:** Commitment penalty revenue and charitable impact totals are intentional non-metrics — these are byproducts of task failure, not indicators of product success.

### Technical Success

- **Native-feel UI on iOS and macOS** — the bar is indistinguishable from a system app (Things 3, Fantastical). Fluid animations, responsive interactions, platform conventions respected. This is a hard requirement, not an aspiration.
- **Cross-platform-ready architecture** — Android, Windows, Linux, and web are not v1 targets, but the architecture must support them without rewrites. Platform-specific UI layers may differ; the core must be portable.
- **Payment reliability** — Stripe off-session charges must fire with near-zero failure rate. A missed charge or erroneous charge at a critical moment is trust-destroying and potentially legally complex.
- **Scheduling accuracy** — tasks scheduled into genuinely free calendar time; no double-booking, no conflicts with existing events.
- **AI verification accuracy** — false negative rate (valid proof incorrectly rejected) must be low enough that disputes are rare and exceptional, not routine.

### Measurable Outcomes

| Metric | Target |
|---|---|
| NPS (30+ day active users) | > 50 |
| Staked vs. unstaked completion rate | ≥ 2× lift |
| 90-day retention | TBD at launch baseline |
| Unit economics breakeven | Subscription revenue > (inference + infra costs) per user |
| Active user growth | Positive MoM after launch |

## Product Scope

### V1 — MVP

The complete daily-driver release. No further reduction — this is the minimum scope at which the product can be meaningfully dog-fooded and iterated on.

- Task capture with natural language, AI-powered
- Google Calendar two-way sync and intelligent auto-scheduling
- Time-of-day constraints; infinitely nested sections and subtasks
- Shared lists with assignment strategies (round-robin, least-busy, AI-assisted); accountability inheritance (list → section → task)
- Commitment contracts: Stripe off-session charges, 50/50 charity split via Every.org, lifetime impact dashboard
- Proof modes: photo/video (AI-verified), Watch Mode (passive camera; focus mode and proof mechanism), HealthKit integration-verified
- Dispute flow with human review escalation
- Shared accountability: individual-stakes-group-approved and pool modes
- REST API (OpenAPI spec) and MCP server
- Predicted completion dates for tasks and sections
- Pricing tiers: Individual (~$10/mo subject to validation), Couple, Family & Friends

### V2 — Growth

- Android, Windows, Linux, and web clients
- Gantt timeline view
- Social enforcement modes (notify accountability partner, text a friend, post to social)
- Anti-charity stakes (optional — money to a cause the user opposes)
- Pool payouts — competitive redistribution of forfeited stakes based on completion performance
- Fitbit and additional health/fitness integrations
- Outlook calendar integration

### V3 — Vision

- Additional calendar, health, and productivity integrations
- Advanced scheduling insights and analytics
- Platform-specific enhancements as native ecosystems evolve
- Expanded social and community features

## User Journeys

> **Note on commitment contracts:** Commitment contracts are an opt-in layer. On Task is a first-class task management and scheduling app for users who never set a single stake. The scheduling, shared lists, and predicted completion features stand entirely on their own. Commitment contracts are available when a user wants them — they are never the default, never assumed, and never required.

> **Note on task types:** One-off tasks and recurring tasks are equally first-class. A task to "grout the bathroom tiles" is as well-supported as a daily exercise habit. Due dates, scheduling, and commitment contracts apply to both.

### Journey 1: The Overwhelmed Individual (Primary — Success Path)

**Persona: Alex**, 34. Has ADHD, diagnosed two years ago. Tried Things, Todoist, and Notion. All of them became graveyards — perfectly organized lists they never looked at. The problem isn't capturing tasks. It's that opening the app and deciding *what to do right now* takes more energy than the task itself.

**Opening Scene:** It's Sunday evening. Alex has 23 items in their head: a work report due Wednesday, a dentist appointment to schedule, a car registration that's three weeks overdue, and a text from their partner about the dog's vet visit. They open On Task and start typing. "Schedule dentist. Car registration before end of month. Finish Q3 report — probably 4 hours. Dog vet, needs to happen this week."

**Rising Action:** On Task parses each entry. It reads Alex's Google Calendar — two evening meetings this week, a packed Tuesday. It schedules: car registration Monday morning (30 min, low energy task, scheduled for 9am when Alex has a free slot). Dentist call Tuesday lunch. Dog vet Wednesday afternoon. The Q3 report gets blocked across Thursday in two 2-hour chunks. Alex's calendar now has those blocks. They didn't choose the times — On Task did.

Alex sees the predicted completion dates on each item. The report: Thursday. The registration: Monday. For the first time in weeks, the list doesn't feel like a wall — it feels like a plan.

**Climax:** Thursday morning. Alex sits down to work on the report. The commitment they set — $15 to a climate charity if not submitted by 6pm — is already locked in. There's nothing to decide. The choice was made on Sunday. They open the draft and start writing.

**Resolution:** At 5:45pm Alex submits the report and uploads a screenshot of the submission confirmation. On Task reads the text in the image, confirms the task, and the charge never fires. The stake is released. Alex sees their impact dashboard: $0 charged this week, three tasks completed on schedule. The app didn't nag them. It just held the space.

**Capabilities revealed:** Natural language task capture, AI scheduling around calendar, time-block writing to calendar, predicted completion dates, commitment contract creation, screenshot/document proof verification, charge release on verification.

---

### Journey 2: The Coordinating Couple (Primary — Success Path)

**Personas: Jordan & Sam**, both in their early 30s. Jordan has ADHD; Sam is autistic and gets overwhelmed by ambiguity. They share a home, a dog, a renovation in progress, and a growing stack of things neither person is sure the other has handled. The resentment isn't dramatic — it's ambient. "Did you call about the tiles?" "I thought you were doing that."

**Opening Scene:** Jordan creates a shared list: **"Home Renovations."** Inside it, they add a section: **"Q2."** The section has a default due date of June 30 — every task without a specific due date inherits it. Some tasks have their own dates: "Order bathroom tiles" is due May 1 because everything else depends on it. Others just inherit the section default. The predicted completion date for the Q2 section is 9 weeks from now.

Jordan invites Sam. Sam accepts and sees the list — including the four tasks already assigned to them by round-robin, already scheduled into their week.

**Rising Action:** When Sam's calendar gets busy mid-month with a work deadline, On Task automatically routes the next round-robin assignment to Jordan instead. Sam doesn't have to ask. Jordan doesn't have to notice.

Jordan sets a household accountability default on the list: $10 stake per task, photo proof. Sam reviews the arrangement — Jordan: $10/task, Sam: $10/task — and approves it. Both are committed. If either misses a task, only that person's stake fires. The other is unaffected.

**Climax:** Sam finishes grouting the bathroom tiles. They take a photo in-app — the finished wall, timestamp embedded. On Task's AI reads it against "grout bathroom tiles" and confirms completion. Sam's $10 stake is released.

Jordan taps the completed task later that evening and sees Sam's photo — the clean grout lines, the finished wall. Not as evidence. As a record. The renovation is becoming a quiet visual history of what they've built together.

**Resolution:** Eight weeks in, the renovation is on track. The predicted completion date moved from 9 weeks to 7. Neither partner has had to ask the other "did you do that thing?" in weeks. The app holds that question so they don't have to.

**Capabilities revealed:** Shared list and section creation, user invitation and onboarding, due date inheritance (task ← section ← list), round-robin assignment, least-busy rebalancing, per-user schedule integration, list-level accountability defaults, group approval flow, photo proof capture and AI verification, proof photo retention as completion record visible to all list members, partner completion notifications, predicted completion dates at section level.

---

### Journey 3: The Accountability-First Power User (Secondary — Success Path)

**Persona: Morgan**, 41. Has used Beeminder for four years. Knows — with certainty — that financial stakes work for them. But Beeminder has no task management, no scheduling, no mobile experience worth using. Morgan tracks goals in Beeminder and tasks in a separate app and manually bridges them. It's exhausting.

**Opening Scene:** Morgan hears about On Task. The pitch — "scheduling + commitment contracts, native iOS" — is the product they've been waiting for. They sign up, connect Google Calendar, and within 20 minutes have migrated their top five recurring commitments: daily exercise, weekly review, two work deliverables, and a language learning habit.

**Rising Action:** Morgan is immediately drawn to the stake calibration. They set stakes deliberately: $25 on the weekly review (high-value, easily skipped), $10 on exercise (meaningful but not devastating), $5 on the language habit (motivation boost, not a real threat). For the weekly review, they choose Watch Mode — they work better with passive accountability than a photo to take at the end.

**Climax:** Tuesday. Morgan sits down for the weekly review. Watch Mode activates — the camera runs silently, the AI monitors periodically. Morgan knows it's there. That's enough. Forty minutes later, the session closes automatically. Task verified. No charge.

**Resolution:** Morgan exports their impact dashboard at month end: 0 charges, 23 tasks completed. They cancel their Beeminder subscription.

**Capabilities revealed:** Watch Mode as standalone focus and proof mechanism, stake calibration, multiple proof mode selection per task, recurring task scheduling, impact dashboard.

---

### Journey 4: The Dispute Filer (Primary — Edge Case)

**Persona: Riley**, 29. Set a $20 stake on "clean and vacuum the living room." Spent 45 minutes doing it. Took a photo in-app — clean floor, visible vacuum in the corner, timestamp. On Task's AI reviewed the image and rejected it.

**Opening Scene:** Riley sees the rejection notification. Their immediate reaction: disbelief, then frustration. The room is clean. They did the work. The $20 charge is pending.

**Rising Action:** The app presents one option: **"Request a review."** Tapping it opens a short form:

> *"No questions asked — if the app got this wrong, we want to fix it. A brief note about what happened is helpful if there's something we can improve, but it's not required."*

There's a single text field. Riley types: "I vacuumed the whole room, the photo shows the vacuum and the clean floor." No proof re-submission required. No interrogation. They submit and wait.

**Climax:** Within 24 hours, a human reviewer sees the original photo and Riley's note. The task was clearly completed — the AI made an error. One action: mark complete, cancel pending charge. Riley is notified.

**Resolution:** The charge never fired. Riley didn't have to prove themselves. The review existed as a safety valve — present, accessible, frictionless enough to use in good faith.

**The emergency case:** If Riley had missed the task because of a hospitalization, the same flow applies. The form might say: "Was in hospital — couldn't do it." No proof, no judgment. The review is approved. On Task's position: a product built for people who struggle to do things should never punish them harder when life genuinely intervenes. This is a marketing commitment as much as a product policy.

**Capabilities revealed:** Dispute initiation flow (no proof re-submission required), human review queue, reviewer tooling (approve/reject, view original proof and user note), charge hold during dispute, charge cancellation on successful dispute, "no questions asked" copy as a product-level commitment, reviewer guidelines covering emergency cases, SLA for resolution.

---

### Journey 5: The API / MCP Consumer (Technical — Integration Path)

**Persona: A user of Claude** (or another AI assistant) who has connected On Task via MCP. They don't open the On Task app — they talk to their AI assistant.

**Opening Scene:** "Hey Claude, I need to get the apartment ready for guests arriving Saturday. Can you add the tasks and figure out when I can do them?"

**Rising Action:** Claude calls the On Task MCP server. It creates a set of tasks — clean bathroom, change bedsheets, buy groceries, tidy living room — using the same natural language parsing the in-app experience uses. On Task schedules them against the user's calendar. Claude reports back: "Done — I've added 4 tasks. The grocery run is scheduled for Friday afternoon, everything else is Thursday evening."

**Climax:** The user asks: "Can you put $5 on the grocery run? I keep forgetting that one." Claude calls the MCP commitment endpoint. On Task confirms the user has a saved payment method on file, creates the commitment contract, and returns confirmation.

**Resolution:** The user never opened the On Task app. Their tasks are scheduled, one has a stake, and their calendar has the blocks. On Task is the task layer underneath their AI assistant workflow.

**Capabilities revealed:** Full MCP server exposing task creation, scheduling, and commitment contract creation; NLP task parsing via API (identical to in-app); calendar block writing via API; commitment creation via API (requires existing saved payment method); API authentication.

---

### Journey 6: On Task Operator (Internal — Admin/Ops)

**Persona: The operator** (initially the founder; potentially a small support team later). Responsible for payment health, dispute resolution, and troubleshooting user issues.

**Opening Scene:** A charge fails. Stripe webhook fires. The operator dashboard surfaces the alert: user, task, amount, failure reason (card expired). A separate alert: a user has filed a dispute and is awaiting human review.

**Rising Action:** The operator opens the dispute queue. They see the user's submitted proof and note. The task was clearly completed. One click: mark complete, cancel pending charge. The system notifies the user automatically.

For the payment failure, the operator can view the task record and retry or reverse the charge as appropriate.

For complex support issues, the operator can impersonate a user account — with full audit logging — to reproduce what the user is seeing without requiring the user to describe it.

**Climax:** A user reports being double-charged. The operator impersonates the account, sees two commitment contracts on the same task (a bug), confirms the error, and reverses one charge. The user gets a refund. Total resolution time: under 10 minutes.

**Resolution:** The operator dashboard isn't glamorous, but it gives the operator the tools to uphold trust: fair dispute resolution, correct payment handling, fast debugging. Without it, every edge case becomes a manual, error-prone email thread.

**Capabilities revealed:** Operator dashboard (web-based), dispute review queue, charge reversal and refund issuance, user account impersonation with audit log, payment failure alerts, task and proof audit trail.

---

### Journey Requirements Summary

| Journey | Key Capabilities Revealed |
|---|---|
| Alex (individual) | NLP capture, auto-scheduling, calendar write, commitment contracts, screenshot proof, charge release |
| Jordan & Sam (couple) | Shared lists, due date inheritance, invite flow, round-robin + least-busy, group approval, proof as completion record |
| Morgan (power user) | Watch Mode (focus + proof), stake calibration, recurring tasks, impact dashboard |
| Riley (dispute filer) | No-proof dispute flow, "no questions asked" policy, human review queue, charge hold and cancellation, emergency case handling |
| API/MCP consumer | MCP server, API parity with in-app, commitment creation via API, auth |
| Operator | Admin dashboard, dispute queue, charge reversal/refund, user impersonation with audit log |

## Domain-Specific Requirements

### Payment & Financial Compliance

- **PCI DSS:** On Task never handles raw card data. All payment method storage uses Stripe SetupIntent (web-based); all charges use Stripe PaymentIntent (server-side, off-session). PCI scope is minimized to SAQ A level.
- **Off-session charge model:** User consents to a specific charge amount at task creation time. Charge fires server-side at deadline if task is not verified complete. This is the Beeminder/Nuj model — established precedent in the commitment contract space.
- **Geographic restriction (v1):** US-only. Financial penalty mechanics may require financial services licensing or be classified as gambling in other jurisdictions. No architecture decisions should foreclose future expansion, but compliance for non-US markets is deferred to v2+.
- **Tax treatment:** On Task receives the full penalty amount from Stripe, donates 50% to the user's chosen charity via Every.org, and retains 50% as revenue. On Task is the charitable donor and takes the deduction. Users are not donors — they paid a penalty. No tax receipts are issued to users. This model follows the established Panda Express/cause-marketing precedent.
- **Every.org integration:** Charity disbursement via Every.org API. Requires a documented fallback for API downtime at charge time — funds must be held and disbursed correctly even if the disbursement API is temporarily unavailable.
- **Charge transparency:** Users must see clearly at commitment creation: the exact amount, the trigger condition, the charity recipient, and the timing. No surprises at charge time.

### Privacy & Data Handling

- **Proof media retention:** Proof photos and video submitted for AI verification are retained for the lifetime of the task by default. At proof submission, users are offered a checkbox: *"Attach to completed task"* — if selected, the media persists as a completion record on the task. If not selected, media is purged after verification. This reconciles the privacy default (don't retain what you don't need) with the shared-list trophy use case.
- **Watch Mode — cloud processing:** Watch Mode frames are processed via cloud-based multimodal AI (not on-device). Watch Mode activation requires a one-time camera permission prompt (OS-level). The activation UI leads with the value: *"AI body double — your camera runs quietly in the background while you work."* Technical details of what is captured, processing frequency, and data handling are available via a "Learn more" link within the feature — accessible but not intrusive. Detailed mechanics live in documentation and the privacy policy, not in the activation flow. Radical transparency at the surface can create anxiety rather than trust; the goal is informed availability, not a consent wall.
- **Watch Mode data:** Individual frames are processed and discarded; no continuous video is stored. Session metadata (start time, end time, task, verification result) is retained as part of the task record.
- **Sensitive audience consideration:** The ADHD/mental health audience has heightened sensitivity to data misuse. Privacy disclosures must be plain-language and accessible, not buried in terms of service. The product should never feel like it is surveilling the user.
- **GDPR/CCPA:** Deferred to v2. Architecture should not foreclose compliance, but specific data residency and consent framework requirements are not in v1 scope.

### App Store Compliance

- **No Apple IAP for commitment contracts:** Financial/behavioral penalty services are not "digital content" under App Store rules. The Post-Epic v. Apple ruling explicitly permits in-app links to external web payment setup. Commitment contract payment method setup occurs via web-based Stripe SetupIntent; the app may link to this flow directly.
- **App Store review risk:** The commitment contract model is novel but has precedent (Beeminder, Nuj). App Store submission should document the model clearly. Legal review of App Store guidelines recommended before submission.

### Compliance & Risk Summary

| Area | v1 Requirement | Deferred |
|---|---|---|
| Payment processing | Stripe only, off-session model, PCI SAQ A | — |
| Geographic scope | US-only | Non-US markets (v2+) |
| Tax treatment | On Task as donor, no user receipts | — |
| Proof media | Retained per task lifetime, user-configurable | — |
| Watch Mode | Cloud processing, "Learn more" transparency, frames not retained | On-device option (v2+) |
| GDPR/CCPA | Architecture must not foreclose | Full compliance (v2+) |
| App Store | Web payment setup, link permitted post-Epic | — |

## Innovation & Novel Patterns

### Detected Innovation Areas

**1. Watch Mode — Digital Body Doubling**
Body doubling is a well-established ADHD community practice: working alongside another person provides enough ambient accountability to sustain focus. No consumer productivity app has implemented a digital, asynchronous equivalent. Watch Mode is the first: the camera runs passively, AI monitors periodically, and the user simply works. Nothing to start, nothing to stop. It functions as both a proof mechanism for staked tasks and a standalone focus mode available without any financial commitment.

**2. Cognitive Offloading — Not Accountability**
Every competitor in the commitment device space uses the language of accountability: *hold yourself accountable, be accountable to your goals.* On Task's framing is fundamentally different: **removing the choice so you don't have to fight yourself at the moment of execution.** The stake is a pre-made decision. By the time the task is due, there is nothing to decide — just the task. This framing has no direct equivalent in the market and is central to the non-punitive, calm product tone.

**3. Transparent, Nudgeable Scheduling Engine**
SkedPal pioneered constraint-based auto-scheduling but offers no transparency into *why* a task was scheduled when it was, and no mechanism to request changes without manually rescheduling. On Task will expose both:
- **Scheduling explanations:** Users can see why a task landed at a specific time — what constraints shaped the decision (calendar events, energy preferences, due dates, task duration).
- **Nudging:** Users can request adjustments in natural language — "move this to tomorrow morning" or "I'd rather do this after lunch" — and the scheduler adapts while maintaining overall coherence.

This turns the scheduling engine from a black box into a collaborator. No competitor currently offers this combination.

**4. MCP Server as Distribution Channel**
On Task is being built as the native task layer for AI assistants. The MCP server exposes task creation, scheduling, and commitment contracts to any compatible AI agent — Claude, and others. A user who asks their AI assistant to capture a task, schedule it, or stake it gets the full On Task experience without opening the app. This is a distribution model with no direct competitor.

**5. AI-Verified Proof for Everyday Personal Tasks**
Applying multimodal AI verification to ordinary personal tasks — not just fitness goals or physical check-ins — at consumer scale is novel. Forfeit does this narrowly and for physical tasks only. On Task generalizes it: any task with a describable output can have AI-verified proof, from a grouted tile to a submitted report to a completed workout.

### Market Context & Competitive Landscape

On Task occupies the intersection of three validated but fragmented markets:
- **Auto-scheduling:** SkedPal proved demand; stagnated on UX and single-user limitation. Motion validated premium pricing (~$19/mo) then pivoted to enterprise, vacating the personal market.
- **Commitment devices:** Beeminder (10+ years) and StickK (Yale research) prove financial stakes work. Forfeit proves AI verification is viable. Neither delivers a complete task management experience.
- **Executive dysfunction tooling:** Tiimo proves the niche pays for great design. No app combines Tiimo's calm design sensibility with real scheduling power and commitment mechanics.

The window is open: Motion is leaving, SkedPal is stagnant, and the post-Epic v. Apple ruling unlocks the payment UX.

### Validation Approach

| Innovation | Validation Method | Timing |
|---|---|---|
| Watch Mode / body doubling | Dog-fooding by founder; iterate post-MVP based on real usage | Post-v1 |
| Cognitive offloading framing | Measured by staked task completion rate vs. unstaked (≥2× target) | v1 launch |
| Scheduling transparency + nudging | Scheduling acceptance rate; frequency of nudge usage | v1 launch |
| MCP distribution | MCP-sourced task volume as % of total task creation | v1 launch |
| AI proof verification | False negative rate; dispute volume | v1 launch |

### Risk Mitigation

| Risk | Mitigation |
|---|---|
| Watch Mode camera anxiety | "AI body double" framing leads activation UI; technical details behind "Learn more." Trust built through transparent opt-in, not forced consent. Dedicated design iteration post-MVP. |
| Scheduling engine distrust | Transparency (explain scheduling decisions) + nudging (natural language adjustments) turn the scheduler into a collaborator. Overrides tracked to identify recurring trust failures. |
| Commitment contract adoption too low | Founder is the primary validator — personal daily-driving provides real signal. Broader adoption measured by staked task rate; acceptable that a minority use stakes if the scheduling/shared list features stand alone. |
| Commitment contract stakes too high | In-app guidance toward "meaningful but not devastating" stake amounts. Anxiety caution: for ADHD/anxiety users, excessive stakes can trigger avoidance rather than completion. |
| AI verification false negatives | Accessible, no-questions-asked dispute flow as the safety valve. False negative rate monitored; high dispute volume triggers model review. |

## Mobile App + API Backend Requirements

### Platform Requirements

- **v1 targets:** iOS and macOS (native applications)
- **v2+ targets:** Android, Windows, Linux, web — architecture must support all platforms without requiring rewrites of business logic
- **Native feel target:** Indistinguishable from a system app on iOS and macOS (Things 3, Fantastical as reference bar). Great execution on a cross-platform framework is preferred over poor execution of native-only code.
- **Stack guidance (architecture decision):** Flutter is the recommended direction — single codebase, cross-platform from day one, AI-assisted development friendly, strong LLM training coverage. Final decision deferred to architecture phase. Requirement: whatever stack is chosen must support the native feel target with good execution and must not foreclose v2+ platform expansion.

### Offline Mode

| Capability | Offline Available | Notes |
|---|---|---|
| View existing tasks and schedule | Yes | Core offline use case |
| Capture new tasks | Yes | Queue locally, sync on reconnect |
| Scheduling engine | No | Server-side; deferred until online |
| Locking in commitment contracts | No | Requires online — payment authorization needed |
| Mark task complete (no proof) | Yes | Sync on reconnect |
| Submit proof offline | Yes | Queued with local timestamp; synced on reconnect. If server already fired a charge due to deadline passing while offline, server reverses charge upon receiving backdated valid proof and notifies user. Airplane-mode gaming is an accepted edge case — users willing to go to that effort are not being stopped. |

### Device Permissions

| Permission | Purpose | Required |
|---|---|---|
| Camera | Watch Mode (passive monitoring), photo/video proof capture | Required for commitment features |
| Calendar | Google Calendar two-way sync | Required for scheduling |
| HealthKit | Integration-verified proof (workouts, medication, activity) | Required for HealthKit proof mode |
| Notifications | Task reminders, deadlines, partner events, dispute outcomes | Required for proactive features |
| Face ID / Touch ID | App authentication (optional, user preference) | Optional |

### Authentication

- **Apple Sign In** — v1, primary for iOS/macOS users
- **Google Sign In** — v1, natural fit given Google Calendar dependency
- **Email/password** — v1, fallback and cross-platform compatibility
- All three options available at onboarding; user chooses

### Push Notification Strategy

Notifications are configurable at three levels — **globally** (all on/off), **per-device** (this iPhone but not this Mac), and **per-task** (notify me about this task's deadline but not that one). Users must never need to disable all app notifications to reduce overload.

**Notification types (all configurable):**
- Task reminders (before deadline, configurable lead time)
- Commitment contract deadline approaching
- Proof verification result (pass or fail)
- Dispute resolution outcome
- Partner task completion (shared lists)
- Charge processed (payment confirmation)
- Schedule change (when a task is rescheduled due to calendar conflict)

### API Architecture

- **Style:** REST, JSON, OpenAPI spec auto-generated from route definitions via `hono-openapi`
- **Versioning:** URL-based (`/v1/`, `/v2/`) — simple, cacheable, explicit
- **MCP server:** Deployed as a Cloudflare Worker; TypeScript MCP SDK. Exposes task creation, scheduling, proof submission, and commitment contract creation. NLP task parsing must be identical via MCP and in-app.
- **Authentication:** JWT tokens for REST API; OAuth per MCP specification for MCP server access (FR93)
- **Rate limiting:** Applied to API and MCP endpoints; limits TBD during implementation

**Key API surface areas:**

| Area | Endpoints (indicative) |
|---|---|
| Tasks | CRUD, bulk create, NLP parse, schedule |
| Lists & Sections | CRUD, share, assign, set defaults |
| Scheduling | Get schedule, nudge (natural language), explain slot |
| Commitment contracts | Create, cancel, get status |
| Proof | Submit (photo/video/screenshot/offline queue), Watch Mode session start/end |
| Disputes | File, get status |
| Users | Auth, profile, payment method setup redirect, notification preferences |
| Operator (internal) | Dispute review, charge reversal, user impersonation |

### Backend Architecture

**Stack:** Hono + Cloudflare Workers + Neon + Drizzle ORM + Workers KV + Cloudflare Queues + Backblaze B2 + Stripe + Every.org

| Component | Choice | Rationale |
|---|---|---|
| Framework | Hono on Cloudflare Workers | Lightweight, TypeScript-first, edge-native, serverless |
| API docs | `hono-openapi` | OpenAPI spec generated from route definitions |
| Database | Neon (serverless Postgres) | Native HTTP driver for Workers (no Hyperdrive needed), scales to zero, pay-per-compute, full Postgres |
| ORM | Drizzle | TypeScript-first, zero runtime overhead, edge-compatible, SQL-like syntax |
| Cache / sessions | Cloudflare Workers KV | Auth tokens, notification prefs, rate limiting, hot data cache |
| Job queue | Cloudflare Queues | Proof verification jobs, charge triggers, Every.org disbursement |
| Media storage | Backblaze B2 | S3-compatible, free egress to Cloudflare via Bandwidth Alliance, 60% cheaper storage than R2 |
| Payments | Stripe Node.js SDK | SetupIntent (card storage), PaymentIntent (off-session charges), webhook listener |
| Charity disbursement | Every.org API | 1.8M+ US nonprofits; queue-backed fallback for API downtime |
| Calendar | Google Calendar API | Two-way sync; push notifications or polling for changes |
| AI (proof + NLP) | Multimodal LLM (GPT-4o class) | Proof verification, Watch Mode frame analysis, NLP task parsing — abstracted behind internal interface |

## Project Scoping & Phased Development

### MVP Strategy & Philosophy

**MVP Approach:** Experience MVP — the primary validation mechanism is the founder using the product as their daily driver. The question being answered is not "will the market pay for this" but "does this reduce executive dysfunction in daily life." Commercial and market signals are secondary and follow from that.

**Success definition:** Users completing tasks in a reasonable time. Commitment contracts are one mechanism that supports this; they are not the metric. A user who completes all their tasks without ever staking money is a success story.

**Team model:** Solo founder + AI coding agents (LLMs as primary implementation tool). This is itself an experiment — validating that a complex consumer product with financial mechanics, AI integrations, and a deterministic scheduling engine can be built primarily through AI-assisted development.

### MVP Feature Set (V1)

As defined in Product Scope — the full V1 feature set is the MVP. No further reduction is viable because the founder cannot meaningfully dog-food a partial product. The V1 scope represents the minimum at which daily use is possible.

**Core user journeys supported:** All six (individual, couple, power user, dispute filer, API/MCP consumer, operator).

### Risk Mitigation Strategy

**Technical risk — Scheduling engine**

The scheduling engine is the hardest algorithmic piece and an open research question. Mitigation approach:

- **TDD-first development:** The scheduling engine is built test-first. Every constraint type, edge case, and combination gets a unit test before implementation. LLMs are well-suited to generating exhaustive test suites and implementing algorithms against them.
- **Framework design for testability:** The engine is designed as a pure function — input (tasks, constraints, calendar state) → output (scheduled blocks). No side effects, no hidden state. Easy to unit test, easy for AI coding agents to reason about.
- **Exhaustive coverage:** Every scheduling rule (time-of-day constraints, energy preferences, due dates, calendar conflicts, round-robin assignment) has explicit tests. The test suite is the specification.
- **Transparency as a forcing function:** The scheduling explanation feature (why was this scheduled here?) requires the engine to expose its reasoning — which means the reasoning must be structured and inspectable, not a black box. This is good for testing and good for the user.

**Market risk — Adoption and usage**

The product does not depend on commitment contract adoption for success. Users completing tasks in a reasonable time is the measure. Stakes are one available mechanism; the scheduling engine and shared lists must stand alone.

- Staked task completion rate vs. unstaked is a *signal*, not a gate. If unstaked task completion is already high, that's a success.
- Other accountability mechanisms (text an accountability partner) ship in V2, expanding the toolkit beyond financial stakes.

**Resource risk — Solo founder + AI agents**

This is an all-or-nothing experiment. There is no "launch without X" fallback — the V1 scope is the minimum viable daily driver. Contingency is not a reduced scope; it's extended timeline.

- AI coding agents (Claude, etc.) are the primary implementation tool. The experiment is whether a complex product can be built this way.
- TDD approach serves double duty: good engineering practice *and* a natural fit for AI-assisted development (tests as specification, AI implements against them).
- The operator dashboard and API are scoped to be minimal but complete — no gold-plating, just enough to support real usage.

### Phased Roadmap

See Product Scope section for full V1/V2/V3 breakdown.

## Functional Requirements

> **This list is binding.** UX designers will design only what's listed here. The architect will support only what's listed here. Epics and stories will implement only what's listed here. Any capability not listed does not exist in the final product unless explicitly added.

### Task & List Management

- **FR1:** Users can create tasks by directly entering a title and properties
- **FR1b:** Users can create tasks using natural language input, with the system parsing intent into structured task properties
- **FR2:** Users can organize tasks into lists, with infinitely nested sections and subtasks
- **FR3:** Users can set due dates on individual tasks; sections and lists can define default due dates inherited by tasks without specific dates
- **FR4:** Users can set time-of-day constraints on tasks (hard scheduling pins)
- **FR5:** Users can define energy and context availability preferences that constrain when different types of tasks are scheduled
- **FR6:** Users can view predicted completion dates for tasks, sections, and lists based on current workload
- **FR7:** Users can create one-off tasks and recurring tasks with equal feature parity
- **FR8:** Users can manually override a scheduled time slot for any task
- **FR55:** Users can mark a task complete without submitting proof
- **FR56:** Users can search and filter tasks across lists
- **FR57:** Users can manually reorder tasks within a section
- **FR58:** Users can edit task properties after creation
- **FR59:** Users can archive completed tasks
- **FR68:** Users can set task priority or urgency signals independent of due date
- **FR69:** Users can access a today/focus view showing tasks scheduled for the current day
- **FR73:** Users can define dependencies between tasks so the scheduler respects ordering constraints
- **FR74:** Users can perform bulk operations on multiple tasks (reschedule, complete, assign, delete)
- **FR76:** Users can explicitly begin a task, triggering relevant tracking or notifications
- **FR78:** Users can create, save, and apply list and section templates

### Intelligent Scheduling

- **FR9:** The system automatically schedules tasks into available calendar time, respecting due dates, time constraints, energy preferences, and existing events
- **FR10:** The system reads the user's connected calendar to identify available time and avoid conflicts
- **FR11:** The system writes scheduled task blocks to the user's connected calendar
- **FR12:** The system automatically reschedules tasks when calendar events shift or tasks slip past their scheduled time
- **FR13:** Users can view an explanation of why a task was scheduled at a specific time
- **FR14:** Users can adjust scheduled tasks using natural language nudges
- **FR79:** The system maintains a visible, navigable relationship between tasks and their calendar blocks

### Shared Lists & Household Coordination

- **FR15:** Users can share any list with named users via invitation
- **FR16:** Invited users can accept list membership and complete onboarding into the shared list
- **FR17:** The system assigns tasks in shared lists using configurable strategies: round-robin, least-busy, or AI-assisted balancing
- **FR18:** The system never assigns the same task to two users within the same due-date window
- **FR19:** Tasks assigned to a user in a shared list are automatically integrated into that user's personal schedule
- **FR20:** Accountability settings can be set at list or section level and cascade to all tasks within, with per-task overrides permitted
- **FR21:** Members of a shared list can view proof media attached to tasks completed by other members
- **FR62:** List owners can remove members from a shared list; members can leave a list
- **FR75:** List ownership can be shared among multiple members, with owners collectively holding administrative rights over the list

### Commitment Contracts

- **FR22:** Users can attach a financial stake to any task
- **FR23:** Users can set up a payment method via an external web-based flow
- **FR24:** The system charges the user's stored payment method if a staked task is not verified complete by its deadline
- **FR25:** On an unverified staked task, 50% of the stake is disbursed to the user's chosen charity and 50% is retained by On Task
- **FR26:** Users can select a charity for their stakes from a catalog of nonprofits
- **FR27:** Users can view a lifetime impact dashboard showing total charitable contributions from their stakes
- **FR28:** The system provides in-app guidance to help users calibrate stake amounts appropriately
- **FR29:** Groups can create shared commitment arrangements where each member sets an individual stake, reviewed by all members, activating only upon unanimous approval
- **FR30:** Groups can opt into pool mode, where any member failing their assigned task results in charges for all members per their agreed stakes
- **FR63:** Users can cancel or modify a commitment stake before a defined pre-deadline window
- **FR64:** Users can manage (update or remove) a stored payment method
- **FR65:** Users can view billing history and past charges

### Proof & Verification

- **FR31:** Users can submit photo or video proof captured in-app (camera capture only) for AI verification
- **FR32:** The system verifies submitted photo or video proof against the task description using AI
- **FR33:** Users can activate Watch Mode for passive camera-based monitoring during task work
- **FR34:** Watch Mode is available as a standalone focus mode without requiring a financial stake
- **FR35:** Tasks can be auto-verified via Apple HealthKit when connected health data confirms the task
- **FR36:** Users can submit screenshot or document proof for tasks with digital outputs
- **FR37:** Users can submit proof while offline; on reconnection, the system processes the proof and reverses any charges if the proof timestamp predates the deadline
- **FR38:** Users can choose whether submitted proof is retained as a completion record on the task
- **FR39:** Users can dispute an AI verification result via a no-proof-required review request
- **FR40:** Disputed verifications are escalated to human review with a defined resolution SLA
- **FR41:** Operators can approve or reject disputed verifications and trigger charge cancellation or confirmation
- **FR66:** Users can end a Watch Mode session manually or configure auto-stop conditions
- **FR67:** Users can view a Watch Mode session summary after a session ends

### Notifications & Communication

- **FR42:** Users receive notifications for task reminders, approaching deadlines, commitment contract charge events, proof verification results, dispute outcomes, partner task completions, and schedule changes
- **FR43:** Users can configure notification preferences at three levels: globally, per device, and per task
- **FR72:** Users receive a distinct pre-deadline warning notification when a staked task deadline is approaching

### Platform Integrations & API

- **FR44:** External systems can create, read, update, and schedule tasks via a versioned REST API with OpenAPI documentation
- **FR45:** AI assistants can create tasks, schedule them, and create commitment contracts via an MCP server with feature parity to the in-app experience
- **FR46:** The system performs bidirectional sync with Google Calendar
- **FR47:** The system reads Apple HealthKit data to auto-verify eligible tasks
- **FR71:** External systems can read commitment contract status via API
- **FR80:** API consumers can view rate limit status and current usage in API responses
- **FR93:** MCP server access requires OAuth authentication per the MCP specification, with per-client scoping and token revocation

### User Accounts, Subscriptions & Operator Tools

- **FR48:** Users can authenticate via Apple Sign In, Google Sign In, or email and password
- **FR49:** Users can manage their subscription tier
- **FR51:** Operators can review and resolve disputed proof verifications via an internal dashboard
- **FR52:** Operators can reverse charges and issue refunds
- **FR53:** Operators can impersonate user accounts for troubleshooting, with all impersonation actions logged in an audit trail
- **FR54:** Operators receive alerts for payment failures and pending disputed verifications
- **FR60:** Users can delete their account and all associated data
- **FR61:** New users can complete an onboarding flow covering calendar connection, energy preferences setup, and initial configuration
- **FR77:** Users can customize app appearance settings (theme, text size)
- **FR81:** Users can export their task and list data in CSV and Markdown formats
- **FR82:** New users receive 14 days of full-access free trial; after 14 days, all access is blocked until a paid subscription is activated
- **FR83:** Users can select and subscribe to a pricing tier (Individual, Couple, Family & Friends) during or after the trial period
- **FR84:** Users can upgrade or downgrade their subscription tier
- **FR85:** User data is retained for a defined period after trial expiry before deletion, allowing reactivation without data loss
- **FR86:** Invited users joining a shared list receive an independent trial or onboarding path if not already subscribed
- **FR87:** Users can view their remaining trial days and current subscription status at any time
- **FR88:** Users who reach trial expiry are presented with a designed paywall screen before access is blocked
- **FR89:** Users can cancel their subscription; active commitment contracts continue until their individual deadlines
- **FR90:** Users receive a grace period and notification when a subscription renewal payment fails before access is blocked
- **FR91:** Users can view active sessions and remotely revoke access from specific devices
- **FR92:** The system supports optional two-factor authentication
- **FR94:** The system applies a defined conflict resolution policy when offline changes sync against conflicting server state

## Non-Functional Requirements

### Performance

- **NFR-P1:** App cold launch completes within 2 seconds on supported devices
- **NFR-P2:** Task creation (direct input) completes and appears in the list within 500ms
- **NFR-P3:** NLP task parsing and scheduling completes within 3 seconds of submission
- **NFR-P4:** Single-user schedule recalculation completes within 5 seconds; shared list recalculation (up to 10 members, 100 tasks) completes within 15 seconds
- **NFR-P5:** Scheduling explanation (FR13) loads within 1 second
- **NFR-P6:** REST API standard endpoints respond within 500ms at p95 under normal load
- **NFR-P7:** MCP server endpoints respond within 1 second at p95 under normal load
- **NFR-P8:** UI animations and transitions run at 60fps on supported devices; no perceptible jank
- **NFR-P9:** Task list loads and search results return within 1 second for lists up to 500 tasks
- **NFR-P10:** iOS and macOS app bundle sizes remain within platform best-practice thresholds; assets are optimized and on-demand resources used where appropriate
- **NFR-P11:** All user-facing strings are externalized into a localization layer; v1 ships English-only but the architecture supports future language additions without code changes

### Security

- **NFR-S1:** All data is encrypted in transit (TLS 1.3 minimum) and at rest (AES-256)
- **NFR-S2:** On Task never stores raw payment card data; all payment handling delegated to Stripe (PCI DSS SAQ A compliance)
- **NFR-S3:** Watch Mode frames are processed in-flight and not persisted; no continuous video is stored at any point
- **NFR-S4:** Proof media is stored in private object storage (Backblaze B2) with access scoped to the owning user and their shared list members only
- **NFR-S5:** Authentication tokens are short-lived JWTs; refresh tokens are rotated on use and revocable per session (FR91)
- **NFR-S6:** All operator impersonation actions are immutably logged with timestamp, operator identity, and actions taken
- **NFR-S7:** The application relies on framework-level and infrastructure-level protections (Hono, Cloudflare Workers, Stripe, Neon) to mitigate OWASP Top 10 risks
- **NFR-S8:** Two-factor authentication (FR92) applies to email/password accounts only; Apple Sign In and Google Sign In delegate security to their respective OAuth/OpenID providers

### Reliability

- **NFR-R1:** Stripe off-session charge processing achieves < 0.1% failure rate for valid payment methods under normal conditions; transient failures are retried with exponential backoff and idempotency keys (exactly-once semantics)
- **NFR-R2:** Stripe webhook processing is idempotent; duplicate webhook delivery does not result in duplicate charges or disbursements
- **NFR-R3:** Human dispute review SLA: operator responds within 24 hours of filing; charge hold persists until resolution
- **NFR-R4:** Every.org disbursement failures are queued and retried; funds are never lost in transit
- **NFR-R5:** Offline proof submissions (FR37) are reliably queued and synced on reconnect with timestamp integrity preserved; no proof is silently dropped
- **NFR-R6:** Backend API (Cloudflare Workers) targets 99.9% monthly uptime; maximum tolerable single-incident downtime of 15 minutes
- **NFR-R7:** User data is retained for 30 days after trial expiry or account cancellation before permanent deletion, with a reactivation path available during that window
- **NFR-R8:** Proof media retained as completion records persists until the parent task is permanently deleted. Completing a task archives it by default (FR59); archived tasks and their proof media are retained until explicit deletion.

### Quality & Correctness

- **NFR-Q1:** The scheduling engine produces deterministic output: identical inputs always produce identical scheduled outputs
- **NFR-Q2:** Payment charge logic and scheduling constraint resolution maintain minimum 90% unit test coverage; all edge cases identified during TDD design have explicit tests

### Accessibility

- **NFR-A1:** iOS and macOS apps conform to WCAG 2.1 AA standards
- **NFR-A2:** Full VoiceOver support on iOS and macOS; all interactive elements are reachable and described
- **NFR-A3:** Dynamic Type is supported throughout; no text is hardcoded at a fixed size
- **NFR-A4:** Minimum contrast ratio of 4.5:1 for body text and 3:1 for large text in all themes
- **NFR-A5:** App appearance settings (FR77) include at minimum: light/dark/system theme and text size adjustment beyond system defaults
- **NFR-A6:** No interaction requires precise timing or rapid sequential input; the app accommodates users with motor and cognitive differences

### User Experience Quality

- **NFR-UX1:** The app clearly communicates offline status and indicates which actions are unavailable; queued offline actions (proof submissions, task completions) display visible confirmation that they will sync on reconnect
- **NFR-UX2:** All user-facing error messages are plain-language, non-technical, and include a clear recovery action or next step

### Integration Reliability

- **NFR-I1:** Google Calendar changes propagate to On Task's scheduling engine within 60 seconds of occurring
- **NFR-I2:** On Task calendar block writes appear in the user's Google Calendar within 10 seconds of task scheduling
- **NFR-I3:** Apple HealthKit data used for task auto-verification is read within a 5-minute lag window; delayed data does not result in incorrect charges
- **NFR-I4:** Stripe webhook events are processed within 30 seconds of receipt under normal conditions
- **NFR-I5:** Every.org disbursement is attempted within 1 hour of a confirmed charge; failures are retried and logged
- **NFR-I6:** API rate limits are defined, documented in the OpenAPI spec, enforced consistently, and communicated to consumers via response headers

### Business Intelligence

- **NFR-B1:** Key business events (trial started, trial expired, subscription activated, subscription cancelled, task completed, stake set, charge fired) are instrumented and queryable for analytics
