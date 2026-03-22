# Obsidian <-> Quartz Sync

This repo's current sync entrypoint is:

```bash
./scripts/sync_v2.sh
```

Use that command unless you are intentionally working on a legacy script.

## What Actually Runs

`./scripts/sync_v2.sh` is the end-to-end workflow. It does not pause for manual Cursor chat work.

It uses:

- `obsidian-cli` to read markdown notes from Obsidian and write markdown notes back
- direct file copy for binary assets like `.png`, `.jpg`, `.jpeg`, `.gif`
- `codex exec --full-auto` to perform the automated repo update step
- `npx quartz build` to rebuild the site after Codex changes

The automated agent in the current workflow is Codex CLI, not Cursor Agent CLI.

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
3. Generate `.codex-sync-prompt.txt`
4. Run `codex exec --full-auto` and save the output to `.codex-sync-report.txt`
5. Build Quartz with `npx quartz build`
6. Preview merge-back candidates by comparing Quartz content directly against the Obsidian campaign folder
7. Merge changed or new files back to Obsidian after confirmation, or automatically with `--yes`
8. Write `.merge-back-log.txt`

## Source Of Truth Rules

- `content/Notes/` is treated as source-of-truth content imported from Obsidian session notes
- Codex must not modify files under `content/Notes/`
- Merge-back excludes `Notes/`
- Cross-references, indexes, locations, quests, characters, and timeline pages can be updated by Codex

In practice:

- Session notes flow from Obsidian into Quartz
- Derived knowledge pages flow back from Quartz into Obsidian

## Files Produced During A Run

- `.sync-log.txt`: exact files imported from Obsidian in the latest run
- `.codex-sync-prompt.txt`: prompt passed to Codex CLI
- `.codex-sync-report.txt`: Codex CLI output
- `.merge-back-log.txt`: files merged back into Obsidian

## Environment Overrides

If your Obsidian vault path or name differs, override these variables:

```bash
OBSIDIAN_VAULT_NAME=CloudVault
OBSIDIAN_ROOT_PREFIX=DND/Campaigns/Rebirth
OBSIDIAN_PROJECT_ROOT="$HOME/Documents/CloudVault/DND/Campaigns/Rebirth"
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
  - its `--auto-update` mode prepares a prompt for manual chat use rather than calling Codex CLI directly
- `./scripts/merge-back-obsidian.sh`
  - standalone merge-back helper
  - useful if you only want to export Quartz changes into Obsidian

If you want the full automated pipeline, call `./scripts/sync_v2.sh`.

## Troubleshooting

Missing dependencies:

```bash
obsidian-cli --version
codex --version
npx quartz --help
```

If the Obsidian folder is not a git repo, the sync still works. You just will not have git-based review or commit steps there.

If merge-back reports no work unexpectedly, run:

```bash
./scripts/merge-back-obsidian.sh
```

That script now compares all merge-eligible Quartz files directly against the Obsidian folder instead of relying only on the latest sync log.
