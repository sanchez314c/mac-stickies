# StickyNotes macOS App - Technical Architecture

## Overview

StickyNotes is a native macOS application that provides floating sticky note functionality directly on the desktop. The app window itself serves as a sticky note, with support for multiple notes, color customization, markdown formatting, and text export capabilities.

## Architecture Overview

### Core Architecture Pattern: MVVM (Model-View-ViewModel)

The application follows the MVVM (Model-View-ViewModel) architectural pattern, which provides clear separation of concerns and excellent testability.

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│      View       │    │   ViewModel     │    │     Model       │
│                 │    │                 │    │                 │
│ • SwiftUI Views │◄──►│ • State Mgmt    │◄──►│ • Data Models   │
│ • UI Components │    │ • Business Logic│    │ • Persistence   │
│ • User Input    │    │ • Data Binding  │    │ • Core Data     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Component Breakdown

### 1. Application Layer (`StickyNotesApp`)

```swift
@main
struct StickyNotesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
```

**Responsibilities:**
- Application lifecycle management
- Window configuration
- macOS integration setup

### 2. View Layer (SwiftUI)

#### Main Components:
- `StickyNoteView`: Individual note display and editing
- `NoteListView`: Multiple notes management
- `ColorPickerView`: Note color customization
- `ExportView`: Export functionality

#### Key Features:
- Declarative UI with SwiftUI
- State-driven rendering
- Native macOS design integration

### 3. ViewModel Layer

#### Core ViewModels:
- `NoteViewModel`: Individual note state management
- `NotesViewModel`: Collection management
- `AppViewModel`: Application-level state

#### State Management:
```swift
class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var selectedNote: Note?

    private let persistenceService: PersistenceService
    private let notificationService: NotificationService

    // Business logic methods
}
```

### 4. Model Layer

#### Data Models:
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
}
```

#### Persistence Models:
- Core Data entities for long-term storage
- UserDefaults for app preferences
- File system for export operations

## Data Flow Architecture

### Unidirectional Data Flow

```
User Action → View → ViewModel → Model → Persistence
                                      ↓
                                 UI Update ← View ← ViewModel
```

### State Management Flow:

1. **User Interaction** → View captures input
2. **View** → Binds to ViewModel properties
3. **ViewModel** → Processes business logic
4. **Model** → Updates data structures
5. **Persistence** → Saves to storage
6. **ViewModel** → Publishes state changes
7. **View** → Re-renders with new state

## Window Management System

### Window Architecture

```
┌─────────────────────────────────────┐
│         Window Manager               │
├─────────────────────────────────────┤
│ • Window Creation & Lifecycle       │
│ • Position & Size Management        │
│ • Z-Index & Layering                │
│ • Desktop Integration               │
└─────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────┐
│         NSWindow Management         │
├─────────────────────────────────────┤
│ • Floating Window Behavior         │
│ • Always-on-top Functionality      │
│ • Borderless Design                │
│ • Transparency Support             │
└─────────────────────────────────────┘
```

### Key Window Features:

#### Floating Behavior:
```swift
extension NSWindow {
    func configureAsStickyNote() {
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = true
    }
}
```

#### Window Management:
- Multiple simultaneous note windows
- Independent positioning and sizing
- Z-index management for layering
- Desktop coordinate system integration

## Persistence Layer

### Multi-Layer Persistence Strategy

```
┌─────────────────────────────────────┐
│         Persistence Layer           │
├─────────────────────────────────────┤
│ • Core Data (Primary Storage)      │
│ • UserDefaults (Preferences)       │
│ • File System (Export)             │
│ • iCloud (Sync - Future)           │
└─────────────────────────────────────┘
```

### Core Data Architecture:

#### Data Model:
```
Note Entity:
├── id: UUID (Primary Key)
├── title: String
├── content: String
├── color: Transformable (NoteColor)
├── positionX: Double
├── positionY: Double
├── width: Double
├── height: Double
├── createdAt: Date
├── modifiedAt: Date
└── isMarkdown: Bool
```

#### Persistence Service:
```swift
class PersistenceService {
    private let container: NSPersistentContainer

    func saveNote(_ note: Note) async throws {
        let context = container.viewContext
        // Core Data save logic
    }

    func fetchNotes() async throws -> [Note] {
        let context = container.viewContext
        // Core Data fetch logic
    }
}
```

### Export Capabilities:

#### Supported Formats:
- Plain Text (.txt)
- Markdown (.md)
- JSON (.json)
- PDF (.pdf)

#### Export Service:
```swift
class ExportService {
    func exportNote(_ note: Note, format: ExportFormat) async throws -> URL {
        switch format {
        case .text:
            return try exportAsText(note)
        case .markdown:
            return try exportAsMarkdown(note)
        case .pdf:
            return try exportAsPDF(note)
        }
    }
}
```

## macOS Integration Details

### System Integration Points:

#### 1. Application Lifecycle:
```swift
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure floating windows
        // Setup global hotkeys
        // Initialize services
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep app running with no windows
    }
}
```

#### 2. Menu Bar Integration:
```swift
struct AppMenu: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Note") {
                // Create new note
            }
            .keyboardShortcut("n", modifiers: .command)
        }

        CommandGroup(replacing: .saveItem) {
            Button("Export Note") {
                // Export current note
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
        }
    }
}
```

#### 3. Global Hotkeys:
```swift
class HotkeyManager {
    func registerGlobalHotkeys() {
        // Cmd+N: New Note
        // Cmd+W: Close Note
        // Cmd+Shift+E: Export
        // Cmd+,: Preferences
    }
}
```

#### 4. Notification Center Integration:
```swift
class NotificationService {
    func requestPermissions() async {
        let center = UNUserNotificationCenter.current()
        try await center.requestAuthorization(options: [.alert, .sound])
    }

    func showNoteReminder(for note: Note) {
        let content = UNMutableNotificationContent()
        content.title = note.title
        content.body = "Don't forget this note!"
        // Schedule notification
    }
}
```

### Desktop Integration:

#### Always-on-Top Behavior:
```swift
extension NSWindow.Level {
    static let stickyNote = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)
}
```

#### Desktop Coordinate System:
```swift
extension NSWindow {
    var desktopPosition: CGPoint {
        get {
            let screenFrame = screen?.frame ?? .zero
            return CGPoint(x: frame.origin.x, y: screenFrame.height - frame.maxY)
        }
        set {
            let screenFrame = screen?.frame ?? .zero
            setFrameOrigin(CGPoint(x: newValue.x, y: screenFrame.height - frame.height - newValue.y))
        }
    }
}
```

## Key Design Patterns

### 1. Observer Pattern (Combine Framework)
```swift
class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        // Reactive data binding
        $notes
            .sink { [weak self] notes in
                self?.handleNotesUpdate(notes)
            }
            .store(in: &cancellables)
    }
}
```

### 2. Repository Pattern
```swift
protocol NoteRepository {
    func fetchNotes() async throws -> [Note]
    func saveNote(_ note: Note) async throws
    func deleteNote(id: UUID) async throws
}

class CoreDataNoteRepository: NoteRepository {
    private let persistenceService: PersistenceService

    // Implementation using Core Data
}
```

### 3. Factory Pattern
```swift
class NoteFactory {
    static func createNote(title: String = "New Note",
                          color: NoteColor = .yellow) -> Note {
        return Note(
            id: UUID(),
            title: title,
            content: "",
            color: color,
            position: .zero,
            size: CGSize(width: 300, height: 200),
            createdAt: Date(),
            modifiedAt: Date(),
            isMarkdown: false
        )
    }
}
```

### 4. Coordinator Pattern (Navigation)
```swift
class AppCoordinator {
    private var windows: [NSWindow] = []

    func showNote(_ note: Note) {
        let window = createNoteWindow(for: note)
        window.makeKeyAndOrderFront(nil)
        windows.append(window)
    }

    private func createNoteWindow(for note: Note) -> NSWindow {
        // Window creation logic
    }
}
```

## Security Considerations

### Data Protection:
- Local-only storage (no cloud sync by default)
- Secure coding practices
- Input validation and sanitization

### Privacy:
- No data collection or telemetry
- Local-only operation
- User data stays on device

## Performance Optimizations

### Memory Management:
- Efficient data structures
- Lazy loading for large note collections
- Automatic cleanup of unused resources

### Rendering Performance:
- SwiftUI's efficient diffing algorithm
- Background processing for heavy operations
- Optimized drawing for floating windows

### Storage Performance:
- Batch operations for Core Data
- Efficient querying and indexing
- Background persistence operations

## Testing Strategy

### Unit Testing:
- ViewModel business logic
- Data transformation functions
- Service layer operations

### UI Testing:
- User interaction flows
- Window management
- Export functionality

### Integration Testing:
- Core Data operations
- File system interactions
- macOS system integration

## Deployment & Distribution

### Build Configuration:
- Debug: Development builds
- Release: Production builds
- App Store: Distribution builds

### Code Signing:
- Development certificates
- Distribution certificates
- App Store certificates

### Packaging:
- macOS .app bundle
- Proper entitlements
- Sandbox configuration

## Future Enhancements

### Planned Features:
- iCloud synchronization
- Note sharing
- Advanced markdown support
- Voice notes
- Templates and themes

### Architecture Extensions:
- Plugin system
- Cloud backup
- Collaboration features
- Advanced search and filtering

---

## Architecture Diagrams

### High-Level Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                    StickyNotes App                          │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │   SwiftUI   │ │  ViewModel  │ │   Models    │           │
│  │    Views    │ │   Layer     │ │   Layer     │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │ Core Data   │ │ File System │ │ macOS APIs  │           │
│  │ Persistence │ │   Export    │ │ Integration │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow Diagram
```
User Input → SwiftUI View → ViewModel → Business Logic → Model Update → Core Data
                                                                 ↓
UI Re-render ← State Change ← Published Properties ← Data Binding ← ViewModel
```

This architecture provides a solid foundation for a maintainable, scalable, and user-friendly sticky notes application that integrates seamlessly with macOS while following modern Swift development best practices.