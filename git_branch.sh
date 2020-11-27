

function gt-delete-branch()
{
    if [ -z "$1" ]
    then
        target_branch=$(gbko)
    else
        target_branch=$1
    fi

    echo "Deleting branch "${target_branch}

    git push origin :${target_branch}
    git branch -d ${target_branch}
}
