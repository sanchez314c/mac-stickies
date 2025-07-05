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
   - Go to [releases page](https://github.com/sanchez314c/desktop-stickies/releases)
   - Choose the latest stable release

2. **Choose Your Version**
   - **Intel Macs**: Download `StickyNotes-Intel.dmg`
   - **Apple Silicon Macs**: Download `StickyNotes-AppleSilicon.dmg`
   - **Universal**: Download `StickyNotes-Universal.dmg` (larger file)

3. **Verify Download**
   - Check file size matches the release page
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
   - Eject the DMG by dragging it to Trash

3. **Launch the App**
   - Open Applications folder
   - Double-click StickyNotes
   - If prompted about untrusted developer:
     - System Preferences → Security & Privacy → General
     - Click "Open Anyway" for StickyNotes

### Method 3: GitHub Releases (Advanced)

1. **Clone Repository**
   ```bash
   git clone https://github.com/sanchez314c/desktop-stickies.git
   cd desktop-stickies
   ```

2. **Build from Source**
   ```bash
   # Install dependencies
   swift package resolve

   # Build the project
   swift build -c release

   # Run the app
   .build/release/StickyNotes
   ```

## 🔧 First Launch Setup

### Grant Permissions

1. **Accessibility Permission** (Recommended)
   - System Preferences → Security & Privacy → Privacy
   - Click "Accessibility" in the left sidebar
   - Click the lock icon and enter your password
   - Add StickyNotes and check the box

2. **Files and Folders Permission** (For sync)
   - System Preferences → Security & Privacy → Privacy
   - Click "Files and Folders" in the left sidebar
   - Add StickyNotes and allow access to Desktop/Documents

3. **Screen Recording Permission** (For advanced features)
   - May be required for certain screenshot or recording features
   - System Preferences → Security & Privacy → Privacy
   - Click "Screen Recording" and enable for StickyNotes

### Configure iCloud Sync

1. **Check iCloud Status**
   - System Preferences → Apple ID → iCloud
   - Ensure you're signed in
   - Verify iCloud Drive is enabled

2. **Enable Sync in StickyNotes**
   - Open StickyNotes preferences (`Cmd+,`)
   - Go to "Sync" tab
   - Enable "iCloud Synchronization"
   - Choose sync preferences

## 🔐 Security Verification

### Verify App Authenticity

**For Mac App Store Downloads:**
- Downloaded directly from Apple's secure servers
- Verified by Apple before distribution

**For Direct Downloads:**
1. **Check Developer Certificate**
   - Right-click StickyNotes.app → "Show Package Contents"
   - Go to Contents → _CodeSignature
   - Verify certificate is from "Apple Development" or "Developer ID"

2. **Verify with Gatekeeper**
   - macOS automatically verifies apps on first launch
   - Look for "Apple checked it for malicious software" message

### Enable App if Blocked

If you see "StickyNotes can't be opened because Apple cannot check it for malicious software":

1. **Method 1: Allow Anyway**
   - System Preferences → Security & Privacy → General
   - Find "StickyNotes was blocked from use"
   - Click "Open Anyway"

2. **Method 2: Override in Terminal**
   ```bash
   xattr -rd com.apple.quarantine /Applications/StickyNotes.app
   ```

## 📱 Post-Installation

### Create First Note

1. **Launch StickyNotes** if not already running
2. **Press `Cmd+N`** to create new note
3. **Click in the note** and start typing
4. **Try basic formatting**:
   - Select text → `Cmd+B` for bold
   - Select text → `Cmd+I` for italic

### Customize Settings

1. **Open Preferences**: `Cmd+,` or menu bar icon → Preferences
2. **Configure**:
   - Default note color
   - Font preferences
   - Sync settings
   - Keyboard shortcuts

### Verify Installation

Run these quick checks:

```bash
# Check if app is properly installed
ls -la /Applications/StickyNotes.app

# Check if app runs without errors
open /Applications/StickyNotes.app

# Check system logs for any issues
log show --predicate 'process == "StickyNotes"' --last 10m
```

## 🔄 Updating

### Mac App Store Updates
- Automatic by default
- Check App Store → Updates tab
- Click "Update" next to StickyNotes

### Manual Updates
1. Download latest version from releases page
2. Quit StickyNotes (`Cmd+Q`)
3. Replace app in Applications folder
4. Launch new version

### Beta Updates
- Join TestFlight beta program
- Install TestFlight from App Store
- Accept beta invitation
- Update through TestFlight app

## 🗑️ Uninstallation

### Remove App
1. **Quit StickyNotes**: `Cmd+Q` or menu bar → Quit
2. **Drag to Trash**: Drag app from Applications to Trash
3. **Empty Trash**: Right-click Trash → Empty Trash

### Remove Preferences (Optional)
```bash
# Remove app preferences
defaults delete com.superclaude.stickynotes

# Remove app support files
rm -rf ~/Library/Application\ Support/StickyNotes

# Remove cached data
rm -rf ~/Library/Caches/com.superclaude.stickynotes
```

### Remove iCloud Data
- Notes remain in iCloud until manually deleted
- Use iCloud.com or device settings to manage data

## 🆘 Troubleshooting

### Installation Issues

**"App can't be opened because it is from an unidentified developer"**
- System Preferences → Security & Privacy → General
- Click "Open Anyway"

**"The application cannot be opened"**
- Check macOS version compatibility
- Verify download completed fully
- Try re-downloading

**"StickyNotes is damaged and can't be opened"**
- This usually means the download was corrupted
- Re-download the DMG file
- Verify checksum before installation

### Permission Issues

**App asks for permissions repeatedly**
- System Preferences → Security & Privacy → Privacy
- Reset permissions for StickyNotes
- Grant permissions again when prompted

**Features not working**
- Check all required permissions are granted
- Restart the app after granting permissions
- Check system status for macOS updates

### Performance Issues

**Slow launch**
- Check available disk space
- Close other applications
- Restart Mac
- Consider using Activity Monitor to identify issues

**High memory usage**
- Reduce number of open notes
- Restart StickyNotes periodically
- Check for memory leaks with Activity Monitor

## 📞 Support

### Getting Help

**Documentation:**
- [Quick Start Guide](QUICK_START.md)
- [User Guide](USER_GUIDE.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)

**Contact Support:**
- Email: sanchez314c@jasonpaulmichaels.co
- GitHub Issues: Report bugs and feature requests
- Check existing issues before creating new ones

### System Information for Support

When requesting support, please include:
- macOS version
- StickyNotes version
- Installation method (App Store or direct)
- Steps to reproduce issue
- Screenshot if applicable

---

*Follow this guide for a smooth installation experience. For daily usage, see the [Quick Start Guide](QUICK_START.md).*