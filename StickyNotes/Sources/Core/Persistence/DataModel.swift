//
//  DataModel.swift
//  StickyNotes
//
//  Created on 2025-01-21.
//

import Foundation
import CoreData

/// Utility class for setting up the Core Data model
public final class DataModel {
    /// Create and return the managed object model
    public static func makeManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // Create Note entity
        let noteEntity = NSEntityDescription()
        noteEntity.name = "Note"
        noteEntity.managedObjectClassName = "Note"

        // Create attributes
        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = false

        let titleAttribute = NSAttributeDescription()
        titleAttribute.name = "title"
        titleAttribute.attributeType = .stringAttributeType
        titleAttribute.isOptional = false
        titleAttribute.defaultValue = ""

        let contentAttribute = NSAttributeDescription()
        contentAttribute.name = "content"
        contentAttribute.attributeType = .stringAttributeType
        contentAttribute.isOptional = false
        contentAttribute.defaultValue = ""

        let colorAttribute = NSAttributeDescription()
        colorAttribute.name = "color"
        colorAttribute.attributeType = .stringAttributeType
        colorAttribute.isOptional = false
        colorAttribute.defaultValue = NoteColor.yellow.rawValue

        let positionXAttribute = NSAttributeDescription()
        positionXAttribute.name = "positionX"
        positionXAttribute.attributeType = .doubleAttributeType
        positionXAttribute.isOptional = false
        positionXAttribute.defaultValue = 0.0

        let positionYAttribute = NSAttributeDescription()
        positionYAttribute.name = "positionY"
        positionYAttribute.attributeType = .doubleAttributeType
        positionYAttribute.isOptional = false
        positionYAttribute.defaultValue = 0.0

        let widthAttribute = NSAttributeDescription()
        widthAttribute.name = "width"
        widthAttribute.attributeType = .doubleAttributeType
        widthAttribute.isOptional = false
        widthAttribute.defaultValue = 300.0

        let heightAttribute = NSAttributeDescription()
        heightAttribute.name = "height"
        heightAttribute.attributeType = .doubleAttributeType
        heightAttribute.isOptional = false
        heightAttribute.defaultValue = 200.0

        let createdAtAttribute = NSAttributeDescription()
        createdAtAttribute.name = "createdAt"
        createdAtAttribute.attributeType = .dateAttributeType
        createdAtAttribute.isOptional = false

        let updatedAtAttribute = NSAttributeDescription()
        updatedAtAttribute.name = "updatedAt"
        updatedAtAttribute.attributeType = .dateAttributeType
        updatedAtAttribute.isOptional = false

        let isMarkdownAttribute = NSAttributeDescription()
        isMarkdownAttribute.name = "isMarkdown"
        isMarkdownAttribute.attributeType = .booleanAttributeType
        isMarkdownAttribute.isOptional = false
        isMarkdownAttribute.defaultValue = false

        let isPinnedAttribute = NSAttributeDescription()
        isPinnedAttribute.name = "isPinned"
        isPinnedAttribute.attributeType = .booleanAttributeType
        isPinnedAttribute.isOptional = false
        isPinnedAttribute.defaultValue = false

        let categoryAttribute = NSAttributeDescription()
        categoryAttribute.name = "category"
        categoryAttribute.attributeType = .stringAttributeType
        categoryAttribute.isOptional = true

        let isLockedAttribute = NSAttributeDescription()
        isLockedAttribute.name = "isLocked"
        isLockedAttribute.attributeType = .booleanAttributeType
        isLockedAttribute.isOptional = false
        isLockedAttribute.defaultValue = false

        let tagsAttribute = NSAttributeDescription()
        tagsAttribute.name = "tags"
        tagsAttribute.attributeType = .transformableAttributeType
        tagsAttribute.isOptional = true
        tagsAttribute.valueTransformerName = "NSSecureUnarchiveFromDataTransformer"

        // Add attributes to entity
        noteEntity.properties = [
            idAttribute,
            titleAttribute,
            contentAttribute,
            colorAttribute,
            positionXAttribute,
            positionYAttribute,
            widthAttribute,
            heightAttribute,
            createdAtAttribute,
            updatedAtAttribute,
            isPinnedAttribute,
            categoryAttribute,
            isMarkdownAttribute,
            isLockedAttribute,
            tagsAttribute
        ]

        // Set entity to model
        model.entities = [noteEntity]

        return model
    }

    /// Load the model from a compiled .momd file if available, otherwise create programmatically
    public static func loadModel() -> NSManagedObjectModel {
        // Try to load from bundle first (for production)
        if let modelURL = Bundle.main.url(forResource: "StickyNotes", withExtension: "momd"),
           let model = NSManagedObjectModel(contentsOf: modelURL) {
            return model
        }

        // Fallback to programmatic model creation (for testing)
        return makeManagedObjectModel()
    }
}