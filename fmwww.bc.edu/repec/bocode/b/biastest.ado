*! version 1.0.0  13nov2026
*! biastest: test of coefficient equality between two estimators
*!           (Hausman-type and bootstrap contrasts)
*! Author: Hasraddin Guliyev, Azerbaijan State University of Economics (UNEC)

program define biastest, eclass
    version 14.0
    local vv : display "version " string(_caller()) ":"

    syntax varlist(min=2 numeric) [if] [in] ,                 ///
        m1(string) m2(string)                                   ///
        [ m1ops(string) m2ops(string)                           ///
          SIGMALESS SIGMAMORE EFFicient(integer 0)              ///
          BOOTstrap REPs(integer 200) SEED(string) CLuster(varname) ]

    if "`sigmaless'" != "" & "`sigmamore'" != "" {
        di as error "options sigmaless and sigmamore may not be combined"
        exit 198
    }
    if !inlist(`efficient', 0, 1, 2) {
        di as error "efficient() must be 1 or 2"
        exit 198
    }
    local boot = ("`bootstrap'" != "")
    if !`boot' & ("`cluster'" != "" | "`seed'" != "") {
        di as error "options cluster() and seed() require option bootstrap"
        exit 198
    }
    if `boot' & `reps' < 2 {
        di as error "reps() must be at least 2"
        exit 198
    }

    marksample touse
    gettoken depvar indepvars : varlist
    local indepvars : list retokenize indepvars

    di as text "Dependent variable:    " as result "`depvar'"
    di as text "Independent variables: " as result "`indepvars'"

    tempname b1 V1 b2 V2 sig1 sig2
    tempvar  smp1 smp2 esmp

    // ------------------------------------------------------------------
    // 1. Fit both models on the same marked estimation sample
    // ------------------------------------------------------------------
    forvalues m = 1/2 {
        local show `"`m`m'' `depvar' `indepvars'"'
        if `"`if'"' != "" local show `"`show' `if'"'
        if `"`in'"' != "" local show `"`show' `in'"'
        if `"`m`m'ops'"' != "" local show `"`show', `m`m'ops'"'
        di as text _n "{bf:Model `m'}: " as result `"`show'"'
        capture noisily `vv' `m`m'' `depvar' `indepvars' if `touse', `m`m'ops'
        local rc = _rc
        if `rc' {
            di as error "Model `m' (`m`m'') could not be estimated"
            exit `rc'
        }
        matrix `b`m'' = e(b)
        matrix `V`m'' = e(V)
        local N`m'    = e(N)
        local cmd`m'  `"`e(cmd)'"'
        local vce`m'  `"`e(vce)'"'
        local vcet`m' `"`e(vcetype)'"'
        quietly generate byte `smp`m'' = e(sample)
        // disturbance s.d. used by sigmaless/sigmamore, following -hausman-:
        // e(sigma_e) after xtreg fe/mle, otherwise e(rmse) (e.g. regress,
        // xtreg re), then e(sigma_e), then e(sigma)
        if "`e(cmd)'" == "xtreg" & inlist("`e(model)'", "fe", "ml", "mle") {
            scalar `sig`m'' = e(sigma_e)
        }
        else {
            scalar `sig`m'' = e(rmse)
            if missing(`sig`m'') scalar `sig`m'' = e(sigma_e)
            if missing(`sig`m'') scalar `sig`m'' = e(sigma)
        }
    }

    // ------------------------------------------------------------------
    // 2. Diagnostics (analytic Hausman variance only)
    // ------------------------------------------------------------------
    local scaling "`sigmaless'`sigmamore'"
    if `boot' {
        if `efficient' != 0 | "`scaling'" != "" {
            di as text _n "Note: with option bootstrap, efficient(), sigmaless and sigmamore" ///
                " are not used."
        }
        local scaling
        local sigmaless
        local sigmamore
    }
    else {
        quietly count if `smp1' != `smp2'
        if r(N) > 0 | `N1' != `N2' {
            di as error _n "Warning: the two models were not fit on the same observations" ///
                " (N1 = `N1', N2 = `N2')."
            di as error "         V(cons) - V(eff) presumes both estimators use one sample."
        }
        local nonstd "robust cluster bootstrap jackknife"
        local ns1 : list vce1 in nonstd
        local ns2 : list vce2 in nonstd
        if (`ns1' & "`vce1'" != "") | (`ns2' & "`vce2'" != "") {
            di as error _n "Warning: nonstandard VCE detected (Model 1: `vcet1' `vce1';" ///
                " Model 2: `vcet2' `vce2')."
            di as error "         V(cons) - V(eff) is the variance of the contrast only if the"
            di as error "         efficient estimator is fully efficient under H0; this fails with"
            di as error "         robust, cluster-robust, bootstrap or jackknife variance estimates."
            di as error "         Use option {bf:bootstrap} (with {bf:cluster()} if needed) instead."
        }
        local qcmds "qreg sqreg bsqreg iqreg"
        local q1 : list cmd1 in qcmds
        local q2 : list cmd2 in qcmds
        if `q1' & `q2' {
            di as error _n "Warning: neither quantile regression is efficient relative to the other,"
            di as error "         so V(b1) - V(b2) is not the variance of b1 - b2. Use option"
            di as error "         {bf:bootstrap}, or fit both quantiles with {cmd:sqreg} and use {cmd:test}."
        }
        if "`scaling'" != "" {
            local lincmds "regress xtreg areg"
            local l1 : list cmd1 in lincmds
            local l2 : list cmd2 in lincmds
            if !(`l1' & `l2') {
                di as error _n "Warning: option `scaling' requires both models to have V proportional"
                di as error "         to one disturbance variance (regress, xtreg, areg); option ignored."
                local scaling
            }
            else if missing(`sig1') | missing(`sig2') {
                di as error _n "Warning: e(rmse), e(sigma_e) or e(sigma) is not stored by both models;"
                di as error "         option `scaling' ignored."
                local scaling
            }
            if "`scaling'" == "" {
                local sigmaless
                local sigmamore
            }
        }
    }

    // ------------------------------------------------------------------
    // 3. Coefficients compared (matched by name, omitted terms excluded)
    // ------------------------------------------------------------------
    local kk 0
    mata: _biastest_common("`b1'", "`V1'", "`b2'", "`V2'", "`indepvars'")
    if `kk' == 0 {
        di as error "no coefficient of {it:indepvars} is estimated (and not omitted) in both models"
        exit 498
    }

    // ------------------------------------------------------------------
    // 4. Bootstrap distribution of b1* - b2* (option bootstrap)
    // ------------------------------------------------------------------
    tempname Vb
    local Vbname
    if `boot' {
        local panvar
        local timvar
        capture quietly xtset
        if !_rc {
            local panvar `r(panelvar)'
            local timvar `r(timevar)'
        }
        local isxt = (substr("`cmd1'", 1, 2) == "xt" | substr("`cmd2'", 1, 2) == "xt")
        if `isxt' & "`panvar'" == "" {
            di as error "option bootstrap with xt commands requires the data to be {bf:xtset}"
            exit 459
        }
        // panel data are resampled by panel unless cluster() says otherwise
        local clvar `cluster'
        if "`clvar'" == "" & `isxt' local clvar `panvar'
        if "`clvar'" != "" local unit "clusters of `clvar'"
        else local unit "observations"

        if `"`seed'"' != "" set seed `seed'
        tempname bsD bb1 vb1 bb2 vb2
        tempfile bsbase
        capture mata: rmexternal("`bsD'")
        preserve
        quietly keep if `touse'
        quietly save `"`bsbase'"'
        di as text _n "Bootstrap replications (`reps'), resampling `unit'"
        local nfail 0
        forvalues r = 1/`reps' {
            quietly use `"`bsbase'"', clear
            if "`clvar'" != "" {
                tempvar newcl
                quietly bsample, cluster(`clvar') idcluster(`newcl')
                if `isxt' {
                    // duplicated panels must become distinct panels
                    tempvar newpan
                    quietly egen long `newpan' = group(`newcl' `panvar')
                    if "`timvar'" != "" quietly xtset `newpan' `timvar'
                    else quietly xtset `newpan'
                }
            }
            else quietly bsample
            local okrep 0
            capture quietly `vv' `m1' `depvar' `indepvars', `m1ops'
            if _rc == 1 exit 1
            if !_rc {
                matrix `bb1' = e(b)
                matrix `vb1' = e(V)
                capture quietly `vv' `m2' `depvar' `indepvars', `m2ops'
                if _rc == 1 exit 1
                if !_rc {
                    matrix `bb2' = e(b)
                    matrix `vb2' = e(V)
                    mata: st_local("okrep", strofreal(_biastest_bsappend("`bsD'", "`bb1'", "`vb1'", "`bb2'", "`vb2'", "`common'")))
                }
            }
            if `okrep' di as text "." _continue
            else {
                di as error "x" _continue
                local ++nfail
            }
            if mod(`r', 50) == 0 di as text " " `r'
        }
        if mod(`reps', 50) != 0 di
        restore
        local nboot 0
        mata: _biastest_bsvar("`bsD'", "`Vb'", "`common'")
        if `nboot' < 2 {
            di as error "fewer than 2 successful bootstrap replications"
            exit 498
        }
        local Vbname `Vb'
    }

    // ------------------------------------------------------------------
    // 5. Computations (Mata)
    // ------------------------------------------------------------------
    tempname bA bB dif Vd sev zv pv chi2 rank pval posdef eff mineig
    local names `b1' `V1' `b2' `V2' `sig1' `sig2' `bA' `bB' `dif' `Vd' ///
                `sev' `zv' `pv' `chi2' `rank' `pval' `posdef' `eff' `mineig'
    local noauto 0
    local contra 0
    local nneg   0
    mata: _biastest_work("`names'", "`indepvars'", `efficient', "`scaling'", "`Vbname'")

    local suppress 0
    if !`boot' {
        if `noauto' {
            di as error "the covariance matrix of the compared coefficients is singular in at least"
            di as error "one model, so the efficient model cannot be chosen automatically;"
            di as error "specify {bf:efficient(1)} or {bf:efficient(2)}"
            exit 498
        }
        local effm  = `eff'
        local consm = 3 - `effm'
        if `efficient' == 0 {
            local effhow "chosen automatically: smaller log-determinant of V for the compared coefficients"
        }
        else local effhow "set by option efficient()"
        // with an automatic choice and an indefinite contrast the sign of
        // chi2 is arbitrary (pinv(-A) = -pinv(A)): joint p-value not reported.
        // (If V(cons) - V(eff) is PSD, even singular, the log-det rule is right.)
        local suppress = (`efficient' == 0 & `nneg' > 0)
        if `suppress' scalar `pval' = .
        local vlabel "V(cons) - V(eff)"
    }
    else local vlabel "the bootstrap variance"

    // ------------------------------------------------------------------
    // 6. Individual bias tests
    // ------------------------------------------------------------------
    di as text _n "{bf:Variable bias test}   H0: the coefficient is equal in both models"
    di as text "{hline 13}{c TT}{hline 62}"
    di as text %12s "Variable" " {c |}" %11s "Model 1" %11s "Model 2" ///
        %11s "Diff (1-2)" %11s "Std. Err." %9s "z" %9s "P>|z|"
    di as text "{hline 13}{c +}{hline 62}"
    local j 0
    local nmiss 0
    foreach v of local common {
        local ++j
        di as text %12s abbrev("`v'", 12) " {c |}" as result    ///
            "  " %9.0g el(`bA', 1, `j')  "  " %9.0g el(`bB', 1, `j') ///
            "  " %9.0g el(`dif', 1, `j') "  " %9.0g el(`sev', 1, `j') ///
            "  " %7.3f el(`zv', 1, `j')  "  " %7.3f el(`pv', 1, `j')
        if missing(el(`sev', 1, `j')) local ++nmiss
    }
    di as text "{hline 13}{c BT}{hline 62}"
    if "`excluded'" != "" {
        di as text "{p 0 4 2}Not compared (omitted, or not estimated in both models): `excluded'{p_end}"
    }
    if `nmiss' > 0 {
        di as text "{p 0 4 2}Std. Err. missing: `vlabel' has a nonpositive diagonal" ///
            " element for `nmiss' coefficient(s).{p_end}"
    }
    if `kk' > 1 {
        di as text "{p 0 4 2}The individual z tests are correlated and not adjusted for" ///
            " multiple testing; base the overall conclusion on the joint test.{p_end}"
    }

    // ------------------------------------------------------------------
    // 7. Joint bias test
    // ------------------------------------------------------------------
    di as text _n "{bf:Joint bias test}   H0: all compared coefficients are equal"
    di as text "{hline 44}"
    di as text "  chi2(" as result `rank' as text ")" _col(20) "= " as result %10.3f `chi2'
    di as text "  Prob > chi2" _col(20) "= " as result %10.4f `pval'
    di as text "{hline 44}"

    di as text _n "Notes:"
    if `boot' {
        di as text "{p 2 4 2}- Var(b1 - b2) is the covariance of b1* - b2* over `nboot'" ///
            " bootstrap replications (resampling `unit'; `nfail' failed). No" ///
            " efficiency assumption is required.{p_end}"
    }
    else {
        di as text "{p 2 4 2}- Model `effm' (`cmd`effm'') is treated as efficient under H0" ///
            " (`effhow').  Var(b1 - b2) = V(Model `consm') - V(Model `effm').{p_end}"
    }
    if `contra' {
        di as error "{p 2 4 2}- Warning: the model declared efficient has the larger" ///
            " generalized variance (log-determinant of V) in this sample, which" ///
            " contradicts the efficiency assumption.{p_end}"
    }
    if `posdef' == 0 & `nneg' == 0 {
        di as text "{p 2 4 2}- `vlabel' is singular (rank `=`rank'' of `kk');" ///
            " a generalized inverse is used and df = rank.{p_end}"
    }
    if `nneg' > 0 {
        local me : display %10.3g `mineig'
        local me = trim("`me'")
        di as text "{p 2 4 2}- `vlabel' is not positive semidefinite (`nneg' negative" ///
            " eigenvalue(s); smallest eigenvalue on the correlation scale =" ///
            " `me'). A generalized inverse is used and df = rank. Interpret with" ///
            " caution; consider sigmamore/sigmaless (linear models) or option" ///
            " bootstrap.{p_end}"
    }
    if `suppress' {
        di as error "{p 2 4 2}- Warning: efficient() was not specified and V(cons) - V(eff) has" ///
            " negative eigenvalues, so the sign of chi2 depends on the automatic choice;" ///
            " the joint p-value is not reported and the individual tests are conditional" ///
            " on that choice. Specify efficient(1) or efficient(2).{p_end}"
    }
    if `chi2' < 0 {
        di as text "{p 2 4 2}- chi2 < 0: the data fail to meet the assumptions of the" ///
            " Hausman test (different variance estimates enter the two matrices, or the" ///
            " efficient model is misspecified). Consider sigmamore/sigmaless (linear" ///
            " models) or option bootstrap.{p_end}"
    }
    if "`scaling'" != "" {
        local s1s : display %9.0g `sig1'
        local s2s : display %9.0g `sig2'
        local s1s = trim("`s1s'")
        local s2s = trim("`s2s'")
    }
    if "`sigmaless'" != "" {
        local fac : display %9.4f (`sig`consm''/`sig`effm'')^2
        local fac = trim("`fac'")
        di as text "{p 2 4 2}- sigmaless: V(Model `effm') rescaled by (s`consm'/s`effm')^2 =" ///
            " `fac' (s1 = `s1s', s2 = `s2s').{p_end}"
    }
    if "`sigmamore'" != "" {
        local fac : display %9.4f (`sig`effm''/`sig`consm'')^2
        local fac = trim("`fac'")
        di as text "{p 2 4 2}- sigmamore: V(Model `consm') rescaled by (s`effm'/s`consm')^2 =" ///
            " `fac' (s1 = `s1s', s2 = `s2s').{p_end}"
    }

    // ------------------------------------------------------------------
    // 8. Stored results
    // ------------------------------------------------------------------
    quietly generate byte `esmp' = `smp1' & `smp2'
    quietly count if `esmp'
    local Nboth = r(N)
    ereturn post, esample(`esmp')
    ereturn scalar N         = `Nboth'
    ereturn scalar N1        = `N1'
    ereturn scalar N2        = `N2'
    ereturn scalar chi2      = `chi2'
    ereturn scalar df        = `rank'
    ereturn scalar p         = `pval'
    ereturn scalar posdef    = `posdef'
    ereturn scalar nneg      = `nneg'
    if !`boot' ereturn scalar efficient = `effm'
    else {
        ereturn scalar reps   = `nboot'
        ereturn scalar N_fail = `nfail'
    }
    if !missing(`sig1') ereturn scalar s2_1 = `sig1'
    if !missing(`sig2') ereturn scalar s2_2 = `sig2'
    ereturn matrix b_m1     = `b1'
    ereturn matrix b_m2     = `b2'
    ereturn matrix V_m1     = `V1'
    ereturn matrix V_m2     = `V2'
    ereturn matrix diffs    = `dif'
    ereturn matrix ses      = `sev'
    ereturn matrix z_stats  = `zv'
    ereturn matrix p_values = `pv'
    ereturn matrix V_diff   = `Vd'
    ereturn local m1        `"`m1'"'
    ereturn local m1ops     `"`m1ops'"'
    ereturn local m2        `"`m2'"'
    ereturn local m2ops     `"`m2ops'"'
    ereturn local depvar    "`depvar'"
    ereturn local indepvars "`indepvars'"
    ereturn local common    "`common'"
    ereturn local excluded  "`excluded'"
    if `boot' {
        ereturn local vcetype "Bootstrap"
        ereturn local cluster "`clvar'"
    }
    else {
        ereturn local vcetype          "Hausman"
        ereturn local efficient_model  "Model `effm'"
        ereturn local consistent_model "Model `consm'"
        ereturn local effcrit          "`effhow'"
    }
    if "`sigmaless'" != "" ereturn local sigmaless "adjusted"
    if "`sigmamore'" != "" ereturn local sigmamore "adjusted"
    ereturn local title "Hausman-type bias test"
    ereturn local cmd   "biastest"
end


version 14.0
mata:
mata set matastrict on

real scalar _biastest_find(string matrix cs, string scalar eq, string scalar v)
{
    real vector idx

    idx = selectindex((cs[., 2] :== v) :& (cs[., 1] :== eq))
    if (length(idx) == 0) return(.)
    return(idx[1])
}

real scalar _biastest_logdet(real matrix V)
{
    real rowvector lam

    lam = symeigenvalues((V + V') / 2)
    if (hasmissing(lam)) return(.)
    if (min(lam) <= 0)   return(.)
    return(sum(ln(lam)))
}

// match coefficients by name in the first equation; drop omitted terms
void _biastest_matchidx(string scalar b1n, string scalar V1n,
                        string scalar b2n, string scalar V2n,
                        string rowvector vars,
                        real rowvector i1, real rowvector i2,
                        string rowvector common, string rowvector excluded)
{
    string matrix cs1, cs2
    string scalar eq1, eq2
    real matrix   V1, V2
    real scalar   j, j1, j2

    V1  = st_matrix(V1n)
    V2  = st_matrix(V2n)
    cs1 = st_matrixcolstripe(b1n)
    cs2 = st_matrixcolstripe(b2n)
    eq1 = cs1[1, 1]
    eq2 = cs2[1, 1]
    i1 = J(1, 0, .)
    i2 = J(1, 0, .)
    common   = J(1, 0, "")
    excluded = J(1, 0, "")
    for (j = 1; j <= cols(vars); j++) {
        j1 = _biastest_find(cs1, eq1, vars[j])
        j2 = _biastest_find(cs2, eq2, vars[j])
        if (j1 < . & j2 < .) {
            if (V1[j1, j1] > 0 & V1[j1, j1] < . & V2[j2, j2] > 0 & V2[j2, j2] < .) {
                i1 = i1, j1
                i2 = i2, j2
                common = common, vars[j]
                continue
            }
        }
        excluded = excluded, vars[j]
    }
}

void _biastest_common(string scalar b1n, string scalar V1n,
                      string scalar b2n, string scalar V2n, string scalar varlist)
{
    real rowvector   i1, i2
    string rowvector common, excluded

    i1 = J(1, 0, .)
    i2 = J(1, 0, .)
    common   = J(1, 0, "")
    excluded = J(1, 0, "")
    _biastest_matchidx(b1n, V1n, b2n, V2n, tokens(varlist), i1, i2, common, excluded)
    st_local("kk", strofreal(cols(common)))
    st_local("common", invtokens(common))
    st_local("excluded", invtokens(excluded))
}

// append b1* - b2* of one bootstrap replication; 0 if a term is missing
real scalar _biastest_bsappend(string scalar Dn,
                               string scalar b1n, string scalar V1n,
                               string scalar b2n, string scalar V2n,
                               string scalar varlist)
{
    pointer() scalar p
    real rowvector   i1, i2, b1, b2, d
    string rowvector vars, common, excluded

    vars = tokens(varlist)
    i1 = J(1, 0, .)
    i2 = J(1, 0, .)
    common   = J(1, 0, "")
    excluded = J(1, 0, "")
    _biastest_matchidx(b1n, V1n, b2n, V2n, vars, i1, i2, common, excluded)
    if (cols(common) != cols(vars)) return(0)
    b1 = st_matrix(b1n)
    b2 = st_matrix(b2n)
    d  = b1[i1] - b2[i2]
    if (hasmissing(d)) return(0)
    p = findexternal(Dn)
    if (p == NULL) p = crexternal(Dn)
    if (rows(*p) == 0) *p = d
    else               *p = (*p) \ d
    return(1)
}

// bootstrap covariance of b1* - b2*
void _biastest_bsvar(string scalar Dn, string scalar Vn, string scalar varlist)
{
    pointer() scalar p
    real matrix      D, V
    string rowvector vars
    string matrix    stripe

    p = findexternal(Dn)
    if (p == NULL) {
        st_local("nboot", "0")
        return
    }
    D = *p
    rmexternal(Dn)
    st_local("nboot", strofreal(rows(D)))
    if (rows(D) < 2) return
    V = variance(D)
    vars   = tokens(varlist)
    stripe = (J(cols(vars), 1, ""), vars')
    st_matrix(Vn, V)
    st_matrixcolstripe(Vn, stripe)
    st_matrixrowstripe(Vn, stripe)
}

void _biastest_work(string scalar names, string scalar varlist,
                    real scalar effopt, string scalar scaling,
                    string scalar bootname)
{
    string rowvector nm, common, excluded
    string matrix    stripe
    real rowvector   b1, b2, i1, i2, bb1, bb2, d, dv, se, z, p, lam, sd, ds
    real vector      keep
    real matrix      V1, V2, VV1, VV2, Vc, Ve, Vd, Vds, X
    real scalar      j, kk, ld1, ld2, eff, s1, s2, sc, sf
    real scalar      rk, H, pH, tol, posdef, contra, nneg

    nm = tokens(names)
    i1 = J(1, 0, .)
    i2 = J(1, 0, .)
    common   = J(1, 0, "")
    excluded = J(1, 0, "")
    _biastest_matchidx(nm[1], nm[2], nm[3], nm[4], tokens(varlist),
                       i1, i2, common, excluded)
    kk = cols(common)
    st_local("kk", strofreal(kk))
    st_local("common", invtokens(common))
    st_local("excluded", invtokens(excluded))
    if (kk == 0) return

    b1  = st_matrix(nm[1])
    V1  = st_matrix(nm[2])
    b2  = st_matrix(nm[3])
    V2  = st_matrix(nm[4])
    s1  = st_numscalar(nm[5])
    s2  = st_numscalar(nm[6])
    bb1 = b1[i1]
    bb2 = b2[i2]
    VV1 = V1[i1, i1]
    VV2 = V2[i2, i2]
    d   = bb1 - bb2
    contra = 0

    if (bootname != "") {
        // ---- bootstrap covariance of b1* - b2*: no efficiency assumption
        Vd  = st_matrix(bootname)
        Vd  = (Vd + Vd') / 2
        sd  = sqrt(diagonal(Vd))'
        eff = 0
    }
    else {
        // ---- efficient model: declared, or the smaller generalized variance.
        //      log-det is unit free; if V_c - V_e is PSD it always picks e.
        ld1 = _biastest_logdet(VV1)
        ld2 = _biastest_logdet(VV2)
        if (effopt == 0) {
            if (ld1 >= . | ld2 >= .) {
                st_local("noauto", "1")
                return
            }
            eff = (ld1 < ld2 ? 1 : 2)
        }
        else {
            eff    = effopt
            contra = (ld1 < . & ld2 < . & (eff == 1 ? ld1 > ld2 : ld2 > ld1))
        }
        if (eff == 1) {
            Ve = VV1
            Vc = VV2
            sf = s1
            sc = s2
        }
        else {
            Ve = VV2
            Vc = VV1
            sf = s2
            sc = s1
        }
        // sigmaless: both V's use the consistent estimator's sigma
        // sigmamore: both V's use the efficient estimator's sigma
        if (scaling == "sigmaless") Ve = (sc / sf)^2 * Ve
        if (scaling == "sigmamore") Vc = (sf / sc)^2 * Vc
        Vd = Vc - Ve
        Vd = (Vd + Vd') / 2
        sd = sqrt(diagonal(Vc))'
    }

    // ---- individual tests: z = d_j / sqrt(Vd_jj), asymptotically N(0,1)
    dv = diagonal(Vd)'
    se = J(1, kk, .)
    for (j = 1; j <= kk; j++) {
        if (dv[j] > 0 & dv[j] < .) se[j] = sqrt(dv[j])
    }
    z = d :/ se
    p = 2 :* normal(-abs(z))

    // ---- joint test: H = d' Vd^- d ~ chi2(rank(Vd)).
    //      Rank and definiteness are decided on a correlation scale
    //      (of Vc, or of the bootstrap variance), so they do not depend on
    //      the units of the regressors; the tolerance is well above the
    //      rounding error of Vc - Ve.
    for (j = 1; j <= kk; j++) {
        if (!(sd[j] > 0 & sd[j] < .)) sd[j] = 1
    }
    Vds = Vd :/ (sd' * sd)
    Vds = (Vds + Vds') / 2
    ds  = d :/ sd
    X   = .
    lam = .
    symeigensystem(Vds, X, lam)
    tol    = 1e-10
    keep   = selectindex(abs(lam) :> tol)
    rk     = length(keep)
    posdef = (min(lam) > tol)
    nneg   = sum(lam :< -tol)
    if (rk > 0) H = sum(((ds * X[., keep]) :^ 2) :/ lam[keep])
    else        H = 0
    if (H < 0 & abs(H) < 1e-10 * max((1, ds * ds'))) H = 0
    pH = ((H >= 0 & H < . & rk > 0) ? chi2tail(rk, H) : .)

    // ---- return
    stripe = (J(kk, 1, ""), common')
    st_matrix(nm[7],  bb1)
    st_matrixcolstripe(nm[7],  stripe)
    st_matrix(nm[8],  bb2)
    st_matrixcolstripe(nm[8],  stripe)
    st_matrix(nm[9],  d)
    st_matrixcolstripe(nm[9],  stripe)
    st_matrix(nm[10], Vd)
    st_matrixcolstripe(nm[10], stripe)
    st_matrixrowstripe(nm[10], stripe)
    st_matrix(nm[11], se)
    st_matrixcolstripe(nm[11], stripe)
    st_matrix(nm[12], z)
    st_matrixcolstripe(nm[12], stripe)
    st_matrix(nm[13], p)
    st_matrixcolstripe(nm[13], stripe)
    st_numscalar(nm[14], H)
    st_numscalar(nm[15], rk)
    st_numscalar(nm[16], pH)
    st_numscalar(nm[17], posdef)
    st_numscalar(nm[18], eff)
    st_numscalar(nm[19], min(lam))
    st_local("contra", strofreal(contra))
    st_local("nneg", strofreal(nneg))
}

end
