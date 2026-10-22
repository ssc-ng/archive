---
layout: default
title: About
nav_order: 1
permalink: /
description: "Date-stamped snapshots of the SSC archive"
---

# A mirror of the Statistical Software Components archive at BC

This repository holds a sequence of date-stamped snapshots of the
[SSC Archive](https://ideas.repec.org/s/boc/bocode.html) at Boston College.
A new snapshot is taken (and tagged with its date) every time the archive is
mirrored.

## How can you use it?

Use the [`ssc2`](https://ssc-ng.net/ssc2/) package to install from date-stamped
snapshots of SSC:

```stata
* Install from SSC
ssc install ssc2

* The current stable release
net install ssc2, all replace from("https://raw.githubusercontent.com/ssc-ng/ssc2/latest/")

* install packages
ssc2 install <package_name>, date(<YYYY-MM-DD>)
* e.g. ssc2 install reghdfe, date(2026-10-20)
```

## Explore the snapshots

- [Select packages](browse.html): pick a snapshot, search its packages, tick the
  ones you want, and get the `ssc2` command that installs them as they stood on
  that day.
- [Compare](compare.html): see which packages were added, removed or changed between any two snapshots.
- [Package history](history.html) *(under development)*: in which snapshots a
  package is available, and when its package file changed.
- [Availability](tags.html): the contiguous ranges of date tags, the earliest
  and the latest, and the reasons for the gaps.

## Using the mirror directly

While the `ssc` command in Stata continues to go to the original location,
you can leverage versioned packages from this mirror:

```stata
global sscdate "2021-12-21"
global sscmirror "raw.githubusercontent.com/ssc-ng/archive/$sscdate/"
net install a2reg, from(https://${sscmirror}fmwww.bc.edu/repec/bocode/a) all
```

where the date `2021-12-21` corresponds to an existing tag.

## How the mirror is created

See [mirror.repec.sh](https://github.com/ssc-ng/archive/blob/main/mirror.repec.sh).
The process can take up to 60 minutes. The downloaded mirror is in the
[releases branch](https://github.com/ssc-ng/archive/tree/releases).
For known gaps and errors, see the
[ERRATA](https://github.com/ssc-ng/archive/blob/main/ERRATA.md).

## How to clone this repository

This repository can get big (over 20,000 objects, approx. 320 MB for a shallow
clone). If cloning to your local workspace, use a "shallow" clone:

```bash
git clone --depth 1 https://github.com/ssc-ng/archive.git
```

## License

The code that creates this repository is under a BSD-3 license. All other code
(the mirror) is under whatever license the original authors granted.
