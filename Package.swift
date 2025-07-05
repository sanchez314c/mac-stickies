// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StickyNotes",
    platforms: [
        .macOS(.v12) // Support macOS 12+ for broader compatibility
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .executable(
            name: "StickyNotes",
            targets: ["StickyNotes"]
        ),
        .library(
            name: "StickyNotesCore",
            targets: ["StickyNotesCore"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // Using minimal dependencies for a clean, focused library
        // Add any external dependencies here as needed
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "StickyNotes",
            dependencies: ["StickyNotesCore"],
            path: "Sources/StickyNotes",
            exclude: [
                "Models/Note+CoreData.swift",
                "Models/Note.swift",
                "Models/NoteColor.swift",
                "Views/NoteWindowView.swift",
                "Views/RichTextEditor.swift",
                "Views/FloatingNoteWindow.swift",
                "ViewModels/NotesViewModel.swift",
                "ViewModels/NoteViewModel.swift",
                "Services/CoreDataPersistenceService.swift",
                "Services/CacheService.swift",
                "CoreData/",
                "Services/",
                "StickyNotesCommands.swift"
            ]
        ),
        .target(
            name: "StickyNotesCore",
            dependencies: [],
            path: "Sources",
            exclude: [
                // Exclude app-specific files
                "StickyNotes/"
            ]
        ),
        .testTarget(
            name: "StickyNotesCoreTests",
            dependencies: ["StickyNotesCore"],
            path: "Tests",
            sources: ["StickyNotesCoreTests.swift"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)