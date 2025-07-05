//
//  CoreDataPersistenceService.swift
//  StickyNotes
//
//  Optimized Core Data persistence with batch operations and lazy loading
//

import Foundation
import CoreData
import SwiftUI
import Combine

class CoreDataPersistenceService {
    static let shared = CoreDataPersistenceService()

    // MARK: - Core Data Stack
    private let persistentContainer: NSPersistentContainer
    private let backgroundContext: NSManagedObjectContext

    private init() {
        persistentContainer = NSPersistentContainer(name: "StickyNotesModel")

        // Configure persistent store
        let storeDescription = NSPersistentStoreDescription()
        storeDescription.type = NSSQLiteStoreType
        storeDescription.shouldMigrateStoreAutomatically = true
        storeDescription.shouldInferMappingModelAutomatically = true

        // Enable lightweight migration
        storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

        persistentContainer.persistentStoreDescriptions = [storeDescription]

        persistentContainer.loadPersistentStores { [weak self] (storeDescription, error) in
            if let error = error {
                // Log the error. Do not fatalError — the app can still run without persistence
                // and the user's data is preserved for manual recovery.
                print("ERROR: Core Data store failed to load: \(error.localizedDescription)")
                print("Store URL: \(String(describing: storeDescription.url))")
                // Fall through — the container will have no store, all operations will throw.
                return
            }
            // Configure contexts for performance
            self?.configureContexts()
        }

        backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    private func configureContexts() {
        // Configure main context for UI responsiveness
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        persistentContainer.viewContext.undoManager = nil // Disable undo for performance
    }

    // MARK: - Batch Operations
    func fetchNotesBatch(offset: Int = 0, limit: Int = 50, searchText: String? = nil, colorFilter: NoteColor? = nil) async throws -> [Note] {
        return try await backgroundContext.perform {
            let fetchRequest = NoteEntity.fetchRequest()
            fetchRequest.fetchOffset = offset
            fetchRequest.fetchLimit = limit

            // Sort by modified date (most recent first)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "modifiedAt", ascending: false)]

            // Apply filters
            var predicates: [NSPredicate] = []

            if let searchText = searchText, !searchText.isEmpty {
                let searchPredicate = NSPredicate(format: "searchIndex CONTAINS[cd] %@", searchText.lowercased())
                predicates.append(searchPredicate)
            }

            if let colorFilter = colorFilter {
                let colorPredicate = NSPredicate(format: "colorRawValue == %@", colorFilter.rawValue)
                predicates.append(colorPredicate)
            }

            if !predicates.isEmpty {
                fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            }

            let entities = try self.backgroundContext.fetch(fetchRequest)
            return entities.map { $0.note }
        }
    }

    func fetchAllNotesMetadata() async throws -> [NoteMetadata] {
        return try await backgroundContext.perform {
            let fetchRequest = NoteEntity.fetchRequest()
            fetchRequest.propertiesToFetch = ["id", "title", "colorRawValue", "modifiedAt", "createdAt"]
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "modifiedAt", ascending: false)]

            let entities = try self.backgroundContext.fetch(fetchRequest)
            return entities.map { entity in
                NoteMetadata(
                    id: entity.id,
                    title: entity.title,
                    color: NoteColor(rawValue: entity.colorRawValue) ?? .yellow,
                    modifiedAt: entity.modifiedAt,
                    createdAt: entity.createdAt
                )
            }
        }
    }

    func saveNote(_ note: Note) async throws {
        try await backgroundContext.perform {
            // Check if entity exists
            let fetchRequest = NoteEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", note.id as CVarArg)
            fetchRequest.fetchLimit = 1

            let existingEntity = try self.backgroundContext.fetch(fetchRequest).first

            if let entity = existingEntity {
                // Update existing
                entity.note = note
            } else {
                // Create new
                let entity = NoteEntity(context: self.backgroundContext)
                entity.note = note
            }

            try self.backgroundContext.save()
        }
    }

    func deleteNote(id: UUID) async throws {
        try await backgroundContext.perform {
            let fetchRequest = NoteEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

            let entities = try self.backgroundContext.fetch(fetchRequest)
            entities.forEach { self.backgroundContext.delete($0) }

            try self.backgroundContext.save()
        }
    }

    func batchSaveNotes(_ notes: [Note]) async throws {
        try await backgroundContext.perform {
            for note in notes {
                let fetchRequest = NoteEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", note.id as CVarArg)
                fetchRequest.fetchLimit = 1

                let existingEntity = try self.backgroundContext.fetch(fetchRequest).first

                if let entity = existingEntity {
                    entity.note = note
                } else {
                    let entity = NoteEntity(context: self.backgroundContext)
                    entity.note = note
                }
            }

            try self.backgroundContext.save()
        }
    }

    // MARK: - Migration from JSON
    func migrateFromJSON() async throws {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let notesDirectory = appSupport.appendingPathComponent("StickyNotes")

        guard fileManager.fileExists(atPath: notesDirectory.path) else { return }

        let jsonFiles = try fileManager.contentsOfDirectory(
            at: notesDirectory,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }

        var notes: [Note] = []

        for url in jsonFiles {
            do {
                let data = try Data(contentsOf: url)
                let note = try JSONDecoder().decode(Note.self, from: data)
                notes.append(note)
            } catch {
                print("Failed to decode note from \(url): \(error)")
            }
        }

        // Batch save to Core Data
        try await batchSaveNotes(notes)

        // Backup old files
        let backupURL = notesDirectory.appendingPathComponent("backup_\(Date().timeIntervalSince1970)")
        try fileManager.moveItem(at: notesDirectory, to: backupURL)

        print("Migration completed: \(notes.count) notes migrated")
    }

    // MARK: - Statistics
    func fetchStatistics() async throws -> NoteStatistics {
        return try await backgroundContext.perform {
            let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "NoteEntity")
            fetchRequest.resultType = .dictionaryResultType

            // Count by color
            fetchRequest.propertiesToGroupBy = ["colorRawValue"]
            fetchRequest.propertiesToFetch = ["colorRawValue", "@count.id as count"]
            let colorStats = try self.backgroundContext.fetch(fetchRequest)

            var notesByColor: [NoteColor: Int] = [:]
            for stat in colorStats {
                if let colorRaw = stat["colorRawValue"] as? String,
                   let color = NoteColor(rawValue: colorRaw),
                   let count = stat["count"] as? Int {
                    notesByColor[color] = count
                }
            }

            // Total count
            let countRequest = NSFetchRequest<NSNumber>(entityName: "NoteEntity")
            countRequest.resultType = .countResultType
            let totalCount = try self.backgroundContext.count(for: countRequest)

            return NoteStatistics(totalNotes: totalCount, notesByColor: notesByColor)
        }
    }

    // MARK: - Search Optimization
    func searchNotes(query: String, limit: Int = 50) async throws -> [Note] {
        return try await backgroundContext.perform {
            let fetchRequest = NoteEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "searchIndex CONTAINS[cd] %@", query.lowercased())
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "modifiedAt", ascending: false)]
            fetchRequest.fetchLimit = limit

            let entities = try self.backgroundContext.fetch(fetchRequest)
            return entities.map { $0.note }
        }
    }
}

// MARK: - Supporting Types
struct NoteMetadata: Identifiable, Hashable {
    let id: UUID
    let title: String
    let color: NoteColor
    let modifiedAt: Date
    let createdAt: Date

    var displayTitle: String {
        title.isEmpty ? "Untitled" : title
    }
}

struct NoteStatistics {
    let totalNotes: Int
    let notesByColor: [NoteColor: Int]
}