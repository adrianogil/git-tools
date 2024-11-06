# gtool gt-clone: git clone and enter repo directory
function gt-clone()
{
    # git clone and enter repo directory
    git_url=$1

    if [ -z "$2" ]
    then
        git_repo=$(basename $git_url)
        git_repo=${git_repo%.*}
        git clone $git_url
        cd $git_repo
    else
        git_repo=$2
        git clone $git_url $git_repo
        cd $git_repo
    fi
}
alias gol="gt-clone"

# gtool gt-clone-shallow: git clone with depth 1 and enter repo directory
function gt-clone-shallow()
{
     # git clone with depth 1 and enter repo directory
    git_url=$1
    git_repo=$(basename $git_url)
    git_repo=${git_repo%.*}

    git clone $git_url --depth 1
    cd $git_repo
}
alias golp="gt-clone-shallow"
