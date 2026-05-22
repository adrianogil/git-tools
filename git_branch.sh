# gtool gt-branches-fz: List branches and select one
function gt-branches-fz()
{
    if [[ $(git branch -r | grep -v "/HEAD " | wc -l) -le 1 ]]; then
        git branch -r | grep -v "/HEAD " | cut -c3- | head -1
    else
        git branch -r | grep -v "/HEAD " | cut -c3- | default-fuzzy-finder
    fi
}
alias gbk='gt-branches-fz'

# gtool gt-branches-origin-fz: List branches from origin and select one
function gt-branches-origin-fz()
{
    complete_branch_name=$(gt-branches-fz)
    only_branch_name=$(python3 -m gittools.cli.removeremotename ${complete_branch_name})
    echo ${only_branch_name}
}
alias gbko='gt-branches-origin-fz'

# gtool gt-branch-delete: Delete a target branch (local and remotely)
function gt-branch-delete()
{
    if [ -z "$1" ]
    then
        target_branch=$(gbko)
    else
        target_branch=$1
    fi

    if [ -z "$target_branch" ]
    then
        echo "Branch to be deleted:"
        read target_branch
    fi

    if [ -z "$target_branch" ]
    then
          echo "No branch selected"
    else
          git push origin :${target_branch}
        git branch -d ${target_branch}
    fi
}

# gtool gt-branch-local-delete: Delete a target branch (local only)
function gt-branch-local-delete()
{
    if [ -z "$1" ]
    then
        target_branch=$(git branch -l | grep -v "*" | default-fuzzy-finder)
    else
        target_branch=$1
    fi

    if [ -z "$target_branch" ]
    then
        echo "Branch to be deleted:"
        read target_branch
    fi

    if [ -z "$target_branch" ]
    then
          echo "No branch selected"
    else
        git branch -d ${target_branch}
    fi
}

# gtool gt-branch-set-upstream: set branch upstream
function gt-branch-set-upstream()
{
    target_upstream_remote_branch=$1

    if [ -z "$target_upstream_remote_branch" ]
    then
        target_upstream_remote_branch=$(gbk)
    fi

    git branch --set-upstream-to=${target_upstream_remote_branch}
}
alias gbupstream='gt-branch-set-upstream'

alias gbranch='git branch'

# gtool gt-branches-summary: summarize local/remote branch counts and highlights
function gt-format-unix-time-utc()
{
    local timestamp=$1

    if [ -z "$timestamp" ]; then
        echo ""
        return
    fi

    if command -v python3 >/dev/null 2>&1; then
        python3 - "$timestamp" <<'PY'
import datetime
import sys

ts = int(sys.argv[1])
print(datetime.datetime.fromtimestamp(ts, datetime.timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC'))
PY
        return
    fi

    if date -u -d "@${timestamp}" '+%Y-%m-%d %H:%M:%S UTC' >/dev/null 2>&1; then
        date -u -d "@${timestamp}" '+%Y-%m-%d %H:%M:%S UTC'
        return
    fi

    if date -u -r "${timestamp}" '+%Y-%m-%d %H:%M:%S UTC' >/dev/null 2>&1; then
        date -u -r "${timestamp}" '+%Y-%m-%d %H:%M:%S UTC'
        return
    fi

    echo "${timestamp}"
}

function gt-branches-summary()
{
    local local_count remote_count branch branch_count commit_count
    local top_branch="" top_count=-1
    local newest_branch="" newest_ts=0
    local newest_time_formatted=""

    local_count=$(git for-each-ref refs/heads --format='%(refname:short)' | wc -l)
    remote_count=$(git for-each-ref refs/remotes --format='%(refname:short)' | grep -v '/HEAD$' | wc -l)

    while IFS='|' read -r branch_count branch commit_count
    do
        if [ -z "$branch" ]; then
            continue
        fi

        if [ "$commit_count" -gt "$top_count" ]; then
            top_count=$commit_count
            top_branch=$branch
        fi

        if [ "$branch_count" -gt "$newest_ts" ]; then
            newest_ts=$branch_count
            newest_branch=$branch
        fi
    done < <(
        git for-each-ref refs/heads refs/remotes --format='%(committerdate:unix)|%(refname:short)' \
            | grep -v '/HEAD$' \
            | while IFS='|' read -r ts refname
              do
                  printf '%s|%s|%s\n' "$ts" "$refname" "$(git rev-list --count "$refname")"
              done
    )

    if [ -n "$newest_branch" ]; then
        newest_time_formatted=$(gt-format-unix-time-utc "$newest_ts")
    fi

    echo "Local branches: ${local_count}"
    echo "Remote branches: ${remote_count}"

    if [ -n "$top_branch" ]; then
        echo "Branch with most commits: ${top_branch} (${top_count} commits)"
    else
        echo "Branch with most commits: n/a"
    fi

    if [ -n "$newest_branch" ]; then
        echo "Branch with most recent commit: ${newest_branch} (${newest_time_formatted})"
    else
        echo "Branch with most recent commit: n/a"
    fi
}
alias gbranches-summary='gt-branches-summary'
