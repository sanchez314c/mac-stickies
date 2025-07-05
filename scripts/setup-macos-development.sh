#!/bin/bash

# macOS Development Environment Setup Script
# Sets up certificates, provisioning profiles, and development tools

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
if [ "$(uname)" != "Darwin" ]; then
    print_error "This script must be run on macOS"
    exit 1
fi

print_status "Setting up macOS development environment for StickyNotes"

# Check for Xcode
if ! xcode-select -p >/dev/null 2>&1; then
    print_error "Xcode is not installed or not properly set up"
    print_status "Please install Xcode from the Mac App Store"
    exit 1
fi

print_success "Xcode is installed"

# Accept Xcode license
print_status "Accepting Xcode license..."
sudo xcodebuild -license accept
print_success "Xcode license accepted"

# Install Xcode command line tools
print_status "Installing Xcode command line tools..."
if ! xcode-select --install 2>/dev/null; then
    print_warning "Command line tools may already be installed"
fi
print_success "Command line tools ready"

# Install Homebrew if not present
if ! command -v brew >/dev/null 2>&1; then
    print_status "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    print_success "Homebrew installed"
else
    print_success "Homebrew already installed"
fi

# Install development tools
print_status "Installing development tools..."
brew install swiftlint
brew install fastlane
brew install imagemagick
brew install create-dmg

# Install Node.js for any build scripts
brew install node

print_success "Development tools installed"

# Create development certificates directory
print_status "Setting up certificates directory..."
CERTS_DIR="$HOME/Developer/Certificates/StickyNotes"
mkdir -p "$CERTS_DIR"

cat > "$CERTS_DIR/README.md" << 'EOF'
# StickyNotes Development Certificates

This directory contains certificates and provisioning profiles for StickyNotes development.

## Required Certificates

1. **Apple Development Certificate** - For development builds
2. **Apple Distribution Certificate** - For direct distribution
3. **Mac App Store Distribution Certificate** - For App Store builds
4. **Developer ID Application Certificate** - For notarization

## Provisioning Profiles

1. **Development Profile** - com.superclaude.stickynotes
2. **App Store Profile** - com.superclaude.stickynotes
3. **Developer ID Profile** - com.superclaude.stickynotes

## Setup Instructions

1. Download certificates from Apple Developer Portal
2. Place .p12 files in this directory
3. Update build scripts with certificate names
4. Set up environment variables for CI/CD

## Environment Variables

Set these in your shell profile or CI/CD secrets:

```bash
export APPLE_TEAM_ID="YOUR_TEAM_ID"
export APPLE_ID="your.email@example.com"
export DEVELOPER_CERTIFICATE_PATH="$HOME/Developer/Certificates/StickyNotes/dev.p12"
export APP_STORE_CERTIFICATE_PATH="$HOME/Developer/Certificates/StickyNotes/appstore.p12"
```
EOF

print_success "Certificates directory created at $CERTS_DIR"

# Set up Fastlane
print_status "Setting up Fastlane..."
cd "$(dirname "$0")/.."
fastlane init

print_success "Fastlane initialized"

# Create .env file template
cat > .env.example << 'EOF'
# Apple Developer Credentials
APPLE_TEAM_ID=YOUR_TEAM_ID
APPLE_ID=your.email@example.com
APPLE_APP_SPECIFIC_PASSWORD=your_app_specific_password

# Certificate Paths
DEVELOPER_CERTIFICATE_PATH=/path/to/dev.p12
DEVELOPER_CERTIFICATE_PASSWORD=cert_password
APP_STORE_CERTIFICATE_PATH=/path/to/appstore.p12
APP_STORE_CERTIFICATE_PASSWORD=cert_password

# CI/CD
GITHUB_TOKEN=your_github_token
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...

# App Store Connect
APPLE_ITC_TEAM_ID=your_itc_team_id
EOF

print_success "Environment template created (.env.example)"

# Set up Git hooks for code quality
print_status "Setting up Git hooks..."
mkdir -p .git/hooks

cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

# Pre-commit hook for code quality checks

echo "Running pre-commit checks..."

# Run SwiftLint if available
if command -v swiftlint >/dev/null 2>&1; then
    echo "Running SwiftLint..."
    swiftlint --strict
    if [ $? -ne 0 ]; then
        echo "SwiftLint failed. Please fix the issues."
        exit 1
    fi
fi

echo "Pre-commit checks passed!"
EOF

chmod +x .git/hooks/pre-commit
print_success "Git hooks set up"

# Create build optimization script
print_status "Creating build optimization script..."
cat > scripts/optimize-build.sh << 'EOF'
#!/bin/bash

# Build Optimization Script for StickyNotes

echo "Optimizing build settings..."

# Enable build caching
defaults write com.apple.dt.Xcode IDEBuildOperationMaxNumberOfConcurrentCompileTasks 8

# Enable faster builds
defaults write com.apple.dt.Xcode IDEBuildOperationTimingPopupEnabled 0

# Optimize Swift compilation
defaults write com.apple.dt.Xcode IDEIndexEnable 0

echo "Build optimizations applied!"
echo "Note: These optimizations improve development build speed but may affect debugging."
EOF

chmod +x scripts/optimize-build.sh
print_success "Build optimization script created"

print_success "macOS development environment setup complete!"
echo ""
echo "Next steps:"
echo "1. Set up Apple Developer Program account"
echo "2. Create and download certificates from Apple Developer Portal"
echo "3. Place certificates in $CERTS_DIR"
echo "4. Copy .env.example to .env and fill in your credentials"
echo "5. Run 'fastlane match init' to set up code signing"
echo "6. Run './scripts/optimize-build.sh' for faster builds"
echo ""
echo "For CI/CD setup, add the following secrets to your GitHub repository:"
echo "- APPLE_TEAM_ID"
echo "- APPLE_ID"
echo "- APPLE_APP_SPECIFIC_PASSWORD"
echo "- DEVELOPER_CERTIFICATE (base64 encoded)"
echo "- DEVELOPER_CERTIFICATE_PASSWORD"