
# gtool gt-rename-url - Rename url of a target remote
function gt-rename-url()
{
    if [ -z "$2" ]
    then
        echo "Type target remote name: "
        read remote_name
        echo "Type new remote URL: "
        read remote_url
    else
        remote_name=$1
        remote_url=$2
    fi

    git remote set-url ${remote_name} ${remote_url}
}
