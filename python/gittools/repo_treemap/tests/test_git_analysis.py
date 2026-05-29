from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from gittools.repo_treemap.git_analysis import RepoTreemapAnalyzer


class PathSanitizationTest(unittest.TestCase):
    def test_rejects_parent_traversal(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            self._git(repo, "init")
            self._git(repo, "config", "user.name", "Tester")
            self._git(repo, "config", "user.email", "tester@example.com")
            (repo / "file.txt").write_text("hello\n", encoding="utf-8")
            self._git(repo, "add", "file.txt")
            self._git(repo, "commit", "-m", "initial")

            analyzer = RepoTreemapAnalyzer(repo)
            with self.assertRaises(ValueError):
                analyzer.sanitize_path("../outside")

    def test_cache_invalidates_when_head_changes(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            self._git(repo, "init")
            self._git(repo, "config", "user.name", "Tester")
            self._git(repo, "config", "user.email", "tester@example.com")
            (repo / "file.txt").write_text("one\n", encoding="utf-8")
            self._git(repo, "add", "file.txt")
            self._git(repo, "commit", "-m", "one")

            first = RepoTreemapAnalyzer(repo)
            self.assertFalse(first.cache_used)
            second = RepoTreemapAnalyzer(repo)
            self.assertTrue(second.cache_used)

            (repo / "file.txt").write_text("one\ntwo\n", encoding="utf-8")
            self._git(repo, "add", "file.txt")
            self._git(repo, "commit", "-m", "two")
            third = RepoTreemapAnalyzer(repo)
            self.assertFalse(third.cache_used)
            self.assertEqual(third.files["file.txt"]["loc"], 2)

    @staticmethod
    def _git(repo: Path, *args: str) -> None:
        import subprocess

        subprocess.run(["git", "-C", str(repo), *args], check=True, stdout=subprocess.PIPE)


if __name__ == "__main__":
    unittest.main()
