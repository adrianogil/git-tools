
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

function gs-count()
{
    echo $(gs-files $1 | wc -l)
}

function gls-files()
{
    # gls-files
    # Github-like vision of repo, shows last commit that changed each
    # file in current directory
    if [ -z "$1" ]
    then
        target_directory='.'
    else
        target_directory=$1
    fi

    for a in $(ls $target_directory); do git log --pretty=format:"%h%x09$a%x09[%s]%x09%ar" -1 -- "$a"; done
}

function gls-files-from-commit()
{
    # gls-files $target_commit $target_directory
    # Github-like vision of repo, shows last commit that changed each
    # file in $2 directory

    target_commit=$1
    target_directory=$2

    target_files=$(git show $target_commit:$target_directory | tail -n +3)

    if [ -z "$target_directory" ]
    then
        for a in ${target_files}; do git log --pretty=format:"%h%x09$a%x09[%s]%x09%ar" -1 -- $target_commit $a; done
    else
        for a in ${target_files}; do git log --pretty=format:"%h%x09$a%x09[%s]%x09%ar" -1 -- $target_commit $target_directory/$a; done
    fi

}

function ghard-reset()
{
    # ghard-reset $target_commit
    if [ -z "$1" ]
    then
        target_commit=$(git for-each-ref --format='%(upstream:short)' $(git symbolic-ref -q HEAD))
    else
        target_commit=$1
    fi

    echo 'Git hard reset to ref '$target_commit
    git reset --hard $target_commit
}

alias gupdate-hard="gr && ghard-reset"

function gol
{
    # git clone and enter repo directory
    git_url=$1
    git_repo=$(basename $git_url)
    git_repo=${git_repo%.*}

    git clone $git_url
    cd $git_repo
}

function gnew-commits()
{
    if [ -z "$1" ]
    then
        target_commit=$(git for-each-ref --format='%(upstream:short)' $(git symbolic-ref -q HEAD))
    else
        target_commit=$1
    fi

    new_commits=$(git log HEAD..$target_commit --pretty=oneline| wc -l)

    echo $new_commits" new commits"
}

function gcount-commits()
{
    old_commit=$1
    new_commit=$2

    number_commits=$(($(git rev-list --count $old_commit..$new_commit) - 1))

    echo 'There are '$number_commits' commits of difference between revisions'
}

function gstats-short()
{
    git log --author="$1" --oneline --shortstat $2
}

function random-commit-msg()
{
    # generate a random commit message
    curl -s whatthecommit.com/index.txt
}

function create-random-commits()
{
    # generate random messages
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