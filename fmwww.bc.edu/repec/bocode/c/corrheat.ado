*! version 0.1.2  03nov2026  Shane Littrell
*! Lower-triangle correlation heat plot with r and p cell labels and a
*! gradient color bar drawn inside the empty upper triangle.
*! Requires (SSC): heatplot, palettes, colrspace
*
*  SYNTAX
*    corrheat varlist [if] [in] [, options twoway_options]
*
*  OPTIONS
*    cuts(numlist)       color-bin edges, e.g. cuts(-0.1(0.05)1). Default: from
*                        the most negative r (rounded down to step()) up to 1.
*                        Give the same cuts() to every figure in a paper so a
*                        shade means the same r everywhere.
*    step(#)             bin width used for the automatic cuts; default .05
*    colors(colorlist)   default: White Ivory "118 223 253" "0 129 168"
*    whiteabove(#)       r at or above which cell text turns white; default .8
*    whitebelow(#)       r at or below which cell text turns white (useful with
*                        a diverging palette); default -2 (never)
*    rsize(size)         size of r labels, incl. the diagonal 1s; default *1.3
*    psize(size)         size of p labels; default *.9
*    nopvalues           show r only
*    leadzero            keep leading zeros (0.28, 0.020). Default drops them,
*                        APA style (.28, .020, <.001)
*    listwise            listwise deletion in pwcorr (default pairwise)
*    nobar               omit the color bar
*    barpos(x0 x1 ytop ybot)  bar position in plot coordinates (row i is at
*                        y = i, column j at x = j, row 1 on top). Default:
*                        k-1.25 k-.95 .6 .6+.45k, where k = number of variables
*    ticks(numlist)      bar ticks; values outside the bar's range are skipped.
*                        Default -1(.25)1
*    tlabsize(size)      size of bar tick labels; default small
*    twoway_options      anything else (xtitle(), xsize(), ysize(), name(),
*                        saving(), ...) is passed to the graph
*
*  EXAMPLE
*    corrheat cbsr bs_overall_rate bs_honesty bs_neuro bs_extra bs_agree ///
*        bs_consc bs_open bs_intell, cuts(-0.1(0.05)1)                   ///
*        xtitle("High BS Profiles", size(medium)) xsize(6.5) ysize(4.5)
*
*  Your data are left untouched (the program works on a preserved copy).
*  After editing this file with Stata open, type -discard- to reload it.

program define corrheat
    version 16
    syntax varlist(min=2 numeric) [if] [in] [,  ///
        CUTs(string)                            ///
        STep(real 0.05)                         ///
        COLors(string asis)                     ///
        WHITEAbove(real 0.8)                    ///
        WHITEBelow(real -2)                     ///
        RSize(string)                           ///
        PSize(string)                           ///
        NOPvalues                               ///
        LEADzero                                ///
        LISTwise                                ///
        NOBAR                                   ///
        BARpos(numlist min=4 max=4)             ///
        TICKs(numlist)                          ///
        TLABsize(string)                        ///
        * ]

    // ---- dependencies --------------------------------------------------
    foreach p in heatplot colorpalette {
        capture which `p'
        if _rc {
            di as err "-`p'- not found. Install with:"
            di as err "  ssc install heatplot"
            di as err "  ssc install palettes"
            di as err "  ssc install colrspace"
            exit 199
        }
    }

    // ---- defaults ------------------------------------------------------
    if `"`colors'"'=="" local colors `"White Ivory "118 223 253" "0 129 168""'
    if "`rsize'"==""    local rsize *1.3
    if "`psize'"==""    local psize *.9
    if "`tlabsize'"=="" local tlabsize small
    if "`ticks'"==""    local ticks -1 -.75 -.5 -.25 0 .25 .5 .75 1

    preserve

    // ---- correlations and p-values -------------------------------------
    tempname C S CUTS
    quietly pwcorr `varlist' `if' `in', sig `listwise'
    matrix `C' = r(C)
    matrix `S' = r(sig)
    local k = rowsof(`C')

    // ---- color-bin edges -----------------------------------------------
    if `"`cuts'"'=="" {
        mata: st_local("cmin", strofreal(floor(min(st_matrix("`C'"))/`step' + 1e-9)*`step', "%9.0g"))
        local cuts "`cmin'(`step')1"
    }
    di as txt "corrheat: using cuts(`cuts')"

    // ---- pass 1: no graph; store cell positions/values, exact colors/cuts
    quietly heatplot `C', values(label(`S')) lower nograph generate replace ///
        colors(`colors') cuts(`cuts')
    local barcolors `"`r(colors)'"'
    matrix `CUTS' = r(cuts)

    // ---- cell label strings --------------------------------------------
    tempvar rlab plab
    quietly gen str12 `rlab' = cond(_Y==_X, "1", string(_Z, "%4.2f")) if !missing(_Z)
    quietly gen str12 `plab' = cond(_Mlab<.001, "<0.001", string(_Mlab, "%5.3f")) ///
        if !missing(_Mlab) & _Y!=_X
    if "`leadzero'"=="" {
        quietly replace `rlab' = subinstr(`rlab', "0.", ".", 1)
        quietly replace `plab' = subinstr(`plab', "0.", ".", 1)
    }

    // ---- label plots: black text on light cells, white on dark cells ---
    // compare the rounded r so cells that display the same value match
    local dark  !missing(_Z) & (round(_Z,.01)>=`whiteabove' | round(_Z,.01)<=`whitebelow')
    local light !missing(_Z) & round(_Z,.01)<`whiteabove' & round(_Z,.01)>`whitebelow'
    local lbl scatter _Y _X if _Y!=_X & `light', msym(i) mlab(`rlab') ///
        mlabpos(0) mlabc(black) mlabsize(`rsize')
    local lbl `lbl' || scatter _Y _X if _Y!=_X & `dark', msym(i) mlab(`rlab') ///
        mlabpos(0) mlabc(white) mlabsize(`rsize')
    local lbl `lbl' || scatter _Y _X if _Y==_X & !missing(_Y), msym(i) ///
        mlab(`rlab') mlabpos(0) mlabc(white) mlabsize(`rsize')
    if "`nopvalues'"=="" {
        local lbl `lbl' || scatter _Y _X if _Y!=_X & `light', msym(i) ///
            mlab(`plab') mlabpos(6) mlabgap(1) mlabc(black) mlabsize(`psize')
        local lbl `lbl' || scatter _Y _X if _Y!=_X & `dark', msym(i) ///
            mlab(`plab') mlabpos(6) mlabgap(1) mlabc(white) mlabsize(`psize')
    }

    // ---- color bar -----------------------------------------------------
    local bar
    local textopt
    if "`nobar'"=="" {
        local nbins = colsof(`CUTS') - 1
        local vmin  = `CUTS'[1,1]
        local vmax  = `CUTS'[1,`nbins'+1]
        if "`barpos'"!="" {
            tokenize `barpos'
            local x0   `1'
            local x1   `2'
            local ytop `3'
            local ybot `4'
        }
        else {
            local x0   = `k' - 1.25
            local x1   = `k' - 0.95
            local ytop = 0.60
            local ybot = 0.60 + 0.45*`k'
        }
        local xlab = `x1' + 0.12
        local span = `vmax' - `vmin'
        local h    = `ybot' - `ytop'

        // one filled rectangle per color bin
        forvalues i = 1/`nbins' {
            gettoken c barcolors : barcolors
            local ylo = `ybot' - (`CUTS'[1,`i']   - `vmin')/`span'*`h'
            local yhi = `ybot' - (`CUTS'[1,`i'+1] - `vmin')/`span'*`h'
            local bar `bar' || scatteri `ylo' `x0' `yhi' `x0' `yhi' `x1' `ylo' `x1', ///
                recast(area) nodropbase color("`c'") finten(100) lwidth(vthin)
        }
        // thin outline so the white end stays visible
        local bar `bar' || scatteri `ybot' `x0' `ytop' `x0' `ytop' `x1' `ybot' `x1' `ybot' `x0', ///
            recast(line) lcolor(gs10) lwidth(vthin)

        // ticks and labels
        local labs
        foreach v of local ticks {
            if `v' < `vmin' - 1e-6 | `v' > `vmax' + 1e-6 continue
            local yv = `ybot' - (`v' - `vmin')/`span'*`h'
            local bar `bar' || scatteri `yv' `x1' `yv' `=`x1' + 0.07', ///
                recast(line) lcolor(gs8) lwidth(thin)
            local tl : display %4.2f `v'
            local tl = strtrim("`tl'")
            if "`leadzero'"=="" local tl = subinstr("`tl'", "0.", ".", 1)
            local labs `labs' `yv' `xlab' "`tl'"
        }
        if `"`labs'"'!="" local textopt text(`labs', place(e) size(`tlabsize'))
    }

    // ---- x-axis labels 1 ... k-1 (the last column holds only the diagonal)
    local xl
    forvalues j = 1/`=`k'-1' {
        local xl `xl' `j' "`j'"
    }

    // ---- pass 2: draw ---------------------------------------------------
    heatplot `C', colors(`colors') cuts(`cuts') lower legend(off) aspectratio(1) ///
        label xlabel(`xl', nogrid labsize(small))                               ///
        ylabel(, nogrid labsize(medsmall)) graphregion(color(white))            ///
        `textopt' addplot(`lbl' `bar') `options'
end
