*! version 1.2.1  15nov2026
*! cspmed: causal mediation analysis for cross-sectional and complex-survey
*! data (weighted OLS, logit, probit, ordered and multinomial logit/probit,
*! 2SLS, DML) with multiple mediators
*! Author: Yusuf Toyin Yusuf, Kwara State University, Malete, Nigeria

program define cspmed, eclass sortpreserve
    version 14.0

    if replay() {
        if ("`e(cmd)'" != "cspmed") error 301
        _cp_display `0'
        exit
    }

    syntax varname(numeric) [if] [in] [pweight],    ///
        TREATment(varname numeric)                  ///
        MEDiators(varlist numeric)                  ///
        [ CONTrols(varlist numeric)                 ///
          ESTimator(string)                         ///
          CLuster(varname) STRata(varname) SVY      ///
          IVs(varlist numeric) MEDIVs(varlist numeric) ///
          LEWbel(string) LEWBELVars(varlist numeric) ///
          INTERaction                               ///
          POLY(integer 2) FOLDs(integer 5)          ///
          RIDGE(real 0) GHnodes(integer 15)         ///
          D1(real 1) D0(real 0)                     ///
          BOOTstrap(integer 0) SEED(string)         ///
          NODOTS NODIAG Level(cilevel) ]

    local depvar `varlist'
    if "`estimator'" == "" local estimator ols
    local estimator = lower("`estimator'")
    local estlist ols logit probit iv dml ologit oprobit mlogit mprobit
    if !`: list estimator in estlist' {
        di as err "estimator() must be one of: `estlist'"
        exit 198
    }
    local estcode : list posof "`estimator'" in estlist
    if `d1' == `d0' {
        di as err "d1() and d0() must differ"
        exit 198
    }
    if `bootstrap' > 0 & `bootstrap' < 50 {
        di as err "bootstrap() should be at least 50 replications"
        exit 198
    }
    if !inrange(`poly', 1, 3) | `folds' < 2 | `ghnodes' < 5 {
        di as err "invalid poly(), folds() or ghnodes()"
        exit 198
    }
    local allv `depvar' `treatment' `mediators'
    local dups : list dups allv
    if "`dups'" != "" {
        di as err "depvar, treatment() and mediators() must be distinct"
        exit 198
    }
    local controls : list controls - allv
    local km : word count `mediators'
    local kx : word count `controls'
    local lewbel = lower("`lewbel'")
    if !inlist("`lewbel'", "", "mediators", "treatment", "both") {
        di as err "lewbel() must be mediators, treatment or both"
        exit 198
    }
    if "`lewbel'" != "" & "`estimator'" != "iv" {
        di as err "lewbel() requires estimator(iv)"
        exit 198
    }
    local lewm = inlist("`lewbel'", "mediators", "both") & "`medivs'" == ""
    local lewd = inlist("`lewbel'", "treatment", "both") & "`ivs'" == ""
    if "`lewbelvars'" == "" local lewbelvars `controls'
    if (`lewm' | `lewd') & "`lewbelvars'" == "" {
        di as err "Lewbel instruments need controls() or lewbelvars() as heteroskedasticity drivers"
        exit 198
    }
    if !(`lewm' | `lewd') local lewbelvars
    if "`estimator'" == "iv" {
        if "`ivs'" == "" & "`medivs'" == "" & !`lewm' & !`lewd' {
            di as err "estimator(iv) needs ivs(), medivs() and/or lewbel()"
            exit 198
        }
        if "`medivs'" != "" & `: word count `medivs'' < `km' {
            di as err "medivs() needs at least as many instruments as mediators"
            exit 198
        }
        if ("`ivs'" != "" | `lewd') & "`medivs'" == "" & !`lewm' {
            di as txt "(note: mediators are treated as exogenous in the outcome equation; if the"
            di as txt " treatment is endogenous the mediators generally are too: supply medivs())"
        }
    }
    else {
        local ivs
        local medivs
    }
    local catest = inlist("`estimator'", "ologit", "oprobit", "mlogit", "mprobit")
    local nlest = inlist("`estimator'", "logit", "probit") | `catest'
    if "`interaction'" != "" & !inlist("`estimator'", "ols", "logit", "probit", "ologit", "oprobit", "mlogit", "mprobit") {
        di as txt "(note: interaction applies to ols, logit, probit, ologit, oprobit, mlogit and mprobit only; ignored)"
        local interaction
    }
    if "`estimator'" == "dml" & "`controls'" == "" {
        di as err "estimator(dml) needs controls()"
        exit 198
    }

    * ---------------- survey design ----------------
    local wvar ""
    if "`weight'" != "" {
        local wexp2 = subinstr("`exp'", "=", "", 1)
        tempvar wv
        qui gen double `wv' = `wexp2'
        local wvar `wv'
    }
    if "`svy'" != "" {
        qui svyset
        if "`r(settings)'" == ", clear" {
            di as err "data are not svyset"
            exit 119
        }
        if "`wvar'" == "" & "`r(wvar)'" != "" {
            local wvar `r(wvar)'
            local wlabel "`r(wtype)'= `r(wvar)'"
        }
        if "`cluster'" == "" & "`r(su1)'" != "" & "`r(su1)'" != "_n" local cluster `r(su1)'
        if "`strata'" == "" & "`r(strata1)'" != "" local strata `r(strata1)'
    }

    marksample touse
    markout `touse' `treatment' `mediators' `controls' `ivs' `medivs' `lewbelvars' `wvar'
    if "`cluster'" != "" markout `touse' `cluster', strok
    if "`strata'" != "" markout `touse' `strata', strok
    qui count if `touse'
    local N = r(N)
    if `N' < 20 error 2001
    if inlist("`estimator'", "logit", "probit") {
        qui count if `touse' & !inlist(`depvar', 0, 1)
        if r(N) > 0 {
            di as err "estimator(`estimator') requires a 0/1 outcome"
            exit 450
        }
    }
    if `catest' {
        tempvar tagv
        qui egen byte `tagv' = tag(`depvar') if `touse'
        qui count if `tagv' == 1
        local ncat = r(N)
        if `ncat' < 3 {
            di as err "estimator(`estimator') needs an outcome with at least 3 categories; use logit or probit for a binary outcome"
            exit 450
        }
        if `ncat' > 20 {
            di as err "estimator(`estimator'): outcome has `ncat' distinct values (at most 20 allowed)"
            exit 450
        }
    }

    tempvar one gs gg
    qui gen byte `one' = 1
    if "`strata'" == "" local strata `one'
    if "`cluster'" == "" {
        tempvar obsid
        qui gen long `obsid' = _n
        local clv `obsid'
    }
    else local clv `cluster'
    qui egen long `gs' = group(`strata') if `touse'
    qui egen long `gg' = group(`strata' `clv') if `touse'
    if "`wvar'" == "" local wvar `one'
    sort `touse' `gg'
    if "`seed'" != "" set seed `seed'

    tempname b V EFF VEFF BBOOT DIAG
    mata: _cp_main("`depvar'", "`treatment'", "`mediators'", "`controls'", "`ivs'",   ///
        "`medivs'", "`lewbelvars'", `lewd', `lewm',                                  ///
        "`wvar'", "`gg'", "`gs'", "`touse'", `estcode',                              ///
        ("`interaction'"!=""), `poly', `folds', `ridge', `ghnodes', `d1', `d0',      ///
        `bootstrap', ("`nodots'"==""), `level', ("`nodiag'"==""))

    * ---------------- names ----------------
    local mlinks ""
    forvalues j = 1/`km' {
        local mlinks `mlinks' `=__cp_mlinkm[1, `j']'
    }
    local names ""
    if "`estimator'" == "dml" {
        foreach v in `treatment' `mediators' {
            local names `names' `depvar':`v'
        }
        foreach m of local mediators {
            local names `names' `m':`treatment'
        }
    }
    else {
        local rhs `treatment' `mediators'
        if "`interaction'" != "" {
            foreach m of local mediators {
                local rhs `rhs' c.`treatment'#c.`m'
            }
        }
        local rhs `rhs' `controls'
        if inlist("`estimator'", "ologit", "oprobit") {
            foreach v of local rhs {
                local names `names' `depvar':`v'
            }
            forvalues k = 1/`=`ncat'-1' {
                local names `names' cut`k':_cons
            }
        }
        else if inlist("`estimator'", "mlogit", "mprobit") {
            forvalues k = 2/`ncat' {
                local names `names' c`k':_cons
                foreach v of local rhs {
                    local names `names' c`k':`v'
                }
            }
        }
        else {
            local names `names' `depvar':_cons
            foreach v of local rhs {
                local names `names' `depvar':`v'
            }
        }
        foreach m of local mediators {
            local names `names' `m':_cons `m':`treatment'
            foreach v of local controls {
                local names `names' `m':`v'
            }
        }
        if `nlest' {
            local j 0
            foreach m of local mediators {
                local ++j
                local lk : word `j' of `mlinks'
                if "`lk'" == "0" local names `names' sigma2:`m'
            }
        }
    }
    matrix `b' = __cp_b
    matrix `V' = __cp_V
    matrix colnames `b' = `names'
    matrix colnames `V' = `names'
    matrix rownames `V' = `names'
    local base NDE NIE TE PM
    if `km' > 1 {
        foreach m of local mediators {
            local base `base' NIE_`=substr("`m'", 1, 28)'
        }
    }
    if `catest' {
        tempname CATS
        matrix `CATS' = __cp_cats
        local targets ""
        if inlist("`estimator'", "ologit", "oprobit") local targets EY
        forvalues k = 1/`ncat' {
            local targets `targets' c`k'
        }
        local enames ""
        foreach t of local targets {
            foreach nm of local base {
                local enames `enames' `t':`nm'
            }
        }
        local cnm ""
        forvalues k = 1/`ncat' {
            local cnm `cnm' c`k'
        }
        matrix colnames `CATS' = `cnm'
        local llm = scalar(__cp_ll)
        local ll0 = scalar(__cp_ll0)
    }
    else local enames `base'
    matrix `EFF' = __cp_eff
    matrix `VEFF' = __cp_veff
    matrix rownames `EFF' = `enames'
    matrix colnames `EFF' = b se z pvalue ll ul
    matrix colnames `VEFF' = `enames'
    matrix rownames `VEFF' = `enames'
    if "`nodiag'" == "" {
        matrix `DIAG' = __cp_diag
        local dn Koenker White JB RESET maxVIF FS1 FS2 FS3 FS4 HansenJ Endog PseudoR2 HL LinkTest
        matrix rownames `DIAG' = `dn'
        local cn ""
        foreach v in `depvar' `mediators' {
            local cn `cn' `v':stat `v':df1 `v':df2 `v':p
        }
        matrix colnames `DIAG' = `cn'
    }
    local nfail = scalar(__cp_bfail)
    local npsu = scalar(__cp_npsu)
    local nstr = scalar(__cp_nstr)
    if `bootstrap' > 0 {
        matrix `BBOOT' = __cp_bboot
        matrix colnames `BBOOT' = `enames'
    }
    foreach x in b V eff veff bboot diag {
        capture matrix drop __cp_`x'
    }
    foreach x in bfail npsu nstr {
        capture scalar drop __cp_`x'
    }
    capture matrix drop __cp_mlinkm
    capture matrix drop __cp_cats
    capture scalar drop __cp_ll
    capture scalar drop __cp_ll0

    ereturn post `b' `V', esample(`touse') obs(`N') depname(`depvar')
    ereturn scalar km = `km'
    ereturn scalar N_psu = `npsu'
    ereturn scalar N_strata = `nstr'
    ereturn scalar d1 = `d1'
    ereturn scalar d0 = `d0'
    ereturn scalar level = `level'
    ereturn scalar bootstrap = `bootstrap'
    if `bootstrap' > 0 {
        ereturn scalar boot_fail = `nfail'
        ereturn matrix eff_boot = `BBOOT'
    }
    if "`nodiag'" == "" ereturn matrix diag = `DIAG'
    ereturn matrix effects = `EFF'
    ereturn matrix V_eff = `VEFF'
    if `catest' {
        ereturn scalar k_cat = `ncat'
        ereturn scalar ll = `llm'
        ereturn scalar ll_0 = `ll0'
        ereturn matrix cats = `CATS'
    }
    ereturn local mlinks      "`mlinks'"
    ereturn local estimator   "`estimator'"
    ereturn local interaction "`interaction'"
    ereturn local ivs         "`ivs'"
    ereturn local medivs      "`medivs'"
    ereturn local lewbel      = cond(`lewm' & `lewd', "both", cond(`lewm', "mediators", cond(`lewd', "treatment", "")))
    ereturn local lewbelvars  "`lewbelvars'"
    if "`wlabel'" == "" local wlabel "`weight'`exp'"
    ereturn local wvar        = cond("`wvar'"=="`one'", "", "`wlabel'")
    ereturn local clustvar    = cond("`clv'"=="`cluster'", "`cluster'", "")
    ereturn local strata      = cond("`strata'"=="`one'", "", "`strata'")
    ereturn local controls    "`controls'"
    ereturn local mediators   "`mediators'"
    ereturn local treatment   "`treatment'"
    ereturn local title       "Cross-sectional / survey causal mediation analysis"
    ereturn local cmdline     `"cspmed `0'"'
    ereturn local cmd         "cspmed"
    _cp_display, level(`level')
end

program define _cp_display
    syntax [, Level(cilevel)]
    local est "`e(estimator)'"
    local lab_ols    "Linear (weighted) least squares"
    local lab_logit  "Logit outcome, counterfactual effects"
    local lab_probit "Probit outcome, counterfactual effects"
    local lab_iv     "Two-stage least squares"
    local lab_ologit  "Ordered logit outcome, counterfactual effects"
    local lab_oprobit "Ordered probit outcome, counterfactual effects"
    local lab_mlogit  "Multinomial logit outcome, counterfactual effects"
    local lab_mprobit "Multinomial probit outcome, counterfactual effects"
    local catest = inlist("`est'", "ologit", "oprobit", "mlogit", "mprobit")
    local lab_dml    "DML partialling-out, cross-fitted"
    di
    di as txt "`e(title)'" _col(55) "Number of obs = " as res %8.0fc e(N)
    di as txt "Estimator: " as res "`lab_`est''" _col(55) as txt "PSUs          = " as res %8.0fc e(N_psu)
    di as txt "Weights: " as res cond("`e(wvar)'"=="", "none", "`e(wvar)'") ///
        _col(55) as txt "Strata        = " as res %8.0fc e(N_strata)
    di as txt "Variance: Taylor linearization" cond("`e(clustvar)'"=="", "", ", PSU " + "`e(clustvar)'") ///
        cond("`e(strata)'"=="", "", ", strata " + "`e(strata)'")
    di as txt "Mediators: " as res "`e(mediators)'" as txt cond("`e(interaction)'"=="", "", "  (treatment x mediator interactions)")
    if "`e(lewbel)'" != "" di as txt "Lewbel (2012) instruments for: " as res "`e(lewbel)'" as txt " (drivers: `e(lewbelvars)')"
    if inlist("`est'", "logit", "probit") | `catest' di as txt "Mediator models (0 linear, 1 logit, 2 probit): " as res "`e(mlinks)'"
    if `catest' {
        tempname CT
        matrix `CT' = e(cats)
        local ctxt ""
        forvalues k = 1/`=colsof(`CT')' {
            local ctxt = "`ctxt' c`k' = " + string(`CT'[1,`k'], "%9.0g")
        }
        di as txt "Outcome categories:" as res "`ctxt'"
        if inlist("`est'", "mlogit", "mprobit") di as txt "Base outcome: " as res "c1"
    }
    ereturn display, level(`level')

    tempname E
    matrix `E' = e(effects)
    local rn : rownames `E'
    local req : roweq `E'
    di
    di as txt "Causal mediation effects of moving `e(treatment)' from " as res %9.0g e(d0) as txt " to " as res %9.0g e(d1)
    if e(bootstrap) > 0 di as txt "Inference: PSU bootstrap within strata, " as res e(bootstrap) as txt " replications (percentile CI)"
    else di as txt "Inference: linearization, including the averaging over the sample"
    di as txt "NDE natural direct, NIE natural indirect, TE total effect, PM proportion mediated"
    if `catest' di as txt "E[Y]: expected outcome; Pr(Y=k): probability of outcome category k"
    di as txt "{hline 13}{c TT}{hline 64}"
    di as txt %12s "Effect" " {c |}" "      Coef.   Std. Err.      z    P>|z|     [`level'% Conf. Interval]"
    di as txt "{hline 13}{c +}{hline 64}"
    local r 0
    local prev ""
    if `catest' {
        tempname CT2
        matrix `CT2' = e(cats)
    }
    foreach nm of local rn {
        local ++r
        local eq : word `r' of `req'
        if "`eq'" != "_" & "`eq'" != "`prev'" {
            if "`eq'" == "EY" local hdr "E[Y]"
            else {
                local kq = real(substr("`eq'", 2, .))
                local hdr = "Pr(Y=" + string(`CT2'[1, `kq'], "%6.0g") + ")"
            }
            if "`prev'" != "" di as txt "{hline 13}{c +}{hline 64}"
            di as res %12s abbrev("`hdr'", 12) as txt " {c |}"
            local prev "`eq'"
        }
        local lab "`nm'"
        if "`nm'" == "NDE" local lab "NDE"
        if "`nm'" == "NIE" local lab "NIE"
        if "`nm'" == "TE"  local lab "TE"
        if "`nm'" == "PM"  local lab "PM"
        if substr("`nm'", 1, 4) == "NIE_" {
            local medn = substr("`nm'", 5, .)
            local lab "via `medn'"
        }
        di as txt %12s abbrev("`lab'", 12) " {c |}  " as res %9.0g `E'[`r',1] "  " %9.0g `E'[`r',2] ///
            "  " %7.2f `E'[`r',3] "  " %6.3f `E'[`r',4] "    " %9.0g `E'[`r',5] "   " %9.0g `E'[`r',6]
    }
    di as txt "{hline 13}{c BT}{hline 64}"

    capture confirm matrix e(diag)
    if _rc exit
    tempname G
    matrix `G' = e(diag)
    di
    di as txt "Diagnostics (H0 in brackets)"
    local q 0
    foreach eq in `e(depvar)' `e(mediators)' {
        local ++q
        local c0 = 4*(`q' - 1)
        di as txt "{hline 79}"
        di as txt "Equation: " as res "`eq'" _col(46) as txt "Statistic        df      p-value"
        di as txt "{hline 79}"
        _cp_drow `G' 1  `c0' "Koenker-Breusch-Pagan  [homoskedastic]" chi2
        _cp_drow `G' 2  `c0' "White                  [homoskedastic]" chi2
        _cp_drow `G' 3  `c0' "Jarque-Bera            [normality]" chi2
        _cp_drow `G' 4  `c0' "RESET, design-based    [functional form]" chi2
        _cp_drow `G' 5  `c0' "max VIF                [< 10]" none
        _cp_drow `G' 6  `c0' "First-stage F, endog. 1 [weak IV; F > 10]" F
        _cp_drow `G' 7  `c0' "First-stage F, endog. 2 [weak IV; F > 10]" F
        _cp_drow `G' 8  `c0' "First-stage F, endog. 3 [weak IV; F > 10]" F
        _cp_drow `G' 9  `c0' "First-stage F, endog. 4 [weak IV; F > 10]" F
        _cp_drow `G' 10 `c0' "Hansen J               [valid instruments]" chi2
        _cp_drow `G' 11 `c0' "Endogeneity (control fn.) [exogenous]" chi2
        _cp_drow `G' 12 `c0' "McFadden pseudo R2" none
        _cp_drow `G' 13 `c0' "Hosmer-Lemeshow (10 groups) [good fit]" chi2
        _cp_drow `G' 14 `c0' "Link test, z on xb^2   [correct link]" z
    }
    di as txt "{hline 79}"
end

program define _cp_drow
    args G r c0 lab type
    local s  = `G'[`r', `c0' + 1]
    local d1 = `G'[`r', `c0' + 2]
    local d2 = `G'[`r', `c0' + 3]
    local p  = `G'[`r', `c0' + 4]
    if missing(`s') exit
    if "`type'" == "none" {
        di as txt "  `lab'" _col(46) as res %9.3f `s'
        exit
    }
    local dtxt ""
    if "`type'" == "F" local dtxt = string(`d1') + "," + string(`d2')
    if "`type'" == "chi2" local dtxt = string(`d1')
    di as txt "  `lab'" _col(46) as res %9.3f `s' as txt %12s "`dtxt'" "   " as res %8.4f `p'
end

version 14.0
mata:

real matrix _cp_cdf(real scalar link, real matrix z)
{
    if (link == 1) return(1 :/ (1 :+ exp(-z)))
    return(normal(z))
}

void _cp_wls(real colvector y, real matrix X, real colvector w, real matrix b,
    real matrix IF, real matrix e)
{
    real matrix A
    A = invsym(cross(X, w, X))
    b = A * cross(X, w, y)
    e = y - X * b
    IF = (X :* (w :* e)) * A
}

void _cp_glm(real colvector y, real matrix X, real colvector w, real scalar link,
    real matrix b, real matrix IF, real matrix p)
{
    real matrix H, s
    real colvector xb, f, Wt, step
    real scalar it
    b = J(cols(X), 1, 0)
    for (it = 1; it <= 100; it++) {
        xb = X * b
        if (link == 1) {
            p = 1 :/ (1 :+ exp(-xb))
            s = (y - p) :* X
            Wt = p :* (1 :- p)
        }
        else {
            p = normal(xb)
            p = p :* (p :> 1e-12) + 1e-12 :* (p :<= 1e-12)
            p = p :* (p :< 1 - 1e-12) + (1 - 1e-12) :* (p :>= 1 - 1e-12)
            f = normalden(xb)
            s = (f :* (y - p) :/ (p :* (1 :- p))) :* X
            Wt = f:^2 :/ (p :* (1 :- p))
        }
        H = cross(X, w :* Wt, X)
        step = lusolve(H, colsum(w :* s)')
        b = b + step
        if (max(abs(step)) < 1e-10) break
    }
    xb = X * b
    if (link == 1) {
        p = 1 :/ (1 :+ exp(-xb))
        s = (y - p) :* X
        Wt = p :* (1 :- p)
    }
    else {
        p = normal(xb)
        p = p :* (p :> 1e-12) + 1e-12 :* (p :<= 1e-12)
        p = p :* (p :< 1 - 1e-12) + (1 - 1e-12) :* (p :>= 1 - 1e-12)
        f = normalden(xb)
        s = (f :* (y - p) :/ (p :* (1 :- p))) :* X
        Wt = f:^2 :/ (p :* (1 :- p))
    }
    H = cross(X, w :* Wt, X)
    IF = (w :* s) * luinv(H)
}

void _cp_tsls(real colvector y, real matrix X, real matrix Z, real colvector w,
    real matrix b, real matrix IF, real matrix e)
{
    real matrix Xh, A
    Xh = Z * (invsym(cross(Z, w, Z)) * cross(Z, w, X))
    A = invsym(cross(Xh, w, X))
    b = A * cross(Xh, w, y)
    e = y - X * b
    IF = (Xh :* (w :* e)) * A
}

// Taylor-linearised variance; data sorted by group (stratum x PSU)
real matrix _cp_svy(real matrix IF0, real colvector gg, real colvector gs)
{
    real matrix IF, info, Zg, Zh, V
    real colvector sg, s
    real scalar h, nh
    IF = editmissing(IF0, 0)
    info = panelsetup(gg, 1)
    Zg = panelsum(IF, info)
    sg = gs[info[., 1]]
    V = J(cols(IF), cols(IF), 0)
    for (h = 1; h <= max(sg); h++) {
        s = selectindex(sg :== h)
        nh = rows(s)
        if (nh < 2) continue
        Zh = Zg[s, .]
        Zh = Zh :- mean(Zh)
        V = V + nh / (nh - 1) * cross(Zh, Zh)
    }
    return(V)
}

real matrix _cp_indep(real matrix W)
{
    real matrix Wc
    if (cols(W) == 0) return(W)
    Wc = W :- mean(W)
    return(W[., selectindex(diagonal(invsym(cross(Wc, Wc))) :!= 0)])
}

real matrix _cp_nonconst(real matrix Z)
{
    return(Z[., selectindex(diagonal(variance(Z)) :> 0)])
}

real matrix _cp_poly(real matrix X, real scalar deg)
{
    real matrix Z, P, Pc
    real scalar p, i, j, k
    p = cols(X)
    mu = mean(X)
    sd = sqrt(diagonal(variance(X)))'
    sd = sd + (sd :== 0)
    Z = (X :- mu) :/ sd
    P = Z
    if (deg >= 2) {
        for (i = 1; i <= p; i++) {
            for (j = i; j <= p; j++) P = (P, Z[., i] :* Z[., j])
        }
    }
    if (deg >= 3) {
        for (i = 1; i <= p; i++) {
            for (j = i; j <= p; j++) {
                for (k = j; k <= p; k++) P = (P, Z[., i] :* Z[., j] :* Z[., k])
            }
        }
    }
    Pc = P :- mean(P)
    return(P[., selectindex(diagonal(invsym(cross(Pc, Pc))) :!= 0)])
}

void _cp_gh(real scalar n, real rowvector nodes, real rowvector wts)
{
    real matrix Jm, Vec
    real rowvector L
    real scalar i
    Jm = J(n, n, 0)
    for (i = 1; i < n; i++) {
        Jm[i, i + 1] = sqrt(i)
        Jm[i + 1, i] = sqrt(i)
    }
    symeigensystem(Jm, Vec, L)
    nodes = L
    wts = Vec[1, .]:^2
    wts = wts / sum(wts)
}

// ---------------------------------------------------------------- estimation
// layout L: (est, km, kx, inter, ko, kmed, nsig) ; mlink rowvector (0 lin, 1 logit, 2 probit)
void _cp_est(real scalar est, real colvector Y, real colvector D, real matrix M,
    real matrix X, real matrix Zi, real matrix Zm, real matrix Lv, real scalar lewd,
    real scalar lewm, real colvector w, real colvector gg,
    real scalar inter, real rowvector mlink, real scalar deg, real scalar K,
    real scalar lam, real matrix beta, real matrix IFb, real matrix RES, real matrix YS,
    real matrix ZS, real matrix zoff, real matrix KIND, real matrix ZIS, real matrix zioff,
    real matrix NEX, real matrix END, real colvector cats)
{
    real scalar n, km, kx, j, k, W, s2, nzi, kk
    real matrix Xo, Xm, P, Pc, PP, Mt, Zf, b, IF, e, p, Mj
    real colvector fold, Dt, Yt, tr, te, bb, ug, perm, fg, yc
    n = rows(Y); km = cols(M); kx = cols(X)
    endD = 0; instD = J(n, 0, .)
    beta = J(0, 1, .); IFb = J(n, 0, .); RES = J(n, 0, .); YS = J(n, 0, .)
    ZS = J(n, 0, .); zoff = 0; KIND = J(1, 0, .); ZIS = J(n, 0, .); zioff = 0
    NEX = J(km + 1, max((cols(Zi), cols(Lv) * lewd, 1)) + max((cols(Zm), cols(Lv) * km * lewm, km)) + 1, .)
    END = J(km + 1, 1 + km, .)
    if (est == 5) {
        P = _cp_poly(X, deg)
        Pc = (J(n, 1, 1), P)
        ug = uniqrows(gg)
        perm = order(runiform(rows(ug), 1), 1)
        fg = J(rows(ug), 1, .)
        fg[perm] = mod((1::rows(ug)) :- 1, K)
        fold = J(n, 1, .)
        for (j = 1; j <= rows(ug); j++) fold[selectindex(gg :== ug[j])] = J(sum(gg :== ug[j]), 1, fg[j])
        Dt = _cp_dmlres(D, Pc, w, fold, K, lam)
        Yt = _cp_dmlres(Y, Pc, w, fold, K, lam)
        Mt = J(n, 0, .)
        for (j = 1; j <= km; j++) Mt = (Mt, _cp_dmlres(M[., j], Pc, w, fold, K, lam))
        Xo = (Dt, Mt)
        _cp_wls(Yt, Xo, w, b, IF, e)
        beta = beta \ b; IFb = (IFb, IF); RES = (RES, e); YS = (YS, Yt)
        ZS = (ZS, Xo); zoff = (zoff, cols(ZS)); KIND = (KIND, 0)
        ZIS = (ZIS, J(n, 0, .)); zioff = (zioff, cols(ZIS))
        for (j = 1; j <= km; j++) {
            _cp_wls(Mt[., j], Dt, w, b, IF, e)
            beta = beta \ b; IFb = (IFb, IF); RES = (RES, e); YS = (YS, Mt[., j])
            ZS = (ZS, Dt); zoff = (zoff, cols(ZS)); KIND = (KIND, 0)
            zioff = (zioff, cols(ZIS))
        }
        return
    }
    Xo = (J(n, 1, 1), D, M)
    if (inter) Xo = (Xo, D :* M)
    Xo = (Xo, X)
    if (est == 2 | est == 3) {
        _cp_glm(Y, Xo, w, est - 1, b, IF, p)
        e = Y - p
        KIND = (KIND, est - 1)
        ZIS = (ZIS, J(n, 0, .)); zioff = (zioff, cols(ZIS))
    }
    else if (est >= 6) {
        yc = J(n, 1, 0)
        for (k = 1; k <= rows(cats); k++) yc = yc + k * (Y :== cats[k])
        _cp_mfit(est, yc, Xo[., 2..cols(Xo)], w, rows(cats), b, IF)
        e = J(n, 1, 0)
        KIND = (KIND, est)
        ZIS = (ZIS, J(n, 0, .)); zioff = (zioff, cols(ZIS))
    }
    else if (est == 4) {
        endD = (cols(Zi) > 0) | lewd
        endM = (cols(Zm) > 0) | lewm
        if (cols(Zi)) instD = Zi
        else if (lewd) instD = _cp_lewbel(D, X, Lv, w)
        else instD = D
        if (cols(Zm)) instM = Zm
        else if (lewm) {
            instM = J(n, 0, .)
            for (j = 1; j <= km; j++) instM = (instM, _cp_lewbel(M[., j], X, Lv, w))
        }
        else instM = M
        Zf = (J(n, 1, 1), X, instD, instM)
        nzi = cols(instD)
        kk = 0
        if (endD) {
            for (k = 1; k <= nzi; k++) NEX[1, ++kk] = 1 + kx + k
            END[1, 1] = 2
        }
        if (endM) {
            for (k = 1; k <= cols(instM); k++) NEX[1, ++kk] = 1 + kx + nzi + k
            for (j = 1; j <= km; j++) END[1, endD + j] = 2 + j
        }
        _cp_tsls(Y, Xo, Zf, w, b, IF, e)
        KIND = (KIND, 3)
        ZIS = (ZIS, Zf); zioff = (zioff, cols(ZIS))
    }
    else {
        _cp_wls(Y, Xo, w, b, IF, e)
        KIND = (KIND, 0)
        ZIS = (ZIS, J(n, 0, .)); zioff = (zioff, cols(ZIS))
    }
    beta = beta \ b; IFb = (IFb, IF); RES = (RES, e); YS = (YS, Y)
    ZS = (ZS, Xo); zoff = (zoff, cols(ZS))
    Xm = (J(n, 1, 1), D, X)
    for (j = 1; j <= km; j++) {
        if (mlink[j] > 0) {
            _cp_glm(M[., j], Xm, w, mlink[j], b, IF, p)
            e = M[., j] - p
            KIND = (KIND, mlink[j])
            zioff = (zioff, cols(ZIS))
        }
        else if (est == 4 & endD) {
            Zf = (J(n, 1, 1), X, instD)
            _cp_tsls(M[., j], Xm, Zf, w, b, IF, e)
            for (k = 1; k <= cols(instD); k++) NEX[1 + j, k] = 1 + kx + k
            END[1 + j, 1] = 2
            KIND = (KIND, 3)
            ZIS = (ZIS, Zf); zioff = (zioff, cols(ZIS))
        }
        else {
            _cp_wls(M[., j], Xm, w, b, IF, e)
            KIND = (KIND, 0)
            zioff = (zioff, cols(ZIS))
        }
        beta = beta \ b; IFb = (IFb, IF); RES = (RES, e); YS = (YS, M[., j])
        ZS = (ZS, Xm); zoff = (zoff, cols(ZS))
    }
    if (est == 2 | est == 3 | est >= 6) {
        W = sum(w)
        for (j = 1; j <= km; j++) {
            if (mlink[j] == 0) {
                e = RES[., 1 + j]
                s2 = sum(w :* e:^2) / W
                beta = beta \ s2
                IFb = (IFb, w :* (e:^2 :- s2) / W)
            }
        }
    }
}

real matrix _cp_lewbel(real colvector v, real matrix X, real matrix Lv, real colvector w)
{
    real matrix exo, b, IF, e
    real rowvector Lm
    exo = (J(rows(v), 1, 1), X)
    _cp_wls(v, exo, w, b, IF, e)
    Lm = colsum(w :* Lv) / sum(w)
    return((Lv :- Lm) :* e)
}

real colvector _cp_dmlres(real colvector a, real matrix Pc, real colvector w,
    real colvector fold, real scalar K, real scalar lam)
{
    real colvector out, tr, te, b
    real matrix PP
    real scalar k
    out = J(rows(a), 1, .)
    for (k = 0; k < K; k++) {
        tr = selectindex(fold :!= k)
        te = selectindex(fold :== k)
        if (rows(te) == 0) continue
        PP = cross(Pc[tr, .], w[tr], Pc[tr, .])
        if (lam > 0) PP = PP + lam * rows(tr) * diag((0, J(1, cols(Pc) - 1, 1)))
        b = invsym(PP) * cross(Pc[tr, .], w[tr], a[tr])
        out[te] = a[te] - Pc[te, .] * b
    }
    return(out)
}

// ---------------------------------------------------------------- ordered and multinomial outcomes
// est: 6 ordered logit, 7 ordered probit, 8 multinomial logit, 9 multinomial probit
// R holds the outcome regressors without a constant: (D, M, [D x M], X)
real matrix _cp_ordp(real scalar est, real colvector lin, real colvector kap)
{
    real matrix C
    real scalar k, nc
    nc = rows(kap) + 1
    C = J(rows(lin), nc + 1, 0)
    C[., nc + 1] = J(rows(lin), 1, 1)
    for (k = 1; k < nc; k++) C[., k + 1] = _cp_cdf(est - 5, kap[k] :- lin)
    return(C[., 2..(nc + 1)] - C[., 1..nc])
}

// multinomial probit with independent standard normal latent errors (as in -mprobit-):
// Pr(k) = E_z[ prod_{j != k} Phi(z + eta_k - eta_j) ], Gauss-Hermite with 15 nodes
real matrix _cp_mnp(real scalar est, real matrix ETA)
{
    real matrix E, P
    real rowvector nd, wt
    real colvector pk, pr
    real scalar k, j, q, nc
    nc = cols(ETA)
    if (est == 8) {
        E = exp(ETA :- rowmax(ETA))
        return(E :/ rowsum(E))
    }
    _cp_gh(15, nd, wt)
    P = J(rows(ETA), nc, 0)
    for (k = 1; k <= nc; k++) {
        pk = J(rows(ETA), 1, 0)
        for (q = 1; q <= cols(nd); q++) {
            pr = J(rows(ETA), 1, wt[q])
            for (j = 1; j <= nc; j++) {
                if (j != k) pr = pr :* normal(nd[q] :+ (ETA[., k] - ETA[., j]))
            }
            pk = pk + pr
        }
        P[., k] = pk
    }
    return(P)
}

// category probabilities; b = slopes then cut points (ordered), or one block
// (constant, slopes) per non-base category (multinomial; base = lowest category)
real matrix _cp_mprob(real scalar est, real scalar nc, real colvector b, real matrix R)
{
    real matrix ETA
    real scalar ko, k
    ko = cols(R) + 1
    if (est <= 7) return(_cp_ordp(est, R * b[1..(ko - 1)], b[ko..(ko + nc - 2)]))
    ETA = J(rows(R), 1, 0)
    for (k = 2; k <= nc; k++) ETA = (ETA, (J(rows(R), 1, 1), R) * b[((k - 2) * ko + 1)..((k - 1) * ko)])
    return(_cp_mnp(est, ETA))
}

void _cp_mlev(real scalar todo, real rowvector b, real colvector yc, real matrix R,
    real colvector w, real rowvector info, real matrix v, real matrix g, real matrix H)
{
    real matrix P
    real colvector py
    real scalar k
    P = _cp_mprob(info[1], info[2], b', R)
    py = J(rows(yc), 1, 0)
    for (k = 1; k <= info[2]; k++) py = py + P[., k] :* (yc :== k)
    if (info[1] == 9) py = py :* (py :> 1e-300) + 1e-300 :* (py :<= 1e-300)
    v = w :* ln(py)
}

real scalar _cp_mll(real scalar est, real scalar nc, real colvector b, real colvector yc,
    real matrix R, real colvector w)
{
    real matrix v, g, H
    _cp_mlev(0, b', yc, R, w, (est, nc), v, g, H)
    return(sum(v))
}

// maximum likelihood; IF = weighted scores x inverse information
void _cp_mfit(real scalar est, real colvector yc, real matrix R, real colvector w,
    real scalar nc, real matrix b, real matrix IF)
{
    transmorphic S
    real colvector b0, kap
    real matrix H, Sc
    real scalar ko, k, cs, W, rc, nb
    ko = cols(R) + 1
    nb = (est <= 7 ? ko - 2 + nc : (nc - 1) * ko)
    b = J(nb, 1, .)
    IF = J(rows(yc), nb, .)
    W = sum(w)
    for (k = 1; k <= nc; k++) {
        if (sum(w :* (yc :== k)) <= 0) return
    }
    if (est <= 7) {
        kap = J(nc - 1, 1, .)
        cs = 0
        for (k = 1; k < nc; k++) {
            cs = cs + sum(w :* (yc :== k)) / W
            kap[k] = (est == 6 ? logit(cs) : invnormal(cs))
        }
        b0 = J(ko - 1, 1, 0) \ kap
    }
    else b0 = J(nb, 1, 0)
    S = optimize_init()
    optimize_init_evaluator(S, &_cp_mlev())
    optimize_init_evaluatortype(S, "gf0")
    optimize_init_which(S, "max")
    optimize_init_params(S, b0')
    optimize_init_argument(S, 1, yc)
    optimize_init_argument(S, 2, R)
    optimize_init_argument(S, 3, w)
    optimize_init_argument(S, 4, (est, nc))
    optimize_init_tracelevel(S, "none")
    optimize_init_conv_warning(S, "off")
    optimize_init_conv_maxiter(S, 300)
    rc = _optimize(S)
    if (rc != 0) return
    if (optimize_result_converged(S) != 1) return
    b  = optimize_result_params(S)'
    H  = optimize_result_Hessian(S)
    Sc = optimize_result_scores(S)
    IF = Sc * invsym(-H)
}

// counterfactual targets: (E[y], Pr(y = c1), ..., Pr(y = cJ)) for ordered outcomes,
// (Pr(y = c1), ..., Pr(y = cJ)) for multinomial outcomes
real matrix _cp_mu2(real scalar est, real scalar d, real rowvector dm, real colvector beta,
    real scalar km, real scalar kx, real scalar inter, real rowvector mlink, real matrix X,
    real rowvector nodes, real rowvector wts, real colvector cats)
{
    real scalar n, nc, ko, nbo, kmed, sp, pos, j, c, ncell, nt
    real colvector z, pw, cnt
    real matrix PAR, MV, R, P, total
    real rowvector s2
    n = rows(X)
    nc = rows(cats)
    ko = 2 + km * (1 + inter) + kx
    nbo = (est <= 7 ? ko - 2 + nc : (nc - 1) * ko)
    kmed = 2 + kx
    PAR = J(n, km, .)
    s2 = J(1, km, .)
    sp = nbo + km * kmed
    for (j = 1; j <= km; j++) {
        pos = nbo + (j - 1) * kmed
        z = beta[pos + 1] :+ beta[pos + 2] * dm[j] :+ (kx ? X * beta[(pos + 3)..(pos + kmed)] : J(n, 1, 0))
        if (mlink[j] > 0) PAR[., j] = _cp_cdf(mlink[j], z)
        else {
            PAR[., j] = z
            sp++
            s2[j] = beta[sp]
        }
    }
    nt = (est <= 7 ? nc + 1 : nc)
    total = J(n, nt, 0)
    cnt = J(km, 1, 1)
    ncell = 1
    for (j = 1; j <= km; j++) ncell = ncell * (mlink[j] > 0 ? 2 : cols(nodes))
    for (c = 1; c <= ncell; c++) {
        pw = J(n, 1, 1)
        MV = J(n, km, .)
        for (j = 1; j <= km; j++) {
            if (mlink[j] > 0) {
                MV[., j] = J(n, 1, cnt[j] == 2)
                pw = pw :* (cnt[j] == 2 ? PAR[., j] : 1 :- PAR[., j])
            }
            else {
                MV[., j] = PAR[., j] :+ sqrt(s2[j]) * nodes[cnt[j]]
                pw = pw * wts[cnt[j]]
            }
        }
        R = (J(n, 1, d), MV)
        if (inter) R = (R, d :* MV)
        if (kx) R = (R, X)
        P = _cp_mprob(est, nc, beta[1..nbo], R)
        if (est <= 7) total = total + pw :* (P * cats, P)
        else total = total + pw :* P
        for (j = 1; j <= km; j++) {
            cnt[j] = cnt[j] + 1
            if (cnt[j] <= (mlink[j] > 0 ? 2 : cols(nodes))) break
            cnt[j] = 1
        }
    }
    return(total)
}

// ---------------------------------------------------------------- effects
real matrix _cp_mu(real scalar est, real scalar d, real rowvector dm, real colvector beta,
    real scalar km, real scalar kx, real scalar inter, real rowvector mlink, real matrix X,
    real rowvector nodes, real rowvector wts, real colvector cats)
{
    real scalar n, ko, j, pos, nc, c, r, kmed, sp
    real colvector bo, lin, xb, total, pw, z, cnt
    real matrix MEAN, KINDm, PAR, Mv, bm, s2
    if (est >= 6) return(_cp_mu2(est, d, dm, beta, km, kx, inter, mlink, X, nodes, wts, cats))
    n = rows(X)
    if (est == 5) {
        bo = beta[1..(1 + km)]
        lin = J(n, 1, bo[1] * d)
        for (j = 1; j <= km; j++) lin = lin :+ bo[1 + j] * (beta[1 + km + j] * dm[j])
        return(lin)
    }
    ko = 2 + km * (1 + inter) + kx
    bo = beta[1..ko]
    kmed = 2 + kx
    xb = (kx ? X * bo[(ko - kx + 1)..ko] : J(n, 1, 0))
    PAR = J(n, km, .)
    s2 = J(1, km, .)
    sp = ko + km * kmed
    for (j = 1; j <= km; j++) {
        pos = ko + (j - 1) * kmed
        z = beta[pos + 1] :+ beta[pos + 2] * dm[j] :+ (kx ? X * beta[(pos + 3)..(pos + kmed)] : 0)
        if (mlink[j] > 0) PAR[., j] = _cp_cdf(mlink[j], z)
        else PAR[., j] = z
        if (mlink[j] == 0 & (est == 2 | est == 3)) {
            sp++
            s2[j] = beta[sp]
        }
    }
    if (est != 2 & est != 3) {
        lin = bo[1] :+ bo[2] * d :+ xb
        for (j = 1; j <= km; j++) {
            lin = lin + bo[2 + j] * PAR[., j]
            if (inter) lin = lin + bo[2 + km + j] * d * PAR[., j]
        }
        return(lin)
    }
    // nonlinear outcome: product grid over mediator distributions
    cnt = J(km, 1, 1)
    nc = 1
    for (j = 1; j <= km; j++) nc = nc * (mlink[j] > 0 ? 2 : cols(nodes))
    total = J(n, 1, 0)
    for (c = 1; c <= nc; c++) {
        lin = bo[1] :+ bo[2] * d :+ xb
        pw = J(n, 1, 1)
        for (j = 1; j <= km; j++) {
            if (mlink[j] > 0) {
                Mv = (cnt[j] == 2 ? J(n, 1, 1) : J(n, 1, 0))
                pw = pw :* (cnt[j] == 2 ? PAR[., j] : 1 :- PAR[., j])
            }
            else {
                Mv = PAR[., j] :+ sqrt(s2[j]) * nodes[cnt[j]]
                pw = pw * wts[cnt[j]]
            }
            lin = lin + bo[2 + j] * Mv
            if (inter) lin = lin + bo[2 + km + j] * d * Mv
        }
        total = total + pw :* _cp_cdf(est - 1, lin)
        // advance mixed-radix counter
        for (j = 1; j <= km; j++) {
            cnt[j] = cnt[j] + 1
            if (cnt[j] <= (mlink[j] > 0 ? 2 : cols(nodes))) break
            cnt[j] = 1
        }
    }
    return(total)
}

real matrix _cp_g(real scalar est, real colvector beta, real scalar km, real scalar kx,
    real scalar inter, real rowvector mlink, real matrix X, real rowvector nodes,
    real rowvector wts, real scalar d1, real scalar d0, real colvector cats)
{
    real matrix a11, a10, a00, AJ, G
    real rowvector dm
    real scalar j, t, nt
    a11 = _cp_mu(est, d1, J(1, km, d1), beta, km, kx, inter, mlink, X, nodes, wts, cats)
    a10 = _cp_mu(est, d1, J(1, km, d0), beta, km, kx, inter, mlink, X, nodes, wts, cats)
    a00 = _cp_mu(est, d0, J(1, km, d0), beta, km, kx, inter, mlink, X, nodes, wts, cats)
    nt = cols(a11)
    AJ = J(rows(a11), 0, .)
    if (km > 1) {
        for (j = 1; j <= km; j++) {
            dm = J(1, km, d0)
            dm[j] = d1
            AJ = (AJ, _cp_mu(est, d1, dm, beta, km, kx, inter, mlink, X, nodes, wts, cats) - a10)
        }
    }
    // per target: NDE, NIE, TE, then NIE via each mediator
    G = J(rows(a11), 0, .)
    for (t = 1; t <= nt; t++) {
        G = (G, a10[., t] - a00[., t], a11[., t] - a10[., t], a11[., t] - a00[., t])
        if (km > 1) {
            for (j = 1; j <= km; j++) G = (G, AJ[., (j - 1) * nt + t])
        }
    }
    return(G)
}

void _cp_effects(real scalar est, real colvector beta, real matrix IFb, real scalar km,
    real scalar kx, real scalar inter, real rowvector mlink, real matrix X, real colvector w,
    real rowvector nodes, real rowvector wts, real scalar d1, real scalar d0,
    real colvector cats, real matrix eff, real matrix IFe)
{
    real matrix G, Jm, IFa
    real rowvector th, gp, gm
    real colvector bp, bm
    real scalar W, j, h, pm, nb, nt, t, o
    W = sum(w)
    G = _cp_g(est, beta, km, kx, inter, mlink, X, nodes, wts, d1, d0, cats)
    th = colsum(w :* G) / W
    // point estimates only (bootstrap replications): no Jacobian needed
    if (rows(IFb) == 0) {
        nb = 3 + (km > 1) * km
        nt = cols(G) / nb
        eff = J(1, 0, .)
        for (t = 1; t <= nt; t++) {
            o = (t - 1) * nb
            eff = (eff, th[o + 1], th[o + 2], th[o + 3], th[o + 2] / th[o + 3])
            if (nb > 3) eff = (eff, th[(o + 4)..(o + nb)])
        }
        IFe = J(0, cols(eff), .)
        return
    }
    Jm = J(cols(G), rows(beta), 0)
    for (j = 1; j <= rows(beta); j++) {
        h = 1e-6 * max((1, abs(beta[j])))
        bp = beta; bp[j] = bp[j] + h
        bm = beta; bm[j] = bm[j] - h
        gp = colsum(w :* _cp_g(est, bp, km, kx, inter, mlink, X, nodes, wts, d1, d0, cats)) / W
        gm = colsum(w :* _cp_g(est, bm, km, kx, inter, mlink, X, nodes, wts, d1, d0, cats)) / W
        Jm[., j] = ((gp - gm) / (2 * h))'
    }
    IFa = (w :* (G :- th)) / W + IFb * Jm'
    nb = 3 + (km > 1) * km
    nt = cols(G) / nb
    eff = J(1, 0, .)
    IFe = J(rows(G), 0, .)
    for (t = 1; t <= nt; t++) {
        o = (t - 1) * nb
        pm = th[o + 2] / th[o + 3]
        eff = (eff, th[o + 1], th[o + 2], th[o + 3], pm)
        IFe = (IFe, IFa[., o + 1], IFa[., o + 2], IFa[., o + 3], (IFa[., o + 2] - pm * IFa[., o + 3]) / th[o + 3])
        if (nb > 3) {
            eff = (eff, th[(o + 4)..(o + nb)])
            IFe = (IFe, IFa[., (o + 4)..(o + nb)])
        }
    }
}

// ---------------------------------------------------------------- diagnostics
real scalar _cp_nr2(real colvector y, real matrix W)
{
    real matrix W1
    real colvector b, u
    W1 = (J(rows(y), 1, 1), W)
    b = invsym(cross(W1, W1)) * cross(W1, y)
    u = y - W1 * b
    return(rows(y) * (1 - cross(u, u) / sum((y :- mean(y)):^2)))
}

real matrix _cp_diag(real scalar kind, real colvector y, real matrix Z, real colvector r,
    real colvector bq, real matrix Zi, real rowvector nex, real rowvector endg,
    real colvector w, real colvector gg, real colvector gs, real scalar est,
    real scalar ivendog)
{
    real matrix DG, Zn, Wf, Zu, IF, Vb, C, g, Vg, Za, V1, ZZ
    real colvector f, fs, b, e, p, ord, xb, xk, d, gsum
    real scalar LM, i, j, Sk, Ku, JB, Wd, n, k, q, ll, ll0, p0, HL, a, z, se, dfJ, kk, nx, rr
    DG = J(14, 4, .)
    n = rows(y)
    Zn = _cp_nonconst(Z)
    if (kind == 0 | kind == 3) {
        LM = _cp_nr2(r:^2, Zn)
        DG[1, .] = (LM, cols(Zn), ., chi2tail(cols(Zn), LM))
        Wf = Zn
        for (i = 1; i <= cols(Zn); i++) {
            for (j = i; j <= cols(Zn); j++) Wf = (Wf, Zn[., i] :* Zn[., j])
        }
        Wf = _cp_indep(Wf)
        LM = _cp_nr2(r:^2, Wf)
        DG[2, .] = (LM, cols(Wf), ., chi2tail(cols(Wf), LM))
        d = r :- mean(r)
        Sk = mean(d:^3) / mean(d:^2)^1.5
        Ku = mean(d:^4) / mean(d:^2)^2
        JB = n * (Sk^2 / 6 + (Ku - 3)^2 / 24)
        DG[3, .] = (JB, 2, ., chi2tail(2, JB))
        if (kind == 0 & est != 5) {
            f = y - r
            fs = (f :- mean(f)) / sqrt(mean((f :- mean(f)):^2))
            Zu = (Z, fs:^2, fs:^3)
            _cp_wls(y, Zu, w, b, IF, e)
            Vb = _cp_svy(IF, gg, gs)
            k = cols(Zu)
            Wd = b[(k - 1)..k]' * invsym(Vb[(k - 1)..k, (k - 1)..k]) * b[(k - 1)..k]
            DG[4, .] = (Wd, 2, ., chi2tail(2, Wd))
            if (cols(Zn) > 1) {
                C = correlation(Zn)
                DG[5, 1] = max(diagonal(invsym(C)))
            }
        }
    }
    if (kind == 3) {
        kk = 0
        for (q = 1; q <= cols(endg); q++) {
            if (endg[q] == .) continue
            kk++
            if (kk > 4) break
            xk = Z[., endg[q]]
            _cp_wls(xk, Zi, w, b, IF, e)
            Vb = _cp_svy(IF, gg, gs)
            nx = sum(nex :< .)
            Wd = b[nex[1..nx]]' * invsym(Vb[nex[1..nx], nex[1..nx]]) * b[nex[1..nx]] / nx
            DG[5 + kk, .] = (Wd, nx, n - cols(Zi), Ftail(nx, n - cols(Zi), Wd))
        }
        g = Zi :* (w :* r)
        Vg = _cp_svy(g, gg, gs)
        gsum = colsum(g)'
        dfJ = cols(Zi) - cols(Z)
        if (dfJ > 0) {
            Wd = gsum' * invsym(Vg) * gsum
            DG[10, .] = (Wd, dfJ, ., chi2tail(dfJ, Wd))
        }
        V1 = J(n, 0, .)
        for (q = 1; q <= cols(endg); q++) {
            if (endg[q] == .) continue
            xk = Z[., endg[q]]
            ZZ = invsym(cross(Zi, w, Zi)) * cross(Zi, w, xk)
            V1 = (V1, xk - Zi * ZZ)
        }
        Za = (Z, V1)
        _cp_wls(y, Za, w, b, IF, e)
        Vb = _cp_svy(IF, gg, gs)
        k = cols(Za); kk = cols(V1)
        Wd = b[(k - kk + 1)..k]' * invsym(Vb[(k - kk + 1)..k, (k - kk + 1)..k]) * b[(k - kk + 1)..k]
        DG[11, .] = (Wd, kk, ., chi2tail(kk, Wd))
    }
    if (kind == 1 | kind == 2) {
        p = y - r
        ll = sum(w :* (y :* ln(p) + (1 :- y) :* ln(1 :- p)))
        p0 = sum(w :* y) / sum(w)
        ll0 = sum(w :* (y :* ln(p0) + (1 :- y) :* ln(1 - p0)))
        DG[12, 1] = 1 - ll / ll0
        ord = order(p, 1)
        HL = 0
        a = 0
        for (q = 1; q <= 10; q++) {
            rr = floor(n / 10) + (q <= mod(n, 10))
            d = ord[(a + 1)..(a + rr)]
            a = a + rr
            HL = HL + (sum(y[d]) - sum(p[d]))^2 / (sum(p[d]) * (1 - mean(p[d])))
        }
        DG[13, .] = (HL, 8, ., chi2tail(8, HL))
        xb = Z * bq
        _cp_glm(y, (J(n, 1, 1), xb, xb:^2), w, kind, b, IF, p)
        Vlk = _cp_svy(IF, gg, gs)
        se = sqrt(Vlk[3, 3])
        z = b[3] / se
        DG[14, .] = (z, ., ., 2 * normal(-abs(z)))
    }
    return(DG)
}

// ---------------------------------------------------------------- main
void _cp_main(string scalar yv, string scalar dv, string scalar mv, string scalar cv,
    string scalar ziv, string scalar zmv, string scalar lvv, real scalar lewd,
    real scalar lewm, string scalar wv, string scalar ggv,
    string scalar gsv, string scalar touse, real scalar est, real scalar inter,
    real scalar deg, real scalar K, real scalar lam, real scalar ngh, real scalar d1,
    real scalar d0, real scalar B, real scalar dots, real scalar level, real scalar dodiag)
{
    real colvector Y, D, w, gg, gs, se, z, p, lo, hi, s, idx, ug, ugs, pick, bq
    real matrix M, X, Zi, Zm, Lv, beta, IFb, RES, YS, ZS, zoff, KIND, ZIS, zioff, NEX, END
    real matrix V, eff, IFe, Ve, EB, DG, b2, I2, R2, Y2, Z2, zo2, K2, ZI2, zi2, N2, E2, ef2, IF2, Ro
    real rowvector mlink, nodes, wts
    real colvector cats, yc
    real scalar km, kx, j, n, q, b, h, a, nok, i, nfail, cvz, isbin, nq, nbo, ko, llm, ll0, Wk, k
    Y = st_data(., yv, touse); D = st_data(., dv, touse)
    M = st_data(., tokens(mv), touse)
    X = (strtrim(cv) != "" ? st_data(., tokens(cv), touse) : J(rows(Y), 0, .))
    Zi = (strtrim(ziv) != "" ? st_data(., tokens(ziv), touse) : J(rows(Y), 0, .))
    Zm = (strtrim(zmv) != "" ? st_data(., tokens(zmv), touse) : J(rows(Y), 0, .))
    Lv = (strtrim(lvv) != "" ? st_data(., tokens(lvv), touse) : J(rows(Y), 0, .))
    w = st_data(., wv, touse); gg = st_data(., ggv, touse); gs = st_data(., gsv, touse)
    n = rows(Y); km = cols(M); kx = cols(X)
    mlink = J(1, km, 0)
    if (est == 2 | est == 3 | est >= 6) {
        for (j = 1; j <= km; j++) {
            isbin = (rows(uniqrows(M[., j])) <= 2) & all((M[., j] :== 0) :| (M[., j] :== 1))
            if (isbin) mlink[j] = ((est == 2 | est == 6 | est == 8) ? 1 : 2)
        }
    }
    st_matrix("__cp_mlinkm", mlink)
    cats = (est >= 6 ? uniqrows(Y) : J(0, 1, .))
    if (est >= 6) st_matrix("__cp_cats", cats')
    _cp_gh(ngh, nodes, wts)
    _cp_est(est, Y, D, M, X, Zi, Zm, Lv, lewd, lewm, w, gg, inter, mlink, deg, K, lam, beta, IFb, RES,
        YS, ZS, zoff, KIND, ZIS, zioff, NEX, END, cats)
    if (hasmissing(beta)) {
        errprintf("estimation failed (singular design)\n")
        exit(error(430))
    }
    V = _cp_svy(IFb, gg, gs)
    _cp_effects(est, beta, IFb, km, kx, inter, mlink, X, w, nodes, wts, d1, d0, cats, eff, IFe)
    Ve = _cp_svy(IFe, gg, gs)
    se = sqrt(diagonal(Ve))
    cvz = invnormal(1 - (1 - level / 100) / 2)
    lo = eff' - cvz * se; hi = eff' + cvz * se
    nfail = 0
    if (B > 0) {
        EB = J(B, cols(eff), .)
        ug = uniqrows((gs, gg))
        if (dots) printf("{txt}PSU bootstrap replications ({res}%g{txt})\n", B)
        for (b = 1; b <= B; b++) {
            idx = J(0, 1, .)
            for (h = 1; h <= max(gs); h++) {
                ugs = select(ug[., 2], ug[., 1] :== h)
                pick = ugs[ceil(rows(ugs) * runiform(rows(ugs), 1))]
                for (i = 1; i <= rows(pick); i++) idx = idx \ selectindex(gg :== pick[i])
            }
            Xb  = (cols(X)  ? X[idx, .]  : J(rows(idx), 0, .))
            Zib = (cols(Zi) ? Zi[idx, .] : J(rows(idx), 0, .))
            Zmb = (cols(Zm) ? Zm[idx, .] : J(rows(idx), 0, .))
            Lvb = (cols(Lv) ? Lv[idx, .] : J(rows(idx), 0, .))
            _cp_est(est, Y[idx], D[idx], M[idx, .], Xb, Zib, Zmb, Lvb, lewd, lewm, w[idx],
                gg[idx], inter, mlink, deg, K, lam, b2, I2, R2, Y2, Z2, zo2, K2, ZI2, zi2, N2, E2, cats)
            if (hasmissing(b2)) {
                nfail++
                if (dots) printf("{err}x{txt}")
            }
            else {
                _cp_effects(est, b2, J(0, 0, .), km, kx, inter, mlink, Xb, w[idx], nodes, wts, d1, d0, cats, ef2, IF2)
                EB[b, .] = ef2
                if (dots) printf(".")
            }
            if (dots & mod(b, 50) == 0) printf(" %g\n", b)
            displayflush()
        }
        if (dots) printf("\n")
        a = (1 - level / 100) / 2
        for (i = 1; i <= cols(eff); i++) {
            s = select(EB[., i], EB[., i] :< .)
            nok = rows(s)
            if (nok > 1) {
                se[i] = sqrt(variance(s))
                s = sort(s, 1)
                lo[i] = s[max((1, floor(a * nok)))]
                hi[i] = s[min((nok, ceil((1 - a) * nok)))]
            }
        }
        Ve = variance(select(EB, rowmissing(EB) :== 0))
        st_matrix("__cp_bboot", EB)
    }
    z = eff' :/ se
    p = 2 * normal(-abs(z))
    ko = 2 + km * (1 + inter) + kx
    nbo = (est >= 6 ? (est <= 7 ? ko - 2 + rows(cats) : (rows(cats) - 1) * ko) : .)
    if (est >= 6) {
        yc = J(n, 1, 0)
        for (k = 1; k <= rows(cats); k++) yc = yc + k * (Y :== cats[k])
        Ro = (D, M)
        if (inter) Ro = (Ro, D :* M)
        Ro = (Ro, X)
        llm = _cp_mll(est, rows(cats), beta[1..nbo], yc, Ro, w)
        ll0 = 0
        for (k = 1; k <= rows(cats); k++) {
            Wk = sum(w :* (yc :== k))
            ll0 = ll0 + Wk * ln(Wk / sum(w))
        }
        st_numscalar("__cp_ll", llm)
        st_numscalar("__cp_ll0", ll0)
    }
    if (dodiag) {
        DG = J(14, 0, .)
        a = 0
        for (q = 1; q <= km + 1; q++) {
            nq = zoff[q + 1] - zoff[q]
            if (q == 1 & est >= 6) nq = nbo
            bq = beta[(a + 1)..(a + nq)]
            a = a + nq
            DG = (DG, _cp_diag(KIND[q], YS[., q], ZS[., (zoff[q] + 1)..zoff[q + 1]], RES[., q], bq,
                (zioff[q + 1] > zioff[q] ? ZIS[., (zioff[q] + 1)..zioff[q + 1]] : J(n, 0, .)),
                NEX[q, .], END[q, .], w, gg, gs, est, 0))
        }
        if (est >= 6) DG[12, 1] = 1 - llm / ll0
        st_matrix("__cp_diag", DG)
    }
    st_matrix("__cp_b", beta')
    st_matrix("__cp_V", V)
    st_matrix("__cp_eff", (eff', se, z, p, lo, hi))
    st_matrix("__cp_veff", Ve)
    st_numscalar("__cp_bfail", nfail)
    st_numscalar("__cp_npsu", rows(uniqrows(gg)))
    st_numscalar("__cp_nstr", rows(uniqrows(gs)))
}

end
