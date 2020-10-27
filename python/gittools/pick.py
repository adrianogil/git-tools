#!/usr/bin/env python3
from . import clitools

import sys


def is_int(s):
    try:
        int(s)
        return True
    except ValueError:
        pass

    return False


commits_order = []

max_commit_backtrack = 0

for i in range(1, len(sys.argv)):
    if is_int(sys.argv[i]):
        commits_order_number = int(sys.argv[i])
        if commits_order_number > max_commit_backtrack:
            max_commit_backtrack = commits_order_number

        # Get ref for each commit
        commit = clitools.run_cmd("git rev-parse --short HEAD~" + sys.argv[i])
        commits_order.append(commit)
        print('debug: ' + commit)

max_commit_backtrack = max_commit_backtrack + 1
clitools.run_cmd("git reset --hard HEAD~" + str(max_commit_backtrack))

print('max_commit_backtrack: ' + str(max_commit_backtrack))

# Apply each ref in the correct order
for c in reversed(commits_order):
    clitools.run_cmd("git cherry-pick " + c)
