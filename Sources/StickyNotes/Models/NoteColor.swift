//
//  NoteColor.swift
//  StickyNotes
//
//  Created on 2025-01-21
//

import SwiftUI

enum NoteColor: String, Codable, CaseIterable {
    case yellow
    case blue
    case green
    case pink
    case purple
    case orange

    var color: Color {
        switch self {
        case .yellow: return Color(hex: "#FEF08A") // Light yellow
        case .blue: return Color(hex: "#BFDBFE") // Light blue
        case .green: return Color(hex: "#BBF7D0") // Light green
        case .pink: return Color(hex: "#FBCFE8") // Light pink
        case .purple: return Color(hex: "#DDD6FE") // Light purple
        case .orange: return Color(hex: "#FED7AA") // Light orange
        }
    }

    var borderColor: Color {
        switch self {
        case .yellow: return Color(hex: "#EAB308") // Darker yellow
        case .blue: return Color(hex: "#2563EB") // Darker blue
        case .green: return Color(hex: "#16A34A") // Darker green
        case .pink: return Color(hex: "#DB2777") // Darker pink
        case .purple: return Color(hex: "#7C3AED") // Darker purple
        case .orange: return Color(hex: "#EA580C") // Darker orange
        }
    }

    var displayName: String {
        switch self {
        case .yellow: return "Yellow"
        case .blue: return "Blue"
        case .green: return "Green"
        case .pink: return "Pink"
        case .purple: return "Purple"
        case .orange: return "Orange"
        }
    }

    var keyboardShortcut: String {
        switch self {
        case .yellow: return "1"
        case .blue: return "2"
        case .green: return "3"
        case .pink: return "4"
        case .purple: return "5"
        case .orange: return "6"
        }
    }
}

// Extension to create Color from hex string
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
