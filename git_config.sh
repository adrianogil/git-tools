
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
    # gls-files $target_commit $target_directory
    # Github-like vision of repo, shows last commit that changed each
    # file in $2 directory

    if [ -z "$1" ]
    then
        target_directory=''
        target_commit='HEAD'
    else
        target_directory=$1

        if [ -z "$2" ]
        then
            target_commit='HEAD'
        else
            target_commit=$2
        fi
    fi

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

# Based on http://scriptedonachip.com/git-sparse-checkout
function gsparse-checkout()
{
    git_url=$1
    target_folder=$2
    total_commits=$3

    git init
    git remote add origin $git_url
    git config core.sparsecheckout true
    echo $target_folder"/*" >> .git/info/sparse-checkout
    git pull --depth=$total_commits origin master
}

function ghard-reset-head()
{
    ghard-reset HEAD
}

alias gupdate-hard="gr && ghard-reset"

function gol()
{
    # git clone and enter repo directory
    git_url=$1
    git_repo=$(basename $git_url)
    git_repo=${git_repo%.*}

    git clone $git_url
    cd $git_repo
}

function golp()
{
     # git clone with depth 1 and enter repo directory
    git_url=$1
    git_repo=$(basename $git_url)
    git_repo=${git_repo%.*}

    git clone $git_url --depth 1
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

function gcount()
{
    total_commits=$(gh | wc -l)
    echo 'There are'$total_commits' commits in current local branch'
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

# Git Internals

function gdetails()
{
    git cat-file -p $1
}

alias gdetails-obj-count='git count-objects -v '

alias gfind-big-files=$HOME'/Softwares/git/findbig/git_find_big.sh'