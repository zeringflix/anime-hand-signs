# APPROVED JUTSU ICON MATRIX — ONLY THE 28 ATTACKS ACTUALLY IN GAME

> Generated from `scripts/ReplicatedStorage/Shared/Config.luau` on branch `feature/issue-14-ui-lobby-polish` (2026-11-03). **This configuration—not AI guesses—is authoritative for the active E/R attacks.** Changes to live Studio might differ; compare before uploading or changing UI.

The owner supplied a **new renovated 12-hand-sign sheet**. Its positions, from left to right:

- Row 1: **Dragon, Tiger, Dog, Rat**.
- Row 2: **Ram, Horse, Monkey, Bird**.
- Row 3: **Ox, Serpent (= Config.Snake), Hare, Boar**.

The existing transparent artwork at `assets/icons/hand-signs-art/{Sign}.png` reflects this illustrated hand-seal style; use it for compositing. **Do not redraw, approximate, modify finger anatomy, add fingers, switch poses, or create new seals because an attack name sounds different.** The icon must use the exact pose assigned to its EQUIPPED sign in the current game; effects/attack art surround the approved hands.

## Exact active E / R attack list — 14 signs × 2 = 28 unique icons

| Equipped sign | E icon MUST depict | R icon MUST depict | Exact approved hand-art source |
|---|---|---|---|
| Tiger | Fireball: Fire Style: Fireball Jutsu | PhoenixFlower: Fire Style: Phoenix Flower Jutsu | assets/icons/hand-signs-art/Tiger.png |
| Ram | DragonFlame: Fire Style: Dragon Flame Jutsu | ShadowClone: Shadow Clone Jutsu | assets/icons/hand-signs-art/Ram.png |
| Snake | SnakeHands: Hidden Shadow Snake Hands | StrikingSnakes: Striking Shadow Snakes | assets/icons/hand-signs-art/Snake.png |
| Rat | ShadowImitation: Shadow Imitation Technique | ShadowStrangle: Shadow Strangle Technique | assets/icons/hand-signs-art/Rat.png |
| Ox | Chidori: Chidori | ChidoriStream: Chidori Stream | assets/icons/hand-signs-art/Ox.png |
| Hare | Substitution: Substitution Jutsu | BodyFlicker: Body Flicker Technique | assets/icons/hand-signs-art/Hare.png |
| Horse | Rasengan: Rasengan | MajesticFlame: Fire Style: Majestic Destroyer Flame | assets/icons/hand-signs-art/Horse.png |
| Boar | Summoning: Summoning Jutsu | EarthWall: Earth Style: Earth Wall | assets/icons/hand-signs-art/Boar.png |
| Dog | WaterWall: Water Style: Water Wall | WaterDragon: Water Style: Water Dragon Jutsu | assets/icons/hand-signs-art/Dog.png |
| Bird | GreatBreakthrough: Wind Style: Great Breakthrough | Rasenshuriken: Wind Style: Rasenshuriken | assets/icons/hand-signs-art/Bird.png |
| Monkey | MultiShadowClone: Multi Shadow Clone Jutsu | ChidoriSenbon: Chidori Senbon | assets/icons/hand-signs-art/Monkey.png |
| Dragon | GiantRasengan: Giant Rasengan | Kirin: Kirin | assets/icons/hand-signs-art/Dragon.png |
| Advanced | Amaterasu: Amaterasu | Susanoo: Susanoo | **NO APPROVED POSE IN CURRENT 12-SIGN SHEET** |
| Forbidden | PlanetaryDevastation: Planetary Devastation | TailedBeastBomb: Tailed Beast Bomb | **NO APPROVED POSE IN CURRENT 12-SIGN SHEET** |

**Never generate icons for unrelated moves that aren't in this table**, such as a generic “Genjutsu”, “Lightning Blade”, or “Phoenix Fire” as separate named skills. The actual current entries are `PhoenixFlower`, `Chidori` / `ChidoriStream`, and `ShadowImitation` / `ShadowStrangle`, etc.

## Icon art rules

1. Create **exactly one different 512×512 transparent PNG per active Jutsu ID** listed above. Filename = ID, e.g., `ShadowClone.png`, `PhoenixFlower.png`, `Rasenshuriken.png`. All 28 must exist before marking the pack complete. No card backgrounds, no title text, no keybind letters or cooldown numbers baked into these PNGs.
2. A **pose is sign-dependent**, while visual technique is attack-dependent. E.g. **Ram + Shadow Clone** depicts the owner-approved Ram pose with clouds and clones, not a random Tiger pose; **Tiger + Fireball** uses the approved Tiger seal with a blazing fireball; **Bird + Rasenshuriken** uses approved Bird art with a bright spinning wind shuriken. **Horse + Rasengan** uses the Horse pose, not a generic open hand.
3. To preserve exact anatomy, composite the already-approved transparent `assets/icons/hand-signs-art` images, then add distinct original 2D VFX/attack graphics as separate layers; **do not regenerate the hand anatomy with an AI model**. VFX art should be bold and readable at Roblox button size (roughly 80–120 screen pixels).
4. ShadowClone/MultiShadowClone: visible smoke and 2 or 5 distinct ninja clone silhouettes. Fireball/PhoenixFlower: large or multiple bright flames. Rasengan/GiantRasengan: blue spinning chakra orb. Rasenshuriken: four-bladed glowing wind shuriken. Chidori/ChidoriStream/ChidoriSenbon/Kirin: unmistakably different forms of lightning. Substitution: smoke with log. BodyFlicker: afterimage and speed lines. SnakeHands/StrikingSnakes: purple striking snakes. WaterWall/WaterDragon: wave shield versus water-dragon head. Summoning: giant toad. EarthWall: earthen stone barricade. Susanoo: spectral armored guardian. Amaterasu: black-red fire. PlanetaryDevastation: gravity sphere and floating rocks. TailedBeastBomb: dark magenta chakra bomb. The remaining attacks have their distinct descriptions in `Config.Jutsu`.
5. **Advanced and Forbidden are defined in current Config, but neither has an approved hand pose on the user's new 12-seal sheet.** Do NOT fabricate an “Advanced” or “Forbidden” seal. You can create an attack-focused effect icon without hand art as a temporary placeholder, clearly identify these four as waiting for owner-approved pose art, or resolve only after owner approval. **Do not delete Config signs or saved progression to match the image count.**
6. Source sheet itself was supplied in the ChatGPT conversation. Use the **12 matching per-sign transparent PNGs already in GitHub** for the approved poses; the source layout can be used for audit, but only PNGs are for HUD use.
7. Update `Assets.JutsuIconsById` (or a new explicit config mapping) with ACTUAL uploaded Roblox asset IDs for all Jutsu IDs. Do not reuse the generic `Assets.JutsuIcon[vfx family]` for 28 different attacks. Never invent IDs. Make E/R HUD icons resolve from `Config.HandSigns[equipped].E/.R`; cooldown remains separate.
8. Verify against the latest Studio source/Claude notes. Submit a 28-icon contact sheet labeled OUTSIDE the individual icon images, visually inspect each icon for finger correctness and attack recognizability, then commit art, source and icon-to-ID mapping on a review branch. Do not publish game.

## Current work status

- **28 active Jutsu IDs verified in GitHub configuration**.
- Renovated hand-seal reference supplied by owner; 12 per-sign images available in repo under `assets/icons/hand-signs-art/`.
- The eight previously generated sample attack images in ChatGPT were NOT verified against this table; do NOT treat them as an approved complete pack.
- This matrix is a production **brief**, NOT a claim that new images are uploaded to Roblox or installed in-game.
