# API Reference

This document covers the public API of the `StickyNotesCore` Swift library (path: `Sources/`). The library exposes types and services for managing sticky notes with Core Data + CloudKit persistence.

## Note

Defined in `Sources/Models/Note.swift`.

```swift
public struct Note: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var content: String
    public var color: NoteColor
    public var position: CGPoint
    public var size: CGSize
    public var createdAt: Date
    public var modifiedAt: Date
    public var isMarkdown: Bool
    public var isLocked: Bool
    public var tags: [String]
}
```

Default values: title `""`, content `""`, color `.yellow`, position `.zero`, size `300×200`, isMarkdown `false`, isLocked `false`, tags `[]`.

Computed: `summary` (first 10 words), `isEmpty` (both title and content blank), `characterCount`, `lineCount`.

## NoteColor

```swift
public enum NoteColor: String, Codable, CaseIterable {
    case yellow, blue, green, pink, purple, gray
}
```

Properties: `displayName: String`, `colorValue: (red, green, blue, alpha)`, `accessibilityLabel: String`, `static var random: NoteColor`.

## NoteService

Defined in `Sources/Services/NoteService.swift`. Singleton: `NoteService.shared`.

### Publishers

```swift
public let notesPublisher: PassthroughSubject<[Note], Never>
public let errorPublisher: PassthroughSubject<ServiceError, Never>
```

`notesPublisher` emits after every mutating operation (create, update, delete). Subscribe to keep UI in sync.

### CRUD

```swift
func createNote(title: String, content: String, color: NoteColor, position: CGPoint, size: CGSize) async throws -> Note
func getAllNotes() async throws -> [Note]
func getNote(withId id: UUID) async throws -> Note?
func updateNote(_ note: Note) async throws
func deleteNote(withId id: UUID) async throws
func deleteNotes(withIds ids: [UUID]) async throws
```

### Search and Filter

```swift
func searchNotes(containing text: String) async throws -> [Note]
func getNotes(withColor color: NoteColor) async throws -> [Note]
func getNotes(withTags tags: [String]) async throws -> [Note]
```

### Batch Operations

```swift
func duplicateNote(_ note: Note) async throws -> Note
func updateNotePosition(id: UUID, position: CGPoint) async throws
func updateNoteSize(id: UUID, size: CGSize) async throws
func toggleMarkdownMode(forId id: UUID) async throws
func addTag(_ tag: String, toNoteWithId id: UUID) async throws
func removeTag(_ tag: String, fromNoteWithId id: UUID) async throws
```

`duplicateNote` creates a new note with title appended " Copy" and position offset by +20,+20.

### Statistics

```swift
func getNotesCount() async throws -> Int
func getNotesStatistics() async throws -> NotesStatistics
```

```swift
public struct NotesStatistics {
    public let totalNotes: Int
    public let colorDistribution: [NoteColor: Int]
    public let tagDistribution: [String: Int]
    public let markdownNotes: Int
    public let lockedNotes: Int
    public let averageContentLength: Int
}
```

### Sync

```swift
func sync()                                  // trigger manual CloudKit sync
func isCloudSyncAvailable() async -> Bool    // check iCloud account availability
```

## NoteRepository (protocol)

Defined in `Sources/Services/NoteRepository.swift`. Implement to provide a custom data source.

```swift
public protocol NoteRepository {
    func fetchNotes() async throws -> [Note]
    func fetchNote(withId id: UUID) async throws -> Note?
    func searchNotes(containing text: String) async throws -> [Note]
    func fetchNotes(withColor color: NoteColor) async throws -> [Note]
    func fetchNotes(withTags tags: [String]) async throws -> [Note]
    func saveNote(_ note: Note) async throws
    func saveNotes(_ notes: [Note]) async throws
    func deleteNote(withId id: UUID) async throws
    func deleteNotes(withIds ids: [UUID]) async throws
    func updateNoteModificationDate(forId id: UUID) async throws
    func notesCount() async throws -> Int
    func noteExists(withId id: UUID) async throws -> Bool
}
```

## CoreDataNoteRepository

Concrete implementation of `NoteRepository`. Uses `PersistenceController.performBackgroundTask(_:)` for all operations. All saves immediately call `context.save()`.

```swift
public init(persistenceController: PersistenceController = .shared)
```

## PersistenceController

Defined in `Sources/Persistence/PersistenceController.swift`. Singleton: `PersistenceController.shared`.

```swift
public let container: NSPersistentContainer
public let viewContext: NSManagedObjectContext
public let syncStatusPublisher: PassthroughSubject<SyncStatus, Never>
public let errorPublisher: PassthroughSubject<PersistenceError, Never>
```

```swift
// Init (not normally called directly)
init(inMemory: Bool = false)

// Context management
func newBackgroundContext() -> NSManagedObjectContext
func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void)
func save(context: NSManagedObjectContext) async throws
func saveViewContext() async throws

// Convenience CRUD (bypasses repository layer)
func createNote(title: String, content: String, color: String) -> NoteEntity
func save() throws
func fetchNotes() throws -> [NoteEntity]
func deleteNote(_ note: NoteEntity) throws

// CloudKit
func triggerSync()
func isCloudKitAvailable() async -> Bool
func migrateIfNeeded() async throws
```

### SyncStatus

```swift
public enum SyncStatus {
    case available, noAccount, restricted, unknown, syncing, synced, error
}
```

## BackgroundOperationManager

Defined in `Sources/Services/BackgroundOperationManager.swift`. Singleton: `BackgroundOperationManager.shared`. Max 2 concurrent operations, QoS `.background`.

```swift
public let operationStatusPublisher: PassthroughSubject<OperationStatus, Never>
public let operationProgressPublisher: PassthroughSubject<OperationProgress, Never>

@discardableResult
func importNotes(from jsonData: Data, operationId: UUID = UUID()) -> UUID

@discardableResult
func exportNotes(to url: URL, operationId: UUID = UUID()) -> UUID

@discardableResult
func bulkUpdateNotes(updates: [UUID: NoteUpdate], operationId: UUID = UUID()) -> UUID

@discardableResult
func searchAndReplace(searchText: String, replacementText: String, operationId: UUID = UUID()) -> UUID

@discardableResult
func duplicateNotes(noteIds: [UUID], operationId: UUID = UUID()) -> UUID

func cancelOperation(withId id: UUID)
func cancelAllOperations()
var activeOperationsCount: Int { get }
func isOperationActive(_ id: UUID) -> Bool
```

### NoteUpdate

```swift
public struct NoteUpdate {
    public let title: String?
    public let content: String?
    public let color: NoteColor?
    public let position: CGPoint?
    public let size: CGSize?
    public let isMarkdown: Bool?
    public let isLocked: Bool?
    public let tags: [String]?
}
```

## Error Types

### PersistenceError

```swift
public enum PersistenceError: LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case cloudKitError(Error)
    case syncFailed(Error)
    case invalidData
}
```

`isRecoverable`: cloudKitError and syncFailed return `true`; others return `false`.

### ServiceError

```swift
public enum ServiceError: LocalizedError {
    case createFailed(Error)
    case fetchFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    case searchFailed(Error)
    case syncError
    case persistenceError(PersistenceError)
    case noteNotFound
}
```

## Extensions

Defined in `Sources/Models/Extensions.swift`.

### CGPoint
- `init?(string: String)` — parses `{x, y}` format
- `var stringValue: String`

### CGSize
- `init?(string: String)` — parses `{width, height}` format
- `var stringValue: String`

### Date
- `var iso8601String: String`
- `var relativeTimeString: String` — "2 hours ago"
- `var shortDateString: String`

### String
- `func truncated(to length: Int, trailing: String = "...") -> String`
- `var isBlank: Bool`
- `var wordCount: Int`
- `var estimatedReadingTime: Double` — at 200 wpm

### Array where Element == Note
- `sortedByModifiedDate() -> [Note]`
- `sortedByCreatedDate() -> [Note]`
- `sortedByTitle() -> [Note]`
- `filtered(by color: NoteColor) -> [Note]`
- `filtered(containing text: String) -> [Note]`
- `filtered(byTags tags: [String]) -> [Note]`
- `groupedByColor() -> [NoteColor: [Note]]`
- `groupedByTags() -> [String: [Note]]`

### Note (extensions)
- `contains(_ text: String) -> Bool` — searches title and content
- `hasTag(_ tag: String) -> Bool`
- `hasAnyTag(_ tags: [String]) -> Bool`
