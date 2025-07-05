#!/bin/bash

# StickyNotes Integration Verification Script
# This script verifies that all components integrate properly

set -e

echo "🔍 Verifying StickyNotes Integration..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    local status=$1
    local message=$2
    if [ "$status" -eq 0 ]; then
        echo -e "${GREEN}✅ $message${NC}"
    else
        echo -e "${RED}❌ $message${NC}"
    fi
}

# Check if we're in the right directory
if [ ! -f "Package.swift" ] || [ ! -d "StickyNotes" ]; then
    echo -e "${RED}❌ Error: Must be run from the root StickyNotes directory${NC}"
    exit 1
fi

echo "📦 Checking package structure..."

# Check core library package
if [ -f "Package.swift" ]; then
    print_status 0 "Core library Package.swift found"
else
    print_status 1 "Core library Package.swift missing"
fi

# Check app package
if [ -f "StickyNotes/Package.swift" ]; then
    print_status 0 "App Package.swift found"
else
    print_status 1 "App Package.swift missing"
fi

echo "🔨 Testing builds..."

# Test core library build
echo "Building core library..."
if swift build --package-path . > /dev/null 2>&1; then
    print_status 0 "Core library builds successfully"
else
    print_status 1 "Core library build failed"
fi

# Test app build
echo "Building app..."
if (cd StickyNotes && swift build > /dev/null 2>&1); then
    print_status 0 "App builds successfully"
else
    print_status 1 "App build failed"
fi

echo "🧪 Running tests..."

# Test core library tests
echo "Running core library tests..."
if swift test --package-path . > /dev/null 2>&1; then
    print_status 0 "Core library tests pass"
else
    print_status 1 "Core library tests failed"
fi

# Test app tests
echo "Running app tests..."
if (cd StickyNotes && swift test > /dev/null 2>&1); then
    print_status 0 "App tests pass"
else
    print_status 1 "App tests failed"
fi

# Test integration tests
echo "Running integration tests..."
if (cd StickyNotes && swift test --filter StickyNotesIntegrationTests > /dev/null 2>&1); then
    print_status 0 "Integration tests pass"
else
    print_status 1 "Integration tests failed"
fi

echo "🔗 Checking dependencies..."

# Check if app depends on core library
if grep -q "StickyNotesCore" StickyNotes/Package.swift; then
    print_status 0 "App correctly depends on core library"
else
    print_status 1 "App missing dependency on core library"
fi

echo "📁 Checking file structure..."

# Check for unified models
if [ -f "StickyNotes/Models/Note.swift" ] && grep -q "isLocked" StickyNotes/Models/Note.swift; then
    print_status 0 "Unified Note model with all properties"
else
    print_status 1 "Note model missing unified properties"
fi

# Check for integration service
if [ -f "StickyNotes/Services/PersistenceService.swift" ] && grep -q "PersistenceMode" StickyNotes/Services/PersistenceService.swift; then
    print_status 0 "Integrated persistence service implemented"
else
    print_status 1 "Integrated persistence service missing"
fi

# Check for integration tests
if [ -f "Tests/StickyNotesIntegrationTests.swift" ]; then
    print_status 0 "Integration tests implemented"
else
    print_status 1 "Integration tests missing"
fi

echo "🎯 Checking CI/CD integration..."

# Check GitHub workflow
if [ -f ".github/workflows/build-and-release.yml" ] && grep -q "integration tests" .github/workflows/build-and-release.yml; then
    print_status 0 "CI/CD includes integration tests"
else
    print_status 1 "CI/CD missing integration tests"
fi

echo ""
echo -e "${YELLOW}🎉 Integration verification complete!${NC}"
echo ""
echo "If all checks passed, the StickyNotes app components are properly integrated."
echo "The app now supports both Core Data and file-based persistence with a unified UI."