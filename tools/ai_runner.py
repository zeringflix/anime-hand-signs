"""Owner-operated GitHub issue -> Claude Code -> draft PR -> OpenAI review runner.

This process runs only on the owner's Windows PC. It is deliberately NOT a
GitHub-hosted action, because Roblox Studio MCP is local to that machine.
No secrets are loaded from the repository; no branches are auto-merged.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

REPO = "zeringflix/anime-hand-signs"
OWNER = "zeringflix"
ROOT = Path(__file__).resolve().parents[1]
MODEL = os.getenv("OPENAI_MODEL", "gpt-5.5")
ALLOWED_ROOTS = (
    "src/", "game/", "scripts/", "docs/", "tests/",
    "ServerScriptService/", "ReplicatedStorage/", "StarterGui/", "StarterPlayer/",
)
ALLOWED_FILES = {"README.md", "default.project.json"}
BLOCKED_SEGMENTS = {".git", ".github", "tools", "node_modules", "vendor", ".venv"}
BLOCKED_NAMES = {".env", ".env.local", ".env.production", "credentials.json", "secrets.json", "id_rsa", "id_ed25519"}
MAX_DIFF_CHARS = 60_000


def invoke(args: list[str], *, check: bool = True, timeout: int = 180, cwd: Path = ROOT) -> subprocess.CompletedProcess[str]:
    command = subprocess.run(args, cwd=str(cwd), text=True, encoding="utf-8", errors="replace", capture_output=True, timeout=timeout)
    if check and command.returncode:
        safe_detail = (command.stderr or command.stdout).strip()[-1800:]
        raise RuntimeError(f"Command failed: {args[0]} {args[1] if len(args)>1 else ''}: {safe_detail}")
    return command


def gh_json(args: list[str]):
    return json.loads(invoke(["gh", *args]).stdout)


def validate_path(path: str) -> bool:
    path = path.replace("\\", "/")
    parts = path.split("/")
    if path.startswith("/") or ".." in parts or any(p in BLOCKED_SEGMENTS for p in parts):
        return False
    if any(p.lower() in BLOCKED_NAMES for p in parts):
        return False
    if any(token in path.lower() for token in ("private_key", "api_key", "auth_token", "password")):
        return False
    return path in ALLOWED_FILES or path.startswith(ALLOWED_ROOTS)


def changed_files() -> list[str]:
    """Collect tracked edits and untracked files; reject anything outside safe scope."""
    tracked = invoke(["git", "diff", "--name-only", "HEAD"]).stdout.splitlines()
    untracked = invoke(["git", "ls-files", "--others", "--exclude-standard"]).stdout.splitlines()
    files = sorted(set(tracked + untracked))
    forbidden = [name for name in files if not validate_path(name)]
    if forbidden:
        raise RuntimeError("Unexpected changed paths; requires manual review: " + ", ".join(forbidden[:12]))
    return files


def preflight(check_secrets: bool) -> None:
    for tool in ("git", "gh", "claude"):
        if shutil.which(tool) is None:
            raise RuntimeError(f"{tool} executable not found in PATH")
    invoke(["git", "--version"])
    invoke(["gh", "auth", "status"])
    invoke(["claude", "--version"])
    origin = invoke(["git", "remote", "get-url", "origin"]).stdout.strip().lower()
    if "github.com/zeringflix/anime-hand-signs" not in origin and "github.com:zeringflix/anime-hand-signs" not in origin:
        raise RuntimeError("Expected the zeringflix/anime-hand-signs clone. Check git remote -v.")
    if check_secrets:
        if not os.getenv("OPENAI_API_KEY"):
            raise RuntimeError("OPENAI_API_KEY not set. Set it locally, never commit it to Git.")
        if os.getenv("ROBLOX_BACKUP_CONFIRMED") != "YES":
            raise RuntimeError("Back up the Roblox place, then set ROBLOX_BACKUP_CONFIRMED=YES in this terminal.")
    print("Preflight OK. GitHub, Git, Claude Code and repository were found.")
    print("OpenAI key:", "set" if os.getenv("OPENAI_API_KEY") else "not set")
    print("Studio backup confirmation:", "YES" if os.getenv("ROBLOX_BACKUP_CONFIRMED") == "YES" else "not confirmed")


def prepare_branch(number: int) -> str:
    if invoke(["git", "status", "--porcelain"]).stdout.strip():
        raise RuntimeError("Working directory has uncommitted changes; stop and inspect them first.")
    invoke(["git", "switch", "main"])
    invoke(["git", "pull", "--ff-only", "origin", "main"])
    branch = f"ai/issue-{number}"
    if invoke(["git", "branch", "--list", branch]).stdout.strip():
        raise RuntimeError(f"Local branch {branch} exists. Inspect before retrying.")
    if invoke(["git", "ls-remote", "--heads", "origin", branch]).stdout.strip():
        raise RuntimeError(f"Remote branch {branch} already exists. Inspect before retrying.")
    invoke(["git", "switch", "-c", branch])
    return branch


def call_claude(prompt: str) -> str:
    # acceptEdits can edit permitted files; no dangerously-skip-permissions.
    result = invoke([
        "claude", "-p", prompt, "--output-format", "json",
        "--max-turns", "24", "--permission-mode", "acceptEdits",
    ], timeout=3600)
    raw = result.stdout
    try:
        data = json.loads(raw)
        if data.get("is_error"):
            raise RuntimeError("Claude returned an error: " + str(data.get("result", "unknown"))[-500:])
        return str(data.get("result", raw))
    except json.JSONDecodeError:
        return raw


def save_changes(number: int, amendment: bool = False) -> bool:
    names = changed_files()
    if not names:
        return False
    invoke(["git", "add", "-A", "--", *names])
    if not invoke(["git", "diff", "--cached", "--name-only"]).stdout.strip():
        return False
    message = f"AI implementation: issue #{number}" + (" (review corrections)" if amendment else "")
    invoke(["git", "-c", "user.name=Roblox AI Runner", "-c", "user.email=roblox-ai-runner@users.noreply.github.com", "commit", "-m", message])
    invoke(["git", "push", "--set-upstream", "origin", "HEAD"], timeout=300)
    return True


def create_pr(number: int, title: str, summary: str) -> int:
    body = (
        f"Relates to #{number}\n\n## Claude implementation summary\n"
        + summary[:8500]
        + "\n\n## Evidence requirement\n"
        + "This PR is a DRAFT. Owner must inspect actual Studio playtesting, runtime errors, and screenshots. "
        + "Code review alone does not verify the game. No auto-merge or publication is permitted.\n"
    )
    invoke(["gh", "pr", "create", "-R", REPO, "--draft", "--head", f"ai/issue-{number}", "--base", "main", "--title", f"[AI] #{number} {title}"[:230], "--body", body])
    prs = gh_json(["pr", "list", "-R", REPO, "--head", f"ai/issue-{number}", "--state", "open", "--json", "number", "--limit", "5"])
    if not prs:
        raise RuntimeError("PR creation apparently succeeded but PR could not be found.")
    return int(prs[0]["number"])


def parse_review(text: str) -> dict:
    try:
        # Handle optional Markdown fences.
        clean = text.strip()
        if clean.startswith("```"):
            clean = "\n".join(clean.splitlines()[1:-1]).strip()
        response = json.loads(clean)
    except json.JSONDecodeError as exc:
        raise RuntimeError("OpenAI review was not valid JSON; stopping for human inspection") from exc
    if response.get("decision") not in ("PASS_WITH_CAVEATS", "CHANGES_REQUESTED"):
        raise RuntimeError("Unknown OpenAI review decision")
    if not isinstance(response.get("feedback"), str):
        raise RuntimeError("OpenAI review missing feedback")
    return response


def review(pr_number: int, issue: dict) -> dict:
    from openai import OpenAI
    diff = invoke(["gh", "pr", "diff", str(pr_number), "-R", REPO, "--color", "never"], timeout=120).stdout
    truncated = len(diff) > MAX_DIFF_CHARS
    if truncated:
        diff = diff[:MAX_DIFF_CHARS] + "\n[TRUNCATED: additional diff excluded]"
    response = OpenAI().responses.create(
        model=MODEL,
        instructions=(
            "You are an exacting Roblox Luau code reviewer, not the Roblox Studio runtime. "
            "Check correctness, remote-event trust boundaries, DataStore safety, combat rules, "
            "acceptance criteria, regression risk, and code-test evidence. "
            "Distinguish proven failures from uncertainties. If the diff is truncated, request human review. "
            "Do not certify actual Studio behavior unless credible playtest evidence is supplied. "
            "Return ONLY JSON: {\"decision\":\"PASS_WITH_CAVEATS\" or \"CHANGES_REQUESTED\",\"feedback\":\"concrete review with file paths and reproducible tests\"}. "
            "No markdown fences, no code execution instructions outside the review."
        ),
        input=(
            f"GitHub issue #{issue['number']}: {issue['title']}\n{issue['body'][:14000]}\n"
            f"PR #{pr_number} diff:\n{diff}"
        ),
        max_output_tokens=1600,
    )
    result = parse_review(response.output_text)
    header = f"### Automated OpenAI code review ({MODEL})\n\nDecision: **{result['decision']}**\n\n"
    footer = "\n\n_This is code/diff review, not independent verification in Roblox Studio._"
    invoke(["gh", "pr", "comment", str(pr_number), "-R", REPO, "--body", header + result["feedback"][:16000] + footer])
    return result


def label_issue(number: int, add: str, remove: str | None = None) -> None:
    args = ["gh", "issue", "edit", str(number), "-R", REPO, "--add-label", add]
    if remove:
        args.extend(["--remove-label", remove])
    invoke(args)


def process_one() -> bool:
    issues = gh_json(["issue", "list", "-R", REPO, "--state", "open", "--label", "ai-ready", "--json", "number,title,body,author", "--limit", "30"])
    issues = [i for i in issues if i.get("author", {}).get("login", "").lower() == OWNER]
    if not issues:
        print("No owner-authored issues labeled ai-ready. Nothing to do.")
        return False
    issue = sorted(issues, key=lambda i: i["number"])[0]
    number = int(issue["number"])
    label_issue(number, "ai-running", "ai-ready")
    pr_number = None
    try:
        prepare_branch(number)
        prompt = (
            "You are the Roblox Studio developer for +1 Anime Hand Signs. Read CLAUDE.md, "
            "AGENTS.md, docs/GAME_SPEC.md, docs/WORKFLOW.md, and docs/TEST_PLAN.md. "
            "Use your already configured Roblox Studio MCP and verify current place and backup. "
            "No deleting/rebuilding existing worlds; no publishing; no purchases. "
            "Make only scoped changes requested in the GitHub issue. "
            "Before code changes, inspect current Studio state and confirm that script sync/export is functional. "
            "If Studio is disconnected or sync cannot be established safely, STOP without edits and report blocker. "
            "Test work inside Studio and report exact steps and Output errors; do not invent tests. "
            "Do not open or merge PRs yourself, this runner handles GitHub. "
            f"\n\nIssue #{number}: {issue['title']}\n{issue['body'][:15000]}"
        )
        report = call_claude(prompt)
        if not save_changes(number):
            invoke(["gh", "issue", "comment", str(number), "-R", REPO, "--body", "Automation: Claude ran but produced no safely stageable repository changes. Check Studio sync and logs before rerunning. Summary:\n\n" + report[:6000]])
            label_issue(number, "ai-needs-attention", "ai-running")
            return True
        pr_number = create_pr(number, issue["title"], report)
        for attempt in range(2):
            feedback = review(pr_number, issue)
            if feedback["decision"] == "PASS_WITH_CAVEATS":
                break
            if attempt == 1:
                break
            correction = (
                f"Address these review findings in draft PR #{pr_number} for issue #{number}. "
                "Read CLAUDE.md. Do not change unrelated files or publish. "
                "Verify fixes in Roblox Studio and report true test evidence. "
                "Do not open or merge a PR; runner will commit/push.\n\n"
                + feedback["feedback"]
            )
            fix_report = call_claude(correction)
            if not save_changes(number, amendment=True):
                invoke(["gh", "pr", "comment", str(pr_number), "-R", REPO, "--body", "Claude attempted review corrections but no safe repository changes were detected. Summary:\n\n" + fix_report[:5000]])
                break
        label_issue(number, "ai-review-ready", "ai-running")
        invoke(["gh", "issue", "comment", str(number), "-R", REPO, "--body", f"Automation created draft PR #{pr_number} and posted OpenAI code review. Owner review and actual Studio testing still required."])
        print(f"Draft PR #{pr_number} created. Manual owner review required.")
        return True
    except Exception as exc:
        label_issue(number, "ai-needs-attention", "ai-running")
        message = str(exc)[:2500]
        invoke(["gh", "issue", "comment", str(number), "-R", REPO, "--body", "Automation stopped safely; review needed. Error:\n\n" + message], check=False)
        print(f"Issue #{number}: failed safely: {message}", file=sys.stderr)
        return True


def setup_labels() -> None:
    definitions = {
        "ai-ready": ("0969da", "Owner-approved task available for local Claude runner"),
        "ai-running": ("c2e0c6", "Local runner currently executing task"),
        "ai-review-ready": ("7057ff", "Draft PR and AI review ready for owner inspection"),
        "ai-needs-attention": ("d73a4a", "Automation stopped and requires human intervention"),
    }
    for name, (color, description) in definitions.items():
        invoke(["gh", "label", "create", name, "-R", REPO, "--color", color, "--description", description, "--force"])
    print("GitHub automation labels prepared. No issues have been queued.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument("--check", action="store_true", help="Check tool availability without making changes")
    action.add_argument("--setup-labels", action="store_true", help="Create queue/status labels on GitHub")
    action.add_argument("--list", action="store_true", help="List queued tasks without making changes")
    action.add_argument("--once", action="store_true", help="Process one owner-approved issue")
    action.add_argument("--watch", action="store_true", help="Watch for approved issues while console remains open")
    args = parser.parse_args()
    os.chdir(ROOT)
    try:
        preflight(check_secrets=args.once or args.watch)
        if args.check:
            return
        if args.setup_labels:
            setup_labels()
            return
        if args.list:
            print(json.dumps(gh_json(["issue", "list", "-R", REPO, "--label", "ai-ready", "--json", "number,title,author"]), indent=2))
            return
        if args.once:
            process_one()
            return
        print("Runner active. Ctrl+C stops. It only processes owner-authored issues labeled ai-ready.")
        while True:
            process_one()
            time.sleep(90)
    except KeyboardInterrupt:
        print("Runner stopped by owner.")
    except Exception as exc:
        print(f"Runner setup failed: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
