# Monitoring Guide

Comprehensive monitoring setup and procedures for StickyNotes.

## 📊 Monitoring Overview

### Monitoring Objectives
- **Proactive Issue Detection**: Identify problems before users are affected
- **Performance Tracking**: Monitor system performance and user experience
- **Security Monitoring**: Detect security threats and anomalies
- **Business Metrics**: Track usage patterns and user engagement
- **Compliance Monitoring**: Ensure regulatory compliance

### Monitoring Stack
```
┌─────────────────────────────────────────────────────────────┐
│                    Monitoring Stack                         │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │ Application │ │   System   │ │   Business  │           │
│  │   Metrics   │ │   Metrics  │ │   Metrics   │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │   Logs     │ │   Alerts    │ │ Dashboards  │           │
│  │             │ │             │ │             │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
└─────────────────────────────────────────────────────────────┘
```

## 🔧 Application Monitoring

### Performance Metrics

#### Key Performance Indicators (KPIs)
```swift
struct PerformanceMetrics {
    // Application startup
    let coldStartTime: TimeInterval
    let warmStartTime: TimeInterval

    // Memory usage
    let memoryUsage: UInt64
    let peakMemoryUsage: UInt64

    // CPU usage
    let cpuUsage: Double
    let peakCpuUsage: Double

    // User interactions
    let averageResponseTime: TimeInterval
    let uiResponsiveness: Double // FPS

    // Data operations
    let searchResponseTime: TimeInterval
    let syncDuration: TimeInterval
}
```

#### Performance Monitoring Implementation
```swift
class PerformanceMonitor {
    static let shared = PerformanceMonitor()

    private var metrics: [String: Metric] = [:]
    private let queue = DispatchQueue(label: "performance.monitor")

    func startMonitoring() {
        // Monitor startup time
        monitorStartupTime()

        // Monitor memory usage
        monitorMemoryUsage()

        // Monitor CPU usage
        monitorCpuUsage()

        // Monitor user interactions
        monitorUserInteractions()
    }

    private func monitorStartupTime() {
        let startTime = CFAbsoluteTimeGetCurrent()

        NotificationCenter.default.addObserver(
            forName: NSApplication.didFinishLaunchingNotification,
            object: nil,
            queue: nil
        ) { _ in
            let endTime = CFAbsoluteTimeGetCurrent()
            let startupTime = endTime - startTime

            self.recordMetric("app.startup_time", value: startupTime, unit: "seconds")
        }
    }

    private func monitorMemoryUsage() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            var info = mach_task_basic_info()
            var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

            let kerr = withUnsafeMutablePointer(to: &info) { infoPtr in
                infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                    task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), intPtr, &count)
                }
            }

            if kerr == KERN_SUCCESS {
                let memoryUsage = Double(info.resident_size) / 1024 / 1024 // MB
                self.recordMetric("app.memory_usage", value: memoryUsage, unit: "MB")
            }
        }
    }

    private func monitorCpuUsage() {
        // CPU monitoring implementation
        // This would typically use host_processor_info or similar
    }

    private func monitorUserInteractions() {
        // Monitor UI responsiveness
        // Track user action response times
    }

    func recordMetric(_ name: String, value: Double, unit: String = "") {
        queue.async {
            let metric = self.metrics[name, default: Metric(name: name, unit: unit)]
            metric.addSample(value)
            self.metrics[name] = metric

            // Send to monitoring service
            self.sendToMonitoringService(name: name, value: value, unit: unit)
        }
    }

    private func sendToMonitoringService(name: String, value: Double, unit: String) {
        // Implementation depends on monitoring service (DataDog, New Relic, etc.)
        print("[\(name)]: \(value) \(unit)")
    }
}

class Metric {
    let name: String
    let unit: String
    var samples: [Double] = []
    var maxSamples = 1000

    init(name: String, unit: String) {
        self.name = name
        self.unit = unit
    }

    func addSample(_ value: Double) {
        samples.append(value)
        if samples.count > maxSamples {
            samples.removeFirst()
        }
    }

    var average: Double {
        samples.isEmpty ? 0 : samples.reduce(0, +) / Double(samples.count)
    }

    var latest: Double? {
        samples.last
    }
}
```

### Error Tracking

#### Error Monitoring Setup
```swift
class ErrorTracker {
    static let shared = ErrorTracker()

    private var errors: [ErrorEvent] = []
    private let maxErrors = 1000

    func trackError(_ error: Error, context: [String: Any] = [:]) {
        let event = ErrorEvent(
            error: error,
            context: context,
            timestamp: Date(),
            userId: getCurrentUserId(),
            appVersion: getAppVersion(),
            osVersion: getOSVersion()
        )

        errors.append(event)
        if errors.count > maxErrors {
            errors.removeFirst()
        }

        // Send to error tracking service
        sendToErrorService(event)

        // Log locally
        logError(event)
    }

    private func sendToErrorService(_ event: ErrorEvent) {
        // Implementation depends on error tracking service
        // (Sentry, Crashlytics, Rollbar, etc.)
    }

    private func logError(_ event: ErrorEvent) {
        print("🚨 Error: \(event.error.localizedDescription)")
        print("Context: \(event.context)")
        print("Timestamp: \(event.timestamp)")
    }
}

struct ErrorEvent {
    let error: Error
    let context: [String: Any]
    let timestamp: Date
    let userId: String?
    let appVersion: String
    let osVersion: String
}
```

#### Crash Reporting
```swift
class CrashReporter {
    static let shared = CrashReporter()

    func setup() {
        // Setup crash reporting
        NSSetUncaughtExceptionHandler { exception in
            CrashReporter.shared.handleUncaughtException(exception)
        }

        signal(SIGABRT) { _ in
            CrashReporter.shared.handleSignal("SIGABRT")
        }

        signal(SIGSEGV) { _ in
            CrashReporter.shared.handleSignal("SIGSEGV")
        }
    }

    private func handleUncaughtException(_ exception: NSException) {
        let crashReport = CrashReport(
            type: .exception,
            name: exception.name.rawValue,
            reason: exception.reason ?? "Unknown",
            stackTrace: exception.callStackSymbols,
            timestamp: Date()
        )

        saveCrashReport(crashReport)
        sendCrashReport(crashReport)
    }

    private func handleSignal(_ signal: String) {
        let crashReport = CrashReport(
            type: .signal,
            name: signal,
            reason: "Signal received",
            stackTrace: Thread.callStackSymbols,
            timestamp: Date()
        )

        saveCrashReport(crashReport)
        sendCrashReport(crashReport)
    }

    private func saveCrashReport(_ report: CrashReport) {
        let crashDir = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("Crashes")

        try? FileManager.default.createDirectory(at: crashDir, withIntermediateDirectories: true)

        let crashFile = crashDir.appendingPathComponent("\(report.timestamp.timeIntervalSince1970).crash")
        let data = try? JSONEncoder().encode(report)
        try? data?.write(to: crashFile)
    }

    private func sendCrashReport(_ report: CrashReport) {
        // Send to crash reporting service
    }
}

struct CrashReport: Codable {
    let type: CrashType
    let name: String
    let reason: String
    let stackTrace: [String]
    let timestamp: Date
    let appVersion: String = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    let osVersion: String = ProcessInfo.processInfo.operatingSystemVersionString
}

enum CrashType: String, Codable {
    case exception
    case signal
    case other
}
```

## 🖥️ System Monitoring

### macOS System Metrics

#### System Resource Monitoring
```bash
#!/bin/bash
# system-monitor.sh

while true; do
    # CPU Usage
    CPU_USAGE=$(ps aux | awk 'NR>1 {cpu+=$3} END {print cpu}')

    # Memory Usage
    MEM_INFO=$(vm_stat | awk '/Pages free/ {free=$3} /Pages active/ {active=$3} /Pages wired/ {wired=$3} END {total=free+active+wired; print active*4096/1024/1024 "," wired*4096/1024/1024}')

    # Disk Usage
    DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')

    # Network Usage
    NET_USAGE=$(netstat -ib | awk '/en0/ {print $7 "," $10}')

    echo "$(date +%s),$CPU_USAGE,$MEM_INFO,$DISK_USAGE,$NET_USAGE" >> system_metrics.csv

    sleep 60
done
```

#### System Health Checks
```swift
class SystemMonitor {
    static let shared = SystemMonitor()

    func performHealthCheck() -> SystemHealth {
        let cpuUsage = getCpuUsage()
        let memoryUsage = getMemoryUsage()
        let diskSpace = getDiskSpace()
        let networkStatus = checkNetworkConnectivity()

        return SystemHealth(
            cpuUsage: cpuUsage,
            memoryUsage: memoryUsage,
            diskSpace: diskSpace,
            networkStatus: networkStatus,
            timestamp: Date()
        )
    }

    private func getCpuUsage() -> Double {
        // Implementation to get CPU usage
        return 0.0 // Placeholder
    }

    private func getMemoryUsage() -> MemoryInfo {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), intPtr, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return MemoryInfo(
                used: Int(info.resident_size),
                available: Int(ProcessInfo.processInfo.physicalMemory - UInt64(info.resident_size))
            )
        }

        return MemoryInfo(used: 0, available: 0)
    }

    private func getDiskSpace() -> DiskInfo {
        let fileManager = FileManager.default
        let homeUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let homePath = homeUrl.path

        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: homePath)
            let totalSpace = attributes[.systemSize] as? Int64 ?? 0
            let freeSpace = attributes[.systemFreeSize] as? Int64 ?? 0

            return DiskInfo(total: totalSpace, free: freeSpace)
        } catch {
            return DiskInfo(total: 0, free: 0)
        }
    }

    private func checkNetworkConnectivity() -> Bool {
        // Simple network check
        let reachability = SCNetworkReachabilityCreateWithName(nil, "apple.com")
        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(reachability!, &flags)
        return flags.contains(.reachable)
    }
}

struct SystemHealth {
    let cpuUsage: Double
    let memoryUsage: MemoryInfo
    let diskSpace: DiskInfo
    let networkStatus: Bool
    let timestamp: Date
}

struct MemoryInfo {
    let used: Int
    let available: Int
}

struct DiskInfo {
    let total: Int64
    let free: Int64
}
```

## 📈 Business Metrics

### User Engagement Metrics

#### Usage Analytics
```swift
class AnalyticsTracker {
    static let shared = AnalyticsTracker()

    private var events: [AnalyticsEvent] = []
    private let maxEvents = 10000

    func trackEvent(_ name: String, parameters: [String: Any] = [:]) {
        let event = AnalyticsEvent(
            name: name,
            parameters: parameters,
            timestamp: Date(),
            userId: getUserId(),
            sessionId: getSessionId()
        )

        events.append(event)
        if events.count > maxEvents {
            events.removeFirst()
        }

        // Send to analytics service
        sendToAnalyticsService(event)
    }

    func trackScreenView(_ screenName: String) {
        trackEvent("screen_view", parameters: ["screen_name": screenName])
    }

    func trackUserAction(_ action: String, context: [String: Any] = [:]) {
        trackEvent("user_action", parameters: ["action": action].merging(context, uniquingKeysWith: { $1 }))
    }

    func trackPerformance(_ metric: String, value: Double, unit: String = "") {
        trackEvent("performance", parameters: [
            "metric": metric,
            "value": value,
            "unit": unit
        ])
    }

    private func sendToAnalyticsService(_ event: AnalyticsEvent) {
        // Implementation depends on analytics service
        // (Google Analytics, Mixpanel, Amplitude, etc.)
    }
}

struct AnalyticsEvent {
    let name: String
    let parameters: [String: Any]
    let timestamp: Date
    let userId: String?
    let sessionId: String
}
```

#### Key Business Metrics
- **Daily Active Users (DAU)**: Users who open the app each day
- **Monthly Active Users (MAU)**: Users active in the past 30 days
- **Session Duration**: Average time users spend in the app
- **Feature Usage**: Which features are most/least used
- **Conversion Rates**: Trial to paid conversion, feature adoption
- **Retention Rates**: User retention over time

### Feature Usage Tracking
```swift
extension AnalyticsTracker {
    func trackNoteCreation(color: NoteColor, hasContent: Bool) {
        trackEvent("note_created", parameters: [
            "color": color.rawValue,
            "has_content": hasContent
        ])
    }

    func trackNoteEdit(duration: TimeInterval, changes: Int) {
        trackEvent("note_edited", parameters: [
            "duration": duration,
            "changes": changes
        ])
    }

    func trackSearch(query: String, results: Int, duration: TimeInterval) {
        trackEvent("search_performed", parameters: [
            "query_length": query.count,
            "results_count": results,
            "duration": duration
        ])
    }

    func trackExport(format: ExportFormat, noteCount: Int, duration: TimeInterval) {
        trackEvent("notes_exported", parameters: [
            "format": format.rawValue,
            "note_count": noteCount,
            "duration": duration
        ])
    }

    func trackSync(success: Bool, duration: TimeInterval, noteCount: Int) {
        trackEvent("icloud_sync", parameters: [
            "success": success,
            "duration": duration,
            "note_count": noteCount
        ])
    }
}
```

## 🚨 Alerting System

### Alert Configuration

#### Alert Types
```swift
enum AlertType {
    case performance
    case error
    case security
    case business
    case system
}

enum AlertSeverity {
    case info
    case warning
    case error
    case critical
}

struct AlertRule {
    let name: String
    let type: AlertType
    let severity: AlertSeverity
    let condition: (MonitoringData) -> Bool
    let message: String
    let cooldown: TimeInterval // Minimum time between alerts
}
```

#### Alert Rules Configuration
```swift
class AlertManager {
    static let shared = AlertManager()

    private var rules: [AlertRule] = []
    private var lastAlertTimes: [String: Date] = [:]

    init() {
        setupDefaultRules()
    }

    private func setupDefaultRules() {
        // Performance alerts
        rules.append(AlertRule(
            name: "high_memory_usage",
            type: .performance,
            severity: .warning,
            condition: { $0.memoryUsage.used > 200 * 1024 * 1024 }, // 200MB
            message: "Memory usage is high",
            cooldown: 300 // 5 minutes
        ))

        rules.append(AlertRule(
            name: "slow_startup",
            type: .performance,
            severity: .error,
            condition: { $0.startupTime > 5.0 }, // 5 seconds
            message: "Application startup is slow",
            cooldown: 3600 // 1 hour
        ))

        // Error alerts
        rules.append(AlertRule(
            name: "high_error_rate",
            type: .error,
            severity: .error,
            condition: { $0.errorCount > 10 },
            message: "Error rate is high",
            cooldown: 600 // 10 minutes
        ))

        // System alerts
        rules.append(AlertRule(
            name: "low_disk_space",
            type: .system,
            severity: .critical,
            condition: { Double($0.diskSpace.free) / Double($0.diskSpace.total) < 0.1 }, // 10% free
            message: "Disk space is low",
            cooldown: 1800 // 30 minutes
        ))
    }

    func checkAlerts(data: MonitoringData) {
        for rule in rules {
            if rule.condition(data) {
                let lastAlert = lastAlertTimes[rule.name] ?? .distantPast
                let timeSinceLastAlert = Date().timeIntervalSince(lastAlert)

                if timeSinceLastAlert >= rule.cooldown {
                    triggerAlert(rule, data)
                    lastAlertTimes[rule.name] = Date()
                }
            }
        }
    }

    private func triggerAlert(_ rule: AlertRule, _ data: MonitoringData) {
        let alert = Alert(
            rule: rule,
            data: data,
            timestamp: Date()
        )

        // Send alert
        sendAlert(alert)

        // Log alert
        print("🚨 ALERT: \(rule.message)")
    }

    private func sendAlert(_ alert: Alert) {
        // Implementation depends on alerting service
        // (PagerDuty, Slack, email, etc.)
    }
}

struct Alert {
    let rule: AlertRule
    let data: MonitoringData
    let timestamp: Date
}

struct MonitoringData {
    let memoryUsage: MemoryInfo
    let startupTime: TimeInterval
    let errorCount: Int
    let diskSpace: DiskInfo
    // Add other monitoring data as needed
}
```

### Alert Channels

#### Slack Integration
```swift
class SlackAlertChannel: AlertChannel {
    let webhookURL: URL

    func sendAlert(_ alert: Alert) {
        let payload = SlackMessage(
            text: "🚨 \(alert.rule.message)",
            attachments: [
                SlackAttachment(
                    color: alert.rule.severity.color,
                    fields: [
                        SlackField(title: "Severity", value: alert.rule.severity.rawValue),
                        SlackField(title: "Type", value: alert.rule.type.rawValue),
                        SlackField(title: "Time", value: alert.timestamp.description)
                    ]
                )
            ]
        )

        sendToSlack(payload)
    }

    private func sendToSlack(_ message: SlackMessage) {
        // Send HTTP POST to Slack webhook
    }
}

struct SlackMessage: Codable {
    let text: String
    let attachments: [SlackAttachment]
}

struct SlackAttachment: Codable {
    let color: String
    let fields: [SlackField]
}

struct SlackField: Codable {
    let title: String
    let value: String
}
```

#### Email Alerts
```swift
class EmailAlertChannel: AlertChannel {
    func sendAlert(_ alert: Alert) {
        let subject = "StickyNotes Alert: \(alert.rule.message)"
        let body = """
        Alert Details:
        - Rule: \(alert.rule.name)
        - Severity: \(alert.rule.severity.rawValue)
        - Type: \(alert.rule.type.rawValue)
        - Time: \(alert.timestamp)

        Please check the monitoring dashboard for more details.
        """

        sendEmail(to: "alerts@stickynotes.app", subject: subject, body: body)
    }

    private func sendEmail(to: String, subject: String, body: String) {
        // Implementation depends on email service
    }
}
```

## 📊 Dashboards

### Monitoring Dashboard

#### Key Metrics Dashboard
```
┌─────────────────────────────────────────────────────────────┐
│                    StickyNotes Monitoring                   │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │ CPU Usage   │ │ Memory      │ │ Error Rate  │           │
│  │  5.2%       │ │  85MB       │ │  0.1%       │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │ Startup     │ │ Search      │ │ Sync Time   │           │
│  │  1.8s       │ │  45ms       │ │  2.1s       │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐   │
│  │                    Recent Alerts                     │   │
│  │  • High memory usage (2 min ago)                    │   │
│  │  • Slow search response (15 min ago)                │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

#### Business Metrics Dashboard
```
┌─────────────────────────────────────────────────────────────┐
│                 Business Metrics Dashboard                  │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │ DAU         │ │ MAU         │ │ Retention   │           │
│  │  1,245      │ │  8,932      │ │  78%        │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │ Notes       │ │ Exports     │ │ Searches    │           │
│  │  45,231     │ │  2,134      │ │  12,456     │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐   │
│  │                Feature Usage Trends                 │   │
│  │  ████ Export (↑15%) ███ Search (↑8%) ██ Sync (↓3%) │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Dashboard Implementation

#### Real-time Dashboard
```swift
class MonitoringDashboard {
    private var metrics: [String: MetricSeries] = [:]
    private var alerts: [Alert] = []
    private let updateInterval: TimeInterval = 30 // seconds

    func startDashboard() {
        Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            self.updateDashboard()
        }
    }

    private func updateDashboard() {
        // Fetch latest metrics
        let latestMetrics = fetchLatestMetrics()

        // Update display
        updateMetricsDisplay(latestMetrics)

        // Check for alerts
        checkForNewAlerts()

        // Update charts
        updateCharts()
    }

    private func fetchLatestMetrics() -> [String: Double] {
        // Fetch from monitoring service
        return [:] // Placeholder
    }

    private func updateMetricsDisplay(_ metrics: [String: Double]) {
        // Update UI with latest values
    }

    private func checkForNewAlerts() {
        // Check for new alerts and display them
    }

    private func updateCharts() {
        // Update trend charts
    }
}

struct MetricSeries {
    var values: [MetricPoint]
    var maxPoints = 100

    mutating func addPoint(_ value: Double, timestamp: Date = Date()) {
        let point = MetricPoint(value: value, timestamp: timestamp)
        values.append(point)

        if values.count > maxPoints {
            values.removeFirst()
        }
    }
}

struct MetricPoint {
    let value: Double
    let timestamp: Date
}
```

## 📋 Monitoring Checklist

### Daily Monitoring
- [ ] Check system health metrics
- [ ] Review error logs and alerts
- [ ] Verify backup status
- [ ] Check performance baselines
- [ ] Review user feedback

### Weekly Monitoring
- [ ] Analyze performance trends
- [ ] Review security scans
- [ ] Check system capacity
- [ ] Update monitoring rules
- [ ] Review alert effectiveness

### Monthly Monitoring
- [ ] Comprehensive system audit
- [ ] Business metrics review
- [ ] Compliance verification
- [ ] Stakeholder reporting
- [ ] Monitoring system updates

### Alert Response Times
- **Critical**: Respond within 15 minutes
- **High**: Respond within 1 hour
- **Medium**: Respond within 4 hours
- **Low**: Respond within 24 hours

---

*This monitoring guide ensures StickyNotes maintains high availability, performance, and user satisfaction through comprehensive monitoring and alerting.*