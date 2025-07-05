//
//  Note.swift
//  StickyNotes
//
//  Created by SuperClaude
//  Copyright © 2024 SuperClaude. All rights reserved.
//

import CoreData
import Foundation

@objc(Note)
public class Note: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var content: String
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var color: String
    @NSManaged public var isPinned: Bool
    @NSManaged public var category: String?
    @NSManaged public var tags: [String]?
    @NSManaged public var positionX: Double
    @NSManaged public var positionY: Double
    @NSManaged public var width: Double
    @NSManaged public var height: Double

    override public func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        createdAt = Date()
        updatedAt = Date()
        color = "#FFE4B5" // Default light orange color
        isPinned = false
        tags = []
        positionX = 100
        positionY = 100
        width = 300
        height = 200
    }

    // Removed willSave to prevent infinite recursion during testing
    // updatedAt is set in awakeFromInsert and can be updated manually
}

extension Note {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Note> {
        return NSFetchRequest<Note>(entityName: "Note")
    }

    public var tagsArray: [String] {
        get {
            return tags ?? []
        }
        set {
            tags = newValue
        }
    }

    // Validation methods
    func validateTitle() throws {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyTitle
        }
        guard title.count <= 200 else {
            throw ValidationError.titleTooLong
        }
    }

    func validateContent() throws {
        guard content.count <= 10000 else {
            throw ValidationError.contentTooLong
        }
    }

    // Computed properties
    var displayTitle: String {
        return title.isEmpty ? "Untitled Note" : title
    }

    var previewContent: String {
        let maxLength = 150
        if content.count <= maxLength {
            return content
        }
        let endIndex = content.index(content.startIndex, offsetBy: maxLength)
        return String(content[..<endIndex]) + "..."
    }

    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }

    var formattedUpdatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: updatedAt)
    }

    var position: CGPoint {
        get { CGPoint(x: positionX, y: positionY) }
        set {
            positionX = Double(newValue.x)
            positionY = Double(newValue.y)
        }
    }

    var size: CGSize {
        get { CGSize(width: width, height: height) }
        set {
            width = Double(newValue.width)
            height = Double(newValue.height)
        }
    }
}

enum ValidationError: LocalizedError {
    case emptyTitle
    case titleTooLong
    case contentTooLong

    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "Note title cannot be empty"
        case .titleTooLong:
            return "Note title cannot exceed 200 characters"
        case .contentTooLong:
            return "Note content cannot exceed 10,000 characters"
        }
    }
}
