#!/usr/bin/env python3
"""
build_data.py -- generate the data files the site loads asynchronously,
from the snapshots in ssc-ng/archive.

Run manually:   python3 build_data.py [output_dir [work_dir]]
                (defaults: assets/data, a temporary directory)
Run by CI:      see .github/workflows/site.yml

Output (all static JSON, served next to the site), for EVERY date tag:

  manifest.json   small; loaded on every page view. All snapshots (date and
                  package count), contiguous tag ranges, the gaps between
                  them with the reason from ERRATA.md, earliest/latest tag.
  presence.json   ~110 KB (~30 KB gzipped). Every package name ever seen,
                  with the runs of snapshot indices it appears in ("r") and
                  the snapshot indices at which its .pkg file differs from
                  the previous snapshot it was in ("c"). The browser rebuilds
                  the package list of ANY snapshot from the runs, so there is
                  no per-snapshot file and the size hardly depends on how
                  many snapshots there are.

Source: a blobless clone of the mirror's `releases` branch (commits and
trees only: a few MB, seconds). One `git log --raw` pass over the history
yields every .pkg that was added, modified or deleted in each commit; the
state at each date tag is replayed from that, so the cost is proportional
to the number of changes, not to tags x packages. A package is any
<name>.pkg below fmwww.bc.edu/repec/bocode/<letter>/; "changed" means that
file's blob hash differs, a signal from the package file only (not from the
.ado files, and not a parsed version number -- see the history page).
"""
import datetime as dt
import json
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

MIRROR_GIT = "https://github.com/ssc-ng/archive.git"
DAILY_START = dt.date(2021, 12, 21)
DATE_TAG = re.compile(r"^\d{4}-\d{2}-\d{2}$")
# Package directories are one character (a-z, _). The mirror history also has
# temporary copies in directories such as bocode/_disabled/ and
# bocode/_restored/; those must not count, or a copy's deletion would remove
# the package of the same name that is still in its real directory.
# `git ls-tree -r` line: "<mode> blob <sha>\t<path>"
PKG_LINE = re.compile(
    r"^\d+ blob ([0-9a-f]+)\tfmwww\.bc\.edu/repec/bocode/[^/]/([^/]+)\.pkg$")
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


def parse_tree(listing: str) -> dict[str, str]:
    """`git ls-tree -r` output -> {package name: blob hash of its .pkg}."""
    pkgs = {}
    for line in listing.splitlines():
        m = PKG_LINE.match(line)
        if m:
            pkgs[m.group(2)] = m.group(1)
    return pkgs


ZERO = re.compile(r"^0+$")
# `git log --raw` line: ":<mode> <mode> <old> <new> <status>\t<path>"
RAW_LINE = re.compile(
    r"^:\d+ \d+ ([0-9a-f]+) ([0-9a-f]+) [A-Z]\d*\t"
    r"fmwww\.bc\.edu/repec/bocode/[^/]/([^/]+)\.pkg$")


def tag_commits(repo: Path) -> dict[dt.date, str]:
    """Date tag -> the commit it points to (peeling annotated tags)."""
    out = git("for-each-ref", "--format=%(refname:short) %(objectname) %(*objectname)",
              "refs/tags", cwd=repo)
    found = {}
    for line in out.splitlines():
        parts = line.split()
        if parts and DATE_TAG.match(parts[0]):
            found[dt.date.fromisoformat(parts[0])] = parts[-1]
    return found


def pkg_changes(repo: Path) -> tuple[list[str], dict[str, list[tuple[str, str]]]]:
    """(commits oldest first, {commit: [(package, new blob hash or "")]}).

    One pass over the first-parent history, restricted to the mirror
    directory; commits that touch no .pkg file simply have no entry."""
    order = git("rev-list", "--reverse", "--first-parent", "HEAD", cwd=repo).split()
    log = git("-c", "core.quotepath=false", "log", "--reverse", "--first-parent",
              "--root", "--raw", "--no-renames", "--no-abbrev", "--format=%x01%H",
              "HEAD", "--", "fmwww.bc.edu/repec/bocode", cwd=repo)
    changes, commit = {}, None
    for line in log.splitlines():
        if line.startswith("\x01"):
            commit = line[1:]
        else:
            m = RAW_LINE.match(line)
            if m:
                new = "" if ZERO.match(m.group(2)) else m.group(2)
                changes.setdefault(commit, []).append((m.group(3), new))
    return order, changes


def replay(order, changes, snapshot_commits, offline=None):
    """Walk the commits oldest first and record each snapshot.

    snapshot_commits: {commit: [date, ...]} for tags on the main history.
    offline: {date: {package: hash}} for tags whose commit is NOT on it
    (re-made commits): their full state is given, and they are slotted in by
    date. Returns (dates, counts, runs, changed): the snapshot dates in
    order, the number of packages in each, and per package the flat
    [start, end, ...] runs of snapshot indices it is in and the indices
    where its hash changed."""
    state, last, touched = {}, {}, set()      # last: hash at the previous snapshot
    open_at, runs, changed = {}, {}, {}
    dates, counts = [], []
    pending = sorted(offline.items()) if offline else []

    def record(date, names, current):
        """Snapshot `date`: `names` are the packages whose hash may differ from
        the previous snapshot, `current(n)` their hash now (None if absent)."""
        if dates and date <= dates[-1]:
            raise RuntimeError(f"tag {date} is not newer than {dates[-1]}, "
                               "although its commit is later: tag order differs "
                               "from history order")
        i = len(dates)
        for n in names:
            cur, prev = current(n), last.get(n)
            if cur is None:
                if n in open_at:                  # run ended at the previous snapshot
                    runs.setdefault(n, []).extend([open_at.pop(n), i - 1])
                last.pop(n, None)
            else:
                if n not in open_at:
                    open_at[n] = i
                elif prev is not None and prev != cur:
                    changed.setdefault(n, []).append(i)
                last[n] = cur
        dates.append(date)

    def flush_offline(before):
        nonlocal touched
        while pending and (before is None or pending[0][0] < before):
            date, full = pending.pop(0)
            record(date, set(last) | set(full), full.get)
            counts.append(len(full))
            # the next main-line snapshot is compared with this one
            touched = {n for n in set(last) | set(state) if last.get(n) != state.get(n)}

    for commit in order:
        for name, new in changes.get(commit, ()):
            touched.add(name)
            if new:
                state[name] = new
            else:
                state.pop(name, None)
        for date in sorted(snapshot_commits.get(commit, ())):
            flush_offline(date)
            record(date, touched, state.get)
            counts.append(len(state))
            touched = set()
    flush_offline(None)
    for n, start in open_at.items():
        runs.setdefault(n, []).extend([start, len(dates) - 1])
    return dates, counts, runs, changed


def snapshots_from_history(repo: Path):
    tags = tag_commits(repo)
    order, changes = pkg_changes(repo)
    in_history = set(order)
    by_commit, offline = {}, {}
    for date, commit in tags.items():
        if commit in in_history:
            by_commit.setdefault(commit, []).append(date)
        else:
            print(f"  note: tag {date} is off the main history; reading its tree")
            offline[date] = parse_tree(git("ls-tree", "-r", commit, cwd=repo))
    return replay(order, changes, by_commit, offline)


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
        dates, counts, runs, changed = snapshots_from_history(repo)
    print(f"{len(dates)} snapshots, {len(runs)} distinct packages")

    # an obsolete per-snapshot directory from older builds must not be deployed
    shutil.rmtree(out / "snap", ignore_errors=True)
    pkgs = sorted(runs)
    size = dump(out / "presence.json", {
        "p": pkgs,
        "r": [runs[n] for n in pkgs],
        "c": [changed.get(n, []) for n in pkgs],
    })

    ranges = contiguous_ranges(dates)
    errata = errata_gaps(ERRATA.read_text(encoding="utf-8")) if ERRATA.exists() else []
    dump(out / "manifest.json", {
        "built": dt.date.today().isoformat(),
        "earliest": str(dates[0]),
        "latest": str(dates[-1]),
        "tagCount": len(dates),
        "snapshots": [[str(d), c] for d, c in zip(dates, counts)],
        "ranges": ranges,
        "gaps": gaps_between(ranges, errata),
    })
    print(f"presence.json {size/1024:.0f} KB; done in {time.time() - t0:.0f}s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
