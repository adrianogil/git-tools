
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

    # Load reviewers from a file (one email per line)
    reviewers_file="$(gt-meta-get-path)/reviewers.txt"
    if [ -f "$reviewers_file" ]; then
        reviewers=$(paste -sd, "$reviewers_file")  # Join emails into a comma-separated string
        git push "${target_remote}" HEAD:refs/for/"${target_branch}"%r="${reviewers}"
    else
        echo "Reviewers file not found: ${reviewers_file}"
        git push "${target_remote}" HEAD:refs/for/"${target_branch}"
    fi
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

# gtool gt-gerrit-reviewers-add: Add a reviewer to the list
function gt-gerrit-reviewers-add() {
    reviewers_file="$(gt-meta-get-path)/reviewers.txt"

    # Check if an email was provided as an argument
    if [ -z "$1" ]; then
        echo -n "Enter the reviewer's email address: "
        read reviewer_email
    else
        reviewer_email=$1
    fi

    # Check if the email is empty after prompting
    if [ -z "$reviewer_email" ]; then
        echo "No email address provided. Exiting."
        return 1
    fi

    # Check if the email already exists in the file
    if grep -qx "$reviewer_email" "$reviewers_file"; then
        echo "Reviewer $reviewer_email is already in the list."
    else
        echo "$reviewer_email" >> "$reviewers_file"
        echo "Reviewer $reviewer_email added to the list."
    fi
}

# gtool gt-gerrit-reviewers: Show the list of reviewers
function gt-gerrit-reviewers() {
    reviewers_file="$(gt-meta-get-path)/reviewers.txt"

    echo "Reading reviewers from $reviewers_file:"

    if [ -f "$reviewers_file" ]; then
        cat "$reviewers_file"
    else
        echo "No reviewers found."
    fi
}

