#!/bin/bash

# 📊 Development Dashboard for StickyNotes
# Real-time monitoring and progress reporting

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DASHBOARD_DIR="$SCRIPT_DIR/../dashboards"

# Create dashboard directory
mkdir -p "$DASHBOARD_DIR"

clear

echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║                 STICKYNOTES DEVELOPMENT DASHBOARD                ║${NC}"
echo -e "${MAGENTA}║              Real-time Quality & Progress Monitoring              ║${NC}"
echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function: Project Overview
project_overview() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📋 PROJECT OVERVIEW${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Project stats
    SWIFT_FILES=$(find "$PROJECT_ROOT" -name "*.swift" -type f | wc -l)
    TOTAL_LINES=$(find "$PROJECT_ROOT" -name "*.swift" -type f -exec wc -l {} \; | awk '{sum+=$1} END {print sum}')
    TEST_FILES=$(find "$PROJECT_ROOT" -name "*Test*.swift" -type f | wc -l)

    echo -e "  📁 Project: ${WHITE}StickyNotes${NC}"
    echo -e "  🔧 Language: ${WHITE}Swift${NC}"
    echo -e "  📄 Swift Files: ${WHITE}$SWIFT_FILES${NC}"
    echo -e "  📏 Total Lines: ${WHITE}$TOTAL_LINES${NC}"
    echo -e "  🧪 Test Files: ${WHITE}$TEST_FILES${NC}"
    echo -e "  📊 Test Ratio: ${WHITE}$(echo "scale=1; $TEST_FILES * 100 / $SWIFT_FILES" | bc 2>/dev/null || echo "0")%${NC}"
    echo ""
}

# Function: Quality Gates Status
quality_gates_status() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🚪 QUALITY GATES${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Check if quality gate script exists and run it
    QUALITY_SCRIPT="$SCRIPT_DIR/../quality-gates/quality-gate-runner.sh"

    if [ -f "$QUALITY_SCRIPT" ]; then
        # Run quality gates (capture output)
        QUALITY_OUTPUT=$("$QUALITY_SCRIPT" 2>&1)
        QUALITY_EXIT=$?

        if [ $QUALITY_EXIT -eq 0 ]; then
            echo -e "  ✅ ${GREEN}ALL QUALITY GATES PASSED${NC}"
        else
            echo -e "  ❌ ${RED}QUALITY GATES FAILED${NC}"
            echo "$QUALITY_OUTPUT" | grep -E "❌|⚠️" | head -3 | sed 's/^/    /'
        fi
    else
        echo -e "  ⚠️  ${YELLOW}Quality gate script not found${NC}"
    fi
    echo ""
}

# Function: Performance Metrics
performance_metrics() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}⚡ PERFORMANCE METRICS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Check for recent performance data
    METRICS_DIR="$SCRIPT_DIR/../metrics"
    LATEST_METRICS=$(find "$METRICS_DIR" -name "performance_*.json" -type f -mmin -60 | head -1 2>/dev/null)

    if [ -n "$LATEST_METRICS" ]; then
        # Parse metrics
        STARTUP_TIME=$(jq -r '.metrics.startup_time.value' "$LATEST_METRICS" 2>/dev/null || echo "N/A")
        MEMORY_USAGE=$(jq -r '.metrics.memory_usage.value' "$LATEST_METRICS" 2>/dev/null || echo "N/A")
        CPU_USAGE=$(jq -r '.metrics.cpu_usage.value' "$LATEST_METRICS" 2>/dev/null || echo "N/A")
        COVERAGE=$(jq -r '.metrics.code_coverage.value' "$LATEST_METRICS" 2>/dev/null || echo "N/A")

        echo -e "  🚀 Startup Time: ${WHITE}${STARTUP_TIME}s${NC} (Target: <3.0s)"
        echo -e "  💾 Memory Usage: ${WHITE}${MEMORY_USAGE}MB${NC} (Target: <100MB)"
        echo -e "  ⚡ CPU Usage: ${WHITE}${CPU_USAGE}%${NC} (Target: <20%)"
        echo -e "  📈 Code Coverage: ${WHITE}${COVERAGE}%${NC} (Target: >90%)"
    else
        echo -e "  ${YELLOW}No recent performance data available${NC}"
        echo -e "  ${BLUE}Run performance monitor to collect metrics${NC}"
    fi
    echo ""
}

# Function: Error & Alert Status
error_alert_status() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🚨 ERRORS & ALERTS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Check for recent alerts
    ALERTS_DIR="$SCRIPT_DIR/../alerts"
    LATEST_ALERTS=$(find "$ALERTS_DIR" -name "alert_summary_*.json" -type f -mmin -60 | head -1 2>/dev/null)

    if [ -n "$LATEST_ALERTS" ]; then
        CRITICAL=$(jq -r '.summary.critical' "$LATEST_ALERTS" 2>/dev/null || echo "0")
        WARNING=$(jq -r '.summary.warning' "$LATEST_ALERTS" 2>/dev/null || echo "0")
        INFO=$(jq -r '.summary.info' "$LATEST_ALERTS" 2>/dev/null || echo "0")

        if [ "$CRITICAL" -gt 0 ]; then
            echo -e "  ❌ Critical: ${RED}$CRITICAL${NC}"
        else
            echo -e "  ✅ Critical: ${GREEN}0${NC}"
        fi

        if [ "$WARNING" -gt 0 ]; then
            echo -e "  ⚠️  Warning: ${YELLOW}$WARNING${NC}"
        else
            echo -e "  ✅ Warning: ${GREEN}0${NC}"
        fi

        echo -e "  ℹ️  Info: ${BLUE}$INFO${NC}"
    else
        echo -e "  ${GREEN}✅ No recent alerts${NC}"
    fi
    echo ""
}

# Function: Build & Test Status
build_test_status() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🔨 BUILD & TEST STATUS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    cd "$PROJECT_ROOT/StickyNotes"

    # Check build status
    if swift build -c debug > /dev/null 2>&1; then
        echo -e "  ✅ Debug Build: ${GREEN}PASS${NC}"
    else
        echo -e "  ❌ Debug Build: ${RED}FAIL${NC}"
    fi

    if swift build -c release > /dev/null 2>&1; then
        echo -e "  ✅ Release Build: ${GREEN}PASS${NC}"
    else
        echo -e "  ❌ Release Build: ${RED}FAIL${NC}"
    fi

    # Check test status
    if swift test > /dev/null 2>&1; then
        echo -e "  ✅ Unit Tests: ${GREEN}PASS${NC}"
    else
        echo -e "  ❌ Unit Tests: ${RED}FAIL${NC}"
    fi

    # Check CI/CD status (simplified)
    if [ -f "$PROJECT_ROOT/.github/workflows/build-and-release.yml" ]; then
        echo -e "  ✅ CI/CD Pipeline: ${GREEN}CONFIGURED${NC}"
    else
        echo -e "  ❌ CI/CD Pipeline: ${RED}NOT CONFIGURED${NC}"
    fi
    echo ""
}

# Function: Code Quality Metrics
code_quality_metrics() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🔍 CODE QUALITY${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    cd "$PROJECT_ROOT"

    # SwiftLint status
    if command -v swiftlint &> /dev/null; then
        LINT_ISSUES=$(swiftlint lint --quiet . 2>&1 | wc -l)
        if [ "$LINT_ISSUES" -eq 0 ]; then
            echo -e "  ✅ SwiftLint: ${GREEN}PASS${NC}"
        else
            echo -e "  ❌ SwiftLint: ${RED}$LINT_ISSUES issues${NC}"
        fi
    else
        echo -e "  ⚠️  SwiftLint: ${YELLOW}NOT INSTALLED${NC}"
    fi

    # SwiftFormat status
    if command -v swiftformat &> /dev/null; then
        if swiftformat --lint . > /dev/null 2>&1; then
            echo -e "  ✅ SwiftFormat: ${GREEN}PASS${NC}"
        else
            echo -e "  ❌ SwiftFormat: ${RED}FAIL${NC}"
        fi
    else
        echo -e "  ⚠️  SwiftFormat: ${YELLOW}NOT INSTALLED${NC}"
    fi

    # Documentation status
    if [ -f "README.md" ]; then
        echo -e "  ✅ README: ${GREEN}PRESENT${NC}"
    else
        echo -e "  ❌ README: ${RED}MISSING${NC}"
    fi

    if [ -f "QUALITY_PLAN.md" ]; then
        echo -e "  ✅ Quality Plan: ${GREEN}PRESENT${NC}"
    else
        echo -e "  ❌ Quality Plan: ${RED}MISSING${NC}"
    fi
    echo ""
}

# Function: Progress Tracking
progress_tracking() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📈 DEVELOPMENT PROGRESS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Calculate progress based on completed features/tasks
    TOTAL_FEATURES=10  # Based on QUALITY_PLAN.md requirements

    # Count completed items (simplified logic)
    COMPLETED=0

    # Check for basic project structure
    [ -d "$PROJECT_ROOT/Sources" ] && ((COMPLETED++))
    [ -d "$PROJECT_ROOT/Tests" ] && ((COMPLETED++))
    [ -f "$PROJECT_ROOT/Package.swift" ] && ((COMPLETED++))
    [ -f "$PROJECT_ROOT/README.md" ] && ((COMPLETED++))
    [ -f "$PROJECT_ROOT/QUALITY_PLAN.md" ] && ((COMPLETED++))

    # Check for CI/CD
    [ -f "$PROJECT_ROOT/.github/workflows/build-and-release.yml" ] && ((COMPLETED++))

    # Check for monitoring setup
    [ -d "$SCRIPT_DIR" ] && ((COMPLETED++))

    PROGRESS_PERCENT=$((COMPLETED * 100 / TOTAL_FEATURES))

    # Progress bar
    BAR_WIDTH=20
    FILLED=$((PROGRESS_PERCENT * BAR_WIDTH / 100))
    EMPTY=$((BAR_WIDTH - FILLED))

    printf "  Progress: ["
    printf "%${FILLED}s" | tr ' ' '█'
    printf "%${EMPTY}s" | tr ' ' '░'
    printf "] %d%% (%d/%d)\n" "$PROGRESS_PERCENT" "$COMPLETED" "$TOTAL_FEATURES"

    echo ""
    echo -e "  🎯 Next Milestones:"
    if [ $PROGRESS_PERCENT -lt 50 ]; then
        echo -e "    • Complete basic project setup"
        echo -e "    • Implement core functionality"
        echo -e "    • Set up testing framework"
    elif [ $PROGRESS_PERCENT -lt 80 ]; then
        echo -e "    • Implement monitoring systems"
        echo -e "    • Add comprehensive tests"
        echo -e "    • Configure CI/CD pipeline"
    else
        echo -e "    • Performance optimization"
        echo -e "    • Security hardening"
        echo -e "    • Production deployment"
    fi
    echo ""
}

# Function: Recent Activity
recent_activity() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📈 RECENT ACTIVITY (Last 24h)${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Find recent files
    RECENT_FILES=$(find "$PROJECT_ROOT" -type f \( -name "*.swift" -o -name "*.md" -o -name "*.yml" \) -mtime -1 | head -5)

    if [ -n "$RECENT_FILES" ]; then
        echo "$RECENT_FILES" | while read -r file; do
            MOD_TIME=$(stat -f "%Sm" -t "%H:%M" "$file" 2>/dev/null || date +%H:%M)
            REL_PATH=${file#$PROJECT_ROOT/}
            echo -e "  📄 $MOD_TIME - $REL_PATH"
        done
    else
        echo -e "  ${YELLOW}No recent activity${NC}"
    fi
    echo ""
}

# Function: Quick Actions
quick_actions() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}⚡ QUICK ACTIONS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  1. Run Quality Gates    → ${BLUE}$SCRIPT_DIR/../quality-gates/quality-gate-runner.sh${NC}"
    echo -e "  2. Performance Monitor  → ${BLUE}$SCRIPT_DIR/../metrics/performance-monitor.sh${NC}"
    echo -e "  3. Error Tracker        → ${BLUE}$SCRIPT_DIR/../alerts/error-tracker.sh${NC}"
    echo -e "  4. Generate Report      → ${BLUE}$SCRIPT_DIR/report-generator.sh${NC}"
    echo -e "  5. View Detailed Logs   → ${BLUE}find $SCRIPT_DIR/../ -name \"*.log\" -o -name \"*.json\" | head -10${NC}"
    echo ""
}

# Main dashboard display
main() {
    project_overview
    quality_gates_status
    performance_metrics
    error_alert_status
    build_test_status
    code_quality_metrics
    progress_tracking
    recent_activity
    quick_actions

    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║  Last Updated: $(date '+%Y-%m-%d %H:%M:%S')                      ║${NC}"
    echo -e "${MAGENTA}║  Refresh: Ctrl+C then re-run | Auto-refresh: watch -n 30 ./dashboard.sh ║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════════╝${NC}"
}

# Execute main function
main