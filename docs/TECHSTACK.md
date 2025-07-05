# Tech Stack

## Language and Platform

| Component | Version |
|-----------|---------|
| Swift | 5.10 |
| macOS app target | 13.0 (Ventura) |
| StickyNotesCore library target | 12.0 (Monterey) |
| Universal Binary | arm64 + x86_64 |
| Xcode | 15.0+ |

## Apple Frameworks Used

| Framework | Usage in This Project |
|-----------|----------------------|
| **SwiftUI** | All UI: NavigationView, WindowGroup, LazyVGrid, TextEditor, NSViewRepresentable bridging |
| **AppKit** | NSWindow, NSTextView (via NSViewRepresentable), NSHostingController, NSWindowController |
| **Core Data** | NSPersistentContainer, NSManagedObjectContext, NSFetchRequest, programmatic model via NSManagedObjectModel |
| **CloudKit** | CKContainer for iCloud sync, NSPersistentCloudKitContainer (Xcode project only) |
| **Combine** | PassthroughSubject for note/error streams, debounce for search and auto-save |
| **Foundation** | UUID, Date, URL, Data, JSONEncoder/Decoder, FileManager, NotificationCenter, OperationQueue |
| **CoreGraphics** | CGPoint and CGSize for note position and window geometry |

## No Third-Party Packages

This project has zero external Swift package dependencies. All functionality is in-house.

## Architecture Patterns

| Pattern | Implementation |
|---------|---------------|
| MVVM | `NotesViewModel` + `NoteViewModel` drive `ContentView` + `NoteWindowView` |
| Repository | `NoteRepository` protocol; `CoreDataNoteRepository` is the only implementation |
| Singleton | `PersistenceController.shared`, `NoteService.shared`, `WindowManager.shared`, `CacheService.shared`, `BackgroundOperationManager.shared` |
| Dependency Injection | `NoteService(repository:)` and `CoreDataNoteRepository(persistenceController:)` accept injected dependencies |
| LRU Cache | Custom `LRUCache<Key, Value>` generic class in `CacheService.swift` — capacity-bounded with access-order eviction |
| Operation Queue | Both `BackgroundOperationManager` and `BackgroundProcessingService` use `OperationQueue(maxConcurrentOperationCount: 2, QoS: .background)` |
| Protocol-Oriented | `NoteRepository`, `BackgroundOperation`, `ProgressReportingOperation` protocols |

## Persistence

**Primary**: Core Data (NSPersistentContainer, SQLite backing). The model is built programmatically in `DataModel.makeManagedObjectModel()` for the SPM library target. The Xcode project uses `StickyNotes.xcdatamodeld`.

**Fallback**: File-based JSON storage in `~/Library/Application Support/StickyNotes/`. Each note is a `.json` file named by UUID. `PersistenceService` handles this fallback path.

**Migration path**: `CoreDataPersistenceService.migrateFromJSON()` reads legacy JSON files and batch-imports them into Core Data, then moves the source directory to a timestamped backup.

## Concurrency Model

| Mechanism | Used For |
|-----------|---------|
| `async/await` | All CRUD service calls, CloudKit availability checks |
| `withCheckedThrowingContinuation` | Bridges `performBackgroundTask` callback pattern to async |
| `OperationQueue` (maxConcurrent: 2, QoS: .background) | Import, export, content processing, cache warming |
| `DispatchQueue` serial (QoS: .utility) | `CacheService` thread safety |
| `DispatchQueue.main.async` | UI callbacks from operation completions |
| `@MainActor.run` | Applying batch-load results to `@Published` properties |
| `Task { }` | Fire-and-forget async from sync caller contexts |

## Build Tooling

| Tool | Purpose | Config |
|------|---------|--------|
| Xcode 15 | Primary IDE and build | `StickyNotes/StickyNotes.xcodeproj` |
| Swift Package Manager | Library build and tests | `Package.swift` (root) |
| xcodebuild | CI command-line builds | `.github/workflows/` |
| SwiftLint | Static analysis | `config/.swiftlint.yml`, `StickyNotes/.swiftlint.yml` |
| SwiftFormat | Code formatting | `StickyNotes/.swiftformat` |
| Fastlane 2.210.1 | Distribution automation | `fastlane/Fastfile` |

## CI/CD (GitHub Actions)

| Workflow | File | Trigger |
|----------|------|---------|
| Quality Gates | `ci.yml` | push to main/develop, PR |
| Build & Release | `build-and-release.yml` | push tags `v*` |
| Quality | `quality.yml` | push, PR |
| Release | `release.yml` | push version tags |
| Security | `security.yml` | push, PR |

The `ci.yml` quality-gates job runs: SwiftLint strict → SwiftFormat lint → unit tests → integration tests → UI tests → performance tests → code coverage → release build.

## Storage Paths

| Path | Contents |
|------|---------|
| `~/Library/Containers/com.superclaude.stickynotes/Data/Library/Application Support/StickyNotes/` | Core Data SQLite store (sandboxed app) |
| `~/Library/Application Support/StickyNotes/` | Legacy JSON note files (pre-Core Data) |
| `StickyNotes/Resources/StickyNotes.xcdatamodeld/` | Xcode Core Data model XML |
| `StickyNotes/Resources/Assets.xcassets` | App icons and color assets |
| `StickyNotes/Resources/StickyNotes.entitlements` | Developer ID entitlements |
| `StickyNotes/Resources/StickyNotes-MAS.entitlements` | Mac App Store entitlements |

## Performance Instrumentation

`PerformanceMonitor.shared` (`StickyNotes/Services/PerformanceMonitor.swift`) records:
- Core Data operation average and max times per named operation
- UI render time per named view
- Cache hit/miss rates per cache name
- Resident memory usage sampled every 30 seconds via `mach_task_basic_info`

Thresholds for issue reporting: Core Data > 100ms average, UI render > 16ms (60 FPS), cache hit rate < 80%.

Reports are logged every 5 minutes. `UserDefaults` stores `lastStartupTime` from `markStartupComplete()`.