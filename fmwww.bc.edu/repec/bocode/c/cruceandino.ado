*! cruceandino v0.9.1  2026  Juan Marcelo Gutierrez Miranda | TodoEconometria
*! Multiway cross of an outcome by 1-3 categoricals -> table (collect) + figure.
*! Aimed at household-survey consumption studies (coca/alcohol/tobacco). Requires
*! Stata 17+ (table/collect framework). In one command it emits an exportable
*! table and its coherent figure, with consistent labels and percentages.
*!
*! Syntax:
*!   cruceandino outcome factor1 [factor2 [factor3]] [if] [in] [weight] ,
*!        [ by(varname) statistic(name) pct freq line heatmap composition
*!          panel dual sort hbar title("...") subtitle("...") note("...")
*!          saving("table.md|.docx|.html|.tex") graph("figure.png")
*!          format(%fmt) scheme(name) color(colorstyle) gropts(...) nograph ]
*!   - outcome : outcome variable (binary -> with pct gives a prevalence in %).
*!               In -composition- mode there is NO outcome: all varlist are factors.
*!   - factorN : 1 to 3 categoricals to cross.
*!   - line       : LINE (series) plot; x = factor1 (e.g. year).
*!   - heatmap    : heatmap of the outcome over factor1 (x) by factor2 (y).
*!   - composition: % of the (sub)sample in each cell (as catplot -percent-);
*!                  best with an -if- (e.g. the composition of consumers).
*! v0.9.1: line mode no longer prints the series levels; room for bar value labels
*!         (vertical: below the panel strip; horizontal: right edge).
*! v0.9: -dual- mode = the two margins of an ordinal outcome (0=none): extensive
*!       (% consuming) as bars + intensive (frequency among consumers) as a line
*!       on a second axis; the double hurdle drawn, with its table (ext+int+N).
*! v0.8: class-binned heatmap colour (scales to hundreds of cells without breaking);
*!       auto-hbar when the axis factor has >12 categories (legible labels); -panel-
*!       (small multiples); -gropts()- passes options through to the inner graph;
*!       -hbar- forces horizontal bars.
*! v0.7: clean out-of-the-box output in every mode -- aspect (xsize/ysize), ytitle
*!       with margin and horizontal ylabel (does not collide with axis numbers);
*!       composition with asyvars (no label clash); heatmap with no plotregion box
*!       nor subtitle overlap. v0.6: subtitle() and legible title/axis.
*!       v0.5: heatmap, composition and sort. v0.4: scheme()/color(). v0.3: note().
*! Built ONLY on official Stata commands (table/collect, graph bar, twoway,
*! collapse): no community-contributed dependencies.
program define cruceandino, rclass
    version 17.0
    syntax varlist(min=1 max=4 numeric) [if] [in] [fweight aweight pweight/] , ///
        [ BY(varname numeric) STATistic(name) PCT FReq LIne HEATmap COMPosition ///
          PANel DUAL SORT TItle(string) SUBtitle(string) NOTE(string) SAVing(string) ///
          GRAph(string) FORmat(string) SCHeme(string) COLor(string) ///
          GRopts(string asis) HBAR NOGraph ]

    * --- outcome vs factors (in composition everything is a factor) ---
    if "`composition'"!="" {
        local out
        local facs `varlist'
    }
    else {
        gettoken out facs : varlist
        if `:word count `facs''==0 {
            di as error "need: outcome + at least 1 factor (or use the composition option)"
            exit 198
        }
    }
    local facs = strtrim(stritrim("`facs'"))
    if "`statistic'"=="" local statistic mean
    if "`format'"==""    local format %5.1f
    if "`color'"==""     local color "56 142 60"
    local schopt
    if "`scheme'"!="" local schopt scheme(`scheme')
    local notopt
    if `"`note'"'!="" local notopt note(`"`note'"')

    local nf : word count `facs'
    if "`heatmap'"!="" & `nf'<2 {
        di as error "heatmap needs at least 2 factors (x and y)"
        exit 198
    }
    if "`panel'"!="" & `nf'<2 {
        di as error "panel (small multiples) needs at least 2 factors: axis + panel category"
        exit 198
    }
    if "`dual'"!="" & "`composition'"!="" {
        di as error "dual does not combine with composition: dual decomposes an ordinal outcome (0=none)"
        exit 198
    }
    if "`dual'"!="" & `nf'<1 {
        di as error "dual needs: ordinal outcome + at least 1 factor (axis)"
        exit 198
    }

    marksample touse, strok
    markout `touse' `facs' `out' `by'
    quietly count if `touse'
    if r(N)==0 {
        di as error "no observations after if/in/missing"
        exit 2000
    }
    local nobs = r(N)

    * --- quantity to plot (only when there is an outcome) ---
    if "`composition'"=="" {
        tempvar y
        if "`pct'"!="" {
            quietly summarize `out' if `touse'
            if r(min)<0 | r(max)>1 di as txt "  (note: pct scales x100; `out' does not look binary 0/1)"
            quietly gen double `y' = 100*`out' if `touse'
            local yt "Prevalence (%)"
        }
        else {
            quietly gen double `y' = `out' if `touse'
            local yt "`statistic' of `out'"
        }
        * dual mode: the TWO margins of an ordinal outcome (0 = none)
        if "`dual'"!="" {
            tempvar dext dint
            quietly gen double `dext' = 100*(`out'>0) if `touse' & !missing(`out')
            quietly gen double `dint' = `out' if `touse' & `out'>0
            label variable `dext' "% consuming"
            label variable `dint' "Frequency|consumer"
        }
    }
    else local yt "% (composition)"
    * figure titles: main + secondary, legible in every mode
    local ttl title(`"`title'"', size(medlarge)) subtitle(`"`subtitle'"', size(small) color(gs6))
    * default subtitle explaining the two margins (if the user gave none)
    if "`dual'"!="" & `"`subtitle'"'=="" {
        local ttl title(`"`title'"', size(medlarge)) ///
            subtitle("Bars: % consuming | Line: frequency among consumers", size(small) color(gs6))
    }
    * common options so the output does not fall apart (aspect + clean axis)
    local szo xsize(10) ysize(6) graphregion(margin(l=5))
    local ylo ylabel(, angle(0) nogrid)
    * room for the value labels: without it the tallest bar's label hits the panel strip
    local blo plotregion(margin(t=5 r=3))

    * ===================== TABLE (table + collect) =====================
    local f1 : word 1 of `facs'
    local f2 : word 2 of `facs'
    local f3 : word 3 of `facs'
    local cols
    if "`by'"!="" local cols (`by')

    if "`dual'"!="" {
        * rich table: extensive (% consuming) + intensive (frequency|consumer) + N
        table (`facs') `cols' if `touse' [`weight'`exp'], ///
            statistic(mean `dext') statistic(mean `dint') statistic(frequency) ///
            nformat(`format' mean)
    }
    else if "`composition'"!="" {
        table (`facs') `cols' if `touse' [`weight'`exp'], ///
            statistic(frequency) statistic(percent) nformat(`format' percent)
    }
    else {
        local statspec statistic(`statistic' `y')
        if "`freq'"!="" local statspec `statspec' statistic(frequency)
        table (`facs') `cols' if `touse' [`weight'`exp'], `statspec' nformat(`format' `statistic')
    }
    if `"`saving'"'!="" {
        collect export `"`saving'"', replace
        di as txt "  table  -> `saving'"
    }

    * ===================== FIGURE =====================
    if "`nograph'"=="" {
        if "`heatmap'"!="" {
            * ---------- HEATMAP: colour in K CLASSES (scales without breaking) ----
            * v0.8 key: one SERIES per colour class (not one plot per cell), so it
            * does not hit the twoway layer limit (r1003) at high cardinality
            preserve
            quietly keep if `touse'
            collapse (`statistic') `y' [`weight'`exp'], by(`f1' `f2')
            quietly summarize `y'
            local lo = r(min)
            local hi = r(max)
            if `hi'<=`lo' local hi = `lo' + 1
            local K = 6
            local w = (`hi'-`lo')/`K'
            quietly gen int _bin = ceil((`y'-`lo')/`w')
            quietly replace _bin = 1  if _bin<1
            quietly replace _bin = `K' if _bin>`K'
            * 6 shades of green (light -> dark)
            local c1 "224 240 226"
            local c2 "199 227 204"
            local c3 "150 201 162"
            local c4 " 94 175 120"
            local c5 " 56 142  60"
            local c6 " 27  94  32"
            * grid dimensions -> marker size and aspect
            quietly levelsof `f1', local(_xv)
            local nx : word count `_xv'
            quietly levelsof `f2', local(_yv)
            local ny : word count `_yv'
            local big = max(`nx',`ny')
            local ms  = max(1.8, 30/`big')
            local hx  = max(7, min(13, `nx'*0.8))
            local hy  = max(6, min(15, `ny'*0.5))
            * one series per PRESENT class (avoids empty legend keys)
            quietly levelsof _bin, local(_pb)
            local plots
            local leg
            local pos 0
            foreach k of local _pb {
                local ++pos
                local plots `plots' (scatter `f2' `f1' if _bin==`k', ///
                    msymbol(square) msize(*`ms') mcolor("`c`k''") mlcolor(white) mlwidth(vvthin))
                local a : display `format' `lo'+(`k'-1)*`w'
                local b : display `format' `lo'+`k'*`w'
                local leg `leg' `pos' "`a'-`b'"
            }
            * in-cell numbers only if the grid is small (otherwise they clutter)
            local txts
            if _N<=48 {
                forvalues i = 1/`=_N' {
                    local xv = `f1'[`i']
                    local yv = `f2'[`i']
                    local vv = `y'[`i']
                    local bb = _bin[`i']
                    local tc = cond(`bb'>=5, "white", "0 0 0")
                    local txts `txts' text(`yv' `xv' "`: display `format' `vv''", size(vsmall) color("`tc'"))
                }
            }
            * axis labels from value labels
            local xlab
            foreach x of local _xv {
                local e : label (`f1') `x'
                local xlab `xlab' `x' `"`e'"'
            }
            local ylab2
            foreach y2 of local _yv {
                local e : label (`f2') `y2'
                local ylab2 `ylab2' `y2' `"`e'"'
            }
            * range with slack (0.6) so edge cells can breathe
            quietly summarize `f1'
            local xmin = r(min) - 0.6
            local xmax = r(max) + 0.6
            quietly summarize `f2'
            local ymin = r(min) - 0.6
            local ymax = r(max) + 0.6
            twoway `plots', `txts' `schopt' `notopt' ///
                xlabel(`xlab', angle(45) noticks nogrid labsize(vsmall)) ///
                ylabel(`ylab2', noticks nogrid labsize(vsmall) angle(0)) ///
                xscale(noline range(`xmin' `xmax')) ///
                yscale(noline range(`ymin' `ymax')) ///
                plotregion(margin(zero) lcolor(none) lstyle(none)) ///
                xtitle("") ytitle("") ///
                legend(order(`leg') rows(1) pos(6) size(vsmall) title("`yt'", size(vsmall))) ///
                `ttl' xsize(`hx') ysize(`hy') `gropts' ///
                name(cruceandino, replace)
            restore
        }
        else if "`composition'"!="" {
            * ---------- COMPOSITION: % of the (sub)sample per cell ----------
            preserve
            quietly keep if `touse'
            tempvar w
            quietly gen double `w' = 1
            if "`exp'"!="" quietly replace `w' = `exp'
            collapse (sum) `w', by(`facs' `by')
            if "`by'"!="" quietly bysort `by': egen double _tot = total(`w')
            else quietly egen double _tot = total(`w')
            quietly gen double _pct = 100*`w'/_tot
            * one factor: plain bars; 2+ : f1 on X and f2 on COLOUR+legend (asyvars),
            * which avoids the clash of two rows of X-axis labels
            if `nf'==1 local overs over(`f1', label(labsize(small)))
            else       local overs over(`f2') over(`f1', label(labsize(small))) asyvars
            local bylist
            if `nf'==3 local bylist `f3'
            if "`by'"!="" local bylist `bylist' `by'
            local byopt
            local topttl `ttl'
            if "`bylist'"!="" {
                local byopt by(`bylist', legend(pos(6)) note(`"`note'"') `ttl')
                local topttl
            }
            local colopt bar(1, color("`color'"))
            local legopt
            if `nf'>=2 {
                local colopt
                local legopt legend(rows(1) pos(6) size(small))
            }
            graph bar (mean) _pct if !missing(_pct), ///
                `overs' `byopt' ytitle("`yt'", margin(r=3)) `ylo' `notopt' `schopt' `topttl' ///
                `colopt' `legopt' blabel(bar, format(`format') size(small)) `blo' ///
                `szo' `gropts' name(cruceandino, replace)
            restore
        }
        else if "`dual'"!="" {
            * ---------- DUAL: the TWO margins of an ordinal outcome ----------
            * extensive (% consuming) as bars (left axis) + intensive (frequency
            * among consumers) as a line (right axis). The double hurdle drawn.
            preserve
            quietly keep if `touse'
            * COMMON, honest range of the intensive axis [1, max ordinal]; left on
            * auto, by() rescales it per panel and inflates tiny variations (misleading)
            quietly summarize `out'
            local maxo = r(max)
            local istep = cond(`maxo'<=4, 0.5, 1)
            tempvar ex inn
            quietly gen byte   `ex'  = (`out'>0) if !missing(`out')
            quietly gen double `inn' = `out' if `out'>0
            local panv `f2'
            if "`f3'"!="" local panv `panv' `f3'
            if "`by'"!="" local panv `panv' `by'
            collapse (mean) `ex' `inn' [`weight'`exp'], by(`f1' `panv')
            quietly replace `ex' = 100*`ex'
            quietly levelsof `f1', local(_xl)
            local xlo : word 1 of `_xl'
            local xn  : word count `_xl'
            local xhi : word `xn' of `_xl'
            local byo
            local topttl `ttl'
            if "`panv'"!="" {
                local byo by(`panv', cols(2) note(`"`note'"') legend(off) ///
                    graphregion(margin(l=5)) `ttl')
                local topttl
            }
            twoway (bar `ex' `f1', yaxis(1) barwidth(0.65) color("`color'%80")) ///
                   (connected `inn' `f1', yaxis(2) lcolor("178 24 43") mcolor("178 24 43") ///
                        lwidth(medthick) msize(small)), ///
                `byo' `topttl' `notopt' `schopt' ///
                xlabel(`xlo'(1)`xhi', valuelabel angle(30) labsize(vsmall)) xtitle("") ///
                ytitle("% consuming", axis(1) margin(r=2)) ylabel(, axis(1) angle(0) nogrid) ///
                ytitle("Frequency among consumers", axis(2)) ///
                ylabel(1(`istep')`maxo', axis(2) angle(0)) yscale(axis(2) range(1 `maxo')) ///
                `szo' `gropts' name(cruceandino, replace)
            restore
        }
        else if "`panel'"!="" {
            * ---------- SMALL MULTIPLES: one mini-panel per category ----------
            * f1 = axis (e.g. year); f2 (+f3,+by) = panel categories. Ideal for
            * "evolution of X across many categories" without crowding one axis.
            preserve
            quietly keep if `touse'
            local pan `f2'
            if "`f3'"!="" local pan `pan' `f3'
            if "`by'"!="" local pan `pan' `by'
            collapse (`statistic') `y' [`weight'`exp'], by(`f1' `pan')
            quietly levelsof `f2', local(_pv)
            local ncol = min(5, `: word count `_pv'')
            twoway (connected `y' `f1', sort lcolor("`color'") mcolor("`color'") msize(vsmall) lwidth(medthin)), ///
                by(`pan', cols(`ncol') note(`"`note'"') legend(off) ///
                   graphregion(margin(l=4)) `ttl') ///
                ytitle("`yt'", size(vsmall) margin(r=2)) `ylo' `schopt' ///
                xtitle("") xlabel(, labsize(vsmall)) ///
                xsize(13) ysize(7.5) `gropts' name(cruceandino, replace)
            restore
        }
        else if "`line'"!="" {
            * ---------- LINE plot (series; x = factor1) ----------
            local series
            local panelv
            if "`f2'"!="" {
                local series `f2'
                local panelv `f3'
                if "`by'"!="" local panelv `panelv' `by'
            }
            else if "`by'"!="" {
                local series `by'
                local panelv `f3'
            }
            else local panelv `f3'
            preserve
            quietly keep if `touse'
            collapse (`statistic') `y' [`weight'`exp'], by(`f1' `series' `panelv')
            local byo
            local topttl `ttl'
            if "`panelv'"!="" {
                local byo by(`panelv', legend(pos(6)) note(`"`note'"') `ttl')
                local topttl
            }
            if "`series'"!="" {
                local lblname : value label `series'
                quietly levelsof `series', local(_lv)
                local plots
                local leg
                local k 0
                foreach v of local _lv {
                    local ++k
                    if "`lblname'"!="" local vl : label `lblname' `v'
                    else local vl "`series'=`v'"
                    local plots `plots' (connected `y' `f1' if `series'==`v', sort)
                    local leg `leg' `k' "`vl'"
                }
                twoway `plots', `byo' ytitle("`yt'", margin(r=3)) `ylo' `notopt' `schopt' `topttl' ///
                    legend(order(`leg') pos(6) rows(1) size(small)) `szo' `gropts' name(cruceandino, replace)
            }
            else {
                twoway (connected `y' `f1', sort lcolor("`color'") mcolor("`color'")), ///
                    `byo' ytitle("`yt'", margin(r=3)) `ylo' `notopt' `schopt' `topttl' ///
                    legend(off) `szo' `gropts' name(cruceandino, replace)
            }
            restore
        }
        else {
            * ---------- BAR plot (default) ----------
            local sorto
            if "`sort'"!="" local sorto sort(1) descending
            local bylist
            if `nf'==3 local bylist `f3'
            if "`by'"!="" local bylist `bylist' `by'
            * the title appears ONCE: inside by() if there are panels, else on top
            local byopt
            local topttl `ttl'
            if "`bylist'"!="" {
                local byopt by(`bylist', legend(pos(6)) note(`"`note'"') `ttl')
                local topttl
            }
            * auto-hbar: if the axis factor has MANY categories (>12) the horizontal
            * labels collide; switch to horizontal bars (names stacked with room).
            * Also if the user forces -hbar-.
            quietly levelsof `f1' if `touse', local(_f1v)
            local nlev : word count `_f1v'
            local barcmd graph bar
            local barsz  `szo'
            if `nlev'>12 | "`hbar'"!="" {
                local barcmd graph hbar
                local ht = max(6, min(16, `nlev'*0.38))
                local barsz xsize(9) ysize(`ht') graphregion(margin(l=5))
                local blo plotregion(margin(r=9))
            }
            if `nf'==1 {
                * one factor: bars over f1 with the number on top
                `barcmd' (`statistic') `y' if `touse' [`weight'`exp'], ///
                    over(`f1', `sorto' label(labsize(small))) `byopt' ///
                    ytitle("`yt'", margin(r=3)) `ylo' `notopt' `schopt' `topttl' ///
                    bar(1, color("`color'")) blabel(bar, format(`format') size(small)) `blo' ///
                    `barsz' `gropts' name(cruceandino, replace)
            }
            else {
                * 2+ factors: f1 on the X axis and f2 on COLOUR + legend; this avoids
                * the clash of two rows of labels (which makes the graph illegible)
                `barcmd' (`statistic') `y' if `touse' [`weight'`exp'], ///
                    over(`f2') over(`f1', `sorto' label(labsize(small))) asyvars ///
                    `byopt' ytitle("`yt'", margin(r=3)) `ylo' `notopt' `schopt' `topttl' ///
                    legend(rows(1) pos(6) size(small)) `barsz' `gropts' name(cruceandino, replace)
            }
        }

        if `"`graph'"'!="" {
            graph export `"`graph'"', replace width(2200)
            di as txt "  figure -> `graph'"
        }
    }

    * ===================== stored results =====================
    return local cmd       "cruceandino"
    return local outcome   "`out'"
    return local factors   "`facs'"
    return local by        "`by'"
    return local statistic "`statistic'"
    return local pct       = cond("`pct'"!="", "1", "0")
    return local mode      = cond("`heatmap'"!="","heatmap", cond("`composition'"!="","composition", cond("`dual'"!="","dual", cond("`panel'"!="","panel", cond("`line'"!="","line","bars")))))
    return scalar N        = `nobs'
end
