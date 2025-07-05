# StickyNotes DevOps Pipeline & Deployment Guide

This document outlines the complete DevOps pipeline for building, testing, and deploying the StickyNotes macOS application.

## 🏗️ Architecture Overview

StickyNotes uses a modern macOS development stack:
- **Language**: Swift 5.9+
- **Framework**: SwiftUI
- **Package Manager**: Swift Package Manager
- **CI/CD**: GitHub Actions + Fastlane
- **Distribution**: Mac App Store + Direct Download
- **Code Signing**: Apple Developer Program
- **Notarization**: Apple Notary Service

## 📋 Prerequisites

### Apple Developer Program
1. Enroll in the [Apple Developer Program](https://developer.apple.com/programs/)
2. Create App ID: `com.superclaude.stickynotes`
3. Create provisioning profiles for development and distribution
4. Generate certificates for code signing

### Development Environment
```bash
# Run the setup script
./scripts/setup-macos-development.sh
```

### Required Tools
- Xcode 14.2+
- Swift 5.9+
- Fastlane
- Homebrew
- Node.js (for build scripts)

## 🔧 Build Configuration

### Xcode Project Settings

The project is configured with the following key settings:

#### Build Settings
```swift
// Release Configuration
SWIFT_OPTIMIZATION_LEVEL = -O
DEAD_CODE_STRIPPING = YES
ENABLE_HARDENED_RUNTIME = YES
CODE_SIGN_IDENTITY = "Apple Development"
```

#### Entitlements
- **App Sandbox**: Enabled for security
- **Hardened Runtime**: Enabled for modern macOS compatibility
- **Code Signing**: Required for distribution

### Code Signing

#### Development Signing
```bash
codesign --force --deep --sign "Apple Development: Your Name (TEAM_ID)" \
    --entitlements StickyNotes/Resources/StickyNotes.entitlements \
    --options runtime \
    "StickyNotes.app"
```

#### Distribution Signing
```bash
codesign --force --deep --sign "Developer ID Application: Your Name (TEAM_ID)" \
    --entitlements StickyNotes/Resources/StickyNotes.entitlements \
    --options runtime \
    "StickyNotes.app"
```

## 🚀 CI/CD Pipeline

### GitHub Actions Workflow

The CI/CD pipeline includes:

1. **Testing**: Unit tests, integration tests, UI tests
2. **Building**: Multi-architecture builds (Intel + Apple Silicon)
3. **Code Signing**: Automatic signing with certificates
4. **Notarization**: Apple notary service integration
5. **Distribution**: Mac App Store and direct download

### Workflow Stages

#### 1. Test Stage
```yaml
- name: Run tests
  run: |
    cd StickyNotes
    swift test
```

#### 2. Build Stage
```yaml
- name: Build Release
  run: |
    cd StickyNotes
    swift build -c release --arch arm64 --arch x86_64
```

#### 3. Package Stage
```yaml
- name: Create DMG
  run: |
    hdiutil create -volname "StickyNotes" \
        -srcfolder "StickyNotes.app" \
        -ov -format UDZO "StickyNotes.dmg"
```

#### 4. Notarization Stage
```yaml
- name: Notarize DMG
  run: |
    xcrun notarytool submit "StickyNotes.dmg" \
        --apple-id "${{ secrets.APPLE_ID }}" \
        --password "${{ secrets.APPLE_APP_SPECIFIC_PASSWORD }}" \
        --team-id "${{ secrets.APPLE_TEAM_ID }}" \
        --wait
```

### Fastlane Integration

Fastlane provides automated deployment:

```ruby
# Build for direct distribution
lane :build_direct do
  build_mac_app(
    project: "StickyNotes/StickyNotes.xcodeproj",
    scheme: "StickyNotes",
    export_method: "developer-id"
  )

  notarize(package: lane_context[SharedValues::MAC_APP_BUNDLE])
end
```

## 📦 Distribution Methods

### Mac App Store Distribution

1. **Build for App Store**
   ```bash
   fastlane build_app_store
   ```

2. **Upload to App Store Connect**
   ```bash
   fastlane release
   ```

3. **Submit for Review**
   - Use App Store Connect web interface
   - Or automate with Fastlane Deliver

### Direct Distribution

1. **Build and Sign**
   ```bash
   fastlane build_direct
   ```

2. **Create GitHub Release**
   ```bash
   fastlane github_release
   ```

3. **Distribute DMG**
   - Host on GitHub Releases
   - Or distribute via website

## 🔐 Security & Code Signing

### Certificate Management

Store certificates securely:

```bash
# Export certificate for CI/CD
security export -f pkcs12 -o dev.p12 \
    -k ~/Library/Keychains/login.keychain \
    -P "password"
```

### Environment Variables

Required for CI/CD:

```bash
# Apple Credentials
APPLE_TEAM_ID="YOUR_TEAM_ID"
APPLE_ID="your.email@example.com"
APPLE_APP_SPECIFIC_PASSWORD="app-specific-password"

# Certificates
DEVELOPER_CERTIFICATE_PATH="path/to/dev.p12"
DEVELOPER_CERTIFICATE_PASSWORD="cert-password"

# CI/CD
GITHUB_TOKEN="github-token"
```

## 📊 Performance Optimization

### Build Optimizations

1. **Parallel Compilation**
   ```bash
   xcodebuild -parallelizeTargets
   ```

2. **Build Caching**
   ```bash
   defaults write com.apple.dt.Xcode IDEBuildOperationMaxNumberOfConcurrentCompileTasks 8
   ```

3. **Dead Code Stripping**
   ```swift
   DEAD_CODE_STRIPPING = YES
   ```

### Runtime Optimizations

1. **Swift Whole Module Optimization**
   ```swift
   SWIFT_COMPILATION_MODE = wholemodule
   SWIFT_OPTIMIZATION_LEVEL = -O
   ```

2. **Link Time Optimization**
   ```swift
   LLVM_LTO = YES_THIN
   ```

## 🧪 Testing Strategy

### Test Types

1. **Unit Tests**: Business logic testing
2. **Integration Tests**: Component interaction
3. **UI Tests**: User interface testing
4. **Performance Tests**: Speed and memory usage

### Test Execution

```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter StickyNotesTests

# Run performance tests
swift test --filter StickyNotesPerformanceTests
```

### Code Coverage

```bash
# Generate coverage report
swift test --enable-code-coverage

# View coverage
xcrun llvm-cov show .build/debug/StickyNotesPackageTests.xctest \
    --instr-profile=.build/debug/codecov/default.profdata \
    --format=html > coverage.html
```

## 📈 Monitoring & Analytics

### Crash Reporting

```swift
// Integrate crash reporting
import CrashReporter

let crashReporter = CrashReporter.shared
crashReporter.start()
```

### Performance Monitoring

```swift
// Add performance metrics
import os.signpost

let signpostID = OSSignpostID(log: log)
os_signpost(.begin, log: log, name: "Note Creation", signpostID: signpostID)
// ... note creation code ...
os_signpost(.end, log: log, name: "Note Creation", signpostID: signpostID)
```

## 🚀 Release Process

### Version Management

1. **Update Version**
   ```swift
   MARKETING_VERSION = 1.1.0
   CURRENT_PROJECT_VERSION = 2
   ```

2. **Update Changelog**
   ```markdown
   ## [1.1.0] - 2024-01-15
   ### Added
   - New feature description
   ### Fixed
   - Bug fix description
   ```

3. **Create Git Tag**
   ```bash
   git tag -a v1.1.0 -m "Release version 1.1.0"
   git push origin v1.1.0
   ```

### Automated Release

```yaml
# GitHub Actions release workflow
name: Release
on:
  push:
    tags:
      - 'v*'
jobs:
  release:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - run: fastlane github_release
```

## 🔧 Troubleshooting

### Common Issues

#### Code Signing Problems
```bash
# Check certificate validity
security find-identity -v -p codesigning

# Verify app signature
codesign -vvv StickyNotes.app
```

#### Notarization Failures
```bash
# Check notarization status
xcrun notarytool log <submission-id> \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --team-id "$TEAM_ID"
```

#### Build Failures
```bash
# Clean build artifacts
rm -rf .build/
rm -rf ~/Library/Developer/Xcode/DerivedData/

# Reset package caches
swift package reset
```

## 📚 Additional Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Swift Package Manager Guide](https://swift.org/package-manager/)
- [Fastlane Documentation](https://docs.fastlane.tools/)
- [GitHub Actions for macOS](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners#supported-runners-and-hardware-resources)

---

*Last updated: September 21, 2024*