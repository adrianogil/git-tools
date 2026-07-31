import subprocess
import tempfile
import unittest
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent.parent


class GitConflictsCommandTest(unittest.TestCase):
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

    def commit(self, repo, message):
        self.run_git(
            "-c",
            "user.name=Git Conflicts Test",
            "-c",
            "user.email=git-conflicts-test@example.invalid",
            "commit",
            "-am",
            message,
            cwd=repo,
        )

    def run_gt_conflicts(self, cwd):
        script = 'source "$1/git_status.sh"; gt-conflicts'
        return subprocess.run(
            ["bash", "-c", script, "gt-conflicts-test", str(PROJECT_ROOT)],
            cwd=cwd,
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
        )

    def test_reports_only_unresolved_conflicts(self):
        with tempfile.TemporaryDirectory(prefix="gt-conflicts-test-") as temp_dir:
            repo = Path(temp_dir) / "repo"
            self.init_repo(repo)
            both_modified = repo / "both modified.txt"
            deleted_by_us = repo / "deleted by us.txt"
            both_modified.write_text("base\n", encoding="utf-8")
            deleted_by_us.write_text("base\n", encoding="utf-8")
            self.run_git("add", ".", cwd=repo)
            self.commit(repo, "initial commit")

            self.run_git("checkout", "-b", "feature", cwd=repo)
            both_modified.write_text("feature\n", encoding="utf-8")
            deleted_by_us.write_text("feature\n", encoding="utf-8")
            self.commit(repo, "feature changes")

            self.run_git("checkout", "main", cwd=repo)
            both_modified.write_text("main\n", encoding="utf-8")
            deleted_by_us.unlink()
            self.run_git("add", "-A", cwd=repo)
            self.commit(repo, "main changes")
            merge = self.run_git("merge", "feature", cwd=repo, check=False)
            self.assertNotEqual(merge.returncode, 0)
            (repo / "ordinary untracked.txt").touch()

            status_before = self.run_git("status", "--porcelain=v1", cwd=repo).stdout
            result = self.run_gt_conflicts(repo)
            status_after = self.run_git("status", "--porcelain=v1", cwd=repo).stdout

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(
                result.stdout.splitlines(),
                [
                    "Unresolved conflicts: 2",
                    "  UU  both modified: both modified.txt",
                    "  DU  deleted by us: deleted by us.txt",
                ],
            )
            self.assertNotIn("ordinary untracked.txt", result.stdout)
            self.assertEqual(status_after, status_before)

    def test_reports_when_there_are_no_unresolved_conflicts(self):
        with tempfile.TemporaryDirectory(prefix="gt-conflicts-test-") as temp_dir:
            repo = Path(temp_dir) / "repo"
            self.init_repo(repo)
            (repo / "ordinary change.txt").write_text("untracked\n", encoding="utf-8")

            result = self.run_gt_conflicts(repo)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout, "No unresolved conflicts.\n")

    def test_fails_outside_a_git_worktree(self):
        with tempfile.TemporaryDirectory(prefix="gt-conflicts-test-") as temp_dir:
            result = self.run_gt_conflicts(temp_dir)

            self.assertEqual(result.returncode, 1)
            self.assertEqual(result.stdout, "")
            self.assertEqual(result.stderr, "Error: not inside a Git worktree.\n")


if __name__ == "__main__":
    unittest.main()
