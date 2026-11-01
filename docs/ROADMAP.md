# Development roadmap

All stages below are *planned*, not implemented. Use GitHub Issues for actual task assignments.

## 0. Inspect and safeguard — highest priority
- Inspect existing Studio place, script hierarchy and errors with Roblox Studio MCP.
- Back up place; establish explicit script synchronization to this repository.
- Document existing features and avoid overwriting them.

## 1. Minimum viable progression loop
- Hand-sign training interaction and visible power counter.
- Server-authoritative player stats and basic HUD.
- Starter jutsu with cast feedback, cooldown and reliable hits.
- One enemy with health, damage, reward and respawn.
- One stage gate and progress persistence.

## 2. Ability and combat foundations
- Data-driven power tiers; signature ability plus two supporting skills.
- Server validation for all combat/remotes, cooldown state, and anti-exploit checks.
- Ability visuals/audio, input mapping (PC/mobile/controller), enemy telegraphs and responsive damage feedback.

## 3. Stage framework and first five worlds
- Data-driven stage templates, biome transitions, enemies and unlock requirements.
- Build five polished stages and conduct playtests for difficulty, pacing and readability.
- Performance profiling on lower-end devices.

## 4. Complete 50-stage progression
- Populate all 50 from the tested templates, with escalating enemies and distinctive visuals.
- Verify gates, spawns, currencies, unlocks, checkpoints and persistence across the entire route.

## 5. Polish and release readiness
- Tutorial, onboarding, progression pacing, accessibility, audio/VFX, UI polish.
- Security review, saving failure tests, multiplayer tests, performance checks.
- Monetization only after owner approves ethics, prices and functionality.
- Publish only with explicit owner approval.

### Definition of done
Every implemented task needs a reproducible Studio test, no known blocking console errors, proof of feature behavior, code review and owner approval. See `docs/TEST_PLAN.md`.
