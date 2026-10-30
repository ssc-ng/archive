*! ntcoint 1.0.0  27oct2026
*! Dr Merwan Roudane  -  merwanroudane920@gmail.com
*! github.com/merwanroudane
*!
*! Direct, consistent test of NONTRIVIAL cointegration in a bivariate system,
*! via the squared-correlations ratio (SCR) of
*!   Hualde, J. and J. Olmo (2026), "Testing for Nontrivial Cointegration",
*!   Journal of Business & Economic Statistics, DOI 10.1080/07350015.2026.2638497
*!
*! Abbreviated step -> equation map  (P = main paper, OA = online appendix).
*! The full map is in  help ntcoint methods.
*!   1. remove deterministics      x^c = x - xbar            (P sec.3)
*!                                 x^tr = resid on (1,t)     OA eq.(2)
*!   2. sample correlation r       (P11) / OA after eq.(7)
*!   3. Delta x -> HAC at two bandwidths K_i = C*T^lambda_i  (P16)-(P17), OA(9)
*!   4. rho^2 from the slow/fast pair, truncated at 0        (P18)-(P19)
*!   5. SCR = (1 - r^2)/(1 - rho^2)                          (P15) / OA(8)
*!   6. reject H0 when SCR < cv                              (P22), Thm 2, Thm S2
*!      cv: conservative = A(+-1); plug-in = A(rhohat); bootstrap = OA sec.3
*!
*! H0: absence of nontrivial cointegration (NC, TC or FC)
*! H1: nontrivial cointegration

program define ntcoint, rclass
    version 14.0
    syntax varlist(min=2 numeric ts)        ///
        [if] [in] [,                        ///
        TRend                               ///
        KERNel(string)                      ///
        LAMBda(numlist min=2 max=2 >0 <0.3333333) ///
        Cparm(real 1)                       ///
        REPS(integer 500)                   ///
        SEED(string)                        ///
        CVTable(string)                     ///
        BTYPE(integer 1)                    ///
        Level(integer 95)                   ///
        NOBOOTstrap                         ///
        GRaph                               ///
        PLot(string)                        ///
        NAME(string)                        ///
        GRAPHOPTs(string asis)              ///
        ]

    marksample touse, novarlist

    * ---------------------------------------------------------------- checks
    capture tsset
    if _rc {
        di as error "data must be {bf:tsset} before using ntcoint"
        exit 111
    }
    local tvar "`r(timevar)'"
    if "`r(panelvar)'" != "" {
        di as error "ntcoint is a time-series command; {bf:tsset} a single series, not a panel"
        exit 198
    }

    * kernel
    if "`kernel'" == "" local kernel "parzen"
    local kernel = lower("`kernel'")
    if      "`kernel'" == "parzen"   local kern 3
    else if "`kernel'" == "hanning"  local kern 1
    else if "`kernel'" == "bartlett" local kern 2
    else if "`kernel'" == "nwest"    local kern 2
    else {
        di as error "kernel() must be parzen, hanning or bartlett"
        exit 198
    }
    if `kern' != 3 {
        di as text "{p 0 2 2}note: Theorem 2 of Hualde and Olmo (2026) is established for the " ///
                   "Parzen kernel only; {bf:`kernel'} is offered for comparison and does not "  ///
                   "guarantee SCR >= 0 in finite samples.{p_end}"
    }

    * bandwidth exponents
    if "`lambda'" == "" local lambda "0.2 0.1666667"
    tokenize "`lambda'"
    local lam1 = `1'
    local lam2 = `2'
    if `lam1' <= `lam2' {
        di as error "lambda() must be lambda1 > lambda2 (both < 1/3); you gave `lam1' `lam2'"
        exit 198
    }
    if `cparm' <= 0 {
        di as error "cparm() must be positive"
        exit 198
    }

    * significance level
    if !inlist(`level', 90, 95, 99) {
        di as error "level() must be 90, 95 or 99 (the asymptotic distribution is tabulated at these three levels)"
        exit 198
    }
    local alpha = (100-`level')/100
    local kcol  = cond(`level'==90, 1, cond(`level'==95, 2, 3))

    * which cv table
    if "`cvtable'" == "" local cvtable "exact"
    local cvtable = lower("`cvtable'")
    if !inlist("`cvtable'", "exact", "authors") {
        di as error "cvtable() must be exact or authors"
        exit 198
    }
    local tr = ("`trend'" != "")
    * the tables carry the .mata suffix so that -net install- puts them on the
    * adopath: Stata treats .txt as an ancillary file and would not install it
    local cvstub = cond("`cvtable'"=="exact", "ntcoint_cv", "ntcoint_authcv")
    local cvfile = "`cvstub'" + cond(`tr', "2", "1") + ".mata"
    capture findfile `cvfile'
    if _rc {
        di as error "could not locate {bf:`cvfile'}; reinstall ntcoint so its ancillary files are on the adopath"
        exit 601
    }
    local cvpath "`r(fn)'"

    if !inlist(`btype', 1, 2) {
        di as error "btype() must be 1 (the paper's algorithm) or 2 (fixed denominator)"
        exit 198
    }
    local doboot = ("`nobootstrap'" == "")
    if `doboot' & `reps' < 50 {
        di as error "reps() must be at least 50"
        exit 198
    }
    if "`seed'" != "" set seed `seed'

    * ------------------------------------------------------------- plots
    if "`name'" == "" local name "ntcoint"
    local plotlist = lower(trim("`plot'"))
    if "`graph'" != "" & "`plotlist'" == "" local plotlist "series"
    if "`plotlist'" == "all" local plotlist "series cv boot bandwidth pairs"
    foreach p of local plotlist {
        if !inlist("`p'", "series", "cv", "boot", "bandwidth", "pairs") {
            di as error "plot() takes a list of: series cv boot bandwidth pairs all"
            exit 198
        }
    }
    local p_series : list posof "series"    in plotlist
    local p_cv     : list posof "cv"        in plotlist
    local p_boot   : list posof "boot"      in plotlist
    local p_bw     : list posof "bandwidth" in plotlist
    local p_pairs  : list posof "pairs"     in plotlist
    if `p_boot' & !`doboot' {
        di as error "plot(boot) cannot be combined with nobootstrap"
        exit 198
    }

    * ------------------------------------------------------------ load Mata
    mata: ntc_cv = ntc_readcv("`cvpath'")

    * ------------------------------------------------------------ the pairs
    local nv : word count `varlist'
    tempname RES
    local npair = `nv'*(`nv'-1)/2

    mata: ntc_res = J(`npair', 10, .)

    local p 0
    forvalues i = 1/`=`nv'-1' {
        local vi : word `i' of `varlist'
        forvalues j = `=`i'+1'/`nv' {
            local vj : word `j' of `varlist'
            local ++p
            local pn`p' "`vi' vs `vj'"

            tempvar tu
            quietly generate byte `tu' = `touse' & !missing(`vi') & !missing(`vj')
            quietly count if `tu'
            local Tp = r(N)
            if `Tp' < 20 {
                di as error "pair `vi' / `vj': only `Tp' usable observations; need at least 20"
                exit 2001
            }
            if `Tp' < 100 {
                di as text "{p 0 2 2}note: pair `vi' / `vj' has only `Tp' observations. " ///
                           "The online appendix reports the plug-in and bootstrap tests "  ///
                           "are oversized at T = 50.{p_end}"
            }
            * contiguity: the HAC and the differencing assume no interior gaps
            quietly summarize `tvar' if `tu', meanonly
            local span = r(max) - r(min) + 1
            if `span' != `Tp' {
                di as error "pair `vi' / `vj': the sample has gaps (`Tp' obs spanning `span' periods)"
                di as error "ntcoint needs a contiguous series; use if/in to select a gap-free window"
                exit 198
            }

            * keep the bootstrap draws only when there is one pair to plot
            local keepd = (`npair' == 1 & `p_boot')
            mata: ntc_res[`p',.] = ntc_one(ntc_cv, "`vi' `vj'", "`tu'", `tr',  ///
                          `lam1', `lam2', `cparm', `kern', `kcol', `doboot',   ///
                          `reps', `btype', `keepd')
        }
    }

    mata: st_matrix("`RES'", ntc_res)

    * ------------------------------------------------------------- display
    local T1 = `RES'[1,10]
    local m1 = round(`cparm'*`T1'^`lam1')
    local m2 = round(`cparm'*`T1'^`lam2')

    di ""
    di as text "Test of nontrivial cointegration" _col(56) "Hualde-Olmo (2026) SCR"
    di as text "{hline 78}"
    di as text "  H0: no nontrivial cointegration (no coint., trivial or full)"
    di as text "  H1: nontrivial cointegration" _col(48) "reject when SCR < cv"
    di as text "{hline 78}"
    di as text "  Deterministics  : " as result cond(`tr', "constant and linear trend", "constant")
    di as text "  Kernel          : " as result proper("`kernel'")                    ///
       as text "   C = " as result %4.2f `cparm'
    di as text "  Bandwidths      : " as result "K1 = T^" %6.4f `lam1'               ///
       as text " = " as result `m1' as text ",  K2 = T^" as result %6.4f `lam2'      ///
       as text " = " as result `m2'
    if `m1' <= `m2' {
        di as text "{p 0 20 20}{bf:warning:} the slow and fast bandwidths coincide "  ///
           "at K1 = K2 = `m1'. The two-bandwidth construction of (P18) is then "      ///
           "degenerate and rhohat^2 collapses to the single-bandwidth estimator "     ///
           "(P20), which the paper warns can oversize the test under full "           ///
           "cointegration. Use a longer sample or widen lambda().{p_end}"
    }
    di as text "  Critical values : " as result cond("`cvtable'"=="exact",            ///
       "from eq. (14) / OA, simulated here", "the replication package's thr_asy tables")
    if `doboot' di as text "  Bootstrap       : " as result "`reps' reps, algorithm type `btype'"
    di as text "{hline 78}"
    di as text %-21s "Pair" %8s "r" %8s "rho" %9s "SCR" %9s "cv cons" %9s "cv plug" ///
               %8s "boot p" %12s "cons,plug,bt"
    di as text "{hline 78}"

    forvalues q = 1/`npair' {
        local pb  = `RES'[`q',6]
        local d1  = `RES'[`q',7]
        local d2  = `RES'[`q',8]
        local d3  = `RES'[`q',9]
        local trip = cond(`doboot', "`d1',`d2',`d3'", "`d1',`d2',.")
        di as text %-21s abbrev("`pn`q''",20)                                       ///
           as result %8.4f `RES'[`q',1] %8.4f `RES'[`q',2] %9.4f `RES'[`q',3]       ///
           %9.4f `RES'[`q',4] %9.4f `RES'[`q',5]                                    ///
           _continue
        if `doboot' di as result %8.4f `pb' _continue
        else        di as result %8s "." _continue
        di as text %12s "`trip'"
    }
    di as text "{hline 78}"
    di as text "  r = short-run correlation (P11); rho = long-run correlation (P18)-(P19)."
    di as text "  cv cons = A(+-1), the conservative value (P22); cv plug = A(rhohat)."
    di as text "  Last column: 1 = reject H0 at `level'% (evidence of NTC), 0 = do not reject,"
    di as text "  for the conservative, plug-in and bootstrap versions respectively."
    di as text "{hline 78}"

    * --------------------------------------------------------------- plots
    * All plots are built from the result matrices BEFORE -return matrix-
    * moves them away.
    if "`plotlist'" != "" {
        local single = (`npair' == 1)
        if (`p_series' | `p_cv' | `p_boot' | `p_bw') & !`single' {
            di as text "{p 0 2 2}note: the series, cv, boot and bandwidth plots " ///
               "describe one pair; with `nv' variables only plot(pairs) is drawn.{p_end}"
        }
        if `p_series' & `single' {
            local v1 : word 1 of `varlist'
            local v2 : word 2 of `varlist'
            ntc_pl_series `v1' `v2', tvar(`tvar') touse(`touse')             ///
                scr(`=`RES'[1,3]') cvplug(`=`RES'[1,5]')                     ///
                name(`name'_series) gopts(`graphopts')
        }
        if `p_cv' & `single' {
            ntc_pl_cv, kcol(`kcol') level(`level') pair("`pn1'")             ///
                scr(`=`RES'[1,3]') rho(`=`RES'[1,2]')                        ///
                cvcons(`=`RES'[1,4]') cvplug(`=`RES'[1,5]')                  ///
                trend(`tr') name(`name'_cv) gopts(`graphopts')
        }
        if `p_boot' & `single' {
            ntc_pl_boot, scr(`=`RES'[1,3]') pb(`=`RES'[1,6]')                ///
                level(`level') pair("`pn1'") name(`name'_boot) gopts(`graphopts')
        }
        if `p_bw' & `single' {
            local v1 : word 1 of `varlist'
            local v2 : word 2 of `varlist'
            tempname BW
            mata: st_matrix("`BW'", ntc_bwscan(ntc_cv, "`v1' `v2'", "`tu'",  ///
                            `tr', `cparm', `kern', `kcol'))
            matrix colnames `BW' = lambda1 lambda2 K1 K2 scr cv_cons cv_plug
            ntc_pl_bw, bw(`BW') level(`level') pair("`pn1'")                 ///
                name(`name'_bw) gopts(`graphopts')
            return matrix bwscan = `BW', copy
        }
        if `p_pairs' {
            if `nv' < 3 {
                di as text "note: plot(pairs) needs at least three variables; skipped"
            }
            else {
                tempname DEC
                matrix `DEC' = J(`nv', `nv', .)
                local q 0
                forvalues i = 1/`=`nv'-1' {
                    forvalues j = `=`i'+1'/`nv' {
                        local ++q
                        local sc = `RES'[`q',7] + `RES'[`q',8] +             ///
                                   cond(`doboot', `RES'[`q',9], 0)
                        matrix `DEC'[`i',`j'] = `sc'
                        matrix `DEC'[`j',`i'] = `sc'
                    }
                }
                matrix rownames `DEC' = `varlist'
                matrix colnames `DEC' = `varlist'
                ntc_pl_pairs, dec(`DEC') nv(`nv') vars(`varlist')            ///
                    level(`level') doboot(`doboot')                          ///
                    name(`name'_pairs) gopts(`graphopts')
                return matrix decmap = `DEC', copy
            }
        }
    }

    capture matrix drop __ntc_bdist

    * ------------------------------------------------------------- returns
    if `npair' == 1 {
        * the whole critical-value curve, so the cv plot can be redrawn by hand
        tempname CVC
        mata: st_matrix("`CVC'", (range(-1,1,0.001), ntc_cv[., `kcol']))
        matrix colnames `CVC' = rho cv
        return matrix cvcurve = `CVC', copy
    }
    matrix colnames `RES' = r rho scr cv_cons cv_plug p_boot rej_cons rej_plug rej_boot T
    local rn ""
    forvalues q = 1/`npair' {
        local rn `rn' `: subinstr local pn`q' " vs " "_", all'
    }
    capture matrix rownames `RES' = `rn'
    return scalar npairs  = `npair'
    return scalar level   = `level'
    return scalar lambda1 = `lam1'
    return scalar lambda2 = `lam2'
    return local  kernel  "`kernel'"
    return local  cvtable "`cvtable'"
    return local  deterministic = cond(`tr', "trend", "constant")
    if `npair' == 1 {
        return scalar T        = `RES'[1,10]
        return scalar r        = `RES'[1,1]
        return scalar rho      = `RES'[1,2]
        return scalar scr      = `RES'[1,3]
        return scalar cv_cons  = `RES'[1,4]
        return scalar cv_plug  = `RES'[1,5]
        if `doboot' return scalar p_boot = `RES'[1,6]
        return scalar rej_cons = `RES'[1,7]
        return scalar rej_plug = `RES'[1,8]
        if `doboot' return scalar rej_boot = `RES'[1,9]
    }
    * last: -return matrix- drops the source matrix, so nothing may read it after
    return matrix results = `RES'
    return local cmd "ntcoint"
end


* ==================================================================== plots
* Each helper does preserve / clear / build / graph / restore, and is called
* before -return matrix- moves the result matrices away.

* ---- 1. the two series over the estimation window (Figure 1 of the paper)
program define ntc_pl_series
    version 14.0
    syntax varlist(min=2 max=2), TVAR(string) TOUSE(string) ///
        SCR(real) CVPLUG(real) [NAME(string) GOPTS(string asis)]
    local v1 : word 1 of `varlist'
    local v2 : word 2 of `varlist'
    twoway (line `v1' `tvar' if `touse', lpattern(solid) lwidth(medthick)      ///
                lcolor(navy))                                                  ///
           (line `v2' `tvar' if `touse', lpattern(dash) lwidth(medthick)       ///
                lcolor(cranberry)),                                            ///
        graphregion(color(white)) plotregion(color(white) margin(medsmall))     ///
        legend(order(1 "`v1'" 2 "`v2'") rows(1) region(lstyle(none)))           ///
        ytitle("") xtitle("`tvar'")                                             ///
        title("Observed series", size(medium) color(black))                     ///
        subtitle("SCR = `:di %6.4f `scr'', plug-in cv = `:di %6.4f `cvplug''",  ///
            size(small) color(gs6))                                             ///
        name(`name', replace) `gopts'
end

* ---- 2. the critical-value curve A(rho) with the decision marked
program define ntc_pl_cv
    version 14.0
    syntax, KCOL(integer) LEVEL(integer) PAIR(string) SCR(real) RHO(real) ///
        CVCONS(real) CVPLUG(real) TREND(integer) [NAME(string) GOPTS(string asis)]
    preserve
    clear
    quietly set obs 2001
    quietly generate double rhogrid = -1 + (_n-1)*0.001
    quietly generate double cvcurve = .
    mata: st_store(., "cvcurve", ntc_cv[., `kcol'])
    quietly generate double zero = 0
    * the observed statistic and the point that decides the test
    quietly generate double scrline = `scr'
    local lab = cond(`trend', "A{sup:tr}({&rho})", "A({&rho})")
    local dec = cond(`scr' < `cvplug', "reject H0: evidence of NTC", ///
                                       "do not reject H0")
    twoway (rarea cvcurve zero rhogrid, color(navy*.18) lwidth(none))           ///
           (line cvcurve rhogrid, lcolor(navy) lwidth(medthick))                ///
           (line scrline rhogrid, lcolor(cranberry) lpattern(dash)              ///
                lwidth(medthick))                                               ///
           (scatteri `cvplug' `rho', msymbol(O) msize(large) mcolor(cranberry)  ///
                mlwidth(medthick) mfcolor(white)),                              ///
        graphregion(color(white)) plotregion(color(white) margin(medsmall))      ///
        xlabel(-1(0.5)1, format(%3.1f)) xtitle("long-run correlation {&rho}")    ///
        ytitle("critical value at `level'%")                                     ///
        yline(`cvcons', lcolor(gs8) lpattern(shortdash) lwidth(thin))            ///
        xline(`rho', lcolor(gs10) lpattern(dot))                                 ///
        title("Where the decision comes from: `pair'", size(medium) color(black)) ///
        subtitle("`dec'", size(small) color(gs6))                                 ///
        legend(order(2 "`lab' = critical value" 1 "rejection region"             ///
                     3 "observed SCR = `:di %6.4f `scr''"                        ///
                     4 "at {&rho}-hat = `:di %5.3f `rho''")                      ///
            cols(2) size(small) region(lstyle(none)))                            ///
        note("Conservative cv = A({&plusmn}1) = `:di %6.4f `cvcons''."           ///
             " H0 is rejected when SCR falls inside the shaded region.",          ///
            size(vsmall) color(gs7))                                             ///
        name(`name', replace) `gopts'
    restore
end

* ---- 3. the bootstrap null distribution with the observed statistic marked
program define ntc_pl_boot
    version 14.0
    syntax, SCR(real) PB(real) LEVEL(integer) PAIR(string) ///
        [NAME(string) GOPTS(string asis)]
    capture confirm matrix __ntc_bdist
    if _rc {
        di as text "note: bootstrap draws unavailable; plot(boot) skipped"
        exit
    }
    preserve
    clear
    quietly svmat double __ntc_bdist, name(bstat)
    quietly count
    local B = r(N)
    local alpha = (100-`level')/100
    quietly _pctile bstat1, percentiles(`=100*`alpha'' 90)
    local bcv = r(r1)
    local cap = r(r2)
    * the null distribution has a long right tail; showing it all squeezes the
    * decision region against the axis, so cut the display at the 90th pctile
    quietly count if bstat1 > `cap'
    local nhid = r(N)
    local dec = cond(`pb' <= `alpha', "reject H0: evidence of NTC", ///
                                      "do not reject H0")
    quietly generate byte inrej = bstat1 <= `bcv'
    twoway (histogram bstat1 if bstat1 <= `cap' & !inrej, width(`=`cap'/35')     ///
                start(0) color(navy*.35) lcolor(navy*.6) lwidth(vthin))          ///
           (histogram bstat1 if bstat1 <= `cap' &  inrej, width(`=`cap'/35')     ///
                start(0) color(cranberry*.45) lcolor(cranberry) lwidth(vthin)),  ///
        graphregion(color(white)) plotregion(color(white) margin(medsmall))      ///
        xline(`scr', lcolor(cranberry) lpattern(solid) lwidth(thick))            ///
        xline(`bcv', lcolor(gs4) lpattern(dash) lwidth(medthick))                ///
        xtitle("bootstrap SCR*") ytitle("density")                               ///
        title("Bootstrap null distribution: `pair'", size(medium) color(black))  ///
        subtitle("`dec'   (p = `:di %5.3f `pb'', B = `B')",                      ///
            size(small) color(gs6))                                              ///
        legend(order(2 "rejection region (SCR* {&le} cut-off)")                  ///
            size(small) region(lstyle(none)) position(1) ring(0))                ///
        note("Thick solid line: observed SCR = `:di %6.4f `scr''."               ///
             " Dashed line: the `level'% cut-off = `:di %6.4f `bcv''."           ///
             " The p-value is the share of draws at or below the solid line."    ///
             " Display truncated at the 90th percentile; `nhid' of `B' draws lie beyond.", ///
            size(vsmall) color(gs7) span)                                        ///
        name(`name', replace) `gopts'
    restore
end

* ---- 4. sensitivity to the bandwidth pair
program define ntc_pl_bw
    version 14.0
    syntax, BW(string) LEVEL(integer) PAIR(string) ///
        [NAME(string) GOPTS(string asis)]
    preserve
    clear
    quietly svmat double `bw', name(b)
    quietly generate int k = _n
    label define ntcbw 1 `""(1/4, 1/5)" "K = " ""' 2 `""(1/5, 1/6)" "K = " ""' ///
        3 `""(1/6, 1/7)" "K = " ""', replace
    * rebuild the labels with the realized integer bandwidths
    forvalues i = 1/3 {
        local l1 : di %4.2f b1[`i']
        local k1 = b3[`i']
        local k2 = b4[`i']
        local pr : word `i' of "(1/4,1/5)" "(1/5,1/6)" "(1/6,1/7)"
        label define ntcbw `i' `""`pr'" "K = `k1', `k2'""', modify
    }
    label values k ntcbw
    twoway (connected b5 k, lcolor(cranberry) mcolor(cranberry) msymbol(O)      ///
                lwidth(medthick) msize(medlarge))                               ///
           (connected b7 k, lcolor(navy) mcolor(navy) msymbol(D)                ///
                lpattern(dash) lwidth(medthick) msize(medium))                  ///
           (connected b6 k, lcolor(gs8) mcolor(gs8) msymbol(Th)                 ///
                lpattern(shortdash) lwidth(thin) msize(small)),                 ///
        graphregion(color(white)) plotregion(color(white) margin(medsmall))      ///
        xlabel(1/3, valuelabel labsize(small)) xscale(range(0.7 3.3))            ///
        xtitle("bandwidth exponents ({&lambda}{sub:1}, {&lambda}{sub:2})")       ///
        ytitle("")                                                              ///
        title("Bandwidth sensitivity: `pair'", size(medium) color(black))        ///
        subtitle("H0 is rejected where SCR lies below the critical value",       ///
            size(small) color(gs6))                                             ///
        legend(order(1 "SCR" 2 "plug-in cv (`level'%)" 3 "conservative cv")      ///
            rows(1) size(small) region(lstyle(none)))                            ///
        name(`name', replace) `gopts'
    restore
end

* ---- 5. the pairwise decision map (a visual Table 3)
program define ntc_pl_pairs
    version 14.0
    syntax, DEC(string) NV(integer) VARS(string) LEVEL(integer) ///
        DOBOOT(integer) [NAME(string) GOPTS(string asis)]
    local ntest = cond(`doboot', 3, 2)
    preserve
    clear
    quietly set obs `=`nv'*`nv''
    quietly generate int i = ceil(_n/`nv')
    quietly generate int col = _n - (i-1)*`nv'
    * rows run downward so the picture reads like Table 3 of the paper
    quietly generate int row = `nv' + 1 - i
    quietly generate double tests = .
    forvalues a = 1/`nv' {
        forvalues b = 1/`nv' {
            quietly replace tests = `dec'[`a',`b'] if i==`a' & col==`b'
        }
    }
    label variable tests "tests rejecting"
    local vl ""
    local vlrev ""
    forvalues a = 1/`nv' {
        local va : word `a' of `vars'
        local vl `vl' `a' "`va'"
        local vlrev `vlrev' `=`nv'+1-`a'' "`va'"
    }
    * preferred rendering: heatplot (SSC). Fall back to a marker grid.
    capture noisily {
        quietly heatplot tests row col, discrete                                   ///
            color(Blues) cuts(-0.5(1)`=`ntest'+0.5')                             ///
            graphregion(color(white)) plotregion(color(white))                   ///
            xlabel(`vl', labsize(small)) ylabel(`vlrev', labsize(small) angle(0)) ///
            xtitle("") ytitle("")                                                ///
            title("Pairwise evidence of nontrivial cointegration",               ///
                size(medium) color(black))                                       ///
            subtitle("number of the `ntest' SCR tests rejecting H0 at `level'%", ///
                size(small) color(gs6))                                          ///
            name(`name', replace) `gopts'
    }
    if _rc {
        local layers ""
        local cols "gs14 gs10 orange cranberry"
        forvalues v = 0/`ntest' {
            local c : word `=`v'+1' of `cols'
            local layers `layers' (scatter row col if tests==`v',                  ///
                msymbol(S) msize(*4.2) mcolor(`c') mlcolor(white) mlwidth(thin))
        }
        local leg ""
        forvalues v = 0/`ntest' {
            local leg `leg' `=`v'+1' "`v'"
        }
        twoway `layers',                                                         ///
            graphregion(color(white)) plotregion(color(white) margin(medium))     ///
            xlabel(`vl', labsize(small)) ylabel(`vlrev', labsize(small) angle(0)) ///
            xscale(range(0.4 `=`nv'+0.6')) yscale(range(0.4 `=`nv'+0.6'))         ///
            xtitle("") ytitle("")                                                 ///
            title("Pairwise evidence of nontrivial cointegration",                ///
                size(medium) color(black))                                        ///
            subtitle("number of the `ntest' SCR tests rejecting H0 at `level'%",   ///
                size(small) color(gs6))                                           ///
            legend(order(`leg') rows(1) size(small) region(lstyle(none))          ///
                title("tests rejecting", size(vsmall) color(gs7)))                ///
            note("heatplot is not installed; drawn with base twoway."             ///
                 " ssc install heatplot for the shaded version.",                 ///
                size(vsmall) color(gs7))                                          ///
            name(`name', replace) `gopts'
    }
    restore
end


* ======================================================================= Mata
version 14.0
mata:

// ------------------------------------------------------------------ kernels
// kern: 1 = Tukey-Hanning, 2 = Bartlett/Newey-West, 3 = Parzen (the paper's)
real colvector ntc_kw(real scalar m, real scalar kern)
{
    real colvector j, x
    if (m < 1) return(J(0,1,.))
    j = (1::m)
    x = j :/ m
    if (kern == 1)      return(0.5 :+ 0.5 :* cos(pi() :* x))
    else if (kern == 2) return(1 :- j :/ (m+1))
    return( (x :<= 0.5) :* (1 :- 6 :* x:^2 :+ 6 :* abs(x):^3) +
            (x :>  0.5) :* (2 :* (1 :- abs(x)):^3) )
}

// ------------------------------------------- long-run covariance, (P16)-(P17)
// u is demeaned first, as the authors' hac.m does and as OA eq. (9) specifies.
real matrix ntc_hac(real matrix uu, real scalar m, real scalar kern)
{
    real matrix S, G, u
    real colvector w
    real scalar T, j
    T = rows(uu)
    u = uu :- mean(uu)
    S = quadcross(u, u) / T
    w = ntc_kw(m, kern)
    for (j = 1; j <= m; j++) {
        if (j >= T) break
        G = quadcross(u[|j+1,1 \ T,.|], u[|1,1 \ T-j,.|]) / T
        S = S + w[j] :* (G + G')
    }
    return(S)
}

// --------------------------------------- deterministic removal, P sec.3 / OA(2)
real matrix ntc_detrend(real matrix x, real scalar tr)
{
    real matrix Z
    if (!tr) return(x :- mean(x))
    Z = J(rows(x),1,1), (1::rows(x))
    return(x - Z * qrsolve(Z, x))
}

// ------------------------------------------------- the statistic, (P11)-(P19)
// returns (SCR, r, rho, rho_theta) for the T x 2 matrix x
real rowvector ntc_stat(real matrix x, real scalar tr, real scalar lam1,
                        real scalar lam2, real scalar cc, real scalar kern)
{
    real matrix R, u, S1, S2
    real scalar T, m1, m2, r, om, rho
    T  = rows(x)
    R  = ntc_detrend(x, tr)
    r  = quadcross(R[.,1], R[.,2]) /
         sqrt( quadcross(R[.,1],R[.,1]) * quadcross(R[.,2],R[.,2]) )
    u  = x[|2,1 \ T,.|] - x[|1,1 \ T-1,.|]
    m1 = round(cc * T^lam1)
    m2 = round(cc * T^lam2)
    S1 = ntc_hac(u, m1, kern)
    S2 = ntc_hac(u, m2, kern)
    // (P18)-(P19):  om = 1 - rhohat^2, truncated above at 1 (i.e. rhohat^2 >= 0)
    om  = min(( 1, (S1[1,1]*S1[2,2] - S1[1,2]^2) / (S2[1,1]*S2[2,2]) ))
    rho = sqrt(max(( 1 - om, 0 )))
    // OA eq. (10): the single-bandwidth rho used to drive the bootstrap DGP
    return(( (1 - r^2)/om, r, rho,
             S1[1,2]/sqrt(S1[1,1]*S1[2,2]) ))
}

// --------------------------------------------- bootstrap p-value, OA section 3
// Step 1-5 of the online appendix.  btype 1 recomputes the whole statistic on
// every replication (the paper's algorithm).  btype 2 reuses the observed
// denominator, which is faster but is NOT the published procedure.
// returns the B bootstrap statistics; the p-value is formed by the caller
real colvector ntc_boot(real scalar scr, real scalar rth, real scalar T,
                        real scalar tr, real scalar lam1, real scalar lam2,
                        real scalar cc, real scalar kern, real scalar B,
                        real scalar btype, real scalar om_obs)
{
    real scalar b, n, s, r
    real matrix e, us, xs, R
    real rowvector st
    real colvector out
    n = T + 500
    out = J(B, 1, .)
    for (b = 1; b <= B; b++) {
        e  = rnormal(n, 2, 0, 1)
        us = (sqrt(1-rth^2) :* e[.,1] :+ rth :* e[.,2]), e[.,2]
        xs = runningsum(us[.,1]), runningsum(us[.,2])
        xs = xs[|501,1 \ n,.|]
        if (btype == 1) {
            // Mata will not subscript a function result inline: assign first
            st = ntc_stat(xs, tr, lam1, lam2, cc, kern)
            s  = st[1]
        }
        else {
            R = ntc_detrend(xs, tr)
            r = quadcross(R[.,1],R[.,2]) /
                sqrt(quadcross(R[.,1],R[.,1])*quadcross(R[.,2],R[.,2]))
            s = (1 - r^2) / om_obs
        }
        out[b] = s
    }
    return(out)
}

// ------------------------------------------- SCR across the three bandwidth
// pairs the paper examines, for the sensitivity plot.
// Each row: lambda1, lambda2, K1, K2, SCR, cv conservative, cv plug-in.
real matrix ntc_bwscan(real matrix cv, string scalar vars, string scalar touse,
                       real scalar tr, real scalar cc, real scalar kern,
                       real scalar kcol)
{
    real matrix x, out, grid
    real rowvector st
    real scalar i, idx, T
    x    = st_data(., vars, touse)
    T    = rows(x)
    grid = (1/4, 1/5) \ (1/5, 1/6) \ (1/6, 1/7)
    out  = J(3, 7, .)
    for (i = 1; i <= 3; i++) {
        st  = ntc_stat(x, tr, grid[i,1], grid[i,2], cc, kern)
        idx = round((st[4] + 1)/0.001) + 1
        idx = max(( 1, min(( 2001, idx )) ))
        out[i,.] = (grid[i,1], grid[i,2],
                    round(cc * T^grid[i,1]), round(cc * T^grid[i,2]),
                    st[1], cv[1, kcol], cv[idx, kcol])
    }
    return(out)
}

// ------------------------------------------------------- read a cv table file
real matrix ntc_readcv(string scalar fn)
{
    real scalar fh, i
    real matrix M
    string scalar line
    string rowvector t
    fh = fopen(fn, "r")
    M  = J(2001, 3, .)
    i  = 0
    while ((line = fget(fh)) != J(0,0,"")) {
        t = tokens(line)
        if (cols(t) == 3) {
            i++
            if (i > 2001) break
            M[i,.] = strtoreal(t)
        }
    }
    fclose(fh)
    if (i < 2001) _error("critical-value file " + fn + " is malformed")
    return(M)
}

// --------------------------------------------------------------- one pair
// cv is passed in explicitly: a Mata function cannot see the caller's globals.
real rowvector ntc_one(real matrix cv, string scalar vars, string scalar touse,
                       real scalar tr, real scalar lam1, real scalar lam2,
                       real scalar cc, real scalar kern, real scalar kcol,
                       real scalar doboot, real scalar B, real scalar btype,
                       real scalar keepdist)
{
    real matrix x
    real rowvector st
    real colvector bd
    real scalar T, idx, cvcons, cvplug, pb, om, alph, rjb
    x  = st_data(., vars, touse)
    T  = rows(x)
    st = ntc_stat(x, tr, lam1, lam2, cc, kern)
    // conservative cv = inf over rho, attained at |rho| = 1 (P22)
    cvcons = cv[1, kcol]
    // plug-in: snap rhohat to the 0.001 grid, exactly as coint_test.m does
    idx = round((st[4] + 1)/0.001) + 1
    idx = max(( 1, min(( 2001, idx )) ))
    cvplug = cv[idx, kcol]
    om = (1 - st[2]^2) / st[1]
    pb = .
    if (doboot) {
        bd = ntc_boot(st[1], st[4], T, tr, lam1, lam2, cc, kern, B, btype, om)
        // OA Step 5: the p-value is the share of draws at or below the observed
        pb = mean(bd :<= st[1])
        if (keepdist) st_matrix("__ntc_bdist", bd)
    }
    // three separate decisions, in the order the paper's Table 3 prints them:
    // conservative (P22), plug-in A(rhohat), bootstrap p-value (OA Step 5)
    alph = 0.01
    if (kcol == 1) alph = 0.10
    if (kcol == 2) alph = 0.05
    rjb = .
    if (doboot) {
        if (pb < .) rjb = (pb <= alph)
    }
    return(( st[2], st[3], st[1], cvcons, cvplug, pb,
             (st[1] < cvcons), (st[1] < cvplug), rjb, T ))
}
end
