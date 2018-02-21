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

function gls-files()
{
    for a in $(ls); do git log --pretty=format:"%h%x09$a%x09[%s]" -1 -- "$a"; done
}

function gls-files-from-commit()
{
    # WIP: Fix when files are from different branches
    target_commit=$1
    target_directory=$2

    target_files=$(git show $target_commit:$target_directory | tail -n +3)

    # echo $target_files
    # echo $target_commit

    if [ -z "$target_directory" ]
    then
        for a in ${target_files}; do git log --pretty=format:"%h%x09$a%x09[%s]%x09%ar" -1 -- $target_commit $a; done
    else
        for a in ${target_files}; do git log --pretty=format:"%h%x09$a%x09[%s]%x09%ar" -1 -- $target_commit $target_directory/$a; done
    fi

}

function ghard-reset()
{
    if [ -z "$1" ]
    then
        target_commit=$(git for-each-ref --format='%(upstream:short)' $(git symbolic-ref -q HEAD))
    else
        target_commit=$1
    fi

    echo 'Git hard reset to ref '$target_commit
    git reset --hard $target_commit
}

# git
function gol
{
    git_url=$1
    git_repo=$(basename $git_url)
    git_repo=${git_repo%.*}

    git clone $git_url
    cd $git_repo
}

function random-commit-msg()
{
    curl -s whatthecommit.com/index.txt
}

function create-random-commits()
{
    number_commits=$1

    for i in `seq 1 ${number_commits}`;
        do
            number_files=$(( ( RANDOM % 20 )  + 1 ))

            for i in `seq 1 ${number_commits}`;
            do
                text_name_n1=$(( ( RANDOM % 10 )  + 1 ))
                text_name_n2=$(( ( RANDOM % 10 )  + 1 ))
                text_name_n3=$(( ( RANDOM % 10 ) * $text_name_n1  + $text_name_n2 ))
                text_file_name='text_file_'$text_name_n3'.txt'
                echo $text_file_name >> $text_file_name
                git add $text_file_name
            done
            git commit -m "$(random-commit-msg)"
        done
}