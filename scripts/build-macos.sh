#!/bin/bash

# macOS Build Script for StickyNotes
# Handles building, signing, and packaging for both development and distribution

set -e

# Configuration
APP_NAME="StickyNotes"
BUNDLE_ID="com.superclaude.stickynotes"
BUILD_DIR="build"
ARCHIVE_NAME="${APP_NAME}.xcarchive"
EXPORT_DIR="export"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Functions
print_status() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] ✔${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ✗${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "StickyNotes/Package.swift" ]; then
    print_error "Package.swift not found. Run this script from the project root."
    exit 1
fi

# Parse command line arguments
BUILD_TYPE="development"
SIGNING_IDENTITY=""
TEAM_ID=""
ENTITLEMENTS_FILE=""
NOTARIZE=false
UPLOAD_TO_APP_STORE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --development)
            BUILD_TYPE="development"
            shift
            ;;
        --app-store)
            BUILD_TYPE="app-store"
            ENTITLEMENTS_FILE="Resources/StickyNotes-MAS.entitlements"
            shift
            ;;
        --direct-distribution)
            BUILD_TYPE="direct-distribution"
            ENTITLEMENTS_FILE="Resources/StickyNotes.entitlements"
            NOTARIZE=true
            shift
            ;;
        --signing-identity)
            SIGNING_IDENTITY="$2"
            shift 2
            ;;
        --team-id)
            TEAM_ID="$2"
            shift 2
            ;;
        --notarize)
            NOTARIZE=true
            shift
            ;;
        --upload-app-store)
            UPLOAD_TO_APP_STORE=true
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --development          Build for development (default)"
            echo "  --app-store           Build for Mac App Store"
            echo "  --direct-distribution  Build for direct distribution"
            echo "  --signing-identity ID  Code signing identity"
            echo "  --team-id ID          Apple Developer Team ID"
            echo "  --notarize            Notarize the app"
            echo "  --upload-app-store    Upload to App Store Connect"
            echo "  --help                Show this help"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

print_status "Starting ${BUILD_TYPE} build for ${APP_NAME}"

# Clean previous builds
print_status "Cleaning previous builds..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Build with Swift Package Manager
print_status "Building with Swift Package Manager..."

# Build for both architectures from StickyNotes directory
print_status "Building for Apple Silicon (ARM64)..."
cd StickyNotes
swift build -c release --arch arm64

print_status "Building for Intel (x86_64)..."
swift build -c release --arch x86_64

# Create universal binary
print_status "Creating universal binary..."
lipo -create \
    .build/arm64-apple-macosx/release/StickyNotes \
    .build/x86_64-apple-macosx/release/StickyNotes \
    -output .build/release/StickyNotes

print_success "Universal binary created"

# Create app bundle structure
print_status "Creating app bundle..."
APP_BUNDLE="../${BUILD_DIR}/${APP_NAME}.app"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy binary
cp ".build/release/StickyNotes" "${APP_BUNDLE}/Contents/MacOS/"

# Copy Info.plist
cp "Resources/Info.plist" "${APP_BUNDLE}/Contents/"

# Copy entitlements if specified
if [ -n "$ENTITLEMENTS_FILE" ]; then
    cp "$ENTITLEMENTS_FILE" "${APP_BUNDLE}/Contents/"
fi

# Go back to project root
cd ..

print_success "App bundle created at ${APP_BUNDLE}"

# Code signing
if [ -n "$SIGNING_IDENTITY" ]; then
    print_status "Code signing app bundle..."

    if [ "$BUILD_TYPE" = "app-store" ]; then
        # App Store signing
        codesign --force --deep --sign "$SIGNING_IDENTITY" \
            --entitlements "$ENTITLEMENTS_FILE" \
            --options runtime \
            "$APP_BUNDLE"
    else
        # Direct distribution signing
        codesign --force --deep --sign "$SIGNING_IDENTITY" \
            --entitlements "$ENTITLEMENTS_FILE" \
            --options runtime \
            "$APP_BUNDLE"
    fi

    print_success "App bundle signed"
fi

# Create DMG for direct distribution
if [ "$BUILD_TYPE" = "direct-distribution" ]; then
    print_status "Creating DMG package..."

    DMG_NAME="${APP_NAME}.dmg"
    hdiutil create -volname "${APP_NAME}" \
        -srcfolder "$APP_BUNDLE" \
        -ov -format UDZO \
        "${BUILD_DIR}/${DMG_NAME}"

    print_success "DMG created: ${BUILD_DIR}/${DMG_NAME}"
fi

# Notarization for direct distribution
if [ "$NOTARIZE" = true ] && [ -f "${BUILD_DIR}/${APP_NAME}.dmg" ]; then
    print_status "Submitting for notarization..."

    if [ -z "$APPLE_ID" ] || [ -z "$APPLE_APP_SPECIFIC_PASSWORD" ]; then
        print_error "Apple ID credentials not set for notarization"
        print_error "Set APPLE_ID and APPLE_APP_SPECIFIC_PASSWORD environment variables"
        exit 1
    fi

    # Submit for notarization
    NOTARY_RESPONSE=$(xcrun notarytool submit "${BUILD_DIR}/${APP_NAME}.dmg" \
        --apple-id "$APPLE_ID" \
        --password "$APPLE_APP_SPECIFIC_PASSWORD" \
        --team-id "$TEAM_ID" \
        --wait \
        --output-format json)

    # Check notarization status
    if echo "$NOTARY_RESPONSE" | grep -q '"status":"Accepted"'; then
        print_success "Notarization successful"

        # Staple notarization ticket
        xcrun stapler staple "${BUILD_DIR}/${APP_NAME}.dmg"
        print_success "Notarization ticket stapled"
    else
        print_error "Notarization failed"
        echo "$NOTARY_RESPONSE"
        exit 1
    fi
fi

# App Store upload
if [ "$UPLOAD_TO_APP_STORE" = true ]; then
    print_status "Uploading to App Store Connect..."

    if [ -z "$APPLE_ID" ] || [ -z "$APPLE_APP_SPECIFIC_PASSWORD" ]; then
        print_error "Apple ID credentials not set for App Store upload"
        exit 1
    fi

    # Create export options for App Store
    cat > exportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>${TEAM_ID}</string>
    <key>uploadSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
</dict>
</plist>
EOF

    # Upload to App Store Connect
    xcrun altool --upload-app \
        --type macos \
        --file "$APP_BUNDLE" \
        --username "$APPLE_ID" \
        --password "$APPLE_APP_SPECIFIC_PASSWORD"

    print_success "App uploaded to App Store Connect"
fi

print_success "Build completed successfully!"
print_status "Output location: ${BUILD_DIR}"

# List build artifacts
echo ""
print_info "Build artifacts:"
if [ -d "$APP_BUNDLE" ]; then
    echo "  • App Bundle: $APP_BUNDLE"
fi
if [ -f "${BUILD_DIR}/${APP_NAME}.dmg" ]; then
    echo "  • DMG Package: ${BUILD_DIR}/${APP_NAME}.dmg"
fi

echo ""
print_status "Build Summary:"
echo "  Build Type: $BUILD_TYPE"
echo "  Signed: $([ -n "$SIGNING_IDENTITY" ] && echo "Yes" || echo "No")"
echo "  Notarized: $([ "$NOTARIZE" = true ] && echo "Yes" || echo "No")"
echo "  App Store: $([ "$UPLOAD_TO_APP_STORE" = true ] && echo "Yes" || echo "No")"