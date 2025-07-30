
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
    git ls-files | awk -F. '{ if ($0 ~ /\.test\.js$/) print "test.js"; else print $NF }' | sort | uniq -c | while read count ext; do \
        loc=$(git ls-files | grep "\.${ext}$" | xargs wc -l 2>/dev/null | awk '{sum+=$1} END {print sum+0}'); \
        echo "$count $ext (LOC $loc)"; \
    done | sort -nr

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

# gtool gt-stats-commits-per-month: Commits per month
function gt-stats-commits-per-month() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: This is not a Git repository."
    return 1
  fi

  echo "### Commits Per Month ###"

  # Detect the `date` command type (GNU or BSD)
  if date --version >/dev/null 2>&1; then
    DATE_CMD="gnu" # GNU date
  else
    DATE_CMD="bsd" # BSD date (macOS)
  fi

  # Get the first commit's date
  first_commit_date=$(git log --reverse --format='%ad' --date=format:'%Y-%m' | head -n 1)
  if [ -z "$first_commit_date" ]; then
    echo "Error: No commits found in this repository."
    return 1
  fi

  # Loop through months from the first commit to the current month
  current_date=$(date '+%Y-%m')
  start_date="$first_commit_date"

  while [ "$start_date" != "$current_date" ]; do
    if [ "$DATE_CMD" = "gnu" ]; then
      # GNU date
      next_month=$(date -d "$start_date-01 +1 month" '+%Y-%m')
    else
      # BSD date (macOS)
      next_month=$(date -v+1m -jf "%Y-%m" "$start_date" "+%Y-%m")
    fi

    # Count commits and unique authors for the current month
    commit_count=$(git log --since="${start_date}-01" --until="${next_month}-01" --format='%h' | wc -l)
    unique_authors=$(git log --since="${start_date}-01" --until="${next_month}-01" --format='%ae' | sort | uniq | wc -l)
    echo "$start_date: $commit_count commits, $unique_authors unique authors"

    # Increment the month
    start_date="$next_month"
  done

  # Print the commits and authors for the current month
  if [ "$DATE_CMD" = "gnu" ]; then
    next_month=$(date -d "$current_date-01 +1 month" '+%Y-%m')
  else
    next_month=$(date -v+1m -jf "%Y-%m" "$current_date" "+%Y-%m")
  fi
  commit_count=$(git log --since="${current_date}-01" --until="${next_month}-01" --format='%h' | wc -l)
  unique_authors=$(git log --since="${current_date}-01" --until="${next_month}-01" --format='%ae' | sort | uniq | wc -l)
  echo "$current_date: $commit_count commits, $unique_authors unique authors"
}

# gtool gt-stats-author-commits-per-month: Author commits per month
function gt-stats-author-commits-per-month() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Error: This is not a Git repository."
        return 1
    fi

    # Select author
    author_data=$(git log --format='%aN: <%aE>' | sort -u | fzf --prompt="Select author: ")
    if [ -z "$author_data" ]; then
        echo "Error: No author selected."
        return 1
    fi

    author_name=$(echo ${author_data} | awk -F'[<>]' '{print $1}')
    author=$(echo ${author_data} | awk -F'[<>]' '{print $2}')

    echo "### Author Commits Per Month - ${author_name} ###"

    # Detect the `date` command type (GNU or BSD)
    if date --version >/dev/null 2>&1; then
        DATE_CMD="gnu" # GNU date
    else
        DATE_CMD="bsd" # BSD date (macOS)
    fi

    # Get the first commit's date by the selected author
    first_commit_date=$(git log --author="$author" --reverse --format='%ad' --date=format:'%Y-%m' | head -n 1)
    if [ -z "$first_commit_date" ]; then
        echo "Error: No commits found for author ${author_name}."
        return 1
    fi

    # Loop through months from the first commit to the current month
    current_date=$(date '+%Y-%m')
    start_date="$first_commit_date"

    while [ "$start_date" != "$current_date" ]; do
        if [ "$DATE_CMD" = "gnu" ]; then
            # GNU date
            next_month=$(date -d "$start_date-01 +1 month" '+%Y-%m')
        else
            # BSD date (macOS)
            next_month=$(date -v+1m -jf "%Y-%m" "$start_date" "+%Y-%m")
        fi

        # Count commits for the current month by the selected author
        commit_count=$(git log --author="$author" --since="${start_date}-01" --until="${next_month}-01" --format='%h' | wc -l)
        echo "$start_date: $commit_count commits"

        # Increment the month
        start_date="$next_month"
    done

    # Print commits for the current month by the selected author
    if [ "$DATE_CMD" = "gnu" ]; then
        next_month=$(date -d "$current_date-01 +1 month" '+%Y-%m')
    else
        next_month=$(date -v+1m -jf "%Y-%m" "$current_date" "+%Y-%m")
    fi
    commit_count=$(git log --author="$author" --since="${current_date}-01" --until="${next_month}-01" --format='%h' | wc -l)
    echo "$current_date: $commit_count commits"
}

# gtool gt-stats-commits-per-hour: commits by hour-of-day (00–23)
function gt-stats-commits-per-hour() {
    # ensure we’re in a Git repo
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Error: not a Git repository."
        return 1
    fi

    echo "### Commits Per Hour of Day ###"
    git log --date=format:'%H' --pretty=format:'%ad' \
    | awk '{
        count[$1]++
      }
      END {
        for (i = 0; i < 24; i++) {
          h   = sprintf("%02d", i)
          c   = (h in count ? count[h] : 0)
          lbl = (c == 1 ? "commit" : "commits")
          printf("%s:00-%s:59: %d %s\n", h, h, c, lbl)
        }
      }'
}

# gtool gt-stats-mean-commits-per-weekday: average commits per weekday (per week)
function gt-stats-mean-commits-per-weekday() {
    python3 -m gittools.stats.commits_per_weekday "$@"
}
