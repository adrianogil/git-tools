
# Rebase-related aliases
alias gb='git rebase'
alias gbc='git rebase --continue'

# gtool gt-rebase: rebase from a remote branch
function gt-rebase()
{
    target_branch=$(gbk)
    echo "Let's rebase branch: "$target_branch
    git rebase ${target_branch}
}
alias gb-fz="gt-rebase"

# gtool gt-rebase-local-branch: rebase from a local branch
function gt-rebase-local-branch()
{
    target_branch=$(git branch -a | cut -c3- | sed 's/origin//g' | cut -c2- | default-fuzzy-finder)
    echo "Let's merge branch: "$target_branch
    git rebase ${target_branch}
}

# gtool gt-merge: merge from a remote branch
function gt-merge()
{
    target_branch=$(gbk)
    echo "Let's merge branch: "$target_branch
    git merge ${target_branch}
}

# gtool gt-merge-local-branch: merge from a local branch
function gt-merge-local-branch()
{
    target_branch=$(git branch -a | cut -c3- | default-fuzzy-finder)
    echo "Let's merge branch: "$target_branch
    git merge ${target_branch}
}
