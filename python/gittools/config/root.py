from subprocess import *

import os


def get_git_root(p):
    """Return None if p is not in a git repo, or the root of the repo if it is"""
    if call(["git", "branch"], stderr=STDOUT, stdout=open(os.devnull, 'w'), cwd=p) != 0:
        return None
    else:
        root = check_output(["git", "rev-parse", "--show-toplevel"], cwd=p)
        root = root.decode("utf8")
        root = root.strip()
        return root
