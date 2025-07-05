# StickyNotes macOS App

A native macOS application that provides floating sticky note functionality directly on the desktop. The app window itself serves as a sticky note, with support for multiple notes, color customization, rich text editing, and markdown support.

## Features

### Core Functionality
- **Floating Windows**: Notes appear as floating windows that stay above other applications
- **Rich Text Editor**: Full rich text editing with formatting toolbar
- **Color Themes**: 6 predefined color schemes (Yellow, Blue, Green, Pink, Purple, Orange)
- **Markdown Support**: Toggle between rich text and markdown editing modes
- **Multiple Notes**: Create and manage multiple simultaneous note windows

### User Interface
- **Native macOS Design**: Follows macOS design guidelines and integrates seamlessly
- **Responsive Layout**: Notes automatically resize and reposition
- **Keyboard Shortcuts**: Full keyboard navigation and shortcuts
- **Accessibility**: VoiceOver and keyboard navigation support

### Data Management
- **Local Storage**: Secure local storage with automatic saving
- **Export Options**: Export notes as Text, Markdown, JSON, or PDF
- **Backup/Restore**: Create and restore backups of all notes

## Architecture

### MVVM Pattern
The application follows the Model-View-ViewModel (MVVM) architectural pattern:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│      View       │    │   ViewModel     │    │     Model       │
│                 │    │                 │    │                 │
│ • SwiftUI Views │◄──►│ • State Mgmt    │◄──►│ • Data Models   │
│ • UI Components │    │ • Business Logic│    │ • Persistence   │
│ • User Input    │    │ • Data Binding  │    │ • Core Data     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Key Components

#### Models
- `Note`: Core data model for sticky notes
- `NoteColor`: Color theme enumeration
- `PersistenceService`: Data persistence layer

#### ViewModels
- `NoteViewModel`: Individual note state management
- `NotesViewModel`: Collection management and coordination

#### Views
- `ContentView`: Main application window
- `NoteWindowView`: Individual floating note windows
- `RichTextEditor`: Native rich text editing component

#### Services
- `WindowManager`: macOS window management
- `PersistenceService`: Data persistence and export

## Requirements

- **macOS**: 13.0+
- **Xcode**: 15.0+
- **Swift**: 5.9+

## Building and Running

### Using Swift Package Manager

```bash
# Clone the repository
git clone <repository-url>
cd StickyNotes

# Build the project
swift build

# Run the application
swift run
```

### Using Xcode

```bash
# Generate Xcode project
swift package generate-xcodeproj

# Open in Xcode
open StickyNotes.xcodeproj
```

## Keyboard Shortcuts

### Application
- `Cmd + N`: Create new note
- `Cmd + 1-6`: Create note with specific color
- `Cmd + Shift + A`: Show all notes
- `Cmd + Shift + W`: Close all notes
- `Cmd + ,`: Preferences (future feature)

### Notes
- `Cmd + W`: Close current note
- `Cmd + E`: Export current note
- `Tab`: Insert tab character
- `Cmd + B`: Toggle bold
- `Cmd + I`: Toggle italic
- `Cmd + U`: Toggle underline

## Data Storage

Notes are stored locally in the Application Support directory:
```
~/Library/Application Support/StickyNotes/
```

Each note is saved as a separate JSON file containing:
- Note content (rich text)
- Metadata (title, color, position, timestamps)
- Formatting information

## Export Formats

### Text (.txt)
Plain text export of note content

### Markdown (.md)
Markdown formatted export with headers and basic formatting

### JSON (.json)
Complete note data including metadata and formatting

### PDF (.pdf)
Formatted PDF export suitable for printing or sharing

## Accessibility

The application is fully accessible with:
- VoiceOver screen reader support
- Keyboard navigation for all controls
- High contrast color schemes
- Adjustable text sizes
- Proper focus management

## Future Enhancements

### Planned Features
- iCloud synchronization
- Note sharing and collaboration
- Advanced markdown features
- Voice notes and audio recording
- Templates and note categories
- Advanced search and filtering
- Dark mode support
- Touch Bar integration

### Technical Improvements
- CloudKit integration
- Advanced text editing features
- Plugin system
- Advanced export options
- Performance optimizations

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue on GitHub
- Check the documentation
- Review the code comments

---

*Built with SwiftUI and AppKit for native macOS integration*</content>
</xai:function_call">Now let me create a basic test file to ensure the project structure is complete. I'll create a simple unit test for the Note model. 

<xai:function_call name="filesystem_create_directory">
<parameter name="path">StickyNotes/Tests