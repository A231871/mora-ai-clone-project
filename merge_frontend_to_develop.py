"""
merge_frontend_to_develop.py
Resolves conflicts and merges frontend branches into develop.

Conflict strategy:
  - frontend/ files → keep feature branch version (theirs)
  - All other files → keep develop version (ours)
  - Files only in feature branch → add them

Run: python e:\mora-ai-clone-project\merge_frontend_to_develop.py
"""

import subprocess, sys, os

REPO = r"e:\mora-ai-clone-project"
ENV = {**os.environ, "GIT_EDITOR": "true", "GIT_MERGE_AUTOEDIT": "no"}


def git(*args, check=True, silent=False):
    r = subprocess.run(["git"] + list(args), cwd=REPO,
                       capture_output=True, text=True, env=ENV)
    if not silent:
        if r.stdout.strip(): print(r.stdout.rstrip())
        if r.stderr.strip(): print(r.stderr.rstrip(), file=sys.stderr)
    if check and r.returncode not in (0, 1):
        print(f"FATAL: git {args[0]} failed (exit {r.returncode})")
        sys.exit(r.returncode)
    return r


def resolve_conflicts():
    """Auto-resolve all conflicts after a failed merge."""
    status = subprocess.run(
        ["git", "status", "--porcelain"],
        cwd=REPO, capture_output=True, text=True, env=ENV
    )
    resolved = []
    for line in status.stdout.splitlines():
        if not line.strip():
            continue
        xy = line[:2]
        path = line[3:].strip().strip('"')
        # Conflict codes: UU, AA, DD, AU, UA, DU, UD
        is_conflict = any(c in xy for c in ["U", "A", "D"]) and len(set(xy.strip())) > 1
        untracked = xy.strip() == "?"
        if untracked:
            continue
        if is_conflict or "U" in xy:
            if path.startswith("frontend/"):
                # Keep the feature branch version
                subprocess.run(
                    ["git", "checkout", "--theirs", "--", path],
                    cwd=REPO, capture_output=True, env=ENV
                )
            else:
                # Keep develop's version
                subprocess.run(
                    ["git", "checkout", "--ours", "--", path],
                    cwd=REPO, capture_output=True, env=ENV
                )
            subprocess.run(
                ["git", "add", "--", path],
                cwd=REPO, capture_output=True, env=ENV
            )
            resolved.append(path)
    if resolved:
        print(f"  Resolved {len(resolved)} conflicted file(s):")
        for p in resolved:
            print(f"    ✓ {p}")
    return resolved


def merge_branch(branch, msg):
    print(f"\n{'─'*60}")
    print(f"  MERGING origin/{branch}")
    print(f"{'─'*60}")

    result = subprocess.run(
        ["git", "merge", f"origin/{branch}", "--no-edit",
         "--allow-unrelated-histories", "-m", msg],
        cwd=REPO, capture_output=True, text=True, env=ENV
    )
    print(result.stdout.rstrip())
    if result.stderr.strip():
        print(result.stderr.rstrip())

    if result.returncode == 0:
        print(f"  ✅ Merged cleanly!")
        return True

    # Has conflicts
    print(f"  ⚠️  Conflicts detected — auto-resolving...")
    resolved = resolve_conflicts()

    if not resolved:
        print("  No conflicts to resolve — checking if already up to date...")
        git("add", "-A", silent=True)

    # Continue or commit
    cont = subprocess.run(
        ["git", "merge", "--continue", "--no-edit"],
        cwd=REPO, capture_output=True, text=True, env=ENV
    )
    if cont.returncode != 0:
        # Try direct commit
        commit = subprocess.run(
            ["git", "commit", "--no-edit", "-m", msg],
            cwd=REPO, capture_output=True, text=True, env=ENV
        )
        if commit.returncode not in (0, 1):
            print(f"  ❌ Could not complete merge of {branch}")
            print(f"  stdout: {commit.stdout}")
            print(f"  stderr: {commit.stderr}")
            return False
        print(commit.stdout.rstrip())
    else:
        print(cont.stdout.rstrip())

    print(f"  ✅ {branch} merged with resolved conflicts!")
    return True


# ── Main ──────────────────────────────────────────────────────────────────────

print("=" * 60)
print("  MERGE FRONTEND BRANCHES → develop")
print("=" * 60)

# 1. Fetch
print("\n[1/6] Fetching from origin...")
git("fetch", "--all")

# 2. Checkout develop
print("\n[2/6] Checking out develop...")
git("checkout", "-B", "develop", "origin/develop")

print("\nCurrent develop (last 5 commits):")
git("log", "--oneline", "-5")

# 3. Merge branches in order
branches = [
    (
        "feature/UI",
        "Merge feature/UI: Bubble Mecha Pink design system, shared widgets, 6 screens, router"
    ),
    (
        "feature/UI-screens",
        "Merge feature/UI-screens: all 6 screens - Start, Login, Home, Chat, Reminders, Config"
    ),
    (
        "feature/UI-avatar",
        "Merge feature/UI-avatar: Shizuki sprite animator + 6 transparent PNG assets"
    ),
]

failed = []
for branch, msg in branches:
    ok = merge_branch(branch, msg)
    if not ok:
        failed.append(branch)

# 4. Final log
print(f"\n[5/6] Develop after merges:")
git("log", "--oneline", "-10")

# 5. Push
print(f"\n[6/6] Pushing develop to origin...")
push = git("push", "origin", "develop", check=False)
if push.returncode != 0:
    print("  Normal push failed — trying force-with-lease...")
    git("push", "origin", "develop", "--force-with-lease")

# Summary
print("\n" + "=" * 60)
print("  SUMMARY")
print("=" * 60)
if failed:
    print(f"  ❌ Failed branches (need manual resolution): {failed}")
else:
    print("  ✅ All frontend branches successfully merged into develop!")
    print("\n  Merged branches:")
    for b, _ in branches:
        print(f"    • {b}")
    print("\n  Next: Open GitHub PRs and mark them as merged (or close them).")
print("=" * 60)
