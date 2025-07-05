//
//  MigrationManager.swift
//  StickyNotes
//
//  Created on 2025-01-21.
//

import CoreData
import Foundation

/// Manages Core Data schema migrations
public final class MigrationManager {
    private let storeURL: URL
    private let model: NSManagedObjectModel

    public init(storeURL: URL, model: NSManagedObjectModel) {
        self.storeURL = storeURL
        self.model = model
    }

    /// Check if migration is needed
    public func requiresMigration() -> Bool {
        guard let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(
            ofType: NSSQLiteStoreType,
            at: storeURL,
            options: nil
        ) else {
            // Store doesn't exist, no migration needed
            return false
        }

        return !model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
    }

    /// Perform migration if needed
    public func migrateIfNeeded() throws {
        guard requiresMigration() else { return }

        print("Migration required for store at: \(storeURL)")

        // Create a migration manager
        let migrationManager = try NSMigrationManager(
            sourceModel: sourceModelForStore(),
            destinationModel: model
        )

        // Create temporary store URL for migration
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("MigrationTemp.sqlite")

        // Perform migration
        let mappingModel = NSMappingModel(from: [Bundle.main],
                                          forSourceModel: migrationManager.sourceModel,
                                          destinationModel: model)

        try migrationManager.migrateStore(
            from: storeURL,
            sourceType: NSSQLiteStoreType,
            options: nil,
            with: mappingModel,
            toDestinationURL: tempURL,
            destinationType: NSSQLiteStoreType,
            destinationOptions: nil
        )

        // Replace old store with migrated store
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: storeURL)
        try fileManager.moveItem(at: tempURL, to: storeURL)

        print("Migration completed successfully")
    }

    private func sourceModelForStore() throws -> NSManagedObjectModel {
        let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
            ofType: NSSQLiteStoreType,
            at: storeURL,
            options: nil
        )

        // Try to find a compatible model in the bundle
        let bundle = Bundle.main
        let modelURLs = bundle.urls(forResourcesWithExtension: "mom", subdirectory: nil) ?? []
        let momdURLs = bundle.urls(forResourcesWithExtension: "momd", subdirectory: nil) ?? []

        let allModelURLs = modelURLs + momdURLs

        for url in allModelURLs {
            if let model = NSManagedObjectModel(contentsOf: url),
               model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
            {
                return model
            }
        }

        // If no compatible model found, try to infer from metadata
        return try inferredModelFromMetadata(metadata)
    }

    private func inferredModelFromMetadata(_: [String: Any]) throws -> NSManagedObjectModel {
        // This is a simplified version. In a real app, you'd want more sophisticated
        // model inference based on the entity descriptions in the metadata
        let model = NSManagedObjectModel()

        // For now, return the current model as fallback
        // In production, you'd analyze the metadata to create a compatible source model
        return model
    }

    /// Lightweight migration check (for simple schema changes)
    public func canPerformLightweightMigration() -> Bool {
        guard let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(
            ofType: NSSQLiteStoreType,
            at: storeURL,
            options: nil
        ) else {
            return true // New store
        }

        let sourceModel = NSManagedObjectModel()
        // Configure source model based on metadata...

        return sourceModel.isConfiguration(
            withName: nil,
            compatibleWithStoreMetadata: metadata
        ) && model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
    }
}
