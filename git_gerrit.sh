
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
        git push "${target_remote}" HEAD:refs/for/"${target_branch}"%"${reviewers}"
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
        echo "r=$reviewer_email" >> "$reviewers_file"
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

# gtool gt-gerrit-reviewers-file-open: Open the reviewers file in the default editor
function gt-gerrit-reviewers-file-open() {
    reviewers_file="$(gt-meta-get-path)/reviewers.txt"

    if [ -f "$reviewers_file" ]; then
        $EDITOR "$reviewers_file"
    else
        echo "Reviewers file not found: $reviewers_file"
    fi
}

function gt-gerrit-open-cr() {
  local commit="${1:-HEAD}"
  local remote="${GERRIT_REMOTE:-origin}"

  # 1) Grab Change-Id from commit message body (first match wins).
  local change_id
  change_id="$(git log -1 --format=%B -- "$commit" 2>/dev/null | awk '/^[Cc]hange-[Ii][Dd]:/{print $2; exit}')"

  if [[ -z "$change_id" ]]; then
    echo "Error: no Change-Id found in commit '$commit'." >&2
    echo "Hint: Gerrit Change-Id lines look like:  Change-Id: Ixxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" >&2
    return 1
  fi

  # 2) Determine Gerrit web base.
  local base=""
  if [[ -n "$GERRIT_WEB" ]]; then
    base="${GERRIT_WEB%/}"
  else
    # Try deriving from git remote URL.
    local rurl
    rurl="$(git remote get-url --push "$remote" 2>/dev/null || git remote get-url "$remote" 2>/dev/null)"
    if [[ -z "$rurl" ]]; then
      echo "Error: could not get remote URL for '$remote'." >&2
      echo "Set GERRIT_WEB, e.g.: export GERRIT_WEB=https://review.company.com" >&2
      return 1
    fi

    # Common cases:
    #  - https://review.company.com/a/project.git      -> https://review.company.com
    #  - https://review.company.com/gerrit/project.git -> https://review.company.com/gerrit
    #  - ssh://user@review.company.com:29418/project.git
    #  - user@review.company.com:project.git
    if [[ "$rurl" =~ ^https?:// ]]; then
      # Split scheme://host[:port]/path...
      local scheme host rest path firstseg
      scheme="${rurl%%://*}://"
      rest="${rurl#*://}"
      host="${rest%%/*}"     # host[:port]
      path="${rest#*/}"      # may be 'a/project.git' or 'gerrit/project.git' etc.

      base="${scheme}${host}"

      # Heuristic for optional prefix:
      # If path starts with 'a/', strip it. If it looks like '<prefix>/<project>.git', keep the prefix.
      if [[ "$path" == a/* ]]; then
        : # authenticated HTTP path, UI uses just host root
      else
        firstseg="${path%%/*}"
        # If first segment is not the project itself (ends with .git), assume it's a Gerrit prefix like 'gerrit'
        if [[ ! "$firstseg" =~ \.git$ && "$firstseg" != "$path" ]]; then
          base="${base}/${firstseg}"
        fi
      fi
    else
      # SSH forms
      if [[ "$rurl" =~ ^ssh:// ]]; then
        local rest hostport
        rest="${rurl#ssh://}"
        hostport="${rest%%/*}"                  # user@host:port
        hostport="${hostport##*@}"              # host:port
        hostport="${hostport%:*}"               # host
        base="https://${hostport}"
      else
        # scp-like: user@host:project.git OR host:project.git
        local hostpart
        hostpart="${rurl%%:*}"
        hostpart="${hostpart##*@}"
        base="https://${hostpart}"
      fi
    fi
  fi

  # 3) Build a PolyGerrit search URL for the Change-Id and open it.
  # This lands on the exact change (or search results, if multiple).
  local url="${base%/}/q/${change_id}"

  # Cross-platform opener
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$url" >/dev/null 2>&1 &
  elif command -v open >/dev/null 2>&1; then
    open "$url"
  elif command -v cygstart >/dev/null 2>&1; then
    cygstart "$url"
  elif grep -qi microsoft /proc/version 2>/dev/null; then
    powershell.exe -NoProfile -Command "Start-Process '$url'" >/dev/null 2>&1
  else
    echo "$url"
  fi
}
