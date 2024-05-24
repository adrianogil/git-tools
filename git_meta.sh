export GIT_META_FOLDER=$HOME/.metagit
export GIT_META_REPOS_FOLDER=$GIT_META_FOLDER/repos/


function gt-meta-get-path() {
    # Get the absolute path of the Git root
    local meta_path="$(git rev-parse --show-toplevel)"
    # remove the HOME Path
    local meta_path=${meta_path/$HOME\//}
    # replace the / with .
    local meta_path=${meta_path//\//.}

    echo "$GIT_META_REPOS_FOLDER$meta_path"
}

function gt-meta-init() {

    local meta_path = $(gt-meta-get-path)

    if [ ! -d $meta_path ]; then
        mkdir -p $meta_path
    fi

    return $meta_path
}