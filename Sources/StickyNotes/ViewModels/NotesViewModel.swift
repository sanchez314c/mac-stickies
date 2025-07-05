//
//  NotesViewModel.swift
//  StickyNotes
//
//  Created on 2025-01-21
//

import Combine
import SwiftUI

class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var filteredNotes: [Note] = []
    @Published var selectedNote: Note?
    @Published var searchText = ""
    @Published var selectedColorFilter: NoteColor?
    @Published var isLoading = false
    @Published var hasMoreNotes = true

    private var currentOffset = 0
    private let batchSize = 50
    private var allNotesLoaded = false
    private var cancellables = Set<AnyCancellable>()
    private let persistenceService: CoreDataPersistenceService
    private let cacheService: CacheService

    init(persistenceService: CoreDataPersistenceService = .shared, cacheService: CacheService = .shared) {
        self.persistenceService = persistenceService
        self.cacheService = cacheService
        setupBindings()
        loadInitialNotes()
    }

    private func setupBindings() {
        // Filter notes based on search and color filter with debouncing
        Publishers.CombineLatest($searchText, $selectedColorFilter)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] searchText, colorFilter in
                self?.filterNotes(searchText: searchText, colorFilter: colorFilter)
            }
            .store(in: &cancellables)
    }

    // MARK: - Note Management

    func createNote(title: String = "New Note", color: NoteColor = .yellow) -> Note {
        let note = Note(title: title, color: color)
        notes.append(note)
        selectedNote = note
        saveNote(note)
        return note
    }

    func createNote(with content: NSAttributedString, color: NoteColor = .yellow) -> Note {
        let note = Note(content: content, color: color)
        notes.append(note)
        selectedNote = note
        saveNote(note)
        return note
    }

    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        if selectedNote?.id == note.id {
            selectedNote = nil
        }
        deleteNoteFromPersistence(note)
    }

    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
            updateFilteredNotes()
            saveNote(note)
        }
    }

    func duplicateNote(_ note: Note) -> Note {
        let duplicatedNote = Note(
            title: "\(note.title) Copy",
            content: note.content,
            color: note.color,
            position: CGPoint(x: note.position.x + 20, y: note.position.y + 20),
            size: note.size
        )
        notes.append(duplicatedNote)
        selectedNote = duplicatedNote
        saveNote(duplicatedNote)
        return duplicatedNote
    }

    // MARK: - Loading and Filtering

    private func loadInitialNotes() {
        Task {
            await loadNotesBatch(reset: true)
        }
    }

    private func loadNotesBatch(reset: Bool = false) async {
        guard !isLoading else { return }

        await MainActor.run { isLoading = true }

        do {
            if reset {
                currentOffset = 0
                allNotesLoaded = false
                hasMoreNotes = true
            }

            let batch = try await persistenceService.fetchNotesBatch(
                offset: currentOffset,
                limit: batchSize,
                searchText: searchText.isEmpty ? nil : searchText,
                colorFilter: selectedColorFilter
            )

            await MainActor.run {
                if reset {
                    notes = batch
                } else {
                    notes.append(contentsOf: batch)
                }

                currentOffset += batch.count
                hasMoreNotes = batch.count == batchSize
                allNotesLoaded = batch.count < batchSize
                updateFilteredNotes()
            }
        } catch {
            print("Failed to load notes batch: \(error)")
        }

        await MainActor.run { isLoading = false }
    }

    func loadMoreNotes() {
        guard hasMoreNotes, !isLoading else { return }
        Task {
            await loadNotesBatch()
        }
    }

    private func filterNotes(searchText _: String, colorFilter _: NoteColor?) {
        // Reset pagination when filters change
        Task {
            await loadNotesBatch(reset: true)
        }
    }

    private func updateFilteredNotes() {
        // For now, filteredNotes is the same as notes since we filter at the database level
        // This could be extended for client-side filtering if needed
        filteredNotes = notes
    }

    // MARK: - Persistence

    private func saveNote(_ note: Note) {
        Task {
            do {
                try await persistenceService.saveNote(note)
                // Invalidate cache for this note
                cacheService.invalidateNote(note.id)
            } catch {
                print("Failed to save note: \(error)")
            }
        }
    }

    private func deleteNoteFromPersistence(_ note: Note) {
        Task {
            do {
                try await persistenceService.deleteNote(id: note.id)
                // Remove from local array and invalidate cache
                notes.removeAll { $0.id == note.id }
                cacheService.invalidateNote(note.id)
                updateFilteredNotes()
            } catch {
                print("Failed to delete note: \(error)")
            }
        }
    }

    // MARK: - Export

    func exportNote(_ note: Note, format: ExportFormat) async throws -> URL {
        return try await persistenceService.exportNote(note, format: format)
    }

    // MARK: - UI State

    func selectNote(_ note: Note?) {
        selectedNote = note
    }

    func clearSelection() {
        selectedNote = nil
    }

    func setColorFilter(_ color: NoteColor?) {
        selectedColorFilter = color
    }

    func clearSearch() {
        searchText = ""
    }

    // MARK: - Statistics

    var totalNotesCount: Int {
        notes.count
    }

    var notesByColor: [NoteColor: Int] {
        Dictionary(grouping: notes, by: { $0.color })
            .mapValues { $0.count }
    }
}
