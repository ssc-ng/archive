*! thnltest 1.0.0  02oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! The classical tests of linearity of a univariate autoregression, run before
*! any threshold model is fitted: Keenan (1985), Tsay (1986), Tsay's (1989)
*! arranged-autoregression F test over candidate delays, and a CUSUM
*! portmanteau on the same recursive residuals.
*! Keenan (1985) Biometrika 72:39-44, doi:10.1093/biomet/72.1.39
*! Tsay (1986) Biometrika 73:461-466, doi:10.1093/biomet/73.2.461
*! Tsay (1989) JASA 84:231-240, doi:10.1080/01621459.1989.10478760
*! Petruccelli & Davies (1986) Biometrika 73:687-694, doi:10.1093/biomet/73.3.687
*!
*! With TWO OR MORE variables it switches to the multivariate arranged
*! regression of Tsay (1998): the C(d) test of linearity of a VAR against a
*! threshold VAR, over candidate threshold variables.
*! Tsay (1998) JASA 93:1188-1202, doi:10.1080/01621459.1998.10473779

program define thnltest, rclass
    version 15

    syntax varlist(numeric ts min=1) [if] [in] , AR(numlist integer >0 sort) ///
        [ DELAY(numlist integer >0 sort)                               ///
          THVar(varlist numeric ts)                                    ///
          STARTup(integer 0)                                           ///
          REPS(integer 0)                                              ///
          SEED(string)                                                 ///
          noCONStant ]

    local nvar : word count `varlist'
    if `nvar' > 1 {
        Multi `0'
        * a child program's r() is DISCARDED unless the parent carries it up
        return add
        exit
    }
    if "`thvar'" != "" {
        display as error "{bf:thvar()} is for the multivariate form; with one"
        display as error "series the candidate orderings are set by {bf:delay()}"
        exit 198
    }

    capture tsset
    if _rc {
        display as error "{bf:thnltest} requires the data to be {bf:tsset}"
        exit 459
    }
    local timevar "`r(timevar)'"

    local p : word count `ar'
    local pmax = 0
    foreach j of local ar {
        if `j' > `pmax' local pmax = `j'
    }
    if "`delay'" == "" local delay `ar'
    foreach d of local delay {
        local ok 0
        local i 0
        foreach j of local ar {
            local ++i
            if `j' == `d' local ok `i'
        }
        if `ok' == 0 {
            display as error "delay(`d') is not in ar(`ar'): the transition"
            display as error "variable must be one of the lags in the model"
            exit 198
        }
        local dpos `dpos' `ok'
    }
    if `reps' < 0 {
        display as error "reps() must be 0 or more"
        exit 198
    }
    if "`seed'" != "" set seed `seed'
    local hascons = cond("`constant'"=="", 1, 0)

    local depv `varlist'
    marksample touse
    markout `touse' `depv'

    * ---- the autoregressive design, in the order ar() gives
    local arvars ""
    local arnames ""
    foreach j of local ar {
        tempvar L`j'
        quietly generate double `L`j'' = L`j'.`depv' if `touse'
        local arvars `arvars' `L`j''
        local arnames `arnames' L`j'.`depv'
    }
    markout `touse' `arvars'
    quietly count if `touse'
    if r(N) < 3 * `p' + 10 {
        display as error "too few usable observations (`r(N)') for `p' lags"
        exit 2001
    }
    local nobs = r(N)

    * the startup of the recursion: Tsay (1989) suggests about n/10 plus the
    * number of parameters, and never fewer than the parameters plus one
    local kpar = `p' + `hascons'
    if `startup' <= 0 local startup = max(`kpar' + 1, floor(`nobs'/10) + `kpar')
    if `startup' >= `nobs' - `kpar' {
        display as error "startup(`startup') leaves no recursion: it must be"
        display as error "well below the number of observations (`nobs')"
        exit 198
    }

    * dlist holds the POSITION of each candidate delay inside the design
    local dlist "`dpos'"

    mata: tk_thnltest()

    tempname KE T86 ARR
    matrix `KE'  = __tk_keenan
    matrix `T86' = __tk_tsay86
    matrix `ARR' = __tk_arr
    * translate the positions back into the lags the user asked for
    forvalues i = 1/`=rowsof(`ARR')' {
        if `ARR'[`i',1] < . {
            local dd : word `=`ARR'[`i',1]' of `ar'
            matrix `ARR'[`i',1] = `dd'
        }
    }
    local bestd = __tk_bestd
    if `bestd' < . {
        local bestdlag : word `bestd' of `ar'
    }
    else local bestdlag .
    local cbestd = __tk_cbestd
    if `cbestd' < . {
        local cbestdlag : word `cbestd' of `ar'
    }
    else local cbestdlag .

    matrix colnames `ARR' = delay F df1 df2 p cusum p_cusum M
    matrix colnames `KE'  = F df p
    matrix colnames `T86' = F df p

    * ---------------------------------------------------- display
    display _n as text "Tests of linearity of an autoregression" _col(52) ///
        "Number of obs" _col(68) "=" _col(71) as result %9.0fc `nobs'
    display as text "  Series: " as result "`depv'" _col(52) ///
        as text "Lags" _col(68) "=" _col(71) as result %9.0f `p'
    display as text "  Lags used: " as result "`arnames'"
    display as text "  Time variable: " as result "`timevar'" _col(52) ///
        as text "Startup" _col(68) "=" _col(71) as result %9.0f `startup'
    display ""
    display as text "{hline 78}"
    display as text "  No ordering needed" _col(34) "statistic" _col(48) "df" ///
        _col(60) "p" _continue
    if `reps' > 0 display as text _col(69) "boot p"
    else display ""
    display as text "{hline 78}"
    display as text "  Keenan (1985) one-df F" _col(32) as result %11.4f `KE'[1,1] ///
        _col(45) as text "(" as result %2.0f `KE'[1,2] as text ", " ///
        as result %5.0f (`nobs'-`kpar'-`KE'[1,2]) as text ")" _col(57) ///
        as result %8.4f `KE'[1,3] _continue
    if `reps' > 0 display as result _col(68) %8.4f __tk_pb_keenan
    else display ""
    display as text "  Tsay (1986) second-order F" _col(32) as result %11.4f `T86'[1,1] ///
        _col(45) as text "(" as result %2.0f `T86'[1,2] as text ", " ///
        as result %5.0f (`nobs'-`kpar'-`T86'[1,2]) as text ")" _col(57) ///
        as result %8.4f `T86'[1,3] _continue
    if `reps' > 0 display as result _col(68) %8.4f __tk_pb_tsay86
    else display ""
    display as text "{hline 78}"
    display as text "  Arranged autoregression, ordered by the candidate delay"
    display as text "    delay" _col(16) "Tsay F" _col(28) "df" _col(42) "p" ///
        _col(52) "CUSUM" _col(66) "p"
    display as text "{hline 78}"
    forvalues i = 1/`=rowsof(`ARR')' {
        if `ARR'[`i',2] >= . continue
        local mark = cond(`ARR'[`i',1] == `bestdlag', " *", "  ")
        display as text "    " as result %4.0f `ARR'[`i',1] as text "`mark'" ///
            _col(13) as result %10.4f `ARR'[`i',2] ///
            _col(25) as text "(" as result %2.0f `ARR'[`i',3] as text "," ///
            as result %5.0f `ARR'[`i',4] as text ")" ///
            _col(38) as result %8.4f `ARR'[`i',5] ///
            _col(48) as result %10.4f `ARR'[`i',6] ///
            _col(61) as result %8.4f `ARR'[`i',7]
    }
    display as text "{hline 78}"
    if `bestdlag' < . {
        display as text "  * smallest Tsay p-value: delay " as result "`bestdlag'" ///
            as text ", F = " as result %9.4f __tk_bestF ///
            as text ", p = " as result %6.4f __tk_bestp
        if `reps' > 0 {
            display as text "    bootstrap p for that F (searching the delay is"
            display as text "    included in the simulation) = " ///
                as result %6.4f __tk_pb_tsayF
        }
        else {
            display as text "    This p-value is for a FIXED delay. Having chosen the"
            display as text "    delay by minimising it, add {bf:reps()} for a bootstrap"
            display as text "    p-value that accounts for the search."
        }
    }
    if `cbestdlag' < . {
        display as text "  smallest CUSUM p-value: delay " as result "`cbestdlag'" ///
            as text ", statistic = " as result %8.4f __tk_cbest ///
            as text ", p = " as result %6.4f __tk_cbestp
        if `reps' > 0 {
            display as text "    bootstrap p = " as result %6.4f __tk_pb_cusum
        }
    }
    display as text "{hline 78}"
    display as text "  Keenan and Tsay (1986) look for {bf:any} second-order curvature and"
    display as text "  do not need an ordering, so they have no power against a threshold"
    display as text "  whose two regimes have the same curvature. The arranged"
    display as text "  autoregression is the one aimed at a threshold: it orders the data"
    display as text "  by the candidate threshold variable, so a break shows up as the"
    display as text "  recursion fitting the wrong regime."
    display as text "  The CUSUM is reported in the re-centred (Brownian bridge) form, so"
    display as text "  its asymptotic p-value is exact and needs no table; Petruccelli and"
    display as text "  Davies (1986) tabulate a different normalisation of the same idea."
    display as text "  None of these tests tells you WHERE the threshold is. For that, and"
    display as text "  for a p-value that survives having searched, use {bf:thtest} and"
    display as text "  {bf:thtar}; for a smooth alternative use {bf:thstar}."

    * ---------------------------------------------------- return
    return scalar N        = `nobs'
    return scalar k_lags   = `p'
    return scalar startup  = `startup'
    return scalar F_keenan = `KE'[1,1]
    return scalar p_keenan = `KE'[1,3]
    return scalar F_tsay86 = `T86'[1,1]
    return scalar p_tsay86 = `T86'[1,3]
    return scalar delay    = `bestdlag'
    return scalar F_tsay89 = __tk_bestF
    return scalar p_tsay89 = __tk_bestp
    return scalar delay_cusum = `cbestdlag'
    return scalar cusum    = __tk_cbest
    return scalar p_cusum  = __tk_cbestp
    if `reps' > 0 {
        return scalar reps        = `reps'
        return scalar pb_keenan   = __tk_pb_keenan
        return scalar pb_tsay86   = __tk_pb_tsay86
        return scalar pb_tsay89   = __tk_pb_tsayF
        return scalar pb_cusum    = __tk_pb_cusum
        capture return matrix bdist = __tk_bdist
    }
    return local  cmd      "thnltest"
    return local  depvar   "`depv'"
    return local  arnames  "`arnames'"
    return matrix tsay86   = `T86'
    return matrix keenan   = `KE'
    return matrix arranged = `ARR'

    _tk_drop
end

* ======================================================================
* The multivariate form: Tsay's (1998) C(d) test of a linear VAR against a
* threshold VAR, computed from the multivariate arranged autoregression.
* ======================================================================
program define Multi, rclass
    version 15
    syntax varlist(numeric ts min=2) [if] [in] , AR(numlist integer >0 sort) ///
        [ DELAY(numlist integer >0 sort)                                     ///
          THVar(varlist numeric ts)                                          ///
          STARTup(integer 0)                                                 ///
          REPS(integer 0)                                                    ///
          SEED(string)                                                       ///
          noCONStant ]

    capture tsset
    if _rc {
        display as error "{bf:thnltest} requires the data to be {bf:tsset}"
        exit 459
    }
    local timevar "`r(timevar)'"
    if "`seed'" != "" set seed `seed'
    local hascons = cond("`constant'"=="", 1, 0)
    local yvars `varlist'
    local k : word count `yvars'
    local p : word count `ar'

    marksample touse
    markout `touse' `yvars' `thvar'

    * ---- the VAR design: every listed lag of every variable
    local wvars ""
    local wnames ""
    local nw 0
    foreach j of local ar {
        foreach v of local yvars {
            local ++nw
            quietly generate double __tkn_w`nw' = L`j'.`v' if `touse'
            local wvars `wvars' __tkn_w`nw'
            local wnames `wnames' L`j'.`v'
        }
    }
    * ---- the dependent variables as explicit columns
    local ycols ""
    local ny 0
    foreach v of local yvars {
        local ++ny
        quietly generate double __tkn_y`ny' = `v' if `touse'
        local ycols `ycols' __tkn_y`ny'
    }
    * ---- the candidate threshold variables
    if "`thvar'" != "" {
        local cand "`thvar'"
    }
    else {
        if "`delay'" == "" local delay `ar'
        local first : word 1 of `yvars'
        local cand ""
        foreach d of local delay {
            local cand `cand' L`d'.`first'
        }
    }
    local zcands ""
    local labs ""
    local nz 0
    foreach zz of local cand {
        local ++nz
        quietly generate double __tkn_z`nz' = `zz' if `touse'
        local zcands `zcands' __tkn_z`nz'
        local labs `labs' `zz'
    }
    markout `touse' `wvars' `ycols' `zcands'
    quietly count if `touse'
    local nobs = r(N)
    local kw = `nw' + `hascons'
    if `nobs' < 3 * `kw' + 10 {
        display as error "too few usable observations (`nobs') for a `kw'-regressor VAR"
        capture drop __tkn_*
        exit 2001
    }
    if `startup' <= 0 local startup = max(`kw' + 1, floor(`nobs'/10) + `kw')
    if `startup' >= `nobs' - `kw' {
        display as error "startup(`startup') leaves no recursion"
        capture drop __tkn_*
        exit 198
    }
    local yvars_m "`ycols'"

    _tk_drop __tk_arrm
    local yvars "`ycols'"
    mata: tk_thnltest_m()

    tempname A
    matrix `A' = __tk_arrm
    local besti = __tk_mbesti
    local bestp = __tk_mbestp
    _tk_drop __tk_arrm
    _tk_drop __tk_mbesti __tk_mbestp __tk_mn __tk_mk __tk_mkw
    capture drop __tkn_*

    local bestlab "."
    if `besti' < . local bestlab : word `besti' of `labs'

    display _n as text "Tsay (1998) multivariate threshold nonlinearity test" _col(56) ///
        "Obs" _col(68) "=" _col(71) as result %9.0fc `nobs'
    display as text "  Variables: " as result "`varlist'" _col(56) ///
        as text "Eqs" _col(68) "=" _col(71) as result %9.0f `k'
    display as text "  Lags used: " as result "`wnames'" _col(56) ///
        as text "Startup" _col(68) "=" _col(71) as result %9.0f `startup'
    display ""
    display as text "{hline 78}"
    display as text "  ordering by" _col(24) "C(d) = LR" _col(38) "F" ///
        _col(50) "df" _col(64) "p (F)"
    display as text "{hline 78}"
    forvalues i = 1/`=rowsof(`A')' {
        local lab : word `i' of `labs'
        local mark = cond(`i' == `besti', " *", "  ")
        if `A'[`i',3] < . {
            display as text "  " as result %-16s abbrev("`lab'", 16) as text "`mark'" ///
                _col(21) as result %11.4f `A'[`i',3] ///
                _col(33) %10.4f `A'[`i',4] ///
                _col(45) as text "(" as result %3.0f `A'[`i',5] as text "," ///
                as result %6.0f `A'[`i',6] as text ")" ///
                _col(60) as result %10.4f `A'[`i',10]
        }
        else {
            display as text "  " %-16s abbrev("`lab'", 16) "`mark'" _col(21) ///
                "(not computable)"
        }
    }
    display as text "{hline 78}"
    if `besti' < . {
        display as text "  * smallest p-value: ordering by " as result "`bestlab'" ///
            as text ", p = " as result %7.5f `bestp'
        display as text "    Having chosen the ordering by minimising the p-value, that"
        display as text "    number is optimistic. Report it as a selection, and confirm"
        display as text "    with the bootstrap test in {bf:thtvar, test}."
    }
    display as text "{hline 78}"
    display as text "  C(d) is reported as the Wilks LR, M ln(|S0|/|S1|), and as Rao's F."
    display as text "  Tsay's published C(d) scales the log ratio by [M - b - kw] rather"
    display as text "  than M; the difference is O(1/M). Report the F version: the"
    display as text "  chi-square forms of multivariate LM and LR statistics are heavily"
    display as text "  oversized at these sample sizes. Degrees of freedom are k times"
    display as text "  the RANK of the arranged design, not its column count."
    display as text "  The test says whether the VAR changes somewhere along the chosen"
    display as text "  ordering, NOT where. For the threshold itself use {bf:thtvar}."

    matrix colnames `A' = cand LM LR F df1 df2 chi2_df p_LM p_LR p_F M
    return matrix arranged = `A'
    return scalar N       = `nobs'
    return scalar k_eq    = `k'
    return scalar startup = `startup'
    return scalar p_tsayC = `bestp'
    return local  best    "`bestlab'"
    return local  cands   "`labs'"
    return local  cmd     "thnltest"
    return local  mode    "multivariate"
end
