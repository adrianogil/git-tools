# gtool gt-repos: Find repos
function gfrepos()
{
    python3 "${GIT_TOOLS_DIR}/python/git_repos.py" "$@"
}
alias gt-repos="gfrepos"


# gtool gt-repos-cd: Select and enter a repo
function gt-repos-cd()
{
    local repo repos arg
    for arg in "$@"
    do
        case "$arg" in
            -h|--help) gfrepos "$@"; return $? ;;
        esac
    done
    repos=$(gfrepos "$@") || return $?
    [ -n "$repos" ] || return 0
    repo=$(printf '%s\n' "$repos" | default-fuzzy-finder) || return $?

    if [ -n "$repo" ]
    then
        if [ ! -d "$repo/.git" ] && [ ! -f "$repo/.git" ]
        then
            printf 'cdr: repository no longer exists; try cdr --refresh\n' >&2
            return 1
        fi
        cd -- "$repo"
    fi
}
alias cdr="gt-repos-cd"


function gt-repos-urls-current-folder()
{
    local repos repo
    repos=$(gfrepos "$@") || return $?
    [ -n "$repos" ] || return 0
    while IFS= read -r repo
    do
        git -C "$repo" config --get-regexp '^remote\..*\.url$' | cut -d ' ' -f2-
    done <<EOF
$repos
EOF
}

# gtool gt-repos-urls: List repo urls
function gt-repos-urls()
{
    cat $(git rev-parse --show-toplevel)/.git/config  | grep "url = " | cut -c8-
}
alias gurls="gt-repos-urls"

# gtool gt-repos-open-site: Open repo site 
function gt-repos-open-site()
{
    url_path=$(gt-repos-urls | head -1)
    repo_url="http://www."$(echo ${url_path}| cut -c5- | rev | cut -c5- | rev | tr ":" "/")
    o ${repo_url}
}
