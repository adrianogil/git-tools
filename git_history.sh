
# gtool git-hist: Show commits history
alias git-hist="git log --pretty=format:'%C(red)%h%Creset %C(cyan)%ad%Creset | %s%C(magenta)%d%Creset [%C(blue)%an%Creset]' --graph --date=short"

alias gh='git-hist'
alias gha='git-hist --all '
alias gha-reflog='gh --decorate `git reflog | cut -d " " -f 1`'

alias gh10='gh -10'

alias gtoday='gh --since="1am"'

export GIT_TOOLS_TRACKING_JSON="${GIT_TOOLS_DIR}/.gitdata"

alias gh-changes='python3 -m gittools.history.changes'

# gtool gt-tracking-update: Track commits updates on branches
alias gt-tracking-update='python3 -m gittools.commits.tracking.update'

# gtool gt-hist-target-sk
function gt-hist-target-sk()
{
    target_ref=$(git branch -a | cut -c3- | sk)

    gh ${target_ref}
}


function gt-hist-pick-commit()
{
    target_commit=$(gh | sk | cut -c3- | awk '{print $1}')
    echo ${target_commit} | pbcopy
    echo ${target_commit}
}

# gtool gt-hist-cp-hash
function gt-hist-cp-hash()
{
    echo "Search for Hash"

    target_commit=$(gh | sk | cut -c3- | awk '{print $1}')

    # Copy hash
    echo "Found hash: "$target_commit
    echo "Commit:"
    gh -1 $target_commit
}

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
      --reverse \
      --decorate \
      --pretty=tformat:"%Cblue %h %Creset %<(25)%ci %C(auto)%d%Creset %s [%C(blue)%an%Creset]"
}

alias gh-update="python3 $GIT_TOOLS_DIR/python/git_update_track.py"

function gfunction()
{
    function_name=$1
    file_name=$2

    git log -L :$function_name:$file_name
}

# gtool gh-new-files: Log of commits in which files were added
function gw-new-files()
{
    if [ -z "$1" ]
    then
        echo "Add params to log: (ex: *.js) "
        read log_params
    else
        log_params=$1
    fi

    git whatchanged --diff-filter=A ${log_params}
}

