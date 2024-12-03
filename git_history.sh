
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

# gtool gt-hist-target-fz: search for a target and shows its git logs
function gt-hist-target-fz()
{
    target_ref=$(git branch -a | cut -c3- | default-fuzzy-finder)

    gh ${target_ref}
}

# gtool gt-hist-pick-commit: search for a commit and copy the hash to clipboard
function gt-hist-pick-commit()
{
    target_commit=$(gh $1 | default-fuzzy-finder | cut -c3- | awk '{print $1}')
    echo ${target_commit} | copy-text-to-clipboard
    echo ${target_commit}
}
alias gget="gt-hist-pick-commit"

function gt-hist-reflog-pick-commit()
{
    target_commit=$(gflog | default-fuzzy-finder | awk '{print $1}')
    echo ${target_commit} | copy-text-to-clipboard
    echo ${target_commit}
}
alias gget-flog="gt-hist-reflog-pick-commit"

# gtool gt-hist-tag: search for a tag and shows its git logs
function gt-hist-tag()
{
    target_tag=$(git tag -l | default-fuzzy-finder)
    gh ${target_tag}
}
alias gh-tags="gt-hist-tag"

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

# gtool gt-hist-range: Show history of commits between two refs
function gt-hist-range()
{
    ref1=$1
    ref2=$2

    if [ -z "$ref1" ]
    then
        echo "> First ref (HEAD): "
        read ref1
    fi
    if [ -z "$ref1" ]
    then
        ref1=$(gha | default-fuzzy-finder | cut -c3- | awk '{print $1}')
    fi
    if [ -z "$ref1" ]
    then
        ref1="HEAD"
    fi
    echo "First ref: "$ref1

    if [ -z "$ref2" ]
    then
        echo "> Second ref (HEAD): "
        read ref2
    fi
    if [ -z "$ref2" ]
    then
        ref2=$(gha | default-fuzzy-finder | cut -c3- | awk '{print $1}')
    fi
    if [ -z "$ref2" ]
    then
        ref2="HEAD"
    fi
    echo "Second ref: "$ref2
    echo "## Commit History:"

    git log --pretty=format:'%C(red)%h%Creset %C(cyan)%ad%Creset | %s%C(magenta)%d%Creset [%C(blue)%an%Creset]' --date=short --reverse ${ref1}...${ref2}
}
alias ghs="gt-hist-range"

# gtool gt-history-count: count commits in current ref
function gt-history-count()
{
    total_commits=$(gh $1 | wc -l)
    echo 'There are'$total_commits' commits in current local branch'
}
alias gcount="gt-history-count"

# gtool gt-history-count-today: count commits made today in current ref
function gt-history-count-today()
{
    total_commits=$(gh  --since="1am" | wc -l)
    echo 'Today, there are'$total_commits' commits in current local branch'
}
alias gcount-today="gt-history-count-today"

# gtool gt-history-count-commits: count commits between two refs
function gt-history-count-commits()
{
    old_commit=$1
    new_commit=$2

    number_commits=$(($(git rev-list --count $old_commit..$new_commit) - 1))

    echo 'There are '$number_commits' commits of difference between revisions'
}
alias gcount-commits="gt-history-count-commits"

# gtool gt-history-log-count-from-head: Show the history of changes
function gt-history-log-count-from-head()
{
    # See https://www.commandlinefu.com/commands/view/15063/list-offsets-from-head-with-git-log
    o=0
    git log --oneline | while read l; do printf "%+9s %s\n" "HEAD~${o}" "$l"; o=$(($o+1)); done | less
}
alias gh-log-count="gt-history-log-count-from-head"

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

# gtool gt-reflog: Show reflog
function gt-reflog()
{
    git reflog --format='%C(auto)%h %<|(17)%gd %C(blue)%ci%C(reset) %s' $*
}
alias gflog="gt-reflog"

# gtool gt-reflog-pick: Pick a commit from reflog
function gt-reflog-pick()
{
    gflog $* | default-fuzzy-finder | awk '{print $1}' |  copy-clipboard-function
}
alias gflog-pick="gt-reflog-pick"

# gtool gt-jira-commit-id: Get JIRA commit ID
function gt-jira-commit-id()
{
    git log -1 --pretty=%B $1 | grep -oE "[A-Z]+-[0-9]+" | head -1
}
alias gjira="gt-jira-commit-id"
