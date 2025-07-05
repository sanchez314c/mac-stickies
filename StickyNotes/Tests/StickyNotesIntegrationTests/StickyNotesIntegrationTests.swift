//
//  StickyNotesIntegrationTests.swift
//  StickyNotes
//
//  Created on 2025-01-21.
//

import XCTest
@testable import StickyNotesCore

final class StickyNotesIntegrationTests: XCTestCase {

    // MARK: - Core Data Integration Tests

    func testCoreDataNoteCreationAndRetrieval() async throws {
        // Create in-memory persistence controller for testing
        let persistenceController = PersistenceController(inMemory: true)
        let repository = CoreDataNoteRepository(persistenceController: persistenceController)
        let service = NoteService(repository: repository)

        let title = "Integration Test Note"
        let content = "Test content for integration"
        let color = NoteColor.blue

        // When - Create note through service
        let note = try await service.createNote(title: title, content: content, color: color)

        // Then - Verify note was created and persisted
        XCTAssertEqual(note.title, title)
        XCTAssertEqual(note.content, content)
        XCTAssertEqual(note.color, color)

        // When - Retrieve all notes
        let allNotes = try await service.getAllNotes()

        // Then - Verify note exists in persistence
        XCTAssertEqual(allNotes.count, 1)
        let retrievedNote = allNotes.first!
        XCTAssertEqual(retrievedNote.id, note.id)
        XCTAssertEqual(retrievedNote.title, title)
        XCTAssertEqual(retrievedNote.content, content)
    }

    func testNoteUpdateOperations() async throws {
        // Create in-memory persistence controller for testing
        let persistenceController = PersistenceController(inMemory: true)
        let repository = CoreDataNoteRepository(persistenceController: persistenceController)
        let service = NoteService(repository: repository)

        let note = try await service.createNote(title: "Original", content: "Original content", color: .yellow)

        // When - Update note
        var updatedNote = note
        updatedNote.title = "Updated"
        updatedNote.content = "Updated content"
        updatedNote.color = .blue
        try await service.updateNote(updatedNote)

        // Then - Verify update was persisted
        let retrievedNote = try await service.getNote(withId: note.id)
        XCTAssertNotNil(retrievedNote)
        XCTAssertEqual(retrievedNote?.title, "Updated")
        XCTAssertEqual(retrievedNote?.content, "Updated content")
        XCTAssertEqual(retrievedNote?.color, .blue)
    }

    func testNoteSearchIntegration() async throws {
        // Create in-memory persistence controller for testing
        let persistenceController = PersistenceController(inMemory: true)
        let repository = CoreDataNoteRepository(persistenceController: persistenceController)
        let service = NoteService(repository: repository)

        _ = try await service.createNote(title: "Meeting Notes", content: "Discuss project timeline", color: .yellow)
        _ = try await service.createNote(title: "Shopping List", content: "Buy groceries", color: .blue)
        _ = try await service.createNote(title: "Book Ideas", content: "Novel concepts", color: .green)

        // When - Search for notes
        let searchResults = try await service.searchNotes(containing: "project")

        // Then - Verify search results
        XCTAssertEqual(searchResults.count, 1)
        XCTAssertEqual(searchResults.first?.title, "Meeting Notes")
    }
}