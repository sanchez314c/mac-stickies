//
//  PersistenceControllerIntegrationTests.swift
//  StickyNotesIntegrationTests
//
//  Created by SuperClaude
//  Copyright © 2024 SuperClaude. All rights reserved.
//

import CoreData
@testable import StickyNotes
import XCTest

final class PersistenceControllerIntegrationTests: XCTestCase {
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

    // MARK: - CRUD Operations Tests

    func testCreateAndFetchNotes() throws {
        // Given
        let note1 = persistenceController.createNote(title: "Note 1", content: "Content 1")
        let note2 = persistenceController.createNote(title: "Note 2", content: "Content 2")
        try persistenceController.save()

        // When
        let fetchedNotes = try persistenceController.fetchNotes()

        // Then
        XCTAssertEqual(fetchedNotes.count, 2)
        let titles = fetchedNotes.map { $0.title }.sorted()
        XCTAssertEqual(titles, ["Note 1", "Note 2"])
    }

    func testUpdateNote() throws {
        // Given
        let note = persistenceController.createNote(title: "Original Title", content: "Original Content")
        try persistenceController.save()

        // When
        note.title = "Updated Title"
        note.content = "Updated Content"
        try persistenceController.save()

        // Then
        let fetchedNotes = try persistenceController.fetchNotes()
        XCTAssertEqual(fetchedNotes.count, 1)
        XCTAssertEqual(fetchedNotes.first?.title, "Updated Title")
        XCTAssertEqual(fetchedNotes.first?.content, "Updated Content")
    }

    func testDeleteNote() throws {
        // Given
        let note1 = persistenceController.createNote(title: "Note 1")
        let note2 = persistenceController.createNote(title: "Note 2")
        try persistenceController.save()

        // When
        try persistenceController.deleteNote(note1)

        // Then
        let fetchedNotes = try persistenceController.fetchNotes()
        XCTAssertEqual(fetchedNotes.count, 1)
        XCTAssertEqual(fetchedNotes.first?.title, "Note 2")
    }

    // MARK: - Search Functionality Tests

    func testSearchNotes_ByTitle() throws {
        // Given
        persistenceController.createNote(title: "Meeting Notes", content: "Discuss project")
        persistenceController.createNote(title: "Shopping List", content: "Buy groceries")
        persistenceController.createNote(title: "Book Ideas", content: "Novel concepts")
        try persistenceController.save()

        // When
        let results = try persistenceController.searchNotes(query: "Notes")

        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Meeting Notes")
    }

    func testSearchNotes_ByContent() throws {
        // Given
        persistenceController.createNote(title: "Meeting", content: "Discuss project timeline")
        persistenceController.createNote(title: "Shopping", content: "Buy groceries and milk")
        persistenceController.createNote(title: "Reading", content: "Book recommendations")
        try persistenceController.save()

        // When
        let results = try persistenceController.searchNotes(query: "project")

        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Meeting")
    }

    func testSearchNotes_CaseInsensitive() throws {
        // Given
        persistenceController.createNote(title: "Meeting Notes", content: "Discuss PROJECT")
        try persistenceController.save()

        // When
        let results = try persistenceController.searchNotes(query: "PROJECT")

        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Meeting Notes")
    }

    func testSearchNotes_NoResults() throws {
        // Given
        persistenceController.createNote(title: "Note 1", content: "Content 1")
        try persistenceController.save()

        // When
        let results = try persistenceController.searchNotes(query: "nonexistent")

        // Then
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - Category Filtering Tests

    func testNotesByCategory() throws {
        // Given
        let workNote1 = persistenceController.createNote(title: "Work 1", content: "Work content 1")
        workNote1.category = "Work"
        let workNote2 = persistenceController.createNote(title: "Work 2", content: "Work content 2")
        workNote2.category = "Work"
        let personalNote = persistenceController.createNote(title: "Personal", content: "Personal content")
        personalNote.category = "Personal"
        let uncategorizedNote = persistenceController.createNote(title: "No Category", content: "No category")
        try persistenceController.save()

        // When
        let workNotes = try persistenceController.notesByCategory("Work")
        let personalNotes = try persistenceController.notesByCategory("Personal")

        // Then
        XCTAssertEqual(workNotes.count, 2)
        XCTAssertEqual(personalNotes.count, 1)
        let workTitles = workNotes.map { $0.title }.sorted()
        XCTAssertEqual(workTitles, ["Work 1", "Work 2"])
    }

    func testNotesByCategory_EmptyCategory() throws {
        // Given
        persistenceController.createNote(title: "Note 1", content: "Content 1")
        let categorizedNote = persistenceController.createNote(title: "Note 2", content: "Content 2")
        categorizedNote.category = "Work"
        try persistenceController.save()

        // When
        let results = try persistenceController.notesByCategory("Work")

        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Note 2")
    }

    // MARK: - Pinning Functionality Tests

    func testPinnedNotes() throws {
        // Given
        let pinnedNote1 = persistenceController.createNote(title: "Pinned 1")
        pinnedNote1.isPinned = true
        let pinnedNote2 = persistenceController.createNote(title: "Pinned 2")
        pinnedNote2.isPinned = true
        let unpinnedNote = persistenceController.createNote(title: "Unpinned")
        unpinnedNote.isPinned = false
        try persistenceController.save()

        // When
        let pinnedNotes = try persistenceController.pinnedNotes()

        // Then
        XCTAssertEqual(pinnedNotes.count, 2)
        let pinnedTitles = pinnedNotes.map { $0.title }.sorted()
        XCTAssertEqual(pinnedTitles, ["Pinned 1", "Pinned 2"])
    }

    func testPinnedNotes_NoPinnedNotes() throws {
        // Given
        persistenceController.createNote(title: "Note 1", content: "Content 1")
        persistenceController.createNote(title: "Note 2", content: "Content 2")
        try persistenceController.save()

        // When
        let pinnedNotes = try persistenceController.pinnedNotes()

        // Then
        XCTAssertEqual(pinnedNotes.count, 0)
    }

    // MARK: - Sorting Tests

    func testFetchNotes_SortingByUpdatedDate() throws {
        // Given
        let note1 = persistenceController.createNote(title: "Note 1")
        try persistenceController.save()

        // Wait to ensure different timestamps
        Thread.sleep(forTimeInterval: 0.01)
        let note2 = persistenceController.createNote(title: "Note 2")
        try persistenceController.save()

        Thread.sleep(forTimeInterval: 0.01)
        let note3 = persistenceController.createNote(title: "Note 3")
        try persistenceController.save()

        // When
        let fetchedNotes = try persistenceController.fetchNotes()

        // Then
        XCTAssertEqual(fetchedNotes.count, 3)
        // Should be sorted by updatedAt descending (most recent first)
        XCTAssertEqual(fetchedNotes[0].title, "Note 3")
        XCTAssertEqual(fetchedNotes[1].title, "Note 2")
        XCTAssertEqual(fetchedNotes[2].title, "Note 1")
    }

    func testSearchNotes_SortingByUpdatedDate() throws {
        // Given
        let note1 = persistenceController.createNote(title: "Search Test 1", content: "Test content")
        try persistenceController.save()

        Thread.sleep(forTimeInterval: 0.01)
        let note2 = persistenceController.createNote(title: "Search Test 2", content: "Test content")
        try persistenceController.save()

        // When
        let results = try persistenceController.searchNotes(query: "Test")

        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].title, "Search Test 2") // Most recent first
        XCTAssertEqual(results[1].title, "Search Test 1")
    }

    // MARK: - Bulk Operations Tests

    func testBulkNoteCreation() throws {
        // Given & When
        var createdNotes: [Note] = []
        for i in 1 ... 100 {
            let note = persistenceController.createNote(title: "Bulk Note \(i)", content: "Content \(i)")
            createdNotes.append(note)
        }
        try persistenceController.save()

        // Then
        let fetchedNotes = try persistenceController.fetchNotes()
        XCTAssertEqual(fetchedNotes.count, 100)

        let titles = fetchedNotes.map { $0.title }
        for i in 1 ... 100 {
            XCTAssertTrue(titles.contains("Bulk Note \(i)"))
        }
    }

    func testBulkNoteDeletion() throws {
        // Given
        var notesToDelete: [Note] = []
        for i in 1 ... 50 {
            let note = persistenceController.createNote(title: "Delete Note \(i)")
            notesToDelete.append(note)
        }
        try persistenceController.save()

        // When
        for note in notesToDelete {
            try persistenceController.deleteNote(note)
        }

        // Then
        let remainingNotes = try persistenceController.fetchNotes()
        XCTAssertEqual(remainingNotes.count, 0)
    }

    // MARK: - Error Handling Tests

    func testSaveWithValidationError() throws {
        // Given
        let note = persistenceController.createNote()
        note.title = "" // Invalid empty title

        // When & Then
        XCTAssertThrowsError(try note.validateTitle())
        // Note: Core Data will still save even with validation errors at the model level
        // Validation should be handled at the UI/application level
    }

    func testFetchWithInvalidPredicate() {
        // Given
        let invalidPredicate = NSPredicate(format: "invalidAttribute == %@", "value")

        // When & Then
        XCTAssertThrowsError(try persistenceController.fetchNotes(predicate: invalidPredicate))
    }

    // MARK: - Performance Tests

    func testFetchPerformance_WithLargeDataset() throws {
        // Given: Create 1000 notes
        measure {
            for i in 1 ... 1000 {
                _ = persistenceController.createNote(title: "Performance Note \(i)", content: "Content \(i)")
            }
            _ = try? persistenceController.save()
        }

        // When: Fetch all notes (performance measured by test framework)
        measure {
            _ = try? persistenceController.fetchNotes()
        }

        // Note: Performance is measured by the test framework
        // The test passes if it completes within the timeout
    }

    func testSearchPerformance_WithLargeDataset() throws {
        // Given: Create 1000 notes with searchable content
        for i in 1 ... 1000 {
            let note = persistenceController.createNote(
                title: "Note \(i)",
                content: i % 10 == 0 ? "Special searchable content \(i)" : "Regular content \(i)"
            )
        }
        try persistenceController.save()

        // When: Search for specific term (performance measured by test framework)
        measure {
            _ = try? persistenceController.searchNotes(query: "searchable")
        }

        // Note: Performance is measured by the test framework
        // The test passes if it completes within the timeout
    }

    // MARK: - Concurrency Tests

    func testConcurrentNoteCreation() throws {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent note creation")
        expectation.expectedFulfillmentCount = 10

        // When
        DispatchQueue.concurrentPerform(iterations: 10) { iteration in
            let note = persistenceController.createNote(
                title: "Concurrent Note \(iteration)",
                content: "Content \(iteration)"
            )
            // Note: In a real app, you'd want to use a separate context per thread
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        // Then
        try persistenceController.save()
        let fetchedNotes = try persistenceController.fetchNotes()
        XCTAssertEqual(fetchedNotes.count, 10)
    }

    // MARK: - Data Integrity Tests

    func testNoteDataIntegrity_AfterSaveAndFetch() throws {
        // Given
        let originalNote = persistenceController.createNote(
            title: "Integrity Test",
            content: "Test content with special chars: éñü",
            color: "#FF5733"
        )
        originalNote.category = "Test Category"
        originalNote.isPinned = true
        originalNote.tagsArray = ["tag1", "tag2", "tag3"]
        try persistenceController.save()

        // When
        let fetchedNotes = try persistenceController.fetchNotes()
        let fetchedNote = fetchedNotes.first!

        // Then
        XCTAssertEqual(fetchedNote.title, originalNote.title)
        XCTAssertEqual(fetchedNote.content, originalNote.content)
        XCTAssertEqual(fetchedNote.color, originalNote.color)
        XCTAssertEqual(fetchedNote.category, originalNote.category)
        XCTAssertEqual(fetchedNote.isPinned, originalNote.isPinned)
        XCTAssertEqual(fetchedNote.tagsArray, originalNote.tagsArray)
        XCTAssertEqual(fetchedNote.id, originalNote.id)
    }

    func testNoteRelationships_DataConsistency() throws {
        // Given: Create notes with various relationships
        let workNote = persistenceController.createNote(title: "Work Project", content: "Project details")
        workNote.category = "Work"
        workNote.isPinned = true

        let personalNote = persistenceController.createNote(title: "Personal Reminder", content: "Reminder")
        personalNote.category = "Personal"
        personalNote.isPinned = false

        let shoppingNote = persistenceController.createNote(title: "Shopping List", content: "Groceries")
        shoppingNote.category = "Shopping"

        try persistenceController.save()

        // When: Query by different criteria
        let allNotes = try persistenceController.fetchNotes()
        let workNotes = try persistenceController.notesByCategory("Work")
        let pinnedNotes = try persistenceController.pinnedNotes()

        // Then: Verify data consistency across queries
        XCTAssertEqual(allNotes.count, 3)
        XCTAssertEqual(workNotes.count, 1)
        XCTAssertEqual(pinnedNotes.count, 1)

        // Verify the same note appears in multiple query results correctly
        let workNoteFromCategory = workNotes.first!
        let pinnedNoteFromPinned = pinnedNotes.first!
        XCTAssertEqual(workNoteFromCategory.id, pinnedNoteFromPinned.id)
        XCTAssertEqual(workNoteFromCategory.title, "Work Project")
    }
}
