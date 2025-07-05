//
//  StickyNotesCoreTests.swift
//  StickyNotes
//
//  Created on 2025-01-21.
//

@testable import StickyNotesCore
import XCTest

final class StickyNotesCoreTests: XCTestCase {
    var persistenceController: PersistenceController!
    var repository: CoreDataNoteRepository!
    var noteService: NoteService!

    override func setUp() {
        super.setUp()

        // Create in-memory persistence controller for testing
        persistenceController = PersistenceController(inMemory: true)
        repository = CoreDataNoteRepository(persistenceController: persistenceController)
        noteService = NoteService(repository: repository)
    }

    override func tearDown() {
        persistenceController = nil
        repository = nil
        noteService = nil
        super.tearDown()
    }

    // MARK: - Repository Tests

    func testCreateAndFetchNote() async throws {
        // Given
        let note = Note(
            title: "Test Note",
            content: "Test content",
            color: .blue,
            position: CGPoint(x: 100, y: 100),
            size: CGSize(width: 200, height: 150)
        )

        // When
        try await repository.saveNote(note)
        let fetchedNote = try await repository.fetchNote(withId: note.id)

        // Then
        XCTAssertNotNil(fetchedNote)
        XCTAssertEqual(fetchedNote?.id, note.id)
        XCTAssertEqual(fetchedNote?.title, note.title)
        XCTAssertEqual(fetchedNote?.content, note.content)
        XCTAssertEqual(fetchedNote?.color, note.color)
    }

    func testFetchAllNotes() async throws {
        // Given
        let note1 = Note(title: "Note 1", content: "Content 1", color: .yellow)
        let note2 = Note(title: "Note 2", content: "Content 2", color: .green)

        try await repository.saveNote(note1)
        try await repository.saveNote(note2)

        // When
        let notes = try await repository.fetchNotes()

        // Then
        XCTAssertEqual(notes.count, 2)
        XCTAssertTrue(notes.contains { $0.id == note1.id })
        XCTAssertTrue(notes.contains { $0.id == note2.id })
    }

    func testSearchNotes() async throws {
        // Given
        let note1 = Note(title: "Meeting Notes", content: "Discuss project timeline", color: .yellow)
        let note2 = Note(title: "Shopping List", content: "Buy groceries", color: .blue)

        try await repository.saveNote(note1)
        try await repository.saveNote(note2)

        // When
        let searchResults = try await repository.searchNotes(containing: "project")

        // Then
        XCTAssertEqual(searchResults.count, 1)
        XCTAssertEqual(searchResults.first?.id, note1.id)
    }

    func testDeleteNote() async throws {
        // Given
        let note = Note(title: "Test Note", content: "Test content", color: .yellow)
        try await repository.saveNote(note)

        // Verify note exists
        var fetchedNote = try await repository.fetchNote(withId: note.id)
        XCTAssertNotNil(fetchedNote)

        // When
        try await repository.deleteNote(withId: note.id)

        // Then
        fetchedNote = try await repository.fetchNote(withId: note.id)
        XCTAssertNil(fetchedNote)
    }

    // MARK: - Service Tests

    func testServiceCreateNote() async throws {
        // When
        let note = try await noteService.createNote(
            title: "Service Test",
            content: "Testing service layer",
            color: .green
        )

        // Then
        XCTAssertEqual(note.title, "Service Test")
        XCTAssertEqual(note.content, "Testing service layer")
        XCTAssertEqual(note.color, .green)
        XCTAssertFalse(note.id.uuidString.isEmpty)
    }

    func testServiceUpdateNote() async throws {
        // Given
        var note = try await noteService.createNote(
            title: "Original Title",
            content: "Original content",
            color: .yellow
        )

        // When
        note.title = "Updated Title"
        note.content = "Updated content"
        try await noteService.updateNote(note)

        // Then
        let updatedNote = try await noteService.getNote(withId: note.id)
        XCTAssertEqual(updatedNote?.title, "Updated Title")
        XCTAssertEqual(updatedNote?.content, "Updated content")
    }

    func testServiceDuplicateNote() async throws {
        // Given
        let originalNote = try await noteService.createNote(
            title: "Original",
            content: "Original content",
            color: .blue
        )

        // When
        let duplicatedNote = try await noteService.duplicateNote(originalNote)

        // Then
        XCTAssertEqual(duplicatedNote.title, "Original Copy")
        XCTAssertEqual(duplicatedNote.content, originalNote.content)
        XCTAssertEqual(duplicatedNote.color, originalNote.color)
        XCTAssertNotEqual(duplicatedNote.id, originalNote.id)
    }

    func testServiceStatistics() async throws {
        // Given
        _ = try await noteService.createNote(title: "Note 1", content: "Content", color: .yellow)
        _ = try await noteService.createNote(title: "Note 2", content: "Content", color: .yellow)
        _ = try await noteService.createNote(title: "Note 3", content: "Content", color: .blue)

        // When
        let statistics = try await noteService.getNotesStatistics()

        // Then
        XCTAssertEqual(statistics.totalNotes, 3)
        XCTAssertEqual(statistics.colorDistribution[.yellow], 2)
        XCTAssertEqual(statistics.colorDistribution[.blue], 1)
    }

    // MARK: - Background Operations Tests

    func testBackgroundImportExport() async throws {
        // Given
        let notes = [
            Note(title: "Note 1", content: "Content 1", color: .yellow),
            Note(title: "Note 2", content: "Content 2", color: .blue),
        ]

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(notes)

        // When - Import
        let importOperationId = BackgroundOperationManager.shared.importNotes(from: jsonData)

        // Wait for completion (in real tests, you'd use expectations)
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Then - Verify import
        let allNotes = try await noteService.getAllNotes()
        XCTAssertEqual(allNotes.count, 2)

        // When - Export
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_export.json")
        let exportOperationId = BackgroundOperationManager.shared.exportNotes(to: tempURL)

        // Wait for completion
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Then - Verify export file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path))

        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }
}

// MARK: - Test Extensions
