from gittools.history.log import get_hash_log
from gittools.commits.commit import get_commit_files
import sys

hashes = get_hash_log(sys.argv[1:])

for git_hash in hashes:
    git_hash = git_hash.strip()
    commit_change_info = get_commit_files(ref=git_hash)
    # print(commit_change_info)

    commit_change_info = commit_change_info.split("\n")

    commit_info = commit_change_info[0].strip()

    commit_change = {
        "added": {
            "files": [],
            "by_extension": {}
        },
        "updated": {
            "files": [],
            "by_extension": {}
        }
    }

    files_added = []
    files_deleted = []
    files_updated = []

    for file_info in commit_change_info[1:]:
        file_info = file_info.strip()

        if file_info == "":
            continue

        if file_info[0] in ["M", "R"]:
            commit_change["updated"]["files"].append(file_info.split("\t")[1])
        elif file_info[0] == "A":
            commit_change["added"]["files"].append(file_info.split("\t")[1])

    # Added Files
    for file in commit_change["added"]["files"]:
        file_extension = file.strip().split(".")[-1]

        if file_extension not in commit_change["added"]["by_extension"]:
            commit_change["added"]["by_extension"][file_extension] = []
        commit_change["added"]["by_extension"][file_extension].append(file)
    msg_str = ""
    for extension in commit_change["added"]["by_extension"]:
        if msg_str == "":
            msg_str = "(Added: "
        else:
            msg_str += ", "
        msg_str += str(len(commit_change["added"]["by_extension"][extension])) + " " + extension
    if msg_str != "":
        msg_str += "; "

    # Updated Files:
    for file in commit_change["updated"]["files"]:
        file_extension = file.strip().split(".")[-1]

        if file_extension not in commit_change["updated"]["by_extension"]:
            commit_change["updated"]["by_extension"][file_extension] = []
        commit_change["updated"]["by_extension"][file_extension].append(file)
    update_msg_str = ""
    for extension in commit_change["updated"]["by_extension"]:
        if update_msg_str == "":
            update_msg_str = "Updated: "
        else:
            update_msg_str += ", "
        update_msg_str += str(len(commit_change["updated"]["by_extension"][extension])) + " " + extension
    # if update_msg_str != "":
    #     update_msg_str += ") "

    if msg_str == "":
        msg_str = "(" + update_msg_str + ")"
    else:
        msg_str = msg_str + update_msg_str + ")"

    if len(commit_info) > 60:
        commit_info = commit_info[:50] + "..."
    print(commit_info + " " + msg_str)
