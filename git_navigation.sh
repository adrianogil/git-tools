function ggo()
{
    target_branch=$(git branch -a | cut -c3- | sk)
    echo "Let's checkout to branch: "$target_branch
    git checkout ${target_branch}
}
alias gt-nav-go="ggo"

