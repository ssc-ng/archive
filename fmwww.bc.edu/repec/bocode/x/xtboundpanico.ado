*! xtboundpanico 1.0.0  27oct2026
* Bounds and PANICO testing for cointegration in panels with common factors
* Banerjee, A. and Carrion-i-Silvestre, J. L. (2026), University of Canterbury WP 8/2026
* Author: Dr Merwan Roudane
* merwanroudane920@gmail.com
* https://github.com/merwanroudane
*
* Step -> equation map (full version in: help xtboundpanico methods)
*   step 1  cross-section averages hbar_t                        eq. (1), Assumption G
*   step 2  pooled CCE estimator betahat_x                       eq. (13)
*   step 3  yhat_it = thetahat' Y_it                             eq. (14)
*   step 4  conditional ECM, t-ratio of rho_yi                   eq. (15)-(17)
*   step 5  panel bounds statistic tybar = N^-1 sum t_rhoyi      Section 3
*   step 6  polar critical values I(0) / I(1)                    Corollary 1, Tables C.1-C.2
*   step 7  CADF / CIPS comparator                               eq. (18)
*   step 8  PANICO: defactor D.yhat, recumulate                  eq. (19)-(21)
*   step 9  per-unit ADF on uhat*, pooled P, Pm, Z               eq. (22), Theorem 2
*   step 10 pooled Pa, Pb, PMSB                                  Bai-Ng (2010) eq. (6)-(11)
*   step 11 ADF / MQc / MQf on Fhat                              Bai-Ng (2004) Thm 1, 3
*   step 12 PANICCA variant: CA factors replace PC factors       Section 4, Reese-Westerlund
*   var(betahat) sandwich                                        Holly-Pesaran-Yamagata (2010) eq. (3.12)-(3.13)
*   factor number: ICp/PCp/AIC3/BIC3                             Bai-Ng (2002)
*                  ER / GR                                       Ahn-Horenstein (2013) Sec. 2, eq. (4)
*                  ED                                            Onatski (2010) Sec. IV algorithm
*                  RW                                            Reese-Westerlund (2016) p. 10

program define xtboundpanico, rclass
    version 14.0

    if ("`0'" == "") {
        di as error "nothing to do"
        di as text  "{p 4 4 2}syntax: {bf:xtboundpanico} {it:subcommand} {it:depvar}" ///
            " {it:indepvars} [{it:if}] [{it:in}] [, {it:options}]{p_end}"
        di as text  "{p 4 4 2}subcommands: {bf:bounds}, {bf:panico}, {bf:panicca}," ///
            " {bf:nfactors}, {bf:all}.  See {bf:help xtboundpanico}.{p_end}"
        exit 198
    }

    gettoken sub rest : 0, parse(" ,")

    * the internal xbpmeth() option joins whatever option list the user typed,
    * so a comma is added only when there is not one already
    local cma ""
    if (strpos(`"`rest'"', ",") == 0) local cma ","

    if ("`sub'" == substr("bounds", 1, max(2, length("`sub'")))) {
        _xbp_bounds `rest'
    }
    else if ("`sub'" == substr("panicca", 1, max(7, length("`sub'")))) {
        _xbp_panic `rest' `cma' xbpmeth(ca)
    }
    else if ("`sub'" == substr("panico", 1, max(6, length("`sub'")))) {
        _xbp_panic `rest' `cma' xbpmeth(pc)
    }
    else if ("`sub'" == substr("nfactors", 1, max(2, length("`sub'")))) {
        _xbp_nfac `rest'
    }
    else if ("`sub'" == substr("all", 1, max(2, length("`sub'")))) {
        _xbp_all `rest'
    }
    else {
        di as error "invalid subcommand: `sub'"
        di as text  "{p 4 4 2}valid subcommands are {bf:bounds}, {bf:panico}," ///
            " {bf:panicca}, {bf:nfactors} and {bf:all}.{p_end}"
        exit 198
    }

    return add
end


*------------------------------------------------------------------------------
* shared validation.  Returns descriptors only -- never tempvars, which would
* be dropped the moment this program returns.
*------------------------------------------------------------------------------
program define _xbp_prep, rclass
    version 14.0
    syntax varlist(min=1 numeric) [if] [in] , Touse(varname)

    qui xtset
    local ivar  "`r(panelvar)'"
    local tvar  "`r(timevar)'"
    local delta = 1
    capture confirm number `r(tdelta)'
    if (_rc == 0) local delta = `r(tdelta)'

    if ("`ivar'" == "") {
        di as error "data are not {bf:xtset}"
        di as text  "{p 4 4 2}run {bf:xtset} {it:panelvar} {it:timevar} first.{p_end}"
        exit 459
    }
    if ("`tvar'" == "") {
        di as error "no time variable declared in {bf:xtset}"
        di as text  "{p 4 4 2}every statistic in this command is a time-series test," ///
            " so a time variable is required.{p_end}"
        exit 459
    }
    if (`delta' <= 0) local delta = 1

    qui levelsof `ivar' if `touse', local(ids)
    local N : word count `ids'
    qui levelsof `tvar' if `touse', local(tms)
    local T : word count `tms'
    qui count if `touse'
    local nobs = r(N)

    if (`N' < 2) {
        di as error "need at least 2 panel units in the estimation sample"
        exit 2001
    }
    if (`nobs' != `N' * `T') {
        di as error "the estimation sample is not a balanced panel"
        di as text  "{p 4 4 2}found `nobs' observations for `N' units and `T' periods"  ///
            " (`=`N'*`T'' are needed).  The cross-section averages and the principal"   ///
            " components both require a strongly balanced panel with no gaps and no"    ///
            " missing values on any model variable.  Use {bf:xtdescribe} and"           ///
            " {bf:misstable patterns} to locate the offending units.{p_end}"
        exit 2001
    }

    qui su `tvar' if `touse', meanonly
    local timp = (r(max) - r(min)) / `delta' + 1
    if (abs(`timp' - `T') > 1e-6) {
        di as error "the time dimension has gaps"
        di as text  "{p 4 4 2}`T' distinct periods span `timp' slots between" ///
            " `r(min)' and `r(max)'.  Fill or trim the panel before testing.{p_end}"
        exit 2001
    }

    return local panelvar "`ivar'"
    return local timevar  "`tvar'"
    return scalar N = `N'
    return scalar T = `T'
end


*------------------------------------------------------------------------------
* bounds testing (Section 3)
*------------------------------------------------------------------------------
program define _xbp_bounds, rclass
    version 14.0
    syntax varlist(min=2 numeric) [if] [in] [,          ///
        MODel(integer 1)                                ///
        FACtors(integer -1)                             ///
        LAGs(integer -1)                                ///
        MAXLags(integer -1)                             ///
        LAGCrit(string)                                 ///
        CVMethod(string)                                ///
        LEVel(cilevel)                                  ///
        DFPaper                                         ///
        DFFull                                          ///
        NOCips                                          ///
        GRAPH                                           ///
        NAME(string) ]

    marksample touse
    gettoken dv ivars : varlist
    local k : word count `ivars'

    _xbp_prep `varlist' `if' `in' , touse(`touse')
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    local N = r(N)
    local T = r(T)

    _xbp_chkmodel `model'
    if (`factors' == -1) local factors = 1 + `k'
    _xbp_chkfac `factors' `k'
    local lagcrit = lower(trim("`lagcrit'"))
    if ("`lagcrit'" == "") local lagcrit "bic"
    _xbp_chklagcrit "`lagcrit'"
    local cvmethod = lower(trim("`cvmethod'"))
    if ("`cvmethod'" == "") local cvmethod "surface"
    if (!inlist("`cvmethod'", "surface", "asymptotic")) {
        di as error "cvmethod() must be {bf:surface} or {bf:asymptotic}"
        exit 198
    }
    if (`maxlags' == -1) local maxlags = floor(4 * (`T'/100)^0.25)
    if (`maxlags' < 1) local maxlags = 1
    local fixlag = 0
    if (`lags' != -1) {
        if (`lags' < 1) {
            di as error "lags() must be 1 or more"
            di as text "{p 4 4 2}lags() is the VAR order p_i of equation (7), so the" ///
                " error-correction model carries p_i-1 lagged differences.{p_end}"
            exit 198
        }
        local maxlags = `lags'
        local fixlag  = 1
    }

    * minimum T for the Case-5 design matrix
    local need = `maxlags' + 2 + `factors' + (1+`k')*(`maxlags'-1) + `factors'*`maxlags' + `k' + 2
    if (`T' < `need') {
        di as error "too few time periods"
        di as text "{p 4 4 2}equation (15) with p_max = `maxlags', k = `k' and"           ///
            " r = `factors' needs about `need' periods; the sample has `T'.  Reduce"      ///
            " {bf:maxlags()} or {bf:factors()}, or use a longer panel.{p_end}"
        exit 2001
    }

    * Degrees of freedom for omegahat_{i,xi xi} in eq. (17).  The default is the
    * ordinary OLS df (effective rows minus the actual number of estimated
    * parameters); it reproduces the empirical size of the paper's Table C.3,
    * whereas the literal full-T readings of eq. (17) inflate the statistic and
    * roughly double the size at T = 50.  See: help xtboundpanico methods.
    local dfmode = 2
    if ("`dffull'" != "")  local dfmode = 0
    if ("`dfpaper'" != "") local dfmode = 1
    if ("`dffull'" != "" & "`dfpaper'" != "") {
        di as error "dffull and dfpaper cannot be combined"
        exit 198
    }

    sort `ivar' `tvar'

    tempname TI LAGSI CVS BCCE BVCE DROPPED TCIPS
    mata: _xbp_run_bounds("`dv' `ivars'", "`touse'", `N', `T', `k', `model',    ///
        `factors', `maxlags', `fixlag', "`lagcrit'", `dfmode',                  ///
        ("`nocips'" == ""), "`TI'", "`LAGSI'", "`BCCE'", "`BVCE'",              ///
        "`DROPPED'", "`TCIPS'")

    local nused = rowsof(`TI')
    local ndrop = `N' - `nused'
    tempname tybar cips
    mata: st_numscalar("`tybar'", mean(st_matrix("`TI'")))
    if ("`nocips'" == "") {
        mata: st_numscalar("`cips'", _xbp_meannm(st_matrix("`TCIPS'")))
    }

    mata: _xbp_cvtable(`model', `factors', `k', `T', `nused', "`cvmethod'", "`CVS'")

    *--- display -------------------------------------------------------------
    local mdesc "constant"
    if (`model' == 0) local mdesc "none"
    if (`model' == 2) local mdesc "constant and linear trend"

    di ""
    di as text "Panel cointegration bounds test with common factors"           ///
        _col(58) "Units      = " as result %8.0f `nused'
    di as text "Banerjee and Carrion-i-Silvestre (2026), Section 3"            ///
        _col(58) as text "Periods    = " as result %8.0f `T'
    di as text "H0: panel spurious relationship  (rho_yi = 0 for all i)"       ///
        _col(58) as text "Regressors = " as result %8.0f `k'
    di as text "H1: panel cointegration          (rho_yi < 0)"                 ///
        _col(58) as text "Factors r  = " as result %8.0f `factors'
    di as text "Deterministics: `mdesc'"                                       ///
        _col(58) as text "Max p_i    = " as result %8.0f `maxlags'
    di ""
    _xbp_cce_table `BCCE' `BVCE' "`ivars'"

    di ""
    di as text "{hline 79}"
    di as text "Panel bounds statistic" _col(44) "Lower bound" _col(62) "Upper bound"
    di as text                          _col(44) "all F_t I(0)" _col(62) "all F_t I(1)"
    di as text "{hline 79}"
    di as text %-32s "tybar = N^-1 sum t_rho_yi" _col(34) as result %10.4f scalar(`tybar')
    di as text "{hline 79}"
    forvalues q = 1/4 {
        local plab : word `q' of "1%" "2.5%" "5%" "10%"
        di as text %-32s "critical value, `plab'" _col(44) as result %11.4f `CVS'[`q',1] ///
            _col(62) %11.4f `CVS'[`q',2]
    }
    di as text "{hline 79}"

    local alpha = (100 - `level')/100
    local qrow = 3
    if (abs(`alpha'-0.01)  < 1e-8) local qrow = 1
    if (abs(`alpha'-0.025) < 1e-8) local qrow = 2
    if (abs(`alpha'-0.10)  < 1e-8) local qrow = 4
    local cvlo = `CVS'[`qrow',2]
    local cvup = `CVS'[`qrow',1]
    local alab : word `qrow' of "1%" "2.5%" "5%" "10%"
    if (scalar(`tybar') < `cvlo')      local decis "COINTEGRATION"
    else if (scalar(`tybar') > `cvup') local decis "NO COINTEGRATION (spurious)"
    else                               local decis "INCONCLUSIVE"

    di as text "Bounds decision at the `alab' level: " as result "`decis'"
    if ("`decis'" == "COINTEGRATION") {
        di as text "{p 4 4 2}tybar lies below the I(1) bound, so the null of a panel"    ///
            " spurious relationship is rejected whatever the number and order of"        ///
            " integration of the unobserved common factors.{p_end}"
    }
    else if ("`decis'" == "NO COINTEGRATION (spurious)") {
        di as text "{p 4 4 2}tybar lies above the I(0) bound, so the null is not"        ///
            " rejected whatever the number and order of integration of the common"       ///
            " factors.{p_end}"
    }
    else {
        di as text "{p 4 4 2}tybar falls inside the ambiguity region, so the conclusion" ///
            " depends on how many common factors are I(1).  Resolve it with"             ///
            " {bf:xtboundpanico panico} (compare Pesaran, Shin and Smith 2001, pp. 290"  ///
            " and 299).{p_end}"
    }

    if ("`nocips'" == "") {
        di ""
        di as text "{hline 79}"
        di as text "Comparator: CIPS-type panel cointegration statistic (eq. 18)"
        di as text "{hline 79}"
        di as text %-32s "CIPS = N^-1 sum t_i,0" _col(34) as result %10.4f scalar(`cips')
        di as text "{hline 79}"
        di as text "{p 4 4 2}Banerjee and Carrion-i-Silvestre (2017).  Their critical"    ///
            " values are not tabulated by this package; take them from their Tables 1-3," ///
            " or from Pesaran, Smith and Yamagata (2013) with the rank condition met"     ///
            " with equality.{p_end}"
    }

    if (`ndrop' > 0) {
        di ""
        di as text "{p 4 4 2}Note: `ndrop' unit(s) dropped from the panel average"  ///
            " because the individual regression was singular or degenerate.  Their"  ///
            " positions are in {bf:r(dropped)}.{p_end}"
    }
    if ("`cvmethod'" == "surface") {
        local outside 0
        if (`factors' < 1 | `factors' > 6)  local outside 1
        if (`k' > 5)                        local outside 1
        if (`T' < 50 | `T' > 200)           local outside 1
        if (`nused' < 20 | `nused' > 60)    local outside 1
        if (`outside') {
            di as text "{p 4 4 2}Note: the response surfaces of Table C.2 were fitted"  ///
                " on r in 1..6, k in 0..5 with r <= k+1, T in {50,100,200} and N in"    ///
                " {20,40,60}.  Here (r,k,T,N) = (`factors',`k',`T',`nused'), outside"   ///
                " that box, so the critical values above are extrapolations.  Consider" ///
                " {bf:cvmethod(asymptotic)} as a cross-check.{p_end}"
        }
    }

    *--- graph (before any return matrix move) -------------------------------
    if ("`graph'" != "") {
        if ("`name'" == "") local name "xbp_bounds"
        local g0 = `CVS'[`qrow',1]
        local g1 = `CVS'[`qrow',2]
        local gt = scalar(`tybar')
        preserve
            clear
            qui set obs `nused'
            qui svmat double `TI', name(ti)
            qui gen int unit = _n
            twoway (scatter ti1 unit, msymbol(O) mcolor(navy) msize(small))        ///
                   (function y = `g0', range(1 `nused') lpattern(dash)             ///
                        lcolor(cranberry))                                         ///
                   (function y = `g1', range(1 `nused') lpattern(dash)             ///
                        lcolor(forest_green))                                      ///
                   (function y = `gt', range(1 `nused') lpattern(solid)            ///
                        lcolor(black)),                                            ///
                graphregion(color(white)) plotregion(color(white))                 ///
                legend(order(1 "t_rho_yi" 2 "`alab' bound, I(0)"                   ///
                             3 "`alab' bound, I(1)" 4 "tybar") rows(2)             ///
                       position(6) ring(1) size(small)                             ///
                       region(lstyle(none)))                                       ///
                ytitle("t-ratio of rho_yi") xtitle("panel unit")                   ///
                title("Panel cointegration bounds test", size(medium))             ///
                subtitle("ambiguity region lies between the dashed lines",         ///
                         size(small))                                              ///
                name(`name', replace) nodraw
        restore
        graph display `name'
    }

    *--- return --------------------------------------------------------------
    return local cmd       "xtboundpanico"
    return local subcmd    "bounds"
    return local depvar    "`dv'"
    return local indepvars "`ivars'"
    return local panelvar  "`ivar'"
    return local timevar   "`tvar'"
    return local lagcrit   "`lagcrit'"
    return local cvmethod  "`cvmethod'"
    return local decision  "`decis'"
    return scalar N       = `nused'
    return scalar N_full  = `N'
    return scalar T       = `T'
    return scalar k       = `k'
    return scalar r       = `factors'
    return scalar model   = `model'
    return scalar maxlags = `maxlags'
    return scalar level   = `level'
    return scalar tybar   = scalar(`tybar')
    return scalar cv_i0   = `CVS'[`qrow',1]
    return scalar cv_i1   = `CVS'[`qrow',2]
    if ("`nocips'" == "") {
        return scalar cips = scalar(`cips')
        return matrix t_cips = `TCIPS'
    }
    if (`ndrop' > 0) {
        return matrix dropped = `DROPPED'
    }
    return matrix cv      = `CVS'
    return matrix lags_i  = `LAGSI'
    return matrix t_i     = `TI'
    return matrix V_cce   = `BVCE'
    return matrix b_cce   = `BCCE'
end


*------------------------------------------------------------------------------
* PANICO (PC factors) and PANICCA (CA factors)
*------------------------------------------------------------------------------
program define _xbp_panic, rclass
    version 14.0
    syntax varlist(min=2 numeric) [if] [in] [,          ///
        XBPMeth(string)                                 ///
        MODel(integer 1)                                ///
        FACtors(integer -1)                             ///
        RMAX(integer -1)                                ///
        NFACtors(string)                                ///
        MAXLags(integer -1)                             ///
        LAGs(integer -1)                                ///
        LAGCrit(string)                                 ///
        NWBw(integer -1)                                ///
        LEVel(cilevel)                                  ///
        SAVEComp(name)                                  ///
        GRAPH                                           ///
        NAME(string) ]

    marksample touse
    gettoken dv ivars : varlist
    local k : word count `ivars'

    _xbp_prep `varlist' `if' `in' , touse(`touse')
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    local N = r(N)
    local T = r(T)

    _xbp_chkmodel `model'
    local meth "`xbpmeth'"
    if ("`meth'" == "") local meth "pc"
    local mname "PANICO"
    if ("`meth'" == "ca") local mname "PANICO on cross-section averages (PANICCA)"

    local lagcrit = lower(trim("`lagcrit'"))
    if ("`lagcrit'" == "") local lagcrit "bic"
    _xbp_chklagcrit "`lagcrit'"
    if (`maxlags' == -1) local maxlags = floor(4 * (`T'/100)^0.25)
    if (`maxlags' < 0) local maxlags = 0
    local fixlag = 0
    if (`lags' != -1) {
        if (`lags' < 0) {
            di as error "lags() must be 0 or more"
            exit 198
        }
        local maxlags = `lags'
        local fixlag  = 1
    }
    if (`T' < `maxlags' + 6) {
        di as error "too few time periods for the ADF regressions"
        di as text "{p 4 4 2}with maxlags(`maxlags') at least `=`maxlags'+6' periods"  ///
            " are needed; the sample has `T'.{p_end}"
        exit 2001
    }

    local nfactors = lower(trim("`nfactors'"))
    if ("`nfactors'" == "") {
        if ("`meth'" == "ca") local nfactors "rw"
        else                  local nfactors "icp1"
    }
    _xbp_chknf "`nfactors'" "`meth'"

    if (`rmax' == -1) {
        if ("`meth'" == "ca") local rmax = 1 + `k'
        else                  local rmax = 5
    }
    if ("`meth'" == "ca" & `rmax' > 1 + `k') {
        di as text "{p 4 4 2}Note: rmax() reduced to 1+k = `=1+`k'' -- only 1+k" ///
            " cross-section averages exist.{p_end}"
        local rmax = 1 + `k'
    }
    if (`rmax' < 1)   local rmax = 1
    if (`rmax' > `N') local rmax = `N'
    if (`factors' != -1) {
        if (`factors' < 1) {
            di as error "factors() must be 1 or more"
            exit 198
        }
        if ("`meth'" == "ca" & `factors' > 1 + `k') {
            di as error "factors() cannot exceed 1+k = `=1+`k'' with {bf:panicca}"
            exit 198
        }
    }

    sort `ivar' `tvar'

    tempname ICT IDIOS GRP ADFI PVI LAGSI MQC MQF ADFF FHAT BCCE BVCE RHAT
    mata: _xbp_run_panic("`dv' `ivars'", "`touse'", `N', `T', `k', `model',      ///
        "`meth'", `factors', `rmax', "`nfactors'", `maxlags', `fixlag',          ///
        "`lagcrit'", `nwbw', "`savecomp'", "`ICT'", "`IDIOS'", "`GRP'",          ///
        "`ADFI'", "`PVI'", "`LAGSI'", "`MQC'", "`MQF'", "`ADFF'", "`FHAT'",      ///
        "`BCCE'", "`BVCE'", "`RHAT'")

    local rhat = `RHAT'[1,1]
    local dcase "c"
    if (`model' == 2) local dcase "tau"
    local mdesc "constant"
    if (`model' == 0) local mdesc "none"
    if (`model' == 2) local mdesc "constant and linear trend"
    local fsrc "principal components of D.yhat"
    if ("`meth'" == "ca") local fsrc "differenced cross-section averages"

    di ""
    di as text "`mname'" _col(58) "Units      = " as result %8.0f `N'
    di as text "Banerjee and Carrion-i-Silvestre (2026), Section 4"             ///
        _col(58) as text "Periods    = " as result %8.0f `T'
    di as text "H0: panel spurious relationship  (uhat*_it is I(1))"            ///
        _col(58) as text "Regressors = " as result %8.0f `k'
    di as text "H1: panel cointegration"                                        ///
        _col(58) as text "Factors r  = " as result %8.0f `rhat'
    di as text "Deterministics: `mdesc'  (case `dcase')"                         ///
        _col(58) as text "Max ADF p  = " as result %8.0f `maxlags'
    di as text "Factors from: `fsrc'"
    if (`factors' == -1) {
        di as text "r selected by: " as result upper("`nfactors'") as text        ///
            " with rmax = " as result `rmax'
    }
    else {
        di as text "r imposed by the user"
    }
    di ""
    _xbp_cce_table `BCCE' `BVCE' "`ivars'"

    di ""
    di as text "{hline 79}"
    di as text "Idiosyncratic component uhat*_it:  H0 of a unit root (no cointegration)"
    di as text "{hline 79}"
    di as text %-20s "Statistic" _col(22) %13s "Value" _col(37) %11s "p-value" ///
        _col(50) %8s "Tail" _col(60) %8s "Type"
    di as text "{hline 79}"
    forvalues q = 1/3 {
        local nm : word `q' of P Pm Z
        local tl : word `q' of upper upper lower
        local s  = `GRP'[`q',1]
        local p  = `GRP'[`q',2]
        _xbp_star `p'
        di as text %-20s "`nm'" _col(22) as result %13.4f `s' _col(37) %11.4f `p'  ///
            _col(50) as text %8s "`tl'" _col(60) %8s "group" as text "  `s(star)'"
    }
    di as text "{dup 79:-}"
    forvalues q = 1/3 {
        local nm : word `q' of Pa Pb PMSB
        local s  = `IDIOS'[`q',1]
        local p  = `IDIOS'[`q',2]
        _xbp_star `p'
        di as text %-20s "`nm'" _col(22) as result %13.4f `s' _col(37) %11.4f `p'  ///
            _col(50) as text %8s "lower" _col(60) %8s "pooled" as text "  `s(star)'"
    }
    di as text "{hline 79}"
    di as text "{p 4 4 2}Group-type P, Pm and Z (Bai and Ng 2004) pool the per-unit ADF" ///
        " statistics and allow heterogeneous short-run dynamics.  Pooled-type Pa, Pb"    ///
        " and PMSB (Bai and Ng 2010) impose a common autoregressive parameter.  All are" ///
        " standard normal except P, which is chi2(2N).  Stars: * 10%, ** 5%, *** 1%."    ///
        "{p_end}"

    di ""
    di as text "{hline 79}"
    di as text "Common component Fhat_t:  order of integration"
    di as text "{hline 79}"
    if (`rhat' == 1) {
        local s = `ADFF'[1,1]
        local p = `ADFF'[1,2]
        di as text %-30s "ADF on Fhat (case `dcase')" _col(32) as result %14.4f `s' ///
            _col(48) %12.4f `p' _col(62) as text %10s "lower"
        di as text "{hline 79}"
        local fverd "I(1): one non-stationary common factor (r1 = 1)"
        if (`p' < (100-`level')/100) local fverd "I(0): a stationary common factor (r1 = 0)"
        di as text "Verdict at the `=100-`level''% level: " as result "`fverd'"
        di as text "{p 4 4 2}Critical values are those of the Dickey-Fuller test with"   ///
            " an intercept (case c) or with an intercept and a trend (case tau) -- Bai"  ///
            " and Ng (2004), step 2 of Theorems 1 and 3.{p_end}"
    }
    else {
        di as text %-8s "m" _col(10) %14s "MQc(m)" _col(26) %14s "5% c.v." ///
            _col(42) %14s "reject r1=m"
        di as text "{hline 79}"
        forvalues q = 1/`=rowsof(`MQC')' {
            local rjs "no"
            if (`MQC'[`q',4] == 1) local rjs "yes"
            di as text %-8.0f `MQC'[`q',1] _col(10) as result %14.3f `MQC'[`q',2] ///
                _col(26) %14.3f `MQC'[`q',3] _col(42) as text %14s "`rjs'"
        }
        di as text "{dup 79:-}"
        di as text %-8s "m" _col(10) %14s "MQf(m)" _col(26) %14s "5% c.v." ///
            _col(42) %14s "reject r1=m"
        di as text "{hline 79}"
        forvalues q = 1/`=rowsof(`MQF')' {
            local rjs "no"
            if (`MQF'[`q',4] == 1) local rjs "yes"
            di as text %-8.0f `MQF'[`q',1] _col(10) as result %14.3f `MQF'[`q',2] ///
                _col(26) %14.3f `MQF'[`q',3] _col(42) as text %14s "`rjs'"
        }
        di as text "{hline 79}"
        di as text "Estimated number of I(1) common factors: " as result             ///
            "r1 = `=`MQC'[rowsof(`MQC'),1]'" as text " (MQc),  " as result           ///
            "r1 = `=`MQF'[rowsof(`MQF'),1]'" as text " (MQf)"
        di as text "{p 4 4 2}MQ critical values from Bai and Ng (2004), Table I.  The"  ///
            " sequential procedure starts at m = min(r,6) and steps down one factor at" ///
            " a time until the null r1 = m is not rejected.{p_end}"
    }

    *--- interpretation ------------------------------------------------------
    di ""
    di as text "{hline 79}"
    di as text "Reading this output"
    di as text "{hline 79}"
    local a = (100-`level')/100
    local idv "not rejected: no panel cointegration"
    if (`IDIOS'[2,2] < `a') local idv "rejected: panel cointegration"
    di as text "{p 4 4 2}The idiosyncratic block tests the error-correction term."     ///
        " Here Pb says H0 is `idv' at the `=100-`level''% level.  The common block"     ///
        " tells you whether the cross-section dependence is driven by I(1) or I(0)"     ///
        " factors; that is the information the bounds test deliberately does without."  ///
        "{p_end}"
    di as text "{hline 79}"

    *--- graph ---------------------------------------------------------------
    if ("`graph'" != "") {
        if ("`name'" == "") local name "xbp_panico"
        local nf = colsof(`FHAT')
        * the reference line must match the case: the case-c and case-tau
        * limits of the per-unit ADF differ (about -1.94 against -2.62)
        tempname adfcv
        mata: st_numscalar("`adfcv'", _xbp_adfcv(0.05, "`dcase'"))
        local acv  = scalar(`adfcv')
        local acvl : di %5.2f `acv'
        preserve
            clear
            qui set obs `T'
            qui svmat double `FHAT', name(fh)
            qui gen int tt = _n
            local pl ""
            forvalues q = 1/`nf' {
                local pl "`pl' (line fh`q' tt, lwidth(medthin))"
            }
            twoway `pl', graphregion(color(white)) plotregion(color(white))     ///
                yline(0, lcolor(gs10) lpattern(dot))                           ///
                ytitle("Fhat") xtitle("time index")                            ///
                title("Estimated common factors", size(medium))                ///
                subtitle("cumulated from the defactored differences", size(small)) ///
                legend(region(lstyle(none)) rows(1) position(6) ring(1)        ///
                       size(small))                                            ///
                name(`name'_f, replace) nodraw
            clear
            qui set obs `N'
            qui svmat double `ADFI', name(adf)
            qui gen int unit = _n
            twoway (scatter adf1 unit, msymbol(O) msize(small) mcolor(navy))    ///
                   (function y = `acv', range(1 `N') lpattern(dash)             ///
                        lcolor(cranberry)),                                     ///
                graphregion(color(white)) plotregion(color(white))              ///
                ytitle("ADF on uhat*_i") xtitle("panel unit")                   ///
                title("Per-unit ADF statistics", size(medium))                  ///
                subtitle("case `dcase'", size(small))                           ///
                legend(order(1 "ADF_i" 2 "5% c.v. (`acvl')") rows(1)            ///
                       position(6) ring(1) size(small)                          ///
                       region(lstyle(none)))                                    ///
                name(`name'_u, replace) nodraw
        restore
        graph combine `name'_f `name'_u, graphregion(color(white))              ///
            name(`name', replace)
    }

    if ("`savecomp'" != "") {
        label var `savecomp'_u "uhat* (idiosyncratic component)"
        forvalues q = 1/`rhat' {
            capture label var `savecomp'_f`q' "Fhat`q' (common factor `q')"
        }
        di ""
        di as text "{p 4 4 2}Components saved: {bf:`savecomp'_u} and" ///
            " {bf:`savecomp'_f1}...{bf:`savecomp'_f`rhat'}.{p_end}"
    }

    *--- return --------------------------------------------------------------
    return local cmd    "xtboundpanico"
    return local subcmd "panico"
    if ("`meth'" == "ca") return local subcmd "panicca"
    return local depvar    "`dv'"
    return local indepvars "`ivars'"
    return local panelvar  "`ivar'"
    return local timevar   "`tvar'"
    return local nfactors  "`nfactors'"
    return local lagcrit   "`lagcrit'"
    return local dcase     "`dcase'"
    return scalar N     = `N'
    return scalar T     = `T'
    return scalar k     = `k'
    return scalar r     = `rhat'
    return scalar rmax  = `rmax'
    return scalar model = `model'
    return scalar level = `level'
    return scalar P      = `GRP'[1,1]
    return scalar P_p    = `GRP'[1,2]
    return scalar Pm     = `GRP'[2,1]
    return scalar Pm_p   = `GRP'[2,2]
    return scalar Z      = `GRP'[3,1]
    return scalar Z_p    = `GRP'[3,2]
    return scalar Pa     = `IDIOS'[1,1]
    return scalar Pa_p   = `IDIOS'[1,2]
    return scalar Pb     = `IDIOS'[2,1]
    return scalar Pb_p   = `IDIOS'[2,2]
    return scalar PMSB   = `IDIOS'[3,1]
    return scalar PMSB_p = `IDIOS'[3,2]
    if (`rhat' == 1) {
        return scalar adf_F   = `ADFF'[1,1]
        return scalar adf_F_p = `ADFF'[1,2]
        local r1v = 1
        if (`ADFF'[1,2] < (100-`level')/100) local r1v = 0
        return scalar r1 = `r1v'
    }
    else {
        return scalar r1_mqc = `MQC'[rowsof(`MQC'),1]
        return scalar r1_mqf = `MQF'[rowsof(`MQF'),1]
        return matrix mqf = `MQF'
        return matrix mqc = `MQC'
    }
    return matrix Fhat   = `FHAT'
    return matrix lags_i = `LAGSI'
    return matrix p_i    = `PVI'
    return matrix adf_i  = `ADFI'
    return matrix ic     = `ICT'
    return matrix V_cce  = `BVCE'
    return matrix b_cce  = `BCCE'
end


*------------------------------------------------------------------------------
* number of common factors: every criterion side by side
*------------------------------------------------------------------------------
program define _xbp_nfac, rclass
    version 14.0
    syntax varlist(min=2 numeric) [if] [in] [,          ///
        MODel(integer 1)                                ///
        RMAX(integer -1)                                ///
        METHod(string)                                  ///
        GRAPH                                           ///
        NAME(string) ]

    marksample touse
    gettoken dv ivars : varlist
    local k : word count `ivars'

    _xbp_prep `varlist' `if' `in' , touse(`touse')
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    local N = r(N)
    local T = r(T)
    _xbp_chkmodel `model'

    local method = lower(trim("`method'"))
    if ("`method'" == "") local method "pc"
    if (!inlist("`method'", "pc", "ca")) {
        di as error "method() must be {bf:pc} or {bf:ca}"
        exit 198
    }
    if (`rmax' == -1) {
        if ("`method'" == "ca") local rmax = 1 + `k'
        else                    local rmax = 5
    }
    if ("`method'" == "ca" & `rmax' > 1 + `k') local rmax = 1 + `k'
    if (`rmax' < 1)   local rmax = 1
    if (`rmax' > `N') local rmax = `N'

    sort `ivar' `tvar'

    tempname ICT RHATS
    mata: _xbp_run_nfac("`dv' `ivars'", "`touse'", `N', `T', `k', `model',  ///
        "`method'", `rmax', "`ICT'", "`RHATS'")

    local srcd "principal components of D.yhat"
    if ("`method'" == "ca") local srcd "differenced cross-section averages"

    di ""
    di as text "Number of common factors" _col(58) "Units   = " as result %8.0f `N'
    di as text "Candidates: `srcd'" _col(58) as text "Periods = " as result %8.0f `T'
    di as text "" _col(58) as text "rmax    = " as result %8.0f `rmax'
    di ""
    di as text "{hline 79}"
    if ("`method'" == "ca") {
        di as text "Reese and Westerlund (2016) panel information criterion"
        di as text "{hline 79}"
        di as text %-8s "s" _col(12) %18s "IC(s)" _col(34) %18s "ln Sigma_v(s)"
        di as text "{hline 79}"
        forvalues q = 1/`=rowsof(`ICT')' {
            local mk ""
            if (`ICT'[`q',1] == `RHATS'[1,1]) local mk "   <- rhat"
            di as text %-8.0f `ICT'[`q',1] _col(12) as result %18.6f `ICT'[`q',2] ///
                _col(34) %18.6f `ICT'[`q',3] as text "`mk'"
        }
        di as text "{hline 79}"
        di as text "rhat (Reese-Westerlund) = " as result `RHATS'[1,1]
        di as text "{p 4 4 2}IC(s) = ln det[Sigma_v(s)] + s (m+1) N^-1 ln N with m+1 ="   ///
            " 1+k = `=1+`k''.  This is the multivariate analogue of ICp3 and, as the"      ///
            " paper notes in Section 6.1, it can over-estimate r.{p_end}"
        return scalar r_rw = `RHATS'[1,1]
    }
    else {
        di as text "Bai and Ng (2002) panel criteria  (minimised)"
        di as text "{hline 79}"
        di as text %-5s "k" _col(7) %11s "ICp1" _col(19) %11s "ICp2" _col(31) %11s "ICp3" ///
            _col(43) %11s "PCp1" _col(55) %11s "PCp2" _col(67) %11s "PCp3"
        di as text "{hline 79}"
        forvalues q = 1/`=rowsof(`ICT')' {
            di as text %-5.0f `ICT'[`q',1] _col(7) as result %11.5f `ICT'[`q',2]   ///
                _col(19) %11.5f `ICT'[`q',3] _col(31) %11.5f `ICT'[`q',4]          ///
                _col(43) %11.5f `ICT'[`q',5] _col(55) %11.5f `ICT'[`q',6]          ///
                _col(67) %11.5f `ICT'[`q',7]
        }
        di as text "{hline 79}"
        di as text "AIC3 / BIC3 (minimised) and eigenvalue ratios (maximised)"
        di as text "{hline 79}"
        di as text %-5s "k" _col(7) %11s "AIC3" _col(19) %11s "BIC3" _col(31) %11s "ER" ///
            _col(43) %11s "GR" _col(55) %11s "eigenvalue"
        di as text "{hline 79}"
        forvalues q = 1/`=rowsof(`ICT')' {
            di as text %-5.0f `ICT'[`q',1] _col(7) as result %11.5f `ICT'[`q',8]   ///
                _col(19) %11.5f `ICT'[`q',9] _col(31) %11.5f `ICT'[`q',10]         ///
                _col(43) %11.5f `ICT'[`q',11] _col(55) %11.5f `ICT'[`q',12]
        }
        di as text "{hline 79}"
        di as text %-26s "Criterion" _col(28) %8s "rhat" _col(40) "Source"
        di as text "{hline 79}"
        forvalues q = 1/11 {
            local nm : word `q' of "ICp1 (panel BIC)" "ICp2" "ICp3" "PCp1" "PCp2" ///
                "PCp3" "AIC3" "BIC3" "ER" "GR" "ED"
            local sr : word `q' of "BN02" "BN02" "BN02" "BN02" "BN02" "BN02"      ///
                "BN02" "BN02" "AH13" "AH13" "Onatski10"
            di as text %-26s "`nm'" _col(28) as result %8.0f `RHATS'[1,`q']       ///
                _col(40) as text "`sr'"
        }
        di as text "{hline 79}"
        di as text "{p 4 4 2}BN02 = Bai and Ng (2002); AH13 = Ahn and Horenstein (2013)" ///
            " eigenvalue-ratio and growth-ratio estimators, with their mock eigenvalue"   ///
            " mu_0 = V(0)/ln(min(N,T)) so that rhat = 0 is admissible; Onatski10 ="       ///
            " the edge-distribution (ED) estimator, iterated to convergence.{p_end}"
        di as text "{p 4 4 2}rmax enters PCp, AIC3 and BIC3 through sigmahat^2 = V(rmax)" ///
            " and bounds every estimator.  Over-estimation is common when N or T is"      ///
            " small: Bai and Ng (2002, 2010) and Section 6.1 of the paper both recommend" ///
            " comparing BIC3, ER, GR and ED before settling on rhat.{p_end}"
        forvalues q = 1/11 {
            local nm : word `q' of icp1 icp2 icp3 pcp1 pcp2 pcp3 aic3 bic3 er gr ed
            return scalar r_`nm' = `RHATS'[1,`q']
        }
    }

    if ("`graph'" != "") {
        if ("`name'" == "") local name "xbp_nfac"
        preserve
            clear
            qui set obs `=rowsof(`ICT')'
            qui svmat double `ICT', name(ic)
            if ("`method'" == "ca") {
                twoway (connected ic2 ic1, msymbol(O) mcolor(navy) lcolor(navy)),  ///
                    graphregion(color(white)) plotregion(color(white))              ///
                    ytitle("IC(s)") xtitle("number of cross-section averages s")    ///
                    title("Reese-Westerlund information criterion", size(medium))   ///
                    name(`name', replace) nodraw
            }
            else {
                twoway (connected ic2 ic1, msymbol(O) mcolor(navy) lcolor(navy))      ///
                       (connected ic3 ic1, msymbol(S) mcolor(cranberry)               ///
                            lcolor(cranberry) lpattern(dash))                         ///
                       (connected ic4 ic1, msymbol(T) mcolor(forest_green)            ///
                            lcolor(forest_green) lpattern(shortdash)),                ///
                    graphregion(color(white)) plotregion(color(white))                ///
                    ytitle("criterion value") xtitle("number of factors k")           ///
                    title("Bai-Ng (2002) panel information criteria", size(medium))   ///
                    legend(order(1 "ICp1" 2 "ICp2" 3 "ICp3") rows(1)                  ///
                           position(6) ring(1) size(small)                            ///
                           region(lstyle(none)))                                      ///
                    name(`name', replace) nodraw
            }
        restore
        graph display `name'
    }

    return local cmd    "xtboundpanico"
    return local subcmd "nfactors"
    return local method "`method'"
    return scalar N     = `N'
    return scalar T     = `T'
    return scalar k     = `k'
    return scalar rmax  = `rmax'
    return scalar model = `model'
    return matrix rhats = `RHATS'
    return matrix ic    = `ICT'
end


*------------------------------------------------------------------------------
* all: bounds, then PANICO, then PANICCA, then the synthesis
*------------------------------------------------------------------------------
program define _xbp_all, rclass
    version 14.0
    syntax varlist(min=2 numeric) [if] [in] [,          ///
        MODel(integer 1)                                ///
        FACtors(integer -1)                             ///
        RMAX(integer -1)                                ///
        NFACtors(string)                                ///
        MAXLags(integer -1)                             ///
        LAGs(integer -1)                                ///
        LAGCrit(string)                                 ///
        CVMethod(string)                                ///
        NWBw(integer -1)                                ///
        LEVel(cilevel)                                  ///
        DFPaper DFFull NOCips ]

    local common "model(`model') maxlags(`maxlags') lags(`lags') level(`level')"
    if ("`lagcrit'" != "") local common "`common' lagcrit(`lagcrit')"

    local bo "`common' `dfpaper' `dffull' `nocips'"
    if ("`cvmethod'" != "") local bo "`bo' cvmethod(`cvmethod')"
    if (`factors' != -1)    local bo "`bo' factors(`factors')"

    local po "`common' nwbw(`nwbw')"
    if (`rmax' != -1)       local po "`po' rmax(`rmax')"
    if ("`nfactors'" != "") local po "`po' nfactors(`nfactors')"
    if (`factors' != -1)    local po "`po' factors(`factors')"

    di ""
    di as text "{hline 79}"
    di as text "{bf:Step 1 of 3.}  Bounds testing approach (Section 3)"
    di as text "{hline 79}"
    _xbp_bounds `varlist' `if' `in' , `bo'
    local bdec "`r(decision)'"
    local btyb = r(tybar)
    local lvl  = r(level)

    di ""
    di as text "{hline 79}"
    di as text "{bf:Step 2 of 3.}  PANICO with principal-component factors (Section 4)"
    di as text "{hline 79}"
    _xbp_panic `varlist' `if' `in' , xbpmeth(pc) `po'
    local pcPb  = r(Pb)
    local pcPbP = r(Pb_p)
    local pcr   = r(r)

    di ""
    di as text "{hline 79}"
    di as text "{bf:Step 3 of 3.}  PANICO on cross-section averages (PANICCA)"
    di as text "{hline 79}"
    local cao "`po'"
    if ("`nfactors'" == "") local cao "`common' nwbw(`nwbw')"
    if (`factors' != -1)    local cao "`cao' factors(`factors')"
    capture noisily _xbp_panic `varlist' `if' `in' , xbpmeth(ca) `cao'
    local carc = _rc
    local caPbP = .
    if (`carc' == 0) local caPbP = r(Pb_p)

    local a = (100 - `lvl')/100
    di ""
    di as text "{hline 79}"
    di as text "Synthesis -- the trade-off set out in Section 5.3 of the paper"
    di as text "{hline 79}"
    di as text %-46s "Bounds test, tybar = `:di %7.3f `btyb''" _col(48) as result "`bdec'"
    local pcdec "H0 not rejected"
    if (`pcPbP' < `a') local pcdec "H0 rejected"
    di as text %-46s "PANICO-PC, Pb" _col(48) as result "`pcdec'"
    if (`carc' == 0) {
        local cadec "H0 not rejected"
        if (`caPbP' < `a') local cadec "H0 rejected"
        di as text %-46s "PANICO-CA, Pb" _col(48) as result "`cadec'"
    }
    else {
        di as text %-46s "PANICO-CA" _col(48) as error "failed (rc = `carc')"
    }
    di as text "{hline 79}"
    if ("`bdec'" == "INCONCLUSIVE") {
        di as text "{p 4 4 2}The bounds test is inconclusive, which is the case PANICO"   ///
            " was designed for: it estimates the common factors and their order of"       ///
            " integration, so the ambiguity region disappears.  Read the PANICO block"    ///
            " above, and in particular its verdict on Fhat.{p_end}"
    }
    else {
        di as text "{p 4 4 2}The bounds test reaches a conclusion without committing to"  ///
            " the order of integration of the common factors.  PANICO is reported as a"   ///
            " refinement: the paper finds it more powerful for T >= 100, at the cost of"  ///
            " having to estimate r (here rhat = `pcr').{p_end}"
    }
    di as text "{p 4 4 2}Mild over-rejection by the group-type Z, P and Pm statistics in" ///
        " small T is documented in Section 5.2 and follows from the use of asymptotic"    ///
        " moments and p-values; Pb and PMSB are the better behaved choices.{p_end}"
    di as text "{hline 79}"

    return local cmd      "xtboundpanico"
    return local subcmd   "all"
    return local decision "`bdec'"
    return scalar tybar = `btyb'
    return scalar Pb_pc = `pcPb'
end


*------------------------------------------------------------------------------
* display helpers
*------------------------------------------------------------------------------
program define _xbp_cce_table
    version 14.0
    args B V ivars
    di as text "{hline 79}"
    di as text "Pooled CCE long-run coefficients (eq. 13)"
    di as text "{hline 79}"
    di as text %-22s "Variable" _col(24) %13s "Coef." _col(38) %13s "Std. err." ///
        _col(52) %11s "z" _col(64) %11s "P>|z|"
    di as text "{hline 79}"
    local j = 1
    foreach v of local ivars {
        local b  = `B'[`j',1]
        local se = sqrt(`V'[`j',`j'])
        local z  = .
        local p  = .
        if (`se' < .  &  `se' > 0) {
            local z = `b'/`se'
            local p = 2*normal(-abs(`z'))
        }
        _xbp_star `p'
        di as text %-22s abbrev("`v'",22) _col(24) as result %13.6f `b'      ///
            _col(38) %13.6f `se' _col(52) %11.3f `z' _col(64) %11.3f `p'     ///
            as text " `s(star)'"
        local j = `j' + 1
    }
    di as text "{hline 79}"
    di as text "{p 4 4 2}Variance from Holly, Pesaran and Yamagata (2010), eq. (3.12)" ///
        "-(3.13): N^-1 Psi^-1 R Psi^-1, the non-parametric pooled-CCE sandwich.  Use"  ///
        " it to test theory restrictions such as beta = 1.  Stars: * 10%, ** 5%,"      ///
        " *** 1%.{p_end}"
end

program define _xbp_star, sclass
    version 14.0
    args p
    sreturn clear
    local st ""
    if (`p' < .) {
        if (`p' < 0.10) local st "*"
        if (`p' < 0.05) local st "**"
        if (`p' < 0.01) local st "***"
    }
    sreturn local star "`st'"
end


*------------------------------------------------------------------------------
* option validators
*------------------------------------------------------------------------------
program define _xbp_chkmodel
    version 14.0
    args m
    if (!inlist(`m', 0, 1, 2)) {
        di as error "model() must be 0, 1 or 2"
        di as text "{p 4 4 2}0 = no deterministic terms, 1 = constant (Cases 2 and 3 of" ///
            " the paper, which are equivalent once attention is restricted to rho_yi),"  ///
            " 2 = constant and linear trend (Cases 4 and 5).{p_end}"
        exit 198
    }
end

program define _xbp_chkfac
    version 14.0
    args r k
    if (`r' < 1) {
        di as error "factors() must be 1 or more"
        exit 198
    }
    if (`r' > 1 + `k') {
        di as error "factors() cannot exceed 1+k = `=1+`k''"
        di as text "{p 4 4 2}Assumption G (the rank condition) caps the number of factor" ///
            " proxies at 1+k when the factors are approximated by cross-section"          ///
            " averages: only 1+k averages exist.  Use {bf:xtboundpanico panico} if you"   ///
            " need more factors than that.{p_end}"
        exit 198
    }
end

program define _xbp_chklagcrit
    version 14.0
    args c
    if (!inlist("`c'", "bic", "aic", "maic", "mbic")) {
        di as error "lagcrit() must be {bf:bic}, {bf:aic}, {bf:maic} or {bf:mbic}"
        exit 198
    }
end

program define _xbp_chknf
    version 14.0
    args nf meth
    if ("`meth'" == "ca") {
        if (!inlist("`nf'", "rw", "icp1", "icp2", "icp3", "bic3", "er", "gr", "ed")) {
            di as error "with {bf:panicca}, nfactors() must be rw icp1 icp2 icp3 bic3 er gr or ed"
            exit 198
        }
        exit
    }
    if (!inlist("`nf'", "icp1", "icp2", "icp3", "pcp1", "pcp2", "pcp3") &  ///
        !inlist("`nf'", "aic3", "bic3", "er", "gr", "ed")) {
        di as error "nfactors() must be one of icp1 icp2 icp3 pcp1 pcp2 pcp3 aic3 bic3 er gr ed"
        exit 198
    }
end


*==============================================================================
*                               M A T A   E N G I N E
*==============================================================================
version 14.0
mata:

//-----------------------------------------------------------------------------
// basic transformations
//-----------------------------------------------------------------------------
// data arrive sorted i then t and balanced, so one variable reshapes to T x N
real matrix _xbp_shape(real colvector v, real scalar T)
{
    return(colshape(v', T)')
}

real matrix _xbp_diff(real matrix Z)
{
    real scalar n
    n = rows(Z)
    return(Z[|2,1 \ n,.|] - Z[|1,1 \ n-1,.|])
}

real matrix _xbp_cumul(real matrix dZ)
{
    real matrix Z
    real scalar i
    Z = J(rows(dZ)+1, cols(dZ), 0)
    for (i=2; i<=rows(Z); i++) {
        Z[i,] = Z[i-1,] + dZ[i-1,]
    }
    return(Z)
}

real matrix _xbp_deter(real scalar T, real scalar model)
{
    if (model == 1) {
        return(J(T,1,1))
    }
    if (model == 2) {
        return((J(T,1,1), (1::T)))
    }
    return(J(T,0,.))
}

real matrix _xbp_resid(real matrix Z, real matrix D)
{
    if (cols(D) == 0) {
        return(Z)
    }
    return(Z - D*(invsym(quadcross(D,D))*quadcross(D,Z)))
}

real scalar _xbp_ssq(real matrix R)
{
    return(sum(R:^2))
}

real scalar _xbp_meannm(real matrix M)
{
    real scalar i, s, n
    s = 0
    n = 0
    for (i=1; i<=rows(M); i++) {
        if (M[i,1] != .) {
            s = s + M[i,1]
            n = n + 1
        }
    }
    if (n == 0) {
        return(.)
    }
    return(s/n)
}

//-----------------------------------------------------------------------------
// OLS with the t-ratio of a nominated column
// returns (coef, t, ssr, ncols, flag) ; flag = 1 when the fit is degenerate
// dfmode  0 : full T minus the actual number of parameters (option dffull; the
//             literal T of eq. 17, and the convention of the authors' GAUSS
//             CADF code, which is what the CIPS comparator uses)
//         1 : full T minus the paper's literal m_i = 2 + k + (1+r)p_i (dfpaper)
//         2 : effective rows minus the actual number of parameters -- the
//             DEFAULT, and the only one that reproduces Table C.3
//         3 : effective rows minus m_i
//-----------------------------------------------------------------------------
real rowvector _xbp_ols_t(real colvector y, real matrix X, real scalar j,
                          real scalar Tfull, real scalar dfmode, real scalar mpaper)
{
    real matrix XX, XXi
    real colvector b, e
    real scalar ssr, nc, nr, dfd, s2, vj
    nc = cols(X)
    nr = rows(X)
    if (nr <= nc + 1) {
        return((., ., ., nc, 1))
    }
    XX  = quadcross(X,X)
    XXi = invsym(XX)
    if (diag0cnt(XXi) > 0) {
        return((., ., ., nc, 1))
    }
    b   = XXi*quadcross(X,y)
    e   = y - X*b
    ssr = quadcross(e,e)
    dfd = Tfull - nc
    if (dfmode == 1) {
        dfd = Tfull - mpaper
    }
    if (dfmode == 2) {
        dfd = nr - nc
    }
    if (dfmode == 3) {
        dfd = nr - mpaper
    }
    if (dfd <= 0) {
        return((b[j], ., ssr, nc, 1))
    }
    s2 = ssr/dfd
    vj = s2*XXi[j,j]
    if (vj <= 0) {
        return((b[j], ., ssr, nc, 1))
    }
    return((b[j], b[j]/sqrt(vj), ssr, nc, 0))
}

//-----------------------------------------------------------------------------
// cross-section averages of (y, x1, ..., xk): T x (1+k)
//-----------------------------------------------------------------------------
// The regressors are held in one T x (N*k) matrix, blocked by regressor as in
// the authors' GAUSS code (x = x1 ~ x2 ~ ... ~ xk, each block T x N).
// Columns of unit i, all k regressors:
real rowvector _xbp_xidx(real scalar N, real scalar k, real scalar i)
{
    real rowvector idx
    real scalar j
    idx = J(1, k, .)
    for (j=1; j<=k; j++) {
        idx[j] = (j-1)*N + i
    }
    return(idx)
}

real matrix _xbp_csamat(real matrix Y, real matrix X, real scalar N,
                        real scalar k)
{
    real matrix A
    real scalar j
    A = mean(Y')'
    for (j=1; j<=k; j++) {
        A = A, mean(X[|1,(j-1)*N+1 \ rows(X),j*N|]')'
    }
    return(A)
}

//-----------------------------------------------------------------------------
// pooled CCE estimator, eq. (13), with the Holly-Pesaran-Yamagata (2010)
// variance of eq. (3.12)-(3.13)
//-----------------------------------------------------------------------------
real colvector _xbp_cce(real matrix Y, real matrix X, real scalar N,
                        real scalar k, real scalar model, real matrix V)
{
    real matrix H, Mh, num, den, xi, D, Psi, R, Ai, Ais, bi
    real colvector b, bmg
    real scalar T, i, nu
    T = rows(Y)
    H = _xbp_csamat(Y, X, N, k)
    D = _xbp_deter(T, model)
    if (cols(D) > 0) {
        H = D, H
    }
    Mh  = I(T) - H*invsym(quadcross(H,H))*H'
    den = J(k,k,0)
    num = J(k,1,0)
    Psi = J(k,k,0)
    bi  = J(k,N,.)
    Ais = J(k, k*N, 0)
    for (i=1; i<=N; i++) {
        xi  = X[, _xbp_xidx(N,k,i)]
        Ai  = quadcross(xi, Mh*xi)
        den = den + Ai
        num = num + quadcross(xi, Mh*Y[,i])
        Psi = Psi + Ai/T
        Ais[|1,(i-1)*k+1 \ k,i*k|] = Ai/T
        if (diag0cnt(invsym(Ai)) == 0) {
            bi[,i] = invsym(Ai)*quadcross(xi, Mh*Y[,i])
        }
    }
    b   = invsym(den)*num
    Psi = Psi/N
    // CCEMG and the HPY sandwich
    bmg = J(k,1,0)
    nu  = 0
    for (i=1; i<=N; i++) {
        if (bi[1,i] != .) {
            bmg = bmg + bi[,i]
            nu  = nu + 1
        }
    }
    if (nu < 2 | diag0cnt(invsym(Psi)) > 0) {
        V = J(k,k,.)
        return(b)
    }
    bmg = bmg/nu
    R   = J(k,k,0)
    for (i=1; i<=N; i++) {
        if (bi[1,i] != .) {
            Ai = Ais[|1,(i-1)*k+1 \ k,i*k|]
            R  = R + Ai*(bi[,i]-bmg)*(bi[,i]-bmg)'*Ai
        }
    }
    R = R/(nu-1)
    V = invsym(Psi)*R*invsym(Psi)/N
    return(b)
}

//-----------------------------------------------------------------------------
// lag-order criteria.  tau is the Ng-Perron (2001) penalty term, used only by
// maic / mbic.
//-----------------------------------------------------------------------------
real scalar _xbp_crit(string scalar crit, real scalar ssr, real scalar n,
                      real scalar nc, real scalar p, real scalar tau)
{
    real scalar s2
    if (n <= 0 | ssr <= 0) {
        return(.)
    }
    s2 = ssr/n
    if (crit == "aic") {
        return(ln(s2) + 2*nc/n)
    }
    if (crit == "bic") {
        return(ln(s2) + nc*ln(n)/n)
    }
    if (crit == "maic") {
        return(ln(s2) + 2*(tau + p)/n)
    }
    return(ln(s2) + ln(n)*(tau + p)/n)
}

//-----------------------------------------------------------------------------
// design matrix of the conditional ECM, eq. (15), Case 5
// rows are held at the pmax sample so that the lag criteria are comparable
//-----------------------------------------------------------------------------
void _xbp_ecm_build(real colvector dy,  real matrix dY,   real matrix CSA,
                    real matrix dCSA,   real colvector yl, real matrix dx,
                    real scalar model,  real scalar p,     real scalar pmax,
                    real scalar T,      real colvector yy, real matrix XX)
{
    real matrix Z, D
    real scalar j, lo, hi, nr
    // the differenced arrays are indexed s = t-1 for t = 2..T
    lo = pmax
    hi = T - 1
    nr = hi - lo + 1
    yy = dy[|lo \ hi|]
    D  = _xbp_deter(T, model)
    Z  = J(nr, 0, .)
    if (cols(D) > 0) {
        Z = D[|lo+1,1 \ hi+1,.|]
    }
    // alpha' z_{i,t-1} with z_{i,t} = (yhat_it, CSAbar_t')
    Z = Z, yl[|lo \ hi|], CSA[|lo,1 \ hi,.|]
    // Gamma' D.Y_{i,t-j}, j = 1..p-1
    for (j=1; j<=p-1; j++) {
        Z = Z, dY[|lo-j,1 \ hi-j,.|]
    }
    // Lambda' D.CSAbar_{t-j}, j = 0..p-1
    for (j=0; j<=p-1; j++) {
        Z = Z, dCSA[|lo-j,1 \ hi-j,.|]
    }
    // omega' D.x_{i,t}
    if (cols(dx) > 0) {
        Z = Z, dx[|lo,1 \ hi,.|]
    }
    XX = Z
}

// column of yhat_{i,t-1} inside that design matrix
real scalar _xbp_ecm_pos(real scalar model)
{
    if (model == 0) {
        return(1)
    }
    if (model == 1) {
        return(2)
    }
    return(3)
}

//-----------------------------------------------------------------------------
// Table C.2 response surfaces of eq. (B.15).
// 45 rows = 3 models x 15 coefficients theta0..theta14
// 12 cols = {q1, q2.5, q5, q10, mean, variance} x {I(0), I(1)}
// NOTE Table C.2 prints its coefficient rows as 0..12,12,14; the second "12"
// is theta13, the coefficient on k^2.  That reading is used here.
//-----------------------------------------------------------------------------
real matrix _xbp_surface()
{
    string scalar s
    // 45 rows = 3 models (0,1,2) x 15 coefficients theta0..theta14
    // 12 cols = (q1, q2.5, q5, q10, mean, variance) x (I(0), I(1))
    // Held as a string: 540 numeric literals in one statement exceed
    // Mata's token limit.
    s = "-1.6138 -1.5892 -1.5484 -1.5318 -1.4954 -1.4801 -1.4131 -1.4085 -0.98919 -0.9779 0.092858 0.11161 -9.5855 -4.125 -8.979 -3.3126 -8.0638 -2.5925 -7.3138 -1.828 -5.3558 0 1.4108 0.94107 "
    s = s + "65.5452 0 59.7003 0 56.2838 0 54.778 0 55.2262 0 0 0 18.3698 0 17.8738 0 18.1956 0 18.0753 0 16.3683 0 -0.82205 0 -500.4349 -1.8836 -507.4866 0 -501.8463 6.6203 -485.4769 13.2304 -461.4743 "
    s = s + "26.7382 0 0 -40.0399 0 0 0 0 0 0 0 0 0 0 6.8929 0.13222 0 0.13363 0 0.13369 0 0.12974 0 0.12423 0 -0.005181 0 -1.4853 0 -1.4636 0 -1.467 0 -1.4293 0 -1.4482 0 0 0 4.1343 0 4.048 0 3.9646 0 "
    s = s + "3.9878 0 3.7929 0 -0.11082 0 0 0 0 0 0 0 0 0 0 0 -0.00036296 0 -0.37547 -0.3807 -0.37582 -0.37639 -0.37827 -0.37426 -0.38345 -0.37517 -0.42947 -0.4289 -0.0051587 -0.014795 0 -0.31453 0 "
    s = s + "-0.30843 0 -0.3187 0 -0.31965 0.15465 -0.16058 -0.074438 0.026753 1.6329 2.6016 1.6368 2.6843 1.6608 2.7464 1.6237 2.7896 2.0934 2.8617 0.28111 0 0.024315 0.024903 0.024485 0.024024 0.024736 "
    s = s + "0.023556 0.025266 0.0234 0.027897 0.02763 -0.0011101 0.00035193 -0.0058876 0 -0.0063063 0 -0.0062734 0 -0.005935 0 -0.0052308 0 0.0014175 0 -2.1272 -2.1347 -2.0816 -2.0882 -2.0471 -2.0383 "
    s = s + "-1.994 -1.9871 -1.8007 -1.7765 0.02282 0.022619 -11.965 -4.0925 -10.9393 -3.3738 -9.5275 -3.143 -8.5439 -2.4021 -4.6011 0 0.93846 0.79004 94.4357 0 90.9019 0 80.0574 0 77.3064 0 59.5937 0 0 "
    s = s + "0 16.8718 0 16.7946 0 16.9244 0 16.5466 0 14.366 0 -0.84943 -0.085715 -469.1157 85.3284 -460.7671 82.7987 -462.6905 51.3136 -448.6831 61.4562 -382.0844 83.6785 22.633 0 0 -41.9194 0 -33.3603 "
    s = s + "0 0 0 0 0 0 5.2029 9.8689 0.13756 0 0.1349 0 0.13121 0 0.1287 0 0.11168 0 -0.0055749 0 -1.5327 0 -1.5059 0 -1.4773 0 -1.4603 0 -1.3741 0 0.025424 0 3.9027 0 3.842 0 3.7737 0 3.6636 0 3.3232 "
    s = s + "0 -0.14988 0 -0.0036282 0 -0.0035095 0 -0.0033419 0 -0.0033613 0 -0.0040077 0 0 0 -0.29429 -0.3023 -0.29125 -0.29782 -0.28982 -0.296 -0.28902 -0.29323 -0.26809 -0.27865 0.008621 0.0077381 0 "
    s = s + "-0.25979 0 -0.26097 0 -0.23643 0 -0.21759 0 -0.14092 0.010221 0.044941 2.0625 2.9443 2.1478 3.0474 2.2578 3.1257 2.4172 3.1983 2.8999 3.3669 0.16639 0.059007 0.017203 0.017762 0.016695 "
    s = s + "0.017086 0.016399 0.016772 0.016037 0.016265 0.01166 0.013519 -0.0015844 -0.0013997 -0.0047293 0 -0.0044813 0 -0.0041457 0 -0.0036429 0 0 0 0.00090764 0 -2.5417 -2.5897 -2.5085 -2.5504 "
    s = s + "-2.4742 -2.511 -2.443 -2.4716 -2.3323 -2.3375 0.0086982 0.0090576 -12.6504 -4.6019 -11.6619 -3.9209 -10.8506 -3.6022 -9.4419 -2.8457 -4.7532 0 0.77696 0.65326 85.8934 0 84.9792 0 83.0385 0 "
    s = s + "75.1138 0 53.5967 0 0 0 15.0324 0 15.3092 0 14.2621 0 14.0947 0 13.027 0 -0.58241 -0.28336 -440.2616 73.6185 -439.4516 78.1017 -392.54 54.9069 -375.2985 69.6688 -314.2914 120.039 19.5953 "
    s = s + "10.1449 0 -41.642 0 -32.5273 0 0 0 0 0 0 8.9253 13.2031 0.1026 0 0.10308 0 0.10259 0 0.097855 0 0.07877 0 -0.0033435 0 -1.4 0 -1.4198 0 -1.3841 0 -1.3342 0 -1.1272 0 0.014414 0.0057773 "
    s = s + "3.6473 0 3.4755 0 3.3962 0 3.3069 0 2.9823 0 -0.12186 0 0.0032406 0 0.0027866 0 0.0026367 0 0.0025657 0 0.0011894 0 -0.00018881 0 -0.25613 -0.25608 -0.25258 -0.25287 -0.2492 -0.24878 "
    s = s + "-0.24256 -0.2446 -0.21158 -0.22378 0.0057633 0.0059264 0.20532 -0.20178 0.21345 -0.17208 0.2219 -0.17084 0.19492 -0.14099 0 0 0.035566 0.059176 2.6399 3.3536 2.8278 3.457 2.9866 3.5188 "
    s = s + "3.0877 3.6011 3.5058 3.8084 0.1369 0.088256 0.014021 0.014071 0.013316 0.013673 0.012896 0.013208 0.011966 0.012638 0.0080993 0.0096822 -0.00084972 -0.0008699 -0.0052524 0 -0.004588 0 "
    s = s + "-0.0046616 0 -0.0039321 0 0 0 0.0006437 0 "
    return(colshape(strtoreal(tokens(s)), 12))
}

// Table C.1: asymptotic 5% critical values, 18 rows = 3 models x r1 = 0..5,
// 6 cols = {I(0), I(1)} x {N = 20, 40, 60}
real matrix _xbp_tabc1()
{
    real matrix A
    A =
    (-0.78,-0.78,-0.68,-0.68,-0.63,-0.63 \
     -0.78,-1.60,-0.68,-1.55,-0.63,-1.53 \
     -0.78,-1.96,-0.68,-1.91,-0.63,-1.88 \
     -0.78,-2.25,-0.67,-2.19,-0.63,-2.17 \
     -0.78,-2.50,-0.68,-2.43,-0.63,-2.41 \
     -0.78,-2.72,-0.68,-2.65,-0.63,-2.62 \
     -1.84,-1.84,-1.75,-1.75,-1.71,-1.71 \
     -1.84,-2.20,-1.75,-2.14,-1.71,-2.11 \
     -1.84,-2.47,-1.75,-2.40,-1.71,-2.38 \
     -1.84,-2.70,-1.75,-2.63,-1.71,-2.61 \
     -1.84,-2.91,-1.75,-2.84,-1.71,-2.81 \
     -1.84,-3.10,-1.75,-3.02,-1.71,-2.99 \
     -2.46,-2.46,-2.38,-2.38,-2.34,-2.34 \
     -2.46,-2.70,-2.38,-2.63,-2.34,-2.60 \
     -2.46,-2.92,-2.38,-2.84,-2.34,-2.81 \
     -2.46,-3.10,-2.38,-3.03,-2.34,-3.00 \
     -2.46,-3.28,-2.38,-3.21,-2.34,-3.18 \
     -2.45,-3.44,-2.37,-3.37,-2.34,-3.34)
    return(A)
}

void _xbp_cvtable(real scalar model, real scalar r, real scalar k,
                  real scalar T, real scalar N, string scalar method,
                  string scalar outname)
{
    real matrix S, A, CV, Z
    real rowvector Ng
    real scalar base, q, c, r1, i, lo, hi, w
    CV = J(4,2,.)
    if (method == "asymptotic") {
        A  = _xbp_tabc1()
        r1 = r
        if (r1 > 5) {
            r1 = 5
        }
        base = model*6 + r1 + 1
        Ng   = (20,40,60)
        lo   = 1
        for (i=1; i<=3; i++) {
            if (Ng[i] <= N) {
                lo = i
            }
        }
        hi = lo + 1
        if (hi > 3) {
            hi = 3
        }
        if (Ng[hi] == Ng[lo]) {
            w = 0
        }
        else {
            w = (N - Ng[lo])/(Ng[hi] - Ng[lo])
        }
        if (w < 0) {
            w = 0
        }
        if (w > 1) {
            w = 1
        }
        CV[3,1] = (1-w)*A[base, 2*lo-1] + w*A[base, 2*hi-1]
        CV[3,2] = (1-w)*A[base, 2*lo]   + w*A[base, 2*hi]
    }
    else {
        S = _xbp_surface()
        Z = (1, 1/N, 1/N^2, 1/T, 1/T^2, 1/(N*T), r, r/N, r/T, r^2, k, k/N, k/T, k^2, r*k)
        for (q=1; q<=4; q++) {
            for (c=1; c<=2; c++) {
                CV[q,c] = Z*S[|model*15+1, 2*(q-1)+c \ model*15+15, 2*(q-1)+c|]
            }
        }
    }
    st_matrix(outname, CV)
    st_matrixrowstripe(outname, (J(4,1,""), ("1%" \ "2.5%" \ "5%" \ "10%")))
    st_matrixcolstripe(outname, (J(2,1,""), ("I0" \ "I1")))
}

//-----------------------------------------------------------------------------
// asymptotic p-values for the per-unit ADF on uhat*
//   case c   : Dickey-Fuller with no deterministic terms        (Bai-Ng 2004 Thm 1.1)
//   case tau : -0.5*(int_0^1 V(s)^2 ds)^(-1/2), V a Brownian bridge (Thm 3.1)
// Quantiles simulated with 1,000 steps and 1,000,000 replications; the implied
// moments reproduce footnote 3 of the paper --
//   case c   mean -0.4258 var 0.9645   (paper -0.42608, 0.95743)
//   case tau mean -1.5347 var 0.3409   (paper -1.53627, 0.34107)
// and the case-c 5% point is -1.938 against Bai and Ng's -1.95.
// Rebuild them with xtboundpanico_cvgen.do.
//-----------------------------------------------------------------------------
real colvector _xbp_pgrid()
{
    string scalar s
    s = "0.0004 0.0010 0.0020 0.0040 0.0060 0.0100 0.0140 0.0200 0.0260 0.0300 0.0400 0.0500 0.0600 0.0700 0.0800 0.0900 0.1000 0.1100 0.1200 0.1300 0.1400 0.1500 0.1600 0.1700 0.1800 0.1900 0.2000 "
    s = s + "0.2100 0.2200 0.2300 0.2400 0.2500 0.2600 0.2700 0.2800 0.2900 0.3000 0.3100 0.3200 0.3300 0.3400 0.3500 0.3600 0.3700 0.3800 0.3900 0.4000 0.4100 0.4200 0.4300 0.4400 0.4500 0.4600 0.4700 "
    s = s + "0.4800 0.4900 0.5000 0.5100 0.5200 0.5300 0.5400 0.5500 0.5600 0.5700 0.5800 0.5900 0.6000 0.6100 0.6200 0.6300 0.6400 0.6500 0.6600 0.6700 0.6800 0.6900 0.7000 0.7100 0.7200 0.7300 0.7400 "
    s = s + "0.7500 0.7600 0.7700 0.7800 0.7900 0.8000 0.8100 0.8200 0.8300 0.8400 0.8500 0.8600 0.8700 0.8800 0.8900 0.9000 0.9100 0.9200 0.9300 0.9400 0.9500 0.9600 0.9700 0.9740 0.9800 0.9860 0.9900 "
    s = s + "0.9940 0.9960 0.9980 0.9996 "
    return(strtoreal(tokens(s))')
}

real colvector _xbp_qgrid(string scalar dcase)
{
    string scalar s
    if (dcase == "tau") {
        s = "-4.05724 -3.82850 -3.64432 -3.45102 -3.32998 -3.17306 -3.06277 -2.94595 -2.85583 -2.80420 -2.70052 -2.61458 -2.54258 -2.48042 -2.42500 -2.37446 -2.32956 -2.28737 -2.24781 -2.21151 -2.17691 "
        s = s + "-2.14454 -2.11348 -2.08394 -2.05569 -2.02831 -2.00229 -1.97716 -1.95297 -1.92912 -1.90669 -1.88444 -1.86272 -1.84162 -1.82130 -1.80102 -1.78152 -1.76232 -1.74356 -1.72512 -1.70713 -1.68940 "
        s = s + "-1.67181 -1.65457 -1.63765 -1.62103 -1.60445 -1.58802 -1.57192 -1.55578 -1.53988 -1.52436 -1.50879 -1.49376 -1.47883 -1.46394 -1.44891 -1.43415 -1.41967 -1.40524 -1.39074 -1.37634 -1.36175 "
        s = s + "-1.34772 -1.33329 -1.31901 -1.30488 -1.29083 -1.27661 -1.26261 -1.24870 -1.23449 -1.22048 -1.20653 -1.19251 -1.17834 -1.16398 -1.14976 -1.13549 -1.12124 -1.10688 -1.09243 -1.07768 -1.06301 "
        s = s + "-1.04775 -1.03254 -1.01706 -1.00171 -0.98607 -0.97020 -0.95430 -0.93780 -0.92122 -0.90373 -0.88599 -0.86752 -0.84814 -0.82854 -0.80781 -0.78538 -0.76195 -0.73594 -0.70738 -0.67433 -0.65983 "
        s = s + "-0.63448 -0.60428 -0.57940 -0.54629 -0.52446 -0.49107 -0.43320 "
        return(strtoreal(tokens(s))')
    }
    s = "-3.54409 -3.29986 -3.08849 -2.87524 -2.73772 -2.56057 -2.44248 -2.31006 -2.20826 -2.15211 -2.03233 -1.93792 -1.85683 -1.78689 -1.72428 -1.66748 -1.61594 -1.56767 -1.52131 -1.47889 -1.43825 "
    s = s + "-1.39984 -1.36406 -1.32889 -1.29592 -1.26401 -1.23323 -1.20275 -1.17346 -1.14491 -1.11714 -1.09009 -1.06339 -1.03801 -1.01289 -0.98830 -0.96389 -0.93960 -0.91563 -0.89175 -0.86824 -0.84464 "
    s = s + "-0.82172 -0.79913 -0.77605 -0.75304 -0.73039 -0.70821 -0.68560 -0.66307 -0.64047 -0.61737 -0.59405 -0.57087 -0.54714 -0.52336 -0.49920 -0.47476 -0.44999 -0.42472 -0.39889 -0.37291 -0.34667 "
    s = s + "-0.32003 -0.29294 -0.26558 -0.23804 -0.21022 -0.18228 -0.15417 -0.12531 -0.09622 -0.06656 -0.03682 -0.00636 0.02435 0.05516 0.08712 0.11946 0.15256 0.18623 0.22052 0.25570 0.29138 0.32852 "
    s = s + "0.36638 0.40506 0.44532 0.48686 0.52992 0.57394 0.61969 0.66771 0.71883 0.77202 0.82791 0.88763 0.95394 1.02472 1.10260 1.18814 1.28553 1.39766 1.53912 1.60611 1.72650 1.87857 2.01274 "
    s = s + "2.21013 2.36761 2.61460 3.12974 "
    return(strtoreal(tokens(s))')
}

// generic monotone table lookup, interpolated in (statistic, invnormal(p))
real scalar _xbp_tabp(real scalar t, real colvector cv, real colvector pr,
                      real scalar flo)
{
    real colvector z
    real scalar n, i, lo, w, pv
    if (t == .) {
        return(.)
    }
    n  = rows(pr)
    z  = invnormal(pr)
    lo = 0
    for (i=1; i<=n; i++) {
        if (cv[i] <= t) {
            lo = i
        }
    }
    if (lo < 1) {
        lo = 1
    }
    if (lo > n-1) {
        lo = n-1
    }
    if (cv[lo+1] == cv[lo]) {
        w = 0
    }
    else {
        w = (t - cv[lo])/(cv[lo+1] - cv[lo])
    }
    pv = normal(z[lo] + w*(z[lo+1] - z[lo]))
    if (pv < flo) {
        pv = flo
    }
    if (pv > 1 - flo) {
        pv = 1 - flo
    }
    return(pv)
}

real scalar _xbp_adfp(real scalar t, string scalar dcase)
{
    return(_xbp_tabp(t, _xbp_qgrid(dcase), _xbp_pgrid(), 1e-6))
}

// 5% point of the per-unit ADF statistic for the case in use.  The two cases
// have DIFFERENT limits (about -1.94 for c, -2.62 for tau), so a plot drawn
// against the wrong one is actively misleading.
real scalar _xbp_adfcv(real scalar p, string scalar dcase)
{
    real colvector pg, qg
    real scalar i, n
    pg = _xbp_pgrid()
    qg = _xbp_qgrid(dcase)
    n  = rows(pg)
    for (i=1; i<=n; i++) {
        if (abs(pg[i] - p) < 1e-9) {
            return(qg[i])
        }
    }
    return(.)
}

// asymptotic moments of the per-unit ADF statistic (paper footnote 3)
real rowvector _xbp_adfmom(string scalar dcase)
{
    if (dcase == "tau") {
        return((-1.53627, 0.34107))
    }
    return((-0.42608, 0.95743))
}

// Dickey-Fuller p-value for the ADF on the estimated factor
real scalar _xbp_dfp(real scalar t, real scalar dmod)
{
    real colvector pr, cv
    pr = (0.01 \ 0.025 \ 0.05 \ 0.10 \ 0.20 \ 0.50 \ 0.80 \ 0.90 \ 0.95 \ 0.975 \ 0.99)
    if (dmod == 2) {
        cv = (-3.96 \ -3.66 \ -3.41 \ -3.12 \ -2.75 \ -2.18 \ -1.57 \ -1.25 \ -0.94 \ -0.66 \ -0.33)
    }
    else {
        cv = (-3.43 \ -3.12 \ -2.86 \ -2.57 \ -2.22 \ -1.57 \ -0.89 \ -0.44 \ -0.07 \ 0.23 \ 0.60)
    }
    return(_xbp_tabp(t, cv, pr, 1e-5))
}

//-----------------------------------------------------------------------------
// Newey-West bandwidth (Andrews AR(1) plug-in, the rule used in the PANIC
// code) and the nuisance parameters of Bai and Ng (2010) eq. (4)
//-----------------------------------------------------------------------------
real colvector _xbp_nw(real colvector z, real scalar fixk)
{
    real scalar Tt, anum, aden, rho, sg, alp, kk, i, dn
    real colvector e, w
    Tt = rows(z)
    if (fixk >= 0) {
        kk = fixk
    }
    else {
        dn = quadcross(z[|1 \ Tt-1|], z[|1 \ Tt-1|])
        if (dn <= 0) {
            kk = 0
        }
        else {
            rho = quadcross(z[|1 \ Tt-1|], z[|2 \ Tt|]) / dn
            if (abs(rho) > 0.9999) {
                rho = 0.9999*sign(rho)
            }
            e   = z[|2 \ Tt|] - rho*z[|1 \ Tt-1|]
            sg  = quadcross(e,e)/(Tt-1)
            anum = 4*(rho^2)*(sg^2) / (((1-rho)^6)*(1+rho)^2)
            aden = (sg^2)/((1-rho)^4)
            alp = anum/aden
            kk  = ceil(1.1447*(alp*Tt)^(1/3))
        }
    }
    if (kk < 0 | kk == .) {
        kk = 0
    }
    if (kk > Tt-2) {
        kk = Tt-2
    }
    w = J(kk+1,1,.)
    w[1] = kk
    for (i=1; i<=kk; i++) {
        w[i+1] = 1 - i/(kk+1)
    }
    return(w)
}

// N x 3 of (sigma2_i, omega2_i, lambda_i)
real matrix _xbp_nuis(real matrix eps, real scalar fixk)
{
    real matrix R
    real colvector kw, z
    real scalar TT, NN, i, j, K, g, s2, o2, hf
    TT = rows(eps)
    NN = cols(eps)
    R  = J(NN,3,.)
    for (i=1; i<=NN; i++) {
        z  = eps[,i]
        kw = _xbp_nw(z, fixk)
        K  = kw[1]
        s2 = quadcross(z,z)/TT
        o2 = s2
        hf = 0
        for (j=1; j<=K; j++) {
            g  = quadcross(z[|1 \ TT-j|], z[|j+1 \ TT|])/TT
            o2 = o2 + 2*kw[j+1]*g
            hf = hf + kw[j+1]*g
        }
        R[i,1] = s2
        R[i,2] = o2
        R[i,3] = hf
    }
    return(R)
}

//-----------------------------------------------------------------------------
// Bai and Ng (2010) pooled statistics Pa, Pb, PMSB  (their eq. 6-11)
// U is T x N and carries the leading zero row produced by _xbp_cumul.
// p = 1 (their notation) corresponds to model = 2 here.
//-----------------------------------------------------------------------------
real matrix _xbp_pooled(real matrix U, real scalar model, real scalar fixk)
{
    real matrix R, eps, Ul, Uc
    real scalar t, n, rho, rhop, O2, S2, p4, num, Pa, Pb, MS, trl
    t   = rows(U)
    n   = cols(U)
    Ul  = U[|1,1 \ t-1,.|]
    Uc  = U[|2,1 \ t,.|]
    trl = sum(Ul:^2)
    if (trl <= 0) {
        return(J(3,2,.))
    }
    rho = sum(Ul:*Uc) / trl
    eps = Uc - Ul*rho
    R   = _xbp_nuis(eps, fixk)
    O2  = mean(R[,2])
    S2  = mean(R[,1])
    p4  = mean(R[,2]:^2)
    if (O2 <= 0 | p4 <= 0) {
        return(J(3,2,.))
    }
    if (model == 2) {
        rhop = rho + 3*S2/(t*O2)
    }
    else {
        rhop = rho - (n*t*mean(R[,3]))/trl
    }
    num = sqrt(n)*t*(rhop - 1)
    if (model == 2) {
        // eq. (8), (9), (11): sigma^4 = (sigma2)^2 and omega^8 = (omega2)^4
        Pa = num / (sqrt(36/5*p4)*S2/O2^2)
        Pb = num * sqrt(5/6 * trl/(n*t^2) * O2^3/(p4*S2^2))
        MS = sqrt(n*45/p4)*(sum(U:^2)/(n*t^2) - O2/6)
    }
    else {
        // eq. (6), (7), (10)
        Pa = num / (sqrt(2*p4)/O2)
        Pb = num * sqrt(trl/(n*t^2) * O2/p4)
        MS = sqrt(n*3/p4)*(sum(U:^2)/(n*t^2) - O2/2)
    }
    return((Pa, normal(Pa) \ Pb, normal(Pb) \ MS, normal(MS)))
}

//-----------------------------------------------------------------------------
// per-unit ADF on uhat*, with no deterministic terms  (eq. 22)
// returns N x 3 of (t statistic, p-value, selected lags)
//-----------------------------------------------------------------------------
real matrix _xbp_adfu(real matrix U, real scalar pmax, real scalar fixlag,
                      string scalar lagcrit, string scalar dcase)
{
    real matrix R, X
    real colvector u, du, y
    real scalar t, n, i, p, lo, hi, nr, best, bc, cv, tau, j, pu
    real rowvector o
    t = rows(U)
    n = cols(U)
    R = J(n,3,.)
    lo = pmax + 1
    hi = t - 1
    nr = hi - lo + 1
    if (nr <= pmax + 3) {
        return(R)
    }
    for (i=1; i<=n; i++) {
        u  = U[,i]
        du = u[|2 \ t|] - u[|1 \ t-1|]
        best = 0
        bc   = .
        pu   = pmax
        if (fixlag) {
            best = pmax
        }
        else {
            for (p=0; p<=pu; p++) {
                y = du[|lo \ hi|]
                X = u[|lo \ hi|]
                for (j=1; j<=p; j++) {
                    X = X, du[|lo-j \ hi-j|]
                }
                o = _xbp_ols_t(y, X, 1, t, 2, cols(X))
                if (o[5] == 0) {
                    tau = 0
                    if (o[1] != . & o[3] != . & o[3] > 0) {
                        tau = (o[1]^2)*quadcross(u[|lo \ hi|], u[|lo \ hi|]) / (o[3]/nr)
                    }
                    cv = _xbp_crit(lagcrit, o[3], nr, cols(X), p, tau)
                    if (cv != .) {
                        if (bc == . | cv < bc) {
                            bc   = cv
                            best = p
                        }
                    }
                }
            }
        }
        p = best
        y = du[|lo \ hi|]
        X = u[|lo \ hi|]
        for (j=1; j<=p; j++) {
            X = X, du[|lo-j \ hi-j|]
        }
        o = _xbp_ols_t(y, X, 1, t, 2, cols(X))
        R[i,1] = o[2]
        R[i,2] = _xbp_adfp(o[2], dcase)
        R[i,3] = p
    }
    return(R)
}

// group-type statistics P, Pm, Z  (Bai and Ng 2004, Theorem 4)
real matrix _xbp_group(real matrix A, string scalar dcase)
{
    real rowvector mo
    real scalar n, i, P, Pm, Z, sp, stt, nu
    mo  = _xbp_adfmom(dcase)
    sp  = 0
    stt = 0
    nu  = 0
    n   = rows(A)
    for (i=1; i<=n; i++) {
        if (A[i,1] != . & A[i,2] != .) {
            sp  = sp + ln(A[i,2])
            stt = stt + A[i,1]
            nu  = nu + 1
        }
    }
    if (nu < 1) {
        return(J(3,2,.))
    }
    P  = -2*sp
    Pm = (P - 2*nu)/sqrt(4*nu)
    Z  = (stt/sqrt(nu) - sqrt(nu)*mo[1]) / sqrt(mo[2])
    return((P,  1 - chi2(2*nu, P) \
            Pm, 1 - normal(Pm)     \
            Z,  normal(Z)))
}

//-----------------------------------------------------------------------------
// principal components of the differenced, projected data
//-----------------------------------------------------------------------------
void _xbp_pca(real matrix dz, real scalar r, real matrix f, real matrix lam)
{
    real matrix V, L, S
    real scalar T1
    T1 = rows(dz)
    S  = dz*dz' / (cols(dz)*T1)
    symeigensystem(S, V=., L=.)
    f   = V[|1,1 \ T1,r|]:*sqrt(T1)
    lam = (invsym(quadcross(f,f))*quadcross(f,dz))'
}

// eigenvalues of dz*dz'/(N*T1), descending
real colvector _xbp_eigs(real matrix dz)
{
    real matrix V, L
    symeigensystem(dz*dz'/(cols(dz)*rows(dz)), V=., L=.)
    return(L')
}

// V(k) = average residual variance with k factors, k = 0..rmax
real colvector _xbp_vk(real matrix dz, real scalar rmax)
{
    real matrix V, L, f, res
    real colvector v
    real scalar T1, NN, k
    T1 = rows(dz)
    NN = cols(dz)
    symeigensystem(dz*dz'/(NN*T1), V=., L=.)
    v    = J(rmax+1,1,.)
    v[1] = _xbp_ssq(dz)/(NN*T1)
    for (k=1; k<=rmax; k++) {
        f      = V[|1,1 \ T1,k|]:*sqrt(T1)
        res    = dz - f*(invsym(quadcross(f,f))*quadcross(f,dz))
        v[k+1] = _xbp_ssq(res)/(NN*T1)
    }
    return(v)
}

//-----------------------------------------------------------------------------
// factor-number table.  (rmax+1) x 12:
//   k, ICp1, ICp2, ICp3, PCp1, PCp2, PCp3, AIC3, BIC3, ER, GR, eigenvalue
// ICp/PCp/AIC3/BIC3 : Bai and Ng (2002)
// ER, GR            : Ahn and Horenstein (2013), with the mock eigenvalue
//                     mu_0 = V(0)/ln(m), m = min(N,T), of their eq. (4)
//-----------------------------------------------------------------------------
real matrix _xbp_ictab(real matrix dz, real scalar rmax)
{
    real matrix R
    real colvector v, mu, mus, Vah
    real scalar T1, NN, C2, k, s2, g1, g2, g3, m, j
    T1 = rows(dz)
    NN = cols(dz)
    C2 = min((NN, T1))
    m  = C2
    v  = _xbp_vk(dz, rmax)
    s2 = v[rmax+1]
    mu = _xbp_eigs(dz)
    g1 = ((NN+T1)/(NN*T1))*ln((NN*T1)/(NN+T1))
    g2 = ((NN+T1)/(NN*T1))*ln(C2)
    g3 = ln(C2)/C2
    // Ahn-Horenstein V(k) = sum_{j>k}^{m} mu_j, with the mock mu_0
    mus = J(m+1,1,.)
    Vah = J(m+2,1,0)
    for (k=m; k>=1; k--) {
        Vah[k+1] = Vah[k+2] + mu[k]
    }
    mus[1] = Vah[2]/ln(m)
    for (k=1; k<=m; k++) {
        mus[k+1] = mu[k]
    }
    Vah[1] = Vah[2] + mus[1]
    R = J(rmax+1, 12, .)
    for (k=0; k<=rmax; k++) {
        R[k+1,1]  = k
        R[k+1,2]  = ln(v[k+1]) + k*g1
        R[k+1,3]  = ln(v[k+1]) + k*g2
        R[k+1,4]  = ln(v[k+1]) + k*g3
        R[k+1,5]  = v[k+1] + k*s2*g1
        R[k+1,6]  = v[k+1] + k*s2*g2
        R[k+1,7]  = v[k+1] + k*s2*g3
        R[k+1,8]  = v[k+1] + k*s2*(2*(NN+T1-k)/(NN*T1))
        R[k+1,9]  = v[k+1] + k*s2*((NN+T1-k)*ln(NN*T1)/(NN*T1))
        if (k+1 <= m) {
            if (mus[k+2] > 0) {
                R[k+1,10] = mus[k+1]/mus[k+2]
            }
            if (Vah[k+2] > 0 & Vah[k+3] > 0) {
                if (Vah[k+1] > Vah[k+2] & Vah[k+2] > Vah[k+3]) {
                    R[k+1,11] = ln(Vah[k+1]/Vah[k+2])/ln(Vah[k+2]/Vah[k+3])
                }
            }
        }
        if (k >= 1) {
            if (k <= m) {
                R[k+1,12] = mu[k]
            }
        }
        else {
            R[1,12] = mus[1]
        }
    }
    return(R)
}

// Onatski (2010) edge-distribution estimator, Section IV algorithm
real scalar _xbp_ed(real matrix dz, real scalar rmax)
{
    real colvector mu, y, x
    real matrix X
    real colvector bb
    real scalar n, j, it, dlt, rh, prev, i, best
    mu = _xbp_eigs(dz)
    n  = rows(mu)
    if (n < rmax + 6) {
        return(.)
    }
    j    = rmax + 1
    rh   = .
    prev = -1
    for (it=1; it<=20; it++) {
        y = mu[|j \ j+4|]
        x = J(5,1,.)
        for (i=0; i<=4; i++) {
            x[i+1] = (j + i - 1)^(2/3)
        }
        X  = J(5,1,1), x
        bb = invsym(quadcross(X,X))*quadcross(X,y)
        dlt = 2*abs(bb[2])
        best = 0
        for (i=1; i<=rmax; i++) {
            if (mu[i] - mu[i+1] >= dlt) {
                best = i
            }
        }
        rh = best
        if (rh == prev) {
            return(rh)
        }
        prev = rh
        j    = rh + 1
        if (j + 4 > n) {
            return(rh)
        }
    }
    return(rh)
}

// argmin (maximise = 0) or argmax (maximise = 1) over a column, returning k
real scalar _xbp_pick(real matrix R, real scalar col, real scalar maximise)
{
    real scalar i, best, bv
    best = 0
    bv   = .
    for (i=1; i<=rows(R); i++) {
        if (R[i,col] != .) {
            if (bv == .) {
                bv   = R[i,col]
                best = R[i,1]
            }
            else {
                if (maximise == 1) {
                    if (R[i,col] > bv) {
                        bv   = R[i,col]
                        best = R[i,1]
                    }
                }
                else {
                    if (R[i,col] < bv) {
                        bv   = R[i,col]
                        best = R[i,1]
                    }
                }
            }
        }
    }
    return(best)
}

// Reese-Westerlund (2016, p. 10) IC for the number of cross-section averages.
// (rmax+1) x 3 of (s, IC(s), ln Sigma_v(s))
real matrix _xbp_rwic(real matrix dz, real matrix CA, real scalar rmax,
                      real scalar m1)
{
    real matrix R, f, res
    real scalar T1, NN, s, sv
    T1 = rows(dz)
    NN = cols(dz)
    R  = J(rmax+1, 3, .)
    for (s=0; s<=rmax; s++) {
        if (s == 0) {
            res = dz
        }
        else {
            f   = CA[|1,1 \ T1,s|]
            res = dz - f*(invsym(quadcross(f,f))*quadcross(f,dz))
        }
        sv = _xbp_ssq(res)/(NN*T1)
        if (sv <= 0) {
            continue
        }
        R[s+1,1] = s
        R[s+1,2] = ln(sv) + s*m1*ln(NN)/NN
        R[s+1,3] = ln(sv)
    }
    return(R)
}

//-----------------------------------------------------------------------------
// ADF on the estimated factor (r = 1): with an intercept for case c, with an
// intercept and a trend for case tau  (Bai-Ng 2004, step 2 of Thms 1 and 3)
//-----------------------------------------------------------------------------
real rowvector _xbp_adff(real colvector F, real scalar model, real scalar pmax,
                         real scalar fixlag, string scalar lagcrit)
{
    real matrix X, D
    real colvector dF, y
    real scalar t, p, lo, hi, nr, best, bc, cv, j, tau, dmod
    real rowvector o
    t  = rows(F)
    dF = F[|2 \ t|] - F[|1 \ t-1|]
    lo = pmax + 1
    hi = t - 1
    nr = hi - lo + 1
    if (nr <= pmax + 4) {
        return((., .))
    }
    dmod = 1
    if (model == 2) {
        dmod = 2
    }
    D = _xbp_deter(t, dmod)
    best = 0
    bc   = .
    if (fixlag) {
        best = pmax
    }
    else {
        for (p=0; p<=pmax; p++) {
            y = dF[|lo \ hi|]
            X = F[|lo \ hi|]
            for (j=1; j<=p; j++) {
                X = X, dF[|lo-j \ hi-j|]
            }
            X = X, D[|lo+1,1 \ hi+1,.|]
            o = _xbp_ols_t(y, X, 1, t, 2, cols(X))
            if (o[5] == 0) {
                tau = 0
                if (o[3] > 0) {
                    tau = (o[1]^2)*quadcross(F[|lo \ hi|], F[|lo \ hi|]) / (o[3]/nr)
                }
                cv = _xbp_crit(lagcrit, o[3], nr, cols(X), p, tau)
                if (cv != .) {
                    if (bc == . | cv < bc) {
                        bc   = cv
                        best = p
                    }
                }
            }
        }
    }
    p = best
    y = dF[|lo \ hi|]
    X = F[|lo \ hi|]
    for (j=1; j<=p; j++) {
        X = X, dF[|lo-j \ hi-j|]
    }
    X = X, D[|lo+1,1 \ hi+1,.|]
    o = _xbp_ols_t(y, X, 1, t, 2, cols(X))
    return((o[2], _xbp_dfp(o[2], dmod)))
}

//-----------------------------------------------------------------------------
// MQc and MQf of Bai and Ng (2004), with their Table I critical values
// cols of the table: 1%, 5%, 10% for case c then 1%, 5%, 10% for case tau
//-----------------------------------------------------------------------------
real matrix _xbp_mqcv()
{
    real matrix C
    C = (-20.151,-13.730,-11.022,-29.246,-21.313,-17.829 \
         -31.621,-23.535,-19.923,-38.619,-31.356,-27.435 \
         -41.064,-32.296,-28.399,-50.019,-40.180,-35.685 \
         -48.501,-40.442,-36.592,-58.140,-48.421,-44.079 \
         -58.383,-48.617,-44.111,-64.729,-55.818,-55.286 \
         -66.978,-57.040,-52.312,-74.251,-64.393,-59.555)
    return(C)
}

real matrix _xbp_sigbart(real matrix e, real scalar fixk)
{
    real matrix S
    real colvector kw
    real scalar K, j, n
    n  = rows(e)
    kw = _xbp_nw(e[,1], fixk)
    K  = kw[1]
    S  = J(cols(e), cols(e), 0)
    for (j=1; j<=K; j++) {
        S = S + kw[j+1]*quadcross(e[|1,1 \ n-j,.|], e[|j+1,1 \ n,.|])
    }
    return(S/n)
}

void _xbp_mq(real matrix F, real scalar model, real scalar fixk,
             real scalar pmax, string scalar lagcrit,
             real matrix MQC, real matrix MQF)
{
    real matrix Mp, D, U, L, Y, e, Sg, B, nu, dY, W, Pi, yf, CV, Yl
    real scalar t, m, k, go, stat, cvl, dec, col, j, p, nr, lo
    t  = rows(F)
    CV = _xbp_mqcv()
    col = 2
    if (model == 2) {
        col = 5
    }
    if (model == 0) {
        Mp = I(t)
    }
    else {
        if (model == 1) {
            Mp = I(t) - J(t,t,1/t)
        }
        else {
            D  = J(t,1,1), (1::t)
            Mp = I(t) - D*invsym(quadcross(D,D))*D'
        }
    }
    symeigensystem(F'*Mp*F/t^2, U=., L=.)
    m   = min((6, cols(F)))
    MQC = J(0,4,.)
    k   = m
    go  = 1
    while (go != 0) {
        Y  = Mp*F*U[|1,1 \ cols(F),k|]
        Yl = Y[|1,1 \ t-1,.|]
        e  = Y[|2,1 \ t,.|] - Yl*(invsym(quadcross(Yl,Yl))*quadcross(Yl, Y[|2,1 \ t,.|]))
        Sg = _xbp_sigbart(e, fixk)
        B  = 0.5*(quadcross(Yl, Y[|2,1 \ t,.|]) + quadcross(Y[|2,1 \ t,.|], Yl)  ///
                  - t*(Sg + Sg')) * invsym(quadcross(Yl,Yl))
        nu   = svdsv(B)
        stat = t*(min(nu) - 1)
        cvl  = CV[k, col]
        dec  = (stat < cvl)
        MQC  = MQC \ (k, stat, cvl, dec)
        k    = k - dec
        go   = dec*(k > 0)
    }
    MQF = J(0,4,.)
    k   = m
    go  = 1
    while (go != 0) {
        Y  = Mp*F*U[|1,1 \ cols(F),k|]
        dY = _xbp_diff(Y)
        p  = _xbp_varlag(dY, pmax, lagcrit)
        if (p == 0) {
            yf = Y
        }
        else {
            // Pihat from a VAR(p) in the differences, then filter the levels
            lo = p + 1
            W  = J(t-1-p, 0, .)
            for (j=1; j<=p; j++) {
                W = W, dY[|lo-j,1 \ t-1-j,.|]
            }
            Pi = invsym(quadcross(W,W))*quadcross(W, dY[|lo,1 \ t-1,.|])
            W  = J(t-p, 0, .)
            for (j=1; j<=p; j++) {
                W = W, Y[|lo-j+1,1 \ t-j,.|]
            }
            yf = Y[|lo+1,1 \ t,.|] - W*Pi
        }
        nr = rows(yf)
        Yl = yf[|1,1 \ nr-1,.|]
        B  = 0.5*(quadcross(Yl, yf[|2,1 \ nr,.|]) + quadcross(yf[|2,1 \ nr,.|], Yl)) ///
             * invsym(quadcross(Yl,Yl))
        nu   = svdsv(B)
        stat = nr*(min(nu) - 1)
        cvl  = CV[k, col]
        dec  = (stat < cvl)
        MQF  = MQF \ (k, stat, cvl, dec)
        k    = k - dec
        go   = dec*(k > 0)
    }
}

// VAR order for the MQf filter
real scalar _xbp_varlag(real matrix dY, real scalar pmax, string scalar lagcrit)
{
    real matrix W, res
    real scalar t, p, lo, hi, nr, ssr, nc, best, bc, cv, j
    t  = rows(dY)
    lo = pmax + 1
    hi = t
    nr = hi - lo + 1
    if (nr <= (pmax+1)*cols(dY) + 2) {
        return(0)
    }
    best = 0
    bc   = .
    for (p=0; p<=pmax; p++) {
        if (p == 0) {
            res = dY[|lo,1 \ hi,.|]
            nc  = 0
        }
        else {
            W = J(nr, 0, .)
            for (j=1; j<=p; j++) {
                W = W, dY[|lo-j,1 \ hi-j,.|]
            }
            res = dY[|lo,1 \ hi,.|] -                                        ///
                  W*(invsym(quadcross(W,W))*quadcross(W, dY[|lo,1 \ hi,.|]))
            nc  = cols(W)
        }
        ssr = _xbp_ssq(res)
        cv  = _xbp_crit(lagcrit, ssr, nr*cols(dY), nc*cols(dY), p, 0)
        if (cv != .) {
            if (bc == . | cv < bc) {
                bc   = cv
                best = p
            }
        }
    }
    return(best)
}

//-----------------------------------------------------------------------------
// drivers
//-----------------------------------------------------------------------------
void _xbp_readdata(string scalar vars, string scalar touse, real scalar T,
                   real scalar k, real matrix Y, real matrix X)
{
    real matrix Z
    real scalar j
    Z = st_data(., vars, touse)
    Y = _xbp_shape(Z[,1], T)
    X = J(T, 0, .)
    for (j=1; j<=k; j++) {
        X = X, _xbp_shape(Z[,j+1], T)
    }
}

// yhat_it = y_it - betahat' x_it   (eq. 14)
real matrix _xbp_yhat(real matrix Y, real matrix X, real scalar N,
                      real scalar k, real colvector b)
{
    real matrix YH
    real scalar j
    YH = Y
    for (j=1; j<=k; j++) {
        YH = YH - X[|1,(j-1)*N+1 \ rows(X),j*N|]:*b[j]
    }
    return(YH)
}

void _xbp_run_bounds(string scalar vars, string scalar touse, real scalar N,
                     real scalar T, real scalar k, real scalar model,
                     real scalar r, real scalar pmax, real scalar fixlag,
                     string scalar lagcrit, real scalar dfmode,
                     real scalar docips,
                     string scalar sTI, string scalar sLG, string scalar sB,
                     string scalar sV,  string scalar sDR, string scalar sCI)
{
    real matrix Y, X, CSA, CSAr, dCSAr, YH, V, DR, XX, dXi, Yi, dYall, TK, LK
    real colvector b, yl, yy, dy, TI, LG
    real rowvector o
    real scalar i, j, p, best, bc, cv, tau, mp, nkeep, pos

    _xbp_readdata(vars, touse, T, k, Y=., X=.)
    b   = _xbp_cce(Y, X, N, k, model, V=.)
    CSA = _xbp_csamat(Y, X, N, k)
    st_matrix(sB, b)
    st_matrix(sV, V)
    YH    = _xbp_yhat(Y, X, N, k, b)
    CSAr  = CSA[|1,1 \ T,r|]
    dCSAr = _xbp_diff(CSAr)
    pos   = _xbp_ecm_pos(model)

    TI = J(N,1,.)
    LG = J(N,1,.)
    DR = J(0,1,.)
    for (i=1; i<=N; i++) {
        Yi = Y[,i]
        if (k > 0) {
            Yi = Yi, X[, _xbp_xidx(N,k,i)]
        }
        dYall = _xbp_diff(Yi)
        dy    = dYall[,1]
        dXi   = J(T-1, 0, .)
        if (k > 0) {
            dXi = dYall[|1,2 \ T-1,1+k|]
        }
        yl   = YH[|1,i \ T-1,i|]
        best = 0
        bc   = .
        if (fixlag) {
            best = pmax
        }
        else {
            for (p=1; p<=pmax; p++) {
                _xbp_ecm_build(dy, dYall, CSAr, dCSAr, yl, dXi, model, p, pmax, T, yy=., XX=.)
                mp = 2 + k + (1+r)*p
                o  = _xbp_ols_t(yy, XX, pos, T, dfmode, mp)
                if (o[5] == 0) {
                    tau = 0
                    if (o[3] > 0) {
                        tau = (o[1]^2)*quadcross(XX[,pos], XX[,pos]) / (o[3]/rows(yy))
                    }
                    cv = _xbp_crit(lagcrit, o[3], rows(yy), cols(XX), p, tau)
                    if (cv != .) {
                        if (bc == . | cv < bc) {
                            bc   = cv
                            best = p
                        }
                    }
                }
            }
        }
        if (best < 1) {
            best = 1
        }
        _xbp_ecm_build(dy, dYall, CSAr, dCSAr, yl, dXi, model, best, pmax, T, yy=., XX=.)
        mp = 2 + k + (1+r)*best
        o  = _xbp_ols_t(yy, XX, pos, T, dfmode, mp)
        if (o[5] == 0 & o[2] != .) {
            TI[i] = o[2]
            LG[i] = best
        }
        else {
            DR = DR \ i
        }
    }
    nkeep = 0
    for (i=1; i<=N; i++) {
        if (TI[i] != .) {
            nkeep = nkeep + 1
        }
    }
    TK = J(nkeep,1,.)
    LK = J(nkeep,1,.)
    j  = 0
    for (i=1; i<=N; i++) {
        if (TI[i] != .) {
            j = j + 1
            TK[j] = TI[i]
            LK[j] = LG[i]
        }
    }
    st_matrix(sTI, TK)
    st_matrix(sLG, LK)
    if (rows(DR) > 0) {
        st_matrix(sDR, DR)
    }
    if (docips) {
        st_matrix(sCI, _xbp_cadf(YH, CSA, model, r, pmax, fixlag, lagcrit, T, N))
    }
}

// CADF regression of eq. (18): the CIPS comparator.  Mirrors the authors'
// GAUSS procedure cadf_multiple() in cadfcoin_multiple.src, including its
// s^2 = e'e/(T - cols(X)) convention with the FULL T.
real colvector _xbp_cadf(real matrix YH, real matrix CSA, real scalar model,
                         real scalar r, real scalar pmax, real scalar fixlag,
                         string scalar lagcrit, real scalar T, real scalar N)
{
    real matrix E, D, A, dA, X
    real colvector eb, deb, y, el, R
    real scalar i, p, lo, hi, nr, best, bc, cv, tau
    real rowvector o
    D = _xbp_deter(T, model)
    E = _xbp_resid(YH, D)
    A = mean(E')'
    if (r > 1) {
        A = A, CSA[|1,2 \ T,r|]
    }
    dA = _xbp_diff(A)
    R  = J(N,1,.)
    lo = pmax
    hi = T - 1
    nr = hi - lo + 1
    if (nr <= pmax + 2*cols(A) + 5) {
        return(R)
    }
    for (i=1; i<=N; i++) {
        eb   = E[,i]
        deb  = eb[|2 \ T|] - eb[|1 \ T-1|]
        el   = eb[|1 \ T-1|]
        best = 0
        bc   = .
        if (fixlag) {
            best = pmax
        }
        else {
            for (p=1; p<=pmax; p++) {
                X = _xbp_cadfX(el, deb, A, dA, D, lo, hi, p)
                y = deb[|lo \ hi|]
                o = _xbp_ols_t(y, X, 1, T, 0, cols(X))
                if (o[5] == 0) {
                    tau = 0
                    if (o[3] > 0) {
                        tau = (o[1]^2)*quadcross(el[|lo \ hi|], el[|lo \ hi|]) / (o[3]/nr)
                    }
                    cv = _xbp_crit(lagcrit, o[3], nr, cols(X), p, tau)
                    if (cv != .) {
                        if (bc == . | cv < bc) {
                            bc   = cv
                            best = p
                        }
                    }
                }
            }
        }
        if (best < 1) {
            best = 1
        }
        X = _xbp_cadfX(el, deb, A, dA, D, lo, hi, best)
        y = deb[|lo \ hi|]
        o = _xbp_ols_t(y, X, 1, T, 0, cols(X))
        R[i] = o[2]
    }
    return(R)
}

real matrix _xbp_cadfX(real colvector el, real colvector deb, real matrix A,
                       real matrix dA, real matrix D, real scalar lo,
                       real scalar hi, real scalar p)
{
    real matrix X
    real scalar j
    X = el[|lo \ hi|], A[|lo,1 \ hi,.|], dA[|lo,1 \ hi,.|]
    if (cols(D) > 0) {
        X = X, D[|lo+1,1 \ hi+1,.|]
    }
    for (j=1; j<=p-1; j++) {
        X = X, deb[|lo-j \ hi-j|], dA[|lo-j,1 \ hi-j,.|]
    }
    return(X)
}

void _xbp_run_panic(string scalar vars, string scalar touse, real scalar N,
                    real scalar T, real scalar k, real scalar model,
                    string scalar meth, real scalar rfix, real scalar rmax,
                    string scalar nfac, real scalar pmax, real scalar fixlag,
                    string scalar lagcrit, real scalar nwbw,
                    string scalar savec,
                    string scalar sIC, string scalar sID, string scalar sGR,
                    string scalar sAD, string scalar sPV, string scalar sLG,
                    string scalar sQC, string scalar sQF, string scalar sAF,
                    string scalar sFH, string scalar sB,  string scalar sV,
                    string scalar sRH)
{
    real matrix Y, X, CSA, YH, dYH, dz, f, lam, Z, U, F, A, IC, MQC, MQF, V, CAd, RR
    real colvector b
    real scalar rhat, q
    string scalar dcase, nm

    _xbp_readdata(vars, touse, T, k, Y=., X=.)
    b   = _xbp_cce(Y, X, N, k, model, V=.)
    CSA = _xbp_csamat(Y, X, N, k)
    st_matrix(sB, b)
    st_matrix(sV, V)
    YH = _xbp_yhat(Y, X, N, k, b)

    // eq. (20)-(21): difference, then project out the deterministic component
    dYH = _xbp_diff(YH)
    if (model == 2) {
        dz = dYH :- mean(dYH)
    }
    else {
        dz = dYH
    }
    dcase = "c"
    if (model == 2) {
        dcase = "tau"
    }

    if (meth == "ca") {
        CAd = _xbp_diff(CSA)
        if (model == 2) {
            CAd = CAd :- mean(CAd)
        }
        IC = _xbp_rwic(dz, CAd, rmax, 1+k)
        if (rfix > 0) {
            rhat = rfix
        }
        else {
            if (nfac == "rw") {
                rhat = _xbp_pick(IC, 2, 0)
            }
            else {
                if (nfac == "ed") {
                    rhat = _xbp_ed(dz, rmax)
                }
                else {
                    RR   = _xbp_ictab(dz, rmax)
                    rhat = _xbp_pick(RR, _xbp_nfcol(nfac), _xbp_nfmax(nfac))
                }
            }
        }
        if (rhat < 1 | rhat == .) {
            rhat = 1
        }
        if (rhat > 1+k) {
            rhat = 1 + k
        }
        f   = CAd[|1,1 \ T-1,rhat|]
        lam = (invsym(quadcross(f,f))*quadcross(f,dz))'
        Z   = dz - f*lam'
    }
    else {
        IC = _xbp_ictab(dz, rmax)
        if (rfix > 0) {
            rhat = rfix
        }
        else {
            if (nfac == "ed") {
                rhat = _xbp_ed(dz, rmax)
            }
            else {
                rhat = _xbp_pick(IC, _xbp_nfcol(nfac), _xbp_nfmax(nfac))
            }
        }
        if (rhat < 1 | rhat == .) {
            rhat = 1
        }
        if (rhat > rmax) {
            rhat = rmax
        }
        _xbp_pca(dz, rhat, f=., lam=.)
        Z = dz - f*lam'
    }
    st_matrix(sIC, IC)
    st_matrix(sRH, rhat)

    F = _xbp_cumul(f)
    U = _xbp_cumul(Z)
    st_matrix(sFH, F)

    A = _xbp_adfu(U, pmax, fixlag, lagcrit, dcase)
    st_matrix(sAD, A[,1])
    st_matrix(sPV, A[,2])
    st_matrix(sLG, A[,3])
    st_matrix(sGR, _xbp_group(A, dcase))
    st_matrix(sID, _xbp_pooled(U, model, nwbw))

    if (rhat == 1) {
        st_matrix(sAF, _xbp_adff(F[,1], model, pmax, fixlag, lagcrit))
        st_matrix(sQC, J(1,4,.))
        st_matrix(sQF, J(1,4,.))
    }
    else {
        _xbp_mq(F, model, nwbw, pmax, lagcrit, MQC=., MQF=.)
        st_matrix(sQC, MQC)
        st_matrix(sQF, MQF)
        st_matrix(sAF, J(1,2,.))
    }

    if (savec != "") {
        nm = savec + "_u"
        if (_st_varindex(nm) == .) {
            st_addvar("double", nm)
        }
        st_store(., nm, touse, vec(U))
        for (q=1; q<=cols(F); q++) {
            nm = savec + "_f" + strofreal(q)
            if (_st_varindex(nm) == .) {
                st_addvar("double", nm)
            }
            st_store(., nm, touse, J(N,1,F[,q]))
        }
    }
}

real scalar _xbp_nfcol(string scalar nf)
{
    if (nf == "icp1") {
        return(2)
    }
    if (nf == "icp2") {
        return(3)
    }
    if (nf == "icp3") {
        return(4)
    }
    if (nf == "pcp1") {
        return(5)
    }
    if (nf == "pcp2") {
        return(6)
    }
    if (nf == "pcp3") {
        return(7)
    }
    if (nf == "aic3") {
        return(8)
    }
    if (nf == "bic3") {
        return(9)
    }
    if (nf == "er") {
        return(10)
    }
    return(11)
}

real scalar _xbp_nfmax(string scalar nf)
{
    if (nf == "er" | nf == "gr") {
        return(1)
    }
    return(0)
}

void _xbp_run_nfac(string scalar vars, string scalar touse, real scalar N,
                   real scalar T, real scalar k, real scalar model,
                   string scalar meth, real scalar rmax,
                   string scalar sIC, string scalar sRH)
{
    real matrix Y, X, YH, dYH, dz, V, R, CAd, CSA
    real colvector b
    real rowvector rh
    real scalar q

    _xbp_readdata(vars, touse, T, k, Y=., X=.)
    b   = _xbp_cce(Y, X, N, k, model, V=.)
    CSA = _xbp_csamat(Y, X, N, k)
    YH  = _xbp_yhat(Y, X, N, k, b)
    dYH = _xbp_diff(YH)
    if (model == 2) {
        dz = dYH :- mean(dYH)
    }
    else {
        dz = dYH
    }
    if (meth == "ca") {
        CAd = _xbp_diff(CSA)
        if (model == 2) {
            CAd = CAd :- mean(CAd)
        }
        R = _xbp_rwic(dz, CAd, rmax, 1+k)
        st_matrix(sIC, R)
        st_matrix(sRH, _xbp_pick(R, 2, 0))
        return
    }
    R  = _xbp_ictab(dz, rmax)
    rh = J(1,11,.)
    for (q=1; q<=8; q++) {
        rh[q] = _xbp_pick(R, q+1, 0)
    }
    rh[9]  = _xbp_pick(R, 10, 1)
    rh[10] = _xbp_pick(R, 11, 1)
    rh[11] = _xbp_ed(dz, rmax)
    st_matrix(sIC, R)
    st_matrix(sRH, rh)
}

end
