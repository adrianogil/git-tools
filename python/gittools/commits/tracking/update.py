""" """
from gittools import clitools
from gittools.commits import get_diverge_commits, get_total_commits

import json
import os


def update_tracking():
    current_path = os.getcwd()

    tracking_json_path = os.environ["GIT_TOOLS_TRACKING_JSON"]
    tracking_data = {
        current_path: []
    }
    tracking_hashes = []

    if os.path.exists(tracking_json_path):
        with open(tracking_json_path, 'r') as json_file:
            tracking_data = json.load(json_file)
        if current_path in tracking_data:
            tracking_hashes = tracking_data[current_path]

    branches = clitools.run_cmd("git branch -r ")
    branches = branches.split('\n')

    remote_branches = []
    for b in branches:
        if '->' not in b:
            remote_branches.append(b.strip())

    # print(remote_branches)

    hashes_by_branch = {}

    for b in remote_branches:
        try:
            git_hash = clitools.run_cmd("git rev-parse " + b)
            hashes_by_branch[b] = git_hash
        except Exception as exception:
            print("error" + str(exception))

    new_hashes_by_branch = {}
    last_hashes_by_branch = {}

    for branch1 in hashes_by_branch:
        new_hash = True
        last_hash = None

        for branches_update in reversed(tracking_hashes):
            for branch2 in branches_update:
                if branch1 == branch2:
                    last_hash = branches_update[branch2]
                    if branches_update[branch2] == hashes_by_branch[branch1]:
                        new_hash = False
                        break
            if not new_hash:
                break

        if new_hash:
            new_hashes_by_branch[branch1] = hashes_by_branch[branch1]
            last_hashes_by_branch[branch1] = last_hash
    if new_hashes_by_branch:
        tracking_hashes.append(new_hashes_by_branch)
        tracking_data[current_path] = tracking_hashes

        print("Updates since last tracking:")
        for branch in new_hashes_by_branch:
            if last_hashes_by_branch[branch] is None:
                print("%s - %s commits" % (branch, get_total_commits(new_hashes_by_branch[branch])))
            else:
                total_diverge = get_diverge_commits(new_hashes_by_branch[branch], last_hashes_by_branch[branch])
                print("%s - %s commits" % (branch, int(total_diverge) + 1))

        with open(tracking_json_path, 'w') as json_file:
            json.dump(tracking_data, json_file)


if __name__ == '__main__':
    update_tracking()
