*! jointdiag_all 1.0.0  06oct2026
*! The full dashboard: every joint diagnostic in one pass, with a
*! compact verdict table and a combined graph.
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)

program define jointdiag_all, rclass
    version 14.0

    syntax [anything] [if] [in] [,   ///
        Lags(integer 1)               ///
        ARCHlags(integer 1)           ///
        HET(varlist numeric ts)       ///
        Level(cilevel)                ///
        FAST                          ///
        GRaph                         ///
        NAME(string)                  ///
    ]

    _jd_parse `anything' `if' `in'
    local dv "`r(dv)'"
    local iv "`r(iv)'"

    if ("`name'" == "") local name "jd_dash"
    local a = (100 - `level') / 100

    di as txt ""
    di as txt "{hline 78}"
    di as res "  jointdiag - full joint-diagnostic dashboard"
    di as txt "  Model: " as res "`dv'" as txt " on " as res "`iv'"
    di as txt "{hline 78}"

    *------------------------------------------------ 1. LM four directions
    qui jointdiag lm `dv' `iv' `if' `in', lags(`lags') het(`het') notable
    local lmN = r(lm_N)
    local pN  = r(p_N)
    local lmH = r(lm_H)
    local pH  = r(p_H)
    local lmI = r(lm_I)
    local pI  = r(p_I)
    local lmF = r(lm_F)
    local pF  = r(p_F)
    local lmA = r(lm_NHIF)
    local dA  = r(df_NHIF)
    local pA  = r(p_NHIF)
    local NN  = r(N)

    *------------------------------------------------ 2. IM decomposition
    qui jointdiag im `dv' `iv' `if' `in', ar(0) archlags(`archlags') notable
    local T1 = r(T1)
    local pT1 = r(p1)
    local T2 = r(T2)
    local pT2 = r(p2)
    local T5 = r(T5)
    local pT5 = r(p5)
    local T3 = r(T3)
    local pT3 = r(p3)

    *------------------------------------------------ 3. ARCH vs AR
    qui jointdiag arch `dv' `iv' `if' `in', ar(`lags') archlags(`archlags') ///
        nostationarity notable
    local aA0 = r(lm_arch)
    local paA0 = r(p_arch)
    local aA1 = r(lm_arch_ar)
    local paA1 = r(p_arch_ar)
    local aR0 = r(lm_ar)
    local paR0 = r(p_ar)
    local aR1 = r(lm_ar_arch)
    local paR1 = r(p_ar_arch)

    *------------------------------------------------ 4. bilinearity
    qui jointdiag bilinear `dv' `iv' `if' `in', archlags(`archlags') notable
    local bL = r(lm_bilinear)
    local pbL = r(p_bilinear)
    local bJ = r(lm_joint)
    local pbJ = r(p_joint)

    *------------------------------------------------ 5. score tests
    qui jointdiag score `dv' `iv' `if' `in', ar(`lags') het(`het') bilinear notable
    local sc = r(S)
    local psc = r(p)

    *------------------------------------------------ table
    di as txt ""
    di as txt %-44s "Diagnostic" " {c |}" %12s "statistic" %10s "p-value"
    di as txt "{hline 45}{c +}{hline 32}"

    _jd_all_row "LM  normality (N)"                        `lmN' `pN'
    _jd_all_row "LM  homoskedasticity (H)"                  `lmH' `pH'
    _jd_all_row "LM  serial independence (I)"               `lmI' `pI'
    _jd_all_row "LM  functional form (F)"                   `lmF' `pF'
    di as txt "{hline 45}{c +}{hline 32}"
    _jd_all_row "LM  four-directional  N+H+I+F"             `lmA' `pA'
    di as txt "{hline 45}{c +}{hline 32}"
    _jd_all_row "IM  heteroskedasticity  (Hall T1n)"        `T1'  `pT1'
    _jd_all_row "IM  skewness            (Hall T2n)"        `T5'  `pT5'
    _jd_all_row "IM  kurtosis            (Hall T3n)"        `T3'  `pT3'
    _jd_all_row "IM  conditional het.    (Bera-Lee T2)"     `T2'  `pT2'
    di as txt "{hline 45}{c +}{hline 32}"
    _jd_all_row "ARCH  ignoring autocorrelation"            `aA0' `paA0'
    _jd_all_row "ARCH  given AR(`lags')"                    `aA1' `paA1'
    _jd_all_row "AR    ignoring ARCH"                       `aR0' `paR0'
    _jd_all_row "AR    given ARCH(`archlags')"              `aR1' `paR1'
    di as txt "{hline 45}{c +}{hline 32}"
    _jd_all_row "bilinearity"                               `bL'  `pbL'
    _jd_all_row "ARCH + bilinearity jointly"                `bJ'  `pbJ'
    _jd_all_row "score  autocorrelation + variance"         `sc'  `psc'
    di as txt "{hline 45}{c BT}{hline 32}"
    di as txt "  N = `NN'    Significance: {bf:*} 10%  {bf:**} 5%  {bf:***} 1%"

    *------------------------------------------------ verdict
    di as txt ""
    di as txt "{hline 78}"
    di as res "  Verdict"
    di as txt "{hline 78}"
    local nrej 0
    if (`pN' < `a') {
        di as txt "  - non-normal residuals: inference on t and F is suspect in"
        di as txt "    small samples; consider a transformation or robust errors."
        local ++nrej
    }
    if (`pH' < `a') {
        di as txt "  - heteroskedasticity: use {bf:regress, robust} or model the variance."
        local ++nrej
    }
    if (`pI' < `a') {
        di as txt "  - serial correlation: BUT check the functional form first -"
        di as txt "    Savin & White (1978) show a wrong functional form reads as AR."
        di as txt "    Run {bf:jointdiag bc `dv' `iv', rho} to separate the two."
        local ++nrej
    }
    if (`pF' < `a') {
        di as txt "  - functional form / omitted variables."
        local ++nrej
    }
    if (`paA0' < `a' & `paA1' >= `a') {
        di as txt "  - the ARCH signal DISAPPEARS once autocorrelation is allowed:"
        di as txt "    it was autocorrelation masquerading as ARCH"
        di as txt "    (Bera, Higgins & Lee 1992)."
        local ++nrej
    }
    if (`paR0' < `a' & `paR1' >= `a') {
        di as txt "  - the autocorrelation signal DISAPPEARS once ARCH is allowed:"
        di as txt "    standard AR tests are not valid under ARCH (Diebold 1986)."
        local ++nrej
    }
    if (`paA1' < `a' & `paR1' < `a') {
        di as txt "  - ARCH and autocorrelation are BOTH present after conditioning"
        di as txt "    on each other: estimate them jointly and check the"
        di as txt "    stationarity condition w(phi) * sum(gamma) < 1."
        local ++nrej
    }
    if (`nrej' == 0) {
        di as txt "  No direction rejects at the `=100-`level''% level."
        di as txt "  Remember: four one-directional tests at level a have an overall"
        di as txt "  level near 4a.  See {bf:jointdiag lm ..., mcp} for the controlled"
        di as txt "  multiple-comparison version."
    }
    di as txt "{hline 78}"
    di as txt ""

    *------------------------------------------------ graphs
    if ("`graph'" != "") {
        qui jointdiag lm   `dv' `iv' `if' `in', lags(`lags') het(`het') ///
             notable graph name(`name'_lm)
        qui jointdiag im   `dv' `iv' `if' `in', ar(0) archlags(`archlags') ///
             notable graph name(`name'_im)
        qui jointdiag arch `dv' `iv' `if' `in', ar(`lags') archlags(`archlags') ///
             nostationarity notable graph name(`name'_ar)
        graph combine `name'_lm `name'_im `name'_ar, cols(2)              ///
              graphregion(color(white)) imargin(small)                     ///
              title("jointdiag dashboard: `dv'", size(medium))             ///
              name(`name', replace)
    }

    return scalar lm_NHIF = `lmA'
    return scalar p_NHIF  = `pA'
    return scalar N       = `NN'
    return scalar nflags  = `nrej'
    return local  cmd     "jointdiag all"
end


program define _jd_all_row
    version 14.0
    args lab stat p
    _jd_stars `p'
    if (`stat' >= .) {
        di as txt %-44s "`lab'" " {c |}" as txt %12s "." as txt %10s "."
    }
    else {
        di as txt %-44s "`lab'" " {c |}" as res %12.4f `stat' ///
           as res %10.4f `p' " " as res "`r(stars)'"
    }
end
