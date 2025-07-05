//
//  NoteRepository.swift
//  StickyNotes
//
//  Created on 2025-01-21.
//

import Foundation
import CoreData
import Combine

/// Protocol defining the interface for note data operations
public protocol NoteRepository {
    /// Fetch all notes
    func fetchNotes() async throws -> [Note]

    /// Fetch a specific note by ID
    func fetchNote(withId id: UUID) async throws -> Note?

    /// Search notes by text content
    func searchNotes(containing text: String) async throws -> [Note]

    /// Fetch notes by color
    func fetchNotes(withColor color: NoteColor) async throws -> [Note]

    /// Fetch notes by tags
    func fetchNotes(withTags tags: [String]) async throws -> [Note]

    /// Save a note
    func saveNote(_ note: Note) async throws

    /// Save multiple notes
    func saveNotes(_ notes: [Note]) async throws

    /// Delete a note by ID
    func deleteNote(withId id: UUID) async throws

    /// Delete multiple notes
    func deleteNotes(withIds ids: [UUID]) async throws

    /// Update note modification date
    func updateNoteModificationDate(forId id: UUID) async throws

    /// Get notes count
    func notesCount() async throws -> Int

    /// Check if note exists
    func noteExists(withId id: UUID) async throws -> Bool
}

/// Core Data implementation of NoteRepository
public final class CoreDataNoteRepository: NoteRepository {
    private let persistenceController: PersistenceController
    private let viewContext: NSManagedObjectContext

    public init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.viewContext = persistenceController.viewContext
    }

    // MARK: - Fetch Operations

    public func fetchNotes() async throws -> [Note] {
        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.performBackgroundTask { context in
                do {
                    let request = NoteEntity.fetchRequestSortedByModifiedDate()
                    let entities = try context.fetch(request)
                    let notes = entities.compactMap { Note(from: $0) }
                    continuation.resume(returning: notes)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func fetchNote(withId id: UUID) async throws -> Note? {
        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.performBackgroundTask { context in
                do {
                    let request = NoteEntity.fetchRequestForNote(withId: id)
                    let entities = try context.fetch(request)
                    let note = entities.first.flatMap { Note(from: $0) }
                    continuation.resume(returning: note)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func searchNotes(containing text: String) async throws -> [Note] {
        guard !text.isEmpty else { return try await fetchNotes() }

        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.performBackgroundTask { context in
                do {
                    let request = NoteEntity.fetchRequestForNotes(containing: text)
                    let entities = try context.fetch(request)
                    let notes = entities.compactMap { Note(from: $0) }
                    continuation.resume(returning: notes)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func fetchNotes(withColor color: NoteColor) async throws -> [Note] {
        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.performBackgroundTask { context in
                do {
                    let request = NoteEntity.fetchRequestForNotes(withColor: color.rawValue)
                    let entities = try context.fetch(request)
                    let notes = entities.compactMap { Note(from: $0) }
                    continuation.resume(returning: notes)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func fetchNotes(withTags tags: [String]) async throws -> [Note] {
        guard !tags.isEmpty else { return try await fetchNotes() }

        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.performBackgroundTask { context in
                do {
                    let request = NoteEntity.fetchRequestForNotes(withTags: tags)
                    let entities = try context.fetch(request)
                    let notes = entities.compactMap { Note(from: $0) }
                    continuation.resume(returning: notes)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Save Operations

    public func saveNote(_ note: Note) async throws {
        let updatedNote = Note(
            id: note.id,
            title: note.title,
            content: note.content,
            color: note.color,
            position: note.position,
            size: note.size,
            createdAt: note.createdAt,
            modifiedAt: Date(),
            isMarkdown: note.isMarkdown,
            isLocked: note.isLocked,
            tags: note.tags
        )

        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.performBackgroundTask { context in
                do {
                    // Check if entity exists
                    let request = NoteEntity.fetchRequestForNote(withId: note.id)
                    let existingEntities = try context.fetch(request)

                    if let existingEntity = existingEntities.first {
                        // Update existing entity
                        self.updateEntity(existingEntity, with: updatedNote)
                    } else {
                        // Create new entity
                        _ = updatedNote.toEntity(in: context)
                    }

                    try context.save()
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func saveNotes(_ notes: [Note]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.performBackgroundTask { context in
                do {
                    for note in notes {
                        let updatedNote = Note(
                            id: note.id,
                            title: note.title,
                            content: note.content,
                            color: note.color,
                            position: note.position,
                            size: note.size,
                            createdAt: note.createdAt,
                            modifiedAt: Date(),
                            isMarkdown: note.isMarkdown,
                            isLocked: note.isLocked,
                            tags: note.tags
                        )

                        let request = NoteEntity.fetchRequestForNote(withId: note.id)
                        let existingEntities = try context.fetch(request)

                        if let existingEntity = existingEntities.first {
                            self.updateEntity(existingEntity, with: updatedNote)
                        } else {
                            _ = updatedNote.toEntity(in: context)
                        }
                    }

                    try context.save()
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func updateEntity(_ entity: NoteEntity, with note: Note) {
        entity.title = note.title
        entity.content = note.content
        entity.color = note.color.rawValue
        entity.positionX = note.position.x
        entity.positionY = note.position.y
        entity.width = note.size.width
        entity.height = note.size.height
        entity.modifiedAt = note.modifiedAt
        entity.isMarkdown = note.isMarkdown
        entity.isLocked = note.isLocked
        entity.tags = note.tags as NSObject
    }

    // MARK: - Delete Operations

    public func deleteNote(withId id: UUID) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.performBackgroundTask { context in
                do {
                    let request = NoteEntity.fetchRequestForNote(withId: id)
                    let entities = try context.fetch(request)

                    if let entity = entities.first {
                        context.delete(entity)
                        try context.save()
                    }
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func deleteNotes(withIds ids: [UUID]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.performBackgroundTask { context in
                do {
                    for id in ids {
                        let request = NoteEntity.fetchRequestForNote(withId: id)
                        let entities = try context.fetch(request)

                        if let entity = entities.first {
                            context.delete(entity)
                        }
                    }

                    try context.save()
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Utility Operations

    public func updateNoteModificationDate(forId id: UUID) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.performBackgroundTask { context in
                do {
                    let request = NoteEntity.fetchRequestForNote(withId: id)
                    let entities = try context.fetch(request)

                    if let entity = entities.first {
                        entity.modifiedAt = Date()
                        try context.save()
                    }
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func notesCount() async throws -> Int {
        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.performBackgroundTask { context in
                do {
                    let request = NoteEntity.fetchRequest()
                    let count = try context.count(for: request)
                    continuation.resume(returning: count)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func noteExists(withId id: UUID) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.performBackgroundTask { context in
                do {
                    let request = NoteEntity.fetchRequestForNote(withId: id)
                    let count = try context.count(for: request)
                    continuation.resume(returning: count > 0)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}