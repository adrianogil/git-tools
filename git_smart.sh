# gtool gsmart-add: add files based on project type
function gsmart-add()
{
    min_py_proj_dir=2

    if [ "$(ls *.py 2> /dev/null | wc -l)" -gt "$min_py_proj_dir" ]; then
        echo 'Python project identified'
        git add *.py
    elif [ "$(ls *.sh 2> /dev/null | wc -l)" -gt "$min_py_proj_dir" ]; then
        echo 'Shell project identified'
        git add *.sh
    elif [ "$(ls *.tex 2> /dev/null | wc -l)" -gt "$min_py_proj_dir" ]; then
        echo 'LaTeX project identified'
        git add *.tex *.bib
    elif [ -f "package.json" ]; then
        echo 'Node project identified'
        git add package.json *.js
    else
        echo 'Unknown project'
    fi
}
alias gas="gsmart-add"
