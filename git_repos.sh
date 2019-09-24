# gtool gt-repos
function gfrepos()
{
    f '.git' | xa echo {} | rev | cut -c6- | rev
}
alias gt-repos="gfrepos"

# gtool gfrepos-urls
function gt-repos-urls-current-folder()
{
    gfrepos | xa cat {}/.git/config | grep "url = " | cut -c8-
}

# gtool gt-repos-current-urls
function gt-repos-urls()
{
    cat $(git rev-parse --show-toplevel)/.git/config  | grep "url = " | cut -c8-
}
alias gurls="gt-repos-urls"

# gtool gt-repos-go-to-github
function gt-repos-go-to-github()
{
    url_path=$(gt-repos-urls-current-folder | head -1)
    github_url="http://www."$(echo ${url_path}| cut -c5- | tr ":" "/")
    o ${github_url}
}