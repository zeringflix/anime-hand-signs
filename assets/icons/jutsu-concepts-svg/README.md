# Exact-config 28 attack icon concepts — transparent SVG source art

This directory contains **28 unique transparent SVG illustrations**, one for each currently configured `Config.Jutsu` E/R ability. Unlike the earlier generic icon examples, each file is named after a REAL live-game attack ID from `scripts/ReplicatedStorage/Shared/Config.luau`.

**Finger accuracy:** The 24 icons attached to the twelve standard zodiac signs embed the original, unmodified, transparent `assets/icons/hand-signs-art/<Sign>.png` files already checked into this repository. They are composited with different vector effect layers to depict each actual attack; source hand pixels were not redrawn. The user supplied this renovated 12-sign style. Rat remains part of the CONFIGURED game's sign list even if a prior design sheet had excluded it.

**Important exceptions:** `Advanced` and `Forbidden` currently exist in Config and each has two real attacks, but the renovated sheet has no approved special-tier hand poses. Their four icons (Amaterasu, Susanoo, PlanetaryDevastation and TailedBeastBomb) are **effect-only drafts**. Do not fabricate hand poses or remove saved game tiers. Ask the owner to approve a special-tier pose before finalizing those four.

The art is **not yet Roblox-uploaded or installed**. SVG is vector source, not the finished Roblox PNG. To render all 28 to individual 512×512 RGBA PNGs, run:

```bash
python -m pip install cairosvg
python tools/render_jutsu_icons.py
```

Then QA every exported PNG at 128px and 64px display sizes; verify no cut-off fingers, complete transparency, visually distinct techniques, and correct `Config.Jutsu` mapping. Revise SVG art if necessary; have the owner approve before uploading through Roblox Asset Manager and setting actual asset IDs in `Assets.JutsuIconsById`. Never invent Roblox asset IDs. Keep the current `Assets.JutsuIcon` fallback until all actual uploads work.

Full authoritative mapping: `docs/reference/APPROVED_JUTSU_ICON_MATRIX.md`. Each image has **no text, no border, no background tile, no keybind and no cooldown**, because those belong to game UI.
