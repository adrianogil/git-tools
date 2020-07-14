""" """
from gittools import clitools


branches = clitools.run_cmd("git branch -r ")
branches = branches.split('\n')

remote_branches = []
for b in branches:
    if '->' not in b:
        remote_branches.append(b.strip())

print(remote_branches)

for b in remote_branches:
    try:
        git_hash = clitools.run_cmd("git rev-parse " + b)
        print("%s - %s" % (b, git_hash))
    except Exception as exception:
        print("error" + str(exception))
