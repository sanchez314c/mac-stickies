# Architecture Guide

Comprehensive guide to StickyNotes' system architecture, design patterns, and development principles.

## 🏗️ System Overview

StickyNotes is built as a modern macOS application following Apple's development best practices and Swift concurrency patterns.

### Core Architecture Principles

```
🎯 Single Responsibility - Each component has one clear purpose
🔄 Dependency Inversion - High-level modules don't depend on low-level modules
📦 Interface Segregation - Clients depend only on methods they use
🔌 Plugin Architecture - Extensible through protocols and dependency injection
⚡ Reactive Programming - Combine framework for state management
🧵 Concurrency Safety - Swift Concurrency for thread-safe operations
```

## 🏛️ Architectural Patterns

### MVVM-C (Model-View-ViewModel-Coordinator)

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│    View     │    │ ViewModel   │    │  Model      │    │ Coordinator │
│             │    │             │    │             │    │             │
│ • SwiftUI   │◄──►│ • State      │◄──►│ • Data       │◄──►│ • Navigation │
│ • UI Logic  │    │ • Business   │    │ • Domain     │    │ • Flow Ctrl  │
│ • User Input│    │ • Validation │    │ • Entities   │    │ • Deep Links │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

#### View Layer (SwiftUI)

**Responsibilities:**
- UI rendering and layout
- User interaction handling
- State binding to ViewModels
- Accessibility support

**Key Components:**
```swift
struct StickyNoteView: View {
    @StateObject var viewModel: NoteViewModel

    var body: some View {
        ZStack {
            NoteBackground(color: viewModel.note.color)
            NoteContent(viewModel: viewModel)
            NoteToolbar(viewModel: viewModel)
        }
        .frame(minWidth: 200, minHeight: 150)
        .background(.ultraThinMaterial)
    }
}
```

#### ViewModel Layer

**Responsibilities:**
- Business logic execution
- State management
- Data transformation
- Error handling

**Key Patterns:**
```swift
class NoteViewModel: ObservableObject {
    @Published private(set) var note: Note
    @Published var isEditing = false
    @Published var error: Error?

    private let noteService: NoteServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(note: Note, noteService: NoteServiceProtocol = NoteService.shared) {
        self.note = note
        self.noteService = noteService
        setupBindings()
    }

    private func setupBindings() {
        $note
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] note in
                self?.saveNote(note)
            }
            .store(in: &cancellables)
    }
}
```

#### Model Layer

**Responsibilities:**
- Data persistence
- Domain logic
- Entity definitions
- Validation rules

**Core Data Model:**
```swift
struct Note: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    var color: NoteColor
    var position: CGPoint
    var size: CGSize
    var createdAt: Date
    var modifiedAt: Date
    var isMarkdown: Bool
    var tags: [String]
    var isLocked: Bool

    // Business logic
    mutating func updateContent(_ newContent: String) {
        content = newContent
        modifiedAt = Date()
    }

    func validate() throws {
        guard !title.isEmpty || !content.isEmpty else {
            throw ValidationError.emptyNote
        }
        guard title.count <= 100 else {
            throw ValidationError.titleTooLong
        }
    }
}
```

#### Coordinator Layer

**Responsibilities:**
- Navigation flow management
- View controller lifecycle
- Deep linking
- Modal presentation

```swift
class AppCoordinator {
    private let windowManager: WindowManager
    private var noteWindows: [UUID: NSWindow] = [:]

    func showNote(_ note: Note) {
        let window = createNoteWindow(for: note)
        window.makeKeyAndOrderFront(nil)
        noteWindows[note.id] = window
    }

    func closeNote(_ noteId: UUID) {
        noteWindows[noteId]?.close()
        noteWindows.removeValue(forKey: noteId)
    }

    private func createNoteWindow(for note: Note) -> NSWindow {
        let window = FloatingWindow(
            contentRect: NSRect(origin: note.position, size: note.size),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )

        window.contentView = NSHostingView(
            rootView: StickyNoteView(note: note)
        )

        configureWindowBehavior(window)
        return window
    }
}
```

### Repository Pattern

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ViewModel     │    │   Repository    │    │   Data Source   │
│                 │    │                 │    │                 │
│ • Business      │◄──►│ • Abstraction   │◄──►│ • Core Data     │
│ • Logic         │    │ • Interface     │    │ • CloudKit      │
│ • State         │    │ • Protocol      │    │ • File System   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

#### Repository Protocol

```swift
protocol NoteRepository {
    // CRUD Operations
    func create(_ note: Note) async throws -> Note
    func fetch(id: UUID) async throws -> Note?
    func fetchAll() async throws -> [Note]
    func update(_ note: Note) async throws
    func delete(id: UUID) async throws

    // Search & Filter
    func search(query: String) async throws -> [Note]
    func filter(by color: NoteColor) async throws -> [Note]
    func filter(by tags: [String]) async throws -> [Note]

    // Observers
    var notesPublisher: AnyPublisher<[Note], Error> { get }
}
```

#### Core Data Implementation

```swift
class CoreDataNoteRepository: NoteRepository {
    private let persistenceController: PersistenceController
    private let context: NSManagedObjectContext

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.context = persistenceController.container.viewContext
    }

    func create(_ note: Note) async throws -> Note {
        try await context.perform {
            let entity = NoteEntity(context: self.context)
            entity.id = note.id
            entity.title = note.title
            entity.content = note.content
            entity.color = note.color.rawValue
            entity.positionX = note.position.x
            entity.positionY = note.position.y
            entity.width = note.size.width
            entity.height = note.size.height
            entity.createdAt = note.createdAt
            entity.modifiedAt = note.modifiedAt
            entity.isMarkdown = note.isMarkdown
            entity.tags = note.tags as NSObject
            entity.isLocked = note.isLocked

            try self.context.save()
            return note
        }
    }

    var notesPublisher: AnyPublisher<[Note], Error> {
        let request = NoteEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        return context.publisher(for: request)
            .map { entities in
                entities.map { Note(from: $0) }
            }
            .eraseToAnyPublisher()
    }
}
```

### Service Layer Pattern

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ViewModel     │    │    Service      │    │  Repository     │
│                 │    │                 │    │                 │
│ • UI State      │◄──►│ • Business      │◄──►│ • Data Access    │
│ • User Actions  │    │ • Logic         │    │ • Persistence    │
│ • Validation    │    │ • Coordination  │    │ • External APIs  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

#### Service Implementation

```swift
class NoteService: NoteServiceProtocol {
    private let repository: NoteRepository
    private let validator: NoteValidator
    private let syncService: CloudSyncService?

    init(
        repository: NoteRepository = CoreDataNoteRepository(),
        validator: NoteValidator = DefaultNoteValidator(),
        syncService: CloudSyncService? = CloudSyncService()
    ) {
        self.repository = repository
        self.validator = validator
        self.syncService = syncService
    }

    func createNote(
        title: String,
        content: String,
        color: NoteColor
    ) async throws -> Note {
        let note = Note(
            title: title,
            content: content,
            color: color
        )

        try validator.validate(note)
        let createdNote = try await repository.create(note)
        await syncService?.sync(note: createdNote)

        return createdNote
    }

    func updateNote(_ note: Note) async throws {
        try validator.validate(note)
        try await repository.update(note)
        await syncService?.sync(note: note)
    }
}
```

## 🔄 State Management

### Combine-Based Reactive State

```swift
class AppState: ObservableObject {
    @Published var notes: [Note] = []
    @Published var selectedNoteId: UUID?
    @Published var isSyncing = false
    @Published var lastSyncError: Error?

    private let noteService: NoteServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(noteService: NoteServiceProtocol = NoteService.shared) {
        self.noteService = noteService
        setupBindings()
    }

    private func setupBindings() {
        noteService.notesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.lastSyncError = error
                }
            } receiveValue: { [weak self] notes in
                self?.notes = notes
                self?.lastSyncError = nil
            }
            .store(in: &cancellables)
    }
}
```

### State Persistence

```swift
class StatePersistor {
    private let userDefaults: UserDefaults

    func persist<T: Codable>(_ value: T, for key: String) throws {
        let data = try JSONEncoder().encode(value)
        userDefaults.set(data, forKey: key)
    }

    func retrieve<T: Codable>(for key: String) throws -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
```

## 🧵 Concurrency Architecture

### Swift Concurrency Integration

```swift
actor NoteActor {
    private var notes: [UUID: Note] = [:]
    private let repository: NoteRepository

    func getNote(id: UUID) async throws -> Note? {
        if let cached = notes[id] {
            return cached
        }

        let note = try await repository.fetch(id: id)
        if let note = note {
            notes[id] = note
        }
        return note
    }

    func updateNote(_ note: Note) async throws {
        notes[note.id] = note
        try await repository.update(note)
    }
}
```

### Task Management

```swift
class TaskManager {
    private var tasks: [UUID: Task<Void, Error>] = [:]

    func performTask<T: Sendable>(
        id: UUID,
        priority: TaskPriority = .userInitiated,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        // Cancel existing task if any
        tasks[id]?.cancel()

        let task = Task(priority: priority) {
            try await operation()
        }

        tasks[id] = task

        defer { tasks.removeValue(forKey: id) }

        return try await task.value
    }
}
```

## 🔌 Dependency Injection

### Protocol-Based DI

```swift
protocol NoteServiceProtocol {
    var notesPublisher: AnyPublisher<[Note], Error> { get }

    func createNote(title: String, content: String, color: NoteColor) async throws -> Note
    func getAllNotes() async throws -> [Note]
    func updateNote(_ note: Note) async throws
    func deleteNote(id: UUID) async throws
}

protocol PersistenceControllerProtocol {
    var container: NSPersistentContainer { get }
    func save() throws
}

protocol ExportServiceProtocol {
    func exportNote(_ note: Note, format: ExportFormat) async throws -> URL
}
```

### Dependency Container

```swift
class DependencyContainer {
    static let shared = DependencyContainer()

    lazy var noteService: NoteServiceProtocol = {
        NoteService(
            repository: coreDataRepository,
            validator: noteValidator,
            syncService: cloudSyncService
        )
    }()

    lazy var coreDataRepository: NoteRepository = {
        CoreDataNoteRepository(persistenceController: persistenceController)
    }()

    lazy var persistenceController: PersistenceControllerProtocol = {
        PersistenceController.shared
    }()

    lazy var noteValidator: NoteValidator = {
        DefaultNoteValidator()
    }()

    lazy var cloudSyncService: CloudSyncService? = {
        CloudSyncService()
    }()

    lazy var exportService: ExportServiceProtocol = {
        ExportService()
    }()
}
```

## 🛡️ Error Handling Architecture

### Error Types Hierarchy

```swift
enum StickyNotesError: LocalizedError {
    case service(ServiceError)
    case persistence(PersistenceError)
    case network(NetworkError)
    case validation(ValidationError)
    case export(ExportError)

    var errorDescription: String? {
        switch self {
        case .service(let error):
            return error.localizedDescription
        case .persistence(let error):
            return "Data error: \(error.localizedDescription)"
        case .network(let error):
            return "Network error: \(error.localizedDescription)"
        case .validation(let error):
            return error.localizedDescription
        case .export(let error):
            return "Export error: \(error.localizedDescription)"
        }
    }
}

enum ServiceError: LocalizedError {
    case createFailed(Error)
    case fetchFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    case noteNotFound
    case invalidData
}

enum ValidationError: LocalizedError {
    case emptyNote
    case titleTooLong
    case contentTooLong
    case invalidTags
}
```

### Error Recovery

```swift
class ErrorHandler {
    func handle<T>(
        _ operation: () async throws -> T,
        recovery: (Error) -> T? = { _ in nil }
    ) async -> Result<T, StickyNotesError> {
        do {
            let result = try await operation()
            return .success(result)
        } catch let error as StickyNotesError {
            return .failure(error)
        } catch {
            if let recovered = recovery(error) {
                return .success(recovered)
            }
            return .failure(.service(.createFailed(error)))
        }
    }
}
```

## 🧪 Testing Architecture

### Testable Architecture Principles

```swift
protocol TestableNoteService {
    var notes: [Note] { get set }
    func createNote(_ note: Note) async throws
    func getNote(id: UUID) async throws -> Note?
}

class MockNoteService: TestableNoteService {
    var notes: [Note] = []
    var shouldFail = false

    func createNote(_ note: Note) async throws {
        if shouldFail {
            throw ServiceError.createFailed(NSError(domain: "test", code: -1))
        }
        notes.append(note)
    }

    func getNote(id: UUID) async throws -> Note? {
        notes.first { $0.id == id }
    }
}
```

### Test Structure

```
Tests/
├── Unit/
│   ├── Models/
│   │   ├── NoteTests.swift
│   │   └── NoteColorTests.swift
│   ├── Services/
│   │   ├── NoteServiceTests.swift
│   │   └── ExportServiceTests.swift
│   └── ViewModels/
│       └── NoteViewModelTests.swift
├── Integration/
│   ├── PersistenceIntegrationTests.swift
│   └── CloudSyncIntegrationTests.swift
└── UI/
    ├── NoteUITests.swift
    └── ExportUITests.swift
```

## 📊 Performance Architecture

### Memory Management

```swift
class NoteCache {
    private let cache = NSCache<NSString, Note>()
    private let maxCacheSize = 100

    init() {
        cache.countLimit = maxCacheSize
    }

    func cacheNote(_ note: Note) {
        cache.setObject(note, forKey: note.id.uuidString as NSString)
    }

    func getNote(id: UUID) -> Note? {
        cache.object(forKey: id.uuidString as NSString)
    }

    func clearCache() {
        cache.removeAllObjects()
    }
}
```

### Performance Monitoring

```swift
class PerformanceMonitor {
    static let shared = PerformanceMonitor()

    func measure<T>(
        _ operation: String,
        _ block: () throws -> T
    ) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        defer {
            let end = CFAbsoluteTimeGetCurrent()
            let duration = end - start
            print("[\(operation)] took \(duration) seconds")
        }
        return try block()
    }

    func measureAsync<T>(
        _ operation: String,
        _ block: () async throws -> T
    ) async rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        defer {
            let end = CFAbsoluteTimeGetCurrent()
            let duration = end - start
            print("[\(operation)] took \(duration) seconds")
        }
        return try await block()
    }
}
```

## 🔒 Security Architecture

### Data Protection

```swift
class SecurityManager {
    private let keychain = KeychainManager()

    func encryptNoteContent(_ content: String) throws -> Data {
        let key = try getOrCreateEncryptionKey()
        return try AES.GCM.seal(content.data(using: .utf8)!, using: key)
    }

    func decryptNoteContent(_ encryptedData: Data) throws -> String {
        let key = try getEncryptionKey()
        let decryptedData = try AES.GCM.open(encryptedData, using: key)
        guard let content = String(data: decryptedData, encoding: .utf8) else {
            throw SecurityError.decryptionFailed
        }
        return content
    }

    private func getOrCreateEncryptionKey() throws -> SymmetricKey {
        if let keyData = try keychain.getData(for: "noteEncryptionKey") {
            return try SymmetricKey(data: keyData)
        } else {
            let key = SymmetricKey(size: .bits256)
            try keychain.set(key.dataRepresentation, for: "noteEncryptionKey")
            return key
        }
    }
}
```

## 🚀 Scalability Considerations

### Modular Architecture

```
StickyNotes/
├── Core/           # Core business logic
├── UI/            # User interface components
├── Data/          # Data persistence layer
├── Services/      # External service integrations
├── Utilities/     # Shared utilities and helpers
└── Plugins/       # Plugin architecture
```

### Future Extensions

- **Cloud Sync**: iCloud integration for cross-device sync
- **Collaboration**: Real-time collaborative editing
- **Plugins**: Third-party extension support
- **API**: REST API for web integrations
- **Mobile**: iOS companion app

## 📋 Code Organization

### File Structure

```
Sources/StickyNotes/
├── Models/
│   ├── Note.swift
│   ├── NoteColor.swift
│   └── Extensions/
├── ViewModels/
│   ├── NoteViewModel.swift
│   ├── NotesViewModel.swift
│   └── Protocols/
├── Views/
│   ├── StickyNoteView.swift
│   ├── NoteListView.swift
│   └── Components/
├── Services/
│   ├── NoteService.swift
│   ├── ExportService.swift
│   └── Protocols/
├── Persistence/
│   ├── PersistenceController.swift
│   ├── NoteRepository.swift
│   └── Migrations/
├── Utilities/
│   ├── Constants.swift
│   ├── ErrorHandling.swift
│   └── Extensions/
└── Resources/
    ├── Assets.xcassets/
    └── Localization/
```

### Naming Conventions

```swift
// Protocols
protocol NoteServiceProtocol { }
protocol NoteRepository { }

// Classes
class NoteViewModel { }
class CoreDataNoteRepository { }

// Structs
struct Note { }
struct SearchFilters { }

// Enums
enum NoteColor { }
enum ExportFormat { }

// Extensions
extension Note { }
extension NoteService { }
```

## 🔄 Migration Strategy

### Data Migration

```swift
class MigrationManager {
    func migrateToVersion(_ version: String) throws {
        let currentVersion = getCurrentVersion()

        guard currentVersion != version else { return }

        switch (currentVersion, version) {
        case ("1.0.0", "1.1.0"):
            try migrate_1_0_0_to_1_1_0()
        case ("1.1.0", "2.0.0"):
            try migrate_1_1_0_to_2_0_0()
        default:
            throw MigrationError.unsupportedMigration
        }

        setCurrentVersion(version)
    }

    private func migrate_1_0_0_to_1_1_0() throws {
        // Add tags support to existing notes
        let context = persistenceController.container.viewContext
        let request = NoteEntity.fetchRequest()

        try context.performAndWait {
            let notes = try context.fetch(request)
            for note in notes {
                note.tags = [] as NSObject
            }
            try context.save()
        }
    }
}
```

This architecture provides a solid foundation for a maintainable, scalable, and testable macOS application that can evolve with future requirements while maintaining clean separation of concerns and modern development practices.