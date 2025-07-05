#!/bin/bash

# Run StickyNotes from Source on Linux
# NOTE: This is a macOS-only Swift/SwiftUI application.
# Linux support is limited to Swift Package Manager build of the StickyNotesCore library only.
# The full GUI application requires macOS 13.0+ and Xcode.

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

print_warn "StickyNotes is a macOS-only application."
print_warn "On Linux, only the StickyNotesCore SPM library can be built (no GUI)."
echo ""

# Check for Swift toolchain
if ! command -v swift &>/dev/null; then
    print_error "Swift toolchain not found. Install Swift from https://swift.org/download/"
    exit 1
fi

SWIFT_VERSION=$(swift --version 2>&1 | head -1)
print_status "Swift: $SWIFT_VERSION"

# Build StickyNotesCore library via SPM (Linux-compatible target only)
print_status "Building StickyNotesCore library (Linux SPM build)..."

CORES=$(nproc 2>/dev/null || echo 4)
print_status "Using $CORES CPU cores"

swift build -j "$CORES" --product StickyNotesCore 2>&1
BUILD_EXIT=$?

if [ $BUILD_EXIT -eq 0 ]; then
    print_success "StickyNotesCore library built successfully"
    echo ""
    print_warn "To run the full GUI application, use macOS with run-source-mac.sh"
else
    print_error "Build failed. The macOS-specific targets (AppKit, SwiftUI) cannot compile on Linux."
    print_warn "Use a macOS system with Xcode 15+ to build and run the full application."
    exit $BUILD_EXIT
fi

# Run tests (library tests only — no UI tests on Linux)
print_status "Running StickyNotesCore unit tests..."
swift test -j "$CORES" --filter StickyNotesCoreTests 2>&1
TEST_EXIT=$?

if [ $TEST_EXIT -eq 0 ]; then
    print_success "Core library tests passed"
else
    print_error "Tests failed (exit $TEST_EXIT)"
    exit $TEST_EXIT
fi
