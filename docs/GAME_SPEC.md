# Game specification — +1 Anime Hand Signs

**Status:** Draft design document. Requirements labeled CONFIRMED come from the owner's prior direction; other details are proposals needing approval.

## CONFIRMED core concept
- Roblox progression game titled **+1 Anime Hand Signs**.
- Players begin with a starter hand-sign-based power and progressively unlock stronger techniques.
- Structure progression like the visible stages/biomes in **+1 Anime Eyes**, while making this game's combat and visual identity its own.
- **50 progression stages**; stage worlds/biomes and enemies escalate with progress.
- Major power unlocks should have a signature move plus **two additional attacks** (three usable abilities per power tier).
- Anime-inspired ninja hand signs, combat effects, progression, defeating enemies and unlocking stronger powers are central.

## First-play experience — PROPOSED
1. Spawn facing an obvious hand-sign training prompt and starter ability.
2. Training increments a clearly visible stat with immediate feedback.
3. A nearby enemy lets the player test their starter technique.
4. Defeating enemies earns stage progress and rewards; stage gates display clear requirements.
5. New tiers update hand-sign visuals, ability effects, and combat options (not just numerical damage).

## Design constraints
- Make the first 60 seconds understandable with minimal reading.
- Use readable, performant Roblox-style VFX, clear hit feedback and device-friendly controls.
- Provide keyboard/mouse, touch and controller access for core controls.
- Server-authoritative rewards/damage/unlocks; persistence with safe DataStore writes and migration handling.
- Stages should use data-driven configuration, not 50 unrelated scripts.
- Prefer original art, naming and effects where feasible; verify rights and Roblox policies before copying protected anime assets.

## NOT YET APPROVED / needs Studio inspection
Exact stats, upgrade prices, rebirths, premium products, enemy roster, stage names/biome order, power tier names, drop probabilities, unlock pacing, animations, and UI layout. References like Rasengan/Sharingan/Susanoo are inspiration only until a content decision is approved. No precise balance numbers should be treated as settled.

## Prototype acceptance target
Before constructing 50 stages, deliver one polished loop: train hand signs -> use starter ability -> defeat a server-controlled enemy -> earn rewards -> unlock a meaningful next tier -> persist progress. Expand to stages 1–5, validate player clarity and game feel, then scale to 50 using the proven template.
