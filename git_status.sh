
function gt-status-count() {
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
