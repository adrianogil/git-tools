# !/bin/bash
# gtool gt-continue: Continue a rebase or cherry-pick operationx
alias gcontinue="python3 -m gittools.continue"
alias gt-continue="gcontinue"

alias gabort="python3 -m gittools.abort"
alias gt-abort="gcontinue"

# gtool gt-config-show: Show the config file related to current git file
function gt-config-show()
{
    cat $(gt-get-root-path)/.git/config
}

# gtool gt-zip-repo: Zips a git commit
function gt-zip-repo()
{
    zip_name=$1
    if [ -z "$2" ]
    then
        target_ref=HEAD
    else
        target_ref=$2
    fi
    git archive -o ${zip_name}.zip ${target_ref}
}

function gt-cktout()
{
    target_branch=$(git branch -r | cut -c3- | sk)
    echo "Let's track a new branch: "$target_branch
    git checkout --track ${target_branch}
}


function gt-send-branch()
{
    if [ -z "$2" ]
    then
        if [ -z "$1" ]
        then
            complete_branch_name=$(gt-branches-fz)
            target_branch=$(python3 -m gittools.cli.removeremotename ${complete_branch_name})
            target_remote=$(python3 -m gittools.cli.removeremotename ${complete_branch_name} --get-only-remote)
        else
            target_branch=$1
            target_remote=$(git remote | sk)
        fi
    else
        target_branch=$1
        target_remote=$2
    fi

    if [ -z ${GIT_TOOLS_ALLOW_PUSH_TO_MAIN_BRANCH} ]; then
        # variable not set
        if [[ "$target_branch" == *"main"* ]]; then
          echo "For the main branch you need to push it manually (to avoid mistakes)"
          echo "or set the variable 'GIT_TOOLS_ALLOW_PUSH_TO_MAIN_BRANCH'"
          return 1
        fi
    fi

    echo "Sending commits to branch "${target_branch}" on remote "${target_remote}

    current_branch=$(git rev-parse --abbrev-ref HEAD)
    git push ${target_remote} ${current_branch}:${target_branch}
}
alias gp='gt-send-branch'

function gt-send-branch-force()
{
    if [ -z "$1" ]
    then
        target_branch=$(gbko)
    else
        target_branch=$1
    fi

    if [ -z ${GIT_TOOLS_ALLOW_PUSH_TO_MAIN_BRANCH} ]; then
        # variable not set
        if [[ "$target_branch" == *"main"* ]]; then
          echo "For the main branch you need to push it manually (to avoid mistakes)"
          echo "or set the variable 'GIT_TOOLS_ALLOW_PUSH_TO_MAIN_BRANCH'"
          return 1
        fi
    fi    

    echo "Sending commits to branch "${target_branch}

    current_branch=$(git rev-parse --abbrev-ref HEAD)
    git push origin --force ${current_branch}:${target_branch}
}

function gt-branches-fz()
{
    if [[ $(git branch -r | grep -v "/HEAD " | wc -l) -le 1 ]]; then
        git branch -r | grep -v "/HEAD " | cut -c3- | head -1
    else
        git branch -r | grep -v "/HEAD " | cut -c3- | sk
    fi
    
}
alias gbk='gt-branches-fz'

function gt-branches-origin-fz()
{
    complete_branch_name=$(gt-branches-fz)
    only_branch_name=$(python3 -m gittools.cli.removeremotename ${complete_branch_name})
    echo ${only_branch_name}
}
alias gbko='gt-branches-origin-fz'

TMP_BUFFER_LAST_FETCH=/tmp/last_fetch
function gt-fetch-save-buffer()
{
    target_buffer_file=${TMP_BUFFER_LAST_FETCH}_$(basename $PWD).txt
    echo "" > ${target_buffer_file}
    git fetch $1 -v >& ${target_buffer_file}
    cat ${target_buffer_file}
    echo "Saving git remote "$(date +%F-%H:%M)":" >> ${target_buffer_file}
    echo "" >> ${target_buffer_file}
    echo "Log saved at "${target_buffer_file}
}
function gt-fetch-last()
{
    cat $TMP_BUFFER_LAST_FETCH$(basename $PWD).txt
}

# gtool gt-fetch: Fetch new commits
function gt-fetch()
{
    if [ -z "$1" ]
    then
        if [[ $(git remote | wc -l) -le 1 ]]; then
            target_remote=$(git remote | head -1)
        else
            target_remote=$(git remote | sk)
        fi
    else
          target_remote=$1
    fi

    git remote update ${target_remote}

    # Updating tracking everytime the repo is updated
    gt-tracking-update
}
alias gr='gt-fetch'
alias gro='gt-fetch origin'
alias gr-last='gt-fetch-last'

alias gt-get-root-path='git rev-parse --show-toplevel'
# gtool gt-root: Go to root level of current repo
function gt-root()
{
    cd $(gt-get-root-path)
}
alias groot="gt-root"

function gs-count()
{
    echo $(gs-files $1 | wc -l)
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

function ghard-reset-fz()
{
    target_commit=$(git branch -a | cut -c3- | default-fuzzy-finder)

    echo 'Git hard reset to ref '${target_commit}
    git reset --hard ${target_commit}
}
alias ghrk="ghard-reset-fz"

function ghard-reset-tags()
{
    # ghard-reset $target_commit
    ghard-reset $(git tag -l | default-fuzzy-finder)
}
alias ghrt="ghard-reset-tags"

function ghard-reset-flog()
{
    target_commit=$(gflog | default-fuzzy-finder | awk '{print $1}')
    ghard-reset ${target_commit}
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

# gtool gol: git clone and enter repo directory
function gol()
{
    # git clone and enter repo directory
    git_url=$1

    if [ -z "$2" ]
    then
        git_repo=$(basename $git_url)
        git_repo=${git_repo%.*}
        git clone $git_url
        cd $git_repo
    else
        git_repo=$2
        git clone $git_url $git_repo
        cd $git_repo
    fi
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

# gtool gcount: count commits in current ref
function gcount()
{
    total_commits=$(gh $1 | wc -l)
    echo 'There are'$total_commits' commits in current local branch'
}

function gcount-today()
{
    total_commits=$(gh  --since="1am" | wc -l)
    echo 'Today, there are'$total_commits' commits in current local branch'
}

# gtool gcount-commits: count commits between two refs
function gcount-commits()
{
    old_commit=$1
    new_commit=$2

    number_commits=$(($(git rev-list --count $old_commit..$new_commit) - 1))

    echo 'There are '$number_commits' commits of difference between revisions'
}

function gcountbranches()
{
    python3 $GIT_TOOLS_DIR/python/gcount_branch.py $1 $2
}

# gtool gstats-short: get commit stats
function gstats-short()
{
    git log --author="$1" --oneline --shortstat $2
}

function random-commit-msg()
{
    # generate a random commit message
    curl -s whatthecommit.com/index.txt
}

# gtool gcreate-random-commits: create random commits
function gcreate-random-commits()
{
    
    if [ -z "$1" ]
    then
        number_commits=1
    else
        number_commits=$1
    fi

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
            # generate random messages
            git commit -m "$(random-commit-msg)"
        done
}

# Git Internals
# function gstats-repo()
# {
#     echo $1
# }

# gtool gremove-from-tree: remote file from git tree
function gremove-from-tree()
{
    remove_target=$1
    git filter-branch -f --tree-filter "rm -rf $remove_target" --prune-empty HEAD
}

# gtool gignore-file: add file to .gitignore file
function gignore-file()
{
    python3 ${GIT_TOOLS_DIR}/python/gignore_file.py $(abspath $1)
}

# gtool gopen-commit-files-in-sublime: open commit files in sublime (alias gts)
function gopen-commit-files-in-sublime()
{
    if [ -z "$1" ]
    then
        target_ref=HEAD
    else
        target_ref=$1
    fi

    current_dir=$PWD

    gt-root

    for file_name in `git diff-tree --no-commit-id --name-only -r ${target_ref}`;
    do
        s $file_name
    done

    cd ${current_dir}
}
alias gts="gopen-commit-files-in-sublime"
