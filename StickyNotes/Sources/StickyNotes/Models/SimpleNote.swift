//
//  SimpleNote.swift
//  StickyNotes
//
//  Created for demo purposes
//

import SwiftUI

class SimpleNote: Identifiable, ObservableObject, Hashable {
    let id = UUID()
    @Published var title: String
    @Published var content: String
    @Published var color: String
    @Published var position: CGPoint
    @Published var size: CGSize
    @Published var createdAt: Date
    @Published var updatedAt: Date

    init(title: String = "New Note",
         content: String = "",
         color: String = "#FFE4B5",
         position: CGPoint = CGPoint(x: 100, y: 100),
         size: CGSize = CGSize(width: 300, height: 200)) {
        self.title = title
        self.content = content
        self.color = color
        self.position = position
        self.size = size
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var displayTitle: String {
        title.isEmpty ? "Untitled Note" : title
    }

    var previewContent: String {
        let maxLength = 150
        if content.count <= maxLength {
            return content
        }
        let endIndex = content.index(content.startIndex, offsetBy: maxLength)
        return String(content[..<endIndex]) + "..."
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SimpleNote, rhs: SimpleNote) -> Bool {
        lhs.id == rhs.id
    }
}