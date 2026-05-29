"""Command-line startup for the repository treemap Flask app."""

from __future__ import annotations

import argparse
import sys
from datetime import datetime

from .app import create_app
from .git_analysis import GitCommandError, RepoTreemapAnalyzer


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Render the current HEAD of a Git repository as a navigable treemap."
    )
    parser.add_argument(
        "repo",
        nargs="?",
        default=".",
        help="Repository path to inspect. Defaults to the current working directory.",
    )
    parser.add_argument("--host", default="127.0.0.1", help="Flask host to bind.")
    parser.add_argument("--port", type=int, default=5088, help="Flask port to bind.")
    parser.add_argument("--debug", action="store_true", help="Run Flask in debug mode.")
    parser.add_argument(
        "--rebuild",
        action="store_true",
        help="Force a rebuild of the Git analysis cache.",
    )
    parser.add_argument(
        "--jobs",
        type=int,
        default=None,
        help="Number of files to analyze in parallel while rebuilding the cache. Defaults to min(8, CPU count).",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    def progress(message: str) -> None:
        stamp = datetime.now().strftime("%H:%M:%S")
        print(f"[{stamp}] {message}", flush=True)

    try:
        analyzer = RepoTreemapAnalyzer(
            args.repo,
            rebuild=args.rebuild,
            jobs=args.jobs,
            progress=progress,
        )
    except GitCommandError as exc:
        print(f"repo_treemap: {exc}", file=sys.stderr)
        return 2
    except Exception as exc:
        print(f"repo_treemap: failed to initialize: {exc}", file=sys.stderr)
        return 1

    app = create_app(analyzer)
    url = f"http://{args.host}:{args.port}/view?path="
    print("Git repository treemap")
    print(f"  Repo root:        {analyzer.repo_root}")
    print(f"  Git metadata dir: {analyzer.git_dir}")
    print(f"  Cache path:       {analyzer.cache_path}")
    print(f"  HEAD:             {analyzer.head}")
    print(f"  Local URL:        {url}")
    app.run(host=args.host, port=args.port, debug=args.debug)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
