//
//  BackgroundOperationManager.swift
//  StickyNotes
//
//  Created on 2025-01-21.
//

import Combine
import Foundation

/// Manages background operations for long-running tasks
public final class BackgroundOperationManager {
    public static let shared = BackgroundOperationManager()

    private let operationQueue: OperationQueue
    private let persistenceController: PersistenceController
    private let repository: NoteRepository

    // Publishers for operation status
    public let operationStatusPublisher = PassthroughSubject<OperationStatus, Never>()
    public let operationProgressPublisher = PassthroughSubject<OperationProgress, Never>()

    private var activeOperations = [UUID: BackgroundOperation]()

    private init() {
        operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 2 // Limit concurrent operations
        operationQueue.qualityOfService = .background

        persistenceController = .shared
        repository = CoreDataNoteRepository(persistenceController: persistenceController)
    }

    // MARK: - Bulk Operations

    /// Import notes from JSON data
    @discardableResult
    public func importNotes(from jsonData: Data, operationId: UUID = UUID()) -> UUID {
        let operation = ImportNotesOperation(
            jsonData: jsonData,
            persistenceController: persistenceController,
            operationId: operationId
        )

        operation.completionBlock = { [weak self] in
            self?.handleOperationCompletion(operationId: operationId, operation: operation)
        }

        addOperation(operation, withId: operationId)
        return operationId
    }

    /// Export all notes to JSON
    @discardableResult
    public func exportNotes(to url: URL, operationId: UUID = UUID()) -> UUID {
        let operation = ExportNotesOperation(
            exportURL: url,
            persistenceController: persistenceController,
            operationId: operationId
        )

        operation.completionBlock = { [weak self] in
            self?.handleOperationCompletion(operationId: operationId, operation: operation)
        }

        addOperation(operation, withId: operationId)
        return operationId
    }

    /// Bulk update notes (simplified implementation)
    @discardableResult
    public func bulkUpdateNotes(
        updates: [UUID: NoteUpdate],
        operationId: UUID = UUID()
    ) -> UUID {
        // For now, perform updates synchronously
        // TODO: Implement proper background operation
        Task {
            do {
                for (noteId, update) in updates {
                    if var note = try await self.repository.fetchNote(withId: noteId) {
                        if let title = update.title { note.title = title }
                        if let content = update.content { note.content = content }
                        if let color = update.color { note.color = color }
                        if let position = update.position { note.position = position }
                        if let size = update.size { note.size = size }
                        if let isMarkdown = update.isMarkdown { note.isMarkdown = isMarkdown }
                        if let isLocked = update.isLocked { note.isLocked = isLocked }
                        if let tags = update.tags { note.tags = tags }

                        try await self.repository.saveNote(note)
                    }
                }
                self.operationStatusPublisher.send(.completed(operationId, updates.count))
            } catch {
                self.operationStatusPublisher.send(.failed(operationId, error))
            }
        }
        return operationId
    }

    /// Search and replace across all notes (simplified implementation)
    @discardableResult
    public func searchAndReplace(
        searchText: String,
        replacementText: String,
        operationId: UUID = UUID()
    ) -> UUID {
        // For now, perform search and replace synchronously
        // TODO: Implement proper background operation
        Task {
            do {
                let notes = try await self.repository.fetchNotes()
                var updatedCount = 0

                for var note in notes {
                    if note.content.contains(searchText) {
                        note.content = note.content.replacingOccurrences(of: searchText, with: replacementText)
                        note.modifiedAt = Date()
                        try await self.repository.saveNote(note)
                        updatedCount += 1
                    }
                }

                self.operationStatusPublisher.send(.completed(operationId, updatedCount))
            } catch {
                self.operationStatusPublisher.send(.failed(operationId, error))
            }
        }
        return operationId
    }

    /// Duplicate multiple notes (simplified implementation)
    @discardableResult
    public func duplicateNotes(noteIds: [UUID], operationId: UUID = UUID()) -> UUID {
        // For now, perform duplication synchronously
        // TODO: Implement proper background operation
        Task {
            do {
                var duplicatedNotes: [Note] = []

                for noteId in noteIds {
                    if let originalNote = try await self.repository.fetchNote(withId: noteId) {
                        let duplicate = Note(
                            title: "\(originalNote.title) Copy",
                            content: originalNote.content,
                            color: originalNote.color,
                            position: CGPoint(x: originalNote.position.x + 20, y: originalNote.position.y + 20),
                            size: originalNote.size,
                            isMarkdown: originalNote.isMarkdown,
                            tags: originalNote.tags
                        )

                        try await self.repository.saveNote(duplicate)
                        duplicatedNotes.append(duplicate)
                    }
                }

                self.operationStatusPublisher.send(.completed(operationId, duplicatedNotes))
            } catch {
                self.operationStatusPublisher.send(.failed(operationId, error))
            }
        }
        return operationId
    }

    // MARK: - Operation Management

    private func addOperation(_ operation: BackgroundOperation, withId id: UUID) {
        activeOperations[id] = operation
        operationQueue.addOperation(operation)

        operationStatusPublisher.send(.started(id))

        // Monitor progress if operation supports it
        if let progressOperation = operation as? ProgressReportingOperation {
            progressOperation.progressHandler = { [weak self] progress in
                self?.operationProgressPublisher.send(OperationProgress(
                    operationId: id,
                    completed: progress.completed,
                    total: progress.total,
                    description: progress.description
                ))
            }
        }
    }

    /// Cancel operation
    public func cancelOperation(withId id: UUID) {
        if let operation = activeOperations[id] {
            operation.cancel()
            activeOperations.removeValue(forKey: id)
            operationStatusPublisher.send(.cancelled(id))
        }
    }

    /// Cancel all operations
    public func cancelAllOperations() {
        operationQueue.cancelAllOperations()
        let cancelledIds = Array(activeOperations.keys)
        activeOperations.removeAll()

        for id in cancelledIds {
            operationStatusPublisher.send(.cancelled(id))
        }
    }

    /// Get active operations count
    public var activeOperationsCount: Int {
        activeOperations.count
    }

    /// Check if operation is active
    public func isOperationActive(_ id: UUID) -> Bool {
        activeOperations[id] != nil
    }

    private func handleOperationCompletion(operationId: UUID, operation: BackgroundOperation) {
        activeOperations.removeValue(forKey: operationId)

        if operation.isCancelled {
            operationStatusPublisher.send(.cancelled(operationId))
        } else if let error = operation.error {
            operationStatusPublisher.send(.failed(operationId, error))
        } else {
            operationStatusPublisher.send(.completed(operationId, operation.result))
        }
    }

    // MARK: - Cleanup

    deinit {
        cancelAllOperations()
    }
}

// MARK: - Supporting Types

public protocol BackgroundOperation: Operation {
    var operationId: UUID { get }
    var error: Error? { get }
    var result: Any? { get }
}

public protocol ProgressReportingOperation: BackgroundOperation {
    var progressHandler: ((ProgressUpdate) -> Void)? { get set }
}

public struct ProgressUpdate {
    public let completed: Int
    public let total: Int
    public let description: String
}

public struct OperationStatus {
    public let operationId: UUID
    public let type: StatusType
    public let result: Any?
    public let error: Error?

    public enum StatusType {
        case started
        case completed
        case failed
        case cancelled
    }

    public static func started(_ id: UUID) -> OperationStatus {
        OperationStatus(operationId: id, type: .started, result: nil, error: nil)
    }

    public static func completed(_ id: UUID, _ result: Any?) -> OperationStatus {
        OperationStatus(operationId: id, type: .completed, result: result, error: nil)
    }

    public static func failed(_ id: UUID, _ error: Error) -> OperationStatus {
        OperationStatus(operationId: id, type: .failed, result: nil, error: error)
    }

    public static func cancelled(_ id: UUID) -> OperationStatus {
        OperationStatus(operationId: id, type: .cancelled, result: nil, error: nil)
    }
}

public struct OperationProgress {
    public let operationId: UUID
    public let completed: Int
    public let total: Int
    public let description: String
}

public struct NoteUpdate {
    public let title: String?
    public let content: String?
    public let color: NoteColor?
    public let position: CGPoint?
    public let size: CGSize?
    public let isMarkdown: Bool?
    public let isLocked: Bool?
    public let tags: [String]?

    public init(
        title: String? = nil,
        content: String? = nil,
        color: NoteColor? = nil,
        position: CGPoint? = nil,
        size: CGSize? = nil,
        isMarkdown: Bool? = nil,
        isLocked: Bool? = nil,
        tags: [String]? = nil
    ) {
        self.title = title
        self.content = content
        self.color = color
        self.position = position
        self.size = size
        self.isMarkdown = isMarkdown
        self.isLocked = isLocked
        self.tags = tags
    }
}
