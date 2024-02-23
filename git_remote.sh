
# gtool gt-rename-url: Rename url of a target remote
function gt-rename-url()
{
    if [ -z "$1" ]
    then
        remote_name=$(git remote| default-fuzzy-finder)
    else
        remote_name=$1
    fi

    if [ -z "$2" ]
    then
        echo "Type new remote URL: "
        read remote_url
    else
        remote_url=$2
    fi

    git remote set-url ${remote_name} ${remote_url}
}

# gtool gt-push-set-upstream: Set upstream
function gt-push-set-upstream()
{
    if [ -z "$1" ]
    then
        upstream_branch=$(git rev-parse --abbrev-ref HEAD)
    else
        upstream_branch=$1
    fi

    git push --set-upstream origin ${upstream_branch}

}
alias gpupstream='gt-push-set-upstream'

# gtool gt-send-branch: Send target branch to remote
function gt-send-branch()
{
    if [ -z "$2" ]
    then
        if [ -z "$1" ]
        then
            complete_branch_name=$(gt-branches-fz)
            target_branch=$(python3 -m gittools.cli.removeremotename ${complete_branch_name})
            target_remote=$(python3 -m gittools.cli.removeremotename ${complete_branch_name} --get-only-remote)
        else
            target_branch=$1
            target_remote=$(git remote | default-fuzzy-finder)
        fi
    else
        target_branch=$1
        target_remote=$2
    fi

    if [ -z ${GIT_TOOLS_ALLOW_PUSH_TO_MAIN_BRANCH} ]; then
        # variable not set
        if [[ "$target_branch" == *"main"* ]]; then
          echo "For the main branch you need to push it manually (to avoid mistakes)"
          echo "or set the variable 'GIT_TOOLS_ALLOW_PUSH_TO_MAIN_BRANCH'"
          return 1
        fi
    fi

    echo "Sending commits to branch "${target_branch}" on remote "${target_remote}

    current_branch=$(git rev-parse --abbrev-ref HEAD)
    git push ${target_remote} ${current_branch}:${target_branch}
}
alias gp='gt-send-branch'

# gtool gt-send-branch-force: Send target branch to remote with force
function gt-send-branch-force()
{
    if [ -z "$1" ]
    then
        target_branch=$(gbko)
    else
        target_branch=$1
    fi

    if [ -z ${GIT_TOOLS_ALLOW_PUSH_TO_MAIN_BRANCH} ]; then
        # variable not set
        if [[ "$target_branch" == *"main"* ]]; then
          echo "For the main branch you need to push it manually (to avoid mistakes)"
          echo "or set the variable 'GIT_TOOLS_ALLOW_PUSH_TO_MAIN_BRANCH'"
          return 1
        fi
    fi

    echo "Sending commits to branch "${target_branch}

    current_branch=$(git rev-parse --abbrev-ref HEAD)
    git push origin --force ${current_branch}:${target_branch}
}
