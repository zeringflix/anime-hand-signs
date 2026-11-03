# +1 Anime Eyes lobby → +1 Anime Hand Signs lobby (build reference, issue #14)

**Source of truth:** five owner-provided screenshots of the live +1 Anime Eyes lobby (Bando Interactive, place 97617452700163), stored in `docs/reference/anime-eyes/`. No other footage was accessible from this environment:
- No Roblox player client.
- Web search found only code-listing pages.

Anything not visible in these shots is marked **UNVERIFIED** and placed by inference.

**No assets were copied.** Every model, sign, emblem and icon in `Workspace.Lobby` is new, built from parts, or comes from the owner's licensed gvesster icon pack.

| Reference shot | What it shows |
|---|---|
| `ref_worlds_portal_path.png` | Main path view: lantern-lined path to the WORLDS portal; special pet + leaderboards left; boss rift right |
| `ref_training_field_a.png`, `ref_training_field_b.png` | Training station field (X2…X250 CHAKRA) |
| `ref_eye_showcase.png` | Eye showcase: 2 rows × 7 pads |
| `ref_egg_walkway.png` | Egg walkway with Fuse Machine + Boss Shop |

## Observed layout

**Arena**
- Flat lavender checker floor, studded, in two tones. **Observed.**
- Lime-green lawns with darker rims. **Observed.**
- The arena is enclosed by blocky stepped red-brown dirt cliffs with grass tops and pine trees on them. **Observed** in every shot.

**Main path**
- Light lavender/white path with white edges, lined on both sides by black square stone lanterns with glowing tops. **Observed.**

**WORLDS portal**
- Sits at the end of the main path: a dark stone frame with a "WORLDS" header and a glowing magenta ring. **Observed.**

**Left of the portal (facing it)**
- Special-pet pedestal with a glowing dais, posts and light beams. **Observed.**
- Purple-framed leaderboards behind it (CHAKRA, TROPHIES…). **Observed.**

**Right of the portal**
- Boss rift: a dark-red/purple crystal, "BOSS FIGHT · NEXT FIGHT" timer, on a lime patch. **Observed.**

**Training field**
- Gold-trimmed square platforms with glowing corner posts.
- Each has a themed centrepiece: boxing ring, red shrine, crystal tower, furnace, torii gate, glass dome, dark portal arch, blossom tree, red orb, flower garden, pagoda tower, orb with a light beam.
- Billboards read "X2 … X250 CHAKRA" with a price in **rebirths** (rebirth icon + number) or Robux.
- Higher tiers sit further back.
- **Observed.** Which side of the main path the field sits on: **UNVERIFIED**; placed on the left.

**Eye showcase**
- Dark stone platform holding two rows of 7 square pads.
- Above each pad: a floating orb icon, then name, "xN Chakra", and the trophy price, EQUIPPED or OWNED.
- Pad colours: **red** = buy, **green** = equipped, **yellow** = owned, **blue** = Robux skip.
- Values ascend from right to left, front row then back row; the back row is raised.
- **Observed.** Position relative to spawn: **UNVERIFIED**; placed right of the path near spawn.

**Egg walkway**
- Light walkway with lime edge lines.
- Eggs on glowing pedestals: "STAGE n", egg name, trophy or Robux price.
- The walkway starts with the **Boss Shop** stall and the **Fuse Machine**; the top eggs have light beams.
- **Observed.** Position: **UNVERIFIED**; placed along the far right side.

**Spawn**
- Exact spawn point: **UNVERIFIED**.
- The main-path shot is taken from the path facing the portal, so the spawn is placed at the start of the main path, facing WORLDS.

**Upgrade / rebirth / aura stations**
- **Not seen** in any reference shot; the reference HUD exposes them as buttons.
- None were built in the world: they stay in the HUD menus. This follows the issue: "placed based on what the reference actually contains rather than guessing".

## Schematic (lobby-local; +X = spawn → WORLDS / Stage 1; world origin of lobby = (-185, 0, 0))

```
                 cliffs + pines (3 stepped tiers, all sides)
  z=-90 ┌──────────────────────────────────────────────────────────┐
        │  TRAINING FIELD (5×3 grid, X2 front-left → X250 back)    │ LEADERBOARDS
        │  [X2][X3][X5][X7][X10]                    SPECIAL PET    │ (behind pet)
        │  [X15][X20][X25][X35][X50]                 (pedestal)    │
        │  [X100][X250]                                            │
  z=-20 │  ░ lawn ░ lanterns ░░░░░░░░░░░░░░░░░░░░░░░ ░ lawn ░      │
 SPAWN ▶│══════════════════ MAIN PATH ══════════════════════════ [WORLDS] ▶ Stage 1
  z=+20 │  ░ lawn ░ lanterns ░░░░░░░░░░░░░░░░░░░░░░░ ░ lawn ░      │
        │  HAND SIGN SHOWCASE  front row Tiger→Horse      BOSS RIFT│
        │                      back row (raised) Boar→Forbidden    │
        │  [BOSS SHOP][FUSE] egg walkway: Ninja → … → Divine (beams)│
  z=+90 └──────────────────────────────────────────────────────────┘
        x=-100                                                   x=+100 (= Stage 1 start)
```

## Function mapping (Anime Eyes → Hand Signs)

| Anime Eyes | Hand Signs implementation | Backend |
|---|---|---|
| Main path + lanterns → WORLDS portal | Same; walking through the portal enters **Stage 1** directly (contiguous). `[F]` at the threshold opens the Stages menu (all unlocked stages + LOBBY) | existing `TeleportStage` (server checks Highest) |
| X… CHAKRA training stations (rebirth / Robux price) | 12 stations, **X2…X250 HAND SIGNS**, rebirth-gated only (no Robux) | `SystemsConfig.TrainingStations` → `GameService.StationMultiplier` sets `ZoneMult` server-side |
| Eye showcase (2 × 7) | Hand Sign showcase (2 × 7): front row Tiger…Horse, raised back row Boar…Forbidden. Red buy / green equipped / yellow owned. **No blue Robux skip.** | `BuySign` (Stage + Hand Signs + Trophies), `EquipSign` |
| Egg walkway + Boss Shop + Fuse Machine | Same order; 8 existing eggs with Stage, name and trophy price | `Hatch`. Boss Shop / Fuse = **COMING SOON** placeholders, no prompt |
| Special pet (Robux) | Original "Chakra Fox Spirit" block statue | **COMING SOON**, no product |
| Kyubi boss rift + timer | Original crystal rift | **COMING SOON**, no timer or backend |
| Leaderboards | HAND SIGNS / TROPHIES / STAGE boards | `LeaderboardData` (live servers only) |

## Reinterpreted (not copied) elements

- **Fox:** Kyubi is a licensed character. It is replaced by a generic block "Chakra Fox Spirit".
- **Showcase icons:** eye icons are replaced by the hand-sign emblem on a sign-coloured orb.
- **Currency:** the Chakra flame becomes Hand Signs.
- **Portal ring:** built from neon block segments.
- **Shared generic Roblox simulator vocabulary:** the training-station props (boxing ring, torii, dome, …) are generic shapes rebuilt from parts.

## Pass / fail visual checklist (v2, 2026-11-02)

| Check | Result |
|---|---|
| Spawn on main path facing WORLDS portal | PASS (`v2_spawn_view.jpg`) |
| Lantern-lined lavender path + lime lawns | PASS |
| Enclosing blocky dirt cliffs with pines | PASS (`v2_overhead.jpg`) |
| WORLDS portal frame + glowing ring at path end | PASS (`v2_main_path_to_worlds.jpg` vs `ref_worlds_portal_path.png`) |
| Special pet + leaderboards left, boss rift right of portal | PASS (both placeholders labelled COMING SOON) |
| Gold-trimmed X… HAND SIGNS training field with rebirth prices | PASS (`v2_training_field.jpg` vs `ref_training_field_*.png`) |
| 2 × 7 showcase, red/green/yellow pads, orb + name + mult + trophy price | PASS (`v2_sign_showcase.jpg` vs `ref_eye_showcase.png`) |
| Egg walkway headed by Boss Shop + Fuse Machine, beams on top eggs | PASS (`v2_egg_walkway.jpg` vs `ref_egg_walkway.png`) |
| Exact relative side placement of field / showcase / eggs | UNVERIFIED (inferred; needs owner confirmation or more reference shots) |
| Front / back / left / right / overhead *reference* captures | NOT AVAILABLE (owner can supply) |


## Research update (2026-11-02, lobby v4)

- Gameplay videos could not be watched from this environment (YouTube serves a bot-check page to automated clients; image hosts such as r2.bloxron.com are blocked by the network allowlist). The owner supplied the five bloxron reference screenshots manually.
- [game.guide training table](https://www.game.guide/1-anime-eyes/training): World 1 has **13 training areas**: 9 priced in rebirths (0, 2, 6, 12, 20, 28, 36, 44, 56) and **4 game-pass zones** (x8 99 R$, x25 299 R$, x50 699 R$, x250 1800 R$). Our lobby now mirrors that structure with original names and builds; pass zones read `SC.GamePasses.Zone*` (Id 0 until the owner creates them -> "Not available yet").
- [game.guide eggs](https://www.game.guide/1-anime-eyes/eggs): the lobby sells a cheap trophy egg (10), a second trophy egg (400) and two Robux eggs (79 / 149 R$). Robux eggs were **not** added (no paid items without approval).
- Arena expanded to 300 x 260 studs: 7x2 training field (north), 2x7 showcase with floating transparent hand art (south of path), 8-egg plaza with Boss Shop + Fuse Machine (south edge), portal / special pet / leaderboards / boss rift unchanged in relation to the WORLDS portal.
