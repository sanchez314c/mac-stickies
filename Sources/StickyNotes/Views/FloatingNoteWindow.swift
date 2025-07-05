//
//  FloatingNoteWindow.swift
//  StickyNotes
//
//  Created by SuperClaude
//  Copyright © 2024 SuperClaude. All rights reserved.
//

import AppKit
import SwiftUI

struct FloatingNoteWindow: View {
    @ObservedObject var note: SimpleNote
    @State private var isEditing = false
    @State private var editedTitle = ""
    @State private var editedContent = ""

    var body: some View {
        ZStack {
            // Background with note color
            Color(hexString: note.color)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Title bar
                HStack(spacing: 8) {
                    if isEditing {
                        TextField("", text: $editedTitle)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                    } else {
                        Text(note.displayTitle)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Toolbar buttons
                    HStack(spacing: 4) {
                        // Edit/Save button
                        Button {
                            if isEditing {
                                saveChanges()
                            } else {
                                startEditing()
                            }
                        } label: {
                            Image(systemName: isEditing ? "checkmark" : "pencil")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Close button
                        Button {
                            closeWindow()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .opacity(0.7)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))

                // Content area
                ZStack {
                    if isEditing {
                        TextEditor(text: $editedContent)
                            .font(.system(size: 14))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.clear)
                    } else {
                        ScrollView {
                            Text(note.content)
                                .font(.system(size: 14))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
        .frame(width: note.size.width, height: note.size.height)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        .onAppear {
            editedTitle = note.title
            editedContent = note.content
        }
    }

    private func startEditing() {
        editedTitle = note.title
        editedContent = note.content
        isEditing = true
    }

    private func saveChanges() {
        note.title = editedTitle
        note.content = editedContent
        note.updatedAt = Date()
        isEditing = false
    }

    private func closeWindow() {
        // This will be handled by the window controller
        NSApp.keyWindow?.close()
    }
}

// MARK: - Window Management

class NoteWindowManager {
    static let shared = NoteWindowManager()

    private var windows: [NSWindow] = []
    private var windowControllers: [NSWindowController] = []
    private var delegates: [WindowDelegate] = []

    private init() {}

    func showNoteWindow(for note: SimpleNote) {
        // Check if window already exists for this note
        if let existingWindow = windows.first(where: { ($0.contentViewController as? NSHostingController<FloatingNoteWindow>)?.rootView.note.id == note.id }) {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }

        // Create the SwiftUI view
        let noteView = FloatingNoteWindow(note: note)

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
        window.configureAsStickyNote()

        // Create window controller
        let windowController = NSWindowController(window: window)
        windowController.showWindow(nil)

        // Store references
        windows.append(window)
        windowControllers.append(windowController)

        // Set up window delegate to handle position/size updates
        let delegate = WindowDelegate(note: note)
        window.delegate = delegate
        delegates.append(delegate)
    }

    func closeAllWindows() {
        for window in windows {
            window.close()
        }
        windows.removeAll()
        windowControllers.removeAll()
        delegates.removeAll()
    }
}

class WindowDelegate: NSObject, NSWindowDelegate {
    private let note: SimpleNote

    init(note: SimpleNote) {
        self.note = note
    }

    func windowDidMove(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }

        let position = window.frame.origin
        note.position = position
    }

    func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }

        let size = window.frame.size
        note.size = size
    }
}

class StickyNoteWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    func configureAsStickyNote() {
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = true
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenNone]
        minSize = NSSize(width: 200, height: 150)
        maxSize = NSSize(width: 800, height: 600)
    }
}

// MARK: - Color Extension

extension Color {
    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
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
