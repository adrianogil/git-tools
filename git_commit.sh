# Utilities that creates or edit commits

function _gt_cc_prompt()
{
    prompt_message=$1
    printf "%s" "$prompt_message" >&2
    if IFS= read -r gt_cc_prompt_result
    then
        return 0
    fi

    gt_cc_prompt_result=""
    return 1
}

function _gt_cc_type_from_number()
{
    target_number=$1
    current_number=1

    for conventional_type in feat fix docs style refactor perf test build ci chore revert
    do
        if [ "$current_number" = "$target_number" ]
        then
            printf "%s" "$conventional_type"
            return 0
        fi

        current_number=$((current_number + 1))
    done

    return 1
}

function _gt_cc_is_known_type()
{
    target_type=$1

    for conventional_type in feat fix docs style refactor perf test build ci chore revert
    do
        if [ "$conventional_type" = "$target_type" ]
        then
            return 0
        fi
    done

    return 1
}

function _gt_cc_print_message()
{
    commit_type=$1
    commit_scope=$2
    commit_subject=$3
    commit_body=$4

    if [ -n "$commit_scope" ]
    then
        printf "%s(%s): %s\n" "$commit_type" "$commit_scope" "$commit_subject"
    else
        printf "%s: %s\n" "$commit_type" "$commit_subject"
    fi

    if [ -n "$commit_body" ]
    then
        printf "\n%s\n" "$commit_body"
    fi
}

# gtool gt-conventional-commit: Create a Conventional Commits message interactively
function gt-conventional-commit()
{
    print_only=0

    while [ $# -gt 0 ]
    do
        case "$1" in
            --print|--preview|--dry-run)
                print_only=1
                ;;
            --help|-h)
                echo "Usage: gt-conventional-commit [--print]"
                echo "Interactively build a Conventional Commits message and commit with it."
                echo "Use --print, --preview, or --dry-run to only print the generated message."
                return 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Usage: gt-conventional-commit [--print]"
                return 1
                ;;
        esac

        shift
    done

    echo "Conventional commit type:"
    current_number=1
    for conventional_type in feat fix docs style refactor perf test build ci chore revert
    do
        printf "  %2d) %s\n" "$current_number" "$conventional_type"
        current_number=$((current_number + 1))
    done

    while :
    do
        _gt_cc_prompt "Type [feat]: "
        selected_type=$gt_cc_prompt_result

        if [ -z "$selected_type" ]
        then
            selected_type=feat
            break
        fi

        case "$selected_type" in
            *[!0-9]*)
                if _gt_cc_is_known_type "$selected_type"
                then
                    break
                fi

                case "$selected_type" in
                    *[!A-Za-z0-9_-]*)
                        echo "Invalid type. Use one of the listed types, a number, or a custom alphanumeric type."
                        ;;
                    *)
                        break
                        ;;
                esac
                ;;
            *)
                selected_type=$(_gt_cc_type_from_number "$selected_type")
                if [ -n "$selected_type" ]
                then
                    break
                fi

                echo "Invalid type number."
                ;;
        esac
    done

    while :
    do
        _gt_cc_prompt "Scope (optional): "
        commit_scope=$gt_cc_prompt_result

        case "$commit_scope" in
            *" "*|*"("*|*")"*|*":"*)
                echo "Invalid scope. Avoid spaces, parentheses, and colons."
                ;;
            *)
                break
                ;;
        esac
    done

    while :
    do
        _gt_cc_prompt "Subject: "
        commit_subject=$gt_cc_prompt_result

        if [ -n "$commit_subject" ]
        then
            break
        fi

        echo "Subject is required."
    done

    echo "Description/body (optional). Press Enter on an empty line to finish."
    commit_body=""
    while :
    do
        _gt_cc_prompt "> "
        commit_body_line=$gt_cc_prompt_result

        if [ -z "$commit_body_line" ]
        then
            break
        fi

        if [ -z "$commit_body" ]
        then
            commit_body=$commit_body_line
        else
            commit_body="${commit_body}
${commit_body_line}"
        fi
    done

    echo
    echo "Commit message:"
    echo "----------------"
    _gt_cc_print_message "$selected_type" "$commit_scope" "$commit_subject" "$commit_body"
    echo "----------------"

    if [ "$print_only" = "1" ]
    then
        return 0
    fi

    _gt_cc_prompt "Commit with this message? [y/N] "
    confirm_commit=$gt_cc_prompt_result

    case "$confirm_commit" in
        y|Y|yes|YES)
            message_file=$(mktemp "${TMPDIR:-/tmp}/gt-conventional-commit.XXXXXX") || return 1
            _gt_cc_print_message "$selected_type" "$commit_scope" "$commit_subject" "$commit_body" > "$message_file"
            git commit -F "$message_file"
            commit_status=$?
            rm -f "$message_file"
            return $commit_status
            ;;
        *)
            echo "Commit cancelled."
            return 0
            ;;
    esac
}
alias gt-cc='gt-conventional-commit'

# gtool gt-pop-last-commits: Pop the last N commits
function gt-pop-last-commits()
{
    target_number_commits=$1
    if [ -z "$target_number_commits" ]
    then
        read -p "Enter the number of commits to pop: " target_number_commits
    fi

    if [ -z "$target_number_commits" ]
    then
        echo "Invalid number of commits: $target_number_commits"
        return 1
    fi

    git reset --hard HEAD~$target_number_commits
}
alias gpop='gt-pop-last-commits'

# gtool gt-commit: Create a new commit for author 'adrianogil.san@gmail.com'
function gt-commit()
{
    # Commit as Adriano Gil (personal email)
    git commit --author='Adriano Gil <adrianogil.san@gmail.com>'
}

# gtool gt-squash: Squash last N commits
function gt-squash() {
    N=$1
    MSG=$2

    if [[ -z "$N" ]]; then
        read -p "Enter the number of commits to squash: " N
    fi

    if [[ -z "$N" || "$N" -le 0 ]]; then
        echo "Invalid number of commits: $N"
        return 1
    fi

    # Get the last commit message if no message is provided
    if [[ -z "$MSG" ]]; then
        read -p "Enter the commit message [leave empty to use last commit's message]: " MSG
        if [[ -z "$MSG" ]]; then
          MSG=$(git log --format=%B -n 1 HEAD~$((N-1)))
        fi
    fi

    # Decrement N by 1 because we want to keep the earliest commit
    ((N--))

    git reset --soft HEAD~"$N" && git commit --amend -m "$MSG"
}

# gtool gt-squash-until: Squash until a specific commit
function gt_squash_until()
{
    target_commit=$1
    if [ -z "$target_commit" ]
    then
        read -p "Enter the target commit (hash or ref): " target_commit
    fi

    if [ -z "$target_commit" ]
    then
        echo "Invalid target commit: $target_commit"
        return 1
    fi

    git reset --soft $target_commit && git commit --amend --no-verify
}
alias gt-squash-until=gt_squash_until

# gtool gt-zip-repo: Zips a target commit
function gt-zip-repo()
{
    zip_name=$1

    if [ -z "$zip_name" ]
    then
        zip_name=$(basename $(git rev-parse --show-toplevel))
    fi

    if [ -z "$2" ]
    then
        target_ref=HEAD
    else
        target_ref=$2
    fi

    echo "Zipping repository to $zip_name.zip"
    git archive -o ${zip_name}.zip ${target_ref}
}

# gtool gt-pick-commits: Reorder commits
function gt-pick-commits() {
    python3 -m gittools.pick $*
}
alias gpick='gt-pick-commits'

# gtool gt-commit-generate-date-msg: Generate commit message
function gt-commit-generate-date-msg()
{
    commit_message="Updated changes at "$(date +%F-%H:%M)
    echo "Generating commit: "$commit_message
    gc -m "$commit_message"
}
alias gcm="gt-commit-generate-date-msg"

alias gc='git commit '
alias gcnov='gc --no-verify '
alias gm='git commit -m '
alias gca='git commit --amend '
alias gcanov='gca --no-verify '
alias gcg="git commit --author='Adriano Gil <adrianogil.san@gmail.com>'"
alias git-author-update="gc --amend --author='Adriano Gil <adrianogil.san@gmail.com>'"
