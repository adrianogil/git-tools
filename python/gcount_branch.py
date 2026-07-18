import sys, subprocess

import utils


def _decode_output(output):
    return output.decode("utf8").strip()


def _run_git_command(git_args):
    return _decode_output(subprocess.check_output(["git"] + git_args))


def get_remote_branches():
    branches = _run_git_command(["branch", "-r"]).split('\n')

    remote_branches = []
    for b in branches:
        if b.strip() and '->' not in b:
            remote_branches.append(b.strip())

    return remote_branches


def count_commits(branch):
    commits = _run_git_command(["log", "--oneline", "--graph", branch]).splitlines()
    return str(len([commit for commit in commits if commit.strip()]))


def get_first_commit():
    return _run_git_command(["rev-list", "--max-parents=0", "HEAD", "--abbrev-commit"])


def get_last_commit():
    return _run_git_command(["rev-list", "HEAD", "--abbrev-commit", "-1"])


def get_commit_date(commit):
    return _run_git_command(["log", "-1", "--format=%ai", commit])


def count_commits_in_branch(args=[], extra_args=[]):
    remote_branches = get_remote_branches()

    # print(remote_branches)

    for b in remote_branches:
        try:
            total_commits = count_commits(b)

            extra_info = ""

            if '-t' in extra_args:
                first_commit = get_first_commit()
                last_commit = get_last_commit()
                first_commit_date = get_commit_date(first_commit)
                last_commit_date = get_commit_date(last_commit)

                extra_info = '[' + first_commit_date + ' - ' + last_commit_date + ']' 


            print(b + ": " + total_commits + ' commits ' + extra_info)
        except:
            pass

def count_commits_in_branch_and_sort(args=[], extra_args=[]):
    remote_branches = get_remote_branches()

    branches_count = []

    for b in remote_branches:
        try:
            total_commits = count_commits(b)

            branches_count.append((b,total_commits))
            # print(b + ": " + total_commits)
        except:
            pass

    def get_key(item):
        return int(item[1])

    branches_count = sorted(branches_count, key=get_key)

    for b in branches_count:
        print(b[0] + ": " + b[1])

def count_commits_in_branch_and_reversesort(args=[], extra_args=[]):
    remote_branches = get_remote_branches()

    branches_count = []

    for b in remote_branches:
        try:
            total_commits = count_commits(b)

            branches_count.append((b,total_commits))
            # print(b + ": " + total_commits)
        except:
            pass

    def get_key(item):
        return int(item[1])

    branches_count = sorted(branches_count, key=get_key, reverse=True)

    for b in branches_count:
        print(b[0] + ": " + b[1])


def handle_no_args():
    # print("Default mode\n")
    count_commits_in_branch()

commands_parse = {
    '-rs'           : count_commits_in_branch_and_reversesort,
    '-s'           : count_commits_in_branch_and_sort,
    'no-args'      : handle_no_args,
}

def parse_arguments():

    args = {}

    last_key = ''

    if len(sys.argv) == 1:
        handle_no_args()
        return None

    for i in range(1, len(sys.argv)):
        a = sys.argv[i]
        if a[0] == '-' and not utils.is_float(a):
            last_key = a
            args[a] = []
        elif last_key != '':
            arg_values = args[last_key]
            arg_values.append(a)
            args[last_key] = arg_values

    return args

def parse_commands(args):
    if args is None:
        return

    parse_count = 0

    # print('DEBUG: Parsing args: ' + str(args))
    for a in args:
        if a in commands_parse:
            commands_parse[a](args[a], args)
            parse_count = parse_count + 1

    if parse_count == 0:
        count_commits_in_branch([], args)

if __name__ == "__main__":
    args = parse_arguments()
    parse_commands(args)
