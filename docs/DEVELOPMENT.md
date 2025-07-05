# Development Guide

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Swift 5.10 or later
- SwiftLint: `brew install swiftlint`
- SwiftFormat: `brew install swiftformat`
- Fastlane: `gem install fastlane` (for distribution only)

## Initial Setup

```bash
git clone https://github.com/sanchez314c/desktop-stickies.git
cd desktop-stickies

# Open in Xcode (recommended for full feature development)
open StickyNotes/StickyNotes.xcodeproj

# Or use SPM for library development
swift build
```

No package dependencies to resolve — this project has zero third-party Swift packages.

## Building

### Xcode (primary — required for app features)

```bash
# Debug build
xcodebuild -scheme StickyNotes \
  -project StickyNotes/StickyNotes.xcodeproj \
  -configuration Debug build

# Release build
xcodebuild -scheme StickyNotes \
  -project StickyNotes/StickyNotes.xcodeproj \
  -configuration Release build

# Universal binary (Intel + Apple Silicon)
xcodebuild -scheme StickyNotes \
  -project StickyNotes/StickyNotes.xcodeproj \
  -configuration Release build \
  ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO

# Clean
xcodebuild -scheme StickyNotes clean
```

### SPM (library development only)

```bash
# Build all targets
swift build

# Build release
swift build -c release

# Build with all CPU cores
swift build -j $(nproc)
```

## Running Tests

```bash
# SPM unit tests (StickyNotesCoreTests)
swift test

# All Xcode tests
xcodebuild test \
  -scheme StickyNotes \
  -project StickyNotes/StickyNotes.xcodeproj \
  -destination 'platform=macOS'

# Specific test suite
xcodebuild test \
  -scheme StickyNotes \
  -project StickyNotes/StickyNotes.xcodeproj \
  -destination 'platform=macOS' \
  -only-testing:StickyNotesTests/NoteModelTests

# SPM test with coverage
swift test --enable-code-coverage

# Run specific test class
swift test --filter StickyNotesCoreTests
```

## Code Style

SwiftLint is configured in `config/.swiftlint.yml` and `StickyNotes/.swiftlint.yml`. SwiftFormat config is in `StickyNotes/.swiftformat`.

```bash
# Lint (CI-mode, strict)
swiftlint lint --strict --quiet

# Format and apply changes
swiftformat .

# Format check only (for CI)
swiftformat --lint --verbose .
```

The CI workflow (`ci.yml`) fails on any SwiftLint or SwiftFormat violation.

## Adding a Note Property

When adding a new property to `Note`, changes are required in multiple files:

1. `Sources/Models/Note.swift` — add to `Note` struct and `NoteEntity` init
2. `Sources/Models/NoteEntity.swift` — add `@NSManaged` property
3. `Sources/Persistence/DataModel.swift` — add `NSAttributeDescription` in `makeManagedObjectModel()`
4. `StickyNotes/Models/Note.swift` — add to app-layer Note if UI needs it
5. Tests in `Tests/StickyNotesTests/NoteModelTests.swift`

## Debugging Core Data

Enable Core Data debug output by adding to the scheme's environment variables:
```
-com.apple.CoreData.SQLDebug 1
-com.apple.CoreData.Logging.stderr 1
```

For migration debugging, `MigrationManager.migrateIfNeeded()` prints to console. The store URL is printed when `loadPersistentStores` completes.

## Debugging CloudKit Sync

CloudKit sync only activates when:
1. The container is `NSPersistentCloudKitContainer` (Xcode project, not SPM)
2. A valid iCloud account is signed in
3. The CloudKit entitlement is present

Check `PersistenceController.syncStatusPublisher` for sync state. The CloudKit Dashboard at https://icloud.developer.apple.com shows container `iCloud.com.stickynotes.app`.

## Performance Profiling

`PerformanceMonitor.shared` tracks operation timings, cache hit rates, and memory usage. Call `PerformanceMonitor.shared.generatePerformanceReport()` to dump metrics to console. Thresholds: Core Data ops > 100ms, UI render > 16ms, cache hit rate < 80%.

Run the built-in benchmark:
```swift
await PerformanceMonitor.shared.runBenchmark()
```

## Git Workflow

Branch naming:
- `feature/description` — new features
- `fix/description` — bug fixes
- `docs/description` — documentation only

All PRs target `main`. CI runs quality gates (SwiftLint, SwiftFormat, unit tests, integration tests, UI tests, performance tests, security scan).

Conventional commit format:
```
feat: add tag filtering to note search
fix: prevent race condition in CacheService.set()
docs: update ARCHITECTURE.md with window lifecycle
test: add NoteViewModel auto-save tests
```
