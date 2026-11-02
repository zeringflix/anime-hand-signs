# +1 Anime Hand Signs — inspection and improvement plan
Date: November 1, 2026 (America/Chicago)  
Place: 72288975594385 · Official Roblox_Studio MCP  
Studio instance: 87223762-ef9f-4c1c-82c9-fd2779d858fc

## Executive assessment
The game contains substantial reusable work: all 50 stages, a shared configuration, 14 signs, 28 jutsu definitions, server combat, procedural enemies, pets, auras, rewards, persistence code, HUD and 11 menu panels. Preserve it. The most urgent issue is an incomplete integration between the old configuration and newer service code. It breaks the progression loop before art quality can be judged fairly.

This audit made **no edits or deletions to game scripts, models, map, lighting, or assets**, ran no builders, and made no GitHub changes during inspection. The owner subsequently authorized this evidence package to be saved to GitHub. Playtests used ordinary gameplay inputs and a few normal client remote requests to check guards. No DevGrant, injected unlocks, stat overrides, or paid purchases were used. The owner disabled Studio API access and confirmed saving that setting before play. Output confirmed a temporary profile that will not save. Device simulation and temporary screenshot cameras were used. Play was stopped and default device viewport restored; original LandscapeRight simulator orientation restored. API access remains off.

## Coverage and limits
- Individually captured and visually reviewed **50/50 stage overviews**; checked every stage's required structural children. Every stage has Floor, Cliffs, Decor, Gate, Spawn, TrophyPad and EnemySpawns.
- Inventoried all **19 Lua source containers** and captured their full source locally. Reviewed main paths and cross-system contracts; this is not a formal exhaustive code/security verification.
- Opened all 11 main panels: Signs, Shop, Upgrades, Stages, Rebirth, Auras, Pets, Settings, Rewards, Top, Codes.
- Playtested a fresh desktop session: movement, Tiger E/R, no-target feedback, training, free-auto claim, daily reward, Ninja egg hatch and automatic equip/EquipBest, and locked-content guards.
- Device captures: iPhone 17 Pro landscape and portrait, Galaxy A06 landscape, including a fresh A06 startup. iPhone orientation captures changed during a running session; A06 fresh startup verifies touch initialization.
- **Not certified:** full clears of stages 1–50, final boss phases, 26 later jutsu, advanced pet/aura tiers, long-duration rewards/offline rejoin, persistence, paid purchases, multiplayer, controller navigation, physical-device performance, or frame-time/memory targets. Progression is blocked by the reproduced error; no unlock bypass was used to conceal it.
- Screenshots are edit overviews for the map and live captures for UI/combat. Edit overviews do not prove each biome's runtime atmosphere or enemy behaviour.
- Review observations are evidence-based, not a claim that every possible defect has been found.

## Severity-ranked findings
P0 = core progression broken. P1 = must address before release or risky workflow. P2 = substantial quality/clarity problem. P3 = polish.

### P0-01 — Missing sign Price breaks initialization, training and progression
**Reproduced.** Output: `GameService:178: attempt to compare nil <= number`. `CanUnlock` reads `s.Price <= 0`; Config's hand-sign records contain Stage/Power but no Price. The error occurs in OnLoaded and AddHandSigns. Manual F training reproduced it. Free-auto also calls AddHandSigns inside an unprotected loop, so the coroutine terminates after its first failing tick. The UI timer can continue despite no functioning auto loop. Currency changes precede the error, so later refreshes can reveal accumulated values rather than a clean failure.

**Static consequence:** CreditKill calls AddHandSigns before incrementing StageKills. Therefore the same error can prevent kill-clear bookkeeping and unlocking the next stage. Normal sign purchase also expects Price, while the menu still describes the old Stage + Power model.

**Repair proposal:** choose and document one sign acquisition contract, populate/validate required fields at startup, migrate legacy profiles, keep currency mutation and unlock notifications consistent, and isolate each player's auto-loop failures. Do not silently assign arbitrary prices.

**Acceptance:** fresh join, manual training, free auto over its full cycle, kills, stage clear, next-stage access, sign unlock/purchase and refresh all succeed without errors; displayed rules equal server rules. Include a regression test for every sign schema and a missing-field failure before player mutation.
Evidence: live GameService 120–125, 174–185, 214–236; SystemsService 186–199, 540–550; Config sign construction; [console](playtest-console.txt).

### P1-01 — More unfinished config contracts block advanced systems
**Static, not exercised past locks.** SystemsService references `SC.ShopOnlyAuras`, `SC.FuseTiers`, `SC.FuseCount`, and `SC.BossShop`. None is defined by the captured SystemsConfig. BuyAura indexes ShopOnlyAuras before ownership/stage handling; Fuse takes the length of a nil table; BossShop iterates a missing table. Its outer pcall converts errors into failed actions, but features still fail.

**Repair:** complete or explicitly disable each feature contract; validate schema as one unit. Preserve the unfinished implementations rather than deleting them.
**Acceptance:** every exposed action has valid configuration; buying/toggling an aura, fusing with/without enough copies, and boss-shop guard behaviour return explicit outcomes without warnings.

### P1-02 — Studio can touch production player data and replace a live lease
**Static risk; avoided in this audit.** DataService uses `HandSignsPlayerData_v1` and the same user key in Studio. Load skips the existing-lock check when IsStudio is true; it can overwrite another session token. Saves still run in Studio, including BindToClose. Leaderboards also start in Studio whenever PlaceId is nonzero.

**Repair:** provide a separately namespaced QA store or memory-only mode selected before data loads, including leaderboards. Keep production lease fencing active. Do not test against a real user's live record.
**Acceptance:** Studio QA performs zero production-store operations; two concurrent sessions cannot steal a lease; simulated load failures never save defaults; profile saves/rejoins are tested using disposable data.

### P1-03 — GitHub is an incomplete and stale copy of Studio
Compared the nine exported shared/server scripts with the current repository after normalizing line endings and outer whitespace: **5 differ, 4 match**. The repository tree omits all seven client scripts and all three ServerStorage source containers. It also cannot represent the current model/lighting state by itself. A source snapshot ZIP is provided as evidence, **not a full .rbxl place backup or proof of sync**.

**Repair:** take a fresh full-place backup, then export Studio outward into a review branch with an explicit path/class mapping. Review the diff and confirm sync direction before enabling writes. Never import the stale repository over Studio.
**Acceptance:** all 19 sources, required assets/world settings and a versioned backup manifest are accounted for; a read-only source comparison is clean. Preserve local and collaborator changes.
Repository inspected: [zeringflix/anime-hand-signs](https://github.com/zeringflix/anime-hand-signs), tree SHA `97caf41b4c7744b3e53ce68c212c75ab5a52d0d1`.

### P1-04 — Portrait HUD is visibly unusable
**Reproduced on iPhone 17 Pro**, portrait viewport reported 401×778. Bottom progress, packs, auto clickers and combat controls overlap; top menu icons collide with boss/banner text. Sensor orientation allows portrait. IgnoreGuiInset=true, ScreenInsets=DeviceSafeInsets and ClipToDeviceSafeArea=true were observed. Insets alone do not solve the layout.

**Repair:** responsive portrait and landscape compositions, compact navigation, reduced marketing controls, safe-area-aware anchors and readable touch targets. Decide whether portrait is supported; do not change orientation policy in this audit.
**Acceptance:** no overlaps/clips in phone portrait and landscape, tablet and desktop; movement/jump/combat areas remain clear. Fresh touch startup must be included.

### P1-05 — Receipt grant is acknowledged before durable save succeeds
**Static release blocker for future monetization**, not a claim of a lost purchase in this audit. ProcessReceipt mutates memory, marks a receipt, calls SaveNow (asynchronous, no success returned), then immediately returns PurchaseGranted. Crash/save failure can lose the recorded grant. Receipt history is bounded to 100 entries. Currently all product/pass IDs are zero, so these paths are disabled.

**Repair:** make granting and durable receipt recording idempotent and acknowledged only after a confirmed save. Test retries, duplicates and shutdown failure using test products/data before real monetization is enabled.

### P2-01 — Gate text is inconsistent, stale and visually stacked
Header names the current biome while barrier text advertises the next biome; “5 LEFT” and several text layers stack across a long sightline. Edit screenshots show old recommended values: gate to stage 3 says 390 while runtime menu says 400; stage 12 gate says 71M while runtime Config/menu says 150M. Generated map text is stale relative to runtime config. Next-stage trophy values are displayed at a current-stage exit, which can confuse reward expectations.

**Repair:** one clear current objective, one destination label, one authoritative reward/requirement. Refresh generated signs from the same current schema without rebuilding stages. Limit distant label visibility; reserve large text for the nearest gate.
**Acceptance:** all 50 gate labels match live stage data, reward source is explicit, no competing overlapping labels at player camera heights.
Evidence: stage images, [Stages menu](screenshots/menuStages.png), [combat](screenshots/combatTiger.png).

### P2-02 — 50 biomes share one corridor composition
**Observed across all 50 overviews.** Repeated 170-stud straight stages, mirrored terraces, central path, red/dark boundary strip, lantern spacing and identical gate silhouette make progression feel like palette swaps. “Cavern”, “crater”, “waterfall”, “citadel” and “floating islands” frequently lack the large-scale landform their names promise.

**Repair:** keep every stage model and ID; develop several layout variants and one distinctive focal landmark per region. Revise one pilot stage non-destructively, then apply reusable variants. Preserve combat space, spawns, trophy pads and traversal contracts.
**Acceptance:** silhouettes distinguish regions without reading names; no decor blocks targeting or exits; each stage has a distinct focal feature and a clear arena.

### P2-03 — Saturation, neon and material styles compete
**Observed.** Acid green, saturated red and hot pink dominate the starter map. Full neon canopies/crystals lose shading; late white/gold stages merge into bright ground. Detailed stone lantern meshes sit beside primitive studded trees, giant cylindrical lantern landmarks and repeated small box houses.

Lighting in Edit: Brightness 2.6, ClockTime 14.2, StageGrade Saturation +0.18/Contrast +0.06, Bloom intensity 0.6, threshold 1.6; depth of field is disabled. Client mood tweening exists, but all 50 runtime moods were not visited.

**Repair:** retain the stylized studded language, define a material/scale palette, reduce broad emissive areas, choose calm base colors with limited accent glow, and validate dark/bright biomes in play. Preserve the lantern/trophy kit and improve supporting props to match.

### P2-04 — HUD spends too much screen space on secondary controls
**Observed on desktop and landscape phones.** Many navigation tiles, purchase packs, timers, multiplier text and boss banners compete with combat. A06 has movement controls near currency/menu areas and jump near attack controls. The pet follower can sit behind the large bottom HUD. Boss announcement remains prominent before engaging the boss. Some menus use tiny scaled descriptions and large empty bodies; Pets inventory begins below the fold.

**Repair:** prioritize current objective, health, sign power and three combat controls; collapse secondary navigation and commerce. Use readable type scales, consistent spacing and explicit scroll cues.
**Acceptance:** a new player can find training, attack and next objective without opening menus; screenshots at supported resolutions show readable descriptions and unobstructed gameplay.

### P2-05 — Identity and terminology drift
**Observed/static.** The currency is “Hand Signs,” represented by flame/chakra imagery; the hand-sign menu uses an emoji, M1 a sword, E/R ability-element icons. PROGRESS claims a Ram/Horse swap and a 30-stage reduction, while active Config still uses Ram/Rasengan, Horse/DragonFlame and 50 stages. Current repository GAME_SPEC and this request require 50. The spec's three abilities per tier needs clarification: live code provides shared M1 plus two sign-specific jutsu.

**Repair:** keep 50 stages and existing mappings during the audit; record a current design decision for terminology, icon meaning and ability-count semantics before implementation. Preserve all 28 mechanics.

### P2-06 — Lobby feature is only partly wired
No Lobby model or LobbyService exists. GameService looks for LobbySpawn and falls back to stage 1; ZoneMult defaults to 1. No physical showcase, training stations, fuse machine or boss shop is present. Server implementations reference several missing configs (P1-01).

**Repair:** either complete the hub as an additive model/service or present the current stage-start experience consistently. Do not replace the existing course to create it.

### P2-07 — Combat presentation needs clarity and enemy variety
**Observed for stage 1; broader variety inferred from shared enemy generator.** Several enemy health bars/names overlap in a cluster. Fire/Phoenix show bright yellow/orange spheres and red hit flashes that obscure silhouettes. NPCs use the same R15 primitive outfit/hair/hat recipe with recolours; source includes final-boss phases but these were not tested.

**Repair:** readable windup → impact → recovery, compact target labels, distinct elite/boss silhouettes, bounded VFX brightness/coverage, and consistent hit audio. Keep server authority, cooldowns and mechanic handlers.
**Acceptance:** enemy action remains readable behind VFX, cooldown indicators match server timing, 28 jutsu have reviewed normal/reduced-effects captures, and finale phases are tested after progression repair.

### P2-08 — Resource budget needs measurement before expansion
Inventory: **19,492 StageCourse descendants; 15,503 BaseParts (13,153 Parts + 2,350 MeshParts); 539 PointLights; 600 TextLabels; 150 SurfaceGuis; 50 BillboardGuis; 11 unique mesh IDs**. All stage BaseParts are anchored. StreamingEnabled=true. Stage 18 has 840 parts; stages 3 and 5 have 688/680. There are no edit-time ParticleEmitters under StageCourse; runtime boss/ability/auras do create effects.

This is a workload risk, **not measured proof of low FPS**. Enemy activation/despawn and animation-distance checks already exist and should be retained. All-client VFX broadcasts and per-frame pet/animation work need multiplayer profiling.
**Repair:** measure real phone frame time, light/shadow costs, streaming peaks, VFX spam and pet-heavy multiplayer. Optimize proven hotspots; preserve visual kit through LODs, light culling and simplified repeats.

### P2-09 — Late-game precision and pacing are not validated
Runtime stage 50 recommends 1.4e16 Hand Signs; HP is about 5.6e16. These exceed exact unit-integer range for Luau's number type, so comments claiming huge values “stay exact” are inaccurate. Stage recommendations rise sharply while signs initially unlock several stages apart; intended pacing is unverified because the core loop fails.

**Repair:** choose a documented large-number/rounding policy; model time-to-next-stage with actual multipliers and intended session lengths; test milestone transitions. Do not rebalance by guessing constants.

### P2-10 — Fused pets are incompletely represented
**Static, dependent on missing fuse config.** Pet multiplier can use Tier, but EquipBest sorts raw pet Boost and publishLooks sends only pet IDs. Fused strength and appearance can diverge from the user's expectations.
**Repair:** use effective boost consistently and publish tier metadata; test equip-best with mixed tiers once fusion is configured.

### P3-01 — Explicit placeholders and unfinished polish
Shop is entirely “SOON” because IDs are zero; codes table is empty by design; Top is empty while API access is disabled (not proof live leaderboards fail). Sounds are built-in Roblox click/sword/ping clips, with no cohesive music/biome ambience. Settings has no music control despite a Music profile field. Rebirth copy says “Resets: Hand Signs only. Kept: ... hand signs ...”, confusing currency with unlocked sign types.

**Repair:** label unavailable features clearly, reduce inactive storefront prominence, distinguish currency from sign collection, and add a coherent audio/icon/copy pass after functional fixes. Do not activate products or fabricate codes as part of art work.

## Safe playtest record
| Check | Result |
|---|---|
| Fresh join/HUD | Loads; GameService OnLoaded callback throws missing Price error |
| Manual F training | Reproduces CanUnlock error; mutation may become visible on later refresh |
| Free auto claim | Timer starts; auto loop throws through AddHandSigns and stops |
| Movement | Character navigation to stage 1 combat area succeeded |
| E/R without enemy in range | Clear “No enemy in range” feedback |
| Tiger Fireball/Phoenix | Casts, cooldowns and enemy HP damage observed; XP advanced to 2 |
| Daily claim | 45 trophies observed |
| Ninja hatch | One NinjaCat obtained/equipped; trophies consumed; multiplier x1.1 observed |
| EquipBest | Returned ok=true |
| Repeat hatch with no trophies | Rejected “Not enough Trophies” |
| Rebirth below cost | Rejected “Need 2.5K Hand Signs” |
| Locked Divine egg | Rejected “Reach Stage 46 first” |
| Equip Forbidden / teleport stage 50 | Tiger/Highest=1 remained; locked request did not grant access |
| 11 menu panels | Opened and captured |
| Mobile layout | Portrait fails overlap; landscape crowded; touch badges hidden on fresh A06 start |
| Persistent data writes | Avoided: API access disabled; temporary profile warning confirmed |
| End state | Edit mode, default viewport restored |

## Preservation-first implementation sequence
These are proposed work packages, not authorization to change the game.

1. **Preserve and reconcile.** Full-place backup; outward source export; reviewed branch and sync mapping; record current 50-stage design. Exit: restore point and complete manifest, no lost Studio-only work.
2. **Repair contracts and data safety.** P0-01, P1-01/02/05. Add focused schema and persistence/receipt tests. Exit: fresh player completes stage 1 and unlocks stage 2, sign progression succeeds, autos run reliably, QA cannot write production data.
3. **Prove the loop.** Natural play of stages 1–5; reward/pad accounting, save/rejoin with disposable data, death/respawn, two-player credit and gates. Measure time to first ability and next sign; resolve pacing from evidence.
4. **Make HUD responsive.** Fix portrait/landscape, menu readability and touch zones; consolidate terminology and gate text. Exit: desktop/phone/tablet/controller evidence with no clipping or inaccessible actions.
5. **Approve one art pilot.** Refine stage 1 plus one contrasting biome using retained parts/kit. Establish palette, silhouette, materials, lighting and VFX guidelines. Review before applying across the course.
6. **Roll art changes across all 50.** Work in small region batches, keep stage IDs/spawns/pads stable, compare before/after captures. No BuildAll on original models; preserve originals in a versioned backup or separate review copy.
7. **Finish advanced systems and finale.** Add hub if desired; configure fusion/shop/aura contracts; test all 28 jutsu and boss phases with isolated QA profiles after the initial audit. Validate disabled/locked states.
8. **Release validation.** Real-device performance, multiplayer, data-loss/retry scenarios, production-safe migration rehearsal, and paid purchase tests only after receipt fix. Owner reviews before merge/publication.

For every work package: identify exact changed objects, provide rollback, screenshots and console evidence, and keep unrelated systems untouched. Do not reduce stages to 30 based on stale comments.

## Stage-by-stage visual register
All stages passed the structural-child/anchoring check. Notes below concern visible art/composition in the edit overview; they do not certify runtime playability. Gate stacking, repeated corridor geometry and lack of ambient motion are cross-cutting concerns.

| Stage | Biome | Parts | Specific observation / proposed improvement | Evidence |
|---|---|---:|---|---|
| 1 | Leaf Grove | 282 | Acid green ground, red enclosure, hot pink gate compete; establish a calm starter palette and a clear training prompt. | [View](screenshots/stage-01.png) |
| 2 | Cherry Blossom Hill | 327 | Blossom silhouettes read, but bright green ground and repeated oversized lantern landmark weaken the pink biome identity. | [View](screenshots/stage-02.png) |
| 3 | Sand Dunes | 688 | Desert props resemble bamboo clusters; add dune silhouettes and recognisable cactus forms. High part count. | [View](screenshots/stage-03.png) |
| 4 | Red Canyon | 257 | Reads as orange corridor rather than canyon; add rock strata and a strong canyon silhouette. | [View](screenshots/stage-04.png) |
| 5 | Bamboo Sanctuary | 680 | Bamboo identity is recognisable; dense thin segments are expensive and repetitive. Simplify clusters. | [View](screenshots/stage-05.png) |
| 6 | Misty Marsh | 318 | Marsh has no visible water or mist in edit capture; reeds sit in tiny flat patches. Add wet ground and local atmosphere. | [View](screenshots/stage-06.png) |
| 7 | Stone Valley | 278 | Stone valley relies on recoloured trees and rock scatter; needs a distinctive stone formation. | [View](screenshots/stage-07.png) |
| 8 | Frozen Pass | 258 | Snow/ice palette reads; white highlights and lanterns flatten contrast. Give ice silhouettes deliberate shapes. | [View](screenshots/stage-08.png) |
| 9 | Storm Peak | 248 | Storm rods repeat without an obvious peak or storm event; preserve rods and create a skyline focal point. | [View](screenshots/stage-09.png) |
| 10 | Lava Crater | 272 | Lava crater has dark floor and orange accents but no visible lava crater in capture. | [View](screenshots/stage-10.png) |
| 11 | Spirit Forest | 303 | Neon cyan canopy loses shape detail; reduce full-surface emission and reserve glow for accents. | [View](screenshots/stage-11.png) |
| 12 | Moonlit Ruins | 279 | Ruins are repeated pillars and torii in an open corridor; add a recognisable ruin composition. | [View](screenshots/stage-12.png) |
| 13 | Poison Swamp | 287 | Yellow-green glowing mushrooms overpower the scene; keep poison accent while restoring mushroom form. | [View](screenshots/stage-13.png) |
| 14 | Haunted Graveyard | 301 | Purple canopy and small graves read weakly as haunted cemetery; improve tombstone silhouettes and fog depth. | [View](screenshots/stage-14.png) |
| 15 | Forbidden Shrine | 307 | Torii establish shrine theme; all-magenta props and repeated layout flatten depth. | [View](screenshots/stage-15.png) |
| 16 | Samurai Village | 322 | Village houses are miniature isolated boxes; cluster into a coherent street with consistent scale. | [View](screenshots/stage-16.png) |
| 17 | Iron Fortress | 298 | Fortress is isolated wall stubs; build a focal fortified silhouette using existing pieces. | [View](screenshots/stage-17.png) |
| 18 | Shadow Dojo | 840 | Dojo has many repeated small houses/bamboo pieces, not one readable dojo. Highest part count: 840. | [View](screenshots/stage-18.png) |
| 19 | Crimson Battlefield | 252 | Battlefield is sparse banners and rock scatter; create readable battle traces without obstructing combat. | [View](screenshots/stage-19.png) |
| 20 | Ancient Castle | 322 | Castle reads as repeated roofed columns; establish one dominant castle silhouette. | [View](screenshots/stage-20.png) |
| 21 | Thunder Forest | 272 | Cyan pine recolours and rods dominate; add branch lightning accents rather than flat cyan mass. | [View](screenshots/stage-21.png) |
| 22 | Inferno Temple | 280 | Temple miniatures repeat; select one focal temple and supporting low-detail structures. | [View](screenshots/stage-22.png) |
| 23 | Tidal Sanctuary | 272 | Coral reads as short flat tables and the water theme lacks a strong water feature. | [View](screenshots/stage-23.png) |
| 24 | Wind Canyon | 272 | Windmills have very thin crossing blades; improve structural thickness and keep clear of combat sightlines. | [View](screenshots/stage-24.png) |
| 25 | Crystal Cavern | 258 | Cavern is open sky with emissive spikes; add a cave framing silhouette and toned crystal faces. | [View](screenshots/stage-25.png) |
| 26 | Summoning Grounds | 280 | Scroll props lie flat and look like scraps; use upright or rolled scrolls and a summoning focal circle. | [View](screenshots/stage-26.png) |
| 27 | Serpent Valley | 331 | Serpent statues are angular zigzags; refine heads and coils so the silhouette communicates snake. | [View](screenshots/stage-27.png) |
| 28 | Toad Mountain | 304 | Toad statues read as stone blocks with eyes; improve crouched body silhouette. | [View](screenshots/stage-28.png) |
| 29 | Hidden Laboratory | 250 | Laboratory is scattered cyan cylinders and pillars; create a readable lab focal assembly. | [View](screenshots/stage-29.png) |
| 30 | Sage Sanctuary | 296 | Golden tree canopy obscures foreground; sanctuary needs coherent natural grouping. | [View](screenshots/stage-30.png) |
| 31 | War-Torn Village | 273 | Ruined boxes communicate damage but not a village; compose a damaged street silhouette. | [View](screenshots/stage-31.png) |
| 32 | Hidden Hideout | 249 | Hideout shares the dark corridor template; add a hidden entrance landmark. | [View](screenshots/stage-32.png) |
| 33 | Lightning Citadel | 249 | Citadel uses rods and yellow palette rather than a citadel; add a strong structural focal point. | [View](screenshots/stage-33.png) |
| 34 | Wind Temple | 281 | Temple repeats miniature pagodas; unify hierarchy and avoid foreground occlusion. | [View](screenshots/stage-34.png) |
| 35 | Tailed Beast Valley | 249 | Beast valley lacks a large beast-related landmark; current identity is orange rocks. | [View](screenshots/stage-35.png) |
| 36 | Cloud Temple | 270 | White temple pieces nearly merge with ground and lighting; increase material/value separation. | [View](screenshots/stage-36.png) |
| 37 | Floating Islands | 284 | Floating-island props exist but the play surface is still a flat corridor; communicate depth and suspension. | [View](screenshots/stage-37.png) |
| 38 | Divine Waterfall | 284 | Waterfalls resemble rigid blue slabs; add a visible source, falling-water motion and a receiving pool. | [View](screenshots/stage-38.png) |
| 39 | Golden Summit | 282 | Gold foliage and columns overwhelm composition; reserve gold for the primary landmark. | [View](screenshots/stage-39.png) |
| 40 | Heavenly Gateway | 312 | White/gold gateway feels close to stages 36/38; give gateway a distinctive arch silhouette. | [View](screenshots/stage-40.png) |
| 41 | Void Rift | 304 | Magenta spikes lose internal shading; reduce neon coverage and establish a rift focal point. | [View](screenshots/stage-41.png) |
| 42 | Six Paths Ruins | 278 | Ruins share pillars/pines with prior stages; introduce distinct iconography and silhouette. | [View](screenshots/stage-42.png) |
| 43 | Dark Moon Realm | 310 | Red spikes on dark blue read as colour substitution of Void Rift; strengthen moon identity. | [View](screenshots/stage-43.png) |
| 44 | Celestial Battlefield | 248 | Battlefield is another banner/pillar corridor; add celestial-scale framing and clear arena boundaries. | [View](screenshots/stage-44.png) |
| 45 | Dimension Nexus | 286 | Floating dark rocks and cyan pines have low contrast; use rim accents and a clear nexus landmark. | [View](screenshots/stage-45.png) |
| 46 | Divine Forest | 300 | Large pagoda and gold foliage crowd the frame; refine hierarchy and preserve combat view. | [View](screenshots/stage-46.png) |
| 47 | Chakra Dimension | 259 | Blue corridor and luminous spikes overlap other chakra/void themes; establish unique energy motif. | [View](screenshots/stage-47.png) |
| 48 | Eternal Temple | 286 | Large white/gold pagodas repeat prior temple treatment and obscure sightlines. | [View](screenshots/stage-48.png) |
| 49 | Godly Battlefield | 282 | Gold foliage plus pillars feels decorative rather than a final battlefield; create a clear approach to summit. | [View](screenshots/stage-49.png) |
| 50 | Divine Summit | 283 | Final stage remains corridor template with flat end wall; needs a dedicated finale composition and readable boss arena. | [View](screenshots/stage-50.png) |

## Source coverage and repository comparison
All 19 current source containers are retained in the source snapshot ZIP. All seven client scripts and three ServerStorage source containers are absent from the inspected GitHub tree.

| Live source | Comparison with repository |
|---|---|
| ReplicatedStorage.Shared.Assets | DIFFERS |
| ReplicatedStorage.Shared.Config | Matches after newline/outer whitespace normalization |
| ReplicatedStorage.Shared.SystemsConfig | Matches after newline/outer whitespace normalization |
| ServerScriptService.Main | Matches after newline/outer whitespace normalization |
| ServerScriptService.Services.AbilityService | Matches after newline/outer whitespace normalization |
| ServerScriptService.Services.DataService | DIFFERS |
| ServerScriptService.Services.EnemyService | DIFFERS |
| ServerScriptService.Services.GameService | DIFFERS |
| ServerScriptService.Services.SystemsService | DIFFERS |

## Evidence pack
- [Screenshot gallery](gallery.html): 50 stage captures plus desktop menus, combat, pets and device captures.
- [Console log](playtest-console.txt): first desktop play session, including training/auto errors.
- [Source snapshot](studio-audit-snapshot.zip): captured sources and stage inventories. A full place backup is still required before future edits.
- Earlier [repository audit](https://github.com/zeringflix/anime-hand-signs/blob/main/docs/audits/issue-2.md) was read as context; its no-playtest status is superseded only by the specific evidence recorded here.

