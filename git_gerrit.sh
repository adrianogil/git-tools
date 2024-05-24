
# gtool gt-gerrit-patches-update: Update gerrit patches list
function gt-gerrit-patches-update()
{
    gt-meta-init
	gerrit patches > $(gt-meta-get-path)/gerrit_patches.txt
}
alias gepu="gt-gerrit-patches-updates"

# gtool gt-gerrit-patches: Show gerrit patches for current repo
function gt-gerrit-patches()
{
    gt-meta-init
    cat $(gt-meta-get-path)/gerrit_patches.txt
}
alias gep="gt-gerrit-patches"

# gtool gt-gerrit-checkout: Select a gerrit patch and checkout it
function gt-gerrit-checkout()
{
	target_patch=$(gerrit patches | tail -n +2 | default-fuzzy-finder | awk '{print $1}')
	echo "Checkout patch "${target_patch}
	gerrit checkout ${target_patch}
}

# gtool gt-push2gerrit: push commit to gerrit
function gt-push2gerrit()
{
    if [ -z "$1" ]
    then
        complete_branch_name=$(gt-branches-fz)
        target_branch=$(python3 -m gittools.cli.removeremotename ${complete_branch_name})
        target_remote=$(python3 -m gittools.cli.removeremotename ${complete_branch_name} --get-only-remote)
    else
        target_branch=$1
        target_remote=origin
    fi

    git push ${target_remote} HEAD:refs/for/${target_branch}
}

function gt-gerrit-open-patch()
{
    if [ -z "$1" ]
    then
        target_patch=$(gerrit patches | tail -n +2 | default-fuzzy-finder | awk '{print $1}')
    else
        target_patch=$1
    fi

    gerrit open ${target_patch}
}