
# gtool gt-gerrit-patches: Show gerrit patches for current repo
function gt-gerrit-patches()
{
	gerrit patches
}

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
