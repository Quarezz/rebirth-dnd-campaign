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

SYNC_START_TIME=$(date +%s)
echo "═══════════════════════════════════════════════════════"
echo "  Obsidian → Quartz Sync Script"
echo "═══════════════════════════════════════════════════════"
echo ""
print_info "Sync started at: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
print_info "Source: $OBSIDIAN_VAULT"
print_info "Destination: $QUARTZ_CONTENT"
echo ""

# Check for existing git changes in destination
print_info "Checking destination git status..."
cd "$QUARTZ_CONTENT"
GIT_STATUS=$(git status --short 2>/dev/null)
if [ -n "$GIT_STATUS" ]; then
    print_warning "Destination has uncommitted changes:"
    echo ""
    echo "$GIT_STATUS" | head -10
    echo ""
    if [ $(echo "$GIT_STATUS" | wc -l) -gt 10 ]; then
        print_info "... and $(( $(echo "$GIT_STATUS" | wc -l) - 10 )) more"
        echo ""
    fi
fi
cd - > /dev/null
echo ""

# Show source directory structure
print_info "Scanning source directory structure..."
echo ""
print_detail "Directory tree:"
tree -L 2 -d "$OBSIDIAN_VAULT" 2>/dev/null || (
    print_warning "Tree command not available, listing directories..."
    find "$OBSIDIAN_VAULT" -maxdepth 2 -type d | head -20
)
echo ""

# Count files in source
TOTAL_MD_FILES=$(find "$OBSIDIAN_VAULT" -type f -name "*.md" | wc -l)
TOTAL_IMG_FILES=$(find "$OBSIDIAN_VAULT" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" \) | wc -l)
print_info "Source contains: $TOTAL_MD_FILES markdown files, $TOTAL_IMG_FILES image files"
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
print_info "Starting sync with rsync..."
echo ""
print_detail "Rsync options:"
print_file "Archive mode (-a): preserve permissions, times, symlinks"
print_file "Checksum mode: compare by content, not just timestamps"
print_file "Itemized changes: show detailed file changes"
if [ -n "$DRY_RUN" ]; then
    print_file "DRY RUN: no actual changes will be made"
fi
echo ""

print_detail "Excluded patterns:"
print_file ".obsidian/ (Obsidian config)"
print_file ".trash/ (trash folder)"
print_file ".DS_Store (macOS metadata)"
print_file "*.tmp (temporary files)"
print_file "Thumbs.db (Windows metadata)"
print_file ".git/ (git repository)"
echo ""

print_info "Running rsync..."
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

# Parse rsync output for changes and extract file paths
# Rsync itemize format: YXcstpoguax path/to/file
# Y = update type (>,<,c,h,.,*), X = file type (f,d,L,D,S)
RSYNC_CHANGES=$(echo "$RSYNC_OUTPUT" | grep -E '^[<>ch.*][fdLDS]')

# Extract actual file paths from rsync output (skip the first 12 characters which are flags)
# and filter for markdown and image files
# Use cut to properly handle spaces in filenames (rsync format: 11 chars + space + filename)
RSYNC_FILE_PATHS=$(echo "$RSYNC_OUTPUT" | grep -E '^[<>ch.*][fd]' | cut -c13- | grep -E '\.(md|png|jpg|jpeg|gif)$')

RSYNC_NEW=$(echo "$RSYNC_CHANGES" | grep -E '^>' | wc -l)
RSYNC_MODIFIED=$(echo "$RSYNC_CHANGES" | grep -E '^[<ch.*]' | wc -l)

# Display detailed output
if [ -n "$RSYNC_CHANGES" ]; then
    print_info "Rsync discovered changes:"
    echo ""
    print_detail "Files being transferred: $RSYNC_NEW new, $RSYNC_MODIFIED modified"
    echo ""
    
    # Show the actual changed files
    # Store regex pattern in variable to avoid bash parsing issues with < and >
    rsync_change_pattern='^[<>ch.*][fdLDS]'
    sending_pattern='^sending'
    
    echo "$RSYNC_OUTPUT" | while IFS= read -r line; do
        if [[ $line =~ $sending_pattern ]]; then
            print_detail "$line"
        elif [[ $line =~ $rsync_change_pattern ]]; then
            # Parse itemized changes
            print_file "$line"
        fi
    done
    echo ""
else
    print_info "Rsync output:"
    echo "$RSYNC_OUTPUT"
    echo ""
fi

# Parse and save changed files from rsync output
if [ $RSYNC_EXIT_CODE -eq 0 ] && [ -z "$DRY_RUN" ]; then
    print_info "Analyzing files changed by rsync..."
    echo ""
    
    # Use rsync's file list instead of git diff
    # This ensures we only track files that rsync actually modified in this sync
    ALL_CHANGED_FILES=$(echo "$RSYNC_FILE_PATHS" | grep -v '^$' | sort -u)
    
    if [ -n "$ALL_CHANGED_FILES" ]; then
        # Save to log
        echo "$ALL_CHANGED_FILES" > "$SYNC_LOG.tmp"
        cat "$SYNC_LOG" "$SYNC_LOG.tmp" > "$SYNC_LOG.new"
        mv "$SYNC_LOG.new" "$SYNC_LOG"
        rm -f "$SYNC_LOG.tmp"
        
        FILE_COUNT=$(echo "$ALL_CHANGED_FILES" | wc -l)
        
        print_success "Rsync modified $FILE_COUNT file(s) in this sync:"
        echo ""
        
        # Categorize by rsync operation type
        cd "$QUARTZ_CONTENT"
        TRULY_NEW_FILES=""
        UPDATED_FILES=""
        
        # Use while loop with IFS to properly handle spaces in filenames
        while IFS= read -r file; do
            if [ -n "$file" ]; then
                # Check if file existed in git before this sync
                if git ls-files --error-unmatch "$file" > /dev/null 2>&1; then
                    UPDATED_FILES="${UPDATED_FILES}${file}\n"
                else
                    TRULY_NEW_FILES="${TRULY_NEW_FILES}${file}\n"
                fi
            fi
        done <<< "$ALL_CHANGED_FILES"
        cd - > /dev/null
        
        UPDATED_COUNT=$(echo -e "$UPDATED_FILES" | grep -v '^$' | wc -l)
        NEW_COUNT=$(echo -e "$TRULY_NEW_FILES" | grep -v '^$' | wc -l)
        
        # Show updated files
        if [ $UPDATED_COUNT -gt 0 ]; then
            print_detail "Updated existing files ($UPDATED_COUNT):"
            echo -e "$UPDATED_FILES" | while IFS= read -r file; do
                if [ -n "$file" ]; then
                    print_file "$file"
                fi
            done
            echo ""
        fi
        
        # Show new files
        if [ $NEW_COUNT -gt 0 ]; then
            print_detail "Newly created files ($NEW_COUNT):"
            echo -e "$TRULY_NEW_FILES" | while IFS= read -r file; do
                if [ -n "$file" ]; then
                    print_file "$file"
                fi
            done
            echo ""
        fi
        
        # Categorize by file type
        MD_COUNT=$(echo "$ALL_CHANGED_FILES" | grep '\.md$' | wc -l)
        IMG_COUNT=$(echo "$ALL_CHANGED_FILES" | grep -E '\.(png|jpg|jpeg|gif)$' | wc -l)
        
        print_detail "File type breakdown:"
        print_file "Markdown files: $MD_COUNT"
        print_file "Image files: $IMG_COUNT"
        echo ""
        
        # Categorize by directory
        print_detail "Directory breakdown:"
        echo "$ALL_CHANGED_FILES" | awk -F'/' '{print $1}' | sort | uniq -c | while read count dir; do
            print_file "$dir/: $count file(s)"
        done
        echo ""
        
        print_success "Full list saved to: $SYNC_LOG"
        print_info "This list contains ONLY files modified by rsync in this sync run"
    else
        FILE_COUNT=0
        print_info "No files were modified by rsync in this sync"
    fi
fi

echo ""
echo "═══════════════════════════════════════════════════════"

# Check rsync exit code
if [ $RSYNC_EXIT_CODE -eq 0 ]; then
    if [ -n "$DRY_RUN" ]; then
        print_success "Dry run completed successfully!"
        echo ""
        print_warning "This was a DRY RUN - no actual changes were made"
        print_info "Run without --dry-run to actually sync files:"
        print_file "./sync-obsidian.sh"
    else
        print_success "✓ Sync completed successfully!"
        echo ""
        
        if [ $FILE_COUNT -gt 0 ]; then
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            print_success "SUMMARY: $FILE_COUNT file(s) were synced"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            
            print_detail "Log file location:"
            print_file "$SYNC_LOG"
            echo ""
            
            print_detail "You can review the changes with:"
            print_file "cat $SYNC_LOG"
            print_file "cd $QUARTZ_CONTENT && git status"
            print_file "cd $QUARTZ_CONTENT && git diff"
            echo ""
            
            # Automatically run AI agent if requested
            if [ "$AUTO_UPDATE" = true ]; then
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                print_info "🤖 Auto-update enabled - Invoking AI agent..."
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                
                print_info "Files to process:"
                echo ""
                echo "$ALL_CHANGED_FILES" | while IFS= read -r file; do
                    if [ -n "$file" ]; then
                        print_file "$file"
                    fi
                done
                echo ""
                
                # Create AI prompt
                AI_PROMPT_FILE="$QUARTZ_CONTENT/../.ai-auto-prompt.txt"
                cat > "$AI_PROMPT_FILE" << 'EOFPROMPT'
Process the files that were just synced from Obsidian to Quartz.

STEP 1: Read @.sync-log.txt to see which files were changed/added

STEP 2: For each changed file, read it and analyze:
- Type of content (Character, Location, Quest, Session Note)
- Entities mentioned that need cross-references
- New information added

STEP 3: Update cross-references:
- Add links between related entities using [EntityName](EntityName.md)
- Link characters to locations, quests, and session notes
- Link quests to locations and participants
- ALWAYS link to Session Notes where entities are mentioned

STEP 4: Update ALL index files:
- Персонажі/Всі_персонажі.md (if characters changed)
- Локації/Всі_локації.md (if locations changed)
- Квести/Всі_квести.md (if quests changed)
- Хронологія_подій.md (if session notes added)
- content/index.md (update with latest events)

STEP 5: CRITICAL - Fact-check everything against session notes

STEP 6: Report all modifications made

Remember: All content in Ukrainian, accuracy over completeness.
EOFPROMPT
                
                # Display prompt for manual invocation
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                print_info "🤖 AI PROCESSING REQUEST"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                print_info "Copy and paste the following into this chat:"
                echo ""
                cat "$AI_PROMPT_FILE"
                echo ""
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                print_success "✅ Prompt ready!"
                print_info "I will automatically start processing once you send it!"
                echo ""
                print_detail "Prompt saved to: $AI_PROMPT_FILE"
                echo ""
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            else
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                print_warning "⚠ NEXT STEP REQUIRED: Update references and indexes"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                print_info "Option 1: Run in Cursor (recommended):"
                print_file "@sync-update"
                echo ""
                print_info "Option 2: Re-run with auto-update:"
                print_file "./sync-obsidian.sh --auto-update"
                echo ""
            fi
        else
            print_success "✓ Everything is up to date!"
            print_info "No files were changed - source and destination are in sync"
        fi
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print_info "FINAL STEP: Rebuild your Quartz site"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        print_detail "After AI updates are complete, run:"
        print_file "npx quartz build"
        echo ""
        print_detail "To build and preview:"
        print_file "npx quartz build --serve"
    fi
else
    echo ""
    print_error "✗ Sync failed with exit code: $RSYNC_EXIT_CODE"
    echo ""
    print_info "Check the error messages above for details"
    exit $RSYNC_EXIT_CODE
fi

SYNC_END_TIME=$(date +%s)
SYNC_DURATION=$((SYNC_END_TIME - SYNC_START_TIME))
echo ""
print_info "Sync completed at: $(date '+%Y-%m-%d %H:%M:%S')"
print_detail "Duration: ${SYNC_DURATION} seconds"
echo "═══════════════════════════════════════════════════════"

