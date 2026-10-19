*! xtpqgmmplot 1.0.0  14oct2026
*! Coefficient path beta-hat(tau) with POINTWISE confidence bands, for
*! xtpqgmm (Galvao, Hounyo and Lin 2026, arXiv:2610.12824).
*!
*! Author: Dr Merwan Roudane <merwanroudane920@gmail.com>
*!         github.com/merwanroudane
*!
*! IMPORTANT, and the reason this is a separate command rather than an option:
*! the bands drawn here are POINTWISE.  The paper's Theorem 4.1 is a pointwise
*! result at a fixed tau; it provides no uniform-in-tau limit process, so there
*! is no honest uniform band to draw.  Reading "the path leaves the band
*! somewhere" as a test of constancy is NOT valid.  See
*! {help xtpqgmm_methods##uniform:the methods page}.
*!
*! Requires Stata 17.0 or later.

program xtpqgmmplot, rclass
    version 17.0

    * ------------------------------------------------------------------ parse
    * Same shape as xtpqgmm itself: depvar [exog] (endog = excluded).
    _iv_parse `0'
    local lhs   `s(lhs)'
    local endog `s(endog)'
    local exog  `s(exog)'
    local excl  `s(inst)'
    local 0     `s(zero)'

    syntax [if] [in] ,                                        ///
        [ Quantile(numlist >0 <100 sort)                       ///
          Vars(varlist ts fv)                                  ///
          Level(cilevel)                                       ///
          noCI noYZero                                         ///
          GFORMat(string)                                      ///
          PLOTopts(string asis)  CIOpts(string asis)           ///
          COMBopts(string asis)                                ///
          TItle(string asis) SUBtitle(string asis)             ///
          Name(string)                                         ///
          SAVing(string asis)                                  ///
          noCOMBine KEEPGraphs noDOTS                          ///
          ID(varname) Bandwidth(real -1) LAGs(integer -1)       ///
          MM ONEstep NONMfallback SMOOTHWeight                 ///
          MINT(integer 5) WARNT(integer 20) noWARNings ]

    if ("`quantile'" == "") {
        local quantile 10 20 30 40 50 60 70 80 90
    }
    local nq : word count `quantile'
    if (`nq' < 2) {
        di as error "a coefficient path needs at least two quantiles"
        di as error "{p 4 4 2}{bf:quantile()} got `nq' value(s).  For a" ///
            " single quantile use {help xtpqgmm:xtpqgmm} and read the" ///
            " table.{p_end}"
        exit 198
    }
    if ("`name'" == "") local name xtpqgmm
    if (strpos("`name'", " ")) {
        di as error "{bf:name()} must be a single graph-name stub"
        exit 198
    }
    if ("`gformat'" == "") local gformat %5.0g
    if (substr("`gformat'", 1, 1) != "%") {
        di as error "{bf:gformat()} must be a Stata numeric format, e.g. %4.2f"
        exit 198
    }

    * The xtpqgmm options that are passed straight through, assembled once.
    local pass
    if ("`id'" != "")            local pass `pass' id(`id')
    if (`bandwidth' > 0)         local pass `pass' bandwidth(`bandwidth')
    if (`lags' >= 0)             local pass `pass' lags(`lags')
    if ("`mm'" != "")            local pass `pass' mm
    if ("`onestep'" != "")       local pass `pass' onestep
    if ("`nonmfallback'" != "")  local pass `pass' nonmfallback
    if ("`smoothweight'" != "")  local pass `pass' smoothweight
    local pass `pass' mint(`mint') warnt(`warnt') nowarnings

    local spec `lhs' `exog' (`endog' = `excl')

    * ------------------------------------------------------------- fit the path
    * Each quantile is a separate xtpqgmm call.  They could have been one call
    * with a numlist, but then a single failing tau would take the whole path
    * down; fitting them one at a time lets the path survive a gap and say so.
    tempname B
    tempfile path
    quietly postfile `B' double(tau b se lo hi) str32 vname using "`path'", replace

    local zcrit = invnormal(1 - (100-`level')/200)
    local nfail 0
    local failed
    local vlist

    if ("`dots'" == "") {
        di as text "Fitting `nq' quantiles " _c
    }
    foreach q of local quantile {
        local tau = `q'
        if (`tau' >= 1) local tau = `tau'/100

        capture quietly xtpqgmm `spec' `if' `in', quantile(`q') `pass'
        if (_rc) {
            local ++nfail
            local failed `failed' `q'
            if ("`dots'" == "") di as error "x" _c
            continue
        }
        if ("`dots'" == "") di as text "." _c

        local cn : colnames e(b)
        if ("`vlist'" == "") local vlist `cn'
        local j 0
        foreach v of local cn {
            local ++j
            local bj = el(e(b), 1, `j')
            local vj = el(e(V), `j', `j')
            local sj = sqrt(`vj')
            post `B' (`tau') (`bj') (`sj') ///
                (`bj' - `zcrit'*`sj') (`bj' + `zcrit'*`sj') ("`v'")
        }
    }
    quietly postclose `B'
    if ("`dots'" == "") di as text " done"

    if (`nfail' == `nq') {
        di as error "every quantile failed; nothing to plot"
        di as error "{p 4 4 2}Run {bf:xtpqgmm} at one of them on its own to" ///
            " see the error.{p_end}"
        exit 498
    }
    if (`nfail' > 0) {
        di as error "{p 0 2 2}Warning: `nfail' quantile(s) failed and are" ///
            " absent from the path: `failed'.  The line is drawn through" ///
            " the survivors, so a straight segment there is interpolation," ///
            " not an estimate.{p_end}"
    }

    * which coefficients to draw
    if ("`vars'" != "") {
        local draw
        foreach v of local vars {
            local hit : list v in vlist
            if (!`hit') {
                di as error "{bf:`v'} is not a coefficient of this model"
                di as error "{p 4 4 2}The model has: `vlist'.{p_end}"
                exit 111
            }
            local draw `draw' `v'
        }
    }
    else {
        local draw `vlist'
    }
    local nd : word count `draw'

    * ------------------------------------------------------------------ draw
    preserve
    quietly use "`path'", clear

    local yzeroopt yline(0, lcolor(gs10) lpattern(dash))
    if ("`yzero'" != "") local yzeroopt

    local names
    local k 0
    foreach v of local draw {
        local ++k
        local gname `name'_`k'
        capture quietly graph drop `gname'

        quietly count if vname == "`v'"
        if (r(N) == 0) continue

        if ("`ci'" == "") {
            local ciplot (rarea lo hi tau if vname == "`v'",      ///
                color(%30) lwidth(none) `ciopts')
            local cileg  `level'% pointwise CI
        }
        else {
            local ciplot
            local cileg
        }

        twoway `ciplot'                                           ///
            (line b tau if vname == "`v'",                        ///
                lwidth(medthick) `plotopts')                      ///
            , `yzeroopt'                                          ///
              ytitle("Coefficient on `v'")                        ///
              xtitle("Quantile {&tau}")                           ///
              ylabel(, format(`gformat') angle(horizontal) nogrid) ///
              xlabel(, format(%3.2f))                             ///
              legend(off)                                         ///
              title(`"`v'"', size(medium))                        ///
              name(`gname', replace) nodraw

        local names `names' `gname'
    }

    * ---------------------------------------------------------------- combine
    local ttl `"`title'"'
    if (`"`ttl'"' == "") {
        local ttl "Quantile coefficient path, SP-GMM"
    }
    local sttl `"`subtitle'"'
    if (`"`sttl'"' == "" & "`ci'" == "") {
        local sttl `"`level'% pointwise bands -- NOT uniform in {&tau}"'
    }

    if ("`combine'" == "" & `nd' > 1) {
        capture quietly graph drop `name'
        graph combine `names', name(`name', replace)   ///
            title(`"`ttl'"') subtitle(`"`sttl'"', size(small)) ///
            `combopts'
        local final `name'
        if ("`keepgraphs'" == "") {
            foreach g of local names {
                capture quietly graph drop `g'
            }
        }
    }
    else if (`nd' == 1) {
        * one coefficient: the single graph IS the result, so it takes the
        * name the user asked for and is the thing that gets shown
        local g : word 1 of `names'
        capture quietly graph drop `name'
        graph rename `g' `name', replace
        graph display `name'
        local final `name'
    }
    else {
        foreach g of local names {
            graph display `g'
        }
        local final `names'
    }

    * ------------------------------------------------------------------ save
    if (`"`saving'"' != "") {
        gettoken sfile srest : saving, parse(",")
        local sfile  = trim(`"`sfile'"')
        local srest  = trim(subinstr(`"`srest'"', ",", "", 1))
        local nfinal : word count `final'
        if (`nfinal' == 1) {
            graph save `final' `"`sfile'"', `srest'
        }
        else {
            * nocombine with several coefficients: one file per coefficient,
            * suffixed _1 _2 ... in the order of r(varlist)
            local k 0
            foreach g of local final {
                local ++k
                graph save `g' `"`sfile'_`k'"', `srest'
            }
        }
    }

    * ----------------------------------------------------------- return a table
    * The plotted numbers, so a user can re-draw them their own way or put
    * them in a table.  One row per (variable, tau), in the plotted order.
    * `matrix rownames' will not take an "eq:name" token, so -- exactly as in
    * xtpqgmm itself -- the equation goes on FIRST and the names after.
    tempname R
    quietly {
        generate long __ord = .
        local k 0
        foreach v of local draw {
            local ++k
            replace __ord = `k' if vname == "`v'"
        }
        drop if missing(__ord)
        sort __ord tau
    }
    mkmat tau b se lo hi, matrix(`R')
    matrix colnames `R' = tau b se lo hi
    local rq
    local rv
    forvalues r = 1/`=_N' {
        local rv `rv' `=vname[`r']'
        local rq `rq' q`=subinstr(string(100*tau[`r'], "%4.0f"), ".", "_", .)'
    }
    matrix roweq   `R' = `rv'
    matrix rownames `R' = `rq'
    restore

    return local  graph     `final'
    return local  varlist   `draw'
    return local  quantiles `quantile'
    return local  failed    `failed'
    return scalar n_q       = `nq'
    return scalar n_fail    = `nfail'
    return scalar level     = `level'
    return matrix path      = `R'

    di as text "{p 0 2 2}Bands are {bf:pointwise}.  Theorem 4.1 is a" ///
        " pointwise result; the paper supplies no uniform-in-{&tau} limit" ///
        " process, so these bands do {bf:not} support a test of whether the" ///
        " whole path is flat.  See" ///
        " {help xtpqgmm_methods##uniform:[methods] Uniform inference}.{p_end}"
end
