//
//  NoteService.swift
//  StickyNotes
//
//  Created on 2025-01-21.
//

import Foundation
import Combine
import CoreGraphics

/// Service providing high-level note operations with business logic
public final class NoteService {
    public static let shared = NoteService()

    private let repository: NoteRepository
    private let persistenceController: PersistenceController

    // Publishers for reactive updates
    public let notesPublisher = PassthroughSubject<[Note], Never>()
    public let errorPublisher = PassthroughSubject<ServiceError, Never>()

    private var cancellables = Set<AnyCancellable>()

    public init(repository: NoteRepository = CoreDataNoteRepository()) {
        self.repository = repository
        self.persistenceController = .shared

        setupSyncObservers()
    }

    private func setupSyncObservers() {
        // Observe persistence controller sync status
        persistenceController.syncStatusPublisher
            .sink { [weak self] status in
                switch status {
                case .synced:
                    // Refresh notes when sync completes
                    Task {
                        await self?.refreshNotes()
                    }
                case .error:
                    self?.errorPublisher.send(.syncError)
                default:
                    break
                }
            }
            .store(in: &cancellables)

        persistenceController.errorPublisher
            .sink { [weak self] error in
                self?.errorPublisher.send(.persistenceError(error))
            }
            .store(in: &cancellables)
    }

    // MARK: - CRUD Operations

    /// Create a new note
    public func createNote(
        title: String = "New Note",
        content: String = "",
        color: NoteColor = .yellow,
        position: CGPoint = .zero,
        size: CGSize = CGSize(width: 300, height: 200)
    ) async throws -> Note {
        let note = Note(
            title: title,
            content: content,
            color: color,
            position: position,
            size: size
        )

        do {
            try await repository.saveNote(note)
            await refreshNotes()
            return note
        } catch {
            errorPublisher.send(.createFailed(error))
            throw ServiceError.createFailed(error)
        }
    }

    /// Get all notes
    public func getAllNotes() async throws -> [Note] {
        do {
            let notes = try await repository.fetchNotes()
            return notes
        } catch {
            errorPublisher.send(.fetchFailed(error))
            throw ServiceError.fetchFailed(error)
        }
    }

    /// Get a specific note
    public func getNote(withId id: UUID) async throws -> Note? {
        do {
            return try await repository.fetchNote(withId: id)
        } catch {
            errorPublisher.send(.fetchFailed(error))
            throw ServiceError.fetchFailed(error)
        }
    }

    /// Update an existing note
    public func updateNote(_ note: Note) async throws {
        do {
            try await repository.saveNote(note)
            await refreshNotes()
        } catch {
            errorPublisher.send(.updateFailed(error))
            throw ServiceError.updateFailed(error)
        }
    }

    /// Delete a note
    public func deleteNote(withId id: UUID) async throws {
        do {
            try await repository.deleteNote(withId: id)
            await refreshNotes()
        } catch {
            errorPublisher.send(.deleteFailed(error))
            throw ServiceError.deleteFailed(error)
        }
    }

    /// Delete multiple notes
    public func deleteNotes(withIds ids: [UUID]) async throws {
        do {
            try await repository.deleteNotes(withIds: ids)
            await refreshNotes()
        } catch {
            errorPublisher.send(.deleteFailed(error))
            throw ServiceError.deleteFailed(error)
        }
    }

    // MARK: - Search and Filter

    /// Search notes by text
    public func searchNotes(containing text: String) async throws -> [Note] {
        do {
            return try await repository.searchNotes(containing: text)
        } catch {
            errorPublisher.send(.searchFailed(error))
            throw ServiceError.searchFailed(error)
        }
    }

    /// Get notes by color
    public func getNotes(withColor color: NoteColor) async throws -> [Note] {
        do {
            return try await repository.fetchNotes(withColor: color)
        } catch {
            errorPublisher.send(.fetchFailed(error))
            throw ServiceError.fetchFailed(error)
        }
    }

    /// Get notes by tags
    public func getNotes(withTags tags: [String]) async throws -> [Note] {
        do {
            return try await repository.fetchNotes(withTags: tags)
        } catch {
            errorPublisher.send(.fetchFailed(error))
            throw ServiceError.fetchFailed(error)
        }
    }

    // MARK: - Batch Operations

    /// Duplicate a note
    public func duplicateNote(_ note: Note) async throws -> Note {
        let duplicatedNote = Note(
            title: "\(note.title) Copy",
            content: note.content,
            color: note.color,
            position: CGPoint(x: note.position.x + 20, y: note.position.y + 20),
            size: note.size,
            isMarkdown: note.isMarkdown,
            tags: note.tags
        )

        do {
            try await repository.saveNote(duplicatedNote)
            await refreshNotes()
            return duplicatedNote
        } catch {
            errorPublisher.send(.createFailed(error))
            throw ServiceError.createFailed(error)
        }
    }

    /// Update note position
    public func updateNotePosition(id: UUID, position: CGPoint) async throws {
        guard var note = try await repository.fetchNote(withId: id) else {
            throw ServiceError.noteNotFound
        }

        note.position = position
        try await updateNote(note)
    }

    /// Update note size
    public func updateNoteSize(id: UUID, size: CGSize) async throws {
        guard var note = try await repository.fetchNote(withId: id) else {
            throw ServiceError.noteNotFound
        }

        note.size = size
        try await updateNote(note)
    }

    /// Toggle markdown mode
    public func toggleMarkdownMode(forId id: UUID) async throws {
        guard var note = try await repository.fetchNote(withId: id) else {
            throw ServiceError.noteNotFound
        }

        note.isMarkdown.toggle()
        try await updateNote(note)
    }

    /// Add tag to note
    public func addTag(_ tag: String, toNoteWithId id: UUID) async throws {
        guard var note = try await repository.fetchNote(withId: id) else {
            throw ServiceError.noteNotFound
        }

        if !note.tags.contains(tag) {
            note.tags.append(tag)
            try await updateNote(note)
        }
    }

    /// Remove tag from note
    public func removeTag(_ tag: String, fromNoteWithId id: UUID) async throws {
        guard var note = try await repository.fetchNote(withId: id) else {
            throw ServiceError.noteNotFound
        }

        note.tags.removeAll { $0 == tag }
        try await updateNote(note)
    }

    // MARK: - Statistics

    /// Get total notes count
    public func getNotesCount() async throws -> Int {
        do {
            return try await repository.notesCount()
        } catch {
            errorPublisher.send(.fetchFailed(error))
            throw ServiceError.fetchFailed(error)
        }
    }

    /// Get notes statistics
    public func getNotesStatistics() async throws -> NotesStatistics {
        let notes = try await getAllNotes()

        let colorCounts = Dictionary(grouping: notes, by: { $0.color })
            .mapValues { $0.count }

        let tagCounts = notes.flatMap { $0.tags }
            .reduce(into: [String: Int]()) { counts, tag in
                counts[tag, default: 0] += 1
            }

        let markdownCount = notes.filter { $0.isMarkdown }.count
        let lockedCount = notes.filter { $0.isLocked }.count

        let totalContentLength = notes.reduce(0) { $0 + $1.content.count }

        return NotesStatistics(
            totalNotes: notes.count,
            colorDistribution: colorCounts,
            tagDistribution: tagCounts,
            markdownNotes: markdownCount,
            lockedNotes: lockedCount,
            averageContentLength: notes.isEmpty ? 0 : totalContentLength / notes.count
        )
    }

    // MARK: - Sync Operations

    /// Trigger manual sync
    public func sync() {
        persistenceController.triggerSync()
    }

    /// Check if iCloud is available
    public func isCloudSyncAvailable() async -> Bool {
        await persistenceController.isCloudKitAvailable()
    }

    // MARK: - Private Methods

    private func refreshNotes() async {
        do {
            let notes = try await repository.fetchNotes()
            notesPublisher.send(notes)
        } catch {
            errorPublisher.send(.fetchFailed(error))
        }
    }
}

// MARK: - Supporting Types

public struct NotesStatistics {
    public let totalNotes: Int
    public let colorDistribution: [NoteColor: Int]
    public let tagDistribution: [String: Int]
    public let markdownNotes: Int
    public let lockedNotes: Int
    public let averageContentLength: Int
}

public enum ServiceError: LocalizedError {
    case createFailed(Error)
    case fetchFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    case searchFailed(Error)
    case syncError
    case persistenceError(PersistenceError)
    case noteNotFound

    public var errorDescription: String? {
        switch self {
        case .createFailed(let error):
            return "Failed to create note: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch notes: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update note: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete note: \(error.localizedDescription)"
        case .searchFailed(let error):
            return "Failed to search notes: \(error.localizedDescription)"
        case .syncError:
            return "Synchronization failed"
        case .persistenceError(let error):
            return "Persistence error: \(error.localizedDescription)"
        case .noteNotFound:
            return "Note not found"
        }
    }
}