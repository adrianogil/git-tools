from subprocess import *
import subprocess

import os
import sys


def get_git_root(p):
    """Return None if p is not in a git repo, or the root of the repo if it is"""
    if call(["git", "branch"], stderr=STDOUT, stdout=open(os.devnull, 'w'), cwd=p) != 0:
        return None
    else:
        root = check_output(["git", "rev-parse", "--show-toplevel"], cwd=p)
        root = root.decode("utf8")
        root = root.strip()
        return root


if len(sys.argv) < 2:
    print("Error: you should provide a file to be ignored")
    exit()

target_file = sys.argv[1]
target_path = os.path.dirname(target_file)
git_repo = get_git_root(target_path)

print("Let's ignore file: " + target_file)

if git_repo is None:
    print("Error: file is not inside a valid git repo")
    exit()

add_to_gitignore_cmd = "echo '" + target_file[len(git_repo)+1:] + "' >> '" + git_repo + "/.gitignore'"
add_to_gitignore_output = subprocess.check_output(add_to_gitignore_cmd, shell=True)
add_to_gitignore_output = add_to_gitignore_output.strip()
