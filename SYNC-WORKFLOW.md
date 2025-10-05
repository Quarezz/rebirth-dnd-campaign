# Obsidian → Quartz Sync Workflow

This guide explains the automated workflow for syncing your Obsidian vault to Quartz and updating all references and indexes.

## Quick Start

### Option A: Fully Automated (Recommended)
```bash
./sync-obsidian.sh --auto-update
```
This will sync files AND automatically prepare the AI agent prompt!

### Option B: Manual Steps

**1. Sync Your Obsidian Notes**
```bash
./sync-obsidian.sh
```

This will:
- Compare your Obsidian vault with Quartz content folder
- Copy only new or modified files
- Log all changed files to `.sync-log.txt`
- Display a summary of what was synced

**Dry Run Mode** (preview without copying):
```bash
./sync-obsidian.sh --dry-run
```

**2. Update References & Indexes (AI Agent)**

**Method 1:** Run the helper script
```bash
./run-ai-update.sh
```
Then use `@.ai-prompt.txt` in Cursor

**Method 2:** Use Cursor command directly
```
@sync-update
```

**Method 3:** Use Command Palette
- Press `Ctrl+Shift+P` (Linux) or `Cmd+Shift+P` (Mac)
- Type "Run Cursor Command"
- Select "sync-update"

The AI will automatically:
- ✅ Read all changed files from the sync log
- ✅ Analyze new content (characters, locations, quests, events)
- ✅ Add cross-references between related entities
- ✅ Update all index files (Всі_персонажі, Всі_локації, Всі_квести, etc.)
- ✅ Update chronology with new session notes
- ✅ Update main index with latest events
- ✅ Fact-check everything against session notes
- ✅ Report all changes made

### 3. Build Your Site
```bash
npx quartz build
```

## Script Options

### sync-obsidian.sh
```bash
./sync-obsidian.sh [OPTIONS]

Options:
  -n, --dry-run        Preview changes without copying files
  -a, --auto-update    Automatically prepare AI agent prompt after sync
  -h, --help           Show help message
```

### run-ai-update.sh
```bash
./run-ai-update.sh
```
Prepares the AI agent prompt from the sync log. Run this if you didn't use `--auto-update`.

## Configuration

Edit `sync-obsidian.sh` to change:
- **OBSIDIAN_VAULT**: Path to your Obsidian vault (currently: `/home/morf/Documents/OVault/DND/Campaigns/Rebirth`)
- **QUARTZ_CONTENT**: Path to Quartz content folder (currently: `/home/morf/Downloads/quartz/content`)

## Files

- `sync-obsidian.sh` - Main sync script with auto-update option
- `run-ai-update.sh` - Standalone AI update script
- `.sync-log.txt` - Log of synced files (auto-generated)
- `.ai-prompt.txt` - AI agent prompt with sync log (auto-generated)
- `.cursor/commands/sync-update.md` - AI agent command template
- `.cursor/rules/structure.mdc` - Campaign vault structure rules

## Workflow Diagrams

### Automated Workflow (--auto-update)
```
┌─────────────────────────────────┐
│      Edit in Obsidian           │
│      (Your DnD Campaign)        │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│  ./sync-obsidian.sh             │
│         --auto-update           │ ← Single command!
│                                 │
│  • Compares & Copies            │
│  • Creates .sync-log.txt        │
│  • Creates .ai-prompt.txt       │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│   Use @.ai-prompt.txt           │ ← Manual step
│   in Cursor                     │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│ AI Updates:                     │
│ • Cross-references              │
│ • Indexes                       │
│ • Chronology                    │
│ • Fact-checking                 │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│   npx quartz build              │ ← Manual step
└─────────────────────────────────┘
```

### Manual Workflow
```
┌─────────────────────────┐
│   Edit in Obsidian      │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  ./sync-obsidian.sh     │ ← Manual step
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  ./run-ai-update.sh     │ ← Manual step
│  (or @sync-update)      │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│   AI processes files    │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│   npx quartz build      │ ← Manual step
└─────────────────────────┘
```

## Safety Features

✅ **Never deletes files** - Only copies new/modified files  
✅ **Dry run mode** - Preview changes before applying  
✅ **Excludes Obsidian metadata** - Skips `.obsidian/`, `.trash/`, etc.  
✅ **Fact-checking** - AI verifies all information against session notes  
✅ **Change tracking** - All synced files are logged  

## Troubleshooting

**Q: Nothing synced, but I know I changed files**

A: Check that:
- File modification times are newer in Obsidian
- Files are saved in Obsidian
- File paths match the configured `OBSIDIAN_VAULT` path

**Q: AI command not working**

A: Make sure:
- The `.sync-log.txt` file exists (run sync script first)
- You're using `@sync-update` or the Command Palette

**Q: Cross-references not being added**

A: The AI requires clear information in session notes. If entities aren't mentioned together in session notes, cross-references won't be added (by design, to maintain accuracy).

## Tips

- Run sync after each Obsidian editing session
- Use `--dry-run` first if you're unsure what changed
- Review the AI's report after `@sync-update` to see what was updated
- The AI will notify you of any inconsistencies or missing information

