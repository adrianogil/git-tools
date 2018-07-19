function gsmart-add()
{
    min_py_proj_dir=2

    if [ "$(ls *.py 2> /dev/null | wc -l)" -gt "$min_py_proj_dir" ]; then
        echo 'Python project identified'
        git add *.py
    else
        echo 'Unknown project'
    fi
    # git add *.py
}
