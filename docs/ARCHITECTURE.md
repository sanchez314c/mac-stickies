# Architecture

StickyNotes Desktop is a macOS application built with SwiftUI, Core Data, and CloudKit. It follows the MVVM pattern with a repository abstraction layer for data access.

## Module Structure

The repository contains two Swift targets that serve different purposes:

### StickyNotesCore (SPM library)

Path: `Sources/`

The Core library provides a platform-independent persistence layer. It contains the canonical `Note` struct, the `NoteRepository` protocol, the `CoreDataNoteRepository` implementation, `NoteService`, `BackgroundOperationManager`, `PersistenceController`, and `MigrationManager`. This library has zero external dependencies.

### StickyNotes (Xcode app target)

Path: `StickyNotes/`

The app target contains the macOS-specific UI layer: SwiftUI views, MVVM ViewModels, `WindowManager` (NSWindow lifecycle), `CacheService`, `PerformanceMonitor`, `BackgroundProcessingService`, and `PersistenceService` (bridges to `StickyNotesCore`).

## Layer Diagram

```
┌────────────────────────── UI Layer ──────────────────────────┐
│                                                              │
│  ContentView  ─── NotesToolbarView                          │
│  NotesListView ─── NoteCardView                             │
│  NoteWindowView ── NoteTitleBar, NoteContentArea            │
│  RichTextEditor ── NSViewRepresentable (NSTextView)         │
│  RichTextToolbar ─ Font/style/alignment/list controls        │
│                                                              │
└──────────────────────────────┬───────────────────────────────┘
                               ↓
┌───────────────────── ViewModel Layer ───────────────────────┐
│                                                              │
│  NotesViewModel                                              │
│    @Published notes, filteredNotes, searchText              │
│    Batch loading: batchSize=50, offset pagination            │
│    Debounced search (300ms via CombineLatest + debounce)     │
│                                                              │
│  NoteViewModel                                               │
│    @Published note, isEditing, showColorPicker              │
│    Auto-save debounce: 0.5s on $note changes                │
│                                                              │
└──────────────────────────────┬───────────────────────────────┘
                               ↓
┌─────────────────────── Service Layer ──────────────────────┐
│                                                              │
│  PersistenceService                                          │
│    Mode: .coreData (default) or .fileBased fallback         │
│    File-based: JSON files in ~/Library/.../StickyNotes/     │
│                                                              │
│  CoreDataPersistenceService                                  │
│    NSPersistentContainer("StickyNotesModel")                │
│    Batch fetch with fetchOffset + fetchLimit                 │
│    Search via "searchIndex CONTAINS[cd]" predicate          │
│    migrateFromJSON() for legacy data                        │
│                                                              │
│  CacheService                                                │
│    LRU cache (capacity 200): previews                       │
│    LRU cache (capacity 100): rendered NSAttributedString    │
│    Search cache (capacity 50): [NoteMetadata], TTL 5min     │
│    Metadata cache: TTL 1min                                  │
│                                                              │
│  WindowManager                                               │
│    noteWindows: [UUID: NSWindow]                             │
│    windowControllers: [UUID: NSWindowController]            │
│    Saves position/size on windowDidMove/windowDidResize      │
│                                                              │
│  BackgroundProcessingService                                 │
│    OperationQueue (maxConcurrentOperationCount: 2)          │
│    Operations: ContentProcessing, BatchContentProcessing,   │
│    SearchIndexing, Export, Migration, CacheWarming           │
│                                                              │
└──────────────────────────────┬───────────────────────────────┘
                               ↓
┌──────────────── StickyNotesCore Persistence ───────────────┐
│                                                              │
│  NoteService (singleton: .shared)                           │
│    Combine: notesPublisher, errorPublisher                  │
│    CRUD: createNote, getAllNotes, getNote, updateNote,       │
│          deleteNote, deleteNotes                             │
│    Search: searchNotes, getNotes(withColor:), getNotes(withTags:) │
│    Bulk: duplicateNote, toggleMarkdownMode, addTag, removeTag│
│    Stats: getNotesCount, getNotesStatistics                  │
│                                                              │
│  NoteRepository (protocol)                                   │
│    fetchNotes, fetchNote(withId:), searchNotes(containing:) │
│    fetchNotes(withColor:), fetchNotes(withTags:)             │
│    saveNote, saveNotes, deleteNote, deleteNotes             │
│    updateNoteModificationDate, notesCount, noteExists       │
│                                                              │
│  CoreDataNoteRepository                                      │
│    All ops via performBackgroundTask(_:)                    │
│    withCheckedThrowingContinuation for async bridging       │
│    Upsert on saveNote: fetch by id, update if exists        │
│                                                              │
│  PersistenceController (singleton: .shared)                 │
│    NSPersistentContainer, optionally NSPersistentCloudKitContainer │
│    iCloud container: iCloud.com.stickynotes.app             │
│    viewContext: automaticallyMergesChangesFromParent        │
│    mergePolicy: NSMergeByPropertyObjectTrumpMergePolicy     │
│    syncStatusPublisher + errorPublisher (PassthroughSubject)│
│    Store recovery: wipes SQLite on incompatible migration   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Data Model

### StickyNotesCore.Note (value type)

Defined in `Sources/Models/Note.swift`. Used by the persistence library.

```
Note
  id: UUID
  title: String
  content: String           ← plain text
  color: NoteColor          ← yellow/blue/green/pink/purple/gray
  position: CGPoint
  size: CGSize (default: 300×200)
  createdAt: Date
  modifiedAt: Date
  isMarkdown: Bool
  isLocked: Bool
  tags: [String]
```

### App-Layer Note (value type)

Defined in `StickyNotes/Models/Note.swift`. Used by the UI.

```
Note
  ... (same fields) ...
  content: NSAttributedString   ← RTF-encoded via Codable
  displayTitle: String          ← "Untitled" when title is empty
  previewText: String           ← first 100 chars of content.string
```

### NoteEntity (NSManagedObject)

Defined in `Sources/Models/NoteEntity.swift`. Maps to Core Data entity "Note".

```
NoteEntity
  id: UUID?
  title: String?
  content: String?
  color: String?
  positionX: Double
  positionY: Double
  width: Double
  height: Double
  createdAt: Date?
  modifiedAt: Date?
  isMarkdown: Bool
  isLocked: Bool
  tags: NSObject? (Transformable, NSSecureUnarchiveFromDataTransformer)
```

The programmatic schema in `DataModel.makeManagedObjectModel()` adds: `updatedAt`, `isPinned`, `category` (optional String). These fields exist in the Core Data model but not in the `Note` struct.

## CloudKit Integration

`PersistenceController` attempts to configure CloudKit on every non-test init. The configuration only takes effect when the container is `NSPersistentCloudKitContainer`. In the current SPM setup, a plain `NSPersistentContainer` is used (with name "Dummy"), so CloudKit sync is disabled in SPM builds. The Xcode project uses `NSPersistentCloudKitContainer` configured in the `.xcdatamodeld` file.

CloudKit sync signals:
- `NSPersistentStoreRemoteChange` notification triggers `syncStatusPublisher.send(.syncing)` followed by `.synced` after 1 second
- `CKContainer.default().accountStatus` maps to `SyncStatus` cases

## Background Operations

Two separate background operation systems exist:

1. `BackgroundOperationManager` in `Sources/Services/` — used by `NoteService`. Handles `ImportNotesOperation` (JSON decode + batch save) and `ExportNotesOperation` (fetch all + JSON encode). Bulk update and search-replace run as async Tasks, not Operations.

2. `BackgroundProcessingService` in `StickyNotes/Services/` — app-layer operations. Handles content processing (word count, link detection), search indexing, export (with zip), migration from file-based storage, and cache warming.

## Window Management

`StickyNoteWindow` is an `NSWindow` subclass with:
- Style mask: `[.borderless, .resizable]`
- Level: `.floating`
- Collection behavior: `[.canJoinAllSpaces, .fullScreenNone]`
- Transparent background, shadow enabled
- `isMovableByWindowBackground = true`
- Min size 200×150, max size 800×600

Each note window is tracked by `noteWindows[note.id]`. Position and size changes are persisted back via `PersistenceService.updateNotePosition/updateNoteSize`.

## Concurrency Model

- Core Data operations: `performBackgroundTask(_:)` with `withCheckedThrowingContinuation`
- UI updates: `@MainActor.run` or `DispatchQueue.main.async`
- Background ops: `OperationQueue` with `maxConcurrentOperationCount: 2`, QoS `.background`
- Combine subscriptions stored in `Set<AnyCancellable>` on owning objects
- Auto-save in `NoteViewModel`: debounce 0.5s via `$note.debounce`
- Search reload in `NotesViewModel`: debounce 300ms via `CombineLatest($searchText, $selectedColorFilter).debounce`
