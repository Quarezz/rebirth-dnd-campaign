# Obsidian <-> Quartz Sync

This repo's current sync entrypoint is:

```bash
./scripts/sync_v2.sh
```

Use that command unless you are intentionally working on a legacy script.

## What Actually Runs

`./scripts/sync_v2.sh` is the end-to-end workflow. It does not pause for manual Cursor chat work.

It uses:

- `obsidian-cli` to read markdown notes from Obsidian during import
- direct file copy to merge derived markdown pages back into the local Obsidian campaign folder
- direct file copy for binary assets like `.png`, `.jpg`, `.jpeg`, `.gif`
- `cursor-agent --print --force --trust` to perform the automated repo update step
- `npx quartz build` to rebuild the site after Cursor Agent changes

The automated agent in the current workflow is Cursor Agent CLI, using Cursor Grok 4.6 (`cursor-grok-4.6-high`) by default.

## Recommended Commands

Normal run:

```bash
./scripts/sync_v2.sh
```

Dry-run everything without writing files:

```bash
./scripts/sync_v2.sh --dry-run
```

Run non-interactively and auto-approve merge-back:

```bash
./scripts/sync_v2.sh --yes
```

Proceed even if the Obsidian campaign folder has git changes:

```bash
./scripts/sync_v2.sh --force
```

Show help:

```bash
./scripts/sync_v2.sh --help
```

## How The Workflow Works

`./scripts/sync_v2.sh` performs these steps in order:

1. Import from Obsidian into `content/`
2. Write `.sync-log.txt` with the files imported in the current run
3. Generate `.cursor-sync-prompt.txt`
4. Run `cursor-agent` with Cursor Grok 4.6 and save the output to `.cursor-sync-report.txt`
5. Build Quartz with `npx quartz build`
6. Preview merge-back candidates by comparing Quartz content directly against the Obsidian campaign folder
7. Merge changed or new files back to Obsidian after confirmation, or automatically with `--yes`
8. Write `.merge-back-log.txt`

## Source Of Truth Rules

- `content/Notes/` is treated as source-of-truth content imported from Obsidian session notes
- Cursor Agent must not modify files under `content/Notes/`
- Merge-back excludes `Notes/`
- Cross-references, indexes, locations, quests, characters, and timeline pages can be updated by Cursor Agent
- The homepage and campaign dashboard update uses `CAMPAIGN-DASHBOARD-PROMPT.md`, including its five result-scoring iterations

In practice:

- Session notes flow from Obsidian into Quartz
- Derived knowledge pages flow back from Quartz into Obsidian

## Files Produced During A Run

- `.sync-log.txt`: exact files imported from Obsidian in the latest run
- `.cursor-sync-prompt.txt`: prompt passed to Cursor Agent, including the embedded campaign dashboard prompt
- `.cursor-sync-report.txt`: Cursor Agent CLI output
- `.merge-back-log.txt`: files merged back into Obsidian

## Environment Overrides

If your Obsidian vault path or name differs, override these variables:

```bash
OBSIDIAN_VAULT_NAME=CloudVault
OBSIDIAN_ROOT_PREFIX=DND/Campaigns/Rebirth
OBSIDIAN_PROJECT_ROOT="$HOME/Documents/CloudVault/DND/Campaigns/Rebirth"
```

To change the agent binary or model:

```bash
CURSOR_AGENT=cursor-agent
CURSOR_MODEL=cursor-grok-4.6-high
```

Example:

```bash
OBSIDIAN_PROJECT_ROOT="/path/to/Rebirth" ./scripts/sync_v2.sh
```

## Legacy Scripts

These exist, but they are not the primary workflow anymore:

- `./scripts/sync-workflow.sh`
  - old interactive flow
  - documentation and prompts still describe manual Cursor processing
- `./scripts/sync-obsidian.sh`
  - older import-oriented flow
  - its `--auto-update` mode prepares a prompt for manual chat use rather than calling Cursor Agent directly
- `./scripts/merge-back-obsidian.sh`
  - standalone merge-back helper
  - useful if you only want to export Quartz changes into Obsidian

If you want the full automated pipeline, call `./scripts/sync_v2.sh`.

## Troubleshooting

Missing dependencies:

```bash
obsidian-cli --version
cursor-agent --version
npx quartz --help
```

If the Obsidian folder is not a git repo, the sync still works. You just will not have git-based review or commit steps there.

If merge-back reports no work unexpectedly, run:

```bash
./scripts/merge-back-obsidian.sh
```

That script now compares all merge-eligible Quartz files directly against the Obsidian folder instead of relying only on the latest sync log.
