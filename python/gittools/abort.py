""" Module responsible for ease abort operation"""
from . import gittools
from . import clitools


git_status = gittools.get_status()

next_command = None
if "git cherry-pick" in git_status:
    next_command = "git cherry-pick --abort"
elif "git rebase" in git_status:
    next_command = "git rebase --abort"

if next_command is not None:
    git_continue_output = clitools.run_cmd(next_command)
