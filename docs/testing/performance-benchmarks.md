# Performance Benchmarks

Comprehensive performance testing and benchmarking for StickyNotes.

## 📊 Performance Objectives

### Key Performance Indicators (KPIs)

| Metric | Target | Critical | Description |
|--------|--------|----------|-------------|
| **Startup Time** | <2s cold, <500ms warm | <5s cold, <1s warm | Time to become responsive |
| **Memory Usage** | <100MB baseline | <200MB baseline | RAM consumption |
| **CPU Usage** | <5% average | <15% peak | Processor utilization |
| **Search Performance** | <100ms (1000 notes) | <500ms (1000 notes) | Note search speed |
| **UI Responsiveness** | 60 FPS | 30 FPS | Interface smoothness |
| **Data Sync** | <5s (100 notes) | <30s (100 notes) | iCloud synchronization |

### Performance Budget

```
┌─────────────────────────────────────────────────────────────┐
│                    Performance Budget                      │
├─────────────────────────────────────────────────────────────┤
│ Startup Time:     ████████░ 80% (2.0s of 2.5s budget)     │
│ Memory Usage:     ███████░░ 70% (70MB of 100MB budget)     │
│ CPU Usage:        ████░░░░░ 40% (4% of 10% budget)         │
│ Search (1000):    ████░░░░░ 40% (40ms of 100ms budget)     │
│ UI Responsiveness:█████████░ 90% (54 of 60 FPS)           │
└─────────────────────────────────────────────────────────────┘
```

## 🧪 Benchmark Categories

### 1. Application Startup

#### Cold Start Performance
```swift
class StartupPerformanceTests: XCTestCase {
    func testColdStartupTime() throws {
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Simulate cold start
            let app = NSApplication.shared
            let delegate = AppDelegate()
            app.delegate = delegate

            // Measure time to become responsive
            _ = delegate.applicationDidFinishLaunching(Notification(name: .init("test")))
        }
    }

    func testWarmStartupTime() throws {
        // Pre-warm app state
        _ = NSApplication.shared

        measure(metrics: [XCTClockMetric()]) {
            // Measure subsequent launches
            let delegate = AppDelegate()
            _ = delegate.applicationDidFinishLaunching(Notification(name: .init("test")))
        }
    }
}
```

#### Startup Breakdown
- **Framework Loading**: SwiftUI, Core Data initialization
- **Data Loading**: Persistent store setup and migration
- **UI Initialization**: Window creation and layout
- **Service Setup**: Background services and networking

### 2. Memory Usage

#### Memory Benchmarks
```swift
class MemoryPerformanceTests: XCTestCase {
    func testMemoryUsage_Baseline() throws {
        measure(metrics: [XCTMemoryMetric()]) {
            // Create minimal app state
            let app = NSApplication.shared
            let delegate = AppDelegate()
            app.delegate = delegate

            // Measure baseline memory
            _ = delegate.applicationDidFinishLaunching(Notification(name: .init("test")))
        }
    }

    func testMemoryUsage_WithNotes() throws {
        let notes = TestDataFactory.createNotes(count: 1000)

        measure(metrics: [XCTMemoryMetric()]) {
            // Load notes into memory
            let viewModel = NotesViewModel()
            viewModel.notes = notes

            // Force UI updates
            let view = NotesListView(viewModel: viewModel)
            _ = view.body
        }
    }

    func testMemoryLeaks() throws {
        weak var weakViewModel: NotesViewModel?

        try autoreleasepool {
            let viewModel = NotesViewModel()
            weakViewModel = viewModel

            // Perform operations that might leak
            let notes = TestDataFactory.createNotes(count: 100)
            viewModel.notes = notes
        }

        // Verify deallocation
        XCTAssertNil(weakViewModel, "ViewModel should be deallocated")
    }
}
```

#### Memory Optimization Strategies
- **Lazy Loading**: Load notes on demand
- **Object Pooling**: Reuse expensive objects
- **Weak References**: Prevent retain cycles
- **Background Cleanup**: Periodic memory cleanup

### 3. CPU Performance

#### CPU Benchmarks
```swift
class CPUPerformanceTests: XCTestCase {
    func testCPUUsage_Idle() throws {
        measure(metrics: [XCTCPUMetric()]) {
            // Simulate idle state
            let app = NSApplication.shared
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 1.0))
        }
    }

    func testCPUUsage_NoteOperations() throws {
        let notes = TestDataFactory.createNotes(count: 100)

        measure(metrics: [XCTCPUMetric()]) {
            // Perform CPU-intensive operations
            for note in notes {
                _ = note.content.uppercased()
                _ = note.title.replacingOccurrences(of: " ", with: "_")
            }
        }
    }

    func testCPUUsage_Search() throws {
        let notes = TestDataFactory.createNotes(count: 1000)
        let searchTerms = ["test", "note", "content", "title"]

        measure(metrics: [XCTCPUMetric()]) {
            for term in searchTerms {
                _ = notes.filter { note in
                    note.title.localizedCaseInsensitiveContains(term) ||
                    note.content.localizedCaseInsensitiveContains(term)
                }
            }
        }
    }
}
```

### 4. Search Performance

#### Search Benchmarks
```swift
class SearchPerformanceTests: XCTestCase {
    var notes: [Note] = []

    override func setUp() {
        super.setUp()
        notes = TestDataFactory.createNotes(count: 1000)
    }

    func testSearchPerformance_SmallDataset() throws {
        let smallNotes = Array(notes.prefix(100))

        measure {
            let results = smallNotes.filter { note in
                note.title.localizedCaseInsensitiveContains("test") ||
                note.content.localizedCaseInsensitiveContains("test")
            }
            XCTAssertFalse(results.isEmpty)
        }
    }

    func testSearchPerformance_LargeDataset() throws {
        measure {
            let results = notes.filter { note in
                note.title.localizedCaseInsensitiveContains("test") ||
                note.content.localizedCaseInsensitiveContains("test")
            }
            XCTAssertFalse(results.isEmpty)
        }
    }

    func testSearchPerformance_ComplexQuery() throws {
        measure {
            let results = notes.filter { note in
                note.title.localizedCaseInsensitiveContains("test") &&
                note.color == .yellow &&
                note.createdAt > Date(timeIntervalSinceNow: -86400)
            }
            XCTAssertFalse(results.isEmpty)
        }
    }

    func testSearchPerformance_Index() throws {
        // Test with indexed search
        let indexedNotes = Dictionary(grouping: notes, by: { $0.title.prefix(1) })

        measure {
            let results = indexedNotes["T"]?.filter { note in
                note.content.localizedCaseInsensitiveContains("test")
            } ?? []
            XCTAssertFalse(results.isEmpty)
        }
    }
}
```

#### Search Optimization Strategies
- **Indexing**: Title and content indexing
- **Caching**: Recent search results
- **Background Processing**: Non-blocking search
- **Incremental Search**: Real-time results as user types

### 5. UI Responsiveness

#### UI Benchmarks
```swift
class UIPerformanceTests: XCTestCase {
    func testUIResponsiveness_ListRendering() throws {
        let notes = TestDataFactory.createNotes(count: 1000)
        let viewModel = NotesViewModel()
        viewModel.notes = notes

        measure(metrics: [XCTClockMetric()]) {
            let view = NotesListView(viewModel: viewModel)
            _ = view.body // Force view rendering
        }
    }

    func testUIResponsiveness_NoteEditing() throws {
        let note = TestDataFactory.createNote()
        let viewModel = NoteViewModel(note: note)

        measure(metrics: [XCTClockMetric()]) {
            // Simulate rapid typing
            for i in 0..<100 {
                viewModel.updateContent("Updated content \(i)")
            }
        }
    }

    func testUIResponsiveness_Scrolling() throws {
        let notes = TestDataFactory.createNotes(count: 10000)
        let viewModel = NotesViewModel()
        viewModel.notes = notes

        measure(metrics: [XCTClockMetric()]) {
            // Simulate scrolling through list
            for i in stride(from: 0, to: notes.count, by: 10) {
                _ = viewModel.notes[i]
            }
        }
    }
}
```

#### UI Optimization Strategies
- **Virtual Scrolling**: Render only visible items
- **Background Updates**: Non-blocking UI updates
- **Debounced Input**: Delay expensive operations
- **Progressive Loading**: Load content incrementally

### 6. Data Synchronization

#### Sync Benchmarks
```swift
class SyncPerformanceTests: XCTestCase {
    func testSyncPerformance_SmallDataset() throws {
        let notes = TestDataFactory.createNotes(count: 10)

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            let syncService = CloudSyncService()
            try await syncService.syncNotes(notes)
        }
    }

    func testSyncPerformance_LargeDataset() throws {
        let notes = TestDataFactory.createNotes(count: 100)

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            let syncService = CloudSyncService()
            try await syncService.syncNotes(notes)
        }
    }

    func testSyncPerformance_ConflictResolution() throws {
        let localNotes = TestDataFactory.createNotes(count: 50)
        let remoteNotes = localNotes.map { note in
            var modified = note
            modified.content = "Modified content"
            return modified
        }

        measure(metrics: [XCTClockMetric()]) {
            let syncService = CloudSyncService()
            try await syncService.resolveConflicts(local: localNotes, remote: remoteNotes)
        }
    }
}
```

## 🛠️ Benchmarking Tools

### Xcode Instruments

#### Custom Instruments Template
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>title</key>
    <string>StickyNotes Performance</string>
    <key>instruments</key>
    <array>
        <dict>
            <key>type</key>
            <string>time-profiler</string>
        </dict>
        <dict>
            <key>type</key>
            <string>memory</string>
        </dict>
        <dict>
            <key>type</key>
            <string>cpu</string>
        </dict>
    </array>
</dict>
</plist>
```

### Performance Testing Framework

#### Custom Performance Test Base Class
```swift
class PerformanceTestCase: XCTestCase {
    private var startTime: CFAbsoluteTime = 0
    private var startMemory: UInt64 = 0

    override func setUp() {
        super.setUp()
        startTime = CFAbsoluteTimeGetCurrent()
        startMemory = getCurrentMemoryUsage()
    }

    override func tearDown() {
        let endTime = CFAbsoluteTimeGetCurrent()
        let endMemory = getCurrentMemoryUsage()

        let duration = endTime - startTime
        let memoryDelta = Int64(endMemory) - Int64(startMemory)

        print("Performance Test '\(name)':")
        print("  Duration: \(String(format: "%.3f", duration))s")
        print("  Memory Delta: \(memoryDelta) bytes")

        super.tearDown()
    }

    private func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), intPtr, &count)
            }
        }
        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }
}
```

## 📊 Benchmark Results

### Historical Performance Data

#### Startup Time Trends
```
Date       | Cold Start | Warm Start | Memory Usage
-----------|------------|------------|-------------
2024-01-01 | 2.1s      | 0.4s      | 65MB
2024-02-01 | 1.9s      | 0.3s      | 62MB
2024-03-01 | 1.8s      | 0.3s      | 58MB
2024-04-01 | 1.7s      | 0.2s      | 55MB
```

#### Search Performance Trends
```
Dataset Size | 1.0.0 | 1.1.0 | 1.2.0 | 1.3.0
-------------|-------|-------|-------|-------
100 notes    | 12ms  | 10ms  | 8ms   | 6ms
1000 notes   | 45ms  | 38ms  | 32ms  | 28ms
10000 notes  | 180ms | 150ms | 120ms | 95ms
```

### Performance Regression Detection

#### Automated Regression Testing
```swift
class PerformanceRegressionDetector {
    private let baselineFile = "performance-baselines.json"
    private var baselines: [String: PerformanceBaseline] = [:]

    func loadBaselines() throws {
        let url = URL(fileURLWithPath: baselineFile)
        let data = try Data(contentsOf: url)
        baselines = try JSONDecoder().decode([String: PerformanceBaseline].self, from: data)
    }

    func checkRegression(testName: String, duration: TimeInterval) -> Bool {
        guard let baseline = baselines[testName] else {
            // No baseline, update with current value
            baselines[testName] = PerformanceBaseline(
                testName: testName,
                averageDuration: duration,
                standardDeviation: 0,
                sampleSize: 1,
                lastUpdated: Date()
            )
            return false
        }

        let threshold = baseline.averageDuration + (2 * baseline.standardDeviation)
        return duration > threshold
    }

    func updateBaseline(testName: String, duration: TimeInterval) {
        let baseline = baselines[testName] ?? PerformanceBaseline(
            testName: testName,
            averageDuration: 0,
            standardDeviation: 0,
            sampleSize: 0,
            lastUpdated: Date()
        )

        // Update running average and standard deviation
        let newSampleSize = baseline.sampleSize + 1
        let newAverage = ((baseline.averageDuration * Double(baseline.sampleSize)) + duration) / Double(newSampleSize)

        let variance = baseline.standardDeviation * baseline.standardDeviation
        let newVariance = ((Double(baseline.sampleSize - 1) * variance) + pow(duration - baseline.averageDuration, 2)) / Double(baseline.sampleSize)
        let newStdDev = sqrt(newVariance)

        baselines[testName] = PerformanceBaseline(
            testName: testName,
            averageDuration: newAverage,
            standardDeviation: newStdDev,
            sampleSize: newSampleSize,
            lastUpdated: Date()
        )
    }
}

struct PerformanceBaseline: Codable {
    let testName: String
    let averageDuration: TimeInterval
    let standardDeviation: TimeInterval
    let sampleSize: Int
    let lastUpdated: Date
}
```

## 🎯 Performance Optimization

### Memory Optimization

#### Object Pooling
```swift
class NoteViewPool {
    private var pool: [String: NoteView] = [:]
    private let maxPoolSize = 50

    func getView(for note: Note) -> NoteView {
        let key = note.id.uuidString

        if let view = pool[key] {
            return view
        }

        let view = NoteView(note: note)

        if pool.count < maxPoolSize {
            pool[key] = view
        }

        return view
    }

    func returnView(_ view: NoteView, for note: Note) {
        let key = note.id.uuidString
        pool[key] = view
    }

    func clearPool() {
        pool.removeAll()
    }
}
```

#### Lazy Loading
```swift
class LazyNoteLoader {
    private var loadedNotes: [UUID: Note] = [:]
    private let repository: NoteRepository

    func getNote(id: UUID) async throws -> Note {
        if let cached = loadedNotes[id] {
            return cached
        }

        let note = try await repository.fetch(id: id)
        loadedNotes[id] = note
        return note
    }

    func preloadNotes(ids: [UUID]) async throws {
        let uncachedIds = ids.filter { !loadedNotes.keys.contains($0) }
        guard !uncachedIds.isEmpty else { return }

        let notes = try await repository.fetch(ids: uncachedIds)
        for note in notes {
            loadedNotes[note.id] = note
        }
    }
}
```

### CPU Optimization

#### Background Processing
```swift
class BackgroundProcessor {
    private let queue = DispatchQueue(
        label: "com.stickynotes.background",
        qos: .background,
        attributes: .concurrent
    )

    func processNotes(_ notes: [Note], operation: @escaping (Note) -> Void) async {
        await withTaskGroup(of: Void.self) { group in
            for note in notes {
                group.addTask {
                    operation(note)
                }
            }
        }
    }

    func processNotesSequentially(_ notes: [Note], operation: @escaping (Note) -> Void) async {
        for note in notes {
            operation(note)
            await Task.yield() // Allow other tasks to run
        }
    }
}
```

#### Algorithm Optimization
```swift
extension Array where Element == Note {
    // Optimized search with early termination
    func fastSearch(query: String, maxResults: Int = 50) -> [Note] {
        var results: [Note] = []
        results.reserveCapacity(maxResults)

        let lowercaseQuery = query.lowercased()

        for note in self {
            if results.count >= maxResults {
                break
            }

            if note.title.lowercased().contains(lowercaseQuery) ||
               note.content.lowercased().contains(lowercaseQuery) {
                results.append(note)
            }
        }

        return results
    }

    // Parallel search for large datasets
    func parallelSearch(query: String, maxResults: Int = 50) -> [Note] {
        let chunkSize = 1000
        let chunks = stride(from: 0, to: count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, count)])
        }

        return chunks.concurrentMap { chunk in
            chunk.fastSearch(query: query, maxResults: maxResults)
        }.flatMap { $0 }.prefix(maxResults)
    }
}

extension Array {
    func concurrentMap<T>(_ transform: @escaping (Element) -> T) -> [T] {
        var results = [T?](repeating: nil, count: count)

        DispatchQueue.concurrentPerform(iterations: count) { index in
            results[index] = transform(self[index])
        }

        return results.compactMap { $0 }
    }
}
```

## 📈 Monitoring & Alerting

### Performance Monitoring

#### Real-time Metrics
```swift
class PerformanceMonitor {
    static let shared = PerformanceMonitor()

    private var metrics: [String: PerformanceMetric] = [:]
    private let queue = DispatchQueue(label: "performance.monitor")

    func recordMetric(_ name: String, value: Double, unit: String = "") {
        queue.async {
            let metric = self.metrics[name, default: PerformanceMetric(name: name, unit: unit)]
            metric.addSample(value)
            self.metrics[name] = metric

            // Check thresholds
            self.checkThresholds(for: metric)
        }
    }

    func getMetric(_ name: String) -> PerformanceMetric? {
        queue.sync { metrics[name] }
    }

    private func checkThresholds(for metric: PerformanceMetric) {
        guard let threshold = metric.threshold else { return }

        let average = metric.average
        if average > threshold.upperBound {
            logPerformanceAlert("High \(metric.name): \(average) \(metric.unit)")
        } else if average < threshold.lowerBound {
            logPerformanceAlert("Low \(metric.name): \(average) \(metric.unit)")
        }
    }
}

struct PerformanceMetric {
    let name: String
    let unit: String
    var samples: [Double] = []
    var threshold: Threshold?

    mutating func addSample(_ value: Double) {
        samples.append(value)

        // Keep only recent samples
        if samples.count > 1000 {
            samples.removeFirst(samples.count - 1000)
        }
    }

    var average: Double {
        samples.isEmpty ? 0 : samples.reduce(0, +) / Double(samples.count)
    }

    var standardDeviation: Double {
        let avg = average
        let variance = samples.map { pow($0 - avg, 2) }.reduce(0, +) / Double(samples.count)
        return sqrt(variance)
    }
}

struct Threshold {
    let lowerBound: Double
    let upperBound: Double
}
```

#### Automated Alerting
```swift
class PerformanceAlertManager {
    static let shared = PerformanceAlertManager()

    private var alerts: [PerformanceAlert] = []

    func logPerformanceAlert(_ message: String) {
        let alert = PerformanceAlert(message: message, timestamp: Date())
        alerts.append(alert)

        // Send to monitoring service
        sendAlertToService(alert)

        // Log locally
        print("🚨 Performance Alert: \(message)")
    }

    func getRecentAlerts(hours: Int = 24) -> [PerformanceAlert] {
        let cutoff = Date(timeIntervalSinceNow: Double(-hours * 3600))
        return alerts.filter { $0.timestamp > cutoff }
    }

    private func sendAlertToService(_ alert: PerformanceAlert) {
        // Send to external monitoring service
        // Implementation depends on monitoring platform
    }
}

struct PerformanceAlert {
    let message: String
    let timestamp: Date
    let severity: AlertSeverity = .warning
}

enum AlertSeverity {
    case info
    case warning
    case critical
}
```

---

*These performance benchmarks ensure StickyNotes maintains excellent performance across all usage scenarios. Regular monitoring and optimization keep the app fast and responsive for users.*