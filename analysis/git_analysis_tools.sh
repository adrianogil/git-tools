
function gt-analysis-productivity()
{
    git_flags=$1
    python3 ${GIT_TOOLS_DIR}/analysis/prod_analysis.py $git_flags
}

function gt-stats-by-author()
{
    target_ref=HEAD
    git shortlog ${target_ref} --numbered --summary
}

