source ${GIT_TOOLS_DIR}/git_config.sh
source ${GIT_TOOLS_DIR}/git_smart.sh
source ${GIT_TOOLS_DIR}/personal_aliases.sh
source ${GIT_TOOLS_DIR}/git_repos.sh
source ${GIT_TOOLS_DIR}/git_stage.sh
source ${GIT_TOOLS_DIR}/git_commit.sh
source ${GIT_TOOLS_DIR}/git_internals.sh
source ${GIT_TOOLS_DIR}/git_attributes.sh
source ${GIT_TOOLS_DIR}/git_history.sh
source ${GIT_TOOLS_DIR}/git_navigation.sh
source ${GIT_TOOLS_DIR}/analysis/git_analysis_tools.sh

if [ -z "$GITTOOLS_PYTHON_PATH" ]
then
    export GIT_TOOLS_PYTHON_PATH=$GIT_TOOLS_DIR/python/
    export PYTHONPATH=$GIT_TOOLS_PYTHON_PATH:$PYTHONPATH
fi

# @tool gt-sk
function gt-sk()
{
    gitaction=$(cat ${GIT_TOOLS_DIR}/git_*.sh | grep '# gtool' | cut -c9- | sk)

    eval ${gitaction}
}
alias g="gt-sk"