function gfrepos()
{
    f '.git' | xa echo {} | rev | cut -c6- | rev
}
alias gt-repos="gfrepos"

function gfrepos-urls()
{
    gfrepos | xa cat {}/.git/config | grep "url = " | cut -c8-
}
alias gt-repos-urls="gfrepos-urls"

function gurls()
{
    cat $(git rev-parse --show-toplevel)/.git/config  | grep "url = " | cut -c8-
}
alias gt-repos-current-urls="gurls"
