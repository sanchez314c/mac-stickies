# Deployment

## Distribution Channels

Three distribution paths are available, each with its own Fastlane lane:

### 1. Direct Distribution (Developer ID)

Notarized `.dmg` for distribution outside the App Store.

```bash
fastlane build_direct
```

This lane:
1. Imports the Developer ID certificate from `$DEVELOPER_CERTIFICATE_PATH`
2. Builds release with export method `developer-id`
3. Notarizes with `notarize()`
4. Creates a DMG: `hdiutil create -volname 'StickyNotes' -srcfolder ... -format UDZO`

Output: `StickyNotes.dmg`

### 2. Mac App Store

```bash
fastlane build_app_store
```

Builds with export method `app-store` using MAS entitlements (`StickyNotes-MAS.entitlements`).

### 3. TestFlight (beta)

```bash
fastlane beta
```

Calls `build_app_store` then `upload_to_testflight`. Set `skip_waiting_for_build_processing: true` to avoid CI timeout.

### 4. App Store Submit

```bash
fastlane release
```

Calls `build_app_store` then `deliver`. Configured with `submit_for_review: false` and `automatic_release: false` — manual review submission is required in App Store Connect.

## GitHub Release

```bash
fastlane github_release
```

Builds the direct distribution DMG and creates a GitHub release with the DMG as an attachment. Requires `$GITHUB_TOKEN` and `$GITHUB_REPOSITORY`.

## CI Pipeline

The full pipeline (used in CI):

```bash
fastlane ci
```

Runs: `test` → `build_development` → `build_direct` → `github_release`

## Environment Variables

All secrets are environment variables — never hardcoded. Set in CI secrets or local `.env` (never commit `.env`):

```bash
DEVELOPER_CERTIFICATE_PATH       # Path to .p12 for Developer ID signing
DEVELOPER_CERTIFICATE_PASSWORD   # Password for Developer ID .p12
APP_STORE_CERTIFICATE_PATH       # Path to .p12 for App Store signing
APP_STORE_CERTIFICATE_PASSWORD   # Password for App Store .p12
KEYCHAIN_NAME                    # Temporary keychain name (default: fastlane_tmp_keychain)
APPLE_ID                         # Apple ID email
APPLE_TEAM_ID                    # 10-char team identifier
GITHUB_TOKEN                     # GitHub PAT with repo write scope
GITHUB_REPOSITORY                # owner/repo format
SLACK_WEBHOOK_URL                # Optional — error notifications in Fastfile error block
```

## GitHub Actions Release Flow

Push a version tag to trigger the release workflow:

```bash
git tag v1.0.1
git push origin v1.0.1
```

The `release.yml` workflow fires on `refs/tags/v*`. The `ci.yml` `release-validation` job also runs on tag push, running the full test suite before building the distribution artifact.

## Version Management

Version string is managed via Xcode's `MARKETING_VERSION` in the xcconfig. Build number via `CURRENT_PROJECT_VERSION`. The Fastlane `get_version_number` helper reads from the project.

To bump version for a release:
```bash
xcrun agvtool new-marketing-version 1.1.0
xcrun agvtool new-version -all 2
```

## Notarization Requirements

The `build_direct` lane uses `notarize()` which calls Apple's notarization service. Requirements:
- Valid Developer ID Application certificate
- `$APPLE_ID` must be an Apple Developer account
- App must be built with Hardened Runtime enabled
- App must not contain unsigned binaries

Check notarization status:
```bash
xcrun notarytool history --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password @keychain:AC_PASSWORD
```

## Rollback

Since StickyNotes uses Core Data with automatic migration, schema rollback requires careful handling:

1. Keep previous `.momd` model versions in the Xcode project
2. Do not delete the old version after adding a new model version
3. `MigrationManager` will use the bundle to find a compatible source model

For emergency rollback of the app binary, revert to the previous DMG and reinstall. Core Data stores from newer schema versions may not be compatible — test migration paths before release.

## Production Monitoring

Monitoring configuration is in `monitoring/production/`:
- `alerting-config.json` — alert thresholds
- `analytics-config.json` — analytics tracking config
- `crash-reporting-config.json` — crash reporter settings
- `performance-config.json` — performance budgets
- `deployment-tracking.json` — release tracking

Scripts in `monitoring/`:
- `master-monitor.sh` — runs full monitoring sweep
- `metrics/performance-monitor.sh` — CPU/memory sampling
- `alerts/error-tracker.sh` — log error rate tracking
- `dashboards/report-generator.sh` — summary report
- `quality-gates/quality-gate-runner.sh` — pre-release gate checks
