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

# gtool gt-clone-sparse: git clone with sparse checkout and enter repo directory
function gt-clone-sparse()
{
    local repository_url=$1
    local sparse_path=$2
    local target_branch=${3:-main}

    # Extract the repository name from the URL to use as the target directory
    local target_directory
    target_directory=$(basename -s .git "$repository_url")

    # Step 1: Initialize the target directory
    git init "$target_directory"
    cd "$target_directory" || exit

    # Step 2: Set the remote repository
    git remote add origin "$repository_url"

    # Step 3: Enable sparse checkout
    git config core.sparseCheckout true

    # Step 4: Set the directory to sparse-checkout
    echo "$sparse_path" >> .git/info/sparse-checkout

    # Step 5: Pull the specified branch with sparse checkout
    git pull origin "$target_branch"
}

# gtool gt-clone-local: create a local clone as <repo dir>-1
function gt-clone-local()
{
    local repo_root
    repo_root=$(git rev-parse --show-toplevel) || return 1

    local repo_name
    repo_name=$(basename "$repo_root")

    local target_dir
    target_dir="$(dirname "$repo_root")/${repo_name}-1"

    if [ -e "$target_dir" ]
    then
        echo "Target directory already exists: $target_dir"
        return 1
    fi

    git clone "$repo_root" "$target_dir"
}
alias gclocal="gt-clone-local"
