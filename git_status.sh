

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
