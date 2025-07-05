#!/bin/bash

# Production Monitoring Setup Script
# Configures monitoring and alerting for post-launch performance tracking

set -e

# Configuration
PROJECT_NAME="StickyNotes"
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

# Setup crash reporting
setup_crash_reporting() {
    print_status "Setting up crash reporting configuration..."

    # Create crash reporting configuration
    cat > monitoring/production/crash-reporting-config.json << EOF
{
  "project": "${PROJECT_NAME}",
  "bundle_id": "${BUNDLE_ID}",
  "reporting": {
    "enabled": true,
    "endpoint": "https://api.sentry.io/v1/store/",
    "dsn": "\${SENTRY_DSN}",
    "environment": "production",
    "release": "\${RELEASE_VERSION}",
    "sample_rate": 1.0
  },
  "filters": {
    "ignore_exceptions": [
      "NSUserCancelledError",
      "CKErrorDomain"
    ],
    "ignore_files": [
      "CoreFoundation",
      "libsystem"
    ]
  },
  "integrations": {
    "auto_session_tracking": true,
    "enable_swizzling": true,
    "enable_tracing": true
  }
}
EOF

    print_success "Crash reporting configuration created"
}

# Setup performance monitoring
setup_performance_monitoring() {
    print_status "Setting up performance monitoring..."

    # Create performance monitoring configuration
    cat > monitoring/production/performance-config.json << EOF
{
  "project": "${PROJECT_NAME}",
  "monitoring": {
    "enabled": true,
    "interval_seconds": 300,
    "metrics": {
      "app_startup_time": {
        "enabled": true,
        "threshold_ms": 3000,
        "alert_on_exceed": true
      },
      "memory_usage": {
        "enabled": true,
        "threshold_mb": 100,
        "alert_on_exceed": true
      },
      "cpu_usage": {
        "enabled": true,
        "threshold_percent": 20,
        "alert_on_exceed": true
      },
      "disk_usage": {
        "enabled": true,
        "threshold_mb": 50,
        "alert_on_exceed": true
      },
      "network_requests": {
        "enabled": true,
        "track_failures": true,
        "alert_on_failure_rate": 0.05
      }
    }
  },
  "alerting": {
    "slack_webhook": "\${SLACK_WEBHOOK_URL}",
    "email_recipients": ["\${ALERT_EMAIL}"],
    "alert_levels": {
      "critical": ["app_startup_time", "memory_usage"],
      "warning": ["cpu_usage", "disk_usage"],
      "info": ["network_requests"]
    }
  }
}
EOF

    print_success "Performance monitoring configuration created"
}

# Setup analytics tracking
setup_analytics() {
    print_status "Setting up analytics configuration..."

    # Create analytics configuration
    cat > monitoring/production/analytics-config.json << EOF
{
  "project": "${PROJECT_NAME}",
  "analytics": {
    "enabled": true,
    "provider": "mixpanel",
    "api_key": "\${MIXPANEL_API_KEY}",
    "track_events": [
      "app_launch",
      "note_created",
      "note_edited",
      "note_deleted",
      "export_completed",
      "settings_changed",
      "sync_completed",
      "error_occurred"
    ],
    "user_properties": {
      "platform": "macOS",
      "app_version": "\${APP_VERSION}",
      "os_version": "\${OS_VERSION}",
      "device_type": "desktop"
    },
    "privacy": {
      "require_consent": true,
      "anonymize_ip": true,
      "data_retention_days": 365
    }
  },
  "reporting": {
    "daily_active_users": true,
    "weekly_active_users": true,
    "monthly_active_users": true,
    "feature_usage": true,
    "error_rates": true,
    "performance_metrics": true
  }
}
EOF

    print_success "Analytics configuration created"
}

# Setup deployment tracking
setup_deployment_tracking() {
    print_status "Setting up deployment tracking..."

    # Create deployment tracking configuration
    cat > monitoring/production/deployment-tracking.json << EOF
{
  "project": "${PROJECT_NAME}",
  "deployment": {
    "track_releases": true,
    "channels": ["app_store", "direct_download"],
    "version_tracking": {
      "current_version": "\${CURRENT_VERSION}",
      "previous_version": "\${PREVIOUS_VERSION}",
      "release_date": "\${RELEASE_DATE}"
    },
    "rollout_strategy": {
      "app_store": {
        "phased_rollout": true,
        "initial_percentage": 10,
        "increment_percentage": 10,
        "monitoring_days": 7
      },
      "direct_download": {
        "auto_update": true,
        "update_channel": "stable"
      }
    }
  },
  "monitoring": {
    "crash_rate_tracking": true,
    "performance_regression": true,
    "user_feedback_collection": true,
    "support_ticket_monitoring": true
  },
  "rollback_triggers": {
    "crash_rate_threshold": 0.01,
    "performance_regression_threshold": 0.15,
    "user_complaint_threshold": 50,
    "auto_rollback_enabled": false
  }
}
EOF

    print_success "Deployment tracking configuration created"
}

# Setup alerting system
setup_alerting() {
    print_status "Setting up alerting system..."

    # Create alerting configuration
    cat > monitoring/production/alerting-config.json << EOF
{
  "project": "${PROJECT_NAME}",
  "alerting": {
    "enabled": true,
    "channels": {
      "slack": {
        "enabled": true,
        "webhook_url": "\${SLACK_WEBHOOK_URL}",
        "channel": "#${PROJECT_NAME}-alerts",
        "username": "${PROJECT_NAME} Monitor"
      },
      "email": {
        "enabled": true,
        "smtp_server": "\${SMTP_SERVER}",
        "smtp_port": 587,
        "smtp_username": "\${SMTP_USERNAME}",
        "smtp_password": "\${SMTP_PASSWORD}",
        "from_address": "alerts@${PROJECT_NAME}.com",
        "recipients": ["\${ALERT_EMAIL}"]
      },
      "webhook": {
        "enabled": false,
        "url": "\${WEBHOOK_URL}",
        "headers": {
          "Authorization": "Bearer \${WEBHOOK_TOKEN}",
          "Content-Type": "application/json"
        }
      }
    },
    "alert_types": {
      "critical": {
        "crash_rate_spike": {
          "enabled": true,
          "threshold": 0.005,
          "time_window_minutes": 60,
          "cooldown_minutes": 30
        },
        "performance_regression": {
          "enabled": true,
          "threshold": 0.20,
          "time_window_hours": 24,
          "cooldown_hours": 6
        },
        "app_store_rejection": {
          "enabled": true,
          "immediate_alert": true
        }
      },
      "warning": {
        "memory_usage_high": {
          "enabled": true,
          "threshold_mb": 150,
          "time_window_minutes": 30
        },
        "slow_startup": {
          "enabled": true,
          "threshold_ms": 5000,
          "time_window_hours": 1
        },
        "sync_failures": {
          "enabled": true,
          "threshold_rate": 0.10,
          "time_window_hours": 1
        }
      },
      "info": {
        "new_version_released": {
          "enabled": true
        },
        "user_feedback_received": {
          "enabled": true,
          "batch_size": 10
        },
        "performance_improved": {
          "enabled": true,
          "threshold": 0.10
        }
      }
    },
    "escalation": {
      "enabled": true,
      "levels": [
        {
          "name": "immediate",
          "delay_minutes": 0,
          "channels": ["slack", "email"]
        },
        {
          "name": "escalation_1",
          "delay_minutes": 30,
          "channels": ["slack", "email"],
          "additional_recipients": ["\${ESCALATION_EMAIL_1}"]
        },
        {
          "name": "escalation_2",
          "delay_minutes": 120,
          "channels": ["slack", "email"],
          "additional_recipients": ["\${ESCALATION_EMAIL_2}"]
        }
      ]
    }
  }
}
EOF

    print_success "Alerting system configuration created"
}

# Setup monitoring dashboard
setup_monitoring_dashboard() {
    print_status "Setting up monitoring dashboard..."

    # Create dashboard configuration
    cat > monitoring/production/dashboard-config.json << EOF
{
  "project": "${PROJECT_NAME}",
  "dashboard": {
    "title": "${PROJECT_NAME} Production Monitoring",
    "refresh_interval_seconds": 300,
    "timezone": "UTC",
    "widgets": [
      {
        "type": "metric",
        "title": "Active Users",
        "metrics": ["daily_active_users", "weekly_active_users", "monthly_active_users"],
        "chart_type": "line",
        "time_range": "30d"
      },
      {
        "type": "metric",
        "title": "App Performance",
        "metrics": ["app_startup_time", "memory_usage", "cpu_usage"],
        "chart_type": "line",
        "time_range": "7d",
        "thresholds": {
          "app_startup_time": 3000,
          "memory_usage": 100,
          "cpu_usage": 20
        }
      },
      {
        "type": "metric",
        "title": "Error Rates",
        "metrics": ["crash_rate", "error_rate", "sync_failure_rate"],
        "chart_type": "bar",
        "time_range": "7d",
        "thresholds": {
          "crash_rate": 0.005,
          "error_rate": 0.01,
          "sync_failure_rate": 0.05
        }
      },
      {
        "type": "table",
        "title": "Recent Alerts",
        "data_source": "alerts",
        "columns": ["timestamp", "level", "message", "status"],
        "limit": 10,
        "sort_by": "timestamp",
        "sort_order": "desc"
      },
      {
        "type": "pie_chart",
        "title": "Error Distribution",
        "data_source": "errors_by_type",
        "time_range": "7d"
      },
      {
        "type": "heatmap",
        "title": "User Activity",
        "data_source": "user_activity_heatmap",
        "time_range": "24h"
      }
    ],
    "alerts_panel": {
      "enabled": true,
      "position": "top",
      "max_alerts": 5,
      "auto_dismiss_resolved": true
    },
    "export": {
      "enabled": true,
      "formats": ["pdf", "png", "csv"],
      "schedule": "daily"
    }
  }
}
EOF

    print_success "Monitoring dashboard configuration created"
}

# Create production monitoring directories
create_directories() {
    print_status "Creating production monitoring directories..."

    mkdir -p monitoring/production
    mkdir -p monitoring/production/logs
    mkdir -p monitoring/production/reports
    mkdir -p monitoring/production/backups

    print_success "Production monitoring directories created"
}

# Generate setup documentation
generate_documentation() {
    print_status "Generating setup documentation..."

    cat > monitoring/production/README.md << EOF
# Production Monitoring Setup

This directory contains the production monitoring configuration for ${PROJECT_NAME}.

## Configuration Files

### Core Monitoring
- \`crash-reporting-config.json\` - Crash reporting and error tracking
- \`performance-config.json\` - Performance monitoring and alerting
- \`analytics-config.json\` - User analytics and usage tracking
- \`deployment-tracking.json\` - Deployment and rollout monitoring
- \`alerting-config.json\` - Alert configuration and escalation
- \`dashboard-config.json\` - Monitoring dashboard configuration

## Environment Variables Required

### Crash Reporting (Sentry)
\`\`\`bash
SENTRY_DSN=https://your-sentry-dsn@sentry.io/project-id
\`\`\`

### Analytics (Mixpanel)
\`\`\`bash
MIXPANEL_API_KEY=your-mixpanel-api-key
\`\`\`

### Alerting
\`\`\`bash
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
ALERT_EMAIL=alerts@yourcompany.com
SMTP_SERVER=smtp.yourcompany.com
SMTP_USERNAME=alerts@yourcompany.com
SMTP_PASSWORD=your-smtp-password
\`\`\`

### Escalation Contacts
\`\`\`bash
ESCALATION_EMAIL_1=manager@yourcompany.com
ESCALATION_EMAIL_2=director@yourcompany.com
\`\`\`

## Deployment Instructions

1. **Set Environment Variables**: Configure all required environment variables in your deployment environment
2. **Update Placeholders**: Replace all \`\${VARIABLE}\` placeholders with actual values
3. **Test Configuration**: Run the monitoring system in staging before production
4. **Enable Monitoring**: Set monitoring enabled flags to \`true\` in all config files
5. **Verify Alerts**: Test alert delivery to ensure notifications work correctly

## Monitoring Dashboard

Access the monitoring dashboard at: \`https://your-monitoring-domain/dashboard\`

### Key Metrics to Monitor
- **Crash Rate**: Should be < 0.5%
- **App Startup Time**: Should be < 3 seconds
- **Memory Usage**: Should be < 100MB
- **Daily Active Users**: Track growth trends
- **Error Rates**: Monitor for spikes

## Alert Response Procedures

### Critical Alerts (Immediate Response)
- **Crash Rate Spike**: Investigate recent code changes, prepare rollback if needed
- **Performance Regression**: Check system resources, database performance, network issues
- **App Store Rejection**: Review rejection reason, prepare resubmission

### Warning Alerts (Within 1 Hour)
- **High Memory Usage**: Monitor for memory leaks, check for large data operations
- **Slow Startup**: Check for blocking operations, optimize initialization code
- **Sync Failures**: Verify iCloud service status, check authentication issues

### Info Alerts (Daily Review)
- **New Version Released**: Verify deployment success, monitor initial metrics
- **User Feedback**: Review feedback for patterns, plan improvements
- **Performance Improvements**: Document successful optimizations

## Maintenance

### Daily Tasks
- Review alert summary
- Check dashboard for anomalies
- Monitor user feedback

### Weekly Tasks
- Review performance trends
- Analyze error patterns
- Update alert thresholds if needed

### Monthly Tasks
- Review monitoring configuration
- Update contact information
- Audit monitoring data retention

## Troubleshooting

### Common Issues

#### Alerts Not Sending
1. Check webhook URLs are correct
2. Verify API keys are valid
3. Check network connectivity
4. Review alert thresholds

#### Metrics Not Updating
1. Verify monitoring service is running
2. Check data collection endpoints
3. Review metric collection configuration
4. Check for data processing errors

#### Dashboard Not Loading
1. Check dashboard service status
2. Verify authentication credentials
3. Review browser console for errors
4. Check network connectivity

## Support

For monitoring system issues:
1. Check this documentation
2. Review monitoring service logs
3. Contact the development team
4. Escalate to infrastructure team if needed

---
*Generated by setup-production-monitoring.sh*
EOF

    print_success "Setup documentation generated"
}

# Main setup function
main() {
    print_status "Starting production monitoring setup for ${PROJECT_NAME}..."

    create_directories
    setup_crash_reporting
    setup_performance_monitoring
    setup_analytics
    setup_deployment_tracking
    setup_alerting
    setup_monitoring_dashboard
    generate_documentation

    print_success "Production monitoring setup completed!"
    print_status "Review the generated configuration files in monitoring/production/"
    print_status "See monitoring/production/README.md for setup instructions"
}

# Run main setup
main "$@"