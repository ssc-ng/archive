*! thsearch 1.0.0  05oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Which threshold variable, and which delay?
*!
*! Searching a SET of candidate threshold variables and then reporting the
*! best one's ordinary p-value is one of the commonest ways to manufacture a
*! threshold that is not there. Hansen's (1996) equation (7) defines the
*! statistic as a supremum over the threshold value AND the candidate set, and
*! thsearch computes exactly that: the bootstrap repeats the whole search on
*! every replication, so the p-value it reports is a p-value of the searched
*! statistic.
*!
*! Hansen (1996) Econometrica 64:413-430, doi:10.2307/2171789
*! Hansen (1999) J. Economic Surveys 13:551-576, doi:10.1111/1467-6419.00098
*! Tsay (1989) JASA 84:231-240, doi:10.1080/01621459.1989.10478760
*! Terasvirta (1994) JASA 89:208-218, doi:10.1080/01621459.1994.10476462
*! Lundbergh, Terasvirta & van Dijk (2003) JBES 21:104-121,
*!   doi:10.1198/073500102288618810

program define thsearch, rclass sortpreserve
    version 15

    syntax varlist(numeric fv ts min=1) [if] [in] ,  ///
        [ CANDidates(varlist numeric fv ts)          ///
          DELAY(numlist integer >0 sort)             ///
          DVar(varname numeric ts)                   ///
          TRIM(real 0.15)                            ///
          GRIDn(integer 0)                           ///
          MINOBS(integer 0)                          ///
          noCONStant                                 ///
          STAT(string)                               ///
          VCE(string)                                ///
          ORDer(integer 3)                           ///
          CRITerion(string)                          ///
          REPS(integer 500)                          ///
          SEED(string)                               ///
          GRaph                                      ///
          SAVing(string asis) ]

    * ------------------------------------------------ option checks
    if "`candidates'" == "" & "`delay'" == "" {
        display as error "specify {bf:candidates()}, {bf:delay()}, or both"
        display as error "{bf:thsearch} has nothing to search over otherwise"
        exit 198
    }
    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        exit 198
    }
    if `order' < 0 | `order' > 3 {
        display as error "{bf:order()} must be 0, 1, 2 or 3"
        exit 198
    }
    if `reps' < 0 {
        display as error "{bf:reps()} must be 0 or more ({bf:reps(0)} skips the bootstrap)"
        exit 198
    }
    if "`stat'" == "" local stat sup
    if !inlist("`stat'", "sup", "ave", "exp") {
        display as error "{bf:stat()} must be sup, ave or exp"
        exit 198
    }
    local statno = cond("`stat'"=="sup", 1, cond("`stat'"=="ave", 2, 3))
    if "`criterion'" == "" local criterion ssr
    if !inlist("`criterion'", "ssr", "lmp", "stat") {
        display as error "{bf:criterion()} must be ssr, lmp or stat"
        exit 198
    }
    if "`criterion'" == "lmp" & `order' == 0 {
        display as error "{bf:criterion(lmp)} needs the Taylor test: do not set {bf:order(0)}"
        exit 198
    }
    local robust 0
    if "`vce'" != "" {
        local v = lower(trim("`vce'"))
        if inlist("`v'", "robust", "hc0", "hetero") local robust 1
        else if "`v'" == "ols" | "`v'" == "homoskedastic" local robust 0
        else {
            display as error "{bf:vce()} must be robust or ols"
            exit 198
        }
    }
    if "`seed'" != "" set seed `seed'
    local hascons = cond("`constant'"=="", 1, 0)

    * ------------------------------------------------ sample and regressors
    marksample touse
    gettoken depv indeps : varlist
    _fv_check_depvar `depv'

    if "`delay'" != "" {
        if "`dvar'" == "" local dvar `depv'
        capture tsset
        if _rc {
            display as error "{bf:delay()} builds lags, so the data must be {bf:tsset}"
            exit 459
        }
    }

    local xlist ""
    local xvars ""
    if "`indeps'" != "" {
        fvexpand `indeps' if `touse'
        local xlist `r(varlist)'
        fvrevar `xlist' if `touse'
        local xvars `r(varlist)'
        markout `touse' `xvars'
    }
    if "`xvars'" == "" & !`hascons' {
        display as error "with {bf:noconstant} at least one regressor is required"
        exit 198
    }

    * ------------------------------------------------ the candidate set
    local qvars ""
    local qnames ""
    if "`candidates'" != "" {
        fvexpand `candidates' if `touse'
        local clist `r(varlist)'
        fvrevar `clist' if `touse'
        local qvars `r(varlist)'
        local qnames `clist'
    }
    if "`delay'" != "" {
        foreach d of local delay {
            tempvar qd`d'
            quietly generate double `qd`d'' = L`d'.`dvar'
            local qvars  `qvars'  `qd`d''
            local qnames `qnames' L`d'.`dvar'
        }
    }
    local nc : word count `qvars'
    markout `touse' `qvars'
    quietly count if `touse'
    local nobs = r(N)
    if `nobs' == 0 error 2000
    if `nobs' < 10 * (`nc' > 0) & `nobs' < 20 {
        display as error "only `nobs' usable observations after lagging"
        exit 2001
    }

    * ------------------------------------------------ engine
    capture mata: tk_thsearch()
    if _rc {
        display as error "the search engine failed (rc=" _rc ")"
        display as error "check that the Mata library is indexed: {bf:mata mlib index}"
        exit _rc
    }

    tempname TAB PM BD
    matrix `TAB' = __tk_srtab
    matrix `PM'  = __tk_srp
    local n      = __tk_srn
    local ssr0   = __tk_srssr0
    local obsmax = __tk_srmax
    local pjoint = __tk_srpj
    local bestc  = __tk_srbest
    local bestlm = __tk_srbestlm
    capture matrix `BD' = __tk_srbd

    local bestname : word `bestc' of `qnames'
    local lmname ""
    if `bestlm' < . local lmname : word `bestlm' of `qnames'

    * the column holding the statistic the bootstrap reproduced
    local off = cond(`robust', 6, 2)
    local scol = `off' + `statno'
    local sname = cond(`robust', "`stat'-LM", "`stat'-F")

    * which candidate attains the maximum of that statistic
    local bests = .
    local bestsc = .
    forvalues c = 1/`nc' {
        if `TAB'[`c',`scol'] < . {
            if `bests' == . | `TAB'[`c',`scol'] > `bests' {
                local bests = `TAB'[`c',`scol']
                local bestsc = `c'
            }
        }
    }
    local bestsname ""
    if `bestsc' < . local bestsname : word `bestsc' of `qnames'

    * ------------------------------------------------ display
    display ""
    display as text "Searching for the threshold variable"
    display as text "  Model" _col(24) as result "`depv'" as text " on " ///
        as result "`xlist'" cond(`hascons'," _cons","")
    display as text "  Candidates" _col(24) as result "`nc'" as text ///
        "   N = " as result "`n'" as text "   trim = " as result %4.2f `trim'
    display as text "  Statistic" _col(24) as result "`sname'" as text ///
        cond(`robust', "   (heteroskedasticity-robust)", "   (homoskedastic)")
    display ""
    display as text "{hline 79}"
    display as text "  candidate" _col(26) "min SSR" _col(40) "gamma" ///
        _col(52) "`sname'" _col(64) "boot p"
    display as text "{hline 79}"
    forvalues c = 1/`nc' {
        local nm : word `c' of `qnames'
        local mark = ""
        if `c' == `bestc' local mark = "*"
        display as text "  `mark'" _continue
        display as text %-22s abbrev("`nm'", 22) _continue
        if `TAB'[`c',1] < . {
            display as result _col(26) %13.6f `TAB'[`c',1] ///
                _col(40) %11.6g `TAB'[`c',2] _col(50) %11.4f `TAB'[`c',`scol'] _continue
        }
        else {
            display as text _col(26) %13s "(no grid)" _continue
        }
        if `PM'[`c',1] < . {
            display as result _col(62) %10.4f `PM'[`c',1]
        }
        else display ""
    }
    display as text "{hline 79}"
    display as text "  * smallest residual sum of squares"
    if `order' > 0 {
        display ""
        display as text "Linearity against a smooth transition in each candidate"
        display as text "  (order-`order' Taylor LM of Terasvirta 1994; rank-based df)"
        display as text "{hline 79}"
        display as text "  candidate" _col(30) "LM" _col(44) "df" _col(56) "p"
        display as text "{hline 79}"
        forvalues c = 1/`nc' {
            local nm : word `c' of `qnames'
            local mark = cond(`c' == `bestlm', "+", " ")
            display as text "  `mark'" _continue
            display as text %-24s abbrev("`nm'", 24) _continue
            if `TAB'[`c',13] < . {
                display as result _col(28) %12.4f `TAB'[`c',13] ///
                    _col(42) %10.0f `TAB'[`c',14] _col(52) %12.4f `TAB'[`c',15]
            }
            else display as text _col(28) %12s "(not estimable)"
        }
        display as text "{hline 79}"
        display as text "  + smallest linearity p-value"
    }

    * ------------------------------------------------ the verdict
    display ""
    display as text "{hline 79}"
    display as text "Verdict"
    display as text "{hline 79}"
    display as text "  argmin SSR" _col(34) as result "`bestname'" ///
        as text "   at gamma = " as result %10.6g `TAB'[`bestc',2]
    if `bestsc' < . {
        display as text "  argmax `sname'" _col(34) as result "`bestsname'" ///
            as text "   stat = " as result %10.4f `bests'
    }
    if `order' > 0 & `bestlm' < . {
        display as text "  argmin linearity p" _col(34) as result "`lmname'" ///
            as text "   p = " as result %10.4f `TAB'[`bestlm',15]
    }
    if `pjoint' < . {
        local mcse = sqrt(`pjoint' * (1 - `pjoint') / `reps')
        display as text "{hline 79}"
        display as text "  search-corrected p-value" _col(40) as result %12.4f `pjoint' ///
            as text "   MC s.e. " as result %6.4f `mcse'
        display as text "  (sup over gamma AND over all `nc' candidates, `reps' replications)"
        display as text "{hline 79}"
        display as text "  THIS is the p-value to report when the threshold variable was"
        display as text "  chosen from the data. The ""boot p"" column above is each"
        display as text "  candidate's own marginal p-value: valid only for a candidate"
        display as text "  fixed a priori, and anti-conservative if it was selected here."
    }
    else {
        display as text "{hline 79}"
        display as text "  No bootstrap was run ({bf:reps(0)}), so no p-value is reported."
        display as text "  The nominal distribution of a statistic maximised over `nc'"
        display as text "  candidates is not chi-squared and not tabulated: without the"
        display as text "  bootstrap this table is a ranking, not a test."
    }
    display as text "{hline 79}"
    if `nc' > 1 {
        display as text "  The three criteria need not agree. Minimum SSR is the"
        display as text "  least-squares choice and is what {bf:thtar}/{bf:thregress} will"
        display as text "  reproduce; the smallest linearity p-value is the"
        display as text "  Lundbergh-Terasvirta-van Dijk rule and is the right one when a"
        display as text "  SMOOTH transition is intended. When they disagree, the threshold"
        display as text "  variable is not sharply identified: report that, and fit both."
    }
    display as text "  Next: {bf:thtar} or {bf:thregress} with the chosen variable, or"
    display as text "  {bf:thselect} for how many thresholds it supports."

    * ------------------------------------------------ graph
    if "`graph'" != "" {
        preserve
            quietly {
                clear
                local ne = `nc'
                set obs `ne'
                generate int cand = _n
                generate double ssr  = .
                generate double stat = .
                generate double lmp  = .
                forvalues c = 1/`ne' {
                    replace ssr  = `TAB'[`c',1]      in `c'
                    replace stat = `TAB'[`c',`scol'] in `c'
                    replace lmp  = `TAB'[`c',15]     in `c'
                }
                label define __tkcand 1 "x", modify
                forvalues c = 1/`ne' {
                    local nm : word `c' of `qnames'
                    label define __tkcand `c' "`nm'", modify
                }
                label values cand __tkcand
            }
            twoway (connected ssr cand, sort msymbol(O) lcolor(navy) mcolor(navy)) ///
                , ytitle("minimised SSR") xtitle("candidate threshold variable")   ///
                  xlabel(1(1)`nc', valuelabel angle(45) labsize(small))            ///
                  title("Which threshold variable minimises the SSR?")             ///
                  subtitle("lower is better; a flat profile means no candidate is preferred")
            if `"`saving'"' != "" _tk_gsave `saving'
        restore
    }

    * ------------------------------------------------ return
    matrix colnames `TAB' = ssr gamma_ssr supF aveF expF gamma_F ///
        supLM aveLM expLM gamma_LM ngrid nskip LM3 df_LM3 p_LM3
    matrix colnames `PM' = p_marginal
    local rn ""
    forvalues c = 1/`nc' {
        local nm : word `c' of `qnames'
        local rn `rn' `nm'
    }
    capture matrix rownames `TAB' = `rn'
    capture matrix rownames `PM'  = `rn'

    * , copy because return matrix MOVES the matrix: without it the tempname
    * is destroyed and any later subscript of it fails with "not found".
    return matrix table    = `TAB', copy
    return matrix pmarg    = `PM', copy
    capture return matrix bootdist = `BD', copy
    return scalar N        = `n'
    return scalar ssr0     = `ssr0'
    return scalar n_cand   = `nc'
    return scalar stat_max = `obsmax'
    if `pjoint' < . {
        return scalar p     = `pjoint'
        return scalar p_mcse = sqrt(`pjoint' * (1 - `pjoint') / `reps')
        return scalar reps  = `reps'
    }
    return scalar best     = `bestc'
    return local  bestvar  "`bestname'"
    return scalar gamma    = `TAB'[`bestc',2]
    if `bestlm' < . {
        return scalar best_lm  = `bestlm'
        return local  bestvar_lm "`lmname'"
    }
    if `bestsc' < . {
        return scalar best_stat = `bestsc'
        return local  bestvar_stat "`bestsname'"
    }
    return local candidates "`qnames'"
    return local criterion  "`criterion'"
    return local statistic  "`sname'"
    return local depvar     "`depv'"
    return local indepvars  "`xlist'"
    return local cmd        "thsearch"

    * matrix drop and scalar drop take _all or exact names, NOT wildcards:
    * "matrix drop __tk_sr*" silently drops nothing.
    _tk_drop __tk_srn __tk_srssr0 __tk_srmax __tk_srpj __tk_srbest __tk_srbestlm
    _tk_drop __tk_srtab __tk_srp __tk_srbd
end
