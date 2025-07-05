# CLAUDE.md — StickyNotes Desktop

AI development guide for the StickyNotes macOS application.

## Project Identity

**Author:** Jason Paul Michaels
**GitHub:** https://github.com/sanchez314c/desktop-stickies
**Contact:** sanchez314c@jasonpaulmichaels.co
**Type:** Swift macOS desktop application
**Architecture:** MVVM + Core Data + CloudKit
**Language:** Swift 5.10
**Target:** macOS 13.0+ (Universal Binary: arm64 + x86_64)

## Codebase Structure

Two distinct Swift targets share this repository:

```
mac-stickies/
├── Package.swift               # SPM root — defines StickyNotes + StickyNotesCore targets
├── Sources/                    # StickyNotesCore library (shared persistence layer)
│   ├── Models/
│   │   ├── Note.swift          # Public Note struct (Identifiable, Codable, Hashable)
│   │   ├── NoteEntity.swift    # NSManagedObject subclass with fetch request builders
│   │   └── Extensions.swift    # CGPoint/CGSize/Date/String/Array<Note>/NoteColor extensions
│   ├── Persistence/
│   │   ├── PersistenceController.swift  # Core Data stack + CloudKit sync (singleton)
│   │   ├── DataModel.swift              # Programmatic NSManagedObjectModel construction
│   │   └── MigrationManager.swift       # NSMigrationManager wrapper
│   └── Services/
│       ├── NoteRepository.swift         # NoteRepository protocol + CoreDataNoteRepository
│       ├── NoteService.swift            # High-level service, Combine publishers
│       ├── BackgroundOperationManager.swift  # OperationQueue-based bulk ops
│       └── BackgroundOperations.swift   # ImportNotesOperation, ExportNotesOperation
├── StickyNotes/                # Xcode project (primary app target)
│   ├── StickyNotesApp.swift    # Placeholder @main — shows "coming soon" UI
│   ├── Models/
│   │   ├── Note.swift          # App-layer Note struct (uses NSAttributedString for content)
│   │   └── NoteColor.swift     # NoteColor enum with hex Color init, keyboard shortcuts
│   ├── Views/
│   │   ├── ContentView.swift   # Main window: NotesToolbarView + NotesListView grid
│   │   ├── NoteWindowView.swift # Floating note window: NoteTitleBar + NoteContentArea
│   │   └── RichTextEditor.swift # NSViewRepresentable NSTextView + RichTextToolbar
│   ├── ViewModels/
│   │   ├── NotesViewModel.swift # @Published state, batch loading (50/page), debounced search
│   │   └── NoteViewModel.swift  # Per-note state, 0.5s auto-save debounce
│   └── Services/
│       ├── WindowManager.swift              # NSWindow lifecycle, StickyNoteWindow subclass
│       ├── PersistenceService.swift         # Bridges Core Data + file-based fallback
│       ├── CoreDataPersistenceService.swift # Batch fetch/search with offset pagination
│       ├── CacheService.swift               # LRU cache for rendered content + previews
│       ├── PerformanceMonitor.swift         # Timing, memory polling, cache hit rates
│       └── BackgroundProcessingService.swift # OperationQueue for export/migration/cache warming
├── Tests/                      # XCTest suites
│   ├── StickyNotesCoreTests.swift           # In-memory PersistenceController tests
│   └── StickyNotesTests/NoteModelTests.swift # NoteEntity validation + Core Data tests
├── fastlane/                   # Lanes: test, build_development, build_direct, build_app_store, beta, release
└── .github/workflows/          # ci.yml, build-and-release.yml, quality.yml, release.yml, security.yml
```

## Key Architectural Facts

### Two Note Types
There are two distinct `Note` types in this codebase:
- `Sources/Models/Note.swift` — `StickyNotesCore.Note` with `content: String`, used by the persistence library
- `StickyNotes/Models/Note.swift` — app-layer `Note` with `content: NSAttributedString` (RTF-encoded in Codable), used by the UI

`PersistenceService.swift` bridges between them by converting `NSAttributedString.string` when calling `NoteService`.

### NoteColor Discrepancy
`StickyNotesCore.NoteColor` has: yellow, blue, green, pink, purple, gray
`StickyNotes.NoteColor` has: yellow, blue, green, pink, purple, **orange** (no gray)

### Core Data Model
The model is built programmatically in `DataModel.makeManagedObjectModel()`. Attributes: id (UUID), title, content, color (String), positionX, positionY, width, height, createdAt, updatedAt, isPinned, category, isMarkdown, isLocked, tags (Transformable, NSSecureUnarchiveFromDataTransformer).

### CloudKit Container
`iCloud.com.stickynotes.app` — configured in `PersistenceController.init()` and entitlements files at `StickyNotes/Resources/StickyNotes.entitlements`.

### No External Dependencies
Zero third-party Swift packages. All functionality implemented in-house.

## Development Commands

```bash
# Build (Xcode project, recommended)
xcodebuild -scheme StickyNotes -project StickyNotes/StickyNotes.xcodeproj -configuration Debug build

# Build (SPM)
swift build

# Run all tests
swift test
xcodebuild test -scheme StickyNotes -project StickyNotes/StickyNotes.xcodeproj -destination 'platform=macOS'

# Code style
swiftlint lint --strict
swiftformat .

# Fastlane
fastlane test
fastlane build_development
fastlane build_direct        # Direct distribution + notarization
fastlane build_app_store     # Mac App Store
fastlane beta                # TestFlight
fastlane release             # App Store submit
```

## Testing Patterns

Tests use in-memory `PersistenceController(inMemory: true)`. Always reinitialize in `setUp()`, nil out in `tearDown()`. Background operations tests use `Task.sleep(nanoseconds: 1_000_000_000)` to wait for completion — consider XCTestExpectation for new tests.

## Common Pitfalls

1. **The `StickyNotesApp.swift` in `StickyNotes/` is a placeholder** — it shows a "coming soon" VStack. The real app UI is in `ContentView.swift` but is wired through `NotesViewModel → CoreDataPersistenceService`, not through the SPM `StickyNotesCore`.

2. **`CoreDataPersistenceService` uses `NoteEntity.fetchRequest()`** with `colorRawValue` and `searchIndex` properties that don't exist in the SPM `DataModel` — these are Xcode-model attributes from `StickyNotes.xcdatamodeld`.

3. **Migration**: `MigrationManager.migrateIfNeeded()` is called before `loadPersistentStores`. Recovery wipes the SQLite store if migration fails.

4. **Window behavior**: `StickyNoteWindow` sets `level = .floating` and `collectionBehavior = [.canJoinAllSpaces, .fullScreenNone]`. Min size 200×150, max 800×600.

5. **Export formats**: text (.txt), markdown (.md), json (.json), pdf (simplified Data write — not real PDFKit).
