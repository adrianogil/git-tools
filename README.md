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
gh # show commit graph, similar to git log --oneline --graph
```

Commands related to push commits
```
gp # alias to git push
gt-send-to-branch # uses a fuzzy-finder to select a branch
gbranches-summary # summarize local/remote counts, branch with most commits, and newest branch commit
```

Commands related to commits
```
gt-conventional-commit # interactively create a Conventional Commits message and commit
gt-cc                  # short alias for gt-conventional-commit
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
