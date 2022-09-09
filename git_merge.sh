
# Rebase-related aliases
alias gb='git rebase'
alias gbc='git rebase --continue'

# gtool gb-fz: rebase from a remote branch
alias gb-fz='git rebase $(gbk)'


function gt-rebase-local-branch()
{
    target_branch=$(git branch -a | cut -c3- | sed 's/origin//g' | cut -c2- | default-fuzzy-finder)
    echo "Let's merge branch: "$target_branch
    git rebase ${target_branch}
}

function gt-merge-branch()
{
    target_branch=$(git branch -a | cut -c3- | default-fuzzy-finder)
    echo "Let's merge branch: "$target_branch
    git merge ${target_branch}
}

