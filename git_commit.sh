# Utilities that creates or edit commits

# gtool gt-pop-last-commits: Pop the last N commits
function gt-pop-last-commits()
{
    target_number_commits=$1
    if [ -z "$target_number_commits" ]
    then
        read -p "Enter the number of commits to pop: " target_number_commits
    fi

    if [ -z "$target_number_commits" ]
    then
        echo "Invalid number of commits: $target_number_commits"
        return 1
    fi

    git reset --hard HEAD~$target_number_commits
}
alias gpop='gt-pop-last-commits'

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

# gtool gt-squash-until: Squash until a specific commit
function gt_squash_until()
{
    target_commit=$1
    if [ -z "$target_commit" ]
    then
        read -p "Enter the target commit (hash or ref): " target_commit
    fi

    if [ -z "$target_commit" ]
    then
        echo "Invalid target commit: $target_commit"
        return 1
    fi

    git reset --soft $target_commit && git commit --amend --no-verify
}
alias gt-squash-until=gt_squash_until

# gtool gt-zip-repo: Zips a target commit
function gt-zip-repo()
{
    zip_name=$1

    if [ -z "$zip_name" ]
    then
        zip_name=$(basename $(git rev-parse --show-toplevel))
    fi

    if [ -z "$2" ]
    then
        target_ref=HEAD
    else
        target_ref=$2
    fi

    echo "Zipping repository to $zip_name.zip"
    git archive -o ${zip_name}.zip ${target_ref}
}

# gtool gt-pick-commits: Reorder commits
function gt-pick-commits() {
    python3 -m gittools.pick $*
}
alias gpick='gt-pick-commits'

# gtool gt-commit-generate-date-msg: Generate commit message
function gt-commit-generate-date-msg()
{
    commit_message="Updated changes at "$(date +%F-%H:%M)
    echo "Generating commit: "$commit_message
    gc -m "$commit_message"
}
alias gcm="gt-commit-generate-date-msg"

alias gc='git commit '
alias gm='git commit -m '
alias gca='git commit --amend '
alias gcg="git commit --author='Adriano Gil <adrianogil.san@gmail.com>'"
alias git-author-update="gc --amend --author='Adriano Gil <adrianogil.san@gmail.com>'"