
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
