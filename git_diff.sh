
# gtool gt-diff: diff commits between two references
function gt-diff()
{
    ref1=$1
    ref2=$2
    python3 -m gittools.history.commitsdiff ${ref1} ${ref2}
}

alias gd='git diff '
alias gdc='git diff --cached'
alias gds='git diff --staged'
