

# gtool gt-list-untracked-files: list untracked files
function gt-list-untracked-files()
{
    git ls-files --others --exclude-standard
}
alias gfiles-untracked="gt-list-untracked-files"

# gtool gt-list-modified-files: list modified files
function gt-list-modified-files()
{
    git ls-files --modified
}
alias gfiles-modified="gt-list-modified-files"

# gtool gt-conflicts: summarize unresolved conflicts
function gt-conflicts()
{
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Error: not inside a Git worktree." >&2
        return 1
    fi

    local entry
    local status
    local description
    local path
    local index
    local -a conflict_statuses=()
    local -a conflict_descriptions=()
    local -a conflict_paths=()

    while IFS= read -r -d '' entry; do
        status="${entry:0:2}"
        path="${entry:3}"

        case "$status" in
            DD) description="both deleted" ;;
            AU) description="added by us" ;;
            UD) description="deleted by them" ;;
            UA) description="added by them" ;;
            DU) description="deleted by us" ;;
            AA) description="both added" ;;
            UU) description="both modified" ;;
            *) continue ;;
        esac

        conflict_statuses+=("$status")
        conflict_descriptions+=("$description")
        conflict_paths+=("$path")
    done < <(git status --porcelain=v1 -z --untracked-files=no)

    if [ "${#conflict_paths[@]}" -eq 0 ]; then
        echo "No unresolved conflicts."
        return 0
    fi

    printf 'Unresolved conflicts: %d\n' "${#conflict_paths[@]}"
    for ((index = 0; index < ${#conflict_paths[@]}; index++)); do
        printf '  %s  %s: %s\n' \
            "${conflict_statuses[$index]}" \
            "${conflict_descriptions[$index]}" \
            "${conflict_paths[$index]}"
    done
}
