#!/bin/bash

# Quartz to Obsidian Merge-Back Script
# This script syncs AI-modified content from Quartz back to the Obsidian vault
# It scans merge-eligible Quartz files and copies only those that differ

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

QUARTZ_CONTENT="$PROJECT_ROOT/content"
if [ -d "/Users/rniko/Documents/CloudVault/DND/Campaigns/Rebirth" ]; then
    OBSIDIAN_VAULT="/Users/rniko/Documents/CloudVault/DND/Campaigns/Rebirth"
elif [ -d "/home/morf/Documents/OVault/DND/Campaigns/Rebirth" ]; then
    OBSIDIAN_VAULT="/home/morf/Documents/OVault/DND/Campaigns/Rebirth"
else
    OBSIDIAN_VAULT="/home/morf/Documents/OVault/DND/Campaigns/Rebirth"
fi
MERGE_LOG="$PROJECT_ROOT/.merge-back-log.txt"

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

is_merge_candidate() {
    case "$1" in
        Notes/*|.obsidian/*|.git/*|.codex/*|.trash/*|*/.obsidian/*|*/.git/*|*/.codex/*|*/.trash/*)
            return 1
            ;;
        *.md|*.png|*.jpg|*.jpeg|*.gif|*.MD|*.PNG|*.JPG|*.JPEG|*.GIF)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

collect_content_files() {
    local search_root="$1"

    [ -d "$search_root" ] || return 0

    (
        cd "$search_root" || exit 1
        find . -type f -print | sed 's#^\./##'
    ) | while IFS= read -r file; do
        [ -n "$file" ] || continue

        if is_merge_candidate "$file"; then
            printf '%s\n' "$file"
        fi
    done | sort -u
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

# Detect which files should be merged back to Obsidian
print_info "Detecting files to merge back to Obsidian..."
echo ""

cd "$QUARTZ_CONTENT"

# Strategy: Scan every merge-eligible file and compare it directly to the vault.
# Relying on only the last sync log or uncommitted git changes misses files that
# were already committed in Quartz but still never made it back to Obsidian.
SYNC_LOG="$PROJECT_ROOT/.sync-log.txt"

if [ -f "$SYNC_LOG" ]; then
    print_detail "Last sync log found: $SYNC_LOG"
fi

print_info "Scanning all merge-eligible Quartz files..."
POTENTIAL_FILES=$(collect_content_files "$QUARTZ_CONTENT")

# Filter to only files that actually exist and are different from Obsidian
ALL_CHANGED_FILES=""
while IFS= read -r file; do
    if [ -n "$file" ] && [ -f "$QUARTZ_CONTENT/$file" ]; then
        OBSIDIAN_FILE="$OBSIDIAN_VAULT/$file"
        if [ ! -f "$OBSIDIAN_FILE" ] || ! cmp -s "$QUARTZ_CONTENT/$file" "$OBSIDIAN_FILE"; then
            ALL_CHANGED_FILES="${ALL_CHANGED_FILES}${file}\n"
        fi
    fi
done <<< "$POTENTIAL_FILES"

ALL_CHANGED_FILES=$(echo -e "$ALL_CHANGED_FILES" | grep -v '^$')

# Check if any Notes/ files were excluded
EXCLUDED_NOTES=""
while IFS= read -r file; do
    if [ -n "$file" ]; then
        OBSIDIAN_FILE="$OBSIDIAN_VAULT/$file"
        if [ ! -f "$OBSIDIAN_FILE" ] || ! cmp -s "$QUARTZ_CONTENT/$file" "$OBSIDIAN_FILE"; then
            EXCLUDED_NOTES="${EXCLUDED_NOTES}${file}\n"
        fi
    fi
done <<< "$(cd "$QUARTZ_CONTENT" && find Notes -type f -print 2>/dev/null | sort)"

EXCLUDED_NOTES=$(echo -e "$EXCLUDED_NOTES" | grep -v '^$')
if [ -n "$EXCLUDED_NOTES" ]; then
    EXCLUDED_COUNT=$(echo "$EXCLUDED_NOTES" | wc -l | tr -d ' ')
    print_warning "Excluded $EXCLUDED_COUNT file(s) from Notes/ folder (source of truth)"
    echo ""
fi

if [ -z "$ALL_CHANGED_FILES" ]; then
    print_info "No files need to be merged back to Obsidian"
    print_detail "All files are identical between Quartz and Obsidian"
    cd - > /dev/null
    exit 0
fi

FILE_COUNT=$(echo "$ALL_CHANGED_FILES" | wc -l | tr -d ' ')
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

# Show files to be merged
print_detail "Files to merge back to Obsidian ($FILE_COUNT):"
echo "$ALL_CHANGED_FILES" | while IFS= read -r file; do
    if [ -n "$file" ]; then
        if [ -f "$OBSIDIAN_VAULT/$file" ]; then
            print_file "[UPDATE] $file"
        else
            print_file "[NEW] $file"
        fi
    fi
done
echo ""

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
        print_warning "⚠ IMPORTANT: Review Obsidian changes"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        if [ "$IS_GIT_REPO" = true ]; then
            print_info "Next steps:"
            print_file "cd $OBSIDIAN_VAULT"
            print_file "git status"
            print_file "git diff"
            print_file "git add ."
            print_file "git commit -m 'Merged AI updates from Quartz'"
        else
            print_info "Obsidian vault is not a git repository, so review the new files directly in the vault."
            print_file "open \"$OBSIDIAN_VAULT\""
        fi
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
