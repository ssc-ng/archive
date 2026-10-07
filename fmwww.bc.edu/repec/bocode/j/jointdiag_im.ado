*! jointdiag_im 1.0.0  06oct2026
*! Information-matrix test and its decomposition, with AR(p) errors.
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*
*  SOURCES
*   White (1982), Econometrica 50, 1-25            : the IM equality, eq.(1)
*   Chesher (1983), Economics Letters 13, 45-48    : the n*R^2 score form
*   Chesher (1984), Econometrica 52, 865-872       : IM = test for parameter
*                                                     heterogeneity
*   Hall (1987), REStud 54, 257-263                : for the normal linear model
*       T_n = T1n + T2n + T3n asymptotically, independent;
*       T1n = White/Breusch-Pagan heteroskedasticity
*       T2n = quadratic form in u^3   (skewness)
*       T3n = quadratic form in u^4   (kurtosis)
*       >>> none of the three is sensitive to serial correlation (sec.4)
*   Bera & Lee (1993), REStud 60, 229-240          : the SAME test applied to a
*       linear model with AR(p) errors.  The indicator vector in their eq.(5)
*       is d = (d1,d2,d3,d4,d5,d6)' and the covariance matrix STAYS block
*       diagonal, so  T = T1+T2+T3+T4+T5+T6.  Their d1,d3,d5 reproduce Hall's
*       Delta1,Delta3,Delta2 when phi = 0, and
*       >>> T2 is identical to Engle's (1982) LM test for ARCH (their eq.(7)),
*           or to the augmented-ARCH (AARCH) LM test when Omega is not diagonal.
*
*  Each block statistic is computed as the Chesher (1983) uncentred n*R^2
*  from regressing a vector of ones on [ d-block , score ] minus the n*R^2
*  from regressing ones on the score alone; this is numerically the
*  block quadratic form d' V^-1 d and is what makes the result comparable
*  with -estat imtest-.

program define jointdiag_im, rclass
    version 14.0

    syntax [anything] [if] [in] [,       ///
        AR(integer 0)                     ///
        ARCHLags(integer -1)              ///
        AARCH                             ///
        HALL                              ///
        BP                                ///
        Level(cilevel)                    ///
        COMPare                           ///
        GRaph                             ///
        NAME(string)                      ///
        NOTABle                           ///
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

    if (`ar' < 0) {
        di as err "ar() cannot be negative"
        exit 198
    }
    if ("`hall'" != "") local ar 0
    if (`archlags' < 0) local archlags = max(`ar', 1)
    if (`archlags' < 1) local archlags 1
    * with hall (pure Hall 1987 decomposition) nothing conditional is tested
    if ("`hall'" != "" & `archlags' == 1 & `ar' == 0) local qq 0
    else                                              local qq `archlags'

    *------------------------------------------------- protect e()
    tempname _h
    capture _estimates hold `_h', restore nullok

    *------------------------------------------------- fit the null model
    tempvar res
    if (`ar' == 0) {
        qui regress `dv' `iv' if `touse'
        qui predict double `res' if e(sample), resid
        local nullcmd "regress"
        local phistr  ""
    }
    else {
        capture qui prais `dv' `iv' if `touse', rhotype(regress) nolog
        if (_rc | `ar' > 1) {
            * general AR(p): Cochrane-Orcutt style via arima
            capture qui arima `dv' `iv' if `touse', ar(1/`ar') nolog
            if (_rc) {
                di as err "could not fit the AR(`ar') null model"
                exit 430
            }
            qui predict double `res' if e(sample), resid
            local nullcmd "arima"
            local phistr ""
            forvalues j = 1/`ar' {
                local b = _b[ARMA:L`j'.ar]
                local phistr "`phistr' `b'"
            }
        }
        else {
            qui predict double `res' if e(sample), resid
            local nullcmd "prais"
            local phistr "`e(rho)'"
        }
    }
    qui replace `touse' = 0 if missing(`res')

    *------------------------------------------------- Mata
    tempname B
    mata: _jd_im_core("`dv'", "`iv'", "`touse'", "`res'", `ar', `qq',  ///
                      ("`aarch'" != ""), ("`bp'" == ""), "`B'")

    local nuse = `B'[7,3]
    local jbsk = `B'[8,1]
    local skw  = `B'[8,2]
    local krt  = `B'[8,3]

    *------------------------------------------------- unpack + p-values
    forvalues i = 1/6 {
        local T`i'  = `B'[`i',1]
        local d`i'  = `B'[`i',2]
        if (`d`i'' > 0 & `T`i'' < .) local p`i' = chi2tail(`d`i'', `T`i'')
        else                          local p`i' = .
    }
    local Ttot = 0
    local dtot = 0
    forvalues i = 1/6 {
        if (`T`i'' < .) {
            local Ttot = `Ttot' + `T`i''
            local dtot = `dtot' + `d`i''
        }
    }
    local ptot = chi2tail(`dtot', `Ttot')

    *------------------------------------------------- display
    if ("`notable'" == "") {
        if (`ar' == 0 & `qq' == 0) {
            _jd_head "Information-matrix test - Hall (1987) decomposition"   ///
                     "Model: `dv' on `iv'   (N = `nuse')   null: normal linear model" ///
                     "H0: the information-matrix equality holds"
            _jd_coln "Component"
            _jd_row "T1n heteroskedasticity"  `T1' `d1' `p1' "Hall Delta1 = White/BP"
            _jd_row "T2n skewness   (u^3)"    `T5' `d5' `p5' "Hall Delta2"
            _jd_row "T3n kurtosis   (u^4)"    `T3' `d3' `p3' "Hall Delta3"
            di as txt "{hline 35}{c +}{hline 42}"
            local Th = `T1' + `T5' + `T3'
            local dh = `d1' + `d5' + `d3'
            local ph = chi2tail(`dh', `Th')
            _jd_row "    IM test (total)"     `Th' `dh' `ph' ""
            di as txt "{hline 35}{c BT}{hline 42}"
            di as txt "  Hall (1987, sec. 4): {bf:none} of the three components has power"
            di as txt "  against serial correlation - its power equals its size there."
            di as txt "  Use {bf:jointdiag im, ar(p)} for the Bera-Lee (1993) extension."
            _jd_foot ""
        }
        else {
            local alab "ARCH(`qq')"
            if ("`aarch'" != "") local alab "augmented ARCH, AARCH(`qq')"
            local nlab "AR(`ar')"
            if (`ar' == 0) local nlab "iid"
            _jd_head "Information-matrix test - Bera & Lee (1993) decomposition"  ///
                     "Model: `dv' on `iv'   null errors: `nlab'   (N = `nuse')"   ///
                     "Conditional-variance block tested as: `alab'"
            _jd_coln "Component"
            _jd_row "T1  static heteroskedasticity"   `T1' `d1' `p1' "d1: (u^2-s2) x~ x~"
            _jd_row "T2  conditional heterosk. (ARCH)" `T2' `d2' `p2' "d2 = Engle LM"
            _jd_row "T3  kurtosis"                     `T3' `d3' `p3' "d3: u^4-3s4"
            _jd_row "T4  interaction x~ * eps"         `T4' `d4' `p4' "d4"
            _jd_row "T5  static hetercliticity"        `T5' `d5' `p5' "d5: u^3 x~"
            _jd_row "T6  conditional hetercliticity"   `T6' `d6' `p6' "d6: u^3 eps"
            di as txt "{hline 35}{c +}{hline 42}"
            _jd_row "    IM test (total)"              `Ttot' `dtot' `ptot' "sum of T1..T6"
            di as txt "{hline 35}{c BT}{hline 42}"
            di as txt "  Estimated AR coefficients: " as res "`phistr'" as txt "   (via -`nullcmd'-)"
            di as txt "  T2 is Engle's (1982) ARCH LM test: a rejection there says the"
            di as txt "  autoregressive coefficients are random, i.e. ARCH is present."
            local Thet = `T1' + `T2'
            local dhet = `d1' + `d2'
            local phet = chi2tail(`dhet', `Thet')
            di as txt "  Joint static + conditional heteroskedasticity: chi2(" ///
                as res `dhet' as txt ") = " as res %8.4f `Thet'                ///
                as txt "   p = " as res %6.4f `phet'
            _jd_foot "Block diagonality of V(d) makes the six components additive."
        }
    }

    *------------------------------------------------- compare with estat imtest
    if ("`compare'" != "" & `ar' == 0) {
        qui regress `dv' `iv' if `touse'
        capture qui estat imtest
        if (!_rc) {
            di as txt "  {bf:Cross-check against Stata's -estat imtest-}"
            di as txt "    component" _col(30) "jointdiag" _col(46) "estat imtest"
            di as txt "    heteroskedasticity" _col(30) as res %10.4f `T1' ///
                      _col(46) as res %10.4f r(chi2_h)
            di as txt "    skewness"           _col(30) as res %10.4f `T5' ///
                      _col(46) as res %10.4f r(chi2_s)
            di as txt "    kurtosis"           _col(30) as res %10.4f `T3' ///
                      _col(46) as res %10.4f r(chi2_k)
            di as txt "    The heteroskedasticity blocks agree exactly.  The other two"
            di as txt "    differ by construction: Stata reports the Cameron-Trivedi (1990)"
            di as txt "    OPG form, jointdiag reports Hall's (1987) Delta2 and Delta3."
            di as txt ""
            return scalar ct_h = r(chi2_h)
            return scalar ct_s = r(chi2_s)
            return scalar ct_k = r(chi2_k)
        }
    }

    *------------------------------------------------- graph
    if ("`graph'" != "") {
        if ("`name'" == "") local name "jd_im"
        _jd_im_graph `T1' `T2' `T3' `T4' `T5' `T6' ///
                     `d1' `d2' `d3' `d4' `d5' `d6' `level' "`name'" `ar'
    }

    *------------------------------------------------- returns
    forvalues i = 1/6 {
        return scalar T`i'  = `T`i''
        return scalar df`i' = `d`i''
        return scalar p`i'  = `p`i''
    }
    return scalar T     = `Ttot'
    return scalar df    = `dtot'
    return scalar p     = `ptot'
    return scalar N     = `nuse'
    return scalar ar    = `ar'
    return local  cmd   "jointdiag im"
end


*-----------------------------------------------------------------------
program define _jd_im_graph
    version 14.0
    args T1 T2 T3 T4 T5 T6 d1 d2 d3 d4 d5 d6 level name ar

    _jd_gstyle
    local gopt `"`r(gopt)'"'
    local a = (100 - `level') / 100

    preserve
    clear
    qui set obs 6
    qui gen byte comp = _n
    qui gen double st = .
    qui gen double cv = .
    forvalues i = 1/6 {
        qui replace st = `T`i'' in `i'
        if (`d`i'' > 0) qui replace cv = invchi2(`d`i'', 1 - `a') in `i'
    }
    qui drop if missing(st) | missing(cv) | cv <= 0
    qui gen double ratio = st / cv
    label define _jdim 1 "T1 static heterosk." 2 "T2 ARCH (cond. het.)" ///
                       3 "T3 kurtosis" 4 "T4 interaction"               ///
                       5 "T5 skewness" 6 "T6 cond. heteroclicity", replace
    label values comp _jdim

    qui su ratio, meanonly
    local top = max(1.35, r(max) * 1.18)

    twoway (bar ratio comp if ratio <  1, horizontal barwidth(.55)  ///
                color(navy%70) lcolor(navy) lwidth(thin))            ///
           (bar ratio comp if ratio >= 1, horizontal barwidth(.55)  ///
                color(maroon%80) lcolor(maroon) lwidth(thin)),       ///
           yscale(reverse) ylabel(1(1)6, valuelabel labsize(small))  ///
           ytitle("") xtitle("component / critical value", size(small)) ///
           xline(1, lcolor(black) lpattern(dash) lwidth(medthin))    ///
           xscale(range(0 `top'))                                     ///
           title("Information-matrix test decomposition", size(medium)) ///
           subtitle("Bera & Lee (1993) six components; Hall (1987) when ar(0)", ///
                    size(small))                                      ///
           note("Bars beyond the dashed line reject that component at the `=100-`level''% level.", ///
                size(vsmall))                                         ///
           legend(order(1 "not rejected" 2 "rejected") ring(0) pos(5) ///
                  region(lcolor(white)) size(small) cols(1))           ///
           `gopt' name(`name', replace)
    restore
end



