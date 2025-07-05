#!/bin/bash

# =============================================================================
# Swift Code Quality Check Script
# =============================================================================
# This script performs comprehensive code quality checks on Swift code.
#
# Features:
# - SwiftLint linting
# - SwiftFormat formatting
# - Static analysis
# - Complexity metrics
# - Security checks
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
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

print_warning() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ✗${NC} $1"
}

print_header() {
    echo ""
    echo -e "${WHITE}=============================================================================${NC}"
    echo -e "${WHITE} $1${NC}"
    echo -e "${WHITE}=============================================================================${NC}"
    echo ""
}

# Check if tools are installed
check_tools() {
    local missing_tools=()

    if ! command -v swiftformat &> /dev/null; then
        missing_tools+=("swiftformat")
    fi

    if ! command -v swiftlint &> /dev/null; then
        missing_tools+=("swiftlint")
    fi

    if ! command -v swift &> /dev/null; then
        missing_tools+=("swift")
    fi

    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        echo ""
        echo "Install using:"
        echo "  brew install swiftformat swiftlint"
        echo "  or install Xcode Command Line Tools for swift"
        exit 1
    fi
}

# Run SwiftLint
run_swiftlint() {
    print_status "Running SwiftLint..."

    if swiftlint --strict; then
        print_success "SwiftLint passed"
    else
        print_error "SwiftLint found issues"
        return 1
    fi
}

# Run SwiftFormat
run_swiftformat() {
    print_status "Running SwiftFormat..."

    # First check formatting
    if swiftformat --lint .; then
        print_success "SwiftFormat: Code is properly formatted"
    else
        print_warning "SwiftFormat: Code formatting issues found"

        # Fix formatting issues
        print_status "Fixing formatting issues..."
        if swiftformat .; then
            print_success "SwiftFormat: Code formatting fixed"
        else
            print_error "SwiftFormat: Failed to fix formatting"
            return 1
        fi
    fi
}

# Run Swift compiler checks
run_swift_checks() {
    print_status "Running Swift compiler checks..."

    # Check if we can compile the project
    if swift build --configuration debug > /dev/null 2>&1; then
        print_success "Swift compiler checks passed"
    else
        print_error "Swift compiler errors found"
        swift build --configuration debug
        return 1
    fi
}

# Analyze code complexity
analyze_complexity() {
    print_status "Analyzing code complexity..."

    local complexity_issues=0

    # Find long functions
    find Sources StickyNotes -name "*.swift" -exec grep -l "func.*{$" {} \; 2>/dev/null | while read -r file; do
        local lines=$(awk '/func/ {f=NR} /}/ {if (f) print NR - f + 1}' "$file")
        local func_name=$(grep "func.*{" "$file" | head -1 | sed 's/.*func *\([^)]*\).*/\1/')

        if [[ $lines -gt 50 ]]; then
            print_warning "Long function: $func_name ($lines lines) in $file"
            complexity_issues=$((complexity_issues + 1))
        fi
    done

    # Find deeply nested code
    local nested_issues=$(find Sources StickyNotes -name "*.swift" -exec awk '/^[[:space:]]*{/{print FILENAME":"NR}:/; /^[[:space:]]*}/}' {} \; 2>/dev/null | awk -F: 'NF>5 {print $1 " line " $2}' | wc -l)
    if [[ $nested_issues -gt 0 ]]; then
        print_warning "Deeply nested code blocks: $nested_issues"
        complexity_issues=$((complexity_issues + nested_issues))
    fi

    if [[ $complexity_issues -eq 0 ]]; then
        print_success "Code complexity is acceptable"
    else
        print_warning "Found $complexity_issues complexity issues"
    fi
}

# Check for security issues
check_security() {
    print_status "Checking for security issues..."

    local security_issues=0

    # Check for hardcoded URLs or endpoints
    if grep -r "http://.*" Sources StickyNotes --include="*.swift" 2>/dev/null | head -5; then
        print_warning "Hardcoded HTTP URLs found (should use HTTPS)"
        security_issues=$((security_issues + 1))
    fi

    # Check for potential sensitive data
    if grep -r -i "password\|secret\|token\|key" Sources StickyNotes --include="*.swift" 2>/dev/null | grep -v "//.*" | head -5; then
        print_warning "Potential sensitive data found in source code"
        security_issues=$((security_issues + 1))
    fi

    # Check for unsafe force unwrapping
    local force_unwraps=$(grep -r "!" Sources StickyNotes --include="*.swift" 2>/dev/null | grep -v "!" | wc -l || echo "0")
    if [[ $force_unwraps -gt 5 ]]; then
        print_warning "High number of force unwraps: $force_unwraps"
        security_issues=$((security_issues + 1))
    fi

    if [[ $security_issues -eq 0 ]]; then
        print_success "No obvious security issues found"
    else
        print_warning "Found $security_issues potential security issues"
    fi
}

# Generate quality report
generate_report() {
    local report_file="./reports/quality_report_$(date +"%Y%m%d_%H%M%S").md"
    mkdir -p "$(dirname "$report_file")"

    cat > "$report_file" << EOF
# Swift Code Quality Report

**Generated:** $(date)
**Project:** StickyNotes Desktop
**Repository:** github.com/sanchez314c/desktop-stickies

## Quality Metrics

- **Swift Version:** $(swift --version | head -1 | awk '{print $4}')
- **Build Status:** $([ -n "$BUILD_STATUS" ] && echo "$BUILD_STATUS" || echo "Not checked")
- **Linting:** $([ -n "$LINT_STATUS" ] && echo "$LINT_STATUS" || echo "Not checked")
- **Formatting:** $([ -n "$FORMAT_STATUS" ] && echo "$FORMAT_STATUS" || echo "Not checked")

## Issues Found

EOF

    echo "Quality report generated: $report_file"
}

# Main execution
main() {
    print_header "Swift Code Quality Analysis"
    echo "Analyzing StickyNotes Desktop project..."
    echo ""

    check_tools

    local issues_found=0

    # Run checks
    if ! run_swiftlint; then
        LINT_STATUS="Failed"
        issues_found=$((issues_found + 1))
    else
        LINT_STATUS="Passed"
    fi

    if ! run_swiftformat; then
        FORMAT_STATUS="Fixed"
        issues_found=$((issues_found + 1))
    else
        FORMAT_STATUS="Passed"
    fi

    if ! run_swift_checks; then
        BUILD_STATUS="Failed"
        issues_found=$((issues_found + 1))
    else
        BUILD_STATUS="Passed"
    fi

    analyze_complexity
    check_security
    generate_report

    print_header "Quality Analysis Complete"

    if [[ $issues_found -eq 0 ]]; then
        print_success "All quality checks passed!"
        exit 0
    else
        print_warning "$issues_found quality issues found"
        exit 1
    fi
}

# Run main function
main "$@"