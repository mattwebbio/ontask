---
title: "Product Brief Distillate: On Task"
type: llm-distillate
source: "product-brief-ontask.md"
created: "2026-03-29"
purpose: "Token-efficient context for downstream PRD creation"
---

# On Task — Detail Pack for PRD Creation

## Product Identity

- **Name:** On Task | **Domain:** ontaskhq.com
- **Tagline:** "Stop planning. Start doing."
- **Marketing lines:** "A to-do list that fights back." / "For people who mean it."
- **Rejected tagline:** "The task manager that holds you accountable." — voice felt wrong to founder
- **Core positioning:** The only product that combines intelligent auto-scheduling + shared fairness + financial commitment contracts + AI-verified proof in a single consumer experience
- **Tone:** Calm, not clinical. Non-punitive framing throughout. Stakes are "pre-made decisions," not punishments. Dispute escalation is frictionful (human contact) but never sassy.

---

## Target Users

### Primary: Organized-But-Overwhelmed Individual
- 28–45, has tried and abandoned multiple productivity apps
- Often ADHD, autistic (AuDHD specifically called out by founder), anxious, or simply cognitively overloaded
- Knows *what* needs doing; needs the app to decide *when* and help them *start*
- **Key insight:** "ADHD-specific" app framing is a turn-off even for ADHD users — frame around executive dysfunction broadly
- Executive dysfunction TAM: ~20–30% of adults (ADHD, autism, anxiety, depression, burnout) — much larger than clinical ADHD alone
- Wants calm, not gamified or punitive; needs reduced decision points at every step

### Primary: Coordinating Couples & Households
- Two people managing chores, errands, home projects, kids' schedules
- Pain: mental load imbalance, double-assignment of tasks, no shared visibility into when things will get done
- **Founder scenario:** ADHD founder + AuDHD wife; can't currently share chore lists in SkedPal (single-user only); each person has to manually verify the other isn't doing the same chore
- Shared consequences (both partners staked on a task) reframe accountability from individual nagging to joint commitment
- "Mental load" is the resonant framing for this segment — use it in marketing

### Secondary: Accountability-First Users
- Existing Beeminder / StickK users who want a complete task management experience
- Know commitment devices work for them; frustrated by terrible UX and no scheduling intelligence

### Explicitly Out of Scope
- Businesses / employer-employee workflows — financial penalties don't fit employment relationships
- Note: small teams of peers (freelance collectives, roommates, friend groups) are fine — it's the employer-employee power dynamic that's excluded, not group size

---

## Feature Detail: Intelligent Scheduling

- **Scheduling engine:** Algorithmic (not AI) for cost and determinism; AI used for natural language task capture only
- **Calendar model:** Full two-way sync with Google Calendar. On Task reads existing events to find free time AND writes calendar blocks for scheduled tasks. Tasks are scheduled *around* meetings.
- **Time-of-day constraints:** Users can pin tasks to specific times (e.g., "give the dog meds at 8am") — these are hard constraints, not preferences
- **Energy/context preferences:** Users can define when they're available for different types of work (mirrors SkedPal's "Time Map" concept)
- **Adaptation:** When meetings move or tasks slip, schedule auto-adapts
- **Predicted completion dates:** Every task and section gets a calm, honest predicted completion date based on current workload — primary feature for most users (not Gantt)
- **Gantt view:** Advanced/power user feature; v2 scope. Shows full project timeline given current load.
- **Natural language entry:** AI-powered; also available via MCP server (important — NLP task creation must work identically in-app and via MCP)
- **Rejected approach:** Full AI scheduling (too expensive, non-deterministic); algo handles scheduling, AI handles language understanding

---

## Feature Detail: Shared Lists & Fairness Engine

- **List structure:** Infinitely nested sections and subtasks within lists
- **Sharing model:** Any list can be shared with named users (partners, family, friends)
- **Assignment strategies:**
  - Round-robin
  - Least-busy (based on current task load / calendar availability)
  - AI-assisted balancing (optional softening layer for complexity)
- **Hard constraint:** Same task NEVER assigned to two users in the same due-date window
- **Schedule integration:** When a task is assigned to a user, it integrates into their personal schedule automatically
- **Accountability inheritance:** Accountability settings (stake amount, proof type, enforcement mode) cascade list → section → task. Default set at list level; override at any lower level. Prevents per-task configuration overhead.
- **Visualization:** Users can select a list, parent section, or any section and see predicted completion timeline — key feature for project visibility (when will this house renovation actually be done?)

---

## Feature Detail: Commitment Contracts

### Financial Mechanics
- **Payment processor:** Stripe exclusively. No Apple IAP.
- **Authorization model:** User stores payment method via web-based Stripe SetupIntent (not in-app). Charge fires server-side at deadline if task not verified complete. This is an off-session charge — user consents at task creation, charge happens automatically later.
- **Why no Apple IAP:** Financial/behavioral service penalty is not "digital content." Commitment contract apps (Beeminder, Nuj) have used this model successfully for years. Post-Epic v. Apple ruling, apps can explicitly link to web payment setup from within the app, making UX smooth without triggering IAP.
- **Split:** 50% to user-chosen charity (via Every.org API), 50% retained by On Task as revenue
- **Tax treatment:** On Task is the charitable donor (receives full amount, donates 50%) and takes the deduction — same model as Panda Express charity checkout. Users are not the donor; they paid a penalty. No tax receipt issued to users.
- **User impact dashboard:** Users see lifetime charitable impact (total donated to their cause) — reframes penalty history as positive contribution record
- **Charity selection:** User-chosen from Every.org's catalog of 1.8M+ US nonprofits
- **Geographic restriction:** US-only initially to avoid jurisdictions where financial penalty mechanisms may require financial services licensing or be classified as gambling

### Proof of Completion Modes
1. **Photo/video** — taken in-app (not from photo library, to prevent old-photo gaming). AI verifies against task description using multimodal LLM (GPT-4o class or equivalent). Timestamped capture required.
2. **Watch Mode** — passive camera monitoring while user works. AI polls a frame every 30–60 seconds and confirms activity consistent with the task. No user action required — no timer to start, no photo to take. **Dual purpose: proof mechanism AND standalone focus/body-doubling mode** (available without a financial stake attached). Body doubling is an established ADHD community practice; this is its digital equivalent.
3. **Integration-verified** — task auto-verified when connected service confirms action. v1: Apple HealthKit. v2: Fitbit and others. Examples: workout logged, medication recorded, steps goal hit.
4. **Screenshot/document** — for digital-output tasks (email sent confirmation, bill payment screen, form submission). AI reads text in image to verify.

- **Proof gaming mitigations:** In-app camera capture only (no photo library), timestamp metadata, GPS for location tasks (future), randomized verification prompts (future)
- **False negative handling (AI incorrectly rejects valid proof):** In-app dispute flow → human review escalation. Human review is no-questions-asked but carries inherent social friction (talking to a real person). No explicit "you will be judged" messaging — the friction is the mechanism.
- **Proof data retention:** NOT retained beyond task lifecycle. Privacy-critical for the ADHD/mental health audience.

### Shared Accountability Modes
- **Individual stakes, group-approved:** Each member independently sets their stake amount. Group reviews the full arrangement (e.g., Alice: $5, Bob: $1, Carol: $2) and must approve before any commitment activates. If Alice fails, only Alice pays her $5. Others unaffected.
- **Pool mode:** Group collectively stakes against a shared list/section. If any member fails, all members are charged per their agreed stake. Designed for households and roommates.
- **Pool payouts (v2):** In pool mode, forfeited stakes redistribute to the group based on completion performance. Complete all your tasks → full refund. Highest completion rate → largest share of the pool. Designed for competitive household scenarios (dorm roommates, chore splits). Resolves the "perverse incentive" issue: On Task only retains a cut when the whole group underperforms.
- **Mode combinations:** All accountability modes can layer with social enforcement (notify partner, text a friend, post to social — v2)
- **Extensibility:** Other enforcement modes flagged as future: social media posting, friend notification, accountability partner confirmation

---

## Technical & Architecture Context

- **Target platforms v1:** macOS and iOS (native)
- **Target platforms v2+:** Android, Windows, Linux, web — architecture must support from day one even if builds are deferred
- **API:** Self-documenting REST API (OpenAPI spec). First-class requirement, not an afterthought.
- **MCP server:** Full MCP server exposing task creation, scheduling, and completion features. NLP task entry must work identically via MCP as in-app — AI assistant users (Claude, ChatGPT, etc.) are a real distribution channel.
- **Scheduling algorithm:** Deterministic constraint-based algo (not LLM). Similar conceptual model to SkedPal's time-blocking engine.
- **AI usage:** LLM for (a) natural language task parsing, (b) photo/video proof verification (multimodal), (c) Watch Mode frame analysis, (d) optional AI-assisted task assignment balancing
- **Payment stack:** Stripe (SetupIntent for card storage, PaymentIntent for off-session charges), Every.org API for charity disbursement
- **Calendar:** Google Calendar v1; Outlook v2
- **Health integrations:** Apple HealthKit v1; Fitbit v2

---

## Pricing Model

- **Tiers:** Individual / Couple / Family & Friends
- **Individual target price:** ~$5/mo (founder preference; subject to inference cost modeling)
- **Revenue streams:** Subscription MRR + 50% share of commitment penalty forfeitures
- **Note on inference costs:** MCP-based AI app users (e.g., Claude users who interact via MCP) will partially offset inference costs but won't eliminate them — pricing must account for direct in-app AI usage
- **No free tier confirmed:** Not discussed; worth deciding in PRD phase

---

## Competitive Intelligence

### SkedPal (primary scheduling inspiration)
- Correct concept (constraint-based auto-scheduling into calendar), completely wrong execution
- Terrible mobile UX, steep learning curve, semi-abandoned development cadence
- **Fatal flaw:** Single-user only — no shared lists, no household coordination
- No AI, no natural language, no accountability layer
- Proves the market wants auto-scheduling; fails on every UX and social dimension

### Motion
- Validated premium pricing for personal AI scheduling (~$19/mo individual)
- **Recent pivot to enterprise AI agents** — vacating personal user market, creating direct opportunity
- Core complaint: scheduling decisions felt wrong/opaque; UI overcrowded post-pivot
- Work-centric, no personal/social features, no accountability

### Forfeit
- Direct prior art on financial accountability + photo proof
- Human review team caused delays and inconsistency; pivoting to AI verification
- Thin product — only accountability layer, no task management or scheduling
- Easy to game; limited task scope (physical actions, not cognitive tasks)

### Beeminder
- 10+ years proving financial commitment devices work for a subset of users
- Derailment charge model: Stripe off-session charge, web-first payment setup — **exact technical pattern On Task should use**
- Ugly UI, dated, no AI, no collaboration, no scheduling
- "Akrasia horizon" (7-day delay on goal changes) is a smart anti-gaming mechanism worth considering

### Tiimo
- Best design in the ADHD/executive dysfunction niche
- Deliberately shallow: no scheduling intelligence, no projects, no collaboration, no accountability
- Proves the niche will pay for good design — On Task occupies the space between Tiimo's beauty and Beeminder's brutality

### Every.org
- Recommended charity API. 1.8M+ US nonprofits, developer-friendly, self-serve, handles tax receipts, used by Snap/GitHub
- Potential co-marketing partner (they benefit when On Task grows)

### Behavioral Economics Foundation
- StickK (Yale): financial stakes 3x more effective than non-financial commitment contracts
- Loss aversion (Kahneman): losses felt ~2x more acutely than equivalent gains — why penalties outperform rewards
- Stakes sweet spot: "meaningful but not devastating" — $10–$50 per task depending on income
- Anxiety caution: for ADHD/anxiety users, stakes that are too high can trigger avoidance. App should guide users toward appropriate stake calibration.
- Self-compassion framing matters: reframe failed tasks as "pre-committed consequences you chose," not punishment

---

## Open Questions for PRD Phase

- **Free tier?** Not discussed. Worth deciding before PRD.
- **Minimum stake amount?** Needs a floor to prevent trivially low stakes that don't motivate.
- **Maximum stake amount?** Needs a ceiling for user protection / regulatory caution.
- **Scheduling algo design:** How transparent should the scheduling logic be? SkedPal's opacity was a complaint — users want to understand *why* a task was scheduled when it was.
- **Watch Mode privacy:** Camera access while working is sensitive. Consent flow, on-device vs. cloud processing, and data handling need explicit design.
- **Watch Mode standalone UX:** As a body-doubling focus mode (no stake), what does the session look like? Timer? Ambient presence indicator? Session summary?
- **HealthKit proof edge cases:** What if the health data is delayed, incomplete, or comes from a third-party device?
- **Pool mode charge timing:** Does everyone get charged simultaneously at deadline, or only after all tasks in the window have been evaluated?
- **Couple/group onboarding:** Both-sides activation is required for shared lists. What's the invitation and onboarding flow? What does the app do if one partner never activates?
- **Dispute SLA:** How fast does human review need to resolve? What happens to the charge hold while a dispute is in progress?
- **Every.org fallback:** What happens if the charity disbursement API is down at charge time? Who holds the funds?
- **Pricing model final numbers:** $5/mo individual is a target, not confirmed. Couple and Family & Friends pricing TBD.
- **Watch Mode in v1 vs v2:** Founder wants it in initial design; included in v1 scope pending technical feasibility confirmation.

---

## Rejected / Deferred Ideas (Do Not Re-Propose Without Context)

- **Full AI scheduling:** Rejected — too expensive and non-deterministic. Algo handles scheduling; AI handles language only.
- **Business/enterprise tier:** Rejected for core product. Financial penalty model doesn't fit employer-employee relationships. Small peer groups (roommates, freelance collectives) are fine.
- **"You will be judged" messaging on disputes:** Rejected — too sassy, risks driving users away. Human friction is the mechanism; no explicit judgment language.
- **Anti-charity stakes (money to a cause you oppose):** Research shows it's slightly more effective but psychologically unpleasant to set up. Deferred to v2 as optional mode.
- **Gantt view in v1:** Deferred to v2. Predicted completion dates serve most users.
- **Social enforcement modes in v1:** (Text friends, post to social) Deferred to v2.
- **Outlook integration in v1:** Deferred to v2.
- **Fitbit in v1:** HealthKit only in v1; Fitbit v2.
