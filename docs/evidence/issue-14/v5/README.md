# Issue #14 — owner direction 2026-11-02 (v5): implementation report

Studio place 72288975594385, branch `feature/issue-14-ui-lobby-polish`. Every change below is applied to live
Studio and playtested. All 20 scripts in `scripts/` were hash-checked against live Studio after the last
change, and they match.

## Backups (ServerStorage.Backups)
- `Scripts_preApplyPolish_20261102`: every script before the polish branch was applied.
- `StageCourse_170_pre85_20261102`: all 50 stages at the old 170-stud length.
- `Lobby_v4_pre_v5_20261102`: the previous lobby.

## What changed

### Gameplay
- **Stages:** stages are 85 studs long (was 170). All 50 stages were rebuilt with `WorldBuilder`.
- **Enemies per stage:** 5 regular enemies per stage, and a boss on every other stage (even stages plus stage 50).
  - `Config.HasBoss` and `Config.KillsToClear` decide this per stage.
- **No respawns:** a dead enemy stays dead. A set only comes back after the player has been away from that stage for 20 s.
- **Gate:** the gate opens exactly when the current set is dead. `GameService.ResetStageKills` runs whenever a new set spawns.
- **Enemy models:** enemies are stock R15 Roblox NPCs with the default idle and walk animations, played on the server Animator.
- **Melee range:** the old reach of 5.5 + 2 (7.5 studs) is now 4.5 studs, measured flat. A hit lands only if the player is in front of the enemy and at the same height.
- **Aggro and damage:** aggro radius is 24 studs (34 for bosses). Enemy damage is `2 + 1.5 × stage`. The enemy swing interval is 1.9 s.
- **HP bar:** no numbers. It shades green to yellow to red, like Roblox's own health bar.
- **Walk speed:** 28, which is 1.75 × 16. Set in `StarterPlayer` and enforced when a character spawns.
- **Hand signs:** the only requirement is Trophies, on both server (`BuySign`) and client.

### Lobby (LobbyBuilder v5)
- **WORLDS portal:** at the back (south edge). Players spawn in front of it facing north. The lobby is now its own arena at x = -560.
- **Portal touch:** touching the portal sends a new player to Stage 1 and opens the Worlds menu for everyone else. The prompt also opens the menu.
- **Roads:** Anime Eyes floor, lime studded lawns cut by lavender checker roads with dark-purple borders.
- **Lamps:** the lantern rows along the path are gone. 10 lanterns are spread around the lobby.
- **Training stations:** 13 original stations modelled in Blender:
  - Source: `tools/blender/training_stations.py`. The .blend is on the dev PC at `tools/blender/training_stations.blend`.
  - Pipeline: exported to `assets/blender/stations.json`, then built in Studio by `ServerStorage.Tools.StationKit`.
  - Spinners and bobbers animate on the client.
- **Showcase:** cartoon hand art floating above each pad, with the Anime Eyes text stack: name, "xN Hand Signs", then the trophy price or OWNED / EQUIPPED.
- **Eggs:** 4 eggs, shrunk about 20%:
  - Spirit Egg: 50 Trophies.
  - Flame Egg: 2.5K Trophies.
  - Shadow Egg: 79 R$.
  - Mythic Egg: 149 R$.
- **Special pet:** the pedestal sells the Nine-Tail Spirit Fox (x100, 799 R$).
- **Sign cleanup:** no more STAGE lines, requirement lines or hint banners on the signs.

### UI
- **Icons:** only the owner's Free Icon Pack 3.0.1. The store uses the red basket and Rebirth uses the pack's Rebirth icon. Source PNGs are in `assets/icons/pack`.
- **Studded backgrounds:** square bevelled studs on tiles and panels (`assets/textures/studs_square.png`).
- **Fonts:** Luckiest Guy for titles, tile labels and big numbers; Fredoka One for body text.
- **HUD buttons:** no Places/Stages or Upgrades buttons. Top right is now Codes, Daily, Gifts, Invite, Settings.
- **New panels:** 7-day Daily Rewards (Day 7 rainbow card plus "Unlock All"), Free Gifts (5 / 15 / 60 min with odds and timers), Quests, and a Store with Robux pets and eggs.
- **Rainbow text:** animated rainbow text on every Robux item (`UIKit.rainbow`), including world billboards.

### Pets and SFX
- **Pets:** new original ninja-themed pets for the 4 eggs, plus 3 Robux pets.
- **Saves:** legacy pets stay defined, so existing saves keep them.
- **SFX:** a new `Client.Sfx` module covers training, M1 swing and hit, hits taken, jutsu (fire / lightning / water / magic), explosions, enemy deaths, UI clicks, menus, purchases, rewards, level up, rebirth, stage clear, the portal and errors.
- **SFX sources:** only Roblox's licensed Pro Sound Effects and APM Music library assets, plus sounds that ship with the client.

## Playtest evidence (screenshots in this folder)
- **Stage 1 clear:** cleared in 21 s, with the player's HP never below 97/110.
- **Kills:** 5 kills paid 15 Trophies. Nothing respawned. The gate opened (GateReach 2), and Stage 2 unlocked.
- **Win popup:** "STAGE 1 CLEARED!" shows COLLECT WINS / x2 WINS / KEEP GOING. Collect paid +30 and teleported the player to the lobby.
- **Portal:** touching it as a new player teleported to Stage 1.
- **Daily:** Day 1 claim paid +50 Trophies. A second claim returned "Come back later".
- **Gift:** before its timer, it returned "Not ready yet".
- **Robux egg:** returns "not available yet" because the product Id is 0.
- **Spirit Egg:** hatched a Leaf Ninja Pup.
- **BuySign Ram:** with 45 Trophies, it returned "Need 130 Trophies". No stage check.
- **Console:** no script errors. The only output is the expected Studio DataStore "API access not enabled" fallback.

## Owner to-do (not done on purpose)
- **Developer products:** create them and paste the Ids into `SystemsConfig.DevProducts`: EggShadow, EggMythic, PetSpiritFox, PetKirinPup, PetToadSage, DailyUnlockAll. Until then they show "not available yet".
- **Game passes:** they still need Ids.
- **Publishing:** nothing was published.

## Known issues / for review
- Pose → sign mapping of the hand art still needs the owner's confirmation. Advanced and Forbidden still have no art ("?").
- The Golden Dojo roof wedges are simple. The Blender stations can be refined in `training_stations.py` and re-imported with StationKit.
- `StagePilot` restyled stages 1–3 for the 170-stud layout and has not been re-run on the 85-stud stages, so they use the standard WorldBuilder look.
- Some lobby BillboardGui text built at edit time doesn't lay out until its text changes. The lobby client nudges those labels once on join.
