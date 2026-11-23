*! tvpcgraph 1.0.0  21nov2026
*! Graphs of time-lagged causal structures after tvpc / tvpcmci
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*
*   grid      time-lag grid: variables x time slices t-m..t (Fig. 13 style)
*   map(var)  causal relationship map of one variable (Figs. 3-11 style)
*   heatmap   lag-link heat map, cause x effect, cells = lags
*   degree    in-/out-links by variable
*   network   radial causal network of all nodes (Fig. 2 style)

program define tvpcgraph
    version 15.0
    syntax [, GRID MAP(string) HEATmap DEGree NETwork ALL  ///
        NAME(string) SAVing(string) TItle(string asis) NODRAW ///
        SCHeme(string) noLABels ]
    if !inlist("`e(cmd)'", "tvpc", "tvpcmci") {
        di as err "tvpcgraph requires results from {bf:tvpc} or {bf:tvpcmci}"
        exit 301
    }
    if ("`all'" != "") {
        local grid grid
        local heatmap heatmap
        local degree degree
        local network network
    }
    if ("`grid'`map'`heatmap'`degree'`network'" == "") local grid grid
    if ("`name'" == "") local name "tvpc"
    local draw = cond("`nodraw'" != "", "nodraw", "")
    if ("`scheme'" != "") local sch "scheme(`scheme')"
    tempname L
    matrix `L' = e(links)
    if (`L'[1,1] >= .) {
        di as txt "(no causal links in the estimated graph; nothing to draw)"
        exit
    }
    if ("`grid'" != "")    _tvpcg_grid,    name(`name'_grid) `draw' `sch' title(`title') saving(`saving')
    if ("`heatmap'" != "") _tvpcg_heat,    name(`name'_heat) `draw' `sch' title(`title') saving(`saving')
    if ("`degree'" != "")  _tvpcg_degree,  name(`name'_degree) `draw' `sch' title(`title') saving(`saving')
    if ("`network'" != "") _tvpcg_network, name(`name'_network) `draw' `sch' title(`title') saving(`saving') `labels'
    if ("`map'" != "") {
        local vl "`e(varlist)'"
        if ("`map'" == "_all") local map "`vl'"
        foreach v of local map {
            local pos : list posof "`v'" in vl
            if (`pos' == 0) {
                di as err "map(): `v' is not one of the tvpc variables (`vl')"
                exit 198
            }
            _tvpcg_map, target(`pos') name(`name'_map_`v') `draw' `sch' title(`title') saving(`saving')
        }
    }
end

* ----------------------------------------------------------------------
* helper: append saving() suffix
* ----------------------------------------------------------------------
program define _tvpcg_save
    args saving name
    if ("`saving'" != "") {
        gettoken fn rest : saving, parse(",")
        local fn = trim("`fn'")
        local fn = subinstr("`fn'", ".gph", "", .)
        qui graph save `name' "`fn'_`name'.gph", replace
    }
end

* ----------------------------------------------------------------------
* time-lag grid (Fig. 13 style)
* ----------------------------------------------------------------------
program define _tvpcg_grid
    syntax , name(string) [nodraw scheme(string) title(string asis) saving(string)]
    local nv = e(n_vars)
    local m  = e(lags)
    local s  = e(lagstep)
    local vl "`e(varlist)'"
    tempname L N E A H
    matrix `L' = e(links)
    mata: _tvpcg_grid_m("`L'", `nv', `m', "`N'", "`E'", "`A'", "`H'")
    preserve
    qui {
        clear
        local rows = max(rowsof(`N'), rowsof(`E'), rowsof(`A'), rowsof(`H'))
        set obs `rows'
        svmat double `N', name(nd)
        svmat double `E', name(ed)
        svmat double `A', name(ar)
        svmat double `H', name(hd)
    }
    * nd: x y type(1 current, 2 lag active, 3 lag idle)
    * ed: y1 x1 y2 x2 type(1 lagged)   ar: x y type   hd: y1 x1 y2 x2 type
    local ylab ""
    forvalues i = 1/`nv' {
        local v : word `i' of `vl'
        local ylab `ylab' `=`nv' - `i' + 1' "`v'"
    }
    local xlab ""
    forvalues k = 0/`m' {
        if (`k' == 0) local xlab `xlab' 0 "t"
        else          local xlab `xlab' -`k' "t-`k'"
    }
    if (`"`title'"' == "") local title "Time-lagged causal structure (`e(cmd)')"
    local stepnote = cond(`s' > 1, "One lag step = `s' periods. ", "")
    local leg ""
    qui count if ed5 == 1
    if (r(N)) local leg `leg' 1 "lagged link X(t-k) {&rarr} Y(t)"
    qui count if ar3 == 2
    if (r(N)) local leg `leg' 2 "contemporaneous directed"
    qui count if ar3 == 3
    if (r(N)) local leg `leg' 3 "contemporaneous undirected"
    twoway ///
        (pcarrow ed1 ed2 ed3 ed4 if ed5 == 1, lcolor("214 96 77%75") mcolor("214 96 77%75") lwidth(medthick) msize(medium) barbsize(medium)) ///
        (line ar2 ar1 if ar3 == 2, cmissing(n) lcolor("33 102 172%80") lwidth(medthick)) ///
        (line ar2 ar1 if ar3 == 3, cmissing(n) lcolor("33 102 172%80") lwidth(medthick) lpattern(dash)) ///
        (pcarrow hd1 hd2 hd3 hd4 if hd5 == 2, lcolor("33 102 172%80") mcolor("33 102 172%80") lwidth(medthick) msize(medium) barbsize(medium)) ///
        (scatter nd2 nd1 if nd3 == 3, msymbol(O) msize(large) mcolor(gs14) mlcolor(gs11)) ///
        (scatter nd2 nd1 if nd3 == 2, msymbol(O) msize(large) mcolor("253 219 199") mlcolor("214 96 77")) ///
        (scatter nd2 nd1 if nd3 == 1, msymbol(O) msize(large) mcolor("33 102 172") mlcolor("5 48 97")) ///
        , xlabel(`xlab', labsize(small) noticks) ylabel(`ylab', angle(0) labsize(small) noticks nogrid) ///
        xscale(range(-`m'.5 1.4) noline) yscale(range(0.4 `nv'.6) noline) ///
        xtitle("") ytitle("") legend(order(`leg') rows(1) size(small) position(6) region(lcolor(white))) ///
        title(`title', size(medium) color(black)) ///
        note("`stepnote'Nodes: blue = current time t; orange = lagged node with an outgoing link.", size(vsmall)) ///
        graphregion(color(white)) plotregion(color(white) lcolor(white)) ///
        name(`name', replace) `nodraw' `scheme'
    _tvpcg_save "`saving'" `name'
    restore
end

* ----------------------------------------------------------------------
* lag-link heat map
* ----------------------------------------------------------------------
program define _tvpcg_heat
    syntax , name(string) [nodraw scheme(string) title(string asis) saving(string)]
    local nv = e(n_vars)
    local m  = e(lags)
    local vl "`e(varlist)'"
    tempname L C
    matrix `L' = e(links)
    mata: _tvpcg_heat_m("`L'", `nv', "`C'")
    preserve
    qui {
        clear
        svmat double `C', name(c)
        * c1 cause  c2 effect  c3 count  c4 label id
        gen y = `nv' - c1 + 1
        gen x = c2
        gen str20 lab = ""
    }
    mata: _tvpcg_heat_lab("`L'")
    local xl ""
    local yl ""
    forvalues i = 1/`nv' {
        local v : word `i' of `vl'
        local xl `xl' `i' "`v'"
        local yl `yl' `=`nv' - `i' + 1' "`v'"
    }
    local ms = max(2.5, min(9, 75 / `nv'))
    local cols `""247 251 255" "198 219 239" "158 202 225" "107 174 214" "49 130 189" "8 81 156" "8 48 107""'
    local plots ""
    local leg ""
    local q 0
    forvalues k = 0/6 {
        local col : word `=`k' + 1' of `cols'
        if (`k' < 6) local cond "c3 == `k'"
        else         local cond "c3 >= 6"
        qui count if `cond'
        if (r(N) == 0) continue
        local ++q
        local plots `plots' (scatter y x if `cond', msymbol(S) msize(`ms') mcolor("`col'") mlcolor(gs13) mlwidth(vthin))
        if (`k' > 0) local leg `leg' `q' "`k' lag(s)"
    }
    local lsz = cond(`nv' <= 8, "small", cond(`nv' <= 12, "vsmall", "tiny"))
    if (`"`title'"' == "") local title "Lag-link map: cause(t-k) {&rarr} effect(t)"
    twoway `plots' ///
        (scatter y x if c3 > 0 & c3 < 4, msymbol(none) mlabel(lab) mlabpos(0) mlabsize(`lsz') mlabcolor(black)) ///
        (scatter y x if c3 >= 4, msymbol(none) mlabel(lab) mlabpos(0) mlabsize(`lsz') mlabcolor(white)) ///
        , xlabel(`xl', angle(45) labsize(small) noticks nogrid) ylabel(`yl', angle(0) labsize(small) noticks nogrid) ///
        xscale(range(0.5 `nv'.5) alt) yscale(range(0.5 `nv'.5)) aspectratio(1) ///
        xtitle("Effect variable at t", size(small)) ytitle("Cause variable (lagged)", size(small)) ///
        legend(order(`leg') rows(1) size(vsmall) region(lcolor(white))) ///
        title(`title', size(medium) color(black)) ///
        note("Cell text: lags k (0 = contemporaneous directed, u = undirected).", size(vsmall)) ///
        graphregion(color(white)) plotregion(color(white)) ///
        name(`name', replace) `nodraw' `scheme'
    _tvpcg_save "`saving'" `name'
    restore
end

* ----------------------------------------------------------------------
* degree bars
* ----------------------------------------------------------------------
program define _tvpcg_degree
    syntax , name(string) [nodraw scheme(string) title(string asis) saving(string)]
    local vl "`e(varlist)'"
    tempname D
    matrix `D' = e(degree)
    preserve
    qui {
        clear
        svmat double `D', name(d)
        gen str32 var = ""
        local i 0
        foreach v of local vl {
            local ++i
            replace var = "`v'" in `i'
        }
        rename d1 inlinks
        rename d2 outlinks
    }
    if (`"`title'"' == "") local title "Causal in-links and out-links by variable"
    graph hbar (asis) inlinks outlinks, over(var, sort(inlinks) descending label(labsize(small))) ///
        bar(1, color("33 102 172")) bar(2, color("214 96 77")) ///
        legend(order(1 "In-links (drivers of X(t))" 2 "Out-links (X drives others)") rows(1) size(small) region(lcolor(white))) ///
        blabel(bar, size(vsmall) format(%3.0f)) ytitle("Number of causal links", size(small)) ///
        title(`title', size(medium) color(black)) ///
        graphregion(color(white)) plotregion(color(white)) ///
        name(`name', replace) `nodraw' `scheme'
    _tvpcg_save "`saving'" `name'
    restore
end

* ----------------------------------------------------------------------
* radial network (Fig. 2 style)
* ----------------------------------------------------------------------
program define _tvpcg_network
    syntax , name(string) [nodraw scheme(string) title(string asis) saving(string) nolabels]
    local nv = e(n_vars)
    local m  = e(lags)
    local vl "`e(varlist)'"
    tempname L N E
    matrix `L' = e(links)
    mata: _tvpcg_net_m("`L'", `nv', `m', "`N'", "`E'")
    preserve
    qui {
        clear
        local rows = max(rowsof(`N'), rowsof(`E'))
        set obs `rows'
        svmat double `N', name(nd)
        svmat double `E', name(ed)
        * nd: x y var lag ; ed: y1 x1 y2 x2 type
        gen str40 nlab = ""
        gen pos = 0
    }
    local i 0
    foreach v of local vl {
        local ++i
        qui replace nlab = "`v'" if nd3 == `i' & nd4 == 0
        qui replace nlab = "`v'(t-" + string(nd4) + ")" if nd3 == `i' & nd4 > 0
    }
    * label position by angle
    qui {
        gen ang = atan2(nd2, nd1) * 180 / _pi
        replace pos = 3 if ang > -60 & ang <= 60
        replace pos = 12 if ang > 60 & ang <= 120
        replace pos = 9 if ang > 120 | ang <= -120
        replace pos = 6 if ang > -120 & ang <= -60
    }
    local pal `""33 102 172" "214 96 77" "27 158 119" "117 112 179" "231 41 138" "102 166 30" "230 171 2" "166 118 29" "31 120 180" "227 26 28" "106 61 154" "51 160 44""'
    local cur ""
    forvalues i = 1/`nv' {
        local col : word `=mod(`i' - 1, 12) + 1' of `pal'
        local cur `cur' (scatter nd2 nd1 if nd3 == `i' & nd4 == 0, msymbol(O) msize(vlarge) mcolor("`col'") mlcolor(black) mlwidth(thin))
    }
    local lsz = cond(`nv' <= 8, "small", "vsmall")
    local labplots ""
    if ("`labels'" == "") {
        local labplots (scatter nd2 nd1 if nd4 == 0, msymbol(none) mlabel(nlab) mlabvposition(pos) mlabsize(`lsz') mlabcolor(black) mlabgap(2)) ///
            (scatter nd2 nd1 if nd4 > 0, msymbol(none) mlabel(nlab) mlabvposition(pos) mlabsize(tiny) mlabcolor(gs6))
    }
    if (`"`title'"' == "") local title "Causal network of time-lagged nodes (`e(cmd)')"
    twoway ///
        (pcarrow ed1 ed2 ed3 ed4 if ed5 == 1, lcolor(gs9%60) mcolor(gs9%60) lwidth(thin) msize(small) barbsize(small)) ///
        (pcarrow ed1 ed2 ed3 ed4 if ed5 == 2, lcolor("33 102 172%85") mcolor("33 102 172%85") lwidth(medium) msize(small) barbsize(small)) ///
        (pcspike ed1 ed2 ed3 ed4 if ed5 == 3, lcolor("33 102 172%85") lwidth(medium) lpattern(dash)) ///
        (scatter nd2 nd1 if nd4 > 0, msymbol(O) msize(medium) mcolor(gs14) mlcolor(gs9) mlwidth(thin)) ///
        `cur' `labplots' ///
        , xscale(off range(-`=2.1 + 0.55 * `m'' `=2.1 + 0.55 * `m'')) yscale(off range(-`=2.1 + 0.55 * `m'' `=2.1 + 0.55 * `m'')) ///
        xlabel(none) ylabel(none, nogrid) aspectratio(1) legend(off) xsize(7) ysize(7.4) ///
        title(`title', size(medium) color(black)) ///
        note("Coloured nodes: variables at time t (inner ring); grey nodes: lagged values (outer rings, t-1 innermost)." ///
             "Grey arrows: lagged links; blue: contemporaneous (dashed = undirected).", size(vsmall)) ///
        graphregion(color(white)) plotregion(color(white)) ///
        name(`name', replace) `nodraw' `scheme'
    _tvpcg_save "`saving'" `name'
    restore
end

* ----------------------------------------------------------------------
* causal relationship map of one variable (Figs. 3-11 style)
* ----------------------------------------------------------------------
program define _tvpcg_map
    syntax , target(integer) name(string) [nodraw scheme(string) title(string asis) saving(string)]
    local nv = e(n_vars)
    local vl "`e(varlist)'"
    tempname L B E
    matrix `L' = e(links)
    mata: _tvpcg_map_m("`L'", `nv', `target', "`B'", "`E'", "`vl'")
    local tv : word `target' of `vl'
    local nb = rowsof(`B')
    preserve
    qui {
        clear
        local rows = max(rowsof(`B'), rowsof(`E'))
        set obs `rows'
        svmat double `B', name(b)
        svmat double `E', name(e)
        * b: x y kind(1 target, 2 own lag, 3 other) ; e: y1 x1 y2 x2 type
        gen str60 lab = ""
        gen ylo = b2 - 0.17
        gen yhi = b2 + 0.17
    }
    forvalues r = 1/`nb' {
        qui replace lab = "${TVPCG_LAB`r'}" in `r'
        macro drop TVPCG_LAB`r'
    }
    qui summarize b1
    local xmax = max(r(max), 3)
    local bw = 0.86
    local lsz = cond(`xmax' <= 4, "small", cond(`xmax' <= 6, "vsmall", "tiny"))
    if (`"`title'"' == "") local title "Causal relationship map for `tv'"
    twoway ///
        (rbar ylo yhi b1 if b3 == 3, barwidth(`bw') fcolor(white) lcolor(black) lwidth(thin)) ///
        (rbar ylo yhi b1 if b3 == 2, barwidth(`bw') fcolor("255 236 179") lcolor("230 171 2") lwidth(thin)) ///
        (rbar ylo yhi b1 if b3 == 1, barwidth(`bw') fcolor("198 219 239") lcolor("33 102 172") lwidth(thin)) ///
        (pcarrow e1 e2 e3 e4 if e5 == 1, lcolor(black) mcolor(black) lwidth(thin) msize(small) barbsize(small)) ///
        (pcspike e1 e2 e3 e4 if e5 == 3, lcolor(black) lwidth(thin) lpattern(dash)) ///
        (scatter b2 b1, msymbol(none) mlabel(lab) mlabpos(0) mlabsize(`lsz') mlabcolor(black)) ///
        , xscale(off range(0.3 `=`xmax' + 0.7')) yscale(off range(0.6 3.4)) ///
        xlabel(none) ylabel(none, nogrid) legend(off) ///
        title(`title', size(medium) color(black)) ///
        note("Top: drivers of `tv'(t) (yellow = own lags). Middle: `tv'(t) (blue) and its lags that drive other" ///
             "variables. Bottom: variables at t driven by `tv'. Dashed = undirected contemporaneous link.", size(vsmall)) ///
        graphregion(color(white)) plotregion(color(white)) ///
        name(`name', replace) `nodraw' `scheme'
    _tvpcg_save "`saving'" `name'
    restore
end

mata:

// bezier arc between two current nodes, column x = 0
void _tvpcg_arc(real scalar y1, real scalar y2, real scalar ty,
                real matrix A, real matrix H)
{
    real scalar t, bx, by, cx, cy, n
    real matrix P
    cx = 0.35 + 0.12 * abs(y1 - y2)
    cy = (y1 + y2) / 2
    P = J(0, 2, .)
    for (n = 0; n <= 20; n++) {
        t = n / 20
        bx = 2 * (1 - t) * t * cx
        by = (1 - t) * (1 - t) * y1 + 2 * (1 - t) * t * cy + t * t * y2
        P = P \ (bx, by)
    }
    // trim the end so the arrow head stays outside the target node
    P = P[1::18, .]
    A = A \ (P, J(rows(P), 1, ty)) \ (., ., ty)
    if (ty == 2) {
        H = H \ (P[17, 2], P[17, 1], P[18, 2], P[18, 1], 2)
    }
}

void _tvpcg_grid_m(string scalar lname, real scalar nv, real scalar m,
                   string scalar nn, string scalar en, string scalar an,
                   string scalar hn)
{
    real matrix L, N, E, A, H, act
    real scalar i, k, q, c, j, lg, x1, y1, x2, y2, dx, dy, len, sh
    L = st_matrix(lname)
    act = J(nv, m + 1, 0)
    for (q = 1; q <= rows(L); q++) {
        act[L[q, 2], L[q, 3] + 1] = 1
    }
    N = J(0, 3, .)
    for (i = 1; i <= nv; i++) {
        for (k = 0; k <= m; k++) {
            if (k == 0) {
                N = N \ (0, nv - i + 1, 1)
            }
            else if (act[i, k + 1]) {
                N = N \ (-k, nv - i + 1, 2)
            }
            else {
                N = N \ (-k, nv - i + 1, 3)
            }
        }
    }
    E = J(0, 5, .)
    A = J(0, 3, .)
    H = J(0, 5, .)
    for (q = 1; q <= rows(L); q++) {
        j = L[q, 1]
        c = L[q, 2]
        lg = L[q, 3]
        y1 = nv - c + 1
        y2 = nv - j + 1
        if (L[q, 5] == 1) {
            x1 = -lg
            x2 = 0
            dx = x2 - x1
            dy = y2 - y1
            len = sqrt(dx * dx + dy * dy)
            sh = 0.16 / len
            E = E \ (y1, x1, y2 - sh * dy, x2 - sh * dx, 1)
        }
        else {
            _tvpcg_arc(y1, y2, L[q, 5], A, H)
        }
    }
    if (rows(E) == 0) {
        E = J(1, 5, .)
    }
    if (rows(A) == 0) {
        A = J(1, 3, .)
    }
    if (rows(H) == 0) {
        H = J(1, 5, .)
    }
    st_matrix(nn, N)
    st_matrix(en, E)
    st_matrix(an, A)
    st_matrix(hn, H)
}

void _tvpcg_heat_m(string scalar lname, real scalar nv, string scalar cn)
{
    real matrix L, C
    real scalar q, c, j, r
    L = st_matrix(lname)
    C = J(nv * nv, 3, 0)
    r = 0
    for (c = 1; c <= nv; c++) {
        for (j = 1; j <= nv; j++) {
            r = r + 1
            C[r, 1] = c
            C[r, 2] = j
        }
    }
    for (q = 1; q <= rows(L); q++) {
        c = L[q, 2]
        j = L[q, 1]
        C[(c - 1) * nv + j, 3] = C[(c - 1) * nv + j, 3] + 1
        if (L[q, 5] == 3) {
            C[(j - 1) * nv + c, 3] = C[(j - 1) * nv + c, 3] + 1
        }
    }
    st_matrix(cn, C)
}

// fills string variable lab with lag lists, row order = cause-major
void _tvpcg_heat_lab(string scalar lname)
{
    real matrix L, C
    real scalar q, r, nv, c, j
    string scalar s
    L = st_matrix(lname)
    C = st_data(., ("c1", "c2"))
    for (r = 1; r <= rows(C); r++) {
        c = C[r, 1]
        j = C[r, 2]
        s = ""
        for (q = 1; q <= rows(L); q++) {
            if (L[q, 5] == 3 & ((L[q, 1] == j & L[q, 2] == c) | (L[q, 1] == c & L[q, 2] == j))) {
                if (s != "") {
                    s = s + ","
                }
                s = s + "u"
            }
            else if (L[q, 5] != 3 & L[q, 1] == j & L[q, 2] == c) {
                if (s != "") {
                    s = s + ","
                }
                s = s + strofreal(L[q, 3])
            }
        }
        st_sstore(r, "lab", s)
    }
}

void _tvpcg_net_m(string scalar lname, real scalar nv, real scalar m,
                  string scalar nn, string scalar en)
{
    real matrix L, N, E, act, X, Y
    real scalar i, k, q, th, rad, c, j, lg, x1, y1, x2, y2, dx, dy, len, sh
    L = st_matrix(lname)
    act = J(nv, m + 1, 0)
    for (q = 1; q <= rows(L); q++) {
        act[L[q, 2], L[q, 3] + 1] = 1
    }
    X = J(nv, m + 1, .)
    Y = J(nv, m + 1, .)
    N = J(0, 4, .)
    for (i = 1; i <= nv; i++) {
        th = pi() / 2 - 2 * pi() * (i - 1) / nv
        for (k = 0; k <= m; k++) {
            rad = 1.5 + 0.55 * k
            // spread lags of one variable slightly in angle
            X[i, k + 1] = rad * cos(th + 0.35 * k / nv)
            Y[i, k + 1] = rad * sin(th + 0.35 * k / nv)
            if (k == 0 | act[i, k + 1]) {
                N = N \ (X[i, k + 1], Y[i, k + 1], i, k)
            }
        }
    }
    E = J(0, 5, .)
    for (q = 1; q <= rows(L); q++) {
        j = L[q, 1]
        c = L[q, 2]
        lg = L[q, 3]
        x1 = X[c, lg + 1]
        y1 = Y[c, lg + 1]
        x2 = X[j, 1]
        y2 = Y[j, 1]
        dx = x2 - x1
        dy = y2 - y1
        len = sqrt(dx * dx + dy * dy)
        sh = 0
        if (len > 0) {
            sh = 0.13 / len
        }
        if (L[q, 5] == 3) {
            E = E \ (y1, x1, y2, x2, 3)
        }
        else {
            E = E \ (y1, x1, y2 - sh * dy, x2 - sh * dx, L[q, 5])
        }
    }
    st_matrix(nn, N)
    st_matrix(en, E)
}

string scalar _tvpcg_lagtxt(real rowvector lags)
{
    string scalar s
    real scalar q
    s = ""
    for (q = 1; q <= cols(lags); q++) {
        if (s != "") {
            s = s + ","
        }
        if (lags[q] == 0) {
            s = s + "t"
        }
        else if (q == 1 | lags[max((1, q - 1))] == 0) {
            s = s + "t-" + strofreal(lags[q])
        }
        else {
            s = s + strofreal(lags[q])
        }
    }
    return("(" + s + ")")
}

void _tvpcg_map_m(string scalar lname, real scalar nv, real scalar tg,
                  string scalar bn, string scalar en, string scalar vlist)
{
    real matrix L, B, E, own, ownT
    real scalar q, c, k, m, nb, r, j, x, i, g, found, n1, und
    real rowvector lags, drv, row3, grpk, used
    string rowvector vn, labs
    string scalar key
    string colvector keys
    real colvector gid
    real scalar xt, yt
    L = st_matrix(lname)
    vn = tokens(vlist)
    m = max(L[., 3])
    // own lags: drives target? and set of other targets
    own = J(m + 1, 1, 0)
    ownT = J(m + 1, nv, 0)
    for (q = 1; q <= rows(L); q++) {
        if (L[q, 2] == tg & L[q, 1] == tg & L[q, 5] != 3) {
            own[L[q, 3] + 1] = 1
        }
        if (L[q, 2] == tg & L[q, 1] != tg & L[q, 3] > 0) {
            ownT[L[q, 3] + 1, L[q, 1]] = 1
        }
    }
    B = J(0, 3, .)
    E = J(0, 5, .)
    labs = J(1, 0, "")
    // row 1: other drivers (grouped by variable)
    drv = J(1, 0, .)
    for (c = 1; c <= nv; c++) {
        if (c == tg) {
            continue
        }
        lags = J(1, 0, .)
        und = 0
        for (q = 1; q <= rows(L); q++) {
            if (L[q, 1] == tg & L[q, 2] == c & L[q, 5] != 3) {
                lags = (lags, L[q, 3])
            }
            if (L[q, 5] == 3 & ((L[q, 1] == tg & L[q, 2] == c) | (L[q, 2] == tg & L[q, 1] == c))) {
                und = 1
            }
        }
        if (cols(lags) > 0) {
            drv = (drv, c)
            if (und) {
                labs = (labs, vn[c] + " " + _tvpcg_lagtxt(sort(lags', 1)') + " + t undir.")
            }
            else {
                labs = (labs, vn[c] + " " + _tvpcg_lagtxt(sort(lags', 1)'))
            }
            B = B \ (., 3, 3)
        }
        else if (und) {
            drv = (drv, c)
            labs = (labs, vn[c] + " (t, undirected)")
            B = B \ (., 3, 30 + c)
        }
    }
    // own-lag groups: identical (drives target, target set)
    gid = J(m + 1, 1, 0)
    g = 0
    for (k = 1; k <= m; k++) {
        if (own[k + 1] == 0 & sum(ownT[k + 1, .]) == 0) {
            continue
        }
        found = 0
        for (i = 1; i < k; i++) {
            if (gid[i + 1] > 0 & found == 0) {
                if (own[i + 1] == own[k + 1] & ownT[i + 1, .] == ownT[k + 1, .]) {
                    gid[k + 1] = gid[i + 1]
                    found = 1
                }
            }
        }
        if (found == 0) {
            g = g + 1
            gid[k + 1] = g
        }
    }
    n1 = rows(B)
    // add own-lag groups: row 1 if drives target, else row 2
    for (i = 1; i <= g; i++) {
        lags = J(1, 0, .)
        for (k = 1; k <= m; k++) {
            if (gid[k + 1] == i) {
                lags = (lags, k)
            }
        }
        labs = (labs, vn[tg] + " " + _tvpcg_lagtxt(lags))
        if (own[lags[1] + 1]) {
            B = B \ (., 3, 2)
        }
        else {
            B = B \ (., 2, 2)
        }
    }
    // target
    labs = (labs, vn[tg] + " (t)")
    B = B \ (., 2, 1)
    // row 3: variables driven by target lags or target(t)
    row3 = J(1, 0, .)
    for (j = 1; j <= nv; j++) {
        if (j == tg) {
            continue
        }
        found = 0
        for (q = 1; q <= rows(L); q++) {
            if (L[q, 1] == j & L[q, 2] == tg & L[q, 5] != 3) {
                found = 1
            }
        }
        if (found) {
            row3 = (row3, j)
            labs = (labs, vn[j] + " (t)")
            B = B \ (., 1, 4)
        }
    }
    // x positions: spread each row
    for (r = 1; r <= 3; r++) {
        nb = sum(B[., 2] :== r)
        x = 0
        if (r == 2) {
            // target first (leftmost), then own-lag boxes
            for (q = 1; q <= rows(B); q++) {
                if (B[q, 2] == 2 & B[q, 3] == 1) {
                    x = x + 1
                    B[q, 1] = x
                }
            }
            x = x + 0.6
        }
        for (q = 1; q <= rows(B); q++) {
            if (B[q, 2] == r & !(r == 2 & B[q, 3] == 1)) {
                x = x + 1
                B[q, 1] = x
            }
        }
    }
    // edges
    // locate target box
    for (q = 1; q <= rows(B); q++) {
        if (B[q, 3] == 1) {
            xt = B[q, 1]
            yt = B[q, 2]
        }
    }
    // drivers -> target
    for (q = 1; q <= n1; q++) {
        if (B[q, 3] >= 30) {
            E = E \ (B[q, 2] - 0.17, B[q, 1], yt + 0.17, xt, 3)
        }
        else {
            E = E \ (B[q, 2] - 0.17, B[q, 1], yt + 0.20, xt, 1)
        }
    }
    // own-lag groups
    for (i = 1; i <= g; i++) {
        q = n1 + i
        for (k = 1; k <= m; k++) {
            if (gid[k + 1] == i) {
                break
            }
        }
        if (own[k + 1] & B[q, 2] == 3) {
            E = E \ (B[q, 2] - 0.17, B[q, 1], yt + 0.20, xt, 1)
        }
        for (r = 1; r <= rows(B); r++) {
            if (B[r, 3] == 4) {
                // which variable is this row-3 box?
                j = row3[r - (rows(B) - cols(row3))]
                if (ownT[k + 1, j]) {
                    E = E \ (B[q, 2] - 0.17, B[q, 1], B[r, 2] + 0.20, B[r, 1], 1)
                }
            }
        }
    }
    // target(t) -> row 3 (contemporaneous directed)
    for (r = 1; r <= rows(B); r++) {
        if (B[r, 3] == 4) {
            j = row3[r - (rows(B) - cols(row3))]
            for (q = 1; q <= rows(L); q++) {
                if (L[q, 1] == j & L[q, 2] == tg & L[q, 5] == 2) {
                    E = E \ (yt - 0.17, xt, B[r, 2] + 0.20, B[r, 1], 1)
                }
            }
        }
    }
    if (rows(E) == 0) {
        E = J(1, 5, .)
    }
    // kinds for drawing: 1 target, 2 own lag, 3 other
    for (q = 1; q <= rows(B); q++) {
        if (B[q, 3] >= 30 | B[q, 3] == 4) {
            B[q, 3] = 3
        }
    }
    for (q = 1; q <= cols(labs); q++) {
        st_global("TVPCG_LAB" + strofreal(q), labs[q])
    }
    st_matrix(bn, B)
    st_matrix(en, E)
}

end
