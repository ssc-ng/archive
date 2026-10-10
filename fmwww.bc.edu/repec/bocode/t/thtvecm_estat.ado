*! thtvecm_estat 1.0.0  02oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Post-estimation for thtvecm.
*!   regimes   regime sizes, the two coefficient matrices and the two speeds
*!             of adjustment
*!   ecplot    the error-correction term against time with the threshold drawn
*!   adjust    the adjustment coefficients side by side with a Wald test that
*!             they are equal
*!   bootdist  the bootstrap distribution of the SupLM statistic
*!   table     a publication summary of the fit
*!   serial    system LM test of no residual autocorrelation
*!   archlm    Lutkepohl multivariate ARCH-LM
*!   normality Jarque-Bera on the orthogonalised residuals
*!   diag      all three of the above in one table

program define thtvecm_estat, rclass
    version 15
    if "`e(cmd)'" != "thtvecm" {
        display as error "last estimates not found, or not from {bf:thtvecm}"
        exit 301
    }
    gettoken sub 0 : 0, parse(" ,")
    local l = strlen("`sub'")
    if `l' == 0 {
        display as error "estat subcommand required"
        exit 198
    }
    if "`sub'" == substr("regimes", 1, max(4, `l')) {
        Regimes `0'
        return add
        exit
    }
    if "`sub'" == substr("ecplot", 1, max(2, `l')) {
        Ecplot `0'
        return add
        exit
    }
    if "`sub'" == substr("adjust", 1, max(3, `l')) {
        Adjust `0'
        return add
        exit
    }
    if "`sub'" == substr("bootdist", 1, max(4, `l')) {
        Bootdist `0'
        return add
        exit
    }
    if "`sub'" == substr("table", 1, max(3, `l')) {
        Table `0'
        exit
    }
    if "`sub'" == substr("seotest", 1, max(3, `l')) {
        Seotest `0'
        return add
        exit
    }
    if inlist("`sub'", "serial", "archlm", "normality", "diag") {
        Mvdiag "`sub'" `0'
        return add
        exit
    }
    display as error "unknown estat subcommand {bf:`sub'}"
    display as error "available: regimes ecplot adjust bootdist seotest"
    display as error "           table serial archlm normality diag"
    exit 198
end

* ======================================================================
* Multivariate residual diagnostics, against the regime-split VECM design.
* ======================================================================
program define Mvdiag, rclass
    version 15
    gettoken which 0 : 0
    syntax [, LAGs(integer 4) ]
    if "`which'" == "diag"   local which "serial arch normality"
    if "`which'" == "archlm" local which "arch"

    local yv "`e(depvars)'"
    local p  = e(lags)
    local hc = e(hascons)
    tempname BE GAM
    matrix `BE' = e(beta)
    scalar `GAM' = e(gamma)

    capture drop __tkm_*
    quietly generate byte __tkm_touse = e(sample)
    quietly generate double __tkm_ec = 0 if __tkm_touse
    local j 0
    foreach v of local yv {
        local ++j
        quietly replace __tkm_ec = __tkm_ec + `BE'[1,`j'] * L.`v' if __tkm_touse
    }
    local wv ""
    local nw 0
    forvalues i = 1/`p' {
        foreach v of local yv {
            local ++nw
            quietly generate double __tkm_w`nw' = L`i'.D.`v' if __tkm_touse
            local wv `wv' __tkm_w`nw'
        }
    }
    quietly generate byte __tkm_d1 = (__tkm_ec <= `GAM') if __tkm_touse
    quietly generate byte __tkm_d2 = (__tkm_ec >  `GAM') if __tkm_touse
    local xl ""
    local nx 0
    forvalues r = 1/2 {
        if `hc' {
            local ++nx
            quietly generate double __tkm_x`nx' = __tkm_d`r' if __tkm_touse
            local xl `xl' __tkm_x`nx'
        }
        local ++nx
        quietly generate double __tkm_x`nx' = __tkm_ec * __tkm_d`r' if __tkm_touse
        local xl `xl' __tkm_x`nx'
        foreach v of local wv {
            local ++nx
            quietly generate double __tkm_x`nx' = `v' * __tkm_d`r' if __tkm_touse
            local xl `xl' __tkm_x`nx'
        }
    }
    local el ""
    local i 0
    foreach v of local yv {
        local ++i
        quietly predict double __tkm_e`i' if __tkm_touse, residuals equation(`i')
        local el `el' __tkm_e`i'
    }
    _tk_drop __tkm_E __tkm_X
    mkmat `el' if __tkm_touse, matrix(__tkm_E)
    mkmat `xl' if __tkm_touse, matrix(__tkm_X)

    local dl ""
    foreach v of local yv {
        local dl `dl' D_`v'
    }
    _tk_mvdiag , emat(__tkm_E) xmat(__tkm_X) lags(`lags') ///
        eqnames("`dl'") which("`which'") model("thtvecm")
    return add
    _tk_drop __tkm_E __tkm_X
    capture drop __tkm_*
end

* ======================================================================
program define Regimes, rclass
    version 15
    tempname A1 A2 D BE
    matrix `A1' = e(A1)
    matrix `A2' = e(A2)
    matrix `D'  = `A2' - `A1'
    matrix `BE' = e(beta)
    local bstr ""
    forvalues j = 1/`=colsof(`BE')' {
        local bj : display %8.5f `BE'[1,`j']
        local bstr "`bstr' `=trim("`bj'")'"
    }
    display _n as text "Regimes of the threshold VECM"
    display as text "{hline 72}"
    display as text "  Cointegrating vector beta" _col(44) as result "`bstr'"
    display as text "  beta from" _col(44) as result "`e(beta_src)'"
    display as text "  Threshold on beta'y(t-1)" _col(44) as result %14.6g e(gamma)
    display as text "  Regime 1 (ec <= gamma) observations" _col(44) ///
        as result %14.0fc e(N_regime1)
    display as text "  Regime 2 (ec >  gamma) observations" _col(44) ///
        as result %14.0fc e(N_regime2)
    display as text "{hline 72}"
    display _n as text "Regime 1 coefficients"
    matrix list `A1', noheader format(%9.5f)
    display _n as text "Regime 2 coefficients"
    matrix list `A2', noheader format(%9.5f)
    display _n as text "Difference, regime 2 - regime 1"
    matrix list `D', noheader format(%9.5f)
    return matrix diff = `D', copy
    return matrix A2 = `A2'
    return matrix A1 = `A1'
end

* ======================================================================
* The speeds of adjustment side by side, with a Wald test that they are the
* same in both regimes. Seo (2007) shows that beta converges at n^(3/2) here,
* so treating it as known leaves the short-run Wald tests valid.
* ======================================================================
program define Adjust, rclass
    version 15
    local yv "`e(depvars)'"
    local k  = e(k_var)
    local kw : word count `e(wnames)'
    local hc = e(hascons)
    local ecrow = `hc' + 1
    tempname b V out
    matrix `b' = e(b)
    matrix `V' = e(V)
    matrix `out' = J(`k', 6, .)
    local rn ""
    local i 0
    local cons ""
    foreach d of local yv {
        local ++i
        local i1 = (`i' - 1) * `kw' + `ecrow'
        local i2 = `k' * `kw' + (`i' - 1) * `kw' + `ecrow'
        local a1 = `b'[1,`i1']
        local a2 = `b'[1,`i2']
        local s1 = sqrt(`V'[`i1',`i1'])
        local s2 = sqrt(`V'[`i2',`i2'])
        local vd = `V'[`i1',`i1'] + `V'[`i2',`i2'] - 2*`V'[`i1',`i2']
        matrix `out'[`i',1] = `a1'
        matrix `out'[`i',2] = `s1'
        matrix `out'[`i',3] = `a2'
        matrix `out'[`i',4] = `s2'
        matrix `out'[`i',5] = `a2' - `a1'
        if `vd' > 0 matrix `out'[`i',6] = 2*normal(-abs((`a2'-`a1')/sqrt(`vd')))
        local rn `rn' `d'
        local cons `cons' [R1_D_`d']ec = [R2_D_`d']ec
    }
    matrix rownames `out' = `rn'
    matrix colnames `out' = ec_regime1 se1 ec_regime2 se2 difference p_diff

    display _n as text "Speed of adjustment by regime"
    display as text "  The coefficient on {bf:ec} is the fraction of the gap to"
    display as text "  equilibrium that is closed in one period. A coefficient that is"
    display as text "  negative in one regime and zero in the other is the signature of"
    display as text "  a band of inaction (compare {bf:thmtar, band})."
    matrix list `out', noheader format(%10.5f)

    capture test `cons'
    if !_rc {
        display _n as text "  Joint Wald test that every speed of adjustment is the same"
        display as text "  in both regimes:  chi2(" as result %2.0f r(df) ///
            as text ") = " as result %9.4f r(chi2) as text ",  p = " ///
            as result %6.4f r(p)
        return scalar p_joint = r(p)
        return scalar chi2_joint = r(chi2)
        return scalar df_joint = r(df)
    }
    return matrix adjust = `out'
end

* ======================================================================
program define Ecplot, rclass
    version 15
    syntax [, SAVing(string asis) * ]
    local yv "`e(depvars)'"
    tempname BE
    matrix `BE' = e(beta)
    tempvar touse ecv
    quietly generate byte `touse' = e(sample)
    quietly generate double `ecv' = 0 if `touse'
    local j 0
    foreach v of local yv {
        local ++j
        quietly replace `ecv' = `ecv' + `BE'[1,`j'] * L.`v' if `touse'
    }
    quietly summarize `ecv' if `touse'
    display _n as text "Error-correction term beta'y(t-1)"
    display as text "{hline 66}"
    display as text "  mean / s.d." _col(40) as result %11.6f r(mean) " " %11.6f r(sd)
    display as text "  range" _col(40) as result %11.6f r(min) " " %11.6f r(max)
    display as text "  threshold" _col(40) as result %11.6f e(gamma)
    display as text "{hline 66}"
    return scalar ec_min = r(min)
    return scalar ec_max = r(max)
    twoway (line `ecv' `e(timevar)' if `touse', lcolor(navy))     ///
        , yline(`=e(gamma)', lcolor(red) lpattern(dash))          ///
          ytitle("beta'y(t-1)") xtitle("`e(timevar)'")            ///
          title("Error-correction term and the estimated threshold") ///
          legend(off) `options'
    if `"`saving'"' != "" _tk_gsave `saving'
end

* ======================================================================
program define Bootdist, rclass
    version 15
    syntax [, GRaph BINs(integer 30) SAVing(string asis) * ]
    capture confirm matrix e(bdist)
    if _rc {
        display as error "no bootstrap distribution stored; refit with {bf:test}"
        exit 498
    }
    tempname D
    matrix `D' = e(bdist)
    display _n as text "Bootstrap distribution of the `e(teststat)'-LM statistic"
    display as text "{hline 66}"
    display as text "  replications" _col(46) as result %14.0f rowsof(`D')
    display as text "  observed statistic" _col(46) as result %14.4f e(lm)
    display as text "  bootstrap p-value" _col(46) as result %14.4f e(p)
    display as text "  Monte Carlo s.e. of the p-value" _col(46) as result %14.4f e(p_mcse)
    display as text "{hline 66}"
    display as text "  Under H0 the threshold is unidentified, so the critical values"
    display as text "  are not chi-square: Hansen and Seo (2002) simulate them with the"
    display as text "  design held fixed, which is what this distribution is."
    return matrix bdist = `D', copy
    if "`graph'" != "" {
        preserve
            quietly {
                clear
                svmat double `D', names(lmb)
                keep if lmb1 < .
            }
            twoway (histogram lmb1, bin(`bins') fcolor(gs12) lcolor(gs6)) ///
                , xline(`=e(lm)', lcolor(red) lwidth(medthick))           ///
                  xtitle("bootstrap `e(teststat)'-LM") ytitle("density")  ///
                  title("Hansen-Seo bootstrap under a linear VECM")       ///
                  legend(off) `options'
            if `"`saving'"' != "" _tk_gsave `saving'
        restore
    }
end

* ======================================================================
program define Table
    version 15
    tempname BE
    matrix `BE' = e(beta)
    local bstr ""
    forvalues j = 1/`=colsof(`BE')' {
        local bj : display %8.5f `BE'[1,`j']
        local bstr "`bstr' `=trim("`bj'")'"
    }
    display _n as text "{hline 78}"
    display as text "Threshold vector error correction model -- summary"
    display as text "{hline 78}"
    display as text "  Variables" _col(46) as result "`e(depvars)'"
    display as text "  Cointegrating vector" _col(46) as result "`bstr'"
    display as text "  beta from" _col(46) as result "`e(beta_src)'"
    display as text "  Lags of D" _col(46) as result %12.0f e(lags)
    display as text "  Observations" _col(46) as result %12.0fc e(N)
    display as text "{hline 78}"
    display as text "  Threshold on the error-correction term" _col(46) ///
        as result %12.6g e(gamma)
    display as text "  Regime sizes" _col(40) as result ///
        %11.0fc e(N_regime1) " " %11.0fc e(N_regime2)
    display as text "{hline 78}"
    display as text "  ln|Sigma|" _col(46) as result %12.5f e(lndet)
    display as text "  ln|Sigma| of the linear VECM" _col(46) as result %12.5f e(lndet0)
    display as text "  log likelihood" _col(46) as result %12.4f e(ll)
    display as text "  log likelihood of the linear VECM" _col(46) as result %12.4f e(ll_0)
    display as text "{hline 78}"
    if e(p) < . {
        display as text "  `e(teststat)'-LM" _col(46) as result %12.4f e(lm) ///
            as text "   bootstrap p = " as result %6.4f e(p)
        display as text "{hline 78}"
    }
end

* ======================================================================
* estat seotest -- Seo (2006) sup-Wald test of NO COINTEGRATION against
* threshold cointegration.
*
* This is a DIFFERENT null from the Hansen-Seo test that thtvecm, test
* reports. Hansen-Seo takes cointegration as given and asks whether the
* adjustment is threshold-dependent; Seo asks whether there is any
* error correction at all, allowing the alternative to be
* regime-dependent. A series can easily fail one and pass the other, and
* the order matters: establish cointegration first, then ask about the
* threshold.
*
* Under the null the system is a VAR in differences, so w(t-1) is a unit
* root process and the statistic's limit is non-standard AND size
* distorted at realistic sample lengths. Seo therefore bootstraps under
* the unit-root null by building the levels back up from the restricted
* residuals, which is what tk_seo_boot does. No asymptotic p-value is
* offered, deliberately: there is no table that would be honest here.
* ======================================================================
program define Seotest, rclass
    version 15
    syntax [, REPS(integer 500) STAT(string) BOOT(string) SEED(string) ///
              GRIDn(integer 0) MINOBS(integer 0) TRIM(real 0)          ///
              GRaph BINs(integer 30) SAVing(string asis) * ]

    if "`stat'" == "" local stat sup
    local statnum = .
    if "`stat'" == "sup" local statnum 1
    if "`stat'" == "ave" local statnum 2
    if "`stat'" == "exp" local statnum 3
    if `statnum' == . {
        display as error "stat() must be sup, ave or exp"
        exit 198
    }
    if "`boot'" == "" local boot resample
    if !inlist("`boot'", "resample", "wild") {
        display as error "boot() must be resample or wild"
        exit 198
    }
    local boottype `boot'
    if `reps' < 0 {
        display as error "reps() must be 0 or more"
        exit 198
    }
    if "`seed'" != "" set seed `seed'
    if `trim' == 0 local trim = e(trim)
    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "trim() must be in (0, 0.5)"
        exit 198
    }

    local yvars "`e(depvars)'"
    local lagsn = e(lags)
    local hascons = e(hascons)
    tempvar touse
    quietly generate byte `touse' = e(sample)

    * ---- rebuild the design the fit used, from the SAME sample
    local dvars ""
    local levelvars ""
    local dlagvars ""
    foreach v of local yvars {
        tempvar d_`v' l_`v'
        quietly generate double `d_`v'' = D.`v' if `touse'
        quietly generate double `l_`v'' = L.`v' if `touse'
        local dvars `dvars' `d_`v''
        local levelvars `levelvars' `l_`v''
    }
    forvalues j = 1/`lagsn' {
        foreach v of local yvars {
            tempvar dl`j'_`v'
            quietly generate double `dl`j'_`v'' = L`j'.D.`v' if `touse'
            local dlagvars `dlagvars' `dl`j'_`v''
        }
    }

    * ---- the cointegrating vector is the FITTED one, not re-estimated:
    *      re-estimating it inside the test would change the null
    tempname BE
    matrix `BE' = e(beta)
    local betavec ""
    forvalues j = 1/`=colsof(`BE')' {
        local bj = `BE'[1,`j']
        local betavec `betavec' `bj'
    }

    mata: tk_thseo()

    if __tk_seofail == 1 {
        _tk_drop
        display as error "the trimmed threshold grid is empty: trim() too"
        display as error "large, or too few observations"
        exit 498
    }
    if __tk_seofail == 2 {
        _tk_drop
        display as error "the `stat' statistic could not be computed at any"
        display as error "admissible threshold"
        exit 498
    }

    tempname SUP AVE EXPS GM P NN NG PATH BD
    scalar `SUP'  = __tk_seosup
    scalar `AVE'  = __tk_seoave
    scalar `EXPS' = __tk_seoexp
    scalar `GM'   = __tk_seogmax
    scalar `P'    = __tk_seop
    scalar `NN'   = __tk_seon
    scalar `NG'   = __tk_seong
    matrix `PATH' = __tk_seopath
    local hasbd = 0
    capture confirm matrix __tk_seobd
    if !_rc {
        matrix `BD' = __tk_seobd
        local hasbd = 1
    }
    _tk_drop

    local obs = cond(`statnum'==1, `SUP', cond(`statnum'==2, `AVE', `EXPS'))

    display _n as text "Seo (2006) test of no cointegration vs threshold cointegration"
    display as text "{hline 72}"
    display as text "  H0: no error correction in any regime (a VAR in differences)"
    display as text "  H1: error correction in at least one outer regime"
    display as text "{hline 72}"
    display as text "  observations" _col(50) as result %20.0f `NN'
    display as text "  thresholds searched" _col(50) as result %20.0f `NG'
    display as text "  trimming" _col(50) as result %20.4f `trim'
    display as text "  sup-Wald" _col(50) as result %20.4f `SUP'
    display as text "  ave-Wald" _col(50) as result %20.4f `AVE'
    display as text "  exp-Wald" _col(50) as result %20.4f `EXPS'
    display as text "  argmax threshold" _col(50) as result %20.4f `GM'
    if `P' < . {
        display as text "  bootstrap p-value (`stat'-Wald, `reps' reps)" ///
            _col(50) as result %20.4f `P'
        display as text "  Monte Carlo s.e." _col(50) as result %20.4f ///
            sqrt(`P'*(1-`P')/`reps')
    }
    else {
        display as text "  bootstrap p-value" _col(50) as result %20s "not computed"
    }
    display as text "{hline 72}"

    if `P' < . {
        if `P' < 0.05 {
            display as text "  Cointegration is not rejected as absent -- that is,"
            display as text "  the no-cointegration null IS rejected, so there is"
            display as text "  error correction in at least one outer regime."
            display as text "  Now ask whether it is threshold-dependent:"
            display as text "  refit with {bf:thtvecm ..., test}, which tests a"
            display as text "  DIFFERENT null (linear adjustment, given"
            display as text "  cointegration)."
        }
        else {
            display as text "  The no-cointegration null is NOT rejected. A"
            display as text "  threshold VECM fitted to these data is then"
            display as text "  describing adjustment towards a long-run relation"
            display as text "  for which there is no evidence, and its"
            display as text "  error-correction coefficients should not be"
            display as text "  reported as such. Model the differences instead,"
            display as text "  or reconsider the cointegrating vector."
        }
    }
    display as text ""
    display as text "  The bootstrap imposes the UNIT ROOT null: the levels are"
    display as text "  rebuilt by cumulating the restricted residuals, so each"
    display as text "  replication has no cointegration by construction, and the"
    display as text "  threshold search is repeated inside every replication."
    display as text "  The asymptotic distribution is non-standard and size"
    display as text "  distorted at these sample lengths, so no asymptotic"
    display as text "  p-value is reported."

    return scalar sup   = `SUP'
    return scalar ave   = `AVE'
    return scalar exp   = `EXPS'
    return scalar stat  = `obs'
    return scalar gamma = `GM'
    return scalar p     = `P'
    return scalar N     = `NN'
    return scalar n_grid = `NG'
    return scalar reps  = `reps'
    return scalar trim  = `trim'
    return local  teststat "`stat'"
    return local  boot  "`boottype'"
    return matrix path  = `PATH', copy
    if `hasbd' return matrix bdist = `BD', copy

    if "`graph'" != "" & `hasbd' {
        preserve
            quietly {
                clear
                svmat double `BD', names(seob)
                keep if seob1 < .
            }
            twoway (histogram seob1, bin(`bins') fcolor(gs12) lcolor(gs6)) ///
                , xline(`=`obs'', lcolor(red) lwidth(medthick))            ///
                  xtitle("bootstrap `stat'-Wald") ytitle("density")         ///
                  title("Seo (2006) bootstrap under no cointegration")      ///
                  subtitle("red line: observed statistic")                  ///
                  legend(off) `options'
            if `"`saving'"' != "" _tk_gsave `saving'
        restore
    }
    else if "`graph'" != "" {
        display as error "no bootstrap distribution to graph; set {bf:reps()} > 0"
    }
end
