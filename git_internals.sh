alias gdetails-obj-count='git count-objects -v '
alias gt-internals-obj-count='git count-objects -v '

function gdetails()
{
    git cat-file -p $1
}
alias gt-internals-details="gdetails"

# gtool gt-file-object-path: show where Git stores the current blob for a tracked file
function gt-file-object-path()
{
    python3 "${GIT_TOOLS_DIR}/python/git_object_path.py" "$@"
}
