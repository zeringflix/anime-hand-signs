# ChatGPT ↔ GitHub ↔ Claude Code ↔ Roblox Studio

## What is available today
- ChatGPT can create GitHub Issues, branches, files and pull-request reviews through the connected GitHub integration.
- Claude Code already has an MCP connection to Roblox Studio on the owner's Windows computer (per owner).
- GitHub is the *shared source of truth* for task briefs, synchronized scripts, screenshots/test reports and review comments.

## Manual trigger workflow (works after Claude usage returns)
1. ChatGPT writes one scoped GitHub Issue with acceptance criteria.
2. Claude Code reads `CLAUDE.md` and that issue, opens a feature branch, and checks its Studio MCP connection.
3. Claude implements/test in Roblox Studio and ensures modified scripts are synced/exported to GitHub.
4. Claude commits changes and opens a PR with `.github/PULL_REQUEST_TEMPLATE.md`.
5. ChatGPT reviews the diff, checks reported Studio evidence and leaves a GitHub PR review.
6. Claude reads the review and fixes defects in the same branch; repeat as needed. Owner approves merges.

## Fully automatic handoffs (NOT CONFIGURED YET)
A repository cannot start a local Claude Code process on the owner's computer merely because an issue is created. To avoid copy/pasting after initial setup, install and start a **separate local Windows runner/bridge** which:
- Authenticates to this GitHub repository with minimum necessary permissions.
- Polls for GitHub issues explicitly marked ready for Claude, and handles each once.
- Invokes Claude Code in non-interactive mode with the selected issue plus instructions; keeps Roblox Studio open.
- Verifies Studio connection and sync before editing.
- Opens a PR, records test evidence and returns structured status.
- Triggers an OpenAI API-powered review of PR diffs, then posts feedback to GitHub.
- Caps retries, runtime, spend, and write scope; requires owner approval for destructive operations and merging.

This unattended director is an **OpenAI API process**, not this live browser conversation, and has separate API costs. Claude usage/API limits still apply. An always-on cloud-only GitHub Action is insufficient for local Studio access unless a secure, user-controlled runner is available. Do not expose the local MCP endpoint to the public internet.

## Recommended conventions
- Issue titles: `[STUDIO AUDIT]`, `[BUILD]`, or `[DESIGN]`.
- One issue, one branch, one PR; link the issue from the PR.
- Branch format: `feature/issue-N-short-description`.
- Keep `main` protected with required PR review when supported by repository settings.
- Keep secrets in local environment variables or GitHub Actions secrets, never in Git.
- If the owner's Claude plan is at its usage limit, queue tasks now; no automatic bypass exists.
