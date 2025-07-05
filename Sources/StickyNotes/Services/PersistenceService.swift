//
//  PersistenceService.swift
//  StickyNotes
//
//  Created on 2025-01-21
//

import Combine
import Foundation
import SwiftUI

enum ExportFormat {
    case text
    case markdown
    case json
    case pdf
}

enum PersistenceMode {
    case coreData
    case fileBased
}

class PersistenceService: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading = false
    @Published var error: Error?

    private let mode: PersistenceMode
    private let notesDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // Core Data dependencies (when available)
    private var coreDataService: NoteService?
    private var cancellables = Set<AnyCancellable>()

    init(mode: PersistenceMode = .coreData) {
        self.mode = mode

        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        notesDirectory = appSupport.appendingPathComponent("StickyNotes")

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: notesDirectory, withIntermediateDirectories: true)

        // Configure JSON encoder/decoder
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        decoder.dateDecodingStrategy = .iso8601

        setupCoreDataIfAvailable()
        loadNotes()
    }

    private func setupCoreDataIfAvailable() {
        if mode == .coreData {
            // Try to initialize Core Data service
            // This will be available when StickyNotesCore is linked
            do {
                coreDataService = NoteService.shared
                setupCoreDataObservers()
            } catch {
                print("Core Data not available, falling back to file-based storage")
                // Will use file-based storage as fallback
            }
        }
    }

    private func setupCoreDataObservers() {
        coreDataService?.notesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notes in
                // Convert Core Data notes to SwiftUI notes
                self?.notes = notes.map { coreDataNote in
                    Note(
                        id: coreDataNote.id,
                        title: coreDataNote.title,
                        content: NSAttributedString(string: coreDataNote.content),
                        color: coreDataNote.color,
                        position: coreDataNote.position,
                        size: coreDataNote.size,
                        createdAt: coreDataNote.createdAt,
                        modifiedAt: coreDataNote.modifiedAt,
                        isMarkdown: coreDataNote.isMarkdown,
                        isLocked: coreDataNote.isLocked,
                        tags: coreDataNote.tags
                    )
                }
                self?.isLoading = false
            }
            .store(in: &cancellables)

        coreDataService?.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.error = error
                self?.isLoading = false
            }
            .store(in: &cancellables)
    }

    // MARK: - CRUD Operations

    private func loadNotes() {
        isLoading = true
        error = nil

        Task {
            do {
                if let coreDataService = coreDataService, mode == .coreData {
                    // Use Core Data
                    let coreDataNotes = try await coreDataService.getAllNotes()
                    await MainActor.run {
                        self.notes = coreDataNotes.map { coreDataNote in
                            Note(
                                id: coreDataNote.id,
                                title: coreDataNote.title,
                                content: NSAttributedString(string: coreDataNote.content),
                                color: coreDataNote.color,
                                position: coreDataNote.position,
                                size: coreDataNote.size,
                                createdAt: coreDataNote.createdAt,
                                modifiedAt: coreDataNote.modifiedAt,
                                isMarkdown: coreDataNote.isMarkdown,
                                isLocked: coreDataNote.isLocked,
                                tags: coreDataNote.tags
                            )
                        }
                        self.isLoading = false
                    }
                } else {
                    // Use file-based storage
                    let fileURLs = try FileManager.default.contentsOfDirectory(
                        at: notesDirectory,
                        includingPropertiesForKeys: nil
                    ).filter { $0.pathExtension == "json" }

                    var notes: [Note] = []

                    for url in fileURLs {
                        do {
                            let data = try Data(contentsOf: url)
                            let note = try decoder.decode(Note.self, from: data)
                            notes.append(note)
                        } catch {
                            print("Failed to decode note at \(url): \(error)")
                        }
                    }

                    await MainActor.run {
                        self.notes = notes.sorted { $0.modifiedAt > $1.modifiedAt }
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }

    func fetchNotes() async throws -> [Note] {
        if let coreDataService = coreDataService, mode == .coreData {
            let coreDataNotes = try await coreDataService.getAllNotes()
            return coreDataNotes.map { coreDataNote in
                Note(
                    id: coreDataNote.id,
                    title: coreDataNote.title,
                    content: NSAttributedString(string: coreDataNote.content),
                    color: coreDataNote.color,
                    position: coreDataNote.position,
                    size: coreDataNote.size,
                    createdAt: coreDataNote.createdAt,
                    modifiedAt: coreDataNote.modifiedAt,
                    isMarkdown: coreDataNote.isMarkdown,
                    isLocked: coreDataNote.isLocked,
                    tags: coreDataNote.tags
                )
            }
        } else {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: notesDirectory,
                includingPropertiesForKeys: nil
            ).filter { $0.pathExtension == "json" }

            var notes: [Note] = []

            for url in fileURLs {
                do {
                    let data = try Data(contentsOf: url)
                    let note = try decoder.decode(Note.self, from: data)
                    notes.append(note)
                } catch {
                    print("Failed to decode note at \(url): \(error)")
                }
            }

            return notes.sorted { $0.modifiedAt > $1.modifiedAt }
        }
    }

    func saveNote(_ note: Note) async throws {
        if let coreDataService = coreDataService, mode == .coreData {
            // Convert SwiftUI note to Core Data note
            let coreDataNote = StickyNotesCore.Note(
                id: note.id,
                title: note.title,
                content: note.content.string,
                color: note.color,
                position: note.position,
                size: note.size,
                createdAt: note.createdAt,
                modifiedAt: note.modifiedAt,
                isMarkdown: note.isMarkdown,
                isLocked: note.isLocked,
                tags: note.tags
            )
            try await coreDataService.updateNote(coreDataNote)
        } else {
            // Use file-based storage
            let fileName = "\(note.id.uuidString).json"
            let fileURL = notesDirectory.appendingPathComponent(fileName)

            let data = try encoder.encode(note)
            try data.write(to: fileURL, options: .atomic)
        }

        // Refresh local notes
        loadNotes()
    }

    func createNote(title: String = "New Note",
                    content: NSAttributedString = NSAttributedString(string: ""),
                    color: NoteColor = .yellow) async throws -> Note
    {
        let note = Note(title: title, content: content, color: color)

        if let coreDataService = coreDataService, mode == .coreData {
            let coreDataNote = StickyNotesCore.Note(
                id: note.id,
                title: note.title,
                content: note.content.string,
                color: note.color,
                position: note.position,
                size: note.size,
                createdAt: note.createdAt,
                modifiedAt: note.modifiedAt,
                isMarkdown: note.isMarkdown,
                isLocked: note.isLocked,
                tags: note.tags
            )
            try await coreDataService.updateNote(coreDataNote)
        } else {
            try await saveNote(note)
        }

        loadNotes()
        return note
    }

    func deleteNote(id: UUID) async throws {
        if let coreDataService = coreDataService, mode == .coreData {
            try await coreDataService.deleteNote(withId: id)
        } else {
            let fileName = "\(id.uuidString).json"
            let fileURL = notesDirectory.appendingPathComponent(fileName)

            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        }

        loadNotes()
    }

    func updateNotePosition(id: UUID, position: CGPoint) async throws {
        if let coreDataService = coreDataService, mode == .coreData {
            try await coreDataService.updateNotePosition(id: id, position: position)
        } else {
            // For file-based storage, we need to load, update, and save
            var notes = try await fetchNotes()
            if let index = notes.firstIndex(where: { $0.id == id }) {
                notes[index].position = position
                try await saveNote(notes[index])
            }
        }
    }

    func updateNoteSize(id: UUID, size: CGSize) async throws {
        if let coreDataService = coreDataService, mode == .coreData {
            try await coreDataService.updateNoteSize(id: id, size: size)
        } else {
            // For file-based storage, we need to load, update, and save
            var notes = try await fetchNotes()
            if let index = notes.firstIndex(where: { $0.id == id }) {
                notes[index].size = size
                try await saveNote(notes[index])
            }
        }
    }

    // MARK: - Export

    func exportNote(_ note: Note, format: ExportFormat) async throws -> URL {
        let fileName: String
        let data: Data

        switch format {
        case .text:
            fileName = "\(note.displayTitle).txt"
            data = note.content.string.data(using: .utf8) ?? Data()

        case .markdown:
            fileName = "\(note.displayTitle).md"
            let markdownContent = convertToMarkdown(note)
            data = markdownContent.data(using: .utf8) ?? Data()

        case .json:
            fileName = "\(note.displayTitle).json"
            data = try encoder.encode(note)

        case .pdf:
            return try await exportAsPDF(note)
        }

        let exportURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: exportURL)
        return exportURL
    }

    private func convertToMarkdown(_ note: Note) -> String {
        var markdown = ""

        if !note.title.isEmpty {
            markdown += "# \(note.title)\n\n"
        }

        // Convert attributed string to markdown
        // This is a simplified conversion - in a real app you'd want more sophisticated conversion
        let plainText = note.content.string
        markdown += plainText

        return markdown
    }

    private func exportAsPDF(_ note: Note) async throws -> URL {
        // Create a simple PDF from the note content
        let fileName = "\(note.displayTitle).pdf"
        let pdfURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        // This is a simplified PDF creation - in a real app you'd use PDFKit
        let pdfData = createPDFData(from: note)
        try pdfData.write(to: pdfURL)

        return pdfURL
    }

    private func createPDFData(from note: Note) -> Data {
        // Simplified PDF creation - in practice you'd use PDFKit or similar
        let content = """
        Title: \(note.title)
        Created: \(note.createdAt)
        Modified: \(note.modifiedAt)

        \(note.content.string)
        """

        return content.data(using: .utf8) ?? Data()
    }

    // MARK: - Backup and Restore

    func createBackup() async throws -> URL {
        let backupName = "StickyNotes_Backup_\(Date().timeIntervalSince1970).zip"
        let backupURL = FileManager.default.temporaryDirectory.appendingPathComponent(backupName)

        // Create a zip archive of the notes directory
        // This is simplified - in practice you'd use a proper archiving library
        try FileManager.default.copyItem(at: notesDirectory, to: backupURL)

        return backupURL
    }

    func restoreFromBackup(_ backupURL: URL) async throws {
        let fileManager = FileManager.default

        // Clear existing notes
        let existingFiles = try fileManager.contentsOfDirectory(at: notesDirectory, includingPropertiesForKeys: nil)
        for file in existingFiles {
            try fileManager.removeItem(at: file)
        }

        // Copy backup files
        let backupFiles = try fileManager.contentsOfDirectory(at: backupURL, includingPropertiesForKeys: nil)
        for file in backupFiles where file.pathExtension == "json" {
            let destination = notesDirectory.appendingPathComponent(file.lastPathComponent)
            try fileManager.copyItem(at: file, to: destination)
        }
    }
}
