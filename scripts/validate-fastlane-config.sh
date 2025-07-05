#!/bin/bash

# Fastlane Configuration Validation Script
# Validates Fastlane setup without requiring full Fastlane installation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Functions
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

# Validation functions
validate_fastlane_files() {
    print_status "Validating Fastlane configuration files..."

    local errors=0

    # Check Fastfile
    if [ ! -f "fastlane/Fastfile" ]; then
        print_error "Fastfile not found in fastlane/ directory"
        ((errors++))
    else
        print_success "Fastfile found"
    fi

    # Check Appfile
    if [ ! -f "fastlane/Appfile" ]; then
        print_error "Appfile not found in fastlane/ directory"
        ((errors++))
    else
        print_success "Appfile found"
    fi

    # Check Matchfile
    if [ ! -f "fastlane/Matchfile" ]; then
        print_error "Matchfile not found in fastlane/ directory"
        ((errors++))
    else
        print_success "Matchfile found"
    fi

    return $errors
}

validate_appfile() {
    print_status "Validating Appfile configuration..."

    local errors=0

    # Check required fields
    if ! grep -q "app_identifier" fastlane/Appfile; then
        print_error "app_identifier not found in Appfile"
        ((errors++))
    else
        print_success "app_identifier configured"
    fi

    if ! grep -q "apple_id" fastlane/Appfile; then
        print_warning "apple_id not found in Appfile (will use environment variable)"
    else
        print_success "apple_id configured"
    fi

    if ! grep -q "team_id" fastlane/Appfile; then
        print_warning "team_id not found in Appfile (will use environment variable)"
    else
        print_success "team_id configured"
    fi

    return $errors
}

validate_fastfile_lanes() {
    print_status "Validating Fastfile lanes..."

    local errors=0

    # Check for required lanes
    local required_lanes=("test" "build_development" "build_direct" "build_app_store" "beta" "release" "github_release")
    local found_lanes=()

    for lane in "${required_lanes[@]}"; do
        if grep -q "lane :$lane" fastlane/Fastfile; then
            found_lanes+=("$lane")
            print_success "Lane '$lane' found"
        else
            print_error "Lane '$lane' not found"
            ((errors++))
        fi
    done

    if [ ${#found_lanes[@]} -eq ${#required_lanes[@]} ]; then
        print_success "All required lanes present"
    fi

    return $errors
}

validate_entitlements() {
    print_status "Validating entitlements files..."

    local errors=0

    # Check direct distribution entitlements
    if [ ! -f "StickyNotes/Resources/StickyNotes.entitlements" ]; then
        print_error "Direct distribution entitlements file not found"
        ((errors++))
    else
        print_success "Direct distribution entitlements found"
    fi

    # Check App Store entitlements
    if [ ! -f "StickyNotes/Resources/StickyNotes-MAS.entitlements" ]; then
        print_error "App Store entitlements file not found"
        ((errors++))
    else
        print_success "App Store entitlements found"
    fi

    return $errors
}

validate_environment_variables() {
    print_status "Validating environment variable references..."

    local warnings=0

    # Check for required environment variables in Fastfile
    local required_env_vars=("APPLE_ID" "APPLE_APP_SPECIFIC_PASSWORD" "APPLE_TEAM_ID")
    local found_env_vars=()

    for env_var in "${required_env_vars[@]}"; do
        if grep -q "ENV\\[\"$env_var\"\\]" fastlane/Fastfile; then
            found_env_vars+=("$env_var")
            print_success "Environment variable '$env_var' referenced"
        else
            print_warning "Environment variable '$env_var' not found in Fastfile"
            ((warnings++))
        fi
    done

    if [ ${#found_env_vars[@]} -gt 0 ]; then
        print_success "Environment variables properly referenced"
    fi

    return $warnings
}

validate_project_structure() {
    print_status "Validating project structure..."

    local errors=0

    # Check for Xcode project
    if [ ! -d "StickyNotes.xcodeproj" ]; then
        print_error "Xcode project not found"
        ((errors++))
    else
        print_success "Xcode project found"
    fi

    # Check for Package.swift
    if [ ! -f "Package.swift" ]; then
        print_error "Package.swift not found"
        ((errors++))
    else
        print_success "Package.swift found"
    fi

    # Check for Info.plist
    if [ ! -f "StickyNotes/Info.plist" ]; then
        print_error "Info.plist not found"
        ((errors++))
    else
        print_success "Info.plist found"
    fi

    return $errors
}

generate_validation_report() {
    print_status "Generating validation report..."

    cat > fastlane_validation_report.md << EOF
# Fastlane Configuration Validation Report

Generated: $(date)
Status: $(if [ $total_errors -eq 0 ]; then echo "✅ PASSED"; else echo "❌ FAILED"; fi)

## Summary
- Total Errors: $total_errors
- Total Warnings: $total_warnings

## Validation Results

### Configuration Files
$(if validate_fastlane_files 2>/dev/null; then echo "✅ All required files present"; else echo "❌ Missing configuration files"; fi)

### Appfile Configuration
$(if validate_appfile 2>/dev/null; then echo "✅ Appfile properly configured"; else echo "❌ Appfile configuration issues"; fi)

### Fastfile Lanes
$(if validate_fastfile_lanes 2>/dev/null; then echo "✅ All required lanes present"; else echo "❌ Missing required lanes"; fi)

### Entitlements
$(if validate_entitlements 2>/dev/null; then echo "✅ Entitlements files present"; else echo "❌ Missing entitlements files"; fi)

### Environment Variables
$(if validate_environment_variables 2>/dev/null; then echo "✅ Environment variables referenced"; else echo "❌ Environment variable issues"; fi)

### Project Structure
$(if validate_project_structure 2>/dev/null; then echo "✅ Project structure valid"; else echo "❌ Project structure issues"; fi)

## Next Steps

$(if [ $total_errors -eq 0 ]; then
    echo "### Ready for Deployment
All configuration files are properly set up. You can now:

1. Set up environment variables in your CI/CD system
2. Configure certificates using \`scripts/setup-certificates.sh\`
3. Test deployment with \`fastlane test\` and \`fastlane build_development\`
4. Run full deployment pipeline with \`fastlane ci\`"
else
    echo "### Configuration Issues Found
Please address the following issues before proceeding:

1. Install missing configuration files
2. Set up required environment variables
3. Ensure all required lanes are present in Fastfile
4. Verify project structure and entitlements"
fi)

## Environment Setup Checklist

### GitHub Secrets Required
- [ ] \`APPLE_ID\` - Your Apple Developer email
- [ ] \`APPLE_APP_SPECIFIC_PASSWORD\` - App-specific password
- [ ] \`APPLE_TEAM_ID\` - Apple Developer Team ID
- [ ] \`DEVELOPER_CERTIFICATE\` - Base64 encoded Developer ID certificate
- [ ] \`DEVELOPER_CERTIFICATE_PASSWORD\` - Certificate password
- [ ] \`APP_STORE_CERTIFICATE\` - Base64 encoded App Store certificate
- [ ] \`APP_STORE_CERTIFICATE_PASSWORD\` - Certificate password
- [ ] \`APP_STORE_CONNECT_PRIVATE_KEY\` - App Store Connect API key
- [ ] \`APP_STORE_CONNECT_KEY_ID\` - API key ID
- [ ] \`APP_STORE_CONNECT_ISSUER_ID\` - API key issuer ID

### Optional (for Match)
- [ ] \`MATCH_PASSWORD\` - Match repository password
- [ ] \`MATCH_GIT_URL\` - Match certificates repository URL

---
*Report generated by validate-fastlane-config.sh*
EOF

    print_success "Validation report saved to fastlane_validation_report.md"
}

# Main validation
main() {
    print_status "Starting Fastlane configuration validation..."

    local total_errors=0
    local total_warnings=0

    # Run all validations
    validate_fastlane_files || ((total_errors++))
    validate_appfile || ((total_errors++))
    validate_fastfile_lanes || ((total_errors++))
    validate_entitlements || ((total_errors++))
    validate_environment_variables || ((total_warnings++))
    validate_project_structure || ((total_errors++))

    # Generate report
    generate_validation_report

    # Summary
    echo ""
    print_status "Validation Summary:"
    echo "  Errors: $total_errors"
    echo "  Warnings: $total_warnings"

    if [ $total_errors -eq 0 ]; then
        print_success "Fastlane configuration validation PASSED"
        return 0
    else
        print_error "Fastlane configuration validation FAILED"
        print_status "Check fastlane_validation_report.md for details"
        return 1
    fi
}

# Run main validation
main "$@"