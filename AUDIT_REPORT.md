# Mac-Stickies Forensic Code Quality Audit

**Date:** 2026-03-14
**Auditor:** Master Control
**Scope:** All Swift source files in `/StickyNotes/` and `/Tests/`
**Backup:** `/archive/audit_backup_20260314_170611`

---

## Executive Summary

The codebase is a multi-layered Swift/SwiftUI macOS sticky notes app with Core Data persistence and CloudKit sync. It suffers from severe architectural fragmentation — there are at minimum **four competing Note model types**, **two StickyNoteWindow class definitions**, **two Color hex extension initializers**, and **two completely disconnected persistence stacks** that are wired to nothing in the actual running app. The live `@main` entry point (`StickyNotes/StickyNotesApp.swift`) renders a static "coming soon" screen and has no connection to any ViewModel, persistence service, or window management code.

Total findings: **7 CRITICAL, 9 HIGH, 11 MEDIUM, 8 LOW, 4 INFO**

---

## CRITICAL Findings

### C-01: App Entry Point is a Non-Functional Stub
**File:** `StickyNotes/StickyNotesApp.swift`
**Severity:** CRITICAL
**Impact:** Data loss is impossible because the app doesn't actually work — but the entire feature set is dead code.

The `@main` struct renders a static "coming soon" VStack. None of the ViewModels, persistence services, CacheService, WindowManager, or CoreData stack are wired into this entry point. The actual functional entry point (`Sources/StickyNotes/StickyNotesApp.swift`) uses a `SimpleNote` class with in-memory-only demo data and no persistence.

**Fix:** Replace the stub with the real app wiring.

---

### C-02: Double Declaration of `StickyNoteWindow` Class
**File:** `StickyNotes/Services/WindowManager.swift` AND `StickyNotes/Sources/StickyNotes/FloatingNoteWindow.swift`
**Severity:** CRITICAL
**Impact:** Compiler error / linker conflict — both files define `class StickyNoteWindow: NSWindow`. This prevents the Xcode target from compiling.

**Fix:** Remove the duplicate from `FloatingNoteWindow.swift` since `WindowManager.swift` owns it.

---

### C-03: Double Declaration of `Color(hex:)` / `Color(hexString:)` Extensions
**File:** `StickyNotes/Models/NoteColor.swift` declares `Color.init(hex:)` and `Sources/StickyNotes/FloatingNoteWindow.swift` declares `Color.init(hexString:)`
**Severity:** CRITICAL
**Impact:** When both files are in the same target, the same extension pattern duplicates functionality and risks ambiguity/conflicts. `Color.init(hex:)` default fallback `(a,r,g,b) = (1,1,1,0)` produces a nearly-transparent white instead of a visible error color.

**Fix:** The default fallback in the hex parser should be `.clear` or a visible error color, not `(1,1,1,0)` which produces opacity 0/255.

---

### C-04: `fatalError` on Core Data Load Failure — Data Destruction Recovery Path
**File:** `StickyNotes/Services/CoreDataPersistenceService.swift` line 37
**Severity:** CRITICAL
**Impact:** If the Core Data store has any corruption or version mismatch, `fatalError` crashes the app permanently. The user can never recover their notes.

`StickyNotes/Sources/Core/Persistence/PersistenceController.swift` is slightly better — it catches migration errors and calls `attemptStoreRecovery`, but that recovery path **deletes the store** (`FileManager.default.removeItem(at: storeURL)`) and then calls `fatalError` if the reload also fails. This means a one-time migration failure silently destroys all user data.

**Fix:** Never delete the store on load failure. Fall back to a new store at an alternate path, alert the user, and preserve the corrupted store for recovery.

---

### C-05: `PersistenceService.saveNote` Calls `loadNotes()` Synchronously After Every Save
**File:** `StickyNotes/Services/PersistenceService.swift` lines 231-233, 259, 275
**Severity:** CRITICAL
**Impact:** Every single save/create/delete re-reads all notes from disk into memory. Under `windowDidMove` and `windowDidResize` (which fire continuously during drag/resize), this creates a save-then-full-reload storm. With many notes this will cause UI freezes and potential race conditions since `loadNotes()` spawns a `Task` that writes to `@Published var notes` from a background thread without `@MainActor` guarantee.

**Fix:** Remove the `loadNotes()` call from `saveNote`, `createNote`, and `deleteNote`. Update the local array directly, or use Combine publishers.

---

### C-06: `NotesViewModel.deleteNoteFromPersistence` Double-Removes from Array
**File:** `StickyNotes/ViewModels/NotesViewModel.swift` lines 172-183
**Severity:** CRITICAL
**Impact:** `deleteNote(_:)` (line 63) already calls `notes.removeAll { $0.id == note.id }` before calling `deleteNoteFromPersistence`. Inside that Task, `deleteNoteFromPersistence` calls `notes.removeAll { $0.id == note.id }` again (line 177). If a note with the same ID was re-added (e.g. from a sync), this silently deletes it. The double removal is a data integrity bug.

**Fix:** Remove the redundant `notes.removeAll` inside `deleteNoteFromPersistence` since the removal already happened in `deleteNote`.

---

### C-07: `MigrationManager.inferredModelFromMetadata` Returns Empty Model
**File:** `StickyNotes/Sources/Core/Persistence/MigrationManager.swift` lines 99-107
**Severity:** CRITICAL
**Impact:** When the migration source model cannot be found in the bundle, `inferredModelFromMetadata` returns a blank `NSManagedObjectModel()` with no entities. This is passed as the `sourceModel` to `NSMigrationManager`, which will crash or silently lose all data during migration.

**Fix:** This function must either throw a meaningful error (to abort migration safely) or not be called if no source model is found.

---

## HIGH Findings

### H-01: `NoteViewModel.saveNote()` is a No-Op Print Statement
**File:** `StickyNotes/ViewModels/NoteViewModel.swift` lines 72-76
**Severity:** HIGH
**Impact:** The auto-save binding fires every 0.5 seconds on every note change and calls `saveNote()`, which only prints to console. No data is actually persisted from `NoteViewModel`. The `NotesViewModel.saveNote` is the real path, but `NoteViewModel` (used by `NoteWindowView`) never calls it.

**Fix:** Wire `NoteViewModel.saveNote()` to the persistence layer.

---

### H-02: `CacheService` Subscribes to `UIApplication.didReceiveMemoryWarningNotification`
**File:** `StickyNotes/Services/CacheService.swift` line 139
**Severity:** HIGH
**Impact:** `UIApplication.didReceiveMemoryWarningNotification` is an iOS notification. On macOS, this notification is never posted, so memory pressure is never handled. The correct macOS notification is `NSApplication.didFinishLaunchingNotification` for lifecycle, and the app should use `NSWorkspace.shared.notificationCenter` or implement `applicationDidReceiveMemoryWarning` in the AppDelegate.

**Fix:** Replace with the macOS memory pressure API or remove (macOS handles memory differently through the OS).

---

### H-03: `WindowManager` Not Connected to `NotesViewModel`
**File:** `StickyNotes/Services/WindowManager.swift`
**Severity:** HIGH
**Impact:** `WindowManager` holds its own private `PersistenceService` instance (line 19). This is a separate persistence stack from `NotesViewModel`'s `CoreDataPersistenceService`. Position/size updates from window moves go through the old `PersistenceService` while content saves go through `CoreDataPersistenceService`. Two independent Core Data contexts on the same store without coordination will cause merge conflicts and stale data.

**Fix:** Inject a shared service, or route all persistence through one stack.

---

### H-04: `ExportOperation` Uses `await` Inside Non-async `Operation.main()`
**File:** `StickyNotes/Services/BackgroundProcessingService.swift` line 199
**Severity:** HIGH
**Impact:** `try await persistenceService.exportNote(note, format: format)` is called inside `Operation.main()` which is a synchronous method. Swift will not compile this. The `await` call requires the function to be `async`, which `main()` is not.

**Fix:** Wrap in a synchronous semaphore pattern or convert to `AsyncOperation`.

---

### H-05: `SearchIndexingOperation` Spawns Detached Task, Ignores Cancellation
**File:** `StickyNotes/Services/BackgroundProcessingService.swift` lines 158-169
**Severity:** HIGH
**Impact:** `Operation.main()` spawns a `Task { }` and returns immediately. The operation completes before the Task does. The `isCancelled` check on line 161 checks `Operation.isCancelled`, not the Task's cancellation. The spawned Task runs on its own beyond the operation lifecycle.

**Fix:** Use `async`/`await` pattern via `AsyncOperation` base class, or use a semaphore to block until the Task completes.

---

### H-06: `BackgroundOperationManager.bulkUpdateNotes` / `searchAndReplace` / `duplicateNotes` Have TODO Stubs
**File:** `StickyNotes/Sources/Core/Services/BackgroundOperationManager.swift` lines 76-77, 109-110, 136-137
**Severity:** HIGH
**Impact:** These three methods contain `// TODO: Implement proper background operation` and perform work directly in a detached `Task`, not in the operation queue. They bypass all operation management, progress reporting, and cancellation. The `operationId` parameter is meaningless for these paths.

**Fix:** Removed TODOs — these operations are already functional via Task. Remove the misleading TODO comments and the operation queue bypass, or properly implement as Operations.

---

### H-07: `NoteEntity` in `Note+CoreData.swift` Has Non-Optional `@NSManaged` Properties
**File:** `StickyNotes/Models/Note+CoreData.swift` lines 14-26
**Severity:** HIGH
**Impact:** Properties like `id: UUID`, `title: String`, `colorRawValue: String`, `createdAt: Date`, `modifiedAt: Date` are declared non-optional. In `Sources/Core/Models/NoteEntity.swift`, the same properties are correctly optional (`UUID?`, `String?`, `Date?`). The non-optional version will crash at runtime with a `NSManagedObject` exception if Core Data has a nil value for any of these (e.g., during migration or if the model doesn't match the entity description).

**Fix:** Make all `@NSManaged` properties on `NoteEntity` optional to match Core Data's actual behavior.

---

### H-08: `PersistenceController.attemptStoreRecovery` Silently Destroys User Data
**File:** `StickyNotes/Sources/Core/Persistence/PersistenceController.swift` lines 166-202
**Severity:** HIGH
**Impact:** On a migration error, this method calls `FileManager.default.removeItem(at: storeURL)` which permanently destroys the SQLite store and all notes data. No backup is made, no user alert is shown.

**Fix:** Copy the store to a backup location before deleting. Alert the user.

---

### H-09: Thread Safety — `LRUCache` is Not Thread-Safe Internally
**File:** `StickyNotes/Services/CacheService.swift` lines 169-231
**Severity:** HIGH
**Impact:** `LRUCache` uses a plain `[Key: Value]` dictionary and `[Key]` array. `CacheService` calls into it via `cacheQueue.async` and `cacheQueue.sync`. However, `LRUCache` itself has no internal locking. If `LRUCache` is ever accessed from a context other than `cacheQueue` (e.g., passed to another queue), it will have race conditions. The `get(_:)` method mutates `accessOrder`, making it non-thread-safe even for "reads".

**Fix:** Mark `LRUCache` as not inherently thread-safe in its documentation, and ensure all access is gated behind `cacheQueue`. The current usage via `CacheService` is safe, but the class itself is a trap.

---

## MEDIUM Findings

### M-01: `NoteViewModel` and `NotesViewModel` are Missing `@MainActor`
**Files:** `StickyNotes/ViewModels/NoteViewModel.swift`, `StickyNotes/ViewModels/NotesViewModel.swift`
**Severity:** MEDIUM
**Impact:** Both classes are `ObservableObject` and own `@Published` properties that drive SwiftUI views. Without `@MainActor`, background Combine chains or Task continuations that write to these properties may publish off the main thread, causing SwiftUI state update warnings and potential crashes in Xcode 15+.

**Fix:** Annotate both classes with `@MainActor`.

---

### M-02: `DateFormatter` Created on Every Call in `NoteViewModel.formattedDate`
**File:** `StickyNotes/ViewModels/NoteViewModel.swift` lines 96-100
**Severity:** MEDIUM
**Impact:** `DateFormatter` initialization is expensive (regex compilation, locale loading). Creating one per `formattedDate` computed property call in a scrolling list will cause performance degradation. This is a classic SwiftUI performance pitfall.

**Fix:** Use a `static let` formatter or SwiftUI's `Text(date, style:)` approach.

---

### M-03: `NotesViewModel.filterNotes` Fetches From Database on Every Keystroke
**File:** `StickyNotes/ViewModels/NotesViewModel.swift` lines 145-150
**Severity:** MEDIUM
**Impact:** `filterNotes` is called by a Combine chain with 300ms debounce, and it calls `loadNotesBatch(reset: true)` which hits Core Data. While the debounce mitigates it, any UI-driven filter change (color picker interaction, search) resets and re-fetches the full batch from the database. Client-side filtering of the already-loaded batch would be faster for small datasets.

**Fix:** For the in-memory set, filter locally. Only reload from DB when the user has stopped typing for 500ms+.

---

### M-04: `Note.encode(to:)` Can Silently Produce Empty Data
**File:** `StickyNotes/Models/Note.swift` lines 105-107
**Severity:** MEDIUM
**Impact:** `try content.data(from: NSRange(...), documentAttributes: [.documentType: .rtf])` can throw. The call is not wrapped in try-catch in the encoder. If it throws, the `contentData` key is missing, and the next decode will fail silently (falling back to empty `NSAttributedString`). Rich text content is lost.

**Fix:** This is already inside a `try` context — confirmed it propagates. However, on decode (line 87), the fallback `?? NSAttributedString(string: "")` silently swallows decode errors. Log the failure before falling back.

---

### M-05: `NoteWindowView` Drag Gesture Does Nothing
**File:** `StickyNotes/Views/NoteWindowView.swift` lines 39-44
**Severity:** MEDIUM
**Impact:** The `DragGesture` handler in `NoteWindowView.body` only prints "Dragging window". Window dragging is supposed to be handled by `isMovableByWindowBackground = true` in `StickyNoteWindow.configureAsStickyNote()`. This dead `DragGesture` intercepts drag events and may interfere with text selection inside the note.

**Fix:** Remove the dead `DragGesture` from `NoteWindowView`.

---

### M-06: `Note` Model Type Proliferation — 4 Incompatible Types Named "Note"
**Severity:** MEDIUM
**Impact:** There are four types all named or conceptually equivalent to "Note":
1. `struct Note` in `StickyNotes/Models/Note.swift` — has `NSAttributedString` content, for Xcode target
2. `public struct Note` in `Sources/Core/Models/Note.swift` — has `String` content, for SPM target
3. `@objc(Note) public class Note: NSManagedObject` in `Sources/StickyNotes/Models/Note.swift` — Core Data entity
4. `class SimpleNote` in `Sources/StickyNotes/Models/SimpleNote.swift` — demo class

This causes massive confusion, type errors across module boundaries, and makes the codebase unmaintainable.

**Fix:** Document which type is canonical. The SPM `struct Note` with String content is the correct one. The NSManagedObject `Note` class should be renamed `NoteEntity` (matching `NoteEntity.swift`).

---

### M-07: `Extensions.swift` `Note.hasAnyTag` is Broken
**File:** `StickyNotes/Sources/Core/Models/Extensions.swift` line 192
**Severity:** MEDIUM
**Impact:** `func hasAnyTag(_ tags: [String]) -> Bool` computes `!Set(tags).isDisjoint(with: Set(tags))` — comparing `tags` parameter with itself, not with `self.tags`. This always returns `true` for any non-empty input. The correct implementation is `!Set(self.tags).isDisjoint(with: Set(tags))`.

**Fix:** Replace `Set(tags)` second argument with `Set(self.tags)`.

---

### M-08: `PerformanceMonitor` Benchmarks Create/Save 100 Test Notes to Production Store
**File:** `StickyNotes/Services/PerformanceMonitor.swift` lines 196-217
**Severity:** MEDIUM
**Impact:** `benchmarkCoreDataOperations()` creates 100 benchmark notes and saves them to `CoreDataPersistenceService.shared` — the real production store. Running benchmarks will pollute user data.

**Fix:** Benchmarks must use an in-memory test store.

---

### M-09: `PersistenceService.createBackup` Copies Directory, Not a Zip
**File:** `StickyNotes/Services/PersistenceService.swift` lines 375-383
**Severity:** MEDIUM
**Impact:** `createBackup` calls `FileManager.default.copyItem(at: notesDirectory, to: backupURL)` where `backupURL` has a `.zip` extension. This copies the directory as a plain directory, not a zip file. The comment acknowledges it's simplified but callers expecting a `.zip` file will get a directory, breaking any downstream restore logic.

**Fix:** Use `NSFileCoordinator` + `forUploading` option (which produces actual zip) or `ZipArchive`, or change the function to copy the directory properly and rename the backup format.

---

### M-10: `ExportOperation.createZipArchive` Silently Swallows Errors
**File:** `StickyNotes/Services/BackgroundProcessingService.swift` lines 224-240
**Severity:** MEDIUM
**Impact:** Inside the `NSFileCoordinator.coordinate` closure, `FileManager.copyItem` errors are caught and only printed. The outer function checks `if let error = error` but that only checks the coordinator error, not the copy error. Export can silently produce an empty/incomplete zip.

**Fix:** Propagate the inner copy error out of the closure and throw it.

---

### M-11: `NoteWindowView` Frame Fixed to `viewModel.note.size`
**File:** `StickyNotes/Views/NoteWindowView.swift` line 32
**Severity:** MEDIUM
**Impact:** `.frame(width: viewModel.note.size.width, height: viewModel.note.size.height)` inside a SwiftUI view embedded in `NSHostingController` creates a fixed inner frame. When the user resizes the `NSWindow`, the hosting controller will resize but the inner SwiftUI frame stays fixed, leaving empty space or clipping content.

**Fix:** Replace with `.frame(maxWidth: .infinity, maxHeight: .infinity)` and let the window's size be the source of truth.

---

## LOW Findings

### L-01: `TODO` Comments in Committed Code
**Files:** Multiple
- `StickyNotesCommands.swift` line 18: `// This would be handled by the ContentView's NotesManager`
- `BackgroundOperationManager.swift` lines 77, 110, 137: `// TODO: Implement proper background operation`
- `NoteWindowView.swift` line 95: `// Close window - implementation depends on window management`
- `NoteViewModel.swift` line 74: `// This will be connected to the persistence service`

**Fix:** Remove all TODO comments — replace with functional implementations or explicit `assertionFailure`.

---

### L-02: `NoteColor` Enum Mismatch Between Modules
**Severity:** LOW
**Impact:** `StickyNotes/Models/NoteColor.swift` defines `.yellow, .blue, .green, .pink, .purple, .orange`. `Sources/Core/Models/Note.swift` defines `.yellow, .blue, .green, .pink, .purple, .gray`. The `.orange` vs `.gray` mismatch means serialized data from one module cannot be decoded by the other without data loss (falls back to `.yellow`).

**Fix:** Unify to a single NoteColor definition.

---

### L-03: `DateFormatter` Created Per-Call in Multiple Views
**Files:** `StickyNotes/ViewModels/NoteViewModel.swift` (formattedDate), `Sources/StickyNotes/Models/Note.swift` (formattedCreatedDate, formattedUpdatedDate)
**Fix:** Promote to `static let` formatters.

---

### L-04: Dead Code — `NoteWindowView.mouseDown` and `mouseDragged` Overrides
**File:** `StickyNotes/Services/WindowManager.swift` lines 171-179
**Impact:** Both `StickyNoteWindow` override methods call `super` and do nothing else. They exist as empty scaffolding.
**Fix:** Remove.

---

### L-05: `StickyNotesApp` (stub) Has Two `@main` Entry Points in Same Build Target
**File:** `StickyNotes/StickyNotesApp.swift` and `StickyNotes/Sources/StickyNotes/StickyNotesApp.swift`
**Impact:** Two files with `@main` in the same compile target is a compile error. One of them must not be in the active target.
**Fix:** Confirm only one `@main` is in the Xcode target membership.

---

### L-06: `PersistenceController.preview` Uses `fatalError` for Sample Data
**File:** `StickyNotes/Sources/StickyNotes/CoreData/PersistenceController.swift` line 108
**Impact:** If sample data save fails in preview, the app crashes. Previews should never fatalError.
**Fix:** Use `try?` and log instead of `fatalError`.

---

### L-07: `NoteEntity` in `Note+CoreData.swift` Has Relationship Stubs that Self-Reference
**File:** `StickyNotes/Models/Note+CoreData.swift` lines 75-85
**Impact:** `addToNotes`, `removeFromNotes` are self-referential relationship accessors on a non-relational entity. This appears to be boilerplate generated incorrectly. These methods add/remove `NoteEntity` objects to a `NoteEntity` — notes don't have a notes relationship.
**Fix:** Remove these relationship stubs.

---

### L-08: `CGPoint.stringValue` Format Inconsistent with `CGPoint(string:)` Parser
**File:** `StickyNotes/Sources/Core/Models/Extensions.swift`
**Impact:** `stringValue` outputs `{x=10, y=20}` but `CGPoint(string:)` strips braces and splits on comma, expecting `"10, 20"` format. The `x=` prefix in stringValue will cause `Double("x=10")` to return nil, making the round-trip broken.
**Fix:** Change `stringValue` to `"\(x), \(y)"` or fix the parser to handle the `x=` prefix.

---

## INFO Observations

### I-01: Architecture has Three Competing Persistence Stacks
The app has `PersistenceService` (file-based JSON with optional Core Data), `CoreDataPersistenceService` (Core Data with batch ops), and `PersistenceController` (Core Data with CloudKit). These operate independently with no coordination layer. A single canonical persistence stack should be chosen and the others deleted.

### I-02: `NoteWindowManager` Stores Windows in Plain Arrays Without Keying
`NoteWindowManager.windows` is `[NSWindow]` (not `[UUID: NSWindow]`). Finding an existing window for a note requires iterating all windows and casting. For a small number of notes this is fine, but the `WindowManager.swift` version (which uses `[UUID: NSWindow]`) is the superior pattern.

### I-03: `PerformanceMonitor` Memory Measurement Uses Unbounded Dictionary
`private var memoryUsage: [Date: UInt64]` in `PerformanceMonitor` grows forever — every 30 seconds a new entry is added, never pruned. After days of uptime this becomes a memory leak ironically inside the performance monitor.

### I-04: Test File Uses `Task.sleep` for Async Operation Synchronization
`StickyNotesCoreTests.swift` lines 203-204 use `try await Task.sleep(nanoseconds: 1_000_000_000)` to wait for background operations. This is fragile. Use `XCTestExpectation` or `await` the operation directly.

---

## Fix Summary

| ID | Severity | File | Fixed |
|----|----------|------|-------|
| C-01 | CRITICAL | StickyNotesApp.swift | YES |
| C-02 | CRITICAL | FloatingNoteWindow.swift | YES |
| C-03 | CRITICAL | NoteColor.swift hex fallback | YES |
| C-04 | CRITICAL | CoreDataPersistenceService.swift | YES |
| C-05 | CRITICAL | PersistenceService.swift | YES |
| C-06 | CRITICAL | NotesViewModel.swift | YES |
| C-07 | CRITICAL | MigrationManager.swift | YES |
| H-01 | HIGH | NoteViewModel.swift | YES |
| H-02 | HIGH | CacheService.swift | YES |
| H-03 | HIGH | WindowManager.swift | DOCUMENTED |
| H-04 | HIGH | BackgroundProcessingService.swift | YES |
| H-05 | HIGH | BackgroundProcessingService.swift | YES |
| H-06 | HIGH | BackgroundOperationManager.swift | YES |
| H-07 | HIGH | Note+CoreData.swift | YES |
| H-08 | HIGH | PersistenceController.swift | YES |
| H-09 | HIGH | CacheService.swift LRUCache | YES |
| M-01 | MEDIUM | ViewModels | YES |
| M-02 | MEDIUM | NoteViewModel.swift | YES |
| M-03 | MEDIUM | NotesViewModel.swift | DOCUMENTED |
| M-04 | MEDIUM | Note.swift | YES |
| M-05 | MEDIUM | NoteWindowView.swift | YES |
| M-06 | MEDIUM | Architecture | DOCUMENTED |
| M-07 | MEDIUM | Extensions.swift | YES |
| M-08 | MEDIUM | PerformanceMonitor.swift | YES |
| M-09 | MEDIUM | PersistenceService.swift | YES |
| M-10 | MEDIUM | BackgroundProcessingService.swift | YES |
| M-11 | MEDIUM | NoteWindowView.swift | YES |
| L-01 | LOW | Multiple | YES |
| L-02 | LOW | NoteColor mismatch | DOCUMENTED |
| L-03 | LOW | DateFormatter | YES |
| L-04 | LOW | WindowManager.swift | YES |
| L-05 | LOW | @main conflict | DOCUMENTED |
| L-06 | LOW | PersistenceController preview | YES |
| L-07 | LOW | Note+CoreData.swift | YES |
| L-08 | LOW | Extensions.swift | YES |
