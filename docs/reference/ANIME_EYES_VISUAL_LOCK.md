# DIRECTOR VISUAL LOCK: +1 Anime Eyes-style Lobby and Map Repair
Owner order 2026-11-02 | P0 visual quality | +1 Anime Hand Signs | Roblox Studio place 72288975594385

## The problem and the non-negotiable target

Claude's previous environments look too different from +1 Anime Eyes, and repeated rebuilds are wasting the owner's Claude usage. Stop designing generic anime shrines, giant corridors, excessively neon temples, or enormous blank stage walls. The actual +1 Anime Eyes images and public gameplay frame sheets already in the repository are the visual target for COLOR, SPATIAL COMPOSITION, SCALE, FLOOR PATTERNS, DENSITY, UI READABILITY, CAMERA-LEVEL APPEARANCE and PROGRESSION. Use original art and models; do not extract proprietary source assets, logos or scripts. The owner wants recognizably similar simulator presentation with HAND SIGNS and jutsus instead of eyes.

This is an assignment to IMPLEMENT in the owner's actual Studio place, not to write another plan. Claude develops; Codex tests/screenshots/documents; ChatGPT directs and reviews. Pause broad mass-regeneration until owner sees and accepts a reference-matched quality pilot.

## Real source references Claude MUST OPEN VISUALLY

Actual +1 Anime Eyes in-game screenshots:
1. docs/reference/anime-eyes/ref_worlds_portal_path.png — lavender path, simple lanterns, bright WORLDS portal, special pet and leaderboards to one side, boss rift to the other.
2. docs/reference/anime-eyes/ref_training_field_a.png — golden-edged training stations, distinct low props, big xN Chakra labels, tier progression.
3. docs/reference/anime-eyes/ref_training_field_b.png — alternative angle on the same compact training field.
4. docs/reference/anime-eyes/ref_eye_showcase.png — floating collectible icons, two-by-seven pad arrangement, vivid statuses and labels.
5. docs/reference/anime-eyes/ref_egg_walkway.png — egg pedestals, name and cost labels, Boss Shop and Fuse Machine.
6. docs/reference/anime-eyes-ui/my_eyes.webp — four-column My Eyes cards, very large art, raised square studs, thick black borders, glossy green Equip buttons.
7. docs/reference/anime-eyes-ui/hud.webp and hud_2.png — on-screen menu/control locations and hierarchy.
8. docs/reference/anime-eyes-ui/auras.webp, rebirth.webp, community.webp — the same glossy, studded interface style.

Public YouTube gameplay *storyboard captures*, lower-resolution and possibly an older game version:
9. docs/reference/anime-eyes-video/lobby_to_stage1_a.jpg — character camera at spawn and entrance to Stage 1.
10. docs/reference/anime-eyes-video/lobby_to_stage1_b.jpg — pink Stage 1 arch/panel, green areas, sakura area, sandy area.
11. docs/reference/anime-eyes-video/stages_1_6.jpg — real paths, color and enemy platform sizes, gate hierarchy, reward pads and stage transitions.
12. docs/reference/anime-eyes-video/stages_late.jpg — later arena colors, distinct biome palettes and gameplay readability.
Source videos and provenance are in docs/reference/anime-eyes-video/README.md; do not claim these are current 2026-11-02 live-game frames without confirmation.

Our own screenshots that reveal specific defects:
13. docs/evidence/issue-14/v8/01_lobby_into_stage1_gate.jpg — Stage 1 entrance is dominated by an oversized flat pink wall and blunt text, with sparse, oddly scaled decor. Rebuild proportions, NOT simply add props.
14. docs/evidence/issue-14/v8/02_stage2_banner.jpg — Stage 2 becomes an almost opaque bright-pink screen, washing out labels, path, trees and the next stage. This is a hard FAILURE. Identify the exact offending material/transparency/gate/lighting/postFX and remove the pink wash. Use sakura blossoms and restrained pink trims to convey cherry biome, not a full-screen color veil.
15. docs/evidence/issue-14/v6/02_field_south_rows.jpg — training labels are clipped above the top of the camera and beams are excessively long.
16. docs/evidence/issue-14/v5/01_lobby_overhead.jpg, 02_spawn_facing_north.jpg, 03_worlds_portal_back_special_pet.jpg, 04_sign_showcase.jpg, 05_training_field_blender_stations.jpg and 06_eggs_4_rainbow_robux.jpg — important baseline screenshots for checking lobby changes.
17. docs/evidence/issue-14/ui-overhaul/my_hand_signs.jpg and docs/evidence/issue-14/v5/07_my_hand_signs_cartoon_trophies_only.jpg — current UI for icon and button scale.
18. docs/evidence/issue-14/vfx-v1/01_field_labels_at_beam_tops.jpg and companion VFX screenshots — verify actual latest state rather than assuming all earlier flaws remain.

## LOBBY LOOK: match actual reference style, not more complexity

- Floor: actual slightly raised/surface Roblox studs on pale lavender tiled paths and very bright lime-green lawns, with clean dark purple borders. No random raised grass cubes, no realistic foliage, no maze of floating islands.
- Enclosing terrain: simple stepped red-brown dirt cliffs, crisp green grass tops, blocky green low-poly pines/trees, vibrant sky. This is a deliberately simple Roblox simulator art style.
- Camera-level composition: spawn lets the player see the Stage 1 gate and key hubs. Make the Stage 1 entrance feel ADJACENT to the lobby in the reference-video style; don't route beginners across unnecessary separate bridges, long corridors or disconnected islands. The separate WORLDS portal remains a clear navigational landmark with its actual functionality, not a substitute for Stage 1.
- Paths and lanterns: wide readable lavender footpaths, regular rhythm of low black/grey simple illuminated lanterns. Compare size to player avatar, not zoomed aerial renders.
- Training field: all 13 approved stations clustered in ONE area, without separating Robux stations. Beginner stations immediately nearby, higher multipliers deeper into the field. Visually distinct compact plinths, gold borders and controlled colorful FX, not tall duplicate neon poles.
- Training station build process: owner-provided clean reference images -> Blender actual 3D source -> .glb/.fbx meshes -> Roblox 3D Importer -> real MeshParts (not export JSON and rebuild the visible models as Roblox Blocks). Preserve invisible gameplay trigger Parts. Show Blender exports and imported Studio Explorer.
- Training title position: xN HAND SIGNS and real requirement near the TOP of each short visible vertical beam, directly above correct station. Avoid labels offscreen, overlapping, or behind one another. Rebirth requirement text must be true. For a pass-gated training zone stepped on without pass, show the actual Game Pass purchase flow using the owner-approved ID; NOT generic press F unlock. If ID absent, show unavailable rather than guessing or charging.
- Showcase: reference's tiered two-by-seven pads with huge anatomically correct transparent hand art, readable NAME / MULTIPLIER / TROPHY PRICE, green equipped/yellow owned/red locked. Do not silently reintroduce any artwork owner has rejected; preserve saved sign compatibility.
- Eggs: compact row of clearly displayed eggs with distinct pedestals, readable pricing and gentle glow. No giant mystery models, illegible signs or fake Robux products; not-yet-working Boss Shop and Fuse Machine stay clearly unavailable.
- Custom VFX: use LihFolk Vault 2.5.0 docs and any actually installed/legal asset kit, or original authored emitters/textures. Different effects per station, controlled brightness and mobile performance. Never claim optional pack installed without checking.

## MAP AND STAGE LOOK: actual +1 Anime Eyes, adapted to 50 stages

Keep all 50 stages, saved progress, existing stage progression/kill gates, actual rewards and portal logic. Do not globally change combat, currency, enemy counts or stage lengths as an excuse for a visual rebuild.

- Stage layout: compact, broad, bright Roblox simulator arenas with paths and small asymmetrical side props/trees. Clear simple center walk lane, visible enemies, readable gates and colorful reward pads. Stages should look connected and progressively themed, not repetitive narrow corridors with giant flat walls or tiny decoration scattered in a void.
- Stage 1 Leaf Grove: predominantly bright lime-green grass; red-brown earth sides and blocky green trees; a lavender or pale studded walk lane and a few grey stone lanterns. Bold STAGE 1 + RECOMMENDED HAND SIGNS (live value) on a proportionate pink entrance element. Make it readable at player eye height and avoid enormous flat facade.
- Stage 2 Cherry Blossom Hill: pink blossom trees, petals, pastel accents, some grassy/light stone contrast, clean paths. Absolutely no opaque pink overlay or giant neon pink gate blocking all scenery; fix the actual bug visible in v8/02_stage2_banner.jpg.
- Stage 3 Sand Dunes: warm sand, tan low-poly dunes, sparse palms/cacti and stone ruin props, visible pale walkway and a distinctive silhouette. Do not recolor the cherry stage brown.
- Later stages: real palette/shape changes (red canyon, ice, volcanic, teal etc.) but maintain same intentional footprint and fight-room readability. Different foliage/props/terrain, no artificial repeated shrine/corridor kits everywhere.
- Gates and header text: an appropriate top title and secondary recommended power requirement, stage name if helpful, short clear status and actual reward. No mirrored double GUI bleed, no unreadable translucent pink walls, no oversized letters taking up the entire view. Replace eye-game-specific CHAKRA wording with HAND SIGNS in our game. Don't leave pasted Stage 2 markers visible through stage gates.
- Proportions: compare third-person avatar scale, path width, wall height, tree height, and framing to the real gameplay screenshots. A screenshot from a drone camera cannot substitute for normal player view.

## UI AND ATTACK ICON LOOK

- Study docs/reference/anime-eyes-ui/my_eyes.webp. Match the four-column colorful card layout, real beveled square studs, thick dark outlines, glossy toy-like bright green buttons and text spacing. Hand illustrations should be BIG (roughly 55–70% of each card's inner width, modified for wide hands), never cropped or tiny.
- Existing owner-approved ATTACK ICON reference sheet: anime_hand_signs_attack_icon_concepts.png from the ChatGPT conversation. It shows Shadow Clone as the gesture plus white smoke CLOUDS and duplicate shadow ninjas; Fireball as the gesture plus orange-red FIREBALL and flaming trail. Build the icons to SHOW THE ACTUAL TECHNIQUE, not a generic repeated hand-symbol on every ability. For Rasengan use blue energy orb; lightning use unmistakable lightning arcs. Attack art is an icon-layer asset, not a 3D training station decoration. Hand icons always mapped to correct ability.
- Note: if this exact PNG has not yet been transferred into the Git repository, state this openly and get the actual image from owner/chat; do not claim it exists merely because this filename is listed.
- HUD: same spatial hierarchy as the actual reference, glossy and studs, avoid Academy Captain banners covering UI; responsive at 16:9, 640x480, mobile portrait/landscape.

## CREDIT-SAVING QUALITY GATES — NO WHOLE-MAP GENERATION UNTIL APPROVED

1. Capture and compare 6 real third-person screenshots at matched camera angles: actual reference main path / our spawn; actual training / our training; actual Stage 1 entrance / our Stage 1; actual Stage 1 gameplay / our Stage 1; real sakura scene / our Stage 2; eye showcase / our hand sign display. Include two additional views of our lobby left/right and overhead.
2. Verify full-place .rbxl backup and current live source vs GitHub feature/issue-14-ui-lobby-polish and stacked PR #16/#15. Do not overwrite newer Studio changes; do not publish, change gamepasses or run destructive WorldBuilder scripts.
3. First fix just the lobby spawn-facing view, Stage 1 entrance and ONE training station. Capture screenshots; use true mesh importer and custom FX; ensure beam label top and gamepass flow. No full-field repeat until visual checkpoint.
4. Next fix Stage 1 and Stage 2 visually; remove severe pink-screen bug. Take normal-camera desktop and mobile screenshots, perform basic combat test.
5. Codex independently playtests, records PASS/FAIL/NOT TESTED and reproductions. ChatGPT reviews comparative appearance. Only after owner acceptance do all 13 stations and the remaining stages.
6. Deliver real amended Studio changes, source meshes, script diffs, screenshots in GitHub draft PR. A report, Blender-only scene or unrelated concept art is NOT completion.

## PASS/FAIL acceptance
PASS means readable bright Roblox simulator lobby very close to the +1 Anime Eyes screenshot layout and camera proportions, one clustered field of 13 stations using actual Blender MeshParts, sensible short beams and titles, original custom effects, recognizable skill icons, a proportionate Stage 1 entrance, clean distinct stages 1–3, NO pink stage-screen overlay, all 50 saved stages and functionality preserved. FAIL means any one of these is missing, especially making huge changes without first showing the two-stage pilot. Claude should not spend another development cycle guessing the art direction.

## OWNER LOBBY LAYOUT SKETCH (2026-11-03, overrides earlier layouts)
`docs/reference/owner_lobby_layout_sketch.jpg`. The lobby is one rectangle, about the size of the +1 Anime Eyes lobby:
- **Left side:** the training field, with the stations in a 2-column grid.
- **Centre:** open main area.
- **Right side:** eggs on top and the hand-sign showcase below, with a divider between them.
- **Bottom edge:** the Stage 1 entrance, straight down from the middle.
