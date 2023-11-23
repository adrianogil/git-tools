
# gtool gt-rename-url - Rename url of a target remote
function gt-rename-url()
{
    if [ -z "$1" ]
    then
        remote_name=$(git remote| default-fuzzy-finder)
    else
        remote_name=$1
    fi

    if [ -z "$2" ]
    then
        echo "Type new remote URL: "
        read remote_url
    else
        remote_url=$2
    fi

    git remote set-url ${remote_name} ${remote_url}
}
