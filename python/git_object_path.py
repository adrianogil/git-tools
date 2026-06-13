#!/usr/bin/env python3
"""Show where Git would store the current blob for a tracked file."""

from __future__ import annotations

import argparse
import hashlib
import subprocess
import sys
from pathlib import Path


def run_git(args: list[str], cwd: Path) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=str(cwd),
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    return result.stdout.strip()


def fail(message: str) -> int:
    print(f"gt-file-object-path: {message}", file=sys.stderr)
    return 1


def find_repo(cwd: Path) -> tuple[Path, Path, str]:
    try:
        root = Path(run_git(["rev-parse", "--show-toplevel"], cwd)).resolve()
        git_dir = Path(run_git(["rev-parse", "--absolute-git-dir"], cwd)).resolve()
    except subprocess.CalledProcessError:
        raise RuntimeError("not inside a Git worktree")

    try:
        object_format = run_git(["rev-parse", "--show-object-format"], cwd)
    except subprocess.CalledProcessError:
        object_format = "sha1"

    return root, git_dir, object_format


def resolve_target(raw_path: str, cwd: Path, repo_root: Path) -> Path:
    candidate = Path(raw_path).expanduser()
    if candidate.is_absolute():
        return candidate.resolve()

    cwd_candidate = (cwd / candidate).resolve()
    if cwd_candidate.exists():
        return cwd_candidate

    return (repo_root / candidate).resolve()


def relative_to_repo(path: Path, repo_root: Path) -> Path:
    try:
        return path.relative_to(repo_root)
    except ValueError:
        raise RuntimeError(f"{path} is outside repository {repo_root}")


def ensure_tracked(repo_root: Path, repo_path: Path) -> None:
    try:
        run_git(["ls-files", "--error-unmatch", "--", repo_path.as_posix()], repo_root)
    except subprocess.CalledProcessError:
        raise RuntimeError(f"{repo_path.as_posix()} is not tracked by Git")


def blob_oid(path: Path, object_format: str) -> str:
    content = path.read_bytes()
    data = b"blob " + str(len(content)).encode("ascii") + b"\0" + content

    if object_format == "sha1":
        return hashlib.sha1(data).hexdigest()
    if object_format == "sha256":
        return hashlib.sha256(data).hexdigest()

    raise RuntimeError(f"unsupported Git object format: {object_format}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Print the loose-object path for the current contents of a tracked file."
    )
    parser.add_argument("path", help="repository-relative or working-tree file path")
    args = parser.parse_args(argv)

    cwd = Path.cwd().resolve()

    try:
        repo_root, git_dir, object_format = find_repo(cwd)
        target = resolve_target(args.path, cwd, repo_root)

        if not target.exists():
            return fail(f"{args.path} does not exist")
        if not target.is_file():
            return fail(f"{target} is not a regular file")

        repo_path = relative_to_repo(target, repo_root)
        ensure_tracked(repo_root, repo_path)

        oid = blob_oid(target, object_format)
        loose_path = git_dir / "objects" / oid[:2] / oid[2:]
        loose_exists = loose_path.exists()
    except RuntimeError as error:
        return fail(str(error))
    except OSError as error:
        return fail(str(error))

    print(f"repository: {repo_root}")
    print(f"file: {repo_path.as_posix()}")
    print(f"object_format: {object_format}")
    print(f"blob_oid: {oid}")
    print(f"loose_object_path: {loose_path}")
    print(f"loose_object_exists: {'yes' if loose_exists else 'no'}")

    if not loose_exists:
        print(
            "note: object is not present as a loose object; it may be packed, "
            "or the current file content may not have been written as an object yet."
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
