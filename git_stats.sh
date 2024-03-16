
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

