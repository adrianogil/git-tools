""" """
import datetime

from gittools import clitools
from gittools.commits import get_diverge_commits, get_total_commits
from gittools.config.root import  get_git_root

import json
import os


def update_tracking():
    current_path = os.getcwd()
    root_path = get_git_root(current_path)
    current_date = datetime.datetime.now().strftime("%Y-%m-%d-%H:%M:%S")

    tracking_json_path = os.environ["GIT_TOOLS_TRACKING_JSON"]
    tracking_branches_data = {}
    tracking_data = {
        root_path: tracking_branches_data
    }

    # Update tracking data according to saved JSON file
    if os.path.exists(tracking_json_path):
        with open(tracking_json_path, 'r') as json_file:
            tracking_data = json.load(json_file)
        if root_path in tracking_data:
            tracking_branches_data = tracking_data[root_path]

    # Get list of remote branches
    branches = clitools.run_cmd("git branch -r ")
    branches = branches.split('\n')

    remote_branches = []
    for b in branches:
        if '->' not in b:
            remote_branches.append(b.strip())

    # print(remote_branches) # For debug purposes

    current_hashes_by_branch = {}

    # Get current hash for each remote branch
    for remote_branch_name in remote_branches:
        try:
            git_hash = clitools.run_cmd("git rev-parse " + remote_branch_name)
            current_hashes_by_branch[remote_branch_name] = git_hash
        except Exception as exception:
            print("error" + str(exception))

    new_hashes_by_branch = {}
    last_hashes_by_branch = {}

    # Update tracking data
    for remote_branch_name in current_hashes_by_branch:
        current_hash = current_hashes_by_branch[remote_branch_name]

        tracking_branch_history = []
        if remote_branch_name in tracking_branches_data:
            tracking_branch_history = tracking_branches_data[remote_branch_name]

        # Check if hash is new in branch history
        if tracking_branch_history:
            last_branch_data = tracking_branch_history[-1]
            last_branch_hash = last_branch_data['hash']
            last_hashes_by_branch[remote_branch_name] = last_branch_hash
            if last_branch_hash == current_hash:
                continue

        new_hashes_by_branch[remote_branch_name] = current_hash
        # Add hash to branch history
        current_branch_data = {
            'date': current_date,
            'hash': current_hash
        }
        tracking_branch_history.append(current_branch_data)
        tracking_branches_data[remote_branch_name] = tracking_branch_history

    if new_hashes_by_branch:
        tracking_data[root_path] = tracking_branches_data

        print("Updates since last tracking:")
        for branch in new_hashes_by_branch:
            if branch not in last_hashes_by_branch or last_hashes_by_branch[branch] is None:
                print("%s - %s commits" % (branch, get_total_commits(new_hashes_by_branch[branch])))
            else:
                total_diverge = get_diverge_commits(new_hashes_by_branch[branch], last_hashes_by_branch[branch])
                print("%s - %s commits" % (branch, int(total_diverge) + 1))

        with open(tracking_json_path, 'w') as json_file:
            json.dump(tracking_data, json_file, indent=4)


if __name__ == '__main__':
    update_tracking()
