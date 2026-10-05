*! _bd_graph.ado — publication-quality graphics for bootdiag
*! Version 1.1.0
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Graphs produced, by subcommand:
*!   serial  null density of BG(1); residual correlogram with bootstrap bands
*!   het     null density of the Koenker statistic; squared residuals vs fitted
*!   norm    residual histogram vs fitted normal; normal quantile plot
*!   stab    CUSUM and CUSUMSQ with BOOTSTRAP bands; sequence of Chow F
*!           statistics with the bootstrap supF critical value
*!   spec    null density of RESET
*!   all     the above, plus a P-value discrepancy plot and a combined panel
*!
*! Two of these are not available anywhere else in Stata:
*!   - CUSUM bands drawn as pointwise quantiles of the bootstrap paths,
*!     instead of the straight Brown-Durbin-Evans asymptotic lines that
*!     Kraemer, Ploberger & Alt (1988) show are unreliable in dynamic models;
*!   - a P-value discrepancy plot in the style of Davidson & MacKinnon (1998),
*!     which shows the asymptotic test's size distortion across ALL levels
*!     rather than at 5% alone.

program define _bd_graph
    version 16.0
    syntax , sub(string) reps(integer) dgp(integer) weight(integer) ///
             ftrans(integer) block(real) trim(real) touse(string)   ///
             [ name(string) saving(string) lags(string) resetpow(integer 4) ]

    if "`name'" == "" local name "bootdiag_`sub'"
    if "`lags'" == "" local lags "1"

    local sc    "scheme(s1mono)"
    local gopts "graphregion(color(white)) plotregion(color(white))"
    local C1    "navy"
    local C2    "cranberry"
    local C3    "dkgreen"
    local CBND  "gs13"

    local made ""

    *==================================================================
    * 1. Bootstrap null density of a scalar statistic
    *==================================================================
    if inlist("`sub'", "serial", "het", "spec", "all") {
        if "`sub'" == "serial"   local gl 10
        if "`sub'" == "het"      local gl 21
        if "`sub'" == "spec"     local gl 50
        if "`sub'" == "all"      local gl 21

        if `gl' == 10 {
            local gp : word 1 of `lags'
            local glab "Breusch-Godfrey LM(`gp')"
        }
        else if `gl' == 21 {
            local gp 0
            local glab "Koenker studentised"
        }
        else {
            local gp `resetpow'
            local glab "Ramsey RESET"
        }

        tempname BD
        mata: bd_dist(`gl', `gp', `reps', `dgp', `weight', `ftrans', ///
                      `block', "`BD'")
        local obs = r(bd_obs)

        preserve
        qui clear
        qui svmat double `BD', names(bs)
        qui drop if bs1 >= .
        qui count
        if r(N) > 10 & `obs' < . {
            qui sum bs1, detail
            local cv5  = r(p95)
            local cv10 = r(p90)
            tempvar dx dd
            qui kdensity bs1, nograph generate(`dx' `dd') n(300)
            qui sum `dd'
            local ym = r(max) * 1.15

            twoway                                                       ///
              (area `dd' `dx' if `dx' >= `cv5', color(`CBND') lwidth(none)) ///
              (line `dd' `dx', lcolor(`C1') lwidth(medthick))            ///
              , xline(`obs', lcolor(`C2') lwidth(thick))                 ///
                xline(`cv5', lcolor(black) lpattern(dash))               ///
                yscale(range(0 `ym'))                                    ///
                title("Bootstrap null distribution", size(medium))       ///
                subtitle("`glab' — `reps' replications", size(small))    ///
                xtitle("statistic") ytitle("density")                    ///
                legend(order(2 "bootstrap null" 1 "upper 5%")            ///
                       rows(1) size(small) region(lstyle(none)))         ///
                note("Red = observed (`: di %7.4f `obs''). Dashed = 5% bootstrap c.v. (`: di %7.4f `cv5'')." ///
                     , size(vsmall))                                     ///
                `gopts' `sc' name(`name'_null, replace)
            local made "`made' `name'_null"
        }
        restore
    }

    *==================================================================
    * 2. P-value discrepancy plot (Davidson & MacKinnon 1998)
    *==================================================================
    * Plots the bootstrap p-value of the ASYMPTOTIC test against the
    * nominal level.  A curve above zero means the asymptotic test
    * over-rejects at that level.  This is the picture the asymptotic
    * "5% critical value" hides.
    if inlist("`sub'", "het", "all") {
        tempname BD2
        mata: bd_dist(21, 0, `reps', `dgp', `weight', `ftrans', ///
                      `block', "`BD2'")
        preserve
        qui clear
        qui svmat double `BD2', names(bs)
        qui drop if bs1 >= .
        qui count
        local nb = r(N)
        if `nb' > 20 {
            * degrees of freedom for the asymptotic chi2 reference
            local dfk = e(df_m)
            if `dfk' >= . | `dfk' <= 0 local dfk 2
            tempvar lvl disc
            qui gen double `lvl'  = .
            qui gen double `disc' = .
            local i 0
            forvalues a = 1/40 {
                local al = `a' / 100
                local ++i
                * asymptotic critical value at level al
                local cva = invchi2tail(`dfk', `al')
                * how often the bootstrap null exceeds it = true size
                qui count if bs1 > `cva'
                local act = r(N) / `nb'
                qui replace `lvl'  = `al'        in `i'
                qui replace `disc' = `act' - `al' in `i'
            }
            twoway (line `disc' `lvl', lcolor(`C1') lwidth(medthick))     ///
                   , yline(0, lcolor(black) lpattern(dash))               ///
                     title("P-value discrepancy plot", size(medium))      ///
                     subtitle("asymptotic chi2(`dfk') reference vs bootstrap null" ///
                              , size(small))                             ///
                     xtitle("nominal level") ytitle("actual − nominal")   ///
                     legend(off)                                         ///
                     note("Above zero: the asymptotic test over-rejects at that level." ///
                          " Davidson & MacKinnon (1998).", size(vsmall))  ///
                     `gopts' `sc' name(`name'_pdisc, replace)
            local made "`made' `name'_pdisc"
        }
        restore
    }

    *==================================================================
    * 3. Residual diagnostics
    *==================================================================
    if inlist("`sub'", "norm", "het", "all") {
        tempvar rres rfit rrec
        qui gen double `rres' = .
        qui gen double `rfit' = .
        qui gen double `rrec' = .
        capture mata: bd_export("`rres'", "`rfit'", "`rrec'", "`touse'")

        qui count if `rres' < .
        if r(N) > 5 {
            if inlist("`sub'", "norm", "all") {
                qui sum `rres'
                local mu = r(mean)
                local sd = r(sd)
                local wd = (r(max) - r(min)) / 12

                twoway (histogram `rres', fraction color(`C1'%55)       ///
                            lcolor(white) width(`wd'))                    ///
                       (function `wd'*normalden(x, `mu', `sd'),           ///
                            range(`rres') lcolor(`C2') lwidth(medthick))  ///
                       , title("Residual distribution", size(medium))     ///
                         xtitle("residual") ytitle("fraction")            ///
                         legend(order(1 "residuals" 2 "fitted normal")    ///
                                rows(1) size(small) region(lstyle(none))) ///
                         `gopts' `sc' name(`name'_hist, replace)
                local made "`made' `name'_hist"

                qnorm `rres', title("Normal quantile plot", size(medium)) ///
                    mcolor(`C1'%70) msize(small)                        ///
                    rlopts(lcolor(`C2') lwidth(medthick))                 ///
                    ytitle("residual quantiles")                          ///
                    `gopts' `sc' name(`name'_qq, replace)
                local made "`made' `name'_qq"
            }

            if inlist("`sub'", "het", "all") {
                tempvar u2
                qui gen double `u2' = `rres'^2
                twoway (scatter `u2' `rfit', mcolor(`C1'%55) msize(small)) ///
                       (lowess `u2' `rfit', lcolor(`C2') lwidth(medthick))   ///
                       , title("Squared residuals vs fitted values",         ///
                               size(medium))                                ///
                         subtitle("a trend here is what the heteroskedasticity" ///
                                  " tests are detecting", size(vsmall))     ///
                         xtitle("fitted value") ytitle("squared residual")  ///
                         legend(order(1 "u{superscript:2}" 2 "lowess")      ///
                                rows(1) size(small) region(lstyle(none)))   ///
                         `gopts' `sc' name(`name'_het, replace)
                local made "`made' `name'_het"
            }
        }
    }

    *==================================================================
    * 4. CUSUM / CUSUMSQ with bootstrap bands
    *==================================================================
    if inlist("`sub'", "stab", "all") {
        * A Rademacher wild draw sets u* = +/- u, so |u*| = |u| exactly.
        * CUSUM of squares depends only on squared residuals, so under
        * that scheme every bootstrap path carries the same squares and
        * the band collapses onto the observed path.  Bands therefore use
        * the residual bootstrap, which resamples magnitudes.  The
        * p-values in the table still use whatever dgp() was requested.
        local bdgp = `dgp'
        local bnote ""
        if inlist(`dgp', 2, 3, 7) {
            local bdgp 1
            local bnote "Bands use the residual bootstrap: a Rademacher wild draw preserves |u| and would collapse the band."
        }

        tempname CB SB
        capture mata: bd_cusumband(`reps', `bdgp', `weight', `ftrans', ///
                                   `block', "`CB'", "`SB'")
        if _rc == 0 {
            preserve
            qui clear
            qui svmat double `CB', names(cu)
            qui gen int _t = _n
            qui drop if cu1 >= .
            qui count
            if r(N) > 2 {
                twoway (rarea cu2 cu3 _t, color(`CBND') lwidth(none))        ///
                       (line cu1 _t, lcolor(`C1') lwidth(medthick))        ///
                       , yline(0, lcolor(gs8) lpattern(dot))               ///
                         title("CUSUM of recursive residuals", size(medium)) ///
                         subtitle("with bootstrap 95% bands", size(small)) ///
                         xtitle("observation") ytitle("cumulative sum")    ///
                         legend(order(2 "CUSUM" 1 "bootstrap 95% band")    ///
                                rows(1) size(small) region(lstyle(none)))  ///
                         note("Pointwise quantiles of the bootstrap CUSUM paths under H0," ///
                              " not the Brown-Durbin-Evans asymptotic lines. `bnote'" ///
                              , size(vsmall))                              ///
                         `gopts' `sc' name(`name'_cusum, replace)
            }
            restore
            local made "`made' `name'_cusum"

            preserve
            qui clear
            qui svmat double `SB', names(sq)
            qui gen int _t = _n
            qui drop if sq1 >= .
            qui count
            if r(N) > 2 {
                twoway (rarea sq2 sq3 _t, color(`CBND') lwidth(none))        ///
                       (line sq1 _t, lcolor(`C3') lwidth(medthick))        ///
                       , title("CUSUM of squares", size(medium))           ///
                         subtitle("with bootstrap 95% bands", size(small)) ///
                         xtitle("observation")                             ///
                         ytitle("cumulative sum of squares")               ///
                         legend(order(2 "CUSUMSQ" 1 "bootstrap 95% band")  ///
                                rows(1) size(small) region(lstyle(none)))  ///
                         note("`bnote'", size(vsmall))                     ///
                         `gopts' `sc' name(`name'_cusumsq, replace)
            }
            restore
            local made "`made' `name'_cusumsq"
        }

        *--------------------------------------------------------------
        * Chow F sequence with the bootstrap supF critical value
        *--------------------------------------------------------------
        tempname FS
        capture mata: bd_chowseq(`trim', `reps', `bdgp', `weight', ///
                                 `ftrans', `block', "`FS'")
        if _rc == 0 {
            local supcv = r(bd_supcv)
            local supob = r(bd_supobs)
            local bkobs = r(bd_break)
            preserve
            qui clear
            qui svmat double `FS', names(fs)
            qui drop if fs2 >= .
            qui count
            if r(N) > 2 {
                twoway (line fs2 fs1, lcolor(`C1') lwidth(medthick))        ///
                       , yline(`supcv', lcolor(`C2') lpattern(dash)         ///
                               lwidth(medthick))                            ///
                         xline(`bkobs', lcolor(gs9) lpattern(dot))          ///
                         title("Chow F sequence", size(medium))             ///
                         subtitle("supF = `: di %6.3f `supob'' at observation `bkobs'" ///
                                  , size(small))                            ///
                         xtitle("candidate break point")                    ///
                         ytitle("Chow F statistic")                         ///
                         legend(off)                                        ///
                         note("Dashed line = 5% BOOTSTRAP critical value (`: di %6.3f `supcv'')," ///
                              " which accounts for having searched over every break point." ///
                              , size(vsmall))                               ///
                         `gopts' `sc' name(`name'_chow, replace)
                local made "`made' `name'_chow"
            }
            restore
        }
    }

    *==================================================================
    * 5. Residual correlogram with bootstrap bands
    *==================================================================
    if inlist("`sub'", "serial", "all") {
        tempname AC
        capture mata: bd_acfband(20, `reps', `dgp', `weight', `ftrans', ///
                                 `block', "`AC'")
        if _rc == 0 {
            preserve
            qui clear
            qui svmat double `AC', names(ac)
            qui gen int lag = _n
            qui drop if ac1 >= .
            qui count
            if r(N) > 2 {
                twoway (rarea ac2 ac3 lag, color(`CBND') lwidth(none))       ///
                       (bar  ac1 lag, barwidth(0.5) color(`C1'))           ///
                       , yline(0, lcolor(black))                           ///
                         title("Residual autocorrelations", size(medium))  ///
                         subtitle("with bootstrap 95% bands", size(small)) ///
                         xtitle("lag") ytitle("autocorrelation")           ///
                         legend(order(2 "r(k)" 1 "bootstrap 95% band")     ///
                                rows(1) size(small) region(lstyle(none)))  ///
                         note("Bands come from the same DGP as the reported p-values," ///
                              " so they are consistent with the Breusch-Godfrey results." ///
                              , size(vsmall))                              ///
                         `gopts' `sc' name(`name'_acf, replace)
                local made "`made' `name'_acf"
            }
            restore
        }
    }

    *==================================================================
    * 6. Combined panel
    *==================================================================
    local nmade : word count `made'
    if `nmade' > 1 {
        local cols = cond(`nmade' <= 2, 2, cond(`nmade' <= 4, 2, 3))
        capture graph combine `made', cols(`cols') ///
            title("bootdiag diagnostics", size(medsmall))                 ///
            `gopts' `sc' name(`name'_panel, replace)
        if _rc == 0 local made "`made' `name'_panel"
    }

    if `"`saving'"' != "" {
        capture graph export `"`saving'"', name(`name'_panel) replace
        if _rc capture graph export `"`saving'"', replace
    }

    di as txt ""
    di as txt _col(3) "Graphs created: " as res "`made'"
end
