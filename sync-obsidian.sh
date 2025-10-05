#!/bin/bash

# Obsidian to Quartz Sync Script
# This script syncs content from your Obsidian vault to the Quartz content folder
# It only copies new or modified files and NEVER deletes files from Quartz

# Configuration
OBSIDIAN_VAULT="/home/morf/Documents/OVault/DND/Campaigns/Rebirth"
QUARTZ_CONTENT="/home/morf/Downloads/quartz/content"
SYNC_LOG="/home/morf/Downloads/quartz/.sync-log.txt"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
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

# Check if source directory exists
if [ ! -d "$OBSIDIAN_VAULT" ]; then
    print_error "Obsidian vault not found at: $OBSIDIAN_VAULT"
    exit 1
fi

# Check if destination directory exists
if [ ! -d "$QUARTZ_CONTENT" ]; then
    print_error "Quartz content folder not found at: $QUARTZ_CONTENT"
    exit 1
fi

echo "═══════════════════════════════════════════════════════"
echo "  Obsidian → Quartz Sync Script"
echo "═══════════════════════════════════════════════════════"
echo ""
print_info "Source: $OBSIDIAN_VAULT"
print_info "Destination: $QUARTZ_CONTENT"
echo ""

# Parse command line arguments
DRY_RUN=""
AUTO_UPDATE=false

for arg in "$@"; do
    case $arg in
        --dry-run|-n)
            DRY_RUN="--dry-run"
            print_warning "DRY RUN MODE - No files will be copied"
            echo ""
            ;;
        --auto-update|-a)
            AUTO_UPDATE=true
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -n, --dry-run        Preview changes without copying files"
            echo "  -a, --auto-update    Automatically run AI agent after sync"
            echo "  -h, --help           Show this help message"
            echo ""
            exit 0
            ;;
    esac
done

# Clear previous sync log
if [ -z "$DRY_RUN" ]; then
    > "$SYNC_LOG"
    echo "# Sync Log - $(date)" >> "$SYNC_LOG"
    echo "# Files synced from Obsidian to Quartz" >> "$SYNC_LOG"
    echo "" >> "$SYNC_LOG"
fi

# Run rsync and capture output
print_info "Starting sync..."
echo ""

RSYNC_OUTPUT=$(rsync -av \
    --checksum \
    --itemize-changes \
    $DRY_RUN \
    --exclude='.obsidian/' \
    --exclude='.trash/' \
    --exclude='.DS_Store' \
    --exclude='*.tmp' \
    --exclude='Thumbs.db' \
    --exclude='.git/' \
    "$OBSIDIAN_VAULT/" \
    "$QUARTZ_CONTENT/" 2>&1)

RSYNC_EXIT_CODE=$?

# Display output
echo "$RSYNC_OUTPUT"

# Parse and save changed files using git diff
if [ $RSYNC_EXIT_CODE -eq 0 ] && [ -z "$DRY_RUN" ]; then
    cd "$QUARTZ_CONTENT"
    
    # Get git changes (new, modified, or renamed files)
    CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null | grep -E '\.(md|png|jpg|jpeg|gif)$')
    
    # Also check for untracked files
    UNTRACKED_FILES=$(git ls-files --others --exclude-standard 2>/dev/null | grep -E '\.(md|png|jpg|jpeg|gif)$')
    
    # Combine both lists
    ALL_CHANGED_FILES=$(echo -e "$CHANGED_FILES\n$UNTRACKED_FILES" | grep -v '^$' | sort -u)
    
    if [ -n "$ALL_CHANGED_FILES" ]; then
        echo "$ALL_CHANGED_FILES" >> "$SYNC_LOG"
        FILE_COUNT=$(echo "$ALL_CHANGED_FILES" | wc -l)
        
        print_info "Git detected changes in $FILE_COUNT file(s)"
    else
        FILE_COUNT=0
    fi
    
    cd - > /dev/null
fi

echo ""
echo "═══════════════════════════════════════════════════════"

# Check rsync exit code
if [ $RSYNC_EXIT_CODE -eq 0 ]; then
    if [ -n "$DRY_RUN" ]; then
        print_success "Dry run completed successfully!"
        echo ""
        print_info "Run without --dry-run to actually sync files"
    else
        print_success "Sync completed successfully!"
        echo ""
        
        if [ $FILE_COUNT -gt 0 ]; then
            print_success "$FILE_COUNT file(s) were synced"
            print_info "Changed files logged to: $SYNC_LOG"
            echo ""
            
            # Automatically run AI agent if requested
            if [ "$AUTO_UPDATE" = true ]; then
                print_info "Auto-update enabled - preparing AI prompt..."
                echo ""
                
                # Run the AI update script to prepare the prompt
                SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
                if [ -f "$SCRIPT_DIR/run-ai-update.sh" ]; then
                    bash "$SCRIPT_DIR/run-ai-update.sh"
                else
                    print_error "run-ai-update.sh not found"
                fi
            else
                print_warning "NEXT STEP: Update references and indexes"
                print_info "Run the Cursor command: @sync-update"
                print_info "Or run sync with --auto-update flag: ./sync-obsidian.sh --auto-update"
            fi
        else
            print_info "No files were changed - everything is up to date!"
        fi
        
        echo ""
        print_info "After AI updates, run 'npx quartz build' to rebuild your site"
    fi
else
    print_error "Sync failed with exit code: $RSYNC_EXIT_CODE"
    exit $RSYNC_EXIT_CODE
fi

echo "═══════════════════════════════════════════════════════"

