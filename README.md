# git-tools
A collection of small tools for git

## Commands

Aliases to basic commands:
```
ga  # git add
ga  # git add -i
gc  # git commit
gca # git commit --amend
```

## Planned features
- Suggest commit message from "git diff --cached"

## Installation

### Recommended setup
Install using [gil-install command](https://github.com/adrianogil/gil-tools)

### Manual setup

Add the following lines to your bashrc:
```
export GIT_TOOLS_DIR=/<path-to>/git-tools/
source $GIT_TOOLS_DIR/bashrc.sh
```

## Contributing

Feel free to submit PRs. I will do my best to review and merge them if I consider them essential.

## Interesting Links

* [awesome-git-addons](https://github.com/stevemao/awesome-git-addons): very interesting commands you should check out
    * recent
    * git-standup
    * [git interactive rebase tool](https://github.com/MitMaro/git-interactive-rebase-tool)
    * [diff-so-fancy](https://github.com/so-fancy/diff-so-fancy)
