//
//  ContentView.swift
//  StickyNotes
//
//  Created by SuperClaude
//  Copyright © 2024 SuperClaude. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var notesManager = NotesManager()

    var body: some View {
        NavigationSplitView {
            List(notesManager.notes, selection: $notesManager.selectedNote) { note in
                HStack {
                    VStack(alignment: .leading) {
                        Text(note.displayTitle)
                            .font(.headline)
                        Text(note.previewContent)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button {
                        notesManager.openNoteInWindow(note)
                    } label: {
                        Image(systemName: "macwindow")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Open in floating window")
                }
            }
            .searchable(text: $notesManager.searchText)
            .navigationTitle("Notes")
        } detail: {
            if let note = notesManager.selectedNote {
                VStack {
                    Text(note.title)
                        .font(.title)
                    Text(note.content)
                        .font(.body)
                    Spacer()
                }
                .padding()
            } else {
                Text("Select a note")
                    .foregroundColor(.secondary)
            }
        }
    }
}

class NotesManager: ObservableObject {
    @Published var notes: [SimpleNote] = []
    @Published var selectedNote: SimpleNote?
    @Published var searchText = ""

    init() {
        // Create some sample notes
        notes = [
            SimpleNote(title: "Welcome to StickyNotes", content: "This is your first sticky note! You can create floating windows for any note by clicking the window icon.", color: "#FFE4B5"),
            SimpleNote(title: "Yellow Note", content: "A yellow sticky note with some content.", color: "#FFE4B5"),
            SimpleNote(title: "Blue Note", content: "A blue sticky note example.", color: "#E6E6FA"),
            SimpleNote(title: "Green Note", content: "A green sticky note for your ideas.", color: "#F0FFF0")
        ]
    }

    func addNote() {
        let note = SimpleNote()
        notes.append(note)
        selectedNote = note
    }

    func openNoteInWindow(_ note: SimpleNote) {
        NoteWindowManager.shared.showNoteWindow(for: note)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}