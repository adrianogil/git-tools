alias gs='git status '
# gtool gt-status
function gt-status()
{
	git status | less
}
alias gss='git status | less'

alias gsu='git status -uno'
alias ga='git add '
alias gaf='git add -f '

# gtool gt-add-interactive
function gt-add-interactive()
{
	git add -i
}
alias gai='git add -i'

function gs-files()
{
    # gs-files
    # Git status files
    if [ -z "$1" ]
    then
        git status --porcelain | awk '{print $2}'
    else
        extension=$1
        git status --porcelain | awk '{print $2}' | grep \.$extension
    fi
}

# gtool gt-add-sk - Add file to be staged (alias gsk)
function gt-add-fz()
{
    git add $(gs-files $1 | sk)
}
alias gak="gt-add-fz"

# Unity dev
alias gunity-all='git add Assets/ ProjectSettings/ '
function gunity-meta-all()
{
    f '*.meta' $1 | xargs -I {} git add {}
}
