# Acceptance and playtest evidence

For each gameplay PR, report the Roblox place ID (never credentials), Studio version if relevant, test mode (Play Solo / Start Server + Players), and changed script paths.

## Required checks
- **Functional:** training input gives correct server-side power; ability activates, hits valid targets, respects cooldown, and cannot be spammed.
- **Server authority:** client cannot grant itself currency, stage access, wins, damage, or purchased abilities via forged remotes.
- **Persistence:** joining, leaving, rejoining, and DataStore failures do not corrupt or duplicate progress; handle Studio API limitations honestly.
- **Combat:** damage/respawn/rewards work with two or more players and multiple enemies.
- **Stage progression:** gates and spawn points respect ownership/unlock state; no accidental skip.
- **Controls:** mouse/keyboard, touch, controller have visible, functioning inputs.
- **Performance:** measure FPS/memory as stage and enemy counts scale; keep VFX efficient.
- **Errors:** include relevant Output window messages; do not call untested behavior verified.

## Evidence expected in pull requests
1. Description of what the player actually sees and does.
2. Actual test steps with pass/fail results.
3. Relevant screenshot/video links, if available.
4. Console errors/warnings (or explicitly 'none observed' with test mode).
5. Known limitations and follow-up issues.

A repository-only script review cannot substitute for an actual Roblox Studio playtest.
