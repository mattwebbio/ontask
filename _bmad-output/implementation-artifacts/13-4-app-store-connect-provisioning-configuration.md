# Story 13.4: App Store Connect & Provisioning Configuration

Status: in-progress

## Story

As the development team,
I want App Store Connect records, provisioning profiles, and entitlements correctly configured,
so that the app can be signed, submitted, and tested via TestFlight without provisioning errors.

## Acceptance Criteria

1. **Given** App Store Connect is configured
   **When** the records are created
   **Then** an iOS App Store Connect app record exists with bundle ID `com.ontaskhq.ontask` (DEPLOY-3)
   **And** a macOS Mac App Store record exists with the same bundle ID
   **And** a TestFlight internal test group is configured with at least the developer account as a tester

2. **Given** provisioning profiles are created
   **When** they are applied
   **Then** iOS and macOS App Store distribution profiles are created and installed locally (DEPLOY-2)
   **And** `Runner.entitlements` (iOS) contains all required entitlements: Push Notifications, Associated Domains (`applinks:ontaskhq.com`), Live Activities, HealthKit, Sign In with Apple
   **And** `apns-environment: production` is set in the release/TestFlight configuration; `apns-environment: development` in the debug configuration (DEPLOY-4)

## Tasks / Subtasks

---

### Task 1: Add missing entitlements to iOS `Runner.entitlements` (AC: 2) ✓

The current `apps/flutter/ios/Runner/Runner.entitlements` is **missing two required entitlements**:
- `com.apple.developer.associated-domains` (for Universal Links: `applinks:ontaskhq.com`)
- Push Notifications (`aps-environment` is present as `development`, but the Associated Domains key for Universal Links is entirely absent)

**Current state of `apps/flutter/ios/Runner/Runner.entitlements`:**
```xml
<key>com.apple.developer.applesignin</key><array><string>Default</string></array>
<key>com.apple.developer.healthkit</key><true/>
<key>com.apple.developer.healthkit.access</key><array/>
<key>aps-environment</key><string>development</string>
<key>com.apple.developer.live-activities</key><true/>
<key>com.apple.security.application-groups</key><array><string>group.com.ontaskhq.ontask</string></array>
```

**Add the Associated Domains entitlement** — insert after `com.apple.developer.applesignin`:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:ontaskhq.com</string>
</array>
```

The `aps-environment` key is already `development` — this is correct for the single entitlements file used in debug/profile builds. The release environment switch is handled by Fastlane's build configuration (see Task 3).

**Files to modify:** `apps/flutter/ios/Runner/Runner.entitlements`

---

### Task 2: Add required entitlements to macOS entitlements files (AC: 2) ✓

The macOS app needs Sign In with Apple, Associated Domains, and Push Notifications entitlements for distribution. Currently, `DebugProfile.entitlements` and `Release.entitlements` only have sandbox and network server entries.

**Current `apps/flutter/macos/Runner/DebugProfile.entitlements`:**
```xml
<key>com.apple.security.app-sandbox</key><true/>
<key>com.apple.security.cs.allow-jit</key><true/>
<key>com.apple.security.network.server</key><true/>
<key>aps-environment</key><string>development</string>
```

**Add to `DebugProfile.entitlements`** (after `aps-environment`):
```xml
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:ontaskhq.com</string>
</array>
```

**Current `apps/flutter/macos/Runner/Release.entitlements`:**
```xml
<key>com.apple.security.app-sandbox</key><true/>
<key>aps-environment</key><string>production</string>
```

**Add to `Release.entitlements`** (after `aps-environment`):
```xml
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:ontaskhq.com</string>
</array>
```

**Note:** macOS does NOT support HealthKit or Live Activities — do NOT add those entitlements to macOS files. The macOS entitlements correctly omit them.

**Files to modify:**
- `apps/flutter/macos/Runner/DebugProfile.entitlements`
- `apps/flutter/macos/Runner/Release.entitlements`

---

### Task 3: Update `apps/flutter/fastlane/Fastfile` to set production APNs entitlement for release builds (AC: 2) ✓

The current Fastfile builds the IPA but does not explicitly set `aps-environment: production` for the release build. The entitlements file has `development` hardcoded. Fastlane's `build_app` (gym) action used via `flutter build ipa` does not manipulate entitlements — the entitlement must be correct at build time via an Xcode configuration switch or a Fastlane `update_info_plist`/PlistBuddy step.

**The proper pattern for Flutter iOS apps**: Use a separate `Release.entitlements` file for production builds, and configure Xcode to use it for the Release configuration. However, the Flutter-generated iOS project uses a single `Runner.entitlements` file. The correct approach is:

1. Create `apps/flutter/ios/Runner/Runner-Release.entitlements` — a copy of `Runner.entitlements` with `aps-environment` set to `production`.
2. In the Fastfile `beta` lane, use PlistBuddy to patch `aps-environment` to `production` before building, then restore it after.

**Add a `set_production_apns` helper and update the `beta` lane** in `apps/flutter/fastlane/Fastfile`:

```ruby
default_platform(:ios)

platform :ios do
  desc "Upload a new beta build to TestFlight"
  lane :beta do
    # Patch aps-environment to production before building
    entitlements_path = "../ios/Runner/Runner.entitlements"
    sh("plutil -replace aps-environment -string production #{entitlements_path}")

    begin
      # Fetch latest build number from App Store Connect and increment
      latest = app_store_build_number(
        app_identifier: "com.ontaskhq.ontask",
        live: false,
      )
      increment_build_number(build_number: latest + 1)

      # Build the Flutter IPA
      sh("flutter build ipa --release", chdir: "../")

      # Upload to TestFlight (skip waiting for processing — check ASC manually)
      upload_to_testflight(
        ipa: "../build/ios/ipa/ontask.ipa",
        skip_waiting_for_build_processing: true,
      )
    ensure
      # Always restore development entitlement for local dev
      sh("plutil -replace aps-environment -string development #{entitlements_path}")
    end
  end
end
```

**Files to modify:** `apps/flutter/fastlane/Fastfile`

---

### Task 4: Add `NSUserActivityTypes` to iOS `Info.plist` for Universal Links (AC: 2) ✓

Universal Links require `NSUserActivityTypes` containing `NSUserActivityTypeBrowsingWeb` in `Info.plist` on iOS.

**Add to `apps/flutter/ios/Runner/Info.plist`** (insert before closing `</dict>`):

```xml
<key>NSUserActivityTypes</key>
<array>
    <string>NSUserActivityTypeBrowsingWeb</string>
</array>
```

Also update `CFBundleDisplayName` from `Ontask` to `On Task` (branding fix — the display name is wrong):

```xml
<key>CFBundleDisplayName</key>
<string>On Task</string>
```

**Files to modify:** `apps/flutter/ios/Runner/Info.plist`

---

### Task 5: Document manual App Store Connect steps as TODO checklist ✓

Create `apps/flutter/fastlane/APP_STORE_SETUP.md` documenting the manual steps required in App Store Connect before Story 13.5 (TestFlight build) can proceed. This is reference documentation for the developer, not a code change.

```markdown
# App Store Connect Manual Setup Checklist

Complete these steps in App Store Connect (appstoreconnect.apple.com) before running `fastlane beta`:

## Step 1: Create iOS App Record
- [ ] Go to Apps → + (New App)
- [ ] Platform: iOS
- [ ] Name: On Task
- [ ] Primary Language: English (U.S.)
- [ ] Bundle ID: com.ontaskhq.ontask (must match Xcode)
- [ ] SKU: ontask-ios (any unique string)
- [ ] User Access: Full Access

## Step 2: Create macOS App Record
- [ ] Go to Apps → + (New App)
- [ ] Platform: macOS
- [ ] Name: On Task
- [ ] Bundle ID: com.ontaskhq.ontask
- [ ] SKU: ontask-macos

## Step 3: Configure TestFlight Internal Test Group
- [ ] Open the iOS app record → TestFlight tab
- [ ] Create internal group "Developers"
- [ ] Add developer Apple ID as tester
- [ ] Enable automatic distribution for new builds

## Step 4: Create iOS App Store Distribution Certificate
- [ ] Xcode → Settings → Accounts → Manage Certificates
- [ ] + → Apple Distribution (or use Fastlane match)
- [ ] Download and install in Keychain Access

## Step 5: Create iOS Distribution Provisioning Profile
- [ ] developer.apple.com → Certificates, Identifiers & Profiles
- [ ] Profiles → + → App Store Connect (Distribution)
- [ ] Select App ID: com.ontaskhq.ontask
- [ ] Select certificate from Step 4
- [ ] Name: On Task iOS App Store
- [ ] Download and double-click to install

## Step 6: Create iOS Extension Provisioning Profiles (if needed)
- [ ] Repeat Step 5 for: com.ontaskhq.ontask.OnTaskWidget
- [ ] Repeat Step 5 for: com.ontaskhq.ontask.OnTaskLiveActivity (if extension App ID exists)

## Step 7: Create macOS App Store Distribution Profile
- [ ] Profiles → + → Mac App Store → Mac App Store
- [ ] Select App ID: com.ontaskhq.ontask
- [ ] Name: On Task macOS App Store
- [ ] Download and install

## Step 8: Configure Fastlane Appfile Credentials
- [ ] Set FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD in environment
- [ ] Set FASTLANE_TEAM_ID=69Q5S2QD83 in environment
- [ ] Or update apps/flutter/fastlane/Appfile with apple_id and team_id for local use

## Step 9: Verify App Identifier Capabilities
- [ ] developer.apple.com → Identifiers → com.ontaskhq.ontask
- [ ] Enable: Push Notifications, Associated Domains, HealthKit, Sign In with Apple, App Groups
- [ ] Associated Domains: add ontaskhq.com

## Dependencies Before Running fastlane beta:
- Story 13.1 deployed (AASA file at ontaskhq.com)
- Xcode signing set to Automatic (DEVELOPMENT_TEAM = 69Q5S2QD83 already set)
```

**Files to create:** `apps/flutter/fastlane/APP_STORE_SETUP.md`

---

### Task 6: Update `deferred-work.md` with manual App Store Connect steps (AC: deferred manual work) ✓

Append to `_bmad-output/implementation-artifacts/deferred-work.md`:

```
## Deferred from: Story 13.4 — App Store Connect Provisioning Configuration (2026-04-02)

The following are manual App Store Connect steps that cannot be automated from this repo. They must be completed before Story 13.5 (TestFlight first build) can succeed:

- **Create iOS App Store Connect app record** — bundle ID `com.ontaskhq.ontask`, name "On Task". [apps/flutter/fastlane/APP_STORE_SETUP.md Step 1]
- **Create macOS Mac App Store app record** — same bundle ID. [apps/flutter/fastlane/APP_STORE_SETUP.md Step 2]
- **Configure TestFlight internal test group** — at minimum one tester (developer account). [apps/flutter/fastlane/APP_STORE_SETUP.md Step 3]
- **Create iOS App Store Distribution certificate** — install in local Keychain. [apps/flutter/fastlane/APP_STORE_SETUP.md Step 4]
- **Create iOS App Store distribution provisioning profile** for `com.ontaskhq.ontask` and extension targets. [apps/flutter/fastlane/APP_STORE_SETUP.md Steps 5–6]
- **Create macOS App Store distribution provisioning profile**. [apps/flutter/fastlane/APP_STORE_SETUP.md Step 7]
- **Enable capabilities on App ID** in developer.apple.com: Push Notifications, Associated Domains (ontaskhq.com), HealthKit, Sign In with Apple, App Groups. [apps/flutter/fastlane/APP_STORE_SETUP.md Step 9]
- **Set FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD and FASTLANE_TEAM_ID** environment variables for Fastlane. [apps/flutter/fastlane/APP_STORE_SETUP.md Step 8]
```

**Files to modify:** `_bmad-output/implementation-artifacts/deferred-work.md`

---

## Dev Notes

### Current State of Entitlements

**iOS `Runner.entitlements` — PRESENT:**
- `com.apple.developer.applesignin` (Sign In with Apple) ✓
- `com.apple.developer.healthkit` ✓
- `com.apple.developer.healthkit.access` ✓
- `aps-environment: development` (push notifications) ✓
- `com.apple.developer.live-activities` ✓
- `com.apple.security.application-groups: group.com.ontaskhq.ontask` ✓

**iOS `Runner.entitlements` — MISSING (added by this story):**
- `com.apple.developer.associated-domains` with `applinks:ontaskhq.com` ← Universal Links (DEPLOY-2)

**macOS `DebugProfile.entitlements` — PRESENT:**
- `com.apple.security.app-sandbox`, `cs.allow-jit`, `network.server`
- `aps-environment: development`

**macOS `DebugProfile.entitlements` — MISSING (added by this story):**
- `com.apple.developer.applesignin`
- `com.apple.developer.associated-domains: applinks:ontaskhq.com`

**macOS `Release.entitlements` — PRESENT:**
- `com.apple.security.app-sandbox`
- `aps-environment: production` ✓ (already correct for release)

**macOS `Release.entitlements` — MISSING (added by this story):**
- `com.apple.developer.applesignin`
- `com.apple.developer.associated-domains: applinks:ontaskhq.com`

### Xcode Project — Signing Configuration

The iOS Xcode project (`apps/flutter/ios/Runner.xcodeproj/project.pbxproj`) already has:
- `DEVELOPMENT_TEAM = 69Q5S2QD83` (Apple Developer Team ID — already set)
- `CODE_SIGN_STYLE = Automatic` for Runner targets
- `PRODUCT_BUNDLE_IDENTIFIER = com.ontaskhq.ontask` for Runner (Debug, Profile, Release)
- Widget extension: `com.ontaskhq.ontask.OnTaskWidget`

The macOS Xcode project has `CODE_SIGN_STYLE = Automatic` with `PROVISIONING_PROFILE_SPECIFIER = ""`. Both projects use automatic signing — no manual profile specifier needed in the project file.

**Do NOT modify `project.pbxproj` files** — automatic signing is correct and handles provisioning profile selection.

### Fastlane Architecture

- `apps/flutter/fastlane/Fastfile` — main lane definitions (iOS `beta` lane)
- `apps/flutter/fastlane/Appfile` — `app_identifier("com.ontaskhq.ontask")`; team credentials via env vars
- `FASTLANE_TEAM_ID` must be set to `69Q5S2QD83` in the environment
- The `beta` lane calls `flutter build ipa --release` (not `build_app`/gym directly) — this is the correct pattern for Flutter

### APNs Environment — Production vs Development

- **Development entitlements (`Runner.entitlements`)**: `aps-environment: development` — used for local debug builds and Simulator
- **TestFlight / App Store builds**: must use `aps-environment: production` — patched at build time by Fastlane `beta` lane (Task 3)
- **DEPLOY-4**: This is the explicit architecture requirement — `apns-environment: production` for TestFlight

The `plutil -replace` approach in the Fastfile is safe because:
1. The `ensure` block always restores `development` after the build
2. `plutil` is available on all macOS machines with Xcode tools
3. The alternative (separate entitlements files per config) requires Xcode project edits that risk breaking Flutter's generated structure

### Universal Links — Prerequisite

Universal Links (`applinks:ontaskhq.com`) require:
1. `com.apple.developer.associated-domains` entitlement in the app (this story)
2. `/.well-known/apple-app-site-association` AASA file served from `ontaskhq.com` (completed in Story 13.1)
3. Story 13.1 already deployed the AASA file associating `com.ontaskhq.ontask` with `/setup/*`, `/subscribe/*` paths

### macOS Entitlement Constraints

- macOS does NOT support HealthKit — do NOT add `com.apple.developer.healthkit` to macOS entitlements
- macOS does NOT support Live Activities — do NOT add `com.apple.developer.live-activities` to macOS entitlements
- macOS DOES support Associated Domains, Sign In with Apple, and APNs
- macOS app sandbox (`com.apple.security.app-sandbox: true`) is **required** for Mac App Store distribution — do NOT remove it
- macOS `Release.entitlements` already has `aps-environment: production` — this is correct (the macOS build is always a release for distribution)

### App Store Connect Record — Manual Prerequisites

Story 13.4 code changes (entitlements, Fastfile) can be committed and merged immediately. The App Store Connect records are created manually in appstoreconnect.apple.com. Story 13.5 (TestFlight first build) depends on both:
1. This story's code changes merged
2. Manual App Store Connect steps completed (documented in `APP_STORE_SETUP.md`)

### Bundle IDs in Use

| Target | Bundle ID | Notes |
|--------|-----------|-------|
| iOS Runner | `com.ontaskhq.ontask` | Primary app |
| macOS Runner | `com.ontaskhq.ontask` | Same bundle ID per DEPLOY-3 |
| iOS Widget Extension | `com.ontaskhq.ontask.OnTaskWidget` | Needs its own provisioning profile |
| iOS Live Activity | `com.ontaskhq.ontask.OnTaskLiveActivity` | Needs its own provisioning profile |

### References

- Epics file: `_bmad-output/planning-artifacts/epics.md` — DEPLOY-1–4, Story 13.4 AC
- Architecture: `_bmad-output/planning-artifacts/architecture.md` — ARCH-7 (Fastlane), APNs section (DEPLOY-4)
- Story 13.1: AASA file deployed — prerequisite for Associated Domains / Universal Links
- Story 1.2: CI/CD pipeline — `ARCH-7: Fastlane for TestFlight and App Store automation`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None — all plist edits validated with `plutil -lint` (exit 0 on all 4 files).

### Completion Notes List

- Task 1: Added `com.apple.developer.associated-domains` with `applinks:ontaskhq.com` to `apps/flutter/ios/Runner/Runner.entitlements`. All 6 required entitlements are now present: Sign In with Apple, Associated Domains, HealthKit, HealthKit.access, APNs (development), Live Activities, App Groups. `plutil -lint` validated.
- Task 2: Added `com.apple.developer.applesignin` and `com.apple.developer.associated-domains` (applinks:ontaskhq.com) to both macOS entitlements files. `DebugProfile.entitlements` uses `aps-environment: development`; `Release.entitlements` uses `aps-environment: production`. HealthKit and Live Activities intentionally omitted (not supported on macOS). App sandbox preserved. Both files validated with `plutil -lint`.
- Task 3: Updated `apps/flutter/fastlane/Fastfile` `beta` lane to use `plutil -replace` to patch `aps-environment` to `production` before building and an `ensure` block to restore `development` after (even on failure). Satisfies DEPLOY-4.
- Task 4: Fixed `CFBundleDisplayName` from `Ontask` to `On Task` in `apps/flutter/ios/Runner/Info.plist`. Added `NSUserActivityTypes` array with `NSUserActivityTypeBrowsingWeb` required for Universal Links. `plutil -lint` validated.
- Task 5: Created `apps/flutter/fastlane/APP_STORE_SETUP.md` with a 9-step checklist covering iOS and macOS app record creation, TestFlight internal test group setup, certificate and provisioning profile creation, and App ID capability enablement.
- Task 6: Prepended manual App Store Connect deferred steps to `_bmad-output/implementation-artifacts/deferred-work.md` with references to APP_STORE_SETUP.md for each item.

### File List

- apps/flutter/ios/Runner/Runner.entitlements (modified — added Associated Domains)
- apps/flutter/macos/Runner/DebugProfile.entitlements (modified — added Sign In with Apple, Associated Domains)
- apps/flutter/macos/Runner/Release.entitlements (modified — added Sign In with Apple, Associated Domains)
- apps/flutter/fastlane/Fastfile (modified — added plutil APNs production patch with ensure restore)
- apps/flutter/ios/Runner/Info.plist (modified — fixed CFBundleDisplayName, added NSUserActivityTypes)
- apps/flutter/fastlane/APP_STORE_SETUP.md (created — manual App Store Connect setup checklist)
- _bmad-output/implementation-artifacts/deferred-work.md (modified — prepended Story 13.4 deferred manual steps)
- _bmad-output/implementation-artifacts/13-4-app-store-connect-provisioning-configuration.md (story file updated)
- _bmad-output/implementation-artifacts/sprint-status.yaml (status updated)

### Review Findings

- [ ] [Review][Patch] Fastfile: `plutil` production patch is outside `begin` block — if plutil fails, `ensure` restore never runs, leaving entitlements in `production` state [apps/flutter/fastlane/Fastfile:8]
- [ ] [Review][Patch] Fastfile: interpolated `entitlements_path` is not shell-quoted in either `plutil` call — breaks if path contains spaces [apps/flutter/fastlane/Fastfile:8,28]
- [x] [Review][Defer] `Runner.entitlements` not referenced via `CODE_SIGN_ENTITLEMENTS` in `project.pbxproj` — file may be orphaned by Xcode [apps/flutter/ios/Runner.xcodeproj/project.pbxproj] — deferred, pre-existing across entire project history; story explicitly prohibits modifying project.pbxproj

### Change Log

- 2026-04-02: Story 13.4 implemented — added Associated Domains entitlement to iOS Runner.entitlements; added Sign In with Apple + Associated Domains to macOS DebugProfile.entitlements and Release.entitlements; updated Fastfile beta lane to patch aps-environment to production for TestFlight builds (with ensure restore); fixed CFBundleDisplayName and added NSUserActivityTypes to iOS Info.plist; created APP_STORE_SETUP.md manual checklist; documented deferred manual App Store Connect steps in deferred-work.md.
