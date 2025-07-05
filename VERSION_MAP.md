# VERSION_MAP.md

Maps version tags to their significant changes.

| Version | Date | Swift | macOS Target | Notes |
|---------|------|-------|-------------|-------|
| 1.0.0 | 2024-09-21 | 5.10 | 13.0 | Initial release. SwiftUI UI, Core Data + CloudKit backend, universal binary (arm64 + x86_64), fastlane automation. |
| unreleased | — | 5.10 | 13.0 | Repository standardization, MVVM refactor, batch loading (50 notes/page), LRU cache layer, background operation queue, performance monitor. |

## Build Number Format

`MARKETING_VERSION` (e.g. `1.0.0`) follows Semantic Versioning.
`CURRENT_PROJECT_VERSION` is the Xcode build number, auto-incremented by CI via `agvtool`.

## Package Manifest

`Package.swift` at root declares swift-tools-version 5.10 and requires macOS 12+.
`config/Package.swift` (alternate/legacy) requires macOS 13+.

## Minimum OS Requirements

| Component | Minimum macOS | Minimum Swift |
|-----------|-------------|--------------|
| StickyNotes app | 13.0 (Ventura) | 5.10 |
| StickyNotesCore library | 12.0 (Monterey) | 5.0 |
| CloudKit sync | 13.0 (Ventura) | — |
| NSPersistentCloudKitContainer | 10.15+ | — |
