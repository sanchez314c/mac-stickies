//
//  StickyNotesCommands.swift
//  StickyNotes
//
//  Created by SuperClaude
//  Copyright © 2024 SuperClaude. All rights reserved.
//

import SwiftUI

struct StickyNotesCommands: Commands {
    // For demo purposes, we'll use a shared notes manager
    // In a real app, this would be injected through the environment

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Note") {
                // This would be handled by the ContentView's NotesManager
                print("New note command")
            }
            .keyboardShortcut("n", modifiers: .command)
        }

        CommandGroup(replacing: .saveItem) {
            Button("Export Note") {
                exportCurrentNote()
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
        }

        CommandMenu("Notes") {
            Button("New Yellow Note") {
                createNoteWithColor("#FFE4B5")
            }
            .keyboardShortcut("1", modifiers: .command)

            Button("New Blue Note") {
                createNoteWithColor("#E6E6FA")
            }
            .keyboardShortcut("2", modifiers: .command)

            Button("New Green Note") {
                createNoteWithColor("#F0FFF0")
            }
            .keyboardShortcut("3", modifiers: .command)

            Button("New Pink Note") {
                createNoteWithColor("#FFB6C1")
            }
            .keyboardShortcut("4", modifiers: .command)

            Button("New Purple Note") {
                createNoteWithColor("#DDA0DD")
            }
            .keyboardShortcut("5", modifiers: .command)

            Button("New Orange Note") {
                createNoteWithColor("#F5DEB3")
            }
            .keyboardShortcut("6", modifiers: .command)

            Divider()

            Button("Show All Notes in Windows") {
                showAllNotesInWindows()
            }
            .keyboardShortcut("a", modifiers: [.command, .shift])

            Button("Close All Floating Windows") {
                closeAllNotes()
            }
            .keyboardShortcut("w", modifiers: [.command, .shift])
        }

        CommandGroup(replacing: .windowList) {
            // Custom window management commands
        }
    }

    private func createNoteWithColor(_ color: String) {
        let note = SimpleNote(title: "New Note", color: color)
        // In a real app, this would add to the shared notes manager
        NoteWindowManager.shared.showNoteWindow(for: note)
    }

    private func exportCurrentNote() {
        // Export the currently focused note
        // This would need to be implemented with focus management
        print("Exporting current note")
    }

    private func showAllNotesInWindows() {
        // For demo, create some sample notes and show them
        let sampleNotes = [
            SimpleNote(title: "Sample Yellow", color: "#FFE4B5"),
            SimpleNote(title: "Sample Blue", color: "#E6E6FA"),
            SimpleNote(title: "Sample Green", color: "#F0FFF0"),
        ]

        for note in sampleNotes {
            NoteWindowManager.shared.showNoteWindow(for: note)
        }
    }

    private func closeAllNotes() {
        NoteWindowManager.shared.closeAllWindows()
    }
}
