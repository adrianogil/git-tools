alias gs='git status '
# gtool gt-status
function gt-status()
{
	git status | less
}
alias gss='git status | less'

alias gsu='git status -uno'
alias ga='git add '

# gtool gt-add-interactive
function gt-add-interactive()
{
	git add -i
}
alias gai='git add -i'

function gt-add-sk()
{
    git add $(gs-files $1 | sk)
}
alias gak="gt-add-sk"

# Unity dev
alias gunity-all='git add Assets/ ProjectSettings/ '
