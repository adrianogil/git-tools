
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