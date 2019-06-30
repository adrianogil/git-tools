alias gdetails-obj-count='git count-objects -v '
alias gt-internals-obj-count='git count-objects -v '

function gdetails()
{
    git cat-file -p $1
}
alias gt-internals-details="gdetails"
