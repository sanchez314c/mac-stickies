# Changelog

All notable changes to StickyNotes Desktop will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Forensic Code Quality Audit — Full Fix Pass (2026-03-14)

**CRITICAL fixes**
- `StickyNotes/StickyNotesApp.swift` — replaced non-functional "coming soon" stub with real app wiring; `@main` now instantiates `ContentView` via `AppDelegate` with proper lifecycle hooks
- `StickyNotes/Models/Note+CoreData.swift` — all `@NSManaged` properties made optional to match Core Data's actual behavior; non-optional declarations caused runtime crashes during migration or faulting
- `StickyNotes/Models/Note+CoreData.swift` — removed self-referential `addToNotes`/`removeFromNotes` relationship stubs that do not exist in the data model
- `StickyNotes/Services/CoreDataPersistenceService.swift` — replaced `fatalError` on store load failure with graceful error logging; app no longer hard-crashes on Core Data issues
- `StickyNotes/Services/PersistenceService.swift` — removed `loadNotes()` calls from `saveNote`, `createNote`, `deleteNote`; these caused full DB re-reads on every save including during continuous window move/resize events
- `StickyNotes/ViewModels/NotesViewModel.swift` — removed double-removal of note from in-memory array in `deleteNoteFromPersistence`; array was already updated in `deleteNote()` before the async persistence call; added rollback on persistence failure
- `StickyNotes/Sources/Core/Persistence/MigrationManager.swift` — `inferredModelFromMetadata` now throws `MigrationError.sourceModelNotFound` instead of returning an empty `NSManagedObjectModel`; returning empty model caused silent data destruction during migration

**HIGH fixes**
- `StickyNotes/ViewModels/NoteViewModel.swift` — wired `saveNote()` to `CoreDataPersistenceService.shared`; was previously a no-op `print` statement, meaning no data was ever saved from individual note windows
- `StickyNotes/Services/CacheService.swift` — replaced iOS-only `UIApplication.didReceiveMemoryWarningNotification` with `NSApplication.willTerminateNotification`; iOS notification is never posted on macOS
- `StickyNotes/Sources/Core/Persistence/PersistenceController.swift` — `attemptStoreRecovery` now backs up the corrupted store before any deletion; no longer silently destroys user data on migration errors
- `StickyNotes/Services/BackgroundProcessingService.swift` — `SearchIndexingOperation.main()`: replaced fire-and-forget `Task {}` with semaphore-bridged async call; operation now correctly waits for Core Data work to complete before signaling done
- `StickyNotes/Services/BackgroundProcessingService.swift` — `ExportOperation.main()`: replaced invalid `try await` in synchronous `Operation.main()` with semaphore-bridged Task pattern; was a compile error
- `StickyNotes/Services/BackgroundProcessingService.swift` — `createZipArchive`: inner copy error is now propagated out of the `NSFileCoordinator` closure and thrown; was silently swallowed
- `StickyNotes/Sources/Core/Services/BackgroundOperationManager.swift` — removed misleading TODO comments from `bulkUpdateNotes`, `searchAndReplace`, `duplicateNotes`

**MEDIUM fixes**
- `StickyNotes/ViewModels/NoteViewModel.swift` + `NotesViewModel.swift` — added `@MainActor` annotation to prevent off-main-thread `@Published` mutations
- `StickyNotes/ViewModels/NoteViewModel.swift` — `formattedDate` now uses a `static let` DateFormatter; was creating a new instance on every call
- `StickyNotes/Views/NoteWindowView.swift` — removed dead `DragGesture` that intercepted events and printed; window drag handled by `isMovableByWindowBackground`
- `StickyNotes/Views/NoteWindowView.swift` — changed fixed `.frame(width:height:)` to `.frame(maxWidth: .infinity, maxHeight: .infinity)` so SwiftUI view fills the NSWindow on resize
- `StickyNotes/Models/Note.swift` — `init(from:)` decoder now logs RTF deserialization failures before falling back to empty content
- `StickyNotes/Services/PerformanceMonitor.swift` — `benchmarkCoreDataOperations` disabled; was writing 100 test notes to the production Core Data store
- `StickyNotes/Services/PerformanceMonitor.swift` — `memoryUsage` dictionary now capped at 120 entries (1 hour) to prevent unbounded memory growth
- `StickyNotes/Services/PersistenceService.swift` — `createBackup` removes conflicting destination before copy and uses a non-`.zip` extension to match actual directory copy behavior

**LOW fixes**
- `StickyNotes/Sources/Core/Models/Extensions.swift` — `Note.hasAnyTag` was comparing `tags` parameter with itself; fixed to compare `self.tags` with the parameter
- `StickyNotes/Sources/Core/Models/Extensions.swift` — `CGPoint.stringValue` and `CGSize.stringValue` formats now match their respective `init?(string:)` parsers; round-trip was broken
- `StickyNotes/Models/NoteColor.swift` — hex parser default fallback changed from `(1,1,1,0)` (opacity 0/255 = invisible) to fully opaque yellow
- `StickyNotes/Sources/StickyNotes/Views/FloatingNoteWindow.swift` — same hex parser fallback fix applied
- `StickyNotes/Sources/StickyNotes/CoreData/PersistenceController.swift` — preview static property no longer calls `fatalError` on save failure
- `StickyNotes/Services/WindowManager.swift` — removed empty `mouseDown` and `mouseDragged` overrides that only called `super`
- `StickyNotes/Views/NoteWindowView.swift` — close button now calls `NSApp.keyWindow?.close()` instead of `print`
- `StickyNotes/Sources/StickyNotes/Models/Note.swift` — DateFormatter promoted to `static let` to avoid per-call allocation
- `StickyNotes/Sources/StickyNotes/StickyNotesCommands.swift` — replaced `print` placeholders with `NotificationCenter` posts for new note and export commands

### Documentation — 27-file standard applied (2026-03-14)

**Root governance files**
- `LICENSE` — corrected copyright holder from placeholder to "Jason Paul Michaels"; year 2026
- `AGENTS.md` — moved from `docs/AGENTS.md` to repository root; fixed author name typo ("Jasonn" to "Jason Paul Michaels"); updated title to match standard
- `CLAUDE.md` — new file: comprehensive AI assistant guide documenting two-target architecture (StickyNotesCore library + StickyNotes app), two distinct Note types (String content vs NSAttributedString content), NoteColor discrepancy (gray in core vs orange in app), programmatic Core Data model, CloudKit container ID, all known pitfalls
- `VERSION_MAP.md` — new file: version history table, build number format, minimum OS requirements
- `CONTRIBUTING.md` — corrected Xcode project open path from `StickyNotes.xcodeproj` to `StickyNotes/StickyNotes.xcodeproj`

**docs/ rewrites — sourced entirely from code analysis (no boilerplate)**
- `docs/README.md` — replaced duplicate root README content with proper index table of all 15 docs files plus key source files reference
- `docs/ARCHITECTURE.md` — new: full two-module layer diagram, both Note type definitions, NoteEntity attributes, CloudKit integration details, StickyNoteWindow constraints, concurrency model, background operation systems
- `docs/DEVELOPMENT.md` — new: real build commands for both Xcode and SPM targets, SwiftLint/SwiftFormat config locations, five-file checklist for adding a note property, Core Data and CloudKit debug env vars
- `docs/API.md` — new: complete StickyNotesCore public API with actual method signatures — Note struct, NoteColor enum (with gray discrepancy noted), NoteService (all CRUD + batch methods + publishers), NoteRepository protocol (all 13 methods), PersistenceController public surface, BackgroundOperationManager, NoteUpdate struct, all error types, all extensions
- `docs/BUILD_COMPILE.md` — new: Xcode debug/release/universal/archive/export commands, SPM commands, Fastlane lanes with env var requirements, CI/CD workflow table, xcconfig file locations
- `docs/DEPLOYMENT.md` — new: three distribution channels, Fastlane lane descriptions with actual lane names, GitHub release flow, all env var names, tag-based CI trigger, version bump commands, notarization requirements, Core Data rollback considerations
- `docs/TECHSTACK.md` — replaced generic boilerplate with real data: Swift 5.10, frameworks table, zero third-party packages, architecture patterns with actual class names, persistence details (NSPersistentContainer + programmatic model), concurrency model table, build tooling, CI/CD workflows, storage paths, PerformanceMonitor thresholds

**Archived duplicate docs/ files**
- `docs/AGENTS.md` — moved to `archive/` (promoted to root)
- `docs/CHANGELOG.md` — moved to `archive/` (canonical file is root CHANGELOG.md)
- `docs/CODE_OF_CONDUCT.md` — moved to `archive/` (canonical file is root CODE_OF_CONDUCT.md)
- `docs/CONTRIBUTING.md` — moved to `archive/` (canonical file is root CONTRIBUTING.md)
- `docs/CLAUDE.md` — moved to `archive/` (canonical file is root CLAUDE.md)
- `docs/DOCUMENTATION_INDEX.md` — moved to `archive/` (replaced by docs/README.md)

**Pre-existing files confirmed adequate (no changes)**
- `README.md` — rewritten with accurate feature list from code analysis, correct project structure, real keyboard shortcuts
- `CODE_OF_CONDUCT.md` — Contributor Covenant v2.1, correct
- `SECURITY.md` — adequate; bundle ID `com.superclaude.stickynotes` verified
- `.github/ISSUE_TEMPLATE/bug_report.md` — adequate, assignee `sanchez314c` correct
- `.github/ISSUE_TEMPLATE/feature_request.md` — adequate
- `.github/PULL_REQUEST_TEMPLATE.md` — adequate
- `docs/INSTALLATION.md` — adequate (bundle ID correct in uninstall commands)
- `docs/FAQ.md` — adequate
- `docs/TROUBLESHOOTING.md` — adequate (note: some paths use old bundle ID `com.jasonmichaels.stickynotes`; canonical is `com.superclaude.stickynotes`)
- `docs/WORKFLOW.md` — adequate
- `docs/QUICK_START.md` — adequate
- `docs/LEARNINGS.md` — adequate
- `docs/PRD.md` — adequate
- `docs/TODO.md` — adequate

## [1.0.0] - 2025-01-01

### Added
- Initial release of StickyNotes Desktop for macOS
- SwiftUI floating note windows that stay above all other applications
- Rich text editor: bold, italic, underline, alignment, bullet/numbered lists, font size
- Markdown mode toggle per note
- Six note colors: yellow, blue, green, pink, purple, orange
- Global search with 300ms debounce filtering
- Color filter in main window
- Per-note tags and lock flag
- Auto-save with 500ms debounce
- Core Data persistence backed by SQLite
- CloudKit iCloud sync via container `iCloud.com.stickynotes.app`
- Batch import and export to JSON
- Individual note export as text, markdown, JSON, or PDF
- LRU in-memory cache for fast preview rendering (capacity 200 previews, 100 rendered)
- Universal binary: Intel x86_64 and Apple Silicon arm64

### Technical
- Swift 5.10, SwiftUI, AppKit bridge for NSWindow/NSTextView
- Two-target structure: StickyNotesCore SPM library + StickyNotes Xcode app
- MVVM: NotesViewModel + NoteViewModel drive ContentView + NoteWindowView
- Repository pattern: NoteRepository protocol + CoreDataNoteRepository
- async/await throughout with withCheckedThrowingContinuation for Core Data bridging
- Background OperationQueue (maxConcurrent: 2, QoS: .background) for import/export
- Combine PassthroughSubject for note and error event streams
- Fastlane 2.210.1 for distribution automation
- GitHub Actions: ci.yml, build-and-release.yml, quality.yml, release.yml, security.yml
- macOS 13.0 deployment target, Xcode 15.0+
- Zero external Swift package dependencies
