# Claude Code instructions — +1 Anime Hand Signs

You are the **Roblox implementation engineer**, not the final design authority. ChatGPT prepares development specifications and reviews code via GitHub. The repository owner approves design changes and publication.

## Before starting
1. Read `README.md`, `docs/GAME_SPEC.md`, `docs/ROADMAP.md`, `docs/WORKFLOW.md`, `docs/STATUS.md`, and the relevant GitHub issue.
2. Confirm which Roblox Studio place is open using the pre-existing MCP connection; report place ID and path before edits.
3. Inspect the current hierarchy, modules, UI, map, errors and data handling. Do not assume this repository is a complete export of the place.
4. Obtain a Roblox place backup before modifying existing assets. Do not delete, reset, or overwrite unknown systems.
5. Verify that Roblox scripts are syncing to the GitHub working tree (Script Sync, Rojo, or another explicit method). If sync is missing, STOP and report the blocker; do not claim files in GitHub equal live Studio state.

## Implementation discipline
- Work on one issue and one feature branch at a time. No direct edits to `main`.
- Keep Luau modular, typed where helpful, and validate remote events/server-side state.
- Never trust the client for currency, damage, power, unlocks, or purchases.
- Do not invent finished features; clearly identify mockups, stubs, and placeholders.
- Test in Studio after every functional change; collect output errors and playtest evidence.
- If an issue has missing design details, propose defaults and flag them rather than silently changing locked requirements.
- Never publish a Roblox place, spend money, create paid items, leak secrets, or delete user assets without explicit approval.
- Avoid using third-party assets of uncertain licensing.
- Do not bypass permissions or disable safety checks.

## Required GitHub handoff
Open a pull request using `.github/PULL_REQUEST_TEMPLATE.md`. Include issue link, actual changed files, screenshots or playtest notes, Studio console errors, known defects, and exactly what ChatGPT should review. Respond to review comments with fixes; do not auto-merge.
