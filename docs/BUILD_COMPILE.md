# Build & Compile

## Prerequisites

- macOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.10 or later

Optional for distribution:
- Fastlane: `sudo gem install fastlane`
- SwiftLint: `brew install swiftlint`
- SwiftFormat: `brew install swiftformat`

## Project Structure Note

There are two build systems in this repo:

1. **`StickyNotes/StickyNotes.xcodeproj`** — primary Xcode project for the macOS app
2. **`Package.swift`** (root) — SPM manifest for the `StickyNotesCore` library

Build the Xcode project for the full app. Build SPM for library development.

## Xcode Builds

### Debug build

```bash
xcodebuild -scheme StickyNotes \
  -project StickyNotes/StickyNotes.xcodeproj \
  -configuration Debug \
  build
```

Output: `~/Library/Developer/Xcode/DerivedData/StickyNotes-.../Build/Products/Debug/StickyNotes.app`

### Release build

```bash
xcodebuild -scheme StickyNotes \
  -project StickyNotes/StickyNotes.xcodeproj \
  -configuration Release \
  build
```

### Universal binary (arm64 + x86_64)

```bash
xcodebuild -scheme StickyNotes \
  -project StickyNotes/StickyNotes.xcodeproj \
  -configuration Release \
  build \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO
```

Verify architecture after build:
```bash
lipo -info build/Build/Products/Release/StickyNotes.app/Contents/MacOS/StickyNotes
```

### Archive for distribution

```bash
xcodebuild -scheme StickyNotes \
  -project StickyNotes/StickyNotes.xcodeproj \
  -configuration Release \
  archive \
  -archivePath ./build/StickyNotes.xcarchive
```

### Export from archive

```bash
xcodebuild -exportArchive \
  -archivePath ./build/StickyNotes.xcarchive \
  -exportPath ./build/export \
  -exportOptionsPlist exportOptions.plist
```

### Clean

```bash
xcodebuild -scheme StickyNotes \
  -project StickyNotes/StickyNotes.xcodeproj \
  clean
```

### Tests

```bash
xcodebuild test \
  -scheme StickyNotes \
  -project StickyNotes/StickyNotes.xcodeproj \
  -destination 'platform=macOS'
```

## SPM Builds

```bash
# Debug
swift build

# Release
swift build -c release

# Use all CPU cores
swift build -j $(nproc)

# Test
swift test

# Test with coverage
swift test --enable-code-coverage

# Filter tests
swift test --filter StickyNotesCoreTests
```

## Build Scripts

Scripts in `scripts/` handle more complex scenarios:

| Script | Purpose |
|--------|---------|
| `build-macos.sh` | Standard macOS build |
| `build-compile-dist.sh` | Distribution build with `--universal` or `--arch-specific` flags |
| `build-multi-platform.sh` | Multi-platform cross-compile |
| `build-swift-comprehensive.sh` | Full sweep: build, test, lint, quality checks |

```bash
# Universal distribution build (CI uses this)
chmod +x scripts/build-compile-dist.sh
./scripts/build-compile-dist.sh --universal --skip-codesign

# Architecture-specific builds
./scripts/build-compile-dist.sh --arch-specific --skip-codesign
```

## Fastlane Distribution

Fastlane manages signing, notarization, and upload. Defined in `fastlane/Fastfile`.

```bash
# Install Fastlane
sudo gem install fastlane

# Run tests
fastlane test

# Debug build
fastlane build_development

# Direct distribution (Developer ID, notarize, DMG)
fastlane build_direct

# Mac App Store build
fastlane build_app_store

# TestFlight
fastlane beta

# App Store submit
fastlane release

# Full CI pipeline
fastlane ci
```

Required environment variables for signing:

```bash
export DEVELOPER_CERTIFICATE_PATH=/path/to/cert.p12
export DEVELOPER_CERTIFICATE_PASSWORD=secret
export APP_STORE_CERTIFICATE_PATH=/path/to/appstore_cert.p12
export APP_STORE_CERTIFICATE_PASSWORD=secret
export APPLE_ID=developer@example.com
export APPLE_TEAM_ID=XXXXXXXXXX
export KEYCHAIN_NAME=fastlane_tmp_keychain
```

## CI/CD

GitHub Actions workflows in `.github/workflows/`:

| Workflow | Trigger | Jobs |
|----------|---------|------|
| `ci.yml` | push to main/develop, PR | quality-gates, multi-platform-build, performance-baseline, accessibility, security, release-validation |
| `build-and-release.yml` | push tags `v*` | build, release |
| `quality.yml` | push, PR | lint, format, test |
| `release.yml` | push tags | archive, export, notarize |
| `security.yml` | push, PR | static analysis |

The `ci.yml` quality-gates job runs: SwiftLint → SwiftFormat → unit tests → integration tests → UI tests → performance tests → coverage report → release build.

## Build Configuration Files

| File | Purpose |
|------|---------|
| `StickyNotes.xcconfig` | Root build settings overlay |
| `config/StickyNotes.xcconfig` | Config directory copy |
| `config/build-config.json` | Build metadata |
| `config/cross-platform.json` | Platform build matrix |
| `config/.swiftlint.yml` | SwiftLint rules |
| `StickyNotes/.swiftlint.yml` | App-target SwiftLint rules |
| `StickyNotes/.swiftformat` | SwiftFormat config |

## Code Signing

For development, Xcode manages signing automatically. For CI and distribution, certificates are imported via Fastlane's `import_certificate` action.

The bundle ID is `com.superclaude.stickynotes`. Entitlements are at:
- `StickyNotes/Resources/StickyNotes.entitlements` (Developer ID / development)
- `StickyNotes/Resources/StickyNotes-MAS.entitlements` (Mac App Store)
