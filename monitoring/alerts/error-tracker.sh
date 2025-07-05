#!/bin/bash

# 🚨 Real-time Error Tracking & Alerting System
# Monitors for errors, exceptions, and issues during development

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ALERTS_DIR="$SCRIPT_DIR/../alerts"
LOGS_DIR="$ALERTS_DIR/logs"

# Create directories
mkdir -p "$ALERTS_DIR" "$LOGS_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ERROR_LOG="$LOGS_DIR/error_log_$TIMESTAMP.txt"
ALERT_SUMMARY="$ALERTS_DIR/alert_summary_$TIMESTAMP.json"

echo -e "${RED}🚨 STICKYNOTES ERROR TRACKER${NC}"
echo -e "${RED}==============================${NC}"
echo "Error monitoring session: $(date)"
echo ""

# Initialize alert summary
cat > "$ALERT_SUMMARY" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "session_id": "$TIMESTAMP",
  "alerts": [],
  "summary": {
    "total_alerts": 0,
    "critical": 0,
    "warning": 0,
    "info": 0
  }
}
EOF

# Function to add alert
add_alert() {
    local severity="$1"
    local category="$2"
    local message="$3"
    local details="$4"

    # Add to log
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$severity] [$category] $message" >> "$ERROR_LOG"
    if [ -n "$details" ]; then
        echo "Details: $details" >> "$ERROR_LOG"
    fi
    echo "" >> "$ERROR_LOG"

    # Add to JSON summary
    jq --arg severity "$severity" --arg category "$category" --arg message "$message" --arg details "$details" \
       '.alerts += [{"severity": $severity, "category": $category, "message": $message, "details": $details, "timestamp": "'$(date -Iseconds)'"}]' \
       "$ALERT_SUMMARY" > "${ALERT_SUMMARY}.tmp" && mv "${ALERT_SUMMARY}.tmp" "$ALERT_SUMMARY"

    # Update summary counts
    jq --arg severity "$severity" \
       '.summary.total_alerts += 1 | if $severity == "critical" then .summary.critical += 1 elif $severity == "warning" then .summary.warning += 1 else .summary.info += 1 end' \
       "$ALERT_SUMMARY" > "${ALERT_SUMMARY}.tmp" && mv "${ALERT_SUMMARY}.tmp" "$ALERT_SUMMARY"
}

# Alert Category 1: Build Failures
echo -e "${YELLOW}🔨 CHECKING BUILD STATUS${NC}"

cd "$PROJECT_ROOT/StickyNotes"

if swift build -c debug > /dev/null 2>&1; then
    echo -e "  ✅ Debug build: Success"
else
    echo -e "  ❌ Debug build: Failed"
    BUILD_ERROR=$(swift build -c debug 2>&1 | tail -10)
    add_alert "critical" "build" "Debug build failed" "$BUILD_ERROR"
fi

if swift build -c release > /dev/null 2>&1; then
    echo -e "  ✅ Release build: Success"
else
    echo -e "  ❌ Release build: Failed"
    BUILD_ERROR=$(swift build -c release 2>&1 | tail -10)
    add_alert "critical" "build" "Release build failed" "$BUILD_ERROR"
fi

# Alert Category 2: Test Failures
echo -e "\n${YELLOW}🧪 CHECKING TEST STATUS${NC}"

cd "$PROJECT_ROOT/StickyNotes"

TEST_OUTPUT=$(swift test 2>&1)
TEST_EXIT=$?

if [ $TEST_EXIT -eq 0 ]; then
    echo -e "  ✅ Tests: All passed"
else
    echo -e "  ❌ Tests: Failures detected"
    FAILED_TESTS=$(echo "$TEST_OUTPUT" | grep -E "failed|error" | head -5)
    add_alert "critical" "testing" "Unit tests failed" "$FAILED_TESTS"
fi

# Alert Category 3: Code Quality Issues
echo -e "\n${YELLOW}🔍 CHECKING CODE QUALITY${NC}"

cd "$PROJECT_ROOT"

# SwiftLint check
if command -v swiftlint &> /dev/null; then
    LINT_OUTPUT=$(swiftlint lint --quiet . 2>&1)
    LINT_EXIT=$?

    if [ $LINT_EXIT -ne 0 ]; then
        LINT_ISSUES=$(echo "$LINT_OUTPUT" | wc -l)
        echo -e "  ❌ SwiftLint: $LINT_ISSUES issues found"
        TOP_ISSUES=$(echo "$LINT_OUTPUT" | head -3)
        add_alert "warning" "code_quality" "SwiftLint violations detected" "$TOP_ISSUES"
    else
        echo -e "  ✅ SwiftLint: No issues"
    fi
else
    echo -e "  ⚠️  SwiftLint not available"
    add_alert "info" "code_quality" "SwiftLint not installed" "Install with: brew install swiftlint")
fi

# SwiftFormat check
if command -v swiftformat &> /dev/null; then
    FORMAT_OUTPUT=$(swiftformat --lint . 2>&1)
    FORMAT_EXIT=$?

    if [ $FORMAT_EXIT -ne 0 ]; then
        FORMAT_ISSUES=$(echo "$FORMAT_OUTPUT" | wc -l)
        echo -e "  ❌ SwiftFormat: $FORMAT_ISSUES formatting issues"
        add_alert "warning" "code_quality" "Code formatting issues detected" "Run: swiftformat .")
    else
        echo -e "  ✅ SwiftFormat: Code properly formatted"
    fi
else
    echo -e "  ⚠️  SwiftFormat not available"
    add_alert "info" "code_quality" "SwiftFormat not installed" "Install with: brew install swiftformat")
fi

# Alert Category 4: Security Issues
echo -e "\n${YELLOW}🔒 CHECKING SECURITY${NC}"

cd "$PROJECT_ROOT"

# Check for hardcoded secrets
SECRETS=$(grep -r -i "password\|secret\|key\|token" --include="*.swift" Sources/ | grep -v "import\|//\|#" | wc -l)
if [ "$SECRETS" -gt 0 ]; then
    echo -e "  ❌ Security: $SECRETS potential hardcoded secrets found"
    SECRET_LOCATIONS=$(grep -r -i "password\|secret\|key\|token" --include="*.swift" Sources/ | grep -v "import\|//\|#" | head -3)
    add_alert "critical" "security" "Potential hardcoded secrets detected" "$SECRET_LOCATIONS"
else
    echo -e "  ✅ Security: No hardcoded secrets detected"
fi

# Check for insecure patterns
INSECURE_PATTERNS=$(grep -r "http://" --include="*.swift" Sources/ | grep -v "localhost\|example\|test" | wc -l)
if [ "$INSECURE_PATTERNS" -gt 0 ]; then
    echo -e "  ❌ Security: $INSECURE_PATTERNS insecure HTTP URLs found"
    add_alert "warning" "security" "Insecure HTTP URLs detected" "Use HTTPS instead of HTTP")
else
    echo -e "  ✅ Security: No insecure HTTP URLs"
fi

# Alert Category 5: Performance Issues
echo -e "\n${YELLOW}⚡ CHECKING PERFORMANCE${NC}"

# Check for memory leaks (basic pattern matching)
MEMORY_ISSUES=$(grep -r "retain\|alloc\|dealloc" --include="*.swift" Sources/ | grep -v "import\|//" | wc -l)
if [ "$MEMORY_ISSUES" -gt 10 ]; then
    echo -e "  ⚠️  Performance: High memory management code detected"
    add_alert "warning" "performance" "High memory management activity detected" "Consider using ARC patterns")
else
    echo -e "  ✅ Performance: Memory management looks good"
fi

# Check bundle size
BUNDLE_SIZE=$(du -sh "$PROJECT_ROOT/StickyNotes/.build" 2>/dev/null | awk '{print $1}' || echo "0M")
BUNDLE_MB=$(echo "$BUNDLE_SIZE" | sed 's/M//' | sed 's/K/\/1024/' | bc 2>/dev/null || echo "0")

if (( $(echo "$BUNDLE_MB > 100" | bc -l 2>/dev/null || echo "0") )); then
    echo -e "  ❌ Performance: Large bundle size ($BUNDLE_SIZE)"
    add_alert "warning" "performance" "Bundle size exceeds 100MB" "Current: $BUNDLE_SIZE")
else
    echo -e "  ✅ Performance: Bundle size acceptable"
fi

# Alert Category 6: Dependency Issues
echo -e "\n${YELLOW}📦 CHECKING DEPENDENCIES${NC}"

cd "$PROJECT_ROOT"

# Check Package.swift for issues
if [ -f "Package.swift" ]; then
    DEP_COUNT=$(grep -c "dependencies" Package.swift 2>/dev/null || echo "0")
    echo -e "  ✅ Dependencies: Package.swift found ($DEP_COUNT dependencies)"
else
    echo -e "  ❌ Dependencies: Package.swift missing"
    add_alert "critical" "dependencies" "Package.swift file missing" "Create Package.swift for dependency management")
fi

# Alert Category 7: Documentation Issues
echo -e "\n${YELLOW}📚 CHECKING DOCUMENTATION${NC}"

REQUIRED_DOCS=("README.md" "QUALITY_PLAN.md")
for doc in "${REQUIRED_DOCS[@]}"; do
    if [ -f "$doc" ]; then
        DOC_SIZE=$(wc -c < "$doc")
        if [ $DOC_SIZE -gt 100 ]; then
            echo -e "  ✅ Documentation: $doc present (${DOC_SIZE} bytes)"
        else
            echo -e "  ⚠️  Documentation: $doc exists but very small"
            add_alert "info" "documentation" "$doc is very small" "Consider adding more comprehensive documentation")
        fi
    else
        echo -e "  ❌ Documentation: $doc missing"
        add_alert "warning" "documentation" "Required documentation missing: $doc" "Create $doc with project information")
    fi
done

# Alert Category 8: CI/CD Issues
echo -e "\n${YELLOW}🔄 CHECKING CI/CD STATUS${NC}"

if [ -f ".github/workflows/build-and-release.yml" ]; then
    echo -e "  ✅ CI/CD: GitHub Actions workflow present"
else
    echo -e "  ❌ CI/CD: GitHub Actions workflow missing"
    add_alert "warning" "cicd" "CI/CD pipeline not configured" "Create .github/workflows/build-and-release.yml")
fi

# Generate Alert Summary
echo -e "\n${MAGENTA}📋 ALERT SUMMARY${NC}"
echo -e "${MAGENTA}================${NC}"

CRITICAL_COUNT=$(jq '.summary.critical' "$ALERT_SUMMARY")
WARNING_COUNT=$(jq '.summary.warning' "$ALERT_SUMMARY")
INFO_COUNT=$(jq '.summary.info' "$ALERT_SUMMARY")
TOTAL_COUNT=$(jq '.summary.total_alerts' "$ALERT_SUMMARY")

echo -e "Total Alerts: $TOTAL_COUNT"
echo -e "Critical: ${RED}$CRITICAL_COUNT${NC}"
echo -e "Warning: ${YELLOW}$WARNING_COUNT${NC}"
echo -e "Info: ${BLUE}$INFO_COUNT${NC}"

if [ "$CRITICAL_COUNT" -gt 0 ]; then
    echo -e "\n${RED}🚨 CRITICAL ALERTS:${NC}"
    jq -r '.alerts[] | select(.severity == "critical") | "• \(.category): \(.message)"' "$ALERT_SUMMARY"
fi

if [ "$WARNING_COUNT" -gt 0 ]; then
    echo -e "\n${YELLOW}⚠️  WARNINGS:${NC}"
    jq -r '.alerts[] | select(.severity == "warning") | "• \(.category): \(.message)"' "$ALERT_SUMMARY"
fi

# Save detailed logs
echo ""
echo -e "${GREEN}📝 Detailed logs saved to: $ERROR_LOG${NC}"
echo -e "${GREEN}📊 Alert summary saved to: $ALERT_SUMMARY${NC}"

# Exit with appropriate code
if [ "$CRITICAL_COUNT" -gt 0 ]; then
    echo -e "\n${RED}❌ Critical issues found - immediate attention required!${NC}"
    exit 1
elif [ "$WARNING_COUNT" -gt 0 ]; then
    echo -e "\n${YELLOW}⚠️  Warnings found - review recommended${NC}"
    exit 0
else
    echo -e "\n${GREEN}✅ No alerts - all systems operational!${NC}"
    exit 0
fi