import subprocess
import tempfile
import unittest
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent.parent


class GitReflogCherryPickCommandTest(unittest.TestCase):
    def run_git(self, *args, cwd=None, check=True):
        return subprocess.run(
            ["git", *args],
            cwd=cwd,
            check=check,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
        )

    def init_repo(self, path):
        self.run_git("init", "-b", "main", str(path))
        self.run_git("config", "user.name", "Reflog Cherry Pick Test", cwd=path)
        self.run_git(
            "config",
            "user.email",
            "reflog-cherry-pick-test@example.invalid",
            cwd=path,
        )

    def commit_all(self, repo, message):
        self.run_git("add", "-A", cwd=repo)
        self.run_git("commit", "-m", message, cwd=repo)

    def run_command(self, cwd, fuzzy_finder_body=None):
        fuzzy_finder = ""
        if fuzzy_finder_body is not None:
            fuzzy_finder = """
default-fuzzy-finder() {
    %s
}
""" % fuzzy_finder_body
        script = """
%s
source "$1/git_history.sh"
gt-reflog-cherry-pick
""" % fuzzy_finder
        return subprocess.run(
            ["bash", "-c", script, "gt-reflog-test", str(PROJECT_ROOT)],
            cwd=cwd,
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
        )

    def inspect_alias(self, alias_name):
        script = 'source "$1/git_history.sh"; alias "$2"'
        return subprocess.run(
            [
                "bash",
                "-c",
                script,
                "gt-reflog-test",
                str(PROJECT_ROOT),
                alias_name,
            ],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
        )

    def test_defines_cereja_alias(self):
        new_alias = self.inspect_alias("gflog-cereja")
        old_alias = self.inspect_alias("gflog-cherry-pick")

        self.assertEqual(new_alias.returncode, 0, new_alias.stderr)
        self.assertEqual(
            new_alias.stdout,
            "alias gflog-cereja='gt-reflog-cherry-pick'\n",
        )
        self.assertNotEqual(old_alias.returncode, 0)

    def test_selects_reflog_commit_and_cherry_picks_it(self):
        with tempfile.TemporaryDirectory(prefix="gt-reflog-test-") as temp_dir:
            repo = Path(temp_dir) / "repo"
            self.init_repo(repo)
            recovered_file = repo / "recovered file.txt"
            recovered_file.write_text("base\n", encoding="utf-8")
            self.commit_all(repo, "initial commit")

            recovered_file.write_text("recovered content\n", encoding="utf-8")
            self.commit_all(repo, "commit to recover")
            recovered_commit = self.run_git("rev-parse", "HEAD", cwd=repo).stdout.strip()
            self.run_git("reset", "--hard", "HEAD~1", cwd=repo)

            result = self.run_command(repo, "grep 'commit to recover' | head -n 1")

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(f"Cherry-picking {recovered_commit[:7]}...", result.stdout)
            self.assertEqual(
                recovered_file.read_text(encoding="utf-8"),
                "recovered content\n",
            )
            self.assertEqual(
                self.run_git("log", "-1", "--format=%s", cwd=repo).stdout.strip(),
                "commit to recover",
            )

    def test_cancelled_selection_does_not_cherry_pick(self):
        with tempfile.TemporaryDirectory(prefix="gt-reflog-test-") as temp_dir:
            repo = Path(temp_dir) / "repo"
            self.init_repo(repo)
            (repo / "file.txt").write_text("content\n", encoding="utf-8")
            self.commit_all(repo, "initial commit")
            head_before = self.run_git("rev-parse", "HEAD", cwd=repo).stdout.strip()

            result = self.run_command(repo, "return 1")

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout, "No commit selected.\n")
            self.assertEqual(
                self.run_git("rev-parse", "HEAD", cwd=repo).stdout.strip(),
                head_before,
            )

    def test_fails_outside_a_git_worktree(self):
        with tempfile.TemporaryDirectory(prefix="gt-reflog-test-") as temp_dir:
            result = self.run_command(temp_dir, "head -n 1")

            self.assertEqual(result.returncode, 1)
            self.assertEqual(result.stdout, "")
            self.assertEqual(result.stderr, "Error: not inside a Git worktree.\n")

    def test_fails_when_fuzzy_finder_is_not_configured(self):
        with tempfile.TemporaryDirectory(prefix="gt-reflog-test-") as temp_dir:
            repo = Path(temp_dir) / "repo"
            self.init_repo(repo)

            result = self.run_command(repo)

            self.assertEqual(result.returncode, 1)
            self.assertEqual(result.stdout, "")
            self.assertEqual(
                result.stderr,
                "Error: default-fuzzy-finder is not configured.\n",
            )


if __name__ == "__main__":
    unittest.main()
