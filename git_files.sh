
# gtool gt-file-previous-version: select a commit and then a file to see its previous version
function gt-file-previous-version()
{
    if [ -z "$1" ]
    then
        target_commit=$(gt-hist-pick-commit)
    else
        target_commit=$1
    fi

    target_file=$(git diff-tree --no-commit-id --name-only -r ${target_commit} | default-fuzzy-finder)

    echo "Let's see previous version of "${target_file}" in ref "${target_commit}

    git show ${target_commit}:${target_file}
}

# gtool gt-file-history: see change log for a specific file
function gt-file-history()
{
    if [ -z "$1" ]
    then
        target_file=$(find . -not -path '*/\.*' | default-fuzzy-finder | cut -c3-)
    else
        target_file=$1
    fi

    gh ${target_file}
}

# gtool gt-file-history-version: select a file and then a commit to see its previous version
function gt-file-history-version()
{
    if [ -z "$1" ]
    then
        target_file=$(find . -not -path '*/\.*' | default-fuzzy-finder | cut -c3-)
    else
        target_file=$1
    fi

    target_commit=$(gh ${target_file} | default-fuzzy-finder | cut -c3- | awk '{print $1}')

    echo "Let's see previous version of "${target_file}" in ref "${target_commit}"\n"

    git show ${target_commit}:${target_file}
}

# gtool gt-file-checkout-version: change a target file to its version in a target commit
function gt-file-checkout-version()
{
    if [ -z "$1" ]
    then
        target_file=$(find . -not -path '*/\.*' | default-fuzzy-finder | cut -c3-)
    else
        target_file=$1
    fi

    if [ -z "$2" ]
    then
        target_commit=$(gh ${target_file} | default-fuzzy-finder | cut -c3- | awk '{print $1}')
    else
        target_commit=$2
    fi

    echo "Change file "${target_file}" to its previous version in ref "${target_commit}"\n"

    git checkout ${target_commit} ${target_file}
}
