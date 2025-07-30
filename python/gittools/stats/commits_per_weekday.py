#!/usr/bin/env python3
import sys
import subprocess
import datetime

def main():
    # Get revision range from first argument, default to HEAD
    rev = sys.argv[1] if len(sys.argv) > 1 else 'HEAD'

    # Run git log to get commit timestamps (seconds since epoch)
    try:
        result = subprocess.run(
            ['git', 'log', rev, '--pretty=format:%ct'],
            check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        )
    except subprocess.CalledProcessError as e:
        print(f"Error running git log: {e.stderr.strip()}", file=sys.stderr)
        sys.exit(1)

    lines = result.stdout.splitlines()
    if not lines:
        print("No commits found.")
        return

    # Prepare counters
    counts = [0] * 7  # 0=Monday, ..., 6=Sunday
    dates = []

    # Parse each timestamp
    for line in lines:
        try:
            ts = int(line.strip())
        except ValueError:
            continue
        dt = datetime.datetime.fromtimestamp(ts)
        d = dt.date()
        dates.append(d)
        counts[d.weekday()] += 1

    # Determine span and number of weeks
    first, last = min(dates), max(dates)
    days_span = (last - first).days + 1
    weeks = days_span / 7.0
    if weeks < 1:
        weeks = 1.0

    # Weekday names
    names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']

    # Print results
    print(f"Commit stats for revision '{rev}':")
    print(f"  Time span: {first} → {last}  ({days_span} days, {weeks:.2f} weeks)\n")
    print(f"{'Weekday':<10} {'Count':>6} {'Avg/week':>10}")
    print('-' * 28)
    for i, name in enumerate(names):
        count = counts[i]
        avg = count / weeks
        print(f"{name:<10} {count:6d} {avg:10.2f}")

if __name__ == '__main__':
    main()
