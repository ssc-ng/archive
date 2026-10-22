#!/usr/bin/env python3
"""
build_data.py -- generate the data files the package browser loads
asynchronously, from the snapshots in ssc-ng/archive.

Run manually:   python3 build_data.py [output_dir]      (default assets/data)
Run by CI:      see .github/workflows/site.yml

Output (all static JSON, served next to the site):

  manifest.json        small; loaded on every page view. Snapshot list
                       (date + package count), contiguous tag ranges, and
                       the earliest/latest tag.
  presence.json        medium (~100 KB, ~30 KB gzipped); loaded on demand.
                       Every package name ever seen, with the runs of
                       snapshot indices it appears in. Answers "when was
                       this package available?" and drives the history
                       strip, without touching the per-snapshot files.
  snap/<date>.json     one small file per snapshot, fetched only when the
                       visitor selects that snapshot: {"d": date, "p": [names]}.

Which snapshots get a file: the first tag that has a sscfiles.txt
(FILELIST_START; earlier tags have no file list), the first tag of each
calendar month after that, and the latest tag. The list of *all* tags (including the daily ones) is still
recorded, as contiguous ranges in the manifest. Widening the policy is a
one-line change; presence.json stays small because package availability is
stored as runs, not as one entry per snapshot.

A package is any <name>.pkg below fmwww.bc.edu/repec/bocode/ in the
snapshot's sscfiles.txt. Tags come from `git ls-remote` and file lists from
raw.githubusercontent.com: no API, no rate limits.
"""
import datetime as dt
import json
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

MIRROR_GIT = "https://github.com/ssc-ng/archive.git"
MIRROR_RAW = "https://raw.githubusercontent.com/ssc-ng/archive"
FILELIST_START = dt.date(2023, 11, 18)   # first tag that has a sscfiles.txt
DATE_TAG = re.compile(r"^\d{4}-\d{2}-\d{2}$")
PKG_PATH = re.compile(r"^fmwww\.bc\.edu/repec/bocode/[^/]+/([^/]+)\.pkg$")


def all_tags() -> list[dt.date]:
    out = subprocess.run(["git", "ls-remote", "--tags", MIRROR_GIT],
                         check=True, capture_output=True, text=True).stdout
    tags = set()
    for line in out.splitlines():
        ref = line.split("refs/tags/")[-1].removesuffix("^{}")
        if DATE_TAG.match(ref):
            tags.add(dt.date.fromisoformat(ref))
    return sorted(tags)


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


def select_snapshots(tags: list[dt.date]) -> list[dt.date]:
    """The first tag with a file list, the first tag of each later month, and the latest."""
    chosen, seen_months = [], set()
    for t in (t for t in tags if t >= FILELIST_START):
        if not chosen or (t.year, t.month) not in seen_months:
            seen_months.add((t.year, t.month))
            chosen.append(t)
    if tags[-1] not in chosen:
        chosen.append(tags[-1])
    return chosen


def package_names(file_list: str) -> list[str]:
    names = set()
    for line in file_list.splitlines():
        m = PKG_PATH.match(line.strip())
        if m:
            names.add(m.group(1))
    return sorted(names)


def fetch_names(tag: dt.date, attempts: int = 4) -> list[str] | None:
    """Package names in a snapshot, or None if it has no sscfiles.txt
    (the oldest tags predate that file)."""
    url = f"{MIRROR_RAW}/{tag}/sscfiles.txt"
    for i in range(attempts):
        try:
            with urllib.request.urlopen(url, timeout=60) as fh:
                return package_names(fh.read().decode("utf-8", "replace"))
        except urllib.error.HTTPError as exc:
            if exc.code == 404:
                return None
            if i == attempts - 1:
                raise RuntimeError(f"{url}: {exc}") from exc
            time.sleep(2 ** i)
        except Exception as exc:
            if i == attempts - 1:
                raise RuntimeError(f"{url}: {exc}") from exc
            time.sleep(2 ** i)


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
    tags = all_tags()
    snaps = select_snapshots(tags)
    print(f"{len(tags)} tags; fetching {len(snaps)} snapshots")
    with ThreadPoolExecutor(max_workers=8) as pool:
        fetched = list(pool.map(fetch_names, snaps))
    for d, names in zip(snaps, fetched):
        if names is None:
            print(f"  skipped {d}: no sscfiles.txt in that snapshot")
    kept = [(d, n) for d, n in zip(snaps, fetched) if n is not None]
    snaps = [d for d, _ in kept]
    names_by_snap = [n for _, n in kept]

    (out / "snap").mkdir(parents=True, exist_ok=True)
    for old in (out / "snap").glob("*.json"):
        old.unlink()
    for d, names in zip(snaps, names_by_snap):
        dump(out / "snap" / f"{d}.json", {"d": str(d), "p": names})

    index = {}
    for i, names in enumerate(names_by_snap):
        for n in names:
            index.setdefault(n, []).append(i)
    pkgs = sorted(index)
    size = dump(out / "presence.json",
                {"p": pkgs, "r": [runs(index[n]) for n in pkgs]})

    dump(out / "manifest.json", {
        "built": dt.date.today().isoformat(),
        "earliest": str(tags[0]),
        "latest": str(tags[-1]),
        "tagCount": len(tags),
        "fileListStart": str(FILELIST_START),
        "snapshots": [[str(d), len(n)] for d, n in zip(snaps, names_by_snap)],
        "ranges": contiguous_ranges(tags),
    })
    print(f"{len(pkgs)} distinct packages; presence.json {size/1024:.0f} KB; "
          f"done in {time.time() - t0:.0f}s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
