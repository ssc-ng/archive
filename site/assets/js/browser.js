/* Package selector, package history and availability pages for the archive site.

   Nothing is embedded in the pages. Data is fetched asynchronously from
   assets/data/ (written by build_data.py):

     manifest.json      always, on load (a few KB): snapshot list, tag
                        ranges, gaps with reasons
     snap/<date>.json   selector page, on demand: one snapshot's package
                        names (~15 KB gz); neighbouring snapshots are
                        prefetched when idle
     presence.json      history page (and idle prefetch elsewhere): all
                        names with the runs of snapshots each appears in
                        and the snapshots where its .pkg changed (~25 KB gz)

   Every fetch goes through getJSON(), which caches the in-flight promise,
   so a slider drag, a prefetch and a click for the same file share one
   request. */
"use strict";

const BASE = window.DATA_BASE || "assets/data/";
const $ = id => document.getElementById(id);
const esc = s => s.replace(/[&<>"]/g, c =>
  ({"&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;"}[c]));
const fmt = n => n.toLocaleString("en-US");

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
const idle = cb => (window.requestIdleCallback || (f => setTimeout(f, 300)))(cb);

function status(msg, busy) {
  const el = $("loadstat");
  el.textContent = msg;
  el.classList.toggle("busy", !!busy);
}

function snapIndexOnOrBefore(snaps, date) {
  let k = 0;
  snaps.forEach(([d], i) => { if (d <= date) k = i; });
  return k;
}

function hashParams() { return new URLSearchParams(location.hash.slice(1)); }
function saveHash(p) { history.replaceState(null, "", "#" + p.toString()); }

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
  // WCAG 1.4.13 (dismissable): Escape hides any open tooltip, whether it is
  // showing because of hover or of focus, without moving the pointer or
  // focus. The dismissed state (a class on <body>, which overrides the
  // hover/focus rules in custom.scss) lasts until the pointer enters a
  // tooltip trigger again or focus moves onto one.
  const root = document.body;
  document.addEventListener("keydown", e => {
    if (e.key === "Escape") root.classList.add("tips-dismissed");
  });
  document.addEventListener("focusin", e => {
    if (e.target.closest(".tip")) root.classList.remove("tips-dismissed");
  });
  document.addEventListener("mouseover", e => {
    const tip = e.target.closest(".tip");
    if (tip && !tip.contains(e.relatedTarget)) root.classList.remove("tips-dismissed");
  });
}

/* ------------------------------------------------------------------ */
/* Select packages page                                                */
/* ------------------------------------------------------------------ */

const PAGE = 150;                     // rows rendered per "show more"
const S = {                           // all mutable state in one place
  snaps: [], idx: 0, req: 0,          // idx = loaded snapshot, req = requested
  names: [], q: "", letter: "", limit: PAGE, sel: new Set()
};
const cache = new Map();              // snapshot date -> sorted names

function loadSnap(i) {
  const d = S.snaps[i][0];
  if (cache.has(d)) return Promise.resolve(cache.get(d));
  return getJSON("snap/" + d + ".json").then(j => (cache.set(d, j.p), j.p));
}

// Show a snapshot in the timeline controls (requested or loaded).
function showSnap(i) {
  $("tl").value = i;
  $("tl-date").textContent = S.snaps[i][0];
  $("prev").disabled = i === 0;
  $("next").disabled = i === S.snaps.length - 1;
  $("datepick").value = S.snaps[i][0];
}

// While a snapshot loads, the list still describes the previous one, so it
// is inert and Copy is off; commands are always built from the loaded
// snapshot (S.idx) and its names, never from the requested date.
function setLoading(on) {
  $("list").inert = $("letters").inert = $("more").inert = on;
  $("list").classList.toggle("stale", on);
  if (on) $("copybtn").disabled = true; else command();
}

// Resolves true if this request is the one now shown, false if it failed
// or was superseded by a newer one.
let loadToken = 0;
async function selectSnap(i) {
  const req = Math.max(0, Math.min(S.snaps.length - 1, i));
  const token = ++loadToken, d = S.snaps[req][0];
  S.req = req;
  showSnap(req);
  $("snapnote").classList.remove("show");
  const t0 = performance.now(), hit = cache.has(d);
  if (!hit) { status("Loading snapshot " + d + "…", true); setLoading(true); }
  try {
    const names = await loadSnap(req);
    if (token !== loadToken) return false;      // a newer selection superseded us
    S.idx = req; S.names = names;
    const have = new Set(names), gone = [...S.sel].filter(n => !have.has(n));
    gone.forEach(n => S.sel.delete(n));         // no commands for absent packages
    status(`${fmt(names.length)} packages in ${d}` +
      (hit ? " (cached)" : ` · loaded in ${Math.round(performance.now() - t0)} ms`) +
      (gone.length ? `. Not in this snapshot, so deselected: ${gone.join(", ")}` : ""));
    S.limit = PAGE;
    setLoading(false);
    render();
    idle(() => [S.idx - 1, S.idx + 1].forEach(j => {
      if (j >= 0 && j < S.snaps.length) loadSnap(j).catch(() => {});
    }));
    return true;
  } catch (e) {
    if (token !== loadToken) return false;
    showSnap(S.idx);                            // back to what is actually loaded
    setLoading(false);
    status("Could not load snapshot " + d + ": " + e.message +
      (S.names.length ? ` Still showing ${S.snaps[S.idx][0]}.` : ""));
    return false;
  }
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
  const n = S.snaps.length, tl = $("tl"), dp = $("datepick");
  tl.max = n - 1; tl.disabled = false;
  $("tl-min").textContent = S.snaps[0][0];
  $("tl-max").textContent = S.snaps[n - 1][0];
  dp.min = S.snaps[0][0]; dp.max = S.snaps[n - 1][0]; dp.disabled = false;
  $("q").disabled = false;
  $("stats").innerHTML =
    `Snapshots offered: every tag before <code>2021-12-21</code>, the first tag of each ` +
    `month since, and the latest (<code>${m.latest}</code>). ` +
    `All ${fmt(m.tagCount)} tags are listed on the <a href="tags.html">availability page</a>. ` +
    `Data built ${m.built}. A package is a <code>.pkg</code> file under ` +
    `<code>fmwww.bc.edu/repec/bocode/</code> in the snapshot.`;

  const h = hashParams();                      // restore state from the URL
  const start = h.get("s") ? snapIndexOnOrBefore(S.snaps, h.get("s")) : n - 1;
  S.q = h.get("q") || ""; $("q").value = S.q;
  S.letter = h.get("l") || "";
  (h.get("p") || "").split(",").filter(Boolean).forEach(x => S.sel.add(x));

  // Separate timers: typing in Search must not cancel a pending slider fetch.
  let snapTimer, searchTimer;
  tl.addEventListener("input", () => {
    $("tl-date").textContent = S.snaps[+tl.value][0];
    clearTimeout(snapTimer);
    snapTimer = setTimeout(() => selectSnap(+tl.value), 120);   // fetch once the drag settles
  });
  $("prev").onclick = () => selectSnap(S.req - 1);
  $("next").onclick = () => selectSnap(S.req + 1);
  dp.addEventListener("change", () => {
    const want = dp.value;                      // selectSnap() overwrites dp.value
    if (!want) return;
    const i = snapIndexOnOrBefore(S.snaps, want);
    selectSnap(i).then(ok => {
      if (ok && S.snaps[i][0] !== want) {
        $("snapnote").textContent = "no listed snapshot on " + want + "; showing " + S.snaps[i][0];
        $("snapnote").classList.add("show");
      }
    });
  });
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

  selectSnap(start);
  idle(() => getJSON("presence.json").catch(() => {}));
}

/* ------------------------------------------------------------------ */
/* Package history page                                                */
/* ------------------------------------------------------------------ */

const H = {snaps: [], pres: null, name: "", sel: -1};

function presenceOf(name, p = H.pres) {
  let lo = 0, hi = p.p.length - 1;                 // names are sorted
  while (lo <= hi) {
    const mid = (lo + hi) >> 1;
    if (p.p[mid] === name) return {runs: p.r[mid], changed: p.c[mid]};
    if (p.p[mid] < name) lo = mid + 1; else hi = mid - 1;
  }
  return null;
}

function showHistory(name, selDate) {
  const rec = presenceOf(name);
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
  const on = new Set(), chg = new Set(rec.changed);
  for (let k = 0; k < rec.runs.length; k += 2)
    for (let i = rec.runs[k]; i <= rec.runs[k + 1]; i++) on.add(i);
  H.on = on; H.chg = chg;
  H.sel = selDate ? snapIndexOnOrBefore(H.snaps, selDate) : -1;
  const n = H.snaps.length, first = Math.min(...on), last = Math.max(...on);
  const gaps = last - first + 1 - on.size;
  $("hist").hidden = false;
  $("d-name").textContent = name;
  $("d-text").textContent =
    `In ${on.size} of ${n} listed snapshots: first ${H.snaps[first][0]}, last ${H.snaps[last][0]}` +
    (gaps ? `, with ${gaps} snapshot${gaps > 1 ? "s" : ""} missing in between` : "") +
    `. Its package file changed in ${chg.size} of them. Select a block for details.`;
  $("d-min").textContent = H.snaps[0][0];
  $("d-max").textContent = H.snaps[n - 1][0];
  $("d-changes").innerHTML = chg.size
    ? `<span class="hint">Package file changed at:</span> ` +
      [...chg].map(i => `<button type="button" class="letter chgbtn" data-i="${i}">${H.snaps[i][0]}</button>`).join(" ")
    : `<span class="hint">The package file did not change between the listed snapshots.</span>`;
  drawStrip();
  const p = new URLSearchParams();
  p.set("p", name);
  if (H.sel >= 0) p.set("s", H.snaps[H.sel][0]);
  saveHash(p);
}

function stateOf(i) {
  return H.on.has(i) ? (H.chg.has(i) ? "present, package file changed since the previous listed snapshot"
                                     : "present") : "not in this snapshot";
}

function drawStrip() {
  $("strip").innerHTML = H.snaps.map(([d], i) =>
    `<button type="button" data-i="${i}" class="${H.on.has(i) ? (H.chg.has(i) ? "chg" : "on") : ""}` +
    `${i === H.sel ? " cur" : ""}" aria-pressed="${i === H.sel}" ` +
    `title="${d}: ${stateOf(i)}" aria-label="${d}: ${stateOf(i)}"></button>`).join("");
  const box = $("d-pick");
  if (H.sel < 0) { box.innerHTML = ""; return; }
  const d = H.snaps[H.sel][0];
  box.innerHTML = `<b>${d}</b>: ${stateOf(H.sel)}.` + (H.on.has(H.sel)
    ? ` <a href="browse.html#s=${d}&amp;p=${encodeURIComponent(H.name)}">Select ${esc(H.name)} as of ${d}</a>`
    : "");
}

function pickSnap(i) {
  H.sel = i; drawStrip();
  const p = hashParams(); p.set("s", H.snaps[i][0]); saveHash(p);
}

async function initHistory(m) {
  H.snaps = m.snapshots;
  $("stats").innerHTML = `Snapshots: every tag before <code>2021-12-21</code>, the first tag of each ` +
    `month since, and the latest (<code>${m.latest}</code>). "Changed" compares a package's ` +
    `<code>.pkg</code> file with the one in the previous listed snapshot (a month apart for recent ones). Data built ${m.built}.`;
  status("Loading package index…", true);
  try {
    H.pres = await getJSON("presence.json");
  } catch (e) { status("Could not load the package index: " + e.message); return; }
  status(`${fmt(H.pres.p.length)} packages known`);
  $("pkgdl").innerHTML = H.pres.p.map(n => `<option value="${esc(n)}">`).join("");
  const q = $("hq");
  q.disabled = false;
  const go = () => { const v = q.value.trim(); if (v) showHistory(v); };
  q.addEventListener("change", go);
  q.addEventListener("keydown", e => { if (e.key === "Enter") go(); });
  $("suggest").addEventListener("click", e => {
    const b = e.target.closest("button[data-n]");
    if (b) { q.value = b.dataset.n; showHistory(b.dataset.n); }
  });
  $("strip").addEventListener("click", e => {
    const b = e.target.closest("button[data-i]"); if (b) pickSnap(+b.dataset.i);
  });
  $("d-changes").addEventListener("click", e => {
    const b = e.target.closest("button[data-i]"); if (b) pickSnap(+b.dataset.i);
  });
  const fromHash = () => {            // initial load, and back/forward or an edited URL
    const h = hashParams();
    if (h.get("p")) { q.value = h.get("p"); showHistory(h.get("p"), h.get("s")); }
  };
  addEventListener("hashchange", fromHash);
  fromHash();
  if (!q.value) q.focus();
}

/* ------------------------------------------------------------------ */
/* Compare page                                                        */
/* ------------------------------------------------------------------ */

const CPAGE = 100;                    // rows per page
const C = {a: 0, b: 0, pres: null, lists: null, tab: "", q: "", page: 1};

// Added / removed / changed between two listed snapshots (a older than b).
// Added and removed compare the two package lists. Changed means the
// package is in both and its .pkg file was modified at some listed snapshot
// after a, up to and including b (so a change that was later undone still
// counts). Each row carries the detail shown next to the name.
function diffSnapshots(ia, ib, namesA, namesB, pres) {
  const setA = new Set(namesA), setB = new Set(namesB);
  const added = [], removed = [], changed = [];
  let same = 0;
  const when = i => C.snaps[i][0];
  for (const n of namesB) {
    const rec = presenceOf(n, pres);
    if (!setA.has(n)) {
      let first = ib;                               // first listed snapshot after a that has it
      for (let k = 0; rec && k < rec.runs.length; k += 2)
        if (rec.runs[k + 1] > ia) { first = Math.max(rec.runs[k], ia + 1); break; }
      added.push({n, d: "first listed " + when(first)});
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
    let last = ia;                                  // last listed snapshot before b that has it
    for (let k = 0; rec && k < rec.runs.length; k += 2)   // a run may start long before a
      if (rec.runs[k + 1] >= ia && rec.runs[k] < ib)
        last = Math.max(last, Math.min(rec.runs[k + 1], ib - 1));
    removed.push({n, d: `last listed ${when(last)}; gone by ${when(last + 1)}`});
  }
  return {added, removed, changed, same, nA: namesA.length, nB: namesB.length};
}

let cmpToken = 0;
async function runCompare() {
  let ia = +$("cmp-a").value, ib = +$("cmp-b").value;
  const token = ++cmpToken;
  $("cmp-result").hidden = true;
  if (ia === ib) { status("Pick two different snapshots."); return; }
  if (ia > ib) [ia, ib] = [ib, ia];                 // older one is always the base
  const [da, db] = [C.snaps[ia][0], C.snaps[ib][0]];
  status(`Loading ${da} and ${db}…`, true);
  try {
    const [namesA, namesB, pres] = await Promise.all([loadSnap(ia), loadSnap(ib), getJSON("presence.json")]);
    if (token !== cmpToken) return;                 // superseded by a newer choice
    C.pres = pres;
    C.lists = diffSnapshots(ia, ib, namesA, namesB, pres);
    C.da = da; C.db = db;
    $("n-added").textContent = fmt(C.lists.added.length);
    $("n-removed").textContent = fmt(C.lists.removed.length);
    $("n-changed").textContent = fmt(C.lists.changed.length);
    $("n-same").textContent = fmt(C.lists.same);
    $("cmp-sum").textContent =
      `${da} has ${fmt(C.lists.nA)} packages; ${db} has ${fmt(C.lists.nB)} ` +
      `(${C.lists.nB >= C.lists.nA ? "+" : "−"}${fmt(Math.abs(C.lists.nB - C.lists.nA))}). ` +
      `Packages are compared at these two snapshots only; "changed" means the package's ` +
      `.pkg file was modified at some listed snapshot in between.`;
    status(`Compared ${da} with ${db}.`);
    $("cmp-result").hidden = false;
    renderCompareList();
  } catch (e) {
    if (token === cmpToken) status("Could not compare: " + e.message);
  }
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
  p.set("a", C.snaps[Math.min(+$("cmp-a").value, +$("cmp-b").value)][0]);
  p.set("b", C.snaps[Math.max(+$("cmp-a").value, +$("cmp-b").value)][0]);
  if (C.tab) p.set("t", C.tab);
  if (C.q) p.set("q", C.q);
  if (C.page > 1) p.set("pg", C.page);
  saveHash(p);
}

function initCompare(m) {
  C.snaps = S.snaps = m.snapshots;                  // loadSnap() reads S.snaps
  const n = C.snaps.length, opts = C.snaps.map(([d, c], i) =>
    `<option value="${i}">${d} (${fmt(c)} packages)</option>`).join("");
  $("cmp-a").innerHTML = $("cmp-b").innerHTML = opts;
  let keepPage = 1;
  const fromHash = () => {                          // initial load, and a pasted/edited link
    const h = hashParams();
    const idxOf = (v, dflt) => v ? snapIndexOnOrBefore(C.snaps, v) : dflt;
    $("cmp-b").value = idxOf(h.get("b"), n - 1);
    $("cmp-a").value = idxOf(h.get("a"), Math.max(0, n - 13));   // about a year back
    C.tab = ["added", "removed", "changed"].includes(h.get("t")) ? h.get("t") : "";
    C.q = h.get("q") || ""; $("cmp-q").value = C.q;
    C.page = keepPage = +h.get("pg") || 1;
    runCompare().then(() => { if (keepPage > 1) { C.page = keepPage; renderCompareList(); } });
  };
  for (const id of ["cmp-a", "cmp-b", "cmp-swap"]) $(id).disabled = false;
  $("stats").innerHTML = `Snapshots offered: every tag before <code>2021-12-21</code>, the first tag of each ` +
    `month since, and the latest (<code>${m.latest}</code>). Data built ${m.built}.`;

  const rerun = () => { C.page = 1; runCompare(); };
  $("cmp-a").onchange = $("cmp-b").onchange = rerun;
  $("cmp-swap").onclick = () => {
    [$("cmp-a").value, $("cmp-b").value] = [$("cmp-b").value, $("cmp-a").value]; rerun();
  };
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
  addEventListener("hashchange", fromHash);
  fromHash();
}

/* ------------------------------------------------------------------ */

getJSON("manifest.json").then(m => {
  if ($("ranges")) initRanges(m);
  if ($("tl")) initSelect(m);
  if ($("hq")) initHistory(m);
  if ($("cmp-a")) initCompare(m);
}).catch(e => {
  const msg = "Could not load the snapshot data (" + e.message + ").";
  if ($("loadstat")) status(msg);
  if ($("tagsummary")) $("tagsummary").textContent = msg;
});
