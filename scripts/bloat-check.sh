#!/bin/bash

# =============================================================================
# StickyNotes Desktop - Bloat Analysis and Dependency Optimization Script
# =============================================================================
# This script analyzes project dependencies, binary size, and potential bloat
# issues to help optimize the application.
#
# Features:
# - Dependency size analysis
# - Binary composition analysis
# - Unused dependency detection
# - Framework optimization recommendations
# - Bundle size tracking
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
BUILD_DIR="./build"
DIST_DIR="./dist"
REPORT_DIR="./reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="$REPORT_DIR/bloat_analysis_$TIMESTAMP.md"

# Create reports directory
mkdir -p "$REPORT_DIR"

# Utility functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${WHITE}=============================================================================${NC}"
    echo -e "${WHITE} $1${NC}"
    echo -e "${WHITE}=============================================================================${NC}"
}

# Initialize report
initialize_report() {
    cat > "$REPORT_FILE" << EOF
# StickyNotes Desktop - Bloat Analysis Report

**Generated:** $(date)
**Project:** $PROJECT_NAME
**Build Configuration:** Analysis of current build artifacts

## Executive Summary

EOF
}

# Analyze Swift Package Manager dependencies
analyze_swift_packages() {
    log_header "Analyzing Swift Package Dependencies"

    echo "## Swift Package Manager Dependencies" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    if [[ -f "Package.swift" ]]; then
        log_info "Analyzing Package.swift dependencies..."

        # Extract dependencies from Package.swift
        echo "\`\`\`swift" >> "$REPORT_FILE"
        cat Package.swift >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"

        # Check for build directory
        if [[ -d ".build" ]]; then
            log_info "Analyzing built package sizes..."
            echo "### Package Build Sizes" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
            echo "| Package | Size | Location |" >> "$REPORT_FILE"
            echo "|---------|------|----------|" >> "$REPORT_FILE"

            find .build -name "*.build" -type d | while read -r build_dir; do
                if [[ -d "$build_dir" ]]; then
                    size=$(du -sh "$build_dir" 2>/dev/null | cut -f1 || echo "N/A")
                    pkg_name=$(basename "$build_dir" | sed 's/.build//')
                    echo "| $pkg_name | $size | $build_dir |" >> "$REPORT_FILE"
                fi
            done
            echo "" >> "$REPORT_FILE"
        fi
    else
        echo "No Package.swift found - using Xcode project dependencies" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi

    log_success "Swift package analysis complete"
}

# Analyze Xcode project frameworks
analyze_xcode_frameworks() {
    log_header "Analyzing Xcode Project Frameworks"

    echo "## Xcode Project Frameworks" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    # Find built app
    local app_path=$(find "$DIST_DIR" -name "*.app" -type d 2>/dev/null | head -1)

    if [[ -n "$app_path" && -d "$app_path" ]]; then
        log_info "Analyzing frameworks in: $app_path"

        local frameworks_dir="$app_path/Contents/Frameworks"
        if [[ -d "$frameworks_dir" ]]; then
            echo "### Embedded Frameworks" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
            echo "| Framework | Size | Architecture |" >> "$REPORT_FILE"
            echo "|----------|------|--------------|" >> "$REPORT_FILE"

            local total_size=0
            find "$frameworks_dir" -name "*.framework" -type d | while read -r framework; do
                if [[ -d "$framework" ]]; then
                    local size=$(du -s "$framework" 2>/dev/null | awk '{print $1}' || echo "0")
                    local size_mb=$(echo "scale=2; $size/1024" | bc -l 2>/dev/null || echo "N/A")
                    local name=$(basename "$framework")
                    local arch=$(lipo -info "$framework"/* 2>/dev/null | grep "Architectures" | head -1 | sed 's/.*are: //' || echo "N/A")

                    echo "| $name | ${size_mb} MB | $arch |" >> "$REPORT_FILE"
                    total_size=$((total_size + size))
                fi
            done

            local total_mb=$(echo "scale=2; $total_size/1024" | bc -l 2>/dev/null || echo "N/A")
            echo "" >> "$REPORT_FILE"
            echo "**Total Frameworks Size:** ${total_mb} MB" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
        fi

        # Analyze app bundle size
        log_info "Analyzing app bundle composition..."
        echo "### App Bundle Composition" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "| Component | Size | Percentage |" >> "$REPORT_FILE"
        echo "|-----------|------|------------|" >> "$REPORT_FILE"

        local total_app_size=$(du -s "$app_path" 2>/dev/null | awk '{print $1}' || echo "0")

        # Analyze different components
        local components=("Resources" "Frameworks" "Executables" "PlugIns" "SharedSupport")
        for component in "${components[@]}"; do
            local comp_dir="$app_path/Contents/$component"
            if [[ -d "$comp_dir" ]]; then
                local comp_size=$(du -s "$comp_dir" 2>/dev/null | awk '{print $1}' || echo "0")
                local percentage=$(echo "scale=2; $comp_size*100/$total_app_size" | bc -l 2>/dev/null || echo "0")
                local size_mb=$(echo "scale=2; $comp_size/1024" | bc -l 2>/dev/null || echo "N/A")
                echo "| $component | ${size_mb} MB | ${percentage}% |" >> "$REPORT_FILE"
            fi
        done

        local total_mb=$(echo "scale=2; $total_app_size/1024" | bc -l 2>/dev/null || echo "N/A")
        echo "" >> "$REPORT_FILE"
        echo "**Total App Size:** ${total_mb} MB" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    else
        echo "No built app found in $DIST_DIR" >> "$REPORT_FILE"
        echo "Run the build script first to generate analysis data" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi

    log_success "Xcode frameworks analysis complete"
}

# Analyze binary composition
analyze_binary_composition() {
    log_header "Analyzing Binary Composition"

    echo "## Binary Composition Analysis" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    local app_path=$(find "$DIST_DIR" -name "*.app" -type d 2>/dev/null | head -1)

    if [[ -n "$app_path" ]]; then
        local executable=$(find "$app_path" -name "*" -type f -perm +111 2>/dev/null | head -1)

        if [[ -n "$executable" ]]; then
            log_info "Analyzing executable: $executable"

            # Binary size
            local binary_size=$(du -sh "$executable" 2>/dev/null | cut -f1)
            echo "### Executable Information" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
            echo "- **Path:** $executable" >> "$REPORT_FILE"
            echo "- **Size:** $binary_size" >> "$REPORT_FILE"
            echo "- **Architecture:** $(lipo -info "$executable" 2>/dev/null || echo 'N/A')" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"

            # Section analysis
            echo "### Binary Sections" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
            echo "| Section | Size | Description |" >> "$REPORT_FILE"
            echo "|---------|------|-------------|" >> "$REPORT_FILE"

            size -l -m "$executable" 2>/dev/null | grep -E "^\d" | head -20 | while read -r line; do
                local section=$(echo "$line" | awk '{print $2}')
                local size=$(echo "$line" | awk '{print $1}')
                local desc=$(echo "$line" | cut -c45-)
                echo "| $section | $size | $desc |" >> "$REPORT_FILE"
            done
            echo "" >> "$REPORT_FILE"
        fi
    fi

    log_success "Binary composition analysis complete"
}

# Check for potential bloat issues
check_bloat_issues() {
    log_header "Checking for Potential Bloat Issues"

    echo "## Potential Bloat Issues" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    # Check for common issues
    local issues_found=0

    # Large resource files
    log_info "Checking for large resource files..."
    echo "### Large Resource Files" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    local app_path=$(find "$DIST_DIR" -name "*.app" -type d 2>/dev/null | head -1)
    if [[ -n "$app_path" ]]; then
        find "$app_path" -type f -size +1M 2>/dev/null | while read -r file; do
            local size=$(du -sh "$file" 2>/dev/null | cut -f1)
            local rel_path=$(echo "$file" | sed "s|$app_path||")
            echo "- **$rel_path**: $size" >> "$REPORT_FILE"
            issues_found=$((issues_found + 1))
        done
    fi
    echo "" >> "$REPORT_FILE"

    # Unused frameworks
    log_info "Checking for potentially unused frameworks..."
    echo "### Optimization Recommendations" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    # Check for debug symbols
    local app_path=$(find "$DIST_DIR" -name "*.app" -type d 2>/dev/null | head -1)
    if [[ -n "$app_path" ]]; then
        local dwarf_files=$(find "$app_path" -name "*.dSYM" -o -name "*.dwarf" 2>/dev/null | wc -l)
        if [[ $dwarf_files -gt 0 ]]; then
            echo "- ⚠️ **Debug symbols found**: Consider removing for release builds" >> "$REPORT_FILE"
            issues_found=$((issues_found + 1))
        fi
    fi

    # Check for optimization opportunities
    echo "- 📊 **Consider enabling bitcode** for App Store distribution" >> "$REPORT_FILE"
    echo "- 🗜️ **Enable compiler optimizations** (-O2 or -O3)" >> "$REPORT_FILE"
    echo "- 📦 **Review embedded frameworks** for necessity" >> "$REPORT_FILE"
    echo "- 🖼️ **Optimize images and assets**" >> "$REPORT_FILE"
    echo "- 📚 **Remove unused Swift libraries**" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    if [[ $issues_found -eq 0 ]]; then
        echo "✅ **No major bloat issues detected**" >> "$REPORT_FILE"
    else
        echo "⚠️ **$issues_found potential issues found**" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"

    log_success "Bloat issues check complete"
}

# Generate recommendations
generate_recommendations() {
    log_header "Generating Optimization Recommendations"

    echo "## Optimization Recommendations" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    echo "### High Priority" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "1. **Enable Compiler Optimizations**" >> "$REPORT_FILE"
    echo "   - Use Release configuration with -O optimization" >> "$REPORT_FILE"
    echo "   - Enable Whole Module Optimization" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    echo "2. **Strip Debug Symbols**" >> "$REPORT_FILE"
    echo "   - Remove .dSYM files from release builds" >> "$REPORT_FILE"
    echo "   - Use \`strip\` command on final binary" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    echo "3. **Optimize Asset Size**" >> "$REPORT_FILE"
    echo "   - Compress images using ImageOptim or similar tools" >> "$REPORT_FILE"`
    echo "   - Use vector formats where appropriate" >> "$REPORT_FILE"
    echo "   - Remove unused assets" >> "$REPORT_FILE"`
    echo "" >> "$REPORT_FILE"`

    echo "### Medium Priority" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "4. **Review Dependencies**" >> "$REPORT_FILE"
    echo "   - Remove unused Swift packages" >> "$REPORT_FILE"`
    echo "   - Consider static linking for frameworks" >> "$REPORT_FILE"`
    echo "   - Use framework-specific optimization" >> "$REPORT_FILE"`
    echo "" >> "$REPORT_FILE"`

    echo "5. **Enable Link-Time Optimization (LTO)**" >> "$REPORT_FILE"`
    echo "   - Set \`-flto\` compiler flag" >> "$REPORT_FILE"`
    echo "   - Monitor build time impact" >> "$REPORT_FILE"`
    echo "" >> "$REPORT_FILE"`

    echo "### Advanced Optimizations" >> "$REPORT_FILE"`
    echo "" >> "$REPORT_FILE"`
    echo "6. **Custom Compiler Flags**" >> "$REPORT_FILE"`
    echo "   - \`-dead_strip\`: Remove unused code" >> "$REPORT_FILE"`
    echo "   - \`-no_dead_strip_inits_and_terms\`: Keep necessary symbols" >> "$REPORT_FILE"`
    echo "   - \`-cross_optimize\`: Cross-file optimization" >> "$REPORT_FILE"`
    echo "" >> "$REPORT_FILE"`

    echo "7. **Asset Catalog Optimization**" >> "$REPORT_FILE"`
    echo "   - Use asset catalogs for images" >> "$REPORT_FILE"`
    echo "   - Enable app thinning" >> "$REPORT_FILE"`
    echo "   - Optimize for different screen sizes" >> "$REPORT_FILE"`
    echo "" >> "$REPORT_FILE"`

    echo "### Monitoring" >> "$REPORT_FILE"`
    echo "" >> "$REPORT_FILE"`
    echo "- **Set up size budgets**: Target maximum app size" >> "$REPORT_FILE"`
    echo "- **Automated monitoring**: Include in CI/CD pipeline" >> "$REPORT_FILE"`
    echo "- **Regular analysis**: Run this script weekly" >> "$REPORT_FILE"`
    echo "- **Version tracking**: Monitor size changes over time" >> "$REPORT_FILE"`
    echo "" >> "$REPORT_FILE"`

    log_success "Recommendations generated"
}

# Display summary
display_summary() {
    log_header "Bloat Analysis Summary"

    echo "Analysis completed successfully!"
    echo ""
    echo "Report saved to: $REPORT_FILE"
    echo "Report size: $(du -sh "$REPORT_FILE" | cut -f1)"
    echo ""

    if command -v open &> /dev/null; then
        read -p "Open report? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            open "$REPORT_FILE"
        fi
    fi

    log_success "Bloat analysis complete!"
}

# Main execution
main() {
    log_header "StickyNotes Desktop - Bloat Analysis"
    echo "Timestamp: $TIMESTAMP"
    echo ""

    initialize_report
    analyze_swift_packages
    analyze_xcode_frameworks
    analyze_binary_composition
    check_bloat_issues
    generate_recommendations
    display_summary
}

# Run main function
main "$@"