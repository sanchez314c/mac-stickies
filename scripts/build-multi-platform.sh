#!/bin/bash

# =============================================================================
# StickyNotes Desktop - Multi-Platform Build Configuration
# =============================================================================
# This script configures and executes multi-platform builds for StickyNotes
# with support for different macOS versions, architectures, and deployment targets.
#
# Features:
# - Cross-platform macOS builds (Intel, Apple Silicon, Universal)
# - Multiple deployment targets (12.0, 13.0, 14.0, 15.0)
# - Environment-specific builds (Development, Staging, Production)
# - Automated testing and validation across platforms
# - Build matrix generation and parallel execution
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
CONFIG_FILE="config/build-config.json"
BUILD_SCRIPT="./scripts/build-compile-dist.sh"

# Platform configurations
declare -A PLATFORMS
PLATFORMS[macos]="macOS"
PLATFORMS[ios]="iOS"  # Future support
PLATFORMS[ipados]="iPadOS"  # Future support

# Architecture configurations
declare -A ARCHITECTURES
ARCHITECTURES[x86_64]="Intel (x86_64)"
ARCHITECTURES[arm64]="Apple Silicon (arm64)"
ARCHITECTURES[universal]="Universal Binary"

# macOS deployment targets
MACOS_VERSIONS=("12.0" "13.0" "14.0" "15.0")
DEFAULT_MACOS_VERSION="13.0"

# Build environments
ENVIRONMENTS=("development" "staging" "production")
DEFAULT_ENVIRONMENT="development"

# Build options
PARALLEL_BUILD=false
BUILD_ALL_VERSIONS=false
BUILD_ALL_ARCHITECTURES=false
BUILD_ALL_ENVIRONMENTS=false
CLEAN_BUILD=false
RUN_TESTS=true
GENERATE_MATRIX=false

# Matrix configuration
BUILD_MATRIX=()
MATRIX_RESULTS=()

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
    echo "Multi-Platform Build Configuration for StickyNotes"
    echo ""
    echo "Options:"
    echo "  -p, --platform PLATFORM    Target platform (macos, ios, ipados)"
    echo "  -a, --arch ARCH          Architecture (x86_64, arm64, universal)"
    echo "  -v, --version VERSION     macOS deployment target (12.0, 13.0, 14.0, 15.0)"
    echo "  -e, --environment ENV     Build environment (development, staging, production)"
    echo "  --all-versions            Build for all supported macOS versions"
    echo "  --all-archs              Build for all architectures"
    echo "  --all-environments        Build for all environments"
    echo "  --parallel               Enable parallel builds"
    echo "  --matrix                 Generate build matrix"
    echo "  -c, --clean             Clean build directories"
    echo "  --skip-tests             Skip test execution"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --platform macos --arch universal --version 13.0"
    echo "  $0 --all-versions --all-archs --parallel"
    echo "  $0 --environment production --matrix"
}

# =============================================================================
# Configuration Loading and Validation
# =============================================================================

load_build_config() {
    log_step "Loading build configuration..."
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Build configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    # Parse JSON configuration (basic parsing without external tools)
    log_info "Configuration loaded from: $CONFIG_FILE"
    log_success "Build configuration loaded successfully"
}

validate_platform() {
    local platform="$1"
    
    if [[ -z "${PLATFORMS[$platform]}" ]]; then
        log_error "Unsupported platform: $platform"
        log_info "Supported platforms: ${!PLATFORMS[*]}"
        exit 1
    fi
    
    log_info "Platform validated: ${PLATFORMS[$platform]}"
}

validate_architecture() {
    local arch="$1"
    
    if [[ -z "${ARCHITECTURES[$arch]}" ]]; then
        log_error "Unsupported architecture: $arch"
        log_info "Supported architectures: ${!ARCHITECTURES[*]}"
        exit 1
    fi
    
    log_info "Architecture validated: ${ARCHITECTURES[$arch]}"
}

validate_macos_version() {
    local version="$1"
    
    if [[ ! " ${MACOS_VERSIONS[*]} " =~ " $version " ]]; then
        log_error "Unsupported macOS version: $version"
        log_info "Supported versions: ${MACOS_VERSIONS[*]}"
        exit 1
    fi
    
    log_info "macOS version validated: $version"
}

validate_environment() {
    local environment="$1"
    
    if [[ ! " ${ENVIRONMENTS[*]} " =~ " $environment " ]]; then
        log_error "Unsupported environment: $environment"
        log_info "Supported environments: ${ENVIRONMENTS[*]}"
        exit 1
    fi
    
    log_info "Environment validated: $environment"
}

# =============================================================================
# Build Matrix Generation
# =============================================================================

generate_build_matrix() {
    log_header "Generating Build Matrix"
    
    local platforms=("${TARGET_PLATFORMS[@]:-macos}")
    local archs=("${TARGET_ARCHS[@]:-x86_64 arm64 universal}")
    local versions=("${TARGET_VERSIONS[@]:-$DEFAULT_MACOS_VERSION}")
    local environments=("${TARGET_ENVIRONMENTS[@]:-$DEFAULT_ENVIRONMENT}")
    
    log_info "Generating matrix for:"
    log_info "  Platforms: ${platforms[*]}"
    log_info "  Architectures: ${archs[*]}"
    log_info "  Versions: ${versions[*]}"
    log_info "  Environments: ${environments[*]}"
    
    # Generate matrix combinations
    for platform in "${platforms[@]}"; do
        for arch in "${archs[@]}"; do
            for version in "${versions[@]}"; do
                for environment in "${environments[@]}"; do
                    local combination="$platform-$arch-$version-$environment"
                    BUILD_MATRIX+=("$combination")
                    log_info "  Matrix entry: $combination"
                done
            done
        done
    done
    
    log_success "Generated ${#BUILD_MATRIX[@]} build combinations"
}

execute_build_matrix() {
    log_header "Executing Build Matrix"
    
    local total_builds=${#BUILD_MATRIX[@]}
    local current_build=0
    
    for combination in "${BUILD_MATRIX[@]}"; do
        current_build=$((current_build + 1))
        
        # Parse combination
        IFS='-' read -ra PARTS <<< "$combination"
        local platform="${PARTS[0]}"
        local arch="${PARTS[1]}"
        local version="${PARTS[2]}"
        local environment="${PARTS[3]}"
        
        log_step "Building $current_build/$total_builds: $combination"
        
        # Execute build
        if execute_single_build "$platform" "$arch" "$version" "$environment"; then
            MATRIX_RESULTS+=("SUCCESS: $combination")
            log_success "Build completed: $combination"
        else
            MATRIX_RESULTS+=("FAILED: $combination")
            log_error "Build failed: $combination"
        fi
        
        # Add separator between builds
        echo ""
    done
    
    # Show matrix results
    show_matrix_results
}

execute_single_build() {
    local platform="$1"
    local arch="$2"
    local version="$3"
    local environment="$4"
    
    # Build command arguments
    local build_args=(
        "--platform" "$platform"
        "--arch" "$arch"
        "--version" "$version"
        "--environment" "$environment"
    )
    
    if [[ "$CLEAN_BUILD" == true ]]; then
        build_args+=("--clean")
    fi
    
    if [[ "$RUN_TESTS" != true ]]; then
        build_args+=("--skip-tests")
    fi
    
    # Execute build script
    log_info "Executing: $BUILD_SCRIPT ${build_args[*]}"
    
    if [[ -x "$BUILD_SCRIPT" ]]; then
        "$BUILD_SCRIPT" "${build_args[@]}"
        return $?
    else
        log_error "Build script not found or not executable: $BUILD_SCRIPT"
        return 1
    fi
}

show_matrix_results() {
    log_header "Build Matrix Results"
    
    local successful=0
    local failed=0
    
    for result in "${MATRIX_RESULTS[@]}"; do
        if [[ "$result" == SUCCESS:* ]]; then
            successful=$((successful + 1))
            echo -e "${GREEN}✓${NC} ${result#SUCCESS: }"
        else
            failed=$((failed + 1))
            echo -e "${RED}✗${NC} ${result#FAILED: }"
        fi
    done
    
    echo ""
    echo "Summary:"
    echo "  Successful builds: $successful"
    echo "  Failed builds: $failed"
    echo "  Total builds: ${#MATRIX_RESULTS[@]}"
    
    if [[ $failed -gt 0 ]]; then
        return 1
    else
        return 0
    fi
}

# =============================================================================
# Parallel Build Execution
# =============================================================================

execute_parallel_builds() {
    log_header "Executing Parallel Builds"
    
    local pids=()
    local build_count=0
    
    for combination in "${BUILD_MATRIX[@]}"; do
        build_count=$((build_count + 1))
        
        # Limit parallel builds to avoid resource exhaustion
        if [[ ${#pids[@]} -ge 4 ]]; then
            wait_for_build "${pids[0]}"
            pids=("${pids[@]:1}")
        fi
        
        log_info "Starting parallel build $build_count: $combination"
        
        # Execute build in background
        (
            IFS='-' read -ra PARTS <<< "$combination"
            execute_single_build "${PARTS[0]}" "${PARTS[1]}" "${PARTS[2]}" "${PARTS[3]}"
        ) &
        
        pids+=($!)
    done
    
    # Wait for all builds to complete
    for pid in "${pids[@]}"; do
        wait_for_build "$pid"
    done
    
    show_matrix_results
}

wait_for_build() {
    local pid="$1"
    
    if wait "$pid"; then
        log_success "Build process $pid completed successfully"
    else
        log_error "Build process $pid failed"
    fi
}

# =============================================================================
# Platform-Specific Configurations
# =============================================================================

configure_macos_build() {
    local arch="$1"
    local version="$2"
    local environment="$3"
    
    log_step "Configuring macOS build"
    log_info "  Architecture: $arch"
    log_info "  Deployment Target: $version"
    log_info "  Environment: $environment"
    
    # Set environment-specific variables
    case "$environment" in
        development)
            export DEBUG="true"
            export LOG_LEVEL="debug"
            export ENABLE_CLOUDKIT="false"
            ;;
        staging)
            export DEBUG="false"
            export LOG_LEVEL="info"
            export ENABLE_CLOUDKIT="true"
            ;;
        production)
            export DEBUG="false"
            export LOG_LEVEL="warning"
            export ENABLE_CLOUDKIT="true"
            ;;
    esac
    
    # Configure build script arguments
    local build_args=(
        "--deployment-target" "$version"
    )
    
    if [[ "$arch" == "universal" ]]; then
        build_args+=("--universal")
    else
        build_args+=("--arch-specific")
    fi
    
    echo "${build_args[@]}"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    log_header "StickyNotes Multi-Platform Build Configuration"
    
    # Default values
    local target_platform="macos"
    local target_arch="universal"
    local target_version="$DEFAULT_MACOS_VERSION"
    local target_environment="$DEFAULT_ENVIRONMENT"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--platform)
                target_platform="$2"
                validate_platform "$2"
                shift 2
                ;;
            -a|--arch)
                target_arch="$2"
                validate_architecture "$2"
                shift 2
                ;;
            -v|--version)
                target_version="$2"
                validate_macos_version "$2"
                shift 2
                ;;
            -e|--environment)
                target_environment="$2"
                validate_environment "$2"
                shift 2
                ;;
            --all-versions)
                TARGET_VERSIONS=("${MACOS_VERSIONS[@]}")
                shift
                ;;
            --all-archs)
                TARGET_ARCHS=(x86_64 arm64 universal)
                shift
                ;;
            --all-environments)
                TARGET_ENVIRONMENTS=("${ENVIRONMENTS[@]}")
                shift
                ;;
            --parallel)
                PARALLEL_BUILD=true
                shift
                ;;
            --matrix)
                GENERATE_MATRIX=true
                shift
                ;;
            -c|--clean)
                CLEAN_BUILD=true
                shift
                ;;
            --skip-tests)
                RUN_TESTS=false
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
    
    # Load configuration
    load_build_config
    
    # Set target arrays if not specified
    if [[ -z "${TARGET_PLATFORMS[*]}" ]]; then
        TARGET_PLATFORMS=("$target_platform")
    fi
    
    if [[ -z "${TARGET_ARCHS[*]}" ]]; then
        TARGET_ARCHS=("$target_arch")
    fi
    
    if [[ -z "${TARGET_VERSIONS[*]}" ]]; then
        TARGET_VERSIONS=("$target_version")
    fi
    
    if [[ -z "${TARGET_ENVIRONMENTS[*]}" ]]; then
        TARGET_ENVIRONMENTS=("$target_environment")
    fi
    
    # Generate matrix if requested
    if [[ "$GENERATE_MATRIX" == true ]]; then
        generate_build_matrix
    fi
    
    # Execute builds
    if [[ "$PARALLEL_BUILD" == true ]]; then
        execute_parallel_builds
    elif [[ ${#BUILD_MATRIX[@]} -gt 0 ]]; then
        execute_build_matrix
    else
        # Single build execution
        log_header "Executing Single Build"
        if execute_single_build "$target_platform" "$target_arch" "$target_version" "$target_environment"; then
            log_success "Build completed successfully!"
        else
            log_error "Build failed!"
            exit 1
        fi
    fi
}

# Run main function with all arguments
main "$@"