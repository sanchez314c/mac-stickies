# Troubleshooting Guide

This guide helps you resolve common issues with StickyNotes Desktop.

## Table of Contents

- [Installation Issues](#installation-issues)
- [Sync Problems](#sync-problems)
- [Performance Issues](#performance-issues)
- [UI/Display Issues](#uidisplay-issues)
- [Data Loss/Recovery](#data-lossrecovery)
- [Crashes and Freezes](#crashes-and-freezes)
- [Build/Development Issues](#builddevelopment-issues)

## Installation Issues

### App Won't Open

**Symptoms**: Double-clicking the app does nothing, or it immediately closes

**Solutions**:
1. **Check macOS Version**: Ensure you're running macOS 13.0 (Ventura) or later
2. **Verify Source**: Download only from official GitHub releases or Mac App Store
3. **Gatekeeper Settings**:
   ```bash
   # Allow app from unidentified developer
   sudo spctl --master-disable
   # Or right-click app → Open → Accept risk
   ```
4. **Permissions**: Check System Settings → Privacy & Security for app permissions

### "App is Damaged" Error

**Symptoms**: macOS reports the app is damaged and can't be opened

**Solutions**:
1. **Re-download**: The file may be corrupted during download
2. **Verify Checksum**: Compare with release checksum
3. **Remove Quarantine**:
   ```bash
   xattr -d com.apple.quarantine StickyNotes.app
   ```

## Sync Problems

### CloudKit Sync Not Working

**Symptoms**: Notes not syncing between devices

**Solutions**:
1. **Check iCloud Status**:
   - Ensure you're signed into iCloud
   - Check System Settings → Apple ID → iCloud → iCloud Drive
   - Verify "Desktop & Documents Folders" is enabled if needed

2. **Network Connection**:
   - Check internet connectivity
   - Try switching between WiFi and cellular
   - Verify firewall isn't blocking CloudKit

3. **Reset CloudKit**:
   ```bash
   # Delete local CloudKit data (will re-download from iCloud)
   rm -rf ~/Library/Containers/com.jasonmichaels.stickynotes/
   ```

### Sync Conflicts

**Symptoms**: Duplicate notes or conflicting versions

**Solutions**:
1. **Manual Resolution**: Choose which version to keep
2. **Last Write Wins**: Most recent changes typically override older ones
3. **Export and Re-import**: Export notes, delete all, then re-import

## Performance Issues

### App is Slow/Laggy

**Symptoms**: Typing lag, slow note opening, general sluggishness

**Solutions**:
1. **Check Resources**:
   - Open Activity Monitor
   - Check CPU and Memory usage
   - Restart app if usage is high

2. **Large Note Count**:
   - Archive old notes
   - Delete unnecessary notes
   - Consider splitting into multiple windows

3. **Restart App**:
   ```bash
   # Force quit and restart
   pkill StickyNotes
   ```

### High Memory Usage

**Symptoms**: System becomes slow when app is running

**Solutions**:
1. **Note Size**: Very large notes with images can consume memory
2. **Background Processes**: Check for background operations
3. **Restart Periodically**: Restart app daily if memory usage grows

## UI/Display Issues

### Notes Not Visible

**Symptoms**: Note windows appear but content is blank

**Solutions**:
1. **Restart App**: Simple restart often fixes display issues
2. **Check Colors**: Light text on light background might be invisible
3. **Font Issues**: Ensure system fonts are not corrupted

### Window Position Problems

**Symptoms**: Notes appear off-screen or in wrong position

**Solutions**:
1. **Reset Window Positions**:
   ```bash
   # Delete window position preferences
   rm -rf ~/Library/Preferences/com.jasonmichaels.stickynotes.plist
   ```
2. **Mission Control**: Check if windows are in different spaces
3. **Display Settings**: Verify display arrangement in System Settings

## Data Loss/Recovery

### Accidentally Deleted Notes

**Solutions**:
1. **CloudKit Recovery**: Check other devices for the note
2. **Time Machine**: Restore from backup if available
3. **iCloud.com**: Check iCloud web interface for recently deleted items

### Corrupted Data

**Symptoms**: App crashes when opening specific notes

**Solutions**:
1. **Export Working Notes**: Export notes that still open
2. **Reset Database**:
   ```bash
   # WARNING: This deletes all local data
   rm -rf ~/Library/Containers/com.jasonmichaels.stickynotes/Data/Library/Application\ Support/StickyNotes/
   ```
3. **Re-import**: Re-import exported notes

## Crashes and Freezes

### App Crashes on Launch

**Solutions**:
1. **Safe Mode**: Restart Mac in Safe Mode and try again
2. **Create New User**: Test if issue is user-specific
3. **Reinstall**: Completely remove and reinstall app

### App Freezes

**Solutions**:
1. **Force Quit**: `Cmd+Option+Esc` → Select StickyNotes → Force Quit
2. **Check Activity Monitor**: See if app is "Not Responding"
3. **Console App**: Check Console.app for crash logs:
   - Open Console.app
   - Search for "StickyNotes"
   - Look for error messages

## Build/Development Issues

### Build Fails

**Common Build Errors**:

1. **Xcode Version**: Ensure Xcode 15.0+ is installed
2. **Swift Version**: Check Swift 5.10+ compatibility
3. **Dependencies**: Run `swift package update`
4. **Code Signing**: Verify developer certificates

### Simulator Issues

**Solutions**:
1. **Reset Simulator**: `Device → Erase All Content and Settings`
2. **Update Xcode**: Ensure latest Xcode and simulators
3. **Clean Build**: `Product → Clean Build Folder`

## Getting Help

If you're still experiencing issues:

1. **Check GitHub Issues**: Search existing issues at [github.com/sanchez314c/desktop-stickies/issues](https://github.com/sanchez314c/desktop-stickies/issues)
2. **Create New Issue**: Include:
   - macOS version
   - App version
   - Steps to reproduce
   - Console logs (if applicable)
3. **Contact Support**: Email sanchez314c@jasonpaulmichaels.co

## Diagnostic Information

To collect diagnostic information:

```bash
# System information
sw_vers
system_profiler SPSoftwareDataType

# App information
ls -la ~/Library/Containers/com.jasonmichaels.stickynotes/

# Crash logs
ls -la ~/Library/Logs/DiagnosticReports/StickyNotes*
```

## Common Workflows

### First Troubleshooting Steps

1. Restart the app
2. Restart your Mac
3. Check for updates
4. Try with a new note
5. Check network connectivity (for sync issues)

### Before Reporting Issues

1. Search existing issues
2. Try on another Mac if possible
3. Collect system information
4. Note exact error messages
5. Document steps to reproduce

---

*Last updated: 2025-10-31*