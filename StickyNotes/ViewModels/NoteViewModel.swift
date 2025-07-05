//
//  NoteViewModel.swift
//  StickyNotes
//
//  Created on 2025-01-21
//

import SwiftUI
import Combine

@MainActor
class NoteViewModel: ObservableObject {
    @Published var note: Note
    @Published var isEditing = false
    @Published var showColorPicker = false

    private var cancellables = Set<AnyCancellable>()
    private let persistenceService = CoreDataPersistenceService.shared

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    init(note: Note) {
        self.note = note
        setupBindings()
    }

    private func setupBindings() {
        // Auto-save when content changes
        $note
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.saveNote()
            }
            .store(in: &cancellables)
    }

    func updateContent(_ newContent: NSAttributedString) {
        note.content = newContent
        note.modifiedAt = Date()
    }

    func updateTitle(_ newTitle: String) {
        note.title = newTitle
        note.modifiedAt = Date()
    }

    func updateColor(_ newColor: NoteColor) {
        note.color = newColor
        note.modifiedAt = Date()
    }

    func updatePosition(_ newPosition: CGPoint) {
        note.position = newPosition
        note.modifiedAt = Date()
    }

    func updateSize(_ newSize: CGSize) {
        note.size = newSize
        note.modifiedAt = Date()
    }

    func toggleMarkdown() {
        note.isMarkdown.toggle()
        note.modifiedAt = Date()
    }

    func startEditing() {
        isEditing = true
    }

    func stopEditing() {
        isEditing = false
        saveNote()
    }

    private func saveNote() {
        let noteToSave = note
        Task {
            do {
                try await persistenceService.saveNote(noteToSave)
            } catch {
                print("Failed to save note \(noteToSave.id): \(error)")
            }
        }
    }

    // Computed properties for UI
    var backgroundColor: Color {
        note.color.color
    }

    var borderColor: Color {
        note.color.borderColor
    }

    var displayTitle: String {
        note.displayTitle
    }

    var previewText: String {
        note.previewText
    }

    var formattedDate: String {
        NoteViewModel.dateFormatter.string(from: note.modifiedAt)
    }
}