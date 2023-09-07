# Utilities that creates or edit commits


# gtool gt-commit: Create a new commit for author 'adrianogil.san@gmail.com'
function gt-commit()
{
    # Commit as Adriano Gil (personal email)
    git commit --author='Adriano Gil <adrianogil.san@gmail.com>'
}

# gtool gt-squash: Squash last N commits
function gt-squash() {
    N=$1
    MSG=$2

    if [[ -z "$N" ]]; then
        read -p "Enter the number of commits to squash: " N
    fi

    if [[ -z "$N" || "$N" -le 0 ]]; then
        echo "Invalid number of commits: $N"
        return 1
    fi

    # Get the last commit message if no message is provided
    if [[ -z "$MSG" ]]; then
        read -p "Enter the commit message [leave empty to use last commit's message]: " MSG
        if [[ -z "$MSG" ]]; then
          MSG=$(git log --format=%B -n 1 HEAD~$((N-1)))
        fi
    fi

    # Decrement N by 1 because we want to keep the earliest commit
    ((N--))

    git reset --soft HEAD~"$N" && git commit --amend -m "$MSG"
}