# 🔄 Obsidian ↔ Quartz Sync System

An automated workflow to sync your D&D campaign notes from Obsidian to Quartz with AI-powered cross-referencing and index updates.

## ⚡ Quick Start

### Fully Automated Workflow (Recommended)

```bash
# 1. Sync and prepare AI prompt
./sync-obsidian.sh --auto-update

# 2. In Cursor, invoke the AI agent
@.ai-prompt.txt

# 3. Build your Quartz site
npx quartz build
```

That's it! The AI will handle all cross-references and index updates automatically.

## 📋 What Each Script Does

### `sync-obsidian.sh`
Main sync script that:
- Compares Obsidian vault with Quartz content folder
- Copies only new/modified files (uses rsync)
- Creates `.sync-log.txt` with list of changed files
- Optionally prepares AI agent prompt

**Usage:**
```bash
./sync-obsidian.sh                    # Basic sync
./sync-obsidian.sh --dry-run          # Preview changes
./sync-obsidian.sh --auto-update      # Sync + prepare AI prompt
./sync-obsidian.sh --help             # Show options
```

### `run-ai-update.sh`
Standalone AI prompt generator:
- Reads `.sync-log.txt`
- Combines it with `sync-update.md` template
- Creates `.ai-prompt.txt` for Cursor

**Usage:**
```bash
./run-ai-update.sh
# Then use: @.ai-prompt.txt in Cursor
```

### `.cursor/commands/sync-update.md`
AI agent template that tells the AI to:
- ✅ Read all changed files
- ✅ Analyze new content (characters, locations, quests, events)
- ✅ Add cross-references using `[Entity](Entity.md)` format
- ✅ Update all index files automatically
- ✅ Update chronology with new sessions
- ✅ Fact-check against session notes
- ✅ Report all changes made

## 🎯 Workflow Options

### Option A: Fully Automated
```bash
./sync-obsidian.sh --auto-update  # Then use @.ai-prompt.txt
```

### Option B: Step-by-Step
```bash
./sync-obsidian.sh                # Sync files
./run-ai-update.sh                # Prepare prompt
# Use @.ai-prompt.txt in Cursor
```

### Option C: Manual AI Trigger
```bash
./sync-obsidian.sh                # Sync files
# Use @sync-update in Cursor
```

## 📁 Generated Files

These files are auto-generated and gitignored:

- **`.sync-log.txt`** - List of files synced from Obsidian
- **`.ai-prompt.txt`** - Complete prompt for AI agent with sync log

## ⚙️ Configuration

Edit paths in `sync-obsidian.sh` (lines 8-9):

```bash
OBSIDIAN_VAULT="/home/morf/Documents/OVault/DND/Campaigns/Rebirth"
QUARTZ_CONTENT="/home/morf/Downloads/quartz/content"
```

## 🛡️ Safety Features

- ✅ **Never deletes files** - Only copies new/modified
- ✅ **Dry run mode** - Preview before applying
- ✅ **Excludes metadata** - Skips `.obsidian/`, `.trash/`
- ✅ **Fact-checking** - AI verifies against session notes
- ✅ **Change tracking** - All synced files logged

## 📚 File Structure

```
quartz/
├── sync-obsidian.sh          ← Main sync script
├── run-ai-update.sh          ← AI prompt generator
├── .sync-log.txt             ← Auto-generated sync log
├── .ai-prompt.txt            ← Auto-generated AI prompt
├── SYNC-WORKFLOW.md          ← Detailed documentation
└── .cursor/
    └── commands/
        └── sync-update.md    ← AI agent template
```

## 🐛 Troubleshooting

**Q: Script says "permission denied"**
```bash
chmod +x sync-obsidian.sh run-ai-update.sh
```

**Q: No files synced but I know files changed**
- Check file modification times
- Files must be newer in Obsidian
- Verify `OBSIDIAN_VAULT` path is correct

**Q: AI doesn't find the prompt**
- Make sure you ran sync first
- Check `.ai-prompt.txt` exists
- Try `./run-ai-update.sh` to regenerate

**Q: Want to test without copying files?**
```bash
./sync-obsidian.sh --dry-run
```

## 💡 Tips

- Run `--dry-run` first if unsure what will change
- The `--auto-update` flag is your friend for regular syncs
- AI agent respects your campaign structure rules automatically
- All generated files are gitignored by default
- Session notes are the source of truth - AI never invents facts

## 📖 More Info

See [SYNC-WORKFLOW.md](SYNC-WORKFLOW.md) for detailed documentation and workflow diagrams.

---

**Made with ❤️ for your D&D campaign management**

