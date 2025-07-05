//
//  Note+CoreData.swift
//  StickyNotes
//
//  Core Data model for optimized performance
//

import CoreData
import Foundation
import SwiftUI

@objc(NoteEntity)
public class NoteEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var contentData: Data
    @NSManaged public var colorRawValue: String
    @NSManaged public var positionX: Double
    @NSManaged public var positionY: Double
    @NSManaged public var sizeWidth: Double
    @NSManaged public var sizeHeight: Double
    @NSManaged public var createdAt: Date
    @NSManaged public var modifiedAt: Date
    @NSManaged public var isMarkdown: Bool
    @NSManaged public var searchIndex: String // For fast searching

    // Computed properties for compatibility
    var note: Note {
        get {
            let color = NoteColor(rawValue: colorRawValue) ?? .yellow
            let position = CGPoint(x: positionX, y: positionY)
            let size = CGSize(width: sizeWidth, height: sizeHeight)

            // Deserialize content efficiently
            let content = (try? NSAttributedString(data: contentData, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil))
                ?? NSAttributedString(string: "")

            return Note(id: id, title: title, content: content, color: color,
                        position: position, size: size, createdAt: createdAt,
                        modifiedAt: modifiedAt, isMarkdown: isMarkdown)
        }
        set {
            id = newValue.id
            title = newValue.title
            colorRawValue = newValue.color.rawValue
            positionX = Double(newValue.position.x)
            positionY = Double(newValue.position.y)
            sizeWidth = Double(newValue.size.width)
            sizeHeight = Double(newValue.size.height)
            createdAt = newValue.createdAt
            modifiedAt = newValue.modifiedAt
            isMarkdown = newValue.isMarkdown

            // Serialize content efficiently
            contentData = (try? newValue.content.data(from: NSRange(location: 0, length: newValue.content.length),
                                                      documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])) ?? Data()

            // Update search index for fast queries
            updateSearchIndex()
        }
    }

    private func updateSearchIndex() {
        // Create searchable text combining title and plain text content
        let plainText = (try? NSAttributedString(data: contentData, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil))?.string ?? ""
        searchIndex = (title + " " + plainText).lowercased()
    }
}

public extension NoteEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<NoteEntity> {
        return NSFetchRequest<NoteEntity>(entityName: "NoteEntity")
    }

    @objc(addNotesObject:)
    @NSManaged func addToNotes(_ value: NoteEntity)

    @objc(removeNotesObject:)
    @NSManaged func removeFromNotes(_ value: NoteEntity)

    @objc(addNotess:)
    @NSManaged func addToNotes(_ values: NSSet)

    @objc(removeNotess:)
    @NSManaged func removeFromNotes(_ values: NSSet)
}

// MARK: - Identifiable

extension NoteEntity: Identifiable {}
