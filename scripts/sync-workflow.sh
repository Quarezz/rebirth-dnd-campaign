#!/bin/bash

# Interactive Sync Workflow Script
# Orchestrates the complete Obsidian ↔ Quartz sync workflow with manual AI processing pause

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

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

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

print_header() {
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}  $1${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════${NC}"
    echo ""
}

# Function to wait for user confirmation
wait_for_user() {
    local message="$1"
    echo ""
    print_warning "$message"
    echo ""
    read -p "Press Enter to continue..."
    echo ""
}

# Function to run a step with error checking
run_step() {
    local step_name="$1"
    local command="$2"
    local description="$3"

    print_step "$step_name: $description"

    if eval "$command"; then
        print_success "✓ $step_name completed successfully"
        echo ""
        return 0
    else
        print_error "✗ $step_name failed"
        echo ""
        return 1
    fi
}

# Main workflow
main() {
    print_header "🔄 Interactive Sync Workflow"
    print_info "This script will guide you through the complete Obsidian ↔ Quartz sync process"
    echo ""

    WORKFLOW_START_TIME=$(date +%s)

    # Step 1: Import from Obsidian to Quartz
    print_header "📥 STEP 1: Import from Obsidian to Quartz"

    if ! run_step "SYNC" "./sync-obsidian.sh --auto-update" "Syncing files from Obsidian to Quartz"; then
        print_error "Sync failed. Please check the errors above and try again."
        exit 1
    fi

    # Step 2: Manual AI Processing
    print_header "🤖 STEP 2: Manual AI Processing (REQUIRED)"

    print_info "The AI prompt has been prepared above."
    echo ""
    print_info "📋 NEXT STEPS:"
    echo -e "  1. ${GREEN}Copy the AI prompt${NC} from the terminal output above"
    echo -e "  2. ${GREEN}Paste it into Cursor IDE${NC} chat (@.ai-prompt.txt also created)"
    echo -e "  3. ${GREEN}Wait for AI to process${NC} all the files"
    echo -e "  4. ${GREEN}Review the changes${NC} made by the AI"
    echo ""
    print_warning "⚠ IMPORTANT: Do NOT continue until AI processing is complete!"
    echo ""

    wait_for_user "Have you completed the AI processing in Cursor?"

    # Step 3: Rebuild Quartz Content
    print_header "🔨 STEP 3: Rebuild Quartz Content"

    cd "$PROJECT_ROOT"
    if ! run_step "BUILD" "npx quartz build" "Building Quartz site with AI updates"; then
        print_error "Build failed. Please check the errors and fix them."
        exit 1
    fi

    # Step 4: Preview Export to Obsidian
    print_header "👀 STEP 4: Preview Export to Obsidian"

    print_info "First, let's preview what will be exported back to Obsidian..."
    echo ""

    if ! run_step "PREVIEW" "./scripts/merge-back-obsidian.sh" "Previewing changes to export to Obsidian (DRY RUN)"; then
        print_warning "Preview completed with warnings. Please review the output above."
        echo ""
    fi

    # Step 5: Confirm and Execute Export
    print_header "📤 STEP 5: Execute Export to Obsidian"

    echo ""
    print_warning "Ready to export AI changes back to Obsidian vault?"
    echo ""
    read -p "Do you want to proceed with the export? (y/N): " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Export cancelled by user."
        print_info "You can run the export manually later with:"
        print_file "./scripts/merge-back-obsidian.sh --execute"
        echo ""
        exit 0
    fi

    if ! run_step "EXPORT" "./scripts/merge-back-obsidian.sh --execute" "Exporting AI changes to Obsidian vault"; then
        print_error "Export failed. Please check the errors above."
        print_info "You can try again with: ./scripts/merge-back-obsidian.sh --execute"
        exit 1
    fi

    # Step 6: Final Instructions
    print_header "✅ WORKFLOW COMPLETE"

    print_success "🎉 All steps completed successfully!"
    echo ""
    print_info "📋 FINAL STEPS (Manual):"
    echo ""
    echo -e "  ${GREEN}1. Commit Obsidian changes:${NC}"
    echo -e "     cd ~/Documents/OVault/DND/Campaigns/Rebirth"
    echo -e "     git status"
    echo -e "     git diff"
    echo -e "     git add ."
    echo -e "     git commit -m 'AI updates processed'"
    echo -e "     git push"
    echo ""
    echo -e "  ${GREEN}2. Optional - Deploy Quartz:${NC}"
    echo -e "     npx quartz build --serve  # Preview locally"
    echo -e "     # or deploy to your hosting platform"
    echo ""

    # Summary
    WORKFLOW_END_TIME=$(date +%s)
    WORKFLOW_DURATION=$((WORKFLOW_END_TIME - WORKFLOW_START_TIME))

    print_header "📊 WORKFLOW SUMMARY"
    print_success "✓ Imported from Obsidian to Quartz"
    print_success "✓ Prepared AI processing prompt"
    print_success "✓ Rebuilt Quartz content"
    print_success "✓ Exported changes back to Obsidian"
    echo ""
    print_info "Total workflow time: ${WORKFLOW_DURATION} seconds"
    echo ""
    print_info "Remember to commit your Obsidian changes!"
    echo ""
    print_header "🏁 WORKFLOW FINISHED"
}

# Check if we're in the right directory
if [ ! -d "$SCRIPT_DIR" ]; then
    print_error "Scripts directory not found: $SCRIPT_DIR"
    exit 1
fi

if [ ! -f "$PROJECT_ROOT/package.json" ]; then
    print_error "Not in Quartz project root. Please run from the quartz directory."
    exit 1
fi

# Make sure scripts are executable
chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true

# Run main workflow
main
