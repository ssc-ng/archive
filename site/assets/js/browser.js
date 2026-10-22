/* Package selector, compare, package history and availability pages for the
   archive site.

   Nothing is embedded in the pages. Data is fetched asynchronously from
   assets/data/ (written by build_data.py) and covers EVERY date tag:

     manifest.json   always, on load (~5 KB gzipped): all snapshots with their
                     package counts, tag ranges, and the gaps with reasons
     presence.json   package pages (~28 KB gzipped): every package with the
                     runs of snapshots it appears in and the snapshots where
                     its .pkg changed. The package list of ANY snapshot is
                     rebuilt from the runs in the browser, so there is no
                     per-snapshot file.

   Every fetch goes through getJSON(), which caches the in-flight promise. */
"use strict";

const BASE = window.DATA_BASE || "assets/data/";
const $ = id => document.getElementById(id);
const esc = s => String(s).replace(/[&<>"]/g, c =>
  ({"&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;"}[c]));
const fmt = n => n.toLocaleString("en-US");
const plural = (n, w) => `${fmt(n)} ${w}${n === 1 ? "" : "s"}`;

const inflight = new Map();
function getJSON(path) {
  if (!inflight.has(path)) {
    const p = fetch(BASE + path).then(r => {
      if (!r.ok) throw new Error(path + ": HTTP " + r.status);
      return r.json();
    });
    p.catch(() => inflight.delete(path));       // allow a retry after failure
    inflight.set(path, p);
  }
  return inflight.get(path);
}

function status(msg, busy) {
  const el = $("loadstat");
  el.textContent = msg;
  el.classList.toggle("busy", !!busy);
}
function hashParams() { return new URLSearchParams(location.hash.slice(1)); }
function saveHash(p) { history.replaceState(null, "", "#" + p.toString()); }

/* ------------------------------------------------------------------ */
/* Dates                                                               */
/* ------------------------------------------------------------------ */

const pad2 = n => String(n).padStart(2, "0");
const dim = (y, m) => new Date(Date.UTC(y, m, 0)).getUTCDate();         // m is 1-based
const dayDiff = (a, b) => Math.round((Date.parse(b) - Date.parse(a)) / 864e5);
const addDays = (d, k) => new Date(Date.parse(d) + k * 864e5).toISOString().slice(0, 10);
const monthIndex = ym => { const [y, m] = ym.split("-").map(Number); return y * 12 + m - 1; };
const ymFromIndex = t => `${Math.floor(t / 12)}-${pad2(t % 12 + 1)}`;
const firstOfMonth = ym => ym + "-01";
const lastOfMonth = ym => { const [y, m] = ym.split("-").map(Number); return `${ym}-${pad2(dim(y, m))}`; };
function addMonths(date, k) {
  const [y, m, d] = date.split("-").map(Number), t = y * 12 + m - 1 + k;
  const ny = Math.floor(t / 12), nm = t % 12 + 1;
  return `${ny}-${pad2(nm)}-${pad2(Math.min(d, dim(ny, nm)))}`;
}

// Index of the last snapshot on or before `date` (0 if it is before the first).
function snapIndexOnOrBefore(snaps, date) {
  let lo = 0, hi = snaps.length - 1;
  while (lo < hi) {
    const mid = (lo + hi + 1) >> 1;
    if (snaps[mid][0] <= date) lo = mid; else hi = mid - 1;
  }
  return lo;
}

// Why are there no snapshots between a and b (inclusive)? From the manifest's
// gaps (ERRATA.md), or because the range is outside the first/last tag.
function makeReasoner(m) {
  return (a, b) => {
    const why = [...new Set(m.gaps.filter(g => g[0] <= b && g[1] >= a).map(g => g[3]))];
    if (why.length) return why.join("; ").replace(/\.$/, "") + ".";
    if (b < m.earliest) return `Before the first snapshot (${m.earliest}).`;
    if (a > m.latest) return `After the latest snapshot (${m.latest}); not taken yet.`;
    return "No snapshot.";
  };
}

/* ------------------------------------------------------------------ */
/* Package index (presence.json)                                       */
/* ------------------------------------------------------------------ */

function presenceOf(name, p) {                     // names are sorted
  let lo = 0, hi = p.p.length - 1;
  while (lo <= hi) {
    const mid = (lo + hi) >> 1;
    if (p.p[mid] === name) return {runs: p.r[mid], changed: p.c[mid]};
    if (p.p[mid] < name) lo = mid + 1; else hi = mid - 1;
  }
  return null;
}

// Sorted package names present in snapshot i, rebuilt from the runs.
const nameCache = new Map();
function namesAt(pres, i) {
  if (nameCache.has(i)) return nameCache.get(i);
  const out = [];
  for (let k = 0; k < pres.p.length; k++) {
    const R = pres.r[k];
    for (let j = 0; j < R.length; j += 2) {
      if (R[j] > i) break;
      if (i <= R[j + 1]) { out.push(pres.p[k]); break; }
    }
  }
  nameCache.set(i, out);
  if (nameCache.size > 16) nameCache.delete(nameCache.keys().next().value);
  return out;
}

/* ------------------------------------------------------------------ */
/* Two-level timeline: a bar of months and, below it, the days of the  */
/* selected month. Used by every page that picks a snapshot.           */
/*                                                                     */
/* A grey tick stands for a stretch with no snapshots (several months  */
/* in the top bar, several days in the bottom one) and carries the     */
/* reason from ERRATA.md in a tooltip. Keys: arrows step one snapshot, */
/* PageUp/PageDown one month (with Shift: one year), Home/End first    */
/* and last.                                                           */
/* ------------------------------------------------------------------ */

function createTimeline(root, o) {
  const snaps = o.snaps, n = snaps.length, dates = snaps.map(s => s[0]);
  const byDate = new Map(dates.map((d, i) => [d, i]));
  const months = [];                                // every month with a snapshot
  dates.forEach((d, i) => {
    const ym = d.slice(0, 7), last = months[months.length - 1];
    if (last && last.ym === ym) last.idxs.push(i); else months.push({ym, idxs: [i]});
  });
  let lo = o.lo ?? 0, hi = o.hi ?? n - 1, idx = Math.max(lo, Math.min(hi, o.idx ?? hi));

  root.classList.add("tl2");
  root.classList.toggle("plain", !o.state);
  root.innerHTML =
    `<div class="tl2-stage">` +
    `<div class="tl2-bubble">` +
    `<button type="button" class="stepbtn" data-m="-1" aria-label="Previous month">&lsaquo;</button>` +
    `<span class="tl2-mlabel"></span>` +
    `<button type="button" class="stepbtn" data-m="1" aria-label="Next month">&rsaquo;</button></div>` +
    `<div class="tl2-stem"></div>` +
    `<div class="tl2-bar tl2-months" role="group" aria-label="Months"></div>` +
    `<svg class="tl2-funnel" aria-hidden="true" focusable="false"><polygon/><path/></svg>` +
    `<div class="tl2-bar tl2-days" role="group" aria-label="Days of the selected month"></div></div>` +
    `<div class="tl2-summary"><div class="tl2-big"></div><div class="tl2-info"></div>` +
    `<div class="tl2-action"></div><div class="snapnote" role="status"></div></div>` +
    `<p class="hint tl2-keys">Arrow keys: one snapshot &middot; PgUp/PgDn: one month ` +
    `(Shift: one year) &middot; Home/End: first/last</p>`;
  const $stage = root.querySelector(".tl2-stage"), $bubble = root.querySelector(".tl2-bubble");
  const $stem = root.querySelector(".tl2-stem"), $fun = root.querySelector(".tl2-funnel");
  const $m = root.querySelector(".tl2-months"), $d = root.querySelector(".tl2-days");
  const $mlabel = root.querySelector(".tl2-mlabel"), $note = root.querySelector(".snapnote");
  const $big = root.querySelector(".tl2-big"), $info = root.querySelector(".tl2-info");
  const $action = root.querySelector(".tl2-action");

  const gapCell = (grow, text, right) =>
    `<span class="gapwrap${right ? " r" : ""}" style="flex-grow:${grow}">` +
    `<span class="tip gapcell" role="img" aria-label="${esc(text)}"></span>` +
    `<span class="tipbox" role="tooltip" aria-hidden="true">${esc(text)}</span></span>`;
  const range = (a, b) => a === b ? a : `${a} to ${b}`;

  // Place the month bubble over the selected month's tick and draw the funnel
  // from that tick down to the full width of the day bar.
  function layout() {
    const sel = $m.querySelector(".mcell.sel"), sb = $stage.getBoundingClientRect();
    if (!sel || !sb.width) return;                  // not visible (e.g. a closed panel)
    const c = sel.getBoundingClientRect(), dr = $d.getBoundingClientRect();
    const cx = c.left + c.width / 2 - sb.left, bw = $bubble.offsetWidth;
    $bubble.style.left = Math.max(0, Math.min(sb.width - bw, cx - bw / 2)) + "px";
    const top = $bubble.offsetTop + $bubble.offsetHeight;
    $stem.style.cssText = `left:${cx}px;top:${top}px;height:${Math.max(0, c.top - sb.top - top)}px`;
    const h = $fun.getBoundingClientRect().height;
    $fun.setAttribute("width", sb.width); $fun.setAttribute("height", h);
    const x1 = c.left - sb.left, x2 = c.right - sb.left, dl = dr.left - sb.left, dr2 = dr.right - sb.left;
    $fun.querySelector("polygon").setAttribute("points", `${x1},0 ${x2},0 ${dr2},${h} ${dl},${h}`);
    $fun.querySelector("path").setAttribute("d", `M${x1},0 L${dl},${h} M${x2},0 L${dr2},${h}`);
  }
  if (window.ResizeObserver) new ResizeObserver(layout).observe(root);

  function render() {
    const cur = dates[idx], curYm = cur.slice(0, 7);
    // ---- months
    const list = months.filter(M => M.idxs[M.idxs.length - 1] >= lo && M.idxs[0] <= hi);
    let html = "", prevT = null, prevYear = null;
    list.forEach((M, k) => {
      const t = monthIndex(M.ym), allowed = M.idxs.filter(i => i >= lo && i <= hi);
      if (prevT !== null && t - prevT > 1) {
        const a = firstOfMonth(ymFromIndex(prevT + 1)), b = lastOfMonth(ymFromIndex(t - 1));
        html += gapCell(Math.min(t - prevT - 1, 3),
          `${range(a, b)}: ${o.reason(a, b)}`, k > list.length / 2);
      }
      const year = M.ym.slice(0, 4);
      const cls = ["mcell", M.ym === curYm ? "sel" : "", o.monthState ? o.monthState(allowed) : ""].join(" ");
      const label = `${M.ym}: ${plural(allowed.length, "snapshot")}`;
      html += `<button type="button" class="${cls}" data-ym="${M.ym}"` +
        `${year !== prevYear ? ` data-yr="${year}"` : ""} tabindex="${M.ym === curYm ? 0 : -1}" ` +
        `aria-label="${esc(label)}" title="${esc(label)}"${M.ym === curYm ? ' aria-current="true"' : ""}></button>`;
      prevT = t; prevYear = year;
    });
    $m.innerHTML = html;
    // ---- days of the selected month
    const [y, mo] = curYm.split("-").map(Number), nd = dim(y, mo);
    html = "";
    for (let d = 1; d <= nd; ) {
      const date = `${curYm}-${pad2(d)}`, i = byDate.get(date);
      if (i !== undefined && i >= lo && i <= hi) {
        const label = o.cellLabel ? o.cellLabel(i) : `${date}: ${plural(snaps[i][1], "package")}`;
        const cls = ["dcell", i === idx ? "sel" : "", o.state ? o.state(i) : ""].join(" ");
        html += `<button type="button" class="${cls}" data-i="${i}" tabindex="${i === idx ? 0 : -1}" ` +
          `aria-label="${esc(label)}" title="${esc(label)}"${i === idx ? ' aria-current="true"' : ""}>${d}</button>`;
        d++;
        continue;
      }
      const blocked = i !== undefined;               // a snapshot, but outside the allowed range
      let e = d;                                     // extend over days of the same kind
      while (e + 1 <= nd) {
        const j = byDate.get(`${curYm}-${pad2(e + 1)}`);
        if ((j !== undefined) !== blocked || (j !== undefined && j >= lo && j <= hi)) break;
        e++;
      }
      const a = `${curYm}-${pad2(d)}`, b = `${curYm}-${pad2(e)}`;
      html += gapCell(e - d + 1,
        `${range(a, b)}: ${blocked ? (o.blockedReason || "Not selectable here.") : o.reason(a, b)}`, d > nd / 2);
      d = e + 1;
    }
    $d.innerHTML = html;
    // ---- bubble, selection summary
    const pos = list.findIndex(M => M.ym === curYm);
    $mlabel.textContent = curYm;
    root.querySelector('[data-m="-1"]').disabled = pos <= 0;
    root.querySelector('[data-m="1"]').disabled = pos >= list.length - 1;
    $big.textContent = cur;
    $info.textContent = o.info ? o.info(idx) : "";
    $action.innerHTML = o.action ? o.action(idx) : "";
    layout();
  }

  function renderKeepFocus() {
    const active = root.contains(document.activeElement) && document.activeElement.closest(".tl2-bar");
    const which = active && (active === $m ? $m : $d);
    render();
    if (which) which.querySelector('[tabindex="0"]')?.focus();
  }

  function nearest(date) {                           // allowed snapshot closest to a date
    let a = lo, b = hi + 1;
    while (a < b) { const mid = (a + b) >> 1; if (dates[mid] < date) a = mid + 1; else b = mid; }
    const cand = [a, a - 1].filter(i => i >= lo && i <= hi);
    return cand.reduce((best, i) =>
      Math.abs(dayDiff(dates[i], date)) < Math.abs(dayDiff(dates[best], date)) ? i : best);
  }

  const noteClear = () => { $note.textContent = ""; $note.classList.remove("show"); };
  function note(text) { $note.textContent = text; $note.classList.add("show"); }

  function go(target, announce = true) {
    target = Math.max(lo, Math.min(hi, target));
    if (target === idx) return false;
    const prev = idx;
    idx = target;
    noteClear();
    renderKeepFocus();
    if (announce && Math.abs(target - prev) === 1) {   // stepped across a stretch with no snapshots?
      const [a, b] = target > prev ? [dates[prev], dates[target]] : [dates[target], dates[prev]];
      const skipped = dayDiff(a, b) - 1;
      if (skipped > 0) note(`Skipped ${plural(skipped, "day")} without a snapshot: ` +
        o.reason(addDays(a, 1), addDays(b, -1)));
    }
    o.onChange && o.onChange(idx);
    return true;
  }

  function jump(k) {
    let t = nearest(addMonths(dates[idx], k));
    if (k > 0 && t <= idx) t = idx + 1;
    if (k < 0 && t >= idx) t = idx - 1;
    return t;
  }

  root.addEventListener("click", e => {
    const mc = e.target.closest(".mcell"), dc = e.target.closest(".dcell"), sb = e.target.closest(".stepbtn");
    if (dc) go(+dc.dataset.i);
    else if (mc) {                                    // the snapshot of that month nearest the current day
      const day = +dates[idx].slice(8), ym = mc.dataset.ym;
      const cand = months.find(M => M.ym === ym).idxs.filter(i => i >= lo && i <= hi);
      go(cand.reduce((b, i) => Math.abs(+dates[i].slice(8) - day) < Math.abs(+dates[b].slice(8) - day) ? i : b));
    } else if (sb) go(jump(+sb.dataset.m));
  });
  root.addEventListener("keydown", e => {
    if (!e.target.closest(".tl2-bar")) return;
    const big = e.shiftKey ? 12 : 1;
    const t = {ArrowLeft: idx - 1, ArrowDown: idx - 1, ArrowRight: idx + 1, ArrowUp: idx + 1,
      Home: lo, End: hi}[e.key] ?? (e.key === "PageUp" ? jump(big) : e.key === "PageDown" ? jump(-big) : null);
    if (t === null) return;
    e.preventDefault();
    go(t);
  });

  render();
  return {
    get: () => idx,
    set(i) { idx = Math.max(lo, Math.min(hi, i)); noteClear(); render(); },
    setRange(l, h) { lo = l; hi = h; idx = Math.max(lo, Math.min(hi, idx)); render(); },
    refresh: renderKeepFocus,
  };
}

/* ------------------------------------------------------------------ */
/* Tooltips: Escape dismisses any open one (WCAG 1.4.13), whether it   */
/* shows because of hover or of focus, without moving the pointer or   */
/* focus. The dismissed state (a class on <body>, which overrides the  */
/* hover/focus rules in custom.scss) lasts until the pointer enters a  */
/* trigger again or focus moves onto one.                              */
/* ------------------------------------------------------------------ */

function installTooltipDismissal() {
  const root = document.body;
  document.addEventListener("keydown", e => {
    if (e.key === "Escape") root.classList.add("tips-dismissed");
  });
  document.addEventListener("focusin", e => {
    if (e.target.closest(".tip")) root.classList.remove("tips-dismissed");
  });
  document.addEventListener("mouseover", e => {
    const tip = e.target.closest(".tip, .gapwrap");
    if (tip && !tip.contains(e.relatedTarget)) root.classList.remove("tips-dismissed");
  });
}

/* ------------------------------------------------------------------ */
/* Availability page: contiguous ranges of tags, and the gaps          */
/* ------------------------------------------------------------------ */

function initRanges(m) {
  const link = d => `<a href="https://github.com/ssc-ng/archive/releases/tag/${d}">${d}</a>`;
  const rows = [];
  m.ranges.forEach(([from, to, n], i) => {
    const g = i > 0 && m.gaps[i - 1];
    if (g) {
      // The reason is a tooltip that shows on hover AND keyboard focus, is
      // dismissable with Escape, and is also exposed to assistive tech
      // through aria-describedby (so it does not depend on hovering).
      rows.push(`<tr class="gap"><td colspan="4"><span class="tip" tabindex="0" ` +
        `aria-describedby="gap${i}">${g[2]} day${g[2] > 1 ? "s" : ""} without a snapshot` +
        `<span class="sr-only"> (${g[0]}${g[0] === g[1] ? "" : " to " + g[1]})</span></span>` +
        `<span class="tipbox" role="tooltip" id="gap${i}">` +
        `<b>${g[0]}${g[0] === g[1] ? "" : " to " + g[1]}:</b> ${esc(g[3])}</span></td></tr>`);
    }
    const badges =
      (from === m.earliest ? '<span class="badge earliest">earliest tag</span>' : "") +
      (to === m.latest ? '<span class="badge latest">latest tag</span>' : "");
    rows.push(`<tr${badges ? ' class="edge"' : ""}><td>${link(from)}</td>` +
      `<td>${from === to ? "&mdash;" : link(to)}</td><td class="num">${n}</td><td>${badges}</td></tr>`);
  });
  $("ranges").querySelector("tbody").innerHTML = rows.join("");
  $("ranges").hidden = false;
  $("tagsummary").innerHTML =
    `<b>${fmt(m.tagCount)}</b> snapshots in <b>${m.ranges.length}</b> contiguous ranges, ` +
    `from <b>${m.earliest}</b> (earliest) to <b>${m.latest}</b> (latest).`;
}

const footnote = m =>
  `Snapshots available: every tag, ${m.earliest} to ${m.latest} (${fmt(m.tagCount)}); ` +
  `see the <a href="tags.html">availability page</a> for the gaps. Data built ${m.built}. ` +
  `A package is a <code>.pkg</code> file under <code>fmwww.bc.edu/repec/bocode/</code> in the snapshot.`;

/* ------------------------------------------------------------------ */
/* Select packages page                                                */
/* ------------------------------------------------------------------ */

const PAGE = 150;                     // rows rendered per "show more"
const S = {                           // all mutable state in one place
  snaps: [], idx: 0, names: [], q: "", letter: "", limit: PAGE, sel: new Set(),
  pres: null, tl: null
};

function applySnap(i) {
  S.idx = i;
  S.names = namesAt(S.pres, i);
  const have = new Set(S.names), gone = [...S.sel].filter(n => !have.has(n));
  gone.forEach(n => S.sel.delete(n));             // no commands for absent packages
  status(`${plural(S.names.length, "package")} in ${S.snaps[i][0]}` +
    (gone.length ? `. Not in this snapshot, so deselected: ${gone.join(", ")}` : ""));
  S.limit = PAGE;
  render();
}

function matches() {
  const q = S.q.toLowerCase(), rows = [];
  for (const n of S.names) {
    if (S.letter && n[0].toLowerCase() !== S.letter) continue;
    const pos = q ? n.toLowerCase().indexOf(q) : 0;
    if (pos >= 0) rows.push({n, pos});
  }
  if (q) rows.sort((a, b) => (a.pos > 0) - (b.pos > 0) || a.pos - b.pos || (a.n < b.n ? -1 : 1));
  return rows;
}

function mark(n, q) {
  const i = q ? n.toLowerCase().indexOf(q.toLowerCase()) : -1;
  if (i < 0) return esc(n);
  return esc(n.slice(0, i)) + "<mark>" + esc(n.slice(i, i + q.length)) + "</mark>" + esc(n.slice(i + q.length));
}

function render() {
  const rows = matches(), shown = rows.slice(0, S.limit);
  $("list").innerHTML = shown.map(({n}) =>
    `<li class="${S.sel.has(n) ? "sel" : ""}" data-n="${esc(n)}">` +
    `<label class="nm"><input type="checkbox"${S.sel.has(n) ? " checked" : ""}> ` +
    `<span>${mark(n, S.q)}</span></label>` +
    `<a class="hist" href="history.html#p=${encodeURIComponent(n)}" ` +
    `aria-label="History of ${esc(n)}">history</a></li>`).join("");
  $("count").textContent = (rows.length === S.names.length
    ? `${fmt(rows.length)} packages`
    : `${fmt(rows.length)} ${rows.length === 1 ? "match" : "matches"} of ${fmt(S.names.length)}`);
  const more = rows.length - shown.length;
  $("more").hidden = more <= 0;
  $("more").textContent = `show ${Math.min(PAGE, more)} more (${fmt(more)} remaining)`;
  buildLetters();
  command();
  saveSelectHash();
}

function buildLetters() {
  const keys = [...new Set(S.names.map(n => n[0].toLowerCase()))].sort();
  $("letters").innerHTML =
    `<button type="button" class="letter" data-l="" aria-pressed="${S.letter === ""}">all</button>` +
    keys.map(l => `<button type="button" class="letter" data-l="${esc(l)}" aria-pressed="${S.letter === l}">${esc(l)}</button>`).join("");
}

function command() {
  const d = S.snaps[S.idx][0], names = [...S.sel].sort(), lines = [];
  if (names.length && $("bootstrap").checked) {
    lines.push('<span class="cm">* one-time installation of ssc2</span>');
    lines.push('<span class="p">. </span>ssc install ssc2');
  }
  if (names.length) {
    lines.push(`<span class="cm">* ${names.length} package${names.length > 1 ? "s" : ""}, as of ${d}</span>`);
    const opts = `<span class="opt">date(${d})</span>` +
      ($("replaceopt").checked ? ' <span class="opt">replaceall</span>' : "");
    for (const n of names)
      lines.push(`<span class="p">. </span>ssc2 install ${esc(n)}, ${opts}`);
  }
  $("out").innerHTML = lines.join("\n") + (lines.length ? "\n" : "") +
    '<span class="p">. </span><span class="cursor"></span>';
  $("copybtn").disabled = !names.length;
  $("clearsel").disabled = !names.length;
  $("clearsel").textContent = names.length ? `Clear selections (${names.length})` : "Clear selections";
}

function plainCommand() {
  return $("out").textContent.replace(/^\. ?/gm, "").replace(/\n+$/, "");
}

function saveSelectHash() {
  const p = new URLSearchParams();
  p.set("s", S.snaps[S.idx][0]);
  if (S.q) p.set("q", S.q);
  if (S.letter) p.set("l", S.letter);
  if (S.sel.size) p.set("p", [...S.sel].sort().join(","));
  saveHash(p);
}

function initSelect(m) {
  S.snaps = m.snapshots;
  const n = S.snaps.length, reason = makeReasoner(m);
  $("stats").innerHTML = footnote(m);

  const readHash = () => {                     // state from the URL
    const h = hashParams();
    S.q = h.get("q") || ""; $("q").value = S.q;
    S.letter = h.get("l") || "";
    S.sel = new Set((h.get("p") || "").split(",").filter(Boolean));
    return h.get("s") ? snapIndexOnOrBefore(S.snaps, h.get("s")) : n - 1;
  };
  const start = readHash();

  S.tl = createTimeline($("tl-root"), {
    snaps: S.snaps, reason, idx: start,
    info: i => plural(S.snaps[i][1], "package"),
    onChange: i => S.pres && applySnap(i),
  });

  let searchTimer;                              // search has its own debounce
  $("q").addEventListener("input", e => {
    S.q = e.target.value.trim(); S.limit = PAGE;
    clearTimeout(searchTimer);
    searchTimer = setTimeout(render, 80);
  });
  document.addEventListener("keydown", e => {
    if (e.key === "/" && !/^(INPUT|SELECT|TEXTAREA)$/.test(document.activeElement.tagName)) {
      e.preventDefault(); $("q").focus();
    }
  });
  $("letters").addEventListener("click", e => {
    const b = e.target.closest("button[data-l]");
    if (b) { S.letter = b.dataset.l; S.limit = PAGE; render(); }
  });
  $("more").onclick = () => { S.limit += PAGE; render(); };
  $("list").addEventListener("change", e => {
    const li = e.target.closest("li[data-n]");
    if (!li) return;
    e.target.checked ? S.sel.add(li.dataset.n) : S.sel.delete(li.dataset.n);
    li.classList.toggle("sel", e.target.checked);
    command(); saveSelectHash();
  });
  $("replaceopt").onchange = $("bootstrap").onchange = command;
  $("clearsel").onclick = () => { S.sel.clear(); render(); };
  $("copybtn").onclick = () => {
    const done = () => { $("copybtn").textContent = "Copied"; setTimeout(() => $("copybtn").textContent = "Copy", 1200); };
    (navigator.clipboard ? navigator.clipboard.writeText(plainCommand()) : Promise.reject()).then(done, () => {
      const r = document.createRange(); r.selectNodeContents($("out"));
      const sel = getSelection(); sel.removeAllRanges(); sel.addRange(r);
    });
  };

  status("Loading the package index…", true);
  getJSON("presence.json").then(pres => {
    S.pres = pres;
    $("q").disabled = false;
    addEventListener("hashchange", () => {     // a pasted or edited link on this page
      S.tl.set(readHash());
      applySnap(S.tl.get());
    });
    applySnap(S.tl.get());
  }).catch(e => status("Could not load the package index: " + e.message));
}

/* ------------------------------------------------------------------ */
/* Compare page                                                        */
/* ------------------------------------------------------------------ */

const CPAGE = 100;                    // rows per page
const C = {snaps: [], pres: null, ia: 0, ib: 0, lists: null, tab: "", q: "", page: 1, pages: 1};

// Added / removed / changed between two snapshots (ia < ib). Added and
// removed compare the two package lists. Changed means the package is in
// both and its .pkg file was modified at some snapshot after ia, up to and
// including ib (so a change that was later undone still counts). Each row
// carries the detail shown next to the name.
function diffSnapshots(ia, ib, namesA, namesB, pres, when) {
  const setA = new Set(namesA), setB = new Set(namesB);
  const added = [], removed = [], changed = [];
  let same = 0;
  for (const n of namesB) {
    const rec = presenceOf(n, pres);
    if (!setA.has(n)) {
      let first = ib;                               // first snapshot after ia that has it
      for (let k = 0; rec && k < rec.runs.length; k += 2)
        if (rec.runs[k + 1] > ia) { first = Math.max(rec.runs[k], ia + 1); break; }
      added.push({n, d: "first available " + when(first)});
    } else {
      const ch = rec ? rec.changed.filter(i => i > ia && i <= ib) : [];
      if (ch.length) {
        const shown = ch.slice(0, 3).map(when).join(", ");
        changed.push({n, d: "package file changed " + shown + (ch.length > 3 ? ` (+${ch.length - 3} more)` : "")});
      } else same++;
    }
  }
  for (const n of namesA) if (!setB.has(n)) {
    const rec = presenceOf(n, pres);
    let last = ia;                                  // last snapshot before ib that has it
    for (let k = 0; rec && k < rec.runs.length; k += 2)   // a run may start long before ia
      if (rec.runs[k + 1] >= ia && rec.runs[k] < ib)
        last = Math.max(last, Math.min(rec.runs[k + 1], ib - 1));
    removed.push({n, d: `last available ${when(last)}; removed by ${when(last + 1)}`});
  }
  return {added, removed, changed, same, nA: namesA.length, nB: namesB.length};
}

function runCompare() {
  if (!C.pres) return;
  const {ia, ib} = C, [da, db] = [C.snaps[ia][0], C.snaps[ib][0]];
  const when = i => C.snaps[i][0];
  C.lists = diffSnapshots(ia, ib, namesAt(C.pres, ia), namesAt(C.pres, ib), C.pres, when);
  C.da = da; C.db = db;
  $("n-added").textContent = fmt(C.lists.added.length);
  $("n-removed").textContent = fmt(C.lists.removed.length);
  $("n-changed").textContent = fmt(C.lists.changed.length);
  $("n-same").textContent = fmt(C.lists.same);
  $("cmp-sum").textContent =
    `${da} has ${fmt(C.lists.nA)} packages; ${db} has ${fmt(C.lists.nB)} ` +
    `(${C.lists.nB >= C.lists.nA ? "+" : "−"}${fmt(Math.abs(C.lists.nB - C.lists.nA))}). ` +
    `Packages are compared at these two snapshots only; "changed" means the package's ` +
    `.pkg file was modified at some snapshot in between.`;
  status(`Compared ${da} with ${db}.`);
  $("cmp-result").hidden = false;
  renderCompareList();
}

function compareRows() {
  const q = C.q.toLowerCase();
  return (C.lists[C.tab] || []).filter(r => !q || r.n.toLowerCase().includes(q));
}

function renderCompareList() {
  for (const b of document.querySelectorAll(".tile[data-t]"))
    b.setAttribute("aria-pressed", String(b.dataset.t === C.tab));
  $("cmp-listbox").hidden = !C.tab;
  if (C.tab) {
    const rows = compareRows(), pages = Math.max(1, Math.ceil(rows.length / CPAGE));
    C.page = Math.max(1, Math.min(pages, C.page));
    const from = (C.page - 1) * CPAGE, shown = rows.slice(from, from + CPAGE);
    $("cmp-legend").textContent = `Packages ${C.tab} between ${C.da} and ${C.db}`;
    $("cmp-list").innerHTML = shown.map(r =>
      `<li><a class="nm" href="history.html#p=${encodeURIComponent(r.n)}" title="History of ${esc(r.n)}">${esc(r.n)}</a>` +
      `<span class="detail">${esc(r.d)}</span></li>`).join("");
    $("cmp-count").textContent = rows.length
      ? `${fmt(from + 1)}–${fmt(from + shown.length)} of ${fmt(rows.length)}` +
        (C.q ? ` matching "${C.q}"` : "")
      : (C.q ? "No matches." : "None.");
    $("pager").hidden = pages <= 1;
    $("pg-info").textContent = `Page ${fmt(C.page)} of ${fmt(pages)}`;
    $("pg-first").disabled = $("pg-prev").disabled = C.page === 1;
    $("pg-next").disabled = $("pg-last").disabled = C.page === pages;
    C.pages = pages;
  }
  const p = new URLSearchParams();
  p.set("a", C.snaps[C.ia][0]);
  p.set("b", C.snaps[C.ib][0]);
  if (C.tab) p.set("t", C.tab);
  if (C.q) p.set("q", C.q);
  if (C.page > 1) p.set("pg", C.page);
  saveHash(p);
}

function initCompare(m) {
  C.snaps = m.snapshots;
  const n = C.snaps.length, reason = makeReasoner(m);
  $("stats").innerHTML = footnote(m);
  const label = i => `${C.snaps[i][0]} · ${plural(C.snaps[i][1], "package")}`;
  const setButtons = () => {
    $("cmp-a-btn").textContent = label(C.ia) + " ▾";
    $("cmp-b-btn").textContent = label(C.ib) + " ▾";
  };
  // From/To from the URL (or: the latest snapshot against about a year before it)
  const resolve = h => {
    let ib = h.get("b") ? snapIndexOnOrBefore(C.snaps, h.get("b")) : n - 1;
    let ia = h.get("a") ? snapIndexOnOrBefore(C.snaps, h.get("a"))
                        : snapIndexOnOrBefore(C.snaps, addMonths(C.snaps[ib][0], -12));
    if (ia >= ib) { ib = n - 1; ia = Math.min(ia, n - 2); }
    return [ia, ib];
  };

  let tlA, tlB;
  const [ia0, ib0] = resolve(hashParams());
  C.ia = ia0; C.ib = ib0;
  tlA = createTimeline($("cmp-a-tl"), {
    snaps: C.snaps, reason, lo: 0, hi: n - 2, idx: ia0,
    blockedReason: "The latest snapshot cannot be the starting point.",
    info: i => plural(C.snaps[i][1], "package"),
    onChange: i => {
      C.ia = i;
      const keep = tlB.get();                       // To offers only snapshots after From
      tlB.setRange(i + 1, n - 1);
      tlB.set(keep > i ? keep : n - 1);
      C.ib = tlB.get();
      C.page = 1; setButtons(); runCompare();
    },
  });
  tlB = createTimeline($("cmp-b-tl"), {
    snaps: C.snaps, reason, lo: ia0 + 1, hi: n - 1, idx: ib0,
    blockedReason: "Must be later than the From snapshot.",
    info: i => plural(C.snaps[i][1], "package"),
    onChange: i => { C.ib = i; C.page = 1; setButtons(); runCompare(); },
  });

  const fromHash = () => {                          // initial load, and a pasted/edited link
    const h = hashParams();
    [C.ia, C.ib] = resolve(h);
    C.tab = ["added", "removed", "changed"].includes(h.get("t")) ? h.get("t") : "";
    C.q = h.get("q") || ""; $("cmp-q").value = C.q;
    C.page = +h.get("pg") || 1;
    tlA.set(C.ia); tlB.setRange(C.ia + 1, n - 1); tlB.set(C.ib);
    setButtons();
    const page = C.page;
    runCompare();
    if (page > 1) { C.page = page; renderCompareList(); }
  };

  // Expanding panels: one open at a time, Escape closes and returns to the button.
  const panels = [["cmp-a-btn", "cmp-a-panel"], ["cmp-b-btn", "cmp-b-panel"]];
  const toggle = (btnId, open) => {
    for (const [b, p] of panels) {
      const on = b === btnId ? (open ?? $(p).hidden) : false;
      $(p).hidden = !on; $(b).setAttribute("aria-expanded", String(on));
    }
  };
  for (const [b, p] of panels) {
    $(b).disabled = false;
    $(b).onclick = () => toggle(b);
    $(p).addEventListener("keydown", e => {
      if (e.key === "Escape" && !$(p).hidden) { toggle(b, false); $(b).focus(); }
    });
  }

  for (const b of document.querySelectorAll(".tile[data-t]"))
    b.onclick = () => { C.tab = C.tab === b.dataset.t ? "" : b.dataset.t; C.page = 1; renderCompareList(); };
  let t;
  $("cmp-q").addEventListener("input", e => {
    C.q = e.target.value.trim(); C.page = 1;
    clearTimeout(t); t = setTimeout(renderCompareList, 80);
  });
  const go = d => () => { C.page = d === "first" ? 1 : d === "last" ? C.pages : C.page + d; renderCompareList();
    $("cmp-listbox").scrollIntoView({block: "nearest"}); };
  $("pg-first").onclick = go("first"); $("pg-last").onclick = go("last");
  $("pg-prev").onclick = go(-1); $("pg-next").onclick = go(1);

  setButtons();
  status("Loading the package index…", true);
  getJSON("presence.json").then(pres => {
    C.pres = pres;
    addEventListener("hashchange", fromHash);
    fromHash();
  }).catch(e => status("Could not load the package index: " + e.message));
}

/* ------------------------------------------------------------------ */
/* Package history page                                                */
/* ------------------------------------------------------------------ */

const H = {snaps: [], pres: null, name: "", on: new Set(), chg: new Set(), tl: null};

function stateOf(i) {
  return H.on.has(i) ? (H.chg.has(i) ? "available, package file changed since the previous snapshot"
                                     : "available")
                     : "not in this snapshot";
}

function showHistory(name, selDate) {
  const rec = presenceOf(name, H.pres);
  $("suggest").innerHTML = "";
  if (!rec) {
    $("hist").hidden = true;
    const q = name.toLowerCase();
    const near = q ? H.pres.p.filter(n => n.toLowerCase().includes(q)).slice(0, 8) : [];
    $("suggest").innerHTML = `<span class="hint">No package named <code>${esc(name)}</code>.` +
      (near.length ? " Did you mean: " : "") + "</span> " +
      near.map(n => `<button type="button" class="letter sug" data-n="${esc(n)}">${esc(n)}</button>`).join(" ");
    return;
  }
  H.name = name;
  H.on = new Set(); H.chg = new Set(rec.changed);
  for (let k = 0; k < rec.runs.length; k += 2)
    for (let i = rec.runs[k]; i <= rec.runs[k + 1]; i++) H.on.add(i);
  const n = H.snaps.length, first = rec.runs[0], last = rec.runs[rec.runs.length - 1];
  const gaps = last - first + 1 - H.on.size;
  $("hist").hidden = false;
  $("d-name").textContent = name;
  $("d-text").textContent =
    `Available in ${fmt(H.on.size)} of ${fmt(n)} snapshots: first ${H.snaps[first][0]}, last ${H.snaps[last][0]}` +
    (gaps ? `, with ${plural(gaps, "snapshot")} without it in between` : "") +
    `. Its package file ${H.chg.size === 0 ? "never changed" : H.chg.size === 1 ? "changed once" : "changed " + fmt(H.chg.size) + " times"}.`;
  drawChanges();
  const sel = selDate ? snapIndexOnOrBefore(H.snaps, selDate) : H.tl.get();
  H.tl.set(sel);
  const p = new URLSearchParams();
  p.set("p", name);
  if (selDate) p.set("s", H.snaps[sel][0]);
  saveHash(p);
}

// The dates of the package file changes: kept in the page for screen readers
// (the highlighted days in the timeline show them to everyone else).
function drawChanges() {
  const all = [...H.chg].reverse();
  $("d-changes").innerHTML = all.length
    ? `<span>Package file changed at:</span> ` +
      all.map(i => `<button type="button" tabindex="-1" data-i="${i}">${H.snaps[i][0]}</button>`).join(" ")
    : `<span>The package file never changed.</span>`;
}

function pickSnap(i) {
  const p = hashParams(); p.set("s", H.snaps[i][0]); saveHash(p);
}

function initHistory(m) {
  H.snaps = m.snapshots;
  const n = H.snaps.length, reason = makeReasoner(m);
  $("stats").innerHTML = footnote(m) +
    ` "Changed" compares a package's <code>.pkg</code> file with the one in the previous snapshot.`;
  status("Loading the package index…", true);
  getJSON("presence.json").then(pres => {
    H.pres = pres;
    status(`${fmt(pres.p.length)} packages known`);
    $("pkgdl").innerHTML = pres.p.map(x => `<option value="${esc(x)}">`).join("");
    const q = $("hq");
    q.disabled = false;
    H.tl = createTimeline($("hist-tl"), {
      snaps: H.snaps, reason, idx: n - 1,
      state: i => H.on.has(i) ? (H.chg.has(i) ? "chg" : "on") : "off",
      monthState: idxs => {
        if (idxs.some(i => H.chg.has(i))) return "chg";
        const k = idxs.filter(i => H.on.has(i)).length;
        return k === idxs.length ? "on" : k ? "part" : "off";
      },
      cellLabel: i => `${H.snaps[i][0]}: ${stateOf(i)}`,
      info: i => stateOf(i),
      action: i => H.on.has(i)
        ? `<a href="browse.html#s=${H.snaps[i][0]}&amp;p=${encodeURIComponent(H.name)}">` +
          `Install ${esc(H.name)} as of ${H.snaps[i][0]}</a>` : "",
      onChange: pickSnap,
    });
    const go = () => { const v = q.value.trim(); if (v) showHistory(v); };
    q.addEventListener("change", go);
    q.addEventListener("keydown", e => { if (e.key === "Enter") go(); });
    $("suggest").addEventListener("click", e => {
      const b = e.target.closest("button[data-n]");
      if (b) { q.value = b.dataset.n; showHistory(b.dataset.n); }
    });
    $("d-changes").addEventListener("click", e => {
      const b = e.target.closest("button[data-i]");
      if (b) { H.tl.set(+b.dataset.i); pickSnap(+b.dataset.i); }
    });
    const fromHash = () => {          // initial load, and back/forward or an edited URL
      const h = hashParams();
      if (h.get("p")) { q.value = h.get("p"); showHistory(h.get("p"), h.get("s")); }
    };
    addEventListener("hashchange", fromHash);
    fromHash();
    if (!q.value) q.focus();
  }).catch(e => status("Could not load the package index: " + e.message));
}

/* ------------------------------------------------------------------ */

installTooltipDismissal();
getJSON("manifest.json").then(m => {
  if ($("ranges")) initRanges(m);
  if ($("tl-root")) initSelect(m);
  if ($("cmp-a-tl")) initCompare(m);
  if ($("hq")) initHistory(m);
}).catch(e => {
  const msg = "Could not load the snapshot data (" + e.message + ").";
  if ($("loadstat")) status(msg);
  if ($("tagsummary")) $("tagsummary").textContent = msg;
});
