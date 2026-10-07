*! jointdiag_lm 1.0.0  06oct2026
*! Four-directional LM test: normality, heteroskedasticity, serial
*! independence and functional form, with all 2^4-1 sub-combinations
*! and the Bera-Jarque multiple comparison procedure.
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*
*  SOURCES
*   Jarque & Bera (1980), Economics Letters 6, 255-259, eq.(4)
*       LM_NHI = LM_N + LM_H + LM_I
*   Bera  & Jarque (1982), J. Econometrics 20, 59-82, eq.(4) and sec.5
*       LM_NHIF = LM_N + LM_H + LM_I + LM_F  ~ chi2(2+q+p+r+L)
*       additivity from block diagonality of (J22 - J21 J11^-1 J12)
*       MCP: steps (i)-(iv), p.75
*   Higgins & Bera (1988), Econometric Reviews 7(2), sec.2
*       Bera-McKenzie necessary and sufficient condition for additivity
*   Koenker (1981), J. Econometrics 17, 107-112  (studentised LM_H)
*   Engle (1979) / Ramsey (1969) / Thursby & Schmidt (1977)  (LM_F)

program define jointdiag_lm, rclass
    version 14.0

    syntax [anything] [if] [in] [,          ///
        Lags(integer 1)                      ///
        HET(varlist numeric ts)              ///
        RHS                                  ///
        FUNC(varlist numeric ts)             ///
        RESET(integer 4)                     ///
        TSpowers                             ///
        STUDentize                           ///
        DFadj                                ///
        FULLbg                               ///
        MCP                                  ///
        SIM(integer 0)                       ///
        SEED(integer 0)                      ///
        Level(cilevel)                       ///
        GRaph                                ///
        NAME(string)                         ///
        NOTABle                              ///
    ]

    *-------------------------------------------------- parse / sample
    _jd_parse `anything' `if' `in'
    local dv   "`r(dv)'"
    local iv   "`r(iv)'"
    local post = r(post)

    marksample touse, novarlist
    markout `touse' `dv' `iv' `het' `func'

    if (`post') {
        tempvar esamp
        qui gen byte `esamp' = e(sample)
        qui replace `touse' = 0 if `esamp' == 0
    }

    if (`lags' < 1) {
        di as err "lags() must be a positive integer"
        exit 198
    }
    if (`reset' < 2) {
        di as err "reset() must be at least 2"
        exit 198
    }

    *-------------------------------------------------- protect e()
    tempname _h
    capture _estimates hold `_h', restore nullok

    *-------------------------------------------------- base OLS fit
    qui regress `dv' `iv' if `touse'
    local N  = e(N)
    local k  = e(df_m) + 1
    tempvar res yhat
    qui predict double `res'  if e(sample), resid
    qui predict double `yhat' if e(sample), xb
    qui replace `touse' = 0 if missing(`res')

    *-------------------------------------------------- Z for LM_H
    if ("`het'" != "" & "`rhs'" != "") {
        di as err "specify het() or rhs, not both"
        exit 198
    }
    if ("`rhs'" != "")      local zv "`iv'"
    else if ("`het'" != "") local zv "`het'"
    else                    local zv ""          // -> fitted values

    *-------------------------------------------------- W for LM_F
    if ("`func'" != "" & "`tspowers'" != "") {
        di as err "specify func() or tspowers, not both"
        exit 198
    }

    *-------------------------------------------------- Mata workhorse
    tempname B
    mata: _jd_lm_core("`dv'", "`iv'", "`zv'", "`func'", "`touse'",  ///
                      "`res'", "`yhat'", `lags', `reset',          ///
                      ("`tspowers'" != ""), ("`studentize'" != ""), ///
                      ("`dfadj'" != ""), ("`fullbg'" != ""), "`B'")

    *-------------------------------------------------- unpack
    local lmN  = `B'[1,1]
    local lmH  = `B'[2,1]
    local lmI  = `B'[3,1]
    local lmF  = `B'[4,1]
    local dfN  = `B'[1,2]
    local dfH  = `B'[2,2]
    local dfI  = `B'[3,2]
    local dfF  = `B'[4,2]
    local skew = `B'[5,1]
    local kurt = `B'[5,2]
    local nuse = `B'[6,1]

    local lmNH   = `lmN' + `lmH'
    local lmNI   = `lmN' + `lmI'
    local lmNF   = `lmN' + `lmF'
    local lmHI   = `lmH' + `lmI'
    local lmHF   = `lmH' + `lmF'
    local lmIF   = `lmI' + `lmF'
    local lmNHI  = `lmN' + `lmH' + `lmI'
    local lmNHF  = `lmN' + `lmH' + `lmF'
    local lmNIF  = `lmN' + `lmI' + `lmF'
    local lmHIF  = `lmH' + `lmI' + `lmF'
    local lmNHIF = `lmN' + `lmH' + `lmI' + `lmF'

    foreach c in NH NI NF HI HF IF NHI NHF NIF HIF NHIF {
        local d`c' = 0
    }
    local dNH   = `dfN' + `dfH'
    local dNI   = `dfN' + `dfI'
    local dNF   = `dfN' + `dfF'
    local dHI   = `dfH' + `dfI'
    local dHF   = `dfH' + `dfF'
    local dIF   = `dfI' + `dfF'
    local dNHI  = `dfN' + `dfH' + `dfI'
    local dNHF  = `dfN' + `dfH' + `dfF'
    local dNIF  = `dfN' + `dfI' + `dfF'
    local dHIF  = `dfH' + `dfI' + `dfF'
    local dNHIF = `dfN' + `dfH' + `dfI' + `dfF'

    foreach s in N H I F NH NI NF HI HF IF NHI NHF NIF HIF NHIF {
        if (inlist("`s'","N","H","I","F")) local dd = `df`s''
        else                               local dd = `d`s''
        local p`s' = chi2tail(`dd', `lm`s'')
        local df`s' = `dd'
    }

    *-------------------------------------------------- display
    if ("`notable'" == "") {
        local zlab "fitted values"
        if ("`rhs'" != "")      local zlab "all regressors"
        if ("`het'" != "")      local zlab "`het'"
        local flab "powers 2-`reset' of fitted values"
        if ("`tspowers'" != "") local flab "powers 2-`reset' of regressors (Thursby-Schmidt)"
        if ("`func'" != "")     local flab "`func'"

        _jd_head "Bera-Jarque four-directional LM specification test"      ///
                 "Model: `dv' on `iv'    (N = `nuse')"                      ///
                 "H0: normal, homoskedastic, serially independent, correctly specified"

        di as txt "  Heteroskedasticity variables (Z) : " as res "`zlab'"
        di as txt "  Functional-form variables (W)    : " as res "`flab'"
        di as txt "  Serial-correlation order (p)     : " as res `lags'
        if ("`studentize'" != "") di as txt "  LM_H studentised (Koenker 1981)"
        if ("`fullbg'" != "")     di as txt "  LM_I from the Breusch-Godfrey auxiliary regression"
        di as txt "{hline 78}"

        _jd_coln "One-directional components"
        _jd_row "LM_N   normality"              `lmN' `dfN' `pN' "Jarque-Bera"
        _jd_row "LM_H   homoskedasticity"       `lmH' `dfH' `pH' "Breusch-Pagan"
        _jd_row "LM_I   serial independence"    `lmI' `dfI' `pI' "Breusch-Godfrey"
        _jd_row "LM_F   functional form"        `lmF' `dfF' `pF' "Engle/RESET"
        di as txt "{hline 35}{c +}{hline 42}"

        di as txt %-34s "Two-directional" " {c |}"
        _jd_row "  LM_NH"   `lmNH'  `dfNH'  `pNH'  ""
        _jd_row "  LM_NI"   `lmNI'  `dfNI'  `pNI'  ""
        _jd_row "  LM_NF"   `lmNF'  `dfNF'  `pNF'  ""
        _jd_row "  LM_HI"   `lmHI'  `dfHI'  `pHI'  ""
        _jd_row "  LM_HF"   `lmHF'  `dfHF'  `pHF'  ""
        _jd_row "  LM_IF"   `lmIF'  `dfIF'  `pIF'  ""
        di as txt "{hline 35}{c +}{hline 42}"

        di as txt %-34s "Three-directional" " {c |}"
        _jd_row "  LM_NHI"  `lmNHI' `dfNHI' `pNHI' "Jarque-Bera (1980)"
        _jd_row "  LM_NHF"  `lmNHF' `dfNHF' `pNHF' ""
        _jd_row "  LM_NIF"  `lmNIF' `dfNIF' `pNIF' ""
        _jd_row "  LM_HIF"  `lmHIF' `dfHIF' `pHIF' ""
        di as txt "{hline 35}{c +}{hline 42}"

        di as txt %-34s "Four-directional" " {c |}"
        _jd_row "  LM_NHIF" `lmNHIF' `dfNHIF' `pNHIF' "Bera-Jarque (1982)"
        di as txt "{hline 35}{c BT}{hline 42}"

        di as txt "  Residual skewness = " as res %8.4f `skew'  ///
                  as txt "    kurtosis = " as res %8.4f `kurt'
        _jd_foot "Components are additive: every joint statistic is the sum of its parts."
    }

    *-------------------------------------------------- MCP
    if ("`mcp'" != "") {
        local alpha = (100 - `level') / 100
        local aj    = `alpha' / 4
        local cN = invchi2(`dfN', 1 - `aj')
        local cH = invchi2(`dfH', 1 - `aj')
        local cI = invchi2(`dfI', 1 - `aj')
        local cF = invchi2(`dfF', 1 - `aj')

        if (`sim' > 0) {
            if (`seed' > 0) set seed `seed'
            tempname CV
            mata: _jd_lm_sim("`dv'", "`iv'", "`zv'", "`func'", "`touse'", ///
                             `lags', `reset', ("`tspowers'" != ""),        ///
                             ("`studentize'" != ""), ("`dfadj'" != ""),    ///
                             ("`fullbg'" != ""), `sim', `aj', "`CV'")
            local cN = `CV'[1,1]
            local cH = `CV'[2,1]
            local cI = `CV'[3,1]
            local cF = `CV'[4,1]
        }

        * exact overall level under asymptotic independence
        local aov = 1 - (1 - `aj')^4

        _jd_head "Multiple comparison procedure (Bera-Jarque 1982, sec. 5)" ///
                 "Marginal level per direction = `: di %5.3f `aj''   overall (asympt. indep.) = `: di %5.3f `aov''" ///
                 "Bonferroni upper bound for the overall level = `: di %5.3f `alpha''"

        di as txt %-26s "Direction" " {c |}" %12s "LM" %14s "crit. value" %14s "decision"
        di as txt "{hline 27}{c +}{hline 50}"
        local nrej 0
        foreach s in N H I F {
            local nm = cond("`s'"=="N","Normality (N)",         ///
                       cond("`s'"=="H","Homoskedasticity (H)",  ///
                       cond("`s'"=="I","Serial independ. (I)","Functional form (F)")))
            local d  = cond(`lm`s'' >= `c`s'', "REJECT", "do not reject")
            if (`lm`s'' >= `c`s'') local nrej = `nrej' + 1
            di as txt %-26s "`nm'" " {c |}" as res %12.4f `lm`s'' ///
               as res %14.4f `c`s'' as txt %14s "`d'"
        }
        di as txt "{hline 27}{c BT}{hline 50}"
        if (`sim' > 0) {
            di as txt "  Critical values simulated from `sim' Gaussian replications under H0."
        }
        else {
            di as txt "  Critical values are asymptotic chi2 with marginal level alpha/4."
        }
        di as txt "  Directions rejected: " as res `nrej' as txt " of 4"
        di as txt "  Adjust the model only in the rejected direction(s); see" ///
                  " {help jointdiag_lm##remarks:Remarks}."
        di as txt ""

        return scalar nrej = `nrej'
        return scalar cN = `cN'
        return scalar cH = `cH'
        return scalar cI = `cI'
        return scalar cF = `cF'
        return scalar alpha_marginal = `aj'
        return scalar alpha_overall  = `aov'
    }

    *-------------------------------------------------- results matrix
    tempname R
    matrix `R' = J(15, 3, .)
    local i 0
    foreach s in N H I F NH NI NF HI HF IF NHI NHF NIF HIF NHIF {
        local ++i
        matrix `R'[`i',1] = `lm`s''
        matrix `R'[`i',2] = `df`s''
        matrix `R'[`i',3] = `p`s''
    }
    matrix colnames `R' = statistic df p
    matrix rownames `R' = LM_N LM_H LM_I LM_F LM_NH LM_NI LM_NF LM_HI ///
                          LM_HF LM_IF LM_NHI LM_NHF LM_NIF LM_HIF LM_NHIF

    *-------------------------------------------------- graph
    if ("`graph'" != "") {
        if ("`name'" == "") local name "jd_lm"
        _jd_lm_graph `lmN' `lmH' `lmI' `lmF' `dfN' `dfH' `dfI' `dfF' ///
                     `level' "`name'"
    }

    *-------------------------------------------------- returns
    foreach s in N H I F NH NI NF HI HF IF NHI NHF NIF HIF NHIF {
        return scalar lm_`s' = `lm`s''
        return scalar df_`s' = `df`s''
        return scalar p_`s'  = `p`s''
    }
    return scalar skewness = `skew'
    return scalar kurtosis = `kurt'
    return scalar N        = `nuse'
    return local  depvar   "`dv'"
    return local  indepvars "`iv'"
    return local  cmd      "jointdiag lm"
    return matrix table = `R'
end


*-----------------------------------------------------------------------
* contribution plot: each component scaled by its own critical value
*-----------------------------------------------------------------------
program define _jd_lm_graph
    version 14.0
    args lmN lmH lmI lmF dfN dfH dfI dfF level name

    _jd_gstyle
    local gopt `"`r(gopt)'"'

    local a = (100 - `level') / 100
    preserve
    clear
    qui set obs 4
    qui gen byte  dir  = _n
    qui gen double lm  = .
    qui gen double cv  = .
    qui replace lm = `lmN' in 1
    qui replace lm = `lmH' in 2
    qui replace lm = `lmI' in 3
    qui replace lm = `lmF' in 4
    qui replace cv = invchi2(`dfN', 1 - `a') in 1
    qui replace cv = invchi2(`dfH', 1 - `a') in 2
    qui replace cv = invchi2(`dfI', 1 - `a') in 3
    qui replace cv = invchi2(`dfF', 1 - `a') in 4
    qui gen double ratio = lm / cv
    label define _jddir 1 "Normality (N)" 2 "Homoskedasticity (H)" ///
                        3 "Serial indep. (I)" 4 "Functional form (F)", replace
    label values dir _jddir

    qui su ratio, meanonly
    local top = max(1.35, r(max) * 1.18)

    twoway (bar ratio dir if ratio <  1, horizontal barwidth(.55) ///
               color(navy%70) lcolor(navy) lwidth(thin))          ///
           (bar ratio dir if ratio >= 1, horizontal barwidth(.55) ///
               color(maroon%80) lcolor(maroon) lwidth(thin)),     ///
           yscale(reverse) ylabel(1(1)4, valuelabel labsize(small)) ///
           ytitle("") xtitle("LM statistic / critical value", size(small)) ///
           xline(1, lcolor(black) lpattern(dash) lwidth(medthin))  ///
           xscale(range(0 `top'))                                  ///
           title("Direction-by-direction contributions", size(medium)) ///
           subtitle("Bera-Jarque (1982) four-directional LM test", size(small)) ///
           note("Bars beyond the dashed line reject that direction at the" ///
                " `=100-`level''% level (marginal).", size(vsmall))         ///
           legend(order(1 "not rejected" 2 "rejected") ring(0) pos(5)       ///
                  region(lcolor(white)) size(small) cols(1))                 ///
           `gopt' name(`name', replace)
    restore
end



