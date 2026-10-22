#!/usr/bin/env python3
"""
build_data.py -- generate the data files the site loads asynchronously,
from the snapshots in ssc-ng/archive.

Run manually:   python3 build_data.py [output_dir [work_dir]]
                (defaults: assets/data, a temporary directory)
Run by CI:      see .github/workflows/site.yml

Output (all static JSON, served next to the site):

  manifest.json        small; loaded on every page view. Snapshot list
                       (date + package count), contiguous tag ranges, the
                       gaps between them with the reason from ERRATA.md,
                       and the earliest/latest tag.
  presence.json        medium (~100 KB, ~30 KB gzipped); loaded on demand.
                       Every package name ever seen, with the runs of
                       snapshot indices it appears in ("r") and the
                       snapshot indices at which its .pkg file differs from
                       the previous snapshot it was in ("c"). Drives the
                       package history page without touching the
                       per-snapshot files.
  snap/<date>.json     one small file per snapshot, fetched only when the
                       visitor selects that snapshot: {"d": date, "p": [names]}.

Source: a blobless clone of the mirror's `releases` branch. Only commits and
trees are downloaded (a few MB, seconds), and `git ls-tree` then lists every
file and its blob hash in any tag offline. A package is any <name>.pkg below
fmwww.bc.edu/repec/bocode/<letter>/; "changed" means that file's blob hash
differs, so it is a signal from the package file only (not from the .ado
files, and not a parsed version number -- see the history page).

Which snapshots get a file: every tag older than DAILY_START, the first tag
of each calendar month after that, and the latest tag. The list of *all*
tags (including the daily ones) is still recorded, as contiguous ranges in
the manifest. Widening the policy is a one-line change; presence.json stays
small because availability is stored as runs.
"""
import datetime as dt
import json
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path

MIRROR_GIT = "https://github.com/ssc-ng/archive.git"
DAILY_START = dt.date(2021, 12, 21)
DATE_TAG = re.compile(r"^\d{4}-\d{2}-\d{2}$")
# `git ls-tree -r` line: "<mode> blob <sha>\t<path>"
PKG_LINE = re.compile(
    r"^\d+ blob ([0-9a-f]+)\tfmwww\.bc\.edu/repec/bocode/[^/]+/([^/]+)\.pkg$")
ERRATA = Path(__file__).resolve().parent.parent / "ERRATA.md"
ERRATA_ROW = re.compile(
    r"^\|\s*(\d{4}-\d{2}-\d{2})\s*\|\s*(\d{4}-\d{2}-\d{2})\s*\|\s*(.*?)\s*\|\s*$")
EARLY_REASON = ("Before the mirror was automated, snapshots were taken "
                "only occasionally (see ERRATA, early dates).")
NO_REASON = "No reason is recorded in the ERRATA."


def git(*args, cwd=None) -> str:
    return subprocess.run(["git", *args], cwd=cwd, check=True,
                          capture_output=True, text=True).stdout


def clone(work: Path) -> Path:
    """Blobless clone of the releases branch, with all tags."""
    repo = work / "releases"
    if not repo.exists():
        git("clone", "-q", "--filter=blob:none", "--no-checkout",
            "--single-branch", "--branch", "releases", MIRROR_GIT, str(repo))
    git("fetch", "-q", "--filter=blob:none", "origin",
        "refs/tags/*:refs/tags/*", cwd=repo)
    return repo


def all_tags(repo: Path) -> list[dt.date]:
    return sorted(dt.date.fromisoformat(t) for t in git("tag", cwd=repo).split()
                  if DATE_TAG.match(t))


def contiguous_ranges(tags: list[dt.date]) -> list[list]:
    """[[first, last, count], ...] for runs of consecutive daily tags."""
    runs = []
    for t in tags:
        if runs and (t - runs[-1][1]).days == 1:
            runs[-1][1] = t
            runs[-1][2] += 1
        else:
            runs.append([t, t, 1])
    return [[str(a), str(b), n] for a, b, n in runs]


def errata_gaps(text: str) -> list[tuple[dt.date, dt.date, str]]:
    """Rows of the 'Absent dates' table in ERRATA.md."""
    rows = []
    for line in text.splitlines():
        m = ERRATA_ROW.match(line)
        if m:
            rows.append((dt.date.fromisoformat(m.group(1)),
                         dt.date.fromisoformat(m.group(2)),
                         m.group(3).rstrip(". ")))
    return rows


def gaps_between(ranges: list[list], errata) -> list[list]:
    """[[first, last, days, reason], ...] for the dates between ranges."""
    out = []
    for (_, prev_end, _), (next_start, _, _) in zip(ranges, ranges[1:]):
        a = dt.date.fromisoformat(prev_end) + dt.timedelta(1)
        b = dt.date.fromisoformat(next_start) - dt.timedelta(1)
        if a > b:
            continue
        why = [r for s, e, r in errata if s <= b and e >= a]
        reason = "; ".join(dict.fromkeys(why)) or (
            EARLY_REASON if b < DAILY_START else NO_REASON)
        out.append([str(a), str(b), (b - a).days + 1, reason])
    return out


def select_snapshots(tags: list[dt.date]) -> list[dt.date]:
    """Tags older than DAILY_START, the first tag of each later month, and the latest."""
    chosen, seen_months = [], set()
    for t in tags:
        if t < DAILY_START:
            chosen.append(t)
        elif (t.year, t.month) not in seen_months:
            seen_months.add((t.year, t.month))
            chosen.append(t)
    if tags[-1] not in chosen:
        chosen.append(tags[-1])
    return chosen


def parse_tree(listing: str) -> dict[str, str]:
    """`git ls-tree -r` output -> {package name: blob hash of its .pkg}."""
    pkgs = {}
    for line in listing.splitlines():
        m = PKG_LINE.match(line)
        if m:
            pkgs[m.group(2)] = m.group(1)
    return pkgs


def runs(indices: list[int]) -> list[int]:
    """Sorted snapshot indices -> flat [start, end, start, end, ...] runs."""
    out = []
    for i in indices:
        if out and i == out[-1] + 1:
            out[-1] = i
        else:
            out += [i, i]
    return out


def dump(path: Path, obj) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    text = json.dumps(obj, separators=(",", ":"), ensure_ascii=False)
    path.write_text(text, encoding="utf-8")
    return len(text.encode())


def main() -> int:
    out = Path(sys.argv[1] if len(sys.argv) > 1 else "assets/data")
    t0 = time.time()
    with tempfile.TemporaryDirectory() as tmp:
        work = Path(sys.argv[2]) if len(sys.argv) > 2 else Path(tmp)
        repo = clone(work)
        tags = all_tags(repo)
        snaps = select_snapshots(tags)
        print(f"{len(tags)} tags; reading {len(snaps)} snapshots")
        trees = [parse_tree(git("ls-tree", "-r", str(d), cwd=repo)) for d in snaps]

    (out / "snap").mkdir(parents=True, exist_ok=True)
    for old in (out / "snap").glob("*.json"):
        old.unlink()
    for d, pk in zip(snaps, trees):
        dump(out / "snap" / f"{d}.json", {"d": str(d), "p": sorted(pk)})

    present, changed = {}, {}
    for i, pk in enumerate(trees):
        for n, sha in pk.items():
            present.setdefault(n, []).append(i)
            if i and trees[i - 1].get(n, sha) != sha:
                changed.setdefault(n, []).append(i)
    pkgs = sorted(present)
    size = dump(out / "presence.json", {
        "p": pkgs,
        "r": [runs(present[n]) for n in pkgs],
        "c": [changed.get(n, []) for n in pkgs],
    })

    ranges = contiguous_ranges(tags)
    errata = errata_gaps(ERRATA.read_text(encoding="utf-8")) if ERRATA.exists() else []
    dump(out / "manifest.json", {
        "built": dt.date.today().isoformat(),
        "earliest": str(tags[0]),
        "latest": str(tags[-1]),
        "tagCount": len(tags),
        "snapshots": [[str(d), len(pk)] for d, pk in zip(snaps, trees)],
        "ranges": ranges,
        "gaps": gaps_between(ranges, errata),
    })
    print(f"{len(pkgs)} distinct packages; presence.json {size/1024:.0f} KB; "
          f"done in {time.time() - t0:.0f}s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
