# Issue #2 — Studio audit: +1 Anime Hand Signs

- **Audit date:** 2026-11-01
- **Branch:** `ai/issue-2`
- **Auditor:** Claude Code (Sonnet 5.5), non-interactive runner session
- **Scope:** read-only. No Studio edits, no playtest, no gameplay-file edits. The only repo change is this report.
- **MCP server used:** official `Roblox_Studio` only. The ShiroKSH `plugin:roblox-studio:roblox-studio` tools were not used.

## 1. Connection and identifiers

| Item | Value | Source |
|---|---|---|
| MCP server | official `Roblox_Studio` | `list_roblox_studios` |
| Studio instance ID | `87223762-ef9f-4c1c-82c9-fd2779d858fc` | `list_roblox_studios` |
| Open place | `+1 Anime Hand Signs (placeId: 72288975594385)` | `list_roblox_studios` |
| Studio mode | Edit (not playing); only the `Edit` DataModel is available | `get_studio_state` |
| Number of Studio instances | 1 | `list_roblox_studios` |

The official MCP connection works in the runner's non-interactive session.

**Tools that worked:** `list_roblox_studios`, `get_studio_state`, `get_console_output`, `search_game_tree`, `inspect_instance`, `script_read`, `script_search`.

**Tool that was refused:** `execute_luau` (permission not granted).
- The refusal is expected: the project policy puts Luau execution behind "ask".
- This blocked bulk checks such as a full-hierarchy walk and a hash comparison of live and repo sources.
- All findings below use read-only tools only.

**Team Create:** the Output log shows `Lausming joined live editing session.` Another collaborator is in the live session, so the live place can change independently of this audit.

## 2. Backup confirmation

- **Not independently verified by me.** The setup notes on issue #2 say the owner confirmed an actual local `.rbxl` backup was downloaded.
- I cannot see the file system from Studio through the MCP, and I did not make a backup myself.
- No writes were made to Studio, so no backup was needed for this audit.
- **Before any write issue starts:** confirm the backup is recent enough. The live place contains work that is not in GitHub (section 6).

## 3. Hierarchy inventory (live Studio, Edit mode, 2026-11-01)

### ServerScriptService
- `Main` (Script)
  - Matches `scripts/ServerScriptService/Main.legacy.luau` (41 lines, same content on read).
- `Services/` (Folder), five ModuleScripts:
  - `DataService`
  - `GameService`
  - `EnemyService`
  - `AbilityService`
  - `SystemsService`

### ReplicatedStorage
- `Shared/` (Folder), three ModuleScripts:
  - `Config`
  - `SystemsConfig`
  - `Assets`
- There is **no** `Remotes` folder in Edit mode. `GameService` creates it at runtime: 9 RemoteEvents plus the `Action` RemoteFunction.

### StarterPlayer.StarterPlayerScripts.Client (not in GitHub)
- `Main` (LocalScript)
- `HUD`, `Menus`, `UIKit`, `VFX`, `Anim`, `Looks` (ModuleScripts)

### StarterGui
- Empty. All UI is built by script.

### ServerStorage (not in GitHub)
- `StageBuilder` (ModuleScript)
- `Tools/WorldBuilder` and `Tools/PROGRESS` (ModuleScripts)
  - `PROGRESS` is a checklist comment that returns `nil`.
- `Tools/Kit/` (Models): `TrophyStatue`, `StoneLantern`, `PostLantern`
  - These are MeshParts, with PointLights on the lanterns.

### Workspace
- `StageCourse` (Folder) holding **50** Models, `Stage01` to `Stage50`.
- `Terrain`, `SpawnLocation`, `Camera`.
- **No** `Lobby` model, and no Instance named Lobby, Hub or Plaza.
- **No** `Enemies` folder in Edit mode. `Client.Main` waits for it, so presumably the server creates it at runtime. I did not verify that.

**Per-stage structure** (inspected on `Stage01`, `Stage05`, `Stage11` and `Stage16`):

| Child | Type |
|---|---|
| `Floor` | Model |
| `Decor` | Model |
| `Cliffs` | Model |
| `Gate` | Model |
| `EnemySpawns` | Folder |
| `Spawn`, `TrophyPad` | Part |
| `Boundary` | Part (x2) |
| `Part` | Part (x2) |

- `Stage01` has 360 descendants.
- The two unnamed `Part` children per stage look like generated leftovers. I did not identify them.

### Lighting
- `Sky`, `SunRays`, `Atmosphere`, `Bloom`, `DepthOfField`, `StageGrade` (ColorCorrection).
- `Client.Main` tweens `Atmosphere` and `StageGrade` per stage.

### Players
- `Lausming` is present (the Team Create collaborator).

## 4. Systems inventory: what the code does

This section comes from reading the live source. **I did not run the game**, so none of it is playtest-verified. The "TESTED" labels in `ServerStorage.Tools.PROGRESS` are the owner's or a previous agent's claims and are unverified by this audit.

| System | Evidence in live code | Status per code reading |
|---|---|---|
| Training (+1 taps) | `Client.Main` batches taps every 0.2s to `Remotes.Train`. `GameService` rate-limits to `Config.Economy.MaxTrainsPerSecond` = 12. | Implemented; server-capped |
| Hand signs | 14 signs in `Config.HandSigns`, each with an E and an R jutsu. `Menus.Signs` equips via the `EquipSign` remote. | Implemented |
| Jutsu / abilities | 28 jutsu in `Config.Jutsu`. `AbilityService` handles the `Attack` and `Cast` remotes with cooldowns. | Implemented per code |
| Enemies and bosses | `EnemyService` spawns enemies per stage when players are nearby. Final-boss logic keys on `Config.StageCount`. Client HUD shows a boss bar and phase celebrations. | Implemented per code |
| Stages | 50 stage models in Workspace. `Config.Stages` has 50 rows (live `Config` lines 86-135). Gates are per-player on the client; the server guards the real check. | Implemented |
| Trophy pads | `ServerScriptService.Main` wires `Touched` to `GameService.ClaimPad`, with a debounce. | Implemented |
| Data | `DataService` has session locking, a lease, fenced saves, autosave and BindToClose. It falls back to memory-only if the store is unavailable. | Implemented; `PROGRESS` says persistence is unverified (place unpublished) |
| Pets, auras, upgrades, rebirth, offline, daily, playtime, milestones, codes | `SystemsService` plus `Menus` panels. | Implemented per code |
| Leaderboards | `SystemsService` uses OrderedDataStores `LB_<stat>_v1`. | Implemented; `Menus.Top` says "Updates on live servers" |
| Monetization | Game passes and dev products exist in `SystemsConfig`; per `PROGRESS` all IDs are 0, so they are disabled ("SOON"). | Placeholder (IDs 0) |
| Codes | `PROGRESS`: the codes table is empty on purpose. | Placeholder |
| HUD / UI | Full ScreenGui built by `Client.HUD` and `Client.Main`. Menus for Signs, Pets, Auras, Upgrades, Rebirth, Stages, Rewards, Shop, Top, Codes, Settings. Touch and gamepad inputs are present. | Implemented per code |
| Sounds | Roblox built-in `rbxasset://sounds/` only. | Placeholder-grade |
| Icons | `Shared.Assets` references uploaded images. I did not check asset ownership or licence. | Unverified |

**Placeholders and gaps called out in `PROGRESS`:**
- Menus still use emoji in a few card spots.
- No custom animations or sounds.
- Real game pass and product IDs are missing.
- The balance pass is not done.
- The mobile layout is unchecked.

**Not present in the place (owner direction in `PROGRESS`, 2026-11-01 12:57, items 2 to 6):**
- A lobby hub with showcase pads, training stations, egg row, fuse machine, boss shop, worlds portal and leaderboards.
- Hand-sign emblem on the ATTACK, E and R buttons.
- A 30-stage remap.
- A VFX remake.
- The offline, "DON'T LEAVE YET!" and "COME BACK TOMORROW" popups.

## 5. Output / console errors

`get_console_output` was read at the start and the end of the audit, with identical content:

```
Lausming joined live editing session.
debug.profileEnd() - No active profile annotation. At: Stack Begin
Script 'MaterialManager.MaterialManager.Packages._Index.ReactReconciler... RobloxReactProfiling', Line 65 ...
... (React/Roact stack frames from the MaterialManager plugin) ...
Stack End
```

- The only warning comes from the **MaterialManager Studio plugin** (React profiling). It is not from game code.
- No errors or warnings from `ServerScriptService`, `Client`, `ReplicatedStorage` or `ServerStorage` were present.
- **This reflects Edit mode only.** Runtime errors from a playtest are untested, because the audit was read-only and I did not start a playtest.

### Runtime risks found by reading code

1. **Missing lobby.**
   - Live `GameService.StageSpawnCFrame(0)` looks for `workspace.Lobby.LobbySpawn`, which does not exist.
   - It silently falls back to stage 1.
   - The live PlayerAdded handler calls this on every spawn (the comment says "everyone spawns in the lobby hub").
   - Result: spawning works but goes to stage 1, not a lobby.
2. **Reference to a missing script.**
   - Live `GameService.TrainingMultiplier` reads attribute `ZoneMult` and says it is "set server-side by LobbyService".
   - No script named `LobbyService` exists (`script_search` for "Lobby" returned nothing).
   - `ZoneMult` defaults to 1, so there is no error, but the feature is half-wired.
3. **Contradictory stage count.**
   - The live comment says "course shrank from 50 to 30 stages", yet `Config` still defines 50 stages and Workspace has 50 stage models.
   - The clamp logic is therefore a no-op today. Whoever finishes the 30-stage change must handle stages 31 to 50 deliberately.
4. **Documentation drift.**
   - `PROGRESS` says Ram = Dragon Flame (E) and Rasengan moved to Horse "DONE in Config".
   - Live `Config.HandSigns` has Ram = `Rasengan` / `ShadowClone` and Horse = `DragonFlame` / `MajesticFlame`.
   - Either `PROGRESS` is ahead of `Config` or the change was reverted. I did not resolve this.
5. **Rate-limit and server authority.** Both are present in the code I read.
   - `Train` uses a token bucket.
   - The client only fires batched counts.
   - Gates are enforced server-side, with the client barrier cosmetic only (per the code comment).
   - I did not audit every remote handler for forged-argument handling. That needs its own issue.
6. **Studio edit-time builders** (`StageBuilder`, `WorldBuilder`) can destroy and rebuild stage models by name.
   - `BuildStage` destroys any existing `StageNN`, and `SetupWorld` destroys `Baseplate` and `SpawnLocation`.
   - Those functions must never run against the live place without a fresh backup.

## 6. Script Sync status and evidence

**Verdict: sync is NOT verified. The GitHub tree does NOT equal live Studio state. Do not treat `scripts/` as authoritative.**

### What I could and could not check

- **Studio side:** no Script Sync configuration is visible through the read-only tools. Not-visible does not mean not-enabled.
  - I did not confirm the mapping from Studio services to repo folders.
  - I did not confirm whether Script Sync is connected to `C:\Users\zerin\anime-hand-signs\scripts`.
  - I did not confirm sync direction or behaviour on conflicts.
- **Repo side:** the working tree has no sync marker files (no `*.project.json`, no Rojo config). The repo's `.claude` directory holds only `settings.json` and `settings.local.json` (not opened in this audit).
  - `docs/STUDIO_MCP_PERMISSIONS.md` warns "Script Sync means local file edits may immediately affect Studio". I could not confirm this.
- **Round trip:** not tested, on purpose. A write test could overwrite live scripts, which this audit forbids.

### Live-vs-repo comparison of exported scripts

I compared full text for `ServerScriptService.Main` and `DataService` lines 1 to 60. For the rest I compared tail lines and line counts.

| Script | Repo lines | Live lines | Result |
|---|---|---|---|
| `ServerScriptService/Main` | 41 | 41 | **Match** (read in full) |
| `Shared/Config` | 195 | 195 | Same length and same end |
| `Shared/SystemsConfig` | 168 | 168 | Same length and same end |
| `Shared/Assets` | 43 | 44 | **Differs by +1 line** |
| `Services/AbilityService` | 590 | 590 | Same length and same end |
| `Services/DataService` | 211 | 212 | **Differs** (live Default() has extra fields) |
| `Services/GameService` | 340 | 357 | **Differs** (live has lobby code) |
| `Services/EnemyService` | 477 | 510+ | **Differs** (live is longer than the repo copy) |
| `Services/SystemsService` | 470 | 500+ | **Differs** (live is longer than the repo copy) |

Same-length rows are weak evidence; I did not diff their contents.

**Concrete drift evidence (live has, repo lacks):**
- `DataService.Default()` has `KyubiCoins`, `TrophyBoostUntil` and `LastLeaveBonus`. The repo's `Default()` ends at `ClaimedMilestones`.
- `GameService.LobbySpawnCFrame`, plus `StageSpawnCFrame(0)` handling.
- The `ZoneMult` multiplier hook.
- The "course shrank from 50 to 30" clamp.
- Repo-wide search for `Lobby` and `ZoneMult` in `scripts/`: no matches.

**Consequence:** the live place contains work newer than the GitHub copy (PRs #7 and #8). If anyone pushes the current repo `scripts/` back into Studio through Script Sync, they would likely **overwrite and regress** that live work.

### Not exported yet
- All `StarterPlayerScripts.Client.*` scripts: `Main`, `HUD`, `Menus`, `UIKit`, `VFX`, `Anim`, `Looks`.
- `ServerStorage.StageBuilder` and `ServerStorage.Tools.WorldBuilder` / `PROGRESS`.

These are known gaps, per the setup notes. I did **not** copy them into the repo in this audit. Doing it by hand through `script_read` risks transcription errors, and the issue wants Script Sync to be the export method.

### Other repo observations
- The exported server entry script is named `Main.legacy.luau`, not `Main.server.luau`. Script Sync may name or classify it differently from how it is classified in Studio; confirm the mapping.
- `ReplicatedStorage.Shared.Assets`, `Config` and `SystemsConfig` are on both sides.

## 7. Working, placeholder, missing

- **Appears implemented per code (unplaytested here):**
  - Core loop: training, signs, jutsu, enemies, bosses, 50 stage models, gates, trophy pads.
  - Data layer with session locking.
  - Systems: pets, auras, upgrades, rebirth, rewards.
  - Full HUD and menus.
  - Per-stage mood.
- **Placeholders / disabled:**
  - Game passes and dev products (IDs 0).
  - Codes (empty).
  - Built-in Roblox sounds.
  - Emoji in menus.
  - Leaderboards (live-server only).
- **Partially done / inconsistent:**
  - Lobby: code references exist; no Lobby model and no `LobbyService`.
  - 30-stage change: comment only; 50 stages everywhere.
  - Ram / Horse jutsu swap: `PROGRESS` and `Config` disagree.
- **Missing (not in the place):**
  - The lobby hub.
  - The popup flows.
  - The VFX remake.
  - The sign emblem on the ability buttons.
- **Unverified:** persistence, monetization, mobile layout, multiplayer combat, performance, asset licensing.

## 8. Blockers and unanswered questions

1. **Sync direction and ownership.**
   - Is Script Sync actually connected to this repo folder, and in which direction?
   - Until then the repo should be treated as a stale snapshot, not as Studio's source of truth.
2. **Stale repo.**
   - Who owns the unexported lobby/currency work (`KyubiCoins`, lobby code in `GameService`)?
   - It is in Studio but not in GitHub.
   - Was it Team Create collaborator `Lausming`, the owner, or an earlier agent?
3. **Backup recency.**
   - Was the `.rbxl` backup taken before or after that lobby-related work?
4. **Lobby intent.**
   - Is the lobby to be built next, per the 12:57 direction?
   - The code expects `workspace.Lobby.LobbySpawn`.
5. **Stage count.**
   - Should the course be 30 or 50 stages?
   - Config, the world and the live comment disagree.
6. **Ram / Horse signs.**
   - Which is authoritative, `PROGRESS` or `Config`?
7. **Permissions for the next issue.**
   - A build issue needs approved Studio write tools, since `execute_luau`, edit and playtest tools are currently "ask".
   - An unattended runner cannot answer a prompt, so the next issue needs an explicit scoped policy.

## 9. Recommended next steps

1. **Owner:** verify Script Sync in Studio. Open the Script Sync settings, confirm the folder mapping, and report whether it is two-way.
2. **Do not push the repo's current `scripts/` into Studio.** First export Studio's current server and shared scripts into the repo (a Studio-to-repo export), so `GameService`, `DataService`, `EnemyService`, `SystemsService` and `Assets` catch up.
3. **Export the client and ServerStorage scripts** (`Client.*`, `StageBuilder`, `WorldBuilder`, `PROGRESS`) with the same method. Review the resulting diff.
4. **Take a fresh `.rbxl` backup** right before any write issue.
5. **Run a playtest audit as its own issue.**
   - Include Play Solo and Start Server with 2 players.
   - Check Output for runtime errors, the lobby spawn fallback, stage 1 to 3 progression, E/R casts, gates and trophy pads.
   - Playtest tools are not allowed without a permission change.
6. **Resolve the questions in section 8** (stage count, lobby, jutsu mapping) before ChatGPT specs the build issues.
7. **Later, design a remote-security review issue** that covers `Action`, `Cast`, `Train`, `EquipSign` and `TeleportStage` for forged arguments and rate limits.

## 10. Evidence log

All calls made with the official `Roblox_Studio` MCP, studio ID `87223762-ef9f-4c1c-82c9-fd2779d858fc`, on 2026-11-01.

- `list_roblox_studios` returned the one instance above.
- `get_studio_state` reported Mode: Edit.
- `get_console_output` was called at the start and again after the script reads. Both outputs were identical.
- `search_game_tree` was used on the whole tree, `BaseScript` instances, `ServerScriptService`, `ReplicatedStorage`, `StarterPlayer`, `StarterGui`, `ServerStorage`, `Workspace.StageCourse`, `Lighting`, and for Lobby/Hub/Plaza keywords.
- `inspect_instance` was used on `Workspace.StageCourse.Stage01`.
- `script_read` was used on `ServerScriptService.Main` (full), `Client.Main`, `Client.HUD`, `Client.Menus`, `ServerStorage.StageBuilder`, `ServerStorage.Tools.PROGRESS` (full), and selected ranges of the shared and service modules.
- `script_search` for "Remotes" and "Lobby" returned no matches.
- `execute_luau` was attempted once and refused (permission not granted). It was not retried.

**Not done:** no playtest, no screenshots, no viewport capture, no Output from a running game, no Script Sync round trip, no independent backup check.
