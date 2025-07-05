#!/bin/bash

# Repository Optimization Script
# Optimizes repository for performance and maintainability

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DRY_RUN=false
ANALYZE_ONLY=false
OPTIMIZE_GIT=true
OPTIMIZE_STRUCTURE=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --analyze-only)
            ANALYZE_ONLY=true
            shift
            ;;
        --no-git-opt)
            OPTIMIZE_GIT=false
            shift
            ;;
        --no-struct-opt)
            OPTIMIZE_STRUCTURE=false
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --dry-run       Show what would be optimized without doing it"
            echo "  --analyze-only  Only analyze, don't make changes"
            echo "  --no-git-opt    Don't optimize git configuration"
            echo "  --no-struct-opt Don't optimize repository structure"
            echo "  -h, --help     Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Counter for results
TOTAL_OPTIMIZATIONS=0
APPLIED_OPTIMIZATIONS=0

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((APPLIED_OPTIMIZATIONS++))
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_action() {
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY RUN] $1${NC}"
    else
        echo -e "${GREEN}$1${NC}"
    fi
}

# Start optimization
echo "⚡ Repository Optimization Started"
echo "================================="

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}🔍 DRY RUN MODE - No files will be modified${NC}"
fi

# 1. Git Optimization
if [ "$OPTIMIZE_GIT" = true ]; then
    echo ""
    echo "🔧 Git Optimization"
    echo "-------------------"
    
    # Check git configuration
    increment_total
    if git config --get core.autocrlf > /dev/null 2>&1; then
        log_success "Git line ending configuration exists"
    else
        log_action "Setting git core.autocrlf to input"
        if [ "$DRY_RUN" = false ] && [ "$ANALYZE_ONLY" = false ]; then
            git config core.autocrlf input
            ((APPLIED_OPTIMIZATIONS++))
        fi
        ((TOTAL_OPTIMIZATIONS++))
    fi
    
    # Check for .gitattributes
    increment_total
    if [ -f ".gitattributes" ]; then
        log_success ".gitattributes file exists"
        
        # Check if it has proper settings
        if grep -q "text eol=lf" .gitattributes; then
            log_success ".gitattributes has line ending settings"
        else
            log_action "Adding line ending settings to .gitattributes"
            if [ "$DRY_RUN" = false ] && [ "$ANALYZE_ONLY" = false ]; then
                echo "*.swift text eol=lf" >> .gitattributes
                echo "*.md text eol=lf" >> .gitattributes
                echo "*.yml text eol=lf" >> .gitattributes
                echo "*.yaml text eol=lf" >> .gitattributes
                ((APPLIED_OPTIMIZATIONS++))
            fi
            ((TOTAL_OPTIMIZATIONS++))
        fi
    else
        log_action "Creating .gitattributes file"
        if [ "$DRY_RUN" = false ] && [ "$ANALYZE_ONLY" = false ]; then
            cat > .gitattributes << 'EOF'
# Set default line ending to LF
* text eol=lf

# Specific file types
*.swift text eol=lf
*.md text eol=lf
*.yml text eol=lf
*.yaml text eol=lf
*.json text eol=lf

# Binary files
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.ico binary
EOF
            ((APPLIED_OPTIMIZATIONS++))
        fi
        ((TOTAL_OPTIMIZATIONS++))
    fi
    
    # Optimize git ignore
    increment_total
    if [ -f ".gitignore" ]; then
        # Check for essential ignore patterns
        essential_patterns=(".DS_Store" "*.xcuserstate" "DerivedData" ".build" "build/")
        missing_patterns=0
        
        for pattern in "${essential_patterns[@]}"; do
            if ! grep -q "$pattern" .gitignore; then
                ((missing_patterns++))
            fi
        done
        
        if [ $missing_patterns -eq 0 ]; then
            log_success ".gitignore has essential patterns"
        else
            log_action "Adding missing patterns to .gitignore"
            if [ "$DRY_RUN" = false ] && [ "$ANALYZE_ONLY" = false ]; then
                for pattern in "${essential_patterns[@]}"; do
                    if ! grep -q "$pattern" .gitignore; then
                        echo "$pattern" >> .gitignore
                    fi
                done
                ((APPLIED_OPTIMIZATIONS++))
            fi
            ((TOTAL_OPTIMIZATIONS++))
        fi
    else
        log_warning ".gitignore file missing"
    fi
fi

# 2. Repository Structure Optimization
if [ "$OPTIMIZE_STRUCTURE" = true ]; then
    echo ""
    echo "📁 Structure Optimization"
    echo "------------------------"
    
    # Check for optimal directory structure
    required_dirs=("Sources" "Tests" "docs" "scripts")
    for dir in "${required_dirs[@]}"; do
        increment_total
        if [ -d "$dir" ]; then
            log_success "Required directory exists: $dir"
        else
            log_action "Creating missing directory: $dir"
            if [ "$DRY_RUN" = false ] && [ "$ANALYZE_ONLY" = false ]; then
                mkdir -p "$dir"
                ((APPLIED_OPTIMIZATIONS++))
            fi
            ((TOTAL_OPTIMIZATIONS++))
        fi
    done
    
    # Check for .editorconfig
    increment_total
    if [ -f ".editorconfig" ]; then
        log_success ".editorconfig exists"
    else
        log_action "Creating .editorconfig file"
        if [ "$DRY_RUN" = false ] && [ "$ANALYZE_ONLY" = false ]; then
            cat > .editorconfig << 'EOF'
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = space
indent_size = 4

[*.swift]
indent_size = 4

[*.yml]
indent_size = 2

[*.yaml]
indent_size = 2

[*.json]
indent_size = 2

[*.md]
trim_trailing_whitespace = false
EOF
            ((APPLIED_OPTIMIZATIONS++))
        fi
        ((TOTAL_OPTIMIZATIONS++))
    fi
    
    # Check for package.json (even for Swift projects, for tooling)
    increment_total
    if [ -f "package.json" ]; then
        log_success "package.json exists"
        
        # Check if it has scripts section
        if grep -q '"scripts"' package.json; then
            log_success "package.json has scripts section"
        else
            log_action "Adding scripts section to package.json"
            if [ "$DRY_RUN" = false ] && [ "$ANALYZE_ONLY" = false ]; then
                # Add scripts to existing package.json
                if command -v jq &> /dev/null; then
                    jq '.scripts = {"validate": "./scripts/validate-repository.sh", "test": "swift test", "build": "swift build"}' package.json > package.json.tmp
                    mv package.json.tmp package.json
                else
                    log_warning "jq not available, manual package.json edit required"
                fi
                ((APPLIED_OPTIMIZATIONS++))
            fi
            ((TOTAL_OPTIMIZATIONS++))
        fi
    else
        log_action "Creating package.json for tooling"
        if [ "$DRY_RUN" = false ] && [ "$ANALYZE_ONLY" = false ]; then
            cat > package.json << 'EOF'
{
  "name": "desktop-stickies",
  "version": "1.0.0",
  "description": "A modern macOS desktop sticky notes application",
  "scripts": {
    "validate": "./scripts/validate-repository.sh",
    "test": "swift test",
    "build": "swift build",
    "quality": "./scripts/test-quality.sh",
    "docs": "./scripts/validate-documentation.sh",
    "cleanup": "./scripts/cleanup-repository.sh"
  },
  "devDependencies": {},
  "repository": {
    "type": "git",
    "url": "https://github.com/sanchez314c/desktop-stickies.git"
  },
  "keywords": [
    "macos",
    "sticky-notes",
    "swift",
    "desktop-app"
  ],
  "author": "Jasonn Michaels",
  "license": "MIT"
}
EOF
            ((APPLIED_OPTIMIZATIONS++))
        fi
        ((TOTAL_OPTIMIZATIONS++))
    fi
fi

# 3. Performance Optimization
echo ""
echo "⚡ Performance Optimization"
echo "--------------------------"

# Check for large files that could impact performance
increment_total
large_files=$(find . -type f -size +1M -not -path "./.git/*" -not -path "./archive/*" | wc -l)
if [ $large_files -eq 0 ]; then
    log_success "No large files (>1MB) found in repository"
else
    log_warning "Found $large_files large files that may impact performance"
    find . -type f -size +1M -not -path "./.git/*" -not -path "./archive/*" -exec ls -lh {} \;
fi
((TOTAL_OPTIMIZATIONS++))

# Check for deeply nested directories
increment_total
deep_dirs=$(find . -type d -path '*/.*/*/*/*/*' | wc -l)
if [ $deep_dirs -eq 0 ]; then
    log_success "No excessively deep directory structures found"
else
    log_warning "Found $deep_dirs deeply nested directories"
fi
((TOTAL_OPTIMIZATIONS++))

# 4. Security Optimization
echo ""
echo "🔒 Security Optimization"
echo "------------------------"

# Check for sensitive files in repository
increment_total
sensitive_files=$(find . -name "*.pem" -o -name "*.key" -o -name "*.p12" -o -name ".env" -not -path "./.git/*" -not -path "./archive/*" | wc -l)
if [ $sensitive_files -eq 0 ]; then
    log_success "No sensitive files found in repository"
else
    log_error "Found $sensitive_files sensitive files in repository"
    find . -name "*.pem" -o -name "*.key" -o -name "*.p12" -o -name ".env" -not -path "./.git/*" -not -path "./archive/*"
fi
((TOTAL_OPTIMIZATIONS++))

# Check .gitignore for security patterns
increment_total
security_patterns=("*.pem" "*.key" "*.p12" ".env" "*.secret" "*.p8")
missing_security_patterns=0

for pattern in "${security_patterns[@]}"; do
    if ! grep -q "$pattern" .gitignore 2>/dev/null; then
        ((missing_security_patterns++))
    fi
done

if [ $missing_security_patterns -eq 0 ]; then
    log_success ".gitignore includes security patterns"
else
    log_action "Adding security patterns to .gitignore"
    if [ "$DRY_RUN" = false ] && [ "$ANALYZE_ONLY" = false ]; then
        for pattern in "${security_patterns[@]}"; do
            if ! grep -q "$pattern" .gitignore 2>/dev/null; then
                echo "$pattern" >> .gitignore
            fi
        done
        ((APPLIED_OPTIMIZATIONS++))
    fi
fi
((TOTAL_OPTIMIZATIONS++))

# 5. Documentation Optimization
echo ""
echo "📚 Documentation Optimization"
echo "---------------------------"

# Check for README optimization
increment_total
if [ -f "README.md" ]; then
    readme_size=$(wc -c < README.md)
    if [ $readme_size -lt 2048 ]; then
        log_success "README.md is concise and readable"
    else
        log_warning "README.md is quite large ($(echo "scale=1; $readme_size/1024" | bc 2>/dev/null || echo $((readme_size/1024)) )KB)"
    fi
    
    # Check for table of contents
    if grep -q "## Table of Contents\|## TOC" README.md; then
        log_success "README.md has table of contents"
    else
        log_action "Consider adding table of contents to README.md"
    fi
else
    log_error "README.md missing"
fi
((TOTAL_OPTIMIZATIONS++))

# 6. Build Optimization
echo ""
echo "🏗️ Build Optimization"
echo "---------------------"

# Check for build optimization files
increment_total
if [ -f "Package.swift" ]; then
    # Check if Package.resolved exists (for reproducible builds)
    if [ -f "Package.resolved" ]; then
        log_success "Package.resolved exists for reproducible builds"
    else
        log_action "Consider generating Package.resolved for reproducible builds"
    fi
    
    # Check for platform-specific optimizations
    if grep -q "platforms" Package.swift; then
        log_success "Package.swift specifies supported platforms"
    else
        log_action "Consider adding platform specifications to Package.swift"
    fi
else
    log_warning "Package.swift not found"
fi
((TOTAL_OPTIMIZATIONS++))

# 7. Analysis Results
echo ""
echo "📊 Optimization Analysis"
echo "======================"

if [ "$ANALYZE_ONLY" = true ]; then
    echo -e "${BLUE}📈 ANALYSIS ONLY - No optimizations applied${NC}"
fi

echo "Total optimizations identified: $TOTAL_OPTIMIZATIONS"
if [ "$ANALYZE_ONLY" = false ]; then
    echo -e "Optimizations applied: ${GREEN}$APPLIED_OPTIMIZATIONS${NC}"
else
    echo "Optimizations that could be applied: $TOTAL_OPTIMIZATIONS"
fi

# Calculate optimization score
if [ $TOTAL_OPTIMIZATIONS -gt 0 ]; then
    if [ "$ANALYZE_ONLY" = false ]; then
        optimization_score=$((APPLIED_OPTIMIZATIONS * 100 / TOTAL_OPTIMIZATIONS))
    else
        optimization_score=100  # Analysis mode shows potential
    fi
    
    echo "Optimization potential: ${optimization_score}%"
    
    # Grade the optimization
    if [ $optimization_score -ge 90 ]; then
        echo -e "${GREEN}🏆 Grade: A+ (Excellently Optimized)${NC}"
    elif [ $optimization_score -ge 80 ]; then
        echo -e "${GREEN}🥇 Grade: A (Well Optimized)${NC}"
    elif [ $optimization_score -ge 70 ]; then
        echo -e "${YELLOW}🥈 Grade: B (Moderately Optimized)${NC}"
    elif [ $optimization_score -ge 60 ]; then
        echo -e "${YELLOW}🥉 Grade: C (Needs Optimization)${NC}"
    else
        echo -e "${RED}📉 Grade: D (Poorly Optimized)${NC}"
    fi
fi

# Recommendations
echo ""
echo "💡 Optimization Recommendations"
echo "=============================="

if [ "$APPLIED_OPTIMIZATIONS" -gt 0 ]; then
    echo "✅ Repository optimizations applied successfully"
    echo "🔄 Consider running this optimization regularly"
    echo "📊 Monitor repository performance over time"
fi

if [ "$TOTAL_OPTIMIZATIONS" -gt "$APPLIED_OPTIMIZATIONS" ]; then
    remaining=$((TOTAL_OPTIMIZATIONS - APPLIED_OPTIMIZATIONS))
    echo "⚠️ $remaining optimizations were not applied"
    echo "🔍 Review the suggestions above for manual implementation"
fi

echo "🔧 Set up pre-commit hooks to maintain optimization"
echo "📋 Add optimization to CI/CD pipeline"
echo "📈 Monitor repository metrics regularly"

# Generate optimization report
if [ "$DRY_RUN" = false ] && [ "$ANALYZE_ONLY" = false ]; then
    echo ""
    echo "📋 Generating Optimization Report..."
    
    cat > optimization-report.md << EOF
# Repository Optimization Report

**Date**: $(date)
**Repository**: $(basename $(pwd))
**Optimizations Applied**: $APPLIED_OPTIMIZATIONS / $TOTAL_OPTIMIZATIONS

## Applied Optimizations

EOF
    
    if [ "$OPTIMIZE_GIT" = true ]; then
        echo "- Git configuration optimized" >> optimization-report.md
    fi
    
    if [ "$OPTIMIZE_STRUCTURE" = true ]; then
        echo "- Repository structure optimized" >> optimization-report.md
    fi
    
    cat >> optimization-report.md << EOF

## Performance Metrics

- Repository size: $(du -sh . | cut -f1)
- Files processed: $(find . -type f -not -path "./.git/*" | wc -l)
- Directories: $(find . -type d -not -path "./.git/*" | wc -l)

## Next Steps

1. Test all changes to ensure functionality
2. Commit optimization changes
3. Monitor repository performance
4. Set up automated optimization checks

---
*Report generated by repository optimization script*
EOF
    
    log_success "Optimization report saved to optimization-report.md"
fi

# Final message
echo ""
if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}🔍 DRY RUN COMPLETED - No files were modified${NC}"
    echo "Run without --dry-run to apply optimizations"
elif [ "$ANALYZE_ONLY" = true ]; then
    echo -e "${BLUE}📊 ANALYSIS COMPLETED${NC}"
    echo "Run without --analyze-only to apply optimizations"
else
    echo -e "${GREEN}🎉 Repository optimization completed successfully!${NC}"
fi

exit 0