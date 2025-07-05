//
//  ContentView.swift
//  StickyNotes
//
//  Created by SuperClaude
//  Copyright © 2024 SuperClaude. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var notesManager: NotesManager

    var body: some View {
        NavigationView {
            List {
                ForEach(notesManager.notes) { note in
                    NoteRowView(note: note, notesManager: notesManager)
                        .onTapGesture {
                            notesManager.selectedNote = note
                        }
                }
            }
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Note", systemImage: "plus") {
                        notesManager.addNote()
                    }
                }
            }

            if let note = notesManager.selectedNote {
                NoteDetailView(note: note, notesManager: notesManager)
            } else {
                VStack {
                    Image(systemName: "note.text")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("Select a note to view")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct NoteRowView: View {
    let note: SimpleNote
    let notesManager: NotesManager

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.displayTitle)
                    .font(.headline)
                Text(note.previewContent)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Circle()
                .fill(Color(hex: note.color) ?? .yellow)
                .frame(width: 12, height: 12)
        }
        .padding(.vertical, 2)
    }
}

struct NoteDetailView: View {
    @State private var isEditing = false
    @State private var editableTitle: String
    @State private var editableContent: String
    let note: SimpleNote
    let notesManager: NotesManager

    init(note: SimpleNote, notesManager: NotesManager) {
        self.note = note
        self.notesManager = notesManager
        self._editableTitle = State(initialValue: note.title)
        self._editableContent = State(initialValue: note.content)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                if isEditing {
                    TextField("Note Title", text: $editableTitle)
                        .textFieldStyle(.plain)
                        .font(.title)
                } else {
                    Text(note.displayTitle)
                        .font(.title)
                }

                Spacer()

                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        saveChanges()
                    }
                    isEditing.toggle()
                }
            }

            Divider()

            if isEditing {
                TextEditor(text: $editableContent)
                    .font(.body)
            } else {
                ScrollView {
                    Text(note.content.isEmpty ? "Click Edit to add content..." : note.content)
                        .font(.body)
                        .foregroundColor(note.content.isEmpty ? .secondary : .primary)
                        .textSelection(.enabled)
                }
            }

            Spacer()
        }
        .padding()
        .onAppear {
            editableTitle = note.title
            editableContent = note.content
        }
    }

    private func saveChanges() {
        var updatedNote = note
        updatedNote.title = editableTitle
        updatedNote.content = editableContent
        notesManager.updateNote(updatedNote)
    }
}

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
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
            SimpleNote(title: "Green Note", content: "A green sticky note for your ideas.", color: "#F0FFF0"),
        ]
    }

    func addNote() {
        let note = SimpleNote()
        notes.append(note)
        selectedNote = note
    }

    func updateNote(_ note: SimpleNote) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index] = note
    }
}
