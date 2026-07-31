import subprocess

import os
import sys


def get_git_root(path):
    """Return the repository root containing path, or None outside a repository."""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=path,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            encoding="utf-8",
            check=False,
        )
    except (FileNotFoundError, NotADirectoryError):
        return None

    if result.returncode != 0:
        return None

    return result.stdout.strip()


def append_pattern(gitignore_path, pattern):
    """Append pattern to gitignore_path unless it is already present."""
    try:
        with open(gitignore_path, encoding="utf-8") as gitignore_file:
            existing_content = gitignore_file.read()
    except FileNotFoundError:
        existing_content = ""

    if pattern in existing_content.splitlines():
        return False

    needs_leading_newline = existing_content and not existing_content.endswith(("\n", "\r"))
    with open(gitignore_path, "a", encoding="utf-8") as gitignore_file:
        if needs_leading_newline:
            gitignore_file.write("\n")
        gitignore_file.write(pattern + "\n")

    return True


def ignore_file(target_file):
    """Add target_file as a repository-relative .gitignore pattern."""
    target_file = os.path.abspath(target_file)
    target_path = os.path.dirname(target_file)
    git_repo = get_git_root(target_path)

    if git_repo is None:
        return False

    normalized_target = os.path.join(
        os.path.realpath(target_path),
        os.path.basename(target_file),
    )
    pattern = os.path.relpath(normalized_target, os.path.realpath(git_repo))
    append_pattern(os.path.join(git_repo, ".gitignore"), pattern)
    return True


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    if not argv:
        print("Error: you should provide a file to be ignored")
        return 1

    target_file = argv[0]

    print("Let's ignore file: " + target_file)

    if not ignore_file(target_file):
        print("Error: file is not inside a valid git repo")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
