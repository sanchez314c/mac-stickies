//
//  BackgroundOperations.swift
//  StickyNotes
//
//  Created on 2025-01-21.
//

import Foundation

// MARK: - Import Notes Operation

class ImportNotesOperation: Operation, BackgroundOperation {
    let operationId: UUID
    private let jsonData: Data
    private let persistenceController: PersistenceController

    private(set) var error: Error?
    private(set) var result: Any?

    init(jsonData: Data, persistenceController: PersistenceController, operationId: UUID) {
        self.jsonData = jsonData
        self.persistenceController = persistenceController
        self.operationId = operationId
        super.init()
        self.qualityOfService = .background
    }

    override func main() {
        guard !isCancelled else { return }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let notes = try decoder.decode([Note].self, from: jsonData)

            guard !isCancelled else { return }

            // Import notes in batches to avoid memory issues
            let batchSize = 50
            var importedCount = 0

            let batches = stride(from: 0, to: notes.count, by: batchSize).map {
                Array(notes[$0..<min($0 + batchSize, notes.count)])
            }
            for batch in batches {
                guard !isCancelled else { return }

                persistenceController.performBackgroundTask { context in
                    do {
                        for note in batch {
                            let entity = note.toEntity(in: context)
                            // Ensure created/modified dates are preserved
                            entity.createdAt = note.createdAt
                            entity.modifiedAt = note.modifiedAt
                        }
                        try context.save()
                    } catch {
                        // Handle error in background operation
                        print("Error importing notes batch: \(error)")
                    }
                }

                importedCount += batch.count
            }

            result = importedCount

        } catch {
            self.error = error
        }
    }
}

// MARK: - Export Notes Operation

class ExportNotesOperation: Operation, BackgroundOperation, ProgressReportingOperation {
    let operationId: UUID
    private let exportURL: URL
    private let persistenceController: PersistenceController

    private(set) var error: Error?
    private(set) var result: Any?
    var progressHandler: ((ProgressUpdate) -> Void)?

    init(exportURL: URL, persistenceController: PersistenceController, operationId: UUID) {
        self.exportURL = exportURL
        self.persistenceController = persistenceController
        self.operationId = operationId
        super.init()
        self.qualityOfService = .background
    }

    override func main() {
        guard !isCancelled else { return }

        do {
            // Fetch all notes
            var allNotes = [Note]()
            persistenceController.performBackgroundTask { context in
                do {
                    let request = NoteEntity.fetchRequestSortedByModifiedDate()
                    let entities = try context.fetch(request)
                    allNotes = entities.compactMap { Note(from: $0) }
                } catch {
                    print("Error fetching notes for export: \(error)")
                }
            }

            guard !isCancelled else { return }

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted

            let jsonData = try encoder.encode(allNotes)

            guard !isCancelled else { return }

            try jsonData.write(to: exportURL, options: .atomic)

            result = exportURL

        } catch {
            self.error = error
        }
    }
}