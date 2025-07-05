#!/bin/bash

# Repository Cleanup Script
# Cleans and optimizes repository structure and files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DRY_RUN=false
BACKUP_FILES=true
CLEAN_CACHE=true
OPTIMIZE_IMAGES=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --no-backup)
            BACKUP_FILES=false
            shift
            ;;
        --no-cache-clean)
            CLEAN_CACHE=false
            shift
            ;;
        --no-image-opt)
            OPTIMIZE_IMAGES=false
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --dry-run        Show what would be cleaned without doing it"
            echo "  --no-backup      Don't create backup files"
            echo "  --no-cache-clean Don't clean cache directories"
            echo "  --no-image-opt   Don't optimize images"
            echo "  -h, --help      Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Counter for results
TOTAL_CLEANED=0
TOTAL_OPTIMIZED=0
TOTAL_REMOVED=0

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_action() {
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY RUN] $1${NC}"
    else
        echo -e "${GREEN}$1${NC}"
    fi
}

backup_file() {
    if [ "$BACKUP_FILES" = true ] && [ "$DRY_RUN" = false ]; then
        local file="$1"
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup" 2>/dev/null || true
        log_info "Backed up: $file -> $backup"
    fi
}

# Start cleanup
echo "🧹 Repository Cleanup Started"
echo "==========================="

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}🔍 DRY RUN MODE - No files will be modified${NC}"
fi

# 1. Clean temporary files
echo ""
echo "🗑️ Cleaning Temporary Files"
echo "-------------------------"

# Clean common temporary files
temp_patterns=(
    "*.tmp"
    "*.temp"
    "*.bak"
    "*.backup.*"
    "*.swp"
    "*.swo"
    "*~"
    ".DS_Store"
    "Thumbs.db"
    "*.log"
    "*.out"
)

for pattern in "${temp_patterns[@]}"; do
    files_found=$(find . -name "$pattern" -not -path "./.git/*" -not -path "./archive/*" 2>/dev/null)
    if [ -n "$files_found" ]; then
        while IFS= read -r file; do
            if [ -f "$file" ]; then
                log_action "Removing temporary file: $file"
                if [ "$DRY_RUN" = false ]; then
                    rm "$file"
                    ((TOTAL_REMOVED++))
                fi
                ((TOTAL_CLEANED++))
            fi
        done <<< "$files_found"
    fi
done

# 2. Clean cache directories
if [ "$CLEAN_CACHE" = true ]; then
    echo ""
    echo "🗂️ Cleaning Cache Directories"
    echo "-----------------------------"
    
    cache_dirs=(
        ".build"
        "build"
        "dist"
        "node_modules/.cache"
        ".spm-build"
        "DerivedData"
        "*.xcworkspace/xcuserdata"
        "*.xcodeproj/xcuserdata"
        "Carthage/Build"
        "Pods/build"
    )
    
    for dir_pattern in "${cache_dirs[@]}"; do
        dirs_found=$(find . -name "$dir_pattern" -type d 2>/dev/null)
        if [ -n "$dirs_found" ]; then
            while IFS= read -r dir; do
                if [ -d "$dir" ]; then
                    log_action "Removing cache directory: $dir"
                    if [ "$DRY_RUN" = false ]; then
                        rm -rf "$dir"
                        ((TOTAL_REMOVED++))
                    fi
                    ((TOTAL_CLEANED++))
                fi
            done <<< "$dirs_found"
        fi
    done
fi

# 3. Clean backup files (keep only 5 most recent per file)
echo ""
echo "💾 Cleaning Backup Files"
echo "----------------------"

# Find backup files and keep only 5 most recent per original file
find . -name "*.backup.*" -not -path "./.git/*" -not -path "./archive/*" | while read -r backup_file; do
    if [ -f "$backup_file" ]; then
        # Extract original filename
        original_file=$(echo "$backup_file" | sed 's/\.backup\.[0-9]*_[0-9]*$//')
        
        # Count existing backups for this file
        backup_count=$(find . -name "$(basename "$original_file").backup.*" | wc -l)
        
        if [ $backup_count -gt 5 ]; then
            # Find oldest backup and remove it
            oldest_backup=$(find . -name "$(basename "$original_file").backup.*" -printf '%T@ %p\n' | sort -n | head -1 | cut -d' ' -f2-)
            if [ -f "$oldest_backup" ]; then
                log_action "Removing old backup: $oldest_backup"
                if [ "$DRY_RUN" = false ]; then
                    rm "$oldest_backup"
                    ((TOTAL_REMOVED++))
                fi
                ((TOTAL_CLEANED++))
            fi
        fi
    fi
done

# 4. Optimize images
if [ "$OPTIMIZE_IMAGES" = true ]; then
    echo ""
    echo "🖼️ Optimizing Images"
    echo "-------------------"
    
    # Find image files
    image_files=$(find . -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" | grep -v ".git" | grep -v "archive")
    
    while IFS= read -r image_file; do
        if [ -f "$image_file" ]; then
            file_size=$(stat -f%z "$image_file" 2>/dev/null || stat -c%s "$image_file" 2>/dev/null)
            
            # Check if image is larger than 100KB
            if [ "$file_size" -gt 102400 ]; then
                log_action "Optimizing large image: $image_file ($(echo "scale=2; $file_size/1024" | bc)KB)"
                
                if [ "$DRY_RUN" = false ]; then
                    backup_file "$image_file"
                    
                    # Try to optimize with available tools
                    if command -v sips &> /dev/null; then
                        # macOS image optimization
                        sips -Z 1920 "$image_file" --out "${image_file}.opt" 2>/dev/null || true
                        if [ -f "${image_file}.opt" ] && [ $(stat -f%z "${image_file}.opt") -lt $file_size ]; then
                            mv "${image_file}.opt" "$image_file"
                            ((TOTAL_OPTIMIZED++))
                        else
                            rm -f "${image_file}.opt"
                        fi
                    elif command -v convert &> /dev/null; then
                        # ImageMagick optimization
                        convert "$image_file" -resize 1920x1920\> -quality 85 "${image_file}.opt" 2>/dev/null || true
                        if [ -f "${image_file}.opt" ] && [ $(stat -c%s "${image_file}.opt") -lt $file_size ]; then
                            mv "${image_file}.opt" "$image_file"
                            ((TOTAL_OPTIMIZED++))
                        else
                            rm -f "${image_file}.opt"
                        fi
                    fi
                fi
                ((TOTAL_CLEANED++))
            fi
        fi
    done <<< "$image_files"
fi

# 5. Clean duplicate files
echo ""
echo "🔄 Finding Duplicate Files"
echo "------------------------"

# Find duplicate files by content hash
find . -type f -not -path "./.git/*" -not -path "./archive/*" -not -name "*.backup.*" | while read -r file; do
    if [ -f "$file" ]; then
        # Generate content hash
        file_hash=$(md5sum "$file" 2>/dev/null | cut -d' ' -f1 || md5 -q "$file" 2>/dev/null)
        
        if [ -n "$file_hash" ]; then
            # Check if we've seen this hash before
            if grep -q "$file_hash" /tmp/duplicate_hashes.txt 2>/dev/null; then
                # Find the original file with this hash
                original_file=$(grep "$file_hash" /tmp/duplicate_hashes.txt | cut -d':' -f2- | head -1)
                
                if [ "$file" != "$original_file" ]; then
                    log_action "Found duplicate: $file (same as $original_file)"
                    
                    if [ "$DRY_RUN" = false ]; then
                        # Move duplicate to archive
                        mkdir -p archive/duplicates
                        mv "$file" "archive/duplicates/$(basename "$file").duplicate.$(date +%Y%m%d_%H%M%S)"
                        ((TOTAL_REMOVED++))
                    fi
                    ((TOTAL_CLEANED++))
                fi
            else
                echo "$file_hash:$file" >> /tmp/duplicate_hashes.txt
            fi
        fi
    fi
done

# Clean up temporary hash file
rm -f /tmp/duplicate_hashes.txt

# 6. Optimize file structure
echo ""
echo "📁 Optimizing File Structure"
echo "---------------------------"

# Check for empty directories
empty_dirs=$(find . -type d -empty -not -path "./.git/*" 2>/dev/null)
if [ -n "$empty_dirs" ]; then
    while IFS= read -r dir; do
        log_action "Removing empty directory: $dir"
        if [ "$DRY_RUN" = false ]; then
            rmdir "$dir"
            ((TOTAL_REMOVED++))
        fi
        ((TOTAL_CLEANED++))
    done <<< "$empty_dirs"
fi

# Check for misnamed files
misnamed_files=$(find . -name "* *" -o -name "*:*" 2>/dev/null | grep -v ".git" | grep -v "archive")
if [ -n "$misnamed_files" ]; then
    while IFS= read -r file; do
        if [ -f "$file" ] || [ -d "$file" ]; then
            log_action "Found misnamed file: $file"
            # Note: We don't automatically rename these as it could break things
            ((TOTAL_CLEANED++))
        fi
    done <<< "$misnamed_files"
fi

# 7. Clean up line endings
echo ""
echo "🔧 Fixing Line Endings"
echo "----------------------"

# Find text files with mixed line endings
text_files=$(find . -name "*.md" -o -name "*.swift" -o -name "*.yml" -o -name "*.yaml" -o -name "*.json" | grep -v ".git" | grep -v "archive")

while IFS= read -r file; do
    if [ -f "$file" ]; then
        # Check for Windows line endings
        if file "$file" | grep -q "CRLF"; then
            log_action "Fixing Windows line endings in: $file"
            
            if [ "$DRY_RUN" = false ]; then
                backup_file "$file"
                # Convert to Unix line endings
                tr -d '\r' < "$file" > "${file}.tmp"
                mv "${file}.tmp" "$file"
                ((TOTAL_OPTIMIZED++))
            fi
            ((TOTAL_CLEANED++))
        fi
    fi
done <<< "$text_files"

# 8. Clean up whitespace
echo ""
echo "🧹 Cleaning Whitespace"
echo "---------------------"

# Find files with trailing whitespace
files_with_trailing_ws=$(grep -r -l "[[:space:]]$" --include="*.swift" --include="*.md" . | grep -v ".git" | grep -v "archive" 2>/dev/null)

if [ -n "$files_with_trailing_ws" ]; then
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            log_action "Removing trailing whitespace from: $file"
            
            if [ "$DRY_RUN" = false ]; then
                backup_file "$file"
                # Remove trailing whitespace
                sed -i '' 's/[[:space:]]*$//' "$file"
                ((TOTAL_OPTIMIZED++))
            fi
            ((TOTAL_CLEANED++))
        fi
    done <<< "$files_with_trailing_ws"
fi

# 9. Optimize repository size
echo ""
echo "📊 Repository Size Analysis"
echo "------------------------"

# Get repository size before cleanup
if [ "$DRY_RUN" = false ]; then
    repo_size_before=$(du -sh . | cut -f1)
    log_info "Repository size after cleanup: $repo_size_before"
    
    # Count files by type
    swift_files=$(find . -name "*.swift" -not -path "./.git/*" | wc -l)
    md_files=$(find . -name "*.md" -not -path "./.git/*" | wc -l)
    image_files=$(find . -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -not -path "./.git/*" | wc -l)
    
    echo "File statistics:"
    echo "- Swift files: $swift_files"
    echo "- Markdown files: $md_files"
    echo "- Image files: $image_files"
fi

# 10. Generate cleanup report
echo ""
echo "📋 Cleanup Report"
echo "================="

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}DRY RUN SUMMARY:${NC}"
    echo "- Items that would be cleaned: $TOTAL_CLEANED"
    echo "- Items that would be optimized: $TOTAL_OPTIMIZED"
    echo "- Items that would be removed: $TOTAL_REMOVED"
else
    echo -e "${GREEN}CLEANUP COMPLETED:${NC}"
    echo "- Items cleaned: $TOTAL_CLEANED"
    echo "- Items optimized: $TOTAL_OPTIMIZED"
    echo "- Items removed: $TOTAL_REMOVED"
    
    # Create cleanup log
    echo "# Repository Cleanup Log - $(date)" > cleanup-log.md
    echo "" >> cleanup-log.md
    echo "## Summary" >> cleanup-log.md
    echo "- Items cleaned: $TOTAL_CLEANED" >> cleanup-log.md
    echo "- Items optimized: $TOTAL_OPTIMIZED" >> cleanup-log.md
    echo "- Items removed: $TOTAL_REMOVED" >> cleanup-log.md
    echo "" >> cleanup-log.md
    echo "## Actions Performed" >> cleanup-log.md
    echo "- Removed temporary files" >> cleanup-log.md
    echo "- Cleaned cache directories" >> cleanup-log.md
    echo "- Optimized images" >> cleanup-log.md
    echo "- Fixed line endings" >> cleanup-log.md
    echo "- Removed trailing whitespace" >> cleanup-log.md
    echo "- Removed empty directories" >> cleanup-log.md
    
    log_success "Cleanup log saved to cleanup-log.md"
fi

# Recommendations
echo ""
echo "💡 Recommendations"
echo "=================="

if [ $TOTAL_CLEANED -gt 0 ]; then
    echo "✅ Repository cleanup completed successfully"
    echo "📈 Consider running this cleanup regularly"
    echo "🔍 Review the changes before committing"
fi

if [ $TOTAL_OPTIMIZED -gt 0 ]; then
    echo "🎨 Some files were optimized for better performance"
    echo "📊 Test the optimized files to ensure they work correctly"
fi

if [ $TOTAL_REMOVED -gt 0 ]; then
    echo "🗑️ Unnecessary files were removed"
    echo "💾 Check the archive/ directory for removed files"
fi

echo "🔄 Consider setting up a pre-commit hook to prevent future issues"
echo "📋 Add this cleanup script to your CI/CD pipeline"

# Final message
echo ""
if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}🔍 DRY RUN COMPLETED - No files were modified${NC}"
    echo "Run without --dry-run to perform the actual cleanup"
else
    echo -e "${GREEN}🎉 Repository cleanup completed successfully!${NC}"
fi

exit 0