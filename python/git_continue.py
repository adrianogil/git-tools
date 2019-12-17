
from git_tools import git_tools
import subprocess


git_status = git_tools.get_status()

next_command = None
if "git cherry-pick" in git_status:
    next_command = "git cherry-pick --continue"
elif "git rebase" in git_status:
    next_command = "git rebase --continue"

if next_command is not None:
    git_continue_cmd = next_command
    git_continue_output = subprocess.check_output(git_continue_cmd, shell=True)
    git_continue_output = git_continue_output.strip()
