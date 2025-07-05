#!/bin/bash

# Documentation Validation Script
# Validates documentation quality and completeness

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

# Start documentation validation
echo "📚 Documentation Validation Started"
echo "================================="

# 1. Essential Files Check
echo ""
echo "📋 Essential Files Check"
echo "-----------------------"

essential_files=(
    "README.md"
    "CHANGELOG.md" 
    "CONTRIBUTING.md"
    "CODE_OF_CONDUCT.md"
    "LICENSE"
    "SECURITY.md"
    "SUPPORT.md"
    "GOVERNANCE.md"
)

for file in "${essential_files[@]}"; do
    increment_total
    if [ -f "$file" ]; then
        log_success "$file exists"
    else
        log_error "$file missing"
    fi
done

# 2. Documentation Structure
echo ""
echo "🏗️ Documentation Structure"
echo "-------------------------"

increment_total
if [ -d "docs" ]; then
    log_success "docs directory exists"
else
    log_error "docs directory missing"
fi

# Check docs subdirectories
docs_subdirs=("user" "developer" "architecture" "deployment" "installation" "maintenance" "testing")
for subdir in "${docs_subdirs[@]}"; do
    increment_total
    if [ -d "docs/$subdir" ]; then
        log_success "docs/$subdir directory exists"
    else
        log_warning "docs/$subdir directory missing"
    fi
done

# 3. README Quality
echo ""
echo "📖 README Quality"
echo "-----------------"

increment_total
if [ -s "README.md" ]; then
    readme_size=$(wc -l < README.md)
    if [ $readme_size -gt 50 ]; then
        log_success "README.md has substantial content ($readme_size lines)"
    else
        log_warning "README.md needs more content ($readme_size lines)"
    fi
else
    log_error "README.md is empty"
fi

# Check README sections
readme_sections=("Installation" "Usage" "Contributing" "License")
for section in "${readme_sections[@]}"; do
    increment_total
    if grep -q "## $section\|### $section" README.md; then
        log_success "README.md contains $section section"
    else
        log_warning "README.md missing $section section"
    fi
done

increment_total
if grep -q "```" README.md; then
    log_success "README.md contains code examples"
else
    log_warning "README.md missing code examples"
fi

increment_total
if grep -q "!\[.*\](.*)" README.md; then
    log_success "README.md contains badges"
else
    log_warning "README.md missing badges"
fi

# 4. API Documentation
echo ""
echo "🔌 API Documentation"
echo "--------------------"

increment_total
if [ -f "docs/API.md" ]; then
    log_success "API documentation exists"
    
    # Check API doc quality
    api_size=$(wc -l < docs/API.md)
    if [ $api_size -gt 100 ]; then
        log_success "API documentation is comprehensive ($api_size lines)"
    else
        log_warning "API documentation needs more content"
    fi
    
    increment_total
    if grep -q "## " docs/API.md; then
        log_success "API documentation has proper structure"
    else
        log_warning "API documentation lacks structure"
    fi
    
    increment_total
    if grep -q "```" docs/API.md; then
        log_success "API documentation contains code examples"
    else
        log_warning "API documentation missing code examples"
    fi
else
    log_error "API documentation missing"
fi

# 5. Architecture Documentation
echo ""
echo "🏛️ Architecture Documentation"
echo "---------------------------"

increment_total
if [ -f "docs/ARCHITECTURE.md" ]; then
    log_success "Architecture documentation exists"
else
    log_error "Architecture documentation missing"
fi

increment_total
if [ -f "docs/architecture/architecture-overview.md" ]; then
    log_success "Detailed architecture documentation exists"
    
    # Check for architecture diagrams
    if grep -q "```mermaid\|!\[.*diagram" docs/architecture/architecture-overview.md; then
        log_success "Architecture documentation includes diagrams"
    else
        log_warning "Architecture documentation missing diagrams"
    fi
else
    log_warning "Detailed architecture documentation missing"
fi

increment_total
if [ -f "docs/architecture/data-model.md" ]; then
    log_success "Data model documentation exists"
else
    log_warning "Data model documentation missing"
fi

# 6. User Documentation
echo ""
echo "👥 User Documentation"
echo "---------------------"

user_docs=("getting-started.md" "features.md" "user-guide.md" "troubleshooting.md" "keyboard-shortcuts.md")
for doc in "${user_docs[@]}"; do
    increment_total
    if [ -f "docs/user/$doc" ]; then
        log_success "User doc exists: $doc"
    else
        log_warning "User doc missing: $doc"
    fi
done

# 7. Developer Documentation
echo ""
echo "💻 Developer Documentation"
echo "------------------------"

dev_docs=("DEVELOPMENT.md" "api-reference.md" "code-style.md" "contributing.md")
for doc in "${dev_docs[@]}"; do
    increment_total
    if [ -f "docs/developer/$doc" ]; then
        log_success "Developer doc exists: $doc"
    else
        log_warning "Developer doc missing: $doc"
    fi
done

# 8. Installation Documentation
echo ""
echo "📦 Installation Documentation"
echo "--------------------------"

increment_total
if [ -f "docs/installation/installation-guide.md" ]; then
    log_success "Installation guide exists"
else
    log_warning "Installation guide missing"
fi

increment_total
if [ -f "docs/installation/system-requirements.md" ]; then
    log_success "System requirements documentation exists"
else
    log_warning "System requirements documentation missing"
fi

# 9. Security Documentation
echo ""
echo "🔒 Security Documentation"
echo "------------------------"

increment_total
if [ -f "docs/SECURITY.md" ]; then
    log_success "Security documentation exists"
    
    # Check security doc quality
    if grep -q "## Reporting" docs/SECURITY.md; then
        log_success "Security documentation includes reporting instructions"
    else
        log_warning "Security documentation missing reporting instructions"
    fi
    
    increment_total
    if grep -q "## Supported" docs/SECURITY.md; then
        log_success "Security documentation includes supported versions"
    else
        log_warning "Security documentation missing supported versions"
    fi
else
    log_error "Security documentation missing"
fi

# 10. Contributing Documentation
echo ""
echo "🤝 Contributing Documentation"
echo "---------------------------"

increment_total
if [ -f "CONTRIBUTING.md" ]; then
    log_success "Contributing guide exists"
    
    # Check contributing guide quality
    if grep -q "## Quick Start\|## Getting Started" CONTRIBUTING.md; then
        log_success "Contributing guide has quick start section"
    else
        log_warning "Contributing guide missing quick start"
    fi
    
    increment_total
    if grep -q "## Development Setup" CONTRIBUTING.md; then
        log_success "Contributing guide includes development setup"
    else
        log_warning "Contributing guide missing development setup"
    fi
else
    log_error "Contributing guide missing"
fi

# 11. Changelog Quality
echo ""
echo "📅 Changelog Quality"
echo "--------------------"

increment_total
if [ -f "CHANGELOG.md" ]; then
    log_success "Changelog exists"
    
    # Check changelog format
    if grep -q "## \[Unreleased\]" CHANGELOG.md; then
        log_success "Changelog follows Keep a Changelog format"
    else
        log_warning "Changelog doesn't follow standard format"
    fi
    
    increment_total
    if grep -q "### Added\|### Changed\|### Fixed\|### Removed" CHANGELOG.md; then
        log_success "Changelog uses proper change types"
    else
        log_warning "Changelog missing proper change types"
    fi
    
    increment_total
    if grep -q "## \[.*\]" CHANGELOG.md; then
        log_success "Changelog includes versioned releases"
    else
        log_warning "Changelog missing versioned releases"
    fi
else
    log_error "Changelog missing"
fi

# 12. Cross-References
echo ""
echo "🔗 Cross-References"
echo "-------------------"

increment_total
# Check if README references other docs
if grep -q "\[.*\](docs/.*\.md)" README.md; then
    log_success "README references other documentation"
else
    log_warning "README doesn't reference other documentation"
fi

increment_total
# Check for broken internal links
broken_links=0
for doc in docs/**/*.md; do
    if [ -f "$doc" ]; then
        # Extract markdown links and check if they exist
        links=$(grep -o '\[.*\](.*\.md)' "$doc" | sed 's/.*(\(.*\.md\)).*/\1/')
        for link in $links; do
            if [[ $link == http* ]]; then
                continue  # Skip external links
            fi
            
            # Resolve relative paths
            if [[ $link == /* ]]; then
                target="${link#/}"
            else
                target="$(dirname "$doc")/$link"
            fi
            
            if [ ! -f "$target" ] && [ ! -d "$target" ]; then
                ((broken_links++))
                echo "Broken link: $doc -> $link"
            fi
        done
    fi
done

if [ $broken_links -eq 0 ]; then
    log_success "No broken internal links found"
else
    log_warning "Found $broken_links broken internal links"
fi

# 13. Documentation Consistency
echo ""
echo "📏 Documentation Consistency"
echo "--------------------------"

increment_total
# Check for consistent heading styles
inconsistent_headings=0
for doc in docs/**/*.md; do
    if [ -f "$doc" ]; then
        # Check for mixed heading styles
        if grep -q "^# " "$doc" && grep -q "^## " "$doc"; then
            ((inconsistent_headings++))
        fi
    fi
done

if [ $inconsistent_headings -eq 0 ]; then
    log_success "Consistent heading styles across documentation"
else
    log_warning "Found $inconsistent_headings files with inconsistent heading styles"
fi

increment_total
# Check for consistent code block formatting
inconsistent_code_blocks=0
for doc in docs/**/*.md; do
    if [ -f "$doc" ]; then
        # Check for unindented code blocks
        if grep -q "^[^ ]*```" "$doc"; then
            ((inconsistent_code_blocks++))
        fi
    fi
done

if [ $inconsistent_code_blocks -eq 0 ]; then
    log_success "Consistent code block formatting"
else
    log_warning "Found $inconsistent_code_blocks files with inconsistent code blocks"
fi

# 14. Documentation Completeness Score
echo ""
echo "📊 Documentation Completeness"
echo "-----------------------------"

# Calculate completeness score
max_score=$TOTAL_CHECKS
current_score=$PASSED_CHECKS

if [ $max_score -gt 0 ]; then
    completeness_percentage=$((current_score * 100 / max_score))
    echo "Documentation completeness: ${completeness_percentage}%"
    
    # Grade the documentation
    if [ $completeness_percentage -ge 95 ]; then
        echo -e "${GREEN}🏆 Grade: A+ (Outstanding)${NC}"
    elif [ $completeness_percentage -ge 85 ]; then
        echo -e "${GREEN}🥇 Grade: A (Excellent)${NC}"
    elif [ $completeness_percentage -ge 75 ]; then
        echo -e "${YELLOW}🥈 Grade: B (Good)${NC}"
    elif [ $completeness_percentage -ge 65 ]; then
        echo -e "${YELLOW}🥉 Grade: C (Fair)${NC}"
    else
        echo -e "${RED}📉 Grade: D (Needs Work)${NC}"
    fi
fi

# Results Summary
echo ""
echo "📊 Documentation Validation Results"
echo "================================="
echo "Total checks: $TOTAL_CHECKS"
echo -e "Passed: ${GREEN}$PASSED_CHECKS${NC}"
echo -e "Failed: ${RED}$FAILED_CHECKS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"

# Final verdict
echo ""
if [ $FAILED_CHECKS -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}🎉 Excellent! Documentation validation passed with no issues.${NC}"
        exit 0
    else
        echo -e "${YELLOW}✅ Documentation validation passed with $WARNINGS warnings.${NC}"
        echo "Consider addressing warnings for optimal documentation quality."
        exit 0
    fi
else
    echo -e "${RED}❌ Documentation validation failed with $FAILED_CHECKS errors.${NC}"
    echo "Please address critical documentation issues."
    exit 1
fi