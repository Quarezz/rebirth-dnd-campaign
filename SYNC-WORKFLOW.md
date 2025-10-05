# Obsidian ↔ Quartz Sync Workflow

This document describes the complete workflow for syncing your D&D campaign between Obsidian and Quartz with AI processing.

## 📋 Overview

1. **Obsidian** - Your source of truth (session notes are edited here)
2. **Quartz** - Publishing platform (AI updates character/location/quest files here)
3. **AI Agent** - Processes session notes and updates cross-references

## 🔄 Complete Workflow

### Step 1: Sync from Obsidian to Quartz

```bash
./sync-obsidian.sh --auto-update
```

**What it does:**
- ✅ Syncs ALL files from Obsidian to Quartz
- ✅ Detects which files changed
- ✅ Shows verbose output of what was synced
- ✅ Displays AI processing request

**What to do:**
- Copy the AI prompt from terminal
- Paste it into Cursor chat
- AI will process and update files automatically

### Step 2: AI Processing

The AI will:
- ✅ Read new/modified session notes
- ✅ Update character files with new events
- ✅ Update location files with new information
- ✅ Update quest files with progress
- ✅ Update Хронологія_подій.md
- ✅ Update index.md with latest events
- ✅ Create cross-references between entities
- ✅ Fact-check everything against session notes

**IMPORTANT:** AI will NOT modify session notes (they are source of truth)

### Step 3: Merge AI Changes Back to Obsidian

First, preview what will be merged:

```bash
./merge-back-obsidian.sh
```

This runs in **DRY RUN mode** by default and shows what would be copied.

To actually merge the changes:

```bash
./merge-back-obsidian.sh --execute
```

**What it does:**
- ✅ Merges AI-modified files back to Obsidian
- ✅ EXCLUDES Notes/ folder (session notes never overwritten)
- ✅ Only copies files that actually changed
- ✅ Creates parent directories as needed
- ✅ Checks for conflicts

**What it merges:**
- ✅ Персонажі/ (character files)
- ✅ Локації/ (location files)
- ✅ Квести/ (quest files)
- ✅ Хронологія_подій.md
- ✅ index.md
- ✅ Resources/ (images)

**What it excludes:**
- ❌ Notes/ (session notes - source of truth)

### Step 4: Commit Obsidian Changes

```bash
cd /home/morf/Documents/OVault/DND/Campaigns/Rebirth
git status
git diff
git add .
git commit -m "AI updates: Session 47 processed"
git push
```

### Step 5: Build and Deploy Quartz

```bash
cd /home/morf/Downloads/quartz
npx quartz build
# or with preview:
npx quartz build --serve
```

## 🛡️ Safety Features

### sync-obsidian.sh
- Uses rsync with --checksum for accurate change detection
- Shows exactly what files changed
- Logs all synced files to `.sync-log.txt`
- Handles filenames with spaces correctly

### merge-back-obsidian.sh
- **Default DRY RUN mode** - won't copy unless you use --execute
- **Excludes Notes/ folder** - session notes never overwritten
- **Checks for Obsidian uncommitted changes** - warns before merging
- **Uses --force flag** - can override safety checks if needed
- **Compares files** - skips identical files
- **Logs all merges** to `.merge-back-log.txt`

## 📝 Quick Reference

### Full Workflow (One-Liner)
```bash
# 1. Sync to Quartz and process with AI
./sync-obsidian.sh --auto-update
# (paste prompt into Cursor chat)

# 2. Preview merge-back
./merge-back-obsidian.sh

# 3. Execute merge-back
./merge-back-obsidian.sh --execute

# 4. Commit to Obsidian
cd ~/Documents/OVault/DND/Campaigns/Rebirth && git add . && git commit -m "AI updates" && git push

# 5. Build Quartz
cd ~/Downloads/quartz && npx quartz build
```

## 🎯 Best Practices

1. **Always review AI changes** before merging back to Obsidian
2. **Commit Obsidian changes** regularly to track AI modifications
3. **Use dry-run mode first** to preview what will be merged
4. **Keep session notes in Obsidian** - never edit them in Quartz
5. **Rebuild Quartz** after merging to see updates on your site

## 🔧 Troubleshooting

### "Obsidian has uncommitted changes"
```bash
# Option 1: Commit your changes first
cd ~/Documents/OVault/DND/Campaigns/Rebirth
git add . && git commit -m "Manual updates"

# Option 2: Use force flag (not recommended)
./merge-back-obsidian.sh --execute --force
```

### "No files to merge"
This means Quartz has no uncommitted changes. This is normal if:
- You just synced from Obsidian
- AI hasn't processed anything yet
- All AI changes were already merged back

### Files with spaces not working
Both scripts handle spaces correctly. If you see issues:
- Make sure file names use proper encoding
- Check that both Obsidian and Quartz use UTF-8

## 📊 File Tracking

- **`.sync-log.txt`** - Files synced from Obsidian to Quartz
- **`.merge-back-log.txt`** - Files merged from Quartz to Obsidian

These logs help you track what changed and when.

## ⚠️ Important Notes

- **Session notes are read-only in this workflow** - edit them only in Obsidian
- **AI updates are always in Quartz first** - then merged back to Obsidian
- **Git is used for change detection** - both repos should be git repositories
- **Always review before committing** - AI can make mistakes

## 🎉 Benefits

✅ **Automated cross-referencing** - AI maintains links between entities  
✅ **Consistent formatting** - All files follow the same structure  
✅ **Fact-checked** - AI verifies against session notes  
✅ **Bi-directional sync** - Changes flow both ways safely  
✅ **Source of truth preserved** - Session notes never modified by AI  
✅ **Version controlled** - All changes tracked in git  
