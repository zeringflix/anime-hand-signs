# Studio inspection and safe playtest evidence

Inspection date: November 1, 2026 (America/Chicago). Place: `72288975594385`. Related context: [issue #2](https://github.com/zeringflix/anime-hand-signs/issues/2); this package does not close its backup/sync requirements.

- [Ranked findings and improvement plan](inspection-and-improvement-plan.md)
- [All 69 screenshots](screenshots/) and [GitHub screenshot index](screenshots.md)
- [Interactive gallery](gallery.html) — download this directory and open the HTML locally; GitHub displays HTML as source.
- [Playtest console output](playtest-console.txt)
- [19 captured Studio source files](source-snapshot/)
- [Source and inventory archive](studio-audit-snapshot.zip)
- [Integrity manifest](manifest.json)

## Code change status
No game code was edited during this audit. `source-snapshot/` contains read-only copies of existing Studio scripts for evidence; it is not a patch, a synced source root, or a full place backup. Existing repository `scripts/` remain unchanged. Five of the nine comparable scripts differed at inspection time; ten Studio source containers were absent from the prior repository export. Do not import either snapshot over the live place without resolving sync and backup first.

## Verified coverage and limits
50 stage overviews, 11 menus, fresh desktop play, basic Tiger combat, training/free-auto failures, daily reward, pet hatch/equip, locked requests, and simulated phone layouts. Progression failed with `GameService:178: attempt to compare nil <= number`; full clears, later abilities, final boss phases, persistence, purchases, multiplayer, controller, and physical-device performance remain unverified.

Studio API access was disabled and saved by the owner before play; Output confirmed an unsaved temporary profile. Play was stopped and the default viewport/orientation restored. No game assets were modified or deleted, no builders ran, and no place was published.
