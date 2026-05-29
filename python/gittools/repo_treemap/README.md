# Git Repository Treemap

This Flask app renders the current `HEAD` of a Git repository as a navigable D3 treemap. Only versioned files from `HEAD` are included.

## Usage

Install Flask if it is not already available:

```bash
python3 -m pip install Flask
```

Run from a Git repository:

```bash
python3 /path/to/git-tools/python/repo_treemap.py
```

Or point it at a different repository:

```bash
python3 /path/to/git-tools/python/repo_treemap.py /path/to/repo --port 5088
```

When `git-tools` is sourced, the bash helper is:

```bash
gt-repo-treemap [repo] [--port 5088] [--rebuild]
```

Cold cache builds run `git blame` and history commands for every versioned file. The analyzer runs files in parallel by default with up to 8 workers. Tune this for very large repos:

```bash
gt-repo-treemap --jobs 4
gt-repo-treemap --jobs 1 --rebuild
```

## Architecture

- `repo_treemap.py`: CLI startup.
- `app.py`: Flask routes for `/view`, `/api/node`, `/api/legend`, and `/api/cache`.
- `git_analysis.py`: Git command execution, HEAD file listing, blame ownership, history metrics, alias normalization, path validation, and cache invalidation.
- `templates/view.html`: HTML shell.
- `static/app.js`: D3 treemap rendering, directory navigation, contributor bands, tooltips, breadcrumbs, and legend.
- `static/style.css`: Layout and tile styling.

## Git Metadata Cache

The cache is written to the real Git metadata directory:

```text
<git rev-parse --absolute-git-dir>/.repo_treemap_cache.json
```

This deliberately avoids assuming that `.git` is a directory under the working tree. Linked worktrees, submodules, and `.git` pointer files are handled by Git itself. The cache is reused until `HEAD`, the cache schema, repository root, or alias config fingerprint changes. Use `--rebuild` to force a fresh analysis.

## Metrics

- Text file LOC comes from the current `HEAD` blob.
- Binary files and Gitlinks are included with `LOC = 1` so they remain visible.
- Zero-line text files keep `loc = 0`, but their internal `size_metric` is `1` so the treemap can still show and hover them.
- Text file contribution bands come from `git blame --line-porcelain HEAD`.
- Binary or non-blameable file contribution bands come from non-merge commit-touch counts.
- History stats use `git log --follow --no-merges --numstat`, so merge commits themselves are ignored while commits introduced by merges remain counted.

## Alias Config

Create `.repo_treemap_aliases.json` at the repository root to merge developer aliases:

```json
{
  "aliases": {
    "canonical_dev_1": {
      "display_name": "Alice",
      "emails": ["alice@corp.com", "alice@gmail.com"],
      "names": ["Alice", "Alice Smith", "asmith"]
    }
  }
}
```

Emails take priority over names. If the same email or name is assigned to multiple canonical developers, startup fails with a clear alias collision error.
