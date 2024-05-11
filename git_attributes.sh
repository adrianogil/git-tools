function gcreate-attributes-python()
{
    path=$1

    py_attributes_from_github=https://raw.githubusercontent.com/alexkaratarakis/gitattributes/master/Python.gitattributes

    curl $py_attributes_from_github >> $path/.attributes
}
alias gt-attributes-python="gcreate-attributes-python"


#gtool gt-file-attributes: show file attributes
function gt-file-attributes()
{
    if [ -z "$1" ]
    then
        target_file=$(find . -not -path '*/\.*' | default-fuzzy-finder | cut -c3-)
    else
        target_file=$1
    fi

    git check-attr --all -- ${target_file}
}
