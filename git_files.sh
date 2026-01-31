
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

# gtool gt-file-history: see change log for a specific file
function gt-file-history()
{
    if [ -z "$1" ]
    then
        target_file=$(find . -not -path '*/\.*' | default-fuzzy-finder | cut -c3-)
    else
        target_file=$1
    fi

    gh ${target_file}
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
