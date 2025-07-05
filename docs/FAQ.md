# Frequently Asked Questions

Common questions and answers about StickyNotes.

## General Questions

### Q: Is StickyNotes free?
A: Yes, StickyNotes is free to download and use. All core features are included at no cost.

### Q: Does StickyNotes work on iOS/iPadOS?
A: Currently, StickyNotes is macOS only. An iOS version is planned for future release but no timeline is set.

### Q: Can I use StickyNotes on multiple Macs?
A: Yes, with iCloud sync enabled, your notes are available on all your Mac devices signed into the same Apple ID.

### Q: Does StickyNotes require an internet connection?
A: No, StickyNotes works offline. Internet connection is only needed for iCloud synchronization and some export features.

### Q: What's the difference between StickyNotes and Apple's Stickies?
A: StickyNotes offers modern features like iCloud sync, rich text editing, themes, and better organization compared to Apple's built-in Stickies app.

## Installation and Setup

### Q: Why am I getting "unidentified developer" error?
A: This is a macOS security feature. Go to System Preferences → Security & Privacy → General and click "Open Anyway". Or right-click the app and select "Open".

### Q: StickyNotes won't open after installation
A: Try these steps:
1. Restart your Mac
2. Check macOS compatibility (requires macOS 12.0+)
3. Verify app permissions in System Preferences
4. Reinstall from the original source

### Q: Can I install StickyNotes on a USB drive?
A: Yes, you can copy the app to a USB drive and run it from there, but iCloud sync may have limitations.

## Features and Usage

### Q: How many notes can I create?
A: There's no hard limit on the number of notes. Performance may vary with very large numbers (1000+ notes).

### Q: Can I password-protect individual notes?
A: This feature is planned for a future update. Currently, you can use macOS FileVault to protect your entire system.

### Q: Does StickyNotes support images or attachments?
A: Currently, StickyNotes is text-only. Image support is planned for a future release.

### Q: Can I customize fonts?
A: Yes, you can change fonts using the Format menu or keyboard shortcuts. The app uses your system fonts.

### Q: Does StickyNotes support Markdown?
A: Yes, StickyNotes supports Markdown mode. Enable it via Format → Markdown or with the toggle in note preferences.

## Synchronization

### Q: How does iCloud sync work?
A: StickyNotes uses CloudKit to sync notes across your devices. Changes are automatically synced when you're connected to the internet.

### Q: My notes aren't syncing. What should I do?
A: Try these solutions:
1. Check iCloud Drive is enabled
2. Verify you're signed into iCloud
3. Restart StickyNotes
4. Toggle sync off and on in preferences
5. Check Apple's System Status for iCloud issues

### Q: Can I sync with non-Apple devices?
A: Currently, iCloud sync only works with Apple devices. You can export notes manually for use on other platforms.

### Q: Will I lose my notes if I cancel iCloud?
A: No, notes remain on your local device. However, sync between devices will stop working.

## Performance and Compatibility

### Q: StickyNotes is using too much memory. What can I do?
A: Try these tips:
- Close unused notes
- Restart the app periodically
- Limit the number of notes with large content
- Check for app updates

### Q: Does StickyNotes support Apple Silicon (M1/M2/M3)?
A: Yes, StickyNotes runs natively on both Intel and Apple Silicon Macs.

### Q: Which macOS versions are supported?
A: StickyNotes requires macOS 12.0 (Monterey) or later. Older versions of macOS are not supported.

### Q: Can I use StickyNotes with external displays?
A: Yes, StickyNotes works with any number of displays and remembers note positions.

## Data and Privacy

### Q: Are my notes private and secure?
A: Yes, notes are stored locally on your device and encrypted when synced via iCloud. The developer cannot access your notes.

### Q: Where are my notes stored locally?
A: Notes are stored in your Library folder at:
`~/Library/Containers/com.superclaude.stickynotes/Data/Documents/`

### Q: Can I export my notes?
A: Yes, you can export notes in various formats (Text, Markdown, RTF, HTML, PDF, JSON) via the Export button.

### Q: How do I backup my notes?
A: Options:
1. Enable iCloud sync for automatic backup
2. Export notes manually to a safe location
3. Use Time Machine for system-wide backup

### Q: Can StickyNotes read my other notes apps?
A: StickyNotes can import text and Markdown files. Use File → Import to bring in notes from other sources.

## Troubleshooting

### Q: StickyNotes crashed. What should I do?
A: 1. Restart the app
2. Check for updates
3. If crashes persist, report the issue with crash logs from Console.app

### Q: I can't type in my notes
A: 1. Click directly in the note content area
2. Check if another app is capturing keyboard input
3. Restart StickyNotes
4. Check keyboard in System Preferences

### Q: Notes disappeared after update
A: 1. Check if sync is enabled
2. Look in recently deleted in preferences
3. Check local backups if any
4. Contact support with details about the update

### Q: StickyNotes menu bar icon disappeared
A: 1. Check if StickyNotes is running (Activity Monitor)
2. Restart the app
3. Check menu bar settings in System Preferences
4. Reset preferences if needed

## Keyboard Shortcuts

### Q: What are the essential keyboard shortcuts?
A:
- `Cmd+N` - New note
- `Cmd+W` - Close note
- `Cmd+F` - Find
- `Cmd+,` - Preferences
- `Cmd+B/I/U` - Bold/Italic/Underline
- `Cmd+Shift+8/7` - Bullet/Numbered list

### Q: Can I customize keyboard shortcuts?
A: Currently, keyboard shortcuts are fixed. Custom shortcuts may be added in a future update.

## Advanced Usage

### Q: Can I use StickyNotes for presentations?
A: Yes, you can create presentation notes with different colors and positioning. Use full screen mode for better visibility.

### Q: Does StickyNotes support scripting or automation?
A: AppleScript support is planned. Currently, you can use macOS automation tools for basic operations.

### Q: Can I integrate StickyNotes with other apps?
A: StickyNotes supports standard macOS services. You can share text from other apps to create notes.

## Account and Billing

### Q: Do I need an account to use StickyNotes?
A: No account required. Only an Apple ID for iCloud sync if you choose to use it.

### Q: Are there any in-app purchases?
A: No, all features are free. No hidden costs or subscriptions.

### Q: Will StickyNotes ever become a paid app?
A: There are no current plans to charge for StickyNotes. Any future premium features would be clearly communicated in advance.

## Community and Support

### Q: How can I request features?
A:
- GitHub Issues: Create feature requests
- Email: sanchez314c@jasonpaulmichaels.co
- Community feedback is welcome and valued

### Q: How can I report bugs?
A: Please include:
- macOS and StickyNotes version
- Steps to reproduce
- Expected vs actual behavior
- Screenshots if applicable
- Console logs if available

### Q: Is there a user community?
A: Check GitHub Discussions for community support. You can also share tips and tricks with other users.

### Q: Can I contribute to StickyNotes development?
A: Yes! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on contributing code, documentation, or translations.

---

*Still have questions? Check the [User Guide](USER_GUIDE.md) or [Troubleshooting Guide](TROUBLESHOOTING.md) for more detailed information.*