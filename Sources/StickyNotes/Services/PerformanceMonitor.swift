//
//  PerformanceMonitor.swift
//  StickyNotes
//
//  Performance monitoring and benchmarking
//

import Combine
import Foundation
import SwiftUI

class PerformanceMonitor {
    static let shared = PerformanceMonitor()

    // MARK: - Metrics

    private var startupTime: TimeInterval?
    private var coreDataOperationTimes: [String: [TimeInterval]] = [:]
    private var uiRenderTimes: [String: [TimeInterval]] = [:]
    private var memoryUsage: [Date: UInt64] = [:]
    private var cacheHitRates: [String: (hits: Int, misses: Int)] = [:]

    private let monitorQueue = DispatchQueue(label: "com.stickynotes.performance", qos: .background)
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupMemoryMonitoring()
        setupPeriodicReporting()
    }

    // MARK: - Startup Performance

    func markStartupBegin() {
        startupTime = ProcessInfo.processInfo.systemUptime
    }

    func markStartupComplete() {
        guard let startTime = startupTime else { return }
        let duration = ProcessInfo.processInfo.systemUptime - startTime
        print("🚀 App startup time: \(String(format: "%.3f", duration))s")

        // Store for benchmarking
        UserDefaults.standard.set(duration, forKey: "lastStartupTime")
    }

    // MARK: - Core Data Performance

    func measureCoreDataOperation<T>(_ operationName: String, operation: () async throws -> T) async rethrows -> T {
        let startTime = ProcessInfo.processInfo.systemUptime

        let result = try await operation()

        let duration = ProcessInfo.processInfo.systemUptime - startTime

        monitorQueue.async {
            if self.coreDataOperationTimes[operationName] == nil {
                self.coreDataOperationTimes[operationName] = []
            }
            self.coreDataOperationTimes[operationName]?.append(duration)
        }

        return result
    }

    // MARK: - UI Performance

    func measureUIRender<T>(_ viewName: String, operation: () -> T) -> T {
        let startTime = ProcessInfo.processInfo.systemUptime

        let result = operation()

        let duration = ProcessInfo.processInfo.systemUptime - startTime

        monitorQueue.async {
            if self.uiRenderTimes[viewName] == nil {
                self.uiRenderTimes[viewName] = []
            }
            self.uiRenderTimes[viewName]?.append(duration)
        }

        return result
    }

    // MARK: - Cache Performance

    func recordCacheHit(_ cacheName: String) {
        monitorQueue.async {
            if self.cacheHitRates[cacheName] == nil {
                self.cacheHitRates[cacheName] = (0, 0)
            }
            self.cacheHitRates[cacheName]!.hits += 1
        }
    }

    func recordCacheMiss(_ cacheName: String) {
        monitorQueue.async {
            if self.cacheHitRates[cacheName] == nil {
                self.cacheHitRates[cacheName] = (0, 0)
            }
            self.cacheHitRates[cacheName]!.misses += 1
        }
    }

    // MARK: - Memory Monitoring

    private func setupMemoryMonitoring() {
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.recordMemoryUsage()
            }
            .store(in: &cancellables)
    }

    private func recordMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let memoryUsage = info.resident_size
            monitorQueue.async {
                self.memoryUsage[Date()] = memoryUsage
            }
        }
    }

    // MARK: - Performance Reporting

    private func setupPeriodicReporting() {
        Timer.publish(every: 300, on: .main, in: .common) // Every 5 minutes
            .autoconnect()
            .sink { [weak self] _ in
                self?.generatePerformanceReport()
            }
            .store(in: &cancellables)
    }

    func generatePerformanceReport() {
        monitorQueue.async {
            print("📊 Performance Report")
            print("====================")

            // Core Data operations
            print("\nCore Data Operations:")
            for (operation, times) in self.coreDataOperationTimes {
                let avg = times.reduce(0, +) / Double(times.count)
                let max = times.max() ?? 0
                print("  \(operation): avg=\(String(format: "%.3f", avg))s, max=\(String(format: "%.3f", max))s, count=\(times.count)")
            }

            // UI Render times
            print("\nUI Render Times:")
            for (view, times) in self.uiRenderTimes {
                let avg = times.reduce(0, +) / Double(times.count)
                let max = times.max() ?? 0
                print("  \(view): avg=\(String(format: "%.3f", avg))s, max=\(String(format: "%.3f", max))s, count=\(times.count)")
            }

            // Cache hit rates
            print("\nCache Performance:")
            for (cache, stats) in self.cacheHitRates {
                let total = stats.hits + stats.misses
                let hitRate = total > 0 ? Double(stats.hits) / Double(total) * 100 : 0
                print("  \(cache): \(String(format: "%.1f", hitRate))% hit rate (\(stats.hits)/\(total))")
            }

            // Memory usage
            if let latestMemory = self.memoryUsage.values.sorted(by: { $0 > $1 }).first {
                let memoryMB = Double(latestMemory) / 1024 / 1024
                print("\nMemory Usage: \(String(format: "%.1f", memoryMB)) MB")
            }

            print("====================")
        }
    }

    // MARK: - Benchmarking

    func runBenchmark() async {
        print("🏃 Running Performance Benchmarks...")

        // Core Data benchmarks
        await benchmarkCoreDataOperations()

        // Cache benchmarks
        benchmarkCacheOperations()

        // Memory benchmarks
        benchmarkMemoryUsage()

        print("✅ Benchmarks complete")
    }

    private func benchmarkCoreDataOperations() async {
        let persistenceService = CoreDataPersistenceService.shared

        do {
            // Create test notes
            var testNotes: [Note] = []
            for i in 0 ..< 100 {
                let note = Note(
                    title: "Benchmark Note \(i)",
                    content: NSAttributedString(string: "This is benchmark content for note \(i). " * 10),
                    color: .yellow
                )
                testNotes.append(note)
            }

            // Benchmark batch save
            let saveStart = ProcessInfo.processInfo.systemUptime
            try await persistenceService.batchSaveNotes(testNotes)
            let saveTime = ProcessInfo.processInfo.systemUptime - saveStart
            print("  Batch save (100 notes): \(String(format: "%.3f", saveTime))s")

            // Benchmark batch fetch
            let fetchStart = ProcessInfo.processInfo.systemUptime
            _ = try await persistenceService.fetchNotesBatch(offset: 0, limit: 100)
            let fetchTime = ProcessInfo.processInfo.systemUptime - fetchStart
            print("  Batch fetch (100 notes): \(String(format: "%.3f", fetchTime))s")

            // Benchmark search
            let searchStart = ProcessInfo.processInfo.systemUptime
            _ = try await persistenceService.searchNotes(query: "Benchmark")
            let searchTime = ProcessInfo.processInfo.systemUptime - searchStart
            print("  Search operation: \(String(format: "%.3f", searchTime))s")

        } catch {
            print("  Benchmark failed: \(error)")
        }
    }

    private func benchmarkCacheOperations() {
        let cacheService = CacheService.shared

        // Benchmark cache operations
        let testNote = Note(title: "Cache Test", content: NSAttributedString(string: "Test content"), color: .yellow)

        let cacheStart = ProcessInfo.processInfo.systemUptime
        for _ in 0 ..< 1000 {
            let preview = NotePreview(title: testNote.displayTitle, previewText: testNote.previewText, color: testNote.color, lastModified: testNote.modifiedAt)
            cacheService.cachePreview(for: testNote, preview: preview)
            _ = cacheService.getPreview(for: testNote.id)
        }
        let cacheTime = ProcessInfo.processInfo.systemUptime - cacheStart
        print("  Cache operations (1000 cycles): \(String(format: "%.3f", cacheTime))s")
    }

    private func benchmarkMemoryUsage() {
        // Force garbage collection and measure
        // Note: This is a simplified memory benchmark
        print("  Memory benchmark: Check performance report for details")
    }

    // MARK: - Performance Thresholds

    func checkPerformanceThresholds() -> [PerformanceIssue] {
        var issues: [PerformanceIssue] = []

        monitorQueue.sync {
            // Check Core Data operation times
            for (operation, times) in coreDataOperationTimes {
                let avg = times.reduce(0, +) / Double(times.count)
                if avg > 0.1 { // More than 100ms average
                    issues.append(.slowCoreDataOperation(operation: operation, averageTime: avg))
                }
            }

            // Check UI render times
            for (view, times) in uiRenderTimes {
                let avg = times.reduce(0, +) / Double(times.count)
                if avg > 0.016 { // More than 16ms (60fps threshold)
                    issues.append(.slowUIRender(view: view, averageTime: avg))
                }
            }

            // Check cache hit rates
            for (cache, stats) in cacheHitRates {
                let total = stats.hits + stats.misses
                let hitRate = total > 0 ? Double(stats.hits) / Double(total) : 0
                if hitRate < 0.8 { // Less than 80% hit rate
                    issues.append(.lowCacheHitRate(cache: cache, hitRate: hitRate))
                }
            }
        }

        return issues
    }
}

// MARK: - Supporting Types

enum PerformanceIssue {
    case slowCoreDataOperation(operation: String, averageTime: TimeInterval)
    case slowUIRender(view: String, averageTime: TimeInterval)
    case lowCacheHitRate(cache: String, hitRate: Double)

    var description: String {
        switch self {
        case let .slowCoreDataOperation(operation, time):
            return "Slow Core Data operation '\(operation)': \(String(format: "%.3f", time))s average"
        case let .slowUIRender(view, time):
            return "Slow UI render '\(view)': \(String(format: "%.3f", time))s average"
        case let .lowCacheHitRate(cache, rate):
            return "Low cache hit rate '\(cache)': \(String(format: "%.1f", rate * 100))%"
        }
    }
}

// MARK: - SwiftUI Performance Helpers

extension View {
    func measureRenderTime(_ viewName: String) -> some View {
        PerformanceMonitor.shared.measureUIRender(viewName) {
            self
        }
    }
}
