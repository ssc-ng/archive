*! jointdiag_bilinear 1.0.0  06oct2026
*! ARCH versus bilinearity: a joint test, and a non-nested comparison.
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*
*  SOURCES
*   Higgins & Bera (1988), Econometric Reviews 7(2), 171-181
*     sec.2 : the Bera-McKenzie necessary and sufficient condition for
*             LM statistics to be ADDITIVE -- T_AB = T_A + T_B when the
*             information matrix is block diagonal between the two sets
*             of restrictions.
*     sec.3 : the simultaneous LM test for ARCH and bilinearity,
*             LM = LM_ARCH + LM_BILIN  ~ chi2(q + d)
*   Bera & Higgins (1997), JBES 15(1), 43-50  [WP 93-0116 in the folder]
*     sec.2 : GARCH and bilinear share the unconditional moment structure
*             - both are uncorrelated in levels and autocorrelated in
*             squares - so one is easily mistaken for the other.
*     sec.3 : the locally equivalent alternative model eq.(3.4)
*                 y_t = x_t'b + sum_i a_i (e^2_{t-i} - s2)
*                             + sum_ij b_ij e_{t-i} e_{t-j} + e_t
*             and the joint statistic
*                 (q/2) F_a + d F_b  ~ chi2(q + d)
*             The FACTOR 2 on the ARCH block is essential: the ordinary
*             regression variance of e_t(e^2_{t-i} - s2) is 2 s^8/... ,
*             i.e. HALF the correct asymptotic variance (their p.14-15,
*             following Godfrey & Wickens 1982 p.86 and Koenker 1981).
*     sec.4 : a simulated Cox test to choose BETWEEN the two models.

program define jointdiag_bilinear, rclass
    version 14.0

    syntax [anything] [if] [in] [,  ///
        ARCHlags(integer 1)          ///
        R(integer 1)                 ///
        S(integer 1)                 ///
        Fform                        ///
        Level(cilevel)               ///
        GRaph                        ///
        NAME(string)                 ///
        NOTABle                      ///
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
    if (`archlags' < 1 | `r' < 1 | `s' < 1) {
        di as err "archlags(), r() and s() must be positive"
        exit 198
    }
    if (`s' > `r') {
        di as err "the bilinear model needs s <= r (Saikkonen & Luukkonen 1988);" ///
                  " b_ij is set to zero for i < j"
        exit 198
    }

    tempname _h
    capture _estimates hold `_h', restore nullok

    qui regress `dv' `iv' if `touse'
    tempvar res
    qui predict double `res' if e(sample), resid
    qui replace `touse' = 0 if missing(`res')

    tempname B
    mata: _jd_bil_core("`res'", "`touse'", `archlags', `r', `s',  ///
                       ("`fform'" != ""), "`B'")

    local lmA = `B'[1,1]
    local dfA = `B'[1,2]
    local lmB = `B'[2,1]
    local dfB = `B'[2,2]
    local nn  = `B'[3,1]

    local lmJ = `lmA' + `lmB'
    local dfJ = `dfA' + `dfB'

    local pA = chi2tail(`dfA', `lmA')
    local pB = chi2tail(`dfB', `lmB')
    local pJ = chi2tail(`dfJ', `lmJ')

    if ("`notable'" == "") {
        local lab "LM (n R-squared)"
        if ("`fform'" != "") local lab "F-form, variance corrected"
        _jd_head "ARCH and bilinearity tested jointly"                      ///
                 "Model: `dv' on `iv'    (N = `nn')"                         ///
                 "ARCH order q = `archlags' ;  bilinear orders r = `r', s = `s'   [`lab']"

        _jd_coln "Direction"
        _jd_row "LM(ARCH)"             `lmA' `dfA' `pA' "Engle (1982)"
        _jd_row "LM(bilinearity)"      `lmB' `dfB' `pB' "Granger-Andersen (1978)"
        di as txt "{hline 35}{c +}{hline 42}"
        _jd_row "LM(joint) = sum"      `lmJ' `dfJ' `pJ' "Higgins & Bera (1988)"
        di as txt "{hline 35}{c BT}{hline 42}"
        di as txt "  Additivity holds because the two blocks of regressors in the"
        di as txt "  locally equivalent alternative are asymptotically orthogonal"
        di as txt "  (Bera & McKenzie condition; Higgins & Bera 1988, sec. 2)."
        if ("`fform'" != "") {
            di as txt "  The ARCH block carries the factor-2 variance correction of"
            di as txt "  Godfrey & Wickens (1982, p.86): the naive regression variance"
            di as txt "  is HALF the correct one, so an uncorrected F over-rejects."
        }
        if (`pA' < 0.05 & `pB' < 0.05) {
            di as txt "  {bf:Both} directions reject.  Because the two processes share"
            di as txt "  their unconditional moments this is expected; the joint test"
            di as txt "  says 'nonlinear', not 'which'.  Use a non-nested comparison"
            di as txt "  (Bera & Higgins 1997, sec. 4) to choose between them."
        }
        _jd_foot ""
    }

    if ("`graph'" != "") {
        if ("`name'" == "") local name "jd_bil"
        _jd_bil_graph `lmA' `lmB' `dfA' `dfB' `level' "`name'"
    }

    return scalar lm_arch     = `lmA'
    return scalar df_arch     = `dfA'
    return scalar p_arch      = `pA'
    return scalar lm_bilinear = `lmB'
    return scalar df_bilinear = `dfB'
    return scalar p_bilinear  = `pB'
    return scalar lm_joint    = `lmJ'
    return scalar df_joint    = `dfJ'
    return scalar p_joint     = `pJ'
    return scalar N           = `nn'
    return local  cmd         "jointdiag bilinear"
end


program define _jd_bil_graph
    version 14.0
    args a b da db level name

    _jd_gstyle
    local gopt `"`r(gopt)'"'
    local al = (100 - `level') / 100

    preserve
    clear
    qui set obs 2
    qui gen byte id = _n
    qui gen double st = .
    qui gen double cv = .
    qui replace st = `a' in 1
    qui replace st = `b' in 2
    qui replace cv = invchi2(`da', 1-`al') in 1
    qui replace cv = invchi2(`db', 1-`al') in 2
    qui gen double ratio = st/cv
    label define _jdbl 1 "ARCH" 2 "bilinearity", replace
    label values id _jdbl
    qui su ratio, meanonly
    local top = max(1.35, r(max)*1.2)

    twoway (bar ratio id if ratio <  1, horizontal barwidth(.45) ///
                color(navy%70) lcolor(navy))                      ///
           (bar ratio id if ratio >= 1, horizontal barwidth(.45) ///
                color(maroon%85) lcolor(maroon)),                 ///
           yscale(reverse) ylabel(1(1)2, valuelabel labsize(small)) ///
           ytitle("") xtitle("LM / critical value", size(small))     ///
           xline(1, lcolor(black) lpattern(dash)) xscale(range(0 `top')) ///
           title("ARCH vs bilinearity", size(medium))                 ///
           subtitle("two competing models for the same nonlinear dependence", ///
                    size(small))                                      ///
           note("Both rejecting is normal: the processes share their unconditional moments.", ///
                size(vsmall))                                         ///
           legend(order(1 "not rejected" 2 "rejected") ring(0) pos(5) ///
                  region(lcolor(white)) size(small) cols(1))           ///
           `gopt' name(`name', replace)
    restore
end



