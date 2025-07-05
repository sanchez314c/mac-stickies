# Code Style Guide

Comprehensive coding standards and conventions for StickyNotes development.

## 📋 Table of Contents

- [Swift Language Guidelines](#swift-language-guidelines)
- [Naming Conventions](#naming-conventions)
- [Code Organization](#code-organization)
- [Documentation](#documentation)
- [Error Handling](#error-handling)
- [Testing](#testing)
- [Performance](#performance)

## 🏗️ Swift Language Guidelines

### Swift Version
- **Target**: Swift 5.9+
- **Minimum**: Swift 5.7
- **Features**: Use modern Swift concurrency, opaque types, and result builders

### Language Features

#### ✅ Use
```swift
// Modern syntax
let notes = await noteService.fetchNotes()
if let note = notes.first(where: { $0.id == targetId }) { }

// Opaque types
func createNoteView() -> some View { }

// Result builders
@ViewBuilder
func noteContent() -> some View { }

// Async/await
func saveNote() async throws { }

// Struct over class when possible
struct Note: Identifiable, Codable { }
```

#### ❌ Avoid
```swift
// Legacy syntax
notes.first { $0.id == targetId }

// Force unwrapping without guard
let note = notes.first!

// Old completion handlers
func fetchNotes(completion: @escaping (Result<[Note], Error>) -> Void)

// Implicitly unwrapped optionals
var viewModel: NoteViewModel!
```

## 📝 Naming Conventions

### Classes and Structs
```swift
// ✅ Good
class NoteViewModel { }
struct NoteRepository { }
enum ExportFormat { }

// ❌ Bad
class noteViewModel { }        // lowercase start
struct note_repo { }          // snake_case
enum export-format { }        // kebab-case
```

### Protocols
```swift
// ✅ Good
protocol NoteServiceProtocol { }
protocol Exportable { }

// ❌ Bad
protocol NoteService { }       // No "Protocol" suffix for interface protocols
protocol exportable { }       // lowercase start
```

### Properties and Variables
```swift
// ✅ Good
var notes: [Note] = []
let selectedNoteId: UUID?
private let persistenceController: PersistenceController

// ❌ Bad
var Notes: [Note] = []         // uppercase start
let selected_note_id: UUID?    // snake_case
var persistence: PersistenceController // abbreviated
```

### Methods and Functions
```swift
// ✅ Good
func createNote(title: String, content: String) -> Note
func exportNotes(to url: URL) async throws
private func setupBindings()

// ❌ Bad
func create_note(title: String, content: String) // snake_case
func exportNotesToURL(url: URL)                  // parameter in name
func setup()                                     // too generic
```

### Constants
```swift
// ✅ Good
let maximumNoteLength = 10000
let defaultNoteColor = NoteColor.yellow
static let cellReuseIdentifier = "NoteCell"

// ❌ Bad
let MAX_NOTE_LENGTH = 10000     // screaming snake_case
let defaultColor = .yellow      // unclear context
let reuseID = "NoteCell"        // abbreviated
```

### Enums
```swift
// ✅ Good
enum NoteColor: String, Codable {
    case yellow
    case blue
    case green
    case pink
    case purple
    case gray
}

// ❌ Bad
enum Color {                    // too generic
    case Yellow                 // capitalized
    case note_blue              // inconsistent
}
```

## 📁 Code Organization

### File Structure
```
Sources/StickyNotes/
├── Models/
│   ├── Note.swift
│   ├── NoteColor.swift
│   └── Note+Extensions.swift
├── ViewModels/
│   ├── NoteViewModel.swift
│   └── NotesViewModel.swift
├── Views/
│   ├── NoteView.swift
│   ├── NoteListView.swift
│   └── Components/
│       ├── NoteToolbar.swift
│       └── ColorPicker.swift
├── Services/
│   ├── NoteService.swift
│   ├── ExportService.swift
│   └── Persistence/
│       ├── PersistenceController.swift
│       └── NoteRepository.swift
└── Utilities/
    ├── Constants.swift
    ├── Extensions/
    │   ├── View+Extensions.swift
    │   └── String+Extensions.swift
    └── Helpers/
        ├── DateFormatter+Helpers.swift
        └── FileManager+Helpers.swift
```

### Import Organization
```swift
// ✅ Good - Grouped and ordered
import SwiftUI
import Combine
import CoreData

// Third-party frameworks
import Alamofire
import Kingfisher

// Local modules
import StickyNotesCore
import StickyNotesUI

// Standard library (if needed)
import Foundation
import UIKit

// ❌ Bad - Ungrouped
import Combine
import StickyNotesCore
import SwiftUI
import Alamofire
import CoreData
import Kingfisher
```

### Type Organization in Files
```swift
// 1. Imports
import Foundation

// 2. Global constants and typealiases
typealias NoteID = UUID
let maximumNoteLength = 10000

// 3. Main type definition
struct Note: Identifiable, Codable {
    // MARK: - Properties
    let id: UUID
    var title: String
    var content: String

    // MARK: - Initialization
    init(id: UUID = UUID(), title: String = "", content: String = "") {
        // ...
    }

    // MARK: - Methods
    func validate() throws -> Bool {
        // ...
    }
}

// 4. Extensions
extension Note {
    // Additional methods
}

// 5. Private implementations
private extension Note {
    // Private helpers
}
```

## 📖 Documentation

### Documentation Comments
```swift
// ✅ Good
/// Creates a new sticky note with the specified content.
///
/// This method validates the input parameters and creates a note
/// with default positioning and sizing.
///
/// - Parameters:
///   - title: The title of the note (optional)
///   - content: The content text of the note
///   - color: The color theme for the note
/// - Returns: A new `Note` instance
/// - Throws: `ValidationError` if parameters are invalid
/// - Note: The note will be positioned at the default location
/// - SeeAlso: `NoteViewModel.updateNote(_:)`
/// - Important: This method performs validation synchronously
func createNote(
    title: String = "",
    content: String,
    color: NoteColor = .yellow
) throws -> Note

// ❌ Bad
/// Creates a note
/// - Parameter title: title
/// - Parameter content: content
func createNote(title: String, content: String) -> Note
```

### Inline Comments
```swift
// ✅ Good - Explain why, not what
func validateNote(_ note: Note) throws {
    // Ensure title length is reasonable for UI display
    guard note.title.count <= 100 else {
        throw ValidationError.titleTooLong
    }

    // Prevent empty notes that serve no purpose
    guard !note.title.isEmpty || !note.content.isEmpty else {
        throw ValidationError.emptyNote
    }
}

// ❌ Bad - Comments that state the obvious
func validateNote(_ note: Note) throws {
    // Check if title is longer than 100 characters
    if note.title.count > 100 {
        throw ValidationError.titleTooLong
    }

    // Check if both title and content are empty
    if note.title.isEmpty && note.content.isEmpty {
        throw ValidationError.emptyNote
    }
}
```

### MARK Comments
```swift
class NoteService {
    // MARK: - Properties
    private let repository: NoteRepository
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(repository: NoteRepository = CoreDataNoteRepository()) {
        self.repository = repository
        setupBindings()
    }

    // MARK: - Public Methods
    func createNote(title: String, content: String) async throws -> Note {
        // ...
    }

    // MARK: - Private Methods
    private func setupBindings() {
        // ...
    }

    // MARK: - Combine Subscriptions
    private func bindToRepository() {
        // ...
    }
}
```

## 🚨 Error Handling

### Error Types
```swift
// ✅ Good - Specific, actionable errors
enum NoteError: LocalizedError {
    case invalidTitle(reason: String)
    case contentTooLong(maxLength: Int)
    case saveFailed(Error)
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidTitle(let reason):
            return "Invalid title: \(reason)"
        case .contentTooLong(let maxLength):
            return "Content exceeds maximum length of \(maxLength) characters"
        case .saveFailed(let error):
            return "Failed to save note: \(error.localizedDescription)"
        case .networkUnavailable:
            return "Network connection is required for this operation"
        }
    }
}

// ❌ Bad - Generic errors
enum NoteError: Error {
    case invalidInput     // Too vague
    case saveError        // No context
}
```

### Error Handling Patterns
```swift
// ✅ Good - Specific error handling
func saveNote(_ note: Note) async throws {
    do {
        try note.validate()
        try await repository.save(note)
        analytics.track(.noteSaved)
    } catch let error as ValidationError {
        logger.error("Validation failed: \(error)")
        throw NoteError.validationFailed(error)
    } catch let error as PersistenceError {
        logger.error("Persistence failed: \(error)")
        analytics.track(.saveFailed)
        throw NoteError.saveFailed(error)
    } catch {
        logger.error("Unexpected error: \(error)")
        throw NoteError.unexpectedError(error)
    }
}

// ❌ Bad - Generic catch-all
func saveNote(_ note: Note) async throws {
    try await repository.save(note)
} catch {
    throw NSError(domain: "NoteError", code: -1, userInfo: nil)
}
```

### Result Types
```swift
// ✅ Good - Clear success/failure states
func exportNote(_ note: Note) async -> Result<URL, ExportError> {
    do {
        let url = try await exportService.export(note)
        return .success(url)
    } catch let error as ExportError {
        return .failure(error)
    } catch {
        return .failure(.unexpectedError(error))
    }
}

// ❌ Bad - Throwing without context
func exportNote(_ note: Note) async throws -> URL {
    try await exportService.export(note)
}
```

## 🧪 Testing

### Test File Organization
```swift
// Tests/StickyNotesTests/
// ├── Models/
// │   ├── NoteTests.swift
// │   └── NoteColorTests.swift
// ├── Services/
// │   ├── NoteServiceTests.swift
// │   └── ExportServiceTests.swift
// ├── ViewModels/
// │   ├── NoteViewModelTests.swift
// │   └── NotesViewModelTests.swift
// └── Integration/
//     └── PersistenceIntegrationTests.swift
```

### Test Structure
```swift
// ✅ Good - Clear test structure
class NoteServiceTests: XCTestCase {
    // MARK: - Properties
    private var sut: NoteService!
    private var mockRepository: MockNoteRepository!
    private var mockValidator: MockNoteValidator!

    // MARK: - Setup/Teardown
    override func setUp() {
        super.setUp()
        mockRepository = MockNoteRepository()
        mockValidator = MockNoteValidator()
        sut = NoteService(
            repository: mockRepository,
            validator: mockValidator
        )
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        mockValidator = nil
        super.tearDown()
    }

    // MARK: - Tests
    func testCreateNote_Success() async throws {
        // Given
        let title = "Test Note"
        let content = "Test content"
        let color = NoteColor.yellow

        // When
        let note = try await sut.createNote(
            title: title,
            content: content,
            color: color
        )

        // Then
        XCTAssertEqual(note.title, title)
        XCTAssertEqual(note.content, content)
        XCTAssertEqual(note.color, color)
        XCTAssertFalse(note.id.uuidString.isEmpty)
    }

    func testCreateNote_ValidationFails() async throws {
        // Given
        mockValidator.shouldFailValidation = true
        let expectedError = ValidationError.emptyNote

        // When/Then
        await XCTAssertThrowsError(
            try await sut.createNote(title: "", content: "", color: .yellow)
        ) { error in
            XCTAssertEqual(error as? ServiceError, .validationFailed(expectedError))
        }
    }
}
```

### Test Naming
```swift
// ✅ Good - Behavior-driven naming
func testCreateNote_WithValidInput_CreatesNoteSuccessfully()
func testCreateNote_WithEmptyTitle_ThrowsValidationError()
func testExportNote_AsPDF_GeneratesValidFile()

// ❌ Bad - Unclear naming
func testCreateNote()
func testExport()
func testError()
```

## ⚡ Performance

### Efficient Code Patterns
```swift
// ✅ Good - Lazy initialization
class NoteCache {
    lazy var expensiveResource: ExpensiveObject = {
        // Heavy computation here
        return ExpensiveObject()
    }()
}

// ✅ Good - Value types for small data
struct NoteFilter {
    let colors: [NoteColor]
    let dateRange: ClosedRange<Date>?
    let searchText: String?
}

// ✅ Good - Copy-on-write optimization
struct NotesCollection {
    private var notes: [Note]

    mutating func addNote(_ note: Note) {
        if !isKnownUniquelyReferenced(&notes) {
            notes = notes + [note]  // Creates new array
        } else {
            notes.append(note)      // Modifies in place
        }
    }
}
```

### Performance Anti-patterns
```swift
// ❌ Bad - Force casting
let note = notes.first as! Note

// ❌ Bad - String concatenation in loop
var result = ""
for note in notes {
    result += note.title + ", "  // Creates new string each iteration
}

// ❌ Bad - Unnecessary optionals
func processNotes(_ notes: [Note]?) {
    guard let notes = notes else { return }
    // Process notes
}
```

## 🔧 Code Formatting

### SwiftFormat Configuration
```yaml
# .swiftformat
--indent 4
--maxwidth 120
--wraparguments before-first
--wrapparameters before-first
--closingparen same-line
--commas inline
--semicolons inline
--indentstrings true
--trimwhitespace always
--header "\n//  StickyNotes\n//  Created by {author} on {date}.\n//  Copyright © {year} SuperClaude. All rights reserved.\n"
```

### SwiftLint Rules
```yaml
# .swiftlint.yml
disabled_rules:
  - trailing_whitespace
  - vertical_whitespace

opt_in_rules:
  - empty_count
  - force_unwrapping
  - implicit_getter
  - missing_docs
  - redundant_nil_coalescing

included:
  - Sources
  - Tests

excluded:
  - Carthage
  - Pods
  - build

line_length: 120
file_length: 500
type_name:
  min_length: 3
  max_length: 40

function_body_length:
  warning: 50
  error: 100
```

## 🚀 Best Practices

### Code Reviews
- **Mandatory** for all changes
- **Automated checks** via CI/CD
- **Minimum 1 approval** required
- **Self-review** before submitting

### Git Workflow
```bash
# ✅ Good - Clear commit messages
git commit -m "feat: Add note color picker component

- Add ColorPicker SwiftUI view
- Integrate with NoteViewModel
- Add unit tests for color selection
- Update accessibility labels

Closes #123"

# ❌ Bad - Unclear messages
git commit -m "fix bug"
git commit -m "update code"
```

### Version Control
- **Feature branches** for new work
- **Squash merges** for clean history
- **Protected main branch** with required checks
- **Semantic versioning** for releases

## 📊 Metrics

### Code Quality Targets
- **Cyclomatic Complexity**: < 10 per function
- **Code Coverage**: > 90% for critical paths
- **Technical Debt**: < 5% of codebase
- **Duplication**: < 3% of codebase

### Performance Benchmarks
- **Startup Time**: < 2 seconds
- **Memory Usage**: < 100MB with 1000 notes
- **Search Performance**: < 100ms for 1000 notes
- **UI Responsiveness**: 60 FPS minimum

## 🔄 Continuous Improvement

### Regular Reviews
- **Monthly**: Code style guide review
- **Quarterly**: Architecture and patterns assessment
- **Annually**: Complete codebase modernization

### Tool Updates
- **SwiftFormat**: Update to latest version quarterly
- **SwiftLint**: Update rules based on Swift evolution
- **Xcode**: Adopt new features and deprecations

This style guide ensures consistent, maintainable, and high-quality code across the StickyNotes codebase. All team members should familiarize themselves with these guidelines and apply them consistently.