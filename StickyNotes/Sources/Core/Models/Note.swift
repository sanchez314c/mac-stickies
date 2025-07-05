//
//  Note.swift
//  StickyNotes
//
//  Created on 2025-01-21.
//

import Foundation
import CoreData
import CoreGraphics

/// Represents a sticky note with all its properties
public struct Note: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var content: String
    public var color: NoteColor
    public var position: CGPoint
    public var size: CGSize
    public var createdAt: Date
    public var modifiedAt: Date
    public var isMarkdown: Bool
    public var isLocked: Bool
    public var tags: [String]

    public init(
        id: UUID = UUID(),
        title: String = "",
        content: String = "",
        color: NoteColor = .yellow,
        position: CGPoint = .zero,
        size: CGSize = CGSize(width: 300, height: 200),
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        isMarkdown: Bool = false,
        isLocked: Bool = false,
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.color = color
        self.position = position
        self.size = size
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.isMarkdown = isMarkdown
        self.isLocked = isLocked
        self.tags = tags
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Note, rhs: Note) -> Bool {
        lhs.id == rhs.id
    }
}

/// Color options for sticky notes
public enum NoteColor: String, Codable, CaseIterable {
    case yellow
    case blue
    case green
    case pink
    case purple
    case gray

    public var displayName: String {
        switch self {
        case .yellow: return "Yellow"
        case .blue: return "Blue"
        case .green: return "Green"
        case .pink: return "Pink"
        case .purple: return "Purple"
        case .gray: return "Gray"
        }
    }

    public var colorValue: (red: Double, green: Double, blue: Double, alpha: Double) {
        switch self {
        case .yellow: return (1.0, 0.95, 0.6, 1.0)
        case .blue: return (0.7, 0.9, 1.0, 1.0)
        case .green: return (0.8, 1.0, 0.7, 1.0)
        case .pink: return (1.0, 0.8, 0.9, 1.0)
        case .purple: return (0.9, 0.8, 1.0, 1.0)
        case .gray: return (0.9, 0.9, 0.9, 1.0)
        }
    }
}

/// Core Data entity extension for Note
extension Note {
    init?(from entity: NoteEntity) {
        guard let id = entity.id,
              let title = entity.title,
              let content = entity.content,
              let colorRaw = entity.color,
              let color = NoteColor(rawValue: colorRaw),
              let createdAt = entity.createdAt,
              let modifiedAt = entity.modifiedAt else {
            return nil
        }

        self.id = id
        self.title = title
        self.content = content
        self.color = color
        self.position = CGPoint(x: entity.positionX, y: entity.positionY)
        self.size = CGSize(width: entity.width, height: entity.height)
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.isMarkdown = entity.isMarkdown
        self.isLocked = entity.isLocked
        self.tags = (entity.tags as? [String]) ?? []
    }

    func toEntity(in context: NSManagedObjectContext) -> NoteEntity {
        let entity = NoteEntity(context: context)
        entity.id = id
        entity.title = title
        entity.content = content
        entity.color = color.rawValue
        entity.positionX = position.x
        entity.positionY = position.y
        entity.width = size.width
        entity.height = size.height
        entity.createdAt = createdAt
        entity.modifiedAt = modifiedAt
        entity.isMarkdown = isMarkdown
        entity.isLocked = isLocked
        entity.tags = tags as NSObject

        return entity
    }
}