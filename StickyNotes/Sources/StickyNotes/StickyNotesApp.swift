//
//  StickyNotesApp.swift
//  StickyNotes
//
//  Created by SuperClaude
//  Copyright © 2024 SuperClaude. All rights reserved.
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
        .commands {
            StickyNotesCommands()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure floating windows and macOS integration
        configureApplication()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep app running with floating windows
    }

    private func configureApplication() {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Application cleanup
    }
}