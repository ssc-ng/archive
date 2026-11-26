// Interactive tree of mchaid / maid (rD3tree). D3 v5. The numbers and the texts come ready from R (tree_data()); this file only
// draws them. Units: 100 px = 1 inch of the static graph treestyle = "boxes" of the mchaid package, whose geometry it follows.
(function () {
  "use strict";

  window.addEventListener("error", function (e) {              // errors visible in the page (and in --dump-dom)
    var p = document.getElementById("err") || document.body.appendChild(Object.assign(document.createElement("pre"), {id: "err"}));
    p.style.cssText = "position:fixed;left:8px;bottom:8px;margin:0;padding:6px 10px;background:#fee;color:#900;font:12px monospace;z-index:20;white-space:pre-wrap";
    p.textContent += e.message + " (" + (e.filename || "").split("/").pop() + ":" + e.lineno + ")\n";
  });

  var raw = JSON.parse(document.getElementById("data").textContent),
      O = raw.options, T = raw.text, ND = raw.nodes;

  var FONT = "Roboto, Arial, Helvetica, sans-serif";
  var UI = {
    en: {expand: "Expand all", collapse: "Collapse all", fit: "Fit", svg: "SVG", png: "PNG", nterm: "terminal nodes", nterm1: "terminal node", zin: "Zoom in", zout: "Zoom out", lvl: "Level"},
    es: {expand: "Expandir todo", collapse: "Contraer todo", fit: "Ajustar", svg: "SVG", png: "PNG", nterm: "nodos finales", nterm1: "nodo final", zin: "Acercar", zout: "Alejar", lvl: "Nivel"},
    ca: {expand: "Expandeix tot", collapse: "Contreu tot", fit: "Ajusta", svg: "SVG", png: "PNG", nterm: "nodes finals", nterm1: "node final", zin: "Acosta", zout: "Allunya", lvl: "Nivell"},
    fr: {expand: "Tout déplier", collapse: "Tout replier", fit: "Ajuster", svg: "SVG", png: "PNG", nterm: "nœuds terminaux", nterm1: "nœud terminal", zin: "Agrandir", zout: "Réduire", lvl: "Niveau"},
    de: {expand: "Alle öffnen", collapse: "Alle schließen", fit: "Anpassen", svg: "SVG", png: "PNG", nterm: "Endknoten", nterm1: "Endknoten", zin: "Vergrößern", zout: "Verkleinern", lvl: "Ebene"},
    it: {expand: "Espandi tutto", collapse: "Comprimi tutto", fit: "Adatta", svg: "SVG", png: "PNG", nterm: "nodi finali", nterm1: "nodo finale", zin: "Ingrandisci", zout: "Riduci", lvl: "Livello"},
    pt: {expand: "Expandir tudo", collapse: "Recolher tudo", fit: "Ajustar", svg: "SVG", png: "PNG", nterm: "nós finais", nterm1: "nó final", zin: "Ampliar", zout: "Reduzir", lvl: "Nível"}
  };
  var L = UI[O.language] || UI.en;

  // ---- sizes (px)
  var F = {nm: 16.5, nn: 12.5, sv: 15, ch: 11.5, bl: 12, pc: 10.5, pr: 14, lg: 15, lt: 17};
  var ismaid = O.kind === "maid", isdots = O.nodeplot === "dots", np = isdots ? "box" : O.nodeplot, isbar = np === "bar", isbox = np === "box", isboth = np === "both", plotbox = !isbar;
  // nodehead = "category": the heading of a box is the category (or interval) of the splitting variable that forms the node, as in the
  // branch labels, which then disappear from the connectors; the number of the node goes in a small square that sticks out of the top left corner
  // treestyle = "classic": the layout of the classic static graph (small boxes with the category of the branch and the size, the splitting
  // variable and its test over the branch, the bars only under the terminal nodes); the measures are those of the static graph (100 px = 1 inch)
  var isclassic = O.treestyle === "classic";
  var CL = {dx: 115, dy: O.showp ? 160 : 145, w0: 90, wmax: 105, bw: 92, gapbar: 12, barh: 110, fh: 17, fn: 12.5, fz: 12, fp: 12.5,
            sgap: 4.17, bh: O.showp ? 35.56 : 22, foot: 12};
  var headcat = isclassic || O.nodehead === "category";
  var hb = isclassic ? 50 : (ismaid ? (isbar ? 140 : isbox ? 130 : 172) : (isbox ? 108 : 92)) + (isdots ? 34 : 0);   // height of a node box (dots: room for the points under the box plot)
  var zt = isclassic ? CL.sgap + CL.bh + 4.26 : 46,                    // from the bottom of a box to the horizontal bar of its branches
      barh = 28, gapx = 18, topm = isclassic ? 24 : 24, sidem = 40;
  var BOXC = isclassic ? "#707070" : "#404040", BOXW = isclassic ? 1 : 1.6;           // border of the boxes of the nodes
  var G = "#404040", GREY35 = "#595959", GREY = "#404040", BEIGE = "#F5F2EB",
      MED = "#009E73";                                            // overall median (green of the Okabe-Ito palette: red was confused with the orange of "below")
  // reference line of the bars of maid: dark grey when it is the overall MEAN (center = "mean"); the median is always green
  var REFC = (O.kind === "maid" && O.nodeplot === "bar" && O.center === "mean") ? GREY : MED;

  // ---- the tree
  var byId = {};
  ND.forEach(function (n) { byId[n.id] = n; n.kids = []; n.collapsed = false; n.shown = false; });
  ND.forEach(function (n) { if (n.parent !== null && n.parent !== undefined) { n.pa = byId[n.parent]; n.pa.kids.push(n); } });
  ND.forEach(function (n) { n.kids.sort(function (a, b) { return a.x - b.x; }); n.hasKids = n.kids.length > 0; });
  var root = byId[0];
  var dmax = 0;
  ND.forEach(function (n) { if (n.id !== 0 && n.dev !== undefined) dmax = Math.max(dmax, Math.abs(n.dev)); });
  if (dmax === 0) dmax = 1;
  if (O.collapse !== null && O.collapse !== undefined) ND.forEach(function (n) { if (n.hasKids && n.depth >= O.collapse) n.collapsed = true; });

  // ---- text measurement
  var ctx = document.createElement("canvas").getContext("2d");
  function tw(txt, size, bold) { ctx.font = (bold ? "bold " : "") + size + "px " + FONT; return ctx.measureText(String(txt)).width; }
  function fmtPct(v) { return String(Math.round(v)); }

  var wb, bw, dx;
  function metrics() {
    if (isclassic) {                                              // each box as wide as its texts (at least 0.9 inches); the bars and the spacing are fixed
      dx = CL.dx; bw = CL.bw; wb = CL.w0;
      ND.forEach(function (n) {
        var fh = fitHead(n.headlab, CL.wmax - 14, false, CL.fh);
        n.fh = fh;
        n.w = Math.max(CL.w0, Math.max.apply(null, fh.lines.map(function (s) { return tw(s, fh.size); })) + 14, tw(n.ncl, CL.fn) + 20, n.hasKids ? tw(n.svar, CL.fh) + 20 : 0);
        if (n.hasKids) n.sww = Math.max(97.2, tw(n.svar, CL.fh) + 10, tw(n.stat || "", CL.fz) + 10);
        if (n.branch.length) n.bww = 0;
      });
      ext.footW = Math.max(tw(O.foot.left, CL.foot), tw(O.foot.note, CL.foot));
      return;
    }
    wb = 120;
    ND.forEach(function (n) {
      wb = Math.max(wb, tw(n.nline, F.nn) + 25, tw(n.l3 || "", F.nn) + 25, tw(n.l4 || "", F.nn) + 25,
                    headcat ? Math.min(170, tw(n.headlab, 14, true) + 20) : tw(n.name, F.nm, true) + 30);   // a longer heading is shrunk, split or cut (fitHead)
      if (n.hasKids) n.sww = Math.max(tw(n.svar, F.sv, true), tw(n.stat || "", F.ch)) + 10;
      if (n.branch.length) n.bww = Math.max.apply(null, n.branch.map(function (s) { return tw(s, F.bl); })) + 16;
      if (n.hasKids && n.sww > wb + 2 * gapx) wb = n.sww - gapx;
    });
    if (!ismaid && O.levels) { /* nothing more */ }
    bw = wb - (ismaid ? 22 : 18);
    dx = wb + gapx;
  }

  // ---- page
  var body = d3.select("body");
  var svg = body.append("svg").attr("id", "tree").attr("font-family", FONT).attr("text-anchor", "middle");
  var vp = svg.append("g").attr("id", "viewport");
  var gLinks = vp.append("g"), gLabs = vp.append("g"), gNodes = vp.append("g"), gLeg = vp.append("g");
  var tip = body.append("div").attr("id", "tip");
  if (O.main) body.append("h1").attr("id", "title").text(O.main);

  var ext = {w: 800, h: 600};
  var curT = d3.zoomIdentity;
  var zoom = d3.zoom().scaleExtent([0.1, 8]).on("zoom", function () { curT = d3.event.transform; vp.attr("transform", curT); });
  svg.call(zoom).on("dblclick.zoom", null);

  var bar = body.append("div").attr("id", "bar");
  function btn(txt, title, fn) { bar.append("button").text(txt).attr("title", title || txt).on("click", fn); }
  btn("+", L.zin, function () { svg.call(zoom.scaleBy, 1.3); });
  btn("−", L.zout, function () { svg.call(zoom.scaleBy, 1 / 1.3); });
  btn("⤢ " + L.fit, L.fit, function () { fit(true); });
  bar.append("span").attr("class", "sep");
  btn("⊞ " + L.expand, L.expand, function () { ND.forEach(function (n) { n.collapsed = false; }); update(true, true); });
  btn("⊟ " + L.collapse, L.collapse, function () { ND.forEach(function (n) { n.collapsed = n.hasKids && n.depth >= 1; }); update(true, true); });
  bar.append("span").attr("class", "sep");
  btn("SVG", "SVG", function () { exportSVG(); });
  btn("PNG", "PNG", function () { exportPNG(); });

  // ---- layout of the visible part of the tree
  var vis = [];
  function visibleKids(n) { return n.collapsed ? [] : n.kids; }
  function layout() {
    vis = [];
    var cur = 0;
    (function place(n) {
      vis.push(n);
      var ks = visibleKids(n);
      if (!ks.length) n.lx = ++cur;
      else { ks.forEach(place); n.lx = (ks[0].lx + ks[ks.length - 1].lx) / 2; }
    })(root);
    var nleaf = cur;
    // rows: the gap below a level depends on the lines of the labels of the next one
    var maxd = d3.max(vis, function (n) { return n.depth; });
    var gap = [], ytop = [];
    for (var d = 0; d < maxd; d++) {
      var nl = 1;
      vis.forEach(function (n) { if (n.depth === d + 1) nl = Math.max(nl, n.branch.length); });
      gap[d] = isclassic ? CL.dy - hb : headcat ? zt + 30 : zt + 12 + (10 + 14 * nl) + 20;                 // without the labels of the branches the drop is short
    }
    ytop[0] = topm;
    for (d = 1; d <= maxd; d++) ytop[d] = ytop[d - 1] + hb + gap[d - 1];
    var legW = legendWidth(Math.max(nleaf * dx, 760));
    var xs = Math.max(nleaf * dx + 2 * sidem, legW + 60, isclassic ? ext.footW + 40 : 0);
    var x0 = (xs - nleaf * dx) / 2;
    vis.forEach(function (n) { n.gx = x0 + (n.lx - 0.5) * dx; n.gy = ytop[n.depth]; });
    var lastClosed = vis.some(function (n) { return n.depth === maxd && n.hasKids && n.collapsed; });
    ext.treeBottom = ytop[maxd] + hb + (lastClosed ? 74 : 34);
    if (isclassic) {                                              // the terminal nodes are all at the bottom, with their bars under them
      var leafs = vis.filter(function (n) { return !visibleKids(n).length; });      // the terminal nodes and the collapsed ones
      leafs.forEach(function (n) { n.gy = ytop[maxd]; });
      if (leafs.length) {
        ext.treeBottom = ytop[maxd] + hb + CL.gapbar + CL.barh + (ismaid ? 42 : 0) + 12;
        ext.ybase = ytop[maxd] + hb + CL.gapbar + CL.barh / 2;
        ext.lx1 = d3.min(leafs, function (n) { return n.gx; }) - dx / 2;
        ext.lx2 = d3.max(leafs, function (n) { return n.gx; }) + dx / 2;
      } else ext.ybase = null;
    }
    ext.cx = xs / 2;
    ext.w = xs;
    ext.nleaf = nleaf;
    ext.treeW = nleaf * dx;
  }

  // ---- drawing of the contents of a node (does not depend on the layout)
  function line(g, x1, y1, x2, y2, col, w, dash) {
    var l = g.append("line").attr("x1", x1).attr("y1", y1).attr("x2", x2).attr("y2", y2).attr("stroke", col).attr("stroke-width", w);
    if (dash) l.attr("stroke-dasharray", dash);
    return l;
  }
  function txt(g, x, y, s, size, bold, col) {
    return g.append("text").attr("x", x).attr("y", y).attr("dy", ".35em").attr("font-size", size).attr("fill", col || "#000")
      .attr("font-weight", bold ? "bold" : "normal").text(s);
  }
  var SC = O.scale || {};
  function fx(v) { return -bw / 2 + (v - SC.vmin) * bw / (SC.vmax - SC.vmin); }

  function drawBoxPlot(g, n, yr) {
    var q1 = fx(n.q1), q3 = fx(n.q3), lo = fx(n.lo), hi = fx(n.hi), md = fx(n.med);
    g.append("rect").attr("x", q1).attr("y", yr - 12).attr("width", Math.max(q3 - q1, 0)).attr("height", 24).attr("fill", n.fill)
      .attr("stroke", GREY35).attr("stroke-width", 0.8);
    line(g, lo, yr, q1, yr, GREY35, 1); line(g, q3, yr, hi, yr, GREY35, 1);
    line(g, lo, yr - 6, lo, yr + 6, GREY35, 1); line(g, hi, yr - 6, hi, yr + 6, GREY35, 1);
    line(g, md, yr - 12, md, yr + 12, "#000", 2.4);
    line(g, fx(SC.ref), yr - 19, fx(SC.ref), yr + (isdots ? 46 : 19), MED, 1.6);
    if (isdots && n.dv) {                                       // the observations (all those outside the whiskers and a sample of the rest) in a band under the box
      var gd = g.append("g").attr("class", "dots").attr("fill", "#404040").attr("fill-opacity", 0.55);
      n.dv.forEach(function (v, i) { gd.append("circle").attr("cx", fx(v)).attr("cy", yr + 31 + 11 * n.dj[i]).attr("r", 2.6); });
    }
  }

  // heading that has to fit in mw px: smaller letter (down to 12.5), then two lines, then cut with an ellipsis
  // (bold and z0: boxes style 16.5 px bold; classic 17 px regular)
  function fitHead(s, mw, bold, z0) {
    if (bold === undefined) bold = true;
    var z;
    for (z = z0 || 16.5; z >= 12.5; z -= 0.5) if (tw(s, z, bold) <= mw) return {lines: [s], size: z};
    var words = s.split(/\s+/), best = null;
    for (z = 13; z >= 11.5 && !best; z -= 0.5) {
      for (var i = 1; i < words.length; i++) {
        var a = words.slice(0, i).join(" "), b = words.slice(i).join(" "), m = Math.max(tw(a, z, bold), tw(b, z, bold));
        if (m <= mw && (!best || m < best.m)) best = {lines: [a, b], size: z, m: m};
      }
    }
    if (best) return best;
    function cut(t) { while (t.length > 1 && tw(t + "…", 12, bold) > mw) t = t.slice(0, -1); return t + "…"; }
    if (words.length > 1) {                                       // two lines at 12 px, split where the longer one is shortest, and cut
      var bi = 1, bm = 1e9;
      for (var j = 1; j < words.length; j++) {
        var mj = Math.max(tw(words.slice(0, j).join(" "), 12, bold), tw(words.slice(j).join(" "), 12, bold));
        if (mj < bm) { bm = mj; bi = j; }
      }
      var l1 = words.slice(0, bi).join(" "), l2 = words.slice(bi).join(" ");
      return {lines: [tw(l1, 12, bold) > mw ? cut(l1) : l1, tw(l2, 12, bold) > mw ? cut(l2) : l2], size: 12};
    }
    return {lines: [cut(s)], size: 12};
  }
  // a single line (the prediction under the leaves) that has to fit in mw px: smaller letter (down to 10.5), then cut with an ellipsis
  function fitLine(s, size, bold, mw) {
    for (var z = size; z >= 10.5; z -= 0.5) if (tw(s, z, bold) <= mw) return {s: s, size: z};
    var t = s;
    while (t.length > 1 && tw(t + "…", 10.5, bold) > mw) t = t.slice(0, -1);
    return {s: t + "…", size: 10.5};
  }

  // ---- classic style: box with the heading (category of the branch) and the size; under a terminal node, its bar
  function drawClassicNode(g, n) {
    var fh = n.fh;
    g.append("rect").attr("x", -n.w / 2).attr("y", 0).attr("width", n.w).attr("height", hb).attr("fill", "#fff").attr("stroke", BOXC).attr("stroke-width", BOXW);
    if (fh.lines.length === 1) {
      txt(g, 0, 17.5, fh.lines[0], fh.size);
      txt(g, 0, 35.5, n.ncl, CL.fn);
    } else {
      fh.lines.forEach(function (s, i) { txt(g, 0, 9.3 + 13.4 * i, s, fh.size); });
      txt(g, 0, 38.5, n.ncl, CL.fn);
    }
    classicBars(g.append("g").attr("class", "cbars"), n);        // the bar of every node; it is shown under the terminal nodes and the collapsed ones
  }
  // lines of the median and the quartiles over a bar: ys = y of each line (the median first); labels = [y, half width] of the numbers of the
  // bar, which the line goes around; with quartiles = "auto" only the median is drawn if a quartile is too close to it to be told apart
  function classicLines(g, ys, labels) {
    var nq = ys.length, yd = [];
    if (nq > 1 && !isNaN(ys[0]) && O.quartiles !== "all") {
      for (var i = 1; i < nq; i++) if (Math.abs(ys[i] - ys[0]) < 7) { nq = 1; break; }
    }
    for (var j = 0; j < nq; j++) {
      var ym = ys[j];
      if (isNaN(ym) || yd.some(function (v) { return Math.abs(v - ym) < 1e-6; })) continue;
      yd.push(ym);
      var dash = j > 0, w = dash ? (O.quartiles === "all" ? 1 : 1.8) : 2.2, gp = 0;
      (labels || []).forEach(function (l) { if (Math.abs(l[0] - ym) < 9) gp = Math.max(gp, l[1]); });
      var segs = gp > 0 ? [[-50, -gp], [gp, 50]] : [[-50, 50]];
      segs.forEach(function (s) { line(g, s[0], ym, s[1], ym, MED, w, dash ? "5,4" : null); });
    }
  }
  function classicBars(g, n) {
    var y0 = hb + CL.gapbar, H = CL.barh, xa = -CL.bw / 2;
    if (!ismaid) {                                                // stacked bar of the categories, the first one at the bottom
      var cum = 0, mx = Math.max.apply(null, n.pc), labels = [], nlev = n.pc.length;
      n.pc.forEach(function (pc, j) {
        if (pc > 0) {
          var yt = y0 + H - H * (cum + pc) / 100;
          g.append("rect").attr("class", "seg s" + j).attr("x", xa).attr("y", yt).attr("width", CL.bw).attr("height", H * pc / 100)
            .attr("fill", O.levels[j].color).attr("stroke", "#fff").attr("stroke-width", 0.5);
          if (O.pct && (pc >= 12 || pc === mx)) {
            var s = fmtPct(pc) + (pc === mx ? "*" : ""), yc = y0 + H - H * (cum + pc / 2) / 100;
            g.append("text").attr("class", "seg s" + j).attr("x", 0).attr("y", yc).attr("dy", ".35em").attr("font-size", CL.fp).attr("fill", O.levels[j].text).text(s);
            labels.push([yc, tw(s, CL.fp) / 2 + 5]);
          }
        }
        cum += pc;
      });
      if (O.dvordered && O.quartiles) {                           // median and quartiles on the scale of the categories
        var lv = O.nquart === 3 ? [50, 25, 75] : [50];
        var ys = lv.map(function (L) {
          var c = 0;
          for (var jq = 0; jq < nlev; jq++) {
            var pc = n.pc[jq];
            if (pc > 0 && c + pc >= L - 1e-6) return y0 + H - H * (jq + Math.min(1, Math.max(0, (L - c) / pc))) / nlev;
            c += pc;
          }
          return NaN;
        });
        classicLines(g, ys, labels);
      }
    } else {                                                      // deviation of the mean from the overall one, blue above and orange below
      var yb = y0 + H / 2, k = (H / 2) / O.maxdev, d = n.dev * k;
      g.append("rect").attr("x", xa).attr("y", d >= 0 ? yb - d : yb).attr("width", CL.bw).attr("height", Math.abs(d))
        .attr("fill", d >= 0 ? O.colors.above : O.colors.below).attr("stroke", "#fff").attr("stroke-width", 0.5);
      txt(g, 0, y0 + H + 13, n.mtxt, CL.fp);
      txt(g, 0, y0 + H + 27, n.stxt, CL.fp);
      if (O.quartiles && n.med !== undefined) classicLines(g, [n.med, n.q1, n.q3].map(function (v) { return yb - (v - O.gm) * k; }), []);
    }
  }

  function drawNodeContents(g, n) {
    if (isclassic) { drawClassicNode(g, n); return; }
    g.append("rect").attr("x", -wb / 2).attr("y", 0).attr("width", wb).attr("height", hb).attr("fill", "#fff").attr("stroke", G).attr("stroke-width", 1.6);
    if (headcat) {
      var f = fitHead(n.headlab, wb - 16);
      f.lines.forEach(function (s, i) { txt(g, 0, f.lines.length === 1 ? 17 : 10.5 + 14.5 * i, s, f.size, true); });
      var ds = String(n.id), bwid = Math.max(16, 6.4 * ds.length + 8), bh = 15;      // number of the node: small square on top of the top left corner
      var bd = g.append("g").attr("class", "badge").attr("transform", "translate(" + (-wb / 2) + "," + (-bh) + ")");
      bd.append("rect").attr("x", 0).attr("y", 0).attr("width", bwid).attr("height", bh).attr("fill", n.leaf ? G : "#fff").attr("stroke", G).attr("stroke-width", 1.3);
      bd.append("text").attr("x", bwid / 2).attr("y", bh / 2).attr("dy", ".36em").attr("font-size", 10.5).attr("font-weight", "bold").attr("fill", n.leaf ? "#fff" : "#000").text(ds);     // a terminal node: dark square with the number in white
    } else {
      if (n.leaf) g.append("rect").attr("x", -wb / 2).attr("y", 0).attr("width", wb).attr("height", 27).attr("fill", G);   // (nodehead = "number") dark heading
      txt(g, 0, 17, n.name, F.nm, true, n.leaf ? "#fff" : null);
    }
    txt(g, 0, 39 + (ismaid ? 2 : 0), n.nline, F.nn);
    if (ismaid || isbox) txt(g, 0, ismaid ? 55 : 57, n.l3, F.nn);
    if (ismaid) txt(g, 0, 71, n.l4, F.nn);
    if (!ismaid && !isbox) {                                   // stacked bar of the categories
      var cum = 0, xa = -bw / 2, mx = Math.max.apply(null, n.pc);
      n.pc.forEach(function (pc, j) {
        if (pc > 0) {
          g.append("rect").attr("class", "seg s" + j).attr("x", xa + bw * cum / 100).attr("y", 70 - barh / 2).attr("width", bw * pc / 100)
            .attr("height", barh).attr("fill", O.levels[j].color).attr("stroke", "#fff").attr("stroke-width", 0.5);
          if (O.pct && (pc >= 12 || pc === mx) && pc >= 1)
            g.append("text").attr("class", "seg s" + j).attr("x", xa + bw * (cum + pc / 2) / 100).attr("y", 70).attr("dy", ".35em")
              .attr("font-size", F.pc).attr("fill", O.levels[j].text).text(fmtPct(pc));
        }
        cum += pc;
      });
    }
    if (ismaid && isbar) {
      var yd = 104, sc = (bw / 2) * 0.95 / dmax;
      line(g, 0, yd - 25, 0, yd + 25, REFC, 1.6);
      if (n.id !== 0) {
        var a = n.dev >= 0 ? 0 : n.dev * sc, w = Math.abs(n.dev) * sc;
        g.append("rect").attr("x", a).attr("y", yd - 18).attr("width", w).attr("height", 36).attr("fill", n.fill).attr("stroke", "#fff").attr("stroke-width", 0.5);
      }
    }
    if (plotbox) {
      var yr = !ismaid ? 86 : isbox ? 105 : 102;
      drawBoxPlot(g, n, yr);
      if (isboth && n.id !== 0) {
        var yb = 142, a0 = fx(SC.ref2), a1 = fx(n.mean);
        g.append("rect").attr("x", Math.min(a0, a1)).attr("y", yb - 13).attr("width", Math.abs(a1 - a0)).attr("height", 26).attr("fill", n.fill)
          .attr("stroke", "#fff").attr("stroke-width", 0.5);
        line(g, a0, yb - 19, a0, yb + 19, O.center === "mean" ? (n.dev >= 0 ? O.colors.above5 : O.colors.below5) : MED, 1.6);
      }
    }
    if (n.leaf && !ismaid) {                                    // prediction under the leaf: it may not touch that of the next one
      var fp = fitLine(n.pred, F.pr, true, dx - 6);
      txt(g, 0, hb + 17, fp.s, fp.size, true, n.predcol);
    }
  }

  // ---- geometry of the connectors. g(n) gives the position of a node at the moment of the animation
  function labh(c) { return 10 + 14 * c.branch.length; }
  function P(n, s) { return {x: n.px0 + (n.gx - n.px0) * s, y: n.py0 + (n.gy - n.py0) * s}; }
  function op(n, s) { return n.st === "enter" ? s : n.st === "leave" ? 1 - s : 1; }       // opacity of what hangs from a node
  function opEx(n, s) { return n.exNew && n.exOld ? 1 : n.exNew ? s : 1 - s; }          // the stem and the bar of the branches: only while the node is open
  function pStem(u, g) { var p = g(u), y0 = p.y + hb; return "M" + p.x + "," + y0 + "V" + (y0 + zt); }
  function pHbar(u, g) {
    var xs = u.kids.filter(function (c) { return c.st !== "none"; }).map(function (c) { return g(c).x; }), yl = g(u).y + hb + zt;
    return "M" + Math.min.apply(null, xs) + "," + yl + "H" + Math.max.apply(null, xs);
  }
  function pDrop(c, g) { var p = g(c.pa), q = g(c), yl = p.y + hb + zt; return "M" + q.x + "," + yl + "V" + (headcat ? q.y : q.y - 20 - labh(c) / 2); }
  function pDash(c, g) { var q = g(c); return "M" + q.x + "," + (q.y - 20 - labh(c) / 2) + "V" + q.y; }
  function labT(c, g) { var q = g(c); return "translate(" + q.x + "," + (q.y - 20 - labh(c) / 2) + ")"; }
  function nodeT(n, g) { var q = g(n); return "translate(" + q.x + "," + q.y + ")"; }
  function splitT(n, g) { var q = g(n); return "translate(" + q.x + "," + (q.y + hb) + ")"; }

  // ---- elements: one group per node and per split box, one path per connector, one group per label of a branch
  var els = {};
  function sync(list) {
    var internal = list.filter(function (n) { return n.hasKids; }),
        nonroot = list.filter(function (n) { return n.id !== 0; }),
        opened = list.filter(function (n) { return n.exNew || n.exOld; }),
        id = function (d) { return d.id; };

    var sN = gNodes.selectAll("g.node").data(list, id);
    sN.exit().remove();
    var eN = sN.enter().append("g").attr("class", "node")
      .each(function (d) { drawNodeContents(d3.select(this), d); })
      .on("mouseover", function (d) { showTip(d); highlight(d); })
      .on("mousemove", moveTip)
      .on("mouseout", function () { tip.style("display", "none"); highlight(null); })
      .on("click", function (d) { if (d.hasKids) toggle(d); });
    els.N = eN.merge(sN).style("cursor", function (d) { return d.hasKids ? "pointer" : "default"; });

    // split boxes (the variable, its test and the button to open and close the branch)
    var sS = gNodes.selectAll("g.split").data(internal, id);
    sS.exit().remove();
    var eS = sS.enter().append("g").attr("class", "split")
      .each(function (d) {
        var g = d3.select(this), by = 23;
        if (isclassic) {                                          // white block over the branch: the variable (and its mark) and, under it, its test
          g.append("rect").attr("class", "blk").attr("x", -d.sww / 2).attr("y", CL.sgap).attr("width", d.sww).attr("height", CL.bh).attr("fill", "#fff");
          if (d.stat) { txt(g, 0, CL.sgap + 9.5, d.svar, CL.fh).attr("class", "blk"); txt(g, 0, CL.sgap + 26.5, d.stat, CL.fz).attr("class", "blk"); }
          else txt(g, 0, CL.sgap + CL.bh / 2, d.svar, CL.fh).attr("class", "blk");
          by = CL.sgap + CL.bh / 2;
        } else {
          g.append("rect").attr("x", -d.sww / 2).attr("y", 5).attr("width", d.sww).attr("height", 36).attr("fill", "#fff");
          txt(g, 0, 15, d.svar, F.sv, true);
          if (d.stat) txt(g, 0, 32, d.stat, F.ch);
        }
        var b = g.append("g").attr("class", "tgl").attr("transform", "translate(" + (d.sww / 2 + 12) + "," + by + ")");
        b.append("circle").attr("r", 8).attr("fill", "#fff").attr("stroke", GREY35).attr("stroke-width", 1.2);
        b.append("text").attr("class", "sgn").attr("dy", ".35em").attr("font-size", 14).attr("fill", "#333");
        g.append("text").attr("class", "cnt").attr("x", 0).attr("y", 58).attr("dy", ".35em").attr("font-size", F.ch).attr("fill", "#666");
        b.on("click", function (dd) { toggle(dd); d3.event.stopPropagation(); });
        g.on("mouseover", function (dd) { showTip(dd); highlight(dd); }).on("mousemove", moveTip).on("mouseout", function () { tip.style("display", "none"); highlight(null); });
      });
    els.S = eS.merge(sS);
    els.S.select("text.sgn").text(function (d) { return d.collapsed ? "+" : "−"; });
    els.S.select("text.cnt").text(function (d) { return d.collapsed && !isclassic ? d.nleaves + " " + (d.nleaves === 1 ? L.nterm1 : L.nterm) : ""; });
    if (isclassic) {                                              // a collapsed node shows its own bar under its box (as a terminal node): the block of the variable gives way
      els.N.select("g.cbars").style("display", function (d) { return (d.leaf || d.collapsed) ? null : "none"; });   // and the button goes to the side of the box
      els.S.selectAll(".blk").style("display", function (d) { return d.collapsed ? "none" : null; });
      els.S.select("g.tgl").attr("transform", function (d) { return d.collapsed ? "translate(" + (d.w / 2 + 11) + "," + (-hb / 2) + ")" : "translate(" + (d.sww / 2 + 12) + "," + (CL.sgap + CL.bh / 2) + ")"; });
    }

    function joinPath(layer, cls, data) {
      var s = layer.selectAll("path." + cls).data(data, id);
      s.exit().remove();
      var e = s.enter().append("path").attr("class", cls).attr("fill", "none").attr("stroke", "#666").attr("stroke-width", 1);
      if (cls === "dash") e.attr("stroke-dasharray", "4,3");
      els[cls] = e.merge(s);
    }
    joinPath(gLinks, "stem", opened);
    joinPath(gLinks, "hbar", opened.filter(function (n) { return n.kids.length > 1; }));
    joinPath(gLinks, "drop", nonroot);
    joinPath(gLinks, "dash", headcat ? [] : nonroot);                            // (with the heading of category there are no labels on the branches)

    var sL = gLabs.selectAll("g.lab").data(headcat ? [] : nonroot, id);
    sL.exit().remove();
    var eL = sL.enter().append("g").attr("class", "lab")
      .each(function (d) {
        var g = d3.select(this), h = labh(d), nl = d.branch.length;
        g.append("rect").attr("x", -d.bww / 2).attr("y", -h / 2).attr("width", d.bww).attr("height", h).attr("fill", BEIGE);
        d.branch.forEach(function (s, i) { txt(g, 0, ((i + 1) - (nl + 1) / 2) * 14, s, F.bl); });
      });
    els.L = eL.merge(sL);
  }

  // ---- one frame of the animation (s from 0, previous positions, to 1, the new ones)
  function frame(s) {
    var g = function (n) { return P(n, s); };
    els.N.attr("transform", function (d) { return nodeT(d, g); }).style("opacity", function (d) { return op(d, s); });
    els.S.attr("transform", function (d) { return splitT(d, g); }).style("opacity", function (d) { return op(d, s); });
    els.stem.attr("d", function (d) { return pStem(d, g); }).style("opacity", function (d) { return opEx(d, s); });
    els.hbar.attr("d", function (d) { return pHbar(d, g); }).style("opacity", function (d) { return opEx(d, s); });
    els.drop.attr("d", function (d) { return pDrop(d, g); }).style("opacity", function (d) { return op(d, s); });
    els.dash.attr("d", function (d) { return pDash(d, g); }).style("opacity", function (d) { return op(d, s); });
    els.L.attr("transform", function (d) { return labT(d, g); }).style("opacity", function (d) { return op(d, s); });
  }

  // ---- tweens with requestAnimationFrame (the d3 of rD3plot has no d3-transition)
  var DUR = 450, running = null;
  function ease(t) { return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2; }
  function tween(fn, done) {
    var t0 = null, stopped = false, id;
    function step(ts) {
      if (stopped) return;
      if (t0 === null) t0 = ts;
      var t = Math.min(1, (ts - t0) / DUR);
      fn(ease(t));
      if (t < 1) id = requestAnimationFrame(step); else { stopped = true; if (done) done(); }
    }
    id = requestAnimationFrame(step);
    return {finish: function () { if (stopped) return; stopped = true; cancelAnimationFrame(id); fn(1); if (done) done(); }};
  }

  function update(animate, refit, stopAt) {
    if (running) running.finish();
    ND.forEach(function (n) { if (n.shown) { n.px0 = n.gx; n.py0 = n.gy; } n.exOld = n.shown && !!n.exNew; });
    layout();
    var visSet = {};
    vis.forEach(function (n) { visSet[n.id] = true; });
    ND.forEach(function (n) {
      n.st = visSet[n.id] ? (n.shown ? "stay" : "enter") : (n.shown ? "leave" : "none");
      n.exNew = !!visSet[n.id] && n.hasKids && !n.collapsed;
    });
    vis.forEach(function (n) {                                    // a new node starts from the old place of its parent (pre-order)
      if (n.st === "enter") { if (n.pa) { n.px0 = n.pa.px0; n.py0 = n.pa.py0; } else { n.px0 = n.gx; n.py0 = n.gy; } }
    });
    var leaving = ND.filter(function (n) { return n.st === "leave"; });
    leaving.forEach(function (n) {                                // a node that goes away moves to the place of its nearest visible ancestor
      var a = n.pa;
      while (a && !visSet[a.id]) a = a.pa;
      n.gx = a.gx; n.gy = a.gy;
    });
    sync(vis.concat(leaving));
    drawLegend();
    ext.h = ext.legBottom + 24;
    function settle() {                                           // end of the movement: the leaving nodes are removed
      running = null;
      ND.forEach(function (n) { n.shown = !!visSet[n.id]; n.st = n.shown ? "stay" : "none"; n.px0 = n.gx; n.py0 = n.gy; });
      ND.forEach(function (n) { n.exOld = n.exNew; });
      sync(vis);
      frame(1);
    }
    if (typeof stopAt === "number") { frame(stopAt); return; }                // (test hook)
    if (animate) { frame(0); running = tween(frame, settle); } else { frame(1); settle(); }
    if (refit) fit(animate);
  }

  function toggle(n) { n.collapsed = !n.collapsed; update(true, false); }

  // ---- highlight of the path from the root to a node
  function highlight(n) {
    var inPath = {}, k = n;
    while (k) { inPath[k.id] = true; k = k.pa; }
    function isOn(sel, f) {
      sel.attr("stroke", function (d) { return n && f(d) ? "#1f6feb" : "#666"; }).attr("stroke-width", function (d) { return n && f(d) ? 2.4 : 1; });
    }
    isOn(gLinks.selectAll("path.drop"), function (c) { return inPath[c.id]; });
    isOn(gLinks.selectAll("path.dash"), function (c) { return inPath[c.id]; });
    isOn(gLinks.selectAll("path.stem"), function (u) { return inPath[u.id] && u !== n; });
    isOn(gLinks.selectAll("path.hbar"), function (u) { return inPath[u.id] && u !== n; });
    gNodes.selectAll("g.node > rect:first-child").attr("stroke", function (d) { return n && inPath[d.id] ? "#1f6feb" : BOXC; })
      .attr("stroke-width", function (d) { return n && inPath[d.id] ? 2.6 : BOXW; });
  }

  // ---- tooltip
  function showTip(d) {
    tip.html(d.tip + (isclassic && d.collapsed ? "<br><i>" + d.nleaves + " " + (d.nleaves === 1 ? L.nterm1 : L.nterm) + "</i>" : "")).style("display", "block");     // classic: the count that the collapsed node no longer writes
    moveTip();
  }
  function moveTip() {
    var e = d3.event || {clientX: 420, clientY: 260}, w = tip.node().offsetWidth, h = tip.node().offsetHeight;
    var x = e.clientX + 16, y = e.clientY + 16;
    if (x + w > window.innerWidth - 8) x = e.clientX - w - 16;
    if (y + h > window.innerHeight - 8) y = e.clientY - h - 16;
    tip.style("left", Math.max(4, x) + "px").style("top", Math.max(4, y) + "px");
  }

  // ---- legend and scale (they are part of the drawing, so they go to the exported files too)
  var legItems = [];
  function buildLegend() {
    legItems = [];
    function add(w, draw, cls) { legItems.push({w: w, draw: draw}); }
    var sq = 16, gp = 10;
    var C = O.colors, boxtxt = "Q1-Q3, " + T.median + ", " + O.whiskertxt;
    if (!ismaid && !isbox) {
      O.levels.forEach(function (lv, j) {
        var w = tw(lv.name, F.lg);
        add(sq + gp + w, function (g, x, y) {
          var it = g.append("g").attr("class", "legitem").style("cursor", "default");
          it.append("rect").attr("x", x).attr("y", y - sq / 2).attr("width", sq).attr("height", sq).attr("fill", lv.color).attr("stroke", "#fff").attr("stroke-width", 0.5);
          txt(it, x + sq + gp + w / 2, y, lv.name, F.lg);
          it.on("mouseover", function () { gNodes.selectAll(".seg").attr("opacity", 0.18); gNodes.selectAll(".seg.s" + j).attr("opacity", 1); })
            .on("mouseout", function () { gNodes.selectAll(".seg").attr("opacity", 1); });
        });
      });
      if (isclassic && O.dvordered && O.quartiles) addQuartLegend();
    } else if (isclassic) {                                       // maid: the overall mean (dashed line) and, if asked for, the median and the quartiles
      add(30 + 7 + tw(SC.reftxt, F.lg), function (g, x, y) {
        line(g, x, y, x + 30, y, "#4D4D4D", 1, "5,4");
        txt(g, x + 37 + tw(SC.reftxt, F.lg) / 2, y, SC.reftxt, F.lg);
      });
      if (O.quartiles) addQuartLegend();
    } else {
      if (!isbar) add(50 + 14 + tw(boxtxt, F.lg), function (g, x, y) {
        line(g, x, y, x + 50, y, GREY35, 1); line(g, x, y - 6, x, y + 6, GREY35, 1); line(g, x + 50, y - 6, x + 50, y + 6, GREY35, 1);
        g.append("rect").attr("x", x + 15).attr("y", y - 12).attr("width", 20).attr("height", 24).attr("fill", "#D9D9D9").attr("stroke", GREY35).attr("stroke-width", 0.8);
        line(g, x + 25, y - 12, x + 25, y + 12, "#000", 2.4);
        txt(g, x + 64 + tw(boxtxt, F.lg) / 2, y, boxtxt, F.lg);
      });
      if (isdots) add(36 + 10 + tw(O.dotstxt, F.lg), function (g, x, y) {
        [[4, 3], [13, -5], [22, 4], [31, -3]].forEach(function (d) { g.append("circle").attr("cx", x + d[0]).attr("cy", y + d[1]).attr("r", 2.6).attr("fill", "#404040").attr("fill-opacity", 0.55); });
        txt(g, x + 46 + tw(O.dotstxt, F.lg) / 2, y, O.dotstxt, F.lg);
      });
      add(12 + 10 + tw(SC.reftxt, F.lg), function (g, x, y) {
        line(g, x + 6, y - 11, x + 6, y + 11, REFC, 1.6);
        txt(g, x + 22 + tw(SC.reftxt, F.lg) / 2, y, SC.reftxt, F.lg);
      });
      if (SC.showref2) add(20 + 10 + tw(SC.reftxt2, F.lg), function (g, x, y) {
        line(g, x + 4, y - 11, x + 4, y + 11, C.above5, 1.3); line(g, x + 14, y - 11, x + 14, y + 11, C.below5, 1.3);
        txt(g, x + 30 + tw(SC.reftxt2, F.lg) / 2, y, SC.reftxt2, F.lg);
      });
      [[T.above, C.above5], [T.below, C.below5]].forEach(function (a) {
        add(sq + gp + tw(a[0], F.lg), function (g, x, y) {
          g.append("rect").attr("x", x).attr("y", y - sq / 2).attr("width", sq).attr("height", sq).attr("fill", a[1]).attr("stroke", "#fff").attr("stroke-width", 0.5);
          txt(g, x + sq + gp + tw(a[0], F.lg) / 2, y, a[0], F.lg);
        });
      });
    }
    if (!isclassic) addLeaf();
  }
  function addQuartLegend() {                                    // median (solid green) and, with five or more categories or in maid, Q1 and Q3 (dashed)
    legItems.push({w: 30 + 7 + tw(T.median, F.lg), draw: function (g, x, y) {
      line(g, x, y, x + 30, y, MED, 2.2);
      txt(g, x + 37 + tw(T.median, F.lg) / 2, y, T.median, F.lg);
    }});
    if (O.nquart === 3) legItems.push({w: 30 + 7 + tw("Q1, Q3", F.lg), draw: function (g, x, y) {
      line(g, x, y, x + 30, y, MED, 1.8, "5,4");
      txt(g, x + 37 + tw("Q1, Q3", F.lg) / 2, y, "Q1, Q3", F.lg);
    }});
  }
  function addLeaf() {                                           // terminal node: the dark square of its number
    if (!T.leaf) return;
    legItems.push({w: 16 + 10 + tw(T.leaf, F.lg), draw: function (g, x, y) {
      g.append("rect").attr("x", x).attr("y", y - 7.5).attr("width", 16).attr("height", 15).attr("fill", G).attr("stroke", G).attr("stroke-width", 1.3);
      txt(g, x + 26 + tw(T.leaf, F.lg) / 2, y, T.leaf, F.lg);
    }});
  }
  var legGap = 20, rowH = 26;
  function legendRows(maxw) {
    var rows = [], cur = [], cw = 0;
    legItems.forEach(function (it) {
      if (cur.length && cw + legGap + it.w > maxw) { rows.push(cur); cur = []; cw = 0; }
      cw += (cur.length ? legGap : 0) + it.w;
      cur.push(it);
    });
    rows.push(cur);
    return rows;
  }
  function rowW(r) { return r.reduce(function (s, it) { return s + it.w; }, 0) + legGap * (r.length - 1); }
  // rows of the legend: no wider than maxw, 3 at most (the width grows if need be) and balanced, as in the static graph:
  // the narrowest width that keeps the same number of rows
  function legendLayout(maxw) {
    var rows = legendRows(maxw);
    while (rows.length > 3 && maxw < 4000) { maxw *= 1.1; rows = legendRows(maxw); }
    var n = rows.length, widest = Math.max.apply(null, legItems.map(function (it) { return it.w; }));
    while (n > 1 && maxw - 5 > widest && legendRows(maxw - 5).length === n) maxw -= 5;
    return legendRows(maxw);
  }
  function legendWidth(maxw) {
    var rows = legendLayout(maxw);
    var w = Math.max.apply(null, rows.map(rowW));
    return Math.max(w, tw(legTitle(), F.lt));
  }
  function legTitle() { return isclassic ? "" : (!ismaid && !isbox) ? O.legend : O.depvar; }       // (the classic graph has no title over the legend)
  function drawLegend() {
    gLeg.selectAll("*").remove();
    var rows = legendLayout(Math.max(ext.treeW, 760));
    var y = ext.treeBottom + 20;
    if (isclassic && ismaid && ext.ybase) line(gLeg, ext.lx1, ext.ybase, ext.lx2, ext.ybase, "#4D4D4D", 1, "5,4");      // maid: the overall mean across the bars
    if (legTitle()) {
      txt(gLeg, ext.cx, y, legTitle(), F.lt, false);
      y += 28;
    }
    var lastY = y, lastL = ext.cx;
    rows.forEach(function (r) {
      var x = ext.cx - rowW(r) / 2;
      lastY = y; lastL = x;
      r.forEach(function (it) { it.draw(gLeg, x, y); x += it.w + legGap; });
      y += rowH;
    });
    if (isclassic) {                                              // foot of the classic graph: risk estimate and Cramer's V, and the note of the bars
      y += 2;
      [O.foot.left, O.foot.note].forEach(function (s) {
        if (s) { txt(gLeg, ext.cx, y, s, CL.foot, false, "#333"); y += 17; }
      });
    }
    if (plotbox) {                                                // scale of the box plots
      var ya = y + 14, xg = ext.cx - bw / 2;
      line(gLeg, xg, ya, xg + bw, ya, GREY35, 1);
      if (ismaid) {
        var xt = SC.ticks.map(function (tk) { return xg + (tk.v - SC.vmin) * bw / (SC.vmax - SC.vmin); });
        var hw = SC.ticks.map(function (tk) { return tw(tk.t, F.ch) / 2; });
        SC.ticks.forEach(function (tk, j) {
          line(gLeg, xt[j], ya - 5, xt[j], ya + 5, GREY35, 1);
          // the label of the middle tick is written unless it would touch those of the ends (measured widths)
          var fits = j !== 1 || (xt[1] - hw[1] - 8 > xt[0] + hw[0] && xt[1] + hw[1] + 8 < xt[2] - hw[2]);
          if (fits) txt(gLeg, xt[j], ya + 17, tk.t, F.ch);
        });
        txt(gLeg, ext.cx, ya + 36, T.scalecap, F.ch);
        y = ya + 44;
      } else {
        var nl = SC.cats.length;
        for (var j = 0; j <= nl; j++) line(gLeg, xg + j * bw / nl, ya - 5, xg + j * bw / nl, ya + 5, GREY35, 1);
        txt(gLeg, xg + 0.5 * bw / nl, ya + 17, SC.cats[0], F.ch);
        txt(gLeg, xg + (nl - 0.5) * bw / nl, ya + 17, SC.cats[nl - 1], F.ch);
        y = ya + 26;
      }
    }
    if (O.note) {                                                 // note (source of the data...): at the bottom left, on the line of the last row of the legend if there is room
      var mx = 24, FN = 13, lh = 17;
      var room = Math.min(lastL, plotbox ? ext.cx - bw / 2 : lastL) - mx - 30;
      var side = room >= 220, maxn = side ? room : ext.w - 2 * mx, lines = [];
      String(O.note).split(/\r?\n/).forEach(function (par) {
        var cur = "";
        par.split(/\s+/).forEach(function (w) {
          if (!w) return;
          if (cur && tw(cur + " " + w, FN) > maxn) { lines.push(cur); cur = w; } else cur = cur ? cur + " " + w : w;
        });
        lines.push(cur);
      });
      var yn = side ? lastY : y + 22;
      lines.forEach(function (ln, i) { txt(gLeg, mx, yn + i * lh, ln, FN, false, "#222").attr("text-anchor", "start"); });
      y = Math.max(y, yn + lines.length * lh);
    }
    ext.legBottom = y;
  }

  // ---- fit to the window
  function fit(animate) {
    var W = window.innerWidth, H = window.innerHeight, top = O.main ? 44 : 44;
    var k = Math.min((W - 24) / ext.w, (H - top - 12) / ext.h, 1.5);
    var tr = d3.zoomIdentity.translate((W - ext.w * k) / 2, top + (H - top - ext.h * k) / 2).scale(k);
    if (!animate) { svg.call(zoom.transform, tr); return; }
    var a = curT;
    tween(function (s) { svg.call(zoom.transform, d3.zoomIdentity.translate(a.x + (tr.x - a.x) * s, a.y + (tr.y - a.y) * s).scale(a.k + (tr.k - a.k) * s)); });
  }

  // ---- export
  function svgString() {
    var c = svg.node().cloneNode(true);
    var v = c.querySelector("#viewport"), top = O.main ? 44 : 0;
    v.setAttribute("transform", "translate(0," + top + ")");
    c.setAttribute("xmlns", "http://www.w3.org/2000/svg");
    c.setAttribute("viewBox", "0 0 " + ext.w + " " + (ext.h + top));
    c.setAttribute("width", ext.w);
    c.setAttribute("height", ext.h + top);
    c.removeAttribute("style");
    c.removeAttribute("id");
    var bg = document.createElementNS("http://www.w3.org/2000/svg", "rect");
    bg.setAttribute("x", 0); bg.setAttribute("y", 0); bg.setAttribute("width", ext.w); bg.setAttribute("height", ext.h + top); bg.setAttribute("fill", "#fff");
    c.insertBefore(bg, c.firstChild);
    if (O.main) {
      var tt = document.createElementNS("http://www.w3.org/2000/svg", "text");
      tt.setAttribute("x", ext.w / 2); tt.setAttribute("y", 28); tt.setAttribute("font-size", 22); tt.textContent = O.main;
      c.appendChild(tt);
    }
    return new XMLSerializer().serializeToString(c);
  }
  function fileName(ext_) { return (O.kind + "_tree_" + O.depvar).replace(/[^\w\-]+/g, "_") + "." + ext_; }
  function download(blob, name) {
    var u = URL.createObjectURL(blob), a = document.createElement("a");
    a.style.display = "none"; a.href = u; a.download = name; document.body.appendChild(a); a.click();
    setTimeout(function () { document.body.removeChild(a); URL.revokeObjectURL(u); }, 100);
  }
  function exportSVG() { download(new Blob([svgString()], {type: "image/svg+xml;charset=utf-8"}), fileName("svg")); }
  function exportPNG() {
    var s = svgString(), img = new Image(), k = 2;
    img.onload = function () {
      var cv = document.createElement("canvas");
      cv.width = ext.w * k; cv.height = (ext.h + (O.main ? 44 : 0)) * k;
      var c2 = cv.getContext("2d");
      c2.fillStyle = "#fff"; c2.fillRect(0, 0, cv.width, cv.height);
      c2.drawImage(img, 0, 0, cv.width, cv.height);
      cv.toBlob(function (b) { download(b, fileName("png")); }, "image/png");
    };
    img.src = "data:image/svg+xml;charset=utf-8," + encodeURIComponent(s);
  }

  // ---- start (after the fonts, so that the widths are measured with the real font)
  function start() {
    try { start0(); } catch (e) { window.dispatchEvent(new ErrorEvent("error", {message: e.message + " | " + (e.stack || "").split("\n").slice(0, 3).join(" < ")})); }
  }
  function start0() {
    metrics();
    buildLegend();
    update(false, true);
    window.addEventListener("resize", function () { fit(false); });
    // hooks for testing from the address (#collapse=1, #toggle=3)
    var h = location.hash.replace("#", "");
    h.split("&").forEach(function (kv) {
      var a = kv.split("=");
      if (a[0] === "collapse") { ND.forEach(function (n) { n.collapsed = n.hasKids && n.depth >= +a[1]; }); update(false, true); }
      if (a[0] === "click") {                                   // a real click event on the button of the branch (test hook)
        var tg = gNodes.selectAll("g.split").filter(function (d) { return d.id === +a[1]; }).select("g.tgl").node();
        tg.dispatchEvent(new MouseEvent("click", {bubbles: true}));
      }
      if (a[0] === "seq") { a[1].split(",").forEach(function (id) { toggle(byId[+id]); if (running) running.finish(); }); }   // toggles, each one finished at once (test hook)
      if (a[0] === "zoom") { svg.call(zoom.scaleBy, +a[1]); }
      if (a[0] === "half") { byId[+a[1]].collapsed = !byId[+a[1]].collapsed; update(true, false, 0.5); }
      if (a[0] === "tip") { showTip(byId[+a[1]]); highlight(byId[+a[1]]); }
      if (a[0] === "svgimg") { var im = new Image(); im.onload = function () { document.body.innerHTML = ""; document.body.appendChild(im); im.style.cssText = "position:absolute;left:0;top:0;max-width:100%"; }; im.src = "data:image/svg+xml;charset=utf-8," + encodeURIComponent(svgString()); }
      if (a[0] === "toggle") { a[1].split(",").forEach(function (id) { byId[+id].collapsed = !byId[+id].collapsed; }); update(false, true); }
    });
  }
  window.rD3tree = {nodes: ND, update: update, fit: fit, toggle: toggle};
  if (document.fonts && document.fonts.load) {
    Promise.all([document.fonts.load("12px Roboto"), document.fonts.load("bold 12px Roboto")]).then(start, start);
  } else start();
})();
