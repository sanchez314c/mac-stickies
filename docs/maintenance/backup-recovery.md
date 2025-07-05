# Backup and Recovery Guide

Comprehensive backup and recovery procedures for StickyNotes data protection.

## 📋 Backup Overview

### Backup Objectives
- **Data Protection**: Prevent permanent data loss
- **Business Continuity**: Minimize downtime during incidents
- **Compliance**: Meet data retention requirements
- **User Confidence**: Ensure users can recover their data

### Backup Types
```
┌─────────────────────────────────────────────────────────────┐
│                    Backup Types                            │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │   Full      │ │ Incremental │ │  Differential│           │
│  │  Backup     │ │  Backup     │ │   Backup     │           │
│  │             │ │             │ │              │           │
│  │ • Complete  │ │ • Changes   │ │ • Changes     │           │
│  │ • Slow      │ │ • Fast      │ │ • Moderate    │           │
│  │ • Large     │ │ • Small     │ │ • Medium      │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │  On-site    │ │   Off-site  │ │   Cloud     │           │
│  │  Storage    │ │  Storage    │ │  Storage    │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
└─────────────────────────────────────────────────────────────┘
```

## 💾 Automated Backups

### Time Machine Integration

#### Setup Time Machine Backup
```bash
#!/bin/bash
# setup-timemachine-backup.sh

# Check if Time Machine is enabled
TM_STATUS=$(tmutil status | grep "Running" | awk '{print $3}')

if [ "$TM_STATUS" = "1" ]; then
    echo "✅ Time Machine is running"
else
    echo "❌ Time Machine is not running"
    echo "Please enable Time Machine in System Preferences"
    exit 1
fi

# Get backup destinations
echo "Available backup destinations:"
tmutil destinationinfo

# Check last backup time
LAST_BACKUP=$(tmutil latestbackup 2>/dev/null)
if [ -n "$LAST_BACKUP" ]; then
    echo "Last backup: $LAST_BACKUP"
else
    echo "No backups found"
fi

# Check excluded items
echo "Excluded from backup:"
tmutil isexcluded ~/Library/Containers/com.superclaude.stickynotes || echo "StickyNotes data is included in backup"
```

#### Time Machine Backup Schedule
- **Automatic**: Every hour when Time Machine disk is available
- **Manual**: Can be triggered anytime via menu bar
- **Deep Backup**: Full system backup weekly
- **Retention**: Keeps hourly backups for 24 hours, daily for 30 days, weekly until disk full

### iCloud Backup

#### iCloud Data Protection
```swift
class CloudBackupManager {
    private let container: CKContainer
    private let privateDatabase: CKDatabase

    init() {
        container = CKContainer(identifier: "iCloud.com.superclaude.stickynotes")
        privateDatabase = container.privateCloudDatabase
    }

    func enableCloudBackup() async throws {
        // Check iCloud availability
        guard FileManager.default.ubiquityIdentityToken != nil else {
            throw BackupError.iCloudNotAvailable
        }

        // Enable iCloud sync
        UserDefaults.standard.set(true, forKey: "iCloudSyncEnabled")

        // Initial sync
        try await performInitialSync()
    }

    func performInitialSync() async throws {
        let notes = try await loadLocalNotes()
        let records = notes.map { $0.toCloudKitRecord() }

        // Upload in batches to avoid timeouts
        let batchSize = 100
        for batch in records.chunked(into: batchSize) {
            try await privateDatabase.modifyRecords(
                saving: batch,
                deleting: [],
                savePolicy: .allKeys
            )
        }
    }

    private func loadLocalNotes() async throws -> [Note] {
        // Load notes from local storage
        // Implementation depends on data layer
        return []
    }
}
```

#### iCloud Backup Features
- **Automatic Sync**: Changes sync across devices
- **Conflict Resolution**: Automatic merging of conflicting changes
- **Offline Support**: Local changes sync when online
- **Storage Limits**: 5GB free, additional storage available

### Application-Level Backups

#### Automatic Data Backup
```swift
class BackupManager {
    static let shared = BackupManager()

    private let backupQueue = DispatchQueue(label: "backup.queue")
    private var backupTimer: Timer?

    func startAutomaticBackup() {
        // Backup every 6 hours
        backupTimer = Timer.scheduledTimer(
            withTimeInterval: 6 * 3600,
            repeats: true
        ) { [weak self] _ in
            self?.performAutomaticBackup()
        }
    }

    private func performAutomaticBackup() {
        backupQueue.async {
            do {
                let backupURL = try self.createBackup()
                try self.cleanOldBackups()

                print("✅ Automatic backup completed: \(backupURL.lastPathComponent)")
            } catch {
                print("❌ Automatic backup failed: \(error.localizedDescription)")
            }
        }
    }

    private func createBackup() throws -> URL {
        let backupDir = getBackupDirectory()
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let backupName = "StickyNotes-Backup-\(timestamp).zip"
        let backupURL = backupDir.appendingPathComponent(backupName)

        // Create backup archive
        let tempDir = FileManager.default.temporaryDirectory
        let tempBackupDir = tempDir.appendingPathComponent("backup-temp")

        try FileManager.default.createDirectory(at: tempBackupDir, withIntermediateDirectories: true)

        // Copy data to temp directory
        try copyDataToBackup(tempBackupDir)

        // Create zip archive
        try createZipArchive(from: tempBackupDir, to: backupURL)

        // Clean up temp directory
        try FileManager.default.removeItem(at: tempBackupDir)

        return backupURL
    }

    private func copyDataToBackup(_ backupDir: URL) throws {
        let fileManager = FileManager.default

        // Copy Core Data store
        let dataDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("StickyNotes")

        if fileManager.fileExists(atPath: dataDir.path) {
            let backupDataDir = backupDir.appendingPathComponent("Data")
            try fileManager.copyItem(at: dataDir, to: backupDataDir)
        }

        // Copy preferences
        let prefsURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Preferences")
            .appendingPathComponent("com.superclaude.stickynotes.plist")

        if fileManager.fileExists(atPath: prefsURL.path) {
            let backupPrefsURL = backupDir.appendingPathComponent("Preferences.plist")
            try fileManager.copyItem(at: prefsURL, to: backupPrefsURL)
        }
    }

    private func createZipArchive(from sourceDir: URL, to destinationURL: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = ["-r", destinationURL.path, "."]
        process.currentDirectoryURL = sourceDir

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw BackupError.archiveCreationFailed
        }
    }

    private func cleanOldBackups() throws {
        let backupDir = getBackupDirectory()
        let fileManager = FileManager.default

        let backups = try fileManager.contentsOfDirectory(
            at: backupDir,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ).filter { $0.pathExtension == "zip" }

        // Keep last 10 backups
        if backups.count > 10 {
            let sortedBackups = backups.sorted { lhs, rhs in
                let lhsDate = try? lhs.resourceValues(forKeys: [.creationDateKey]).creationDate ?? .distantPast
                let rhsDate = try? rhs.resourceValues(forKeys: [.creationDateKey]).creationDate ?? .distantPast
                return lhsDate ?? .distantPast > rhsDate ?? .distantPast
            }

            for backup in sortedBackups[10...] {
                try fileManager.removeItem(at: backup)
            }
        }
    }

    private func getBackupDirectory() -> URL {
        let fileManager = FileManager.default
        let backupDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("StickyNotes")
            .appendingPathComponent("Backups")

        try? fileManager.createDirectory(at: backupDir, withIntermediateDirectories: true)
        return backupDir
    }
}

enum BackupError: LocalizedError {
    case iCloudNotAvailable
    case archiveCreationFailed
    case insufficientSpace
    case backupDirectoryNotAccessible

    var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return "iCloud is not available or not signed in"
        case .archiveCreationFailed:
            return "Failed to create backup archive"
        case .insufficientSpace:
            return "Insufficient disk space for backup"
        case .backupDirectoryNotAccessible:
            return "Cannot access backup directory"
        }
    }
}
```

## 📤 Manual Backup Procedures

### Export User Data

#### Complete Data Export
```swift
class DataExportManager {
    static let shared = DataExportManager()

    func exportAllData(to url: URL) async throws {
        let exportData = try await gatherExportData()
        let jsonData = try JSONEncoder().encode(exportData)
        try jsonData.write(to: url)
    }

    private func gatherExportData() async throws -> ExportData {
        let notes = try await NoteService.shared.getAllNotes()
        let preferences = getUserPreferences()
        let metadata = createExportMetadata()

        return ExportData(
            notes: notes,
            preferences: preferences,
            metadata: metadata
        )
    }

    private func getUserPreferences() -> [String: Any] {
        UserDefaults.standard.dictionaryRepresentation()
    }

    private func createExportMetadata() -> ExportMetadata {
        ExportMetadata(
            version: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown",
            exportDate: Date(),
            platform: "macOS",
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString
        )
    }
}

struct ExportData: Codable {
    let notes: [Note]
    let preferences: [String: Any]
    let metadata: ExportMetadata
}

struct ExportMetadata: Codable {
    let version: String
    let exportDate: Date
    let platform: String
    let osVersion: String
}
```

#### Selective Export Options
- **Notes by Date Range**: Export notes created or modified within specific dates
- **Notes by Color**: Export notes of specific colors
- **Notes by Tags**: Export notes with specific tags
- **Single Note**: Export individual notes

### Backup Verification

#### Backup Integrity Check
```swift
class BackupVerifier {
    static let shared = BackupVerifier()

    func verifyBackup(at url: URL) throws -> BackupVerificationResult {
        let fileManager = FileManager.default

        // Check if backup file exists
        guard fileManager.fileExists(atPath: url.path) else {
            throw BackupError.backupFileNotFound
        }

        // Check file size
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int64 ?? 0

        guard fileSize > 0 else {
            throw BackupError.backupFileEmpty
        }

        // For zip files, verify archive integrity
        if url.pathExtension == "zip" {
            try verifyZipArchive(at: url)
        }

        // For JSON files, verify data integrity
        if url.pathExtension == "json" {
            try verifyJSONData(at: url)
        }

        return BackupVerificationResult(
            isValid: true,
            fileSize: fileSize,
            noteCount: try getNoteCount(from: url),
            verificationDate: Date()
        )
    }

    private func verifyZipArchive(at url: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-t", url.path]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            throw BackupError.corruptedArchive(details: output)
        }
    }

    private func verifyJSONData(at url: URL) throws {
        let data = try Data(contentsOf: url)
        _ = try JSONDecoder().decode(ExportData.self, from: data)
    }

    private func getNoteCount(from url: URL) throws -> Int {
        if url.pathExtension == "json" {
            let data = try Data(contentsOf: url)
            let exportData = try JSONDecoder().decode(ExportData.self, from: data)
            return exportData.notes.count
        } else if url.pathExtension == "zip" {
            // Extract and count notes from zip
            return 0 // Placeholder
        }
        return 0
    }
}

struct BackupVerificationResult {
    let isValid: Bool
    let fileSize: Int64
    let noteCount: Int
    let verificationDate: Date
}

enum BackupError: LocalizedError {
    case backupFileNotFound
    case backupFileEmpty
    case corruptedArchive(details: String)
    case invalidJSONData
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .backupFileNotFound:
            return "Backup file not found"
        case .backupFileEmpty:
            return "Backup file is empty"
        case .corruptedArchive(let details):
            return "Backup archive is corrupted: \(details)"
        case .invalidJSONData:
            return "Backup data is invalid"
        case .verificationFailed:
            return "Backup verification failed"
        }
    }
}
```

## 🔄 Recovery Procedures

### Data Recovery Priority
1. **P0 - Critical**: Complete data loss, application unusable
2. **P1 - High**: Significant data loss, core functionality affected
3. **P2 - Medium**: Partial data loss, limited functionality affected
4. **P3 - Low**: Minor data loss, full functionality available

### Recovery Strategies

#### Strategy 1: Time Machine Restore
```bash
#!/bin/bash
# timemachine-restore.sh

echo "=== Time Machine Data Recovery ==="

# Check available backups
echo "Available backups:"
tmutil listbackups

# Enter Time Machine
echo "Opening Time Machine..."
open /System/Library/CoreServices/backupd.bundle/Contents/Resources/restore.app

echo "Instructions:"
echo "1. Navigate to ~/Library/Containers/com.superclaude.stickynotes"
echo "2. Select the data you want to restore"
echo "3. Click Restore"
echo "4. Restart StickyNotes"
```

#### Strategy 2: iCloud Recovery
```swift
class CloudRecoveryManager {
    static let shared = CloudRecoveryManager()

    func recoverFromCloud() async throws {
        // Disable local sync temporarily
        UserDefaults.standard.set(false, forKey: "iCloudSyncEnabled")

        // Clear local data
        try clearLocalData()

        // Re-enable sync to download from cloud
        UserDefaults.standard.set(true, forKey: "iCloudSyncEnabled")

        // Wait for sync to complete
        try await waitForSyncCompletion()
    }

    private func clearLocalData() throws {
        let fileManager = FileManager.default
        let dataDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("StickyNotes")

        if fileManager.fileExists(atPath: dataDir.path) {
            try fileManager.removeItem(at: dataDir)
        }
    }

    private func waitForSyncCompletion() async throws {
        // Implementation to wait for iCloud sync
        // This would monitor sync status
    }
}
```

#### Strategy 3: Backup File Restore
```swift
class BackupRestoreManager {
    static let shared = BackupRestoreManager()

    func restoreFromBackup(at url: URL) async throws {
        // Verify backup
        let verification = try BackupVerifier.shared.verifyBackup(at: url)
        guard verification.isValid else {
            throw BackupError.backupVerificationFailed
        }

        // Create restore point
        try createRestorePoint()

        // Extract backup data
        let tempDir = try extractBackupData(from: url)

        // Restore data
        try await restoreData(from: tempDir)

        // Clean up
        try FileManager.default.removeItem(at: tempDir)

        // Verify restoration
        try await verifyRestoration()
    }

    private func createRestorePoint() throws {
        let fileManager = FileManager.default
        let dataDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("StickyNotes")

        if fileManager.fileExists(atPath: dataDir.path) {
            let backupDir = dataDir.deletingLastPathComponent()
                .appendingPathComponent("StickyNotes-Backup-\(Date().timeIntervalSince1970)")

            try fileManager.moveItem(at: dataDir, to: backupDir)
        }
    }

    private func extractBackupData(from url: URL) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("restore-temp-\(UUID())")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        if url.pathExtension == "zip" {
            try unzipArchive(from: url, to: tempDir)
        } else if url.pathExtension == "json" {
            // Handle JSON export format
            try FileManager.default.copyItem(at: url, to: tempDir.appendingPathComponent("export.json"))
        }

        return tempDir
    }

    private func unzipArchive(from source: URL, to destination: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = [source.path, "-d", destination.path]

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw BackupError.archiveExtractionFailed
        }
    }

    private func restoreData(from tempDir: URL) async throws {
        let fileManager = FileManager.default

        // Restore Core Data store
        let dataDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("StickyNotes")

        let backupDataDir = tempDir.appendingPathComponent("Data")
        if fileManager.fileExists(atPath: backupDataDir.path) {
            try fileManager.createDirectory(at: dataDir, withIntermediateDirectories: true)
            try fileManager.copyItem(at: backupDataDir, to: dataDir)
        }

        // Restore preferences
        let prefsURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Preferences")
            .appendingPathComponent("com.superclaude.stickynotes.plist")

        let backupPrefsURL = tempDir.appendingPathComponent("Preferences.plist")
        if fileManager.fileExists(atPath: backupPrefsURL.path) {
            try fileManager.copyItem(at: backupPrefsURL, to: prefsURL)
        }
    }

    private func verifyRestoration() async throws {
        // Verify that data was restored correctly
        let noteCount = try await NoteService.shared.getNotesCount()
        print("✅ Restored \(noteCount) notes")

        // Additional verification checks
    }
}
```

### Recovery Testing

#### Recovery Test Procedures
```swift
class RecoveryTestManager {
    static let shared = RecoveryTestManager()

    func performRecoveryTest() async throws {
        print("=== Starting Recovery Test ===")

        // Create test data
        let testNotes = try await createTestData()

        // Create backup
        let backupURL = try await BackupManager.shared.createBackup()

        // Simulate data loss
        try simulateDataLoss()

        // Perform recovery
        try await BackupRestoreManager.shared.restoreFromBackup(at: backupURL)

        // Verify recovery
        try await verifyRecovery(testNotes)

        print("✅ Recovery test passed")
    }

    private func createTestData() async throws -> [Note] {
        let testNotes = [
            Note(title: "Test Note 1", content: "Content 1"),
            Note(title: "Test Note 2", content: "Content 2"),
            Note(title: "Test Note 3", content: "Content 3")
        ]

        for note in testNotes {
            try await NoteService.shared.createNote(
                title: note.title,
                content: note.content,
                color: note.color
            )
        }

        return testNotes
    }

    private func simulateDataLoss() throws {
        let fileManager = FileManager.default
        let dataDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("StickyNotes")

        if fileManager.fileExists(atPath: dataDir.path) {
            try fileManager.removeItem(at: dataDir)
        }
    }

    private func verifyRecovery(_ originalNotes: [Note]) async throws {
        let restoredNotes = try await NoteService.shared.getAllNotes()

        guard restoredNotes.count == originalNotes.count else {
            throw RecoveryTestError.noteCountMismatch
        }

        for originalNote in originalNotes {
            guard restoredNotes.contains(where: { $0.title == originalNote.title }) else {
                throw RecoveryTestError.noteMissing
            }
        }
    }
}

enum RecoveryTestError: LocalizedError {
    case noteCountMismatch
    case noteMissing
    case dataCorruption

    var errorDescription: String? {
        switch self {
        case .noteCountMismatch:
            return "Restored note count doesn't match original"
        case .noteMissing:
            return "Some notes are missing after recovery"
        case .dataCorruption:
            return "Restored data is corrupted"
        }
    }
}
```

## 📊 Backup Monitoring

### Backup Health Metrics

#### Backup Success Rate
- **Target**: 100% success rate for automated backups
- **Monitoring**: Track backup failures and reasons
- **Alerting**: Alert when backup success rate drops below 95%

#### Backup Age
- **Maximum Age**: No backup older than 24 hours
- **Monitoring**: Track age of last successful backup
- **Alerting**: Alert when last backup is older than 25 hours

#### Backup Size Trends
- **Monitoring**: Track backup size over time
- **Anomaly Detection**: Alert on unusual size changes
- **Capacity Planning**: Plan storage needs based on growth

### Backup Reporting

#### Automated Reports
```swift
class BackupReportingManager {
    static let shared = BackupReportingManager()

    func generateBackupReport() -> BackupReport {
        let backups = getAvailableBackups()
        let lastBackup = backups.max(by: { $0.date < $1.date })
        let successRate = calculateSuccessRate(backups)
        let storageUsed = calculateStorageUsed(backups)

        return BackupReport(
            totalBackups: backups.count,
            lastBackupDate: lastBackup?.date,
            successRate: successRate,
            storageUsed: storageUsed,
            issues: identifyIssues(backups)
        )
    }

    private func getAvailableBackups() -> [BackupInfo] {
        // Implementation to list available backups
        return []
    }

    private func calculateSuccessRate(_ backups: [BackupInfo]) -> Double {
        let successful = backups.filter { $0.status == .success }.count
        return Double(successful) / Double(backups.count)
    }

    private func calculateStorageUsed(_ backups: [BackupInfo]) -> Int64 {
        backups.reduce(0) { $0 + $1.size }
    }

    private func identifyIssues(_ backups: [BackupInfo]) -> [BackupIssue] {
        var issues: [BackupIssue] = []

        // Check for old backups
        if let lastBackup = backups.max(by: { $0.date < $1.date }),
           Date().timeIntervalSince(lastBackup.date) > 25 * 3600 {
            issues.append(.oldBackup)
        }

        // Check success rate
        let successRate = calculateSuccessRate(backups)
        if successRate < 0.95 {
            issues.append(.lowSuccessRate)
        }

        return issues
    }
}

struct BackupReport {
    let totalBackups: Int
    let lastBackupDate: Date?
    let successRate: Double
    let storageUsed: Int64
    let issues: [BackupIssue]
}

struct BackupInfo {
    let date: Date
    let size: Int64
    let status: BackupStatus
}

enum BackupStatus {
    case success
    case failed
    case partial
}

enum BackupIssue {
    case oldBackup
    case lowSuccessRate
    case storageFull
    case corruptedBackup
}
```

## 📋 Backup Checklist

### Daily Backup Checks
- [ ] Automated backups completed successfully
- [ ] Backup verification passed
- [ ] Sufficient storage space available
- [ ] No backup failures in logs
- [ ] Backup age within acceptable limits

### Weekly Backup Reviews
- [ ] Backup success rate above 95%
- [ ] Storage utilization within limits
- [ ] Backup integrity verified
- [ ] Recovery procedures tested
- [ ] Backup retention policy followed

### Monthly Backup Audits
- [ ] Complete backup inventory
- [ ] Recovery testing performed
- [ ] Backup security verified
- [ ] Compliance requirements met
- [ ] Stakeholder reporting completed

### Backup Retention Policy
- **Daily Backups**: Keep 7 days
- **Weekly Backups**: Keep 4 weeks
- **Monthly Backups**: Keep 12 months
- **Yearly Backups**: Keep indefinitely
- **Total Retention**: 3 years minimum

---

*This backup and recovery guide ensures StickyNotes data is protected and recoverable through comprehensive backup strategies and tested recovery procedures.*