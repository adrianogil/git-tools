import argparse
import os
import subprocess
import sys
from typing import Iterable, List, Optional


def run_git(args: List[str], *, text: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["git", *args],
        check=False,
        capture_output=True,
        text=text,
    )


def ensure_repo_root() -> str:
    result = run_git(["rev-parse", "--show-toplevel"])
    if result.returncode != 0:
        print("gt-files-to-prompt-to-code-review: not a git repo", file=sys.stderr)
        raise SystemExit(1)
    return result.stdout.strip()


def get_changed_files(commit: str) -> List[str]:
    result = run_git(["diff-tree", "--no-commit-id", "--name-only", "-r", commit])
    if result.returncode != 0:
        print(
            f"gt-files-to-prompt-to-code-review: failed to list files for {commit}",
            file=sys.stderr,
        )
        raise SystemExit(1)
    files = [line for line in result.stdout.splitlines() if line.strip()]
    if not files:
        print(
            f"gt-files-to-prompt-to-code-review: no files changed in commit {commit}",
            file=sys.stderr,
        )
        raise SystemExit(1)
    return files


def is_text_blob(data: bytes) -> bool:
    if b"\x00" in data:
        return False
    try:
        data.decode("utf-8")
    except UnicodeDecodeError:
        return False
    return True


def get_file_content(commit: str, file_path: str) -> Optional[str]:
    result = subprocess.run(
        ["git", "show", f"{commit}:{file_path}"],
        check=False,
        capture_output=True,
    )
    if result.returncode != 0:
        print(
            f"gt-files-to-prompt-to-code-review: {file_path}: missing or unreadable",
            file=sys.stderr,
        )
        return None
    if not is_text_blob(result.stdout):
        print(
            f"gt-files-to-prompt-to-code-review: {file_path} is binary, skipping",
            file=sys.stderr,
        )
        return None
    return result.stdout.decode("utf-8")


def build_prompt(commit: str, files: Iterable[str]) -> str:
    show_result = run_git(["show", commit])
    if show_result.returncode != 0:
        print(
            f"gt-files-to-prompt-to-code-review: failed to read commit {commit}",
            file=sys.stderr,
        )
        raise SystemExit(1)

    lines: List[str] = [
        "Help me to code review this commit. Give me comments per file.",
        "",
        "Here is the commit:",
        show_result.stdout.rstrip(),
        "",
        "And below is full content version of each file:",
    ]

    for file_path in files:
        content = get_file_content(commit, file_path)
        if content is None:
            continue
        lines.append(f"```{file_path}")
        lines.append(content.rstrip("\n"))
        lines.append("```")

    return "\n".join(lines).rstrip() + "\n"


def copy_to_clipboard(text: str) -> None:
    try:
        process = subprocess.run(
            ["copy-text-to-clipboard"],
            input=text,
            text=True,
            check=False,
        )
    except FileNotFoundError:
        print(
            "gt-files-to-prompt-to-code-review: copy-text-to-clipboard not found",
            file=sys.stderr,
        )
        raise SystemExit(1)

    if process.returncode != 0:
        print(
            "gt-files-to-prompt-to-code-review: failed to copy prompt to clipboard",
            file=sys.stderr,
        )
        raise SystemExit(process.returncode)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Copy a code-review prompt for a commit to the clipboard."
    )
    parser.add_argument("commit", nargs="?", default="HEAD")
    args = parser.parse_args()

    repo_root = ensure_repo_root()
    os.chdir(repo_root)
    files = get_changed_files(args.commit)
    prompt = build_prompt(args.commit, files)
    copy_to_clipboard(prompt)


if __name__ == "__main__":
    main()
