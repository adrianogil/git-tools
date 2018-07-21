function gsmart-add()
{
    min_py_proj_dir=2

    if [ "$(ls *.py 2> /dev/null | wc -l)" -gt "$min_py_proj_dir" ]; then
        echo 'Python project identified'
        git add *.py
    elif [ "$(ls *.sh 2> /dev/null | wc -l)" -gt "$min_py_proj_dir" ]; then
        echo 'Shell project identified'
        git add *.sh
    else
        echo 'Unknown project'
    fi
    # git add *.py
}
