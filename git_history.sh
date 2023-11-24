
# gtool git-hist: Show commits history
alias git-hist="git log --pretty=format:'%C(red)%h%Creset %C(cyan)%ad%Creset | %s%C(magenta)%d%Creset [%C(blue)%an%Creset]' --graph --date=short"

alias gh='git-hist'
alias gha='git-hist --all '
alias gha-reflog='gh --decorate `git reflog | cut -d " " -f 1`'

alias gh10='gh -10'

alias gtoday='gh --since="1am"'

export GIT_TOOLS_TRACKING_JSON="${GIT_TOOLS_DIR}/.gitdata"

#gtool gh-changes: see summarized changes of each commit
alias gh-changes='python3 -m gittools.history.changes'

# gtool gt-tracking-update: Track commits updates on branches
alias gt-tracking-update='python3 -m gittools.commits.tracking.update'

# gtool gt-hist-target-fz
function gt-hist-target-fz()
{
    target_ref=$(git branch -a | cut -c3- | default-fuzzy-finder)

    gh ${target_ref}
}

function gt-hist-pick-commit()
{
    target_commit=$(gh | default-fuzzy-finder | cut -c3- | awk '{print $1}')
    echo ${target_commit} | pbcopy
    echo ${target_commit}
}

# gtool gt-hist-tag: search for a tag and shows its git logs
function gt-hist-tag()
{
    target_tag=$(git tag -l | default-fuzzy-finder)
    gh ${target_tag}
}
alias gh-tags="gt-hist-tag"

# gtool gt-hist-cp-hash
function gt-hist-cp-hash()
{
    echo "Search for Hash"

    target_commit=$(gha | default-fuzzy-finder | cut -c3- | awk '{print $1}')

    # Copy hash
    echo "Found hash: "$target_commit
    echo "Commit:"
    gh -1 $target_commit
}

# gtool gt-hist-find-string: Find string in all commit history
function gt-hist-find-string()
{
    if [ -z "$1" ]
    then
        read -p "Target string: " word
    else
        target_string=$1
    fi

    git log -S ${target_string} --source --all
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

# gtool gt-branches: Show the history of changes for each branch
function gt-history-by-branches()
{
    # https://stackoverflow.com/questions/47142799/git-list-all-branches-tags-and-remotes-with-commit-hash-and-date
    git --no-pager log \
      --simplify-by-decoration \
      --tags --branches --remotes \
      --date-order \
      --reverse \
      --decorate \
      --pretty=tformat:"%Cblue %h %Creset %<(25)%ci %C(auto)%d%Creset %s [%C(blue)%an%Creset]" $@
}
alias gh-branches="gt-history-by-branches"

alias gh-update="python3 $GIT_TOOLS_DIR/python/git_update_track.py"

# gtool gt-function: Show the history of changes of a given function
function gt-function()
{
    if [ -z "$1" ]
    then
        echo "Type function name: "
        read function_name
    else
        function_name=$1
    fi

    if [ -z "$2" ]
    then
        file_name=$(find . -type f -not -path "./.git/*" | default-fuzzy-finder)
    else
        file_name=$2
    fi

    git log -L :$function_name:$file_name
}
alias gfunction="gt-function"

# gtool gw-new-files: Log of commits in which files were added
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

# gtool gw-file: Log of commits in which a given file is included
function gw-file()
{
    target_file=$1

    git whatchanged -- ${target_file}
}

alias gh-diff="python3 -m gittools.history.commitsdiff"
