# Security Guide

Comprehensive security practices and procedures for StickyNotes development and operations.

## 🔒 Security Overview

### Security Principles
- **Defense in Depth**: Multiple layers of security controls
- **Least Privilege**: Minimum permissions required for functionality
- **Fail-Safe Defaults**: Secure defaults with explicit opt-in for features
- **Zero Trust**: Verify all access and actions
- **Privacy by Design**: User privacy considered in all features

### Security Objectives
- **Confidentiality**: Protect user data from unauthorized access
- **Integrity**: Ensure data accuracy and prevent unauthorized modification
- **Availability**: Maintain service availability and prevent denial of service
- **Accountability**: Track and audit security-relevant events

## 🛡️ Application Security

### Data Encryption

#### At-Rest Encryption
```swift
class DataEncryptionManager {
    static let shared = DataEncryptionManager()

    private let keychain = KeychainManager()
    private var encryptionKey: SymmetricKey?

    func encrypt(_ data: Data) throws -> Data {
        let key = try getEncryptionKey()
        return try AES.GCM.seal(data, using: key)
    }

    func decrypt(_ data: Data) throws -> Data {
        let key = try getEncryptionKey()
        return try AES.GCM.open(data, using: key)
    }

    private func getEncryptionKey() throws -> SymmetricKey {
        if let key = encryptionKey {
            return key
        }

        // Try to get key from keychain
        if let keyData = try keychain.getData(for: "stickyNotesEncryptionKey") {
            let key = try SymmetricKey(data: keyData)
            encryptionKey = key
            return key
        }

        // Generate new key
        let key = SymmetricKey(size: .bits256)
        let keyData = key.dataRepresentation

        try keychain.set(keyData, for: "stickyNotesEncryptionKey")
        encryptionKey = key

        return key
    }
}

extension SymmetricKey {
    var dataRepresentation: Data {
        withUnsafeBytes { Data($0) }
    }

    init(data: Data) throws {
        self.init(data: data)
    }
}
```

#### In-Transit Encryption
```swift
class NetworkSecurityManager {
    static let shared = NetworkSecurityManager()

    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.default

        // Configure TLS settings
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
        configuration.tlsMaximumSupportedProtocolVersion = .TLSv13

        // Certificate pinning (if required)
        // configuration.urlCredentialStorage = nil
        // configuration.urlCache = nil

        session = URLSession(configuration: configuration)
    }

    func secureRequest(to url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method

        // Add security headers
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        // Add authentication if required
        if let token = getAuthToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func getAuthToken() -> String? {
        // Implementation to get authentication token
        return nil
    }
}
```

### Secure Coding Practices

#### Input Validation
```swift
class InputValidator {
    static let shared = InputValidator()

    func validateNoteTitle(_ title: String) throws {
        // Length validation
        guard title.count <= 100 else {
            throw ValidationError.titleTooLong
        }

        // Content validation
        guard !title.isEmpty else {
            throw ValidationError.titleEmpty
        }

        // Character validation (prevent injection)
        let allowedCharacters = CharacterSet.alphanumerics
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: "-_"))

        guard title.rangeOfCharacter(from: allowedCharacters.inverted) == nil else {
            throw ValidationError.invalidCharacters
        }

        // Prevent path traversal
        guard !title.contains("..") && !title.contains("/") else {
            throw ValidationError.pathTraversalAttempt
        }
    }

    func validateNoteContent(_ content: String) throws {
        // Length validation
        guard content.count <= 10000 else {
            throw ValidationError.contentTooLong
        }

        // Basic sanitization
        let sanitized = content
            .replacingOccurrences(of: "<script", with: "&lt;script", options: .caseInsensitive)
            .replacingOccurrences(of: "javascript:", with: "", options: .caseInsensitive)

        // Additional validation as needed
        _ = sanitized
    }

    func validateFilePath(_ path: String) throws {
        let url = URL(fileURLWithPath: path)

        // Ensure path is within allowed directories
        let allowedDirectories = [
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0],
            FileManager.default.temporaryDirectory
        ]

        let isAllowed = allowedDirectories.contains { allowedDir in
            url.path.hasPrefix(allowedDir.path)
        }

        guard isAllowed else {
            throw ValidationError.unauthorizedPath
        }

        // Prevent directory traversal
        guard !path.contains("..") else {
            throw ValidationError.pathTraversalAttempt
        }
    }
}

enum ValidationError: LocalizedError {
    case titleTooLong
    case titleEmpty
    case contentTooLong
    case invalidCharacters
    case pathTraversalAttempt
    case unauthorizedPath

    var errorDescription: String? {
        switch self {
        case .titleTooLong:
            return "Title is too long"
        case .titleEmpty:
            return "Title cannot be empty"
        case .contentTooLong:
            return "Content is too long"
        case .invalidCharacters:
            return "Title contains invalid characters"
        case .pathTraversalAttempt:
            return "Path traversal attempt detected"
        case .unauthorizedPath:
            return "Access to path is not authorized"
        }
    }
}
```

#### Secure File Operations
```swift
class SecureFileManager {
    static let shared = SecureFileManager()

    func secureWrite(_ data: Data, to url: URL) throws {
        // Validate path
        try InputValidator.shared.validateFilePath(url.path)

        // Create directory if needed
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete]
        )

        // Write atomically
        let tempURL = directory.appendingPathComponent(UUID().uuidString)
        try data.write(to: tempURL, options: .atomic)

        // Set secure permissions
        try setSecurePermissions(for: tempURL)

        // Move to final location
        try FileManager.default.moveItem(at: tempURL, to: url)
    }

    func secureRead(from url: URL) throws -> Data {
        // Validate path
        try InputValidator.shared.validateFilePath(url.path)

        // Check file permissions
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let permissions = attributes[.posixPermissions] as? Int else {
            throw SecurityError.invalidPermissions
        }

        // Ensure file is not world-writable
        guard permissions & 0o022 == 0 else {
            throw SecurityError.insecurePermissions
        }

        return try Data(contentsOf: url)
    }

    private func setSecurePermissions(for url: URL) throws {
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600], // Owner read/write only
            ofItemAtPath: url.path
        )
    }
}

enum SecurityError: LocalizedError {
    case invalidPermissions
    case insecurePermissions
    case accessDenied

    var errorDescription: String? {
        switch self {
        case .invalidPermissions:
            return "File has invalid permissions"
        case .insecurePermissions:
            return "File has insecure permissions"
        case .accessDenied:
            return "Access to file is denied"
        }
    }
}
```

## 🔐 macOS Security Integration

### App Sandbox

#### Entitlements Configuration
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- App Sandbox -->
    <key>com.apple.security.app-sandbox</key>
    <true/>

    <!-- File Access -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>

    <!-- Network Access -->
    <key>com.apple.security.network.client</key>
    <true/>

    <!-- Downloads Folder Access -->
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>

    <!-- Temporary Folder Access -->
    <key>com.apple.security.temporary-exception.files.absolute-path.read-write</key>
    <array>
        <string>/private/tmp</string>
        <string>/private/var/tmp</string>
    </array>

    <!-- Disable Undocumented Features -->
    <key>com.apple.security.cs.disable-library-validation</key>
    <false/>
    <key>com.apple.security.cs.disable-executable-page-protection</key>
    <false/>
    <key>com.apple.security.cs.allow-dyld-environment-variables</key>
    <false/>
</dict>
</plist>
```

### Code Signing and Notarization

#### Code Signing Setup
```bash
#!/bin/bash
# code-signing-setup.sh

# Verify certificate
echo "Checking code signing certificates..."
security find-identity -v -p codesigning

# Sign application
echo "Signing StickyNotes.app..."
codesign --force --deep --sign "Developer ID Application: Company Name (TEAM_ID)" \
    --entitlements StickyNotes.entitlements \
    --options runtime \
    --timestamp \
    "StickyNotes.app"

# Verify signature
echo "Verifying signature..."
codesign -vvv --deep --strict "StickyNotes.app"

# Check entitlements
echo "Checking entitlements..."
codesign -d --entitlements - "StickyNotes.app"
```

#### Notarization Process
```bash
#!/bin/bash
# notarization-process.sh

# Create zip archive
echo "Creating archive for notarization..."
ditto -c -k --keepParent "StickyNotes.app" "StickyNotes.zip"

# Submit for notarization
echo "Submitting for notarization..."
xcrun notarytool submit "StickyNotes.zip" \
    --apple-id "developer@company.com" \
    --password "app-specific-password" \
    --team-id "TEAM_ID" \
    --wait

# Check notarization status
echo "Checking notarization status..."
xcrun notarytool log <submission-id> \
    --apple-id "developer@company.com" \
    --password "app-specific-password" \
    --team-id "TEAM_ID"

# Staple notarization ticket
echo "Stapling notarization ticket..."
xcrun stapler staple "StickyNotes.app"

# Validate notarization
echo "Validating notarization..."
xcrun stapler validate "StickyNotes.app"
```

### Keychain Integration

#### Secure Credential Storage
```swift
class KeychainManager {
    static let shared = KeychainManager()

    func set(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.superclaude.stickynotes",
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Delete existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status: status)
        }
    }

    func getData(for key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.superclaude.stickynotes",
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.retrieveFailed(status: status)
        }

        return result as? Data
    }

    func delete(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.superclaude.stickynotes",
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status: status)
        }
    }
}

enum KeychainError: LocalizedError {
    case saveFailed(status: OSStatus)
    case retrieveFailed(status: OSStatus)
    case deleteFailed(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to keychain: \(status)"
        case .retrieveFailed(let status):
            return "Failed to retrieve from keychain: \(status)"
        case .deleteFailed(let status):
            return "Failed to delete from keychain: \(status)"
        }
    }
}
```

## 🛡️ Security Monitoring

### Threat Detection

#### Anomaly Detection
```swift
class SecurityMonitor {
    static let shared = SecurityMonitor()

    private var eventLog: [SecurityEvent] = []
    private let maxEvents = 10000

    func logEvent(_ event: SecurityEvent) {
        eventLog.append(event)
        if eventLog.count > maxEvents {
            eventLog.removeFirst()
        }

        // Check for suspicious patterns
        analyzeEvent(event)
    }

    private func analyzeEvent(_ event: SecurityEvent) {
        // Check for brute force attempts
        let recentFailedLogins = eventLog
            .filter { $0.type == .loginFailed }
            .filter { Date().timeIntervalSince($0.timestamp) < 300 } // Last 5 minutes

        if recentFailedLogins.count > 5 {
            alertBruteForceAttempt()
        }

        // Check for unusual data access patterns
        let recentDataAccess = eventLog
            .filter { $0.type == .dataAccess }
            .filter { Date().timeIntervalSince($0.timestamp) < 3600 } // Last hour

        if recentDataAccess.count > 100 {
            alertUnusualDataAccess()
        }
    }

    private func alertBruteForceAttempt() {
        // Send alert to security team
        print("🚨 SECURITY ALERT: Potential brute force attack detected")
    }

    private func alertUnusualDataAccess() {
        // Send alert to security team
        print("🚨 SECURITY ALERT: Unusual data access pattern detected")
    }
}

struct SecurityEvent {
    let type: SecurityEventType
    let userId: String?
    let ipAddress: String?
    let userAgent: String?
    let details: [String: Any]
    let timestamp: Date
}

enum SecurityEventType {
    case loginSuccess
    case loginFailed
    case dataAccess
    case dataModification
    case exportPerformed
    case settingsChanged
    case suspiciousActivity
}
```

### Audit Logging

#### Comprehensive Audit Trail
```swift
class AuditLogger {
    static let shared = AuditLogger()

    private let logQueue = DispatchQueue(label: "audit.logger")
    private var currentLogFile: URL?

    func logAuditEvent(
        action: AuditAction,
        resource: String,
        userId: String? = nil,
        details: [String: Any] = [:]
    ) {
        logQueue.async {
            let event = AuditEvent(
                id: UUID(),
                timestamp: Date(),
                action: action,
                resource: resource,
                userId: userId,
                details: details,
                ipAddress: self.getIPAddress(),
                userAgent: self.getUserAgent()
            )

            self.writeEventToLog(event)
            self.rotateLogIfNeeded()
        }
    }

    private func writeEventToLog(_ event: AuditEvent) {
        let logFile = getCurrentLogFile()
        let logEntry = """
        [\(event.timestamp)] \(event.action.rawValue) - \(event.resource)
        User: \(event.userId ?? "Unknown")
        IP: \(event.ipAddress ?? "Unknown")
        Details: \(event.details)
        ---

        """

        do {
            try logEntry.append(to: logFile)
        } catch {
            print("Failed to write audit log: \(error)")
        }
    }

    private func getCurrentLogFile() -> URL {
        if let current = currentLogFile {
            return current
        }

        let logsDir = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("StickyNotes").appendingPathComponent("AuditLogs")

        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())

        let logFile = logsDir.appendingPathComponent("audit-\(dateString).log")
        currentLogFile = logFile

        return logFile
    }

    private func rotateLogIfNeeded() {
        guard let logFile = currentLogFile else { return }

        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: logFile.path)
            let fileSize = attributes[.size] as? Int64 ?? 0

            // Rotate if file is larger than 10MB
            if fileSize > 10 * 1024 * 1024 {
                let rotatedFile = logFile.deletingPathExtension()
                    .appendingPathExtension("log.\(Date().timeIntervalSince1970)")

                try FileManager.default.moveItem(at: logFile, to: rotatedFile)
                currentLogFile = nil
            }
        } catch {
            print("Failed to check log file size: \(error)")
        }
    }

    private func getIPAddress() -> String? {
        // Implementation to get IP address
        return nil
    }

    private func getUserAgent() -> String? {
        // Implementation to get user agent
        return nil
    }
}

struct AuditEvent {
    let id: UUID
    let timestamp: Date
    let action: AuditAction
    let resource: String
    let userId: String?
    let details: [String: Any]
    let ipAddress: String?
    let userAgent: String?
}

enum AuditAction: String {
    case create = "CREATE"
    case read = "READ"
    case update = "UPDATE"
    case delete = "DELETE"
    case export = "EXPORT"
    case login = "LOGIN"
    case logout = "LOGOUT"
    case settingsChange = "SETTINGS_CHANGE"
}
```

## 🔍 Security Testing

### Automated Security Testing

#### Static Application Security Testing (SAST)
```swift
class SecurityTestSuite: XCTestCase {
    func testNoHardcodedSecrets() throws {
        let sourceFiles = try findSourceFiles()

        for file in sourceFiles {
            let content = try String(contentsOf: file)

            // Check for hardcoded API keys
            XCTAssertFalse(
                content.contains("api_key") || content.contains("API_KEY"),
                "Potential hardcoded API key in \(file.lastPathComponent)"
            )

            // Check for hardcoded passwords
            XCTAssertFalse(
                content.contains("password") && content.contains("="),
                "Potential hardcoded password in \(file.lastPathComponent)"
            )
        }
    }

    func testSecureFilePermissions() throws {
        let appURL = Bundle.main.bundleURL

        let attributes = try FileManager.default.attributesOfItem(atPath: appURL.path)
        let permissions = attributes[.posixPermissions] as? Int ?? 0

        // Ensure app is not world-writable
        XCTAssertEqual(permissions & 0o022, 0, "App has insecure permissions")
    }

    func testInputValidation() throws {
        let validator = InputValidator.shared

        // Test path traversal prevention
        XCTAssertThrowsError(try validator.validateFilePath("/etc/passwd"))
        XCTAssertThrowsError(try validator.validateFilePath("../../etc/passwd"))

        // Test SQL injection prevention (if applicable)
        XCTAssertThrowsError(try validator.validateNoteTitle("'; DROP TABLE notes; --"))
    }

    private func findSourceFiles() throws -> [URL] {
        let fileManager = FileManager.default
        let sourcesURL = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources")

        guard fileManager.fileExists(atPath: sourcesURL.path) else {
            return []
        }

        return try fileManager.subpathsOfDirectory(atPath: sourcesURL.path)
            .filter { $0.hasSuffix(".swift") }
            .map { sourcesURL.appendingPathComponent($0) }
    }
}
```

#### Penetration Testing
```swift
class PenetrationTestSuite: XCTestCase {
    func testDataEncryption() throws {
        let encryptionManager = DataEncryptionManager.shared
        let testData = "Sensitive note content".data(using: .utf8)!

        // Test encryption/decryption roundtrip
        let encrypted = try encryptionManager.encrypt(testData)
        let decrypted = try encryptionManager.decrypt(encrypted)

        XCTAssertEqual(testData, decrypted)
        XCTAssertNotEqual(testData, encrypted)
    }

    func testKeychainSecurity() throws {
        let keychain = KeychainManager.shared
        let testKey = "test_key"
        let testData = "test_data".data(using: .utf8)!

        // Test keychain storage
        try keychain.set(testData, for: testKey)
        let retrieved = try keychain.getData(for: testKey)

        XCTAssertEqual(testData, retrieved)

        // Clean up
        try keychain.delete(for: testKey)
    }

    func testSecureFileOperations() throws {
        let secureFileManager = SecureFileManager.shared
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let testData = "Secure file content".data(using: .utf8)!

        // Test secure write
        try secureFileManager.secureWrite(testData, to: tempURL)
        let readData = try secureFileManager.secureRead(from: tempURL)

        XCTAssertEqual(testData, readData)

        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }
}
```

## 📋 Security Checklist

### Development Security Checklist
- [ ] All sensitive data is encrypted
- [ ] Input validation prevents injection attacks
- [ ] Secure coding practices followed
- [ ] No hardcoded secrets in code
- [ ] Proper error handling without information leakage
- [ ] Secure file permissions set
- [ ] Code signing implemented
- [ ] Notarization completed

### Operational Security Checklist
- [ ] Regular security updates applied
- [ ] Security monitoring active
- [ ] Audit logging enabled
- [ ] Access controls configured
- [ ] Backup security verified
- [ ] Incident response plan tested
- [ ] Security training completed

### Compliance Checklist
- [ ] Data protection regulations followed
- [ ] Privacy policy updated
- [ ] Security assessments completed
- [ ] Penetration testing performed
- [ ] Compliance documentation maintained
- [ ] Third-party security verified

---

*This security guide ensures StickyNotes maintains high security standards through comprehensive security practices, monitoring, and testing procedures.*