

alias gignore-file-hard='git update-index --assume-unchanged '

# gtool gignore-file: add file to .gitignore file
function gignore-file()
{
    if [ -z "$1" ]
    then
        target_file=$(git ls-files --others --exclude-standard | default-fuzzy-finder)
    else
        target_file=$1
    fi

    python3 ${GIT_TOOLS_DIR}/python/gignore_file.py $(abspath $target_file)
}

# gtool gignore-add-gitignore: add .gitignore file from template
function gignore-add-gitignore()
{
    if [ -z "$1" ]
    then
        project_type=$(echo -e "python\nnodejs\nunity3d\nlatex" | default-fuzzy-finder)
    else
        project_type=$1
    fi

    git_root_path=$(git rev-parse --show-toplevel)
    cat ${GIT_TOOLS_DIR}/templates/gitignore/${project_type}_gitignore.txt >> ${git_root_path}/.gitignore
}

# gtool gignore-set-global-ignore: set global ignore file
function gignore-set-global-ignore()
{
    global_ignore_file=$1
    if [ -z "$global_ignore_file" ]
    then
        global_ignore_file=${GIT_TOOLS_DIR}/gitignore_global
    fi

    git config --global core.excludesfile ${global_ignore_file}
}
