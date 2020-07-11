import gittools.clitools as clitools


def get_status():
    cmd = "git status"
    get_git_status_output = clitools.run_cmd(cmd)

    return get_git_status_output
