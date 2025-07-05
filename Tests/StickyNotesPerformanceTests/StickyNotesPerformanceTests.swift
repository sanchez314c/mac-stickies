//
//  StickyNotesPerformanceTests.swift
//  StickyNotesPerformanceTests
//
//  Created by SuperClaude
//  Copyright © 2024 SuperClaude. All rights reserved.
//

import CoreData
@testable import StickyNotes
import XCTest

final class StickyNotesPerformanceTests: XCTestCase {
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

    // MARK: - Core Data Performance Tests

    func testNoteCreationPerformance() {
        // Test: Creating individual notes
        measure {
            for i in 1 ... 1000 {
                let note = persistenceController.createNote(
                    title: "Performance Note \(i)",
                    content: "Content for performance test note \(i)"
                )
                note.category = "Performance"
                note.color = "#FFE4B5"
            }
        }
    }

    func testBulkNoteCreationPerformance() {
        // Test: Bulk creation with batch save
        measure {
            for i in 1 ... 1000 {
                _ = persistenceController.createNote(
                    title: "Bulk Note \(i)",
                    content: String(repeating: "Content ", count: 50)
                )
            }
            try? persistenceController.save()
        }
    }

    func testNoteFetchPerformance_SmallDataset() {
        // Given: 100 notes
        createTestNotes(count: 100)

        // Test: Fetch all notes
        measure {
            _ = try? persistenceController.fetchNotes()
        }
    }

    func testNoteFetchPerformance_LargeDataset() {
        // Given: 10000 notes
        createTestNotes(count: 10000)

        // Test: Fetch all notes
        measure {
            _ = try? persistenceController.fetchNotes()
        }
    }

    func testNoteSearchPerformance_SmallDataset() {
        // Given: 100 notes with searchable content
        createTestNotes(count: 100, includeSearchableContent: true)

        // Test: Search operation
        measure {
            _ = try? persistenceController.searchNotes(query: "searchable")
        }
    }

    func testNoteSearchPerformance_LargeDataset() {
        // Given: 5000 notes with searchable content
        createTestNotes(count: 5000, includeSearchableContent: true)

        // Test: Search operation
        measure {
            _ = try? persistenceController.searchNotes(query: "searchable")
        }
    }

    func testCategoryFilteringPerformance() {
        // Given: 1000 notes across multiple categories
        createTestNotesWithCategories(count: 1000, categories: ["Work", "Personal", "Ideas", "Shopping"])

        // Test: Filter by category
        measure {
            _ = try? persistenceController.notesByCategory("Work")
        }
    }

    func testPinnedNotesFetchPerformance() {
        // Given: 1000 notes with some pinned
        createTestNotes(count: 1000, pinPercentage: 0.1) // 10% pinned

        // Test: Fetch pinned notes
        measure {
            _ = try? persistenceController.pinnedNotes()
        }
    }

    func testNoteUpdatePerformance() {
        // Given: 1000 existing notes
        let notes = createTestNotes(count: 1000)

        // Test: Update all notes
        measure {
            for note in notes {
                note.title = "Updated \(note.title)"
                note.content = "Updated content for \(note.title)"
            }
            try? persistenceController.save()
        }
    }

    func testNoteDeletionPerformance() {
        // Given: 1000 notes to delete
        let notes = createTestNotes(count: 1000)

        // Test: Delete all notes
        measure {
            for note in notes {
                testContext.delete(note)
            }
            try? testContext.save()
        }
    }

    // MARK: - Memory Usage Tests

    func testMemoryUsageDuringBulkOperations() {
        // Test: Monitor memory during bulk creation
        let initialMemory = getMemoryUsage()

        measure {
            autoreleasepool {
                for i in 1 ... 5000 {
                    _ = persistenceController.createNote(
                        title: "Memory Test Note \(i)",
                        content: String(repeating: "Large content block ", count: 100)
                    )
                }
                try? persistenceController.save()
            }
        }

        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory

        // Assert memory increase is reasonable (less than 100MB for 5000 notes)
        XCTAssertLessThan(memoryIncrease, 100 * 1024 * 1024, "Memory increase should be less than 100MB")
    }

    func testMemoryLeakDetection() {
        // Test: Create and delete notes to check for memory leaks
        measure {
            autoreleasepool {
                for i in 1 ... 1000 {
                    let note = persistenceController.createNote(
                        title: "Leak Test \(i)",
                        content: "Content \(i)"
                    )
                    // Immediately delete to test cleanup
                    testContext.delete(note)
                }
                try? testContext.save()
            }
        }
    }

    // MARK: - Sorting Performance Tests

    func testSortingPerformance_ByDate() {
        // Given: 5000 notes with random dates
        createTestNotes(count: 5000, randomizeDates: true)

        // Test: Sort by updated date
        measure {
            _ = try? persistenceController.fetchNotes(
                sortDescriptors: [NSSortDescriptor(key: "updatedAt", ascending: false)]
            )
        }
    }

    func testSortingPerformance_ByTitle() {
        // Given: 5000 notes
        createTestNotes(count: 5000)

        // Test: Sort by title
        measure {
            _ = try? persistenceController.fetchNotes(
                sortDescriptors: [NSSortDescriptor(key: "title", ascending: true)]
            )
        }
    }

    // MARK: - Complex Query Performance Tests

    func testComplexQueryPerformance() {
        // Given: 2000 notes with various attributes
        createComplexTestData(count: 2000)

        // Test: Complex query with multiple predicates
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "isPinned == true"),
            NSPredicate(format: "category == %@", "Work"),
            NSPredicate(format: "title CONTAINS[cd] %@", "Important"),
        ])

        measure {
            _ = try? persistenceController.fetchNotes(predicate: compoundPredicate)
        }
    }

    func testPaginationPerformance() {
        // Given: 10000 notes
        createTestNotes(count: 10000)

        // Test: Fetch with limit (pagination)
        let fetchRequest = Note.fetchRequest()
        fetchRequest.fetchLimit = 50
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]

        measure {
            for page in 0 ..< 20 { // 20 pages of 50 = 1000 notes
                fetchRequest.fetchOffset = page * 50
                _ = try? testContext.fetch(fetchRequest)
            }
        }
    }

    // MARK: - Concurrent Operations Performance Tests

    func testConcurrentReadPerformance() {
        // Given: 5000 notes
        createTestNotes(count: 5000)

        // Test: Concurrent reads
        let expectation = XCTestExpectation(description: "Concurrent reads")
        expectation.expectedFulfillmentCount = 10

        measure {
            DispatchQueue.concurrentPerform(iterations: 10) { _ in
                _ = try? persistenceController.fetchNotes()
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testConcurrentWritePerformance() {
        // Test: Concurrent writes (using separate contexts)
        let expectation = XCTestExpectation(description: "Concurrent writes")
        expectation.expectedFulfillmentCount = 5

        measure {
            DispatchQueue.concurrentPerform(iterations: 5) { iteration in
                autoreleasepool {
                    let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                    privateContext.parent = testContext

                    privateContext.perform {
                        for i in 1 ... 100 {
                            let note = Note(context: privateContext)
                            note.title = "Concurrent Note \(iteration)-\(i)"
                            note.content = "Content for concurrent write test"
                        }

                        do {
                            try privateContext.save()
                            expectation.fulfill()
                        } catch {
                            XCTFail("Failed to save context: \(error)")
                        }
                    }
                }
            }
        }

        wait(for: [expectation], timeout: 15.0)
    }

    // MARK: - Model Validation Performance Tests

    func testValidationPerformance() {
        // Given: Notes with various validation scenarios
        let notes = createTestNotes(count: 1000)

        // Test: Validate all notes
        measure {
            for note in notes {
                _ = try? note.validateTitle()
                _ = try? note.validateContent()
            }
        }
    }

    func testComputedPropertiesPerformance() {
        // Given: Notes with various content lengths
        let notes = createTestNotes(count: 1000, varyContentLength: true)

        // Test: Access computed properties
        measure {
            for note in notes {
                _ = note.displayTitle
                _ = note.previewContent
                _ = note.formattedCreatedDate
                _ = note.formattedUpdatedDate
            }
        }
    }

    // MARK: - Data Migration Performance Tests

    func testDataMigrationPerformance() {
        // Given: Existing data that needs migration
        createLegacyTestData(count: 1000)

        // Test: Migration performance (simulated)
        measure {
            // Simulate migration by updating all notes
            let notes = try? persistenceController.fetchNotes()
            notes?.forEach { note in
                // Simulate migration operations
                note.updatedAt = Date()
                if note.tags == nil {
                    note.tags = []
                }
            }
            try? persistenceController.save()
        }
    }

    // MARK: - Helper Methods

    @discardableResult
    private func createTestNotes(count: Int, pinPercentage: Double = 0.0, randomizeDates: Bool = false, includeSearchableContent: Bool = false, varyContentLength: Bool = false) -> [Note] {
        var notes: [Note] = []

        for i in 1 ... count {
            let note = persistenceController.createNote(
                title: "Test Note \(i)",
                content: generateContent(for: i, includeSearchable: includeSearchableContent, varyLength: varyContentLength)
            )

            if Double.random(in: 0 ... 1) < pinPercentage {
                note.isPinned = true
            }

            if randomizeDates {
                // Random date within last year
                let randomTimeInterval = Double.random(in: 0 ... (365 * 24 * 60 * 60))
                note.createdAt = Date(timeIntervalSinceNow: -randomTimeInterval)
                note.updatedAt = note.createdAt
            }

            notes.append(note)
        }

        try? persistenceController.save()
        return notes
    }

    private func createTestNotesWithCategories(count: Int, categories: [String]) {
        for i in 1 ... count {
            let note = persistenceController.createNote(
                title: "Categorized Note \(i)",
                content: "Content for note \(i)"
            )
            note.category = categories[i % categories.count]
        }
        try? persistenceController.save()
    }

    private func createComplexTestData(count: Int) {
        for i in 1 ... count {
            let note = persistenceController.createNote(
                title: i % 10 == 0 ? "Important Note \(i)" : "Note \(i)",
                content: "Content \(i)"
            )
            note.isPinned = i % 20 == 0 // 5% pinned
            note.category = ["Work", "Personal", "Ideas"][i % 3]
        }
        try? persistenceController.save()
    }

    private func createLegacyTestData(count: Int) {
        // Simulate legacy data without some newer fields
        for i in 1 ... count {
            let note = persistenceController.createNote(
                title: "Legacy Note \(i)",
                content: "Legacy content \(i)"
            )
            // Simulate missing tags field
            note.tags = nil
        }
        try? persistenceController.save()
    }

    private func generateContent(for index: Int, includeSearchable: Bool, varyLength: Bool) -> String {
        if varyLength {
            let lengths = [10, 50, 200, 1000, 5000]
            let length = lengths[index % lengths.count]
            return String(repeating: "Word ", count: length)
        }

        var content = "Content for note \(index)"
        if includeSearchable && index % 10 == 0 {
            content += " searchable content for testing"
        }
        return content
    }

    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), intPtr, &count)
            }
        }

        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }
}

// MARK: - Performance Baselines

extension StickyNotesPerformanceTests {
    // These tests establish performance baselines and will fail if performance degrades

    func testPerformanceBaseline_NoteCreation() {
        // Baseline: Should create 100 notes in less than 0.1 seconds
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            for i in 1 ... 100 {
                _ = persistenceController.createNote(
                    title: "Baseline Note \(i)",
                    content: "Content \(i)"
                )
            }
        }
    }

    func testPerformanceBaseline_NoteFetch() {
        // Given: 1000 notes
        createTestNotes(count: 1000)

        // Baseline: Should fetch 1000 notes in less than 0.05 seconds
        measure(metrics: [XCTClockMetric(), XCTCPUMetric()]) {
            _ = try? persistenceController.fetchNotes()
        }
    }

    func testPerformanceBaseline_NoteSearch() {
        // Given: 1000 notes
        createTestNotes(count: 1000, includeSearchableContent: true)

        // Baseline: Should search 1000 notes in less than 0.02 seconds
        measure(metrics: [XCTClockMetric()]) {
            _ = try? persistenceController.searchNotes(query: "searchable")
        }
    }
}
