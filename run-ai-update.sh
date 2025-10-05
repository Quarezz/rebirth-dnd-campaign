#!/bin/bash

# AI Update Runner
# This script invokes the Cursor AI agent to process synced files

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SYNC_LOG="$SCRIPT_DIR/.sync-log.txt"
PROMPT_FILE="$SCRIPT_DIR/.cursor/commands/sync-update.md"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "═══════════════════════════════════════════════════════"
echo "  Cursor AI Update Runner"
echo "═══════════════════════════════════════════════════════"
echo ""

# Check if sync log exists
if [ ! -f "$SYNC_LOG" ]; then
    print_error "Sync log not found: $SYNC_LOG"
    print_info "Please run ./sync-obsidian.sh first"
    exit 1
fi

# Check if prompt file exists
if [ ! -f "$PROMPT_FILE" ]; then
    print_error "Prompt file not found: $PROMPT_FILE"
    exit 1
fi

# Read synced files
SYNCED_FILES=$(cat "$SYNC_LOG" | tail -n +4)

if [ -z "$SYNCED_FILES" ]; then
    print_warning "No files in sync log. Nothing to process."
    exit 0
fi

print_info "Found synced files to process"
print_info "Preparing AI agent prompt..."
echo ""

# Create the combined prompt
AGENT_PROMPT="$(cat $PROMPT_FILE)

## Synced Files

The following files were just synced from Obsidian:

\`\`\`
$SYNCED_FILES
\`\`\`

Please process these files according to the instructions above."

# Save prompt to a temporary file for the AI to read
TEMP_PROMPT="$SCRIPT_DIR/.ai-prompt.txt"
echo "$AGENT_PROMPT" > "$TEMP_PROMPT"

print_success "Prompt prepared and saved to: $TEMP_PROMPT"
echo ""
echo "═══════════════════════════════════════════════════════"
echo ""
print_info "✅ Invoking Cursor AI Agent..."
echo ""

# Provide instructions for running the AI agent
print_success "✅ AI prompt is ready!"
echo ""
print_info "Next steps - Choose one method:"
echo ""
echo -e "  ${GREEN}Method 1 (Recommended):${NC} In Cursor IDE, type:"
echo -e "    ${GREEN}@.ai-prompt.txt${NC}"
echo ""
echo -e "  ${GREEN}Method 2 (CLI):${NC} Run in terminal (may take 5-10 minutes):"
echo -e "    ${GREEN}cat .ai-prompt.txt | cursor-agent --print --force${NC}"
echo ""
print_warning "Note: cursor-agent CLI may hang in some terminal environments."
print_info "Manual invocation in Cursor IDE is more reliable."

echo ""
echo "═══════════════════════════════════════════════════════"

