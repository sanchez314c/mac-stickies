#!/bin/bash

# Run StickyNotes from Source on macOS
# Builds and launches the StickyNotes macOS application via xcodebuild or swift build.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status()  { echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"; }
print_success() { echo -e "${GREEN}[$(date +'%H:%M:%S')] OK${NC} $1"; }
print_warn()    { echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARN${NC} $1"; }
print_error()   { echo -e "${RED}[$(date +'%H:%M:%S')] ERR${NC} $1"; }

# Verify macOS
if [ "$(uname)" != "Darwin" ]; then
    print_error "This script is for macOS only. Use run-source-linux.sh on Linux."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# CPU core count for parallel builds
CORES=$(sysctl -n hw.logicalcpu 2>/dev/null || echo 4)
print_status "Using $CORES CPU cores"

# Prefer xcodebuild if Xcode project is present
XCODEPROJ="StickyNotes/StickyNotes.xcodeproj"
SCHEME="StickyNotes"
CONFIGURATION="${BUILD_CONFIG:-Debug}"

if [ -d "$XCODEPROJ" ]; then
    print_status "Xcode project detected: $XCODEPROJ"
    print_status "Scheme: $SCHEME | Configuration: $CONFIGURATION"

    # Check Xcode
    if ! command -v xcodebuild &>/dev/null; then
        print_error "xcodebuild not found. Install Xcode from the Mac App Store."
        exit 1
    fi

    XCODE_VERSION=$(xcodebuild -version 2>&1 | head -1)
    print_status "Xcode: $XCODE_VERSION"

    # Build
    print_status "Building StickyNotes..."
    xcodebuild \
        -project "$XCODEPROJ" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -jobs "$CORES" \
        build 2>&1 | xcpretty 2>/dev/null || xcodebuild \
        -project "$XCODEPROJ" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -jobs "$CORES" \
        build

    print_success "Build complete"

    # Find and launch the built app
    DERIVED_DATA=$(xcodebuild \
        -project "$XCODEPROJ" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -showBuildSettings 2>/dev/null | grep "BUILT_PRODUCTS_DIR" | head -1 | awk '{print $3}')

    if [ -n "$DERIVED_DATA" ] && [ -d "$DERIVED_DATA/StickyNotes.app" ]; then
        print_status "Launching StickyNotes.app..."
        open "$DERIVED_DATA/StickyNotes.app"
        print_success "Application launched"
    else
        print_warn "Could not auto-locate built .app. Run the app from Xcode or DerivedData."
    fi

elif command -v swift &>/dev/null; then
    # Fallback: SPM build for StickyNotesCore library
    print_warn "No Xcode project found. Falling back to SPM build (library only)."
    print_status "Building StickyNotesCore via swift build..."
    swift build -j "$CORES"
    print_success "SPM build complete"
    print_warn "Open Xcode to run the full GUI application."
else
    print_error "Neither xcodebuild nor swift found. Install Xcode 15+ from the Mac App Store."
    exit 1
fi
