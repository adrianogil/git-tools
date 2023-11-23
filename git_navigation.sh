
# gtool gt-navigate-to-local-branch: Change current branch
function gt-navigate-to-local-branch()
{
    target_branch=$(git branch -a | cut -c3- | default-fuzzy-finder)
    echo "Let's checkout to branch: "$target_branch
    git checkout ${target_branch}
}
alias gt-go-local-branch="gt-navigate-to-local-branch"
alias ggo="gt-navigate-to-local-branch"
