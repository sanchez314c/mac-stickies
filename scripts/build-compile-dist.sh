#!/bin/bash

# =============================================================================
# StickyNotes Desktop - Comprehensive Build, Compile & Distribution Script
# =============================================================================
# This script builds the StickyNotes macOS application with comprehensive
# optimization, testing, and distribution support.
#
# Features:
# - Multiple build configurations (Debug, Release, Distribution)
# - Comprehensive testing and validation
# - Code quality checks and optimization
# - Automated cleanup and temporary file management
# - Performance analysis and bloat detection
# - Build artifact organization and signing
# =============================================================================

set -e  # Exit on any error

# =============================================================================
# Configuration and Variables
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Project configuration
PROJECT_NAME="StickyNotes"
SCHEME_NAME="StickyNotes"
WORKSPACE_NAME="StickyNotes.xcworkspace"
PROJECT_FILE="StickyNotes.xcodeproj"
CONFIGURATION="Release"
BUILD_DIR="./build"
DIST_DIR="./dist"
ARCHIVE_DIR="./archives"
TEMP_DIR="./temp"

# Version and build information
VERSION=$(git describe --tags --always --dirty 2>/dev/null || echo "dev")
BUILD_NUMBER=$(git rev-list --count HEAD 2>/dev/null || echo "1")
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Build options
CLEAN_BUILD=false
RUN_TESTS=true
NOTARIZE=false
UPLOAD=false
PERFORMANCE_ANALYSIS=false
CREATE_INSTALLER=true
SKIP_CODESIGNING=false

# Multi-platform options
BUILD_UNIVERSAL=true
BUILD_ARCHS=("x86_64" "arm64")
DEPLOYMENT_TARGET="13.0"
ARCH_SPECIFIC_BUILDS=false
CROSS_COMPILE=false

# =============================================================================
# Utility Functions
# =============================================================================

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

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -c, --clean           Clean build directory before building"
    echo "  -t, --test            Run tests (default: true)"
    echo "  -d, --debug           Build in Debug configuration"
    echo "  -r, --release         Build in Release configuration (default)"
    echo "  --skip-tests          Skip test execution"
    echo "  --skip-codesign       Skip code signing"
    echo "  --no-installer        Don't create installer package"
    echo "  --performance         Run performance analysis"
    echo "  --notarize            Notarize the application (requires Apple Developer account)"
    echo "  --upload              Upload to App Store Connect"
    echo "  --universal           Build universal binary (Intel + Apple Silicon) (default)"
    echo "  --arch-specific       Build separate binaries for each architecture"
    echo "  --deployment-target   Set minimum macOS deployment target (default: 13.0)"
    echo "  --cross-compile       Enable cross-compilation support"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Basic release build"
    echo "  $0 --clean --test     # Clean build with tests"
    echo "  $0 --debug            # Debug build"
    echo "  $0 --performance      # Build with performance analysis"
}

cleanup_on_exit() {
    if [[ -d "$TEMP_DIR" ]]; then
        log_info "Cleaning up temporary files..."
        rm -rf "$TEMP_DIR"
    fi
}

# Set up cleanup trap
trap cleanup_on_exit EXIT

# =============================================================================
# Parse Command Line Arguments
# =============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        -t|--test)
            RUN_TESTS=true
            shift
            ;;
        -d|--debug)
            CONFIGURATION="Debug"
            shift
            ;;
        -r|--release)
            CONFIGURATION="Release"
            shift
            ;;
        --skip-tests)
            RUN_TESTS=false
            shift
            ;;
        --skip-codesign)
            SKIP_CODESIGNING=true
            shift
            ;;
        --no-installer)
            CREATE_INSTALLER=false
            shift
            ;;
        --performance)
            PERFORMANCE_ANALYSIS=true
            shift
            ;;
        --notarize)
            NOTARIZE=true
            shift
            ;;
        --upload)
            UPLOAD=true
            shift
            ;;
        --universal)
            BUILD_UNIVERSAL=true
            ARCH_SPECIFIC_BUILDS=false
            shift
            ;;
        --arch-specific)
            ARCH_SPECIFIC_BUILDS=true
            BUILD_UNIVERSAL=false
            shift
            ;;
        --deployment-target)
            DEPLOYMENT_TARGET="$2"
            shift 2
            ;;
        --cross-compile)
            CROSS_COMPILE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# =============================================================================
# Environment Validation
# =============================================================================

validate_environment() {
    log_step "Validating build environment..."

    # Check if we're on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script must be run on macOS"
        exit 1
    fi

    # Check for Xcode
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode is not installed or not in PATH"
        exit 1
    fi

    # Check for project files
    if [[ ! -f "$PROJECT_FILE" ]]; then
        log_error "Project file not found: $PROJECT_FILE"
        exit 1
    fi

    # Check Xcode version
    XCODE_VERSION=$(xcodebuild -version | head -1 | awk '{print $2}')
    log_info "Xcode version: $XCODE_VERSION"

    # Check Swift version
    SWIFT_VERSION=$(swift --version | head -1 | awk '{print $4}')
    log_info "Swift version: $SWIFT_VERSION"

    log_success "Environment validation complete"
}

# =============================================================================
# Directory Setup and Cleanup
# =============================================================================

setup_directories() {
    log_step "Setting up build directories..."

    # Create directories
    mkdir -p "$BUILD_DIR"
    mkdir -p "$DIST_DIR"
    mkdir -p "$ARCHIVE_DIR"
    mkdir -p "$TEMP_DIR"

    # Clean if requested
    if [[ "$CLEAN_BUILD" == true ]]; then
        log_info "Cleaning build directories..."
        rm -rf "$BUILD_DIR"/*
        rm -rf "$DIST_DIR"/*
        xcodebuild clean -project "$PROJECT_FILE" -scheme "$SCHEME_NAME" || true
    fi

    log_success "Directories setup complete"
}

# =============================================================================
# Code Quality Checks
# =============================================================================

run_code_quality_checks() {
    log_step "Running code quality checks..."

    # Check for SwiftFormat
    if command -v swiftformat &> /dev/null; then
        log_info "Running SwiftFormat..."
        swiftformat . --strict || log_warning "SwiftFormat found issues"
    else
        log_warning "SwiftFormat not found. Install with: brew install swiftformat"
    fi

    # Check for SwiftLint
    if command -v swiftlint &> /dev/null; then
        log_info "Running SwiftLint..."
        swiftlint || log_warning "SwiftLint found issues"
    else
        log_warning "SwiftLint not found. Install with: brew install swiftlint"
    fi

    log_success "Code quality checks complete"
}

# =============================================================================
# Build Process
# =============================================================================

build_application() {
    log_header "Building $PROJECT_NAME v$VERSION (Build $BUILD_NUMBER)"

    if [[ "$BUILD_UNIVERSAL" == true ]]; then
        build_universal_binary
    elif [[ "$ARCH_SPECIFIC_BUILDS" == true ]]; then
        build_arch_specific_binaries
    else
        build_single_architecture
    fi
}

build_single_architecture() {
    log_step "Building single architecture binary"

    local build_command=(
        xcodebuild
        -project "$PROJECT_FILE"
        -scheme "$SCHEME_NAME"
        -configuration "$CONFIGURATION"
        -derivedDataPath "$BUILD_DIR"
        ENABLE_BITCODE=YES
        ONLY_ACTIVE_ARCH=NO
        MACOSX_DEPLOYMENT_TARGET="$DEPLOYMENT_TARGET"
    )

    # Skip code signing if requested
    if [[ "$SKIP_CODESIGNING" == true ]]; then
        build_command+=(CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO)
    fi

    # Add version info
    build_command+=(
        MARKETING_VERSION="$VERSION"
        CURRENT_PROJECT_VERSION="$BUILD_NUMBER"
    )

    log_info "Starting build process..."
    log_info "Configuration: $CONFIGURATION"
    log_info "Skip Code Signing: $SKIP_CODESIGNING"
    log_info "Deployment Target: $DEPLOYMENT_TARGET"

    if "${build_command[@]}"; then
        log_success "Build completed successfully"
    else
        log_error "Build failed"
        exit 1
    fi
}

build_universal_binary() {
    log_step "Building universal binary (Intel + Apple Silicon)"

    # Build for each architecture
    local build_paths=()
    for arch in "${BUILD_ARCHS[@]}"; do
        log_info "Building for architecture: $arch"

        local arch_build_dir="$BUILD_DIR/$arch"
        mkdir -p "$arch_build_dir"

        local build_command=(
            xcodebuild
            -project "$PROJECT_FILE"
            -scheme "$SCHEME_NAME"
            -configuration "$CONFIGURATION"
            -derivedDataPath "$arch_build_dir"
            -arch "$arch"
            ENABLE_BITCODE=YES
            ONLY_ACTIVE_ARCH=NO
            MACOSX_DEPLOYMENT_TARGET="$DEPLOYMENT_TARGET"
        )

        # Skip code signing if requested
        if [[ "$SKIP_CODESIGNING" == true ]]; then
            build_command+=(CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO)
        fi

        # Add version info
        build_command+=(
            MARKETING_VERSION="$VERSION"
            CURRENT_PROJECT_VERSION="$BUILD_NUMBER"
        )

        if "${build_command[@]}"; then
            log_success "Build for $arch completed successfully"
            build_paths+=("$arch_build_dir")
        else
            log_error "Build for $arch failed"
            exit 1
        fi
    done

    # Create universal binary
    log_step "Creating universal binary"
    create_universal_binary "${build_paths[@]}"
}

build_arch_specific_binaries() {
    log_step "Building architecture-specific binaries"

    for arch in "${BUILD_ARCHS[@]}"; do
        log_info "Building for architecture: $arch"

        local arch_dist_dir="$DIST_DIR/$arch"
        mkdir -p "$arch_dist_dir"

        local build_command=(
            xcodebuild
            -project "$PROJECT_FILE"
            -scheme "$SCHEME_NAME"
            -configuration "$CONFIGURATION"
            -derivedDataPath "$BUILD_DIR/$arch"
            -arch "$arch"
            ENABLE_BITCODE=YES
            ONLY_ACTIVE_ARCH=YES
            MACOSX_DEPLOYMENT_TARGET="$DEPLOYMENT_TARGET"
        )

        # Skip code signing if requested
        if [[ "$SKIP_CODESIGNING" == true ]]; then
            build_command+=(CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO)
        fi

        # Add version info
        build_command+=(
            MARKETING_VERSION="$VERSION"
            CURRENT_PROJECT_VERSION="$BUILD_NUMBER"
        )

        if "${build_command[@]}"; then
            log_success "Build for $arch completed successfully"

            # Archive and export for this architecture
            archive_for_arch "$arch" "$arch_dist_dir"
        else
            log_error "Build for $arch failed"
            exit 1
        fi
    done
}

create_universal_binary() {
    local build_paths=("$@")
    log_step "Creating universal binary from ${#build_paths[@]} architectures"

    # Find the built products for each architecture
    local app_paths=()
    for build_path in "${build_paths[@]}"; do
        local app_path=$(find "$build_path/Build/Products/$CONFIGURATION" -name "*.app" | head -1)
        if [[ -n "$app_path" ]]; then
            app_paths+=("$app_path")
        fi
    done

    if [[ ${#app_paths[@]} -lt 2 ]]; then
        log_error "Need at least 2 architecture builds for universal binary"
        exit 1
    fi

    # Create universal binary using lipo
    local universal_app="$BUILD_DIR/Build/Products/$CONFIGURATION/$PROJECT_NAME.app"
    mkdir -p "$(dirname "$universal_app")"

    log_info "Combining architectures into universal binary..."

    # Combine executables
    local exec_name="$PROJECT_NAME"
    local exec_paths=()
    for app_path in "${app_paths[@]}"; do
        exec_paths+=("$app_path/Contents/MacOS/$exec_name")
    done

    lipo -create -output "$universal_app/Contents/MacOS/$exec_name" "${exec_paths[@]}"

    # Copy resources from first architecture (they should be identical)
    cp -R "${app_paths[0]}/Contents/Resources" "$universal_app/Contents/"
    cp "${app_paths[0]}/Contents/Info.plist" "$universal_app/Contents/"
    cp -R "${app_paths[0]}/Contents/Frameworks" "$universal_app/Contents/" 2>/dev/null || true

    log_success "Universal binary created: $universal_app"
}

archive_for_arch() {
    local arch="$1"
    local arch_dist_dir="$2"

    log_step "Archiving for architecture: $arch"

    local archive_path="$arch_dist_dir/${PROJECT_NAME}_${VERSION}_${arch}_${TIMESTAMP}.xcarchive"

    local archive_command=(
        xcodebuild
        archive
        -project "$PROJECT_FILE"
        -scheme "$SCHEME_NAME"
        -configuration "$CONFIGURATION"
        -archivePath "$archive_path"
        -arch "$arch"
        MARKETING_VERSION="$VERSION"
        CURRENT_PROJECT_VERSION="$BUILD_NUMBER"
        MACOSX_DEPLOYMENT_TARGET="$DEPLOYMENT_TARGET"
    )

    if [[ "$SKIP_CODESIGNING" == true ]]; then
        archive_command+=(CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO)
    fi

    if "${archive_command[@]}"; then
        log_success "Archive created for $arch: $archive_path"
    else
        log_error "Archive failed for $arch"
        exit 1
    fi
}

# =============================================================================
# Testing
# =============================================================================

run_tests() {
    if [[ "$RUN_TESTS" != true ]]; then
        log_info "Skipping tests as requested"
        return
    fi

    log_header "Running Tests"

    # Unit tests
    log_step "Running unit tests..."
    if xcodebuild test \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME_NAME" \
        -configuration "$CONFIGURATION" \
        -derivedDataPath "$BUILD_DIR" \
        -enableCodeCoverage YES; then
        log_success "Unit tests passed"
    else
        log_error "Unit tests failed"
        exit 1
    fi

    # Generate coverage report if tools are available
    if command -v xcrun &> /dev/null; then
        log_info "Generating coverage report..."
        xcrun xccov view --report --json "$BUILD_DIR/Logs/Test/*.xcresult" > "$TEMP_DIR/coverage.json" || true
    fi
}

# =============================================================================
# Archive and Export
# =============================================================================

archive_application() {
    log_header "Archiving Application"

    local archive_path="$ARCHIVE_DIR/${PROJECT_NAME}_${VERSION}_${TIMESTAMP}.xcarchive"

    log_step "Creating archive: $archive_path"

    local archive_command=(
        xcodebuild
        archive
        -project "$PROJECT_FILE"
        -scheme "$SCHEME_NAME"
        -configuration "$CONFIGURATION"
        -archivePath "$archive_path"
        MARKETING_VERSION="$VERSION"
        CURRENT_PROJECT_VERSION="$BUILD_NUMBER"
    )

    if [[ "$SKIP_CODESIGNING" == true ]]; then
        archive_command+=(CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO)
    fi

    if "${archive_command[@]}"; then
        log_success "Archive created successfully"
    else
        log_error "Archive failed"
        exit 1
    fi

    # Export archive
    log_step "Exporting archive..."

    local export_options_plist="$TEMP_DIR/ExportOptions.plist"
    cat > "$export_options_plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
EOF

    local export_path="$DIST_DIR/${PROJECT_NAME}_${VERSION}_${TIMESTAMP}"

    if xcodebuild -exportArchive \
        -archivePath "$archive_path" \
        -exportPath "$export_path" \
        -exportOptionsPlist "$export_options_plist"; then
        log_success "Archive exported successfully"
    else
        log_error "Archive export failed"
        exit 1
    fi

    # Find the exported app
    APP_PATH=$(find "$export_path" -name "*.app" | head -1)
    if [[ -z "$APP_PATH" ]]; then
        log_error "No .app file found in export"
        exit 1
    fi

    log_success "Application exported to: $APP_PATH"
}

# =============================================================================
# Create Installer
# =============================================================================

create_installer() {
    if [[ "$CREATE_INSTALLER" != true ]]; then
        log_info "Skipping installer creation as requested"
        return
    fi

    if [[ "$SKIP_CODESIGNING" == true ]]; then
        log_info "Skipping installer creation due to skipped code signing"
        return
    fi

    log_header "Creating Installer Package"

    if [[ -z "$APP_PATH" ]]; then
        log_error "No application found for packaging"
        exit 1
    fi

    local installer_name="${PROJECT_NAME}_${VERSION}_${TIMESTAMP}.pkg"
    local installer_path="$DIST_DIR/$installer_name"

    log_step "Creating installer package..."

    # Create simple installer using productbuild
    if productbuild \
        --root "$APP_PATH" \
        --component "/Applications/$(basename "$APP_PATH")" \
        --install-location "/" \
        --sign "3rd Party Mac Developer Installer: YOUR_TEAM_ID" \
        "$installer_path"; then
        log_success "Installer created: $installer_path"
    else
        log_warning "Installer creation failed (might need proper signing certificate)"
        # Create unsigned installer as fallback
        productbuild \
            --root "$APP_PATH" \
            --component "/Applications/$(basename "$APP_PATH")" \
            --install-location "/" \
            "$installer_path" || log_error "Fallback installer creation failed"
    fi
}

# =============================================================================
# Performance Analysis
# =============================================================================

run_performance_analysis() {
    if [[ "$PERFORMANCE_ANALYSIS" != true ]]; then
        return
    fi

    log_header "Performance Analysis"

    # Analyze binary size
    if [[ -n "$APP_PATH" ]]; then
        log_step "Analyzing application size..."
        local app_size=$(du -sh "$APP_PATH" | cut -f1)
        log_info "Application size: $app_size"

        # Analyze frameworks
        log_info "Analyzing frameworks..."
        find "$APP_PATH/Contents/Frameworks" -name "*.framework" -exec du -sh {} \; 2>/dev/null || true
    fi

    # Run Instruments if available
    if command -v instruments &> /dev/null && [[ -n "$APP_PATH" ]]; then
        log_info "Instruments is available for detailed performance analysis"
        log_info "You can run: instruments -t 'Allocations' '$APP_PATH'"
    fi
}

# =============================================================================
# Build Summary
# =============================================================================

build_summary() {
    log_header "Build Summary"

    echo "Project: $PROJECT_NAME"
    echo "Version: $VERSION"
    echo "Build Number: $BUILD_NUMBER"
    echo "Configuration: $CONFIGURATION"
    echo "Timestamp: $TIMESTAMP"
    echo "Universal Binary: $BUILD_UNIVERSAL"
    echo "Arch-Specific Builds: $ARCH_SPECIFIC_BUILDS"
    echo "Deployment Target: $DEPLOYMENT_TARGET"
    echo "Architectures: ${BUILD_ARCHS[*]}"
    echo ""

    if [[ -n "$APP_PATH" ]]; then
        echo "Application: $APP_PATH"
        local app_size=$(du -sh "$APP_PATH" | cut -f1)
        echo "Size: $app_size"
    fi

    echo "Build Directory: $BUILD_DIR"
    echo "Distribution Directory: $DIST_DIR"
    echo "Archive Directory: $ARCHIVE_DIR"

    # List generated files
    if [[ -d "$DIST_DIR" ]]; then
        echo ""
        echo "Generated Files:"
        ls -la "$DIST_DIR"
    fi

    log_success "Build process completed successfully!"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    log_header "StickyNotes Desktop Build System"
    echo "Version: $VERSION"
    echo "Build: $BUILD_NUMBER"
    echo "Configuration: $CONFIGURATION"
    echo "Timestamp: $TIMESTAMP"
    echo ""

    # Execute build phases
    validate_environment
    setup_directories
    run_code_quality_checks
    build_application
    run_tests
    archive_application
    create_installer
    run_performance_analysis
    build_summary

    log_success "All build operations completed successfully!"
}

# Run main function
main "$@"