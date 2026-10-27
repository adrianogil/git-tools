#!/usr/bin/env python3
"""Discover repositories without traversing their contents by default."""

import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import sys
import tempfile
import time


def is_repo(path):
    marker = Path(path) / ".git"
    return marker.is_dir() or marker.is_file()


def discover(root, recursive):
    pending = [root]
    repos = []
    complete = True
    while pending:
        directory = pending.pop()
        if is_repo(directory):
            repos.append(directory)
            if not recursive:
                continue
        try:
            with os.scandir(directory) as entries:
                pending.extend(
                    entry.path for entry in entries
                    if entry.name != ".git" and entry.is_dir(follow_symlinks=False)
                )
        except OSError as error:
            print(f"gt-repos: {error}", file=sys.stderr)
            complete = False
    return sorted(repos), complete


def cache_path(root, recursive):
    base = os.environ.get("GT_REPOS_CACHE_DIR")
    if not base:
        base = str(Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") / "git-tools" / "repos")
    key = hashlib.sha256(json.dumps([1, root, recursive]).encode()).hexdigest()
    return Path(base) / (key + ".json")


def read_cache(path, ttl, root):
    try:
        if not 0 <= time.time() - path.stat().st_mtime < ttl:
            return None
        repos = json.loads(path.read_text())
        if not isinstance(repos, list) or not all(
            isinstance(repo, str) and os.path.isabs(repo)
            and os.path.commonpath([root, repo]) == root for repo in repos
        ):
            return None
        return [repo for repo in repos if is_repo(repo)]
    except (OSError, ValueError):
        return None


def write_cache(path, repos):
    temporary = None
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as output:
            temporary = output.name
            json.dump(repos, output)
        os.replace(temporary, path)
    except OSError:
        # An unavailable cache must not prevent navigation.
        pass
    finally:
        if temporary:
            try:
                os.unlink(temporary)
            except OSError:
                pass


def main():
    parser = argparse.ArgumentParser(
        prog="gt-repos / cdr",
        description="Find repositories below the current directory (including itself). Requires Python 3.",
        epilog="Cache lifetime: GT_REPOS_CACHE_TTL seconds (default 300; 0 disables caching). "
        "Location: GT_REPOS_CACHE_DIR or $XDG_CACHE_HOME/git-tools/repos (default ~/.cache/git-tools/repos).",
    )
    parser.add_argument("-r", "--recursive", action="store_true", help="also search inside repositories for nested repos and submodules")
    parser.add_argument("--refresh", action="store_true", help="rebuild the cache for this directory and mode")
    parser.add_argument("--no-cache", action="store_true", help="scan without reading or writing the cache")
    args = parser.parse_args()
    try:
        ttl = float(os.environ.get("GT_REPOS_CACHE_TTL", "300"))
        if not math.isfinite(ttl) or ttl < 0:
            raise ValueError
    except ValueError:
        parser.error("GT_REPOS_CACHE_TTL must be a finite, nonnegative number")

    root = os.getcwd()
    path = cache_path(root, args.recursive)
    use_cache = not args.no_cache and ttl > 0
    repos = read_cache(path, ttl, root) if use_cache and not args.refresh else None
    complete = True
    if repos is None:
        repos, complete = discover(root, args.recursive)
        if use_cache and complete:
            write_cache(path, repos)
    for repo in repos:
        print(repo)
    return 0 if complete else 1


if __name__ == "__main__":
    sys.exit(main())
