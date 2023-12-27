# gtool gt-branches-fz: List branches and select one
function gt-branches-fz()
{
    if [[ $(git branch -r | grep -v "/HEAD " | wc -l) -le 1 ]]; then
        git branch -r | grep -v "/HEAD " | cut -c3- | head -1
    else
        git branch -r | grep -v "/HEAD " | cut -c3- | default-fuzzy-finder
    fi

}
alias gbk='gt-branches-fz'

# gtool gt-branches-origin-fz: List branches from origin and select one
function gt-branches-origin-fz()
{
    complete_branch_name=$(gt-branches-fz)
    only_branch_name=$(python3 -m gittools.cli.removeremotename ${complete_branch_name})
    echo ${only_branch_name}
}
alias gbko='gt-branches-origin-fz'

# gtool gt-branch-delete: Delete a target branch (local and remotely)
function gt-branch-delete()
{
    if [ -z "$1" ]
    then
        target_branch=$(gbko)
    else
        target_branch=$1
    fi

    if [ -z "$target_branch" ]
    then
        echo "Branch to be deleted:"
        read target_branch
    fi

    if [ -z "$target_branch" ]
    then
          echo "No branch selected"
    else
          git push origin :${target_branch}
        git branch -d ${target_branch}
    fi
}

# gtool gt-branch-set-upstream: set branch upstream
function gt-branch-set-upstream()
{
    target_upstream_remote_branch=$1

    if [ -z "$target_upstream_remote_branch" ]
    then
        target_upstream_remote_branch=$(gbk)
    fi

    git branch --set-upstream-to=${target_upstream_remote_branch}
}
alias gbupstream='gt-branch-set-upstream'

alias gbranch='git branch'
