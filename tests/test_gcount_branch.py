import os
import sys
import unittest
from unittest.mock import patch


PROJECT_ROOT = os.path.dirname(os.path.dirname(__file__))
PYTHON_DIR = os.path.join(PROJECT_ROOT, "python")
if PYTHON_DIR not in sys.path:
    sys.path.insert(0, PYTHON_DIR)

import gcount_branch


class BranchStatisticsTest(unittest.TestCase):
    def test_get_remote_branches_uses_subprocess_args_and_filters_head_alias(self):
        def fake_check_output(cmd):
            self.assertEqual(cmd, ["git", "branch", "-r"])
            return b"  origin/main\n  origin/HEAD -> origin/main\n  origin/feature\n"

        with patch("subprocess.check_output", fake_check_output):
            self.assertEqual(
                gcount_branch.get_remote_branches(),
                ["origin/main", "origin/feature"],
            )

    def test_count_commits_uses_git_args_and_counts_lines_in_python(self):
        def fake_check_output(cmd):
            self.assertEqual(cmd, ["git", "log", "--oneline", "--graph", "origin/main"])
            return b"* abc first\n* def second\n\n"

        with patch("subprocess.check_output", fake_check_output):
            self.assertEqual(gcount_branch.count_commits("origin/main"), "2")

    def test_commit_dates_use_subprocess_args(self):
        calls = []

        def fake_check_output(cmd):
            calls.append(cmd)
            if cmd[1] == "rev-list" and "--max-parents=0" in cmd:
                return b"abc123\n"
            if cmd[1] == "rev-list":
                return b"def456\n"
            return b"2026-07-18 10:00:00 -0400\n"

        with patch("subprocess.check_output", fake_check_output):
            first_commit = gcount_branch.get_first_commit()
            last_commit = gcount_branch.get_last_commit()
            first_date = gcount_branch.get_commit_date(first_commit)
            last_date = gcount_branch.get_commit_date(last_commit)

        self.assertEqual(first_commit, "abc123")
        self.assertEqual(last_commit, "def456")
        self.assertEqual(first_date, "2026-07-18 10:00:00 -0400")
        self.assertEqual(last_date, "2026-07-18 10:00:00 -0400")
        self.assertEqual(
            calls,
            [
                ["git", "rev-list", "--max-parents=0", "HEAD", "--abbrev-commit"],
                ["git", "rev-list", "HEAD", "--abbrev-commit", "-1"],
                ["git", "log", "-1", "--format=%ai", "abc123"],
                ["git", "log", "-1", "--format=%ai", "def456"],
            ],
        )

    def test_sorted_branch_counts_print_lowest_count_first(self):
        with patch.object(gcount_branch, "get_remote_branches", return_value=["origin/a", "origin/b"]):
            with patch.object(gcount_branch, "count_commits", side_effect=["10", "2"]):
                with patch("builtins.print") as print_mock:
                    gcount_branch.count_commits_in_branch_and_sort()

        self.assertEqual(
            [call.args[0] for call in print_mock.call_args_list],
            ["origin/b: 2", "origin/a: 10"],
        )


if __name__ == "__main__":
    unittest.main()
