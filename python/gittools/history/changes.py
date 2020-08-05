from gittools.clitools import run_cmd


hashes = run_cmd('git log -2 --pretty=format:"%h"')
hashes = hashes.split("\n")

for git_hash in hashes:
    git_hash = git_hash.strip()
    hash_info = run_cmd('git log --name-status --oneline -1 %s' % (git_hash,))
    print(hash_info)
