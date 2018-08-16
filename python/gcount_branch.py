import sys, subprocess

import utils


def count_commits_in_branch(args=[], extra_args=[]):
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

            extra_info = ""

            if '-t' in extra_args:
                first_commit = subprocess.check_output("git rev-list --max-parents=0 HEAD --abbrev-commit", shell=True)
                first_commit = first_commit.decode("utf8").strip()

                last_commit = subprocess.check_output("git rev-list HEAD --abbrev-commit -1", shell=True)
                last_commit = last_commit.decode("utf8").strip()

                first_commit_date = subprocess.check_output("git log -1 --format=\%ai " + first_commit, shell=True)
                first_commit_date = first_commit_date.decode("utf8").strip()

                last_commit_date = subprocess.check_output("git log -1 --format=\%ai " + last_commit, shell=True)
                last_commit_date = last_commit_date.decode("utf8").strip()

                extra_info = '[' + first_commit_date + ' - ' + last_commit_date + ']' 


            print(b + ": " + total_commits + ' commits ' + extra_info)
        except:
            pass

def count_commits_in_branch_and_sort(args=[], extra_args=[]):
    branches = subprocess.check_output("git branch -r ", shell=True)
    branches = branches.decode("utf8").strip().split('\n')

    remote_branches = []
    for b in branches:
        if not '->' in b:
            remote_branches.append(b.strip())

    branches_count = []

    for b in remote_branches:
        try:
            total_commits = subprocess.check_output("git log --oneline --graph " + b + " | wc -l", shell=True)
            total_commits = total_commits.decode("utf8").strip()

            branches_count.append((b,total_commits))
            # print(b + ": " + total_commits)
        except:
            pass

    def get_key(item):
        return int(item[1])

    sorted(branches_count, key=get_key)

    for b in branches_count:
        print(b[0] + ": " + b[1])

def count_commits_in_branch_and_reversesort(args=[], extra_args=[]):
    branches = subprocess.check_output("git branch -r ", shell=True)
    branches = branches.decode("utf8").strip().split('\n')

    remote_branches = []
    for b in branches:
        if not '->' in b:
            remote_branches.append(b.strip())

    branches_count = []

    for b in remote_branches:
        try:
            total_commits = subprocess.check_output("git log --oneline --graph " + b + " | wc -l", shell=True)
            total_commits = total_commits.decode("utf8").strip()

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

args = parse_arguments()
parse_commands(args)