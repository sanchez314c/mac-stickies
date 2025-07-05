# Data Model

Comprehensive documentation of StickyNotes' data structures, relationships, and persistence strategy.

## 📊 Core Data Models

### Note Entity

The fundamental data model representing a sticky note.

```swift
struct Note: Identifiable, Codable, Hashable {
    // Primary identifier
    let id: UUID

    // Content
    var title: String
    var content: String
    var isMarkdown: Bool

    // Appearance
    var color: NoteColor
    var position: CGPoint
    var size: CGSize

    // Metadata
    var createdAt: Date
    var modifiedAt: Date
    var isLocked: Bool
    var tags: [String]

    // Initialization
    init(
        id: UUID = UUID(),
        title: String = "",
        content: String = "",
        color: NoteColor = .yellow,
        position: CGPoint = .zero,
        size: CGSize = CGSize(width: 300, height: 200),
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        isMarkdown: Bool = false,
        isLocked: Bool = false,
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.color = color
        self.position = position
        self.size = size
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.isMarkdown = isMarkdown
        self.isLocked = isLocked
        self.tags = tags
    }
}
```

#### Field Specifications

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `id` | `UUID` | Yes | Auto-generated | Unique identifier |
| `title` | `String` | No | Empty | Note title (optional) |
| `content` | `String` | No | Empty | Main note content |
| `isMarkdown` | `Bool` | No | `false` | Markdown rendering enabled |
| `color` | `NoteColor` | No | `.yellow` | Visual color theme |
| `position` | `CGPoint` | No | `.zero` | Screen position |
| `size` | `CGSize` | No | `300×200` | Note dimensions |
| `createdAt` | `Date` | Yes | Current date | Creation timestamp |
| `modifiedAt` | `Date` | Yes | Current date | Last modification |
| `isLocked` | `Bool` | No | `false` | Edit protection |
| `tags` | `[String]` | No | Empty array | Associated tags |

### NoteColor Enumeration

Defines available color themes for notes.

```swift
enum NoteColor: String, Codable, CaseIterable {
    case yellow = "yellow"
    case blue = "blue"
    case green = "green"
    case pink = "pink"
    case purple = "purple"
    case gray = "gray"

    var displayName: String {
        switch self {
        case .yellow: return "Yellow"
        case .blue: return "Blue"
        case .green: return "Green"
        case .pink: return "Pink"
        case .purple: return "Purple"
        case .gray: return "Gray"
        }
    }

    var uiColor: NSColor {
        switch self {
        case .yellow: return NSColor.systemYellow
        case .blue: return NSColor.systemBlue
        case .green: return NSColor.systemGreen
        case .pink: return NSColor.systemPink
        case .purple: return NSColor.systemPurple
        case .gray: return NSColor.systemGray
        }
    }

    var hexValue: String {
        switch self {
        case .yellow: return "#FFEB3B"
        case .blue: return "#2196F3"
        case .green: return "#4CAF50"
        case .pink: return "#E91E63"
        case .purple: return "#9C27B0"
        case .gray: return "#9E9E9E"
        }
    }
}
```

## 🗂️ Core Data Schema

### Note Entity (Core Data)

```xml
<!-- StickyNotes.xcdatamodel -->
<entity name="NoteEntity" representedClassName="NoteEntity" syncable="YES">
    <attribute name="id" attributeType="UUID" usesScalarValueType="NO" syncable="YES"/>
    <attribute name="title" attributeType="String" syncable="YES"/>
    <attribute name="content" attributeType="String" syncable="YES"/>
    <attribute name="color" attributeType="String" syncable="YES"/>
    <attribute name="positionX" attributeType="Double" defaultValueString="0.0" usesScalarValueType="YES" syncable="YES"/>
    <attribute name="positionY" attributeType="Double" defaultValueString="0.0" usesScalarValueType="YES" syncable="YES"/>
    <attribute name="width" attributeType="Double" defaultValueString="300.0" usesScalarValueType="YES" syncable="YES"/>
    <attribute name="height" attributeType="Double" defaultValueString="200.0" usesScalarValueType="YES" syncable="YES"/>
    <attribute name="createdAt" attributeType="Date" usesScalarValueType="NO" syncable="YES"/>
    <attribute name="modifiedAt" attributeType="Date" usesScalarValueType="NO" syncable="YES"/>
    <attribute name="isMarkdown" attributeType="Boolean" defaultValueString="NO" usesScalarValueType="YES" syncable="YES"/>
    <attribute name="isLocked" attributeType="Boolean" defaultValueString="NO" usesScalarValueType="YES" syncable="YES"/>
    <attribute name="tags" attributeType="Transformable" syncable="YES"/>
</entity>
```

### Relationships

Currently, StickyNotes uses a simple, non-relational data model. Future versions may introduce:

- **Tag Entity**: Separate tags with many-to-many relationships
- **Category Entity**: Note organization hierarchies
- **Attachment Entity**: File attachments and media

## 🔄 Data Transformation

### Model Conversion

```swift
extension NoteEntity {
    func toNote() -> Note {
        Note(
            id: id ?? UUID(),
            title: title ?? "",
            content: content ?? "",
            color: NoteColor(rawValue: color ?? "yellow") ?? .yellow,
            position: CGPoint(x: positionX, y: positionY),
            size: CGSize(width: width, height: height),
            createdAt: createdAt ?? Date(),
            modifiedAt: modifiedAt ?? Date(),
            isMarkdown: isMarkdown,
            isLocked: isLocked,
            tags: tags as? [String] ?? []
        )
    }
}

extension Note {
    func toEntity(context: NSManagedObjectContext) -> NoteEntity {
        let entity = NoteEntity(context: context)
        entity.id = id
        entity.title = title
        entity.content = content
        entity.color = color.rawValue
        entity.positionX = position.x
        entity.positionY = position.y
        entity.width = size.width
        entity.height = size.height
        entity.createdAt = createdAt
        entity.modifiedAt = modifiedAt
        entity.isMarkdown = isMarkdown
        entity.isLocked = isLocked
        entity.tags = tags as NSObject
        return entity
    }
}
```

### JSON Serialization

```swift
extension Note {
    func toJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(self)
    }

    static func fromJSON(_ data: Data) throws -> Note {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Note.self, from: data)
    }
}
```

## 💾 Persistence Strategy

### Multi-Layer Storage

```
┌─────────────────────────────────────┐
│         Application Layer           │
├─────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐    │
│  │ Core Data   │ │ UserDefaults│    │
│  │ (Notes)     │ │ (Settings)  │    │
│  └─────────────┘ └─────────────┘    │
├─────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐    │
│  │ File System │ │ Keychain    │    │
│  │ (Exports)   │ │ (Secrets)   │    │
│  └─────────────┘ └─────────────┘    │
└─────────────────────────────────────┘
```

#### Primary Storage: Core Data
- **Purpose**: Structured note data persistence
- **Features**: Relationships, querying, migrations
- **Location**: `~/Library/Containers/com.superclaude.stickynotes/Data/Documents/StickyNotes.sqlite`

#### Secondary Storage: UserDefaults
- **Purpose**: Application preferences and settings
- **Features**: Key-value storage, automatic synchronization
- **Location**: `~/Library/Preferences/com.superclaude.stickynotes.plist`

#### Tertiary Storage: File System
- **Purpose**: Export files, temporary data
- **Features**: Direct file access, large file support
- **Location**: `~/Documents/StickyNotes/`

### Data Encryption

```swift
class DataEncryptionService {
    private let keychain = KeychainManager()

    func encryptNoteData(_ data: Data) throws -> Data {
        let key = try getOrCreateEncryptionKey()
        return try AES.GCM.seal(data, using: key)
    }

    func decryptNoteData(_ encryptedData: Data) throws -> Data {
        let key = try getEncryptionKey()
        return try AES.GCM.open(encryptedData, using: key)
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

## 🔄 Data Migration

### Schema Evolution

```swift
class MigrationManager {
    static let currentVersion = "1.0.0"

    func migrateStoreIfNeeded() throws {
        let currentVersion = getCurrentVersion()

        switch (currentVersion, Self.currentVersion) {
        case ("1.0.0", "1.1.0"):
            try migrate_1_0_0_to_1_1_0()
        case ("1.1.0", "2.0.0"):
            try migrate_1_1_0_to_2_0_0()
        default:
            break // No migration needed
        }

        setCurrentVersion(Self.currentVersion)
    }

    private func migrate_1_0_0_to_1_1_0() throws {
        // Add tags support to existing notes
        let context = persistentContainer.viewContext
        let request = NSFetchRequest<NoteEntity>(entityName: "NoteEntity")

        try context.performAndWait {
            let notes = try context.fetch(request)
            for note in notes {
                note.tags = [] as NSObject // Add empty tags array
            }
            try context.save()
        }
    }

    private func migrate_1_1_0_to_2_0_0() throws {
        // Add markdown support
        let context = persistentContainer.viewContext
        let request = NSFetchRequest<NoteEntity>(entityName: "NoteEntity")

        try context.performAndWait {
            let notes = try context.fetch(request)
            for note in notes {
                note.isMarkdown = false // Default to plain text
            }
            try context.save()
        }
    }
}
```

### Migration Strategies

- **Lightweight Migration**: Automatic for simple schema changes
- **Manual Migration**: Custom mapping for complex changes
- **Progressive Migration**: Migrate data in background
- **Rollback Support**: Ability to revert migrations

## ☁️ Cloud Synchronization

### iCloud Integration

```swift
class CloudSyncService {
    private let container: CKContainer
    private let privateDatabase: CKDatabase

    init() {
        container = CKContainer(identifier: "iCloud.com.superclaude.stickynotes")
        privateDatabase = container.privateCloudDatabase
    }

    func syncNote(_ note: Note) async throws {
        let record = note.toCloudKitRecord()
        try await privateDatabase.save(record)
    }

    func fetchCloudNotes() async throws -> [Note] {
        let query = CKQuery(recordType: "Note", predicate: NSPredicate(value: true))
        let result = try await privateDatabase.records(matching: query)

        return result.matchResults.compactMap { _, result in
            switch result {
            case .success(let record):
                return Note.fromCloudKitRecord(record)
            case .failure:
                return nil
            }
        }
    }
}

extension Note {
    func toCloudKitRecord() -> CKRecord {
        let record = CKRecord(recordType: "Note", recordID: CKRecord.ID(recordName: id.uuidString))
        record["title"] = title
        record["content"] = content
        record["color"] = color.rawValue
        record["positionX"] = position.x
        record["positionY"] = position.y
        record["width"] = size.width
        record["height"] = size.height
        record["createdAt"] = createdAt
        record["modifiedAt"] = modifiedAt
        record["isMarkdown"] = isMarkdown
        record["isLocked"] = isLocked
        record["tags"] = tags
        return record
    }

    static func fromCloudKitRecord(_ record: CKRecord) -> Note? {
        guard let idString = record.recordID.recordName,
              let id = UUID(uuidString: idString) else {
            return nil
        }

        return Note(
            id: id,
            title: record["title"] as? String ?? "",
            content: record["content"] as? String ?? "",
            color: NoteColor(rawValue: record["color"] as? String ?? "yellow") ?? .yellow,
            position: CGPoint(
                x: record["positionX"] as? Double ?? 0,
                y: record["positionY"] as? Double ?? 0
            ),
            size: CGSize(
                width: record["width"] as? Double ?? 300,
                height: record["height"] as? Double ?? 200
            ),
            createdAt: record["createdAt"] as? Date ?? Date(),
            modifiedAt: record["modifiedAt"] as? Date ?? Date(),
            isMarkdown: record["isMarkdown"] as? Bool ?? false,
            isLocked: record["isLocked"] as? Bool ?? false,
            tags: record["tags"] as? [String] ?? []
        )
    }
}
```

### Conflict Resolution

```swift
enum SyncConflictResolution {
    case localWins
    case remoteWins
    case manualMerge
    case lastModifiedWins
}

class ConflictResolver {
    func resolveConflict(
        local: Note,
        remote: Note,
        strategy: SyncConflictResolution = .lastModifiedWins
    ) -> Note {
        switch strategy {
        case .localWins:
            return local
        case .remoteWins:
            return remote
        case .lastModifiedWins:
            return local.modifiedAt > remote.modifiedAt ? local : remote
        case .manualMerge:
            return mergeNotes(local, remote)
        }
    }

    private func mergeNotes(_ local: Note, _ remote: Note) -> Note {
        // Intelligent merging logic
        var merged = local

        // Keep the most recent modification
        if remote.modifiedAt > local.modifiedAt {
            merged.modifiedAt = remote.modifiedAt
        }

        // Merge content if both have been modified
        if local.content != remote.content {
            merged.content = mergeContent(local.content, remote.content)
        }

        // Combine tags
        merged.tags = Array(Set(local.tags + remote.tags))

        return merged
    }

    private func mergeContent(_ local: String, _ remote: String) -> String {
        // Simple merge strategy - could be enhanced with diff algorithms
        return """
        <<<<<<< LOCAL
        \(local)
        =======
        \(remote)
        >>>>>>> REMOTE
        """
    }
}
```

## 📤 Export Formats

### Supported Export Formats

```swift
enum ExportFormat {
    case text
    case markdown
    case rtf
    case html
    case pdf
    case json
}
```

### Export Data Structures

```swift
struct ExportMetadata {
    let format: ExportFormat
    let exportedAt: Date
    let version: String
    let noteCount: Int
}

struct ExportResult {
    let data: Data
    let metadata: ExportMetadata
    let filename: String
    let mimeType: String
}
```

### Format Implementations

```swift
class ExportService {
    func exportNote(_ note: Note, format: ExportFormat) throws -> ExportResult {
        switch format {
        case .text:
            return try exportAsText(note)
        case .markdown:
            return try exportAsMarkdown(note)
        case .rtf:
            return try exportAsRTF(note)
        case .html:
            return try exportAsHTML(note)
        case .pdf:
            return try exportAsPDF(note)
        case .json:
            return try exportAsJSON(note)
        }
    }

    private func exportAsText(_ note: Note) throws -> ExportResult {
        let content = """
        \(note.title)

        \(note.content)

        ---
        Created: \(note.createdAt.formatted())
        Modified: \(note.modifiedAt.formatted())
        Color: \(note.color.displayName)
        Tags: \(note.tags.joined(separator: ", "))
        """

        let data = content.data(using: .utf8)!
        return ExportResult(
            data: data,
            metadata: ExportMetadata(
                format: .text,
                exportedAt: Date(),
                version: "1.0",
                noteCount: 1
            ),
            filename: "\(note.title).txt",
            mimeType: "text/plain"
        )
    }

    private func exportAsMarkdown(_ note: Note) throws -> ExportResult {
        let content = """
        # \(note.title)

        \(note.content)

        ---
        *Created: \(note.createdAt.formatted())*  
        *Modified: \(note.modifiedAt.formatted())*  
        *Color: \(note.color.displayName)*  
        *Tags: \(note.tags.map { "`\($0)`" }.joined(separator: ", "))*
        """

        let data = content.data(using: .utf8)!
        return ExportResult(
            data: data,
            metadata: ExportMetadata(
                format: .markdown,
                exportedAt: Date(),
                version: "1.0",
                noteCount: 1
            ),
            filename: "\(note.title).md",
            mimeType: "text/markdown"
        )
    }
}
```

## 🔍 Data Validation

### Validation Rules

```swift
struct NoteValidator {
    enum ValidationError: LocalizedError {
        case emptyNote
        case titleTooLong(maxLength: Int)
        case contentTooLong(maxLength: Int)
        case invalidTags
        case invalidPosition
        case invalidSize

        var errorDescription: String? {
            switch self {
            case .emptyNote:
                return "Note must have either a title or content"
            case .titleTooLong(let maxLength):
                return "Title must be \(maxLength) characters or less"
            case .contentTooLong(let maxLength):
                return "Content must be \(maxLength) characters or less"
            case .invalidTags:
                return "Tags contain invalid characters"
            case .invalidPosition:
                return "Note position is invalid"
            case .invalidSize:
                return "Note size is invalid"
            }
        }
    }

    static let maxTitleLength = 100
    static let maxContentLength = 10000
    static let maxTagsPerNote = 10
    static let maxTagLength = 50

    func validate(_ note: Note) throws {
        // Check for empty note
        guard !note.title.isEmpty || !note.content.isEmpty else {
            throw ValidationError.emptyNote
        }

        // Validate title length
        guard note.title.count <= Self.maxTitleLength else {
            throw ValidationError.titleTooLong(maxLength: Self.maxTitleLength)
        }

        // Validate content length
        guard note.content.count <= Self.maxContentLength else {
            throw ValidationError.contentTooLong(maxLength: Self.maxContentLength)
        }

        // Validate tags
        guard note.tags.count <= Self.maxTagsPerNote else {
            throw ValidationError.invalidTags
        }

        for tag in note.tags {
            guard tag.count <= Self.maxTagLength else {
                throw ValidationError.invalidTags
            }
            guard tag.range(of: #"^[a-zA-Z0-9\-_]+$"#, options: .regularExpression) != nil else {
                throw ValidationError.invalidTags
            }
        }

        // Validate position
        guard note.position.x.isFinite && note.position.y.isFinite else {
            throw ValidationError.invalidPosition
        }

        // Validate size
        guard note.size.width >= 200 && note.size.height >= 150 else {
            throw ValidationError.invalidSize
        }
        guard note.size.width.isFinite && note.size.height.isFinite else {
            throw ValidationError.invalidSize
        }
    }
}
```

## 📊 Data Analytics

### Usage Statistics

```swift
struct NoteStatistics {
    let totalNotes: Int
    let notesByColor: [NoteColor: Int]
    let averageNoteSize: CGSize
    let totalContentLength: Int
    let oldestNote: Date?
    let newestNote: Date?
    let mostUsedTags: [(tag: String, count: Int)]

    static func calculate(from notes: [Note]) -> NoteStatistics {
        let totalNotes = notes.count

        let notesByColor = Dictionary(grouping: notes, by: \.color)
            .mapValues { $0.count }

        let averageSize = notes.reduce(CGSize.zero) { sum, note in
            CGSize(
                width: sum.width + note.size.width,
                height: sum.height + note.size.height
            )
        }
        let averageNoteSize = CGSize(
            width: averageSize.width / CGFloat(max(1, notes.count)),
            height: averageSize.height / CGFloat(max(1, notes.count))
        )

        let totalContentLength = notes.reduce(0) { $0 + $1.content.count }

        let dates = notes.map { $0.createdAt }.sorted()
        let oldestNote = dates.first
        let newestNote = dates.last

        let tagCounts = notes.flatMap { $0.tags }
            .reduce(into: [:]) { counts, tag in
                counts[tag, default: 0] += 1
            }
        let mostUsedTags = tagCounts.sorted { $0.value > $1.value }
            .prefix(10)
            .map { (tag: $0.key, count: $0.value) }

        return NoteStatistics(
            totalNotes: totalNotes,
            notesByColor: notesByColor,
            averageNoteSize: averageNoteSize,
            totalContentLength: totalContentLength,
            oldestNote: oldestNote,
            newestNote: newestNote,
            mostUsedTags: Array(mostUsedTags)
        )
    }
}
```

---

*This data model documentation covers the core data structures and persistence strategies used in StickyNotes. The model is designed to be extensible and maintainable while ensuring data integrity and performance.*