alias gs='git status '
alias gss='git status | less'
alias gsu='git status -uno'
alias ga='git add '
alias gai='git add -i'
alias gb='git rebase'
alias gbc='git rebase --continue'
alias gbupstream='git branch --set-upstream-to=origin/master'
alias gbranch='git branch'
alias gc='git commit '
alias gm='git commit -m '
alias gca='git commit --amend '
alias gcg="git commit --author='Adriano Gil <adrianogil.san@gmail.com>'"
alias gd='git diff '
alias gdc='git diff --cached'
alias gk='gitk --all&'
alias gx='gitx --all'
alias gr='git remote update '
alias gw='git whatchanged --pretty=oneline'
alias greset='git reset '
alias gsoft-reset='git reset '
alias ghrme='git reset --hard HEAD'
alias gshow='git show '
alias gcereja='git cherry-pick '
alias gflog="git reflog --format='%C(auto)%h %<|(17)%gd %C(blue)%ci%C(reset) %s'"

alias grb="gr && gb"
alias grbp="gr && gb && gp"

alias gco='git checkout '
alias gckout='git checkout'
alias gckt='git checkout --track'

alias gp='echo "Lets push to repo" && git push'
alias gpupstream='git push --set-upstream origin master'

alias gpick='python3 $GIT_TOOLS_DIR/python/git_pick.py'
alias gsquash='python3 $GIT_TOOLS_DIR/python/git_squash.py'

alias got='git '
alias get='git '
alias gil='git '

alias gl1='git log -1'
alias gh10='gh -10'
alias gw1='git whatchanged -1 '

alias gremotes="git remote -v"

alias gtoday='gh --since="1am"'

alias gignore-file='git update-index --assume-unchanged '

alias git-author-update="gc --amend --author='Adriano Gil <adrianogil.san@gmail.com>'"

alias gh='git hist'
alias gha='git hist --all '
alias gha-reflog='gh --decorate `git reflog | cut -d " " -f 1`'

# See https://www.commandlinefu.com/commands/view/15063/list-offsets-from-head-with-git-log.
function gh-count-from-head()
{
    o=0
    git log --oneline | while read l; do printf "%+9s %s\n" "HEAD~${o}" "$l"; o=$(($o+1)); done | less
}

# Specific command related to my own scripts that exchange commits and CL between P4 and git repos
alias perforce-push='git push local master:perforce-master'

# I have the habit of creating in each git workspace a local tag 'local/props'
# with my local modification. So I can use this command to quickly load all
# my private settings
alias load-local-properties='git cherry-pick local/props && git reset HEAD~1'

# Unity dev
alias gunity-all='git add Assets/ ProjectSettings/ '

# Generate commit message
function gcm()
{
    commit_message="Updated changes at "$(date +%F-%H:%M)
    echo "Generating commit: "$commit_message
    gc -m "$commit_message"
}

function ghs()
{
    gh $1 $2 | less
}

function gpush2gerrit()
{
    if [ -z "$1" ]
    then
        target_branch=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/ ')

        remote=$(git config "branch.${target_branch}.remote")
    else
        target_commit=$1
        remote=origin
    fi

    git push $remote HEAD:refs/for/$target_branch
}

alias gfind-big-files=$HOME'/Softwares/git/findbig/git_find_big.sh'