import subprocess
import tempfile
import unittest
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent.parent


class CloneShallowAllBranchesTest(unittest.TestCase):
    def git(self, repo, *args):
        return subprocess.check_output(
            ["git", "-C", str(repo), *args], text=True, stderr=subprocess.PIPE
        ).strip()

    def command(self, cwd, *args):
        script = '''
source "$1/git_clone.sh"
shift
gt-clone-shallow-all-branches "$@"
result=$?
printf '\\nCWD=%s\\n' "$PWD"
exit "$result"
'''
        return subprocess.run(
            ["bash", "-c", script, "clone-test", str(PROJECT_ROOT), *args],
            cwd=cwd, capture_output=True, text=True,
        )

    def test_all_branches_have_one_commit_and_track_origin(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            source = root / "source repo.git"
            source.mkdir()
            self.git(source, "init", "-b", "main")
            self.git(source, "config", "user.name", "Clone Test")
            self.git(source, "config", "user.email", "clone@example.invalid")
            for message in ("initial", "second", "third"):
                self.git(source, "commit", "--allow-empty", "-m", message)
            self.git(source, "branch", "older", "HEAD~1")
            self.git(source, "switch", "-c", "feature/topic")
            self.git(source, "commit", "--allow-empty", "-m", "feature")
            self.git(source, "switch", "main")
            branches = ["feature/topic", "main", "older"]

            for local_path in (False, True):
                with self.subTest(local_path=local_path):
                    parent = root / str(local_path)
                    parent.mkdir()
                    if local_path:
                        args = (str(source), "custom destination")
                        clone = parent / "custom destination"
                    else:
                        args = (source.as_uri(),)
                        clone = parent / "source%20repo"
                    result = self.command(parent, *args)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertIn(f"CWD={clone}\n", result.stdout)
                    self.assertEqual(self.git(clone, "branch", "--show-current"), "main")
                    self.assertEqual(self.git(clone, "rev-parse", "--is-shallow-repository"), "true")
                    self.assertEqual(
                        self.git(clone, "for-each-ref", "--format=%(refname:short)", "refs/heads/").splitlines(),
                        branches,
                    )
                    self.assertEqual(
                        self.git(clone, "config", "--get-all", "remote.origin.fetch"),
                        "+refs/heads/*:refs/remotes/origin/*",
                    )
                    for branch in branches:
                        self.assertEqual(self.git(clone, "rev-list", "--count", branch), "1")
                        self.assertEqual(self.git(clone, "rev-parse", branch), self.git(source, "rev-parse", branch))
                        self.assertEqual(
                            self.git(clone, "rev-parse", "--abbrev-ref", f"{branch}@{{upstream}}"),
                            f"origin/{branch}",
                        )
                        self.git(clone, "switch", branch)

    def test_invalid_arguments_and_failed_clone_preserve_directory(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            for args in ((), ("",), ("a", "b", "c"), (str(root / "missing"), "target")):
                with self.subTest(args=args):
                    result = self.command(root, *args)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn(f"CWD={root}\n", result.stdout)
                    self.assertFalse((root / "target").exists())


if __name__ == "__main__":
    unittest.main()
