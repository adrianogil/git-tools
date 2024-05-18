
function gt-stage-count() {

  # Count the number of files in HEAD
  local head_count=$(git ls-tree -r HEAD --name-only | wc -l)

  # Count the number of files in the staging area
  local stage_count=$(git diff --name-only --cached | wc -l)

  # Count the number of files in the worktree
  local worktree_count=$(git ls-files --others --exclude-standard | wc -l)

  echo "HEAD:     $head_count"
  echo "Stage:    $stage_count"
  echo "Worktree: $worktree_count"
}
alias gt-st-count="gt-status-count"


function gt-status-count() {
    # Files staged for commit (A, M, or D in the index relative to HEAD)
    echo "Files to be committed: $(git status --porcelain | grep '^[AMDR]' | wc -l)"
    # Files not staged for commit (M or D in the working tree relative to the index)
    echo "Files not staged for commit: $(git status --porcelain | grep '^.[MD]' | wc -l)"
}
alias gs-count="gt-status-count"


# gtool gstats-short: get commit stats
function gt-stats-short()
{
    git log --author="$1" --oneline --shortstat $2
}
alias gstats-short="gt-stats-short"

# gtool gt-stats-by-author: Stats by author
function gt-stats-by-author()
{
    target_ref=HEAD
    git shortlog ${target_ref} --numbered --summary
}

# gtool gt-stats-summarize: Summarize repository
function gt-stats-summarize()
{
    # Ensure we are in a git repository
    if [ ! -d .git ]; then
        echo "Not a git repository. Please navigate to a git repository."
        return 1
    fi

    echo "### Repository Summary ###"
    echo

    # Repository details
    echo "Repository: $(basename "$(git rev-parse --show-toplevel)")"
    echo "Remote URL: $(git config --get remote.origin.url)"
    echo "Total number of commits: $(git rev-list --count HEAD)"
    echo "Size: $(du -sh .git | cut -f1)"
    echo

    # Summary of files (count each extension)
    echo "### Files Summary ###"
    echo
    git ls-files | sed 's/.*\.//' | sort | uniq -c | sort -nr
    echo

    # Summary of contributors
    echo "### Contributors ###"
    echo
    git shortlog -sn
    echo

    # Branches
    echo "### Most recent Branches ###"
    echo
    # List 5 most recent branches
    git branch --sort=-creatordate | head -n 5
    echo

    # Tags
    # Check if there are tags
    if [ -z "$(git tag)" ]; then
        echo "No tags found."
    else
        echo "### Most recent Tags ###"
        echo
        # List 5 most recent tags
        git tag --sort=-creatordate | head -n 5
        echo
    fi

    # Latest commit
    echo "### Latest Commit ###"
    echo
    git log -1 --pretty=format:"Commit: %H%nAuthor: %an%nDate: %ad%nMessage: %s"
    echo
    echo
}
