# +1 Anime Hand Signs

A Roblox anime-inspired hand-sign progression game. **This repository currently contains planning and AI collaboration documentation, not a playable Roblox game.**

## Game direction
- Train hand signs to earn power and unlock techniques.
- Progress through **50 stages** with distinct biome themes and increasingly difficult enemies, inspired by the clear, visible progression structure of +1 Anime Eyes.
- Each major power unlock includes a signature technique and **two additional abilities**, each with unique combat utility.
- Begin with a recognizable starter hand-sign power, then make upgrades feel visibly stronger.
- Prioritize compelling early gameplay, clear power feedback, responsive combat, and replay value.

See [docs/GAME_SPEC.md](docs/GAME_SPEC.md) for confirmed requirements versus open design choices.

## AI shared workplace
- **ChatGPT / director:** research, game design, task specifications, code reviews, balance feedback.
- **Claude Code / builder:** implement Luau and world changes through the existing Roblox Studio MCP connection; test in Studio; open pull requests.
- **GitHub:** durable task queue, code history, PR reviews, implementation reports.

Start with [docs/WORKFLOW.md](docs/WORKFLOW.md), [docs/ROADMAP.md](docs/ROADMAP.md), and the open issues. Claude should read [CLAUDE.md](CLAUDE.md) before changing anything.

## Current state
Planning workspace only. The existing Studio place has **not** been inspected or synced here. No gameplay has been implemented by this repository setup. **No fully unattended ChatGPT-to-Claude automation is running yet.**

## Safety
Back up the Roblox place before edits. Never commit API keys, Roblox cookies, credentials, or private account data. No direct changes to `main` for gameplay; use a branch and pull request.
