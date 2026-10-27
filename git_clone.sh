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

# gtool gt-clone-shallow-all-branches: Clone depth 1 with all branches available locally and enter repo
function gt-clone-shallow-all-branches()
{
    if [ "$#" -lt 1 ] || [ "$#" -gt 2 ] || [ -z "$1" ]
    then
        echo "Usage: gt-clone-shallow-all-branches <repository> [directory]" >&2
        return 2
    fi

    local repository_url="$1"
    local target_directory
    if [ "$#" -eq 2 ]
    then
        target_directory="$2"
    else
        target_directory="${repository_url%/}"
        target_directory="${target_directory##*/}"
        target_directory="${target_directory##*:}"
        target_directory="${target_directory%.git}"
    fi

    # --no-local makes --depth apply to local filesystem sources, too.
    git clone --depth 1 --no-single-branch --no-local -- "$repository_url" "$target_directory" || return $?

    local remote_refs remote_ref symbolic_target branch_name
    remote_refs=$(git -C "$target_directory" for-each-ref \
        --format='%(refname) %(symref)' refs/remotes/origin/) || return $?
    while read -r remote_ref symbolic_target
    do
        # Skip symbolic refs such as origin/HEAD, and empty output.
        [ -n "$remote_ref" ] && [ -z "$symbolic_target" ] || continue
        branch_name="${remote_ref#refs/remotes/origin/}"
        if ! git -C "$target_directory" show-ref --verify --quiet "refs/heads/$branch_name"
        then
            git -C "$target_directory" branch --track -- "$branch_name" "$remote_ref" || return $?
        fi
    done <<< "$remote_refs"

    cd -- "$target_directory"
}

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

    local parent_dir
    parent_dir=$(dirname "$repo_root")

    local count=${1:-1}
    if [ "$count" -lt 1 ] 2>/dev/null
    then
        echo "Usage: gt-clone-local [count]"
        return 1
    fi

    local created=0
    local suffix=1
    while [ "$created" -lt "$count" ]
    do
        local target_dir="${parent_dir}/${repo_name}-${suffix}"
        if [ ! -e "$target_dir" ]
        then
            git clone "$repo_root" "$target_dir" || return 1
            created=$((created + 1))
        fi
        suffix=$((suffix + 1))
    done
}
alias gclocal="gt-clone-local"
