# Security Policy

## Supported Versions

We actively support the following versions with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability in Desktop Stickies, please help us by reporting it responsibly.

### How to Report

1. **Do not** create a public GitHub issue for the vulnerability
2. Email security concerns to: security@stickynotes.app
3. Alternatively, use the "Report a security vulnerability" button in GitHub Security tab
4. Include detailed information about the vulnerability

### What to Include

- A clear description of the vulnerability
- Steps to reproduce the issue
- Potential impact and severity assessment
- Any suggested fixes or mitigations
- Your contact information for follow-up

### Our Response Process

1. **Acknowledgment**: We will acknowledge receipt within 48 hours
2. **Investigation**: We will investigate and validate the vulnerability
3. **Updates**: We will provide regular updates on our progress
4. **Fix**: We will develop and test a fix
5. **Disclosure**: We will coordinate disclosure with you

## Security Considerations

Desktop Stickies is a native macOS application with the following security properties:

### Application Security
- **App Sandbox**: The application runs in a sandboxed environment
- **Hardened Runtime**: Enhanced runtime security enabled
- **Code Signing**: All releases are code-signed
- **Data Storage**: Notes stored locally via Core Data with encryption at rest

### Platform Security
- **macOS Security Framework**: Leverages macOS security features
- **CloudKit**: Secure sync via Apple's CloudKit infrastructure
- **Keychain**: Sensitive data stored in macOS Keychain
- **Entitlements**: Minimal entitlements following principle of least privilege

## Responsible Disclosure

We kindly ask that you:
- Give us reasonable time to fix the issue before public disclosure
- Avoid accessing or modifying user data without permission
- Do not perform DoS attacks or degrade service availability
- Respect user privacy and data protection

Thank you for helping keep Desktop Stickies secure.
