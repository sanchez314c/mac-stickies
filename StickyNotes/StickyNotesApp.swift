//
//  StickyNotesApp.swift
//  StickyNotes
//
//  Created on 2025-01-21
//
//  NOTE: This is the Xcode target entry point.
//  The SPM-based entry point is Sources/StickyNotes/StickyNotesApp.swift.
//  Only one of these should be included in the active build target.
//  The Xcode xcodeproj target uses this file.
//

import SwiftUI

@main
struct StickyNotesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep app running even when all windows are closed (floating note windows may remain)
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Save any pending changes before exit
        WindowManager.shared.closeAllNoteWindows()
    }
}
