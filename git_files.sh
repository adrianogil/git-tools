
# gtool gt-file-previous-version
function gt-file-previous-version()
{
    if [ -z "$1" ]
    then
        target_commit=$(gt-hist-pick-commit)
    else
        target_commit=$1
    fi

    target_file=$(git diff-tree --no-commit-id --name-only -r ${target_commit} | sk)

    echo "Let's see previous version of "${target_file}" in ref "${target_commit}

    git show ${target_commit}:${target_file}
}

# gtool gt-file-previous-version
function gt-file-history()
{
    if [ -z "$1" ]
    then
        target_file=$(find . -not -path '*/\.*' | sk | cut -c3-)
    else
        target_file=$1
    fi

    gh ${target_file}
}

# gtool gt-file-previous-version
function gt-file-history-version()
{
    if [ -z "$1" ]
    then
        target_file=$(find . -not -path '*/\.*' | sk | cut -c3-)
    else
        target_file=$1
    fi

    target_commit=$(gh ${target_file} | sk | cut -c3- | awk '{print $1}')

    echo "Let's see previous version of "${target_file}" in ref "${target_commit}

    git show ${target_commit}:${target_file}
}
