# -*- coding: utf-8 -*-
"""
wordfreq_pdf.py -- PDF/text corpus keyword-frequency engine for the Stata
                   program wordfreq.ado (bilingual: Chinese / English).

Two steps, both callable independently:

  1. extract : convert every PDF found under --path into a UTF-8 .txt file
               (cached, so re-runs are fast). Uses pypdf, falls back to
               pdfminer.six when pypdf cannot open a file.
  2. count   : count how often every user keyword occurs in each document and
               write one tidy CSV (one row per document).

Usage
-----
  python wordfreq_pdf.py extract --path DIR --pattern "*.pdf" --cache DIR
  python wordfreq_pdf.py count   --path DIR --pattern "*.pdf" --cache DIR \
                                 --kwfile KWS.txt --lang cn --out OUT.csv

The CSV produced by ``count`` has the columns

  stkcd, year, filename, path, n_chars, n_words, wf1 ... wfK, wf_total

so that ``import delimited`` in Stata maps one keyword to one variable.

Author: WU Lianghai, WU Hanyan, XU Huihui   (October 6, 2026)
"""

from __future__ import annotations

import argparse
import contextlib
import csv
import json
import logging
import os
import re
import sys
import unicodedata
import warnings
from concurrent.futures import ProcessPoolExecutor, as_completed

# ------------------------------------------------ quiet third-party libraries
logging.getLogger("pdfminer").setLevel(logging.ERROR)
logging.getLogger("pypdf").setLevel(logging.ERROR)
warnings.filterwarnings("ignore")


@contextlib.contextmanager
def suppress_output():
    """Silence C-level chatter (pypdf/pdfminer print to fd 1/2)."""
    devnull = os.open(os.devnull, os.O_WRONLY)
    saved_out, saved_err = os.dup(1), os.dup(2)
    os.dup2(devnull, 1)
    os.dup2(devnull, 2)
    try:
        yield
    finally:
        os.dup2(saved_out, 1)
        os.dup2(saved_err, 2)
        for fd in (devnull, saved_out, saved_err):
            try:
                os.close(fd)
            except OSError:
                pass


def write_status(out_path, ok, message=""):
    """Write a small side-car status file consumed by wordfreq.ado."""
    if not out_path:
        return
    side = out_path + ".status"
    try:
        with open(side, "w", encoding="utf-8") as fh:
            fh.write(("OK\n" if ok else "ERROR\n") + (message or ""))
    except OSError:
        pass


# ---------------------------------------------------------------- utilities
_WORDNAME_RE = re.compile(r"^(\d{6})[_\-\s]*(\d{4})$")
_CJK_RE = re.compile(r"[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]")


def say(msg: str) -> None:
    enc = getattr(sys.stdout, "encoding", None) or "utf-8"
    try:
        print(msg, flush=True)
    except UnicodeEncodeError:
        print(msg.encode(enc, "replace").decode(enc, "replace"), flush=True)


def clean_text(text: str) -> str:
    """Loose clean-up: drop control/zero-width characters, squeeze blanks."""
    text = unicodedata.normalize("NFKC", text)
    text = re.sub(r"[\ufeff\u200b\u200c\u200d\u2060]", "", text)
    text = re.sub(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]", " ", text)
    text = re.sub(r"第\s*\d+\s*页\s*(?:[，,/／]?\s*共\s*\d+\s*页)?", " ", text)
    text = re.sub(r"[ \t\u3000]+", " ", text)
    text = re.sub(r"\n{2,}", "\n", text)
    return text


def parse_meta(path: str):
    """Recover stkcd / year from a file name such as ``000521_2023.pdf``."""
    stem = os.path.splitext(os.path.basename(path))[0]
    m = _WORDNAME_RE.match(stem)
    if m:
        return m.group(1), int(m.group(2))
    m = re.match(r"^(\d{6})", stem)
    stkcd = m.group(1) if m else ""
    m = re.search(r"(20\d{2})", stem)
    year = int(m.group(1)) if m else ""
    return stkcd, year


# ------------------------------------------------------------ PDF extraction
def _extract_with_pypdf(path: str) -> str:
    from pypdf import PdfReader

    reader = PdfReader(path)
    parts = []
    for page in reader.pages:
        try:
            parts.append(page.extract_text() or "")
        except Exception:
            parts.append("")
    return "\n".join(parts)


def _extract_with_pdfminer(path: str) -> str:
    from pdfminer.high_level import extract_text

    return extract_text(path) or ""


def extract_one(args):
    """Worker: return (src, dst, status, nchars)."""
    src, cache, force = args
    rel = os.path.splitext(os.path.basename(src))[0]
    dst = os.path.join(cache, rel + ".txt")
    if (not force) and os.path.exists(dst) and os.path.getsize(dst) > 0:
        return src, dst, "cached", os.path.getsize(dst)
    text = ""
    err = ""
    with suppress_output():
        try:
            text = _extract_with_pypdf(src)
        except Exception as exc:  # pragma: no cover - library specific
            err = "pypdf: %s" % exc
        if len(text.strip()) < 50:
            try:
                alt = _extract_with_pdfminer(src)
                if len(alt.strip()) > len(text.strip()):
                    text = alt
                    err = ""
            except Exception as exc:  # pragma: no cover
                err = (err + " | pdfminer: %s" % exc).strip(" |")
    text = clean_text(text)
    with open(dst, "w", encoding="utf-8", errors="ignore") as fh:
        fh.write(text)
    status = "ok" if len(text.strip()) >= 50 else "empty"
    if err and status == "ok":
        status = "ok(warn)"
    return src, dst, status, len(text)


def list_files(path: str, pattern: str, recursive: bool):
    pat = pattern or "*"
    rx = re.compile(
        "^" + re.escape(pat).replace(r"\*", ".*").replace(r"\?", ".") + "$", re.I
    )
    out = []
    if os.path.isfile(path):
        return [path]
    if recursive:
        for root, _dirs, files in os.walk(path):
            for fn in files:
                if rx.match(fn):
                    out.append(os.path.join(root, fn))
    else:
        for fn in os.listdir(path):
            full = os.path.join(path, fn)
            if os.path.isfile(full) and rx.match(fn):
                out.append(full)
    return sorted(out)


def do_extract(a) -> None:
    files = list_files(a.path, a.pattern, a.recursive)
    if not files:
        raise SystemExit("No file matching %r under %s" % (a.pattern, a.path))
    os.makedirs(a.cache, exist_ok=True)
    jobs = [(f, a.cache, a.force) for f in files]
    stats = {"ok": 0, "cached": 0, "empty": 0, "ok(warn)": 0}
    say("Extracting %d file(s) -> %s" % (len(files), a.cache))
    if a.workers > 1 and len(files) > 1:
        with ProcessPoolExecutor(max_workers=a.workers) as pool:
            for fut in as_completed([pool.submit(extract_one, j) for j in jobs]):
                src, _dst, status, n = fut.result()
                stats[status] = stats.get(status, 0) + 1
                if status == "empty":
                    say("  [empty] %s" % os.path.basename(src))
    else:
        for j in jobs:
            src, _dst, status, n = extract_one(j)
            stats[status] = stats.get(status, 0) + 1
            if status == "empty":
                say("  [empty] %s" % os.path.basename(src))
    say("Extraction finished: %s" % stats)
    write_status(os.path.join(a.cache, "_extract.csv"), True, json.dumps(stats))


# ------------------------------------------------------------ keyword count
def _norm_en(s: str) -> str:
    return re.sub(r"\s+", " ", s.strip().lower())


def build_counter(lang: str):
    if lang == "en":
        cache = {}

        def count(text, kw):
            key = kw
            rx = cache.get(key)
            if rx is None:
                words = [re.escape(w) for w in _norm_en(kw).split(" ")]
                pat = r"(?<![A-Za-z0-9])" + r"\s+".join(words) + r"(?![A-Za-z0-9])"
                rx = re.compile(pat, re.I)
                cache[key] = rx
            return len(rx.findall(text))

        return count, _norm_en

    def count(text, kw):
        return text.count(kw)

    return count, (lambda s: s.strip())


def count_one(args):
    src, cache, keywords, lang = args
    rel = os.path.splitext(os.path.basename(src))[0]
    txt_path = os.path.join(cache, rel + ".txt")
    if not os.path.exists(txt_path):
        return None
    with open(txt_path, "r", encoding="utf-8", errors="ignore") as fh:
        text = fh.read()
    text_l = text.lower() if lang == "en" else text
    counter, normaliser = build_counter(lang)
    counts = [counter(text_l, normaliser(k)) for k in keywords]
    n_cjk = len(_CJK_RE.findall(text))
    n_words = len(re.findall(r"[A-Za-z0-9']+", text))
    stkcd, year = parse_meta(src)
    return {
        "stkcd": stkcd,
        "year": year,
        "filename": os.path.basename(src),
        "n_chars": len(text),
        "n_words": n_words if lang == "en" else n_cjk,
        "counts": counts,
        "total": sum(counts),
    }


def do_count(a) -> None:
    if a.kwfile:
        with open(a.kwfile, "r", encoding="utf-8") as fh:
            keywords = [ln.strip() for ln in fh if ln.strip()]
    else:
        keywords = [k.strip() for k in a.keywords.split(",") if k.strip()]
    if not keywords:
        raise SystemExit("No keyword supplied (use --keywords or --kwfile).")
    files = list_files(a.path, a.pattern, a.recursive)
    if not files:
        raise SystemExit("No file matching %r under %s" % (a.pattern, a.path))
    os.makedirs(a.cache, exist_ok=True)
    # Auto-extract any document that is not yet in the text cache.
    missing = []
    for f in files:
        txt = os.path.join(a.cache, os.path.splitext(os.path.basename(f))[0] + ".txt")
        if not os.path.exists(txt):
            missing.append((f, a.cache, False))
    if missing:
        say("Extracting %d new document(s) ..." % len(missing))
        if a.workers > 1 and len(missing) > 1:
            with ProcessPoolExecutor(max_workers=a.workers) as pool:
                list(pool.map(extract_one, missing))
        else:
            for j in missing:
                extract_one(j)
    jobs = [(f, a.cache, keywords, a.lang) for f in files]
    rows = []
    if a.workers > 1 and len(files) > 1:
        with ProcessPoolExecutor(max_workers=a.workers) as pool:
            for fut in as_completed([pool.submit(count_one, j) for j in jobs]):
                r = fut.result()
                if r:
                    rows.append(r)
    else:
        for j in jobs:
            r = count_one(j)
            if r:
                rows.append(r)
    rows.sort(key=lambda r: (str(r["stkcd"]), str(r["year"]), r["filename"]))
    header = (["stkcd", "year", "filename", "n_chars", "n_words"]
              + ["wf%d" % (i + 1) for i in range(len(keywords))] + ["wf_total"])
    os.makedirs(os.path.dirname(os.path.abspath(a.out)) or ".", exist_ok=True)
    with open(a.out, "w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(header)
        for r in rows:
            w.writerow([r["stkcd"], r["year"], r["filename"], r["n_chars"],
                        r["n_words"]] + r["counts"] + [r["total"]])
    meta = {"keywords": keywords, "lang": a.lang, "n_docs": len(rows),
            "n_files": len(files)}
    with open(os.path.splitext(a.out)[0] + "_meta.json", "w", encoding="utf-8") as fh:
        json.dump(meta, fh, ensure_ascii=False, indent=2)
    say("Counted %d keyword(s) in %d document(s) -> %s"
        % (len(keywords), len(rows), a.out))
    write_status(a.out, True, "%d keywords, %d documents" % (len(keywords), len(rows)))


# ------------------------------------------------------------------- CLI
def main(argv=None):
    p = argparse.ArgumentParser(description="PDF keyword-frequency engine")
    sub = p.add_subparsers(dest="cmd", required=True)

    def common(sp):
        sp.add_argument("--path", required=True)
        sp.add_argument("--pattern", default="*.pdf")
        sp.add_argument("--cache", required=True)
        sp.add_argument("--recursive", action="store_true")
        sp.add_argument("--workers", type=int, default=4)

    sp = sub.add_parser("extract")
    common(sp)
    sp.add_argument("--force", action="store_true")
    sp.set_defaults(func=do_extract)

    sp = sub.add_parser("count")
    common(sp)
    sp.add_argument("--keywords", default="")
    sp.add_argument("--kwfile", default="")
    sp.add_argument("--lang", default="cn", choices=["cn", "en"])
    sp.add_argument("--out", required=True)
    sp.set_defaults(func=do_count)

    a = p.parse_args(argv)
    a.func(a)



# ------------------------------------------------------- job-spec entry point
def _parse_spec(path):
    """Parse a tiny ``key = value`` job file (UTF-8, no escaping needed)."""
    spec = {"keyword": []}
    with open(path, "r", encoding="utf-8-sig", errors="replace") as fh:
        for line in fh:
            line = line.rstrip("\r\n")
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            if "=" not in line:
                continue
            key, val = line.split("=", 1)
            key = key.strip().lower()
            val = val.strip()
            if key in ("keyword", "kw"):
                spec["keyword"].append(val)
            else:
                spec[key] = val
    return spec


def do_job(a) -> None:
    """Run extract or count from a UTF-8 job file (safe for CJK paths)."""
    spec = _parse_spec(a.spec)
    cmd = (spec.get("cmd") or spec.get("command") or "count").lower()
    ns = argparse.Namespace(
        path=spec.get("path", "."),
        pattern=spec.get("pattern", "*.pdf"),
        cache=spec.get("cache", os.path.join(os.path.dirname(a.spec), "_cache")),
        recursive=str(spec.get("recursive", "1")).lower() not in ("0", "no", "false"),
        workers=int(spec.get("workers", 4)),
        force=str(spec.get("force", "0")).lower() in ("1", "yes", "true"),
        keywords=",".join(spec["keyword"]),
        kwfile=spec.get("kwfile", ""),
        lang=spec.get("lang", spec.get("language", "cn")),
        out=spec.get("out", ""),
    )
    if cmd == "count" and not ns.out:
        ns.out = os.path.join(os.path.dirname(os.path.abspath(a.spec)),
                              "wordfreq_result.csv")
    try:
        if cmd == "extract":
            do_extract(ns)
        elif cmd == "count":
            do_count(ns)
        else:
            raise SystemExit("Unknown job cmd: %s" % cmd)
    except BaseException as exc:  # noqa: BLE001 - report back to Stata
        write_status(ns.out or a.spec, False, "ERROR: %s: %s" % (type(exc).__name__, exc))
        say("ERROR: %s: %s" % (type(exc).__name__, exc))
        raise
    write_status(ns.out, True)


def main2(argv=None):
    p = argparse.ArgumentParser(description="PDF keyword-frequency engine (job mode)")
    p.add_argument("--spec", required=True)
    main_job = p.parse_args(argv)
    do_job(main_job)


if __name__ == "__main__":
    if "--spec" in sys.argv:
        main2()
    else:
        main()
