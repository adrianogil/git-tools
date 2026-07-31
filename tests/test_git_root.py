import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent.parent
PYTHON_DIR = PROJECT_ROOT / "python"
if str(PYTHON_DIR) not in sys.path:
    sys.path.insert(0, str(PYTHON_DIR))

import gignore_file
from gittools.config import root as root_config


class GitRootDetectionTest(unittest.TestCase):
    detectors = (
        gignore_file.get_git_root,
        root_config.get_git_root,
    )

    def run_git(self, *args, cwd=None):
        return subprocess.run(
            ["git", *args],
            cwd=cwd,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
        )

    def init_repo(self, path):
        self.run_git("init", str(path))

    def assert_git_root(self, path, expected):
        for detector in self.detectors:
            with self.subTest(detector=detector.__module__):
                self.assertEqual(detector(path), str(expected.resolve()))

    def test_repo_root(self):
        with tempfile.TemporaryDirectory(prefix="git-root-test-") as temp_dir:
            repo = Path(temp_dir) / "repo"
            self.init_repo(repo)

            self.assert_git_root(repo, repo)

    def test_nested_subdirectory_returns_repo_root(self):
        with tempfile.TemporaryDirectory(prefix="git-root-test-") as temp_dir:
            repo = Path(temp_dir) / "repo"
            nested = repo / "one" / "two"
            nested.mkdir(parents=True)
            self.init_repo(repo)

            self.assert_git_root(nested, repo)

    def test_non_repo_returns_none(self):
        with tempfile.TemporaryDirectory(prefix="git-root-test-") as temp_dir:
            non_repo = Path(temp_dir) / "not-a-repo"
            non_repo.mkdir()

            for detector in self.detectors:
                with self.subTest(detector=detector.__module__):
                    self.assertIsNone(detector(non_repo))

    def test_linked_worktree_returns_worktree_root(self):
        with tempfile.TemporaryDirectory(prefix="git-root-test-") as temp_dir:
            temp_path = Path(temp_dir)
            repo = temp_path / "main-repo"
            worktree = temp_path / "linked-worktree"
            self.init_repo(repo)
            self.run_git(
                "-c",
                "user.name=Git Root Test",
                "-c",
                "user.email=git-root-test@example.invalid",
                "commit",
                "--allow-empty",
                "-m",
                "initial commit",
                cwd=repo,
            )
            self.run_git(
                "worktree",
                "add",
                "-b",
                "linked-worktree-test",
                str(worktree),
                cwd=repo,
            )

            self.assert_git_root(worktree, worktree)


if __name__ == "__main__":
    unittest.main()
