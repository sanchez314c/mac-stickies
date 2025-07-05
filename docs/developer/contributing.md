# Contributing Guide

Welcome to StickyNotes! This guide explains how to contribute to the project effectively.

## 📋 Table of Contents

- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Contribution](#code-contribution)
- [Testing](#testing)
- [Documentation](#documentation)
- [Issue Reporting](#issue-reporting)
- [Pull Request Process](#pull-request-process)

## 🚀 Getting Started

### Prerequisites

**Required Tools:**
- **macOS**: 12.0+ (Monterey or later)
- **Xcode**: 14.2+ with command line tools
- **Swift**: 5.9+
- **Git**: 2.30+

**Installation:**
```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install development tools
brew install swiftlint
brew install swiftformat
brew install carthage  # if using Carthage for dependencies
```

### Project Setup

1. **Fork the repository** on GitHub
2. **Clone your fork:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/stickynotes.git
   cd stickynotes
   ```

3. **Add upstream remote:**
   ```bash
   git remote add upstream https://github.com/superclaude/stickynotes.git
   ```

4. **Install dependencies:**
   ```bash
   # Using Swift Package Manager
   swift package resolve

   # Or using Carthage (if applicable)
   carthage bootstrap --use-xcframeworks
   ```

5. **Open in Xcode:**
   ```bash
   open StickyNotes.xcodeproj
   ```

6. **Build and run:**
   - Select "StickyNotes" scheme
   - Press `Cmd+R` to build and run

## 🔄 Development Workflow

### Branch Strategy

We use a simplified Git flow:

```
main (protected)
├── feature/feature-name
├── bugfix/bug-description
├── hotfix/critical-fix
└── refactor/refactor-description
```

**Branch Naming:**
```bash
# Features
git checkout -b feature/add-note-templates

# Bug fixes
git checkout -b bugfix/fix-crash-on-empty-note

# Hotfixes (for production issues)
git checkout -b hotfix/fix-data-corruption

# Refactoring
git checkout -b refactor/cleanup-view-models
```

### Commit Convention

We follow conventional commits:

```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Testing
- `chore`: Maintenance

**Examples:**
```bash
# Feature commit
feat(ui): add dark mode toggle to note preferences

- Add toggle switch in preferences window
- Persist dark mode setting in UserDefaults
- Update all views to respect dark mode

Closes #123

# Bug fix commit
fix(core): prevent crash when deleting note during sync

The app would crash if a note was deleted while iCloud sync
was in progress. Added proper state checking before deletion.

Fixes #456

# Documentation commit
docs(api): update NoteService protocol documentation

- Add missing parameter descriptions
- Include usage examples
- Document error conditions
```

### Development Process

1. **Choose an issue** from the [issue tracker](https://github.com/superclaude/stickynotes/issues)
2. **Create a feature branch** from `main`
3. **Implement the feature** following our [code style guide](code-style.md)
4. **Write tests** for your changes
5. **Update documentation** if needed
6. **Run the full test suite**
7. **Submit a pull request**

## 💻 Code Contribution

### Code Standards

All code must follow our [code style guide](code-style.md):

- **SwiftLint**: Code must pass all lint checks
- **SwiftFormat**: Code must be properly formatted
- **Documentation**: All public APIs must be documented
- **Testing**: Code must have appropriate test coverage

**Pre-commit checks:**
```bash
# Run linting
swiftlint lint --strict

# Run formatting check
swiftformat --lint --verbose .

# Run tests
swift test
```

### Architecture Guidelines

**Follow MVVM-C Pattern:**
- **Models**: Data structures and business logic
- **ViewModels**: UI state and user interactions
- **Views**: SwiftUI components
- **Coordinator**: Navigation and flow control

**Dependency Injection:**
```swift
// ✅ Good - Injectable dependencies
class NoteViewModel {
    private let noteService: NoteServiceProtocol
    private let analytics: AnalyticsServiceProtocol

    init(
        noteService: NoteServiceProtocol = NoteService.shared,
        analytics: AnalyticsServiceProtocol = AnalyticsService.shared
    ) {
        self.noteService = noteService
        self.analytics = analytics
    }
}

// ❌ Bad - Hardcoded dependencies
class NoteViewModel {
    private let noteService = NoteService.shared  // Tightly coupled
}
```

### Error Handling

**Use typed errors:**
```swift
enum NoteError: LocalizedError {
    case invalidTitle(String)
    case saveFailed(Error)
    case networkError

    var errorDescription: String? {
        switch self {
        case .invalidTitle(let reason):
            return "Invalid title: \(reason)"
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .networkError:
            return "Network connection required"
        }
    }
}
```

**Handle errors appropriately:**
```swift
func saveNote() async {
    do {
        try await noteService.save(note)
        showSuccessMessage()
    } catch let error as NoteError {
        showError(error.localizedDescription)
    } catch {
        showError("An unexpected error occurred")
        logError(error)
    }
}
```

## 🧪 Testing

### Test Requirements

- **Unit Tests**: Required for all business logic
- **Integration Tests**: Required for data persistence
- **UI Tests**: Required for critical user flows
- **Coverage**: >90% for new code, >80% overall

### Test Structure

```swift
class NoteServiceTests: XCTestCase {
    private var sut: NoteService!
    private var mockRepository: MockNoteRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockNoteRepository()
        sut = NoteService(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    func testCreateNote_Success() async throws {
        // Given
        let title = "Test Note"
        let content = "Content"

        // When
        let note = try await sut.createNote(title: title, content: content)

        // Then
        XCTAssertEqual(note.title, title)
        XCTAssertEqual(note.content, content)
    }

    func testCreateNote_EmptyTitle_ThrowsError() async throws {
        // Given
        let title = ""
        let content = "Valid content"

        // When/Then
        await XCTAssertThrowsError(try await sut.createNote(title: title, content: content))
    }
}
```

### Running Tests

```bash
# Run all tests
swift test

# Run specific test class
swift test --filter NoteServiceTests

# Run with code coverage
swift test --enable-code-coverage

# Run performance tests
swift test --filter StickyNotesPerformanceTests
```

### Test Coverage

Check coverage after running tests:

```bash
# Generate coverage report
xcrun llvm-cov show .build/debug/StickyNotesPackageTests.xctest \
    --instr-profile .build/debug/codecov/default.profdata \
    --format html > coverage.html

# Open in browser
open coverage.html
```

## 📚 Documentation

### Documentation Requirements

- **README**: Update for new features
- **API Docs**: Document all public APIs
- **Code Comments**: Explain complex logic
- **Changelogs**: Document changes

### Documentation Standards

**API Documentation:**
```swift
/// Creates a new sticky note with the specified parameters.
///
/// This method performs validation on the input parameters and creates
/// a note with default positioning and theming.
///
/// - Parameters:
///   - title: The title text for the note (optional)
///   - content: The main content text (required)
///   - color: The color theme (defaults to yellow)
/// - Returns: A new `Note` instance
/// - Throws: `ValidationError` if parameters are invalid
/// - Note: The note will be positioned at default coordinates
/// - SeeAlso: `updateNote(_:)` for modifying existing notes
func createNote(
    title: String = "",
    content: String,
    color: NoteColor = .yellow
) async throws -> Note
```

**README Updates:**
- Add new features to feature list
- Update installation instructions if changed
- Include screenshots for UI changes

## 🐛 Issue Reporting

### Bug Reports

**Required Information:**
- **macOS Version**: `sw_vers`
- **Xcode Version**: `xcodebuild -version`
- **App Version**: Check in StickyNotes → About
- **Steps to Reproduce**: Detailed reproduction steps
- **Expected Behavior**: What should happen
- **Actual Behavior**: What actually happens
- **Logs**: Console logs or crash reports

**Bug Report Template:**
```markdown
## Bug Report

**Description:**
[Clear description of the bug]

**Steps to Reproduce:**
1. [First step]
2. [Second step]
3. [Third step]

**Expected Behavior:**
[What should happen]

**Actual Behavior:**
[What actually happens]

**Environment:**
- macOS Version: [e.g., 13.2.1]
- App Version: [e.g., 1.0.0]
- Xcode Version: [e.g., 14.2]

**Additional Context:**
[Screenshots, logs, or other relevant information]
```

### Feature Requests

**Feature Request Template:**
```markdown
## Feature Request

**Problem:**
[Describe the problem this feature would solve]

**Solution:**
[Describe the proposed solution]

**Alternatives:**
[Describe alternative solutions considered]

**Additional Context:**
[Mockups, examples, or other relevant information]
```

## 🔄 Pull Request Process

### PR Requirements

**Before submitting:**
- [ ] Code follows [style guide](code-style.md)
- [ ] All tests pass (`swift test`)
- [ ] Code is linted (`swiftlint lint`)
- [ ] Code is formatted (`swiftformat`)
- [ ] Documentation updated
- [ ] Self-review completed

**PR Template:**
```markdown
## Description
[Brief description of changes]

## Type of Change
- [ ] Bug fix (non-breaking change)
- [ ] New feature (non-breaking change)
- [ ] Breaking change
- [ ] Documentation update
- [ ] Refactoring

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] UI tests added/updated
- [ ] Manual testing completed

## Screenshots (if applicable)
[Add screenshots for UI changes]

## Checklist
- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
```

### PR Review Process

1. **Automated Checks**: CI/CD runs tests and linting
2. **Code Review**: At least 1 maintainer review required
3. **Testing**: Reviewer may request additional tests
4. **Approval**: PR approved and merged by maintainer
5. **Deployment**: Changes deployed according to release process

### Review Guidelines

**Reviewers should check:**
- Code quality and style compliance
- Test coverage adequacy
- Documentation completeness
- Breaking changes impact
- Performance implications
- Security considerations

**Authors should:**
- Respond to review comments promptly
- Make requested changes
- Re-request review when changes are ready

## 🎯 Areas for Contribution

### High Priority
- **Bug Fixes**: Critical and high-priority bugs
- **Performance**: Memory leaks, slow operations
- **Accessibility**: VoiceOver, keyboard navigation
- **iCloud Sync**: Sync reliability and conflict resolution

### Medium Priority
- **New Features**: Well-designed, requested features
- **UI Polish**: Visual improvements and animations
- **Documentation**: API docs, user guides
- **Testing**: Additional test coverage

### Low Priority
- **Code Cleanup**: Refactoring and modernization
- **Tooling**: Build scripts, CI/CD improvements
- **Internationalization**: Additional language support

## 📞 Getting Help

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and discussions
- **Slack/Discord**: Real-time chat (if available)

### Response Times

- **Bug Reports**: Acknowledged within 24 hours
- **Feature Requests**: Initial response within 1 week
- **PR Reviews**: Within 2-3 business days
- **General Questions**: Within 1-2 business days

## 🙏 Recognition

Contributors are recognized through:
- **GitHub Contributors**: Listed in repository contributors
- **Changelog**: Mentioned in release notes
- **Credits**: Listed in app credits (for major contributions)

Thank you for contributing to StickyNotes! Your efforts help make the app better for all users.