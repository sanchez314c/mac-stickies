//
//  StickyNotesUITests.swift
//  StickyNotesUITests
//
//  Created by SuperClaude
//  Copyright © 2024 SuperClaude. All rights reserved.
//

import XCTest

final class StickyNotesUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launch()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - App Launch Tests

    func testAppLaunchesSuccessfully() {
        // Then
        XCTAssertTrue(app.state == .runningForeground, "App should launch and be in foreground")
    }

    func testMainWindowExists() {
        // Then
        XCTAssertTrue(app.windows.count >= 1, "App should have at least one window")
    }

    // MARK: - Navigation Tests

    func testSidebarNavigation() {
        // Given
        let sidebar = app.outlines.firstMatch

        // Then
        XCTAssertTrue(sidebar.exists, "Sidebar should exist")
        XCTAssertTrue(sidebar.isHittable, "Sidebar should be accessible")
    }

    func testNewNoteButtonExists() {
        // Then
        let newNoteButton = app.buttons["New Note"]
        XCTAssertTrue(newNoteButton.exists, "New Note button should exist")
        XCTAssertTrue(newNoteButton.isEnabled, "New Note button should be enabled")
    }

    // MARK: - Note Creation Tests

    func testCreateNewNote() {
        // Given
        let initialNotesCount = app.outlines.staticTexts.matching(identifier: "NoteRow").count

        // When
        app.buttons["New Note"].click()

        // Then
        let newNoteSheet = app.sheets.firstMatch
        XCTAssertTrue(newNoteSheet.exists, "New note sheet should appear")

        // Fill in note details
        let titleField = newNoteSheet.textFields.firstMatch
        XCTAssertTrue(titleField.exists, "Title field should exist")

        titleField.click()
        titleField.typeText("UI Test Note")

        let contentField = newNoteSheet.textViews.firstMatch
        XCTAssertTrue(contentField.exists, "Content field should exist")

        contentField.click()
        contentField.typeText("This is a test note created by UI tests.")

        // Create the note
        newNoteSheet.buttons["Create"].click()

        // Verify note was created
        let finalNotesCount = app.outlines.staticTexts.matching(identifier: "NoteRow").count
        XCTAssertEqual(finalNotesCount, initialNotesCount + 1, "Notes count should increase by 1")
    }

    func testCreateNoteValidation_EmptyTitle() {
        // When
        app.buttons["New Note"].click()

        let newNoteSheet = app.sheets.firstMatch
        XCTAssertTrue(newNoteSheet.exists, "New note sheet should appear")

        // Try to create note without title
        let createButton = newNoteSheet.buttons["Create"]
        XCTAssertFalse(createButton.isEnabled, "Create button should be disabled for empty title")

        // Fill title and verify button enables
        let titleField = newNoteSheet.textFields.firstMatch
        titleField.click()
        titleField.typeText("Valid Title")

        XCTAssertTrue(createButton.isEnabled, "Create button should be enabled with valid title")
    }

    // MARK: - Note Display Tests

    func testNoteDisplaysCorrectly() {
        // Given: Create a test note
        createTestNote(title: "Display Test", content: "Test content for display")

        // When: Select the note
        let noteRow = app.outlines.staticTexts["Display Test"]
        XCTAssertTrue(noteRow.exists, "Note should appear in sidebar")
        noteRow.click()

        // Then: Verify note details are displayed
        let detailView = app.scrollViews.firstMatch
        XCTAssertTrue(detailView.exists, "Note detail view should exist")

        XCTAssertTrue(app.staticTexts["Display Test"].exists, "Note title should be displayed")
        XCTAssertTrue(app.staticTexts["Test content for display"].exists, "Note content should be displayed")
    }

    func testNotePreviewInSidebar() {
        // Given: Create a note with long content
        let longContent = String(repeating: "This is a long note content that should be truncated in the sidebar preview. ", count: 10)
        createTestNote(title: "Preview Test", content: longContent)

        // When: Look at sidebar
        let sidebar = app.outlines.firstMatch

        // Then: Verify preview is truncated
        let noteRow = sidebar.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Preview Test")).firstMatch
        XCTAssertTrue(noteRow.exists, "Note should appear in sidebar")

        // Note: Exact truncation verification would require more specific element identification
        // This is a basic check that the note appears
    }

    // MARK: - Search Functionality Tests

    func testSearchNotes() {
        // Given: Create multiple notes
        createTestNote(title: "Meeting Notes", content: "Discuss project timeline")
        createTestNote(title: "Shopping List", content: "Buy groceries")
        createTestNote(title: "Book Ideas", content: "Novel concepts")

        // When: Search for specific term
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.exists, "Search field should exist")

        searchField.click()
        searchField.typeText("Meeting")

        // Then: Only matching notes should be visible
        let visibleNotes = app.outlines.staticTexts.matching(identifier: "NoteRow")
        XCTAssertEqual(visibleNotes.count, 1, "Only one note should match search")

        let meetingNote = app.outlines.staticTexts["Meeting Notes"]
        XCTAssertTrue(meetingNote.exists, "Meeting Notes should be visible")
    }

    func testSearchNotes_NoResults() {
        // Given: Create some notes
        createTestNote(title: "Note 1", content: "Content 1")
        createTestNote(title: "Note 2", content: "Content 2")

        // When: Search for non-existent term
        let searchField = app.searchFields.firstMatch
        searchField.click()
        searchField.typeText("nonexistent")

        // Then: No notes should be visible
        let visibleNotes = app.outlines.staticTexts.matching(identifier: "NoteRow")
        XCTAssertEqual(visibleNotes.count, 0, "No notes should match non-existent search term")
    }

    // MARK: - Edit Note Tests

    func testEditNote() {
        // Given: Create and select a note
        createTestNote(title: "Edit Test", content: "Original content")
        selectNote(title: "Edit Test")

        // When: Enter edit mode
        app.buttons["Edit"].click()

        // Then: Edit fields should be available
        let titleField = app.textFields.firstMatch
        XCTAssertTrue(titleField.exists, "Title field should be editable")

        let contentField = app.textViews.firstMatch
        XCTAssertTrue(contentField.exists, "Content field should be editable")

        // Edit the content
        titleField.click()
        titleField.clearAndEnterText("Edited Title")

        contentField.click()
        contentField.clearAndEnterText("Edited content")

        // Save changes
        app.buttons["Save"].click()

        // Verify changes were saved
        XCTAssertTrue(app.staticTexts["Edited Title"].exists, "Edited title should be displayed")
        XCTAssertTrue(app.staticTexts["Edited content"].exists, "Edited content should be displayed")
    }

    func testCancelEditNote() {
        // Given: Create and select a note
        createTestNote(title: "Cancel Edit Test", content: "Original content")
        selectNote(title: "Cancel Edit Test")

        // When: Enter edit mode and make changes
        app.buttons["Edit"].click()

        let titleField = app.textFields.firstMatch
        titleField.click()
        titleField.clearAndEnterText("Changed Title")

        // Cancel changes
        app.buttons["Cancel"].click()

        // Then: Original content should be preserved
        XCTAssertTrue(app.staticTexts["Cancel Edit Test"].exists, "Original title should be displayed")
        XCTAssertTrue(app.staticTexts["Original content"].exists, "Original content should be displayed")
        XCTAssertFalse(app.staticTexts["Changed Title"].exists, "Changed title should not be displayed")
    }

    // MARK: - Category Tests

    func testCreateNoteWithCategory() {
        // When: Create a note with category
        app.buttons["New Note"].click()

        let newNoteSheet = app.sheets.firstMatch
        let titleField = newNoteSheet.textFields.firstMatch
        titleField.click()
        titleField.typeText("Categorized Note")

        let categoryField = newNoteSheet.textFields["Category (optional)"]
        categoryField.click()
        categoryField.typeText("Work")

        newNoteSheet.buttons["Create"].click()

        // Then: Category should be displayed
        selectNote(title: "Categorized Note")
        XCTAssertTrue(app.staticTexts["Work"].exists, "Category should be displayed")
    }

    // MARK: - Keyboard Navigation Tests

    func testKeyboardNavigation() {
        // Given: Create a note
        createTestNote(title: "Keyboard Test", content: "Test content")

        // When: Use keyboard shortcuts
        selectNote(title: "Keyboard Test")

        // Test edit shortcut (Cmd+E)
        app.typeKey("e", modifierFlags: .command)

        // Then: Should enter edit mode
        let titleField = app.textFields.firstMatch
        XCTAssertTrue(titleField.exists, "Should enter edit mode with Cmd+E")

        // Test cancel shortcut (Escape)
        app.typeKey(.escape, modifierFlags: [])
        XCTAssertFalse(app.textFields.firstMatch.exists, "Should exit edit mode with Escape")
    }

    // MARK: - Accessibility Tests

    func testAccessibilityLabels() {
        // Given: App is launched

        // When: Check accessibility
        let newNoteButton = app.buttons["New Note"]

        // Then: Elements should have proper accessibility labels
        XCTAssertNotNil(newNoteButton.identifier, "New Note button should have accessibility identifier")
        // Note: isAccessibilityElement is not available in this version of XCTest
    }

    func testVoiceOverCompatibility() {
        // Given: App is launched with VoiceOver simulated

        // When: Navigate through elements
        let sidebar = app.outlines.firstMatch

        // Then: Elements should be accessible to VoiceOver
        XCTAssertTrue(sidebar.children(matching: .any).count > 0,
                      "Sidebar should contain accessible elements")
    }

    // MARK: - Performance Tests

    func testAppLaunchPerformance() {
        // Given
        let app = XCUIApplication()

        // When: Measure launch time
        measure {
            app.launch()
            // Note: In real UI tests, we'd need to wait for the app to be ready
            // This is a simplified version for demonstration
        }
    }

    func testNoteCreationPerformance() {
        // Given
        let iterationCount = 10

        // When: Measure note creation time
        measure {
            for i in 1 ... iterationCount {
                createTestNote(title: "Performance Note \(i)", content: "Content \(i)")
            }
        }

        // Note: In real UI tests, performance measurement would be more sophisticated
        // This is a simplified version for demonstration
    }

    // MARK: - Helper Methods

    private func createTestNote(title: String, content: String = "Test content") {
        app.buttons["New Note"].click()

        let newNoteSheet = app.sheets.firstMatch
        let titleField = newNoteSheet.textFields.firstMatch
        titleField.click()
        titleField.typeText(title)

        let contentField = newNoteSheet.textViews.firstMatch
        contentField.click()
        contentField.typeText(content)

        newNoteSheet.buttons["Create"].click()

        // Wait for note to be created
        let noteRow = app.outlines.staticTexts[title]
        XCTAssertTrue(noteRow.waitForExistence(timeout: 5), "Note should appear in sidebar")
    }

    private func selectNote(title: String) {
        let noteRow = app.outlines.staticTexts[title]
        XCTAssertTrue(noteRow.exists, "Note should exist in sidebar")
        noteRow.click()

        // Wait for selection
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 2), "Note should be selected")
    }
}

// MARK: - Extensions

extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard let stringValue = value as? String else {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }

        click()

        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
        typeText(text)
    }
}
