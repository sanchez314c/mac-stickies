# Troubleshooting Guide

Solve common issues and get StickyNotes working perfectly on your Mac.

## 🔍 Quick Diagnosis

### Is StickyNotes Running?

**Check the menu bar:**
- Look for the sticky note icon (📝) in your menu bar
- If missing, StickyNotes may not be running

**Check Activity Monitor:**
1. Open Activity Monitor (Spotlight: "Activity Monitor")
2. Search for "StickyNotes"
3. If not found, the app isn't running

### Basic Health Check

Run this quick diagnostic:

```bash
# Check if app is installed
ls -la /Applications/StickyNotes.app

# Check system logs for errors
log show --predicate 'process == "StickyNotes"' --last 1h
```

## 🚨 Common Issues & Solutions

### Issue: Notes Not Appearing

**Symptoms:**
- Pressing `Cmd+N` does nothing
- No notes visible on screen
- Menu bar icon missing

**Solutions:**

1. **Check if app is running:**
   - Open Activity Monitor
   - Look for "StickyNotes" process
   - If not running, relaunch from Applications

2. **Reset app state:**
   ```bash
   # Quit StickyNotes completely
   killall StickyNotes

   # Clear preferences (WARNING: resets all settings)
   defaults delete com.superclaude.stickynotes

   # Relaunch app
   open /Applications/StickyNotes.app
   ```

3. **Check permissions:**
   - System Preferences → Security & Privacy → Privacy
   - Ensure StickyNotes has Accessibility permission
   - Grant Screen Recording permission if prompted

### Issue: Can't Type in Notes

**Symptoms:**
- Clicking in note doesn't show cursor
- Keyboard input ignored
- Note appears "frozen"

**Solutions:**

1. **Check focus:**
   - Click directly in the note content area (not title bar)
   - Look for blue border indicating note is selected

2. **Restart note:**
   - Close the problematic note (`Cmd+W`)
   - Create new note (`Cmd+N`)
   - Try typing in new note

3. **Check for modal dialogs:**
   - Close any open dialogs or preferences windows
   - Check if another app has keyboard focus

### Issue: Notes Disappearing

**Symptoms:**
- Notes vanish after restart
- Notes not restoring position
- Data appears lost

**Solutions:**

1. **Check auto-save:**
   - Preferences → General → Auto-save should be enabled
   - Notes save automatically - no manual save needed

2. **Verify storage location:**
   ```bash
   # Check app data directory
   ls -la ~/Library/Containers/com.superclaude.stickynotes/Data/
   ```

3. **Check disk space:**
   ```bash
   # Check available space
   df -h /
   ```

4. **Restore from backup:**
   - If using Time Machine, restore from backup
   - Check iCloud if sync is enabled

### Issue: Performance Problems

**Symptoms:**
- App slow to respond
- High CPU/memory usage
- Notes lag when typing

**Solutions:**

1. **Check system resources:**
   ```bash
   # Monitor CPU usage
   top -pid $(pgrep StickyNotes)
   ```

2. **Close unnecessary notes:**
   - Too many open notes can slow performance
   - Close notes with `Cmd+W`

3. **Reset app:**
   ```bash
   # Force quit and restart
   killall StickyNotes
   open /Applications/StickyNotes.app
   ```

4. **Check for conflicts:**
   - Disable other note-taking apps temporarily
   - Check for keyboard shortcut conflicts

## 🔄 iCloud Sync Issues

### Issue: Sync Not Working

**Symptoms:**
- Changes not appearing on other devices
- Sync status shows errors
- iCloud preferences unavailable

**Solutions:**

1. **Verify iCloud setup:**
   - System Preferences → Apple ID → iCloud
   - Ensure iCloud Drive is enabled
   - Check available storage space

2. **Check StickyNotes sync settings:**
   - Preferences → iCloud → Enable sync
   - Try toggling sync off/on

3. **Force sync:**
   ```bash
   # Trigger manual sync
   killall StickyNotes
   defaults write com.superclaude.stickynotes forceSync -bool true
   open /Applications/StickyNotes.app
   ```

4. **Check iCloud status:**
   - Visit [icloud.com](https://icloud.com) in browser
   - Verify account is active

### Issue: Sync Conflicts

**Symptoms:**
- Duplicate notes appearing
- Conflicting changes not merging
- Sync errors in console

**Solutions:**

1. **Resolve manually:**
   - Choose which version to keep
   - Delete duplicate notes

2. **Reset sync:**
   ```bash
   # Disable sync temporarily
   defaults write com.superclaude.stickynotes iCloudSync -bool false

   # Clear sync data
   rm -rf ~/Library/Containers/com.superclaude.stickynotes/Data/iCloud*

   # Re-enable sync
   defaults write com.superclaude.stickynotes iCloudSync -bool true
   ```

## 🎨 Display & Appearance Issues

### Issue: Notes Look Wrong

**Symptoms:**
- Colors not displaying correctly
- Text formatting issues
- Transparency not working

**Solutions:**

1. **Check system appearance:**
   - System Preferences → General → Appearance
   - Try switching between Light/Dark mode

2. **Reset appearance settings:**
   ```bash
   # Reset to defaults
   defaults delete com.superclaude.stickynotes appearance
   ```

3. **Check graphics:**
   - Ensure macOS is updated
   - Check for graphics driver issues

### Issue: Window Behavior Problems

**Symptoms:**
- Notes not floating above other apps
- Can't move or resize notes
- Windows appearing behind others

**Solutions:**

1. **Check window level:**
   ```bash
   # Reset window levels
   defaults write com.superclaude.stickynotes resetWindowLevels -bool true
   ```

2. **Verify permissions:**
   - System Preferences → Security & Privacy → Accessibility
   - Ensure StickyNotes is checked

3. **Restart window server:**
   ```bash
   # Restart window management
   killall WindowServer
   ```

## ⌨️ Keyboard & Input Issues

### Issue: Shortcuts Not Working

**Symptoms:**
- Keyboard shortcuts ignored
- Wrong shortcuts triggering

**Solutions:**

1. **Check for conflicts:**
   - System Preferences → Keyboard → Shortcuts
   - Look for conflicting app shortcuts

2. **Reset shortcuts:**
   ```bash
   # Reset to defaults
   defaults delete com.superclaude.stickynotes keyboardShortcuts
   ```

3. **Check input sources:**
   - System Preferences → Keyboard → Input Sources
   - Ensure correct keyboard layout

### Issue: Special Characters Not Working

**Symptoms:**
- Accented characters not appearing
- Emoji picker not opening

**Solutions:**

1. **Check keyboard settings:**
   - System Preferences → Keyboard → Keyboard
   - Enable "Show keyboard and emoji viewers in menu bar"

2. **Reset input methods:**
   ```bash
   # Clear input method cache
   rm -rf ~/Library/Preferences/com.apple.HIToolbox.plist
   ```

## 📤 Export Problems

### Issue: Export Failing

**Symptoms:**
- Export dialog not opening
- Files not saving
- Format conversion errors

**Solutions:**

1. **Check permissions:**
   ```bash
   # Check write permissions
   ls -la ~/Desktop/
   ```

2. **Try different location:**
   - Export to Downloads folder instead
   - Check available disk space

3. **Reset export settings:**
   ```bash
   # Clear export preferences
   defaults delete com.superclaude.stickynotes export
   ```

## 🔧 Advanced Troubleshooting

### Debug Mode

Enable debug logging for detailed diagnostics:

```bash
# Enable debug mode
defaults write com.superclaude.stickynotes debugMode -bool true

# View logs
log stream --predicate 'process == "StickyNotes"' --level debug
```

### Clean Reinstall

For persistent issues, completely reinstall:

```bash
# Quit app
killall StickyNotes

# Remove app
rm -rf /Applications/StickyNotes.app

# Clear all data (WARNING: deletes all notes!)
rm -rf ~/Library/Containers/com.superclaude.stickynotes/
rm -rf ~/Library/Preferences/com.superclaude.stickynotes.plist

# Reinstall from App Store or DMG
```

### System Compatibility

**macOS Version Issues:**
- Ensure running macOS 12.0 or later
- Update to latest macOS version

**Hardware Compatibility:**
- Intel and Apple Silicon supported
- Minimum 4GB RAM recommended
- 500MB free disk space required

## 📞 Getting Help

### Self-Help Resources

- **User Guide**: [Complete documentation](user-guide.md)
- **FAQ**: [Frequently asked questions](https://stickynotes.app/faq)
- **Community Forum**: [User discussions](https://forum.stickynotes.app)

### Contact Support

**Email Support:**
- Address: support@stickynotes.app
- Response time: Within 24 hours
- Include: macOS version, StickyNotes version, detailed problem description

**Support Information to Include:**
- macOS version: `sw_vers`
- App version: Check in StickyNotes → About
- System specs: `system_profiler SPHardwareDataType`
- Error logs: Console app → Search "StickyNotes"

### Emergency Contacts

**Data Recovery:**
- For lost notes: Check Time Machine backups
- iCloud recovery: Visit [icloud.com](https://icloud.com)

**Critical Issues:**
- App completely broken: Complete reinstall
- System instability: Contact Apple Support

## 🛡️ Prevention

### Regular Maintenance

**Weekly:**
- Check for app updates
- Verify iCloud sync status
- Clear old notes periodically

**Monthly:**
- Review backup integrity
- Check system storage space
- Update macOS and all apps

### Best Practices

- **Don't force quit unnecessarily** - can cause data loss
- **Keep notes organized** - too many open notes slows performance
- **Regular backups** - enable Time Machine
- **Monitor storage** - keep 10% free space available

---

*This troubleshooting guide covers version 1.0.0. For newer versions, check the [latest documentation](https://docs.stickynotes.app/troubleshooting).*