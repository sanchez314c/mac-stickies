# Makefile for StickyNotes Testing Framework
# Provides convenient commands for running tests and quality checks

.PHONY: all test test-unit test-integration test-ui test-performance clean lint format coverage help

# Default target
all: lint test coverage

# Test targets
test: test-unit test-integration test-ui test-performance

test-unit:
	@echo "Running unit tests..."
	swift test --filter StickyNotesTests

test-integration:
	@echo "Running integration tests..."
	swift test --filter StickyNotesIntegrationTests

test-ui:
	@echo "Running UI tests..."
	xcodebuild test -scheme StickyNotesUITests -destination 'platform=macOS' -quiet

test-performance:
	@echo "Running performance tests..."
	swift test --filter StickyNotesPerformanceTests

# Code quality
lint:
	@echo "Running SwiftLint..."
	swiftlint lint --strict --quiet

format:
	@echo "Running SwiftFormat..."
	swiftformat .

lint-fix:
	@echo "Running SwiftLint with auto-fix..."
	swiftlint autocorrect

# Coverage
coverage:
	@echo "Running tests with coverage..."
	swift test --enable-code-coverage
	@echo "Coverage report generated in .build/debug/codecov/"

# Xcode integration
xcode-test:
	@echo "Running all tests in Xcode..."
	xcodebuild test -scheme StickyNotes -destination 'platform=macOS' -enableCodeCoverage YES

xcode-clean:
	@echo "Cleaning Xcode build artifacts..."
	xcodebuild clean -scheme StickyNotes

# CI/CD simulation
ci: lint format test coverage
	@echo "CI pipeline completed successfully"

# Development helpers
setup:
	@echo "Setting up development environment..."
	brew install swiftlint
	brew install swiftformat

clean:
	@echo "Cleaning build artifacts..."
	rm -rf .build/
	rm -rf .swiftpm/
	rm -rf *.xcresult

# Performance monitoring
profile:
	@echo "Running performance profiling..."
	swift test --filter StickyNotesPerformanceTests -v

# Accessibility testing
accessibility:
	@echo "Running accessibility-focused tests..."
	xcodebuild test -scheme StickyNotesUITests -destination 'platform=macOS' -test-iterations 3

# Help
help:
	@echo "StickyNotes Testing Framework"
	@echo ""
	@echo "Available targets:"
	@echo "  all              - Run linting, all tests, and coverage"
	@echo "  test             - Run all test suites"
	@echo "  test-unit        - Run unit tests only"
	@echo "  test-integration - Run integration tests only"
	@echo "  test-ui          - Run UI tests only"
	@echo "  test-performance - Run performance tests only"
	@echo "  lint             - Run SwiftLint code analysis"
	@echo "  format           - Run SwiftFormat code formatting"
	@echo "  lint-fix         - Auto-fix SwiftLint violations"
	@echo "  coverage         - Generate code coverage report"
	@echo "  xcode-test       - Run tests using Xcode build system"
	@echo "  xcode-clean      - Clean Xcode build artifacts"
	@echo "  ci               - Simulate CI/CD pipeline"
	@echo "  setup            - Install development dependencies"
	@echo "  clean            - Clean all build artifacts"
	@echo "  profile          - Run performance profiling"
	@echo "  accessibility    - Run accessibility-focused tests"
	@echo "  help             - Show this help message"
	@echo ""
	@echo "Quality Gates (from QUALITY_PLAN.md):"
	@echo "  - Unit Tests: 95%+ critical path coverage"
	@echo "  - Integration Tests: 90%+ business logic coverage"
	@echo "  - UI Tests: 70%+ component coverage"
	@echo "  - Performance: Meet all benchmark targets"
	@echo "  - Static Analysis: Zero critical issues"