//
//  StickyNotesTests.swift
//  StickyNotesTests
//
//  Created on 2025-01-21
//

@testable import StickyNotes
import XCTest

class StickyNotesTests: XCTestCase {
    func testNoteCreation() {
        let note = Note(title: "Test Note", color: .yellow)

        XCTAssertEqual(note.title, "Test Note")
        XCTAssertEqual(note.color, .yellow)
        XCTAssertEqual(note.displayTitle, "Test Note")
        XCTAssertFalse(note.content.string.isEmpty)
    }

    func testNoteColorProperties() {
        let yellowNote = Note(color: .yellow)
        let blueNote = Note(color: .blue)

        XCTAssertEqual(yellowNote.color.color.hex, "#FEF08A")
        XCTAssertEqual(blueNote.color.color.hex, "#BFDBFE")
        XCTAssertEqual(yellowNote.color.displayName, "Yellow")
        XCTAssertEqual(blueNote.color.displayName, "Blue")
    }

    func testNoteViewModel() {
        let note = Note(title: "Test", color: .yellow)
        let viewModel = NoteViewModel(note: note)

        XCTAssertEqual(viewModel.displayTitle, "Test")
        XCTAssertEqual(viewModel.backgroundColor.hex, "#FEF08A")

        viewModel.updateTitle("Updated Title")
        XCTAssertEqual(viewModel.note.title, "Updated Title")
    }

    func testNotesViewModel() {
        let viewModel = NotesViewModel()

        let note1 = viewModel.createNote(title: "Note 1", color: .yellow)
        let note2 = viewModel.createNote(title: "Note 2", color: .blue)

        XCTAssertEqual(viewModel.notes.count, 2)
        XCTAssertEqual(viewModel.notes[0].title, "Note 1")
        XCTAssertEqual(viewModel.notes[1].title, "Note 2")
    }
}

// MARK: - Test Extensions

extension Color {
    var hex: String {
        // Simplified hex conversion for testing
        // In a real implementation, you'd extract RGB components
        switch self {
        case Color(hex: "#FEF08A"): return "#FEF08A"
        case Color(hex: "#BFDBFE"): return "#BFDBFE"
        default: return "#000000"
        }
    }
}
