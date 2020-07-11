import git_tools.clitools as clitools
from datetime import datetime


def get_commit_date(repo_dir, ref):
    cmd = "git show -s --format=%ci " + ref
    commit_date_output = clitools.run_cmd(cmd)

    commit_date = datetime.strptime(commit_date_output[:-9], "%Y-%m-%d %H:%M")

    return commit_date


def get_commits_with(file=""):
    cmd = "git log --pretty=format:'%%h' %s" % (file,)
    get_hashes_output = clitools.run_cmd(cmd)

    hash_list = get_hashes_output.split("\n")

    return hash_list


def get_status():
    cmd = "git status"
    get_git_status_output = clitools.run_cmd(cmd)

    return get_git_status_output
