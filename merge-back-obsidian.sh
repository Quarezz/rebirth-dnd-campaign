#!/bin/bash

# Quartz to Obsidian Merge-Back Script
# This script syncs AI-modified content from Quartz back to the Obsidian vault
# It only copies files that were changed in Quartz (detected via git)

# Configuration
QUARTZ_CONTENT="/home/morf/Downloads/quartz/content"
OBSIDIAN_VAULT="/home/morf/Documents/OVault/DND/Campaigns/Rebirth"
MERGE_LOG="/home/morf/Downloads/quartz/.merge-back-log.txt"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_detail() {
    echo -e "${CYAN}  →${NC} $1"
}

print_file() {
    echo -e "${MAGENTA}    ✓${NC} $1"
}

# Check if directories exist
if [ ! -d "$QUARTZ_CONTENT" ]; then
    print_error "Quartz content folder not found at: $QUARTZ_CONTENT"
    exit 1
fi

if [ ! -d "$OBSIDIAN_VAULT" ]; then
    print_error "Obsidian vault not found at: $OBSIDIAN_VAULT"
    exit 1
fi

MERGE_START_TIME=$(date +%s)
echo "═══════════════════════════════════════════════════════"
echo "  Quartz → Obsidian Merge-Back Script"
echo "═══════════════════════════════════════════════════════"
echo ""
print_info "Merge started at: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
print_info "Source: $QUARTZ_CONTENT"
print_info "Destination: $OBSIDIAN_VAULT"
echo ""

# Parse command line arguments
DRY_RUN="--dry-run"
FORCE_MODE=false

for arg in "$@"; do
    case $arg in
        --execute|-e)
            DRY_RUN=""
            print_warning "EXECUTE MODE - Files will be copied!"
            echo ""
            ;;
        --force|-f)
            FORCE_MODE=true
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -e, --execute        Actually copy files (default is dry-run)"
            echo "  -f, --force          Force merge even if there are uncommitted Obsidian changes"
            echo "  -h, --help           Show this help message"
            echo ""
            echo "Default mode is DRY RUN - no files will be copied."
            echo "Run with --execute to actually merge files."
            exit 0
            ;;
    esac
done

if [ -n "$DRY_RUN" ]; then
    print_warning "DRY RUN MODE - No files will be copied"
    print_info "Run with --execute to actually merge files"
    echo ""
fi

# Check Obsidian vault for uncommitted changes (if it's a git repo)
print_info "Checking Obsidian vault status..."
cd "$OBSIDIAN_VAULT"
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_warning "Obsidian vault is not a git repository"
    print_info "Skipping git checks - will proceed with merge"
    echo ""
    IS_GIT_REPO=false
else
    IS_GIT_REPO=true
    OBSIDIAN_STATUS=$(git status --short 2>/dev/null)
    if [ -n "$OBSIDIAN_STATUS" ]; then
        print_warning "Obsidian vault has uncommitted changes:"
        echo ""
        echo "$OBSIDIAN_STATUS" | head -10
        echo ""
        if [ $(echo "$OBSIDIAN_STATUS" | wc -l) -gt 10 ]; then
            print_info "... and $(( $(echo "$OBSIDIAN_STATUS" | wc -l) - 10 )) more"
            echo ""
        fi
        
        if [ "$FORCE_MODE" = false ]; then
            print_error "Refusing to merge with uncommitted changes in Obsidian"
            print_info "Either commit your Obsidian changes first, or use --force flag"
            exit 1
        else
            print_warning "FORCE mode enabled - proceeding despite uncommitted changes"
            echo ""
        fi
    else
        print_success "Obsidian vault is clean"
        echo ""
    fi
fi
cd - > /dev/null

# Detect which files changed in Quartz (using git)
print_info "Detecting files changed in Quartz..."
echo ""

cd "$QUARTZ_CONTENT"

# Get modified and new files, but EXCLUDE Notes/ folder (session notes are source of truth)
MODIFIED_FILES=$(git diff --name-only HEAD 2>/dev/null | grep -E '\.(md|png|jpg|jpeg|gif)$' | grep -v '^Notes/')
UNTRACKED_FILES=$(git ls-files --others --exclude-standard 2>/dev/null | grep -E '\.(md|png|jpg|jpeg|gif)$' | grep -v '^Notes/')

# Combine both lists
ALL_CHANGED_FILES=$(echo -e "$MODIFIED_FILES\n$UNTRACKED_FILES" | grep -v '^$' | sort -u)

# Check if any Notes/ files were excluded
EXCLUDED_NOTES=$(git diff --name-only HEAD 2>/dev/null | grep '^Notes/' | grep -E '\.(md|png|jpg|jpeg|gif)$')
if [ -n "$EXCLUDED_NOTES" ]; then
    EXCLUDED_COUNT=$(echo "$EXCLUDED_NOTES" | wc -l)
    print_warning "Excluded $EXCLUDED_COUNT file(s) from Notes/ folder (source of truth)"
    echo ""
fi

if [ -z "$ALL_CHANGED_FILES" ]; then
    print_info "No modified files detected in Quartz"
    print_info "Nothing to merge back to Obsidian"
    cd - > /dev/null
    exit 0
fi

FILE_COUNT=$(echo "$ALL_CHANGED_FILES" | wc -l)
print_success "Found $FILE_COUNT AI-modified file(s) to merge:"
echo ""

# Show what's being excluded
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_info "📋 Merge Policy:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_success "✓ WILL MERGE: Персонажі/, Локації/, Квести/, Хронологія_подій.md, index.md"
print_warning "✗ EXCLUDED: Notes/ folder (session notes are source of truth)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Categorize files
MODIFIED_COUNT=$(echo "$MODIFIED_FILES" | grep -v '^$' | wc -l)
NEW_COUNT=$(echo "$UNTRACKED_FILES" | grep -v '^$' | wc -l)

if [ $MODIFIED_COUNT -gt 0 ]; then
    print_detail "Modified existing files ($MODIFIED_COUNT):"
    echo "$MODIFIED_FILES" | while IFS= read -r file; do
        if [ -n "$file" ]; then
            print_file "$file"
        fi
    done
    echo ""
fi

if [ $NEW_COUNT -gt 0 ]; then
    print_detail "New files ($NEW_COUNT):"
    echo "$UNTRACKED_FILES" | while IFS= read -r file; do
        if [ -n "$file" ]; then
            print_file "$file"
        fi
    done
    echo ""
fi

cd - > /dev/null

# Prepare merge log
if [ -z "$DRY_RUN" ]; then
    > "$MERGE_LOG"
    echo "# Merge-Back Log - $(date)" >> "$MERGE_LOG"
    echo "# Files merged from Quartz to Obsidian" >> "$MERGE_LOG"
    echo "" >> "$MERGE_LOG"
    echo "$ALL_CHANGED_FILES" >> "$MERGE_LOG"
fi

# Perform the merge using rsync for each file
print_info "Starting merge-back..."
echo ""

if [ -n "$DRY_RUN" ]; then
    print_detail "DRY RUN - Showing what would be copied:"
else
    print_detail "Copying files to Obsidian vault..."
fi
echo ""

COPIED_COUNT=0
ERROR_COUNT=0

while IFS= read -r file; do
    if [ -n "$file" ]; then
        SOURCE_FILE="$QUARTZ_CONTENT/$file"
        DEST_FILE="$OBSIDIAN_VAULT/$file"
        
        if [ ! -f "$SOURCE_FILE" ]; then
            print_warning "Source file not found: $file"
            ((ERROR_COUNT++))
            continue
        fi
        
        # Create destination directory if needed
        DEST_DIR=$(dirname "$DEST_FILE")
        if [ -z "$DRY_RUN" ]; then
            mkdir -p "$DEST_DIR"
        fi
        
        # Check if destination file exists and is different
        if [ -f "$DEST_FILE" ]; then
            if cmp -s "$SOURCE_FILE" "$DEST_FILE"; then
                print_detail "Skipping (identical): $file"
                continue
            else
                if [ -n "$DRY_RUN" ]; then
                    print_file "[UPDATE] $file"
                else
                    cp "$SOURCE_FILE" "$DEST_FILE"
                    print_file "[UPDATED] $file"
                fi
                ((COPIED_COUNT++))
            fi
        else
            if [ -n "$DRY_RUN" ]; then
                print_file "[NEW] $file"
            else
                cp "$SOURCE_FILE" "$DEST_FILE"
                print_file "[CREATED] $file"
            fi
            ((COPIED_COUNT++))
        fi
    fi
done <<< "$ALL_CHANGED_FILES"

echo ""
echo "═══════════════════════════════════════════════════════"

# Summary
if [ -n "$DRY_RUN" ]; then
    print_success "Dry run completed successfully!"
    echo ""
    print_warning "This was a DRY RUN - no actual changes were made"
    print_info "Would merge $COPIED_COUNT file(s)"
    echo ""
    print_info "Run with --execute to actually merge files:"
    print_file "./merge-back-obsidian.sh --execute"
else
    print_success "✓ Merge-back completed successfully!"
    echo ""
    
    if [ $COPIED_COUNT -gt 0 ]; then
        print_success "$COPIED_COUNT file(s) were merged to Obsidian"
        if [ $ERROR_COUNT -gt 0 ]; then
            print_warning "$ERROR_COUNT file(s) had errors"
        fi
        echo ""
        print_detail "Merge log saved to:"
        print_file "$MERGE_LOG"
        echo ""
        
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print_warning "⚠ IMPORTANT: Review and commit Obsidian changes"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        print_info "Next steps:"
        print_file "cd $OBSIDIAN_VAULT"
        print_file "git status"
        print_file "git diff"
        print_file "git add ."
        print_file "git commit -m 'Merged AI updates from Quartz'"
        echo ""
    else
        print_info "No files needed to be merged (all identical)"
    fi
fi

MERGE_END_TIME=$(date +%s)
MERGE_DURATION=$((MERGE_END_TIME - MERGE_START_TIME))
echo ""
print_info "Merge completed at: $(date '+%Y-%m-%d %H:%M:%S')"
print_detail "Duration: ${MERGE_DURATION} seconds"
echo "═══════════════════════════════════════════════════════"

