# Issue #14: training stations v2, rebuilt from the owner's 8 references (2026-11-02)

Studio place 72288975594385, branch `feature/issue-14-ui-lobby-polish`. All 20 scripts in `scripts/` were
hash-checked against live Studio after the last change, and all 20 match. Nothing was published.

## Backups (ServerStorage.Backups)
- `BlenderStations_v1_20261102`: the v1 Blender station models.
- `Lobby_v5_preStationsV2_20261102`: the lobby before this change.

## What changed
- **`tools/blender/training_stations_v2.py`** (new, Blender 5.2): all 13 stations remodelled after the owner's reference sheet.
  - **Shared kit:**
    - Gold-trim plinths with corner lanterns.
    - Neon light pillars with a white core.
    - Open swirl rings, banners, arches and tapered crystal stacks.
  - **Mapping from the references to stations:**

    | Ref | Look | Station |
    |---|---|---|
    | 1 | Golden orb shrine | SageThrone (X250) |
    | 2 | Sakura shrine | ScrollTemple |
    | 3 | Purple pagoda | GoldenDojo (StormPagoda is a blue storm variant) |
    | 4 | Red torii with fire | DragonGate |
    | 5 | Purple crystal | GravitySeal (CrimsonAltar is a red crystal spire) |
    | 6 | Fire forge | Forge |
    | 7 | Blue arch well | ChakraPool |
    | 8 | Void torii | VoidTotem |

  - **Other stations:** Dummy, Ring, StormPagoda, ThunderDome and CrimsonAltar were restyled with the same kit.
  - **Originality:** every station is built from primitives in Blender. No third-party meshes or textures.
- **`rbx_fx` effect tags:** effects are tagged in Blender, exported in `stations.json`, and created by `StationKit`:
  - `beam`: rising sparkles up each light pillar. The pillar is non-collidable.
  - `sparkle`: twinkles.
  - `fire`: a Roblox `Fire` in the forge mouth and torii braziers.
  - `smoke`: chimney smoke.
  - `embers`: rising sparks.
  - `petals`: pink petals drifting down from the sakura canopy.
  - The particles use only textures that ship with the Roblox client (`rbxasset://textures/particles/...`).
- **`LobbyBuilder`:**
  - Each station slot now has a yaw, so its front faces the nearest cross road. The old blanket 180° rotation turned most fronts away from the player.
  - The old extra "beam" on stations of X25 and above is gone; the light pillars are now part of the models.
  - Two lawn pines that sat inside station plots were moved.
- **In-game review tweaks:**
  - Light pillars are 70% of their first height (`BEAM_SCALE`). At full height they cluttered the skyline; see 01 vs 02.
  - The Sage Throne orb shell changed from Glass to soft Neon. Roblox Glass refracted the brown cliffs behind it, while reference 1 is a gold glow.
  - The Blender renders in `assets/blender/renders_v2/` were taken before these two tweaks. The exported `assets/blender/stations.json` includes them.

## Playtest
- **Zones:** all 13 station zones resolve in `GameService.StationMultiplier`.
  - With 0 rebirths, only X2 applies. With enough rebirths, the rebirth-gated stations (X3–X40) apply.
  - The Robux stations (X8, X25, X50, X250) stay ×1 without their game pass.
  - Live player on the X2 plinth: `ZoneMult` = 2.
- **Effects:** 25 effects run in play mode, including petals, forge fire with smoke, and the gold halo.
- **Console:** no script errors. The only output is the expected Studio DataStore "API access not enabled" fallback, so the session ran on a temporary, non-saving profile.

## Screenshots
| File | Shows |
|---|---|
| `00_blender_contact_sheet.jpg` | Blender renders of all 13 stations |
| `01_field_first_import_tall_beams.jpg` | First import, before the beam fix |
| `02_field_south_rows.jpg` / `03_field_north_row.jpg` | Final training field |
| `04_play_sakura_shrine_petals.jpg` / `05_play_fire_forge.jpg` | Close-ups in play mode with the HUD |
| `06_sage_throne_gold_orb.jpg` | The X250 Sage Throne with the gold orb |

## For review
- Is each reference → station mapping right? Should any station swap looks? Each station is one function in `training_stations_v2.py`.
- **Re-import pipeline:**
  1. Run `build_all()` and `export_json()` in Blender.
  2. Run `StationKit.Import()`.
  3. Run `LobbyBuilder.Build()`.
