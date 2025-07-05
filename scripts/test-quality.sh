#!/bin/bash

# Quality Testing Script
# Runs comprehensive quality tests on the codebase

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MIN_COVERAGE=80
MAX_FILE_SIZE_KB=100
MAX_FUNCTION_LENGTH=50
MAX_CYCLOMATIC_COMPLEXITY=10

# Counter for results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNINGS=0

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASSED_TESTS++))
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARNINGS++))
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    ((FAILED_TESTS++))
}

increment_total() {
    ((TOTAL_TESTS++))
}

# Start quality testing
echo "🧪 Quality Testing Started"
echo "========================"

# 1. Build Test
echo ""
echo "🏗️ Build Test"
echo "---------------"

increment_total
log_info "Building project..."
if swift build > /dev/null 2>&1; then
    log_success "Project builds successfully"
else
    log_error "Project build failed"
    swift build
fi

# 2. Test Execution
echo ""
echo "🧪 Test Execution"
echo "------------------"

increment_total
log_info "Running unit tests..."
if swift test > /dev/null 2>&1; then
    log_success "All unit tests pass"
else
    log_error "Some unit tests failed"
    swift test
fi

# 3. Code Coverage
echo ""
echo "📊 Code Coverage"
echo "----------------"

increment_total
log_info "Calculating test coverage..."
if command -v xcrun &> /dev/null; then
    # Try to get coverage information
    if swift test --enable-code-coverage > /dev/null 2>&1; then
        coverage_output=$(swift test --enable-code-coverage 2>&1 | grep -o '[0-9]*%' | head -1 | tr -d '%')
        if [ -n "$coverage_output" ] && [ "$coverage_output" -ge $MIN_COVERAGE ]; then
            log_success "Code coverage: ${coverage_output}% (≥${MIN_COVERAGE}%)"
        elif [ -n "$coverage_output" ]; then
            log_warning "Code coverage: ${coverage_output}% (<${MIN_COVERAGE}%)"
        else
            log_warning "Could not determine coverage percentage"
        fi
    else
        log_warning "Coverage analysis not available"
    fi
else
    log_warning "Xcode tools not available for coverage analysis"
fi

# 4. Code Formatting
echo ""
echo "🎨 Code Formatting"
echo "-----------------"

increment_total
log_info "Checking code formatting..."
if command -v swiftformat &> /dev/null; then
    if swiftformat --lint . > /dev/null 2>&1; then
        log_success "Code formatting is correct"
    else
        log_error "Code formatting issues found"
        swiftformat --lint .
    fi
else
    log_warning "SwiftFormat not installed, skipping formatting check"
fi

# 5. Linting
echo ""
echo "🔍 Linting"
echo "------------"

increment_total
log_info "Running SwiftLint..."
if command -v swiftlint &> /dev/null; then
    if swiftlint --strict > /dev/null 2>&1; then
        log_success "No SwiftLint violations"
    else
        log_error "SwiftLint violations found"
        swiftlint --strict
    fi
else
    log_warning "SwiftLint not installed, skipping linting"
fi

# 6. File Size Analysis
echo ""
echo "📏 File Size Analysis"
echo "---------------------"

increment_total
log_info "Analyzing file sizes..."
large_files=$(find Sources/ -name "*.swift" -size +${MAX_FILE_SIZE_KB}k | wc -l)
if [ $large_files -eq 0 ]; then
    log_success "All files under ${MAX_FILE_SIZE_KB}KB"
else
    log_warning "Found $large_files files over ${MAX_FILE_SIZE_KB}KB"
    find Sources/ -name "*.swift" -size +${MAX_FILE_SIZE_KB}k -exec ls -lh {} \;
fi

# 7. Function Length Analysis
echo ""
echo "📏 Function Length Analysis"
echo "--------------------------"

increment_total
log_info "Analyzing function lengths..."
long_functions=0
for file in Sources/**/*.swift; do
    if [ -f "$file" ]; then
        # Simple function length detection (this is basic)
        func_lengths=$(awk '/func / {start=NR} /^[[:space:]]*}[[:space:]]*$/ {if(start) print NR-start; start=0}' "$file")
        for length in $func_lengths; do
            if [ $length -gt $MAX_FUNCTION_LENGTH ]; then
                ((long_functions++))
            fi
        done
    fi
done

if [ $long_functions -eq 0 ]; then
    log_success "All functions under ${MAX_FUNCTION_LENGTH} lines"
else
    log_warning "Found $long_functions functions over ${MAX_FUNCTION_LENGTH} lines"
fi

# 8. Cyclomatic Complexity
echo ""
echo "🔀 Cyclomatic Complexity"
echo "------------------------"

increment_total
log_info "Analyzing cyclomatic complexity..."
# This is a simplified complexity check
complex_files=0
for file in Sources/**/*.swift; do
    if [ -f "$file" ]; then
        # Count decision points (simplified)
        decision_points=$(grep -c "if\|for\|while\|switch\|case\|&&\|||\|guard" "$file" 2>/dev/null || echo 0)
        if [ $decision_points -gt $MAX_CYCLOMATIC_COMPLEXITY ]; then
            ((complex_files++))
            echo "Complex file: $file ($decision_points decision points)"
        fi
    fi
done

if [ $complex_files -eq 0 ]; then
    log_success "All files under complexity threshold"
else
    log_warning "Found $complex_files complex files"
fi

# 9. Documentation Coverage
echo ""
echo "📚 Documentation Coverage"
echo "------------------------"

increment_total
log_info "Checking documentation coverage..."
undocumented_public=0
total_public=0

for file in Sources/**/*.swift; do
    if [ -f "$file" ]; then
        # Find public declarations
        public_declarations=$(grep -E "public (func|class|struct|enum|var)" "$file" | wc -l)
        documented_declarations=$(grep -E "public (func|class|struct|enum|var)" "$file" -A1 | grep -c "///" || echo 0)
        
        total_public=$((total_public + public_declarations))
        undocumented_public=$((undocumented_public + public_declarations - documented_declarations))
    fi
done

if [ $total_public -gt 0 ]; then
    doc_coverage=$(( (total_public - undocumented_public) * 100 / total_public ))
    if [ $doc_coverage -ge 80 ]; then
        log_success "Documentation coverage: ${doc_coverage}%"
    else
        log_warning "Documentation coverage: ${doc_coverage}% (<80%)"
    fi
else
    log_warning "No public declarations found"
fi

# 10. Dependency Analysis
echo ""
echo "📦 Dependency Analysis"
echo "--------------------"

increment_total
log_info "Analyzing dependencies..."
if [ -f "Package.swift" ]; then
    # Count external dependencies
    external_deps=$(grep -c "\.package(" Package.swift 2>/dev/null || echo 0)
    log_success "Found $external_deps external dependencies"
    
    # Check for outdated dependencies (simplified)
    log_info "Checking for dependency updates..."
    if swift package update > /dev/null 2>&1; then
        log_success "Dependencies can be updated"
    else
        log_warning "Dependency update check failed"
    fi
else
    log_warning "No Package.swift found"
fi

# 11. Security Analysis
echo ""
echo "🔒 Security Analysis"
echo "-------------------"

increment_total
log_info "Running security analysis..."
security_issues=0

# Check for hardcoded secrets
if grep -r -i "password\|secret\|key\|token" Sources/ --include="*.swift" | grep -v "//.*password\|//.*secret\|//.*key\|//.*token" > /dev/null 2>&1; then
    log_error "Potential hardcoded secrets found"
    ((security_issues++))
else
    log_success "No hardcoded secrets detected"
fi

# Check for unsafe functions
unsafe_functions=$(grep -r "eval\|performSelector" Sources/ --include="*.swift" 2>/dev/null | wc -l)
if [ $unsafe_functions -eq 0 ]; then
    log_success "No unsafe functions detected"
else
    log_warning "Found $unsafe_functions potentially unsafe functions"
fi

# 12. Performance Analysis
echo ""
echo "⚡ Performance Analysis"
echo "----------------------"

increment_total
log_info "Running performance analysis..."
if [ -d "Tests/StickyNotesPerformanceTests" ]; then
    if swift test --filter StickyNotesPerformanceTests > /dev/null 2>&1; then
        log_success "Performance tests pass"
    else
        log_warning "Performance tests failed"
    fi
else
    log_warning "No performance tests found"
fi

# Check for potential performance issues
sync_issues=$(grep -r "DispatchQueue.main.async" Sources/ --include="*.swift" | wc -l)
if [ $sync_issues -eq 0 ]; then
    log_success "No obvious main thread sync issues"
else
    log_warning "Found $sync_issues main thread sync calls"
fi

# Results Summary
echo ""
echo "📊 Quality Test Results"
echo "======================="
echo "Total tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"

# Calculate success rate
if [ $TOTAL_TESTS -gt 0 ]; then
    success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo "Success rate: $success_rate%"
else
    echo "No tests were executed"
fi

# Quality Score Calculation
quality_score=$PASSED_TESTS
max_score=$TOTAL_TESTS

if [ $max_score -gt 0 ]; then
    quality_percentage=$((quality_score * 100 / max_score))
    echo "Quality score: $quality_percentage%"
    
    # Quality grade
    if [ $quality_percentage -ge 90 ]; then
        echo -e "${GREEN}🏆 Grade: A+ (Excellent)${NC}"
    elif [ $quality_percentage -ge 80 ]; then
        echo -e "${GREEN}🥇 Grade: A (Very Good)${NC}"
    elif [ $quality_percentage -ge 70 ]; then
        echo -e "${YELLOW}🥈 Grade: B (Good)${NC}"
    elif [ $quality_percentage -ge 60 ]; then
        echo -e "${YELLOW}🥉 Grade: C (Fair)${NC}"
    else
        echo -e "${RED}📉 Grade: D (Needs Improvement)${NC}"
    fi
fi

# Final verdict
echo ""
if [ $FAILED_TESTS -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}🎉 Excellent! All quality tests passed with no issues.${NC}"
        exit 0
    else
        echo -e "${YELLOW}✅ Quality tests passed with $WARNINGS warnings.${NC}"
        echo "Consider addressing warnings for optimal code quality."
        exit 0
    fi
else
    echo -e "${RED}❌ Quality tests failed with $FAILED_TESTS errors.${NC}"
    echo "Please address critical issues before proceeding."
    exit 1
fi