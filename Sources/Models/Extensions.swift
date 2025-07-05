//
//  Extensions.swift
//  StickyNotes
//
//  Created on 2025-01-21.
//

import CoreGraphics
import Foundation

// MARK: - CGPoint Extensions

extension CGPoint {
    /// Creates a CGPoint from a string representation
    init?(string: String) {
        let components = string
            .replacingOccurrences(of: "{", with: "")
            .replacingOccurrences(of: "}", with: "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        guard components.count == 2,
              let x = Double(components[0]),
              let y = Double(components[1])
        else {
            return nil
        }

        self.init(x: x, y: y)
    }

    /// String representation of the point
    var stringValue: String {
        "{x=\(x), y=\(y)}"
    }
}

// MARK: - CGSize Extensions

extension CGSize {
    /// Creates a CGSize from a string representation
    init?(string: String) {
        let components = string
            .replacingOccurrences(of: "{", with: "")
            .replacingOccurrences(of: "}", with: "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        guard components.count == 2,
              let width = Double(components[0]),
              let height = Double(components[1])
        else {
            return nil
        }

        self.init(width: width, height: height)
    }

    /// String representation of the size
    var stringValue: String {
        "{width=\(width), height=\(height)}"
    }
}

// MARK: - Date Extensions

extension Date {
    /// ISO 8601 formatted string
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }

    /// Relative time string (e.g., "2 hours ago")
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Short date string
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - String Extensions

extension String {
    /// Truncates the string to the specified length with ellipsis
    func truncated(to length: Int, trailing: String = "...") -> String {
        guard count > length else { return self }
        return String(prefix(length - trailing.count)) + trailing
    }

    /// Checks if the string contains only whitespace
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Word count
    var wordCount: Int {
        let words = components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }

    /// Estimated reading time in minutes
    var estimatedReadingTime: Double {
        let wordsPerMinute = 200.0
        return Double(wordCount) / wordsPerMinute
    }
}

// MARK: - Array Extensions

extension Array where Element == Note {
    /// Sort notes by modification date (newest first)
    func sortedByModifiedDate() -> [Note] {
        sorted { $0.modifiedAt > $1.modifiedAt }
    }

    /// Sort notes by creation date (newest first)
    func sortedByCreatedDate() -> [Note] {
        sorted { $0.createdAt > $1.createdAt }
    }

    /// Sort notes by title alphabetically
    func sortedByTitle() -> [Note] {
        sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    /// Filter notes by color
    func filtered(by color: NoteColor) -> [Note] {
        filter { $0.color == color }
    }

    /// Filter notes containing text in title or content
    func filtered(containing text: String) -> [Note] {
        guard !text.isEmpty else { return self }
        let lowercasedText = text.lowercased()
        return filter {
            $0.title.lowercased().contains(lowercasedText) ||
                $0.content.lowercased().contains(lowercasedText)
        }
    }

    /// Filter notes by tags
    func filtered(byTags tags: [String]) -> [Note] {
        guard !tags.isEmpty else { return self }
        return filter { note in
            !Set(tags).isDisjoint(with: Set(note.tags))
        }
    }

    /// Group notes by color
    func groupedByColor() -> [NoteColor: [Note]] {
        Dictionary(grouping: self) { $0.color }
    }

    /// Group notes by tags
    func groupedByTags() -> [String: [Note]] {
        var result = [String: [Note]]()
        for note in self {
            for tag in note.tags {
                result[tag, default: []].append(note)
            }
        }
        return result
    }
}

// MARK: - Note Extensions

extension Note {
    /// Check if note contains text in title or content
    func contains(_ text: String) -> Bool {
        guard !text.isEmpty else { return true }
        let lowercasedText = text.lowercased()
        return title.lowercased().contains(lowercasedText) ||
            content.lowercased().contains(lowercasedText)
    }

    /// Check if note has specific tag
    func hasTag(_ tag: String) -> Bool {
        tags.contains(tag)
    }

    /// Check if note has any of the specified tags
    func hasAnyTag(_ tags: [String]) -> Bool {
        !Set(tags).isDisjoint(with: Set(tags))
    }

    /// Summary of the note (first few words)
    var summary: String {
        let words = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        let summaryWords = words.prefix(10)
        return summaryWords.joined(separator: " ") + (words.count > 10 ? "..." : "")
    }

    /// Is note empty (no title and no content)
    var isEmpty: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Character count
    var characterCount: Int {
        content.count
    }

    /// Line count
    var lineCount: Int {
        content.components(separatedBy: .newlines).count
    }
}

// MARK: - NoteColor Extensions

extension NoteColor {
    /// All colors for UI display
    static var allCasesForDisplay: [NoteColor] {
        allCases
    }

    /// Random color
    static var random: NoteColor {
        allCases.randomElement() ?? .yellow
    }

    /// Color name for accessibility
    var accessibilityLabel: String {
        displayName
    }
}

// MARK: - Persistence Error Extensions

extension PersistenceError {
    /// Check if error is recoverable
    var isRecoverable: Bool {
        switch self {
        case .cloudKitError, .syncFailed:
            return true
        case .saveFailed, .fetchFailed, .deleteFailed, .invalidData:
            return false
        }
    }

    /// Suggested recovery action
    var recoverySuggestion: String {
        switch self {
        case .cloudKitError:
            return "Check your iCloud account settings and try again."
        case .syncFailed:
            return "Synchronization failed. Changes will be retried automatically."
        case .saveFailed:
            return "Failed to save changes. Please try again."
        case .fetchFailed:
            return "Failed to load data. Please restart the app."
        case .deleteFailed:
            return "Failed to delete item. Please try again."
        case .invalidData:
            return "Invalid data encountered. Please contact support."
        }
    }
}
