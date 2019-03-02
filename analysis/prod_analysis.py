import sys, os
import subprocess
from git_tools import git_tools
import matplotlib.pylab as pylab

current_dir = os.getcwd()

authors_data = {}

def commit_analysis(commit_hash, initial_date):
    # print("commit: " + commit_hash)

    author_name_cmd = "git log -1 --pretty=format:'%an' " + commit_hash
    author_name_output = subprocess.check_output(author_name_cmd, shell=True)
    author_name_output = author_name_output.decode("utf8")
    author_name_output = author_name_output.strip()

    author_name = author_name_output

    commit_data = {}

    # total_line_changed_cmd = "git log " + commit_hash + " -1 --pretty=tformat: --numstat | awk '{ loc += $1 + $2 } END { printf \"%s\", loc }'"
    # total_line_changed_output = subprocess.check_output(total_line_changed_cmd, shell=True)
    # total_line_changed_output = total_line_changed_output.decode("utf8")
    # total_line_changed_output = total_line_changed_output.strip()

    # commit_data['commit_size'] = int(total_line_changed_output)
    date_diff = (git_tools.get_commit_date(current_dir, commit_hash) - initial_date)
    commit_data['mins'] = date_diff.seconds / 60.0 + date_diff.days * 24 * 60

    # print(str(git_tools.get_commit_date(current_dir, commit_hash) - initial_date))
    # print(str(git_tools.get_commit_date(current_dir, commit_hash)))
    # print(str(initial_date))

    if author_name in authors_data:
        authors_data[author_name].append(commit_data)
    else:
        authors_data[author_name] = [commit_data]


def plot_repo_data(repo_data):

    colors = ['tab:blue', 'tab:orange', 'tab:green', 'tab:red', 'tab:purple', 'tab:brown', 'tab:pink', 'tab:gray', 'tab:olive', 'tab:cyan', "xkcd:crimson", "xkcd:lavender"]
    cindex = 0
    for author in repo_data.keys():
        days = []
        commit_size = []

        total_size = 0

        repo_data[author] = sorted(repo_data[author], key=lambda x: x['mins'], reverse=False)

        for c in repo_data[author]:
            # total_size += c['commit_size']
            total_size += 1
            days.append(c['mins'])
            commit_size.append(total_size)

        pylab.plot(days, commit_size, '-o', color=colors[cindex % len(colors)], label=author)
        cindex += 1

    pylab.legend(loc='upper left')
    pylab.show()


if __name__ == "__main__":
    # print(str(sys.argv))

    git_flags = ""
    if len(sys.argv) > 1:
        for a in range(1, len(sys.argv)):
            git_flags += sys.argv[a] + " "
    else:
        git_flags = "HEAD"

    git_hashes_cmd = "git rev-list " + git_flags

    print(git_hashes_cmd)

    git_hashes_output = subprocess.check_output(git_hashes_cmd, shell=True)
    git_hashes_output = git_hashes_output.decode("utf8")
    git_hashes_output = git_hashes_output.strip()

    git_hashes = git_hashes_output.split("\n")

    initial_date = git_tools.get_commit_date(current_dir, git_hashes[-1])

    for h in reversed(git_hashes):
        commit_analysis(h, initial_date)

    plot_repo_data(authors_data)
