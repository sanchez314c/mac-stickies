//
//  NoteModelTests.swift
//  StickyNotesTests
//
//  Created by SuperClaude
//  Copyright © 2024 SuperClaude. All rights reserved.
//

import CoreData
@testable import StickyNotes
import XCTest

final class NoteModelTests: XCTestCase {
    var persistenceController: PersistenceController!
    var testContext: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        testContext = persistenceController.container.viewContext
    }

    override func tearDown() {
        persistenceController = nil
        testContext = nil
        super.tearDown()
    }

    // MARK: - Note Creation Tests

    func testNoteCreation() {
        // Given
        let title = "Test Note"
        let content = "Test content"
        let color = "#FF0000"

        // When
        let note = persistenceController.createNote(title: title, content: content, color: color)

        // Then
        XCTAssertNotNil(note.id)
        XCTAssertEqual(note.title, title)
        XCTAssertEqual(note.content, content)
        XCTAssertEqual(note.color, color)
        XCTAssertFalse(note.isPinned)
        XCTAssertNotNil(note.createdAt)
        XCTAssertNotNil(note.updatedAt)
        XCTAssertLessThanOrEqual(note.createdAt, note.updatedAt) // updatedAt should be >= createdAt
    }

    func testNoteDefaultValues() {
        // When
        let note = Note(context: testContext)

        // Then
        XCTAssertNotNil(note.id)
        XCTAssertEqual(note.title, "")
        XCTAssertEqual(note.content, "")
        XCTAssertEqual(note.color, "#FFE4B5")
        XCTAssertFalse(note.isPinned)
        XCTAssertNil(note.category)
        XCTAssertEqual(note.tagsArray, [])
        XCTAssertNotNil(note.createdAt)
        XCTAssertNotNil(note.updatedAt)
    }

    // MARK: - Validation Tests

    func testValidateTitle_ValidTitle() {
        // Given
        let note = Note(context: testContext)
        note.title = "Valid Title"

        // When & Then
        XCTAssertNoThrow(try note.validateTitle())
    }

    func testValidateTitle_EmptyTitle() {
        // Given
        let note = Note(context: testContext)
        note.title = ""

        // When & Then
        XCTAssertThrowsError(try note.validateTitle()) { error in
            XCTAssertEqual(error as? ValidationError, .emptyTitle)
        }
    }

    func testValidateTitle_WhitespaceOnlyTitle() {
        // Given
        let note = Note(context: testContext)
        note.title = "   \n\t  "

        // When & Then
        XCTAssertThrowsError(try note.validateTitle()) { error in
            XCTAssertEqual(error as? ValidationError, .emptyTitle)
        }
    }

    func testValidateTitle_TitleTooLong() {
        // Given
        let note = Note(context: testContext)
        note.title = String(repeating: "A", count: 201)

        // When & Then
        XCTAssertThrowsError(try note.validateTitle()) { error in
            XCTAssertEqual(error as? ValidationError, .titleTooLong)
        }
    }

    func testValidateContent_ValidContent() {
        // Given
        let note = Note(context: testContext)
        note.content = "Valid content"

        // When & Then
        XCTAssertNoThrow(try note.validateContent())
    }

    func testValidateContent_ContentTooLong() {
        // Given
        let note = Note(context: testContext)
        note.content = String(repeating: "A", count: 10001)

        // When & Then
        XCTAssertThrowsError(try note.validateContent()) { error in
            XCTAssertEqual(error as? ValidationError, .contentTooLong)
        }
    }

    // MARK: - Computed Properties Tests

    func testDisplayTitle_WithTitle() {
        // Given
        let note = Note(context: testContext)
        note.title = "My Note"

        // When & Then
        XCTAssertEqual(note.displayTitle, "My Note")
    }

    func testDisplayTitle_EmptyTitle() {
        // Given
        let note = Note(context: testContext)
        note.title = ""

        // When & Then
        XCTAssertEqual(note.displayTitle, "Untitled Note")
    }

    func testPreviewContent_ShortContent() {
        // Given
        let note = Note(context: testContext)
        note.content = "Short content"

        // When & Then
        XCTAssertEqual(note.previewContent, "Short content")
    }

    func testPreviewContent_LongContent() {
        // Given
        let note = Note(context: testContext)
        let longContent = String(repeating: "A", count: 200)
        note.content = longContent

        // When & Then
        XCTAssertEqual(note.previewContent.count, 153) // 150 + "..."
        XCTAssertTrue(note.previewContent.hasSuffix("..."))
    }

    func testTagsArray_Getter() {
        // Given
        let note = Note(context: testContext)
        note.tags = ["tag1", "tag2"]

        // When & Then
        XCTAssertEqual(note.tagsArray, ["tag1", "tag2"])
    }

    func testTagsArray_Getter_NilTags() {
        // Given
        let note = Note(context: testContext)
        note.tags = nil

        // When & Then
        XCTAssertEqual(note.tagsArray, [])
    }

    func testTagsArray_Setter() {
        // Given
        let note = Note(context: testContext)

        // When
        note.tagsArray = ["newTag1", "newTag2"]

        // Then
        XCTAssertEqual(note.tags, ["newTag1", "newTag2"])
    }

    // MARK: - Date Formatting Tests

    func testFormattedCreatedDate() {
        // Given
        let note = Note(context: testContext)
        let testDate = Date(timeIntervalSince1970: 1_609_459_200) // 2021-01-01 00:00:00 UTC
        note.createdAt = testDate

        // When
        let formatted = note.formattedCreatedDate

        // Then
        XCTAssertFalse(formatted.isEmpty)
        // Note: Exact format depends on locale, but should contain date/time info
    }

    func testFormattedUpdatedDate() {
        // Given
        let note = Note(context: testContext)
        let testDate = Date(timeIntervalSince1970: 1_609_459_200) // 2021-01-01 00:00:00 UTC
        note.updatedAt = testDate

        // When
        let formatted = note.formattedUpdatedDate

        // Then
        XCTAssertFalse(formatted.isEmpty)
    }

    // MARK: - Core Data Integration Tests

    func testNotePersistence() throws {
        // Given
        let note = persistenceController.createNote(title: "Persistent Note", content: "Content")
        try persistenceController.save()

        // When
        let fetchedNotes = try persistenceController.fetchNotes()

        // Then
        XCTAssertEqual(fetchedNotes.count, 1)
        XCTAssertEqual(fetchedNotes.first?.title, "Persistent Note")
        XCTAssertEqual(fetchedNotes.first?.content, "Content")
    }

    func testNoteUpdateTimestamp() throws {
        // Given
        let note = persistenceController.createNote()
        let initialUpdateTime = note.updatedAt
        try persistenceController.save()

        // Wait a bit to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.001)

        // When
        note.title = "Updated Title"
        try persistenceController.save()

        // Then
        XCTAssertGreaterThan(note.updatedAt, initialUpdateTime)
    }

    func testNoteDeletion() throws {
        // Given
        let note = persistenceController.createNote()
        try persistenceController.save()

        // Verify note exists
        var fetchedNotes = try persistenceController.fetchNotes()
        XCTAssertEqual(fetchedNotes.count, 1)

        // When
        try persistenceController.deleteNote(note)

        // Then
        fetchedNotes = try persistenceController.fetchNotes()
        XCTAssertEqual(fetchedNotes.count, 0)
    }
}
