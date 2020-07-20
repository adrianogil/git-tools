import gittools.clitools as clitools


def get_diverge_commits(ref1, ref2):
    get_diverge_commits_command = 'git log %s..%s' % (ref1, ref2) + ' --pretty=oneline | wc -l'
    diverge_commits = clitools.run_cmd(get_diverge_commits_command)

    return diverge_commits


def get_total_commits(ref1):
    get_diverge_commits_command = 'git log %s' % (ref1,) + ' --pretty=oneline | wc -l'
    diverge_commits = clitools.run_cmd(get_diverge_commits_command)

    return diverge_commits
