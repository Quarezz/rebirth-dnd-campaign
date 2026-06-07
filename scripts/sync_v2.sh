#!/bin/bash

set -euo pipefail

# End-to-end Obsidian <-> Quartz sync workflow.
# Markdown imports are read via obsidian-cli so Obsidian links/paths resolve through the vault.
# Merge-back and binary attachments use direct file copies to avoid Obsidian URI hangs.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
QUARTZ_CONTENT="$PROJECT_ROOT/content"
SYNC_LOG="$PROJECT_ROOT/.sync-log.txt"
MERGE_LOG="$PROJECT_ROOT/.merge-back-log.txt"
AI_PROMPT_FILE="$PROJECT_ROOT/.codex-sync-prompt.txt"
AI_REPORT_FILE="$PROJECT_ROOT/.codex-sync-report.txt"
DASHBOARD_PROMPT_FILE="$PROJECT_ROOT/CAMPAIGN-DASHBOARD-PROMPT.md"

OBSIDIAN_VAULT_NAME="${OBSIDIAN_VAULT_NAME:-CloudVault}"
OBSIDIAN_ROOT_PREFIX="${OBSIDIAN_ROOT_PREFIX:-DND/Campaigns/Rebirth}"
OBSIDIAN_PROJECT_ROOT="${OBSIDIAN_PROJECT_ROOT:-$HOME/Documents/CloudVault/DND/Campaigns/Rebirth}"

FORCE_MODE=false
AUTO_APPROVE=false
DRY_RUN=false
IMPORTED_FILE_COUNT=0
IMPORTED_CANDIDATES_FILE=""
MERGE_CANDIDATES_FILE=""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

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

print_detail() {
    echo -e "${CYAN}  ->${NC} $1"
}

print_file() {
    echo -e "${MAGENTA}    *${NC} $1"
}

print_header() {
    echo -e "${MAGENTA}=======================================================${NC}"
    echo -e "${MAGENTA}  $1${NC}"
    echo -e "${MAGENTA}=======================================================${NC}"
    echo ""
}

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --force          Proceed even if the Obsidian campaign folder has git changes
  --yes            Apply merge-back without confirmation
  --dry-run        Report planned changes without modifying files
  -h, --help       Show this help message

Environment overrides:
  OBSIDIAN_VAULT_NAME    Default: CloudVault
  OBSIDIAN_ROOT_PREFIX   Default: DND/Campaigns/Rebirth
  OBSIDIAN_PROJECT_ROOT  Default: \$HOME/Documents/CloudVault/DND/Campaigns/Rebirth
EOF
}

require_command() {
    local command_name="$1"
    if ! command -v "$command_name" >/dev/null 2>&1; then
        print_error "Required command not found: $command_name"
        exit 1
    fi
}

is_markdown_file() {
    case "$1" in
        *.md) return 0 ;;
        *) return 1 ;;
    esac
}

is_asset_file() {
    case "$1" in
        *.png|*.jpg|*.jpeg|*.gif) return 0 ;;
        *) return 1 ;;
    esac
}

should_skip_relative_path() {
    case "$1" in
        .obsidian/*|.trash/*|.git/*|.codex/*|*/.obsidian/*|*/.trash/*|*/.git/*|*/.codex/*) return 0 ;;
        .*|*/.*) return 0 ;;
        *.tmp|*/.DS_Store|.DS_Store|*/Thumbs.db|Thumbs.db) return 0 ;;
        *) return 1 ;;
    esac
}

obsidian_note_path() {
    printf '%s/%s' "$OBSIDIAN_ROOT_PREFIX" "$1"
}

create_parent_dir() {
    local file_path="$1"
    mkdir -p "$(dirname "$file_path")"
}

write_header_log() {
    local file_path="$1"
    local title="$2"

    {
        echo "# $title - $(date)"
        echo "# Vault: $OBSIDIAN_VAULT_NAME"
        echo "# Root: $OBSIDIAN_ROOT_PREFIX"
        echo ""
    } >"$file_path"
}

files_equivalent_for_sync() {
    local left_file="$1"
    local right_file="$2"
    local left_normalized right_normalized

    if cmp -s "$left_file" "$right_file"; then
        return 0
    fi

    left_normalized="$(mktemp)"
    right_normalized="$(mktemp)"

    perl -0pe 's/\n+\z//' "$left_file" >"$left_normalized"
    perl -0pe 's/\n+\z//' "$right_file" >"$right_normalized"

    if cmp -s "$left_normalized" "$right_normalized"; then
        rm -f "$left_normalized" "$right_normalized"
        return 0
    fi

    rm -f "$left_normalized" "$right_normalized"
    return 1
}

check_prerequisites() {
    require_command "obsidian-cli"
    require_command "codex"
    require_command "npx"
    require_command "git"

    if [ ! -d "$QUARTZ_CONTENT" ]; then
        print_error "Quartz content folder not found at: $QUARTZ_CONTENT"
        exit 1
    fi

    if [ ! -d "$OBSIDIAN_PROJECT_ROOT" ]; then
        print_error "Obsidian campaign folder not found at: $OBSIDIAN_PROJECT_ROOT"
        print_info "Override with OBSIDIAN_PROJECT_ROOT if needed."
        exit 1
    fi
}

check_quartz_dependencies() {
    if [ -f "$PROJECT_ROOT/node_modules/yargs/package.json" ]; then
        return 0
    fi

    print_error "Quartz dependencies are not installed"
    print_info "Run \`npm install\` in $PROJECT_ROOT and then re-run this script."
    exit 1
}

check_obsidian_git_status() {
    if ! git -C "$OBSIDIAN_PROJECT_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
        print_warning "Obsidian campaign folder is not a git repository"
        echo ""
        return 0
    fi

    local git_status
    git_status="$(git -C "$OBSIDIAN_PROJECT_ROOT" status --short 2>/dev/null || true)"

    if [ -z "$git_status" ]; then
        print_success "Obsidian campaign folder is clean"
        echo ""
        return 0
    fi

    print_warning "Obsidian campaign folder has uncommitted changes:"
    echo ""
    printf '%s\n' "$git_status" | sed -n '1,10p'
    echo ""

    if [ "$(printf '%s\n' "$git_status" | wc -l | tr -d ' ')" -gt 10 ]; then
        print_info "... and more"
        echo ""
    fi

    if [ "$FORCE_MODE" = false ]; then
        if [ "$DRY_RUN" = true ]; then
            print_warning "Continuing because dry-run mode will not write to Obsidian"
            echo ""
            return 0
        fi
        print_error "Refusing to continue with uncommitted Obsidian changes"
        print_info "Re-run with --force to override."
        exit 1
    fi

    print_warning "FORCE mode enabled - continuing anyway"
    echo ""
}

import_from_obsidian() {
    local changed_tmp new_tmp updated_tmp scan_error_tmp sorted_changed_tmp
    local total_md=0
    local total_assets=0
    local changed_count=0
    local markdown_count=0
    local asset_count=0

    changed_tmp="$(mktemp)"
    new_tmp="$(mktemp)"
    updated_tmp="$(mktemp)"
    scan_error_tmp="$(mktemp)"
    sorted_changed_tmp="$(mktemp)"

    : >"$changed_tmp"
    : >"$new_tmp"
    : >"$updated_tmp"
    : >"$scan_error_tmp"
    : >"$sorted_changed_tmp"

    print_header "STEP 1: Import from Obsidian"
    print_info "Vault: $OBSIDIAN_VAULT_NAME"
    print_info "Vault root: $OBSIDIAN_PROJECT_ROOT"
    print_info "Quartz content: $QUARTZ_CONTENT"
    echo ""
    print_warning "Markdown notes sync through obsidian-cli. Binary attachments still use direct file copy."
    echo ""

    while IFS= read -r -d '' source_file; do
        local relative_path destination_file temp_file note_path existed_before=false

        relative_path="${source_file#$OBSIDIAN_PROJECT_ROOT/}"

        if should_skip_relative_path "$relative_path"; then
            continue
        fi

        if is_markdown_file "$relative_path"; then
            total_md=$((total_md + 1))
            destination_file="$QUARTZ_CONTENT/$relative_path"
            note_path="$(obsidian_note_path "$relative_path")"
            temp_file="$(mktemp)"

            if ! obsidian-cli print "$note_path" --vault "$OBSIDIAN_VAULT_NAME" >"$temp_file"; then
                print_warning "Failed to read note via obsidian-cli: $relative_path"
                printf '%s\n' "$relative_path" >>"$scan_error_tmp"
                rm -f "$temp_file"
                continue
            fi

            if [ -f "$destination_file" ]; then
                existed_before=true
            fi

            if [ ! -f "$destination_file" ] || ! files_equivalent_for_sync "$temp_file" "$destination_file"; then
                printf '%s\n' "$relative_path" >>"$changed_tmp"
                changed_count=$((changed_count + 1))
                markdown_count=$((markdown_count + 1))

                if [ "$DRY_RUN" = false ]; then
                    create_parent_dir "$destination_file"
                    cp "$temp_file" "$destination_file"
                fi

                if [ "$existed_before" = true ]; then
                    printf '%s\n' "$relative_path" >>"$updated_tmp"
                else
                    printf '%s\n' "$relative_path" >>"$new_tmp"
                fi
            fi

            rm -f "$temp_file"
            continue
        fi

        if is_asset_file "$relative_path"; then
            total_assets=$((total_assets + 1))
            destination_file="$QUARTZ_CONTENT/$relative_path"

            if [ -f "$destination_file" ]; then
                existed_before=true
            else
                existed_before=false
            fi

            if [ ! -f "$destination_file" ] || ! cmp -s "$source_file" "$destination_file"; then
                printf '%s\n' "$relative_path" >>"$changed_tmp"
                changed_count=$((changed_count + 1))
                asset_count=$((asset_count + 1))

                if [ "$DRY_RUN" = false ]; then
                    create_parent_dir "$destination_file"
                    cp "$source_file" "$destination_file"
                fi

                if [ "$existed_before" = true ]; then
                    printf '%s\n' "$relative_path" >>"$updated_tmp"
                else
                    printf '%s\n' "$relative_path" >>"$new_tmp"
                fi
            fi
        fi
    done < <(find "$OBSIDIAN_PROJECT_ROOT" -type f -print0)

    if [ -s "$changed_tmp" ]; then
        sort -u "$changed_tmp" >"$sorted_changed_tmp"
    fi

    IMPORTED_CANDIDATES_FILE="$sorted_changed_tmp"

    if [ "$DRY_RUN" = false ]; then
        write_header_log "$SYNC_LOG" "Sync Log"
        if [ -s "$sorted_changed_tmp" ]; then
            cat "$sorted_changed_tmp" >>"$SYNC_LOG"
        fi
    fi

    print_info "Source contains: $total_md markdown file(s), $total_assets asset file(s)"
    echo ""

    if [ "$changed_count" -eq 0 ]; then
        if [ "$DRY_RUN" = true ]; then
            print_success "Dry run found no import changes"
        else
            print_success "Nothing changed during import"
        fi
    else
        if [ "$DRY_RUN" = true ]; then
            print_success "Dry run: would import $changed_count changed file(s)"
        else
            print_success "Imported $changed_count changed file(s)"
        fi
        print_detail "Markdown files: $markdown_count"
        print_detail "Asset files: $asset_count"
        echo ""

        if [ -s "$updated_tmp" ]; then
            print_detail "Updated existing files:"
            while IFS= read -r file_path; do
                [ -n "$file_path" ] && print_file "$file_path"
            done < <(sort -u "$updated_tmp")
            echo ""
        fi

        if [ -s "$new_tmp" ]; then
            print_detail "New files:"
            while IFS= read -r file_path; do
                [ -n "$file_path" ] && print_file "$file_path"
            done < <(sort -u "$new_tmp")
            echo ""
        fi

        if [ "$DRY_RUN" = true ]; then
            print_detail "No files were copied and .sync-log.txt was not updated"
        else
            print_detail "Sync log saved to: $SYNC_LOG"
        fi
    fi

    if [ -s "$scan_error_tmp" ]; then
        echo ""
        print_warning "Some markdown notes could not be read via obsidian-cli:"
        while IFS= read -r file_path; do
            [ -n "$file_path" ] && print_file "$file_path"
        done <"$scan_error_tmp"
    fi

    echo ""

    rm -f "$changed_tmp" "$new_tmp" "$updated_tmp" "$scan_error_tmp"
    IMPORTED_FILE_COUNT="$changed_count"
}

run_codex_update() {
    print_header "STEP 2: Codex Update"

    if [ "${IMPORTED_FILE_COUNT:-0}" -eq 0 ]; then
        print_info "Skipping Codex update because no files changed during import"
        echo ""
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        print_info "Dry run: Codex would process the imported file set and update references/index pages"
        print_detail "No prompt/report files were written"
        if [ -n "$IMPORTED_CANDIDATES_FILE" ] && [ -s "$IMPORTED_CANDIDATES_FILE" ]; then
            echo ""
            while IFS= read -r file_path; do
                [ -n "$file_path" ] && print_file "$file_path"
            done <"$IMPORTED_CANDIDATES_FILE"
        fi
        echo ""
        return 0
    fi

    if [ ! -f "$DASHBOARD_PROMPT_FILE" ]; then
        print_error "Campaign dashboard prompt not found: $DASHBOARD_PROMPT_FILE"
        exit 1
    fi

    cat >"$AI_PROMPT_FILE" <<'EOF'
You are updating a Ukrainian D&D campaign knowledge base after an Obsidian import.

First read `.sync-log.txt` to get the exact files imported in the latest sync.

Global requirements:
- Work only inside this repository.
- Treat `content/Notes/` as source of truth and do not modify files under `content/Notes/`.
- Update cross-references between characters, locations, quests, and timeline/index pages when the imported changes justify it.
- Keep all user-facing content in Ukrainian.
- Use only facts supported by the imported notes and the current repository state.
- Relevant index pages usually include:
  - `content/Персонажі/00_Index.md`
  - `content/Локації/Всі_локації.md`
  - `content/Квести/Всі_квести.md`
  - `content/Хронологія_подій.md`
  - `content/index.md`
- Preserve existing style and link conventions.

Required workflow:
1. First update justified derived knowledge pages: character pages, location pages, quest pages, index pages, and chronology.
2. Then update the campaign homepage/dashboard by following the campaign dashboard prompt embedded below.
3. The embedded prompt's `Files you may edit` and scope rules apply to the dashboard phase only, after the broader derived-page update phase is complete.
4. The dashboard prompt's five result-scoring iterations are mandatory. Include those scores in your final report.
5. Run any build/check commands required by the embedded dashboard prompt. The outer sync script will run `npx quartz build` again after Codex finishes.
6. At the end, provide a concise summary of files changed, the recap session used, build/check result, and any evidence gaps.

Embedded campaign dashboard prompt:
EOF

    cat "$DASHBOARD_PROMPT_FILE" >>"$AI_PROMPT_FILE"

    print_info "Running Codex CLI non-interactively..."
    print_detail "Prompt file: $AI_PROMPT_FILE"
    print_detail "Dashboard prompt: $DASHBOARD_PROMPT_FILE"
    print_detail "Report file: $AI_REPORT_FILE"
    echo ""

    if codex exec --full-auto --color never -C "$PROJECT_ROOT" -o "$AI_REPORT_FILE" - <"$AI_PROMPT_FILE"; then
        print_success "Codex update completed"
    else
        print_error "Codex update failed"
        exit 1
    fi

    echo ""
}

build_quartz() {
    print_header "STEP 3: Build Quartz"

    if [ "$DRY_RUN" = true ]; then
        print_info "Dry run: would run \`npx quartz build\` after Codex finishes"
        echo ""
        return 0
    fi

    check_quartz_dependencies

    if npx quartz build; then
        print_success "Quartz build completed"
    else
        print_error "Quartz build failed"
        exit 1
    fi

    echo ""
}

collect_merge_candidates() {
    local candidates_tmp filtered_tmp

    candidates_tmp="$(mktemp)"
    filtered_tmp="$(mktemp)"

    : >"$candidates_tmp"
    : >"$filtered_tmp"

    # Compare every merge-eligible file under Quartz content directly against
    # Obsidian. Using only the sync log or git dirtiness misses committed files
    # that still never made it back to the vault.
    (
        cd "$QUARTZ_CONTENT" || exit 1
        find . -type f -print | sed 's#^\./##'
    ) | while IFS= read -r file_path; do
        [ -z "$file_path" ] && continue

        if should_skip_relative_path "$file_path"; then
            continue
        fi

        case "$file_path" in
            Notes/*) continue ;;
        esac

        if is_markdown_file "$file_path" || is_asset_file "$file_path"; then
            printf '%s\n' "$file_path" >>"$candidates_tmp"
        fi
    done

    sort -u "$candidates_tmp" | while IFS= read -r file_path; do
        local quartz_file obsidian_file

        [ -z "$file_path" ] && continue

        quartz_file="$QUARTZ_CONTENT/$file_path"
        obsidian_file="$OBSIDIAN_PROJECT_ROOT/$file_path"

        [ -f "$quartz_file" ] || continue

        if [ ! -f "$obsidian_file" ] || ! cmp -s "$quartz_file" "$obsidian_file"; then
            printf '%s\n' "$file_path" >>"$filtered_tmp"
        fi
    done

    rm -f "$candidates_tmp"
    printf '%s' "$filtered_tmp"
}

preview_merge_back() {
    local merge_candidates_file file_count

    merge_candidates_file="$(collect_merge_candidates)"
    MERGE_CANDIDATES_FILE="$merge_candidates_file"

    print_header "STEP 4: Preview Merge-Back"
    print_info "Notes under Notes/ are excluded from merge-back"
    if [ "$DRY_RUN" = true ]; then
        print_warning "Dry run preview reflects the current Quartz workspace only"
        print_warning "Import/Codex/build changes were not applied, so final merge-back candidates may differ"
    fi
    echo ""

    if [ ! -s "$MERGE_CANDIDATES_FILE" ]; then
        print_success "No files need to be merged back to Obsidian"
        echo ""
        return 0
    fi

    file_count="$(wc -l <"$MERGE_CANDIDATES_FILE" | tr -d ' ')"
    print_success "Found $file_count file(s) to merge back:"
    echo ""

    while IFS= read -r file_path; do
        local obsidian_file
        obsidian_file="$OBSIDIAN_PROJECT_ROOT/$file_path"

        if [ -f "$obsidian_file" ]; then
            print_file "[UPDATE] $file_path"
        else
            print_file "[NEW] $file_path"
        fi
    done <"$MERGE_CANDIDATES_FILE"

    echo ""
}

merge_back_to_obsidian() {
    local copied_count=0
    local file_count

    if [ ! -s "${MERGE_CANDIDATES_FILE:-}" ]; then
        return 0
    fi

    file_count="$(wc -l <"$MERGE_CANDIDATES_FILE" | tr -d ' ')"

    if [ "$DRY_RUN" = true ]; then
        print_header "STEP 5: Merge-Back to Obsidian"
        print_info "Dry run: would merge back $file_count file(s) after confirmation"
        echo ""
        return 0
    fi

    if [ "$AUTO_APPROVE" = false ]; then
        read -r -p "Proceed with merge-back of $file_count file(s)? (y/N): " reply
        case "$reply" in
            [Yy]|[Yy][Ee][Ss]) ;;
            *)
                print_info "Merge-back cancelled"
                echo ""
                return 0
                ;;
        esac
    fi

    print_header "STEP 5: Merge-Back to Obsidian"
    write_header_log "$MERGE_LOG" "Merge-Back Log"

    while IFS= read -r file_path; do
        local source_file destination_file

        [ -z "$file_path" ] && continue

        source_file="$QUARTZ_CONTENT/$file_path"
        destination_file="$OBSIDIAN_PROJECT_ROOT/$file_path"

        if is_markdown_file "$file_path"; then
            create_parent_dir "$destination_file"
            cp "$source_file" "$destination_file"
            print_file "[SYNCED NOTE] $file_path"
            printf '%s\n' "$file_path" >>"$MERGE_LOG"
            copied_count=$((copied_count + 1))
            continue
        fi

        if is_asset_file "$file_path"; then
            create_parent_dir "$destination_file"
            cp "$source_file" "$destination_file"
            print_file "[SYNCED ASSET] $file_path"
            printf '%s\n' "$file_path" >>"$MERGE_LOG"
            copied_count=$((copied_count + 1))
        fi
    done <"$MERGE_CANDIDATES_FILE"

    echo ""
    print_success "Merged $copied_count file(s) back to Obsidian"
    print_detail "Merge log saved to: $MERGE_LOG"
    echo ""
}

print_summary() {
    print_header "WORKFLOW COMPLETE"
    if [ "$DRY_RUN" = true ]; then
        print_success "Dry-run import analysis finished"
        print_success "Dry-run Codex planning finished"
        print_success "Dry-run build planning finished"
        print_success "Dry-run merge-back preview finished"
    else
        print_success "Import finished"
        print_success "Codex processing finished"
        print_success "Quartz build finished"
        print_success "Merge-back preview finished"
    fi
    echo ""
    print_info "Vault path: $OBSIDIAN_PROJECT_ROOT"
    print_info "Quartz path: $QUARTZ_CONTENT"
    if [ "$DRY_RUN" = true ]; then
        print_info "Dry run did not write sync logs or Codex report files"
    else
        print_info "Sync log: $SYNC_LOG"
        print_info "Codex report: $AI_REPORT_FILE"
    fi
    echo ""

    if git -C "$OBSIDIAN_PROJECT_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
        print_info "Review and commit Obsidian changes:"
        print_file "cd \"$OBSIDIAN_PROJECT_ROOT\""
        print_file "git status"
        print_file "git diff"
        print_file "git add ."
        print_file "git commit -m 'Synced campaign updates'"
    else
        print_warning "Obsidian campaign folder is not a git repository, so there is nothing to commit there."
    fi

    echo ""
}

main() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --force)
                FORCE_MODE=true
                ;;
            --yes)
                AUTO_APPROVE=true
                ;;
            --dry-run)
                DRY_RUN=true
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
        shift
    done

    check_prerequisites

    print_header "Obsidian <-> Quartz Sync v2"
    if [ "$DRY_RUN" = true ]; then
        print_warning "Running in dry-run mode. No files will be modified."
        echo ""
    fi
    check_obsidian_git_status
    import_from_obsidian
    run_codex_update
    build_quartz
    preview_merge_back
    merge_back_to_obsidian
    print_summary

    rm -f "${IMPORTED_CANDIDATES_FILE:-}"
    rm -f "${MERGE_CANDIDATES_FILE:-}"
}

main "$@"
