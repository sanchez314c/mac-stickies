//
//  Note+CoreData.swift
//  StickyNotes
//
//  Core Data model for optimized performance
//

import Foundation
import CoreData
import SwiftUI

@objc(NoteEntity)
public class NoteEntity: NSManagedObject {
    // All @NSManaged properties must be optional — Core Data may have nil values
    // during migration, faulting, or model mismatch. Non-optional types crash at runtime.
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var contentData: Data?
    @NSManaged public var colorRawValue: String?
    @NSManaged public var positionX: Double
    @NSManaged public var positionY: Double
    @NSManaged public var sizeWidth: Double
    @NSManaged public var sizeHeight: Double
    @NSManaged public var createdAt: Date?
    @NSManaged public var modifiedAt: Date?
    @NSManaged public var isMarkdown: Bool
    @NSManaged public var searchIndex: String? // For fast searching

    // Computed properties for compatibility
    var note: Note {
        get {
            let resolvedId = id ?? UUID()
            let resolvedTitle = title ?? ""
            let resolvedColor = colorRawValue.flatMap { NoteColor(rawValue: $0) } ?? .yellow
            let position = CGPoint(x: positionX, y: positionY)
            let size = CGSize(width: sizeWidth, height: sizeHeight)
            let resolvedCreatedAt = createdAt ?? Date()
            let resolvedModifiedAt = modifiedAt ?? Date()

            // Deserialize content efficiently; fall back to empty on any error
            let content: NSAttributedString
            if let data = contentData, !data.isEmpty {
                content = (try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil))
                          ?? NSAttributedString(string: "")
            } else {
                content = NSAttributedString(string: "")
            }

            return Note(id: resolvedId, title: resolvedTitle, content: content, color: resolvedColor,
                       position: position, size: size, createdAt: resolvedCreatedAt,
                       modifiedAt: resolvedModifiedAt, isMarkdown: isMarkdown)
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

            // Serialize content efficiently; store empty Data on failure rather than crashing
            if let data = try? newValue.content.data(
                from: NSRange(location: 0, length: newValue.content.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
            ) {
                contentData = data
            } else {
                contentData = Data()
                print("Warning: Failed to serialize RTF content for note \(newValue.id)")
            }

            // Update search index for fast queries
            updateSearchIndex()
        }
    }

    private func updateSearchIndex() {
        // Create searchable text combining title and plain text content
        let plainText: String
        if let data = contentData, !data.isEmpty {
            plainText = (try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil))?.string ?? ""
        } else {
            plainText = ""
        }
        searchIndex = ((title ?? "") + " " + plainText).lowercased()
    }
}

extension NoteEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<NoteEntity> {
        return NSFetchRequest<NoteEntity>(entityName: "NoteEntity")
    }
    // Self-referential relationship stubs removed — NoteEntity has no note relationships.
}

// MARK: - Identifiable
extension NoteEntity : Identifiable {}