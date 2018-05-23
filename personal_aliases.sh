alias gs='git status '
alias gss='git status | less'
alias gsu='git status -uno'
alias ga='git add '
alias gai='git add -i'
alias gb='git rebase'
alias gbranch='git branch'
alias gc='git commit '
alias gca='git commit --amend '
alias gcg="git commit --author='Adriano Gil <adrianogil.san@gmail.com>'"
alias gd='git diff '
alias gdc='git diff --cached'
alias gk='gitk --all&'
alias gx='gitx --all'
alias gr='git remote update '
alias gw='git whatchanged --pretty=oneline'
alias gh='git hist'
alias gha='git hist --all '
alias greset='git reset '
alias gsoft-reset='git reset '
alias ghrme='git reset --hard HEAD'
alias gshow='git show '
alias gcereja='git cherry-pick '
alias gflog="git reflog --format='%C(auto)%h %<|(17)%gd %C(blue)%ci%C(reset) %s'"

alias gco='git checkout '
alias gckout='git checkout'
alias gckt='git checkout --track'

alias gp='echo "Lets push to repo" && git push'
alias gpick='python3 $GIT_TOOLS_DIR/python/git_pick.py'
alias gsquash='python3 $GIT_TOOLS_DIR/python/git_squash.py'

alias got='git '
alias get='git '
alias gil='git '

alias git-author-update="gc --amend --author='Adriano Gil <adrianogil.san@gmail.com>'"

# Specific command related to my own scripts that exchange commits and CL between P4 and git repos
alias perforce-push='git push local master:perforce-master'

# I have the habit of creating in each git workspace a local tag 'local/props'
# with my local modification. So I can use this command to quickly load all
# my private settings
alias load-local-properties='git cherry-pick local/props && git reset HEAD~1'

# Unity dev
alias gunity-all='git add Assets/ ProjectSettings/ '

function gpush2gerrit()
{
    if [ -z "$1" ]
    then
        target_branch=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/ ')
    else
        target_commit=$1
    fi

    git push origin HEAD:refs/for/$target_branch
}