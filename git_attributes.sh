function gcreate-attributes-python()
{
    path=$1

    py_attributes_from_github=https://raw.githubusercontent.com/alexkaratarakis/gitattributes/master/Python.gitattributes

    curl $py_attributes_from_github >> $path/.attributes
}
alias gt-attributes-python="gcreate-attributes-python"
