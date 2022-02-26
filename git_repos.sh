# gtool gt-repos: Find repos
function gfrepos()
{
    f '.git' | xa echo {} | rev | cut -c6- | rev
}
alias gt-repos="gfrepos"


function gt-repos-urls-current-folder()
{
    gfrepos | xa cat {}/.git/config | grep "url = " | cut -c8-
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
