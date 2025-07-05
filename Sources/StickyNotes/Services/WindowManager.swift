//
//  WindowManager.swift
//  StickyNotes
//
//  Created on 2025-01-21
//

import AppKit
import SwiftUI

class WindowManager: NSObject, NSWindowDelegate {
    static let shared = WindowManager()

    private var noteWindows: [UUID: NSWindow] = [:]
    private var windowControllers: [UUID: NSWindowController] = [:]
    private let persistenceService: PersistenceService

    override private init() {
        persistenceService = PersistenceService()
        super.init()
    }

    // MARK: - Window Creation

    func createNoteWindow(for note: Note) {
        // Check if window already exists
        if let existingWindow = noteWindows[note.id] {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }

        // Create the SwiftUI view
        let noteView = NoteWindowView(note: note)
        let hostingController = NSHostingController(rootView: noteView)

        // Create the window
        let window = StickyNoteWindow(
            contentRect: NSRect(
                x: note.position.x,
                y: note.position.y,
                width: note.size.width,
                height: note.size.height
            ),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )

        window.contentViewController = hostingController
        window.delegate = self
        window.configureAsStickyNote()

        // Create window controller
        let windowController = NSWindowController(window: window)
        windowController.showWindow(nil)

        // Store references
        noteWindows[note.id] = window
        windowControllers[note.id] = windowController

        // Set window level for floating behavior
        window.level = .floating
    }

    func closeNoteWindow(for noteId: UUID) {
        if let window = noteWindows[noteId] {
            window.close()
            noteWindows.removeValue(forKey: noteId)
            windowControllers.removeValue(forKey: noteId)
        }
    }

    func closeAllNoteWindows() {
        for window in noteWindows.values {
            window.close()
        }
        noteWindows.removeAll()
        windowControllers.removeAll()
    }

    // MARK: - Window Positioning

    func positionWindow(for noteId: UUID, at position: CGPoint) {
        if let window = noteWindows[noteId] {
            window.setFrameOrigin(position)
        }
    }

    func resizeWindow(for noteId: UUID, to size: CGSize) {
        if let window = noteWindows[noteId] {
            var frame = window.frame
            frame.size = size
            window.setFrame(frame, display: true)
        }
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }

        // Find the note ID for this window
        if let noteId = noteWindows.first(where: { $0.value == window })?.key {
            noteWindows.removeValue(forKey: noteId)
            windowControllers.removeValue(forKey: noteId)
        }
    }

    func windowDidMove(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }

        // Update note position in the persistence layer
        if let noteId = noteWindows.first(where: { $0.value == window })?.key {
            let position = window.frame.origin
            Task {
                do {
                    try await persistenceService.updateNotePosition(id: noteId, position: position)
                } catch {
                    print("Failed to update note position: \(error)")
                }
            }
        }
    }

    func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }

        // Update note size in the persistence layer
        if let noteId = noteWindows.first(where: { $0.value == window })?.key {
            let size = window.frame.size
            Task {
                do {
                    try await persistenceService.updateNoteSize(id: noteId, size: size)
                } catch {
                    print("Failed to update note size: \(error)")
                }
            }
        }
    }
}

// MARK: - Custom NSWindow Subclass

class StickyNoteWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }

    func configureAsStickyNote() {
        // Configure window appearance
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = true
        titlebarAppearsTransparent = true
        titleVisibility = .hidden

        // Configure window behavior
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenNone]

        // Set minimum size
        minSize = NSSize(width: 200, height: 150)
        maxSize = NSSize(width: 800, height: 600)
    }

    override func mouseDown(with event: NSEvent) {
        // Handle mouse down for dragging
        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        // Handle mouse drag for moving window
        super.mouseDragged(with: event)
    }
}

// MARK: - SwiftUI Integration

extension View {
    func openInStickyNoteWindow(note: Note) -> some View {
        onAppear {
            WindowManager.shared.createNoteWindow(for: note)
        }
    }
}
