#!/usr/bin/env python3
"""Add snapshot dates that have neither a tag nor an ERRATA entry to ERRATA.md.

Usage: errata_sync.py TAGFILE [--start YYYY-MM-DD] [--end YYYY-MM-DD] [--errata ERRATA.md]

TAGFILE holds one tag name per line. A tag counts for its first ten characters
(so "2025-03-14test" covers 2025-03-14). Prints the added ranges as
"start end" lines; prints nothing and leaves ERRATA.md untouched if in sync.
"""
import argparse
import re
from datetime import date, timedelta

PLACEHOLDER = "TODO: reason to be filled in before merging"
ROW = re.compile(r"^\|\s*(\d{4}-\d\d-\d\d)\s*\|\s*(\d{4}-\d\d-\d\d)\s*\|(.*)\|\s*$")


def daterange(a, b):
    for i in range((b - a).days + 1):
        yield a + timedelta(days=i)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("tagfile")
    p.add_argument("--start", default="2026-01-01")
    p.add_argument("--end", default=str(date.today() - timedelta(days=1)))
    p.add_argument("--errata", default="ERRATA.md")
    args = p.parse_args()
    start, end = date.fromisoformat(args.start), date.fromisoformat(args.end)

    tagged = set()
    with open(args.tagfile) as f:
        for line in f:
            m = re.match(r"(\d{4}-\d\d-\d\d)", line.strip())
            if m:
                tagged.add(date.fromisoformat(m.group(1)))

    lines = open(args.errata).read().split("\n")
    rows = [(i, ROW.match(l)) for i, l in enumerate(lines)]
    rows = [(i, m) for i, m in rows if m]
    if not rows:
        raise SystemExit("No table rows found in " + args.errata)
    listed = set()
    for _, m in rows:
        listed.update(daterange(date.fromisoformat(m.group(1)), date.fromisoformat(m.group(2))))

    missing = [d for d in daterange(start, end) if d not in tagged and d not in listed]
    if not missing:
        return

    ranges = []
    for d in missing:
        if ranges and ranges[-1][1] + timedelta(days=1) == d:
            ranges[-1][1] = d
        else:
            ranges.append([d, d])

    # Rebuild the table body in date order, keeping existing rows verbatim
    first, last = rows[0][0], rows[-1][0]
    body = [(m.group(1), lines[i]) for i, m in rows]
    body += [(str(a), f"| {a} | {b} | {PLACEHOLDER} |") for a, b in ranges]
    body.sort(key=lambda t: t[0])
    lines[first:last + 1] = [l for _, l in body]
    with open(args.errata, "w") as f:
        f.write("\n".join(lines))

    for a, b in ranges:
        print(a, b)


if __name__ == "__main__":
    main()
