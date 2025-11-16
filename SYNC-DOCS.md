# 🔄 Obsidian ↔ Quartz Sync System

Simple workflow to sync your D&D campaign notes between Obsidian and Quartz with AI processing.

## ⚡ Quick Start

```bash
# Run the complete workflow
./scripts/sync-workflow.sh
```

**What it does:**
1. Imports from Obsidian to Quartz
2. Pauses for manual AI processing
3. Rebuilds Quartz site
4. Exports changes back to Obsidian

## 📋 Scripts

### `scripts/sync-workflow.sh` - **Main Workflow**
Interactive script that handles the complete sync process.

### `scripts/sync-obsidian.sh` - **Import from Obsidian**
Syncs files from your Obsidian vault to Quartz content folder.

### `scripts/merge-back-obsidian.sh` - **Export to Obsidian**
Exports AI-modified files back to your Obsidian vault.

## ⚙️ Configuration

Edit paths in `scripts/sync-obsidian.sh`:

```bash
OBSIDIAN_VAULT="/home/morf/Documents/OVault/DND/Campaigns/Rebirth"
QUARTZ_CONTENT="$PROJECT_ROOT/content"
```

## 🛡️ Safety

- **AI never modifies session notes** (they stay in Obsidian as source of truth)
- **Dry-run mode available** for all operations
- **Git tracking** for all changes

## 🐛 Troubleshooting

**Permission denied:**
```bash
chmod +x scripts/*.sh
```

**No files synced:**
- Check file modification times
- Verify Obsidian vault path

**Obsidian has uncommitted changes:**
```bash
cd ~/Documents/OVault/DND/Campaigns/Rebirth
git add . && git commit -m "Manual updates"
```

---

**Simple, safe, effective sync workflow for your D&D campaign.**
