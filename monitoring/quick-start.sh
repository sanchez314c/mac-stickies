#!/bin/bash

# 🚀 Quick Start Guide for StickyNotes Monitoring System
# Get up and running with comprehensive quality assurance in minutes

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${MAGENTA}🚀 STICKYNOTES MONITORING QUICK START${NC}"
echo -e "${MAGENTA}=========================================${NC}"
echo ""
echo -e "Setting up comprehensive monitoring and quality assurance..."
echo ""

# Function: Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}🔍 CHECKING PREREQUISITES${NC}"

    local missing_tools=()

    # Check for required tools
    if ! command -v swift &> /dev/null; then
        missing_tools+=("Swift (xcode-select --install)")
    fi

    if ! command -v git &> /dev/null; then
        missing_tools+=("Git")
    fi

    # Optional but recommended tools
    if ! command -v swiftlint &> /dev/null; then
        echo -e "  ⚠️  ${YELLOW}SwiftLint not found - install with: brew install swiftlint${NC}"
    fi

    if ! command -v swiftformat &> /dev/null; then
        echo -e "  ⚠️  ${YELLOW}SwiftFormat not found - install with: brew install swiftformat${NC}"
    fi

    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo -e "  ❌ ${RED}Missing required tools:${NC}"
        for tool in "${missing_tools[@]}"; do
            echo -e "    • $tool"
        done
        exit 1
    else
        echo -e "  ✅ ${GREEN}All prerequisites met${NC}"
    fi
    echo ""
}

# Function: Initialize monitoring environment
initialize_environment() {
    echo -e "${YELLOW}🔧 INITIALIZING MONITORING ENVIRONMENT${NC}"

    # Create all necessary directories
    mkdir -p "$SCRIPT_DIR"/{quality-gates,metrics,alerts/{logs,alerts},dashboards,reports}

    # Make all scripts executable
    find "$SCRIPT_DIR" -name "*.sh" -type f -exec chmod +x {} \;

    # Create initial configuration
    cat > "$SCRIPT_DIR/config.sh" << 'EOF'
#!/bin/bash
# Monitoring System Configuration

# Monitoring intervals (seconds)
MONITOR_INTERVAL=${MONITOR_INTERVAL:-300}    # 5 minutes
REPORT_INTERVAL=${REPORT_INTERVAL:-3600}     # 1 hour
ALERT_THRESHOLD=${ALERT_THRESHOLD:-1}        # Alert on any critical issue

# Quality thresholds
MIN_CODE_COVERAGE=80          # Minimum code coverage percentage
MAX_STARTUP_TIME=3.0         # Maximum startup time in seconds
MAX_MEMORY_USAGE=100         # Maximum memory usage in MB
MAX_CPU_USAGE=20            # Maximum CPU usage percentage

# File paths
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="$PROJECT_ROOT/monitoring"
METRICS_DIR="$SCRIPT_DIR/metrics"
ALERTS_DIR="$SCRIPT_DIR/alerts"
REPORTS_DIR="$SCRIPT_DIR/reports"
LOGS_DIR="$ALERTS_DIR/logs"
EOF

    chmod +x "$SCRIPT_DIR/config.sh"

    echo -e "  ✅ ${GREEN}Monitoring environment initialized${NC}"
    echo -e "  📁 Created directories and configuration${NC}"
    echo ""
}

# Function: Run initial quality assessment
run_initial_assessment() {
    echo -e "${YELLOW}📊 RUNNING INITIAL QUALITY ASSESSMENT${NC}"

    # Run quality gates
    echo "  Running quality gates..."
    if "$SCRIPT_DIR/quality-gates/quality-gate-runner.sh" > /dev/null 2>&1; then
        echo -e "  ✅ ${GREEN}Quality gates: PASSED${NC}"
    else
        echo -e "  ⚠️  ${YELLOW}Quality gates: ISSUES FOUND${NC}"
        echo -e "    Run './monitoring/quality-gates/quality-gate-runner.sh' for details"
    fi

    # Run performance monitoring
    echo "  Running performance assessment..."
    if "$SCRIPT_DIR/metrics/performance-monitor.sh" > /dev/null 2>&1; then
        echo -e "  ✅ ${GREEN}Performance monitoring: COMPLETED${NC}"
    else
        echo -e "  ⚠️  ${YELLOW}Performance monitoring: ISSUES${NC}"
    fi

    # Run error tracking
    echo "  Running error assessment..."
    if "$SCRIPT_DIR/alerts/error-tracker.sh" > /dev/null 2>&1; then
        echo -e "  ✅ ${GREEN}Error tracking: COMPLETED${NC}"
    else
        echo -e "  ⚠️  ${YELLOW}Error tracking: ISSUES FOUND${NC}"
    fi

    echo ""
}

# Function: Generate initial reports
generate_initial_reports() {
    echo -e "${YELLOW}📋 GENERATING INITIAL REPORTS${NC}"

    # Generate comprehensive reports
    if "$SCRIPT_DIR/dashboards/report-generator.sh" > /dev/null 2>&1; then
        echo -e "  ✅ ${GREEN}Reports generated successfully${NC}"
    else
        echo -e "  ❌ ${RED}Report generation failed${NC}"
    fi

    echo ""
}

# Function: Display quick start menu
display_quick_start_menu() {
    echo -e "${CYAN}🎯 QUICK START MENU${NC}"
    echo -e "${CYAN}==================${NC}"
    echo ""
    echo -e "Your monitoring system is ready! Here are the key commands:"
    echo ""
    echo -e "${GREEN}📊 View Development Dashboard${NC}"
    echo -e "  ./monitoring/dashboards/development-dashboard.sh"
    echo ""
    echo -e "${GREEN}🚪 Run Quality Gates${NC}"
    echo -e "  ./monitoring/quality-gates/quality-gate-runner.sh"
    echo ""
    echo -e "${GREEN}⚡ Check Performance${NC}"
    echo -e "  ./monitoring/metrics/performance-monitor.sh"
    echo ""
    echo -e "${GREEN}🚨 Monitor Errors${NC}"
    echo -e "  ./monitoring/alerts/error-tracker.sh"
    echo ""
    echo -e "${GREEN}📋 Generate Reports${NC}"
    echo -e "  ./monitoring/dashboards/report-generator.sh"
    echo ""
    echo -e "${GREEN}🎮 Start Continuous Monitoring${NC}"
    echo -e "  ./monitoring/master-monitor.sh"
    echo ""
    echo -e "${GREEN}📖 View Documentation${NC}"
    echo -e "  cat monitoring/README.md"
    echo ""
}

# Function: Setup development hooks (optional)
setup_development_hooks() {
    echo -e "${YELLOW}🔗 OPTIONAL: DEVELOPMENT HOOKS${NC}"

    read -p "Would you like to set up pre-commit quality gates? (y/N): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Create pre-commit hook
        mkdir -p "$PROJECT_ROOT/.git/hooks"

        cat > "$PROJECT_ROOT/.git/hooks/pre-commit" << 'EOF'
#!/bin/bash
# Pre-commit quality gate hook

SCRIPT_DIR="monitoring"
QUALITY_SCRIPT="$SCRIPT_DIR/quality-gates/quality-gate-runner.sh"

if [ -x "$QUALITY_SCRIPT" ]; then
    echo "Running quality gates..."
    if ! "$QUALITY_SCRIPT" > /dev/null 2>&1; then
        echo "❌ Quality gates failed. Please fix issues before committing."
        echo "Run '$QUALITY_SCRIPT' for details."
        exit 1
    fi
    echo "✅ Quality gates passed!"
else
    echo "⚠️  Quality gate script not found. Skipping checks."
fi
EOF

        chmod +x "$PROJECT_ROOT/.git/hooks/pre-commit"
        echo -e "  ✅ ${GREEN}Pre-commit hooks installed${NC}"
    else
        echo -e "  ⏭️  ${BLUE}Skipping development hooks${NC}"
    fi

    echo ""
}

# Function: Display next steps
display_next_steps() {
    echo -e "${MAGENTA}🎉 SETUP COMPLETE!${NC}"
    echo -e "${MAGENTA}==================${NC}"
    echo ""
    echo -e "Your StickyNotes monitoring system is now active with:"
    echo ""
    echo -e "  ✅ Automated quality gates"
    echo -e "  ✅ Performance monitoring"
    echo -e "  ✅ Error tracking & alerting"
    echo -e "  ✅ Real-time dashboards"
    echo -e "  ✅ Comprehensive reporting"
    echo -e "  ✅ CI/CD integration"
    echo ""
    echo -e "${YELLOW}📈 Daily Workflow:${NC}"
    echo -e "  1. Start your day: ${GREEN}./monitoring/dashboards/development-dashboard.sh${NC}"
    echo -e "  2. Before commits: ${GREEN}./monitoring/quality-gates/quality-gate-runner.sh${NC}"
    echo -e "  3. Monitor progress: ${GREEN}./monitoring/master-monitor.sh${NC} (background)"
    echo ""
    echo -e "${BLUE}📚 Learn More:${NC}"
    echo -e "  • Documentation: ${GREEN}monitoring/README.md${NC}"
    echo -e "  • Quality Standards: ${GREEN}QUALITY_PLAN.md${NC}"
    echo -e "  • Support: Check monitoring logs in ${GREEN}monitoring/alerts/logs/${NC}"
    echo ""
    echo -e "${CYAN}🚀 Happy monitoring!${NC}"
}

# Main execution
main() {
    check_prerequisites
    initialize_environment
    run_initial_assessment
    generate_initial_reports
    setup_development_hooks
    display_quick_start_menu
    display_next_steps
}

# Run main function
main