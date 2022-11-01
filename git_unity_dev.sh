# Unity dev

alias gunity-all='git add Assets/ ProjectSettings/ '

function gunity-meta-all()
{
    f '*.meta' $1 | xargs -I {} git add {}
}


function gunity-check-meta()
{
    ASSETS_DIR="$(git config --get unity3d.assets-dir || echo "Assets")"

    if git rev-parse --verify HEAD >/dev/null 2>&1
    then
        against=HEAD
    else
        # Initial commit: diff against an empty tree object
        against=4b825dc642cb6eb9a060e54bf8d69288fbee4904
    fi

    # Redirect output to stderr.
    exec 1>&2

    git -c diff.renames=false diff --cached --name-only --diff-filter=A -z $against -- "$ASSETS_DIR" | while read -d $'\0' f; do
        ext="${f##*.}"
        base="${f%.*}"
        filename="$(basename "$f")"

        if [ "$ext" = "meta" ]; then
            if [ $(git ls-files --cached -- "$base" | wc -l) = 0 ]; then
                echo "Meta file \`$f' is added, but \`$base' is not in the git index."
                return
            fi
        elif [ "${filename##.*}" != '' ]; then
            p="$f"
            while [ "$p" != "$ASSETS_DIR" ]; do
                if [ $(git ls-files --cached -- "$p.meta" | wc -l) = 0 ]; then
                    echo "Asset \`$f' is added, but \`$p.meta' is not in the git index."
                    echo "Please add \`$p.meta' to git as well."
                    return
                fi
                p="${p%/*}"
            done
        fi
    done

    ret="$?"
    if [ "$ret" != 0 ]; then
        exit "$ret"
    fi

    git -c diff.renames=false diff --cached --name-only --diff-filter=D -z $against -- "$ASSETS_DIR" | while read -d $'\0' f; do
        ext="${f##*.}"
        base="${f%.*}"

        if [ "$ext" = "meta" ]; then
            if [ $(git ls-files --cached -- "$base" | wc -l) != 0 ]; then
                echo "Error: Missing meta file."
                echo "Meta file \`$f' is removed, but \`$base' is still in the git index."
                echo "Please revert the beta file or remove the asset file."
                return
            fi
        else
            p="$f"
            while [ "$p" != "$ASSETS_DIR" ]; do
                if [ $(git ls-files --cached -- "$p" | wc -l) = 0 ] && [ $(git ls-files --cached -- "$p.meta" | wc -l) != 0 ]; then
                    echo "Error: Redudant meta file."
                    echo "Asset \`$f' is removed, but \`$p.meta' is still in the git index."
                    echo "Please remove \`$p.meta' from git as well."
                    return
                fi
                p="${p%/*}"
            done
        fi
    done
}