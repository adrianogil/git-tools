
# gtool gt-gerrit-patches-update: Update gerrit local patches list
function gt-gerrit-patches-update()
{
    gt-meta-init
	gerrit patches --oneline > $(gt-meta-get-path)/gerrit_patches.txt
}
alias gepu="gt-gerrit-patches-update"

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
	target_patch=$(gt-gerrit-patches | default-fuzzy-finder | awk '{print $1}')
	echo "Checkout patch "${target_patch}
	gerrit checkout ${target_patch}
}
alias gec="gt-gerrit-checkout"

# gtool gt-push2gerrit: push commit to gerrit
function gt-push2gerrit()
{
    if [ -z "$1" ]
    then
        complete_branch_name=$(gt-branches-fz)
        target_branch=$(echo "$complete_branch_name" | cut -d'/' -f2-)
        target_remote=$(echo "$complete_branch_name" | awk -F'/' '{print $1}')
    else
        target_branch=$1
        target_remote=origin
    fi

    git push ${target_remote} HEAD:refs/for/${target_branch}
}

# gtool gt-gerrit-open-patch: Open gerrit patch in browser
function gt-gerrit-open-patch()
{
    if [ -z "$1" ]
    then
        target_patch=$(cat $(gt-meta-get-path)/gerrit_patches.txt | default-fuzzy-finder | awk '{print $1}')
    else
        target_patch=$1
    fi

    gerrit open ${target_patch}
}
alias geop="gt-gerrit-open-patch"