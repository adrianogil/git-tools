# git-tools
A collection of aliases and tools for git

## Commands

Aliases to basic commands (All defined at personal_aliases.sh):
```
ga  # git add
ga  # git add -i
gc  # git commit
gca # git commit --amend
gflog # git reflog with a pretty format
```

Commands related to log history
```
gh              # show commit graph, similar to git log --oneline --graph
gt-file-history # follow one file's history across renames
```

### File history across renames

`gt-file-history` prints a concise, newest-first log for one path and uses
Git's rename-following history. Paths are resolved from the repository root,
so the command works from subdirectories and with deleted files, spaces,
Unicode, and leading dashes.

```bash
gt-file-history 'docs/file name.md'
gt-file-history -- '-leading-dash.txt'
```

Use `--diff REV` to show the patch that changed the file in a specific commit.
The helper resolves the filename used at that point in history, including before
one or more renames:

```bash
gt-file-history --diff HEAD~3 -- 'docs/file name.md'
```

Omit `REV` to select a commit with `default-fuzzy-finder` and show its file
patch:

```bash
gt-file-history --diff -- 'docs/file name.md'
```

Run `gt-file-history --help` for the complete command syntax. In a shallow
clone, fetch the missing history with `gt-unshallow` (`git fetch --unshallow`)
before tracing renames.

Commands related to fetching history
```bash
gt-unshallow        # fetch the missing history of a shallow clone
gt-unshallow origin # optionally specify a remote or other git fetch arguments
```

Commands related to push commits
```
gp # alias to git push
gt-send-to-branch # uses a fuzzy-finder to select a branch
gbranches-summary # summarize local/remote counts, branch with most commits, and newest branch commit
```

Commands related to merge and rebase
```
gt-merge              # preview commits from a remote branch, then merge after confirmation
gt-merge-local-branch # preview commits from a local branch, then merge after confirmation
gt-rebase             # preview incoming/replayed commits from a remote branch, then rebase after confirmation
gt-rebase-local-branch # preview incoming/replayed commits from a local branch, then rebase after confirmation
gt-conflicts          # summarize only unresolved conflicts and their conflict types
```

Set `GT_TOOLS_ASSUME_YES=1` to skip the confirmation prompt in scripts after the preview is printed.

Commands related to repositories
```
gt-repos # list directories below the current directory that contain a .git subdirectory
gt-repos-cd # choose one of those repositories with default-fuzzy-finder and cd into it
cdr # alias for gt-repos-cd
```

Commands related to commits
```
gt-conventional-commit # interactively create a Conventional Commits message and commit
gt-cc                  # short alias for gt-conventional-commit
gt-reflog-cherry-pick  # select a reflog commit with the configured fzf command and cherry-pick it
gflog-cereja           # short alias for gt-reflog-cherry-pick
```

Visualization
```
gt-repo-treemap # start a local Flask/D3 treemap for the current Git repo
gt-treemap      # short alias for gt-repo-treemap
```

Git internals
```
gt-file-object-path README.md
```

Prints the blob object id for the current contents of a tracked file, the loose-object path under `.git/objects`, and whether that loose object currently exists. It works from subdirectories and accepts either repository-relative paths or working-tree paths.

Example output:
```
repository: /tmp/example-repo
file: README.md
object_format: sha1
blob_oid: 9daeafb9864cf43055ae93beb0afd6c7d144bfa4
loose_object_path: /tmp/example-repo/.git/objects/9d/aeafb9864cf43055ae93beb0afd6c7d144bfa4
loose_object_exists: yes
```

Manual smoke test:
```
tmpdir=$(mktemp -d)
cd "$tmpdir"
git init
git config user.email test@example.com
git config user.name Test
printf 'hello world\n' > 'file with spaces.txt'
git add 'file with spaces.txt'
git commit -m 'add spaced file'
gt-file-object-path 'file with spaces.txt'
```

## Planned features
- Save and track each branch update
- Suggest commit message from "git diff --cached"

## Installation

### Recommended setup
Install using [gil-install command](https://github.com/adrianogil/gil-tools)

```
cd /<path-to>/git-tools/
gil-install -i
```

### Manual setup

Add the following lines to your bashrc:
```
export GIT_TOOLS_DIR=/<path-to>/git-tools/
source $GIT_TOOLS_DIR/bashrc.sh
```

And you should also define an alias default-fuzzy-finder to the fuzzy-finder you want to use. For example:

```bash
alias default-fuzzy-finder='fzf'
```

## Navigation helpers

- `gt-move-dir-from-change` (alias: `cdg`): choose a directory changed in a commit (defaults to `HEAD`) and `cd` into it.

## Contributing

Feel free to submit PRs. I will do my best to review and merge them if I consider them essential.

## Interesting Links

* [awesome-git-addons](https://github.com/stevemao/awesome-git-addons): very interesting commands you should check out:
    * recent
    * git-standup
    * [git interactive rebase tool](https://github.com/MitMaro/git-interactive-rebase-tool)
    * [diff-so-fancy](https://github.com/so-fancy/diff-so-fancy)
    * [awesome-git](https://github.com/dictcp/awesome-git)
    * [method_log](https://github.com/freerange/method_log): tool to analyze the change history of methods (see more on [this blog post](https://www.urbanautomaton.com/blog/2014/09/22/tracking-method-history-in-git/))
