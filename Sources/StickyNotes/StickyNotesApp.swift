//
//  StickyNotesApp.swift
//  StickyNotes
//
//  Created on 2025-01-21
//

import SwiftUI
import StickyNotesCore

@main
struct StickyNotesApp: App {
    @StateObject private var notesManager = NotesManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notesManager)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Note") {
                    notesManager.addNote()
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }
    }
}
