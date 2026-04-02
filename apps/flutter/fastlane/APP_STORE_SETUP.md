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

## Step 6: Create iOS Extension Provisioning Profiles

- [ ] Repeat Step 5 for: com.ontaskhq.ontask.OnTaskWidget
- [ ] Repeat Step 5 for: com.ontaskhq.ontask.OnTaskLiveActivity (if extension App ID exists)

## Step 7: Create macOS App Store Distribution Profile

- [ ] Profiles → + → Mac App Store → Mac App Store
- [ ] Select App ID: com.ontaskhq.ontask
- [ ] Name: On Task macOS App Store
- [ ] Download and install

## Step 8: Configure Fastlane Appfile Credentials

- [ ] Set `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` in environment
- [ ] Set `FASTLANE_TEAM_ID=69Q5S2QD83` in environment
- [ ] Or update `apps/flutter/fastlane/Appfile` with `apple_id` and `team_id` for local use

## Step 9: Verify App Identifier Capabilities

- [ ] developer.apple.com → Identifiers → com.ontaskhq.ontask
- [ ] Enable: Push Notifications, Associated Domains, HealthKit, Sign In with Apple, App Groups
- [ ] Associated Domains: add `ontaskhq.com`

## Dependencies Before Running `fastlane beta`

- Story 13.1 deployed (AASA file at `ontaskhq.com/.well-known/apple-app-site-association`)
- Xcode signing set to Automatic (DEVELOPMENT_TEAM = 69Q5S2QD83 already set in project)
- All steps above completed

## Notes

- The `fastlane beta` lane automatically patches `aps-environment` to `production` before building and restores `development` after. No manual entitlement editing is required before running the lane.
- Automatic code signing is configured in the Xcode projects — Xcode selects provisioning profiles from the local keychain based on the installed profiles and certificates.
- The bundle ID `com.ontaskhq.ontask` is shared between iOS and macOS targets (per DEPLOY-3).
