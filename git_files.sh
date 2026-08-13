
# gtool gt-file-previous-version: select a commit and then a file to see its previous version
function gt-file-previous-version()
{
    if [ -z "$1" ]
    then
        target_commit=$(gt-hist-pick-commit)
    else
        target_commit=$1
    fi

    target_file=$(git diff-tree --no-commit-id --name-only -r ${target_commit} | default-fuzzy-finder)

    echo "Let's see previous version of "${target_file}" in ref "${target_commit}

    git show ${target_commit}:${target_file}
}

# Normalize a repository-relative path without depending on realpath(1), which is
# not available by default on every supported macOS installation.
function _gt-file-history-normalize-path()
{
    local remaining="$1"
    local component
    local normalized=''

    while [ -n "$remaining" ]; do
        case "$remaining" in
            */*)
                component=${remaining%%/*}
                remaining=${remaining#*/}
                ;;
            *)
                component=$remaining
                remaining=''
                ;;
        esac

        case "$component" in
            ''|.)
                ;;
            ..)
                if [ -z "$normalized" ]; then
                    return 1
                fi
                case "$normalized" in
                    */*) normalized=${normalized%/*} ;;
                    *) normalized='' ;;
                esac
                ;;
            *)
                if [ -z "$normalized" ]; then
                    normalized=$component
                else
                    normalized="$normalized/$component"
                fi
                ;;
        esac
    done

    [ -n "$normalized" ] || return 1
    printf '%s\n' "$normalized"
}

function _gt-file-history-resolve-path()
{
    local root="$1"
    local input_path="$2"
    local input_dir
    local input_name
    local physical_dir
    local prefix
    local candidate

    case "$input_path" in
        /*)
            input_dir=${input_path%/*}
            input_name=${input_path##*/}
            [ -n "$input_dir" ] || input_dir='/'
            if physical_dir=$(cd "$input_dir" 2>/dev/null && pwd -P); then
                input_path="$physical_dir/$input_name"
            fi
            case "$input_path" in
                "$root"/*) candidate=${input_path#"$root"/} ;;
                *) return 1 ;;
            esac
            ;;
        *)
            prefix=$(git rev-parse --show-prefix 2>/dev/null) || return 1
            candidate="${prefix}${input_path}"
            ;;
    esac

    _gt-file-history-normalize-path "$candidate"
}

function _gt-file-history-path-at-commit()
{
    local root="$1"
    local target_file="$2"
    local wanted_commit="$3"
    local return_previous="${4-}"
    local line
    local current_commit=''
    local matched_commit='false'

    while IFS= read -r line; do
        case "$line" in
            __GT_FILE_HISTORY_COMMIT__*)
                current_commit=${line#__GT_FILE_HISTORY_COMMIT__}
                ;;
            '')
                ;;
            *)
                if [ "$current_commit" = "$wanted_commit" ]; then
                    if [ "$return_previous" = 'previous' ]; then
                        matched_commit='true'
                    else
                        printf '%s\n' "$line"
                        return 0
                    fi
                elif [ "$matched_commit" = 'true' ]; then
                    printf '%s\n' "$line"
                    return 0
                fi
                ;;
        esac
    done < <(
        git -C "$root" --literal-pathspecs -c core.quotePath=false log \
            --follow --find-renames \
            --format='__GT_FILE_HISTORY_COMMIT__%H' --name-only \
            -- "$target_file"
    )

    return 1
}

function _gt-file-history-help()
{
    cat <<'EOF'
Usage:
  gt-file-history [--] FILE
  gt-file-history --diff [REV] [--] FILE

Show a concise, newest-first history for FILE, following historical renames.

Options:
  -d, --diff [REV]  Show the file patch from REV. If REV is omitted, select a
                    commit with default-fuzzy-finder.
  -h, --help        Show this help.

Examples:
  gt-file-history 'docs/file name.md'
  gt-file-history -- '-leading-dash.txt'
  gt-file-history --diff HEAD~2 -- 'docs/file name.md'
  gt-file-history --diff -- 'docs/file name.md'
EOF
}

# gtool gt-file-history: follow a file's history across renames
function gt-file-history()
{
    local mode='log'
    local revision=''
    local input_path
    local root
    local target_file
    local shallow
    local history
    local selected
    local revision_diagnostic
    local revision_status
    local resolved_commit
    local historical_path
    local previous_path

    case "${1-}" in
        -h|--help)
            _gt-file-history-help
            return 0
            ;;
        -d|--diff)
            mode='diff'
            shift
            ;;
    esac

    if [ "$mode" = 'log' ]; then
        [ "${1-}" = '--' ] && shift
        if [ "$#" -ne 1 ]; then
            _gt-file-history-help >&2
            return 2
        fi
        input_path=$1
    else
        if [ "${1-}" = '--' ]; then
            shift
        elif [ "$#" -ge 2 ]; then
            revision=$1
            shift
            [ "${1-}" = '--' ] && shift
        fi
        if [ "$#" -ne 1 ]; then
            _gt-file-history-help >&2
            return 2
        fi
        input_path=$1
    fi

    if ! root=$(git rev-parse --show-toplevel 2>/dev/null); then
        printf 'gt-file-history: not inside a Git worktree.\n' >&2
        return 1
    fi
    root=$(cd "$root" && pwd -P) || {
        printf 'gt-file-history: cannot resolve the repository root.\n' >&2
        return 1
    }

    if ! target_file=$(_gt-file-history-resolve-path "$root" "$input_path"); then
        printf 'gt-file-history: path is outside the repository or invalid: %s\n' "$input_path" >&2
        return 1
    fi

    shallow=$(git -C "$root" rev-parse --is-shallow-repository 2>/dev/null) || {
        printf 'gt-file-history: cannot determine whether the repository is shallow.\n' >&2
        return 1
    }
    if [ "$shallow" = 'true' ]; then
        printf 'gt-file-history: repository history is shallow; fetch more history before tracing renames.\n' >&2
        return 1
    fi

    history=$(git -C "$root" --literal-pathspecs log --follow --find-renames \
        --format='%H' -- "$target_file") || {
        printf 'gt-file-history: failed to read history for: %s\n' "$target_file" >&2
        return 1
    }
    if [ -z "$history" ]; then
        printf 'gt-file-history: no history found for: %s\n' "$target_file" >&2
        return 1
    fi

    if [ "$mode" = 'log' ]; then
        git -C "$root" --literal-pathspecs --no-pager log \
            --follow --find-renames --date=short \
            --format='%h %ad %s [%an]' -- "$target_file"
        return $?
    fi

    if [ -z "$revision" ]; then
        if ! type default-fuzzy-finder >/dev/null 2>&1; then
            printf 'gt-file-history: default-fuzzy-finder is required when REV is omitted.\n' >&2
            return 1
        fi
        selected=$(
            git -C "$root" --literal-pathspecs --no-pager log \
                --follow --find-renames --date=short \
                --format='%h %ad %s [%an]' -- "$target_file" \
                | default-fuzzy-finder
        )
        if [ $? -ne 0 ] || [ -z "$selected" ]; then
            printf 'gt-file-history: no commit selected.\n' >&2
            return 1
        fi
        revision=${selected%% *}
    fi

    revision_diagnostic=$(git -C "$root" rev-parse --verify \
        --end-of-options "${revision}^{commit}" 2>&1 >/dev/null)
    revision_status=$?
    case "$revision_diagnostic" in
        *ambiguous*) revision_status=1 ;;
    esac
    if [ "$revision_status" -ne 0 ]; then
        printf 'gt-file-history: invalid or ambiguous revision: %s\n' "$revision" >&2
        return 1
    fi
    resolved_commit=$(git -C "$root" rev-parse --verify --quiet \
        --end-of-options "${revision}^{commit}") || return 1

    if ! historical_path=$(_gt-file-history-path-at-commit \
        "$root" "$target_file" "$resolved_commit"); then
        printf 'gt-file-history: revision did not change this file: %s\n' "$revision" >&2
        return 1
    fi

    previous_path=$(_gt-file-history-path-at-commit \
        "$root" "$target_file" "$resolved_commit" previous) || previous_path=''

    if [ -n "$previous_path" ] && [ "$previous_path" != "$historical_path" ]; then
        git -C "$root" --literal-pathspecs -c core.quotePath=false --no-pager show --find-renames \
            --date=short \
            --format='commit %H%nAuthor: %an <%ae>%nDate:   %ad%n%n    %s' \
            "$resolved_commit" -- "$previous_path" "$historical_path"
    else
        git -C "$root" --literal-pathspecs -c core.quotePath=false --no-pager show --find-renames \
            --date=short \
            --format='commit %H%nAuthor: %an <%ae>%nDate:   %ad%n%n    %s' \
            "$resolved_commit" -- "$historical_path"
    fi
}

# gtool gt-file-history-version: select a file and then a commit to see its previous version
function gt-file-history-version()
{
    if [ -z "$1" ]
    then
        target_file=$(find . -not -path '*/\.*' | default-fuzzy-finder | cut -c3-)
    else
        target_file=$1
    fi

    target_commit=$(gh ${target_file} | default-fuzzy-finder | cut -c3- | awk '{print $1}')

    echo "Let's see previous version of "${target_file}" in ref "${target_commit}"\n"

    git show ${target_commit}:${target_file}
}

# gtool gt-file-checkout-version: change a target file to its version in a target commit
function gt-file-checkout-version()
{
    if [ -z "$1" ]
    then
        target_file=$(find . -not -path '*/\.*' | default-fuzzy-finder | cut -c3-)
    else
        target_file=$1
    fi

    if [ -z "$2" ]
    then
        target_commit=$(gh ${target_file} | default-fuzzy-finder | cut -c3- | awk '{print $1}')
    else
        target_commit=$2
    fi

    echo "Change file "${target_file}" to its previous version in ref "${target_commit}"\n"

    git checkout ${target_commit} ${target_file}
}

# gtool gls-files: see most recent commit that changed each file in a target directory
function gls-files()
{
    # gls-files $target_commit $target_directory
    # Github-like vision of repo, shows last commit that changed each
    # file in $2 directory

    if [ -z "$1" ]
    then
        target_directory=''
        target_commit='HEAD'
    else
        target_directory=$1

        if [ -z "$2" ]
        then
            target_commit='HEAD'
        else
            target_commit=$2
        fi
    fi

    target_files=$(git show $target_commit:$target_directory | tail -n +3)
    # target_files=$(echo -e $target_files | tr '\n' ' ')

    line='----------------------------------------'

    if [ -z "$target_directory" ]
    then
        echo ${target_files} | xargs -I {} git log -n 1 --pretty=format:""{}" - %h%x09[%><(35,trunc)%s]%x09%ar" -- ${target_commit} {}
    else
        echo ${target_files} | xargs -I {} git log -n 1 --pretty=format:""{}" - %h%x09[%><(35,trunc)%s]%x09%ar" -- ${target_commit} $target_directory/{}
    fi

    total_files=$(echo $target_files | wc -l)
    echo ${total_files}" files"

}

# gtool gt-files-to-prompt: copy only the files changed in a commit to the clipboard
function gt-files-to-prompt() {
    local commit="${1:-HEAD}"
    echo "Copying files changed in commit ${commit} to clipboard"

    # ensure we're in a git repo
    local root
    if ! root=$(git rev-parse --show-toplevel 2>/dev/null); then
        printf 'gt-files-to-prompt: not a git repo\n' >&2
        return 1
    fi
    cd "$root"

    # list only the files changed in that commit
    local file_list
    file_list=$(git diff-tree --no-commit-id --name-only -r "$commit") || {
        printf 'gt-files-to-prompt: failed to list files for %s\n' "$commit" >&2
        return 1
    }

    if [[ -z $file_list ]]; then
        printf 'gt-files-to-prompt: no files changed in commit %s\n' "$commit" >&2
        return 1
    fi

    {
        while IFS= read -r file; do
            # skip unreadable
            if [[ ! -r $file ]]; then
                printf 'gt-files-to-prompt: %s: missing or unreadable\n' "$file" >&2
                continue
            fi

            # detect binary vs text
            local mime
            mime=$(file --mime-type -b -- "$file")
            if [[ $mime != text/* ]]; then
                printf 'gt-files-to-prompt: %s is binary (%s), skipping\n' "$file" "$mime" >&2
                continue
            fi

            # fence with filename
            printf '```%s\n' "$file"
            cat -- "$file"
            printf '\n```\n'
        done <<< "$file_list"
    } | copy-text-to-clipboard
}

# gtool gt-dir-to-prompt: copy only the files tracked by git under a selected directory to the clipboard
function gt-dir-to-prompt() {
    echo "Copying tracked files for selected directory to clipboard"

    # ensure we're in a git repo
    local root
    if ! root=$(git rev-parse --show-toplevel 2>/dev/null); then
        printf 'gt-dir-to-prompt: not a git repo\n' >&2
        return 1
    fi
    cd "$root"

    local target_directory
    target_directory=$(
        {
            printf '.\n'
            find . -mindepth 1 -type d -not -path '*/\.*'
        } | default-fuzzy-finder | sed 's|^\./||'
    )

    if [[ -z $target_directory ]]; then
        printf 'gt-dir-to-prompt: no directory selected\n' >&2
        return 1
    fi

    local dir_prefix=''
    if [[ $target_directory != '.' ]]; then
        dir_prefix="${target_directory%/}/"
    fi

    local file_list
    if [[ -z $dir_prefix ]]; then
        file_list=$(git ls-files) || {
            printf 'gt-dir-to-prompt: failed to list tracked files\n' >&2
            return 1
        }
    else
        file_list=$(git ls-files -- "$dir_prefix") || {
            printf 'gt-dir-to-prompt: failed to list tracked files under %s\n' "$target_directory" >&2
            return 1
        }
    fi

    if [[ -z $file_list ]]; then
        printf 'gt-dir-to-prompt: no tracked files under %s\n' "$target_directory" >&2
        return 1
    fi

    {
        while IFS= read -r file; do
            # skip unreadable
            if [[ ! -r $file ]]; then
                printf 'gt-dir-to-prompt: %s: missing or unreadable\n' "$file" >&2
                continue
            fi

            # detect binary vs text
            local mime
            mime=$(file --mime-type -b -- "$file")
            if [[ $mime != text/* ]]; then
                printf 'gt-dir-to-prompt: %s is binary (%s), skipping\n' "$file" "$mime" >&2
                continue
            fi

            # fence with filename
            printf '```%s\n' "$file"
            cat -- "$file"
            printf '\n```\n'
        done <<< "$file_list"
    } | copy-text-to-clipboard
}

# gtool gt-files-to-prompt-pick-commit: copy only the files changed in a picked commit to the clipboard
function gt-files-to-prompt-pick-commit() {
    local commit
    commit=$(gt-hist-pick-commit) || {
        printf 'gt-files-to-prompt-pick-commit: failed to pick commit\n' >&2
        return 1
    }

    gt-files-to-prompt "$commit"
}


# gtool gt-files-to-prompt-pick-commit-flog: copy only the files changed in a picked commit (from git reflog) to the clipboard
function gt-files-to-prompt-pick-commit-flog() {
    local commit
    commit=$(gt-flog-pick-commit) || {
        printf 'gt-files-to-prompt-pick-commit-flog: failed to pick commit\n' >&2
        return 1
    }

    gt-files-to-prompt "$commit"
}

# gtool gt-tree-tracked: show a tree of files tracked by git
function gt-tree-tracked() {
    local root
    if ! root=$(git rev-parse --show-toplevel 2>/dev/null); then
        printf 'gt-tree-tracked: not a git repo\n' >&2
        return 1
    fi

    cd "$root" || return 1

    git ls-files | python3 "$GIT_TOOLS_DIR/python/git_tree_tracked.py"
}

# gtool gt-show-files-tree: show a tree of files changed in a commit with added/deleted counts
function gt-show-files-tree() {
    local commit="${1:-HEAD}"
    local root
    if ! root=$(git rev-parse --show-toplevel 2>/dev/null); then
        printf 'gt-show-files-tree: not a git repo\n' >&2
        return 1
    fi

    cd "$root" || return 1

    git log -n 1 --format="%h %s | %an | %ad" --date=short "$commit"
    git diff-tree --no-commit-id --numstat -r --root "$commit" | \
        python3 "$GIT_TOOLS_DIR/python/git_tree_changed.py"
}

# gtool gt-files-to-prompt-to-code-review: copy changed files and commit details into a code review prompt
function gt-files-to-prompt-to-code-review() {
    local commit="${1:-HEAD}"
    echo "Copying code review prompt for commit ${commit} to clipboard"

    # ensure we're in a git repo
    local root
    if ! root=$(git rev-parse --show-toplevel 2>/dev/null); then
        printf 'gt-files-to-prompt-to-code-review: not a git repo\n' >&2
        return 1
    fi
    cd "$root"

    # list only the files changed in that commit
    local file_list
    file_list=$(git diff-tree --no-commit-id --name-only -r "$commit") || {
        printf 'gt-files-to-prompt-to-code-review: failed to list files for %s\n' "$commit" >&2
        return 1
    }

    if [[ -z $file_list ]]; then
        printf 'gt-files-to-prompt-to-code-review: no files changed in commit %s\n' "$commit" >&2
        return 1
    fi

    {
        printf 'Help me to code review this commit. Give me comments per file.\n\n'
        printf 'Here is the commit:\n'
        git show "$commit" | sed '/^Author:/d'
        printf '\n\nAnd below is full content version of each file:\n'

        while IFS= read -r file; do
            # skip unreadable
            if [[ ! -r $file ]]; then
                printf 'gt-files-to-prompt-to-code-review: %s: missing or unreadable\n' "$file" >&2
                continue
            fi

            # detect binary vs text
            local mime
            mime=$(file --mime-type -b -- "$file")
            if [[ $mime != text/* ]]; then
                printf 'gt-files-to-prompt-to-code-review: %s is binary (%s), skipping\n' "$file" "$mime" >&2
                continue
            fi

            # fence with filename
            printf '```%s\n' "$file"
            cat -- "$file"
            printf '\n```\n'
        done <<< "$file_list"
    } | copy-text-to-clipboard
}
