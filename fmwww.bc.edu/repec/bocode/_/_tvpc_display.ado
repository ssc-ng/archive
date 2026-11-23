*! _tvpc_display 1.0.0  21nov2026
*! Journal-style tables for tvpc and tvpcmci results
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
* ======================================================================
* display
* ======================================================================
program define _tvpc_display
    version 15.0
    syntax [, NOEDGEs NOLAGmap NOSUMmary]
    local nv = e(n_vars)
    local m  = e(lags)
    local s  = e(lagstep)
    local vl "`e(varlist)'"

    di
    di as text "{hline 78}"
    if ("`e(cmd)'" == "tvpc") {
        di as text "{bf:Time-variant Peter-Clark (TV-PC) causal discovery}"
        di as text "Aung, Zhu, Lee, Guo & Li (2026), {it:Computational Economics}"
        di as text "{hline 78}"
        di as text "CI test   : " as res "Fisher's z (Eq. 2.1)" ///
            as text _col(48) "Number of obs (u)  = " as res %8.0f e(N)
        di as text "PC variant: " as res "`e(variant)' (gCastle)" ///
            as text _col(48) "Variables (n)      = " as res %8.0f e(n_vars)
        di as text "alpha     : " as res %-9.4g e(alpha) ///
            as text _col(48) "Lags (m)           = " as res %8.0f e(lags)
        di as text "Contemp.  : " as res "`e(contemp)'" ///
            as text _col(48) "Lag step (periods) = " as res %8.0f e(lagstep)
        di as text "Restrict. : " as res "no self/lag-lag/current->lag" ///
            as text _col(48) "Nodes n(m+1)       = " as res %8.0f e(nodes)
        di as text "Pairs removed a priori = " as res e(n_forbid) ///
            as text _col(48) "CI tests run       = " as res %8.0f e(ntests)
        di as text _col(48) "Max cond. set |S|  = " as res %8.0f e(depth)
    }
    else {
        di as text "{bf:PCMCI benchmark (Runge et al. 2019), partial-correlation CI test}"
        di as text "As used for the comparison in Aung et al. (2026, Sec. 5, Table 1)"
        di as text "{hline 78}"
        di as text "CI test   : " as res "ParCorr (t test)" ///
            as text _col(48) "Number of obs (T')  = " as res %8.0f e(N)
        di as text "pc_alpha  : " as res %-9.4g e(pc_alpha) ///
            as text _col(48) "Variables (n)       = " as res %8.0f e(n_vars)
        di as text "alpha     : " as res %-9.4g e(alpha) ///
            as text _col(48) "tau_max             = " as res %8.0f e(lags)
        di as text "tau_min   : " as res e(tau_min) ///
            as text _col(48) "Lag step (periods)  = " as res %8.0f e(lagstep)
        di as text "PC1 parents (total) = " as res e(n_parents) ///
            as text _col(48) "CI tests run        = " as res %8.0f e(ntests)
    }
    di as text "Edges: " as res e(n_edges) as text " total;  " ///
        as res e(n_lagged) as text " lagged (X(t-k) -> Y(t));  " ///
        as res e(n_cdir) as text " contemp. directed;  " ///
        as res e(n_cund) as text " undirected"

    tempname L
    matrix `L' = e(links)
    local K = rowsof(`L')
    local hasstab = (e(reps) > 0)

    * ---------------------------------------------- edge table
    if ("`noedges'" == "" & `K' > 0 & `L'[1,1] < .) {
        di
        di as text "{bf:Table A. Causal links of the PDAG (grouped by effect variable)}"
        di as text "{hline 78}"
        if ("`e(cmd)'" == "tvpc") {
            di as text %-14s "Effect (t)" %-15s "Cause" %7s "Lag" %8s "Type" ///
                %9s "r(marg)" %9s "|r|min" %9s "p max" _c
        }
        else {
            di as text %-14s "Effect (t)" %-15s "Cause" %7s "Lag" %8s "Type" ///
                %9s "MCI r" %9s "PC1|r|" %9s "MCI p" _c
        }
        if (`hasstab') di as text %7s "Stab%"
        else di
        di as text "{hline 78}"
        local last 0
        forvalues k = 1/`K' {
            local j  = `L'[`k',1]
            local c  = `L'[`k',2]
            local lg = `L'[`k',3]
            local ty = `L'[`k',5]
            local ef : word `j' of `vl'
            local ca : word `c' of `vl'
            if (`j' != `last') {
                local efd = abbrev("`ef'", 13)
                if (`last' != 0) di as text "{hline 78}"
            }
            else local efd ""
            local last = `j'
            if (`lg' == 0) local lgd "t"
            else local lgd "t-`lg'"
            if (`ty' == 1) local tyd "-->"
            if (`ty' == 2) local tyd "-->"
            if (`ty' == 3) local tyd "---"
            local pm = `L'[`k',8]
            di as text %-14s "`efd'" as res %-15s abbrev("`ca'", 14) ///
                %7s "`lgd'" %8s "`tyd'" %9.3f `L'[`k',6] %9.3f `L'[`k',7] ///
                %9.4f `pm' _c
            if (`hasstab') di as res %7.1f 100 * `L'[`k',9]
            else di
        }
        di as text "{hline 78}"
        di as text "Lag t-k = k steps of e(lagstep) = `s' period(s). --> directed; --- undirected."
        if ("`e(cmd)'" == "tvpc") {
            di as text "r(marg): marginal correlation; |r|min: weakest |partial r| over all CI tests;"
            di as text "p max: largest Fisher-z p-value over all tests (edge kept since all p < alpha)."
        }
        else {
            di as text "MCI r / MCI p: momentary conditional independence partial correlation and"
            di as text "p-value (larger of the two for contemporaneous pairs); PC1|r|: weakest"
            di as text "|partial r| of the lagged parent in the PC1 condition-selection stage."
        }
        if (`hasstab') di as text "Stab%: share of " e(reps) " moving-block bootstrap PDAGs containing the link (block = " e(blocklen) ")."
    }

    * ---------------------------------------------- lag-link matrix
    if ("`nolagmap'" == "") {
        di
        di as text "{bf:Table B. Lag-link matrix: cause (rows) -> effect at time t (columns)}"
        di as text "cell = lags k of cause(t-k) driving effect(t); 0 = contemporaneous directed,"
        di as text "u = contemporaneous undirected; . = no link"
        local w = 8
        local nblk = ceil(`nv' / 7)
        forvalues b = 1/`nblk' {
            local c1 = (`b' - 1) * 7 + 1
            local c2 = min(`nv', `b' * 7)
            local wid = 14 + (`c2' - `c1' + 1) * `w'
            di as text "{hline `wid'}"
            di as text %-14s "cause \ effect" _c
            forvalues j = `c1'/`c2' {
                local ef : word `j' of `vl'
                di as text %`w's abbrev("`ef'", `w' - 1) _c
            }
            di
            di as text "{hline `wid'}"
            forvalues c = 1/`nv' {
                local ca : word `c' of `vl'
                di as text %-14s abbrev("`ca'", 13) _c
                forvalues j = `c1'/`c2' {
                    local cell ""
                    forvalues k = 1/`K' {
                        if (`L'[`k',1] == `j' & `L'[`k',2] == `c') {
                            if (`L'[`k',5] == 3) local cell "`cell'u"
                            else local cell "`cell'`=`L'[`k',3]'"
                        }
                    }
                    if ("`cell'" == "") local cell "."
                    if (length("`cell'") > `w' - 1) local cell "#`=length("`cell'")'"
                    di as res %`w's "`cell'" _c
                }
                di
            }
            di as text "{hline `wid'}"
        }
    }

    * ---------------------------------------------- variable summary
    if ("`nosummary'" == "") {
        tempname D
        matrix `D' = e(degree)
        di
        di as text "{bf:Table C. Causal relationship summary by variable}"
        di as text "{hline 78}"
        di as text %-16s "Variable" %10s "In-links" %10s "Out-links" ///
            %10s "Drivers" %10s "Driven" %11s "Own lags" %11s "Autoreg."
        di as text "{hline 78}"
        forvalues j = 1/`nv' {
            local v : word `j' of `vl'
            local ar = cond(`D'[`j',5] > 0, "yes", "no")
            di as text %-16s abbrev("`v'", 15) as res %10.0f `D'[`j',1] ///
                %10.0f `D'[`j',2] %10.0f `D'[`j',3] %10.0f `D'[`j',4] ///
                %11.0f `D'[`j',5] %11s "`ar'"
        }
        di as text "{hline 78}"
        di as text "In-links: links into X(t); Out-links: links from X(t-k) or X(t) into other"
        di as text "variables at t; Drivers/Driven: distinct variables; Own lags: X(t-k)->X(t)."
    }

    * ---------------------------------------------- scoring
    capture confirm scalar e(F1)
    if (!_rc) {
        di
        di as text "{bf:Table D. Accuracy against the supplied ground truth}"
        di as text "{hline 78}"
        di as text "True links = " as res e(n_true) as text "   Estimated (nnz) = " as res e(nnz)  ///
            as text "   TP = " as res e(TP) as text "   reversed = " as res e(reversed)
        di as text "Precision = " as res %6.4f e(precision) as text "   Recall = " ///
            as res %6.4f e(recall) as text "   F1 = " as res %6.4f e(F1) ///
            as text "   SHD = " as res e(shd)
        di as text "Skeleton F1 = " as res %6.4f e(F1_skel) ///
            as text "   (gCastle MetricsDAG conventions; undirected edges count twice in nnz)"
        di as text "{hline 78}"
    }

    * ---------------------------------------------- strength
    capture confirm matrix e(strength)
    if (!_rc) {
        tempname S
        matrix `S' = e(strength)
        di
        di as text "{bf:Table E. Strength of causal links (extension): OLS of standardised Y(t) on its parents}"
        di as text "{hline 78}"
        di as text %-14s "Effect (t)" %-15s "Cause" %6s "Lag" %10s "Coef." ///
            %9s "Std.err" %8s "t" %8s "P>|t|" %10s "R2"
        di as text "{hline 78}"
        local last 0
        forvalues r = 1/`=rowsof(`S')' {
            local j = `S'[`r',1]
            local ef : word `j' of `vl'
            local ca : word `=`S'[`r',2]' of `vl'
            if (`j' != `last') local efd = abbrev("`ef'", 13)
            else local efd ""
            if (`j' != `last' & `last' != 0) di as text "{hline 78}"
            local lg = `S'[`r',3]
            local lgd = cond(`lg' == 0, "t", "t-`lg'")
            local pv = `S'[`r',7]
            local st = cond(`pv' < .01, "***", cond(`pv' < .05, "**", cond(`pv' < .1, "*", "")))
            local r2d = cond(`j' != `last', string(`S'[`r',8], "%5.3f"), "")
            local last = `j'
            di as text %-14s "`efd'" as res %-15s abbrev("`ca'", 14) %6s "`lgd'" ///
                %10.4f `S'[`r',4] %9.4f `S'[`r',5] %8.2f `S'[`r',6] %8.4f `pv' ///
                " " %-4s "`st'" %5s "`r2d'"
        }
        di as text "{hline 78}"
        di as text "*** p<0.01, ** p<0.05, * p<0.1. Standardised coefficients; the PDAG is taken"
        di as text "as given (post-selection inference: p-values are descriptive)."
    }
end

