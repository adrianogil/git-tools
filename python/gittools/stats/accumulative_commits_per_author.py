#!/usr/bin/env python3
"""
accumulative_commits_per_author.py

Count commits per author since the first commit up to a given ref (default HEAD),
and plot cumulative totals for all authors.

Usage
  python accumulative_commits_per_author.py
  python accumulative_commits_per_author.py main --top 15 --inline-labels
  python accumulative_commits_per_author.py v1.2.0 --no-merges --save out.png

Key options
  --by {email,name,both}   How authors are grouped (default: email). Use "email"
                           to collapse different names that share the same email.
  --label {auto,name,email,both}
                           How authors are shown in legend/labels (default: auto).
                           - auto: best name seen for that email, else email
                           - name/email/both: force a specific format
  --inline-labels          Put compact labels at the end of each line (skip legend)
  --steps/--no-steps       Draw cumulative lines as steps (default: --steps)
  --top N                  Plot only top N authors by total commits
  --save PATH              Save the figure instead of showing it

Dependencies: git CLI, matplotlib
"""

import argparse
import subprocess
import sys
from collections import defaultdict, Counter
from datetime import datetime
from typing import Dict, List, Tuple, Optional

def run_git(args: List[str]) -> str:
    p = subprocess.run(["git"] + args, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if p.returncode != 0:
        raise RuntimeError(f"git {' '.join(args)} failed:\n{p.stderr.strip()}")
    return p.stdout

def assert_in_repo():
    out = run_git(["rev-parse", "--is-inside-work-tree"]).strip().lower()
    if out != "true":
        raise RuntimeError("Not inside a git work tree.")

def collect_commits(ref: str, include_merges: bool) -> List[Tuple[datetime, str, str]]:
    """Return list of (date, author_name, author_email) sorted oldest->newest."""
    pretty = "%ad%x09%an%x09%ae"
    args = [
        "log",
        "--no-decorate",
        "--date=short",
        f"--pretty=format:{pretty}",
        "--reverse",
        ref,
    ]
    if not include_merges:
        args.insert(1, "--no-merges")

    out = run_git(args)
    rows: List[Tuple[datetime, str, str]] = []
    for line in out.splitlines():
        parts = line.split("\t")
        if len(parts) != 3:
            continue
        date_str, name, email = parts
        try:
            d = datetime.strptime(date_str, "%Y-%m-%d").date()
        except ValueError:
            continue
        rows.append((datetime(d.year, d.month, d.day), name.strip(), (email or "").strip()))
    if not rows:
        raise RuntimeError(f"No commits reachable from {ref}.")
    return rows

def best_name_per_email(rows: List[Tuple[datetime, str, str]]) -> Dict[str, str]:
    """Pick the most frequent name used with each email (ties break by latest)."""
    name_counts: Dict[str, Counter] = defaultdict(Counter)
    last_seen: Dict[Tuple[str, str], datetime] = {}
    for dt, name, email in rows:
        if not email:
            continue
        name_counts[email][name] += 1
        last_seen[(email, name)] = dt

    best: Dict[str, str] = {}
    for email, counts in name_counts.items():
        # sort by (count desc, last_seen desc)
        candidates = sorted(
            counts.items(),
            key=lambda kv: (kv[1], last_seen[(email, kv[0])]),
            reverse=True,
        )
        best[email] = candidates[0][0]
    return best

def build_counts(rows, by: str) -> Tuple[List[datetime], Dict[str, List[int]], Dict[str, str]]:
    """
    Return (sorted_dates, series, labels_map).
    series[key] = cumulative list aligned to sorted_dates.
    labels_map maps key -> nice label (may be same as key).
    """
    # Build per-day counts by chosen key
    per_key_per_day: Dict[str, Counter] = defaultdict(Counter)
    all_days: List[datetime] = []

    # Precompute a canonical "best name" per email for nicer labels
    email_to_best_name = best_name_per_email(rows)

    for dt, name, email in rows:
        day = dt  # already date-aligned at midnight
        if not all_days or all_days[-1] != day:
            # track unique days in sorted order
            if not all_days or all_days[-1] != day:
                pass
        key: str
        if by == "email":
            key = email if email else name
        elif by == "both":
            key = f"{name} <{email}>" if email else name
        else:
            key = name
        per_key_per_day[key][day.date()] += 1
        if not all_days or all_days[-1].date() != day.date():
            all_days.append(day)

    sorted_days = sorted({d.date() for d in all_days})
    # Build cumulative series
    series: Dict[str, List[int]] = {}
    for key, daily in per_key_per_day.items():
        total = 0
        ys: List[int] = []
        for d in sorted_days:
            total += daily.get(d, 0)
            ys.append(total)
        series[key] = ys

    # Labels
    labels_map: Dict[str, str] = {}
    for key in series.keys():
        if by == "email":
            email = key if "@" in key else ""
            if email and email in email_to_best_name:
                labels_map[key] = f"{email_to_best_name[email]} <{email}>"
            else:
                labels_map[key] = key if key else "Unknown"
        else:
            labels_map[key] = key
    # Convert dates back to datetime for plotting
    x = [datetime(d.year, d.month, d.day) for d in sorted_days]
    return x, series, labels_map

def main():
    parser = argparse.ArgumentParser(description="Plot cumulative commits per author up to a ref (default HEAD).")
    parser.add_argument("ref", nargs="?", default="HEAD", help="Git ref to use as the upper bound (default: HEAD)")
    parser.add_argument("--by", choices=["email", "name", "both"], default="email",
                        help="Group authors by this identity (default: email).")
    parser.add_argument("--label", choices=["auto", "name", "email", "both"], default="auto",
                        help="How to show author labels in the plot (default: auto).")
    parser.add_argument("--no-merges", action="store_true", help="Exclude merge commits")
    parser.add_argument("--top", type=int, default=0, help="Plot only the top N authors by total commits")
    parser.add_argument("--inline-labels", action="store_true",
                        help="Place compact labels at the end of lines instead of a big legend")
    parser.add_argument("--steps", dest="steps", action="store_true", default=True,
                        help="Draw cumulative lines as steps (default)")
    parser.add_argument("--no-steps", dest="steps", action="store_false",
                        help="Disable step drawing")
    parser.add_argument("--save", type=str, default="", help="File path to save the figure (png/pdf/svg)")
    args = parser.parse_args()

    try:
        assert_in_repo()
        rows = collect_commits(args.ref, include_merges=not args.no_merges)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(2)

    # Build time series
    x, series, labels_map = build_counts(rows, by=args.by)
    if not x:
        print("No commits found to plot.", file=sys.stderr)
        sys.exit(1)

    # Optionally keep only the top N authors
    if args.top and args.top > 0:
        totals = sorted(((k, v[-1]) for k, v in series.items()), key=lambda t: t[1], reverse=True)[: args.top]
        keep = {k for k, _ in totals}
        series = {k: v for k, v in series.items() if k in keep}
        labels_map = {k: v for k, v in labels_map.items() if k in keep}

    # Choose final labels formatting
    def label_for(key: str) -> str:
        if args.label == "auto":
            return labels_map.get(key, key)
        if args.label == "name":
            # best-effort: if key is email, show best name; else keep name
            if "@" in key and key in labels_map:
                v = labels_map[key]
                return v.split(" <")[0] if " <" in v else v
            return key
        if args.label == "email":
            if "@" in key:
                return key
            # extract from labels_map if present
            v = labels_map.get(key, key)
            if "<" in v and ">" in v:
                return v[v.find("<") + 1 : v.find(">")]
            return v
        if args.label == "both":
            if "@" in key and key in labels_map:
                return labels_map[key]
            # try to synthesize
            nm = label_for(key="name")  # type: ignore
            em = label_for(key="email")  # type: ignore
            return f"{nm} <{em}>" if em != nm else nm
        return labels_map.get(key, key)

    # Plot
    try:
        import matplotlib.pyplot as plt
        import matplotlib.dates as mdates
    except ImportError:
        print("matplotlib is required. Install it with: pip install matplotlib", file=sys.stderr)
        sys.exit(3)

    # Sort by final totals so dominant series are drawn last (on top)
    order = sorted(series.keys(), key=lambda k: series[k][-1], reverse=True)
    y_max = max(series[k][-1] for k in order)

    fig, ax = plt.subplots(figsize=(13, 7))
    for k in order:
        ys = series[k]
        lw = 1.5 + 2.0 * (ys[-1] / y_max) if y_max > 0 else 1.5  # thicker for larger totals
        if args.steps:
            ax.plot(x, ys, linewidth=lw, drawstyle="steps-post", label=label_for(k), alpha=0.9)
        else:
            ax.plot(x, ys, linewidth=lw, label=label_for(k), alpha=0.9)

    # Title and axes
    ax.set_title(f"Cumulative commits per author up to {args.ref}")
    ax.set_xlabel("Date")
    ax.set_ylabel("Cumulative commits")

    # Date formatting
    locator = mdates.AutoDateLocator()
    formatter = mdates.ConciseDateFormatter(locator)
    ax.xaxis.set_major_locator(locator)
    ax.xaxis.set_major_formatter(formatter)

    # Grid & frame
    ax.grid(True, axis="y", linestyle="--", alpha=0.35)
    ax.grid(True, axis="x", linestyle=":", alpha=0.15)
    for spine in ["top", "right"]:
        ax.spines[spine].set_visible(False)

    # Labels at end of lines (optional)
    if args.inline_labels:
        ax.margins(x=0.05)  # space for labels at right
        last_x = x[-1]
        # small vertical offset to reduce overlap
        ys_last = [series[k][-1] for k in order]
        # compute rank for offsetting
        ranks = {k: i for i, k in enumerate(sorted(order, key=lambda k: series[k][-1]))}
        for k in order:
            y = series[k][-1]
            offset = (ranks[k] % 6) * (0.006 * y_max)  # stagger a bit
            ax.text(
                last_x, y + offset,
                f" {label_for(k)}",
                va="center", ha="left", fontsize=8,
            )
    else:
        ax.legend(loc="center left", bbox_to_anchor=(1.02, 0.5), frameon=False, fontsize=9, title="Authors")

    fig.tight_layout()

    if args.save:
        fig.savefig(args.save, dpi=150, bbox_inches="tight")
        print(f"Saved figure to {args.save}")
    else:
        import matplotlib
        # Try interactive backend; fall back gracefully in headless envs
        try:
            plt.show()
        except Exception as _:
            fig.savefig("commits_per_author.png", dpi=150, bbox_inches="tight")
            print("GUI not available; saved to commits_per_author.png")

if __name__ == "__main__":
    main()
