import sys, subprocess

# remote_name = sys.argv[1]

branches = subprocess.check_output("git branch -r ", shell=True)
branches = branches.decode("utf8").strip().split('\n')

remote_branches = []
for b in branches:
    if not '->' in b:
        remote_branches.append(b.strip())

# print(remote_branches)

for b in remote_branches:
    try:
        total_commits = subprocess.check_output("git log --oneline --graph " + b + " | wc -l", shell=True)
        total_commits = total_commits.decode("utf8").strip()

        print(b + ": " + total_commits)
    except:
        pass