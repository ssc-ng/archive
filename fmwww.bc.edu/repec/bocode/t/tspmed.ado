*! version 1.1.0  11nov2026
*! tspmed: causal mediation analysis for time series (OLS-HAC, ARDL, FMOLS,
*! DOLS, DML) with multiple mediators and residual diagnostics
*! Author: Yusuf Toyin Yusuf, Kwara State University, Malete, Nigeria

program define tspmed, eclass sortpreserve
    version 14.0

    if replay() {
        if ("`e(cmd)'" != "tspmed") error 301
        _tp_display `0'
        exit
    }

    syntax varname(numeric) [if] [in],              ///
        TREATment(varname numeric)                  ///
        MEDiators(varlist numeric)                  ///
        [ CONTrols(varlist numeric)                 ///
          ESTimator(string)                         ///
          TRend                                     ///
          VCE(string)                               ///
          HACLag(integer -1)                        ///
          ARDLlags(numlist integer min=2 max=2 >=0) ///
          MAXP(integer 4) MAXQ(integer 4)           ///
          IC(string)                                ///
          LEADs(integer 1) DLAGs(integer 1)         ///
          POLY(integer 2) FOLDs(integer 5)          ///
          RIDGE(real 0) GAP(integer -1)             ///
          D1(real 1) D0(real 0)                     ///
          BOOTstrap(integer 0) BLOCKlen(integer 0)  ///
          SEED(string) NODOTS NODIAG                ///
          BGLags(integer 4) ARCHLags(integer 2)     ///
          BREAK(string)                             ///
          SIMReps(integer 999) BMethod(string)      ///
          FMBW(real -1) NOPREWhite                  ///
          Level(cilevel) ]

    local depvar `varlist'
    if "`estimator'" == "" local estimator ols
    local estimator = lower("`estimator'")
    local estlist ols ardl fmols dols dml
    if !`: list estimator in estlist' {
        di as err "estimator() must be one of: `estlist'"
        exit 198
    }
    local estcode : list posof "`estimator'" in estlist
    if "`vce'" == "" local vce qs
    local vce = lower("`vce'")
    if !inlist("`vce'", "qs", "hac", "robust") {
        di as err "vce() must be {bf:qs}, {bf:hac} or {bf:robust}"
        exit 198
    }
    if "`ic'" == "" local ic aic
    if !inlist("`ic'", "aic", "bic") {
        di as err "ic() must be aic or bic"
        exit 198
    }
    if `d1' == `d0' {
        di as err "d1() and d0() must differ"
        exit 198
    }
    if `bootstrap' > 0 & `bootstrap' < 50 {
        di as err "bootstrap() should be at least 50 replications"
        exit 198
    }
    if !inrange(`poly', 1, 3) | `folds' < 2 | `maxp' < 1 | `maxq' < 0 | `bglags' < 1 | `archlags' < 1 {
        di as err "invalid poly(), folds(), maxp(), maxq(), bglags() or archlags()"
        exit 198
    }
    local allv `depvar' `treatment' `mediators'
    local dups : list dups allv
    if "`dups'" != "" {
        di as err "depvar, treatment() and mediators() must be distinct"
        exit 198
    }
    local controls : list controls - allv
    if "`bmethod'" == "" local bmethod = cond(inlist("`estimator'", "fmols", "dols"), "sieve", "block")
    local bmethod = lower("`bmethod'")
    if !inlist("`bmethod'", "block", "sieve") {
        di as err "bmethod() must be block or sieve"
        exit 198
    }
    if "`bmethod'" == "sieve" & !inlist("`estimator'", "fmols", "dols") {
        di as err "the sieve bootstrap is for the cointegrating estimators fmols and dols"
        exit 198
    }
    if `simreps' < 99 {
        di as err "simreps() must be at least 99"
        exit 198
    }
    if "`estimator'" == "dml" & "`controls'" == "" {
        di as err "estimator(dml) needs controls() (the confounders to partial out)"
        exit 198
    }
    local km : word count `mediators'
    local kx : word count `controls'
    local fixp = -1
    local fixq = -1
    if "`ardllags'" != "" {
        local fixp : word 1 of `ardllags'
        local fixq : word 2 of `ardllags'
        if `fixp' < 1 {
            di as err "ardllags(p q) needs p >= 1"
            exit 198
        }
    }

    * ---------------- time structure ----------------
    qui tsset
    local tvar "`r(timevar)'"
    if "`r(panelvar)'" != "" {
        di as err "data are xtset with a panel variable; use {bf:xtpmed} for panel data"
        exit 459
    }
    local delta = cond(missing(r(tdelta)), 1, r(tdelta))
    marksample touse
    markout `touse' `treatment' `mediators' `controls'
    qui count if `touse'
    local nobs = r(N)
    if `nobs' < 20 error 2001
    qui summ `tvar' if `touse', meanonly
    local tmin = r(min)
    local T = round((r(max) - r(min))/`delta') + 1
    tempvar tid
    qui gen long `tid' = round((`tvar' - `tmin')/`delta') + 1 if `touse'

    if `haclag' < 0 local haclag = floor(4*(`T'/100)^(2/9))
    local gaplag = `haclag'
    if "`vce'" == "robust" local haclag 0
    if "`vce'" == "qs" local haclag = -1
    if `gap' < 0 local gap = max(`gaplag', 1)
    if `blocklen' <= 0 local blocklen = max(2, round(`T'^(1/3)))
    if "`break'" == "" local brk = floor(`T'/2)
    else {
        capture confirm number `break'
        if _rc {
            di as err "break() must be a value of the time variable"
            exit 198
        }
        local brk = round((`break' - `tmin')/`delta') + 1
        if `brk' < 2 | `brk' >= `T' {
            di as err "break() must lie strictly inside the sample"
            exit 198
        }
    }
    if "`seed'" != "" set seed `seed'

    tempname b V EFF VEFF BBOOT DIAG
    mata: _tp_main("`depvar'", "`treatment'", "`mediators'", "`controls'", "`touse'", ///
        "`tid'", `T', `estcode', ("`trend'"!=""), `haclag', `fixp', `fixq', `maxp',   ///
        `maxq', ("`ic'"=="bic"), `leads', `dlags', `poly', `folds', `ridge', `gap',   ///
        `d1', `d0', `bootstrap', `blocklen', ("`nodots'"==""), `level',              ///
        ("`nodiag'"==""), `bglags', `archlags', `brk', `simreps', ("`bmethod'"=="sieve"), ///
        `fmbw', ("`noprewhite'"==""))

    * ---------------- names ----------------
    local ec = ("`estimator'" == "ardl")
    local xs = cond("`estimator'" == "dml", "", "`controls'")
    local names ""
    foreach v in `treatment' `mediators' `xs' {
        local names `names' `depvar':`v'
    }
    if `ec' local names `names' `depvar':ec
    foreach m of local mediators {
        foreach v in `treatment' `xs' {
            local names `names' `m':`v'
        }
        if `ec' local names `names' `m':ec
    }
    matrix `b' = __tp_b
    matrix `V' = __tp_V
    matrix colnames `b' = `names'
    matrix colnames `V' = `names'
    matrix rownames `V' = `names'
    local enames NDE NIE TE PM
    if `km' > 1 {
        foreach m of local mediators {
            local enames `enames' NIE_`=substr("`m'", 1, 28)'
        }
    }
    matrix `EFF' = __tp_eff
    matrix `VEFF' = __tp_veff
    matrix rownames `EFF' = `enames'
    matrix colnames `EFF' = b se z pvalue ll ul
    matrix colnames `VEFF' = `enames'
    matrix rownames `VEFF' = `enames'
    if "`nodiag'" == "" {
        matrix `DIAG' = __tp_diag
        local dn BG LjungBox DW Koenker White ARCH JB skew kurt RESET CUSUM CUSUMSQ Chow ARDLlags BoundsF_I0 BoundsF_I1 BoundsT_I0 BoundsT_I1 BoundsDecision EGADF
        matrix rownames `DIAG' = `dn'
        local cn ""
        foreach v in `depvar' `mediators' {
            local cn `cn' `v':stat `v':df1 `v':df2 `v':p
        }
        matrix colnames `DIAG' = `cn'
    }
    local nfail = scalar(__tp_bfail)
    if `bootstrap' > 0 {
        matrix `BBOOT' = __tp_bboot
        matrix colnames `BBOOT' = `enames'
    }
    foreach x in b V eff veff bboot diag {
        capture matrix drop __tp_`x'
    }
    capture scalar drop __tp_bfail

    ereturn post `b' `V', esample(`touse') obs(`nobs') depname(`depvar')
    ereturn scalar T        = `T'
    ereturn scalar km       = `km'
    ereturn scalar haclag   = cond(`haclag' < 0, ., `haclag')
    ereturn scalar d1       = `d1'
    ereturn scalar d0       = `d0'
    ereturn scalar level    = `level'
    ereturn scalar bootstrap = `bootstrap'
    ereturn scalar bglags   = `bglags'
    ereturn scalar archlags = `archlags'
    ereturn scalar break_t  = `tmin' + `brk'*`delta'
    ereturn scalar simreps  = `simreps'
    ereturn local bmethod   "`bmethod'"
    if "`estimator'" == "fmols" ereturn scalar fmols_bw = scalar(__tp_fmbw)
    capture scalar drop __tp_fmbw
    if `bootstrap' > 0 {
        ereturn scalar blocklen  = `blocklen'
        ereturn scalar boot_fail = `nfail'
        ereturn matrix eff_boot = `BBOOT'
    }
    if "`nodiag'" == "" ereturn matrix diag = `DIAG'
    ereturn matrix effects = `EFF'
    ereturn matrix V_eff   = `VEFF'
    ereturn local estimator "`estimator'"
    ereturn local vce       = cond("`estimator'"=="fmols", "FMOLS mixed-normal, prewhitened QS kernel", cond("`vce'"=="qs", "prewhitened QS kernel, Andrews bandwidth", cond(`haclag' > 0, "Newey-West HAC", "White robust")))
    ereturn local trend     "`trend'"
    ereturn local controls  "`controls'"
    ereturn local mediators "`mediators'"
    ereturn local treatment "`treatment'"
    ereturn local tvar      "`tvar'"
    ereturn local title     "Time-series causal mediation analysis"
    ereturn local cmdline   `"tspmed `0'"'
    ereturn local cmd       "tspmed"
    _tp_display, level(`level')
end

program define _tp_display
    syntax [, Level(cilevel)]
    local est "`e(estimator)'"
    local lab_ols   "OLS with HAC standard errors"
    local lab_ardl  "ARDL, long-run coefficients"
    local lab_fmols "Fully modified OLS (Phillips-Hansen)"
    local lab_dols  "Dynamic OLS (Stock-Watson)"
    local lab_dml   "DML partialling-out, blocked cross-fitting"
    di
    di as txt "`e(title)'" _col(50) "Number of obs = " as res %8.0fc e(N)
    di as txt "Estimator: " as res "`lab_`est''" _col(50) as txt "Periods (T)   = " as res %8.0fc e(T)
    if "`est'" == "fmols" di as txt "Std. errors: " as res "`e(vce)'" as txt " (Andrews bandwidth " as res %5.2f e(fmols_bw) as txt ")"
    else if e(haclag) > 0 & e(haclag) < . di as txt "Std. errors: " as res "`e(vce)'" as txt " (lag " as res e(haclag) as txt ")"
    else di as txt "Std. errors: " as res "`e(vce)'"
    di as txt "Mediators: " as res "`e(mediators)'"
    if "`est'" == "ardl" di as txt "Coefficients are long-run; " as res "ec" as txt " = speed of adjustment"
    ereturn display, level(`level')

    tempname E
    matrix `E' = e(effects)
    local rn : rownames `E'
    di
    di as txt "Causal mediation effects of moving `e(treatment)' from " as res %9.0g e(d0) as txt " to " as res %9.0g e(d1)
    if e(bootstrap) > 0 & "`e(bmethod)'" == "sieve" di as txt "Inference: sieve (VAR) bootstrap-t, " as res e(bootstrap) as txt " replications; p-values and CIs from the bootstrap"
    else if e(bootstrap) > 0 di as txt "Inference: moving-block bootstrap, " as res e(bootstrap) as txt " replications, block length " as res e(blocklen)
    else di as txt "Inference: delta method on the joint (cross-equation) HAC variance"
    di as txt "{hline 26}{c TT}{hline 64}"
    di as txt %25s "Effect" " {c |}" "      Coef.   Std. Err.      z    P>|z|     [`level'% Conf. Interval]"
    di as txt "{hline 26}{c +}{hline 64}"
    local r 0
    foreach nm of local rn {
        local ++r
        local lab "`nm'"
        if "`nm'" == "NDE" local lab "Natural direct (NDE)"
        if "`nm'" == "NIE" local lab "Natural indirect (NIE)"
        if "`nm'" == "TE"  local lab "Total (TE)"
        if "`nm'" == "PM"  local lab "Proportion mediated"
        if substr("`nm'", 1, 4) == "NIE_" {
            local medn = substr("`nm'", 5, .)
            local lab "  via `medn'"
        }
        di as txt %25s abbrev("`lab'", 25) " {c |}  " as res %9.0g `E'[`r',1] "  " %9.0g `E'[`r',2] ///
            "  " %7.2f `E'[`r',3] "  " %6.3f `E'[`r',4] "    " %9.0g `E'[`r',5] "   " %9.0g `E'[`r',6]
    }
    di as txt "{hline 26}{c BT}{hline 64}"

    capture confirm matrix e(diag)
    if _rc exit
    tempname G
    matrix `G' = e(diag)
    di
    di as txt "Residual diagnostics (H0 in brackets)"
    local q 0
    foreach eq in `e(depvar)' `e(mediators)' {
        local ++q
        local c0 = 4*(`q' - 1)
        di as txt "{hline 79}"
        di as txt "Equation: " as res "`eq'" _col(46) as txt "Statistic        df      p-value"
        di as txt "{hline 79}"
        _tp_drow `G' 1  `c0' "Breusch-Godfrey LM(`e(bglags)') [no serial corr.]" chi2
        _tp_drow `G' 2  `c0' "Ljung-Box Q(`e(bglags)')   [no serial corr.]" chi2
        _tp_drow `G' 3  `c0' "Durbin-Watson" none
        _tp_drow `G' 4  `c0' "Koenker-Breusch-Pagan   [homoskedastic]" chi2
        _tp_drow `G' 5  `c0' "White                   [homoskedastic]" chi2
        _tp_drow `G' 6  `c0' "ARCH LM(`e(archlags)')            [no ARCH]" chi2
        _tp_drow `G' 7  `c0' "Jarque-Bera             [normality]" chi2
        _tp_drow `G' 8  `c0' "  skewness" none
        _tp_drow `G' 9  `c0' "  kurtosis" none
        _tp_drow `G' 10 `c0' "Ramsey RESET            [functional form]" F
        _tp_drow `G' 11 `c0' "CUSUM max |W|/bound (5% cv) [stable]" cv
        _tp_drow `G' 12 `c0' "CUSUMSQ max dev. (5% cv) [stable var.]" cv
        _tp_drow `G' 13 `c0' "Chow breakpoint         [no break]" F
        if "`e(estimator)'" == "ardl" {
            local pp = `G'[14, `c0' + 2]
            local qq = `G'[14, `c0' + 3]
            di as txt "  ARDL lags selected (p, q) = (" as res `pp' as txt ", " as res `qq' as txt ")"
            _tp_drow `G' 15 `c0' "Bounds F, all I(0) (5% cv) [no level]" cv
            _tp_drow `G' 16 `c0' "Bounds F, all I(1) (5% cv) [no level]" cv
            _tp_drow `G' 17 `c0' "Bounds t, all I(0) (5% cv) [no level]" cv
            _tp_drow `G' 18 `c0' "Bounds t, all I(1) (5% cv) [no level]" cv
            local dc = `G'[19, `c0' + 1]
            di as txt "  Bounds decision at 5%: " as res cond(`dc' == 1, "level relationship", cond(`dc' == 0.5, "inconclusive", "no level relationship"))
        }
        if inlist("`e(estimator)'", "fmols", "dols") {
            _tp_drow `G' 20 `c0' "Engle-Granger resid. ADF t (5% cv) [no coint.]" cv
        }
    }
    di as txt "{hline 79}"
    di as txt "Notes: CUSUM, CUSUMSQ, bounds and Engle-Granger critical values and p-values are simulated"
    di as txt "       under the null for this sample size and specification (" as res e(simreps) as txt " replications)."
    di as txt "       Chow test: first post-break period " as res e(break_t) as txt "."
end

program define _tp_drow
    args G r c0 lab type
    local s  = `G'[`r', `c0' + 1]
    local d1 = `G'[`r', `c0' + 2]
    local d2 = `G'[`r', `c0' + 3]
    local p  = `G'[`r', `c0' + 4]
    if missing(`s') {
        di as txt "  `lab'" _col(46) as txt "      n/a"
        exit
    }
    if "`type'" == "none" {
        di as txt "  `lab'" _col(46) as res %9.3f `s'
        exit
    }
    local dtxt ""
    if "`type'" == "F" local dtxt = string(`d1') + "," + string(`d2')
    if "`type'" == "chi2" local dtxt = string(`d1')
    if "`type'" == "cv" local dtxt = "cv " + string(`d1', "%6.3f")
    di as txt "  `lab'" _col(46) as res %9.3f `s' as txt %12s "`dtxt'" "   " as res %8.4f `p'
end

version 14.0
mata:

real matrix _tp_lag(real matrix A, real scalar l)
{
    real matrix out
    real scalar n, k
    if (l == 0 | cols(A) == 0) return(A)
    n = rows(A); k = cols(A)
    out = J(n, k, .)
    if (l > 0 & n > l)  out[|l + 1, 1 \ n, k|] = A[|1, 1 \ n - l, k|]
    if (l < 0 & n > -l) out[|1, 1 \ n + l, k|] = A[|1 - l, 1 \ n, k|]
    return(out)
}

real colvector _tp_ok(real matrix A)
{
    if (cols(A) == 0) return(J(rows(A), 1, 1))
    return(rowmissing(A) :== 0)
}

real matrix _tp_z0(real matrix A)
{
    return(editmissing(A, 0))
}

real matrix _tp_det(real scalar n, real scalar trend)
{
    if (trend) return((J(n, 1, 1), (1::n)))
    return(J(n, 1, 1))
}

real matrix _tp_indep(real matrix W)
{
    real matrix Wc
    real colvector s
    if (cols(W) == 0) return(W)
    Wc = W :- mean(W)
    s = selectindex(diagonal(invsym(cross(Wc, Wc))) :!= 0)
    return(W[., s])
}

real matrix _tp_nonconst(real matrix Z)
{
    real colvector s
    s = selectindex((diagonal(variance(Z)) :> 0))
    return(Z[., s])
}

real matrix _tp_poly(real matrix X, real scalar deg)
{
    real matrix Z, P, Xv
    real scalar p, i, j, k
    p = cols(X)
    if (p == 0) return(J(rows(X), 0, .))
    Xv = select(X, _tp_ok(X))
    mu = mean(Xv)
    sd = sqrt(diagonal(variance(Xv)))'
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
    Pc = select(P, _tp_ok(P))
    Pc = Pc :- mean(Pc)
    s = selectindex(diagonal(invsym(cross(Pc, Pc))) :!= 0)
    return(P[., s])
}

real matrix _tp_hac(real matrix IF0, real scalar lag)
{
    real matrix h, V, G
    real scalar n, l
    h = editmissing(IF0, 0)
    h = h :- mean(h)
    n = rows(h)
    V = cross(h, h)
    for (l = 1; l <= min((lag, n - 1)); l++) {
        G = h[|l + 1, 1 \ n, cols(h)|]' * h[|1, 1 \ n - l, cols(h)|]
        V = V + (1 - l / (lag + 1)) * (G + G')
    }
    return(V * n / (n - 1))
}

real colvector _tp_qsk(real colvector x)
{
    real colvector out, z, s
    out = J(rows(x), 1, 1)
    z = 6 * pi() * x / 5
    s = selectindex(x :!= 0)
    if (rows(s)) out[s] = 25 :/ (12 * pi()^2 * x[s]:^2) :* (sin(z[s]) :/ z[s] - cos(z[s]))
    return(out)
}

real scalar _tp_andrews(real matrix e)
{
    real scalar a, n, rho, s2, num, den
    real colvector x
    num = 0; den = 0
    n = rows(e)
    for (a = 1; a <= cols(e); a++) {
        x = e[., a]
        rho = (x[2..n]' * x[1..(n - 1)]) / (x[1..(n - 1)]' * x[1..(n - 1)])
        rho = min((max((rho, -0.97)), 0.97))
        s2 = mean((x[2..n] - rho * x[1..(n - 1)]):^2)
        num = num + 4 * rho^2 * s2^2 / (1 - rho)^8
        den = den + s2^2 / (1 - rho)^4
    }
    return(1.3221 * (num / den * n)^0.2)
}

void _tp_kern(real matrix e, real scalar b, real matrix Om, real matrix De)
{
    real scalar ne, Jm, j
    real matrix Gj
    real colvector ks
    ne = rows(e)
    Om = cross(e, e) / ne
    De = Om
    Jm = min((ne - 1, ceil(8 * b) + 1))
    ks = _tp_qsk((1::Jm) / b)
    for (j = 1; j <= Jm; j++) {
        Gj = e[|1, 1 \ ne - j, cols(e)|]' * e[|j + 1, 1 \ ne, cols(e)|] / ne
        Om = Om + ks[j] * (Gj + Gj')
        De = De + ks[j] * Gj
    }
}

// QS long-run covariance, Andrews (1991) bandwidth, Andrews-Monahan (1992) prewhitening.
// Delta (one-sided, needed by FMOLS) is computed without prewhitening.
void _tp_lrcovqs(real matrix w0, real scalar pw, real scalar bw, real matrix Om,
    real matrix De, real scalar bwu)
{
    real matrix w, Om0, X, Y, A, e, Oe, Dtmp, Bi
    real scalar n, m, b1, b2, ev
    w = w0 :- mean(w0)
    n = rows(w); m = cols(w)
    b1 = (bw < 0 ? _tp_andrews(w) : bw)
    _tp_kern(w, b1, Om0, De)
    if (!pw) {
        Om = Om0
        bwu = b1
        return
    }
    X = w[|1, 1 \ n - 1, m|]
    Y = w[|2, 1 \ n, m|]
    A = (invsym(cross(X, X)) * cross(X, Y))'
    ev = max(abs(eigenvalues(A)))
    if (ev > 0.97) A = A * 0.97 / ev
    e = Y - X * A'
    b2 = (bw < 0 ? _tp_andrews(e) : bw)
    _tp_kern(e, b2, Oe, Dtmp)
    Bi = luinv(I(m) - A)
    Om = Bi * Oe * Bi'
    bwu = b2
}

// each equation fills: R, IF (T x kR), e, y, Z, v, ext
void _tp_ols(real colvector y, real matrix X, real scalar trend, real matrix R,
    real matrix IF, real matrix e, real matrix Z, real matrix v)
{
    real scalar n, nd
    real matrix A
    real colvector b, s
    n = rows(y); nd = 1 + trend
    Z = (_tp_det(n, trend), X)
    v = _tp_ok((y, Z))
    s = selectindex(v)
    A = invsym(cross(Z[s, .], Z[s, .]))
    b = A * cross(Z[s, .], y[s])
    e = J(n, 1, .)
    e[s] = y[s] - Z[s, .] * b
    IF = J(n, cols(Z), 0)
    IF[s, .] = (Z[s, .] :* e[s]) * A
    R = b[(nd + 1)..rows(b)]
    IF = IF[., (nd + 1)..cols(Z)]
}

real matrix _tp_ardldes(real colvector y, real matrix X, real scalar p, real scalar q, real scalar trend)
{
    real matrix Z
    real scalar l, c
    Z = _tp_det(rows(y), trend)
    for (l = 1; l <= p; l++) Z = (Z, _tp_lag(y, l))
    for (c = 1; c <= cols(X); c++) {
        for (l = 0; l <= q; l++) Z = (Z, _tp_lag(X[., c], l))
    }
    return(Z)
}

real rowvector _tp_ecmstats(real colvector y, real matrix X, real scalar p, real scalar q,
    real scalar trend)
{
    real scalar n, k, nd, c, a, s2, F
    real matrix E, Ae, Vb
    real colvector dy, dx, ve, be, ue, idx
    n = rows(y); k = cols(X); nd = 1 + trend
    dy = y - _tp_lag(y, 1)
    E = (_tp_det(n, trend), _tp_lag(y, 1))
    for (c = 1; c <= k; c++) E = (E, _tp_lag(X[., c], 1))
    for (c = 1; c <= p - 1; c++) E = (E, _tp_lag(dy, c))
    for (c = 1; c <= k; c++) {
        dx = X[., c] - _tp_lag(X[., c], 1)
        for (a = 0; a <= max((q, 1)) - 1; a++) E = (E, _tp_lag(dx, a))
    }
    ve = selectindex(_tp_ok((dy, E)))
    Ae = invsym(cross(E[ve, .], E[ve, .]))
    be = Ae * cross(E[ve, .], dy[ve])
    ue = dy[ve] - E[ve, .] * be
    s2 = cross(ue, ue) / (rows(ve) - cols(E))
    idx = (nd + 1)::(nd + 1 + k)
    Vb = s2 * Ae[idx, idx]
    F = be[idx]' * invsym(Vb) * be[idx] / rows(idx)
    return((F, be[nd + 1] / sqrt(s2 * Ae[nd + 1, nd + 1])))
}

real scalar _tp_quant(real colvector x0, real scalar p)
{
    real colvector x
    real scalar h, lo
    x = sort(select(x0, x0 :< .), 1)
    h = (rows(x) - 1) * p + 1
    lo = floor(h)
    if (lo >= rows(x)) return(x[rows(x)])
    return(x[lo] + (h - lo) * (x[lo + 1] - x[lo]))
}

real matrix _tp_simbounds(real scalar n, real scalar k, real scalar p, real scalar q,
    real scalar trend, real scalar reps)
{
    real matrix out, e, X1
    real colvector y
    real scalar r, c
    out = J(reps, 4, .)
    for (r = 1; r <= reps; r++) {
        y = runningsum(rnormal(n, 1, 0, 1))
        e = rnormal(n, k, 0, 1)
        X1 = e
        for (c = 1; c <= k; c++) X1[., c] = runningsum(e[., c])
        out[r, .] = (_tp_ecmstats(y, e, p, q, trend), _tp_ecmstats(y, X1, p, q, trend))
    }
    return(out)
}

real rowvector _tp_adf(real colvector e)
{
    real colvector dx, w, bb, uu
    real matrix Zl, A
    real scalar n, p, j, s2, aic, best, t, pl
    n = rows(e)
    dx = e - _tp_lag(e, 1)
    best = .
    for (p = 0; p <= 4; p++) {
        Zl = _tp_lag(e, 1)
        for (j = 1; j <= p; j++) Zl = (Zl, _tp_lag(dx, j))
        w = selectindex(_tp_ok((dx, Zl)) :& ((1::n) :> 6))
        A = invsym(cross(Zl[w, .], Zl[w, .]))
        bb = A * cross(Zl[w, .], dx[w])
        uu = dx[w] - Zl[w, .] * bb
        s2 = cross(uu, uu) / (rows(w) - cols(Zl))
        aic = ln(cross(uu, uu) / rows(w)) + 2 * cols(Zl) / rows(w)
        if (best == . | aic < best) {
            best = aic
            t = bb[1] / sqrt(s2 * A[1, 1])
            pl = p
        }
    }
    return((t, pl))
}

real colvector _tp_simeg(real scalar n, real scalar k, real scalar trend, real scalar reps)
{
    real colvector out, b
    real matrix W, Z
    real scalar r, c
    out = J(reps, 1, .)
    for (r = 1; r <= reps; r++) {
        W = rnormal(n, k + 1, 0, 1)
        for (c = 1; c <= k + 1; c++) W[., c] = runningsum(W[., c])
        Z = (_tp_det(n, trend), W[., 2..(k + 1)])
        b = invsym(cross(Z, Z)) * cross(Z, W[., 1])
        adfr = _tp_adf(W[., 1] - Z * b)
        out[r] = adfr[1]
    }
    return(out)
}

void _tp_simcusum(real scalar m, real scalar k, real scalar reps, real colvector cs,
    real colvector sq)
{
    real scalar r, n, a
    real colvector w, W, S, bound, rr
    n = m + k
    a = 0.948
    rr = (1::m)
    bound = a * sqrt(n - k) :+ 2 * a * rr / sqrt(n - k)
    cs = J(reps, 1, .); sq = J(reps, 1, .)
    for (r = 1; r <= reps; r++) {
        w = rnormal(m, 1, 0, 1)
        W = runningsum(w) / sqrt(variance(w))
        cs[r] = max(abs(W) :/ bound)
        S = runningsum(w:^2) / cross(w, w)
        sq[r] = max(abs(S - rr / m))
    }
}

void _tp_ardl(real colvector y, real matrix X, real scalar trend, real scalar fixp,
    real scalar fixq, real scalar maxp, real scalar maxq, real scalar bic, real matrix R,
    real matrix IF, real matrix e, real matrix Z, real matrix v, real matrix ext)
{
    real scalar n, k, nd, p, q, pp, qq, mx, best, crit, nn, kk, s2, c, den, num, F, tB, a, z
    real matrix A, Ib, Jg, E, Ae, Vb
    real colvector b, s, phi, be, ue, dy, dx, ve, idx, common
    n = rows(y); k = cols(X); nd = 1 + trend
    if (fixp < 0) {
        best = .
        mx = max((maxp, maxq))
        common = ((1::n) :> mx)
        for (pp = 1; pp <= maxp; pp++) {
            for (qq = 0; qq <= maxq; qq++) {
                Z = _tp_ardldes(y, X, pp, qq, trend)
                s = selectindex(_tp_ok((y, Z)) :& common)
                b = invsym(cross(Z[s, .], Z[s, .])) * cross(Z[s, .], y[s])
                s2 = mean((y[s] - Z[s, .] * b):^2)
                nn = rows(s); kk = cols(Z)
                crit = ln(s2) + (bic ? ln(nn) : 2) * kk / nn
                if (best == . | crit < best) {
                    best = crit; p = pp; q = qq
                }
            }
        }
    }
    else {
        p = fixp; q = fixq
    }
    Z = _tp_ardldes(y, X, p, q, trend)
    v = _tp_ok((y, Z))
    s = selectindex(v)
    A = invsym(cross(Z[s, .], Z[s, .]))
    b = A * cross(Z[s, .], y[s])
    e = J(n, 1, .); e[s] = y[s] - Z[s, .] * b
    Ib = J(n, cols(Z), 0); Ib[s, .] = (Z[s, .] :* e[s]) * A
    phi = b[(nd + 1)..(nd + p)]
    den = 1 - sum(phi)
    R = J(k + 1, 1, 0); Jg = J(k + 1, rows(b), 0)
    for (c = 1; c <= k; c++) {
        a = nd + p + (c - 1) * (q + 1) + 1
        z = nd + p + c * (q + 1)
        num = sum(b[a..z])
        R[c] = num / den
        Jg[c, a..z] = J(1, z - a + 1, 1 / den)
        Jg[c, (nd + 1)..(nd + p)] = J(1, p, num / den^2)
    }
    R[k + 1] = sum(phi) - 1
    Jg[k + 1, (nd + 1)..(nd + p)] = J(1, p, 1)
    IF = Ib * Jg'
    ecs = _tp_ecmstats(y, X, p, q, trend)
    F = ecs[1]; tB = ecs[2]
    ext = (p, q, F, tB, k)
}

void _tp_fmols(real colvector y, real matrix X, real scalar trend, real scalar bw,
    real scalar pw, real matrix R, real matrix IF, real matrix e, real matrix Z, real matrix v,
    real matrix up, real matrix bf, real scalar bwu)
{
    real scalar n, k, nd
    real matrix Dt, dX, Om, De, Ovvi, ZZi
    real colvector s, b0, u, Ouv, ystar, Dvu, corr, b, ups
    n = rows(y); k = cols(X)
    Dt = _tp_det(n, trend); nd = cols(Dt)
    Z = (Dt, X)
    dX = X - _tp_lag(X, 1)
    v = _tp_ok((y, Z, dX))
    s = selectindex(v)
    b0 = invsym(cross(Z[s, .], Z[s, .])) * cross(Z[s, .], y[s])
    u = y[s] - Z[s, .] * b0
    _tp_lrcovqs((u, dX[s, .]), pw, bw, Om, De, bwu)
    Ouv = Om[2..(k + 1), 1]
    Ovvi = invsym(Om[2..(k + 1), 2..(k + 1)])
    ystar = y[s] - dX[s, .] * (Ovvi * Ouv)
    Dvu = De[2..(k + 1), 1] - De[2..(k + 1), 2..(k + 1)] * Ovvi * Ouv
    ZZi = invsym(cross(Z[s, .], Z[s, .]))
    corr = J(nd, 1, 0) \ (rows(s) * Dvu)
    b = ZZi * (cross(Z[s, .], ystar) - corr)
    ups = ystar - Z[s, .] * b
    e = J(n, 1, .); e[s] = y[s] - Z[s, .] * b
    up = J(n, 1, .); up[s] = ups
    IF = J(n, cols(Z), 0); IF[s, .] = (Z[s, .] :* ups) * ZZi
    R = b[(nd + 1)..rows(b)]
    IF = IF[., (nd + 1)..cols(Z)]
    bf = b
}

// mixed-normal joint covariance of FMOLS long-run coefficients across equations
real matrix _tp_fmjoint(real matrix ZS, real matrix zoff, real matrix VS, real matrix UP,
    real scalar nd, real scalar pw, real scalar bw)
{
    real scalar neq, i, j, bwu
    real colvector s
    real matrix Om, De, V, Zi, Zj, Ai, Aj, Vij, rowb
    neq = cols(UP)
    s = selectindex(rowmin(VS) :== 1)
    _tp_lrcovqs(UP[s, .], pw, bw, Om, De, bwu)
    V = J(0, 0, .)
    for (i = 1; i <= neq; i++) {
        Zi = ZS[s, (zoff[i] + 1)..zoff[i + 1]]
        Ai = invsym(cross(Zi, Zi))
        rowb = J(cols(Zi) - nd, 0, .)
        for (j = 1; j <= neq; j++) {
            Zj = ZS[s, (zoff[j] + 1)..zoff[j + 1]]
            Aj = invsym(cross(Zj, Zj))
            Vij = Ai * cross(Zi, Zj) * Aj * Om[i, j]
            rowb = (rowb, Vij[(nd + 1)..rows(Vij), (nd + 1)..cols(Vij)])
        }
        V = (rows(V) ? V \ rowb : rowb)
    }
    return(V)
}

void _tp_dols(real colvector y, real matrix X, real scalar trend, real scalar leads,
    real scalar lags, real matrix R, real matrix IF, real matrix e, real matrix Z, real matrix v,
    real matrix bf)
{
    real scalar n, k, nd, c, j
    real matrix dX, A
    real colvector s, b
    n = rows(y); k = cols(X)
    Z = (_tp_det(n, trend), X)
    nd = 1 + trend
    dX = X - _tp_lag(X, 1)
    for (c = 1; c <= k; c++) {
        for (j = -leads; j <= lags; j++) Z = (Z, _tp_lag(dX[., c], j))
    }
    v = _tp_ok((y, Z))
    s = selectindex(v)
    A = invsym(cross(Z[s, .], Z[s, .]))
    b = A * cross(Z[s, .], y[s])
    e = J(n, 1, .); e[s] = y[s] - Z[s, .] * b
    IF = J(n, cols(Z), 0); IF[s, .] = (Z[s, .] :* e[s]) * A
    R = b[(nd + 1)..(nd + k)]
    IF = IF[., (nd + 1)..(nd + k)]
    bf = b[1..(nd + k)]
}

real colvector _tp_dmlres(real colvector a, real matrix P, real scalar K, real scalar gap, real scalar lam)
{
    real matrix Z, ZZ
    real colvector out, idx, tr, blk, b, sizes
    real scalar n, m, k, st, lo, hi
    n = rows(a)
    out = J(n, 1, .)
    idx = selectindex(_tp_ok((a, P)))
    m = rows(idx)
    Z = (J(n, 1, 1), P)
    sizes = J(K, 1, floor(m / K))
    if (mod(m, K)) sizes[1..mod(m, K)] = sizes[1..mod(m, K)] :+ 1
    st = 0
    for (k = 1; k <= K; k++) {
        blk = idx[(st + 1)..(st + sizes[k])]
        st = st + sizes[k]
        lo = blk[1] - gap; hi = blk[rows(blk)] + gap
        tr = select(idx, (idx :< lo) :| (idx :> hi))
        ZZ = cross(Z[tr, .], Z[tr, .])
        if (lam > 0) ZZ = ZZ + lam * rows(tr) * diag((0, J(1, cols(P), 1)))
        b = invsym(ZZ) * cross(Z[tr, .], a[tr])
        out[blk] = a[blk] - Z[blk, .] * b
    }
    return(out)
}

// runs all equations; returns R, IF, off, residual matrix, extra
void _tp_eqs(real scalar est, real matrix G, real scalar km, real scalar trend, real scalar hlag,
    real scalar fixp, real scalar fixq, real scalar maxp, real scalar maxq, real scalar bic,
    real scalar leads, real scalar dlags, real scalar deg, real scalar K, real scalar lam,
    real scalar gap, real matrix R, real matrix IF, real matrix off, real matrix RES,
    real matrix YS, real matrix ZS, real matrix zoff, real matrix VS, real matrix EXT,
    real scalar fmbw, real scalar pw, real matrix UP, real matrix BF, real matrix bfo,
    real scalar bwbar)
{
    real colvector Y, D, y, Dt, Yt, b, e, s, Rq
    real matrix Mm, X, P, Mt, Xq, Zq, A, IFq, eq, vq, ext, upq, bfq
    real scalar bwq
    real scalar q, n
    n = rows(G)
    Y = G[., 1]; D = G[., 2]; Mm = G[., 3..(2 + km)]
    X = (cols(G) > 2 + km ? G[., (3 + km)..cols(G)] : J(n, 0, .))
    R = J(0, 1, .); IF = J(n, 0, .); off = J(1, 0, .); RES = J(n, 0, .)
    YS = J(n, 0, .); VS = J(n, 0, .); EXT = J(km + 1, 5, .)
    UP = J(n, 0, .); BF = J(0, 1, .); bfo = 0; bwbar = 0
    ZS = J(n, 0, .); zoff = 0
    if (est == 5) {
        P = _tp_poly(X, deg)
        Dt = _tp_dmlres(D, P, K, gap, lam)
        Yt = _tp_dmlres(Y, P, K, gap, lam)
        Mt = J(n, 0, .)
        for (q = 1; q <= km; q++) Mt = (Mt, _tp_dmlres(Mm[., q], P, K, gap, lam))
    }
    for (q = 0; q <= km; q++) {
        if (est == 5) {
            y  = (q == 0 ? Yt : Mt[., q])
            Zq = (q == 0 ? (Dt, Mt) : Dt)
            vq = _tp_ok((y, Zq))
            s  = selectindex(vq)
            A  = invsym(cross(Zq[s, .], Zq[s, .]))
            b  = A * cross(Zq[s, .], y[s])
            eq = J(n, 1, .); eq[s] = y[s] - Zq[s, .] * b
            IFq = J(n, cols(Zq), 0); IFq[s, .] = (Zq[s, .] :* eq[s]) * A
            Rq = b
        }
        else {
            y  = (q == 0 ? Y : Mm[., q])
            Xq = (q == 0 ? (D, Mm, X) : (D, X))
            if (est == 1) _tp_ols(y, Xq, trend, Rq, IFq, eq, Zq, vq)
            else if (est == 2) {
                _tp_ardl(y, Xq, trend, fixp, fixq, maxp, maxq, bic, Rq, IFq, eq, Zq, vq, ext)
                EXT[q + 1, .] = ext
            }
            else if (est == 3) {
                _tp_fmols(y, Xq, trend, fmbw, pw, Rq, IFq, eq, Zq, vq, upq, bfq, bwq)
                UP = (UP, upq); BF = BF \ bfq; bfo = (bfo, rows(BF))
                bwbar = bwbar + bwq / (km + 1)
            }
            else {
                _tp_dols(y, Xq, trend, leads, dlags, Rq, IFq, eq, Zq, vq, bfq)
                BF = BF \ bfq; bfo = (bfo, rows(BF))
            }
        }
        off = (off, rows(R) + 1)
        R = R \ Rq
        IF = (IF, IFq)
        RES = (RES, eq)
        YS = (YS, y)
        VS = (VS, vq)
        ZS = (ZS, Zq)
        zoff = (zoff, cols(ZS))
    }
}

real rowvector _tp_eff(real colvector R, real matrix off, real scalar km, real scalar d1, real scalar d0)
{
    real rowvector nies, out
    real scalar j, nde, nie
    nies = J(1, km, .)
    for (j = 1; j <= km; j++) nies[j] = R[off[1] + j] * R[off[1 + j]] * (d1 - d0)
    nde = R[off[1]] * (d1 - d0)
    nie = sum(nies)
    out = (nde, nie, nde + nie, nie / (nde + nie))
    if (km > 1) out = (out, nies)
    return(out)
}

real matrix _tp_effjac(real colvector R, real matrix off, real scalar km, real scalar d1, real scalar d0)
{
    real matrix Jm
    real colvector Rp, Rm
    real scalar j, h
    Jm = J(cols(_tp_eff(R, off, km, d1, d0)), rows(R), 0)
    for (j = 1; j <= rows(R); j++) {
        h = 1e-6 * max((1, abs(R[j])))
        Rp = R; Rp[j] = Rp[j] + h
        Rm = R; Rm[j] = Rm[j] - h
        Jm[., j] = ((_tp_eff(Rp, off, km, d1, d0) - _tp_eff(Rm, off, km, d1, d0)) / (2 * h))'
    }
    return(Jm)
}

// ----------------------------------------------------------------- diagnostics
real scalar _tp_nr2(real colvector y, real matrix W)
{
    real matrix W1
    real colvector b, u
    W1 = (J(rows(y), 1, 1), W)
    b = invsym(cross(W1, W1)) * cross(W1, y)
    u = y - W1 * b
    return(rows(y) * (1 - cross(u, u) / sum((y :- mean(y)):^2)))
}

real matrix _tp_diag(real colvector e, real colvector y, real matrix Z, real colvector v,
    real scalar bgp, real scalar archq, real scalar brk, real scalar est, real rowvector ext,
    real scalar simreps, real scalar trend, real scalar keg)
{
    real matrix DG, W, Wf, Zv, Zu, A, E2l, Zl
    real colvector s, r, b, u, ev, x, d, f, fs, r0, r1, w, Wc, S, post, pv, yv, dx, bb, uu
    real scalar n, LM, Q, k, rr, i, j, JB, Sk, Ku, F, df, nn, kk, c0, a, stat, q, rank0, rank1, best, t, p, aic, s2, pl
    real colvector csn, sqn, EG
    real matrix NB
    real rowvector adf
    DG = J(20, 4, .)
    s = selectindex(v)
    n = rows(e)
    // Breusch-Godfrey
    W = J(n, 0, .)
    for (j = 1; j <= bgp; j++) W = (W, _tp_z0(_tp_lag(e, j)))
    W = (Z, W)
    W = W[s, .]
    r = e[s]
    b = invsym(cross(W, W)) * cross(W, r)
    u = r - W * b
    LM = rows(s) * (1 - cross(u, u) / sum((r :- mean(r)):^2))
    DG[1, .] = (LM, bgp, ., chi2tail(bgp, LM))
    // Ljung-Box
    x = select(e, e :< .); x = x :- mean(x); nn = rows(x)
    Q = 0
    for (j = 1; j <= bgp; j++) Q = Q + ((x[(j + 1)..nn]' * x[1..(nn - j)]) / cross(x, x))^2 / (nn - j)
    Q = Q * nn * (nn + 2)
    DG[2, .] = (Q, bgp, ., chi2tail(bgp, Q))
    ev = select(e, e :< .)
    DG[3, 1] = sum((ev[2..rows(ev)] - ev[1..(rows(ev) - 1)]):^2) / cross(ev, ev)
    // Koenker and White
    W = _tp_nonconst(Z[s, .])
    LM = _tp_nr2(e[s]:^2, W)
    DG[4, .] = (LM, cols(W), ., chi2tail(cols(W), LM))
    Wf = W
    for (i = 1; i <= cols(W); i++) {
        for (j = i; j <= cols(W); j++) Wf = (Wf, W[., i] :* W[., j])
    }
    Wf = _tp_indep(Wf)
    if (cols(Wf) < rows(s) / 2) {
        LM = _tp_nr2(e[s]:^2, Wf)
        DG[5, .] = (LM, cols(Wf), ., chi2tail(cols(Wf), LM))
    }
    // ARCH
    E2l = J(n, 0, .)
    for (j = 1; j <= archq; j++) E2l = (E2l, _tp_lag(e:^2, j))
    w = selectindex(_tp_ok((e:^2, E2l)))
    LM = _tp_nr2(e[w]:^2, E2l[w, .])
    DG[6, .] = (LM, archq, ., chi2tail(archq, LM))
    // Jarque-Bera
    d = ev :- mean(ev)
    Sk = mean(d:^3) / mean(d:^2)^1.5
    Ku = mean(d:^4) / mean(d:^2)^2
    JB = rows(ev) * (Sk^2 / 6 + (Ku - 3)^2 / 24)
    DG[7, .] = (JB, 2, ., chi2tail(2, JB))
    DG[8, 1] = Sk; DG[9, 1] = Ku
    // RESET
    Zv = Z[s, .]; yv = y[s]
    b = invsym(cross(Zv, Zv)) * cross(Zv, yv)
    f = Zv * b
    fs = (f :- mean(f)) / sqrt(mean((f :- mean(f)):^2))
    Zu = (Zv, fs:^2, fs:^3)
    bb = invsym(cross(Zu, Zu)) * cross(Zu, yv)
    r0 = yv - f; r1 = yv - Zu * bb
    nn = rows(yv); kk = cols(Zu)
    F = ((cross(r0, r0) - cross(r1, r1)) / 2) / (cross(r1, r1) / (nn - kk))
    DG[10, .] = (F, 2, nn - kk, Ftail(2, nn - kk, F))
    // CUSUM and CUSUMSQ (recursive residuals)
    k = cols(Zv)
    w = J(nn - k, 1, .)
    for (rr = k + 1; rr <= nn; rr++) {
        A = invsym(cross(Zv[1..(rr - 1), .], Zv[1..(rr - 1), .]))
        b = A * cross(Zv[1..(rr - 1), .], yv[1..(rr - 1)])
        w[rr - k] = (yv[rr] - Zv[rr, .] * b) / sqrt(1 + Zv[rr, .] * A * Zv[rr, .]')
    }
    Wc = runningsum(w) / sqrt(variance(w))
    a = 0.948
    t = rows(w)
    stat = max(abs(Wc) :/ (a * sqrt(nn - k) :+ 2 * a * (1::t) / sqrt(nn - k)))
    S = runningsum(w:^2) / cross(w, w)
    _tp_simcusum(t, k, simreps, csn, sqn)
    DG[11, .] = (stat, _tp_quant(csn, .95), ., mean(csn :>= stat))
    stat = max(abs(S - (1::t) / t))
    DG[12, .] = (stat, _tp_quant(sqn, .95), ., mean(sqn :>= stat))
    // Chow breakpoint (post = periods after brk)
    post = ((1::n) :> brk)
    pv = post[s]
    Zu = (Zv, Zv :* pv)
    bb = invsym(cross(Zu, Zu)) * cross(Zu, yv)
    r0 = yv - f; r1 = yv - Zu * bb
    rank1 = rank(Zu); rank0 = rank(Zv)
    q = rank1 - rank0
    F = ((cross(r0, r0) - cross(r1, r1)) / q) / (cross(r1, r1) / (nn - rank1))
    DG[13, .] = (F, q, nn - rank1, Ftail(q, nn - rank1, F))
    if (est == 2) {
        DG[14, 2] = ext[1]; DG[14, 3] = ext[2]; DG[14, 1] = 0
        NB = _tp_simbounds(rows(y), ext[5], ext[1], ext[2], trend, simreps)
        DG[15, .] = (ext[3], _tp_quant(NB[., 1], .95), ., mean(NB[., 1] :>= ext[3]))
        DG[16, .] = (ext[3], _tp_quant(NB[., 3], .95), ., mean(NB[., 3] :>= ext[3]))
        DG[17, .] = (ext[4], _tp_quant(NB[., 2], .05), ., mean(NB[., 2] :<= ext[4]))
        DG[18, .] = (ext[4], _tp_quant(NB[., 4], .05), ., mean(NB[., 4] :<= ext[4]))
        DG[19, 1] = (DG[16, 4] < .05 ? 1 : (DG[15, 4] < .05 ? 0.5 : 0))
    }
    if (est == 3 | est == 4) {
        adf = _tp_adf(e)
        EG = _tp_simeg(rows(y), keg, trend, simreps)
        DG[20, .] = (adf[1], _tp_quant(EG, .05), adf[2], mean(EG :<= adf[1]))
    }
    return(DG)
}

// ----------------------------------------------------------------- main
real matrix _tp_vqs(real matrix IF)
{
    real matrix Om, De
    real scalar bw
    _tp_lrcovqs(editmissing(IF, 0), 1, -1, Om, De, bw)
    return(rows(IF) * Om)
}

void _tp_fitV(real scalar est, real matrix G, real scalar km, real scalar trend,
    real scalar hlag, real scalar fixp, real scalar fixq, real scalar maxp, real scalar maxq,
    real scalar bic, real scalar leads, real scalar dlags, real scalar deg, real scalar K,
    real scalar lam, real scalar gap, real scalar fmbw, real scalar pw, real scalar d1,
    real scalar d0, real matrix R, real matrix V, real matrix off, real matrix eff,
    real matrix Ve, real matrix RES, real matrix YS, real matrix ZS, real matrix zoff,
    real matrix VS, real matrix EXT, real matrix UP, real matrix BF, real matrix bfo,
    real scalar bwbar)
{
    real matrix IF, Jm
    _tp_eqs(est, G, km, trend, hlag, fixp, fixq, maxp, maxq, bic, leads, dlags, deg, K,
        lam, gap, R, IF, off, RES, YS, ZS, zoff, VS, EXT, fmbw, pw, UP, BF, bfo, bwbar)
    if (hasmissing(R)) return
    if (est == 3) V = _tp_fmjoint(ZS, zoff, VS, UP, 1 + trend, pw, fmbw)
    else if (hlag < 0) V = _tp_vqs(IF)
    else V = _tp_hac(IF, hlag)
    V = (V + V') / 2
    eff = _tp_eff(R, off, km, d1, d0)
    Jm = _tp_effjac(R, off, km, d1, d0)
    Ve = Jm * V * Jm'
}

void _tp_main(string scalar yv, string scalar dv, string scalar mv, string scalar cv,
    string scalar touse, string scalar tidv, real scalar T, real scalar est,
    real scalar trend, real scalar hlag, real scalar fixp, real scalar fixq,
    real scalar maxp, real scalar maxq, real scalar bic, real scalar leads,
    real scalar dlags, real scalar deg, real scalar K, real scalar lam, real scalar gap,
    real scalar d1, real scalar d0, real scalar B, real scalar L, real scalar dots,
    real scalar level, real scalar dodiag, real scalar bgp, real scalar archq,
    real scalar brk, real scalar simreps, real scalar sieve, real scalar fmbw, real scalar pw)
{
    real matrix G0, G, R, off, RES, YS, VS, EXT, V, Ve, EB, DG, ZS, zoff, UP, BF, bfo
    real matrix Rb, Vb, ob, efb, Veb, R2, Y2, Z2, z2, V2, E2, U2, B2, b2o
    real matrix Mm, X, exo, DT, Xs, U, w, Y_, Xl, Bv, E, Sg, best_B, best_E, e, ws, exs, Ms, Gs, Zl
    real colvector tid, se, z, p, lo, hi, rr, starts, s, Ys, Ds, tobs
    real scalar km, kx, b, nb, i, a, nok, nfail, cvz, q, bwbar, bw2, nd, ne, pp, aic, best, best_p, t, l, burn, j
    real rowvector eff, lagv
    tid = st_data(., tidv, touse)
    G0 = (st_data(., (yv, dv), touse), st_data(., tokens(mv), touse))
    if (strtrim(cv) != "") G0 = (G0, st_data(., tokens(cv), touse))
    km = cols(tokens(mv))
    kx = cols(G0) - 2 - km
    G = J(T, cols(G0), .)
    G[tid, .] = G0

    _tp_fitV(est, G, km, trend, hlag, fixp, fixq, maxp, maxq, bic, leads, dlags, deg, K,
        lam, gap, fmbw, pw, d1, d0, R, V, off, eff, Ve, RES, YS, ZS, zoff, VS, EXT, UP, BF,
        bfo, bwbar)
    if (hasmissing(R)) {
        errprintf("estimation failed (singular design or too few usable observations)\n")
        exit(error(430))
    }
    se = sqrt(diagonal(Ve))
    cvz = invnormal(1 - (1 - level / 100) / 2)
    lo = eff' - cvz * se; hi = eff' + cvz * se
    p = 2 * normal(-abs(eff' :/ se))
    nfail = 0
    if (B > 0 & !sieve) {
        EB = J(B, cols(eff), .)
        nb = ceil(T / L)
        if (dots) printf("{txt}Block bootstrap replications ({res}%g{txt})\n", B)
        for (b = 1; b <= B; b++) {
            starts = floor(runiform(nb, 1) * (T - L + 1))
            rr = J(0, 1, .)
            for (i = 1; i <= nb; i++) rr = rr \ ((starts[i] + 1)::(starts[i] + L))
            rr = rr[1..T]
            _tp_fitV(est, G[rr, .], km, trend, hlag, fixp, fixq, maxp, maxq, bic, leads, dlags,
                deg, K, lam, gap, fmbw, pw, d1, d0, Rb, Vb, ob, efb, Veb, R2, Y2, Z2, z2, V2, E2,
                U2, B2, b2o, bw2)
            if (hasmissing(Rb)) {
                nfail++
                if (dots) printf("{err}x{txt}")
            }
            else {
                EB[b, .] = efb
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
        p = 2 * normal(-abs(eff' :/ se))
        st_matrix("__tp_bboot", EB)
    }
    if (B > 0 & sieve) {
        // sieve (VAR) bootstrap-t for the cointegrated system (Chang, Park and Song 2006)
        if (hasmissing(G)) {
            errprintf("the sieve bootstrap needs a series without gaps or missing values\n")
            exit(error(416))
        }
        Mm = G[., 3..(2 + km)]
        X  = (kx ? G[., (3 + km)..cols(G)] : J(T, 0, .))
        exo = (G[., 2], X)
        nd = 1 + trend
        DT = _tp_det(T, trend)
        U = J(T, km + 1, .)
        for (q = 1; q <= km + 1; q++) {
            Zl = ZS[., (zoff[q] + 1)..(zoff[q] + nd + (q == 1 ? 1 + km + kx : 1 + kx))]
            U[., q] = YS[., q] - Zl * BF[(bfo[q] + 1)..bfo[q + 1]]
        }
        w = (U[2..T, .], exo[2..T, .] - exo[1..(T - 1), .])
        w = w :- mean(w)
        ne = km + 1
        best = .
        for (pp = 1; pp <= 4; pp++) {
            Y_ = w[(pp + 1)..rows(w), .]
            Xl = J(rows(Y_), 0, .)
            for (l = 1; l <= pp; l++) Xl = (Xl, w[(pp + 1 - l)..(rows(w) - l), .])
            Bv = invsym(cross(Xl, Xl)) * cross(Xl, Y_)
            E = Y_ - Xl * Bv
            Sg = cross(E, E) / rows(E)
            aic = ln(det(Sg)) + 2 * pp * cols(w)^2 / rows(E)
            if (best == . | aic < best) {
                best = aic; best_p = pp; best_B = Bv; best_E = E
            }
        }
        best_E = best_E :- mean(best_E)
        burn = 50
        EB = J(B, cols(eff), .)
        if (dots) printf("{txt}Sieve bootstrap replications ({res}%g{txt})\n", B)
        for (b = 1; b <= B; b++) {
            e = best_E[ceil(rows(best_E) * runiform(T + burn, 1)), .]
            ws = J(T + burn, cols(w), 0)
            for (t = 1; t <= T + burn; t++) {
                lagv = J(1, 0, .)
                for (l = 1; l <= best_p; l++) lagv = (lagv, (t - l >= 1 ? ws[t - l, .] : J(1, cols(w), 0)))
                ws[t, .] = lagv * best_B + e[t, .]
            }
            ws = ws[(burn + 1)..(T + burn), .]
            exs = J(T, cols(exo), .)
            exs[1, .] = exo[1, .]
            for (i = 1; i <= cols(exo); i++) exs[2..T, i] = exo[1, i] :+ runningsum(ws[2..T, ne + i])
            Ds = exs[., 1]
            Xs = (kx ? exs[., 2..cols(exs)] : J(T, 0, .))
            Ms = J(T, km, .)
            for (j = 1; j <= km; j++) {
                Ms[., j] = (DT, Ds, Xs) * BF[(bfo[j + 1] + 1)..bfo[j + 2]] + ws[., 1 + j]
            }
            Ys = (DT, Ds, Ms, Xs) * BF[(bfo[1] + 1)..bfo[2]] + ws[., 1]
            Gs = (Ys, Ds, Ms, Xs)
            _tp_fitV(est, Gs, km, trend, hlag, fixp, fixq, maxp, maxq, bic, leads, dlags,
                deg, K, lam, gap, fmbw, pw, d1, d0, Rb, Vb, ob, efb, Veb, R2, Y2, Z2, z2, V2, E2,
                U2, B2, b2o, bw2)
            if (hasmissing(Rb) | hasmissing(Veb)) {
                nfail++
                if (dots) printf("{err}x{txt}")
            }
            else {
                EB[b, .] = (efb - eff) :/ sqrt(diagonal(Veb))'
                if (dots) printf(".")
            }
            if (dots & mod(b, 50) == 0) printf(" %g\n", b)
            displayflush()
        }
        if (dots) printf("\n")
        a = (1 - level / 100) / 2
        tobs = eff' :/ se
        for (i = 1; i <= cols(eff); i++) {
            s = select(EB[., i], EB[., i] :< .)
            lo[i] = eff[i] - _tp_quant(s, 1 - a) * se[i]
            hi[i] = eff[i] - _tp_quant(s, a) * se[i]
            p[i] = mean(abs(s) :>= abs(tobs[i]))
        }
        st_matrix("__tp_bboot", EB)
    }
    z = eff' :/ se
    if (dodiag) {
        DG = J(20, 0, .)
        for (q = 1; q <= km + 1; q++) {
            DG = (DG, _tp_diag(RES[., q], YS[., q], ZS[., (zoff[q] + 1)..zoff[q + 1]], VS[., q], bgp,
                archq, brk, est, EXT[q, .], simreps, trend, (q == 1 ? 1 + km + kx : 1 + kx)))
        }
        st_matrix("__tp_diag", DG)
    }
    st_matrix("__tp_b", R')
    st_matrix("__tp_V", V)
    st_matrix("__tp_eff", (eff', se, z, p, lo, hi))
    st_matrix("__tp_veff", Ve)
    st_numscalar("__tp_bfail", nfail)
    st_numscalar("__tp_fmbw", bwbar)
}

end
