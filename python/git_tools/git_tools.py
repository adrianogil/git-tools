import subprocess
from datetime import datetime


def get_commit_date(repo_dir, ref):
    get_commit_date_cmd = "git show -s --format=%ci " + ref
    get_commit_date_output = subprocess.check_output(get_commit_date_cmd, shell=True)
    get_commit_date_output = get_commit_date_output.decode("utf8")
    get_commit_date_output = get_commit_date_output.strip()

    commit_date = datetime.strptime(get_commit_date_output[:-9], "%Y-%m-%d %H:%M")

    return commit_date
