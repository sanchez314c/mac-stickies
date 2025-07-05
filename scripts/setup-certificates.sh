#!/bin/bash

# Certificate Setup Script for StickyNotes
# Handles certificate export, import, and configuration for CI/CD

set -e

# Configuration
TEAM_ID="${APPLE_TEAM_ID:-ABC123DEF4}"
APPLE_ID="${APPLE_ID:-your-email@example.com}"
BUNDLE_ID="com.superclaude.stickynotes"

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

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script must be run on macOS"
    exit 1
fi

# Parse command line arguments
COMMAND=""
CERT_TYPE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        export)
            COMMAND="export"
            shift
            ;;
        import)
            COMMAND="import"
            shift
            ;;
        setup-match)
            COMMAND="setup-match"
            shift
            ;;
        --development)
            CERT_TYPE="development"
            shift
            ;;
        --app-store)
            CERT_TYPE="app-store"
            shift
            ;;
        --direct-distribution)
            CERT_TYPE="direct-distribution"
            shift
            ;;
        --help)
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  export              Export certificates for CI/CD"
            echo "  import              Import certificates from CI/CD"
            echo "  setup-match         Set up Fastlane Match repository"
            echo ""
            echo "Options:"
            echo "  --development       Work with development certificates"
            echo "  --app-store        Work with App Store certificates"
            echo "  --direct-distribution  Work with direct distribution certificates"
            echo "  --help              Show this help"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$COMMAND" ]; then
    print_error "No command specified. Use --help for usage information."
    exit 1
fi

# Export certificates for CI/CD
export_certificates() {
    print_status "Exporting certificates for CI/CD..."

    # Create certificates directory
    mkdir -p certificates

    # Export Developer ID certificate (for direct distribution)
    if [ "$CERT_TYPE" = "direct-distribution" ] || [ -z "$CERT_TYPE" ]; then
        print_status "Exporting Developer ID certificate..."

        # Find Developer ID certificate
        DEV_CERT_ID=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | awk '{print $2}')

        if [ -z "$DEV_CERT_ID" ]; then
            print_error "Developer ID Application certificate not found"
            print_warning "Please ensure you have a Developer ID Application certificate installed"
            print_warning "Go to https://developer.apple.com/account/resources/certificates/ to create one"
            exit 1
        fi

        # Export certificate
        security export -f pkcs12 \
            -k ~/Library/Keychains/login.keychain \
            -t identities \
            -o certificates/developer_id.p12 \
            -P "developer_cert_password"

        print_success "Developer ID certificate exported to certificates/developer_id.p12"

        # Convert to base64 for GitHub secrets
        DEV_CERT_B64=$(base64 -i certificates/developer_id.p12)
        echo "$DEV_CERT_B64" > certificates/developer_id.b64
        print_success "Base64 encoded certificate saved to certificates/developer_id.b64"
    fi

    # Export App Store certificate
    if [ "$CERT_TYPE" = "app-store" ] || [ -z "$CERT_TYPE" ]; then
        print_status "Exporting App Store certificate..."

        # Find App Store certificate
        APP_STORE_CERT_ID=$(security find-identity -v -p codesigning | grep "Apple Distribution" | head -1 | awk '{print $2}')

        if [ -z "$APP_STORE_CERT_ID" ]; then
            print_error "Apple Distribution certificate not found"
            print_warning "Please ensure you have an Apple Distribution certificate installed"
            print_warning "Go to https://developer.apple.com/account/resources/certificates/ to create one"
            exit 1
        fi

        # Export certificate
        security export -f pkcs12 \
            -k ~/Library/Keychains/login.keychain \
            -t identities \
            -o certificates/app_store.p12 \
            -P "app_store_cert_password"

        print_success "App Store certificate exported to certificates/app_store.p12"

        # Convert to base64 for GitHub secrets
        APP_STORE_CERT_B64=$(base64 -i certificates/app_store.p12)
        echo "$APP_STORE_CERT_B64" > certificates/app_store.b64
        print_success "Base64 encoded certificate saved to certificates/app_store.b64"
    fi

    # Create setup instructions
    cat > certificates/README.md << EOF
# Certificate Setup Instructions

This directory contains exported certificates for CI/CD deployment.

## GitHub Secrets Configuration

Copy the base64 encoded certificates to your GitHub repository secrets:

### Developer Certificate (Direct Distribution)
\`\`\`bash
DEVELOPER_CERTIFICATE=$(cat developer_id.b64)
DEVELOPER_CERTIFICATE_PASSWORD=developer_cert_password
\`\`\`

### App Store Certificate
\`\`\`bash
APP_STORE_CERTIFICATE=$(cat app_store.b64)
APP_STORE_CERTIFICATE_PASSWORD=app_store_cert_password
\`\`\`

## Security Notes
- Keep certificate passwords secure and never commit them to version control
- Rotate certificates regularly (Apple recommends annually)
- Use different passwords for each certificate type
- Store base64 files securely and delete after configuring secrets

## Certificate Types Exported
$(if [ "$CERT_TYPE" = "direct-distribution" ] || [ -z "$CERT_TYPE" ]; then echo "- Developer ID Application (for direct distribution)"; fi)
$(if [ "$CERT_TYPE" = "app-store" ] || [ -z "$CERT_TYPE" ]; then echo "- Apple Distribution (for App Store)"; fi)
EOF

    print_success "Certificate export completed"
    print_status "See certificates/README.md for setup instructions"
}

# Import certificates from CI/CD
import_certificates() {
    print_status "Importing certificates from CI/CD..."

    if [ -z "$CERT_TYPE" ]; then
        print_error "Certificate type must be specified for import"
        exit 1
    fi

    # Create temporary keychain for CI
    if [ "$CI" = "true" ]; then
        print_status "Creating temporary keychain for CI..."

        KEYCHAIN_NAME="fastlane_tmp_keychain"
        KEYCHAIN_PASSWORD=$(openssl rand -base64 32)

        security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME"
        security default-keychain -s "$KEYCHAIN_NAME"
        security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME"
        security set-keychain-settings -t 3600 -u "$KEYCHAIN_NAME"
    fi

    # Import Developer ID certificate
    if [ "$CERT_TYPE" = "direct-distribution" ]; then
        if [ -z "$DEVELOPER_CERTIFICATE" ] || [ -z "$DEVELOPER_CERTIFICATE_PASSWORD" ]; then
            print_error "DEVELOPER_CERTIFICATE and DEVELOPER_CERTIFICATE_PASSWORD environment variables required"
            exit 1
        fi

        print_status "Importing Developer ID certificate..."

        # Decode and import certificate
        echo "$DEVELOPER_CERTIFICATE" | base64 -d > /tmp/developer_id.p12
        security import /tmp/developer_id.p12 \
            -k "$KEYCHAIN_NAME" \
            -P "$DEVELOPER_CERTIFICATE_PASSWORD" \
            -T /usr/bin/codesign

        print_success "Developer ID certificate imported"
    fi

    # Import App Store certificate
    if [ "$CERT_TYPE" = "app-store" ]; then
        if [ -z "$APP_STORE_CERTIFICATE" ] || [ -z "$APP_STORE_CERTIFICATE_PASSWORD" ]; then
            print_error "APP_STORE_CERTIFICATE and APP_STORE_CERTIFICATE_PASSWORD environment variables required"
            exit 1
        fi

        print_status "Importing App Store certificate..."

        # Decode and import certificate
        echo "$APP_STORE_CERTIFICATE" | base64 -d > /tmp/app_store.p12
        security import /tmp/app_store.p12 \
            -k "$KEYCHAIN_NAME" \
            -P "$APP_STORE_CERTIFICATE_PASSWORD" \
            -T /usr/bin/codesign

        print_success "App Store certificate imported"
    fi

    # Set up code signing permissions
    security set-key-partition-list -S apple-tool:,apple: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME" 2>/dev/null || true

    print_success "Certificate import completed"
}

# Set up Fastlane Match
setup_match() {
    print_status "Setting up Fastlane Match repository..."

    if [ -z "$MATCH_GIT_URL" ]; then
        print_error "MATCH_GIT_URL environment variable required"
        print_warning "Set MATCH_GIT_URL to your certificates repository URL"
        exit 1
    fi

    # Initialize Match
    print_status "Initializing Match repository..."
    fastlane match init

    # Configure Match for different certificate types
    if [ "$CERT_TYPE" = "development" ] || [ -z "$CERT_TYPE" ]; then
        print_status "Setting up development certificates..."
        fastlane match development --readonly false
    fi

    if [ "$CERT_TYPE" = "app-store" ] || [ -z "$CERT_TYPE" ]; then
        print_status "Setting up App Store certificates..."
        fastlane match appstore --readonly false
    fi

    if [ "$CERT_TYPE" = "direct-distribution" ] || [ -z "$CERT_TYPE" ]; then
        print_status "Setting up Mac Installer certificates..."
        fastlane match mac_installer_distribution --readonly false
    fi

    print_success "Fastlane Match setup completed"
    print_status "Certificates are now stored in: $MATCH_GIT_URL"
}

# Main execution
case $COMMAND in
    export)
        export_certificates
        ;;
    import)
        import_certificates
        ;;
    setup-match)
        setup_match
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        exit 1
        ;;
esac

print_success "Certificate setup script completed"