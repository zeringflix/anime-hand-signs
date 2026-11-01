# One-time Windows setup for the local GitHub → Claude → OpenAI workflow

This runner is **opt-in**. Installing or checking it never sends a job to Claude or edits Roblox Studio. It runs on your Windows PC, where Roblox Studio and Claude MCP are installed.

## Prerequisites

- Git and GitHub CLI installed; `gh auth status` succeeds.
- Claude Code installed and signed in; `claude --version` and `claude mcp list` work.
- Python 3.10+ installed; `py --version` works.
- Studio open with existing Claude MCP connection; a manually saved **.rbxl backup** of the open game.
- OpenAI API key with billing configured, separate from ChatGPT Plus. Claude subscription/API quota also applies.

## Install (no Claude usage required)

```powershell
cd "$HOME\anime-hand-signs"
git pull --ff-only
py -m pip install -r tools\requirements.txt
py tools\ai_runner.py --check
py tools\ai_runner.py --setup-labels
```

If `claude --version` isn't recognized, install Claude Code before using the runner; the runner can't install or configure Studio MCP itself.

## How to queue and run the first task (only after backup)

1. Check Studio is open, Claude Code MCP is connected, and script sync has been configured or can be safely established.
2. Make an actual copy of your Roblox place and verify it opens.
3. Set an **environment variable in this PowerShell session only** (never paste API keys into ChatGPT or GitHub):

```powershell
$env:OPENAI_API_KEY = Read-Host "OpenAI API key (input visible; avoid screen sharing)"
$env:ROBLOX_BACKUP_CONFIRMED = "YES"
$env:OPENAI_MODEL = "gpt-5.5"  # change if your API account uses another supported model
```

4. Add the **ai-ready** label to issue #2 to queue the read/inspect-first Studio audit:

```powershell
gh issue edit 2 -R zeringflix/anime-hand-signs --add-label ai-ready
py tools\ai_runner.py --once
```

5. After a successful test, use `py tools\ai_runner.py --watch` to watch for new `ai-ready` issues. Keep the PowerShell window and Roblox Studio open; **Ctrl+C stops**. No scheduled startup is configured by default.

## What the runner actually does

- Reads only owner-authored issues explicitly marked `ai-ready`.
- Creates one issue-specific Git branch.
- Invokes Claude Code in non-interactive mode with the issue and repository instructions.
- Rejects file changes outside approved game/documentation directories; never auto-merges, publishes or deploys.
- Pushes changes to a **draft PR** and sends its diff to the configured OpenAI API model for automated code review.
- Posts review feedback to that PR and makes at most one correction pass, then stops for **owner review**.
- Marks failures as `ai-needs-attention` rather than repeatedly charging calls or forcing progress.

The OpenAI API reviewer is **not this live ChatGPT conversation**. Code review cannot replace verifying live gameplay in Roblox Studio. Do not use this runner on a Studio place you haven't backed up. Claude usage limits still apply; no quota bypass is provided.

## Troubleshooting

- `claude not found`: make sure Claude Code is installed and on PATH; restart PowerShell.
- `OPENAI_API_KEY not set`: configure it locally; never commit it.
- `Studio MCP disconnected`: open Roblox Studio and check Claude MCP status.
- `No Git changes`: inspect whether Script Sync/Rojo has exported the Studio script changes into the working tree.
- `ai-needs-attention` label: check the issue comment and PR; do **not** blindly requeue after a partial failure, as a branch may already exist.
- `Unexpected changed paths`: review the affected files manually; the runner intentionally stops rather than committing secrets or automation config files.

## Safety limitations

`--permission-mode acceptEdits` authorizes some noninteractive edits, so **do not run** until you are comfortable with this and have a place backup. The runner does not bypass Claude's own MCP/tool authorization prompts or guarantee it can operate unattended on all Studio commands. No cloud-to-local MCP endpoint is exposed.
