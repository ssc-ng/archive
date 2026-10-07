*! jointdiag_arch 1.0.0  06oct2026
*! ARCH / AARCH and autocorrelation tested jointly and conditionally.
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*
*  SOURCES
*   Bera, Higgins & Lee (1992), JBES 10(2), 133-142
*     model (1.1): y_t = x_t'beta + eps_t,  eps_t = sum_j (phi_j + eta_jt) eps_{t-j} + u_t
*     (1.2)-(1.3): E(eps_t|F) = phi'eps_{t-} ,  h_t = sigma^2 + eps_{t-}' C eps_{t-}
*       C diagonal  -> Engle's ARCH ;  C full -> AARCH (their sec.1)
*     sec.3 : LM_{AARCH|AR}  = N R^2 from regressing u_t^2 on (1, z1t, z2t)
*                               z1t = lagged squares, z2t = distinct cross products
*             LM_{ARCH|AR}   = the same with C diagonal      ~ chi2(p)
*             LM_{AR|AARCH}  = N R^2 on the STANDARDISED residuals  ~ chi2(p)
*     sec.2 Proposition 1: stationarity needs
*             (a) eigenvalues of the AR companion matrix inside the unit circle
*             (b) w(phi) * sum_j gamma_j < 1
*           so autocorrelation can destroy the ARCH stationarity region
*   Bera & Lee (1993), REStud 60 : ARCH == random AR coefficients
*   Wooldridge (1990), Econometric Theory 6, 17-43 : the robust LM form
*     used for LM_{R-AR} in their Table 2
*   Engle (1982), Econometrica 50 : the ARCH LM test itself

program define jointdiag_arch, rclass
    version 14.0

    syntax [anything] [if] [in] [,   ///
        AR(integer 1)                 ///
        ARCHlags(integer 1)           ///
        AARCH                         ///
        ROBUST                        ///
        NOSTAtionarity                ///
        Level(cilevel)                ///
        GRaph                         ///
        NAME(string)                  ///
        NOTABle                       ///
    ]

    _jd_parse `anything' `if' `in'
    local dv   "`r(dv)'"
    local iv   "`r(iv)'"
    local post = r(post)

    marksample touse, novarlist
    markout `touse' `dv' `iv'
    if (`post') {
        tempvar esamp
        qui gen byte `esamp' = e(sample)
        qui replace `touse' = 0 if `esamp' == 0
    }
    if (`ar' < 1 | `archlags' < 1) {
        di as err "ar() and archlags() must be positive"
        exit 198
    }

    tempname _h
    capture _estimates hold `_h', restore nullok

    local p = `ar'
    local q = `archlags'
    local aa = ("`aarch'" != "")

    *=================================================== STEP 1  OLS null
    qui regress `dv' `iv' if `touse'
    tempvar e0
    qui predict double `e0' if e(sample), resid
    qui replace `touse' = 0 if missing(`e0')
    local N = e(N)

    tempname A
    mata: _jd_arch_naive("`e0'", "`touse'", `p', `q', `aa',  ///
                         ("`robust'" != ""), "`A'")
    local lmARCH0 = `A'[1,1]
    local dfARCH0 = `A'[1,2]
    local lmAR0   = `A'[2,1]
    local dfAR0   = `A'[2,2]
    local nuse    = `A'[3,1]

    local pARCH0 = chi2tail(`dfARCH0', `lmARCH0')
    local pAR0   = chi2tail(`dfAR0',   `lmAR0')
    local lmJ0   = `lmARCH0' + `lmAR0'
    local dfJ0   = `dfARCH0' + `dfAR0'
    local pJ0    = chi2tail(`dfJ0', `lmJ0')

    *=================================================== STEP 2  ARCH | AR
    * null model = linear regression with AR(p) errors
    tempvar e1
    local arok 1
    capture qui arima `dv' `iv' if `touse', ar(1/`p') nolog
    if (_rc) {
        capture qui prais `dv' `iv' if `touse', nolog
        if (_rc) local arok 0
    }
    if (`arok') {
        qui predict double `e1' if e(sample), resid
        tempname A1
        mata: _jd_arch_naive("`e1'", "`touse'", `p', `q', `aa', ///
                             ("`robust'" != ""), "`A1'")
        local lmARCH1 = `A1'[1,1]
        local dfARCH1 = `A1'[1,2]
        local pARCH1  = chi2tail(`dfARCH1', `lmARCH1')
    }
    else {
        local lmARCH1 = .
        local dfARCH1 = .
        local pARCH1  = .
    }

    *=================================================== STEP 3  AR | ARCH
    * null model = linear regression with ARCH(q) errors
    tempvar e2 h2 g2
    local aok 1
    capture qui arch `dv' `iv' if `touse', arch(1/`q') nolog
    if (_rc) local aok 0
    if (`aok') {
        qui predict double `e2' if e(sample), residuals
        qui predict double `h2' if e(sample), variance
        qui gen double `g2' = `e2' / sqrt(`h2') if `h2' > 0 & !missing(`h2')
        tempname A2
        mata: _jd_arch_arpart("`g2'", "`touse'", `p', ("`robust'" != ""), "`A2'")
        local lmAR1 = `A2'[1,1]
        local dfAR1 = `A2'[1,2]
        local pAR1  = chi2tail(`dfAR1', `lmAR1')
    }
    else {
        local lmAR1 = .
        local dfAR1 = .
        local pAR1  = .
    }

    *=================================================== STEP 4  full model
    local fok 1
    capture qui arch `dv' `iv' if `touse', ar(1/`p') arch(1/`q') nolog
    if (_rc) local fok 0
    local phis ""
    local gams ""
    local sumg = 0
    if (`fok') {
        local llf = e(ll)
        local aicf = -2*e(ll) + 2*e(k)
        forvalues j = 1/`p' {
            local b = _b[ARMA:L`j'.ar]
            local phis "`phis' `b'"
        }
        forvalues j = 1/`q' {
            local b = _b[ARCH:L`j'.arch]
            local gams "`gams' `b'"
            local sumg = `sumg' + `b'
        }
    }

    *=================================================== display
    if ("`notable'" == "") {
        local clab "ARCH(`q')"
        if (`aa') local clab "AARCH(`q')"
        _jd_head "ARCH and autocorrelation tested jointly - Bera, Higgins & Lee (1992)" ///
                 "Model: `dv' on `iv'    (N = `nuse')"                                  ///
                 "Conditional variance: `clab'     AR order tested: `p'"

        _jd_coln "Panel A: one-directional (OLS residuals)"
        _jd_row "LM(ARCH)   ignoring AR"      `lmARCH0' `dfARCH0' `pARCH0' "Engle (1982)"
        _jd_row "LM(AR)     ignoring ARCH"    `lmAR0'   `dfAR0'   `pAR0'   "Breusch-Godfrey"
        _jd_row "LM(AR + ARCH)  joint"        `lmJ0'    `dfJ0'    `pJ0'    "additive"
        di as txt "{hline 35}{c +}{hline 42}"

        di as txt %-34s "Panel B: each in the presence" " {c |}"
        di as txt %-34s "         of the other" " {c |}"
        _jd_row "LM(ARCH | AR(`p'))"           `lmARCH1' `dfARCH1' `pARCH1' "sec.3"
        _jd_row "LM(AR | `clab')"              `lmAR1'   `dfAR1'   `pAR1'   "standardised resid."
        di as txt "{hline 35}{c BT}{hline 42}"

        if ("`robust'" != "") {
            di as txt "  Robust (Wooldridge 1990) forms used throughout Panel A and B."
        }
        di as txt "  A gap between Panel A and Panel B is the whole point of the paper:"
        di as txt "  the usual test for one problem is not valid when the other is present."
        _jd_foot ""

    }

    *=================================================== stationarity
    local wphi = .
    local maxe = .
    local cond = .
    if ("`nostationarity'" == "" & `fok') {
        tempname W
        mata: _jd_arch_wphi("`phis'", "`W'")
        local wphi = `W'[1,1]
        local maxe = `W'[2,1]
        local cond = `wphi' * `sumg'

        if ("`notable'" == "") {
            local clab2 "ARCH(`q')"
            if (`aa') local clab2 "AARCH(`q')"
            _jd_head "Stationarity of the combined AR(`p') + `clab2' process"  ///
                     "Bera, Higgins & Lee (1992), Proposition 1"                ///
                     ""
            di as txt "  Estimated AR coefficients   : " as res "`phis'"
            di as txt "  Estimated ARCH coefficients : " as res "`gams'"
            di as txt "{hline 78}"
            di as txt %-44s "  (a) max |eigenvalue| of AR companion matrix" " {c |}" ///
               as res %12.6f `maxe' as txt "   < 1 ?  " ///
               as res cond(`maxe' < 1, "yes", "NO")
            di as txt %-44s "  (b) w(phi)" " {c |}" as res %12.6f `wphi'
            di as txt %-44s "      sum of ARCH coefficients" " {c |}" as res %12.6f `sumg'
            di as txt %-44s "      w(phi) * sum(gamma)" " {c |}" ///
               as res %12.6f `cond' as txt "   < 1 ?  " ///
               as res cond(`cond' < 1, "yes", "NO")
            di as txt "{hline 78}"
            if (`cond' < 1 & `maxe' < 1) {
                di as txt "  The process is second-order stationary."
            }
            else {
                di as err "  The process is NOT second-order stationary."
            }
            if (`sumg' < 1 & `cond' >= 1) {
                di as err "  Note: sum(gamma) = " %6.4f `sumg' " < 1, so the PURE ARCH"
                di as err "  stationarity condition holds, yet the combined process is"
                di as err "  non-stationary.  Autocorrelation has destroyed it (sec. 2)."
            }
            di as txt ""
        }
        return scalar wphi     = `wphi'
        return scalar sumg     = `sumg'
        return scalar statcond = `cond'
        return scalar maxeig   = `maxe'
    }

    *=================================================== graph
    if ("`graph'" != "") {
        if ("`name'" == "") local name "jd_arch"
        _jd_arch_graph `lmARCH0' `lmARCH1' `lmAR0' `lmAR1'  ///
                       `dfARCH0' `dfARCH1' `dfAR0' `dfAR1' `level' "`name'"
    }

    *=================================================== returns
    return scalar lm_arch      = `lmARCH0'
    return scalar df_arch      = `dfARCH0'
    return scalar p_arch       = `pARCH0'
    return scalar lm_ar        = `lmAR0'
    return scalar df_ar        = `dfAR0'
    return scalar p_ar         = `pAR0'
    return scalar lm_joint     = `lmJ0'
    return scalar df_joint     = `dfJ0'
    return scalar p_joint      = `pJ0'
    return scalar lm_arch_ar   = `lmARCH1'
    return scalar df_arch_ar   = `dfARCH1'
    return scalar p_arch_ar    = `pARCH1'
    return scalar lm_ar_arch   = `lmAR1'
    return scalar df_ar_arch   = `dfAR1'
    return scalar p_ar_arch    = `pAR1'
    return scalar N            = `nuse'
    return local  cmd          "jointdiag arch"
end


*-----------------------------------------------------------------------
program define _jd_arch_graph
    version 14.0
    args a0 a1 r0 r1 da0 da1 dr0 dr1 level name

    _jd_gstyle
    local gopt `"`r(gopt)'"'
    local a = (100 - `level') / 100

    preserve
    clear
    qui set obs 4
    qui gen byte id = _n
    qui gen double st = .
    qui gen double cv = .
    qui gen byte   grp = .
    qui replace st = `a0' in 1
    qui replace st = `a1' in 2
    qui replace st = `r0' in 3
    qui replace st = `r1' in 4
    qui replace cv = invchi2(`da0', 1-`a') in 1
    qui replace cv = invchi2(`da1', 1-`a') in 2
    qui replace cv = invchi2(`dr0', 1-`a') in 3
    qui replace cv = invchi2(`dr1', 1-`a') in 4
    qui replace grp = 1 in 1
    qui replace grp = 2 in 2
    qui replace grp = 1 in 3
    qui replace grp = 2 in 4
    qui drop if missing(st) | missing(cv)
    qui gen double ratio = st / cv
    label define _jdar 1 "ARCH, ignoring AR" 2 "ARCH, given AR" ///
                       3 "AR, ignoring ARCH" 4 "AR, given ARCH", replace
    label values id _jdar

    qui su ratio, meanonly
    local top = max(1.35, r(max)*1.2)

    twoway (bar ratio id if grp==1, horizontal barwidth(.5) ///
               color(gs9%75) lcolor(gs6) lwidth(thin))       ///
           (bar ratio id if grp==2, horizontal barwidth(.5) ///
               color(navy%80) lcolor(navy) lwidth(thin)),    ///
           yscale(reverse) ylabel(1(1)4, valuelabel labsize(small)) ///
           ytitle("") xtitle("LM / critical value", size(small))     ///
           xline(1, lcolor(maroon) lpattern(dash))                   ///
           xscale(range(0 `top'))                                     ///
           title("ARCH and autocorrelation: naive vs corrected", size(medium)) ///
           subtitle("Bera, Higgins & Lee (1992)", size(small))        ///
           note("A shift between the grey and navy bar is the interaction effect.", ///
                size(vsmall))                                         ///
           legend(order(1 "one-directional" 2 "in the presence of the other") ///
                  ring(0) pos(5) region(lcolor(white)) size(small) cols(1))    ///
           `gopt' name(`name', replace)
    restore
end



