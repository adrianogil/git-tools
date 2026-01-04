
# gtool gt-navigate-to-local-branch: Change current branch
function gt-navigate-to-local-branch()
{
    target_branch=$(git branch -a | cut -c3- | default-fuzzy-finder)
    echo "Let's checkout to branch: "$target_branch
    git checkout ${target_branch}
}
alias gt-go-local-branch="gt-navigate-to-local-branch"
alias ggo="gt-navigate-to-local-branch"

# gtool gt-move-dir-from-change: cd to a directory changed by the current commit
function gt_move_dir_from_change()
{
    local commit="${1:-HEAD}"
    local root

    if ! root=$(git rev-parse --show-toplevel 2>/dev/null); then
        printf 'gt_move_dir_from_change: not a git repo\n' >&2
        return 1
    fi

    local target_dir
    target_dir=$(git diff-tree --no-commit-id --name-only -r "$commit" \
        | xargs -n1 dirname \
        | sort -u \
        | default-fuzzy-finder)

    if [[ -z $target_dir ]]; then
        printf 'gt_move_dir_from_change: no directory selected\n' >&2
        return 1
    fi

    if [[ $target_dir == "." ]]; then
        cd "$root"
    else
        cd "$root/$target_dir"
    fi
}
alias gt-move-dir-from-change="gt_move_dir_from_change"
alias cdg="gt_move_dir_from_change"
