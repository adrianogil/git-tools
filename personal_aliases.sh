
alias gk='gitk --all&'
alias gx='gitx --all'
alias gr-tags='git fetch --tags'
alias gw='git whatchanged --pretty=oneline'
alias greset='git reset '
alias gsoft-reset='git reset '
alias ghrme='git reset --hard HEAD'
alias gshow='git show '
alias gcereja='git cherry-pick '

alias grb="gr && gb"
alias grbp="gr && gb && gp"

alias gco='git checkout '
alias gckout='git checkout'
alias gckt='git checkout --track'

alias gsquash='python3 $GIT_TOOLS_DIR/python/git_squash.py'

alias gil='git '

alias gl1='git log -1'
alias gl2='git log -2'
alias gw1='git whatchanged -1 '

alias gremotes="git remote -v"

# Specific command related to my own scripts that exchange commits and CL between P4 and git repos
alias perforce-push='git push local master:perforce-master'

# Deprecated
# alias gfind-big-files=$HOME'/Softwares/git/findbig/git_find_big.sh'
