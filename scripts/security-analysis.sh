#!/bin/bash

# =============================================================================
# StickyNotes Desktop - Security Analysis and Quality Assurance Script
# =============================================================================
# This script performs comprehensive security analysis and quality checks on the
# StickyNotes macOS application to ensure it meets security and quality standards.
#
# Features:
# - Security vulnerability scanning
# - Code quality assessment
# - Dependency security analysis
# - Certificate and signing verification
# - Data privacy assessment
# - Configuration security review
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
REPORT_DIR="./reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SECURITY_REPORT="$REPORT_DIR/security_analysis_$TIMESTAMP.md"
QUALITY_REPORT="$REPORT_DIR/quality_assessment_$TIMESTAMP.md"

# Security check levels
BASIC_CHECKS=true
DEPENDENCY_CHECKS=true
CODE_SECURITY_CHECKS=true
CERTIFICATE_CHECKS=true

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

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

log_header() {
    echo -e "${WHITE}=============================================================================${NC}"
    echo -e "${WHITE} $1${NC}"
    echo -e "${WHITE}=============================================================================${NC}"
}

# Check for sensitive data exposure
check_sensitive_data() {
    log_step "Checking for sensitive data exposure..."

    echo "## Sensitive Data Exposure Check" >> "$SECURITY_REPORT"
    echo "" >> "$SECURITY_REPORT"

    local issues_found=0

    # Check for potential API keys, passwords, tokens
    local sensitive_patterns=(
        "password\s*=\s*[\"'][^\"']+[\"']"
        "api_key\s*=\s*[\"'][^\"']+[\"']"
        "secret\s*=\s*[\"'][^\"']+[\"']"
        "token\s*=\s*[\"'][^\"']+[\"']"
        "private_key\s*=\s*[\"'][^\"']+"
        "AKIA[0-9A-Z]{16}"  # AWS Access Key pattern
        "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"  # Email addresses
    )

    for pattern in "${sensitive_patterns[@]}"; do
        local matches=$(grep -r -i -n -E "$pattern" . --include="*.swift" --include="*.m" --include="*.h" --include="*.plist" 2>/dev/null || true)
        if [[ -n "$matches" ]]; then
            echo "⚠️ **Potential sensitive data found:**" >> "$SECURITY_REPORT"
            echo "\`\`\`" >> "$SECURITY_REPORT"
            echo "$matches" >> "$SECURITY_REPORT"
            echo "\`\`\`" >> "$SECURITY_REPORT"
            echo "" >> "$SECURITY_REPORT"
            issues_found=$((issues_found + 1))
        fi
    done

    # Check for hardcoded URLs and endpoints
    local url_patterns=(
        "https?://[a-zA-Z0-9.-]+/[a-zA-Z0-9._-]*"
        "cloudkit\.com"
        "api\..*\.com"
    )

    for pattern in "${url_patterns[@]}"; do
        local matches=$(grep -r -n -E "$pattern" . --include="*.swift" --include="*.plist" 2>/dev/null | grep -v "example.com" | grep -v "localhost" || true)
        if [[ -n "$matches" ]]; then
            echo "🔗 **Hardcoded URLs found:**" >> "$SECURITY_REPORT"
            echo "\`\`\`" >> "$SECURITY_REPORT"
            echo "$matches" >> "$SECURITY_REPORT"
            echo "\`\`\`" >> "$SECURITY_REPORT"
            echo "" >> "$SECURITY_REPORT"
        fi
    done

    if [[ $issues_found -eq 0 ]]; then
        echo "✅ **No sensitive data exposure detected**" >> "$SECURITY_REPORT"
    else
        echo "⚠️ **$issues_found potential sensitive data issues found**" >> "$SECURITY_REPORT"
    fi
    echo "" >> "$SECURITY_REPORT"
}

# Check code injection vulnerabilities
check_code_injection() {
    log_step "Checking for code injection vulnerabilities..."

    echo "## Code Injection Vulnerability Check" >> "$SECURITY_REPORT"
    echo "" >> "$SECURITY_REPORT"

    local injection_patterns=(
        "eval\s*\("  # eval function
        "system\s*\("  # system function
        "exec\s*\("  # exec function
        "shell\s*\("  # shell execution
        "NSExpression.*evaluateWithObject"  # Objective-C expression evaluation
        "NSAppleScript.*executeAndReturnError"  # AppleScript execution
    )

    local issues_found=0

    for pattern in "${injection_patterns[@]}"; do
        local matches=$(grep -r -n -E "$pattern" . --include="*.swift" --include="*.m" --include="*.h" 2>/dev/null || true)
        if [[ -n "$matches" ]]; then
            echo "⚠️ **Potential code injection found:**" >> "$SECURITY_REPORT"
            echo "\`\`\`" >> "$SECURITY_REPORT"
            echo "$matches" >> "$SECURITY_REPORT"
            echo "\`\`\`" >> "$SECURITY_REPORT"
            echo "" >> "$SECURITY_REPORT"
            issues_found=$((issues_found + 1))
        fi
    done

    # Check for unsafe string operations
    local unsafe_patterns=(
        "NSString.*format.*%@"  # Unsafe string formatting
        "String.*format.*%@"    # Swift unsafe string formatting
    )

    for pattern in "${unsafe_patterns[@]}"; do
        local matches=$(grep -r -n -E "$pattern" . --include="*.swift" --include="*.m" 2>/dev/null || true)
        if [[ -n "$matches" ]]; then
            echo "⚠️ **Potentially unsafe string operations:**" >> "$SECURITY_REPORT"
            echo "\`\`\`" >> "$SECURITY_REPORT"
            echo "$matches" >> "$SECURITY_REPORT"
            echo "\`\`\`" >> "$SECURITY_REPORT"
            echo "" >> "$SECURITY_REPORT"
        fi
    done

    if [[ $issues_found -eq 0 ]]; then
        echo "✅ **No obvious code injection vulnerabilities found**" >> "$SECURITY_REPORT"
    else
        echo "⚠️ **$issues_found potential code injection issues found**" >> "$SECURITY_REPORT"
    fi
    echo "" >> "$SECURITY_REPORT"
}

# Check file permissions and access
check_file_permissions() {
    log_step "Checking file permissions and access..."

    echo "## File Permissions and Access Check" >> "$SECURITY_REPORT"
    echo "" >> "$SECURITY_REPORT"

    # Check for world-writable files
    local writable_files=$(find . -type f -perm -o+w 2>/dev/null | grep -v ".git" | head -10 || true)
    if [[ -n "$writable_files" ]]; then
        echo "⚠️ **World-writable files found:**" >> "$SECURITY_REPORT"
        echo "\`\`\`" >> "$SECURITY_REPORT"
        echo "$writable_files" >> "$SECURITY_REPORT"
        echo "\`\`\`" >> "$SECURITY_REPORT"
        echo "" >> "$SECURITY_REPORT"
    fi

    # Check for sensitive file permissions
    local sensitive_files=(
        "*.p12"
        "*.pem"
        "*.key"
        "Info.plist"
        "entitlements.plist"
    )

    for file_pattern in "${sensitive_files[@]}"; do
        local files=$(find . -name "$file_pattern" 2>/dev/null || true)
        for file in $files; do
            local permissions=$(ls -l "$file" | cut -d' ' -f1)
            echo "📄 **$file**: $permissions" >> "$SECURITY_REPORT"
        done
    done

    echo "✅ **File permissions analysis completed**" >> "$SECURITY_REPORT"
    echo "" >> "$SECURITY_REPORT"
}

# Check dependency security
check_dependency_security() {
    log_step "Checking dependency security..."

    echo "## Dependency Security Analysis" >> "$SECURITY_REPORT"
    echo "" >> "$SECURITY_REPORT"

    # Check Swift Package Manager dependencies
    if [[ -f "Package.swift" ]]; then
        echo "### Swift Package Dependencies" >> "$SECURITY_REPORT"
        echo "" >> "$SECURITY_REPORT"

        # Extract dependencies from Package.swift
        grep -A 10 -B 2 "\.package" Package.swift >> "$SECURITY_REPORT" 2>/dev/null || true
        echo "" >> "$SECURITY_REPORT"

        # Check for known vulnerable packages (this would need to be updated regularly)
        echo "### Known Vulnerability Check" >> "$SECURITY_REPORT"
        echo "⚠️ **Automated vulnerability checking requires external tools**" >> "$SECURITY_REPORT"
        echo "Consider using: \`swift package audit\` or similar tools" >> "$SECURITY_REPORT"
        echo "" >> "$SECURITY_REPORT"
    fi

    # Check Xcode project dependencies
    if [[ -f "StickyNotes.xcodeproj/project.pbxproj" ]]; then
        echo "### Xcode Project Dependencies" >> "$SECURITY_REPORT"
        echo "" >> "$SECURITY_REPORT"

        # Extract framework dependencies
        grep -E "(framework|library)" "StickyNotes.xcodeproj/project.pbxproj" | head -10 >> "$SECURITY_REPORT" 2>/dev/null || true
        echo "" >> "$SECURITY_REPORT"
    fi

    echo "✅ **Dependency analysis completed**" >> "$SECURITY_REPORT"
    echo "" >> "$SECURITY_REPORT"
}

# Check certificate and code signing
check_certificates() {
    log_step "Checking certificate and code signing configuration..."

    echo "## Certificate and Code Signing Check" >> "$SECURITY_REPORT"
    echo "" >> "$SECURITY_REPORT"

    # Check for certificates
    local certificates=$(find . -name "*.p12" -o -name "*.cer" -o -name "*.pem" 2>/dev/null | grep -v ".git" || true)
    if [[ -n "$certificates" ]]; then
        echo "📜 **Certificates found:**" >> "$SECURITY_REPORT"
        echo "$certificates" >> "$SECURITY_REPORT"
        echo "" >> "$SECURITY_REPORT"
    else
        echo "ℹ️ **No certificate files found in repository**" >> "$SECURITY_REPORT"
        echo "" >> "$SECURITY_REPORT"
    fi

    # Check entitlements files
    local entitlements_files=$(find . -name "*entitlements*.plist" 2>/dev/null || true)
    if [[ -n "$entitlements_files" ]]; then
        echo "🔐 **Entitlements files found:**" >> "$SECURITY_REPORT"
        for file in $entitlements_files; do
            echo "### $file" >> "$SECURITY_REPORT"
            echo "\`\`\`xml" >> "$SECURITY_REPORT"
            cat "$file" >> "$SECURITY_REPORT"
            echo "\`\`\`" >> "$SECURITY_REPORT"
            echo "" >> "$SECURITY_REPORT"
        done
    fi

    # Check for dangerous entitlements
    local dangerous_entitlements=(
        "com.apple.security.cs.allow-jit"
        "com.apple.security.cs.allow-unsigned-executable-memory"
        "com.apple.security.cs.disable-library-validation"
    )

    for entitlement in "${dangerous_entitlements[@]}"; do
        local matches=$(grep -r "$entitlement" . --include="*.plist" 2>/dev/null || true)
        if [[ -n "$matches" ]]; then
            echo "⚠️ **Potentially dangerous entitlement found:** $entitlement" >> "$SECURITY_REPORT"
            echo "$matches" >> "$SECURITY_REPORT"
            echo "" >> "$SECURITY_REPORT"
        fi
    done

    echo "✅ **Certificate analysis completed**" >> "$SECURITY_REPORT"
    echo "" >> "$SECURITY_REPORT"
}

# Check network security
check_network_security() {
    log_step "Checking network security configuration..."

    echo "## Network Security Check" >> "$SECURITY_REPORT"
    echo "" >> "$SECURITY_REPORT"

    # Check for HTTPS usage
    local http_urls=$(grep -r "http://" . --include="*.swift" --include="*.plist" 2>/dev/null | grep -v "http://localhost" | grep -v "http://127.0.0.1" | head -5 || true)
    if [[ -n "$http_urls" ]]; then
        echo "⚠️ **Non-HTTPS URLs found:**" >> "$SECURITY_REPORT"
        echo "\`\`\`" >> "$SECURITY_REPORT"
        echo "$http_urls" >> "$SECURITY_REPORT"
        echo "\`\`\`" >> "$SECURITY_REPORT"
        echo "" >> "$SECURITY_REPORT"
    fi

    # Check for App Transport Security settings
    local ats_settings=$(grep -r "NSAppTransportSecurity" . --include="*.plist" 2>/dev/null || true)
    if [[ -n "$ats_settings" ]]; then
        echo "🔒 **App Transport Security configuration found:**" >> "$SECURITY_REPORT"
        echo "\`\`\`xml" >> "$SECURITY_REPORT"
        echo "$ats_settings" >> "$SECURITY_REPORT"
        echo "\`\`\`" >> "$SECURITY_REPORT"
        echo "" >> "$SECURITY_REPORT"
    fi

    # Check for CloudKit configuration
    local cloudkit_config=$(grep -r "CloudKit" . --include="*.swift" --include="*.plist" 2>/dev/null || true)
    if [[ -n "$cloudkit_config" ]]; then
        echo "☁️ **CloudKit configuration found:**" >> "$SECURITY_REPORT"
        echo "CloudKit provides built-in security for data transmission" >> "$SECURITY_REPORT"
        echo "" >> "$SECURITY_REPORT"
    fi

    echo "✅ **Network security analysis completed**" >> "$SECURITY_REPORT"
    echo "" >> "$SECURITY_REPORT"
}

# Perform code quality assessment
assess_code_quality() {
    log_step "Performing code quality assessment..."

    echo "# StickyNotes Desktop - Code Quality Assessment" > "$QUALITY_REPORT"
    echo "" >> "$QUALITY_REPORT"
    echo "**Generated:** $(date)" >> "$QUALITY_REPORT"
    echo "**Project:** $PROJECT_NAME" >> "$QUALITY_REPORT"
    echo "" >> "$QUALITY_REPORT"

    # Count lines of code
    echo "## Code Metrics" >> "$QUALITY_REPORT"
    echo "" >> "$QUALITY_REPORT"

    local swift_files=$(find . -name "*.swift" | grep -v ".build" | grep -v "Tests" | wc -l | tr -d ' ')
    local total_lines=$(find . -name "*.swift" | grep -v ".build" | grep -v "Tests" | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
    local test_files=$(find . -name "*Test*.swift" | wc -l | tr -d ' ')

    echo "- **Swift Files:** $swift_files" >> "$QUALITY_REPORT"
    echo "- **Lines of Code:** $total_lines" >> "$QUALITY_REPORT"
    echo "- **Test Files:** $test_files" >> "$QUALITY_REPORT"

    if [[ $swift_files -gt 0 ]]; then
        local test_coverage=$((test_files * 100 / swift_files))
        echo "- **Test Coverage:** ${test_coverage}%" >> "$QUALITY_REPORT"
    fi
    echo "" >> "$QUALITY_REPORT"

    # Check for code complexity indicators
    echo "## Code Complexity Analysis" >> "$QUALITY_REPORT"
    echo "" >> "$QUALITY_REPORT"

    # Find large files (>500 lines)
    local large_files=$(find . -name "*.swift" -exec wc -l {} \; 2>/dev/null | awk '$1 > 500 {print}' | head -5 || true)
    if [[ -n "$large_files" ]]; then
        echo "⚠️ **Large files (>500 lines):**" >> "$QUALITY_REPORT"
        echo "\`\`\`" >> "$QUALITY_REPORT"
        echo "$large_files" >> "$QUALITY_REPORT"
        echo "\`\`\`" >> "$QUALITY_REPORT"
        echo "" >> "$QUALITY_REPORT"
    fi

    # Check for deeply nested code
    local deep_nesting=$(grep -r -n "            " . --include="*.swift" | head -5 || true)
    if [[ -n "$deep_nesting" ]]; then
        echo "⚠️ **Deeply nested code (12+ spaces):**" >> "$QUALITY_REPORT"
        echo "\`\`\`" >> "$QUALITY_REPORT"
        echo "$deep_nesting" >> "$QUALITY_REPORT"
        echo "\`\`\`" >> "$QUALITY_REPORT"
        echo "" >> "$QUALITY_REPORT"
    fi

    # Check for long functions
    echo "## Function Analysis" >> "$QUALITY_REPORT"
    echo "" >> "$QUALITY_REPORT"

    local long_functions=$(awk '/func/ {start=NR; func=$0} /}/ {if(start && NR-start > 50) print FILENAME":"start":"func; start=0}' ./**/*.swift 2>/dev/null | head -5 || true)
    if [[ -n "$long_functions" ]]; then
        echo "⚠️ **Long functions (>50 lines):**" >> "$QUALITY_REPORT"
        echo "\`\`\`" >> "$QUALITY_REPORT"
        echo "$long_functions" >> "$QUALITY_REPORT"
        echo "\`\`\`" >> "$QUALITY_REPORT"
        echo "" >> "$QUALITY_REPORT"
    fi

    # Check for TODO/FIXME comments
    echo "## Technical Debt" >> "$QUALITY_REPORT"
    echo "" >> "$QUALITY_REPORT"

    local todos=$(grep -r -n "TODO\|FIXME\|HACK" . --include="*.swift" | head -10 || true)
    if [[ -n "$todos" ]]; then
        echo "📝 **TODO/FIXME comments found:**" >> "$QUALITY_REPORT"
        echo "\`\`\`" >> "$QUALITY_REPORT"
        echo "$todos" >> "$QUALITY_REPORT"
        echo "\`\`\`" >> "$QUALITY_REPORT"
    else
        echo "✅ **No TODO/FIXME comments found**" >> "$QUALITY_REPORT"
    fi
    echo "" >> "$QUALITY_REPORT"

    # Documentation coverage
    echo "## Documentation Coverage" >> "$QUALITY_REPORT"
    echo "" >> "$QUALITY_REPORT"

    local documented_functions=$(grep -r "///" . --include="*.swift" | wc -l | tr -d ' ')
    local total_functions=$(grep -r "func " . --include="*.swift" | wc -l | tr -d ' ')

    if [[ $total_functions -gt 0 ]]; then
        local doc_coverage=$((documented_functions * 100 / total_functions))
        echo "- **Documented Functions:** $documented_functions" >> "$QUALITY_REPORT"
        echo "- **Total Functions:** $total_functions" >> "$QUALITY_REPORT"
        echo "- **Documentation Coverage:** ${doc_coverage}%" >> "$QUALITY_REPORT"
    fi
    echo "" >> "$QUALITY_REPORT"
}

# Generate security recommendations
generate_security_recommendations() {
    log_step "Generating security recommendations..."

    echo "## Security Recommendations" >> "$SECURITY_REPORT"
    echo "" >> "$SECURITY_REPORT"

    echo "### High Priority" >> "$SECURITY_REPORT"
    echo "" >> "$SECURITY_REPORT"
    echo "1. **Review Sensitive Data**" >> "$SECURITY_REPORT"
    echo "   - Remove any hardcoded API keys, passwords, or tokens" >> "$SECURITY_REPORT"
    echo "   - Use secure storage (Keychain) for sensitive information" >> "$SECURITY_REPORT"
    echo "   - Implement proper secret management" >> "$SECURITY_REPORT"
    echo "" >> "$SECURITY_REPORT"

    echo "2. **Implement Input Validation**" >> "$SECURITY_REPORT"
    echo "   - Validate all user inputs before processing" >> "$SECURITY_REPORT"
    echo "   - Sanitize data before storage or display" >> "$SECURITY_REPORT"
    echo "   - Use parameterized queries for database operations" >> "$SECURITY_REPORT"
    echo "" >> "$SECURITY_REPORT"

    echo "3. **Secure Network Communication**" >> "$SECURITY_REPORT"`
    echo "   - Use HTTPS for all network communications" >> "$SECURITY_REPORT"`
    echo "   - Implement certificate pinning for critical services" >> "$SECURITY_REPORT"`
    echo "   - Use App Transport Security (ATS) properly" >> "$SECURITY_REPORT"`
    echo "" >> "$SECURITY_REPORT"`

    echo "### Medium Priority" >> "$SECURITY_REPORT"`
    echo "" >> "$SECURITY_REPORT"`
    echo "4. **Code Signing and Certificates**" >> "$SECURITY_REPORT"`
    echo "   - Use proper code signing for distribution" >> "$SECURITY_REPORT"`
    echo "   - Keep certificates secure and up-to-date" >> "$SECURITY_REPORT"`
    echo "   - Review entitlements for minimum required permissions" >> "$SECURITY_REPORT"`
    echo "" >> "$SECURITY_REPORT"`

    echo "5. **Data Protection**" >> "$SECURITY_REPORT"`
    echo "   - Encrypt sensitive data at rest" >> "$SECURITY_REPORT"`
    echo "   - Use secure CloudKit configurations" >> "$SECURITY_REPORT"`
    echo "   - Implement proper data retention policies" >> "$SECURITY_REPORT"`
    echo "" >> "$SECURITY_REPORT"`

    echo "### Ongoing Security" >> "$SECURITY_REPORT"`
    echo "" >> "$SECURITY_REPORT"`
    echo "6. **Regular Security Audits**" >> "$SECURITY_REPORT"`
    echo "   - Run security scans regularly" >> "$SECURITY_REPORT"`
    echo "   - Keep dependencies updated" >> "$SECURITY_REPORT"`
    echo "   - Monitor for security advisories" >> "$SECURITY_REPORT"`
    echo "" >> "$SECURITY_REPORT"`

    echo "7. **Security Testing**" >> "$SECURITY_REPORT"`
    echo "   - Implement security-focused unit tests" >> "$SECURITY_REPORT"`
    echo "   - Perform penetration testing" >> "$SECURITY_REPORT"`
    echo "   - Use automated security scanning tools" >> "$SECURITY_REPORT"`
    echo "" >> "$SECURITY_REPORT"`
}

# Display summary
display_summary() {
    log_header "Security and Quality Analysis Summary"

    echo "Analysis completed successfully!"
    echo ""
    echo "Reports generated:"
    echo "- Security Report: $SECURITY_REPORT"
    echo "- Quality Report: $QUALITY_REPORT"
    echo ""

    echo "Report sizes:"
    echo "- Security: $(du -sh "$SECURITY_REPORT" 2>/dev/null | cut -f1 || echo "N/A")"
    echo "- Quality: $(du -sh "$QUALITY_REPORT" 2>/dev/null | cut -f1 || echo "N/A")"
    echo ""

    if command -v open &> /dev/null; then
        read -p "Open security report? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            open "$SECURITY_REPORT"
        fi

        read -p "Open quality report? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            open "$QUALITY_REPORT"
        fi
    fi

    log_success "Security and quality analysis complete!"
}

# Main execution
main() {
    log_header "StickyNotes Desktop - Security Analysis and Quality Assurance"
    echo "Timestamp: $TIMESTAMP"
    echo ""

    # Initialize reports
    cat > "$SECURITY_REPORT" << EOF
# StickyNotes Desktop - Security Analysis Report

**Generated:** $(date)
**Project:** $PROJECT_NAME
**Analysis Type:** Comprehensive Security Assessment

## Executive Summary

This security analysis examines the StickyNotes Desktop application for potential security vulnerabilities, data exposure risks, and compliance with security best practices.

EOF

    # Run security checks
    if [[ "$BASIC_CHECKS" == true ]]; then
        check_sensitive_data
        check_code_injection
        check_file_permissions
    fi

    if [[ "$DEPENDENCY_CHECKS" == true ]]; then
        check_dependency_security
    fi

    if [[ "$CODE_SECURITY_CHECKS" == true ]]; then
        check_network_security
    fi

    if [[ "$CERTIFICATE_CHECKS" == true ]]; then
        check_certificates
    fi

    generate_security_recommendations

    # Run quality assessment
    assess_code_quality

    # Display summary
    display_summary
}

# Run main function
main "$@"