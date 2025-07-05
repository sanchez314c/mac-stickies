# CI/CD Setup Guide

Complete setup guide for configuring automated deployment pipelines for StickyNotes.

## 🔐 Required Secrets & Environment Variables

### GitHub Repository Secrets

Configure these secrets in your GitHub repository settings under "Secrets and variables" → "Actions":

#### Apple Developer Account
```bash
APPLE_ID=your-apple-developer-email@example.com
APPLE_APP_SPECIFIC_PASSWORD=abcd-efgh-ijkl-mnop
APPLE_TEAM_ID=ABC123DEF4
APPLE_TEAM_NAME="Your Team Name"
APPLE_ITC_TEAM_ID=123456789
```

#### Code Signing Certificates
```bash
# Base64 encoded certificates
DEVELOPER_CERTIFICATE=<base64-encoded-developer-id-certificate>
DEVELOPER_CERTIFICATE_PASSWORD=certificate-password

APP_STORE_CERTIFICATE=<base64-encoded-app-store-certificate>
APP_STORE_CERTIFICATE_PASSWORD=certificate-password
```

#### App Store Connect API
```bash
APP_STORE_CONNECT_PRIVATE_KEY=<base64-encoded-private-key>
APP_STORE_CONNECT_KEY_ID=ABC123DEF4
APP_STORE_CONNECT_ISSUER_ID=12345678-1234-1234-1234-123456789012
```

#### Certificate Match Repository (Optional)
```bash
MATCH_PASSWORD=match-repository-password
MATCH_GIT_URL=https://github.com/your-org/certificates.git
```

### Environment Variables

#### Build Configuration
```bash
APP_NAME=StickyNotes
BUNDLE_ID=com.superclaude.stickynotes
TEAM_ID=ABC123DEF4
```

#### CI/CD Settings
```bash
CI_MODE=true
BRANCH_NAME=main
COMMIT_SHA=<current-commit-sha>
PR_NUMBER=<pull-request-number>
```

## 🏗️ Certificate Setup

### Method 1: Manual Certificate Export

1. **Export Developer ID Certificate**:
   ```bash
   security export -f pkcs12 \
     -k ~/Library/Keychains/login.keychain \
     -t identities \
     -o developer_id.p12 \
     -P "certificate-password"
   ```

2. **Export App Store Certificate**:
   ```bash
   security export -f pkcs12 \
     -k ~/Library/Keychains/login.keychain \
     -t identities \
     -o app_store.p12 \
     -P "certificate-password"
   ```

3. **Convert to Base64 for GitHub Secrets**:
   ```bash
   # Developer Certificate
   base64 -i developer_id.p12 | pbcopy

   # App Store Certificate
   base64 -i app_store.p12 | pbcopy
   ```

### Method 2: Fastlane Match (Recommended)

1. **Initialize Match Repository**:
   ```bash
   fastlane match init
   # Select 'git' storage mode
   # Enter your certificates repository URL
   ```

2. **Store Certificates in Match**:
   ```bash
   # Development certificate
   fastlane match development

   # App Store certificate
   fastlane match appstore

   # Mac Installer certificate (for direct distribution)
   fastlane match mac_installer_distribution
   ```

3. **Configure Match Password**:
   ```bash
   # Set MATCH_PASSWORD secret in GitHub
   echo "your-match-password" | base64
   ```

## 🔧 Fastlane Configuration

### Appfile Setup
```ruby
# fastlane/Appfile
app_identifier "com.superclaude.stickynotes"
apple_id ENV["APPLE_ID"]
team_id ENV["APPLE_TEAM_ID"]
itc_team_id ENV["APPLE_ITC_TEAM_ID"]
```

### Matchfile Setup
```ruby
# fastlane/Matchfile
git_url ENV["MATCH_GIT_URL"]
storage_mode "git"
type "appstore"
app_identifier "com.superclaude.stickynotes"
username ENV["APPLE_ID"]
team_id ENV["APPLE_TEAM_ID"]
team_name ENV["APPLE_TEAM_NAME"]

additional_cert_types ["mac_installer_distribution"]
platform "macos"
```

## 🚀 GitHub Actions Setup

### Required Permissions

Ensure your GitHub Actions workflow has these permissions:

```yaml
permissions:
  contents: write  # For creating releases
  packages: write  # For package registry
  id-token: write  # For App Store Connect authentication
```

### Workflow Triggers

```yaml
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  release:
    types: [ published ]
  workflow_dispatch:  # Manual trigger
```

## 📋 Setup Checklist

### Pre-Setup
- [ ] Apple Developer Program account with Team ID
- [ ] App Store Connect app record created
- [ ] App-specific password generated
- [ ] App Store Connect API key created
- [ ] GitHub repository with Actions enabled

### Certificate Setup
- [ ] Developer ID certificate exported/created
- [ ] App Store certificate exported/created
- [ ] Certificates converted to base64
- [ ] Match repository initialized (optional)

### GitHub Secrets
- [ ] APPLE_ID configured
- [ ] APPLE_APP_SPECIFIC_PASSWORD configured
- [ ] APPLE_TEAM_ID configured
- [ ] DEVELOPER_CERTIFICATE configured
- [ ] APP_STORE_CERTIFICATE configured
- [ ] APP_STORE_CONNECT_PRIVATE_KEY configured
- [ ] APP_STORE_CONNECT_KEY_ID configured
- [ ] APP_STORE_CONNECT_ISSUER_ID configured

### Fastlane Configuration
- [ ] Appfile updated with correct identifiers
- [ ] Matchfile configured (if using Match)
- [ ] Fastlane lanes tested locally

### CI/CD Pipeline
- [ ] GitHub Actions workflow configured
- [ ] Workflow permissions set correctly
- [ ] Branch protection rules configured
- [ ] Quality gates integrated

## 🧪 Testing the Setup

### Local Testing
```bash
# Test Fastlane setup
fastlane test

# Test certificate import
fastlane build_development

# Test App Store build
fastlane build_app_store

# Test direct distribution build
fastlane build_direct
```

### CI/CD Testing
1. **Push to develop branch**: Triggers quality gates and development build
2. **Create pull request**: Triggers full test suite and quality checks
3. **Merge to main**: Triggers staging deployment
4. **Create release**: Triggers production deployment to both channels

## 🔍 Troubleshooting

### Common Issues

#### Certificate Import Failures
```bash
# Check certificate format
openssl pkcs12 -info -in certificate.p12

# Verify base64 encoding
echo "$DEVELOPER_CERTIFICATE" | base64 -d > test.p12
```

#### App Store Connect Upload Issues
```bash
# Check API key permissions
xcrun altool --list-providers -u "$APPLE_ID" -p "$APPLE_APP_SPECIFIC_PASSWORD"

# Verify app record exists
xcrun altool --list-apps -u "$APPLE_ID" -p "$APPLE_APP_SPECIFIC_PASSWORD"
```

#### Notarization Problems
```bash
# Check notarization status
xcrun notarytool log <submission-id> --apple-id "$APPLE_ID" --password "$APPLE_APP_SPECIFIC_PASSWORD" --team-id "$TEAM_ID"
```

### Debug Commands
```bash
# List available certificates
security find-identity -v -p codesigning

# Check keychain access
security list-keychains

# Test App Store Connect connection
xcrun altool --validate-app -f "path/to/app.pkg" -u "$APPLE_ID" -p "$APPLE_APP_SPECIFIC_PASSWORD"
```

## 📊 Monitoring & Alerts

### Deployment Status Monitoring
- GitHub Actions workflow status
- Fastlane output logs
- App Store Connect build status
- Notarization status tracking

### Alert Configuration
```yaml
# Slack notifications (future enhancement)
- name: Notify Slack
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: failure
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

---

*This CI/CD setup guide ensures secure, automated deployment of StickyNotes to both Mac App Store and direct distribution channels.*