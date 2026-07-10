
# Rebase-related aliases
alias gb='git rebase'
alias gbc='git rebase --continue'

function gt-select-remote-branch()
{
    git for-each-ref --format='%(refname:short)' refs/remotes \
        | grep -v '/HEAD$' \
        | default-fuzzy-finder
}

function gt-select-local-branch()
{
    git for-each-ref --format='%(refname:short)' refs/heads \
        | default-fuzzy-finder
}

function gt-preview-branch-integration()
{
    local operation="$1"
    local target_branch="$2"
    local current_ref
    local incoming_count
    local replay_count
    local answer

    if [[ -z "$target_branch" ]]; then
        echo "No branch selected."
        return 1
    fi

    if ! git rev-parse --verify --quiet "${target_branch}^{commit}" >/dev/null; then
        echo "Branch or ref not found: $target_branch"
        return 1
    fi

    current_ref=$(git symbolic-ref --quiet --short HEAD 2>/dev/null)
    if [[ -z "$current_ref" ]]; then
        current_ref=$(git rev-parse --short HEAD)
    fi

    echo "Previewing git $operation from '$target_branch' while on '$current_ref'."

    incoming_count=$(git rev-list --count "HEAD..${target_branch}")
    if [[ "$incoming_count" -eq 0 ]]; then
        echo "No commits in '$target_branch' that are missing from HEAD."
    else
        echo "Commits in '$target_branch' that are missing from HEAD:"
        git --no-pager log --oneline --decorate "HEAD..${target_branch}"
    fi

    if [[ "$operation" = "rebase" ]]; then
        replay_count=$(git rev-list --count "${target_branch}..HEAD")
        if [[ "$replay_count" -eq 0 ]]; then
            echo "No local commits would be replayed by this rebase."
        else
            echo "Local commits that would be replayed:"
            git --no-pager log --oneline --decorate "${target_branch}..HEAD"
        fi
    fi

    if [[ "${GT_TOOLS_ASSUME_YES:-}" = "1" ]]; then
        return 0
    fi

    printf "Continue with git %s '%s'? [y/N] " "$operation" "$target_branch"
    IFS= read -r answer
    case "$answer" in
        y|Y|yes|YES|Yes)
            return 0
            ;;
        *)
            echo "Aborted."
            return 1
            ;;
    esac
}

function gt-run-branch-integration()
{
    local operation="$1"
    local target_branch="$2"

    if ! gt-preview-branch-integration "$operation" "$target_branch"; then
        return 1
    fi

    echo "Running: git $operation $target_branch"
    if [[ "$operation" = "merge" ]]; then
        git merge -- "$target_branch"
    else
        git rebase "$target_branch"
    fi
}

# gtool gt-rebase: rebase from a remote branch
function gt-rebase()
{
    local target_branch
    target_branch=$(gt-select-remote-branch)
    gt-run-branch-integration rebase "$target_branch"
}
alias gb-fz="gt-rebase"

# gtool gt-rebase-local-branch: rebase from a local branch
function gt-rebase-local-branch()
{
    local target_branch
    target_branch=$(gt-select-local-branch)
    gt-run-branch-integration rebase "$target_branch"
}

# gtool gt-merge: merge from a remote branch
function gt-merge()
{
    local target_branch
    target_branch=$(gt-select-remote-branch)
    gt-run-branch-integration merge "$target_branch"
}

# gtool gt-merge-local-branch: merge from a local branch
function gt-merge-local-branch()
{
    local target_branch
    target_branch=$(gt-select-local-branch)
    gt-run-branch-integration merge "$target_branch"
}

# gtool gt-continue: Continue a rebase, merge or cherry-pick operation
function gt-continue()
{
    repo_root_path=$(gt-get-root-path)
    # Check for ongoing merge, rebase, or cherry-pick
    if [ -d "${repo_root_path}/.git/rebase-apply" ]; then
        echo "Continuing rebase..."
        git rebase --continue
    elif [ -d "${repo_root_path}/.git/rebase-merge" ]; then
        echo "Continuing rebase merge..."
        git rebase --continue
    elif [ -f "${repo_root_path}/.git/MERGE_HEAD" ]; then
        echo "Continuing merge..."
        git merge --continue
    elif [ -f "${repo_root_path}/.git/CHERRY_PICK_HEAD" ]; then
        echo "Continuing cherry-pick..."
        git cherry-pick --continue
    else
        echo "No rebase, merge, or cherry-pick in progress."
    fi
}
alias gcontinue="gt-continue"
