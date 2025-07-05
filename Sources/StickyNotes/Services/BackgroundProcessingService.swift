//
//  BackgroundProcessingService.swift
//  StickyNotes
//
//  Background processing for heavy operations
//

import Combine
import Foundation

class BackgroundProcessingService {
    static let shared = BackgroundProcessingService()

    private let processingQueue = DispatchQueue(label: "com.stickynotes.background", qos: .background)
    private let operationQueue = OperationQueue()
    private var cancellables = Set<AnyCancellable>()

    private init() {
        operationQueue.maxConcurrentOperationCount = 2
        operationQueue.qualityOfService = .background
    }

    // MARK: - Content Processing

    func processNoteContent(_ note: Note, completion: @escaping (ProcessedNoteContent) -> Void) {
        let operation = ContentProcessingOperation(note: note, completion: completion)
        operationQueue.addOperation(operation)
    }

    func batchProcessNotes(_ notes: [Note], completion: @escaping ([ProcessedNoteContent]) -> Void) {
        let operation = BatchContentProcessingOperation(notes: notes, completion: completion)
        operationQueue.addOperation(operation)
    }

    // MARK: - Search Indexing

    func updateSearchIndex(for notes: [Note]) {
        let operation = SearchIndexingOperation(notes: notes)
        operationQueue.addOperation(operation)
    }

    // MARK: - Export Processing

    func exportNotes(_ notes: [Note], format: ExportFormat, completion: @escaping (Result<URL, Error>) -> Void) {
        let operation = ExportOperation(notes: notes, format: format, completion: completion)
        operationQueue.addOperation(operation)
    }

    // MARK: - Migration

    func performMigration(from oldService: PersistenceService, completion: @escaping (Result<Void, Error>) -> Void) {
        let operation = MigrationOperation(oldService: oldService, completion: completion)
        operationQueue.addOperation(operation)
    }

    // MARK: - Cache Warming

    func warmCache(for notes: [Note]) {
        let operation = CacheWarmingOperation(notes: notes)
        operationQueue.addOperation(operation)
    }

    // MARK: - Queue Management

    func cancelAllOperations() {
        operationQueue.cancelAllOperations()
    }

    func waitForAllOperations() {
        operationQueue.waitUntilAllOperationsAreFinished()
    }

    var operationCount: Int {
        operationQueue.operationCount
    }
}

// MARK: - Operation Classes

class ContentProcessingOperation: Operation {
    let note: Note
    let completion: (ProcessedNoteContent) -> Void

    init(note: Note, completion: @escaping (ProcessedNoteContent) -> Void) {
        self.note = note
        self.completion = completion
        super.init()
        qualityOfService = .background
    }

    override func main() {
        guard !isCancelled else { return }

        // Process content in background
        let wordCount = note.content.string.split(separator: " ").count
        let characterCount = note.content.string.count
        let hasLinks = note.content.string.contains("http") || note.content.string.contains("https")

        let processed = ProcessedNoteContent(
            noteId: note.id,
            wordCount: wordCount,
            characterCount: characterCount,
            hasLinks: hasLinks,
            processedAt: Date()
        )

        DispatchQueue.main.async {
            self.completion(processed)
        }
    }
}

class BatchContentProcessingOperation: Operation {
    let notes: [Note]
    let completion: ([ProcessedNoteContent]) -> Void

    init(notes: [Note], completion: @escaping ([ProcessedNoteContent]) -> Void) {
        self.notes = notes
        self.completion = completion
        super.init()
        qualityOfService = .background
    }

    override func main() {
        guard !isCancelled else { return }

        var results: [ProcessedNoteContent] = []

        for note in notes {
            guard !isCancelled else { return }

            let wordCount = note.content.string.split(separator: " ").count
            let characterCount = note.content.string.count
            let hasLinks = note.content.string.contains("http") || note.content.string.contains("https")

            let processed = ProcessedNoteContent(
                noteId: note.id,
                wordCount: wordCount,
                characterCount: characterCount,
                hasLinks: hasLinks,
                processedAt: Date()
            )

            results.append(processed)
        }

        DispatchQueue.main.async {
            self.completion(results)
        }
    }
}

class SearchIndexingOperation: Operation {
    let notes: [Note]

    init(notes: [Note]) {
        self.notes = notes
        super.init()
        qualityOfService = .background
    }

    override func main() {
        guard !isCancelled else { return }

        // Update search indexes in Core Data
        Task {
            for note in notes {
                guard !isCancelled else { return }
                do {
                    try await CoreDataPersistenceService.shared.saveNote(note)
                } catch {
                    print("Failed to update search index for note \(note.id): \(error)")
                }
            }
        }
    }
}

class ExportOperation: Operation {
    let notes: [Note]
    let format: ExportFormat
    let completion: (Result<URL, Error>) -> Void

    init(notes: [Note], format: ExportFormat, completion: @escaping (Result<URL, Error>) -> Void) {
        self.notes = notes
        self.format = format
        self.completion = completion
        super.init()
        qualityOfService = .background
    }

    override func main() {
        guard !isCancelled else { return }

        do {
            // Create temporary directory for export
            let tempDir = FileManager.default.temporaryDirectory
            let exportDir = tempDir.appendingPathComponent("StickyNotes_Export_\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true)

            // Export each note
            for note in notes {
                guard !isCancelled else { return }

                let persistenceService = CoreDataPersistenceService.shared
                let exportURL = try await persistenceService.exportNote(note, format: format)

                // Move to export directory
                let fileName = "\(note.displayTitle).\(format.fileExtension)"
                let finalURL = exportDir.appendingPathComponent(fileName)
                try FileManager.default.moveItem(at: exportURL, to: finalURL)
            }

            // Create zip archive
            let zipURL = tempDir.appendingPathComponent("StickyNotes_Export.zip")
            try createZipArchive(from: exportDir, to: zipURL)

            // Clean up
            try FileManager.default.removeItem(at: exportDir)

            DispatchQueue.main.async {
                self.completion(.success(zipURL))
            }
        } catch {
            DispatchQueue.main.async {
                self.completion(.failure(error))
            }
        }
    }

    private func createZipArchive(from sourceURL: URL, to destinationURL: URL) throws {
        // Simplified zip creation - in practice you'd use a proper archiving library
        let coordinator = NSFileCoordinator()
        var error: NSError?

        coordinator.coordinate(readingItemAt: sourceURL, options: .forUploading, error: &error) { zipURL in
            do {
                try FileManager.default.copyItem(at: zipURL, to: destinationURL)
            } catch {
                print("Failed to create zip archive: \(error)")
            }
        }

        if let error = error {
            throw error
        }
    }
}

class MigrationOperation: Operation {
    let oldService: PersistenceService
    let completion: (Result<Void, Error>) -> Void

    init(oldService: PersistenceService, completion: @escaping (Result<Void, Error>) -> Void) {
        self.oldService = oldService
        self.completion = completion
        super.init()
        qualityOfService = .background
    }

    override func main() {
        guard !isCancelled else { return }

        Task {
            do {
                try await CoreDataPersistenceService.shared.migrateFromJSON()
                DispatchQueue.main.async {
                    self.completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    self.completion(.failure(error))
                }
            }
        }
    }
}

class CacheWarmingOperation: Operation {
    let notes: [Note]

    init(notes: [Note]) {
        self.notes = notes
        super.init()
        qualityOfService = .background
    }

    override func main() {
        guard !isCancelled else { return }

        let cacheService = CacheService.shared

        for note in notes {
            guard !isCancelled else { return }

            // Pre-render preview
            let preview = NotePreview(
                title: note.displayTitle,
                previewText: note.previewText,
                color: note.color,
                lastModified: note.modifiedAt
            )
            cacheService.cachePreview(for: note, preview: preview)

            // Pre-render content if needed
            let renderedContent = RenderedNoteContent(
                attributedString: note.content,
                renderedSize: CGSize(width: 300, height: 200), // Approximate size
                lastModified: note.modifiedAt
            )
            cacheService.cacheRenderedContent(for: note, content: renderedContent)
        }
    }
}

// MARK: - Supporting Types

struct ProcessedNoteContent {
    let noteId: UUID
    let wordCount: Int
    let characterCount: Int
    let hasLinks: Bool
    let processedAt: Date
}

extension ExportFormat {
    var fileExtension: String {
        switch self {
        case .text: return "txt"
        case .markdown: return "md"
        case .json: return "json"
        case .pdf: return "pdf"
        }
    }
}
