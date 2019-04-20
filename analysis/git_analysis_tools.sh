
function gt-analysis-productivity()
{
    git_flags=$1
    python3 ${GIT_TOOLS_DIR}/analysis/prod_analysis.py $git_flags
}