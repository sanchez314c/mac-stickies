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
