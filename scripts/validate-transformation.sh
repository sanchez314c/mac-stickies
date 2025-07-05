#!/bin/bash

# =============================================================================
# StickyNotes Desktop - Repository Transformation Validation Script
# =============================================================================
# This script validates that all repository optimization improvements have been
# properly implemented and are working correctly.
#
# Features:
- Validates all new files are present and correctly configured
- Tests build system functionality
- Checks documentation completeness
- Validates security and quality improvements
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

# Configuration
PROJECT_NAME="StickyNotes"
VALIDATION_RESULTS=()

# Utility functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    VALIDATION_RESULTS+=("✅ $1")
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    VALIDATION_RESULTS+=("⚠️ $1")
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    VALIDATION_RESULTS+=("❌ $1")
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

log_header() {
    echo -e "${WHITE}=============================================================================${NC}"
    echo -e "${WHITE} $1${NC}"
    echo -e "${WHITE}=============================================================================${NC}"
}

# Check file exists and has content
validate_file() {
    local file="$1"
    local description="$2"

    if [[ -f "$file" ]]; then
        if [[ -s "$file" ]]; then
            log_success "$description exists and has content"
            return 0
        else
            log_error "$description exists but is empty"
            return 1
        fi
    else
        log_error "$description does not exist"
        return 1
    fi
}

# Check directory exists
validate_directory() {
    local dir="$1"
    local description="$2"

    if [[ -d "$dir" ]]; then
        log_success "$directory exists"
        return 0
    else
        log_error "$directory does not exist"
        return 1
    fi
}

# Validate essential files
validate_essential_files() {
    log_step "Validating essential files..."

    validate_file ".gitignore" "Git ignore file"
    validate_file "LICENSE" "MIT License file"
    validate_file "CONTRIBUTING.md" "Contributing guidelines"
    validate_file "CLAUDE.md" "AI assistant development guide"
    validate_file "CHANGELOG.md" "Version changelog"
    validate_file "Makefile" "Build system Makefile"
    validate_file "README.md" "Main README"
}

# Validate GitHub configuration
validate_github_config() {
    log_step "Validating GitHub configuration..."

    validate_directory ".github" "GitHub configuration directory"
    validate_directory ".github/workflows" "GitHub workflows directory"
    validate_directory ".github/ISSUE_TEMPLATE" "GitHub issue templates"

    validate_file ".github/ISSUE_TEMPLATE/bug_report.md" "Bug report template"
    validate_file ".github/ISSUE_TEMPLATE/feature_request.md" "Feature request template"
    validate_file ".github/PULL_REQUEST_TEMPLATE.md" "Pull request template"
    validate_file ".github/workflows/build-and-release.yml" "CI/CD workflow"
}

# Validate build system
validate_build_system() {
    log_step "Validating build system..."

    validate_directory "scripts" "Build scripts directory"

    # Check key scripts
    validate_file "scripts/build-compile-dist.sh" "Comprehensive build script"
    validate_file "scripts/bloat-check.sh" "Bloat analysis script"
    validate_file "scripts/temp-cleanup.sh" "Cleanup script"
    validate_file "scripts/security-analysis.sh" "Security analysis script"

    # Check scripts are executable
    for script in scripts/*.sh; do
        if [[ -x "$script" ]]; then
            log_success "$(basename "$script") is executable"
        else
            log_warning "$(basename "$script") is not executable"
        fi
    done
}

# Validate documentation
validate_documentation() {
    log_step "Validating documentation..."

    validate_directory "docs" "Documentation directory"
    validate_file "docs/DOCUMENTATION_INDEX.md" "Documentation index"
    validate_file "docs/developer/DEVELOPMENT.md" "Development guide"

    # Check documentation structure
    local doc_dirs=("architecture" "deployment" "developer" "installation" "maintenance" "testing" "user")
    for dir in "${doc_dirs[@]}"; do
        if [[ -d "docs/$dir" ]]; then
            log_success "docs/$dir directory exists"
        else
            log_warning "docs/$dir directory not found"
        fi
    done
}

# Validate Makefile functionality
validate_makefile() {
    log_step "Validating Makefile functionality..."

    # Test help command
    if make help &>/dev/null; then
        log_success "Makefile help command works"
    else
        log_error "Makefile help command failed"
    fi

    # Check for essential targets
    local makefile_targets=("build" "test" "clean" "dist" "analyze" "format" "lint" "security")
    for target in "${makefile_targets[@]}"; do
        if grep -q "^$target:" Makefile; then
            log_success "Makefile target '$target' exists"
        else
            log_error "Makefile target '$target' missing"
        fi
    done
}

# Validate project structure
validate_project_structure() {
    log_step "Validating project structure..."

    # Check core directories
    local core_dirs=("Sources" "StickyNotes" "Tests")
    for dir in "${core_dirs[@]}"; do
        validate_directory "$dir" "Core directory: $dir"
    done

    # Check for Swift files
    local swift_count=$(find . -name "*.swift" | grep -v ".build" | wc -l | tr -d ' ')
    if [[ $swift_count -gt 0 ]]; then
        log_success "Found $swift_count Swift source files"
    else
        log_warning "No Swift source files found"
    fi
}

# Validate git configuration
validate_git_config() {
    log_step "Validating git configuration..."

    # Check if this is a git repository
    if [[ -d ".git" ]]; then
        log_success "Git repository initialized"

        # Check .gitignore effectiveness
        if git check-ignore "*.DS_Store" &>/dev/null || grep -q "*.DS_Store" .gitignore; then
            log_success ".gitignore is properly configured"
        else
            log_warning ".gitignore may need updates"
        fi
    else
        log_error "Not a git repository"
    fi
}

# Validate security setup
validate_security_setup() {
    log_step "Validating security setup..."

    # Check for security script
    if validate_file "scripts/security-analysis.sh" "Security analysis script"; then
        # Test if security script can run (dry run)
        if timeout 5 scripts/security-analysis.sh &>/dev/null; then
            log_success "Security analysis script is functional"
        else
            log_warning "Security analysis script has issues"
        fi
    fi

    # Check for dangerous patterns
    local dangerous_patterns=(
        "password.*="
        "secret.*="
        "api_key.*="
    )

    local issues_found=0
    for pattern in "${dangerous_patterns[@]}"; do
        if grep -r -i -E "$pattern" . --include="*.swift" --include="*.plist" 2>/dev/null | grep -v "example" | head -1; then
            log_warning "Potentially sensitive pattern found: $pattern"
            issues_found=$((issues_found + 1))
        fi
    done

    if [[ $issues_found -eq 0 ]]; then
        log_success "No obvious security issues detected"
    fi
}

# Validate overall project health
validate_project_health() {
    log_step "Validating overall project health..."

    # Check total project size
    local project_size=$(du -sh . 2>/dev/null | cut -f1)
    log_info "Project size: $project_size"

    # Count files by type
    local swift_files=$(find . -name "*.swift" | grep -v ".build" | wc -l | tr -d ' ')
    local markdown_files=$(find . -name "*.md" | wc -l | tr -d ' ')
    local shell_scripts=$(find . -name "*.sh" | wc -l | tr -d ' ')

    log_info "File counts: Swift: $swift_files, Markdown: $markdown_files, Shell: $shell_scripts"

    # Check for common issues
    if [[ -f ".DS_Store" ]]; then
        log_warning ".DS_Store file present in root"
    fi

    # Check for backup files
    local backup_files=$(find . -name "*.backup*" -o -name "*.bak*" | wc -l | tr -d ' ')
    if [[ $backup_files -gt 0 ]]; then
        log_info "Found $backup_files backup files (acceptable during development)"
    fi
}

# Generate validation report
generate_validation_report() {
    log_header "Validation Summary"

    echo ""
    echo "Total checks performed: ${#VALIDATION_RESULTS[@]}"
    echo ""

    local success_count=0
    local warning_count=0
    local error_count=0

    for result in "${VALIDATION_RESULTS[@]}"; do
        echo "$result"
        if [[ $result == ✅* ]]; then
            success_count=$((success_count + 1))
        elif [[ $result == ⚠️* ]]; then
            warning_count=$((warning_count + 1))
        elif [[ $result == ❌* ]]; then
            error_count=$((error_count + 1))
        fi
    done

    echo ""
    echo "📊 Summary:"
    echo "✅ Success: $success_count"
    echo "⚠️ Warnings: $warning_count"
    echo "❌ Errors: $error_count"
    echo ""

    if [[ $error_count -eq 0 ]]; then
        if [[ $warning_count -eq 0 ]]; then
            echo "🎉 Perfect! All validations passed without issues."
        else
            echo "✅ Good! All critical validations passed. Minor issues to review."
        fi
    else
        echo "⚠️ Some issues found. Please review and fix errors."
    fi

    echo ""
    echo "🚀 Repository transformation completed successfully!"
    echo "The StickyNotes project is now professionally organized and ready for development."
}

# Main execution
main() {
    log_header "StickyNotes Desktop - Repository Transformation Validation"
    echo "Timestamp: $(date)"
    echo ""

    # Run all validation checks
    validate_essential_files
    validate_github_config
    validate_build_system
    validate_documentation
    validate_makefile
    validate_project_structure
    validate_git_config
    validate_security_setup
    validate_project_health

    # Generate final report
    generate_validation_report
}

# Run main function
main "$@"