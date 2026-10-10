*! thstrtype 1.0.0  06oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Choose between a LOGISTIC and an EXPONENTIAL smooth-transition model,
*! and test linearity to fourth order.
*!
*!   Escribano, A. and O. Jorda (1999) "Improved testing and specification
*!     of smooth transition regression models", in P. Rothman (ed.),
*!     Nonlinear Time Series Analysis of Economic and Financial Data,
*!     Dynamic Modeling and Econometrics in Economics and Finance,
*!     pp. 289-319, doi:10.1007/978-1-4615-5129-4_14
*!   Terasvirta, T. (1994) JASA 89:208-218, doi:10.2307/2291217
*!     (the earlier selection rule, reported here for comparison)
*!   Luukkonen, R., P. Saikkonen and T. Terasvirta (1988) Biometrika
*!     75:491-499, doi:10.1093/biomet/75.3.491 (the Taylor-expansion LM idea)
*!
*! See thstrtype.sthlp.
*!
*! WHY THIS EXISTS. thstar makes you pick type(lstar) or type(estar), and
*! nothing in the package helped you pick. The two imply different dynamics
*! -- a logistic transition is monotone in the transition variable, an
*! exponential one is symmetric about its centre -- so the choice is not
*! cosmetic, and fitting both and taking the better likelihood is not a
*! test.
*!
*! Everything here is ordinary least squares and Stata's own F tests on
*! auxiliary regressions. There is no Mata, which is deliberate: the whole
*! procedure IS a sequence of nested F tests, and running them through
*! -regress- and -test- means the arithmetic is Stata's rather than mine.

program define thstrtype, rclass
    version 15

    syntax varname(numeric ts) [if] [in] , ///
        AR(numlist integer >0 sort)        ///
        [ THVar(varname numeric ts)        ///
          DELAY(integer 1)                 ///
          XVars(varlist numeric ts)        ///
          ORDer(integer 4)                 ///
          PARSimonious                     ///
          noCONStant                       ///
          Level(cilevel) ]

    if !inlist(`order', 3, 4) {
        display as error "{bf:order()} must be 3 or 4."
        display as error "Order 4 is the Escribano-Jorda recommendation: the"
        display as error "fourth-order terms are what give the test power"
        display as error "against an EXPONENTIAL transition, and order 3 is"
        display as error "the older Luukkonen-Saikkonen-Terasvirta form."
        exit 198
    }
    if `delay' < 1 | `delay' > 24 {
        display as error "{bf:delay()} must be between 1 and 24"
        exit 198
    }
    if "`level'" == "" local level = c(level)

    capture tsset
    if _rc {
        display as error "{bf:thstrtype} needs the data {bf:tsset}"
        exit 111
    }
    if "`r(panelvar)'" != "" {
        display as error "{bf:thstrtype} is a single time-series command;"
        display as error "panel threshold models are outside this package."
        exit 198
    }

    local yv "`varlist'"
    marksample touse

    * ---------------------------------------------- the linear regressors
    * x_t = (1, y_{t-1}, ..., y_{t-p}, w_t), which is the paper's x_t
    local xl ""
    local nar 0
    foreach k of local ar {
        local ++nar
        tempvar a`k'
        quietly generate double `a`k'' = L`k'.`yv' if `touse'
        local xl `xl' `a`k''
        local arlab `arlab' L`k'.`yv'
    }
    if "`xvars'" != "" {
        quietly tsrevar `xvars'
        local xl `xl' `r(varlist)'
    }

    * ---------------------------------------------- the transition variable
    if "`thvar'" != "" {
        quietly tsrevar `thvar'
        local zv "`r(varlist)'"
        local zlab "`thvar'"
    }
    else {
        tempvar zz
        quietly generate double `zz' = L`delay'.`yv' if `touse'
        local zv "`zz'"
        local zlab "L`delay'.`yv'"
    }

    markout `touse' `xl' `zv'
    quietly count if `touse'
    local nobs = r(N)
    local kx : word count `xl'
    local need = (`kx' + 1)*(`order' + 1) + 5
    if `nobs' < `need' {
        display as error "too few observations (`nobs') for an order-`order'"
        display as error "auxiliary regression with `kx' regressors; it needs"
        display as error "at least about `need'."
        exit 2001
    }

    * ---------------------------------------------- the auxiliary terms
    * Full form: every regressor interacted with z, z^2, z^3, z^4.
    * Parsimonious form (the paper's NL3A/NL4A): the FIRST power is fully
    * interacted but the higher powers enter only as powers of z alone.
    * That is Luukkonen's answer to the lack of parsimony, and it matters
    * when p is large or the sample is short, because every extra regressor
    * costs the test power.
    local pow1 ""
    local pow2 ""
    local pow3 ""
    local pow4 ""
    local j 0
    foreach v of local xl {
        local ++j
        tempvar p1_`j'
        quietly generate double `p1_`j'' = `v'*`zv' if `touse'
        local pow1 `pow1' `p1_`j''
        if "`parsimonious'" == "" {
            tempvar p2_`j' p3_`j'
            quietly generate double `p2_`j'' = `v'*`zv'^2 if `touse'
            quietly generate double `p3_`j'' = `v'*`zv'^3 if `touse'
            local pow2 `pow2' `p2_`j''
            local pow3 `pow3' `p3_`j''
            if `order' == 4 {
                tempvar p4_`j'
                quietly generate double `p4_`j'' = `v'*`zv'^4 if `touse'
                local pow4 `pow4' `p4_`j''
            }
        }
    }
    if "`parsimonious'" != "" {
        tempvar q2 q3
        quietly generate double `q2' = `zv'^2 if `touse'
        quietly generate double `q3' = `zv'^3 if `touse'
        local pow2 "`q2'"
        local pow3 "`q3'"
        if `order' == 4 {
            tempvar q4
            quietly generate double `q4' = `zv'^4 if `touse'
            local pow4 "`q4'"
        }
    }

    * x_t contains the CONSTANT, so the powers of the transition variable
    * must also enter on their own: they are the constant interacted with
    * z^k. Leaving them out silently tests a smaller hypothesis than the
    * procedure specifies -- with one lag it gives 4 Taylor terms where the
    * paper has 8 -- and it unbalances the even/odd comparison the whole
    * selection rule rests on.
    if "`constant'" == "" {
        * The FIRST power is interacted with every regressor in both forms,
        * so the constant times z is needed in both.
        tempvar k1
        quietly generate double `k1' = `zv' if `touse'
        local pow1 `pow1' `k1'
        * The higher powers are only missing their constant interaction in
        * the FULL form. In the parsimonious form those blocks already ARE
        * the bare powers, and adding them again would create exact
        * duplicate columns -- which Stata drops, leaving the test with
        * fewer degrees of freedom than it reports having.
        if "`parsimonious'" == "" {
            tempvar k2 k3
            quietly generate double `k2' = `zv'^2 if `touse'
            quietly generate double `k3' = `zv'^3 if `touse'
            local pow2 `pow2' `k2'
            local pow3 `pow3' `k3'
            if `order' == 4 {
                tempvar k4
                quietly generate double `k4' = `zv'^4 if `touse'
                local pow4 `pow4' `k4'
            }
        }
    }

    local allpow "`pow1' `pow2' `pow3' `pow4'"

    * ---------------------------------------------- the auxiliary regression
    quietly regress `yv' `xl' `allpow' if `touse', `constant'
    local Nreg = e(N)
    local dfr  = e(df_r)
    if `dfr' < 5 {
        display as error "the auxiliary regression has only `dfr' residual"
        display as error "degrees of freedom. Use {bf:parsimonious}, or fewer"
        display as error "{bf:ar()} lags."
        exit 2001
    }

    * any term dropped for collinearity is a term the test cannot use, and
    * silently testing a dropped coefficient gives a wrong df
    local dropped 0
    foreach v of local allpow {
        if _b[`v'] == 0 & _se[`v'] == 0 local ++dropped
    }

    * ---------------------------------------------- the linearity test
    quietly test `allpow'
    local Flin  = r(F)
    local dflin = r(df)
    local plin  = Ftail(r(df), `dfr', r(F))

    * ---------------------------------------------- the EJP selection
    * H0E: the EVEN powers (z^2, z^4) are zero -- exactly true for a
    *      LOGISTIC transition centred at zero
    * H0L: the ODD powers  (z,   z^3) are zero -- exactly true for an
    *      EXPONENTIAL transition centred at zero
    * The rule compares the STRENGTH of the two rejections rather than
    * conditioning one on the other, which is the whole point: Terasvirta's
    * nested sequence conditions on restrictions that are false when the
    * transition is not centred at zero, and then the order of the p-values
    * no longer means what it is supposed to mean.
    local evenl "`pow2' `pow4'"
    local oddl  "`pow1' `pow3'"

    quietly test `evenl'
    local FE  = r(F)
    local dfE = r(df)
    local pE  = Ftail(r(df), `dfr', r(F))

    quietly test `oddl'
    local FL  = r(F)
    local dfL = r(df)
    local pL  = Ftail(r(df), `dfr', r(F))

    local pick = cond(`pL' < `pE', "LSTAR", "ESTAR")
    local ptype = cond("`pick'" == "LSTAR", "lstar", "estar")

    * the extra reading the paper points out: a clean one-sided result also
    * says something about the location of the transition centre
    local cnote ""
    local a = `level'/100
    local crit = 1 - `a'
    if `pL' < `crit' & `pE' >= `crit' local cnote "and a transition centre near zero"
    if `pE' < `crit' & `pL' >= `crit' local cnote "and a transition centre near zero"

    * ---------------------------------------------- Terasvirta's sequence
    * Reported for comparison, because it is what most applied papers used
    * before 1999 and readers will look for it. Only defined in the full
    * (non-parsimonious) form, where the three blocks are separate.
    local haveTP = 0
    if "`parsimonious'" == "" {
        local haveTP = 1
        quietly test `pow3'
        local F3  = r(F)
        local p3  = Ftail(r(df), `dfr', r(F))
        * F2: beta2 = 0 given beta3 = 0
        quietly regress `yv' `xl' `pow1' `pow2' if `touse', `constant'
        local dfr2 = e(df_r)
        quietly test `pow2'
        local F2  = r(F)
        local p2  = Ftail(r(df), `dfr2', r(F))
        * F1: beta1 = 0 given beta2 = beta3 = 0
        quietly regress `yv' `xl' `pow1' if `touse', `constant'
        local dfr1 = e(df_r)
        quietly test `pow1'
        local F1  = r(F)
        local p1  = Ftail(r(df), `dfr1', r(F))

        local pickTP = "LSTAR"
        if `p2' < `p1' & `p2' < `p3' local pickTP = "ESTAR"
    }

    * ---------------------------------------------- display
    display _n as text "Smooth-transition type selection (Escribano-Jorda)"
    display as text "{hline 74}"
    display as text "  series" _col(44) as result %28s "`yv'"
    display as text "  transition variable" _col(44) as result %28s "`zlab'"
    display as text "  linear regressors" _col(44) as result %28s ///
        cond("`constant'" == "", "`nar' lag(s) + constant", "`nar' lag(s)")
    display as text "  Taylor order" _col(44) as result %28.0f `order'
    display as text "  auxiliary form" _col(44) as result %28s ///
        cond("`parsimonious'" != "", "parsimonious (NL`order'A)", "full (NL`order')")
    display as text "  observations" _col(44) as result %28.0f `Nreg'
    display as text "{hline 74}"

    display as text "  LINEARITY (all Taylor terms jointly zero)"
    display as text "    F(" as result `dflin' as text ", " as result `dfr' ///
        as text ") = " as result %10.4f `Flin' ///
        as text "   p = " as result %8.4f `plin'
    if `plin' >= 0.10 {
        display as error "    Linearity is NOT rejected. The selection below"
        display as error "    is then meaningless: it chooses between two"
        display as error "    nonlinear models when the data give no evidence"
        display as error "    of either. The procedure is conditional on a"
        display as error "    prior rejection of linearity."
    }
    display as text "{hline 74}"

    display as text "  SELECTION (Escribano-Jorda)"
    display as text "    H0E: even powers zero (z^2, z^4)" _col(44) ///
        as text "F(" as result `dfE' as text "," as result `dfr' as text ") = " ///
        as result %8.3f `FE' as text "  p = " as result %7.4f `pE'
    display as text "    H0L: odd powers zero  (z, z^3)" _col(44) ///
        as text "F(" as result `dfL' as text "," as result `dfr' as text ") = " ///
        as result %8.3f `FL' as text "  p = " as result %7.4f `pL'
    display as text ""
    display as text "    smaller p-value" _col(44) as result %28s ///
        cond(`pL' < `pE', "H0L (odd terms)", "H0E (even terms)")
    display as text "    {bf:selected transition}" _col(44) as result %28s "`pick'"
    if "`cnote'" != "" {
        display as text "    `cnote'"
    }

    if `haveTP' {
        display as text "{hline 74}"
        display as text "  For comparison, Terasvirta's (1994) sequence"
        display as text "    F3 (cubic terms)" _col(44) as text "F = " ///
            as result %8.3f `F3' as text "   p = " as result %7.4f `p3'
        display as text "    F2 (quadratic | cubic = 0)" _col(44) as text "F = " ///
            as result %8.3f `F2' as text "   p = " as result %7.4f `p2'
        display as text "    F1 (linear | quad = cubic = 0)" _col(44) as text "F = " ///
            as result %8.3f `F1' as text "   p = " as result %7.4f `p1'
        display as text "    Terasvirta's rule selects" _col(44) ///
            as result %28s "`pickTP'"
        if "`pickTP'" != "`pick'" {
            display as error "    The two rules DISAGREE. Escribano and Jorda"
            display as error "    argue theirs is the more reliable, because"
            display as error "    Terasvirta's three tests are NESTED and the"
            display as error "    conditioning restrictions are false whenever"
            display as error "    the transition centre is not zero -- which"
            display as error "    makes the ORDER of the p-values, and so the"
            display as error "    rule itself, unreliable. Prefer the"
            display as error "    Escribano-Jorda choice, and say in the paper"
            display as error "    that the two disagreed."
        }
    }

    display as text "{hline 74}"
    if `dropped' > 0 {
        display as error "  WARNING: `dropped' auxiliary term(s) were dropped"
        display as error "  for collinearity. The degrees of freedom above"
        display as error "  count only the terms that survived. Consider"
        display as error "  {bf:parsimonious} or fewer {bf:ar()} lags."
    }
    display as text "  Next step:"
    display as text "    {bf:thstar `yv', ar(`ar') type(`ptype') delay(`delay')}"
    display as text ""
    display as text "  This is a SELECTION rule, not a test of one type"
    display as text "  against the other: it reports which of two"
    display as text "  non-nested shapes the data lean towards, and it"
    display as text "  always returns one. When the two p-values are close,"
    display as text "  the lean is weak -- fit both and compare."

    * ---------------------------------------------- stored results
    return scalar F_lin  = `Flin'
    return scalar p_lin  = `plin'
    return scalar df_lin = `dflin'
    return scalar F_even = `FE'
    return scalar p_even = `pE'
    return scalar df_even = `dfE'
    return scalar F_odd  = `FL'
    return scalar p_odd  = `pL'
    return scalar df_odd = `dfL'
    return scalar df_r   = `dfr'
    return scalar N      = `Nreg'
    return scalar order  = `order'
    return scalar delay  = `delay'
    return scalar dropped = `dropped'
    if `haveTP' {
        return scalar F1 = `F1'
        return scalar F2 = `F2'
        return scalar F3 = `F3'
        return scalar p1 = `p1'
        return scalar p2 = `p2'
        return scalar p3 = `p3'
        return local  type_tp "`pickTP'"
    }
    return local type    "`pick'"
    return local startype "`ptype'"
    return local cmd     "thstrtype"
    return local depvar  "`yv'"
    return local thvar   "`zlab'"
end
