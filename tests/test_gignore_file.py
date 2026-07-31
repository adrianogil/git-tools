import contextlib
import io
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


PROJECT_ROOT = Path(__file__).resolve().parent.parent
PYTHON_DIR = PROJECT_ROOT / "python"
if str(PYTHON_DIR) not in sys.path:
    sys.path.insert(0, str(PYTHON_DIR))

import gignore_file


class GitIgnoreFileTest(unittest.TestCase):
    def init_repo(self, path):
        subprocess.run(
            ["git", "init", str(path)],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

    def test_get_git_root_uses_subprocess_arguments(self):
        completed_process = subprocess.CompletedProcess(
            ["git", "rev-parse", "--show-toplevel"],
            returncode=0,
            stdout="/tmp/repo with spaces\n",
        )

        with patch("subprocess.run", return_value=completed_process) as run_mock:
            root = gignore_file.get_git_root("/tmp/repo with spaces/subdir")

        self.assertEqual(root, "/tmp/repo with spaces")
        run_mock.assert_called_once_with(
            ["git", "rev-parse", "--show-toplevel"],
            cwd="/tmp/repo with spaces/subdir",
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            encoding="utf-8",
            check=False,
        )

    def test_ignore_file_appends_relative_path_with_spaces_and_unicode(self):
        with tempfile.TemporaryDirectory(prefix="gignore repo ü ") as temp_dir:
            repo = Path(temp_dir) / "project with spaces"
            target = repo / "dados úteis" / "résumé final.txt"
            target.parent.mkdir(parents=True)
            target.touch()
            self.init_repo(repo)

            self.assertTrue(gignore_file.ignore_file(str(target)))

            self.assertEqual(
                (repo / ".gitignore").read_text(encoding="utf-8"),
                os.path.join("dados úteis", "résumé final.txt") + "\n",
            )

    def test_shell_function_preserves_spaced_unicode_path_as_one_argument(self):
        with tempfile.TemporaryDirectory(prefix="gignore shell ü ") as temp_dir:
            repo = Path(temp_dir) / "project with spaces"
            target = repo / "dados úteis" / "résumé final's.txt"
            target.parent.mkdir(parents=True)
            target.touch()
            self.init_repo(repo)
            env = os.environ.copy()
            env["GIT_TOOLS_DIR"] = str(PROJECT_ROOT)
            shell_script = """
abspath() { printf '%s\\n' "$1"; }
source "$GIT_TOOLS_DIR/git_ignore.sh"
gignore-file "$1"
"""

            result = subprocess.run(
                ["bash", "-c", shell_script, "gignore-test", str(target)],
                cwd=repo,
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                encoding="utf-8",
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(
                (repo / ".gitignore").read_text(encoding="utf-8"),
                os.path.join("dados úteis", "résumé final's.txt") + "\n",
            )

    def test_append_pattern_handles_spaces_unicode_and_missing_final_newline(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            gitignore = Path(temp_dir) / ".gitignore"
            gitignore.write_text("existing-pattern", encoding="utf-8")

            added = gignore_file.append_pattern(
                gitignore,
                "build output/relatório final.txt",
            )

            self.assertTrue(added)
            self.assertEqual(
                gitignore.read_text(encoding="utf-8"),
                "existing-pattern\nbuild output/relatório final.txt\n",
            )

    def test_append_pattern_does_not_add_duplicate(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            gitignore = Path(temp_dir) / ".gitignore"
            pattern = "dados úteis/résumé final.txt"
            gitignore.write_text(pattern + "\n", encoding="utf-8")

            added = gignore_file.append_pattern(gitignore, pattern)

            self.assertFalse(added)
            self.assertEqual(gitignore.read_text(encoding="utf-8"), pattern + "\n")

    def test_main_reports_non_repo_without_creating_gitignore(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            target = Path(temp_dir) / "file with spaces.txt"
            target.touch()
            output = io.StringIO()

            with contextlib.redirect_stdout(output):
                exit_code = gignore_file.main([str(target)])

            self.assertEqual(exit_code, 1)
            self.assertIn("Error: file is not inside a valid git repo", output.getvalue())
            self.assertFalse((Path(temp_dir) / ".gitignore").exists())


if __name__ == "__main__":
    unittest.main()
