

# gtool gt-list-untracked-files: list untracked files
function gt-list-untracked-files()
{
    git ls-files --others --exclude-standard
}