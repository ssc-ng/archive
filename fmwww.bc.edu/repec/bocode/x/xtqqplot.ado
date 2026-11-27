*! xtqqplot 1.0.0  25nov2026
*! Graphs after xtqqr / xtqqkrls (panel quantile-on-quantile family)
*! Author: Dr Merwan Roudane  <merwanroudane920@gmail.com>
*! https://github.com/merwanroudane

program define xtqqplot
    version 14.0
    syntax [, HEATmap CONTour SLICes VALidate AME                  ///
        Value(string) COLORmap(string) LEVels(integer 24)            ///
        SIGmark ALpha(real 0.05) AT(numlist >0 <1) OVER(string)      ///
        VALUES COMBine NBins(integer 16)                             ///
        TItle(string asis) SUBtitle(string asis) NAME(string)        ///
        SAVing(string asis) SCHeme(string) noDRAW ]

    if !inlist("`e(cmd)'", "xtqqr", "xtqqkrls") {
        di as err "xtqqplot requires results from {bf:xtqqr} or {bf:xtqqkrls}"
        exit 301
    }
    _xtqqr_load

    local ntype = ("`heatmap'" != "") + ("`contour'" != "") + ///
        ("`slices'" != "") + ("`validate'" != "") + ("`ame'" != "")
    if `ntype' == 0 local heatmap "heatmap"
    if `ntype' > 1 {
        di as err "specify only one of heatmap, contour, slices, validate, ame"
        exit 198
    }
    if "`colormap'" == "" local colormap "parula"
    local colormap = lower("`colormap'")
    if !inlist("`colormap'", "parula", "jet", "bwr") {
        di as err "colormap() must be parula, jet or bwr"
        exit 198
    }
    if "`value'" == "" local value "coef"
    if !inlist("`value'", "coef", "p", "t", "se", "r2") {
        di as err "value() must be coef, se, t, p or r2"
        exit 198
    }
    if "`scheme'" == "" local scheme "s2color"
    if "`name'" == "" local name "xtqq_`heatmap'`contour'`slices'`validate'`ame'"
    local nameopt `"name(`name', replace)"'
    local drawopt ""
    if "`draw'" == "nodraw" local drawopt "nodraw"

    local y "`e(depvar)'"
    local x "`e(qqvar)'"
    local xtit "Quantiles of `x' (theta)"
    if "`e(method)'" == "groups" local xtit "Quantile group of `x' (vs group 1)"
    local estlab "QQR"
    if "`e(cmd)'" == "xtqqkrls" local estlab "QQKRLS"
    local gr `"graphregion(color(white)) plotregion(color(white)) bgcolor(white)"'

    * --------------------------------------------- tile heatmap (default)
    if "`heatmap'" != "" {
        if "`value'" == "r2" & "`e(cmd)'" == "xtqqkrls" {
            di as err "value(r2) is not available after xtqqkrls"
            exit 198
        }
        local ttl1 "QQ slope b(tau, theta)"
        if "`e(cmd)'" == "xtqqkrls" local ttl1 "QQKRLS effect b(tau, theta)"
        if "`e(method)'" == "groups" local ttl1 "Group effect vs group 1"
        if "`value'" == "p"  local ttl1 "p-value"
        if "`value'" == "se" local ttl1 "Standard error"
        if "`value'" == "t"  local ttl1 "z-statistic"
        if "`value'" == "r2" local ttl1 "Pseudo R-squared"
        if `"`title'"' == "" local title `""Panel `estlab': `y' on `x'""'
        if "`combine'" == "" {
            _xtqq_tile, value(`value') map(`colormap') nb(`nbins')           ///
                ttl(`title') `values' name(`name') xname(`x') yname(`y')     ///
                note(`subtitle') `drawopt' full
        }
        else {
            local second "p"
            if "`value'" == "p" local second "coef"
            local ttl2 "p-value"
            if "`second'" == "coef" local ttl2 "QQ slope b(tau, theta)"
            _xtqq_tile, value(`value') map(`colormap') nb(`nbins')           ///
                ttl("`ttl1'") `values' name(`name'_a) xname(`x') yname(`y') nodraw
            _xtqq_tile, value(`second') map(`colormap') nb(`nbins')          ///
                ttl("`ttl2'") `values' name(`name'_b) xname(`x') yname(`y') nodraw
            graph combine `name'_a `name'_b, cols(2) graphregion(color(white)) ///
                imargin(tiny) xsize(10) ysize(4.8) title(`title', size(medsmall) ///
                color(black)) note("Cells: *** p<0.01, ** p<0.05, * p<0.10.", ///
                size(vsmall)) name(`name', replace) `drawopt'
        }
    }

    * ------------------------------------------------------ contour map
    if "`contour'" != "" {
        if "`value'" == "r2" & "`e(cmd)'" == "xtqqkrls" {
            di as err "value(r2) is not available after xtqqkrls"
            exit 198
        }
        tempname Z PV TAU TH
        local zm "`value'"
        matrix `Z'   = e(`zm')
        matrix `PV'  = e(p)
        matrix `TAU' = e(tau)
        matrix `TH'  = e(theta)
        preserve
        qui {
            clear
            local M = rowsof(`Z')
            local L = colsof(`Z')
            set obs `=`M'*`L''
            gen double tau = .
            gen double theta = .
            gen double z = .
            gen double p = .
            local k = 0
            forvalues i = 1/`M' {
                forvalues j = 1/`L' {
                    local ++k
                    replace tau   = `TAU'[`i', 1] in `k'
                    replace theta = `TH'[`j', 1] in `k'
                    replace z     = `Z'[`i', `j'] in `k'
                    replace p     = `PV'[`i', `j'] in `k'
                }
            }
            drop if z >= .
            su z, meanonly
            local zmin = r(min)
            local zmax = r(max)
        }
        if `zmin' >= . {
            di as err "no estimated cells to plot"
            exit 2000
        }
        if "`value'" == "p" {
            local zmin = 0
            local zmax = 1
        }
        else if `zmin' == `zmax' {
            local zmin = `zmin' - 0.5
            local zmax = `zmax' + 0.5
        }
        else if "`colormap'" == "bwr" & `zmin' < 0 & `zmax' > 0 {
            local za = max(abs(`zmin'), abs(`zmax'))
            local zmin = -`za'
            local zmax = `za'
        }
        local n = max(4, `levels')
        mata: xqq_colors_to_local("`colormap'", `n', "ccol")
        local step = (`zmax' - `zmin') / `n'
        local cuts ""
        forvalues c = 1/`=`n'-1' {
            local cuts "`cuts' `=`zmin' + `c' * `step''"
        }
        local ztit "b1(tau, theta)"
        if "`value'" == "p"  local ztit "p-value"
        if "`value'" == "se" local ztit "std. error"
        if "`value'" == "t"  local ztit "z-statistic"
        if "`value'" == "r2" local ztit "pseudo R2"
        if `"`title'"' == "" {
            local title `"Panel `estlab': effect of `x' on `y'"'
        }
        local hm ""
        local interp "interp(thinplatespline)"
        local sig ""
        if "`sigmark'" != "" {
            local sig `"(scatter tau theta if p < `alpha', msymbol(X) mcolor(black) msize(small))"'
        }
        local leg "legend(off)"
        if "`sigmark'" != "" {
            local leg `"legend(order(2 "p < `alpha'") pos(6) ring(1) rows(1) region(lcolor(white)))"'
        }
        twoway (contour z tau theta, `hm' ccuts(`cuts') ccolors(`ccol') `interp' ///
                zlabel(#6, format(%6.2f)) ztitle("`ztit'"))                     ///
            `sig',                                                              ///
            title(`title', size(medium) color(black))                           ///
            subtitle(`subtitle')                                                ///
            xtitle("`xtit'") ytitle("Quantiles of `y' (tau)")                   ///
            xlabel(, grid glcolor(gs14)) ylabel(, angle(0) grid glcolor(gs14))  ///
            `leg' aspectratio(1) `gr' scheme(`scheme') `nameopt' `drawopt'
        restore
    }

    * ------------------------------------------------------------ slices
    if "`slices'" != "" {
        if "`over'" == "" local over "theta"
        if !inlist("`over'", "theta", "tau") {
            di as err "over() must be theta or tau"
            exit 198
        }
        tempname B SE TAU TH
        matrix `B'   = e(coef)
        matrix `SE'  = e(se)
        matrix `TAU' = e(tau)
        matrix `TH'  = e(theta)
        local M = rowsof(`B')
        local L = colsof(`B')
        * choose the slices (nearest grid points to at())
        if "`over'" == "theta" {
            local npts = `L'
            local Vm "`TH'"
        }
        else {
            local npts = `M'
            local Vm "`TAU'"
        }
        if "`at'" == "" {
            if "`e(method)'" == "groups" & "`over'" == "theta" {
                local pick ""
                forvalues j = 1/`L' {
                    local pick "`pick' `j'"
                }
            }
            else {
                local at "0.1 0.5 0.9"
            }
        }
        if "`at'" != "" {
            local pick ""
            foreach a of local at {
                local best = 1
                local bd = 1e10
                forvalues j = 1/`npts' {
                    local d = abs(`Vm'[`j', 1] - `a')
                    if `d' < `bd' {
                        local bd = `d'
                        local best = `j'
                    }
                }
                local pick "`pick' `best'"
            }
            local pick : list uniq pick
        }
        local zc = invnormal(1 - `alpha' / 2)
        preserve
        qui {
            clear
            local np : word count `pick'
            local nrow = cond("`over'" == "theta", `M', `L')
            set obs `=`np' * `nrow''
            gen double q = .
            gen double b = .
            gen double lo = .
            gen double hi = .
            gen int s = .
            local k = 0
            local sidx = 0
            foreach jj of local pick {
                local ++sidx
                forvalues r = 1/`nrow' {
                    local ++k
                    if "`over'" == "theta" {
                        local bv = `B'[`r', `jj']
                        local sv = `SE'[`r', `jj']
                        local qv = `TAU'[`r', 1]
                    }
                    else {
                        local bv = `B'[`jj', `r']
                        local sv = `SE'[`jj', `r']
                        local qv = `TH'[`r', 1]
                    }
                    replace q = `qv' in `k'
                    replace b = `bv' in `k'
                    replace lo = `bv' - `zc' * `sv' in `k'
                    replace hi = `bv' + `zc' * `sv' in `k'
                    replace s = `sidx' in `k'
                }
            }
        }
        local c1 "0 114 189"
        local c2 "217 83 25"
        local c3 "237 177 32"
        local c4 "126 47 142"
        local c5 "119 172 48"
        local c6 "77 190 238"
        local c7 "162 20 47"
        local plots ""
        local lord ""
        local sidx = 0
        foreach jj of local pick {
            local ++sidx
            local ci = mod(`sidx' - 1, 7) + 1
            local cc "`c`ci''"
            if "`over'" == "theta" {
                local lab = `TH'[`jj', 1]
                local labt "theta = `: di %4.2f `lab''"
                if "`e(method)'" == "groups" local labt "group `=`lab''"
            }
            else {
                local lab = `TAU'[`jj', 1]
                local labt "tau = `: di %4.2f `lab''"
            }
            local plots `"`plots' (rarea lo hi q if s == `sidx', color("`cc'%18") lwidth(none))"'
            local plots `"`plots' (connected b q if s == `sidx', lcolor("`cc'") mcolor("`cc'") msymbol(O) msize(small) lwidth(medthick))"'
            local lord `"`lord' `=2*`sidx'' "`labt'""'
        }
        if `"`title'"' == "" local title `"Panel `estlab' slices: `x' on `y'"'
        local xt2 "Quantiles of `y' (tau)"
        if "`over'" == "tau" local xt2 "`xtit'"
        twoway `plots', yline(0, lcolor(gs8) lpattern(dash))                ///
            title(`title', size(medium) color(black)) subtitle(`subtitle')   ///
            xtitle("`xt2'") ytitle("Effect of `x'")                          ///
            ylabel(, angle(0) grid glcolor(gs14)) xlabel(, grid glcolor(gs14)) ///
            legend(order(`lord') rows(1) pos(6) region(lcolor(white)))       ///
            note("Shaded: `=round(100*(1-`alpha'))'% pointwise confidence band") ///
            `gr' scheme(`scheme') `nameopt' `drawopt'
        restore
    }

    * ---------------------------------------------------------- validate
    if "`validate'" != "" {
        capture confirm matrix e(qrcomp)
        if _rc {
            di as err "validation results not found; re-run {bf:xtqqr} with option {bf:validate}"
            exit 198
        }
        tempname Q TAU
        matrix `Q' = e(qrcomp)
        matrix `TAU' = e(tau)
        local zc = invnormal(1 - `alpha' / 2)
        preserve
        qui {
            clear
            local M = rowsof(`Q')
            set obs `M'
            gen double tau = .
            gen double bqr = .
            gen double lo = .
            gen double hi = .
            gen double bqq = .
            forvalues i = 1/`M' {
                replace tau = `TAU'[`i', 1] in `i'
                replace bqr = `Q'[`i', 1] in `i'
                replace lo  = `Q'[`i', 1] - `zc' * `Q'[`i', 2] in `i'
                replace hi  = `Q'[`i', 1] + `zc' * `Q'[`i', 2] in `i'
                replace bqq = `Q'[`i', 4] in `i'
            }
        }
        if `"`title'"' == "" local title `"Panel QR vs averaged QQ estimates"'
        twoway (rarea lo hi tau, color("0 114 189%20") lwidth(none))                ///
            (line bqr tau, lcolor("0 114 189") lwidth(medthick))                     ///
            (connected bqq tau, lcolor("217 83 25") mcolor("217 83 25")              ///
                lpattern(dash) msymbol(D) msize(small)),                             ///
            title(`title', size(medium) color(black)) subtitle(`subtitle')           ///
            xtitle("Quantiles of `y' (tau)") ytitle("Effect of `x'")                 ///
            ylabel(, angle(0) grid glcolor(gs14)) xlabel(, grid glcolor(gs14))       ///
            legend(order(2 "Panel quantile regression" 1                             ///
                "`=round(100*(1-`alpha'))'% CI" 3 "QQ average over theta")           ///
                rows(1) pos(6) region(lcolor(white)))                                ///
            `gr' scheme(`scheme') `nameopt' `drawopt'
        restore
    }

    * --------------------------------------------------------------- ame
    if "`ame'" != "" {
        if "`e(cmd)'" != "xtqqkrls" {
            di as err "option ame is available after {bf:xtqqkrls}"
            exit 198
        }
        tempname A TH
        matrix `A' = e(ame)
        matrix `TH' = e(theta)
        local zc = invnormal(1 - `alpha' / 2)
        preserve
        qui {
            clear
            local L = rowsof(`A')
            set obs `L'
            gen double theta = .
            gen double b = .
            gen double lo = .
            gen double hi = .
            forvalues j = 1/`L' {
                replace theta = `TH'[`j', 1] in `j'
                replace b  = `A'[`j', 1] in `j'
                replace lo = `A'[`j', 1] - `zc' * `A'[`j', 2] in `j'
                replace hi = `A'[`j', 1] + `zc' * `A'[`j', 2] in `j'
            }
        }
        if `"`title'"' == "" local title `"KRLS average marginal effect of `x' by theta-regime"'
        twoway (rcap lo hi theta, lcolor("0 114 189"))                      ///
            (connected b theta, lcolor("0 114 189") mcolor("217 83 25")     ///
                msymbol(O)),                                                 ///
            yline(0, lcolor(gs8) lpattern(dash))                             ///
            title(`title', size(medium) color(black)) subtitle(`subtitle')   ///
            xtitle("`xtit'") ytitle("Average pointwise effect on `y'")       ///
            ylabel(, angle(0) grid glcolor(gs14)) xlabel(, grid glcolor(gs14)) ///
            legend(order(2 "Average effect" 1 "`=round(100*(1-`alpha'))'% CI") ///
                rows(1) pos(6) region(lcolor(white)))                         ///
            `gr' scheme(`scheme') `nameopt' `drawopt'
        restore
    }

    if `"`saving'"' != "" {
        * raster exports default to 2200 pixels wide (journal quality)
        local sv `"`saving'"'
        local lsv = lower(`"`sv'"')
        local raster = strpos(`"`lsv'"', ".png") | strpos(`"`lsv'"', ".tif") | ///
            strpos(`"`lsv'"', ".jpg") | strpos(`"`lsv'"', ".gif")
        if `raster' & !strpos(`"`lsv'"', "width(") {
            if strpos(`"`sv'"', ",") local sv `"`sv' width(2200)"'
            else                     local sv `"`sv', width(2200)"'
        }
        graph export `sv'
    }
end


* =====================================================================
* Tile heatmap: one exact cell per (tau, theta) pair, white grid,
* significance stars in the cells, colour bar (Parula by default).
* tau (quantiles of y) on the x-axis, theta (quantiles of x) on the
* y-axis, the layout of the QQ literature (Sim & Zhou 2015, Fig. 3;
* Adebayo et al. 2024, Figs. 3-8).
* =====================================================================
program define _xtqq_tile
    version 14.0
    syntax , VALUE(string) MAP(string) NB(integer) NAME(string)      ///
        XNAME(string) YNAME(string) [ TTL(string asis) VALUES NODRAW ///
        NOTE(string asis) FULL ]

    tempname Z PV TAU TH COL
    matrix `Z'   = e(`value')
    matrix `PV'  = e(p)
    matrix `TAU' = e(tau)
    matrix `TH'  = e(theta)
    local M = rowsof(`Z')
    local L = colsof(`Z')
    local nb = max(4, `nb')
    local grp = ("`e(method)'" == "groups")

    preserve
    qui {
        clear
        set obs `=`M'*`L''
        gen int ix = .
        gen int iy = .
        gen double z = .
        gen double p = .
        local k = 0
        forvalues i = 1/`M' {
            forvalues j = 1/`L' {
                local ++k
                replace ix = `i' in `k'
                replace iy = `j' in `k'
                replace z  = `Z'[`i', `j'] in `k'
                replace p  = `PV'[`i', `j'] in `k'
            }
        }
        gen double y0 = iy - 0.5
        gen double y1 = iy + 0.5
        gen str3 star = ""
        replace star = "*"   if p < 0.10
        replace star = "**"  if p < 0.05
        replace star = "***" if p < 0.01
        replace star = "" if z >= .
        su z, meanonly
        local zmin = r(min)
        local zmax = r(max)
    }
    if `zmin' >= . {
        di as err "no estimated cells to plot"
        exit 2000
    }
    if "`value'" == "p" {
        local zmin = 0
        local zmax = 1
    }
    if "`map'" == "bwr" & "`value'" != "p" & "`value'" != "se" {
        local za = max(abs(`zmin'), abs(`zmax'))
        local zmin = -`za'
        local zmax = `za'
    }
    if `zmax' <= `zmin' {
        local zmin = `zmin' - 0.5
        local zmax = `zmax' + 0.5
    }
    mata: st_matrix("`COL'", xqq_palette("`map'", `nb'))
    qui gen int bin = min(`nb', 1 + floor(`nb' * (z - `zmin') / (`zmax' - `zmin')))
    qui replace bin = . if z >= .

    * axis labels
    local xl ""
    forvalues i = 1/`M' {
        local v : display %4.2f `TAU'[`i', 1]
        local xl `"`xl' `i' "`v'""'
    }
    local yl ""
    forvalues j = 1/`L' {
        if `grp' {
            local v = "g" + string(`TH'[`j', 1])
        }
        else {
            local v : display %4.2f `TH'[`j', 1]
        }
        local yl `"`yl' `j' "`v'""'
    }

    * tiles (empty cells stay white) and colour bar
    local xb0 = `M' + 0.9
    local xb1 = `M' + 1.4
    local layers `"(rbar y0 y1 ix, barwidth(1) fcolor(white) lcolor(gs13) lwidth(vthin))"'
    forvalues b = 1/`nb' {
        local rgb = string(`COL'[`b', 1]) + " " + string(`COL'[`b', 2]) + ///
            " " + string(`COL'[`b', 3])
        qui count if bin == `b'
        if r(N) > 0 {
            local layers `"`layers' (rbar y0 y1 ix if bin == `b', barwidth(1) fcolor("`rgb'") fintensity(100) lcolor(white) lwidth(thin))"'
        }
        local cb0 = 0.5 + (`b' - 1) * `L' / `nb'
        local cb1 = 0.5 + `b' * `L' / `nb'
        local layers `"`layers' (scatteri `cb0' `xb0' `cb1' `xb0' `cb1' `xb1' `cb0' `xb1' `cb0' `xb0', recast(area) fcolor("`rgb'") lcolor("`rgb'") lwidth(none) nodropbase)"'
    }
    local t0 : display %9.3g `zmin'
    local t1 : display %9.3g (`zmin' + `zmax') / 2
    local t2 : display %9.3g `zmax'
    local tx = `xb1' + 0.15
    local ymid = (`L' + 1) / 2
    local txt `"text(0.5 `tx' "`=trim("`t0'")'", place(e) size(small)) text(`ymid' `tx' "`=trim("`t1'")'", place(e) size(small)) text(`=`L'+0.5' `tx' "`=trim("`t2'")'", place(e) size(small))"'

    * cell labels: stars, or value + stars (sizes adapt to the grid)
    local dense = (`M' > 13 | `L' > 13)
    local lsz "medsmall"
    if `dense' local lsz "small"
    if "`values'" != "" {
        qui gen str14 lab = string(z, "%5.2f") + star
        qui replace lab = "" if z >= .
        local lsz "vsmall"
        if `dense' local lsz "tiny"
        local mark "mlabel(lab) mlabsize(`lsz')"
    }
    else {
        local mark "mlabel(star) mlabsize(`lsz')"
    }
    local labsz "small"
    if `dense' local labsz "vsmall"
    local gsize ""
    if "`full'" != "" local gsize "xsize(7.5) ysize(6.6)"
    local ytt "Quantiles of `xname' ({&theta})"
    if `grp' local ytt "Quantile group of `xname'"
    local nopt ""
    if "`full'" != "" {
        local nopt `"note("Cells: *** p<0.01, ** p<0.05, * p<0.10.  White cells: not estimated." `note', size(vsmall))"'
    }

    twoway `layers'                                                          ///
        (scatter iy ix, msymbol(none) `mark' mlabposition(0) mlabcolor(black)), ///
        `txt' title(`ttl', size(medsmall) color(black))                       ///
        xtitle("Quantiles of `yname' ({&tau})", size(medsmall))                ///
        ytitle("`ytt'", size(medsmall))                                        ///
        xlabel(`xl', labsize(`labsz') angle(45) noticks nogrid)                ///
        ylabel(`yl', labsize(`labsz') angle(0) noticks nogrid)                 ///
        xscale(range(0.5 `=`M'+2.4') noline) yscale(range(0.5 `=`L'+0.5') noline) ///
        legend(off) graphregion(color(white)) plotregion(margin(zero) style(none)) ///
        aspectratio(0.85) `nopt' `gsize' name(`name', replace) `nodraw'
    restore
end
