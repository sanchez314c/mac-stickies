# Documentation Index

StickyNotes Desktop — macOS sticky notes app. Swift 5.10, SwiftUI, Core Data, CloudKit.

**Author:** Jason Paul Michaels
**GitHub:** https://github.com/sanchez314c/desktop-stickies

## All Docs

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | System design, layer diagram, data model, concurrency model, window management |
| [INSTALLATION.md](INSTALLATION.md) | Prerequisites, clone, build, run, configuration |
| [DEVELOPMENT.md](DEVELOPMENT.md) | Dev environment setup, build commands, test commands, code style, debugging |
| [API.md](API.md) | StickyNotesCore public API: Note, NoteService, NoteRepository, PersistenceController, BackgroundOperationManager, error types, extensions |
| [BUILD_COMPILE.md](BUILD_COMPILE.md) | Xcode and SPM build commands, universal binary, archive, distribution, Fastlane lanes, CI workflows |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Distribution channels (direct/MAS/TestFlight), Fastlane lanes, environment variables, GitHub Actions release, versioning, rollback |
| [FAQ.md](FAQ.md) | Frequently asked questions about usage, sync, and data |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Common issues and solutions: startup failures, sync problems, performance, migration |
| [TECHSTACK.md](TECHSTACK.md) | Complete tech stack reference: frameworks, patterns, persistence, concurrency, build tools |
| [WORKFLOW.md](WORKFLOW.md) | Git branching, commit conventions, PR process, release process, testing strategy |
| [QUICK_START.md](QUICK_START.md) | Get the app running in under 5 minutes |
| [LEARNINGS.md](LEARNINGS.md) | Technical and process lessons from building the app |
| [PRD.md](PRD.md) | Product requirements document: vision, audience, feature spec, acceptance criteria |
| [TODO.md](TODO.md) | Planned features, backlog, and in-progress work |

## Subdirectories

Detailed reference docs are organized in:

- `docs/architecture/` — architecture overview and data model deep dives
- `docs/developer/` — API reference, contributing guide, code style
- `docs/deployment/` — CI/CD setup, deployment guides, verification steps
- `docs/installation/` — installation guide, system requirements
- `docs/maintenance/` — backup/recovery, monitoring, security
- `docs/testing/` — testing strategy, performance benchmarks
- `docs/user/` — user guide, features, keyboard shortcuts, troubleshooting

## Key Source Files

| File | Purpose |
|------|---------|
| `Package.swift` | SPM manifest — StickyNotes + StickyNotesCore targets |
| `StickyNotes/StickyNotes.xcodeproj` | Xcode project for the macOS app |
| `Sources/Persistence/PersistenceController.swift` | Core Data stack + CloudKit sync |
| `Sources/Services/NoteService.swift` | High-level CRUD + Combine publishers |
| `Sources/Services/NoteRepository.swift` | NoteRepository protocol + CoreDataNoteRepository |
| `StickyNotes/Views/ContentView.swift` | Main window UI |
| `StickyNotes/Views/NoteWindowView.swift` | Floating sticky note window |
| `StickyNotes/Services/WindowManager.swift` | NSWindow lifecycle + StickyNoteWindow |
| `StickyNotes/Services/CacheService.swift` | LRU cache for previews and rendered content |
| `fastlane/Fastfile` | Distribution automation |
| `.github/workflows/ci.yml` | CI quality gates |
