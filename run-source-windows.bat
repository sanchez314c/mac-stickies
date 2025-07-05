@echo off
:: Run StickyNotes from Source on Windows
:: NOTE: StickyNotes is a macOS-only Swift/SwiftUI application.
:: Windows is NOT supported. This file exists for repository compliance only.

echo ============================================================
echo  StickyNotes - macOS Only Application
echo ============================================================
echo.
echo  ERROR: This application requires macOS 13.0+ (Ventura or later).
echo.
echo  StickyNotes is a native macOS desktop application built with:
echo    - Swift 5.10
echo    - SwiftUI
echo    - AppKit
echo    - Core Data + CloudKit
echo    - Xcode 15+
echo.
echo  Windows is NOT supported.
echo.
echo  To build and run StickyNotes:
echo    1. Use a Mac running macOS 13.0 or later
echo    2. Install Xcode 15+ from the Mac App Store
echo    3. Run: ./run-source-mac.sh
echo.
echo  GitHub: https://github.com/sanchez314c/desktop-stickies
echo ============================================================
echo.
pause
exit /b 1
