// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StickyNotes",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "StickyNotes", targets: ["StickyNotes"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        // Core Data targets
        .target(
            name: "StickyNotesCore",
            dependencies: [],
            path: "Sources/Core"
        ),
        .executableTarget(
            name: "StickyNotes",
            dependencies: ["StickyNotesCore"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "StickyNotesTests",
            dependencies: ["StickyNotes"],
            path: "Tests/StickyNotesTests"
        ),
        .testTarget(
            name: "StickyNotesIntegrationTests",
            dependencies: ["StickyNotes", "StickyNotesCore"],
            path: "Tests/StickyNotesIntegrationTests",
            swiftSettings: [.define("TEST")]
        ),
        // Temporarily disabled UI and performance tests for integration testing
        // .testTarget(
        //     name: "StickyNotesUITests",
        //     dependencies: ["StickyNotes"],
        //     path: "Tests/StickyNotesUITests"
        // ),
        // .testTarget(
        //     name: "StickyNotesPerformanceTests",
        //     dependencies: ["StickyNotes"],
        //     path: "Tests/StickyNotesPerformanceTests"
        // )
    ]
)