alias gunity-all='git add Assets/ ProjectSettings/ '
alias gs='git status '
alias gss='git status | less'
alias gsu='git status -uno'
alias ga='git add '
alias gb='git branch '
alias gc='git commit '
alias gca='git commit --amend '
alias gcg="git commit --author='Adriano Gil <adrianogil.san@gmail.com>'"
alias gd='git diff '
alias gdc='git diff --cached'
alias gco='git checkout '
alias gk='gitk --all&'
alias gx='gitx --all'
alias gr='git remote update '
alias gw='git whatchanged --pretty=oneline'
alias gh='git hist '
alias gha='git hist --all '
alias greset='git reset '
alias gsoft-reset='git reset '
alias ghrme='git reset --hard HEAD'
alias gshow='git show '
alias gcereja='git cherry-pick '
alias gflog="git reflog --format='%C(auto)%h %<|(17)%gd %C(blue)%ci%C(reset) %s'"

alias got='git '
alias get='git '
alias gil='git '

alias git-author-update="gc --amend --author='Adriano Gil <adrianogil.san@gmail.com>'"

alias perforce-push='git push local master:perforce-master'

alias load-local-properties='git cherry-pick local/props && git reset HEAD~1'