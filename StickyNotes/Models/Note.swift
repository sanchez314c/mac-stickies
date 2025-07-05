//
//  Note.swift
//  StickyNotes
//
//  Created on 2025-01-21
//

import Foundation
import SwiftUI

struct Note: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var content: NSAttributedString
    var color: NoteColor
    var position: CGPoint
    var size: CGSize
    var createdAt: Date
    var modifiedAt: Date
    var isMarkdown: Bool
    var isLocked: Bool
    var tags: [String]

    init(id: UUID = UUID(),
         title: String = "New Note",
         content: NSAttributedString = NSAttributedString(string: ""),
         color: NoteColor = .yellow,
         position: CGPoint = .zero,
         size: CGSize = CGSize(width: 300, height: 200),
         createdAt: Date = Date(),
         modifiedAt: Date = Date(),
         isMarkdown: Bool = false,
         isLocked: Bool = false,
         tags: [String] = []) {
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

    // Computed properties
    var displayTitle: String {
        title.isEmpty ? "Untitled" : title
    }

    var previewText: String {
        let plainText = content.string
        return plainText.isEmpty ? "Empty note" : String(plainText.prefix(100))
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Note, rhs: Note) -> Bool {
        lhs.id == rhs.id
    }

    // Codable conformance for NSAttributedString
    enum CodingKeys: String, CodingKey {
        case id, title, color, position, size, createdAt, modifiedAt, isMarkdown, isLocked, tags, contentData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        color = try container.decode(NoteColor.self, forKey: .color)
        position = try container.decode(CGPoint.self, forKey: .position)
        size = try container.decode(CGSize.self, forKey: .size)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        modifiedAt = try container.decode(Date.self, forKey: .modifiedAt)
        isMarkdown = try container.decode(Bool.self, forKey: .isMarkdown)
        isLocked = try container.decodeIfPresent(Bool.self, forKey: .isLocked) ?? false
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []

        let contentData = try container.decode(Data.self, forKey: .contentData)
        if let decoded = try? NSAttributedString(data: contentData,
                                                 options: [.documentType: NSAttributedString.DocumentType.rtf],
                                                 documentAttributes: nil) {
            content = decoded
        } else {
            // Log failure — silently falling back means rich text content is permanently lost
            print("Warning: Failed to decode RTF content for note, falling back to empty content.")
            content = NSAttributedString(string: "")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(color, forKey: .color)
        try container.encode(position, forKey: .position)
        try container.encode(size, forKey: .size)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(modifiedAt, forKey: .modifiedAt)
        try container.encode(isMarkdown, forKey: .isMarkdown)
        try container.encode(isLocked, forKey: .isLocked)
        try container.encode(tags, forKey: .tags)

        let contentData = try content.data(from: NSRange(location: 0, length: content.length),
                                          documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        try container.encode(contentData, forKey: .contentData)
    }
}