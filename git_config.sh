# !/bin/bash
alias gabort="python3 -m gittools.abort"
alias gt-abort="gcontinue"

# gtool gt-config-show: Show the config file related to current git file
function gt-config-show()
{
    cat $(gt-get-root-path)/.git/config
}

# gtool gt-ckout: checkout a branch
function gt-cktout()
{
    target_branch=$(git branch -r | cut -c3- | default-fuzzy-finder)
    echo "Let's track a new branch: "$target_branch
    git checkout --track ${target_branch}
}

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
            target_remote=$(git remote | default-fuzzy-finder)
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

# gtool gt-code-root-path: Open root level as a project in VSCode
function gt-code-root-path()
{
    code $(gt-get-root-path)
}
alias cgroot="gt-code-root-path"


function gt-root-relative()
{
    # Check if the current directory is inside a Git repository
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
        echo "Not inside a Git repository"
        return 1
    }

    # Get the absolute path of the Git root
    local git_root="$(git rev-parse --show-toplevel)"

    # Get the absolute path of the current working directory
    local cwd="$(pwd)"

    # Get the relative path from the current directory to the Git root
    local relative_path="$(realpath --relative-to="$git_root" "$cwd")"

    # Print the relative path
    echo "./$relative_path"
}
alias groot-local="gt-root-relative"

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

function ghard-reset-fz() {
    # Build a nice list with:
    # <ref> | <short-hash> | <author> | <date> | <subject>
    local line ref

    line=$(
        git for-each-ref \
            --sort=-committerdate \
            --format='%(refname:short) | %(objectname:short) | %(authorname) | %(committerdate:short) | %(subject)' \
            refs/heads refs/remotes \
        | default-fuzzy-finder
    ) || return 1  # user aborted

    # Take only the first field (the ref name before the first '|')
    ref=$(awk -F'|' '{gsub(/^ *| *$/, "", $1); print $1}' <<< "$line")

    if [ -z "$ref" ]; then
        echo "No ref selected."
        return 1
    fi

    echo "Git hard reset to ref $ref"
    git reset --hard "$ref"
}
alias ghrfz="ghard-reset-fz"
alias gz="ghard-reset-fz"


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

function gcountbranches()
{
    python3 $GIT_TOOLS_DIR/python/gcount_branch.py $1 $2
}

# gtool random-commit-msg: generate random commit messages
function random-commit-msg() {
    subjects=("Fix" "Add" "Update" "Remove" "Refactor")
    predicates=("bug in authentication" "new feature for sorting" "readme file" "unused code" "database schema")

    subject_index=$(($RANDOM % ${#subjects[@]}))
    predicate_index=$(($RANDOM % ${#predicates[@]}))

    commit_message="${subjects[$subject_index]} ${predicates[$predicate_index]}"

    echo "$commit_message"
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

# gtool gopen-commit-files-in-sublime: open commit files in sublime (alias gts)
function gopen-commit-files-in-sublime()
{
    if [ -z "$1" ]
    then
        target_ref=$(gget)
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


# gtool gopen-commit-files-in-code: open commit files in code (alias gtc)
function gopen-commit-files-in-code()
{
    if [ -z "$1" ]
    then
        target_ref=$(gget)
    else
        target_ref=$1
    fi

    current_dir=$PWD

    gt-root

    for file_name in `git diff-tree --no-commit-id --name-only -r ${target_ref}`;
    do
        code $file_name
    done

    cd ${current_dir}
}
alias gtc="gopen-commit-files-in-code"


# gtool gt-config-user: configure user name and email
function gt-config-user()
{
    username=$1
    email=$2

    if [ -z "$username" ]
    then
        echo "Enter your Git username (default: gituser):"
        read username
        username=${username:-gituser}
    fi

    if [ -z "$email" ]
    then
        echo "Enter your Git email (default: gituser@example.com):"
        read email
        email=${email:-gituser@example.com}
    fi

    echo "name: "${username}
    echo "email: "${email}

    git config --global user.name "$username"
    git config --global user.email "$email"

    echo "Git user name and email set successfully!"
}
