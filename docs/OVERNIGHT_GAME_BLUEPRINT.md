# Overnight game blueprint — Issue #3 (prototype lock + first five biomes)

**Document type:** design specification only. Nothing in this file is implemented by this change.
**Date:** 2026-11-01 · **Branch:** `ai/issue-3` · **Author:** Claude Code (Sonnet 5.5), unattended documentation pass
**Scope guard:** no Roblox Studio instance was queried or modified, no scripts/map/purchases/places were touched, no tests were run. The only repository change is this file.

---

## 0. How to read this document

### 0.1 Status tags (used on every non-trivial statement)

| Tag | Meaning |
|---|---|
| **[CONFIRMED]** | Owner direction recorded in `docs/GAME_SPEC.md` / `docs/DECISIONS.md` ("Accepted owner direction"). |
| **[REPO]** | Read directly from files committed under `scripts/` in this session. This is a stale-able snapshot, **not** proof of live Studio state. |
| **[AUDIT]** | Taken from the committed `docs/audits/issue-2.md` (an earlier AI read-only audit of live Studio). I did not re-verify it. |
| **[PROPOSED]** | My recommendation. **Not approved.** Every number tagged this way is provisional. |
| **[UNVERIFIED-STUDIO]** | An assumption about the live place that I could not check from the repository. |
| **[MODEL]** | A number I calculated by hand from committed formulas. It is arithmetic, not a playtest result. Re-check by printing `Config.Stages` in Studio before relying on it. |

### 0.2 What I did *not* do
- No Studio connection was used (optional per the task scope; skipped to keep the pass strictly non-destructive).
- No playtest happened. **There are no playtest results in this document.** Anything that sounds like one is a [MODEL] estimate or a [PROPOSED] target.
- The client scripts (`StarterPlayerScripts.Client.*`: `Main`, `HUD`, `Menus`, `UIKit`, `VFX`, `Anim`, `Looks`) and `ServerStorage.StageBuilder` are **not in the repository** [AUDIT]. All client/UI behaviour below is therefore [UNVERIFIED-STUDIO] or [PROPOSED].
- Issue #2's Studio audit is not treated as complete. Its report exists but flags blockers (section 9.1); this issue does not depend on it.

### 0.3 The single most important finding
The committed `scripts/` already contain a nearly complete 50-stage simulator (14 hand-sign tiers, 28 jutsu, pets, auras, rebirth, daily rewards) [REPO]. The issue text and `docs/GAME_SPEC.md` describe a *clean prototype first*. So this blueprint does **not** design from zero. It (a) maps the owner's requirements onto what the code already does, (b) lists the gaps, and (c) proposes the smallest ordered set of changes. Also, per the audit, the **live place is ahead of the repo** (lobby code, `KyubiCoins`, a "30-stage" clamp), so nothing here may be applied by pushing repo files into Studio (section 9.1, risk R1).

---

## 1. Owner-confirmed requirements vs proposals

### 1.1 Confirmed (from `docs/GAME_SPEC.md`, `docs/DECISIONS.md`)
1. Game title **+1 Anime Hand Signs**; Roblox progression game. **[CONFIRMED]**
2. Start with a weak, recognizable hand-sign power; unlock stronger techniques; spectacle grows with progress. **[CONFIRMED]**
3. **50 progression stages**, biomes/enemies visibly escalating, inspired by the structure of +1 Anime Eyes without copying protected assets. **[CONFIRMED]**
4. Each **major power unlock = signature move + two additional attacks** (three usable abilities per tier). **[CONFIRMED]**
5. Server-authoritative rewards/damage/unlocks; safe persistence; data-driven stages (not 50 bespoke scripts); keyboard/mouse + touch + controller. **[CONFIRMED]** (listed as design constraints in the spec)
6. Prototype before scale: train → starter ability → kill server-controlled enemy → reward → unlock next tier → persist; then stages 1–5; then 50. **[CONFIRMED]**

### 1.2 Explicitly *not* approved (spec says so)
Exact stats, prices, rebirths, premium products, enemy roster, stage names/biome order, power-tier names, drop rates, unlock pacing, animations, UI layout. **Everything numeric below is [PROPOSED] unless it is quoted from `Config`.** Quoting a number from `Config` does **not** make it approved; it only means it is what the committed code currently does.

### 1.3 Requirement → current code map

| Owner requirement | What `scripts/` does today | Gap |
|---|---|---|
| Hand-sign training, readable power | `Train` remote, server cap 12 taps/s, `HandSigns` counter, `Multiplier` attribute [REPO] | Tutorial/prompt flow not in repo [AUDIT]. |
| Starter hand-sign power | `Tiger` sign auto-unlocked + equipped; E = Fireball, R = Phoenix Flower [REPO] | Starter tier has **two** jutsu + M1, not "signature + two" (see 3.1). |
| Three abilities per tier | Every sign has `E` and `R` plus a shared M1 basic attack [REPO] | Third *jutsu* slot does not exist. Owner must choose (Q-3). |
| Enemy fights, rewards | `EnemyService` (server HP table, 10 Hz AI), `CreditKill` rewards [REPO] | All normal enemies share one melee behaviour (section 4.3). |
| Stage gates | 5 kills of any enemy in the stage → `HighestUnlockedStage + 1`; server guard teleports players back past the gate [REPO] | Boss kill not required; no power check (risk R3). |
| Escalating world difficulty | `Recommended`, `EnemyHp`, `EnemyDamage`, `XP`, `Trophies` generated per stage from formulas [REPO] | Never playtested [AUDIT: balance pass not done]. |
| 50 stages data-driven | `Config.Stages` (50 rows) + one generic `EnemyService` [REPO] | Per-stage obstacles/behaviour are not data-driven yet. |
| Rebirth "only if approved" | **Implemented and callable**: `SystemsService.A.Rebirth` [REPO] | Needs a feature flag until approved (risk R2). |

---

## 2. The 60-second onboarding loop and the starter power

### 2.1 Design goals [PROPOSED]
- A new player with zero reading understands: *tap → number goes up → I hit harder → enemies fall → gate opens*.
- First enemy kill within ~45 s; first Fireball cast within ~60 s; stage 1 cleared within ~90 s.
- Every step is triggered by a **server-observed event**, never by a client claim.

### 2.2 Minute-one beat sheet [PROPOSED targets, not measured]

| t (s) | Player sees / does | Server-side truth | Feedback | Skippable? |
|---|---|---|---|---|
| 0–5 | Spawn facing a glowing training spot + big arrow. Tiger hand-sign emblem + text "TAP TO TRAIN". | Profile loaded; `CurrentStage` = 1 (default) [REPO]. | Camera framing, arrow, pulsing button. | n/a |
| 5–20 | Taps; each tap shows "+1" and the Hand Signs counter ticks; a small "DMG" readout rises. | `Train` batches validated (cap 12/s) [REPO]. | Pop number, counter bump, sound blip. | Prompt hides after 25 taps. |
| ~20 | "FIRE SEAL READY" at ~50 Hand Signs: Fireball button glows. | Nothing locked; the glow is just a hint. At ≥ **47** Hand Signs one Fireball one-shots a Stage 1 enemy (derived: 3×(10+0.5·P) ≥ 100) [MODEL]. | Button pulse. | Yes. |
| 20–35 | Walk to nearest Stage 1 enemy (≤30 studs). Prompt: "ATTACK" (M1). | M1 range 16 studs, cooldown 0.32 s [REPO]. | Hit flash, damage number, enemy HP bar [REPO]. | Prompt hides after first hit. |
| 35–50 | Prompt: "FIREBALL (E)". Enemy dies to it. | `Cast` derives the jutsu from the equipped sign server-side [REPO]. | Impact VFX, cooldown ring, "4 LEFT". | Prompt hides after first cast. |
| 50–90 | Kills 4 more; "N LEFT" counter; on the 5th kill the gate flashes open; trophy pad glows. | `CreditKill` → stage clear → `HighestUnlockedStage = 2`, `PendingPads` [REPO]. | Banner "STAGE 1 CLEARED", gate colour change, reward toast. | n/a |
| 90+ | "Walk into Stage 2" arrow; "NEXT POWER: Ram Sign at Stage 4 + 1,200 Hand Signs" progress bar. | Sign unlock rule: `HighestUnlockedStage ≥ 4` **and** `HandSigns ≥ 1200` [REPO]. | Persistent next-goal bar. | n/a |

### 2.3 The starter power
**[REPO]** The starter tier is the `Tiger` sign: training multiplier ×1, unlocked from the first load (`UnlockedHandSigns = {Tiger = true}`), jutsu `Fireball` (E) and `PhoenixFlower` (R).
**[PROPOSED]** Keep Tiger as the starter. The player's identity at start = "a beginner who can make a Tiger seal and throw one small fireball." Nothing is locked behind tutorial completion (a player who ignores the prompts can still play normally).

### 2.4 Tutorial state (proposed data)
Add one persisted table, e.g. `Tutorial = {Step = 0, Done = false}` to `DataService.Default()`. `migrate()` already back-fills missing top-level keys [REPO], so no schema bump is needed. Steps advance only from server events: `Train` accepted, `Damage` landed, `Cast` accepted, `StageCleared`. **Dependencies:** client export (so the prompt UI can be built) and Studio verification of live `DataService.Default()` (live has extra fields, risk R1).

---

## 3. Combat and abilities

### 3.1 The "signature + two supporting" requirement vs current code
**[CONFIRMED]** three usable abilities per major unlock. **[REPO]** today: M1 (basic attack) + `E` + `R` per sign. There are two ways to read the owner's requirement; this is **Open Question Q-3**:

| Option | Slots per tier | Pros | Cons |
|---|---|---|---|
| A (**recommended, unapproved**) | M1 stays a free basic attack; each tier gets **three jutsu**: Signature `E`, Support A `R`, Support B `F` | Matches "signature + two additional attacks" literally; M1 remains a spam-able filler. | Needs 14 new jutsu rows, a third remote slot, a third mobile button, and UI space. |
| B | Treat M1 + `E` + `R` as the three | Zero code. | M1 is not a "technique", so the owner's wording is arguably not met. |

The rest of this section assumes **Option A**. Under Option B, skip 3.3's third-slot row and the F6 feature (section 8).

### 3.2 Existing combat rules (verified in code) [REPO]
- Damage = `(10 + 0.5 × HandSigns) × (1 + 0.02 × (Level−1)) × (1 + 0.2 × JutsuDamageUpgrade)`; jutsu damage = that × the jutsu's `DamageMult`.
- M1: range 16 studs, cooldown 0.32 s (server allows 0.12 s early tolerance), 5/s rate bucket, `Nearest` target weighted toward facing.
- Cast: the **client sends only "E" or "R"**; the server picks the jutsu from the equipped sign, checks unlocked, global 1.2 s lock after an equip swap, per-**jutsu** cooldowns (swapping signs cannot reset them), 4/s rate bucket.
- Cooldown reduction upgrade: −4 % per level, capped at −40 %.
- Enemy HP lives in a Lua table (not `Humanoid.Health`), so huge numbers stay exact.
- Players can only damage enemies in stages they have unlocked.
- Kill credit: every player who dealt **any** damage to an enemy gets the full reward (see risk R3).

### 3.3 Tier 1 (Tiger, starter) — signature + two supporting [PROPOSED names/numbers]

Existing rows are quoted from `Config.Jutsu`; the third row is new. **Display names are proposed originals** to reduce IP risk (section 9.3); IDs/handlers can stay unchanged because names are data.

| Slot | Role | Config ID | Current display name [REPO] | Proposed original name | Kind (server handler) | Input | Damage role | Range / hit rule | Cooldown | Animation / VFX direction |
|---|---|---|---|---|---|---|---|---|---|---|
| E | **Signature**: reliable single-target burst | `Fireball` | "Fire Style: Fireball Jutsu" | "Ember Orb" | `projectile`: homing, travel time = dist/90, splash 6 studs (non-target takes 50 %) | KB: `E` · Touch: E button · Pad: proposed `ButtonX` | 3× base | Range 70 studs; needs a target; "NoTarget" toast otherwise | 3 s (current) | Two-hand Tiger seal pose (index fingers up) → orange orb from hands → fire burst on impact; keep ≤ 1 emitter group. |
| R | **Support A**: multi-hit spread vs groups | `PhoenixFlower` | "Fire Style: Phoenix Flower Jutsu" | "Cinder Petals" | `multiprojectile`: 6 small homers, 0.07 s apart, spread over nearest enemies | `R` · R button · proposed `ButtonY` | 1.4× per petal (8.4× if all hit one target) | Range 65; needs a target | 6 s (current) | Short seal-clap → petal-shaped flames fan out then curve. |
| F (**new**) | **Support B**: defensive spacing / panic button | `AshRing` (**new row, proposed**) | — | "Ashen Ring" | `aoe` (**existing handler**, no new server mechanic): radial burst around the caster, 0.8 s root, knockback 40 | `F` · F button · proposed `ButtonB` | 1.8× (**[PROPOSED]**) | Radius 12 studs around caster; no target needed | 8 s (**[PROPOSED]**) | Palm-down ground slam → expanding ember ring on the floor. |

Design intent: three different answers: *one big hit*, *many small hits*, *get-off-me*. Satisfies the existing code comment "every pair on a sign differs in kind". Adding `AshRing` needs only a config row and the third-slot plumbing (feature F6).

**Measurable acceptance (for whoever implements it):**
- A1. Fireball cooldown ring reaches 0 within ±0.2 s of 3.0 s (stopwatch or `workspace:GetServerTimeNow()` from the `Cooldown` notify payload) in 10 consecutive casts.
- A2. A client that fires `Cast` with `"F"` before the feature is enabled, or with `nil`, `1`, `"E "`, a table, is ignored: 0 server errors, 0 state change.
- A3. At 47 Hand Signs, one Fireball removes ≥100 HP from a Stage 1 enemy (`Hp` attribute on the model).
- A4. `AshRing` with no enemies in range still shows a cooldown but grants 0 XP (see risk R5; fix required for F6).

### 3.4 Tier 2 (Ram) — unlocks inside the first five stages [REPO + PROPOSED]
Ram unlocks at **Stage 4** and **power 1,200** (`floor(Recommended[4] × 0.5)`, with `Recommended[4] = 2400`) [MODEL]. Today: E `Rasengan` (dash, 5×, 5 s), R `ShadowClone` (2 clones, 8 s, 12 s cooldown), training multiplier ×3 [REPO].

| Slot | Config ID | Proposed original name | Kind | Note |
|---|---|---|---|---|
| E | `Rasengan` | "Spiral Core" | `dash` | Exists. |
| R | `ShadowClone` | "Echo Clones" | `clones` | Exists. |
| F (new) | `SpiralGuard` (**new, proposed**) | "Spiral Guard" | `shield` (existing handler: 85 % reduction, repelling pulses) | Reuses Dog tier's `WaterWall` mechanic with a new VFX family. Proposed 3 s / 10 s cooldown. **[PROPOSED]** |

Tiers 3–14: **not designed here.** Snake (stage 7) is the next. Authoring the third jutsu for tiers 3–14 is a later content issue, not blocking.

### 3.5 Input device notes [UNVERIFIED-STUDIO]
The audit says HUD has ATTACK, E and R buttons and that "touch and gamepad inputs are present" [AUDIT]. I could not read the client code. **[PROPOSED]** mapping, to be reconciled with the real client before building:

| Action | Keyboard / mouse | Touch | Gamepad |
|---|---|---|---|
| Train | Click/tap training prompt (existing behaviour, details unknown) | Tap prompt | `ButtonA` on prompt |
| Basic attack (M1) | Left click | ATTACK button | `ButtonR2` |
| Signature (E) | `E` | E button, bottom-right arc | `ButtonX` |
| Support A (R) | `R` | R button | `ButtonY` |
| Support B (F) | `F` | F button | `ButtonB` |
| Equip sign | Signs menu | Signs menu | Signs menu |

Rules: buttons ≥ 44 px, show cooldown radial + hand-sign emblem, never rely on colour alone, no input conflicts with Roblox defaults (jump/chat/menu).

### 3.6 Combat readability and enemy telegraph rules [PROPOSED]
- Every enemy attack that can deal > 15 % of the player's max HP shows a ground/body telegraph ≥ 0.6 s before damage (the existing boss blast telegraphs 1.0 s [REPO]).
- Damage is applied at resolution time only if the player is still inside the radius (existing code does this for boss blasts [REPO]).
- Hit feedback ≤ 100 ms: damage number + hit flash (exist [REPO]).
- Effects budget: one ParticleEmitter group per jutsu, `ReduceEffects` setting must exist and be honoured (setting exists in `Default().Settings` [REPO]).

---

## 4. First five stages: detailed design

Base data below is quoted from `Config.Stages` [REPO] (names, enemies, bosses, elements, colours). Obstacles, behaviours and gate rules are [PROPOSED]. Region: stages 1–5 are Region 1 "Beginner Shinobi Grounds" [REPO].

### 4.1 Stage cards

#### Stage 1 — Leaf Grove (element `leaf`, prop `pine`, gate colour pink)
- **Teaches:** train, M1, Fireball, kill counter, gate.
- **Enemies [REPO]:** Leaf Genin, Leaf Scout, Academy Ninja. **Boss [REPO]:** Academy Captain.
- **Proposed behaviour set:** all `Brawler` (existing melee). Enemy damage 6 vs player 110 HP [MODEL] → the player cannot die in under ~19 hits; this is intentional tutorial safety.
- **Core obstacle [PROPOSED]:** none besides HP; the only "challenge" is realising training makes enemies easier.
- **Gate [PROPOSED]:** 5 kills (current rule). Boss optional here.
- **Visible progression:** "5 LEFT" counter, gate recolours, trophy pad, first Ninja Egg affordable (45 Trophies) [MODEL].

#### Stage 2 — Cherry Blossom Hill (`wind`, `blossom`)
- **Teaches:** groups, positioning.
- **Enemies [REPO]:** Blossom Ronin, Sakura Spirit, Blossom Guard. **Boss:** Sakura Commander.
- **Proposed new behaviour:** `Lunger` (0.6 s windup, then a 10-stud lunge; hit only if still in line).
- **Core obstacle [PROPOSED]:** two enemies at once at a narrow petal path.
- **Gate:** 5 kills (current). **Visible progression:** Sakura Egg and "Blue Chakra Aura" (300 Trophies, ×1.5 training) become available [REPO + MODEL].

#### Stage 3 — Sand Dunes (`earth`, `cactus`)
- **Teaches:** dodge ranged attacks, use Phoenix Flower on groups.
- **Enemies [REPO]:** Sand Genin, Desert Scout, Sandblade Ninja. **Boss:** Sandblade Captain.
- **Proposed new behaviour:** `Slinger` (stands at range ~25 studs, 0.8 s ground-circle telegraph at the player's position, damage if still inside radius 6). Reuses the *pattern* of the boss blast [REPO].
- **Core obstacle [PROPOSED]:** open dune with 2–3 rock clusters. *Cover that actually blocks* would need line-of-sight checks that do not exist; treat rocks as cosmetic until a LOS feature is approved.
- **Visible progression:** Desert Egg unlocks [REPO]; warm Lighting grade (client tweens `Atmosphere`/`StageGrade` per stage [AUDIT]).

#### Stage 4 — Red Canyon (`earth`, `rock`)
- **Teaches:** the **tier unlock moment** (Ram) and why a new sign changes play, not only damage.
- **Enemies [REPO]:** Canyon Rogue, Red Stone Ninja, Canyon Berserker. **Boss:** Canyon Warlord.
- **Proposed new behaviour:** `Bruiser` (HP ×1.5, damage ×1.3, slower) and `Berserker` enrage (speed ×1.3 below 50 % HP).
- **Core obstacle [PROPOSED]:** a canyon lane ~30 studs wide, so cone/beam/pierce abilities hit several enemies.
- **Gate:** 5 kills **and** boss (see Q-6, unapproved).
- **Visible progression:** Ram unlock cinematic toast ("NEW SIGN: RAM") the first time `HandSigns ≥ 1200` while `Highest ≥ 4` (rule exists [REPO]; the toast `SignUnlocked` exists as a notify kind [REPO]; the visual treatment is [PROPOSED]); hand-sign emblems on HUD swap to Ram.

#### Stage 5 — Bamboo Sanctuary (`leaf`, `bamboo`) — Region 1 capstone
- **Teaches:** combining kits (Ram dash/clones) against mixed groups, a boss with patterns.
- **Enemies [REPO]:** Bamboo Assassin, Bamboo Monk, Forest Sentinel. **Boss:** Bamboo Guardian.
- **Proposed behaviour mix:** Lunger + Slinger + Bruiser together; boss uses the existing telegraphed ranged blast [REPO] plus a **proposed** second ring pattern.
- **Core obstacle [PROPOSED]:** boss + 2 adds; first stage where standing still is punished.
- **Gate:** 5 kills + boss (Q-6). Clearing awards the Stage-5 milestone: `Trophies × 50` = 850 [REPO + MODEL] (existing `MilestoneStages`).
- **Visible progression:** "Sakura Aura" becomes buyable (×2.5, 1,020 Trophies [MODEL]); region banner "Beginner Shinobi Grounds complete" [PROPOSED].

### 4.2 Presented numbers (stage 1–5) — [MODEL], arithmetic from `Config`
`Recommended` and counts follow `Config.Stages` formulas; `EnemyHp = (10 + 0.5·max(Recommended,5)) × 8`.

| Stage | Recommended power | Normal enemy HP | Boss HP (×6) | Enemy damage | Trophies/kill | XP/kill | M1 hits to kill at *recommended* power |
|---|---|---|---|---|---|---|---|
| 1 | 0 (HP computed as if 5) | 100 | 600 | 6 | 3 | 3 | 10 at power 0 |
| 2 | 60 | 320 | 1,920 | 8 | 5 | 5 | 8 |
| 3 | 400 | 1,680 | 10,080 | 10 | 7 | 6 | 8 |
| 4 | 2,400 | 9,680 | 58,080 | 12 | 11 | 8 | 8 |
| 5 | 13,000 | 52,080 | 312,480 | 14 | 17 | 9 | 8 |

Notes: values are hand-calculated; the generated `Config.Stages` is authoritative for what the code does. The `Recommended` curve is rounded by `roundNice`; check rows by printing the table once.

### 4.3 Enemy archetype template [PROPOSED]
Today `EnemyService.think` runs one behaviour for every normal enemy: chase the nearest player within 38 studs, melee in 5.5 studs every 1.4 s; bosses add a telegraphed ranged blast; stage 50 has special phases [REPO]. To make stages 2–5 feel different with data only, add a `Behavior` string per enemy slot:

| Behavior | Rule | Counterplay | First appears |
|---|---|---|---|
| `Brawler` | Existing melee | Kill it | Stage 1 |
| `Lunger` | 0.6 s windup → 10-stud lunge, then 1.5 s recovery | Sidestep during windup | Stage 2 |
| `Slinger` | Keeps ~25 studs away; 0.8 s ground telegraph, radius 6 | Leave the circle; close the gap | Stage 3 |
| `Bruiser` | HP ×1.5, dmg ×1.3, speed ×0.85; enrage <50 % HP | Use cone/pierce; keep spacing | Stage 4 |
| `Boss` | Existing + one extra pattern per 5 stages | Learn the telegraphs | Stage 1 |

### 4.4 Stage-gate rule options [PROPOSED]

| Rule | Behaviour | Risk |
|---|---|---|
| Current [REPO] | 5 kills of any enemy | Boss not required; trivial to skip challenge; chip-damage kill credit (R3). |
| **Recommended (unapproved)** | 4 kills + boss kill, minimum damage share ≥10 % for credit | Changes `StageKills` semantics; needs migration thought (R8). |
| Power-gated | `HandSigns ≥ Recommended × 0.5` to enter | Hard stop for stuck players; needs clear HUD. |

Soft gating already exists via HP scaling: at power 100, a Stage 3 enemy takes 28 M1 hits (~9 s) instead of 8 [MODEL].

---

## 5. Data template for all 50 stages

### 5.1 Row template [PROPOSED extension of `Config.Stages`]
One row per stage. Fields marked **R** exist today [REPO]; **N** are new.

| Field | Type | R/N | Note |
|---|---|---|---|
| `Index`, `Name`, `Region` | number/string/number | R | Region = ceil(i/5). |
| `Enemies` (3 names), `Boss` | strings | R | |
| `Ground/Path/Cliff/Leaf/Trunk/Gate` | Color3 | R | Visuals. |
| `Prop`, `Element` | strings | R | Drives builder/VFX. |
| `Recommended`, `Trophies`, `EnemyHp`, `EnemyDamage`, `XP` | numbers | R | Formula-generated. |
| `EnemyBehaviors` (3) | strings | **N** | From 4.3. |
| `KillsToClear`, `RequireBoss` | number/bool | **N** | Per-stage override of `Economy.KillsToClear`. |
| `MaxAlive`, `RespawnSeconds` | numbers | **N** | Caps performance (R10). |
| `Obstacle` | string tag | **N** | Builder hint. |
| `UnlocksSign`, `UnlocksEgg`, `UnlocksAura` | ids | **N**/R | Today scattered across Config/SystemsConfig. |
| `Status` | `"designed" / "placeholder"` | **N** | Honest tracking. |

### 5.2 Validation (feature F4)
A pure function `Config.Validate()` should assert: exactly `StageCount` rows; unique names; `Recommended` non-decreasing; every egg/aura/sign stage reference exists; no stage > `StageCount` referenced; every behaviour string known.

### 5.3 Inventory of all 50 stages — from `Config.Stages` [REPO]. Only 1–5 are designed in detail.

| # | Name | Element | Boss | # | Name | Element | Boss |
|---|---|---|---|---|---|---|---|
| 1 | Leaf Grove | leaf | Academy Captain | 26 | Summoning Grounds | earth | Summoning Master |
| 2 | Cherry Blossom Hill | wind | Sakura Commander | 27 | Serpent Valley | poison | Serpent Sage |
| 3 | Sand Dunes | earth | Sandblade Captain | 28 | Toad Mountain | water | Toad Sage Guardian |
| 4 | Red Canyon | earth | Canyon Warlord | 29 | Hidden Laboratory | chakra | Forbidden Scientist |
| 5 | Bamboo Sanctuary | leaf | Bamboo Guardian | 30 | Sage Sanctuary | nature | Ancient Sage |
| 6 | Misty Marsh | water | Mist Commander | 31 | War-Torn Village | fire | War General |
| 7 | Stone Valley | earth | Stone Guardian | 32 | Hidden Hideout | shadow | Shadow Organization Leader |
| 8 | Frozen Pass | ice | Frost Commander | 33 | Lightning Citadel | lightning | Thunder Kage |
| 9 | Storm Peak | lightning | Thunder Captain | 34 | Wind Temple | wind | Wind Master |
| 10 | Lava Crater | fire | Inferno Commander | 35 | Tailed Beast Valley | chakra | Beast Chakra Guardian |
| 11 | Spirit Forest | spirit | Forest Curse Master | 36 | Cloud Temple | wind | Celestial Commander |
| 12 | Moonlit Ruins | moon | Ancient Jutsu Master | 37 | Floating Islands | wind | Floating Island Master |
| 13 | Poison Swamp | poison | Poison Sovereign | 38 | Divine Waterfall | water | Divine Water Guardian |
| 14 | Haunted Graveyard | spirit | Graveyard Warden | 39 | Golden Summit | light | Golden Sage |
| 15 | Forbidden Shrine | spirit | Forbidden Shrine Master | 40 | Heavenly Gateway | light | Heavenly Gatekeeper |
| 16 | Samurai Village | steel | Samurai General | 41 | Void Rift | void | Void Master |
| 17 | Iron Fortress | steel | Iron Warlord | 42 | Six Paths Ruins | chakra | Six Paths Guardian |
| 18 | Shadow Dojo | shadow | Shadow Sensei | 43 | Dark Moon Realm | moon | Lunar Sovereign |
| 19 | Crimson Battlefield | fire | Crimson Commander | 44 | Celestial Battlefield | light | Celestial Warlord |
| 20 | Ancient Castle | steel | Castle Shogun | 45 | Dimension Nexus | void | Dimension Master |
| 21 | Thunder Forest | lightning | Thunder Beast | 46 | Divine Forest | light | Divine Forest Master |
| 22 | Inferno Temple | fire | Flame Master | 47 | Chakra Dimension | chakra | Chakra Overlord |
| 23 | Tidal Sanctuary | water | Water Dragon Guardian | 48 | Eternal Temple | light | Eternal Sage |
| 24 | Wind Canyon | wind | Tempest Commander | 49 | Godly Battlefield | chakra | Supreme Shinobi |
| 25 | Crystal Cavern | crystal | Crystal Overlord | 50 | Divine Summit | divine | Divine Chakra Master |

The audit also reports a live comment about shrinking the course to 30 stages while 50 remain defined [AUDIT]; **Q-1** asks the owner to settle this.

---

## 6. Training, currency, upgrades, rebirth, gates, scaling

### 6.1 Currencies and stats [REPO]
- **Hand Signs** (`HandSigns`): the training counter *and* the power stat. Never spent. Damage is computed from it.
- **Trophies**: spendable (upgrades, eggs, auras). Earned from kills, trophy pads, rewards.
- **XP / Level**: from kills and casts; +2 % damage and +10 max HP per level; XP per level `floor(5 + 1.4L + L^1.6)` (7, 10, 15 for levels 1–3 [MODEL]).
- Live place also has `KyubiCoins` [AUDIT] which I cannot see in the repo; its purpose is **unknown**. Do not design around it until export.

### 6.2 Training gain [REPO]
`gain per tap = BaseGain(1) × (1 + SignsPerClick level) × sign multiplier × rebirth multiplier × pets × aura × passes`. Multipliers stack **multiplicatively**. Tiger ×1, Ram ×3, Snake ×8, Rat ×20, Ox ×50 … Forbidden ×250,000. Server cap 12 taps/s; AutoTrain is separate.

### 6.3 Upgrade costs (Trophies, `floor(Base × Growth^level)`) [REPO + MODEL]

| Upgrade | Effect | L0→L1 | L1→2 | L2→3 | L3→4 | L4→5 |
|---|---|---|---|---|---|---|
| Stronger Seals | +1 base signs per tap | 20 | 31 | 48 | 74 | 115 |
| Jutsu Power | +20 % damage | 40 | 64 | 102 | 163 | 262 |
| Quick Hands | −4 % cooldowns (max −40 %) | 100 | 220 | 484 | 1,064 | 2,342 |

### 6.4 Pacing model (taps needed) [MODEL, assumption: 5 taps/s, no pets/auras]

| Goal | Hand Signs needed | Taps at ×1 (Tiger) | Taps with Seals Lv 5 (×6) |
|---|---|---|---|
| Stage 2 recommended | 60 | 60 (12 s) | 10 (2 s) |
| Stage 3 recommended | 400 | 400 (80 s) | ~67 (13 s) |
| Ram unlock power | 1,200 | 1,200 (4 min) | 200 (40 s) |
| Stage 4 recommended | 2,400 | 2,400 (8 min) | 400 (80 s) |
| Stage 5 recommended | 13,000 | ~5,100 taps with the Ram ×3 multiplier after 1,200 (≈17 min) | ~870 (~3 min) |

**Reading:** Seals upgrades dominate pacing. A stage-1 clear gives about 45 Trophies (5 kills × 3 + pad × 10) [MODEL], enough for two Seals levels; stages 2–3 add roughly 75 and 105. So a player who reinvests can finish stages 1–5 far faster than the no-upgrade column. Whether that is desired is **Q-5**. I recommend a target of **20–30 min** for stages 1–5 to keep the first session satisfying but not exhausted, which is unmeasured and **needs a real playtest** before any number is changed.

### 6.5 Pets/auras in the first five stages [REPO + MODEL]
Eggs: Ninja (stage 1, 45 Trophies), Sakura (stage 2), Desert (stage 3). Epic Desert pets give boost +3.0 → a ×4 training multiplier at stage 3 [REPO]; the Blue aura (stage 2, ×1.5, 300 Trophies) and Sakura aura (stage 5, ×2.5) multiply on top. Result: acquisition luck can shift pacing by a large factor. **Risk:** any balance table that ignores pets will be wrong.

### 6.6 Rebirth — **only if approved** [REPO exists; PROPOSED to gate]
Code today: cost `2500 × 7^rebirths`; training multiplier `1 + 0.75 × rebirths`; resets **only** `HandSigns` to 0; keeps stages, signs, pets, auras, upgrades [REPO]. Two consequences:
1. The first rebirth costs 2,500, which is almost exactly Stage 4's recommended power (2,400) [MODEL]: a player can reach it in the first session.
2. Because damage derives from `HandSigns`, a rebirth zeroes damage. After a Stage-4 rebirth, M1 deals 10 against 9,680 HP enemies (≈968 hits ≈ 5 minutes per enemy) [MODEL], until retraining. The 1.75× multiplier softens but does not remove this.

**[PROPOSED]** Add `Config.Features.Rebirth = false` and have `A.Rebirth` and the UI honour it until the owner approves rebirth (Q-4). If approved, redesign what resets (for example, decouple damage from the reset counter).

### 6.7 Monetisation [REPO scaffold, owner approval required]
All pass/product IDs are 0, so purchases are disabled [REPO, AUDIT]. Scaffolding includes "2x Hand Signs", "OP Auto Clicker (5 trains/s)", and Hand-Sign Packs. `CLAUDE.md` forbids creating paid items without approval. **[PROPOSED]** keep IDs at 0 and add a `Features.Monetization = false` guard. Pay-to-progress items need explicit owner sign-off (Q-9).

### 6.8 Enemy scaling and provisional balance table
The code scales enemies by stage only, not by player count [REPO]. **[PROPOSED]** keep that for now; test multi-player before changing.

**Provisional balance targets for stages 1–5 — [PROPOSED], NOT FINAL, NOT PLAYTESTED**

| Stage | Target time to clear (cumulative, new player) | Target power on arrival | Typical enemy TTK at that power (M1 only) | Notes |
|---|---|---|---|---|
| 1 | ≤ 90 s | 0–50 | 3–4 s | Tutorial; Fireball one-shot at ≥47 power. |
| 2 | 3–5 min | ≥ 60 | ≈ 2.6 s (8 hits) | Lunger introduced. |
| 3 | 6–10 min | ≥ 400 | ≈ 2.6 s | Slinger introduced. |
| 4 | 10–18 min | ≥ 2,400 (Ram at 1,200) | ≈ 2.6 s; Bruiser ≈ 4 s | Tier unlock moment. |
| 5 | 18–30 min | ≥ 13,000 | ≈ 2.6 s; boss ≈ 16 s | Region capstone. |

Why 2.6 s: `HitsPerEnemyAtRecommended (8) × M1 cooldown (0.32 s)` [REPO]. A boss is 6× HP ⇒ ≈ 15 s of sustained M1 [MODEL]. These are derived design targets only.

---

## 7. UI behaviour (Roblox) [PROPOSED unless noted]

All current UI is built by script (StarterGui is empty) [AUDIT]; the code is not in the repo. Requirements for whoever builds it:

| Element | Behaviour | Measurable check |
|---|---|---|
| Hand Signs counter + "DMG" readout | Updates ≤ 0.3 s after a tap (server snapshot is throttled to 0.25 s [REPO]) | Tap 10×, counter increases by exactly 10 × gain within 0.5 s. |
| Training prompt | Visible until 25 taps; never covers ability buttons | 25 taps then prompt hidden; no overlap at 360×640. |
| Ability buttons (ATTACK, E, R, F) | Emblem, key hint, radial cooldown; greyed when locked or no data | Press during cooldown: no cast, ring continues. |
| Enemy HP bar | Name + `Config.Format(Hp)/Max` (exists [REPO]) | Matches `Hp` attribute within 1 frame. |
| "N LEFT" counter | Server `StageKills` → remaining | Kill 1 → counter decrements by 1 for this player only. |
| Next-power bar | "NEXT: Ram — Stage 4 + 1,200" with progress | Shows both conditions; turns green when both true. |
| Gate | Recolours when `Highest` rises | Walk into locked gate: pushed back (server guard) with message. |
| Boss bar + phase toasts | Exists per audit [AUDIT] | n/a, verify on export. |
| Settings | `ReduceEffects`, `Music` toggles persist | Toggle, rejoin in a published place; value kept. |
| Mobile | Thumb zones, ≥ 44 px, no overlap at 360×640 | Screenshot at 360×640 and 1920×1080. |

---

## 8. Implementation breakdown (prioritised, independently testable)

Dependencies are explicit. **Nothing below should start until F0 is satisfied.** Every feature needs a Studio playtest (`docs/TEST_PLAN.md`); none can be verified by reading files.

| ID | Priority | Feature | Luau services/modules affected | Depends on | Acceptance checks (all measurable) |
|---|---|---|---|---|---|
| **F0** | P0 (blocker) | **Verified Script Sync + export of live scripts**, fresh `.rbxl` backup, owner answers Q-1/Q-2 | none (process); then `scripts/**` re-exported | owner | Repo hash of every exported script equals live source; client scripts present in repo; backup file date later than lobby work. |
| **F1** | P0 | **Baseline playtest audit** of existing loop (solo + 2 players) | none | F0 | Report lists Output errors verbatim; times for: first kill, stage 1 clear, Ram unlock path; 0 "not tested" claims. |
| **F2** | P1 | **Feature flags** `Config.Features = {Rebirth, Monetization}` default false | `Config`, `SystemsService` (`A.Rebirth`, `A.BuyPass`, `A.BuyProduct`), `GameService` | F0 | With flags false, `Action("Rebirth")`/`BuyPass` return `ok=false`, HandSigns unchanged; flag true restores behaviour. |
| **F3** | P1 | **Config validation** (`Config.Validate()`), clamp `HighestUnlockedStage` ≤ `StageCount` in `migrate()` | `Config`, `DataService`, `Main` (start-up) | F0 | Validation passes on shipped config; a profile with `HighestUnlockedStage = 999` loads as `StageCount`; no nil-index in `DailyReward`. |
| **F4** | P1 | **Tutorial state machine** (server-driven steps, persisted) | new `TutorialService`, `DataService.Default/migrate`, `GameService` events, client HUD | F0, F1 | New profile steps 0→N in order only; forged skip is ignored; median time to first kill ≤ 45 s over 5 manual runs; tutorial can be skipped/never blocks play. |
| **F5** | P1 | **Third ability slot** (`F`) + `AshRing` row | `Config` (HandSign type adds `F`; jutsu row), `AbilityService` (Cast slot list), `GameService.Remotes.Cast`, client input/HUD | F0, Q-3 | Forged slot values (`nil`, 1, `"X"`, long string) ignored; F obeys per-jutsu cooldown; no XP for no-target `aoe`; touch button visible at 360×640. |
| **F6** | P2 | **Enemy behaviour archetypes** (`Lunger`, `Slinger`, `Bruiser`) | `EnemyService` (`Spawn`, `think`), `Config.Stages` (new `EnemyBehaviors`), client VFX for telegraphs | F0, F3 | Telegraph ≥ 0.6 s; damage only if player in radius at resolve; Stage 2–4 enemies each show their behaviour in a recorded run; no new Output errors over a 10-min session. |
| **F7** | P2 | **Gate v2** (`RequireBoss`, per-stage `KillsToClear`, minimum damage share for credit) | `GameService.CreditKill`, `EnemyService.Damage/Kill` (credit), `Config` | F0, F3, Q-6 | Solo: 5 kills without boss does **not** open Stage 4's gate; boss kill does; a second player dealing 1 damage gets no credit; old saves keep progress. |
| **F8** | P2 | **Progress HUD** (next-power bar, "N LEFT", power→damage readout) | client HUD only, plus `GameService.Refresh` attributes | F0 | Values match server attributes in a 2-minute session; no extra remotes. |
| **F9** | P2 | **Stage 1–5 biome/obstacle pass** in Studio | `ServerStorage.StageBuilder` (**read-only until backup**), stage models | F0, F1 | Backup confirmed; no deletion of existing `StageNN` (builders destroy by name, R6); per-stage screenshot; Output clean. |
| **F10** | P3 | **Balance harness** (pure function printing the Section 6 tables) | new `BalanceModel` (shared), no runtime hooks | F3 | Printed table equals Section 4.2/6.4 within rounding. |
| **F11** | P3 | **Remote security review** (`Action`, `Cast`, `Train`, `EquipSign`, `TeleportStage`) | read-only review issue | F0 | Written findings with test case per remote. |
| **F12** | P3 | **Original-name / asset licensing pass** | `Config` (display strings), `SystemsConfig` pet names, `Assets` | owner (Q-2, Q-7) | No jutsu/enemy/stage/pet display string on the owner's reserved list; asset sources documented. |
| **F13** | Later | Rebirth redesign | `SystemsService`, `SystemsConfig`, `GameService` | Q-4 | Only if approved. |

**Build order for early playtesting:** F0 → F1 → F2/F3 → F4 → F5 → F6 → F7/F8 → F9 → F10 (F11/F12 in parallel). After F4, a tester can play the first minute; after F6, stages 2–4 feel distinct; after F9, the first five stages look different.

---

## 9. Regression and security risks revealed by the existing files

### 9.1 Process risks
- **R1. Repo is a stale snapshot of Studio** [AUDIT]. The live place has `DataService.Default()` extra fields (`KyubiCoins`, `TrophyBoostUntil`, `LastLeaveBonus`), `GameService` lobby code and a `ZoneMult` hook, and a "course shrank from 50 to 30" clamp, and longer `EnemyService`/`SystemsService`. Pushing repo files back via Script Sync would regress that work. `Main.legacy.luau` is also named differently from the live `Main`. **Mitigation:** F0 first; treat `scripts/` as non-authoritative until re-exported.
- **R6. Edit-time builders destroy by name** [AUDIT]: `StageBuilder.BuildStage` destroys any existing `StageNN`; `SetupWorld` destroys `Baseplate`/`SpawnLocation`. Never run against the live place without a backup.
- **R-doc. Documentation drift** [AUDIT]: `PROGRESS` and `Config` disagree on the Ram/Horse jutsu swap; unresolved (Q-8).

### 9.2 Code risks (verified in the committed files unless tagged)
- **R2. Rebirth is live and zeroes damage** (6.6). `SystemsService.A.Rebirth` has no flag; cost 2,500 ≈ Stage 4.
- **R3. Gate and credit rules** (`GameService.CreditKill`, `EnemyService.Damage`): (a) any kill counts, boss not required, so the gate does not test the stage; (b) every player in `e.Credit` (any damage > 0) gets the full trophies/XP/Hand Signs and kill progress, enabling chip-damage leeching and AFK farming.
- **R5. Idle-cast XP**: `AbilityService.Cast` grants `AddXP(p, 1)` whenever the handler returns true, and handlers `beam`, `cone`, `aoe`, `evade`, `wall`, `shield`, `transform`, `clones`, `summon` return true with **no target**. Casting at nothing on cooldown yields free XP (and damage-scaling levels). Low severity, easy fix.
- **R8. Persistence/migration**: `migrate()` only back-fills *missing top-level keys*; `SCHEMA` is never bumped; unknown/renamed IDs are not pruned; `HighestUnlockedStage` is not clamped to `StageCount`. If stages are cut to 30, a saved Stage 40 would index past `Config.Stages` in `SystemsConfig.DailyReward`/`ClaimPlaytime` (`Config.Stages[highest]`) and could error. Also `save()` uses a **shallow** `table.clone`, so nested tables can change while an `UpdateAsync` is pending (retries re-use the same snapshot). The lease is deliberately ignored in Studio, so session locking can only be tested on a published server (do not claim it verified).
- **R9. Persistence cannot be proven in an unpublished place** [AUDIT]. In Studio a failed load swaps in a non-saving default profile with a warning [REPO]. Tests must say so.
- **R10. Performance**: `Vfx:FireAllClients` is used for every hit/cast regardless of stage; each damage mutates a server-created `BillboardGui` (bar + text) and attributes; `EnemyService.Nearest`/`InRadius` scan **all** enemies globally (the `stageHint` parameter is unused); the AI loop is O(enemies × players) at 10 Hz; `piercing` ticks at 20 Hz; each enemy spawn builds a `HumanoidDescription` rig. `ensureStage` spawns every spawn point at once. **Mitigation:** per-stage `MaxAlive`, send VFX only to players in the stage, measure before adding behaviours.
- **R11. Hard-coded final-stage literals**: `EnemyService.Spawn` uses `stage == 50` for boss scale/HP; `think` special-cases `Config.StageCount` and `e.Stage == 50`. A 30-stage remap would change which boss gets the phase logic.
- **R12. Position-derived stage state**: `GameService` infers `InStage` and the gate limit from `root.Position.X` and `StageLength = 170` [REPO]. Changing stage layout (needed for biome obstacles) can break the gate guard and `StageSpawnCFrame` fallback.
- **R13. Lobby/`StageSpawnCFrame(0)` fall-through** [AUDIT]: live code expects `workspace.Lobby.LobbySpawn`, which does not exist; falls back to stage 1. Onboarding spawn point (section 2) depends on this.
- **R14. Teleporting abilities** (`dash`, `blink`, `slam`, `evade`) set the character CFrame on the server. The 0.5 s X-position guard corrects overshoot past the gate; acceptable but note when adding movement jutsu.
- **R15. Remote surface**: `Train`, `Attack`, `Cast`, `EquipSign`, `TeleportStage`, `Action` all type-check and rate-limit in the code I read [REPO]. That is **not** a full audit; `Action` dispatches by string to ~20 handlers and deserves its own review (F11).
- **R16. Monetisation scaffolding** (6.7) can start prompting purchases the moment a real ID is pasted into `SystemsConfig`.
- **R17. Studio-only `DevGrant`** BindableFunction is guarded by `RunService:IsStudio()` [REPO]. Keep it so; do not extend it into live code.

### 9.3 IP and asset risks
The repository's names are heavily derived from a well-known anime franchise: jutsu (Rasengan, Chidori, Kirin, Amaterasu, Susanoo, Tailed Beast Bomb, Planetary Devastation, Rasenshuriken, Shadow Imitation/Strangle, Hidden Shadow Snake Hands, Body Flicker, Phoenix Flower, Majestic Destroyer Flame, Great Breakthrough, Substitution), stage and enemy names (Leaf *Genin*, "Thunder Kage", "Six Paths", "Tailed Beast Valley", "Shadow Organization Leader", "Hidden Laboratory/Hideout"), and pets ("Nine-Tail Kit", "Kirin Beast", "Six Paths Beast"). `GAME_SPEC.md` already says these are inspiration only until a content decision is made, and `DECISIONS.md` lists licensed-versus-original as pending. **[PROPOSED]**: use original names (examples in 3.3/3.4) for anything player-visible before publication; names are data so the cost is low. Icons come from a gvesster free pack (commercial use allowed, credit appreciated) plus Blender renders and "reused Smack Your Friend" icons whose ownership I cannot verify from the repo [REPO comment]. Sounds are Roblox built-ins [AUDIT]. No external anime art, audio or models are assumed or required by this plan.

---

## 10. Open questions for owner approval (recommendation given; none assumed decided)

| # | Question | My recommendation (**unapproved**) |
|---|---|---|
| Q-1 | Is the course **30 or 50 stages**? (live comment says 30; config/world have 50) | Keep 50 as the data model (matches confirmed requirement); design only 1–5 now. |
| Q-2 | Original anime-inspired names/looks vs. licensed names? | Original names for all player-visible text before publishing (section 9.3). |
| Q-3 | Three abilities per tier = **M1+E+R** or **three jutsu (E/R/F) plus M1**? | Three jutsu (Option A). |
| Q-4 | Rebirth: approve, redesign, or remove? | Disable via flag until decided; if kept, stop zeroing the damage stat. |
| Q-5 | Target length of stages 1–5 (modelled range is a few minutes to ~17+)? | 20–30 min, measured in a playtest first. |
| Q-6 | Gate rule: any 5 kills (today) vs. boss required vs. power-gated? | 4 kills + boss, minimum damage share for credit. |
| Q-7 | Who owns the icon images and "reused" assets? Credit the free icon pack? | Owner to confirm; keep a licence list in `docs/`. |
| Q-8 | Ram vs Horse jutsu: `PROGRESS` and `Config` disagree. Which is canonical? | Treat `Config` as canonical after re-export. |
| Q-9 | Monetisation (passes, packs, Auto Clicker): approved at all? Prices? | Not now; keep IDs 0; no pay-to-progress without a written decision. |
| Q-10 | What are `KyubiCoins` and the lobby hub for? | Document after F0 export; do not build on unknowns. |
| Q-11 | Player death penalty? Today there is none beyond respawn at the stage spawn [REPO]. | Keep none for stages 1–5. |
| Q-12 | Is damage-share credit (anti-leech) acceptable in co-op? | Yes, ≥10 % share. |

---

## 11. Acceptance-criteria cross-check for Issue #3

- [x] **Owner-confirmed vs proposals:** section 1 (and tags throughout).
- [x] **Every new mechanic has a measurable acceptance test:** F2–F10 (section 8), A1–A4 (3.3), UI checks (section 7).
- [x] **Build order enables early playtesting:** section 8 build-order note.
- [x] **No unlicensed anime assets assumed:** section 9.3; no external assets referenced.
- [ ] **Not done / cannot be done in this pass:** any Studio verification, any playtest result, any code change. Those remain with F0/F1.
