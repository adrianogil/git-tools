

alias git-hist="git log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short"

alias gh='git-hist'
alias gha='git-hist --all '
alias gha-reflog='gh --decorate `git reflog | cut -d " " -f 1`'

alias gh10='gh -10'

alias gtoday='gh --since="1am"'

function ghs()
{
    gh $1 $2 | less
}

# See https://www.commandlinefu.com/commands/view/15063/list-offsets-from-head-with-git-log.
function gh-count-from-head()
{
    o=0
    git log --oneline | while read l; do printf "%+9s %s\n" "HEAD~${o}" "$l"; o=$(($o+1)); done | less
}

# https://stackoverflow.com/questions/47142799/git-list-all-branches-tags-and-remotes-with-commit-hash-and-date
function gh-branches()
{
    git --no-pager log \
      --simplify-by-decoration \
      --tags --branches --remotes \
      --date-order \
      --decorate \
      --pretty=tformat:"%Cblue %h %Creset %<(25)%ci %C(auto)%d%Creset %s"
}

function gh-test()
{
    git --no-pager log \
      --simplify-by-decoration \
      --tags --branches --remotes \
      --date-order \
      --decorate \
      --pretty=tformat:"%Cblue %h %C(auto)%d%Creset"
}

alias gh-update="python3 $GIT_TOOLS_DIR/python/git_update_track.py"