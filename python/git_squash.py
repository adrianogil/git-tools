#!/usr/bin/env python3
import sys
import subprocess

def is_int(s):
    try:
        int(s)
        return True
    except ValueError:
        pass

    return False

commits_order = []

min_commit_backtrack = subprocess.check_output("git log --oneline | wc -l", shell=True)
min_commit_backtrack = min_commit_backtrack.decode("utf8").strip()
max_commit_backtrack = 0

for i in range(1, len(sys.argv)):
    if is_int(sys.argv[i]):
        commits_order_number = int(sys.argv[i])
        if commits_order_number > max_commit_backtrack:
            max_commit_backtrack = commits_order_number
        if commits_order_number < min_commit_backtrack:
            min_commit_backtrack = commits_order_number

        commit = subprocess.check_output("git rev-parse --short HEAD~" + sys.argv[i], shell=True)
        commit = commit.decode("utf8").strip()
        commits_order.append(commit)
        print('debug: ' + commit)

max_commit_backtrack = max_commit_backtrack + 1

commits = []
for i in range(0, max_commit_backtrack):
    commit = subprocess.check_output("git rev-parse --short HEAD~" + str(i), shell=True)
    commit = commit.decode("utf8").strip()
    commits.append(commit)

if min_commit_backtrack > 0:
    subprocess.check_output("git reset --hard HEAD~" + str(min_commit_backtrack), shell=True)
subprocess.check_output("git reset HEAD~" + str(max_commit_backtrack), shell=True)

print('max_commit_backtrack: ' + str(max_commit_backtrack))

for c in range(0, len()):
    subprocess.check_output("git cherry-pick " + c, shell=True)

for c in reversed(commits_order):
    subprocess.check_output("git cherry-pick " + c, shell=True)