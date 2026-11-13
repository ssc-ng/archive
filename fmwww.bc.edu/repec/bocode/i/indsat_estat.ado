*! indsat_estat 1.0.0  12nov2026
*! postestimation for indsat: dates path plot test outlier distort biascorr bias forecast diag
*! Author: Dr Merwan Roudane  (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane

program define indsat_estat, rclass
    version 14.0
    if ("`e(cmd)'"!="indsat") {
        di as err "last estimates not found; run {bf:indsat} first"
        exit 301
    }
    gettoken sub rest : 0, parse(" ,")
    local sub = lower("`sub'")
    if ("`sub'"=="dates" | "`sub'"=="breaks") {
        indsat_estat_dates `rest'
    }
    else if ("`sub'"=="path") {
        indsat_estat_path `rest'
    }
    else if ("`sub'"=="plot" | "`sub'"=="graph") {
        indsat_estat_plot `rest'
    }
    else if ("`sub'"=="test" | "`sub'"=="isattest") {
        indsat_estat_test `rest'
    }
    else if ("`sub'"=="outlier" | "`sub'"=="outliertest") {
        indsat_estat_outlier `rest'
    }
    else if ("`sub'"=="distort" | "`sub'"=="distorttest") {
        indsat_estat_distort `rest'
    }
    else if ("`sub'"=="biascorr" | "`sub'"=="bc") {
        indsat_estat_biascorr `rest'
    }
    else if ("`sub'"=="bias" | "`sub'"=="constancy") {
        indsat_estat_bias `rest'
    }
    else if ("`sub'"=="forecast" | "`sub'"=="fcast") {
        indsat_estat_forecast `rest'
    }
    else if ("`sub'"=="diag" | "`sub'"=="diagnostics") {
        indsat_estat_diag `rest'
    }
    else if ("`sub'"=="ic" | "`sub'"=="summarize" | "`sub'"=="vce") {
        estat_default `0'
        exit
    }
    else {
        di as err "unknown estat subcommand {bf:`sub'}"
        di as err "valid: dates path plot test outlier distort biascorr bias forecast diag"
        exit 198
    }
    return add
end

* ---------------------------------------------------------------------
* helper: date label for a time value
program define indsat_tstr, rclass
    args t
    if ("`e(timevar)'"=="_n") {
        return local s "`t'"
        exit
    }
    local s : display `e(tsfmt)' `t'
    return local s = trim("`s'")
end

* ---------------------------------------------------------------------
program define indsat_estat_dates, rclass
    syntax [, COMPact]
    tempname B
    matrix `B' = e(breaks)
    local k = rowsof(`B')
    local rn : rownames `B'
    if (e(nret)==0) {
        di as text "(no indicators retained)"
        exit
    }
    local tl "IIS SIS TIS MIS UIS BIS QIS CIS DIS PIS"
    local tn `""impulse" "step shift" "broken trend" "coef. shift" "user ind." "designed break" "broken quad." "broken cubic" "diff. impulse" "pair impulse""'
    di
    di as text "{bf:Detected outliers and breaks}" _col(52) "(retained at p < " %6.4f e(tpval) ")"
    di as text "{hline 78}"
    di as text %3s "#" "  " %-16s "Indicator" %-15s "Type" %12s "Date" %10s "Coef." %9s "Std.err." %7s "t" %8s "p"
    di as text "{hline 78}"
    forvalues j = 1/`k' {
        local nm : word `j' of `rn'
        local ty = `B'[`j',1]
        local tyn : word `ty' of `tn'
        indsat_tstr `=`B'[`j',3]'
        local ds "`r(s)'"
        local p = `B'[`j',7]
        local st ""
        if (`p'<0.10) local st "*"
        if (`p'<0.05) local st "**"
        if (`p'<0.01) local st "***"
        di as text %3.0f `j' "  " as res %-16s abbrev("`nm'",16) as text %-15s "`tyn'" as res %12s "`ds'" ///
            %10.4g `B'[`j',4] %9.4g `B'[`j',5] %7.2f `B'[`j',6] %8.4f `p' as text " `st'"
    }
    di as text "{hline 78}"
    if ("`e(sisform)'"=="down" & e(nsis)>0) {
        di as text "Step indicators are 1(t<=date): the coefficient is the level up to the date relative to after it."
    }
    else if (e(nsis)+e(nmis)>0) {
        di as text "Step indicators are 1(t>=date): the coefficient is the shift that starts at the date."
    }
    return matrix breaks = `B', copy
    if ("`compact'"!="") exit

    * regime table of the deterministic (intercept) path at the step dates
    capture noisily indsat_estat_path, nodisplay
    if (_rc) exit
    tempname P
    matrix `P' = r(path)
    local n = rowsof(`P')
    local cuts ""
    forvalues j = 1/`k' {
        local ty = `B'[`j',1]
        if inlist(`ty',2,4) {
            local o = `B'[`j',2]
            if ("`e(sisform)'"=="down" & `ty'==2) local o = `o' + 1
            if (`o'>1 & `o'<=`n') local cuts "`cuts' `o'"
        }
    }
    local cuts : list uniq cuts
    local cuts : list sort cuts
    if ("`cuts'"=="") exit
    numlist "`cuts'", sort
    local cuts "`r(numlist)'"
    di
    di as text "{bf:Regimes implied by the step indicators} (intercept path, held at regime start)"
    di as text "{hline 66}"
    di as text %8s "Regime" %14s "From" %14s "To" %14s "Level" %12s "Std.err."
    di as text "{hline 66}"
    local start 1
    local r 0
    local cuts "`cuts' `=`n'+1'"
    foreach c of local cuts {
        local ++r
        local stop = `c' - 1
        indsat_tstr `=`P'[`start',1]'
        local s1 "`r(s)'"
        indsat_tstr `=`P'[`stop',1]'
        local s2 "`r(s)'"
        di as text %8.0f `r' as res %14s "`s1'" %14s "`s2'" %14.5g `P'[`start',2] %12.5g `P'[`start',3]
        local start = `c'
    }
    di as text "{hline 66}"
end

* ---------------------------------------------------------------------
* coefficient (deterministic) path: constant + IIS/SIS/TIS/BIS/QIS/CIS/DIS/PIS/UIS contributions
program define indsat_estat_path, rclass
    syntax [, GENerate(string) Level(cilevel) LR noDISplay MIS ]
    tempname P M
    mata: indsate_path("`P'", "`lr'"!="")
    if ("`display'"=="") {
        di as text "Coefficient path of the intercept (deterministic part) computed; see r(path)."
        di as text "Columns: time, path, se, lower, upper" cond("`lr'"!="", ", long-run path, se", "")
    }
    if ("`generate'"!="") {
        tempvar es
        qui gen byte `es' = e(sample)
        capture drop `generate' `generate'_se
        qui gen double `generate' = .
        qui gen double `generate'_se = .
        mata: indsate_store("`P'", "`generate'", "`es'")
        label var `generate' "indsat intercept path"
        label var `generate'_se "indsat intercept path s.e."
    }
    if ("`e(misvars)'"!="") {
        mata: indsate_mispath("`M'")
        return matrix mispath = `M'
    }
    return matrix path = `P'
end

* ---------------------------------------------------------------------
program define indsat_estat_plot
    syntax [, NAME(string) noCOMBine SAVing(string) TItle(string) Level(cilevel) ]
    if ("`name'"=="") local name "indsat_dash"
    local y "`e(depvar)'"
    tempname R P T B
    matrix `R' = e(resid)
    matrix `T' = e(tvals)
    matrix `B' = e(breaks)
    qui indsat_estat_path, nodisplay
    matrix `P' = r(path)
    local hasmis = ("`e(misvars)'"!="")
    if (`hasmis') {
        tempname M
        matrix `M' = r(mispath)
    }
    local crit = e(crit)
    local sig = e(sigma)
    * step / break dates for xlines
    local xl ""
    if (e(nret)>0) {
        forvalues j = 1/`=rowsof(`B')' {
            if inlist(`B'[`j',1],2,3,4,6,7,8) local xl "`xl' `=`B'[`j',3]'"
        }
    }
    local xlopt ""
    if ("`xl'"!="") local xlopt "xline(`xl', lcolor(gs10) lpattern(dash) lwidth(thin))"
    local tf "`e(tsfmt)'"
    if ("`e(timevar)'"=="_n") local tf "%9.0g"
    preserve
    qui {
        clear
        svmat double `T', name(tt)
        rename tt1 time
        svmat double `R', name(rr)
        rename (rr1 rr2 rr3) (actual fitted resid)
        svmat double `P', name(pp)
        rename (pp1 pp2 pp3 pp4 pp5) (ptime path pse plo phi)
        gen double zres = resid/`sig'
        gen double crit_hi = `crit'
        gen double crit_lo = -`crit'
        gen byte outl = abs(zres) > `crit'
        gen double zero = 0
        format time `tf'
    }
    qui summarize time, meanonly
    local tmin = r(min)
    local tmax = r(max)
    local gopt "graphregion(color(white)) plotregion(color(white)) ylabel(, angle(0) labsize(small) nogrid) xscale(range(`tmin' `tmax')) xlabel(#6, labsize(small)) legend(rows(1) size(small) position(6) region(lcolor(white)))"
    twoway (line actual time, lcolor(navy) lwidth(medthin)) ///
           (line fitted time, lcolor(maroon) lwidth(medthin) lpattern(solid)), ///
           `xlopt' title("(a) Actual and fitted: `y'", size(medsmall)) ytitle("") xtitle("") ///
           legend(order(1 "Actual" 2 "Fitted")) `gopt' name(indsat_g1, replace) nodraw
    twoway (rspike zero zres time if outl, lcolor(cranberry) lwidth(medthick)) ///
           (scatter zres time, msymbol(circle) msize(vsmall) mcolor(navy)) ///
           (line crit_hi time, lcolor(gs8) lpattern(dash)) (line crit_lo time, lcolor(gs8) lpattern(dash)), ///
           yline(0, lcolor(gs12)) title("(b) Scaled residuals with {&plusminus}c{sub:{&alpha}} bands", size(medsmall)) ///
           ytitle("") xtitle("") legend(order(2 "Residual/{&sigma}" 3 "{&plusminus}c{sub:{&alpha}}")) `gopt' name(indsat_g2, replace) nodraw
    * the actual series is on the same scale as the path only in location models (no regressors)
    if (e(k_x)==0 & "`e(ar)'"=="") {
        twoway (rarea plo phi time, color(navy%20) lwidth(none)) ///
               (line actual time, lcolor(gs10) lwidth(thin)) ///
               (line path time, lcolor(navy) lwidth(medthick)), ///
               `xlopt' title("(c) Intercept path with `level'% band", size(medsmall)) ytitle("") xtitle("") ///
               legend(order(3 "Path" 1 "`level'% CI" 2 "Actual")) `gopt' name(indsat_g3, replace) nodraw
    }
    else {
        twoway (rarea plo phi time, color(navy%20) lwidth(none)) ///
               (line path time, lcolor(navy) lwidth(medthick)), ///
               `xlopt' title("(c) Intercept path (constant + indicators), `level'% band", size(medsmall)) ytitle("") xtitle("") ///
               legend(order(2 "Path" 1 "`level'% CI")) `gopt' name(indsat_g3, replace) nodraw
    }
    local g4 ""
    if (`hasmis') {
        qui svmat double `M', name(mm)
        local nc = colsof(`M')
        local mv "`e(misvars)'"
        local pl ""
        local lg ""
        local cols "maroon forest_green dkorange purple teal"
        local i 0
        forvalues c = 2(3)`nc' {
            local ++i
            local cc : word `i' of `cols'
            local v : word `i' of `mv'
            local c2 = `c' + 1
            local c3 = `c' + 2
            local pl "`pl' (rarea mm`c2' mm`c3' time, color(`cc'%15) lwidth(none)) (line mm`c' time, lcolor(`cc') lwidth(medthick))"
            local o = 2*`i'
            local lg `"`lg' `o' "`v'""'
        }
        twoway `pl', `xlopt' title("(d) Coefficient paths (MIS)", size(medsmall)) ytitle("") xtitle("") ///
            legend(order(`lg')) `gopt' name(indsat_g4, replace) nodraw
        local g4 "indsat_g4"
    }
    else {
        * (d) timeline of retained indicators: coefficient at its date, by type
        if (e(nret)>0) {
            qui svmat double `B', name(bk)
            qui gen double bzero = 0
            format bk3 `tf'
            twoway (rspike bzero bk4 bk3 if bk1==1, lcolor(cranberry) lwidth(medthick)) ///
                   (scatter bk4 bk3 if bk1==1, msymbol(O) mcolor(cranberry)) ///
                   (rspike bzero bk4 bk3 if inlist(bk1,2,4), lcolor(navy) lwidth(medthick)) ///
                   (scatter bk4 bk3 if inlist(bk1,2,4), msymbol(S) mcolor(navy)) ///
                   (rspike bzero bk4 bk3 if !inlist(bk1,1,2,4), lcolor(forest_green) lwidth(medthick)) ///
                   (scatter bk4 bk3 if !inlist(bk1,1,2,4), msymbol(D) mcolor(forest_green)), ///
                   yline(0, lcolor(gs10)) title("(d) Retained indicators: timing and size", size(medsmall)) ///
                   ytitle("") xtitle("") legend(order(2 "Impulse" 4 "Step / MIS" 6 "Trend / designed")) `gopt' name(indsat_g4, replace) nodraw
        }
        else {
            twoway (scatter zres time, msymbol(none)), title("(d) No indicators retained", size(medsmall)) ///
                ytitle("") xtitle("") legend(off) `gopt' name(indsat_g4, replace) nodraw
        }
        local g4 "indsat_g4"
    }
    restore
    if ("`title'"=="") local title "Indicator saturation: `e(saturation)' (p = `=e(tpval)')"
    if ("`combine'"=="") {
        graph combine indsat_g1 indsat_g2 indsat_g3 `g4', cols(2) graphregion(color(white)) ///
            title("`title'", size(medium)) name(`name', replace) iscale(0.6)
        if ("`saving'"!="") graph export "`saving'", replace
    }
    else {
        foreach g in indsat_g1 indsat_g2 indsat_g3 `g4' {
            graph display `g'
        }
    }
end

* ---------------------------------------------------------------------
* isattest (gets): Pretis (2016) / Pretis, Schneider, Smerdon & Hendry: test path against hnull
program define indsat_estat_test, rclass
    syntax [, HNull(real 0) CIPval(real 0.99) BIAScorr LR GRaph NAME(string) ]
    if ("`name'"=="") local name "indsat_test"
    if (strpos("`e(saturation)'","TIS")) di as text "note: TIS included; path variance is exact (a't V a_t), an extension of gets::isattest"
    if ("`biascorr'"!="" & (e(k_x)>0 | "`e(ar)'"!="")) {
        di as text "note: bias correction not applicable with covariates or AR terms (as in gets); biascorr ignored"
        local biascorr ""
    }
    tempname P
    mata: indsate_path("`P'", "`lr'"!="")
    mata: indsate_isattest("`P'", `hnull', `cipval', "`biascorr'"!="", "`lr'"!="")
    tempname O
    matrix `O' = r(pathtest)
    local n = rowsof(`O')
    di
    di as text "{bf:Test of the coefficient path against H0: path = `hnull'}" cond("`lr'"!=""," (long-run path)","")
    tempname bb
    matrix `bb' = e(b)
    local dfp = e(N) - colsof(`bb')
    local crt = r(crit)
    di as text "CI coverage = " %4.2f `cipval' ", critical value t(`dfp') = " %6.3f `crt' cond("`biascorr'"!="", ", 2-step bias corrected", "")
    di as text "{hline 66}"
    di as text %8s "Episode" %14s "From" %14s "To" %8s "Obs" %10s "Mean bias" %10s "Sign"
    di as text "{hline 66}"
    local ep 0
    local inn 0
    local sum 0
    local cnt 0
    forvalues t = 1/`n' {
        local bb = `O'[`t',5] + `O'[`t',6]
        if (`bb'!=0 & !`inn') {
            local inn 1
            local start `t'
            local sum 0
            local cnt 0
            local sg = sign(`bb')
        }
        if (`inn' & (`bb'==0 | sign(`bb')!=`sg')) {
            local ++ep
            indsat_tstr `=`O'[`start',1]'
            local s1 "`r(s)'"
            indsat_tstr `=`O'[`t'-1,1]'
            local s2 "`r(s)'"
            di as text %8.0f `ep' as res %14s "`s1'" %14s "`s2'" %8.0f `cnt' %10.4g `sum'/`cnt' %10s cond(`sg'>0,"above","below")
            local inn 0
            if (`bb'!=0) {
                local inn 1
                local start `t'
                local sum 0
                local cnt 0
                local sg = sign(`bb')
            }
        }
        if (`inn') {
            local sum = `sum' + `bb'
            local ++cnt
        }
    }
    if (`inn') {
        local ++ep
        indsat_tstr `=`O'[`start',1]'
        local s1 "`r(s)'"
        indsat_tstr `=`O'[`n',1]'
        local s2 "`r(s)'"
        di as text %8.0f `ep' as res %14s "`s1'" %14s "`s2'" %8.0f `cnt' %10.4g `sum'/`cnt' %10s cond(`sg'>0,"above","below")
    }
    if (`ep'==0) di as text "  (no period in which the path differs significantly from H0)"
    di as text "{hline 66}"
    return scalar episodes = `ep'
    return scalar crit = `crt'
    if ("`graph'"!="") {
        local tf "`e(tsfmt)'"
        if ("`e(timevar)'"=="_n") local tf "%9.0g"
        tempname R
        matrix `R' = e(resid)
        preserve
        qui {
            clear
            svmat double `O', name(o)
            rename (o1 o2 o3 o4 o5 o6) (time path lo hi biaslo biashi)
            svmat double `R', name(r)
            gen double bias = biaslo + biashi
            format time `tf'
        }
        qui summarize time, meanonly
        local gopt "graphregion(color(white)) plotregion(color(white)) ylabel(, angle(0) labsize(small) nogrid) xscale(range(`r(min)' `r(max)')) xlabel(#6, labsize(small)) legend(rows(1) size(small) position(6) region(lcolor(white)))"
        twoway (line r1 time, lcolor(gs11)) (line path time, lcolor(cranberry) lwidth(medthick)) ///
            (line lo time, lcolor(cranberry) lpattern(dash)) (line hi time, lcolor(cranberry) lpattern(dash)), ///
            yline(`hnull', lcolor(black) lpattern(shortdash)) title("Coefficient path and H0", size(medsmall)) ///
            xtitle("") ytitle("") legend(order(1 "Actual" 2 "Path" 3 "`=100*`cipval''% CI")) `gopt' name(indsat_t1, replace) nodraw
        twoway (bar bias time, color(cranberry%80) lwidth(none)), yline(0, lcolor(gs8)) ///
            title("Significant bias relative to H0", size(medsmall)) xtitle("") ytitle("") legend(off) `gopt' name(indsat_t2, replace) nodraw
        restore
        graph combine indsat_t1 indsat_t2, cols(1) graphregion(color(white)) name(`name', replace) iscale(0.8)
    }
    return matrix pathtest = `O'
end

* ---------------------------------------------------------------------
program define indsat_estat_outlier, rclass
    syntax [, ALTernative(string)]
    if (!strpos("`e(saturation)'","IIS")) {
        di as err "the outlier tests require impulse indicators ({bf:iis})"
        exit 198
    }
    if ("`alternative'"=="") local alternative "two.sided"
    if (e(nsis)+e(ntis)+e(nuis)+e(nmis)+e(nbis)>0 | "`e(saturation)'"!="IIS") {
        di as text "note: the Jiao-Pretis tests are derived for IIS alone; with other indicators they are indicative"
    }
    local n = e(N)
    local a = e(tpval)
    local no = e(niis)
    mata: st_numscalar("r(sd)", sqrt(indsate_vargauge(`a', `n', 1)))
    local sd = r(sd)
    local z = (`no'/`n' - `a')/`sd'
    if ("`alternative'"=="less") local p = normal(`z')
    else if ("`alternative'"=="greater") local p = 1 - normal(`z')
    else local p = 2*normal(-abs(`z'))
    mata: st_numscalar("r(pc)", indsate_poistest(`no', `a'*`n', "`alternative'"))
    local pc = r(pc)
    di
    di as text "{bf:Jiao-Pretis tests for the proportion of outliers} (H0: no outliers; gauge = tpval)"
    di as text "{hline 70}"
    di as text "Detected outliers (IIS)          = " as res %8.0f `no' as text "   out of T = " as res `n'
    di as text "Empirical gauge                  = " as res %8.5f `no'/`n' as text "   null gauge = " as res %7.5f `a'
    di as text "Asymptotic s.e. of the gauge     = " as res %8.5f `sd' as text "   (Johansen-Nielsen 2016, m = 1)"
    di as text "{hline 70}"
    di as text "Outlier proportion test  z       = " as res %8.4f `z' as text "   p-value = " as res %6.4f `p'
    di as text "Outlier count test (Poisson)     = " as res %8.0f `no' as text "   p-value = " as res %6.4f `pc' as text "   (E = " %5.2f `a'*`n' ")"
    di as text "{hline 70}"
    di as text "alternative: `alternative'"
    return scalar z = `z'
    return scalar p = `p'
    return scalar count = `no'
    return scalar p_count = `pc'
    return scalar gauge = `no'/`n'
    return scalar sd = `sd'
end

* ---------------------------------------------------------------------
program define indsat_estat_distort, rclass
    syntax [, BOOT(integer 0) SEED(string) CLEAN noDOTS]
    if ("`e(saturation)'"!="IIS") {
        di as err "the distortion test is defined for IIS alone (re-estimate with {bf:iis} only)"
        exit 198
    }
    if (e(k_x)==0 & e(cons)==0) {
        di as err "no regressors to compare"
        exit 198
    }
    mata: indsate_distort()
    local chi = r(chi2)
    local df = r(df)
    local p = r(p)
    tempname D
    matrix `D' = r(diff)
    di
    di as text "{bf:Jiao-Pretis-Schwarz outlier distortion test}"
    di as text "H0: OLS and IIS (robust) estimates of the regressors coincide"
    di as text "{hline 66}"
    di as text %18s "Regressor" %14s "IIS" %14s "OLS" %14s "Difference"
    di as text "{hline 66}"
    local cn : rownames `D'
    local j 0
    foreach c of local cn {
        local ++j
        di as text %18s abbrev("`c'",18) as res %14.5g `D'[`j',1] %14.5g `D'[`j',2] %14.5g `D'[`j',3]
    }
    di as text "{hline 66}"
    di as text "chi2(" as res `df' as text ") = " as res %9.4f `chi' as text "   p-value = " as res %6.4f `p'
    return scalar chi2 = `chi'
    return scalar df = `df'
    return scalar p = `p'
    return matrix diff = `D'
    if (`boot'>0) {
        * bootstrap on the clean sample (gets::distorttestboot, clean.sample=TRUE)
        if ("`seed'"!="") set seed `seed'
        tempname X R BT
        matrix `X' = e(X)
        matrix `R' = e(resid)
        local tp = e(tpval)
        local xv "`e(xret)'"
        local nx : word count `xv'
        local cons = e(cons)
        local n = e(N)
        mata: indsate_cleanidx()
        tempname est
        _estimates hold `est', restore
        matrix `BT' = J(`boot',1,.)
        if ("`dots'"=="") di as text "bootstrap replications (`boot'): " _c
        preserve
        forvalues b = 1/`boot' {
            qui {
                clear
                mata: indsate_bootdata("`X'", "`R'", `nx', `cons')
                gen t = _n
                tsset t
                local xl ""
                forvalues j = 1/`nx' {
                    local xl "`xl' bx`j'"
                }
                capture indsat by `xl', iis tpval(`tp') `=cond(`cons',"","noconstant")' nodates notable noheader
            }
            if (_rc==0) {
                capture mata: indsate_distort()
                if (_rc==0) matrix `BT'[`b',1] = r(chi2)
            }
            if ("`dots'"=="") di as text "." _c
        }
        restore
        if ("`dots'"=="") di
        mata: st_numscalar("r(pb)", mean((st_matrix("`BT'") :>= `chi') :* (st_matrix("`BT'") :< .)) / mean(st_matrix("`BT'") :< .))
        local pb = r(pb)
        mata: st_matrix("r(q)", mm_quantile_isat(st_matrix("`BT'")))
        tempname Q
        matrix `Q' = r(q)
        di as text "Bootstrap (clean sample, B = `boot'): p-value = " as res %6.4f `pb' ///
           as text "   90/95/99% quantiles = " as res %7.3f `Q'[1,1] " " %7.3f `Q'[1,2] " " %7.3f `Q'[1,3]
        return scalar p_boot = `pb'
        return matrix boot = `BT'
    }
end

* ---------------------------------------------------------------------
program define indsat_estat_biascorr, rclass
    if (e(nret)==0) {
        di as text "(no indicators retained)"
        exit
    }
    tempname B C
    matrix `B' = e(breaks)
    mata: indsate_biascorr("`B'", "`C'")
    local rn : rownames `B'
    local k = rowsof(`B')
    di
    di as text "{bf:Bias correction of retained indicator coefficients} (Hendry-Krolzig 2005; Pretis 2018)"
    di as text "c_alpha = t(T) quantile at tpval = " %6.4f e(tpval) ";  1-step and 2-step corrections of the truncated estimator"
    di as text "{hline 66}"
    di as text %16s "Indicator" %12s "Date" %12s "Estimate" %12s "1-step" %12s "2-step"
    di as text "{hline 66}"
    forvalues j = 1/`k' {
        local nm : word `j' of `rn'
        indsat_tstr `=`B'[`j',3]'
        di as res %16s abbrev("`nm'",16) %12s "`r(s)'" %12.5g `C'[`j',1] %12.5g `C'[`j',2] %12.5g `C'[`j',3]
    }
    di as text "{hline 66}"
    matrix rownames `C' = `rn'
    matrix colnames `C' = beta beta_1step beta_2step
    return matrix biascorr = `C'
end

* ---------------------------------------------------------------------
* Ericsson-type test: retained indicators (and optionally the constant) jointly zero
program define indsat_estat_bias, rclass
    syntax [, CONStant]
    local ind "`e(retained)'"
    local tl ""
    if ("`constant'"!="" & e(cons)==1) local tl "_cons"
    foreach v of local ind {
        local tl "`tl' `v'"
    }
    if ("`tl'"=="") {
        di as text "(nothing to test: no indicators retained)"
        exit
    }
    qui test `tl'
    di
    if ("`constant'"!="") di as text "{bf:Forecast-bias test} (Ericsson & Reisman 2012): constant and retained indicators = 0"
    else di as text "{bf:Constancy test}: all retained indicators jointly = 0"
    di as text "{hline 60}"
    di as text "F(" as res r(df) as text ", " as res r(df_r) as text ") = " as res %9.4f r(F) as text "    p-value = " as res %6.4f r(p)
    di as text "{hline 60}"
    di as text "note: indicators were selected on the same data; the test is conditional on selection."
    return scalar F = r(F)
    return scalar df = r(df)
    return scalar df_r = r(df_r)
    return scalar p = r(p)
end

* ---------------------------------------------------------------------
program define indsat_estat_forecast, rclass
    syntax [, H(integer 8) GENerate(string) Level(cilevel) INTercept GRaph NAME(string) ]
    if ("`generate'"=="") local generate "indsat_f"
    if ("`name'"=="") local name "indsat_fc"
    if ("`e(timevar)'"=="_n") {
        di as err "forecasting requires {bf:tsset} data"
        exit 459
    }
    local tv "`e(timevar)'"
    tempname T
    matrix `T' = e(tvals)
    local tend = `T'[rowsof(`T'),1]
    qui count if `tv' > `tend' & `tv' <= `tend' + `h'*`=cond(r(tdelta)<.,1,1)'
    qui tsset
    local delta = r(tdelta)
    qui count if `tv' > `tend' & `tv' <= `tend' + `h'*`delta'
    if (r(N) < `h') {
        if ("`e(xret)'"!="" | "`e(uisvars)'"!="") {
            di as err "the data do not contain `h' periods after the estimation sample;"
            di as err "use {bf:tsappend} and fill in the future values of the regressors"
            exit 198
        }
        local add = `h' - r(N)
        qui tsappend, add(`add')
        di as text "(`add' observations appended with tsappend)"
    }
    capture drop `generate' `generate'_lo `generate'_hi `generate'_se
    qui gen double `generate' = .
    qui gen double `generate'_se = .
    qui gen double `generate'_lo = .
    qui gen double `generate'_hi = .
    mata: indsate_forecast(`h', `delta', "`generate'", `level', "`intercept'"!="")
    label var `generate' "indsat forecast of `e(depvar)'"
    label var `generate'_lo "lower `level'% forecast band"
    label var `generate'_hi "upper `level'% forecast band"
    tempname F
    matrix `F' = r(fc)
    di
    di as text "{bf:Forecasts from the indsat model}" cond("`intercept'"!="", " with intercept correction (last residual)", "")
    di as text "Impulses end in-sample; step shifts persist; broken trends extrapolate; AR terms iterate."
    di as text "{hline 64}"
    di as text %12s "Date" %4s "h" %14s "Forecast" %12s "s.e." %20s "[`level'% band]"
    di as text "{hline 64}"
    forvalues j = 1/`h' {
        indsat_tstr `=`F'[`j',1]'
        di as res %12s "`r(s)'" %4.0f `j' %14.5g `F'[`j',2] %12.5g `F'[`j',3] %10.5g `F'[`j',4] %10.5g `F'[`j',5]
    }
    di as text "{hline 64}"
    di as text "note: bands use the error variance and AR psi-weights; parameter uncertainty is ignored."
    if ("`graph'"!="") {
        local y "`e(depvar)'"
        local t0 = `T'[max(1,rowsof(`T')-3*`h'),1]
        twoway (rarea `generate'_lo `generate'_hi `tv', color(navy%20) lwidth(none)) ///
               (line `y' `tv' if `tv'>=`t0', lcolor(black)) ///
               (line `generate' `tv', lcolor(navy) lwidth(medthick)), ///
               xline(`tend', lcolor(gs10) lpattern(dash)) graphregion(color(white)) ///
               legend(order(2 "Actual" 3 "Forecast" 1 "`level'% band") rows(1) region(lcolor(white))) ///
               title("indsat forecasts of `y'", size(medsmall)) xtitle("") ytitle("") name(`name', replace)
    }
    return matrix forecast = `F'
end

* ---------------------------------------------------------------------
* PcGive-style misspecification tests on the final indsat model
program define indsat_estat_diag, rclass
    syntax [, LAGs(integer 2) ARCHlags(integer 1)]
    mata: indsate_diag(`lags', `archlags')
    tempname D
    matrix `D' = r(diag)
    di
    di as text "{bf:Misspecification tests on the selected model}"
    di as text "{hline 72}"
    di as text %-30s "Test" %10s "Form" %12s "Statistic" %12s "df" %8s "p-value"
    di as text "{hline 72}"
    local labs `""AR 1-`lags' (Breusch-Godfrey)" "ARCH 1-`archlags' (Engle)" "Normality (Jarque-Bera)" "Normality (Doornik-Hansen)" "Hetero (White, squares)" "RESET (squares, cubes)""'
    local forms "F F chi2 chi2 F F"
    forvalues j = 1/6 {
        local l : word `j' of `labs'
        local f : word `j' of `forms'
        local p = `D'[`j',4]
        local st ""
        if (`p'<0.10) local st "*"
        if (`p'<0.05) local st "**"
        if (`p'<0.01) local st "***"
        if (`D'[`j',1]<.) {
            if ("`f'"=="F") local dfs "`=`D'[`j',2]',`=`D'[`j',3]'"
            else local dfs "`=`D'[`j',2]'"
            di as text %-30s "`l'" %10s "`f'" as res %12.4f `D'[`j',1] %12s "`dfs'" %8.4f `p' as text " `st'"
        }
    }
    di as text "{hline 72}"
    matrix rownames `D' = ar arch jb dh hetero reset
    matrix colnames `D' = stat df1 df2 p
    return matrix diag = `D'
end

* =====================================================================
version 14.0
mata:

/* columns of e(X) that belong to the deterministic (intercept) path */
real rowvector indsate_detcols(string rowvector cn, real matrix B, string rowvector rn)
{
    real rowvector idx
    real scalar j, r
    idx = J(1, 0, .)
    for (j=1; j<=cols(cn); j++) {
        if (cn[j]=="_cons") {
            idx = idx, j
        }
        else {
            for (r=1; r<=cols(rn); r++) {
                if (rn[r]==cn[j]) {
                    if (B[r, 1]!=4) {
                        idx = idx, j
                    }
                }
            }
        }
    }
    return(idx)
}

void indsate_path(string scalar pname, real scalar lr)
{
    real matrix X, V, B, Vs, P, G, VV
    real colvector b, tv, path, se, a, g
    real rowvector idx, aridx
    string rowvector cn, rn
    real scalar n, t, q, s, j, lv, den
    X = st_matrix("e(X)")
    b = st_matrix("e(b)")'
    V = st_matrix("e(V)")
    tv = st_matrix("e(tvals)")
    B = st_matrix("e(breaks)")
    cn = st_matrixcolstripe("e(b)")[., 2]'
    rn = st_matrixrowstripe("e(breaks)")[., 2]'
    n = rows(X)
    lv = strtoreal(st_local("level"))
    if (lv>=.) {
        lv = 95
    }
    q = invttail(st_numscalar("e(df_r)"), (100 - lv)/200)
    idx = indsate_detcols(cn, B, rn)
    path = J(n, 1, 0)
    se = J(n, 1, 0)
    if (cols(idx)>0) {
        Vs = V[idx, idx]
        for (t=1; t<=n; t++) {
            a = X[t, idx]'
            path[t] = a'*b[idx]
            se[t] = sqrt(a'*Vs*a)
        }
    }
    P = tv, path, se, path - q*se, path + q*se
    if (lr==1) {
        aridx = J(1, 0, .)
        for (j=1; j<=cols(cn); j++) {
            if (regexm(cn[j], "^L[0-9]*\." + st_global("e(depvar)") + "$")) {
                aridx = aridx, j
            }
        }
        if (cols(aridx)==0) {
            errprintf("lr requires AR terms of the dependent variable (option ar())\n")
            exit(error(198))
        }
        s = sum(b[aridx])
        den = 1 - s
        G = J(n, 2, .)
        VV = V[(idx, aridx), (idx, aridx)]
        for (t=1; t<=n; t++) {
            a = X[t, idx]'
            g = (a/den) \ J(cols(aridx), 1, path[t]/(den^2))
            G[t, 1] = path[t]/den
            G[t, 2] = sqrt(g'*VV*g)
        }
        P = P, G
    }
    st_matrix(pname, P)
}

void indsate_store(string scalar pname, string scalar gen, string scalar es)
{
    real matrix P
    real colvector idx
    P = st_matrix(pname)
    idx = selectindex(st_data(., es) :!= 0)
    st_store(idx, gen, P[., 2])
    st_store(idx, gen + "_se", P[., 3])
}

/* MIS coefficient paths: beta_x(t) = b_x + sum_j b_mis_j 1{t >= tau_j} */
void indsate_mispath(string scalar mname)
{
    real matrix X, V, B, M
    real colvector b, tv, a
    real rowvector idx
    string rowvector cn, rn, mv
    real scalar n, t, j, r, k, bx, q, lv
    X = st_matrix("e(X)")
    b = st_matrix("e(b)")'
    V = st_matrix("e(V)")
    tv = st_matrix("e(tvals)")
    B = st_matrix("e(breaks)")
    cn = st_matrixcolstripe("e(b)")[., 2]'
    rn = st_matrixrowstripe("e(breaks)")[., 2]'
    mv = tokens(st_global("e(misvars)"))
    n = rows(X)
    lv = 95
    q = invttail(st_numscalar("e(df_r)"), (100 - lv)/200)
    M = tv
    for (k=1; k<=cols(mv); k++) {
        bx = 0
        for (j=1; j<=cols(cn); j++) {
            if (cn[j]==mv[k]) {
                bx = j
            }
        }
        idx = J(1, 0, .)
        if (bx>0) {
            idx = bx
        }
        for (r=1; r<=rows(B); r++) {
            if (B[r, 1]==4) {
                if (strpos(rn[r], "mis" + substr(ustrregexra(mv[k], "[^A-Za-z0-9_]", ""), 1, 12) + "_")==1) {
                    for (j=1; j<=cols(cn); j++) {
                        if (cn[j]==rn[r]) {
                            idx = idx, j
                        }
                    }
                }
            }
        }
        a = indsate_mispath1(b, V, B, cn, rn, idx, bx, n, q)
        M = M, a
    }
    st_matrix(mname, M)
}

real matrix indsate_mispath1(real colvector b, real matrix V, real matrix B, string rowvector cn,
    string rowvector rn, real rowvector idx, real scalar bx, real scalar n, real scalar q)
{
    real matrix out, Vs
    real colvector w
    real scalar t, j, r, tau
    out = J(n, 3, .)
    if (cols(idx)==0) {
        return(out)
    }
    Vs = V[idx, idx]
    for (t=1; t<=n; t++) {
        w = J(cols(idx), 1, 0)
        for (j=1; j<=cols(idx); j++) {
            if (idx[j]==bx) {
                w[j] = 1
            }
            else {
                tau = .
                for (r=1; r<=rows(B); r++) {
                    if (rn[r]==cn[idx[j]]) {
                        tau = B[r, 2]
                    }
                }
                w[j] = (t >= tau)
            }
        }
        out[t, 1] = w'*b[idx]
        out[t, 2] = out[t, 1] - q*sqrt(w'*Vs*w)
        out[t, 3] = out[t, 1] + q*sqrt(w'*Vs*w)
    }
    return(out)
}

/* gets::biascorr */
real matrix indsate_bc(real colvector b, real colvector se, real scalar alpha, real scalar T)
{
    real scalar c, j
    real colvector bt, dr, dtbar, drbar, b1, b2
    c = abs(invttail(T, alpha/2))
    bt = b :/ se
    dr = (normalden(c :- bt) - normalden(-c :- bt)) :/ (1 :- normal(c :- bt) + normal(-c :- bt))
    dtbar = bt - dr
    drbar = (normalden(c :- dtbar) - normalden(-c :- dtbar)) :/ (1 :- normal(c :- dtbar) + normal(-c :- dtbar))
    b1 = b
    b2 = b
    for (j=1; j<=rows(b); j++) {
        if (abs(bt[j]) > c) {
            b1[j] = b[j]*(1 - dr[j]/bt[j])
            b2[j] = b[j]*(1 - drbar[j]/bt[j])
        }
    }
    return((b, b1, b2))
}

void indsate_biascorr(string scalar bname, string scalar cname)
{
    real matrix B
    B = st_matrix(bname)
    st_matrix(cname, indsate_bc(B[., 4], B[., 5], st_numscalar("e(tpval)"), st_numscalar("e(N)")))
}

/* gets::isattest */
void indsate_isattest(string scalar pname, real scalar hnull, real scalar cipval, real scalar bc, real scalar lr)
{
    real matrix P, O
    real colvector m, s, lo, hi, bl, bh
    real scalar T, N, crit
    P = st_matrix(pname)
    T = rows(P)
    N = cols(st_matrix("e(b)"))
    crit = abs(invttail(T - N, (1 - cipval)/2))
    if (lr==1) {
        m = P[., 6]
        s = P[., 7]
    }
    else {
        m = P[., 2]
        s = P[., 3]
        if (bc==1) {
            m = indsate_bc(m, s, st_numscalar("e(tpval)"), T)[., 3]
        }
    }
    lo = m - crit*s
    hi = m + crit*s
    bl = (lo :> hnull) :* (m :- hnull)
    bh = (hi :< hnull) :* (m :- hnull)
    O = P[., 1], m, lo, hi, bl, bh
    st_matrix("r(pathtest)", O)
    st_numscalar("r(crit)", crit)
}

real scalar indsate_vargauge(real scalar alpha, real scalar T, real scalar m)
{
    real scalar c, fc, psi, tau, chi, rho, k, m1, eta1, etag
    c = abs(invnormal(alpha/2))
    fc = normalden(c)
    psi = normal(c) - normal(-c)
    tau = psi - 2*c*fc
    chi = 3*psi - 2*c*(c^2 + 3)*fc
    rho = (c^2 - tau/psi)*c*fc/tau
    k = 3
    m1 = m - 1
    eta1 = (((1 - rho^m1)/((1 - rho)*tau))^2 + 2*((1 - rho^m1)/((1 - rho)*tau))*rho^m1)*(chi - tau^2/psi)/(k - 1) + rho^(2*m1)
    etag = (c*fc)^2*eta1*(k - 1) + 2*c*fc*rho^(m - 1)*(tau - psi)
    return((psi*(1 - psi) + etag)/T)
}

real scalar indsate_poistest(real scalar x, real scalar m, string scalar alt)
{
    real scalar d, relErr, N, y, i
    if (alt=="less") {
        return(poisson(m, x))
    }
    if (alt=="greater") {
        return(poissontail(m, x))
    }
    if (m==0) {
        return(x==0)
    }
    relErr = 1 + 1e-7
    d = poissonp(m, x)
    if (x==m) {
        return(1)
    }
    if (x < m) {
        N = ceil(2*m - x)
        while (poissonp(m, N) > d) {
            N = 2*N
        }
        y = 0
        for (i=ceil(m); i<=N; i++) {
            if (poissonp(m, i) <= d*relErr) {
                y = y + 1
            }
        }
        return(min((1, poisson(m, x) + poissontail(m, N - y + 1))))
    }
    y = 0
    for (i=0; i<=floor(m); i++) {
        if (poissonp(m, i) <= d*relErr) {
            y = y + 1
        }
    }
    if (y - 1 < 0) {
        return(min((1, poissontail(m, x))))
    }
    return(min((1, poisson(m, y - 1) + poissontail(m, x))))
}

/* gets::distorttest (coef = "all") */
void indsate_distort()
{
    real matrix X, V, R, Xk, Vk, XXi, D
    real colvector b, y, bk, bols, sb
    real rowvector kidx
    string rowvector cn, rn
    real scalar n, nret, alpha, c, fc, psi, tau, varsig, rho1, avar1, nrob, st, j, r, isind
    X = st_matrix("e(X)")
    b = st_matrix("e(b)")'
    V = st_matrix("e(V)")
    R = st_matrix("e(resid)")
    y = R[., 1]
    cn = st_matrixcolstripe("e(b)")[., 2]'
    rn = tokens(st_global("e(retained)"))
    kidx = J(1, 0, .)
    for (j=1; j<=cols(cn); j++) {
        isind = 0
        for (r=1; r<=cols(rn); r++) {
            if (rn[r]==cn[j]) {
                isind = 1
            }
        }
        if (isind==0) {
            kidx = kidx, j
        }
    }
    n = rows(X)
    nret = cols(rn)
    alpha = st_numscalar("e(tpval)")
    c = abs(invnormal(alpha/2))
    fc = normalden(c)
    psi = normal(c) - normal(-c)
    tau = psi - 2*c*fc
    varsig = tau/psi
    rho1 = psi^2/(4*(c^2)*(fc^2) + 4*tau*c*fc + tau)
    avar1 = ((2*c*fc - psi)^2 + 2*tau*(2*c*fc - psi) + tau)/psi^2
    nrob = n - nret
    Xk = X[., kidx]
    XXi = invsym(quadcross(Xk, Xk))
    bols = XXi*quadcross(Xk, y)
    bk = b[kidx]
    Vk = (nrob/n)*(1/rho1)*(1/varsig)*V[kidx, kidx]
    sb = bk - bols
    st = 0
    if (max(abs(sb))>0) {
        st = n*sb'*invsym(avar1*n*rho1*Vk)*sb
    }
    D = bk, bols, sb
    st_matrix("r(diff)", D)
    st_matrixrowstripe("r(diff)", (J(cols(kidx), 1, ""), cn[kidx]'))
    st_matrixcolstripe("r(diff)", (J(3, 1, ""), ("IIS", "OLS", "diff")'))
    st_numscalar("r(chi2)", st)
    st_numscalar("r(df)", cols(kidx))
    st_numscalar("r(p)", chi2tail(cols(kidx), st))
}

void indsate_cleanidx()
{
    real matrix B
    real colvector cl
    real scalar n, j
    n = st_numscalar("e(N)")
    B = st_matrix("e(breaks)")
    cl = J(n, 1, 1)
    if (st_numscalar("e(nret)")>0) {
        for (j=1; j<=rows(B); j++) {
            if (B[j, 1]==1) {
                cl[B[j, 2]] = 0
            }
        }
    }
    st_matrix("__isat_clean", selectindex(cl))
}

void indsate_bootdata(string scalar xname, string scalar rname, real scalar nx, real scalar cons)
{
    real matrix X, R
    real colvector cl, draw
    real scalar n, j
    string rowvector nm
    X = st_matrix(xname)
    R = st_matrix(rname)
    cl = st_matrix("__isat_clean")
    n = rows(X)
    draw = cl[ceil(runiform(n, 1)*rows(cl))]
    st_addobs(n)
    (void) st_addvar("double", "by")
    st_store(., "by", R[draw, 1])
    for (j=1; j<=nx; j++) {
        (void) st_addvar("double", "bx" + strofreal(j))
        st_store(., "bx" + strofreal(j), X[draw, j])
    }
}

real rowvector mm_quantile_isat(real colvector x)
{
    real colvector s
    real scalar n
    s = sort(select(x, x :< .), 1)
    n = rows(s)
    if (n==0) {
        return((., ., .))
    }
    return((s[max((1, ceil(0.90*n)))], s[max((1, ceil(0.95*n)))], s[max((1, ceil(0.99*n)))]))
}

/* forecasting: extend indicators, iterate AR terms */
void indsate_forecast(real scalar h, real scalar delta, string scalar gen, real scalar lv, real scalar icor)
{
    real matrix X, B, F
    real colvector b, tv, R, yall, psi
    real rowvector arl, ari
    string rowvector cn, rn, xv
    string scalar dv, tvn, sfm
    real scalar n, j, k, r, t, tend, ty, tau, tt, yhat, sig, q, ic, l, idx, s2, ttau, Lsh
    real rowvector shape, ff
    real colvector fut, futidx, xval
    X = st_matrix("e(X)")
    b = st_matrix("e(b)")'
    tv = st_matrix("e(tvals)")
    B = st_matrix("e(breaks)")
    R = st_matrix("e(resid)")
    cn = st_matrixcolstripe("e(b)")[., 2]'
    rn = st_matrixrowstripe("e(breaks)")[., 2]'
    dv = st_global("e(depvar)")
    tvn = st_global("e(timevar)")
    sfm = st_global("e(sisform)")
    shape = strtoreal(tokens(st_global("e(bisshape)")))
    n = rows(X)
    k = cols(cn)
    tend = tv[n]
    sig = st_numscalar("e(sigma)")
    q = invnormal(1 - (100 - lv)/200)
    ic = 0
    if (icor==1) {
        ic = R[n, 3]
    }
    /* AR structure */
    arl = J(1, k, 0)
    for (j=1; j<=k; j++) {
        if (regexm(cn[j], "^L([0-9]*)\." + dv + "$")) {
            if (regexs(1)=="") {
                arl[j] = 1
            }
            else {
                arl[j] = strtoreal(regexs(1))
            }
        }
    }
    /* history of y */
    yall = R[., 1]
    F = J(h, 5, .)
    psi = J(h, 1, 0)
    psi[1] = 1
    for (r=2; r<=h; r++) {
        s2 = 0
        for (j=1; j<=k; j++) {
            if (arl[j]>0 & r - arl[j] >= 1) {
                s2 = s2 + b[j]*psi[r - arl[j]]
            }
        }
        psi[r] = s2
    }
    for (r=1; r<=h; r++) {
        tt = tend + r*delta
        futidx = selectindex(st_data(., tvn) :== tt)
        yhat = 0
        for (j=1; j<=k; j++) {
            if (arl[j]>0) {
                l = arl[j]
                if (r - l >= 1) {
                    xval = F[r - l, 2]
                }
                else {
                    xval = yall[n + r - l]
                }
                yhat = yhat + b[j]*xval
                continue
            }
            if (cn[j]=="_cons") {
                yhat = yhat + b[j]
                continue
            }
            ty = 0
            for (idx=1; idx<=cols(rn); idx++) {
                if (rn[idx]==cn[j]) {
                    ty = B[idx, 1]
                    ttau = B[idx, 2]
                }
            }
            if (ty==0 | ty==5 | ty==4) {
                /* regressor / user indicator / MIS: read future value from data */
                if (rows(futidx)==0) {
                    errprintf("future values of %s not found\n", cn[j])
                    exit(error(198))
                }
                if (ty==4) {
                    xval = st_data(futidx[1], indsate_misbase(cn[j]))
                    if (sfm=="down") {
                        xval = xval
                    }
                }
                else {
                    xval = st_data(futidx[1], cn[j])
                }
                yhat = yhat + b[j]*xval
                continue
            }
            t = n + r
            if (ty==2) {
                if (sfm=="down") {
                    xval = 0
                }
                else {
                    xval = 1
                }
            }
            if (ty==1 | ty==9 | ty==10) {
                xval = 0
            }
            if (ty==3 | ty==7 | ty==8) {
                xval = (t - ttau + 1)^(1 + (ty==7) + 2*(ty==8))
            }
            if (ty==6) {
                Lsh = cols(shape)
                xval = 0
                if (t - ttau + 1 <= Lsh) {
                    xval = shape[t - ttau + 1]
                }
            }
            yhat = yhat + b[j]*xval
        }
        yhat = yhat + ic
        F[r, 1] = tt
        F[r, 2] = yhat
        F[r, 3] = sig*sqrt(sum(psi[|1 \ r|]:^2))
        F[r, 4] = yhat - q*F[r, 3]
        F[r, 5] = yhat + q*F[r, 3]
        if (rows(futidx)>0) {
            st_store(futidx[1], gen, yhat)
            st_store(futidx[1], gen + "_se", F[r, 3])
            st_store(futidx[1], gen + "_lo", F[r, 4])
            st_store(futidx[1], gen + "_hi", F[r, 5])
        }
    }
    st_matrix("r(fc)", F)
}

string scalar indsate_misbase(string scalar nm)
{
    string rowvector mv
    real scalar k
    mv = tokens(st_global("e(misvars)"))
    for (k=1; k<=cols(mv); k++) {
        if (strpos(nm, "mis" + substr(ustrregexra(mv[k], "[^A-Za-z0-9_]", ""), 1, 12) + "_")==1) {
            return(mv[k])
        }
    }
    return(mv[1])
}

/* diagnostics: BG AR, ARCH LM, JB, Doornik-Hansen, White, RESET */
void indsate_diag(real scalar q, real scalar qa)
{
    real matrix X, R, D, Z, W
    real colvector e, y, f, e2, u, v
    real scalar n, k, rss0, rss1, j, l, st, m, sk, ku, z1, z2, b1, b2, dd, w2, yy, aa, del, alp, ch, xi, beta2, kk
    real rowvector isconst
    X = st_matrix("e(X)")
    R = st_matrix("e(resid)")
    y = R[., 1]
    f = R[., 2]
    e = R[., 3]
    n = rows(X)
    k = cols(X)
    D = J(6, 4, .)
    /* AR 1-q LM (F-form), missing lagged residuals set to 0 */
    Z = X
    for (l=1; l<=q; l++) {
        v = J(l, 1, 0) \ e[|1 \ n - l|]
        Z = Z, v
    }
    rss0 = quadcross(e, e)
    u = e - Z*invsym(quadcross(Z, Z))*quadcross(Z, e)
    rss1 = quadcross(u, u)
    D[1, .] = ((rss0 - rss1)/q)/(rss1/(n - k - q)), q, n - k - q, Ftail(q, n - k - q, ((rss0 - rss1)/q)/(rss1/(n - k - q)))
    /* ARCH 1-qa */
    e2 = e:^2
    Z = J(n - qa, 1, 1)
    for (l=1; l<=qa; l++) {
        Z = Z, e2[|qa - l + 1 \ n - l|]
    }
    v = e2[|qa + 1 \ n|]
    u = v - Z*invsym(quadcross(Z, Z))*quadcross(Z, v)
    rss1 = quadcross(u, u)
    rss0 = quadcross(v :- mean(v), v :- mean(v))
    st = ((rss0 - rss1)/qa)/(rss1/(n - qa - qa - 1))
    D[2, .] = st, qa, n - 2*qa - 1, Ftail(qa, n - 2*qa - 1, st)
    /* JB */
    m = mean(e)
    sk = mean((e :- m):^3)/(mean((e :- m):^2)^1.5)
    ku = mean((e :- m):^4)/(mean((e :- m):^2)^2)
    D[3, .] = (n/6)*(sk^2 + (ku - 3)^2/4), 2, ., chi2tail(2, (n/6)*(sk^2 + (ku - 3)^2/4))
    /* Doornik-Hansen (1994/2008) univariate */
    b1 = sk
    b2 = ku
    beta2 = 3*(n^2 + 27*n - 70)*(n + 1)*(n + 3)/((n - 2)*(n + 5)*(n + 7)*(n + 9))
    w2 = -1 + sqrt(2*(beta2 - 1))
    del = 1/sqrt(ln(sqrt(w2)))
    yy = b1*sqrt((w2 - 1)*(n + 1)*(n + 3)/(12*(n - 2)))
    z1 = del*ln(yy + sqrt(yy^2 + 1))
    dd = (n - 3)*(n + 1)*(n^2 + 15*n - 4)
    aa = ((n - 2)*(n + 5)*(n + 7)*(n^2 + 27*n - 70))/(6*dd)
    ch = ((n - 7)*(n + 5)*(n + 7)*(n^2 + 2*n - 5))/(6*dd)
    kk = ((n + 5)*(n + 7)*(n^3 + 37*n^2 + 11*n - 313))/(12*dd)
    alp = aa + b1^2*ch
    xi = (b2 - 1 - b1^2)*2*kk
    z2 = sqrt(9*alp)*(1/(9*alp) - 1 + (xi/(2*alp))^(1/3))
    D[4, .] = z1^2 + z2^2, 2, ., chi2tail(2, z1^2 + z2^2)
    /* White (squares of non-indicator regressors) */
    isconst = J(1, k, 0)
    W = J(n, 1, 1)
    for (j=1; j<=k; j++) {
        if (min(X[., j])==max(X[., j])) {
            continue
        }
        if (sum(X[., j] :!= 0) <= 2 | indsate_isind(j)) {
            continue
        }
        W = W, X[., j], X[., j]:^2
    }
    if (cols(W)>1) {
        u = e2 - W*invsym(quadcross(W, W))*quadcross(W, e2)
        rss1 = quadcross(u, u)
        rss0 = quadcross(e2 :- mean(e2), e2 :- mean(e2))
        st = ((rss0 - rss1)/(cols(W) - 1))/(rss1/(n - cols(W)))
        D[5, .] = st, cols(W) - 1, n - cols(W), Ftail(cols(W) - 1, n - cols(W), st)
    }
    /* RESET: add fitted^2, fitted^3 */
    Z = X, f:^2, f:^3
    u = y - Z*invsym(quadcross(Z, Z))*quadcross(Z, y)
    rss1 = quadcross(u, u)
    rss0 = quadcross(e, e)
    st = ((rss0 - rss1)/2)/(rss1/(n - k - 2))
    D[6, .] = st, 2, n - k - 2, Ftail(2, n - k - 2, st)
    st_matrix("r(diag)", D)
}

real scalar indsate_isind(real scalar j)
{
    string rowvector cn, rn
    real scalar r
    cn = st_matrixcolstripe("e(b)")[., 2]'
    rn = tokens(st_global("e(retained)"))
    for (r=1; r<=cols(rn); r++) {
        if (rn[r]==cn[j]) {
            return(1)
        }
    }
    return(0)
}

end
