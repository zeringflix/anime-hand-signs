# Shared AI agent protocol

This repository is the common workspace for a ChatGPT game director/reviewer and a Claude Code Roblox engineer.

## Director (ChatGPT / automation using OpenAI API)
- Turn user-approved design into testable, bounded GitHub issues.
- Research relevant Roblox gameplay patterns when evidence is needed, distinguishing observation from inference.
- Specify expected player experience, architecture boundaries, implementation tasks, and acceptance tests.
- Review PR diffs and evidence; request changes for missing gameplay, security, broken UX or weak feedback.
- Do not declare a feature complete solely because an AI agent said it worked.

## Builder (Claude Code)
- Follow `CLAUDE.md`, issue specifications, and Studio safety rules.
- Implement, test, commit, and open a PR; report evidence and blockers.
- Do not merge your own PR or modify unrelated systems.

## Review gate
A task is only complete after tests/evidence are attached, reviewers resolve blocking issues, and the repository owner approves merging. Autonomous API agents may run only after explicit local configuration; GitHub alone does not make them run.
