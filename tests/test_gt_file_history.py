import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent.parent
GIT_FILES = PROJECT_ROOT / "git_files.sh"


class GitFileHistoryCommandTest(unittest.TestCase):
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
        self.run_git("config", "user.name", "File History Test", cwd=path)
        self.run_git(
            "config",
            "user.email",
            "file-history-test@example.invalid",
            cwd=path,
        )

    def commit_all(self, repo, message):
        self.run_git("add", "-A", cwd=repo)
        self.run_git("commit", "-m", message, cwd=repo)
        return self.run_git("rev-parse", "HEAD", cwd=repo).stdout.strip()

    def create_renamed_history(self, repo):
        original = repo / "old name.txt"
        original.write_text("first\n", encoding="utf-8")
        commits = {"add original": self.commit_all(repo, "add original")}

        original.write_text("first\nsecond\n", encoding="utf-8")
        commits["edit original"] = self.commit_all(repo, "edit original")

        unicode_path = repo / "docs" / "résumé history.txt"
        unicode_path.parent.mkdir()
        self.run_git("mv", "--", str(original), str(unicode_path), cwd=repo)
        commits["first rename"] = self.commit_all(repo, "first rename")

        unicode_path.write_text("first\nsecond\nthird\n", encoding="utf-8")
        commits["edit unicode path"] = self.commit_all(repo, "edit unicode path")

        final_path = repo / "- final résumé.txt"
        self.run_git("mv", "--", str(unicode_path), str(final_path), cwd=repo)
        commits["second rename"] = self.commit_all(repo, "second rename")

        final_path.write_text("first\nsecond\nthird\nfourth\n", encoding="utf-8")
        commits["edit final path"] = self.commit_all(repo, "edit final path")
        return final_path, commits

    def run_command(self, cwd, *args, shell="bash", fuzzy_finder_body=None):
        fuzzy_finder = ""
        if fuzzy_finder_body is not None:
            fuzzy_finder = "default-fuzzy-finder() { %s; };" % fuzzy_finder_body
        script = '%s source "$1/git_files.sh"; shift; gt-file-history "$@"' % (
            fuzzy_finder
        )
        return subprocess.run(
            [shell, "-c", script, "gt-file-history-test", str(PROJECT_ROOT), *args],
            cwd=cwd,
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
        )

    def test_default_log_follows_multiple_renames_and_preserves_order(self):
        expected_subjects = [
            "edit final path",
            "second rename",
            "edit unicode path",
            "first rename",
            "edit original",
            "add original",
        ]
        shells = ["bash"]
        if shutil.which("zsh"):
            shells.append("zsh")

        for shell in shells:
            with self.subTest(shell=shell), tempfile.TemporaryDirectory(
                prefix="gt-file-history-test-"
            ) as temp_dir:
                repo = Path(temp_dir) / "repo"
                self.init_repo(repo)
                final_path, _ = self.create_renamed_history(repo)

                result = self.run_command(repo, final_path.name, shell=shell)

                self.assertEqual(result.returncode, 0, result.stderr)
                lines = result.stdout.splitlines()
                self.assertEqual(len(lines), len(expected_subjects))
                self.assertEqual(
                    [next(subject for subject in expected_subjects if subject in line) for line in lines],
                    expected_subjects,
                )

    def test_accepts_absolute_path_from_a_nested_directory(self):
        with tempfile.TemporaryDirectory(prefix="gt-file-history-test-") as temp_dir:
            repo = Path(temp_dir) / "repo"
            self.init_repo(repo)
            final_path, _ = self.create_renamed_history(repo)
            nested = repo / "one" / "two"
            nested.mkdir(parents=True)

            result = self.run_command(nested, str(final_path))

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("add original", result.stdout)

    def test_explicit_diff_uses_the_path_from_the_selected_revision(self):
        with tempfile.TemporaryDirectory(prefix="gt-file-history-test-") as temp_dir:
            repo = Path(temp_dir) / "repo"
            self.init_repo(repo)
            final_path, commits = self.create_renamed_history(repo)

            result = self.run_command(
                repo,
                "--diff",
                commits["edit original"],
                "--",
                final_path.name,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(f"commit {commits['edit original']}", result.stdout)
            self.assertIn("diff --git a/old name.txt b/old name.txt", result.stdout)
            self.assertIn("+second", result.stdout)

            rename_result = self.run_command(
                repo,
                "--diff",
                commits["first rename"],
                "--",
                final_path.name,
            )
            self.assertEqual(rename_result.returncode, 0, rename_result.stderr)
            self.assertIn("similarity index 100%", rename_result.stdout)
            self.assertIn("rename from old name.txt", rename_result.stdout)
            self.assertIn("rename to docs/résumé history.txt", rename_result.stdout)

    def test_interactive_diff_selects_a_followed_commit(self):
        with tempfile.TemporaryDirectory(prefix="gt-file-history-test-") as temp_dir:
            repo = Path(temp_dir) / "repo"
            self.init_repo(repo)
            final_path, commits = self.create_renamed_history(repo)

            result = self.run_command(
                repo,
                "--diff",
                "--",
                final_path.name,
                fuzzy_finder_body="grep 'edit unicode path'",
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(f"commit {commits['edit unicode path']}", result.stdout)
            self.assertIn("résumé history.txt", result.stdout)
            self.assertIn("+third", result.stdout)

    def test_deleted_file_history_remains_available(self):
        with tempfile.TemporaryDirectory(prefix="gt-file-history-test-") as temp_dir:
            repo = Path(temp_dir) / "repo"
            self.init_repo(repo)
            final_path, _ = self.create_renamed_history(repo)
            final_path.unlink()
            self.commit_all(repo, "delete final path")

            result = self.run_command(repo, "--", final_path.name)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(len(result.stdout.splitlines()), 7)
            self.assertIn("delete final path", result.stdout.splitlines()[0])
            self.assertIn("add original", result.stdout.splitlines()[-1])

    def test_rejects_paths_outside_the_repository(self):
        with tempfile.TemporaryDirectory(prefix="gt-file-history-test-") as temp_dir:
            temp_path = Path(temp_dir)
            repo = temp_path / "repo"
            outside = temp_path / "outside.txt"
            self.init_repo(repo)
            outside.write_text("outside\n", encoding="utf-8")

            result = self.run_command(repo, str(outside))

            self.assertEqual(result.returncode, 1)
            self.assertEqual(result.stdout, "")
            self.assertIn("path is outside the repository or invalid", result.stderr)

    def test_fails_outside_a_git_worktree(self):
        with tempfile.TemporaryDirectory(prefix="gt-file-history-test-") as temp_dir:
            result = self.run_command(temp_dir, "file.txt")

            self.assertEqual(result.returncode, 1)
            self.assertEqual(result.stdout, "")
            self.assertEqual(
                result.stderr,
                "gt-file-history: not inside a Git worktree.\n",
            )

    def test_reports_missing_history(self):
        with tempfile.TemporaryDirectory(prefix="gt-file-history-test-") as temp_dir:
            repo = Path(temp_dir) / "repo"
            self.init_repo(repo)
            self.run_git("commit", "--allow-empty", "-m", "initial", cwd=repo)

            result = self.run_command(repo, "never tracked.txt")

            self.assertEqual(result.returncode, 1)
            self.assertIn("no history found for: never tracked.txt", result.stderr)

    def test_rejects_invalid_ambiguous_and_unrelated_revisions(self):
        with tempfile.TemporaryDirectory(prefix="gt-file-history-test-") as temp_dir:
            repo = Path(temp_dir) / "repo"
            self.init_repo(repo)
            final_path, commits = self.create_renamed_history(repo)
            unrelated = repo / "unrelated.txt"
            unrelated.write_text("unrelated\n", encoding="utf-8")
            unrelated_commit = self.commit_all(repo, "unrelated change")
            self.run_git("branch", "collision", "HEAD", cwd=repo)
            self.run_git("tag", "collision", commits["add original"], cwd=repo)

            invalid = self.run_command(repo, "--diff", "missing-revision", final_path.name)
            ambiguous = self.run_command(repo, "--diff", "collision", final_path.name)
            unrelated_result = self.run_command(
                repo, "--diff", unrelated_commit, final_path.name
            )

            self.assertEqual(invalid.returncode, 1)
            self.assertIn("invalid or ambiguous revision: missing-revision", invalid.stderr)
            self.assertEqual(ambiguous.returncode, 1)
            self.assertIn("invalid or ambiguous revision: collision", ambiguous.stderr)
            self.assertEqual(unrelated_result.returncode, 1)
            self.assertIn("revision did not change this file", unrelated_result.stderr)

    def test_shallow_repository_reports_incomplete_history(self):
        with tempfile.TemporaryDirectory(prefix="gt-file-history-test-") as temp_dir:
            temp_path = Path(temp_dir)
            source = temp_path / "source"
            clone = temp_path / "shallow"
            self.init_repo(source)
            final_path, _ = self.create_renamed_history(source)
            self.run_git("clone", "--depth", "1", source.as_uri(), str(clone))

            result = self.run_command(clone, final_path.name)

            self.assertEqual(result.returncode, 1)
            self.assertEqual(result.stdout, "")
            self.assertIn("repository history is shallow", result.stderr)

    def test_help_documents_log_and_diff_forms(self):
        result = self.run_command(PROJECT_ROOT, "--help")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("gt-file-history [--] FILE", result.stdout)
        self.assertIn("gt-file-history --diff [REV] [--] FILE", result.stdout)
        self.assertIn("following historical renames", result.stdout)

    def test_git_files_script_has_valid_bash_and_zsh_syntax(self):
        shells = ["bash"]
        if shutil.which("zsh"):
            shells.append("zsh")

        for shell in shells:
            with self.subTest(shell=shell):
                result = subprocess.run(
                    [shell, "-n", str(GIT_FILES)],
                    check=False,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                    encoding="utf-8",
                )
                self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
