#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from typing import Dict, List

try:
    # Your existing helper
    from gittools.history.log import get_hash_log  # type: ignore
except Exception:
    # Lightweight fallback using git if the helper is unavailable
    # Requires: git installed and cwd inside a repo
    import subprocess

    def get_hash_log(refs: List[str]) -> List[str]:
        # Use --first-parent to mirror many branch histories more intuitively.
        # Drop it if you want full DAG traversal.
        cmd = ["git", "rev-list", "--first-parent"] + refs
        out = subprocess.check_output(cmd, text=True)
        return [line.strip() for line in out.splitlines() if line.strip()]


def compute_commits_diff(ref1: str, ref2: str) -> Dict[str, List[str]]:
    """
    Return commits that are present in one ref and not in the other.
    The lists preserve the original order from get_hash_log(ref).
    """
    hashes_ref1 = get_hash_log([ref1])
    hashes_ref2 = get_hash_log([ref2])

    set_ref1 = set(hashes_ref1)
    set_ref2 = set(hashes_ref2)

    only_in_ref1 = [h for h in hashes_ref1 if h not in set_ref2]
    only_in_ref2 = [h for h in hashes_ref2 if h not in set_ref1]

    return {
        "ref1": ref1,
        "ref2": ref2,
        "only_in_ref1": only_in_ref1,  # present in ref1, missing from ref2
        "only_in_ref2": only_in_ref2,  # present in ref2, missing from ref1
    }


def print_commits_diff(
    diff: Dict[str, List[str]],
    count_only: bool = False,
    limit: int | None = None,
) -> None:
    ref1 = diff["ref1"]
    ref2 = diff["ref2"]
    only_in_ref1 = diff["only_in_ref1"]
    only_in_ref2 = diff["only_in_ref2"]

    def _maybe_limit(items: List[str]) -> List[str]:
        return items if limit is None else items[: max(0, limit)]

    print(f"Diff between {ref1} and {ref2}")
    print(
        f"Present in {ref1} but not in {ref2} "
        f"({len(only_in_ref1)} commits)"
    )
    if not count_only:
        for h in _maybe_limit(only_in_ref1):
            print(h)

    print(
        f"Present in {ref2} but not in {ref1} "
        f"({len(only_in_ref2)} commits)"
    )
    if not count_only:
        for h in _maybe_limit(only_in_ref2):
            print(h)


def parse_args(argv: List[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Show commit hashes that differ between two refs."
    )
    p.add_argument("ref1", help="First ref, branch, tag, or commit")
    p.add_argument("ref2", help="Second ref, branch, tag, or commit")
    p.add_argument(
        "-j",
        "--json",
        action="store_true",
        help="Output JSON with only_in_ref1 and only_in_ref2",
    )
    p.add_argument(
        "-c",
        "--count-only",
        action="store_true",
        help="Only print counts, not hashes",
    )
    p.add_argument(
        "-n",
        "--limit",
        type=int,
        default=None,
        help="Limit how many hashes to print from each side",
    )
    p.add_argument(
        "--fail-on-diff",
        action="store_true",
        help="Exit with code 2 if differences exist",
    )
    return p.parse_args(argv)


def main(argv: List[str]) -> int:
    args = parse_args(argv)
    try:
        diff = compute_commits_diff(args.ref1, args.ref2)
    except Exception as e:
        print(f"error: {e}", file=sys.stderr)
        return 1

    if args.json:
        payload = {
            "ref1": diff["ref1"],
            "ref2": diff["ref2"],
            "only_in_ref1": diff["only_in_ref1"],
            "only_in_ref2": diff["only_in_ref2"],
            "counts": {
                "only_in_ref1": len(diff["only_in_ref1"]),
                "only_in_ref2": len(diff["only_in_ref2"]),
            },
        }
        print(json.dumps(payload, indent=2))
    else:
        print_commits_diff(diff, count_only=args.count_only, limit=args.limit)

    has_diff = bool(diff["only_in_ref1"] or diff["only_in_ref2"])
    if args.fail_on_diff and has_diff:
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
