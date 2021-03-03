
# gtool gt-delete-branch: Delete a target branch (local and remotely)
function gt-delete-branch()
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
