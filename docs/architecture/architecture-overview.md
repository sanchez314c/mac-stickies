# Architecture Overview

High-level overview of StickyNotes' system architecture, design principles, and component interactions.

## 🏛️ System Architecture

StickyNotes is built as a modern macOS application following Apple's development best practices and Swift concurrency patterns. The architecture emphasizes modularity, testability, and maintainability.

### Core Design Principles

```
🎯 Single Responsibility - Each component has one clear purpose
🔄 Dependency Inversion - High-level modules don't depend on low-level modules
📦 Interface Segregation - Clients depend only on methods they use
🔌 Plugin Architecture - Extensible through protocols and dependency injection
⚡ Reactive Programming - Combine framework for state management
🧵 Concurrency Safety - Swift Concurrency for thread-safe operations
```

## 🏗️ Architectural Layers

### Presentation Layer (SwiftUI)

**Components:**
- **Views**: SwiftUI views for user interface
- **ViewModels**: State management and business logic
- **Coordinators**: Navigation and flow control

**Responsibilities:**
- User interaction handling
- UI state management
- Data presentation
- Accessibility support

### Business Logic Layer

**Components:**
- **Services**: Core business operations
- **Use Cases**: Application-specific business rules
- **Domain Models**: Business entities and rules

**Responsibilities:**
- Business rule enforcement
- Data validation
- Application workflows
- Error handling

### Data Access Layer

**Components:**
- **Repositories**: Data access abstraction
- **Data Sources**: Concrete data implementations
- **Persistence**: Core Data and file system operations

**Responsibilities:**
- Data persistence
- Caching strategies
- Synchronization
- Migration handling

### Infrastructure Layer

**Components:**
- **Networking**: API clients and request handling
- **Security**: Encryption and authentication
- **Utilities**: Shared utilities and helpers
- **External Services**: Third-party integrations

**Responsibilities:**
- External communication
- Security operations
- System integration
- Cross-cutting concerns

## 🔄 Data Flow Architecture

### Unidirectional Data Flow

```
User Action → View → ViewModel → Service → Repository → Data Source
                                                              ↓
UI Update ← View ← ViewModel ← Service ← Repository ← Data Source
```

### Reactive Data Binding

```swift
// ViewModel publishes state changes
class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading = false
    @Published var error: Error?

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
                    self?.error = error
                }
                self?.isLoading = false
            } receiveValue: { [weak self] notes in
                self?.notes = notes
                self?.error = nil
                self?.isLoading = false
            }
            .store(in: &cancellables)
    }
}
```

### State Management Strategy

**Local State:**
- View-specific state managed by individual ViewModels
- UI state (loading, errors) handled locally
- Temporary state not persisted

**Global State:**
- Application-wide state managed by AppState
- User preferences and settings
- Cross-screen data coordination

**Persistent State:**
- User data persisted via repositories
- Application settings in UserDefaults
- Cloud synchronization for cross-device state

## 🧩 Component Architecture

### MVVM-C Pattern Implementation

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│      View       │    │   ViewModel     │    │     Model      │    │  Coordinator    │
│                 │    │                 │    │                │    │                 │
│ • SwiftUI       │◄──►│ • State Mgmt    │◄──►│ • Data Models  │◄──►│ • Navigation    │
│ • UI Logic      │    │ • Business      │    │ • Validation   │    │ • Flow Control  │
│ • User Input    │    │ • Data Binding  │    │ • Domain Logic │    │ • Deep Links    │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
```

#### View Layer Details

**Atomic Design:**
- **Atoms**: Basic UI components (buttons, text fields)
- **Molecules**: Composite components (note toolbar, color picker)
- **Organisms**: Complex components (note editor, list view)
- **Templates**: Page-level layouts
- **Pages**: Complete screen implementations

**State-Driven Rendering:**
```swift
struct StickyNoteView: View {
    @ObservedObject var viewModel: NoteViewModel

    var body: some View {
        ZStack {
            NoteBackground(color: viewModel.note.color)
            NoteContent(viewModel: viewModel)
            if viewModel.isEditing {
                NoteToolbar(viewModel: viewModel)
            }
        }
        .frame(minWidth: 200, minHeight: 150)
        .opacity(viewModel.isLoading ? 0.5 : 1.0)
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}
```

#### ViewModel Layer Details

**State Management:**
- Observable properties for UI binding
- Computed properties for derived state
- Private state for internal logic

**Action Handling:**
```swift
class NoteViewModel: ObservableObject {
    // State
    @Published private(set) var note: Note
    @Published var isEditing = false
    @Published var showColorPicker = false

    // Actions
    func startEditing() {
        isEditing = true
        showColorPicker = false
    }

    func saveChanges() async {
        do {
            try await noteService.updateNote(note)
            isEditing = false
        } catch {
            // Handle error
        }
    }

    func changeColor(_ color: NoteColor) {
        note.color = color
        showColorPicker = false
    }
}
```

#### Model Layer Details

**Domain Models:**
```swift
struct Note: Identifiable, Codable, Hashable {
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
    }
}
```

#### Coordinator Layer Details

**Navigation Coordination:**
```swift
class AppCoordinator {
    private let windowManager: WindowManager
    private var noteWindows: [UUID: NSWindow] = [:]

    func showNote(_ note: Note) {
        if let existingWindow = noteWindows[note.id] {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }

        let window = createNoteWindow(for: note)
        window.makeKeyAndOrderFront(nil)
        noteWindows[note.id] = window
    }

    func closeNote(_ noteId: UUID) {
        noteWindows[noteId]?.close()
        noteWindows.removeValue(forKey: noteId)
    }
}
```

### Repository Pattern Implementation

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

    // Reactive interface
    var notesPublisher: AnyPublisher<[Note], Error> { get }
}
```

#### Data Access Strategy
- **Primary Storage**: Core Data for structured data
- **Secondary Storage**: UserDefaults for preferences
- **Cache Layer**: In-memory cache for performance
- **Sync Layer**: CloudKit for cross-device synchronization

## 🧵 Concurrency Architecture

### Swift Concurrency Integration

**Async/Await Pattern:**
```swift
class NoteService {
    private let repository: NoteRepository

    func createNote(
        title: String,
        content: String,
        color: NoteColor
    ) async throws -> Note {
        let note = Note(title: title, content: content, color: color)
        try note.validate()

        return try await repository.create(note)
    }

    func fetchAllNotes() async throws -> [Note] {
        return try await repository.fetchAll()
    }
}
```

**Actor-Based Isolation:**
```swift
actor NoteCache {
    private var cache: [UUID: Note] = [:]

    func getNote(id: UUID) async throws -> Note? {
        if let cached = cache[id] {
            return cached
        }

        // Fetch from repository if not cached
        let note = try await repository.fetch(id: id)
        if let note = note {
            cache[id] = note
        }
        return note
    }

    func updateNote(_ note: Note) async {
        cache[note.id] = note
    }
}
```

**Task Management:**
```swift
class BackgroundTaskManager {
    private var tasks: [UUID: Task<Void, Error>] = [:]

    func performTask<T>(
        id: UUID,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        // Cancel existing task if any
        tasks[id]?.cancel()

        let task = Task {
            defer { tasks.removeValue(forKey: id) }
            return try await operation()
        }

        tasks[id] = task
        return try await task.value
    }
}
```

## 🔒 Security Architecture

### Data Protection Layers

**Encryption Strategy:**
- **At Rest**: AES-256 encryption for stored notes
- **In Transit**: TLS 1.3 for network communication
- **Key Management**: Secure keychain integration

**Access Control:**
- **Local Authentication**: Biometric/PIN protection
- **Permission Model**: Granular access controls
- **Audit Logging**: Security event tracking

### Privacy by Design

**Data Minimization:**
- No unnecessary data collection
- Local processing when possible
- User consent for cloud features

**Transparency:**
- Clear privacy policy
- Data usage explanations
- User data export/deletion options

## 📊 Performance Architecture

### Optimization Strategies

**Memory Management:**
- Efficient data structures
- Lazy loading for large datasets
- Automatic resource cleanup

**Caching Strategy:**
- Multi-level caching (memory, disk, network)
- Intelligent cache invalidation
- Background cache warming

**Rendering Performance:**
- SwiftUI's efficient diffing
- Background processing for heavy operations
- Optimized drawing for floating windows

## 🧪 Testing Architecture

### Test Pyramid Implementation

```
UI Tests (20%)     ┌─────────────┐
Integration (30%)  │  End-to-End │
Unit Tests (50%)   └─────────────┘
```

**Unit Tests:** Business logic, data models, utilities
**Integration Tests:** Component interaction, data persistence
**UI Tests:** User workflows, interface validation

### Testable Architecture

**Dependency Injection:**
```swift
protocol NoteServiceProtocol {
    func createNote(_ note: Note) async throws
    func getNote(id: UUID) async throws -> Note?
}

class MockNoteService: NoteServiceProtocol {
    var notes: [Note] = []

    func createNote(_ note: Note) async throws {
        notes.append(note)
    }

    func getNote(id: UUID) async throws -> Note? {
        notes.first { $0.id == id }
    }
}
```

## 🚀 Scalability Considerations

### Horizontal Scaling

**Data Layer Scaling:**
- Database connection pooling
- Read/write separation
- Sharding strategies for large datasets

**Service Layer Scaling:**
- Microservice decomposition potential
- API rate limiting
- Background job processing

### Performance Scaling

**Caching Strategies:**
- CDN for static assets
- Database query optimization
- Memory-efficient data structures

**Resource Optimization:**
- Lazy loading and pagination
- Background processing
- Intelligent prefetching

## 🔄 Evolution Strategy

### Architectural Evolution

**Phase 1 (Current):** Monolithic macOS app
**Phase 2 (Future):** Modular architecture with plugins
**Phase 3 (Future):** Microservices with cross-platform support

### Migration Strategy

**Incremental Migration:**
- Feature flags for new functionality
- Gradual component replacement
- Backward compatibility maintenance

**Risk Mitigation:**
- Comprehensive testing at each step
- Rollback procedures
- Performance monitoring

## 📋 Architecture Decision Records

### Key Decisions

**ADR 001: MVVM-C Architecture**
- **Context**: Need for testable, maintainable UI code
- **Decision**: Adopt MVVM-C pattern with coordinators
- **Consequences**: Improved testability, complex navigation logic

**ADR 002: Core Data Persistence**
- **Context**: Need for robust local data storage
- **Decision**: Use Core Data with CloudKit integration
- **Consequences**: Complex migration handling, strong querying

**ADR 003: Swift Concurrency**
- **Context**: Modern async programming requirements
- **Decision**: Adopt Swift Concurrency throughout
- **Consequences**: Learning curve, iOS 13+ requirement

**ADR 004: Repository Pattern**
- **Context**: Data access abstraction needs
- **Decision**: Implement repository pattern for data access
- **Consequences**: Additional abstraction layer, improved testability

## 📊 Quality Attributes

### Performance
- **Startup Time**: < 2 seconds
- **Memory Usage**: < 100MB with 1000 notes
- **Responsiveness**: 60 FPS UI updates

### Reliability
- **Crash Rate**: < 0.1%
- **Data Loss**: Zero tolerance
- **Error Recovery**: Graceful degradation

### Security
- **Data Encryption**: AES-256 at rest
- **Network Security**: TLS 1.3 in transit
- **Access Control**: Role-based permissions

### Usability
- **Accessibility**: WCAG 2.1 AA compliance
- **Performance**: Smooth 60 FPS experience
- **Intuitiveness**: Learnable in < 5 minutes

---

*This architecture overview provides a high-level understanding of StickyNotes' system design. For detailed implementation information, refer to the specific component documentation.*