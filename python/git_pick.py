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

max_commit_backtrack = 0

for i in range(1, len(sys.argv)):
    if is_int(sys.argv[i]):
        commits_order_number = int(sys.argv[i])
        if commits_order_number > max_commit_backtrack:
            max_commit_backtrack = commits_order_number

        # Get ref for each commit
        commit = subprocess.check_output("git rev-parse --short HEAD~" + sys.argv[i], shell=True)
        commit = commit.decode("utf8").strip()
        commits_order.append(commit)
        print('debug: ' + commit)

max_commit_backtrack = max_commit_backtrack + 1
subprocess.check_output("git reset --hard HEAD~" + str(max_commit_backtrack), shell=True)

print('max_commit_backtrack: ' + str(max_commit_backtrack))

# Apply each ref in the correct order
for c in reversed(commits_order):
    subprocess.check_output("git cherry-pick " + c, shell=True)