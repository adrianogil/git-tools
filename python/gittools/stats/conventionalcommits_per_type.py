#!/usr/bin/env python3
"""
commit_kind_usage.py

Count usage of Conventional Commit kinds (feat, fix) plus merge commits.
Understands subjects like:
  JIRAKEY-1234 feat(user): ...
  JIRAKEY-1234 (feat): ...
  JIRAKEY-1234 fix(package-lock): ...
Counts merges via topology (--merges), independent of the subject.

Usage:
  python3 -m gittools.stats.conventionalcommits_per_type                 # uses HEAD
  python3 -m gittools.stats.conventionalcommits_per_type v1.2.0..HEAD    # any rev-range/ref
  python3 -m gittools.stats.conventionalcommits_per_type main
"""
import argparse
import json
import re
import shutil
import subprocess
import sys
from typing import Dict, List, Tuple

# ---------- Git helpers ----------

def run_git(args: List[str]) -> str:
    r = subprocess.run(
        ["git"] + args, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
    )
    if r.returncode != 0:
        raise RuntimeError(f"git {' '.join(args)} failed: {r.stderr.strip()}")
    return r.stdout

def ensure_git_repo() -> None:
    try:
        if run_git(["rev-parse", "--is-inside-work-tree"]).strip() != "true":
            raise SystemExit("Error: not a Git repository.")
    except RuntimeError as e:
        raise SystemExit(f"Error: {e}")

# ---------- Counting ----------

def build_kind_regex(kinds: List[str]) -> re.Pattern:
    """
    Match either:
      - feat(scope)!:
      - (feat)!:
      - feat!:
    anywhere in the subject (case-insensitive).
    """
    alt = "|".join(map(re.escape, kinds))
    pattern = rf"""
        (?:                             # either wrapped or bare type
            \(\s*(?P<k1>{alt})\s*\)     # (feat) or (fix) or (chore)
          | (?P<k2>{alt})               # feat   or fix   or chore
        )
        (?:\s*\([^)]*\))?               # optional scope: (scope)
        \s*!?\s*                        # optional breaking-change bang
        :                               # colon terminator
    """
    return re.compile(pattern, re.IGNORECASE | re.VERBOSE)

def count_totals(rev: str, extra: List[str]) -> Tuple[int, int]:
    """Return (all_commits, merge_commits)."""
    all_c = int(run_git(["rev-list", "--count", *extra, rev]).strip() or "0")
    merges = int(run_git(["rev-list", "--count", "--merges", *extra, rev]).strip() or "0")
    return all_c, merges

def count_kinds(rev: str, extra: List[str], kinds: List[str]) -> Dict[str, int]:
    pat = build_kind_regex(kinds)
    out = run_git(["log", "--no-merges", "--format=%s", *extra, rev])
    counts = {k: 0 for k in kinds}
    for s in out.splitlines():
        m = pat.search(s)
        if not m:
            continue
        found = (m.group("k1") or m.group("k2")).lower()
        # normalize to the canonical key casing in counts
        for key in counts:
            if key.lower() == found:
                counts[key] += 1
                break
    return counts

# ---------- Output ----------

def pct(n: int, denom: int) -> str:
    return "0.0%" if denom == 0 else f"{(n * 100.0) / denom:.1f}%"

def print_table(rev: str, kinds: List[str], counts: Dict[str, int],
                merges: int, total_all: int, denom_mode: str):
    non_merge_total = total_all - merges
    denom = total_all if denom_mode == "all" else non_merge_total

    print("### Conventional commit kind usage ###")
    print(f"Rev: {rev}")
    print(f"Denominator: {denom_mode} ({denom} commits)")
    print(f"{'kind':<10} {'count':>8} {'share':>8}")
    for k in kinds:
        c = counts.get(k, 0)
        print(f"{k:<10} {c:>8} {pct(c, denom):>8}")
    print(f"{'merge':<10} {merges:>8} {pct(merges, denom):>8}")
    print(f"{'total(all)':<10} {total_all:>8}")
    print(f"{'total(!merge)':<10} {non_merge_total:>8}")

# ---------- CLI ----------

def parse_args(argv: List[str]):
    parser = argparse.ArgumentParser(
        description="Count usage of Conventional Commit kinds plus merges."
    )
    parser.add_argument(
        "rev",
        nargs="?",
        default="HEAD",
        help="Git rev/ref or rev-range (default: HEAD)",
    )
    parser.add_argument(
        "--kinds",
        default="feat,fix,chore",
        help="Comma-separated kinds to count (default: feat,fix,chore)",
    )
    parser.add_argument(
        "--denom",
        choices=["all", "non-merge"],
        default="all",
        help="Denominator for percentages (default: all)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output JSON instead of a table",
    )
    # Parse known args; anything after '--' (or unknown) is forwarded to git
    args, extra = parser.parse_known_args(argv[1:])
    kinds = [k.strip() for k in args.kinds.split(",") if k.strip()]
    return args, kinds, extra

def main(argv: List[str]):
    if shutil.which("git") is None:
        raise SystemExit("Error: git not found in PATH.")
    ensure_git_repo()

    args, kinds, extra = parse_args(argv)

    try:
        total_all, merges = count_totals(args.rev, extra)
        counts = count_kinds(args.rev, extra, kinds)
    except RuntimeError as e:
        raise SystemExit(f"Error: {e}")

    if args.json:
        non_merge_total = total_all - merges
        denom = total_all if args.denom == "all" else non_merge_total
        payload = {
            "rev": args.rev,
            "kinds": kinds,
            "counts": counts,
            "merges": merges,
            "total_all": total_all,
            "total_non_merge": non_merge_total,
            "denominator_mode": args.denom,
            "denominator_value": denom,
        }
        print(json.dumps(payload, indent=2))
    else:
        print_table(args.rev, kinds, counts, merges, total_all, args.denom)

if __name__ == "__main__":
    main(sys.argv)
