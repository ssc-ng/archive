*! jointdiag_bc 1.0.0  06oct2026
*! Box-Cox functional form tested JOINTLY with autocorrelation,
*! heteroskedasticity and omitted variables.
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*
*  THE MODEL  (Ghali & Snow 1987, eq.(19)-(25) - the most general of the
*  four papers; every other one is a restriction of it)
*
*       y_t^(lambda) = X_t' beta + X*_t' beta*  +  u_t
*       u_t          = rho u_{t-1} + e_t
*       Var(u_t)     = sigma^2 z_t^delta
*
*  with y^(lambda) = (y^lambda - 1)/lambda,  log y at lambda = 0,
*  and X* = the squares, cubes and fourth powers of the regressors
*  (Thursby & Schmidt 1977; Ghali & Snow eq.(27)).
*
*  Concentrated log likelihood, Ghali & Snow eq.(25):
*       L(delta,lambda,rho) = -(T/2)[ln 2pi + 1] - ln|Theta|
*                             + (T/2) ln(1-rho^2) - T ln sigma0(.)
*                             - (delta/2) sum ln z_t + (lambda-1) sum ln y_t
*
*  SPECIAL CASES
*    delta = 0           -> Savin & White (1978, JoE 8): the BCA model and
*                           their five LR tests C(l), G(l), C(r), G(r), J(l,r)
*    rho   = 0           -> Lahiri & Egy (1981, JoE 15): the BCH model,
*                           their Gamma(l,d) and Pi(l,d) tests
*    beta* = 0           -> no omitted-variable direction
*    all free            -> Ghali & Snow's generalized test, eq.(32)
*  LM counterparts
*    Tse (1984, EL 14) eq.(10)-(11) : the LM form of C(l) and J(l,r)
*    Yang & Tse (2008, EctJ 11)     : expected-information LM tests, and
*                                     the studentised versions robust to
*                                     non-normal errors (their Cor. 3.2)

program define jointdiag_bc, rclass
    version 14.0

    syntax [anything] [if] [in] [,       ///
        HET(varname numeric)              ///
        LAMBDA0(real 1)                   ///
        RHO                               ///
        DELTA                             ///
        OMITted                           ///
        RESET(integer 4)                  ///
        GRID(integer 25)                  ///
        LRange(numlist min=2 max=2)       ///
        Level(cilevel)                    ///
        LM                                ///
        STUDentize                        ///
        GRaph                             ///
        NAME(string)                      ///
        NOTABle                           ///
    ]

    _jd_parse `anything' `if' `in', notsrequired
    local dv   "`r(dv)'"
    local iv   "`r(iv)'"

    marksample touse, novarlist
    markout `touse' `dv' `iv' `het'

    qui count if `touse' & `dv' <= 0
    if (r(N) > 0) {
        di as err "`dv' must be strictly positive for a Box-Cox transformation"
        di as err "(`r(N)' non-positive values found; shift the variable first)"
        exit 411
    }
    if ("`delta'" != "" & "`het'" == "") {
        di as err "delta requires het(varname) - the z variable of sigma^2 z^delta"
        exit 198
    }
    if ("`het'" != "") {
        qui count if `touse' & `het' <= 0
        if (r(N) > 0) {
            di as err "het() variable must be strictly positive"
            exit 411
        }
    }

    local useR = ("`rho'"   != "")
    local useD = ("`delta'" != "")
    local useB = ("`omitted'" != "")

    if ("`lrange'" == "") local lrange "-2 3"
    tokenize "`lrange'"
    local lmin `1'
    local lmax `2'

    tempname _h
    capture _estimates hold `_h', restore nullok

    *------------------------------------------------- build W (omitted vars)
    local wv ""
    if (`useB') {
        local j 0
        foreach v of local iv {
            forvalues d = 2/`reset' {
                local ++j
                tempvar w`j'
                qui gen double `w`j'' = `v'^`d' if `touse'
                local wv "`wv' `w`j''"
            }
        }
    }

    *------------------------------------------------- the ML grid in Mata
    tempname RES PROF
    mata: _jd_bc_core("`dv'", "`iv'", "`wv'", "`het'", "`touse'",  ///
                      `lambda0', `useR', `useD', `useB',           ///
                      `lmin', `lmax', `grid', "`RES'", "`PROF'")

    * RES rows:
    *  1 = unrestricted      (lam, rho, del, ll, k)
    *  2 = lambda = lambda0, others free
    *  3 = rho = 0, others free
    *  4 = delta = 0, others free
    *  5 = beta* = 0, others free
    *  6 = fully restricted (lam0, rho=0, del=0, b*=0)
    *  7 = lambda = lambda0 AND rho = 0   (the "conditional" null)
    *  8 = n, k_iv, .
    local lamU = `RES'[1,1]
    local rhoU = `RES'[1,2]
    local delU = `RES'[1,3]
    local llU  = `RES'[1,4]
    local llL  = `RES'[2,4]
    local llR  = `RES'[3,4]
    local llD  = `RES'[4,4]
    local llB  = `RES'[5,4]
    local ll0  = `RES'[6,4]
    local llC  = `RES'[7,4]
    local nuse = `RES'[8,1]
    local kiv  = `RES'[8,2]
    local kw   = `RES'[8,3]

    *------------------------------------------------- LR tests
    * G(.)  = unconditional : all other parameters free under BOTH
    * C(.)  = conditional   : the others fixed at their null values
    local G_lam = 2*(`llU' - `llL')
    local G_rho = 2*(`llU' - `llR')
    local G_del = 2*(`llU' - `llD')
    local G_bet = 2*(`llU' - `llB')
    local J_all = 2*(`llU' - `ll0')

    * the Savin-White conditional tests use the restricted-elsewhere model
    local C_lam = 2*(`llR' - `ll0')
    if (`useR' == 0) local C_lam = 2*(`llU' - `ll0')
    local C_rho = 2*(`llL' - `ll0')

    local dfb = `kw'
    foreach s in lam rho del {
        local df_`s' = 1
    }
    local df_bet = `dfb'
    local df_all = 1 + `useR' + `useD' + `useB'*`dfb'

    foreach s in lam rho del bet {
        if (`G_`s'' < . & `df_`s'' > 0) local pG_`s' = chi2tail(`df_`s'', max(`G_`s'',0))
        else                             local pG_`s' = .
    }
    local pJ_all = chi2tail(`df_all', max(`J_all',0))
    local pC_lam = chi2tail(1, max(`C_lam',0))
    local pC_rho = chi2tail(1, max(`C_rho',0))

    *------------------------------------------------- display
    if ("`notable'" == "") {
        local l0v : di %4.2f `lambda0'
        local sub2 "H0 directions:  lambda = `l0v'"
        if (`useR') local sub2 "`sub2' ,  rho = 0"
        if (`useD') local sub2 "`sub2' ,  delta = 0"
        if (`useB') local sub2 "`sub2' ,  beta* = 0"

        _jd_head "Box-Cox functional form tested jointly with the error structure" ///
                 "Model: `dv' on `iv'    (N = `nuse')"                             ///
                 "`sub2'"

        di as txt "  Maximum-likelihood estimates (unrestricted model)"
        di as txt "{hline 78}"
        di as txt %-30s "    lambda (Box-Cox)" " {c |}" as res %12.6f `lamU'
        if (`useR') di as txt %-30s "    rho (AR 1)" " {c |}" as res %12.6f `rhoU'
        if (`useD') di as txt %-30s "    delta (heteroskedasticity)" " {c |}" as res %12.6f `delU'
        di as txt %-30s "    log likelihood" " {c |}" as res %12.4f `llU'
        di as txt "{hline 78}"

        _jd_coln "Likelihood-ratio tests"
        di as txt %-34s "Conditional (others at H0)" " {c |}"
        _jd_row "  C(lambda)"  `C_lam' 1 `pC_lam' "Savin-White (1978)"
        if (`useR') _jd_row "  C(rho)"  `C_rho' 1 `pC_rho' "Savin-White (1978)"
        di as txt "{hline 35}{c +}{hline 42}"
        di as txt %-34s "Unconditional (others free)" " {c |}"
        _jd_row "  G(lambda)"  `G_lam' `df_lam' `pG_lam' "functional form"
        if (`useR') _jd_row "  G(rho)"   `G_rho' `df_rho' `pG_rho' "autocorrelation"
        if (`useD') _jd_row "  G(delta)" `G_del' `df_del' `pG_del' "heteroskedasticity"
        if (`useB') _jd_row "  G(beta*)" `G_bet' `df_bet' `pG_bet' "omitted variables"
        di as txt "{hline 35}{c +}{hline 42}"
        di as txt %-34s "Joint" " {c |}"
        _jd_row "  J(all directions)" `J_all' `df_all' `pJ_all' "Ghali-Snow (1987)"
        di as txt "{hline 35}{c BT}{hline 42}"

        if (`C_lam' > `G_lam' + 1e-8 | (`useR' & `C_rho' > `G_rho' + 1e-8)) {
            di as txt "  {bf:Note:} a conditional statistic exceeds its unconditional"
            di as txt "  counterpart.  This is exactly Savin & White's (1978) warning:"
            di as txt "  the conditional test can reject where the general one does not,"
            di as txt "  i.e. one misspecification is masquerading as another."
        }
        _jd_foot "C() fixes the other parameters at H0; G() leaves them free."
    }

    *------------------------------------------------- LM versions
    if ("`lm'" != "") {
        tempname LMR
        mata: _jd_bc_lm("`dv'", "`iv'", "`het'", "`touse'", `lambda0',  ///
                        `useR', `useD', ("`studentize'" != ""), "`LMR'")
        local lm_lam = `LMR'[1,1]
        local lm_joint = `LMR'[2,1]
        local df_lmj   = `LMR'[2,2]
        local p_lmlam  = chi2tail(1, `lm_lam')
        local p_lmj    = chi2tail(`df_lmj', `lm_joint')

        _jd_head "Lagrange-multiplier counterparts"                     ///
                 "Tse (1984) eq.(10)-(11); Yang & Tse (2008) Thm 3.1-3.3" ///
                 "evaluated at the restricted MLE - no unrestricted fit needed"
        _jd_coln "LM test"
        _jd_row "LM(lambda)"            `lm_lam'   1        `p_lmlam' "Tse eq.(10)"
        _jd_row "LM(joint)"             `lm_joint' `df_lmj' `p_lmj'   "Tse eq.(11)"
        if ("`studentize'" != "") {
            di as txt "  Studentised (Yang & Tse 2008, Cor. 3.2) - robust to excess"
            di as txt "  skewness and kurtosis in the errors."
        }
        _jd_foot ""
        return scalar lm_lambda = `lm_lam'
        return scalar lm_joint  = `lm_joint'
        return scalar p_lm_joint = `p_lmj'
    }

    *------------------------------------------------- graph
    if ("`graph'" != "") {
        if ("`name'" == "") local name "jd_bc"
        _jd_bc_graph "`PROF'" `lamU' `llU' `lambda0' `level' "`name'"
    }

    *------------------------------------------------- returns
    return scalar lambda   = `lamU'
    return scalar rho      = `rhoU'
    return scalar delta    = `delU'
    return scalar ll       = `llU'
    return scalar ll_0     = `ll0'
    return scalar C_lambda = `C_lam'
    return scalar p_C_lambda = `pC_lam'
    return scalar G_lambda = `G_lam'
    return scalar p_G_lambda = `pG_lam'
    return scalar C_rho    = `C_rho'
    return scalar p_C_rho  = `pC_rho'
    return scalar G_rho    = `G_rho'
    return scalar p_G_rho  = `pG_rho'
    return scalar G_delta  = `G_del'
    return scalar p_G_delta = `pG_del'
    return scalar G_beta   = `G_bet'
    return scalar p_G_beta = `pG_bet'
    return scalar J        = `J_all'
    return scalar df_J     = `df_all'
    return scalar p_J      = `pJ_all'
    return scalar N        = `nuse'
    return local  cmd      "jointdiag bc"
    return matrix profile  = `PROF'
end


*-----------------------------------------------------------------------
program define _jd_bc_graph
    version 14.0
    args PROF lamU llU lam0 level name

    _jd_gstyle
    local gopt `"`r(gopt)'"'
    local crit = invchi2(1, `level'/100) / 2

    preserve
    clear
    qui svmat double `PROF', name(pf)
    rename pf1 lam
    rename pf2 ll
    qui drop if missing(ll)
    qui su ll, meanonly
    local top = r(max)
    qui gen double cut = `top' - `crit'

    twoway (line ll lam, lcolor(navy) lwidth(medthick))                     ///
           (line cut lam, lcolor(maroon) lpattern(dash) lwidth(medthin)),   ///
           xline(`lamU', lcolor(navy) lpattern(solid) lwidth(thin))          ///
           xline(`lam0', lcolor(gs8)  lpattern(shortdash))                   ///
           ytitle("concentrated log likelihood", size(small))                ///
           xtitle("{&lambda}  (Box-Cox transformation parameter)", size(small)) ///
           title("Concentrated likelihood profile", size(medium))            ///
           subtitle("solid vertical = MLE,  grey dashed = H0 value", size(small)) ///
           note("Values above the maroon line are inside the `level'% likelihood interval for {&lambda}.", ///
                size(vsmall))                                                ///
           legend(order(1 "profile" 2 "`level'% LR cut-off") ring(0) pos(5)   ///
                  region(lcolor(white)) size(small) cols(1))                  ///
           `gopt' name(`name', replace)
    restore
end



