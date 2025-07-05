# Installation Guide

Complete guide for installing StickyNotes on macOS.

## 📋 System Requirements

### Minimum Requirements
- **macOS**: 12.0 (Monterey) or later
- **Processor**: Intel Core 2 Duo or Apple Silicon M1/M2/M3
- **Memory**: 4 GB RAM
- **Storage**: 500 MB available space
- **Display**: 1280 × 800 resolution or higher

### Recommended Requirements
- **macOS**: 13.0 (Ventura) or later
- **Processor**: Apple Silicon M1/M2/M3 or Intel Core i5
- **Memory**: 8 GB RAM or more
- **Storage**: 1 GB available space
- **Display**: Retina display recommended

### Supported Architectures
- **Intel (x86_64)**: Full support
- **Apple Silicon**: Native support (ARM64)

## 📦 Installation Methods

### Method 1: Mac App Store (Recommended)

#### For New Users
1. **Open Mac App Store**
   - Click the App Store icon in your Dock
   - Or search for "App Store" using Spotlight (`Cmd+Space`)

2. **Search for StickyNotes**
   - Type "StickyNotes" in the search bar
   - Look for the app with the sticky note icon 📝

3. **Download and Install**
   - Click the "Get" button
   - If prompted, enter your Apple ID password
   - The app will download and install automatically

4. **Launch StickyNotes**
   - Find StickyNotes in your Applications folder
   - Or search for it using Spotlight
   - Double-click to open

#### Automatic Updates
- App Store handles updates automatically
- You'll be notified when updates are available
- Updates install in the background

### Method 2: Direct Download

#### Download from Website
1. **Visit the Download Page**
   - Go to [stickynotes.app/download](https://stickynotes.app/download)
   - Or [github.com/superclaude/stickynotes/releases](https://github.com/superclaude/stickynotes/releases)

2. **Choose Your Version**
   - **Intel Macs**: Download `StickyNotes-Intel.dmg`
   - **Apple Silicon Macs**: Download `StickyNotes-AppleSilicon.dmg`
   - **Universal**: Download `StickyNotes-Universal.dmg` (larger file)

3. **Verify Download**
   - Check file size matches the website
   - Verify checksum if provided:
   ```bash
   shasum -a 256 StickyNotes.dmg
   ```

#### Install from DMG
1. **Open the DMG File**
   - Double-click the downloaded `.dmg` file
   - If prompted about security, click "Open Anyway"

2. **Install the App**
   - Drag the StickyNotes icon to the Applications folder
   - Wait for the copy to complete

3. **Eject the DMG**
   - Right-click the DMG icon on your desktop
   - Select "Eject" or drag to Trash

4. **Launch StickyNotes**
   - Open Finder and go to Applications
   - Find StickyNotes and double-click to open

#### First Launch Security
macOS may show a security warning on first launch:

1. **Security Warning**
   - "StickyNotes" cannot be opened because it is from an unidentified developer

2. **Allow Installation**
   - Go to System Preferences → Security & Privacy → General
   - Click "Allow Anyway" next to StickyNotes
   - Try opening StickyNotes again

### Method 3: Homebrew (Advanced Users)

#### Install via Homebrew Cask
```bash
# Add the tap (if required)
brew tap superclaude/stickynotes

# Install StickyNotes
brew install --cask stickynotes

# To upgrade later
brew upgrade stickynotes
```

#### Uninstall via Homebrew
```bash
# Uninstall StickyNotes
brew uninstall stickynotes

# Remove the tap
brew untap superclaude/stickynotes
```

## ⚙️ Post-Installation Setup

### First Launch Configuration

1. **Welcome Screen**
   - StickyNotes shows a welcome message
   - Click "Continue" to proceed

2. **Permissions Setup**
   - **Accessibility**: Required for floating windows
     - System Preferences → Security & Privacy → Accessibility
     - Check ✓ StickyNotes
   - **Screen Recording**: Optional, for screenshots
     - System Preferences → Security & Privacy → Screen Recording
     - Check ✓ StickyNotes

3. **iCloud Setup (Optional)**
   - Enable iCloud sync for cross-device notes
   - System Preferences → Apple ID → iCloud
   - Enable "iCloud Drive"

### Preferences Configuration

Access preferences via menu bar or keyboard:

- **Menu Bar**: Click StickyNotes icon → "Preferences..."
- **Keyboard**: Press `Cmd+,`

#### Essential Settings
- **Launch at Login**: Enable for automatic startup
- **Show in Menu Bar**: Keep enabled for quick access
- **Default Note Color**: Choose your preferred color
- **iCloud Sync**: Enable if using multiple Macs

## 🔧 Troubleshooting Installation

### Installation Fails

#### App Store Issues
**Problem**: Download won't start
**Solutions**:
- Check internet connection
- Sign out and back into App Store
- Free up storage space (at least 500MB)
- Restart Mac and try again

**Problem**: "This item is temporarily unavailable"
**Solutions**:
- Wait a few minutes and try again
- Check App Store status: [apple.com/support/systemstatus](https://apple.com/support/systemstatus)
- Try downloading from website instead

#### DMG Installation Issues
**Problem**: "The disk image is corrupted"
**Solutions**:
- Re-download the DMG file
- Check available disk space
- Disable antivirus software temporarily
- Try a different browser for download

**Problem**: Can't copy to Applications
**Solutions**:
- Ensure you have admin privileges
- Check Applications folder permissions
- Try copying to Desktop first, then move manually

### Launch Issues

#### App Won't Open
**Symptoms**: Double-clicking does nothing, or "application cannot be verified"

**Solutions**:

1. **Check Gatekeeper**
   ```bash
   # Check Gatekeeper status
   spctl --status
   ```

2. **Allow App Exception**
   - System Preferences → Security & Privacy → General
   - Click "Allow Anyway" or "Open Anyway"

3. **Check App Signature**
   ```bash
   # Verify app signature
   codesign -vvv /Applications/StickyNotes.app
   ```

4. **Reinstall**
   - Delete StickyNotes from Applications
   - Empty Trash
   - Reinstall from original source

#### Permissions Issues
**Symptoms**: Notes don't float, keyboard shortcuts don't work

**Required Permissions**:
- **Accessibility**: For floating windows and keyboard shortcuts
- **Screen Recording**: For export features (optional)

**Setup Permissions**:
1. System Preferences → Security & Privacy → Privacy
2. Select "Accessibility" tab
3. Click 🔒 to unlock
4. Check ✓ StickyNotes
5. Repeat for "Screen Recording" if needed

### Performance Issues

#### Slow Startup
**Causes**:
- Large number of notes
- iCloud sync initializing
- System resource constraints

**Solutions**:
- Close other applications
- Wait for iCloud sync to complete
- Check Activity Monitor for resource usage

#### High Memory Usage
**Normal Behavior**: StickyNotes uses 20-100MB depending on usage

**If Excessive**:
- Close unused notes
- Restart the application
- Check for memory leaks in Console app

## 🔄 Updates and Upgrades

### Automatic Updates (App Store)

- Updates download and install automatically
- Check for updates: App Store → Updates
- Force check: Hold Option key while clicking "Updates"

### Manual Updates (Direct Download)

1. **Check Current Version**
   - StickyNotes → About StickyNotes
   - Note the version number

2. **Download Latest Version**
   - Visit [stickynotes.app/download](https://stickynotes.app/download)
   - Download the appropriate version for your Mac

3. **Install Update**
   - Open new DMG file
   - Drag to Applications (replaces old version)
   - Launch new version

### Beta Versions

For testing pre-release features:

1. **Join Beta Program**
   - Visit [stickynotes.app/beta](https://stickynotes.app/beta)
   - Sign up with email address

2. **Install Beta**
   - Download beta DMG from email link
   - Install alongside stable version
   - Use different name (e.g., "StickyNotes Beta")

## 🗑️ Uninstalling StickyNotes

### Complete Removal

1. **Quit StickyNotes**
   - Right-click menu bar icon → "Quit"

2. **Remove App**
   ```bash
   # From Terminal
   rm -rf /Applications/StickyNotes.app
   ```

3. **Remove Support Files** (Optional)
   ```bash
   # Remove preferences
   rm -rf ~/Library/Preferences/com.superclaude.stickynotes.plist

   # Remove app data (WARNING: deletes all notes!)
   rm -rf ~/Library/Containers/com.superclaude.stickynotes/

   # Remove caches
   rm -rf ~/Library/Caches/com.superclaude.stickynotes/
   ```

4. **Remove from Login Items** (if enabled)
   - System Preferences → Users & Groups → Login Items
   - Remove StickyNotes if present

### Clean Reinstall

For troubleshooting persistent issues:

1. **Complete Uninstall** (see above)
2. **Restart Mac**
3. **Reinstall** from original source

## 📞 Support and Help

### Installation Support

- **Documentation**: [Full user guide](user-guide.md)
- **Troubleshooting**: [Common issues](troubleshooting.md)
- **Community**: [User forum](https://forum.stickynotes.app)

### Contact Information

- **Email**: support@stickynotes.app
- **Response Time**: Within 24 hours
- **Emergency**: For critical installation issues

### System Information for Support

When contacting support, include:

```bash
# macOS version
sw_vers

# Chip architecture
uname -m

# Available storage
df -h /

# App version (if installed)
mdls -name kMDItemVersion /Applications/StickyNotes.app
```

---

*This installation guide covers StickyNotes version 1.0.0. Installation methods may change in future versions.*