#!/bin/bash

# Repository Validation Script
# Validates repository structure, documentation, and quality standards

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counter for results
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASSED_CHECKS++))
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARNINGS++))
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    ((FAILED_CHECKS++))
}

increment_total() {
    ((TOTAL_CHECKS++))
}

# Start validation
echo "🔍 Repository Validation Started"
echo "================================"

# 1. Repository Structure Validation
echo ""
echo "📁 Repository Structure Validation"
echo "-------------------------------"

increment_total
if [ -f "Package.swift" ]; then
    log_success "Package.swift exists"
else
    log_error "Package.swift missing"
fi

increment_total
if [ -d "Sources" ]; then
    log_success "Sources directory exists"
else
    log_error "Sources directory missing"
fi

increment_total
if [ -d "Tests" ]; then
    log_success "Tests directory exists"
else
    log_error "Tests directory missing"
fi

increment_total
if [ -d "docs" ]; then
    log_success "docs directory exists"
else
    log_error "docs directory missing"
fi

increment_total
if [ -f "README.md" ]; then
    log_success "README.md exists"
else
    log_error "README.md missing"
fi

increment_total
if [ -f "LICENSE" ]; then
    log_success "LICENSE file exists"
else
    log_error "LICENSE file missing"
fi

# 2. Documentation Validation
echo ""
echo "📚 Documentation Validation"
echo "-------------------------"

# Check for essential documentation files
essential_docs=("CHANGELOG.md" "CONTRIBUTING.md" "CODE_OF_CONDUCT.md" "SUPPORT.md" "SECURITY.md" "GOVERNANCE.md")

for doc in "${essential_docs[@]}"; do
    increment_total
    if [ -f "$doc" ]; then
        log_success "$doc exists"
    else
        log_error "$doc missing"
    fi
done

# Check documentation quality
increment_total
if [ -s "README.md" ] && [ $(wc -l < README.md) -gt 20 ]; then
    log_success "README.md has substantial content"
else
    log_warning "README.md needs more content"
fi

increment_total
if grep -q "## Installation" README.md; then
    log_success "README.md contains installation instructions"
else
    log_warning "README.md missing installation instructions"
fi

increment_total
if grep -q "## Usage" README.md; then
    log_success "README.md contains usage instructions"
else
    log_warning "README.md missing usage instructions"
fi

# 3. Code Quality Validation
echo ""
echo "🔧 Code Quality Validation"
echo "-------------------------"

increment_total
if [ -d "Sources/StickyNotes" ]; then
    log_success "Main app source directory exists"
else
    log_error "Main app source directory missing"
fi

increment_total
swift_file_count=$(find Sources/ -name "*.swift" -type f | wc -l)
if [ $swift_file_count -gt 0 ]; then
    log_success "Found $swift_file_count Swift source files"
else
    log_error "No Swift source files found"
fi

increment_total
if [ -f ".swiftlint.yml" ] || [ -f "config/.swiftlint.yml" ]; then
    log_success "SwiftLint configuration exists"
else
    log_warning "SwiftLint configuration missing"
fi

# 4. Testing Validation
echo ""
echo "🧪 Testing Validation"
echo "--------------------"

increment_total
test_count=$(find Tests/ -name "*Tests.swift" -type f | wc -l)
if [ $test_count -gt 0 ]; then
    log_success "Found $test_count test files"
else
    log_error "No test files found"
fi

increment_total
if [ -d "Tests/StickyNotesTests" ]; then
    log_success "Unit test directory exists"
else
    log_warning "Unit test directory missing"
fi

increment_total
if [ -d "Tests/StickyNotesIntegrationTests" ]; then
    log_success "Integration test directory exists"
else
    log_warning "Integration test directory missing"
fi

# 5. Build System Validation
echo ""
echo "🏗️ Build System Validation"
echo "--------------------------"

increment_total
if [ -d "scripts" ]; then
    log_success "Build scripts directory exists"
else
    log_warning "Build scripts directory missing"
fi

increment_total
if [ -f "scripts/build-macos.sh" ]; then
    log_success "macOS build script exists"
else
    log_warning "macOS build script missing"
fi

increment_total
if [ -f "scripts/build-multi-platform.sh" ]; then
    log_success "Multi-platform build script exists"
else
    log_warning "Multi-platform build script missing"
fi

# 6. GitHub Configuration Validation
echo ""
echo "🐙 GitHub Configuration Validation"
echo "--------------------------------"

increment_total
if [ -d ".github" ]; then
    log_success ".github directory exists"
else
    log_error ".github directory missing"
fi

increment_total
if [ -d ".github/workflows" ]; then
    log_success "GitHub workflows directory exists"
else
    log_error "GitHub workflows directory missing"
fi

increment_total
if [ -f ".github/ISSUE_TEMPLATE/bug_report.md" ]; then
    log_success "Bug report template exists"
else
    log_warning "Bug report template missing"
fi

increment_total
if [ -f ".github/ISSUE_TEMPLATE/feature_request.md" ]; then
    log_success "Feature request template exists"
else
    log_warning "Feature request template missing"
fi

increment_total
if [ -f ".github/PULL_REQUEST_TEMPLATE.md" ]; then
    log_success "PR template exists"
else
    log_warning "PR template missing"
fi

# 7. Security Validation
echo ""
echo "🔒 Security Validation"
echo "----------------------"

increment_total
if [ -f ".gitignore" ]; then
    log_success ".gitignore exists"
else
    log_error ".gitignore missing"
fi

increment_total
if grep -q ".DS_Store" .gitignore; then
    log_success ".gitignore excludes .DS_Store"
else
    log_warning ".gitignore should exclude .DS_Store"
fi

increment_total
if grep -q "*.xcuserstate" .gitignore; then
    log_success ".gitignore excludes Xcode user state"
else
    log_warning ".gitignore should exclude *.xcuserstate"
fi

# Check for potential security issues
increment_total
if ! grep -r -i "password\|secret\|key\|token" Sources/ --include="*.swift" | grep -v "//.*password\|//.*secret\|//.*key\|//.*token" > /dev/null 2>&1; then
    log_success "No obvious hardcoded secrets found"
else
    log_error "Potential hardcoded secrets detected"
fi

# 8. Performance Validation
echo ""
echo "⚡ Performance Validation"
echo "------------------------"

increment_total
if [ -d "Tests/StickyNotesPerformanceTests" ]; then
    log_success "Performance test directory exists"
else
    log_warning "Performance test directory missing"
fi

increment_total
large_files=$(find Sources/ -name "*.swift" -size +50k | wc -l)
if [ $large_files -eq 0 ]; then
    log_success "No excessively large source files"
else
    log_warning "Found $large_files large source files (>50KB)"
fi

# 9. Documentation Completeness
echo ""
echo "📖 Documentation Completeness"
echo "-----------------------------"

increment_total
if [ -f "docs/ARCHITECTURE.md" ]; then
    log_success "Architecture documentation exists"
else
    log_warning "Architecture documentation missing"
fi

increment_total
if [ -f "docs/API.md" ]; then
    log_success "API documentation exists"
else
    log_warning "API documentation missing"
fi

increment_total
if [ -d "docs/user" ]; then
    log_success "User documentation directory exists"
else
    log_warning "User documentation directory missing"
fi

increment_total
if [ -d "docs/developer" ]; then
    log_success "Developer documentation directory exists"
else
    log_warning "Developer documentation directory missing"
fi

# 10. Repository Health
echo ""
echo "🏥 Repository Health"
echo "-------------------"

increment_total
if git rev-parse --git-dir > /dev/null 2>&1; then
    log_success "Git repository initialized"
else
    log_error "Not a git repository"
fi

increment_total
if [ -n "$(git status --porcelain)" ]; then
    log_warning "Repository has uncommitted changes"
else
    log_success "Repository is clean"
fi

increment_total
if git remote get-url origin > /dev/null 2>&1; then
    log_success "Origin remote configured"
else
    log_warning "No origin remote configured"
fi

# Results Summary
echo ""
echo "📊 Validation Results"
echo "===================="
echo "Total checks: $TOTAL_CHECKS"
echo -e "Passed: ${GREEN}$PASSED_CHECKS${NC}"
echo -e "Failed: ${RED}$FAILED_CHECKS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"

# Calculate success rate
success_rate=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
echo "Success rate: $success_rate%"

# Final verdict
echo ""
if [ $FAILED_CHECKS -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}🎉 Excellent! Repository validation passed with no issues.${NC}"
        exit 0
    else
        echo -e "${YELLOW}✅ Repository validation passed with $WARNINGS warnings.${NC}"
        echo "Consider addressing the warnings for optimal repository health."
        exit 0
    fi
else
    echo -e "${RED}❌ Repository validation failed with $FAILED_CHECKS errors.${NC}"
    echo "Please address the critical issues before proceeding."
    exit 1
fi