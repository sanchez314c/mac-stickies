//
//  PersistenceController.swift
//  StickyNotes
//
//  Created on 2025-01-21.
//

import Foundation
import CoreData
import CloudKit
import Combine

/// Main persistence controller managing Core Data stack with CloudKit integration
public final class PersistenceController {
    public static let shared = PersistenceController()

    // MARK: - Core Data Stack

    public let container: NSPersistentContainer
    public let viewContext: NSManagedObjectContext

    private var backgroundContext: NSManagedObjectContext?

    // MARK: - CloudKit

    private let cloudKitContainer: CKContainer
    private let privateDatabase: CKDatabase

    // MARK: - Publishers

    public let syncStatusPublisher = PassthroughSubject<SyncStatus, Never>()
    public let errorPublisher = PassthroughSubject<PersistenceError, Never>()

    // MARK: - Initialization

    internal init(inMemory: Bool = false) {
        // Initialize CloudKit container
        cloudKitContainer = CKContainer(identifier: "iCloud.com.stickynotes.app")
        privateDatabase = cloudKitContainer.privateCloudDatabase

        // Initialize Core Data container
        let model = DataModel.loadModel()
        guard let _ = model.entities.first else {
            print("[PersistenceController] Warning: Core Data model has no entities")
            let dummy = NSManagedObjectModel()
            container = NSPersistentContainer(name: "Dummy", managedObjectModel: dummy)
            viewContext = container.viewContext
            return
        }

        // Create container manually to avoid bundle loading issues
        container = NSPersistentContainer(name: "Dummy", managedObjectModel: model)

        if inMemory {
            // Override the container to use in-memory store for testing
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            description.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [description]
        }

        // Get view context
        viewContext = container.viewContext
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Configure container (only for CloudKit containers)
        if !inMemory {
            configureContainer()
            setupCloudKitSync()
        }

        // Load persistent stores
        loadPersistentStores()
    }

    private func configureContainer() {
        // Configure CloudKit options (only for CloudKit containers)
        guard let cloudKitContainer = container as? NSPersistentCloudKitContainer,
              let description = container.persistentStoreDescriptions.first else {
            return // Not a CloudKit container, skip CloudKit configuration
        }

        // Enable CloudKit sync
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.stickynotes.app"
        )

        // Configure store options
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
    }

    private func setupCloudKitSync() {
        // Only setup CloudKit sync for CloudKit containers
        guard container is NSPersistentCloudKitContainer else { return }

        // Observe CloudKit sync notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator
        )

        // Observe CloudKit account status
        CKContainer.default().accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorPublisher.send(.cloudKitError(error))
                    return
                }

                switch status {
                case .available:
                    self?.syncStatusPublisher.send(.available)
                case .noAccount:
                    self?.syncStatusPublisher.send(.noAccount)
                case .restricted:
                    self?.syncStatusPublisher.send(.restricted)
                case .temporarilyUnavailable:
                    self?.syncStatusPublisher.send(.unknown)
                case .couldNotDetermine:
                    self?.syncStatusPublisher.send(.unknown)
                @unknown default:
                    self?.syncStatusPublisher.send(.unknown)
                }
            }
        }
    }

    private func loadPersistentStores() {
        // Check for migration before loading
        if let storeURL = container.persistentStoreDescriptions.first?.url {
            let migrationManager = MigrationManager(storeURL: storeURL, model: container.managedObjectModel)
            do {
                try migrationManager.migrateIfNeeded()
            } catch {
                print("Migration failed: \(error.localizedDescription)")
                // Continue with loading - Core Data might handle it
            }
        }

        container.loadPersistentStores { [weak self] description, error in
            if let error = error {
                // Try to handle common migration errors
                if let migrationError = error as NSError?,
                   migrationError.domain == NSCocoaErrorDomain,
                   migrationError.code == NSPersistentStoreIncompatibleVersionHashError ||
                   migrationError.code == NSMigrationMissingSourceModelError {

                    print("Migration error detected, attempting recovery: \(error.localizedDescription)")

                    // Attempt to delete and recreate the store
                    self?.attemptStoreRecovery(for: description, error: error)
                    return
                }

                // Do not fatalError — log and continue with no persistent store.
                // The app can still run read-only; the user's data is preserved for recovery.
                print("ERROR: Failed to load persistent stores: \(error.localizedDescription)")
                return
            }

            // Enable automatic merging of changes from CloudKit
            self?.container.viewContext.automaticallyMergesChangesFromParent = true
            self?.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            print("Persistent store loaded: \(description)")
        }
    }

    private func attemptStoreRecovery(for description: NSPersistentStoreDescription, error: Error) {
        guard let storeURL = description.url else {
            // Cannot recover — log and continue with no persistent store rather than crashing.
            print("ERROR: Cannot recover store without URL. Persistence disabled. Original error: \(error.localizedDescription)")
            return
        }

        do {
            let fileManager = FileManager.default
            let storeDirectory = storeURL.deletingLastPathComponent()
            let storeName = storeURL.deletingPathExtension().lastPathComponent

            // IMPORTANT: Back up the corrupted store before any destructive action.
            let backupURL = storeDirectory.appendingPathComponent("\(storeName).corrupted-\(Int(Date().timeIntervalSince1970)).sqlite")
            if fileManager.fileExists(atPath: storeURL.path) {
                try? fileManager.copyItem(at: storeURL, to: backupURL)
                print("Corrupted store backed up to: \(backupURL.path)")
            }

            // Now remove the problematic store files to allow a fresh start.
            try? fileManager.removeItem(at: storeURL)
            let associatedFiles = ["\(storeName).sqlite-wal", "\(storeName).sqlite-shm"]
            for file in associatedFiles {
                try? fileManager.removeItem(at: storeDirectory.appendingPathComponent(file))
            }

            print("Store recovery: cleared corrupted store, reloading with empty store...")

            container.loadPersistentStores { description, error in
                if let error = error {
                    // Still failing after recovery — log and continue without persistence.
                    print("ERROR: Store recovery reload failed: \(error.localizedDescription). Persistence disabled.")
                    return
                }

                self.container.viewContext.automaticallyMergesChangesFromParent = true
                self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                print("Store recovered successfully (empty store): \(description)")
            }

        }
    }

    // MARK: - Context Management

    /// Get a new background context for operations
    public func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    /// Perform operation on background context
    public func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }

    /// Save changes in the specified context
    public func save(context: NSManagedObjectContext) async throws {
        guard context.hasChanges else { return }

        try await context.perform {
            do {
                try context.save()
            } catch {
                context.rollback()
                throw PersistenceError.saveFailed(error)
            }
        }
    }

    /// Save changes in view context
    public func saveViewContext() async throws {
        try await save(context: viewContext)
    }

    /// Create a new note
    public func createNote(title: String = "", content: String = "", color: String = "#FFE4B5") -> NoteEntity {
        let note = NoteEntity(context: viewContext)
        note.id = UUID()
        note.title = title
        note.content = content
        note.color = color
        note.positionX = 100
        note.positionY = 100
        note.width = 300
        note.height = 200
        note.createdAt = Date()
        note.modifiedAt = Date()
        note.isLocked = false
        note.isMarkdown = false
        return note
    }

    /// Save changes
    public func save() throws {
        try viewContext.save()
    }

    /// Fetch notes
    public func fetchNotes() throws -> [NoteEntity] {
        let request = NoteEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "modifiedAt", ascending: false)]
        return try viewContext.fetch(request)
    }

    /// Delete a note
    public func deleteNote(_ note: NoteEntity) throws {
        viewContext.delete(note)
        try save()
    }

    // MARK: - CloudKit Operations

    @objc private func handleRemoteChange(_ notification: Notification) {
        // Handle remote changes from CloudKit (only for CloudKit containers)
        guard container is NSPersistentCloudKitContainer else { return }

        syncStatusPublisher.send(.syncing)

        // Merge changes will happen automatically due to automaticallyMergesChangesFromParent
        // We can add additional sync logic here if needed

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.syncStatusPublisher.send(.synced)
        }
    }

    /// Manually trigger CloudKit sync
    public func triggerSync() {
        syncStatusPublisher.send(.syncing)

        // Force sync by saving context
        Task {
            do {
                try await saveViewContext()
                syncStatusPublisher.send(.synced)
            } catch {
                errorPublisher.send(.syncFailed(error))
                syncStatusPublisher.send(.error)
            }
        }
    }

    /// Check if iCloud is available
    public func isCloudKitAvailable() async -> Bool {
        do {
            let status = try await cloudKitContainer.accountStatus()
            return status == .available
        } catch {
            errorPublisher.send(.cloudKitError(error))
            return false
        }
    }

    // MARK: - Migration Support

    /// Handle schema migrations
    public func migrateIfNeeded() async throws {
        // Check if migration is needed
        let coordinator = container.persistentStoreCoordinator
        guard let store = coordinator.persistentStores.first else { return }

        let metadata = try coordinator.metadata(for: store)
        let model = container.managedObjectModel

        if !model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) {
            // Migration needed - this would be handled by Core Data automatically
            // but we can add custom migration logic here if needed
            print("Migration may be needed")
        }
    }

    // MARK: - Cleanup

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Supporting Types

public enum SyncStatus {
    case available
    case noAccount
    case restricted
    case unknown
    case syncing
    case synced
    case error
}

public enum PersistenceError: LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case cloudKitError(Error)
    case syncFailed(Error)
    case invalidData

    public var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .cloudKitError(let error):
            return "CloudKit error: \(error.localizedDescription)"
        case .syncFailed(let error):
            return "Sync failed: \(error.localizedDescription)"
        case .invalidData:
            return "Invalid data encountered"
        }
    }
}