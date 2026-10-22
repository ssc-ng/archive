/* Package browser and snapshot-range pages for the archive site.

   Nothing is embedded in the page. Data is fetched asynchronously from
   assets/data/ (written by build_data.py):

     manifest.json      always, on load (a few KB): snapshot list + tag ranges
     snap/<date>.json   on demand, one snapshot's package names (~15 KB gz);
                        neighbouring snapshots are prefetched when idle
     presence.json      on demand (~20 KB gz): all names with the runs of
                        snapshots each appears in; used for the history strip

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

/* ------------------------------------------------------------------ */
/* Snapshots page: contiguous ranges of tags                           */
/* ------------------------------------------------------------------ */

function daysBetween(a, b) {
  return Math.round((Date.parse(b) - Date.parse(a)) / 864e5);
}

function initRanges(m) {
  const tbody = $("ranges").querySelector("tbody");
  const rows = [];
  m.ranges.forEach(([from, to, n], i) => {
    if (i > 0) {
      const gap = daysBetween(m.ranges[i - 1][1], from) - 1;
      if (gap > 0) rows.push(`<tr class="gap"><td colspan="4">${gap} day${gap > 1 ? "s" : ""} without a snapshot</td></tr>`);
    }
    const badges =
      (from === m.earliest ? '<span class="badge earliest">earliest tag</span>' : "") +
      (to === m.latest ? '<span class="badge latest">latest tag</span>' : "");
    const link = d => `<a href="https://github.com/ssc-ng/archive/releases/tag/${d}">${d}</a>`;
    rows.push(`<tr${badges ? ' class="edge"' : ""}><td>${link(from)}</td>` +
      `<td>${from === to ? "&mdash;" : link(to)}</td><td class="num">${n}</td><td>${badges}</td></tr>`);
  });
  tbody.innerHTML = rows.join("");
  $("ranges").hidden = false;
  $("tagsummary").innerHTML =
    `<b>${fmt(m.tagCount)}</b> snapshots in <b>${m.ranges.length}</b> contiguous ranges, ` +
    `from <b>${m.earliest}</b> (earliest) to <b>${m.latest}</b> (latest).`;
  if ($("listfrom")) $("listfrom").textContent = m.fileListStart;
}

/* ------------------------------------------------------------------ */
/* Package browser                                                     */
/* ------------------------------------------------------------------ */

const PAGE = 150;                     // rows rendered per "show more"
const S = {                           // all mutable state in one place
  m: null, snaps: [], idx: 0, names: [], cmpNames: null,
  q: "", letter: "", limit: PAGE, sel: new Set(), presence: null,
  detail: ""
};
const cache = new Map();              // snapshot date -> sorted names

function loadSnap(i) {
  const d = S.snaps[i][0];
  if (cache.has(d)) return Promise.resolve(cache.get(d));
  return getJSON("snap/" + d + ".json").then(j => (cache.set(d, j.p), j.p));
}

function status(msg, busy) {
  const el = $("loadstat");
  el.textContent = msg;
  el.classList.toggle("busy", !!busy);
}

let loadToken = 0;
async function selectSnap(i, fromHash) {
  S.idx = Math.max(0, Math.min(S.snaps.length - 1, i));
  const token = ++loadToken, d = S.snaps[S.idx][0];
  $("tl").value = S.idx;
  $("tl-date").textContent = d;
  $("prev").disabled = S.idx === 0;
  $("next").disabled = S.idx === S.snaps.length - 1;
  $("datepick").value = d;
  $("snapnote").classList.remove("show");
  const t0 = performance.now();
  const hit = cache.has(d);
  if (!hit) status("Loading snapshot " + d + "…", true);
  try {
    const [names, cmp] = await Promise.all([loadSnap(S.idx), loadCompare()]);
    if (token !== loadToken) return;            // a newer selection superseded us
    S.names = names; S.cmpNames = cmp;
    status(`${fmt(names.length)} packages in ${d}` +
      (hit ? " (cached)" : ` · loaded in ${Math.round(performance.now() - t0)} ms`));
    S.limit = PAGE;
    render();
    drawStrip();
    idle(() => [S.idx - 1, S.idx + 1].forEach(j => {
      if (j >= 0 && j < S.snaps.length) loadSnap(j).catch(() => {});
    }));
  } catch (e) {
    if (token === loadToken) status("Could not load snapshot " + d + ": " + e.message);
  }
}

// Compare offers earlier snapshots only, so "added" and "removed" always
// read forward in time; default to about a year back.
function fillCompare() {
  const sel = $("cmpsel"), keep = sel.value === "" ? -1 : +sel.value;
  const k = S.idx;
  sel.innerHTML = S.snaps.slice(0, k).map(([d, c], i) =>
    `<option value="${i}">${d} (${fmt(c)})</option>`).join("");
  if (!k) { $("cmpon").checked = false; }
  $("cmpon").disabled = !k;
  sel.value = keep < k && sel.querySelector(`option[value="${keep}"]`) ? keep : Math.max(0, k - 12);
  const on = $("cmpon").checked;
  sel.hidden = $("onlywrap").hidden = !on;
}

async function loadCompare() {
  fillCompare();
  if (!$("cmpon").checked) return null;
  return new Set(await loadSnap(+$("cmpsel").value));
}

/* --- list ----------------------------------------------------------- */

function matches() {
  const q = S.q.toLowerCase();
  const cur = new Set(S.names);
  let pool = S.names;
  if (S.cmpNames) {                                // union, so removals are visible
    pool = [...new Set([...S.names, ...S.cmpNames])].sort();
  }
  const rows = [];
  for (const n of pool) {
    if (S.letter && n[0].toLowerCase() !== S.letter) continue;
    const pos = q ? n.toLowerCase().indexOf(q) : 0;
    if (pos < 0) continue;
    let st = "";
    if (S.cmpNames) {
      if (cur.has(n) && !S.cmpNames.has(n)) st = "new";
      else if (!cur.has(n)) st = "removed";
      if ($("onlychg").checked && !st) continue;
    }
    rows.push({n, pos, st});
  }
  if (q) rows.sort((a, b) => (a.pos > 0) - (b.pos > 0) || a.pos - b.pos || (a.n < b.n ? -1 : 1));
  return rows;
}

function mark(n, q) {
  if (!q) return esc(n);
  const i = n.toLowerCase().indexOf(q.toLowerCase());
  return esc(n.slice(0, i)) + "<mark>" + esc(n.slice(i, i + q.length)) + "</mark>" + esc(n.slice(i + q.length));
}

function render() {
  const rows = matches();
  const shown = rows.slice(0, S.limit);
  $("list").innerHTML = shown.map(({n, st}) =>
    `<li class="${S.sel.has(n) ? "sel" : ""}${st === "removed" ? " gone" : ""}" data-n="${esc(n)}">` +
    `<input type="checkbox" aria-label="Select ${esc(n)}"${S.sel.has(n) ? " checked" : ""}${st === "removed" ? " disabled" : ""}>` +
    `<button type="button" class="nm" title="Show history">${mark(n, S.q)}</button>` +
    (st ? `<span class="badge ${st}">${st}</span>` : "") + "</li>").join("");
  $("count").textContent = rows.length === S.names.length && !S.cmpNames
    ? `${fmt(rows.length)} packages`
    : `${fmt(rows.length)} ${rows.length === 1 ? "match" : "matches"}` +
      (S.cmpNames ? "" : ` of ${fmt(S.names.length)}`);
  const more = rows.length - shown.length;
  $("more").hidden = more <= 0;
  $("more").textContent = `show ${Math.min(PAGE, more)} more (${fmt(more)} remaining)`;
  buildLetters();
  command();
  saveHash();
}

function buildLetters() {
  const present = new Set(S.names.concat(S.cmpNames ? [...S.cmpNames] : []).map(n => n[0].toLowerCase()));
  const keys = [...present].sort();
  $("letters").innerHTML =
    `<button type="button" class="letter" data-l="" aria-pressed="${S.letter === ""}">all</button>` +
    keys.map(l => `<button type="button" class="letter" data-l="${esc(l)}" aria-pressed="${S.letter === l}">${esc(l)}</button>`).join("");
}

/* --- history -------------------------------------------------------- */

async function openDetail(name) {
  S.detail = name;
  $("detail").hidden = false;
  $("d-name").textContent = name;
  $("d-text").textContent = "Loading history…";
  try {
    S.presence = S.presence || await getJSON("presence.json");
  } catch (e) {
    $("d-text").textContent = "Could not load history: " + e.message;
    return;
  }
  if (S.detail !== name) return;
  drawStrip();
  saveHash();
  $("detail").scrollIntoView({block: "nearest", behavior: "smooth"});
}

function presenceOf(name) {
  const p = S.presence;
  if (!p) return null;
  let lo = 0, hi = p.p.length - 1;                 // names are sorted
  while (lo <= hi) {
    const mid = (lo + hi) >> 1;
    if (p.p[mid] === name) return p.r[mid];
    if (p.p[mid] < name) lo = mid + 1; else hi = mid - 1;
  }
  return [];
}

function drawStrip() {
  if (!S.detail || !S.presence) return;
  const runs = presenceOf(S.detail) || [], on = new Set();
  for (let k = 0; k < runs.length; k += 2)
    for (let i = runs[k]; i <= runs[k + 1]; i++) on.add(i);
  const n = S.snaps.length;
  $("strip").innerHTML = S.snaps.map(([d], i) =>
    `<button type="button" data-i="${i}" class="${on.has(i) ? "on" : ""}${i === S.idx ? " cur" : ""}" ` +
    `title="${d}${on.has(i) ? "" : " (absent)"}" aria-label="${d}${on.has(i) ? "" : " (absent)"}"></button>`).join("");
  $("d-min").textContent = S.snaps[0][0];
  $("d-max").textContent = S.snaps[n - 1][0];
  if (!on.size) {
    $("d-text").textContent = "Not found in any listed snapshot.";
    return;
  }
  const first = Math.min(...on), last = Math.max(...on);
  const gaps = last - first + 1 - on.size;
  $("d-text").textContent =
    `In ${on.size} of ${n} listed snapshots: first ${S.snaps[first][0]}, last ${S.snaps[last][0]}` +
    (gaps ? `, with ${gaps} snapshot${gaps > 1 ? "s" : ""} missing in between` : "") +
    ". Click a block to jump to that snapshot.";
}

/* --- ssc2 command --------------------------------------------------- */

function command() {
  const d = S.snaps[S.idx][0], names = [...S.sel].sort();
  const lines = [];
  if ($("bootstrap").checked) {
    lines.push('<span class="cm">* one-time installation of ssc2</span>');
    lines.push('<span class="p">. </span>ssc install ssc2');
  }
  if (!names.length) {
    lines.push('<span class="cm">* tick packages above to build their ssc2 install commands</span>');
  } else {
    lines.push(`<span class="cm">* ${names.length} package${names.length > 1 ? "s" : ""}, as of ${d}</span>`);
    const opts = `<span class="opt">date(${d})</span>` +
      ($("replaceopt").checked ? ' <span class="opt">replaceall</span>' : "");
    for (const n of names)
      lines.push(`<span class="p">. </span>ssc2 install ${esc(n)}, ${opts}`);
  }
  $("out").innerHTML = lines.join("\n") + '\n<span class="p">. </span><span class="cursor"></span>';
}

function plainCommand() {
  return $("out").textContent.replace(/^\. /gm, "").replace(/\n$/, "");
}

/* --- URL state ------------------------------------------------------ */

function saveHash() {
  const p = new URLSearchParams();
  p.set("s", S.snaps[S.idx][0]);
  if (S.q) p.set("q", S.q);
  if (S.letter) p.set("l", S.letter);
  if ($("cmpon").checked && $("cmpsel").value !== "") p.set("c", S.snaps[+$("cmpsel").value][0]);
  if (S.sel.size) p.set("p", [...S.sel].sort().join(","));
  if (S.detail) p.set("h", S.detail);
  history.replaceState(null, "", "#" + p.toString());
}

function snapIndexOnOrBefore(date) {
  let k = 0;
  S.snaps.forEach(([d], i) => { if (d <= date) k = i; });
  return k;
}

/* --- wiring --------------------------------------------------------- */

function initBrowser(m) {
  S.m = m; S.snaps = m.snapshots;
  const n = S.snaps.length;
  const tl = $("tl");
  tl.max = n - 1; tl.disabled = false;
  $("tl-min").textContent = S.snaps[0][0];
  $("tl-max").textContent = S.snaps[n - 1][0];
  const dp = $("datepick");
  dp.min = S.snaps[0][0]; dp.max = S.snaps[n - 1][0]; dp.disabled = false;
  $("q").disabled = false;
  $("stats").innerHTML =
    `Snapshots listed here: the first tag with a file list (<code>${m.fileListStart}</code>), ` +
    `the first tag of each month, and the latest (<code>${m.latest}</code>). ` +
    `All ${fmt(m.tagCount)} tags are on the <a href="tags.html">snapshots page</a>. ` +
    `Data built ${m.built}. A package is a <code>.pkg</code> file under ` +
    `<code>fmwww.bc.edu/repec/bocode/</code> in the snapshot.`;

  // restore state from the URL hash
  const h = new URLSearchParams(location.hash.slice(1));
  let start = n - 1;
  if (h.get("s")) start = snapIndexOnOrBefore(h.get("s"));
  S.q = h.get("q") || ""; $("q").value = S.q;
  S.letter = h.get("l") || "";
  (h.get("p") || "").split(",").filter(Boolean).forEach(x => S.sel.add(x));
  if (h.get("c")) {
    $("cmpon").checked = true;
    $("cmpsel").innerHTML = `<option value="${snapIndexOnOrBefore(h.get("c"))}"></option>`;
    $("cmpsel").value = snapIndexOnOrBefore(h.get("c"));
  }

  let timer;
  const later = (fn, ms) => { clearTimeout(timer); timer = setTimeout(fn, ms); };
  tl.addEventListener("input", () => {
    $("tl-date").textContent = S.snaps[+tl.value][0];
    later(() => selectSnap(+tl.value), 120);       // fetch only once the drag settles
  });
  $("prev").onclick = () => selectSnap(S.idx - 1);
  $("next").onclick = () => selectSnap(S.idx + 1);
  dp.addEventListener("change", () => {
    if (!dp.value) return;
    const i = snapIndexOnOrBefore(dp.value);
    selectSnap(i).then(() => {
      if (S.snaps[i][0] !== dp.value) {
        const note = $("snapnote");
        note.textContent = "no listed snapshot on " + dp.value + "; showing " + S.snaps[i][0];
        note.classList.add("show");
      }
    });
  });

  $("q").addEventListener("input", e => {
    S.q = e.target.value.trim(); S.limit = PAGE;
    later(render, 80);
  });
  document.addEventListener("keydown", e => {
    if (e.key === "/" && !/^(INPUT|SELECT|TEXTAREA)$/.test(document.activeElement.tagName)) {
      e.preventDefault(); $("q").focus();
    }
  });
  $("letters").addEventListener("click", e => {
    const b = e.target.closest("button[data-l]");
    if (!b) return;
    S.letter = b.dataset.l; S.limit = PAGE; render();
  });
  $("more").onclick = () => { S.limit += PAGE; render(); };

  $("list").addEventListener("click", e => {
    const li = e.target.closest("li[data-n]");
    if (!li) return;
    const name = li.dataset.n;
    if (e.target.matches("input")) {
      e.target.checked ? S.sel.add(name) : S.sel.delete(name);
      li.classList.toggle("sel", e.target.checked);
      command(); saveHash();
    } else if (e.target.closest(".nm")) {
      openDetail(name);
    }
  });
  $("strip").addEventListener("click", e => {
    const b = e.target.closest("button[data-i]");
    if (b) selectSnap(+b.dataset.i);
  });

  $("cmpon").onchange = $("cmpsel").onchange = () => selectSnap(S.idx);
  $("onlychg").onchange = render;
  $("replaceopt").onchange = $("bootstrap").onchange = command;

  $("clearbtn").onclick = () => { S.sel.clear(); render(); };
  $("copybtn").onclick = () => {
    const done = () => { $("copybtn").textContent = "Copied"; setTimeout(() => $("copybtn").textContent = "Copy", 1200); };
    (navigator.clipboard ? navigator.clipboard.writeText(plainCommand()) : Promise.reject()).then(done, () => {
      const r = document.createRange(); r.selectNodeContents($("out"));
      const sel = getSelection(); sel.removeAllRanges(); sel.addRange(r);
    });
  };

  selectSnap(start, true);
  if (h.get("h")) openDetail(h.get("h"));
  idle(() => getJSON("presence.json").then(p => S.presence = S.presence || p).catch(() => {}));
}

/* ------------------------------------------------------------------ */

getJSON("manifest.json").then(m => {
  if ($("ranges")) initRanges(m);
  if ($("tl")) initBrowser(m);
}).catch(e => {
  const msg = "Could not load the snapshot data (" + e.message + ").";
  if ($("loadstat")) status(msg);
  if ($("tagsummary")) $("tagsummary").textContent = msg;
});
