#!/bin/bash

# 🔄 CI/CD Integration for Quality Gates
# Automatically runs quality checks in CI/CD pipelines

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# CI/CD Configuration
CI_MODE=${CI_MODE:-false}
BRANCH_NAME=${BRANCH_NAME:-$(git branch --show-current 2>/dev/null || echo "unknown")}
COMMIT_SHA=${COMMIT_SHA:-$(git rev-parse HEAD 2>/dev/null || echo "unknown")}
PR_NUMBER=${PR_NUMBER:-""}

# Quality gate results
QUALITY_PASSED=true
BLOCKING_ISSUES=0
WARNING_ISSUES=0

echo -e "${CYAN}🔄 STICKYNOTES CI/CD QUALITY GATES${NC}"
echo -e "${CYAN}=====================================${NC}"
echo "CI Mode: $CI_MODE"
echo "Branch: $BRANCH_NAME"
echo "Commit: $COMMIT_SHA"
if [ -n "$PR_NUMBER" ]; then
    echo "PR: #$PR_NUMBER"
fi
echo ""

# Function: Setup CI environment
setup_ci_environment() {
    echo -e "${YELLOW}🔧 SETTING UP CI ENVIRONMENT${NC}"

    # Install required tools if not present
    if ! command -v swiftlint &> /dev/null; then
        echo "  Installing SwiftLint..."
        if command -v brew &> /dev/null; then
            brew install swiftlint
        else
            echo -e "  ⚠️  ${YELLOW}SwiftLint not available - skipping lint checks${NC}"
        fi
    fi

    if ! command -v swiftformat &> /dev/null; then
        echo "  Installing SwiftFormat..."
        if command -v brew &> /dev/null; then
            brew install swiftformat
        else
            echo -e "  ⚠️  ${YELLOW}SwiftFormat not available - skipping format checks${NC}"
        fi
    fi

    echo -e "  ✅ ${GREEN}CI environment ready${NC}"
    echo ""
}

# Function: Pre-commit quality gate
run_pre_commit_checks() {
    echo -e "${YELLOW}🔍 RUNNING PRE-COMMIT CHECKS${NC}"

    # Check for unstaged changes
    if [ "$CI_MODE" = false ]; then
        if ! git diff --quiet || ! git diff --staged --quiet; then
            echo -e "  ⚠️  ${YELLOW}You have unstaged changes. Commit or stash them first.${NC}"
            if [ "$CI_MODE" = true ]; then
                QUALITY_PASSED=false
                ((BLOCKING_ISSUES++))
            fi
        else
            echo -e "  ✅ ${GREEN}Working directory clean${NC}"
        fi
    fi

    # Check for large files
    LARGE_FILES=$(find "$PROJECT_ROOT" -type f -size +50M 2>/dev/null | wc -l)
    if [ "$LARGE_FILES" -gt 0 ]; then
        echo -e "  ❌ ${RED}Large files detected: $LARGE_FILES files >50MB${NC}"
        QUALITY_PASSED=false
        ((BLOCKING_ISSUES++))
    else
        echo -e "  ✅ ${GREEN}No large files detected${NC}"
    fi

    # Check for secrets in code
    SECRETS_FOUND=$(grep -r -i "password\|secret\|key\|token" --include="*.swift" "$PROJECT_ROOT/Sources/" | grep -v "import\|//\|#" | wc -l)
    if [ "$SECRETS_FOUND" -gt 0 ]; then
        echo -e "  ❌ ${RED}Potential secrets found in code: $SECRETS_FOUND instances${NC}"
        QUALITY_PASSED=false
        ((BLOCKING_ISSUES++))
    else
        echo -e "  ✅ ${GREEN}No secrets detected in code${NC}"
    fi

    echo ""
}

# Function: Code quality checks
run_code_quality_checks() {
    echo -e "${YELLOW}🔍 RUNNING CODE QUALITY CHECKS${NC}"

    cd "$PROJECT_ROOT/StickyNotes"

    # SwiftLint check
    if command -v swiftlint &> /dev/null; then
        echo "  Running SwiftLint..."
        SWIFT_LINT_OUTPUT=$(swiftlint lint --quiet . 2>&1)
        SWIFT_LINT_EXIT=$?

        if [ $SWIFT_LINT_EXIT -eq 0 ]; then
            echo -e "  ✅ ${GREEN}SwiftLint: All checks passed${NC}"
        else
            LINT_ISSUES=$(echo "$SWIFT_LINT_OUTPUT" | wc -l)
            echo -e "  ❌ ${RED}SwiftLint: $LINT_ISSUES issues found${NC}"
            echo "$SWIFT_LINT_OUTPUT" | head -10 | sed 's/^/    /'
            QUALITY_PASSED=false
            ((BLOCKING_ISSUES++))
        fi
    else
        echo -e "  ⚠️  ${YELLOW}SwiftLint not available${NC}"
        ((WARNING_ISSUES++))
    fi

    # SwiftFormat check
    if command -v swiftformat &> /dev/null; then
        echo "  Running SwiftFormat..."
        if swiftformat --lint . > /dev/null 2>&1; then
            echo -e "  ✅ ${GREEN}SwiftFormat: Code properly formatted${NC}"
        else
            echo -e "  ❌ ${RED}SwiftFormat: Code formatting issues${NC}"
            QUALITY_PASSED=false
            ((WARNING_ISSUES++))
        fi
    else
        echo -e "  ⚠️  ${YELLOW}SwiftFormat not available${NC}"
        ((WARNING_ISSUES++))
    fi

    echo ""
}

# Function: Build verification
run_build_verification() {
    echo -e "${YELLOW}🔨 RUNNING BUILD VERIFICATION${NC}"

    cd "$PROJECT_ROOT/StickyNotes"

    # Debug build
    echo "  Testing debug build..."
    if swift build -c debug > /dev/null 2>&1; then
        echo -e "  ✅ ${GREEN}Debug build: SUCCESS${NC}"
    else
        echo -e "  ❌ ${RED}Debug build: FAILED${NC}"
        QUALITY_PASSED=false
        ((BLOCKING_ISSUES++))
    fi

    # Release build
    echo "  Testing release build..."
    if swift build -c release > /dev/null 2>&1; then
        echo -e "  ✅ ${GREEN}Release build: SUCCESS${NC}"
    else
        echo -e "  ❌ ${RED}Release build: FAILED${NC}"
        QUALITY_PASSED=false
        ((BLOCKING_ISSUES++))
    fi

    echo ""
}

# Function: Test execution
run_test_execution() {
    echo -e "${YELLOW}🧪 RUNNING TEST EXECUTION${NC}"

    cd "$PROJECT_ROOT/StickyNotes"

    # Run tests
    echo "  Executing test suite..."
    TEST_OUTPUT=$(swift test 2>&1)
    TEST_EXIT=$?

    if [ $TEST_EXIT -eq 0 ]; then
        echo -e "  ✅ ${GREEN}All tests passed${NC}"

        # Extract test counts (simplified)
        TEST_COUNT=$(echo "$TEST_OUTPUT" | grep -c "Test Case" || echo "0")
        echo -e "  📊 Tests executed: $TEST_COUNT"
    else
        echo -e "  ❌ ${RED}Test failures detected${NC}"
        echo "$TEST_OUTPUT" | grep -A5 -B5 "failed\|error" | head -20 | sed 's/^/    /'
        QUALITY_PASSED=false
        ((BLOCKING_ISSUES++))
    fi

    echo ""
}

# Function: Performance benchmarks
run_performance_checks() {
    echo -e "${YELLOW}⚡ RUNNING PERFORMANCE CHECKS${NC}"

    # Run performance monitor
    PERF_SCRIPT="$SCRIPT_DIR/../metrics/performance-monitor.sh"

    if [ -x "$PERF_SCRIPT" ]; then
        echo "  Running performance benchmarks..."
        PERF_OUTPUT=$("$PERF_SCRIPT" 2>&1)
        PERF_EXIT=$?

        if [ $PERF_EXIT -eq 0 ]; then
            echo -e "  ✅ ${GREEN}Performance benchmarks passed${NC}"

            # Check for failures in output
            PERF_FAILURES=$(echo "$PERF_OUTPUT" | grep -c "FAIL" || echo "0")
            if [ "$PERF_FAILURES" -gt 0 ]; then
                echo -e "  ⚠️  ${YELLOW}Some performance benchmarks not met${NC}"
                ((WARNING_ISSUES++))
            fi
        else
            echo -e "  ❌ ${RED}Performance benchmarks failed${NC}"
            QUALITY_PASSED=false
            ((BLOCKING_ISSUES++))
        fi
    else
        echo -e "  ⚠️  ${YELLOW}Performance monitoring script not available${NC}"
        ((WARNING_ISSUES++))
    fi

    echo ""
}

# Function: Security scan
run_security_scan() {
    echo -e "${YELLOW}🔒 RUNNING SECURITY SCAN${NC}"

    cd "$PROJECT_ROOT"

    # Basic security checks
    SECURITY_ISSUES=0

    # Check for insecure imports
    INSECURE_IMPORTS=$(grep -r "import.*http" --include="*.swift" Sources/ | wc -l)
    if [ "$INSECURE_IMPORTS" -gt 0 ]; then
        echo -e "  ⚠️  ${YELLOW}Insecure HTTP imports detected: $INSECURE_IMPORTS${NC}"
        ((SECURITY_ISSUES++))
    fi

    # Check for weak crypto
    WEAK_CRYPTO=$(grep -r "MD5\|SHA1" --include="*.swift" Sources/ | grep -v "import\|//" | wc -l)
    if [ "$WEAK_CRYPTO" -gt 0 ]; then
        echo -e "  ⚠️  ${YELLOW}Weak cryptographic functions detected: $WEAK_CRYPTO${NC}"
        ((SECURITY_ISSUES++))
    fi

    # Check for debug code
    DEBUG_CODE=$(grep -r "print\|debugPrint\|NSLog" --include="*.swift" Sources/ | grep -v "import\|//\|#" | wc -l)
    if [ "$DEBUG_CODE" -gt 10 ]; then
        echo -e "  ⚠️  ${YELLOW}Excessive debug code detected: $DEBUG_CODE instances${NC}"
        ((SECURITY_ISSUES++))
    fi

    if [ "$SECURITY_ISSUES" -eq 0 ]; then
        echo -e "  ✅ ${GREEN}Security scan passed${NC}"
    else
        echo -e "  ⚠️  ${YELLOW}Security issues detected: $SECURITY_ISSUES${NC}"
        ((WARNING_ISSUES++))
    fi

    echo ""
}

# Function: Generate CI report
generate_ci_report() {
    echo -e "${YELLOW}📊 GENERATING CI REPORT${NC}"

    REPORT_FILE="$SCRIPT_DIR/ci_report_$(date +%Y%m%d_%H%M%S).json"

    cat > "$REPORT_FILE" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "ci_mode": $CI_MODE,
  "branch": "$BRANCH_NAME",
  "commit": "$COMMIT_SHA",
  "pr_number": "$PR_NUMBER",
  "quality_gates": {
    "passed": $QUALITY_PASSED,
    "blocking_issues": $BLOCKING_ISSUES,
    "warning_issues": $WARNING_ISSUES
  },
  "checks": {
    "pre_commit": $([ $BLOCKING_ISSUES -eq 0 ] && echo "true" || echo "false"),
    "code_quality": $([ $BLOCKING_ISSUES -eq 0 ] && echo "true" || echo "false"),
    "build_verification": $([ $BLOCKING_ISSUES -eq 0 ] && echo "true" || echo "false"),
    "test_execution": $([ $BLOCKING_ISSUES -eq 0 ] && echo "true" || echo "false"),
    "performance": $([ $BLOCKING_ISSUES -eq 0 ] && echo "true" || echo "false"),
    "security": $([ $WARNING_ISSUES -eq 0 ] && echo "true" || echo "false")
  },
  "recommendations": [
    $(if [ $BLOCKING_ISSUES -gt 0 ]; then echo "\"Fix blocking issues before merge\","; fi)
    $(if [ $WARNING_ISSUES -gt 0 ]; then echo "\"Address warning issues\","; fi)
    "Consider running full monitoring suite locally"
  ]
}
EOF

    echo -e "  ✅ ${GREEN}CI report generated: $REPORT_FILE${NC}"
    echo ""
}

# Function: Display final results
display_final_results() {
    echo -e "${CYAN}📋 QUALITY GATE SUMMARY${NC}"
    echo -e "${CYAN}========================${NC}"

    echo -e "Blocking Issues: ${RED}$BLOCKING_ISSUES${NC}"
    echo -e "Warning Issues: ${YELLOW}$WARNING_ISSUES${NC}"

    if [ "$QUALITY_PASSED" = true ]; then
        echo -e "Overall Status: ${GREEN}✅ PASSED${NC}"
        echo ""
        echo -e "${GREEN}🎉 All quality gates passed! Ready for merge.${NC}"
        return 0
    else
        echo -e "Overall Status: ${RED}❌ FAILED${NC}"
        echo ""
        echo -e "${RED}🚫 Quality gates failed. Please fix issues before proceeding.${NC}"
        return 1
    fi
}

# Main execution
main() {
    setup_ci_environment

    run_pre_commit_checks
    run_code_quality_checks
    run_build_verification
    run_test_execution
    run_performance_checks
    run_security_scan

    generate_ci_report
    display_final_results

    return $?
}

# Run main function
main