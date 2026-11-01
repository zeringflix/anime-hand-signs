# Roblox Studio MCP permissions
These project-scoped Claude Code permissions are only for the **official** `Roblox_Studio` server. They intentionally do not allow the third-party ShiroKSH bridge.

- `allow`: named read-only inspection tools used during Studio audit issue #2.
- `ask`: any listed tool that modifies Studio, executes Luau, controls the game, or creates assets. Unattended `claude -p` sessions cannot answer these prompts and should stop rather than bypass.
- The local runner still requires the user's backed-up place and may edit repository files through Claude's `acceptEdits` file mode. **Script Sync means local file edits may immediately affect Studio**, so do not queue gameplay-building jobs before extra safeguards are set up.
- Do not use `--dangerously-skip-permissions` or wildcard `mcp__Roblox_Studio__*` allow rules.
- This does not grant human review approval or guarantee an MCP connection. Verify the instance ID/Place ID returned by `list_roblox_studios` before future changes.
- To permit automated gameplay development later, design a reviewed, scoped change policy; do not remove these guardrails indiscriminately.
