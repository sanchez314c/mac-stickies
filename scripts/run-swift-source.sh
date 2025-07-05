#!/bin/bash

# Swift Source Run Script
# Runs the Swift application from source code in development mode

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/.."

# Function to print colored output
print_status() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] ✔${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ✗${NC} $1"
}

print_status "Starting Swift application from source..."

# Check if Swift is installed
if ! command -v swift &> /dev/null; then
    print_error "Swift is not installed. Please install Xcode or Swift toolchain."
    exit 1
fi

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This Swift application requires macOS."
    exit 1
fi

# Check for Package.swift
if [[ ! -f "Package.swift" ]]; then
    print_error "Package.swift not found. Not a Swift package."
    exit 1
fi

# Resolve dependencies
if [[ ! -d ".build" ]]; then
    print_status "Resolving dependencies..."
    swift package resolve
fi

# Build and run
print_status "Building and running application..."
swift run StickyNotesApp

print_success "Application executed successfully!"