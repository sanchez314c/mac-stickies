#!/bin/bash

# 🎯 Master Monitoring Orchestrator for StickyNotes
# Coordinates all monitoring systems and provides automated quality assurance

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
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configuration
MONITOR_INTERVAL=${MONITOR_INTERVAL:-300}  # 5 minutes default
REPORT_INTERVAL=${REPORT_INTERVAL:-3600}   # 1 hour default
ALERT_THRESHOLD=${ALERT_THRESHOLD:-1}      # Alert on any critical issues

# State tracking
LAST_REPORT_TIME=0
LAST_CHECK_TIME=0
CRITICAL_ISSUES=0
WARNING_ISSUES=0

echo -e "${MAGENTA}🎯 STICKYNOTES MASTER MONITOR${NC}"
echo -e "${MAGENTA}==============================${NC}"
echo "Starting comprehensive monitoring system..."
echo "Monitor Interval: ${MONITOR_INTERVAL}s"
echo "Report Interval: ${REPORT_INTERVAL}s"
echo "Alert Threshold: ${ALERT_THRESHOLD} critical issues"
echo ""

# Function: Initialize monitoring environment
initialize_monitoring() {
    echo -e "${CYAN}🔧 INITIALIZING MONITORING ENVIRONMENT${NC}"

    # Create all necessary directories
    mkdir -p "$SCRIPT_DIR"/{quality-gates,metrics,alerts/{logs,alerts},dashboards,reports}

    # Check for required scripts
    REQUIRED_SCRIPTS=(
        "quality-gates/quality-gate-runner.sh"
        "metrics/performance-monitor.sh"
        "alerts/error-tracker.sh"
        "dashboards/development-dashboard.sh"
        "dashboards/report-generator.sh"
    )

    MISSING_SCRIPTS=()
    for script in "${REQUIRED_SCRIPTS[@]}"; do
        if [ ! -f "$SCRIPT_DIR/$script" ]; then
            MISSING_SCRIPTS+=("$script")
        fi
    done

    if [ ${#MISSING_SCRIPTS[@]} -gt 0 ]; then
        echo -e "  ❌ ${RED}Missing required scripts:${NC}"
        for script in "${MISSING_SCRIPTS[@]}"; do
            echo -e "    • $script"
        done
        echo -e "  ${YELLOW}Please ensure all monitoring scripts are present${NC}"
        exit 1
    else
        echo -e "  ✅ ${GREEN}All monitoring scripts present${NC}"
    fi

    # Make scripts executable
    find "$SCRIPT_DIR" -name "*.sh" -type f -exec chmod +x {} \;

    echo -e "  ✅ ${GREEN}Monitoring environment initialized${NC}"
    echo ""
}

# Function: Run quality gates
run_quality_gates() {
    echo -e "${YELLOW}🚪 RUNNING QUALITY GATES${NC}"

    QUALITY_SCRIPT="$SCRIPT_DIR/quality-gates/quality-gate-runner.sh"

    if [ -x "$QUALITY_SCRIPT" ]; then
        QUALITY_OUTPUT=$("$QUALITY_SCRIPT" 2>&1)
        QUALITY_EXIT=$?

        if [ $QUALITY_EXIT -eq 0 ]; then
            echo -e "  ✅ ${GREEN}Quality gates PASSED${NC}"
            return 0
        else
            echo -e "  ❌ ${RED}Quality gates FAILED${NC}"
            echo "$QUALITY_OUTPUT" | grep -E "❌|⚠️" | head -3 | sed 's/^/    /'
            return 1
        fi
    else
        echo -e "  ❌ ${RED}Quality gate script not executable${NC}"
        return 1
    fi
}

# Function: Run performance monitoring
run_performance_monitoring() {
    echo -e "${YELLOW}⚡ RUNNING PERFORMANCE MONITORING${NC}"

    PERF_SCRIPT="$SCRIPT_DIR/metrics/performance-monitor.sh"

    if [ -x "$PERF_SCRIPT" ]; then
        "$PERF_SCRIPT" > /dev/null 2>&1
        PERF_EXIT=$?

        if [ $PERF_EXIT -eq 0 ]; then
            echo -e "  ✅ ${GREEN}Performance monitoring completed${NC}"
            return 0
        else
            echo -e "  ❌ ${RED}Performance monitoring failed${NC}"
            return 1
        fi
    else
        echo -e "  ❌ ${RED}Performance script not executable${NC}"
        return 1
    fi
}

# Function: Run error tracking
run_error_tracking() {
    echo -e "${YELLOW}🚨 RUNNING ERROR TRACKING${NC}"

    ERROR_SCRIPT="$SCRIPT_DIR/alerts/error-tracker.sh"

    if [ -x "$ERROR_SCRIPT" ]; then
        ERROR_OUTPUT=$("$ERROR_SCRIPT" 2>&1)
        ERROR_EXIT=$?

        # Parse critical issues from output
        NEW_CRITICAL=$(echo "$ERROR_OUTPUT" | grep -c "CRITICAL" || echo "0")
        NEW_WARNING=$(echo "$ERROR_OUTPUT" | grep -c "WARNING" || echo "0")

        CRITICAL_ISSUES=$((CRITICAL_ISSUES + NEW_CRITICAL))
        WARNING_ISSUES=$((WARNING_ISSUES + NEW_WARNING))

        if [ $ERROR_EXIT -eq 0 ]; then
            echo -e "  ✅ ${GREEN}Error tracking completed${NC}"
            echo -e "    📊 Issues found: ${RED}$NEW_CRITICAL critical${NC}, ${YELLOW}$NEW_WARNING warnings${NC}"
            return 0
        else
            echo -e "  ❌ ${RED}Error tracking failed${NC}"
            return 1
        fi
    else
        echo -e "  ❌ ${RED}Error tracking script not executable${NC}"
        return 1
    fi
}

# Function: Check alert thresholds
check_alert_thresholds() {
    echo -e "${YELLOW}📊 CHECKING ALERT THRESHOLDS${NC}"

    if [ $CRITICAL_ISSUES -ge $ALERT_THRESHOLD ]; then
        echo -e "  🚨 ${RED}ALERT: $CRITICAL_ISSUES critical issues detected!${NC}"
        send_alert "CRITICAL" "$CRITICAL_ISSUES critical issues require immediate attention"
        return 1
    elif [ $WARNING_ISSUES -gt 0 ]; then
        echo -e "  ⚠️  ${YELLOW}WARNING: $WARNING_ISSUES issues detected${NC}"
        return 0
    else
        echo -e "  ✅ ${GREEN}No alerts triggered${NC}"
        return 0
    fi
}

# Function: Send alerts
send_alert() {
    local severity="$1"
    local message="$2"

    # Create alert file
    ALERT_FILE="$SCRIPT_DIR/alerts/$(date +%Y%m%d_%H%M%S)_alert.txt"

    cat > "$ALERT_FILE" << EOF
STICKYNOTES MONITORING ALERT
============================
Timestamp: $(date)
Severity: $severity
Message: $message

Critical Issues: $CRITICAL_ISSUES
Warning Issues: $WARNING_ISSUES

Recent Logs:
$(find "$SCRIPT_DIR/alerts/logs" -name "*.txt" -mmin -5 | head -3 | xargs tail -5 2>/dev/null || echo "No recent logs")

Action Required: Review monitoring dashboard and address issues immediately.
EOF

    echo -e "  📧 ${BLUE}Alert sent: $ALERT_FILE${NC}"

    # In a real implementation, this could send email, Slack notifications, etc.
}

# Function: Generate periodic reports
generate_reports() {
    local current_time=$(date +%s)

    if [ $((current_time - LAST_REPORT_TIME)) -ge $REPORT_INTERVAL ]; then
        echo -e "${YELLOW}📊 GENERATING PERIODIC REPORTS${NC}"

        REPORT_SCRIPT="$SCRIPT_DIR/dashboards/report-generator.sh"

        if [ -x "$REPORT_SCRIPT" ]; then
            "$REPORT_SCRIPT" > /dev/null 2>&1
            REPORT_EXIT=$?

            if [ $REPORT_EXIT -eq 0 ]; then
                echo -e "  ✅ ${GREEN}Reports generated successfully${NC}"
                LAST_REPORT_TIME=$current_time
                return 0
            else
                echo -e "  ❌ ${RED}Report generation failed${NC}"
                return 1
            fi
        else
            echo -e "  ❌ ${RED}Report generator not executable${NC}"
            return 1
        fi
    else
        local next_report=$((REPORT_INTERVAL - (current_time - LAST_REPORT_TIME)))
        echo -e "  ⏰ ${BLUE}Next report in $next_report seconds${NC}"
        return 0
    fi
}

# Function: Display monitoring dashboard
display_dashboard() {
    echo -e "${CYAN}📊 MONITORING DASHBOARD${NC}"
    echo -e "${CYAN}======================${NC}"

    # Show current status
    echo -e "Status: ${GREEN}ACTIVE${NC}"
    echo -e "Uptime: $(ps -p $$ -o etime= | tr -d ' ')"
    echo -e "Last Check: $(date -r $LAST_CHECK_TIME '+%H:%M:%S' 2>/dev/null || echo 'Never')"
    echo -e "Critical Issues: ${RED}$CRITICAL_ISSUES${NC}"
    echo -e "Warning Issues: ${YELLOW}$WARNING_ISSUES${NC}"
    echo ""

    # Show recent activity
    echo -e "Recent Activity:"
    find "$SCRIPT_DIR" -name "*.log" -o -name "*.json" -type f -mmin -5 | head -3 | while read -r file; do
        echo -e "  📄 $(basename "$file") ($(date -r "$file" '+%H:%M:%S'))"
    done
    echo ""
}

# Function: Cleanup old files
cleanup_old_files() {
    echo -e "${YELLOW}🧹 CLEANING UP OLD FILES${NC}"

    # Remove files older than 30 days
    find "$SCRIPT_DIR" -type f \( -name "*.log" -o -name "*.json" -o -name "*.txt" \) -mtime +30 -delete 2>/dev/null || true

    # Remove empty directories
    find "$SCRIPT_DIR" -type d -empty -delete 2>/dev/null || true

    echo -e "  ✅ ${GREEN}Cleanup completed${NC}"
}

# Function: Main monitoring loop
monitoring_loop() {
    echo -e "${GREEN}▶️  Starting monitoring loop...${NC}"
    echo -e "${BLUE}Press Ctrl+C to stop monitoring${NC}"
    echo ""

    # Trap SIGINT for clean shutdown
    trap 'echo -e "\n${YELLOW}⏹️  Monitoring stopped by user${NC}"; exit 0' INT

    while true; do
        local loop_start=$(date +%s)

        # Display dashboard
        display_dashboard

        # Run all monitoring checks
        echo -e "${CYAN}🔄 RUNNING MONITORING CHECKS${NC}"

        # Quality gates
        run_quality_gates
        quality_result=$?

        # Performance monitoring
        run_performance_monitoring
        perf_result=$?

        # Error tracking
        run_error_tracking
        error_result=$?

        # Check thresholds
        check_alert_thresholds
        alert_result=$?

        # Generate reports if needed
        generate_reports
        report_result=$?

        # Update last check time
        LAST_CHECK_TIME=$(date +%s)

        # Calculate next run time
        local loop_end=$(date +%s)
        local execution_time=$((loop_end - loop_start))
        local sleep_time=$((MONITOR_INTERVAL - execution_time))

        if [ $sleep_time -gt 0 ]; then
            echo -e "${BLUE}⏰ Next check in $sleep_time seconds...${NC}"
            sleep $sleep_time
        else
            echo -e "${YELLOW}⚠️  Monitoring cycle took longer than interval, running next check immediately${NC}"
        fi

        # Cleanup every 10 cycles (approximately every 50 minutes with 5min intervals)
        if [ $(( (loop_end / MONITOR_INTERVAL) % 10 )) -eq 0 ]; then
            cleanup_old_files
        fi

        echo ""
    done
}

# Function: Show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -i, --interval SECONDS    Monitoring interval (default: 300)"
    echo "  -r, --report-interval SEC Report generation interval (default: 3600)"
    echo "  -t, --threshold NUM       Critical alert threshold (default: 1)"
    echo "  -s, --single-run          Run monitoring once and exit"
    echo "  -h, --help               Show this help"
    echo ""
    echo "Environment Variables:"
    echo "  MONITOR_INTERVAL         Same as --interval"
    echo "  REPORT_INTERVAL          Same as --report-interval"
    echo "  ALERT_THRESHOLD          Same as --threshold"
}

# Parse command line arguments
SINGLE_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--interval)
            MONITOR_INTERVAL="$2"
            shift 2
            ;;
        -r|--report-interval)
            REPORT_INTERVAL="$2"
            shift 2
            ;;
        -t|--threshold)
            ALERT_THRESHOLD="$2"
            shift 2
            ;;
        -s|--single-run)
            SINGLE_RUN=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
done

# Initialize monitoring
initialize_monitoring

# Run single check or continuous monitoring
if [ "$SINGLE_RUN" = true ]; then
    echo -e "${YELLOW}🔍 RUNNING SINGLE MONITORING CHECK${NC}"
    echo ""

    # Run all checks once
    run_quality_gates
    run_performance_monitoring
    run_error_tracking
    check_alert_thresholds
    generate_reports

    echo ""
    echo -e "${GREEN}✅ Single monitoring check completed${NC}"
else
    # Start continuous monitoring
    monitoring_loop
fi