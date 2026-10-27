import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest
from unittest import mock


PROJECT_ROOT = Path(__file__).resolve().parent.parent
SPEC = importlib.util.spec_from_file_location("git_repos", PROJECT_ROOT / "python/git_repos.py")
DISCOVERY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(DISCOVERY)
SHELLS = [shell for shell in ("bash", "zsh") if shutil.which(shell)]


class RepositoriesTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="gt-repos-test-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.root = self.base / "workspace"
        self.root.mkdir()
        self.cache = self.base / "cache"
        self.env = dict(os.environ, GIT_TOOLS_DIR=str(PROJECT_ROOT),
                        GT_REPOS_CACHE_DIR=str(self.cache), GT_REPOS_CACHE_TTL="300")

    def repo(self, name):
        path = self.root / name
        (path / ".git").mkdir(parents=True)
        return path

    def run_shell(self, command, shell="bash", cwd=None, **env):
        return subprocess.run(
            [shell, "-f", "-c", 'source "$GIT_TOOLS_DIR/git_repos.sh"\n' + command],
            cwd=cwd or self.root, env=dict(self.env, **env),
            capture_output=True, text=True, timeout=15,
        )

    def paths(self, flags="", **kwargs):
        result = self.run_shell("gfrepos " + flags, **kwargs)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout.splitlines()

    def test_discovery_modes_and_metadata_exclusion(self):
        outer = self.repo("outer repo")
        nested = self.repo("outer repo/nested")
        self.repo("outer repo/.git/not-a-working-tree")
        other = self.repo("group/other")
        (self.root / "linked").symlink_to(other, target_is_directory=True)
        for shell in SHELLS:
            with self.subTest(shell=shell):
                self.assertEqual(self.paths("--no-cache", shell=shell), sorted(map(str, [outer, other])))
                self.assertEqual(self.paths("-r --no-cache", shell=shell), sorted(map(str, [outer, nested, other])))
                self.assertEqual(self.paths("--no-cache", shell=shell, cwd=outer), [str(outer)])

    def test_default_does_not_visit_repository_contents(self):
        repo = self.repo("repo")
        with mock.patch.object(DISCOVERY.os, "scandir", wraps=os.scandir) as scan:
            self.assertEqual(DISCOVERY.discover(str(repo), False), ([str(repo)], True))
            scan.assert_not_called()

    def test_cache_refresh_expiry_and_bypass(self):
        first = self.repo("first")
        self.assertEqual(self.paths(), [str(first)])
        cache = next(self.cache.glob("*.json"))
        second = self.repo("second")
        self.assertEqual(self.paths(), [str(first)])
        self.assertEqual(self.paths("--no-cache"), [str(first), str(second)])
        self.assertEqual(self.paths(), [str(first)])
        self.assertEqual(self.paths(GT_REPOS_CACHE_TTL="0"), [str(first), str(second)])
        self.assertEqual(self.paths("--refresh"), [str(first), str(second)])
        third = self.repo("third")
        os.utime(cache, (time.time() - 301, time.time() - 301))
        self.assertEqual(self.paths(), list(map(str, [first, second, third])))
        shutil.rmtree(second)
        self.assertEqual(self.paths(), [str(first), str(third)])

    def test_cache_is_separate_for_each_root_and_mode(self):
        outer = self.repo("outer")
        nested = self.repo("outer/nested")
        self.assertEqual(self.paths(), [str(outer)])
        self.assertEqual(self.paths("-r"), [str(outer), str(nested)])
        self.assertEqual(self.paths(cwd=nested), [str(nested)])
        self.assertEqual(len(list(self.cache.glob("*.json"))), 3)

    def test_corrupt_or_unavailable_cache_falls_back_to_scan(self):
        repo = self.repo("repo")
        self.paths()
        cache = next(self.cache.glob("*.json"))
        for content in ("invalid json", '{"wrong": "shape"}', '[42]', '["/outside"]'):
            cache.write_text(content)
            self.assertEqual(self.paths(), [str(repo)])
        blocked = self.base / "not-a-directory"
        blocked.write_text("occupied")
        self.assertEqual(self.paths(GT_REPOS_CACHE_DIR=str(blocked)), [str(repo)])

    def test_scan_failure_reports_error_and_is_not_cached(self):
        with mock.patch.dict(os.environ, self.env), mock.patch.object(DISCOVERY.os, "scandir", side_effect=PermissionError("denied")), mock.patch.object(DISCOVERY.sys, "argv", ["git_repos"]), mock.patch.object(DISCOVERY.os, "getcwd", return_value=str(self.root)), mock.patch.object(DISCOVERY.sys, "stderr"):
            self.assertEqual(DISCOVERY.main(), 1)
        self.assertFalse(self.cache.exists())

    def test_selection_cancellation_help_and_bad_options(self):
        repo = self.repo("repo with spaces")
        for shell in SHELLS:
            with self.subTest(shell=shell):
                selected = self.run_shell('default-fuzzy-finder() { head -n 1; }; gt-repos-cd; pwd', shell=shell)
                self.assertEqual(selected.returncode, 0, selected.stderr)
                self.assertEqual(selected.stdout.strip(), str(repo))
                cancelled = self.run_shell('default-fuzzy-finder() { cat >/dev/null; return 130; }; gt-repos-cd; result=$?; pwd; exit "$result"', shell=shell)
                self.assertEqual(cancelled.returncode, 130)
                self.assertEqual(cancelled.stdout.strip(), str(self.root))
                for option, expected in (("--help", 0), ("--unknown", 2)):
                    result = self.run_shell('default-fuzzy-finder() { echo CALLED >&2; return 77; }; gt-repos-cd ' + option, shell=shell)
                    self.assertEqual(result.returncode, expected, result.stderr)
                    self.assertNotIn("CALLED", result.stderr)
                empty = self.base / ("empty-" + shell)
                empty.mkdir()
                result = self.run_shell('default-fuzzy-finder() { return 77; }; gt-repos-cd', shell=shell, cwd=empty)
                self.assertEqual(result.returncode, 0, result.stderr)

    def test_refresh_flag_reaches_cdr(self):
        self.paths()
        repo = self.repo("new repo")
        result = self.run_shell('default-fuzzy-finder() { head -n 1; }; gt-repos-cd --refresh; pwd')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), str(repo))

    def test_invalid_ttl(self):
        for ttl in ("-1", "nan", "inf", "oops"):
            result = self.run_shell("gfrepos", GT_REPOS_CACHE_TTL=ttl)
            self.assertEqual(result.returncode, 2)
            self.assertIn("GT_REPOS_CACHE_TTL", result.stderr)

    def test_real_worktree_and_submodule(self):
        def git(*args):
            return subprocess.run(["git", *map(str, args)], check=True, capture_output=True, text=True)

        main = self.root / "main"
        worktree = self.root / "worktree with spaces"
        source = self.base / "submodule-source"
        for repo in (main, source):
            git("init", repo)
            git("-C", repo, "-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "--allow-empty", "-m", "initial")
        git("-C", main, "remote", "add", "origin", "https://example.invalid/repo.git")
        git("-C", main, "worktree", "add", "--detach", worktree)
        git("-C", main, "-c", "protocol.file.allow=always", "submodule", "add", source, "sub")
        self.assertTrue((worktree / ".git").is_file())
        self.assertTrue((main / "sub/.git").is_file())
        self.assertEqual(self.paths(), [str(main), str(worktree)])
        self.assertEqual(self.paths("-r"), [str(main), str(main / "sub"), str(worktree)])
        result = self.run_shell("gt-repos-urls-current-folder")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines(), ["https://example.invalid/repo.git"] * 2)


if __name__ == "__main__":
    unittest.main()
