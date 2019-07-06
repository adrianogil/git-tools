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

# Unity dev
alias gunity-all='git add Assets/ ProjectSettings/ '
