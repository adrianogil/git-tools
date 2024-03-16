source ${GIT_TOOLS_DIR}/git_history.sh
source ${GIT_TOOLS_DIR}/git_smart.sh
source ${GIT_TOOLS_DIR}/git_files.sh
source ${GIT_TOOLS_DIR}/git_config.sh
source ${GIT_TOOLS_DIR}/personal_aliases.sh
source ${GIT_TOOLS_DIR}/git_repos.sh
source ${GIT_TOOLS_DIR}/git_stage.sh
source ${GIT_TOOLS_DIR}/git_commit.sh
source ${GIT_TOOLS_DIR}/git_internals.sh
source ${GIT_TOOLS_DIR}/git_attributes.sh
source ${GIT_TOOLS_DIR}/git_navigation.sh
source ${GIT_TOOLS_DIR}/git_remote.sh
source ${GIT_TOOLS_DIR}/git_branch.sh
source ${GIT_TOOLS_DIR}/git_status.sh
source ${GIT_TOOLS_DIR}/git_tag.sh
source ${GIT_TOOLS_DIR}/git_merge.sh
source ${GIT_TOOLS_DIR}/git_diff.sh
source ${GIT_TOOLS_DIR}/git_unity_dev.sh
source ${GIT_TOOLS_DIR}/analysis/git_analysis_tools.sh
source ${GIT_TOOLS_DIR}/git_gerrit.sh
source ${GIT_TOOLS_DIR}/git_ignore.sh
source ${GIT_TOOLS_DIR}/git_stats.sh

if [ -z "$GITTOOLS_PYTHON_PATH" ]
then
    export GIT_TOOLS_PYTHON_PATH=$GIT_TOOLS_DIR/python/
    export PYTHONPATH=$GIT_TOOLS_PYTHON_PATH:$PYTHONPATH
fi

# @tool gt-fz: Git Tools
function gt-fz()
{
    gitaction=$(cat ${GIT_TOOLS_DIR}/git_*.sh | grep '# gtool' | cut -c9- | default-fuzzy-finder | tr ":" " " | awk '{print $1}')

    eval ${gitaction}
}
alias g="gt-fz"
