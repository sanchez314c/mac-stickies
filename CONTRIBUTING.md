# Contributing to Desktop Stickies

Thank you for your interest in contributing to Desktop Stickies. We welcome contributions from the community.

## Prerequisites

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Swift 5.10 or later
- Git

## Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/your-username/desktop-stickies.git
   cd desktop-stickies
   ```
3. Open the project in Xcode:
   ```bash
   open StickyNotes/StickyNotes.xcodeproj
   ```
4. Build and run (Cmd+R)

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in GitHub Issues
2. Create a detailed bug report with:
   - Clear description of the bug
   - Steps to reproduce the issue
   - Expected behavior vs. actual behavior
   - Screenshots if applicable
   - macOS version and hardware details

### Suggesting Features

1. Check existing feature requests in GitHub Issues
2. Create a feature request with:
   - Problem the feature would solve
   - Proposed solution
   - Alternative solutions considered
   - Mockups or wireframes if applicable

### Submitting Changes

1. Create a feature branch (`git checkout -b feature/amazing-feature`)
2. Make your changes following the existing code style
3. Add tests for new features
4. Ensure all tests pass (`xcodebuild test -scheme StickyNotes`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Code Style

- Follow Swift API Design Guidelines
- Use meaningful names for types, functions, and variables
- Document public APIs with inline documentation comments
- Use 4 spaces for indentation in Swift files
- Keep functions focused and small
- Prefer value types (structs) over reference types (classes) where appropriate

## Testing

- Write unit tests for new features using XCTest
- Write UI tests for new user-facing features
- Ensure all existing tests pass before submitting
- Aim for 80%+ code coverage

## Commit Message Guidelines

- Use present tense ("Add feature" not "Added feature")
- Start with a capital letter
- Keep the first line under 50 characters
- Reference issues with #123 format
- Use conventional commit prefixes:
  - `feat:` for new features
  - `fix:` for bug fixes
  - `docs:` for documentation changes
  - `style:` for formatting changes
  - `refactor:` for code restructuring
  - `test:` for adding or updating tests
  - `chore:` for maintenance tasks

## License

By contributing to this project, you agree that your contributions will be licensed under the same MIT License that covers the project.
