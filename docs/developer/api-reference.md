# API Reference

Complete API documentation for StickyNotes development and integration.

## 📚 API Overview

StickyNotes provides a comprehensive API for developers to integrate with the application, extend functionality, and build custom features.

### API Architecture

```
┌─────────────────────────────────────────────────┐
│                StickyNotes API                  │
├─────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│  │  Public API │ │ Plugin API  │ │  Internal  │ │
│  │             │ │             │ │   APIs     │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ │
├─────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┘ │
│  │ Swift APIs  │ │ REST APIs   │ │ WebSocket    │ │
│  │             │ │             │ │ APIs         │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────┘
```

## 🔧 Core Classes

### Note

The fundamental data model representing a sticky note.

```swift
public struct Note: Identifiable, Codable {
    public let id: UUID
    public var title: String
    public var content: String
    public var color: NoteColor
    public var position: CGPoint
    public var size: CGSize
    public var createdAt: Date
    public var modifiedAt: Date
    public var isMarkdown: Bool
    public var tags: [String]
    public var isLocked: Bool

    public init(
        id: UUID = UUID(),
        title: String = "",
        content: String = "",
        color: NoteColor = .yellow,
        position: CGPoint = .zero,
        size: CGSize = CGSize(width: 300, height: 200),
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        isMarkdown: Bool = false,
        tags: [String] = [],
        isLocked: Bool = false
    )
}
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `UUID` | Unique identifier for the note |
| `title` | `String` | Note title (optional) |
| `content` | `String` | Main note content |
| `color` | `NoteColor` | Visual color theme |
| `position` | `CGPoint` | Screen position coordinates |
| `size` | `CGSize` | Note dimensions |
| `createdAt` | `Date` | Creation timestamp |
| `modifiedAt` | `Date` | Last modification timestamp |
| `isMarkdown` | `Bool` | Whether content uses Markdown |
| `tags` | `[String]` | Associated tags |
| `isLocked` | `Bool` | Whether note is locked from editing |

#### Methods

```swift
// Create a new note with default values
public static func create() -> Note

// Create a note with specific content
public static func create(
    title: String,
    content: String,
    color: NoteColor
) -> Note

// Update modification timestamp
public mutating func touch()

// Check if note contains text
public func contains(_ text: String) -> Bool

// Export to different formats
public func export(as format: ExportFormat) throws -> Data
```

### NoteColor

Enumeration of available note color themes.

```swift
public enum NoteColor: String, Codable, CaseIterable {
    case yellow
    case blue
    case green
    case pink
    case purple
    case gray

    public var displayName: String {
        switch self {
        case .yellow: return "Yellow"
        case .blue: return "Blue"
        case .green: return "Green"
        case .pink: return "Pink"
        case .purple: return "Purple"
        case .gray: return "Gray"
        }
    }

    public var uiColor: NSColor {
        switch self {
        case .yellow: return NSColor.systemYellow
        case .blue: return NSColor.systemBlue
        case .green: return NSColor.systemGreen
        case .pink: return NSColor.systemPink
        case .purple: return NSColor.systemPurple
        case .gray: return NSColor.systemGray
        }
    }
}
```

## 🏪 Service Layer

### NoteService

Main service for note operations.

```swift
public class NoteService {
    public static let shared = NoteService()

    // Publishers for reactive updates
    public var notesPublisher: AnyPublisher<[Note], Never> { get }
    public var errorPublisher: AnyPublisher<Error, Never> { get }

    private init() {}
}
```

#### Core Methods

```swift
// MARK: - CRUD Operations

/// Create a new note
/// - Parameters:
///   - title: Note title
///   - content: Note content
///   - color: Note color theme
/// - Returns: Created note
/// - Throws: ServiceError
public func createNote(
    title: String,
    content: String,
    color: NoteColor
) async throws -> Note

/// Retrieve all notes
/// - Returns: Array of all notes
/// - Throws: ServiceError
public func getAllNotes() async throws -> [Note]

/// Retrieve a specific note by ID
/// - Parameter id: Note identifier
/// - Returns: Note if found
/// - Throws: ServiceError
public func getNote(withId id: UUID) async throws -> Note?

/// Update an existing note
/// - Parameter note: Updated note
/// - Throws: ServiceError
public func updateNote(_ note: Note) async throws

/// Delete a note
/// - Parameter id: Note identifier to delete
/// - Throws: ServiceError
public func deleteNote(withId id: UUID) async throws
```

#### Search and Filter Methods

```swift
// MARK: - Search & Filter

/// Search notes containing text
/// - Parameter query: Search query
/// - Returns: Matching notes
/// - Throws: ServiceError
public func searchNotes(containing query: String) async throws -> [Note]

/// Get notes with specific color
/// - Parameter color: Color to filter by
/// - Returns: Notes with matching color
/// - Throws: ServiceError
public func getNotes(withColor color: NoteColor) async throws -> [Note]

/// Get notes with specific tags
/// - Parameter tags: Tags to filter by
/// - Returns: Notes containing any of the tags
/// - Throws: ServiceError
public func getNotes(withTags tags: [String]) async throws -> [Note]

/// Get notes created within date range
/// - Parameters:
///   - startDate: Start of date range
///   - endDate: End of date range
/// - Returns: Notes in date range
/// - Throws: ServiceError
public func getNotes(
    createdBetween startDate: Date,
    and endDate: Date
) async throws -> [Note]
```

#### Utility Methods

```swift
// MARK: - Utilities

/// Get total count of notes
/// - Returns: Number of notes
public func getNotesCount() async throws -> Int

/// Check if iCloud sync is available
/// - Returns: True if iCloud sync is enabled and available
public func isCloudSyncAvailable() async -> Bool

/// Force synchronization with iCloud
/// - Throws: ServiceError
public func forceCloudSync() async throws

/// Export all notes to directory
/// - Parameter url: Destination directory URL
/// - Throws: ServiceError
public func exportAllNotes(to url: URL) async throws
```

### PersistenceController

Core Data persistence management.

```swift
public class PersistenceController {
    public static let shared = PersistenceController()

    public var container: NSPersistentContainer { get }

    // iCloud sync status
    public var syncStatusPublisher: AnyPublisher<SyncStatus, Never> { get }

    private init() {}
}
```

#### Methods

```swift
/// Save changes to persistent store
/// - Throws: PersistenceError
public func save() throws

/// Perform background task on private context
/// - Parameter block: Task to perform
public func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void)

/// Reset persistent store (WARNING: destroys all data)
/// - Throws: PersistenceError
public func resetStore() throws
```

## 🎨 UI Components

### StickyNoteView

Main view for displaying and editing notes.

```swift
public struct StickyNoteView: View {
    @ObservedObject var viewModel: NoteViewModel

    public init(note: Note)

    public var body: some View
}
```

#### Initialization

```swift
// Create view for existing note
let noteView = StickyNoteView(note: myNote)

// Create view with view model
let viewModel = NoteViewModel(note: myNote)
let noteView = StickyNoteView(viewModel: viewModel)
```

### NoteViewModel

View model for note state management.

```swift
public class NoteViewModel: ObservableObject {
    @Published public var note: Note
    @Published public var isEditing: Bool = false
    @Published public var showColorPicker: Bool = false

    public init(note: Note)

    // Actions
    public func save()
    public func delete()
    public func duplicate() -> Note
    public func export(to format: ExportFormat)
    public func toggleLock()
}
```

## 📤 Export System

### ExportFormat

Supported export formats.

```swift
public enum ExportFormat {
    case text
    case markdown
    case rtf
    case html
    case pdf
    case json
}
```

### ExportService

Handles note export operations.

```swift
public class ExportService {
    public static let shared = ExportService()

    private init() {}
}
```

#### Methods

```swift
/// Export single note
/// - Parameters:
///   - note: Note to export
///   - format: Export format
/// - Returns: URL of exported file
/// - Throws: ExportError
public func exportNote(
    _ note: Note,
    format: ExportFormat
) async throws -> URL

/// Export multiple notes
/// - Parameters:
///   - notes: Notes to export
///   - format: Export format
///   - directory: Destination directory
/// - Returns: URLs of exported files
/// - Throws: ExportError
public func exportNotes(
    _ notes: [Note],
    format: ExportFormat,
    to directory: URL
) async throws -> [URL]

/// Get available export formats for note
/// - Parameter note: Note to check
/// - Returns: Available formats
public func availableFormats(for note: Note) -> [ExportFormat]
```

## 🔍 Search System

### SearchService

Advanced search functionality.

```swift
public class SearchService {
    public static let shared = SearchService()

    private init() {}
}
```

#### Methods

```swift
/// Perform full-text search
/// - Parameter query: Search query
/// - Returns: Search results with highlights
public func search(_ query: String) async throws -> [SearchResult]

/// Search with filters
/// - Parameters:
///   - query: Search query
///   - filters: Search filters
/// - Returns: Filtered search results
public func search(
    _ query: String,
    filters: SearchFilters
) async throws -> [SearchResult]
```

### SearchFilters

Search filtering options.

```swift
public struct SearchFilters {
    public var colors: [NoteColor]?
    public var tags: [String]?
    public var dateRange: ClosedRange<Date>?
    public var isMarkdown: Bool?
    public var isLocked: Bool?

    public init(
        colors: [NoteColor]? = nil,
        tags: [String]? = nil,
        dateRange: ClosedRange<Date>? = nil,
        isMarkdown: Bool? = nil,
        isLocked: Bool? = nil
    )
}
```

### SearchResult

Search result with metadata.

```swift
public struct SearchResult {
    public let note: Note
    public let matches: [SearchMatch]
    public let relevanceScore: Double

    public struct SearchMatch {
        public let range: NSRange
        public let text: String
        public let context: String
    }
}
```

## 🔐 Security & Privacy

### SecurityService

Handles security operations.

```swift
public class SecurityService {
    public static let shared = SecurityService()

    private init() {}
}
```

#### Methods

```swift
/// Encrypt sensitive data
/// - Parameter data: Data to encrypt
/// - Returns: Encrypted data
/// - Throws: SecurityError
public func encrypt(_ data: Data) throws -> Data

/// Decrypt data
/// - Parameter data: Encrypted data
/// - Returns: Decrypted data
/// - Throws: SecurityError
public func decrypt(_ data: Data) throws -> Data

/// Generate secure random data
/// - Parameter length: Length in bytes
/// - Returns: Random data
public func generateRandomData(length: Int) throws -> Data

/// Hash data with SHA-256
/// - Parameter data: Data to hash
/// - Returns: SHA-256 hash
public func sha256(_ data: Data) -> Data
```

## 🌐 Networking (Future)

### APIClient

REST API client for external integrations.

```swift
public class APIClient {
    public static let shared = APIClient()

    public var baseURL: URL
    public var session: URLSession

    private init() {}
}
```

#### Methods

```swift
/// Perform GET request
/// - Parameter endpoint: API endpoint
/// - Returns: Decoded response
/// - Throws: APIError
public func get<T: Decodable>(_ endpoint: String) async throws -> T

/// Perform POST request
/// - Parameters:
///   - endpoint: API endpoint
///   - body: Request body
/// - Returns: Decoded response
/// - Throws: APIError
public func post<T: Decodable, U: Encodable>(
    _ endpoint: String,
    body: U
) async throws -> T

/// Upload file
/// - Parameters:
///   - endpoint: Upload endpoint
///   - fileURL: Local file URL
/// - Returns: Upload result
/// - Throws: APIError
public func upload(
    _ endpoint: String,
    fileURL: URL
) async throws -> UploadResult
```

## 📊 Analytics (Opt-in)

### AnalyticsService

Privacy-focused analytics.

```swift
public class AnalyticsService {
    public static let shared = AnalyticsService()

    public var isEnabled: Bool

    private init() {}
}
```

#### Methods

```swift
/// Track user action
/// - Parameters:
///   - action: Action name
///   - parameters: Additional parameters
public func track(action: String, parameters: [String: Any] = [:])

/// Track performance metric
/// - Parameters:
///   - metric: Metric name
///   - value: Metric value
///   - unit: Unit of measurement
public func track(metric: String, value: Double, unit: String)

/// Track error
/// - Parameter error: Error to track
public func track(error: Error)
```

## 🛠️ Error Types

### ServiceError

Service layer errors.

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
    case invalidData
    case networkError(Error)
    case authenticationRequired
}
```

### PersistenceError

Persistence layer errors.

```swift
public enum PersistenceError: LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case cloudKitError(Error)
    case syncFailed(Error)
    case invalidData
    case storeCorrupted
    case migrationFailed(Error)
}
```

### ExportError

Export operation errors.

```swift
public enum ExportError: LocalizedError {
    case invalidFormat
    case fileWriteFailed(Error)
    case conversionFailed
    case permissionDenied
    case diskFull
}
```

## 🔌 Plugin API (Future)

### PluginProtocol

Protocol for plugin extensions.

```swift
public protocol PluginProtocol {
    var identifier: String { get }
    var name: String { get }
    var version: String { get }

    func activate()
    func deactivate()
    func handle(action: PluginAction) -> PluginResult
}
```

### PluginManager

Manages plugin lifecycle.

```swift
public class PluginManager {
    public static let shared = PluginManager()

    public var plugins: [PluginProtocol] { get }

    private init() {}
}
```

#### Methods

```swift
/// Load plugin from URL
/// - Parameter url: Plugin bundle URL
/// - Throws: PluginError
public func loadPlugin(from url: URL) throws

/// Unload plugin
/// - Parameter identifier: Plugin identifier
/// - Throws: PluginError
public func unloadPlugin(with identifier: String) throws

/// Send action to plugin
/// - Parameters:
///   - action: Action to send
///   - pluginId: Target plugin identifier
/// - Returns: Plugin result
/// - Throws: PluginError
public func send(
    action: PluginAction,
    to pluginId: String
) throws -> PluginResult
```

## 📋 Constants & Types

### Constants

```swift
public struct Constants {
    public static let appVersion = "1.0.0"
    public static let buildNumber = "100"

    public struct Limits {
        public static let maxNoteTitleLength = 100
        public static let maxNoteContentLength = 10000
        public static let maxTagsPerNote = 10
        public static let maxNotesInMemory = 1000
    }

    public struct Defaults {
        public static let noteSize = CGSize(width: 300, height: 200)
        public static let noteColor = NoteColor.yellow
        public static let autoSaveInterval: TimeInterval = 1.0
    }
}
```

### Type Aliases

```swift
public typealias NoteID = UUID
public typealias Tag = String
public typealias SearchQuery = String
public typealias ExportResult = Result<URL, ExportError>
```

## 🔄 Reactive Extensions

### Combine Publishers

```swift
extension NoteService {
    /// Publisher for all notes
    public var notesPublisher: AnyPublisher<[Note], Never>

    /// Publisher for service errors
    public var errorPublisher: AnyPublisher<ServiceError, Never>

    /// Publisher for sync status
    public var syncStatusPublisher: AnyPublisher<SyncStatus, Never>
}

extension PersistenceController {
    /// Publisher for Core Data changes
    public var changesPublisher: AnyPublisher<NSPersistentStoreCoordinator, Never>
}
```

### Async/Await Integration

```swift
extension NoteService {
    /// Async sequence of note changes
    public var notesAsyncSequence: AsyncPublisher<AnyPublisher<[Note], Never>> {
        notesPublisher.values
    }
}
```

## 📖 Usage Examples

### Basic Note Operations

```swift
// Create a new note
let note = try await NoteService.shared.createNote(
    title: "My Note",
    content: "This is my note content",
    color: .blue
)

// Update the note
var updatedNote = note
updatedNote.content = "Updated content"
try await NoteService.shared.updateNote(updatedNote)

// Search for notes
let results = try await NoteService.shared.searchNotes(containing: "content")

// Export note
let exportURL = try await ExportService.shared.exportNote(
    note,
    format: .markdown
)
```

### Reactive Note Binding

```swift
import Combine

class MyViewModel: ObservableObject {
    @Published var notes: [Note] = []
    private var cancellables = Set<AnyCancellable>()

    init() {
        NoteService.shared.notesPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$notes)
            .store(in: &cancellables)
    }
}
```

### Custom Export Format

```swift
extension ExportService {
    func exportNoteAsCustomFormat(_ note: Note) async throws -> URL {
        let customContent = """
        # \(note.title)

        \(note.content)

        ---
        Created: \(note.createdAt)
        Color: \(note.color.displayName)
        """

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(note.id).custom")

        try customContent.write(to: tempURL, atomically: true, encoding: .utf8)
        return tempURL
    }
}
```

---

*This API reference covers StickyNotes version 1.0.0. APIs are subject to change in future versions. Check the [changelog](https://github.com/your-org/stickynotes/blob/main/CHANGELOG.md) for updates.*