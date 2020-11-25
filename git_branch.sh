

function gt-branch-delete()
{
    if [ -z "$1" ]
    then
        target_branch=$(gbko)
    else
        target_branch=$1
    fi

    git push origin :${target_branch}
}
