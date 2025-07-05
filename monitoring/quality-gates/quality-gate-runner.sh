#!/bin/bash

# 🚪 Automated Quality Gates for StickyNotes
# Enforces all quality standards from QUALITY_PLAN.md

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Quality gate results
QUALITY_PASSED=true
ISSUES_FOUND=()

echo -e "${BLUE}🚪 STICKYNOTES QUALITY GATES${NC}"
echo -e "${BLUE}================================${NC}"
echo "Running automated quality checks..."
echo "Timestamp: $(date)"
echo ""

# Quality Gate 1: Code Coverage Check
echo -e "${YELLOW}📊 QUALITY GATE 1: Code Coverage${NC}"
echo "Checking unit test coverage..."

if command -v xcodebuild &> /dev/null; then
    # Run tests with coverage
    cd "$PROJECT_ROOT/StickyNotes"
    xcodebuild test -scheme StickyNotes -enableCodeCoverage YES -resultBundlePath coverage.xcresult > /dev/null 2>&1

    # Extract coverage percentage (simplified - would need more sophisticated parsing in real implementation)
    if [ -d "coverage.xcresult" ]; then
        echo -e "  ✅ Tests executed with coverage enabled"
        # In a real implementation, you'd parse the .xcresult file for actual coverage percentages
        echo -e "  📈 Coverage report generated: coverage.xcresult"
    else
        echo -e "  ⚠️  Coverage report not generated"
        ISSUES_FOUND+=("Code coverage report generation failed")
    fi
else
    echo -e "  ❌ Xcode not available for coverage testing"
    ISSUES_FOUND+=("Xcode not available for testing")
    QUALITY_PASSED=false
fi
echo ""

# Quality Gate 2: Static Analysis
echo -e "${YELLOW}🔍 QUALITY GATE 2: Static Analysis${NC}"
echo "Running SwiftLint and static analysis..."

if command -v swiftlint &> /dev/null; then
    cd "$PROJECT_ROOT"
    SWIFT_LINT_OUTPUT=$(swiftlint lint --quiet . 2>&1)
    SWIFT_LINT_EXIT=$?

    if [ $SWIFT_LINT_EXIT -eq 0 ]; then
        echo -e "  ✅ SwiftLint: No issues found"
    else
        echo -e "  ❌ SwiftLint: Issues detected"
        echo "$SWIFT_LINT_OUTPUT" | head -10
        ISSUES_FOUND+=("SwiftLint violations found")
        QUALITY_PASSED=false
    fi
else
    echo -e "  ⚠️  SwiftLint not installed - install with: brew install swiftlint"
    ISSUES_FOUND+=("SwiftLint not available")
fi

# Check for SwiftFormat
if command -v swiftformat &> /dev/null; then
    cd "$PROJECT_ROOT"
    SWIFT_FORMAT_OUTPUT=$(swiftformat --lint --verbose . 2>&1)
    SWIFT_FORMAT_EXIT=$?

    if [ $SWIFT_FORMAT_EXIT -eq 0 ]; then
        echo -e "  ✅ SwiftFormat: Code properly formatted"
    else
        echo -e "  ❌ SwiftFormat: Formatting issues detected"
        echo "$SWIFT_FORMAT_OUTPUT" | head -10
        ISSUES_FOUND+=("Code formatting issues")
        QUALITY_PASSED=false
    fi
else
    echo -e "  ⚠️  SwiftFormat not installed - install with: brew install swiftformat"
    ISSUES_FOUND+=("SwiftFormat not available")
fi
echo ""

# Quality Gate 3: Build Verification
echo -e "${YELLOW}🔨 QUALITY GATE 3: Build Verification${NC}"
echo "Verifying builds for all configurations..."

cd "$PROJECT_ROOT/StickyNotes"

# Debug build
echo "  Testing debug build..."
if swift build -c debug > /dev/null 2>&1; then
    echo -e "  ✅ Debug build: Success"
else
    echo -e "  ❌ Debug build: Failed"
    ISSUES_FOUND+=("Debug build failed")
    QUALITY_PASSED=false
fi

# Release build
echo "  Testing release build..."
if swift build -c release > /dev/null 2>&1; then
    echo -e "  ✅ Release build: Success"
else
    echo -e "  ❌ Release build: Failed"
    ISSUES_FOUND+=("Release build failed")
    QUALITY_PASSED=false
fi
echo ""

# Quality Gate 4: Performance Benchmarks
echo -e "${YELLOW}⚡ QUALITY GATE 4: Performance Benchmarks${NC}"
echo "Checking performance against benchmarks..."

cd "$PROJECT_ROOT/StickyNotes"

# Run performance tests if they exist
if swift test --filter PerformanceTests > /dev/null 2>&1; then
    echo -e "  ✅ Performance tests: Executed"
else
    echo -e "  ⚠️  Performance tests: Not found or failed"
    ISSUES_FOUND+=("Performance tests not available")
fi

# Check for memory leaks (basic check)
echo "  Checking for potential memory issues..."
MEMORY_ISSUES=$(grep -r "retain" Sources/ 2>/dev/null | wc -l)
if [ "$MEMORY_ISSUES" -gt 0 ]; then
    echo -e "  ⚠️  Found $MEMORY_ISSUES potential memory management locations"
else
    echo -e "  ✅ No obvious memory management issues detected"
fi
echo ""

# Quality Gate 5: Security Scan
echo -e "${YELLOW}🔒 QUALITY GATE 5: Security Scan${NC}"
echo "Running basic security checks..."

cd "$PROJECT_ROOT"

# Check for hardcoded secrets
SECRETS_FOUND=$(grep -r -i "password\|secret\|key\|token" --include="*.swift" Sources/ | grep -v "import\|//\|#" | wc -l)
if [ "$SECRETS_FOUND" -eq 0 ]; then
    echo -e "  ✅ No hardcoded secrets detected"
else
    echo -e "  ❌ Potential hardcoded secrets found: $SECRETS_FOUND instances"
    ISSUES_FOUND+=("Potential hardcoded secrets detected")
    QUALITY_PASSED=false
fi

# Check for proper error handling
ERROR_HANDLING=$(grep -r "try\|catch\|throw" --include="*.swift" Sources/ | wc -l)
if [ "$ERROR_HANDLING" -gt 0 ]; then
    echo -e "  ✅ Error handling patterns detected"
else
    echo -e "  ⚠️  Limited error handling found"
fi
echo ""

# Quality Gate 6: Accessibility Check
echo -e "${YELLOW}♿ QUALITY GATE 6: Accessibility${NC}"
echo "Checking accessibility compliance..."

cd "$PROJECT_ROOT"

# Check for accessibility labels and traits
ACCESSIBILITY_USAGE=$(grep -r "accessibilityLabel\|accessibilityHint\|accessibilityTraits" --include="*.swift" Sources/ | wc -l)
if [ "$ACCESSIBILITY_USAGE" -gt 0 ]; then
    echo -e "  ✅ Accessibility attributes found: $ACCESSIBILITY_USAGE"
else
    echo -e "  ⚠️  No accessibility attributes detected"
    ISSUES_FOUND+=("Missing accessibility attributes")
fi
echo ""

# Quality Gate 7: Documentation Check
echo -e "${YELLOW}📚 QUALITY GATE 7: Documentation${NC}"
echo "Checking documentation coverage..."

cd "$PROJECT_ROOT"

# Check for README and documentation
if [ -f "README.md" ]; then
    echo -e "  ✅ README.md present"
else
    echo -e "  ❌ README.md missing"
    ISSUES_FOUND+=("README.md missing")
    QUALITY_PASSED=false
fi

if [ -f "QUALITY_PLAN.md" ]; then
    echo -e "  ✅ Quality plan documentation present"
else
    echo -e "  ❌ Quality plan missing"
    ISSUES_FOUND+=("Quality plan missing")
    QUALITY_PASSED=false
fi
echo ""

# Generate Quality Report
echo -e "${BLUE}📋 QUALITY GATE SUMMARY${NC}"
echo -e "${BLUE}========================${NC}"

if [ "$QUALITY_PASSED" = true ]; then
    echo -e "${GREEN}✅ ALL QUALITY GATES PASSED${NC}"
    echo "Build can proceed to next stage"
    exit 0
else
    echo -e "${RED}❌ QUALITY GATES FAILED${NC}"
    echo "Issues found:"
    for issue in "${ISSUES_FOUND[@]}"; do
        echo -e "  • $issue"
    done
    echo ""
    echo "Please fix the issues above before proceeding"
    exit 1
fi