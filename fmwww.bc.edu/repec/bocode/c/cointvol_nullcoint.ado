*! cointvol_nullcoint 0.1.0  26sep2026
*! Tests of the null of (linear or nonlinear) cointegration robust to variance
*! breaks and nonstationary volatility (KPSS/Shin-type statistic, fixed-regressor
*! wild bootstrap)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!
*! Step -> source map (full map in cointvol_nullcoint.sthlp, section Methods):
*!   eta = (T^2 s2)^-1 sum_t (sum_{i<=t} u_i)^2 on OLS residuals
*!       -> Cavaliere & Taylor (2006, JTSA) eq (6); Shin (1994)
*!   fixed-regressor wild bootstrap y* = u z, z ~ N(0,1), fixed regressors,
*!       p = N^-1 sum 1(eta* >= eta)                -> C&T (2006) Section 4; Hansen (2000)
*!   h(t,x) = [1,t,..,t^q]delta + g(x,theta), g linear / polynomial / logistic STR /
*!       threshold                                   -> Hanck & Massing (2025) eqs (1)-(3), Sect. 4
*!   NLS eq (10); one-step DNLS eqs (18)-(21); eta_DNLS eq (22), N = T-2K-1
*!       -> Hanck & Massing (2025); Choi & Saikkonen (2010)
*!   Bartlett LRV, l = floor(4(T/100)^(1/4))         -> H&M Section 4.1; KPSS (1992)
*!   bootstrap on DNLS residuals, same LRV            -> H&M Section 3.4, Thm 3, Cor 1
*!   sieve wild bootstrap                             -> H&M Section 4.6 (exploratory)
*!   graph: empirical variance profile                -> H&M eq (28)
*!   simulated asymptotic critical values             -> homoskedastic limit, C&T (2006) eq (8)
*!   C, C_mu, C_tau = T^-2 sum S_t^2 / s2(l)          -> Shin (1994) eqs (6), (13)
*!   DOLS: K leads and K lags of dx                   -> Shin (1994) eqs (10)-(12); Saikkonen (1991)
*!   cv(shin): Table 1 critical values (m = 1..5; none/constant/trend), interpolated
*!       p-value between the 90-99% fractiles         -> Shin (1994) Table 1, Theorems 1-2
*!   method(cs): subresidual KPSS tests C^{b,i}_NLLS / C^{b,i}_LL, max over M blocks,
*!       Bonferroni with the cdf of int W^2          -> Choi & Saikkonen (2010) eqs (11)-(13),
*!       Theorem 1, Sect. 4.2.1 (blocks), 4.2.2 (minimum-volatility block size), Sect. 5 (QS)

program define cointvol_nullcoint, rclass
    version 14.0
    syntax varlist(numeric ts min=2) [if] [in] [,                          ///
        TRend(string) MODel(string) ESTimator(string) LEADs(integer -1)     ///
        LAGs(integer -1) CV(string)                                         ///
        LRV(string) BWidth(integer -1) BOOTstrap(string) Reps(integer 500)  ///
        SEED(string) Level(cilevel) MULTiplier(string) PVALue(string)       ///
        ASYReps(integer 5000) TRANSvar(varname numeric ts)                  ///
        SLope(numlist max=1 >0) TRIM(real 0.15) SIEVEmax(integer -1)        ///
        SAVing(string) NODOTS GRaph GRAPHName(string)                       ///
        METhod(string) BLOCK(numlist integer >0 max=2) MVwidth(integer 2)   ///
        CSLag(real 4) ]

    // ---------------- load / reload the Mata engines ----------------------
    // (Mata code in an autoloaded ado is private to that file, so each engine
    //  is -run- as a do-file, which compiles its functions globally.)
    capture mata: st_local("__cvver", cv_engine_version())
    if _rc {
        capture program drop cointvol_engine
        quietly findfile cointvol_engine.ado
        quietly run `"`r(fn)'"'
    }
    capture mata: st_local("__cvnver", cvn_version())
    if _rc | "`__cvnver'" != "0.1.1" {
        capture program drop cointvol_eng_nullcoint
        quietly findfile cointvol_eng_nullcoint.ado
        quietly run `"`r(fn)'"'
    }

    gettoken depvar indepvars : varlist
    local m : word count `indepvars'

    // ---------------- model() ---------------------------------------------
    local model = strtrim(`"`model'"')
    if `"`model'"' == "" local model "linear"
    local mlow = strlower(`"`model'"')
    local type 0
    local pd 1
    local qvar ""
    if inlist(`"`mlow'"', "lin", "line", "linea", "linear") {
        local type 1
        local mname "linear"
    }
    else if inlist(`"`mlow'"', "quad", "quadratic") {
        local type 1
        local pd 2
    }
    else if inlist(`"`mlow'"', "cubic") {
        local type 1
        local pd 3
    }
    else if regexm(`"`mlow'"', "^poly[a-z]*[ ]*\(?[ ]*([0-9]+)[ ]*\)?$") {
        local type 1
        local pd = real(regexs(1))
    }
    else if inlist(`"`mlow'"', "str", "lstr", "logistic", "smooth") {
        local type 2
    }
    else if regexm(`"`mlow'"', "^thr[a-z]*[ ]*\(") {
        local type 3
        local p1 = strpos(`"`model'"', "(")
        local qvar = substr(`"`model'"', `p1' + 1, .)
        local qvar = strtrim(subinstr(`"`qvar'"', ")", "", .))
        capture confirm numeric variable `qvar'
        if _rc {
            di as err "model(threshold(varname)): `qvar' is not a numeric variable"
            exit 198
        }
        unab qvar : `qvar'
    }
    if `type' == 0 {
        di as err "model() must be linear, poly(#), quadratic, cubic, str or threshold(varname)"
        exit 198
    }
    if `type' == 1 {
        if `pd' < 1 | `pd' > 6 {
            di as err "model(poly(#)): the degree must be between 1 and 6"
            exit 198
        }
        if `pd' == 1 local mname "linear"
        else local mname "polynomial of degree `pd'"
    }

    // ---------------- trend() (deterministic polynomial degree q) -----------
    local trend = strlower(strtrim(`"`trend'"'))
    if `"`trend'"' == "" local trend "constant"
    if inlist(`"`trend'"', "n", "no", "non", "none") {
        local qd -1
        local tlab "none"
    }
    else if inlist(`"`trend'"', "c", "co", "con", "cons", "const", "constant") {
        local qd 0
        local tlab "constant"
    }
    else if inlist(`"`trend'"', "t", "tr", "tre", "tren", "trend", "linear") {
        local qd 1
        local tlab "constant + linear trend"
    }
    else {
        capture confirm integer number `trend'
        if _rc {
            di as err "trend() must be none, constant, trend or an integer degree 0,...,4"
            exit 198
        }
        local qd = `trend'
        if `qd' < 0 | `qd' > 4 {
            di as err "trend(#): the polynomial degree must lie in 0,...,4"
            exit 198
        }
        if `qd' == 0 local tlab "constant"
        else if `qd' == 1 local tlab "constant + linear trend"
        else local tlab "polynomial trend of degree `qd'"
    }
    if `qd' == -1 local trend "none"
    else if `qd' == 0 local trend "constant"
    else if `qd' == 1 local trend "trend"
    else local trend "`qd'"

    // ---------------- estimator() -----------------------------------------
    local estimator = strlower(strtrim(`"`estimator'"'))
    if `"`estimator'"' == "" {
        if `type' == 3 local estimator "static"
        else local estimator "dnls"
    }
    if inlist(`"`estimator'"', "ols", "nls", "static", "stat") local estimator "static"
    else if inlist(`"`estimator'"', "dnls", "dols", "dynamic", "dyn") local estimator "dnls"
    else {
        di as err "estimator() must be ols (nls, static) or dnls (dols)"
        exit 198
    }
    local dn = ("`estimator'" == "dnls")
    if `type' == 3 & `dn' {
        di as err "the threshold model is estimated by grid-search NLS only; use estimator(nls)"
        di as err "(Hanck & Massing 2025, Section 4.4, use NLS residuals for this model)"
        exit 198
    }
    if `dn' {
        // K leads and K lags by default (Shin 1994 eqs 10-12; H&M eq 18);
        // leads() alone or lags() alone sets both
        if `leads' == -1 & `lags' == -1 {
            local leads 1
            local lags 1
        }
        else if `leads' == -1 {
            local leads = `lags'
        }
        else if `lags' == -1 {
            local lags = `leads'
        }
        if `leads' < 0 {
            di as err "leads() must be a non-negative integer"
            exit 198
        }
        if `lags' < 0 {
            di as err "lags() must be a non-negative integer"
            exit 198
        }
    }
    else {
        if `leads' != -1 | `lags' != -1 {
            di as txt "(note: leads() and lags() are ignored with estimator(`estimator'))"
        }
        local leads 0
        local lags 0
    }

    // ---------------- method(): full-residual KPSS or Choi-Saikkonen -------
    local method = strlower(strtrim(`"`method'"'))
    if `"`method'"' == "" local method "kpss"
    if inlist(`"`method'"', "kpss", "shin", "full") local method "kpss"
    else if inlist(`"`method'"', "cs", "choi", "choisaikkonen", "subresidual", "sub") local method "cs"
    else {
        di as err "method() must be kpss or cs"
        exit 198
    }
    local iscs = ("`method'" == "cs")
    if `iscs' & `type' == 3 {
        di as err "method(cs) requires a smooth g(x,theta) (Choi & Saikkonen 2010, Assumption 4);"
        di as err "it is not available for model(threshold())"
        exit 198
    }
    if !`iscs' & ("`block'" != "" | `mvwidth' != 2 | `cslag' != 4) {
        di as err "block(), mvwidth() and cslag() are only allowed with method(cs)"
        exit 198
    }
    if `iscs' {
        if `mvwidth' < 1 {
            di as err "mvwidth() must be a positive integer"
            exit 198
        }
        if `cslag' <= 0 {
            di as err "cslag() must be positive"
            exit 198
        }
    }

    // ---------------- lrv(), bootstrap(), multiplier(), pvalue() -----------
    local lrv = strlower(strtrim(`"`lrv'"'))
    if `"`lrv'"' == "" {
        if `iscs' local lrv "qs"
        else local lrv "bartlett"
    }
    if inlist(`"`lrv'"', "bartlett", "bart", "nw", "kpss", "hac") local lrv "bartlett"
    else if inlist(`"`lrv'"', "ols", "iid", "var", "variance", "s2") local lrv "ols"
    else if inlist(`"`lrv'"', "qs", "quadratic", "quadraticspectral", "andrews") local lrv "qs"
    else {
        di as err "lrv() must be bartlett, qs or ols"
        exit 198
    }
    local lrvt 0
    if "`lrv'" == "bartlett" local lrvt 1
    if "`lrv'" == "qs"       local lrvt 2

    local bootstrap = strlower(strtrim(`"`bootstrap'"'))
    if `iscs' {
        if !inlist(`"`bootstrap'"', "", "none", "no", "asy") {
            di as err "bootstrap() is not available with method(cs): inference is by the"
            di as err "Bonferroni procedure of Choi & Saikkonen (2010); specify bootstrap(none) or omit it"
            exit 198
        }
        local bootstrap "none"
    }
    if `"`bootstrap'"' == "" local bootstrap "frwild"
    if inlist(`"`bootstrap'"', "frwild", "wild", "fr", "fixed") local bootstrap "frwild"
    else if inlist(`"`bootstrap'"', "sieve", "sievewild") local bootstrap "sieve"
    else if inlist(`"`bootstrap'"', "none", "no", "asy") local bootstrap "none"
    else {
        di as err "bootstrap() must be frwild, sieve or none"
        exit 198
    }
    local multiplier = strlower(strtrim(`"`multiplier'"'))
    if `"`multiplier'"' == "" local multiplier "gauss"
    if inlist(`"`multiplier'"', "gaussian", "normal", "n") local multiplier "gauss"
    if inlist(`"`multiplier'"', "rad", "r")                 local multiplier "rademacher"
    if inlist(`"`multiplier'"', "mam", "m")                 local multiplier "mammen"
    if !inlist(`"`multiplier'"', "gauss", "rademacher", "mammen") {
        di as err "multiplier() must be gauss, rademacher or mammen"
        exit 198
    }
    local pvalue = strlower(strtrim(`"`pvalue'"'))
    if `"`pvalue'"' == "" local pvalue "weak"
    if !inlist(`"`pvalue'"', "weak", "strict", "plusone") {
        di as err "pvalue() must be weak, strict or plusone"
        exit 198
    }
    if "`bootstrap'" != "none" & `reps' < 19 {
        di as err "reps() must be at least 19"
        exit 198
    }
    if `asyreps' < 0 | (`asyreps' > 0 & `asyreps' < 100) {
        di as err "asyreps() must be 0 (no simulation) or at least 100"
        exit 198
    }
    if `trim' <= 0 | `trim' >= 0.5 {
        di as err "trim() must lie strictly between 0 and 0.5"
        exit 198
    }

    // ---------------- cv(): asymptotic reference distribution --------------
    // shin: Shin (1994) Table 1 (linear model, m = 1..5, trend none/constant/trend)
    // sim : simulated homoskedastic limit (asyreps() draws)
    local cvuser = strtrim(`"`cv'"')
    local cv = strlower(`"`cvuser'"')
    local cvtab = (`type' == 1 & `pd' == 1 & `qd' <= 1 & `m' >= 1 & `m' <= 5)
    if `"`cv'"' == "" {
        if `cvtab' local cv "shin"
        else local cv "sim"
    }
    if inlist(`"`cv'"', "shin", "table", "tab", "shin1994") local cv "shin"
    else if inlist(`"`cv'"', "sim", "simul", "simulate", "simulated") local cv "sim"
    else {
        di as err "cv() must be shin or sim"
        exit 198
    }
    if "`cv'" == "shin" & !`cvtab' {
        di as err "cv(shin): Shin (1994, Table 1) tabulates model(linear) with 1 to 5 regressors"
        di as err "and trend(none), trend(constant) or trend(trend) only; use cv(sim) or the bootstrap"
        exit 198
    }
    if `"`cvuser'"' != "" & !(`type' == 1 & `pd' == 1) {
        di as txt "(note: asymptotic critical values are only available for model(linear); cv() ignored)"
    }

    // ---------------- STR options -------------------------------------------
    local tidx 0
    local slv .
    if `type' == 2 {
        if "`transvar'" == "" {
            local transvar : word 1 of `indepvars'
        }
        local tidx : list posof "`transvar'" in indepvars
        if `tidx' == 0 {
            di as err "transvar(): `transvar' must be one of the regressors (`indepvars')"
            exit 198
        }
        if "`slope'" != "" local slv = `slope'
        local mname "logistic smooth transition in `transvar'"
    }
    else {
        if "`transvar'" != "" {
            di as err "transvar() is only allowed with model(str)"
            exit 198
        }
        if "`slope'" != "" {
            di as err "slope() is only allowed with model(str)"
            exit 198
        }
    }

    // ---------------- sample and time-series checks ------------------------
    qui tsset
    local tvar  "`r(timevar)'"
    local pvar  "`r(panelvar)'"
    local tdelta = r(tdelta)
    local tfmt  "`r(tsfmt)'"
    if "`pvar'" != "" {
        di as err "cointvol nullcoint requires time-series data; the data are xtset as a panel"
        exit 459
    }
    marksample touse
    local qlag ""
    if `type' == 3 {
        tsrevar L.`qvar'
        local qlag "`r(varlist)'"
        markout `touse' `qlag'
        local mname "threshold in L.`qvar' (trim `trim')"
    }
    qui count if `touse'
    local T = r(N)
    if `T' == 0 {
        error 2000
    }
    qui summarize `tvar' if `touse', meanonly
    local tmin = r(min)
    local tmax = r(max)
    if (`tmax' - `tmin')/`tdelta' + 1 != `T' {
        di as err "the estimation sample contains gaps; cointvol nullcoint needs consecutive observations"
        exit 498
    }

    // number of parameters
    local nz = `qd' + 1
    if `type' == 1 local kpar = `nz' + `m'*`pd'
    if `type' == 2 local kpar = `nz' + `m' + 2 + ("`slope'" == "")
    if `type' == 3 local kpar = `nz' + 2*`m' + 1
    local Nres = `T'
    if `dn' local Nres = `T' - `leads' - `lags' - 1
    local kreg = `kpar' + `dn'*`m'*(`leads' + `lags' + 1)
    if `T' < 20 | `Nres' < `kreg' + 10 {
        di as err "too few observations (T = `T') for `kreg' regressors" _c
        if `dn' di as err " and `leads' leads / `lags' lags"
        else di as err ""
        exit 2001
    }
    if `bwidth' == -1 {
        local bwidth = floor(4 * (`T'/100)^0.25)
    }
    if `bwidth' < 0 {
        di as err "bwidth() must be a non-negative integer"
        exit 198
    }
    if `sievemax' == -1 {
        local sievemax = floor(4 * (`T'/100)^0.25)
    }
    if `sievemax' < 0 {
        di as err "sievemax() must be a non-negative integer"
        exit 198
    }

    // Choi & Saikkonen (2010) block size: fixed b, or the minimum-volatility rule
    // over [bmin, bmax], default [floor(T^0.7), floor(T^0.9)] (C&S Sect. 4.2.2)
    local csbfix .
    local csbmin .
    local csbmax .
    if `iscs' {
        local nbl : word count `block'
        if `nbl' == 1 {
            local csbfix = `block'
            if `csbfix' < 10 | `csbfix' > `Nres' {
                di as err "block(#): the block size must lie between 10 and the number of residuals (`Nres')"
                exit 198
            }
        }
        else {
            if `nbl' == 2 {
                local csbmin : word 1 of `block'
                local csbmax : word 2 of `block'
                if `csbmin' >= `csbmax' {
                    di as err "block(# #): the lower bound must be smaller than the upper bound"
                    exit 198
                }
            }
            else {
                local csbmin = floor(`T'^0.7)
                local csbmax = floor(`T'^0.9)
            }
            if `csbmax' + `mvwidth' > `Nres' local csbmax = `Nres' - `mvwidth'
            if `csbmin' - `mvwidth' < 10 local csbmin = 10 + `mvwidth'
            if `csbmin' > `csbmax' {
                di as err "too few residuals (`Nres') for the minimum-volatility block-size search;"
                di as err "specify a fixed block size with block(#)"
                exit 2001
            }
        }
    }

    // seed
    if `"`seed'"' != "" {
        set seed `seed'
    }
    local seeduse `"`seed'"'
    if `"`seeduse'"' == "" local seeduse "(current RNG state)"

    // ts-operated variables -> temporary variables for Mata
    tsrevar `depvar'
    local my "`r(varlist)'"
    tsrevar `indepvars'
    local mx "`r(varlist)'"

    local dots = ("`nodots'" == "") & ("`bootstrap'" != "none")
    if `dots' {
        di as txt _n "Bootstrap replications (" as res `reps' as txt "), one dot = 50:"
    }
    mata: cvn_main("`my'", "`mx'", "`qlag'", "`touse'", `type', `pd', `tidx', `slv', ///
        `trim', `qd', `dn', `leads', `lags', `lrvt', `bwidth', "`bootstrap'", "`multiplier'", ///
        `reps', "`pvalue'", `dots', `sievemax', `iscs', `csbfix', `csbmin', `csbmax', ///
        `mvwidth', `cslag')

    tempname bvec bcv prof boot stats asy shtab
    matrix `bvec' = __cvn_b
    matrix `bcv'  = __cvn_bcv
    matrix `prof' = __cvn_prof
    local eta   = scalar(__cvn_eta)
    local pboot = scalar(__cvn_pb)
    local om2   = scalar(__cvn_om2)
    local N     = scalar(__cvn_N)
    local ssr   = scalar(__cvn_ssr)
    local fails = scalar(__cvn_fails)
    local psel  = scalar(__cvn_psel)
    capture matrix drop __cvn_b __cvn_bcv __cvn_prof
    capture scalar drop __cvn_eta __cvn_pb __cvn_om2 __cvn_N __cvn_T __cvn_ssr ///
        __cvn_fails __cvn_psel
    if "`bootstrap'" != "none" {
        matrix `boot' = __cvn_boot
        capture matrix drop __cvn_boot
        matrix colnames `boot' = eta_boot
    }
    tempname csr csblk csmv
    if `iscs' {
        matrix `csr'   = __cvn_cs
        matrix `csblk' = __cvn_csblk
        matrix `csmv'  = __cvn_csmv
        capture matrix drop __cvn_cs __cvn_csblk __cvn_csmv
        local cs_stat = `csr'[1, 1]
        local cs_p    = `csr'[1, 2]
        local cs_pb   = `csr'[1, 3]
        local cs_b    = `csr'[1, 4]
        local cs_M    = `csr'[1, 5]
        local cs_bw   = `csr'[1, 6]
        local cs_cv10 = `csr'[1, 7]
        local cs_cv5  = `csr'[1, 8]
        local cs_cv25 = `csr'[1, 9]
        local cs_cv1  = `csr'[1, 10]
        matrix colnames `csblk' = start end stat p
        local rn ""
        forvalues j = 1/`=rowsof(`csblk')' {
            local rn "`rn' block`j'"
        }
        matrix rownames `csblk' = `rn'
        matrix colnames `csmv' = b sc
    }

    // ---------------- asymptotic reference distribution (linear model) -----
    // cv(shin): Shin (1994) Table 1, p-value by linear interpolation between the
    //           0.90/0.95/0.975/0.99 fractiles, bounds outside that range
    // cv(sim) : homoskedastic Shin (1994) limit simulated with a fixed internal
    //           seed, so that the critical values do not depend on (and do not
    //           disturb) the user's RNG
    local pasy   = .
    local pbound = .
    local cva10  = .
    local cva5   = .
    local cva2p5 = .
    local cva1   = .
    local cvlev  = .
    local doasy = (`type' == 1 & `pd' == 1 & !`iscs')
    if "`cv'" == "sim" & `asyreps' == 0 local doasy 0
    if `doasy' & "`cv'" == "shin" {
        mata: cvn_shin(`eta', `m', `qd', `level')
        matrix `asy'   = __cvn_shin
        matrix `shtab' = __cvn_shintab
        capture matrix drop __cvn_shin __cvn_shintab
        matrix colnames `shtab' = fractile m1 m2 m3 m4 m5
        matrix rownames `shtab' = q01 q025 q05 q10 q20 q30 q40 q50 q60 q70 q80 q90 q95 q975 q99
        local pasy   = `asy'[1, 1]
        local pbound = `asy'[1, 2]
        local cva10  = `asy'[1, 3]
        local cva5   = `asy'[1, 4]
        local cva2p5 = `asy'[1, 5]
        local cva1   = `asy'[1, 6]
        local cvlev  = `asy'[1, 7]
    }
    else if `doasy' {
        local rngst "`c(rngstate)'"
        set seed 19940101
        mata: cvn_asy(`eta', `m', `qd', `asyreps', 500)
        set rngstate `rngst'
        matrix `asy' = __cvn_asy
        capture matrix drop __cvn_asy
        local pasy   = `asy'[1, 1]
        local cva10  = `asy'[1, 2]
        local cva5   = `asy'[1, 3]
        local cva2p5 = `asy'[1, 4]
        local cva1   = `asy'[1, 5]
    }
    local cvb10  = `bcv'[1, 1]
    local cvb5   = `bcv'[1, 2]
    local cvb2p5 = `bcv'[1, 3]
    local cvb1   = `bcv'[1, 4]
    local cvused "none"
    if `doasy' local cvused "`cv'"

    matrix `stats' = (`eta', `pboot', `pasy', `cvb10', `cvb5', `cvb1', `cva10', `cva5', `cva1', ///
        `cvb2p5', `cva2p5')
    matrix colnames `stats' = eta p_boot p_asy cv10_boot cv5_boot cv1_boot cv10_asy cv5_asy ///
        cv1_asy cv2p5_boot cv2p5_asy
    matrix rownames `stats' = eta

    // ---------------- parameter names --------------------------------------
    local pnames ""
    if `qd' >= 0 local pnames "_cons"
    if `qd' >= 1 local pnames "`pnames' trend"
    forvalues j = 2/`qd' {
        local pnames "`pnames' trend_p`j'"
    }
    local xnames ""
    foreach v of local indepvars {
        local nm = strtoname("`v'")
        local xnames "`xnames' `nm'"
    }
    if `type' == 1 {
        foreach v of local xnames {
            local pnames "`pnames' `v'"
            forvalues j = 2/`pd' {
                local pnames "`pnames' `v'_p`j'"
            }
        }
    }
    if `type' == 2 {
        local pnames "`pnames' `xnames' str_coef str_loc"
        if "`slope'" == "" local pnames "`pnames' str_slope"
    }
    if `type' == 3 {
        local pnames "`pnames' `xnames'"
        foreach v of local xnames {
            local pnames "`pnames' `v'_thr"
        }
        local pnames "`pnames' thr_c"
    }
    local npar : word count `pnames'
    if `npar' != colsof(`bvec') {
        local pnames ""
        forvalues j = 1/`=colsof(`bvec')' {
            local pnames "`pnames' p`j'"
        }
    }
    matrix colnames `bvec' = `pnames'
    local nm = strtoname("`depvar'")
    matrix rownames `bvec' = `nm'
    matrix colnames `prof' = s rho
    local k = colsof(`bvec')

    // ---------------- labels -------------------------------------------------
    if `leads' == `lags' local kl "K = `leads' leads and lags"
    else local kl "`leads' leads and `lags' lags"
    if `type' == 1 & `dn' == 0 local elab "OLS (static)"
    if `type' == 1 & `dn' == 1 local elab "DOLS (Saikkonen 1991; Shin 1994), `kl'"
    if `type' == 2 & `dn' == 0 local elab "NLS (Levenberg-Marquardt)"
    if `type' == 2 & `dn' == 1 local elab "one-step DNLS, `kl'"
    if `type' == 3 local elab "NLS (grid search over threshold, OLS for slopes)"
    if "`lrv'" == "bartlett" local llab "Bartlett kernel, bandwidth = `bwidth'"
    if "`lrv'" == "ols"      local llab "residual variance (no HAC correction)"
    if "`lrv'" == "qs"       local llab "quadratic spectral kernel, bandwidth = `bwidth'"
    if "`bootstrap'" == "frwild" local blab "fixed-regressor wild (`multiplier')"
    if "`bootstrap'" == "sieve"  local blab "sieve wild, VAR(`psel') by AIC (exploratory)"
    if "`bootstrap'" == "none"   local blab "none"
    local s1 = `tmin' + (`T' - `Nres' - `leads')*`tdelta'
    if `dn' == 0 local s1 = `tmin'
    local s2 = `tmax' - `leads'*`tdelta'
    local sfrom : display `tfmt' `s1'
    local sto   : display `tfmt' `s2'
    local eta_l = 1 - `level'/100
    local lev   : display %4.3g 100 - `level'
    local lev = strtrim("`lev'")

    // ---------------- output: header -------------------------------------
    di
    if `iscs' local ttl "Test of the null of cointegration (Choi-Saikkonen)"
    else local ttl "Test of the null of cointegration (KPSS/Shin type)"
    di as txt "`ttl'" _col(52) "Residual obs   = " as res %9.0f `N'
    di as txt "Sample: " as res "`sfrom' - `sto'" as txt _col(52) "Sample size T  = " as res %9.0f `T'
    di as txt "Dependent variable: " as res abbrev("`depvar'", 24) ///
        as txt _col(52) "Regressors     = " as res %9.0f `m'
    di as txt "Model g(x): " as res "`mname'"
    di as txt "Deterministic: " as res "`tlab'"
    di as txt "Estimator: " as res "`elab'"
    di as txt "Long-run variance: " as res "`llab'"
    if "`bootstrap'" != "none" {
        di as txt "Bootstrap: " as res "`blab'" as txt "   B = " as res `reps' ///
            as txt "   Seed: " as res `"`seeduse'"'
    }

    // ---------------- output: parameter estimates ---------------------------
    di
    di as txt "{hline 20}{c TT}{hline 14}"
    di as txt _col(2) "Parameter" _col(21) "{c |}" _col(25) "Estimate"
    di as txt "{hline 20}{c +}{hline 14}"
    forvalues j = 1/`k' {
        local nm : word `j' of `pnames'
        di as txt _col(2) abbrev("`nm'", 18) _col(21) "{c |}" as res _col(23) %12.0g `bvec'[1, `j']
    }
    di as txt "{hline 20}{c BT}{hline 14}"
    if `dn' {
        di as txt "(leads/lags coefficients of the dynamic regression not shown)"
    }

    // ---------------- output: Choi & Saikkonen (2010) subresidual test -------
    if `iscs' {
        if `dn' {
            local csname "C_LL^max"
            local csfull "C_LL (C&S eq. 10)"
            local csoff = `lags' + 1
        }
        else {
            local csname "C_NLLS^max"
            local csfull "C_NLLS (C&S eq. 9)"
            local csoff 0
        }
        local scs = cond(`cs_pb' < . & `cs_pb' <= `eta_l', "*", " ")
        di
        di as txt "{hline 12}{c TT}{hline 11}{c TT}{hline 34}{c TT}{hline 9}{c TT}{hline 9}"
        di as txt _col(2) "Test" _col(13) "{c |}" _col(15) "Statistic" _col(25) "{c |}"   ///
            _col(29) "cv 10%" _col(38) "cv 5%" _col(44) "cv 2.5%" _col(54) "cv 1%"       ///
            _col(60) "{c |}" _col(62) "p-value" _col(70) "{c |}" _col(72) "Bonf. p"
        di as txt "{hline 12}{c +}{hline 11}{c +}{hline 34}{c +}{hline 9}{c +}{hline 9}"
        di as txt _col(2) "`csname'" _col(13) "{c |}" as res _col(15) %9.4f `cs_stat'     ///
            as txt _col(25) "{c |}" as res _col(27) %8.4f `cs_cv10' _col(35) %8.4f `cs_cv5' ///
            _col(43) %8.4f `cs_cv25' _col(51) %8.4f `cs_cv1'                              ///
            as txt _col(60) "{c |}" as res _col(62) %7.4f `cs_p'                          ///
            as txt _col(70) "{c |}" as res _col(72) %7.4f `cs_pb' as txt "`scs'"
        di as txt "{hline 12}{c BT}{hline 11}{c BT}{hline 34}{c BT}{hline 9}{c BT}{hline 9}"
        di as txt "H0: (nonlinear) cointegration; H1: no cointegration.  Upper-tail test."
        di as txt "* rejects H0 at the `lev'% level: p-value <= " as res "`lev'" as txt "%/M."
        if `csbfix' < . {
            di as txt "Block size b = " as res `cs_b' as txt " (fixed); M = " as res `cs_M' ///
                as txt " subresidual tests (C&S Sect. 4.2.1)."
        }
        else {
            di as txt "Block size b = " as res `cs_b' as txt " (minimum-volatility rule over [" ///
                as res `csbmin' as txt ", " as res `csbmax' as txt "], m = " as res `mvwidth' ///
                as txt "); M = " as res `cs_M' as txt " tests."
        }
        if "`lrv'" == "qs" local klab "quadratic spectral"
        if "`lrv'" == "bartlett" local klab "Bartlett"
        if "`lrv'" == "ols" local klab "none (residual variance)"
        di as txt "Block long-run variance: " as res "`klab'" as txt ", bandwidth floor(" ///
            as res `cslag' as txt "(b/100)^(1/4)) = " as res `cs_bw' as txt "."
        di as txt "p-value = 1 - F(stat), F = cdf of int W^2 (C&S eq. 13); cv = alpha/M quantiles;"
        di as txt "   Bonf. p = min(1, M p) (Choi & Saikkonen 2010, Theorem 1, Sect. 4.2)."
        di as txt "Full-residual statistic `csfull' = " as res %9.4f `eta' ///
            as txt " (non-pivotal limit, C&S Lemma A.3)."
        di
        di as txt "{hline 7}{c TT}{hline 29}{c TT}{hline 22}"
        di as txt _col(2) "Block" _col(8) "{c |}" _col(11) "Residual span (time)" _col(38) "{c |}" ///
            _col(40) "Statistic" _col(52) "p-value"
        di as txt "{hline 7}{c +}{hline 29}{c +}{hline 22}"
        forvalues j = 1/`cs_M' {
            local a1 = `tmin' + (`csblk'[`j', 1] + `csoff' - 1)*`tdelta'
            local a2 = `tmin' + (`csblk'[`j', 2] + `csoff' - 1)*`tdelta'
            local a1 : display `tfmt' `a1'
            local a2 : display `tfmt' `a2'
            local a1 = strtrim("`a1'")
            local a2 = strtrim("`a2'")
            di as txt _col(2) %4.0f `j' _col(8) "{c |}" as res _col(10) %12s "`a1'" ///
                as txt " - " as res %12s "`a2'" as txt _col(38) "{c |}"          ///
                as res _col(40) %9.4f `csblk'[`j', 3] _col(52) %7.4f `csblk'[`j', 4]
        }
        di as txt "{hline 7}{c BT}{hline 29}{c BT}{hline 22}"
        di as txt "Critical values assume a constant variance; they are not robust to variance breaks."
    }

    // ---------------- output: test table ------------------------------------
    if !`iscs' {
    local sb = cond(`pboot' < `eta_l' & `pboot' < ., "*", " ")
    if "`cvused'" == "shin" {
        // reject when eta exceeds the Table 1 value interpolated at fractile level/100
        local sa = cond(`eta' < . & `cvlev' < . & `eta' > `cvlev', "*", " ")
        if `pbound' == 1 local pas ">0.100"
        else if `pbound' == -1 local pas "<0.010"
        else local pas : display %6.3f `pasy'
    }
    else {
        local sa = cond(`pasy' < `eta_l' & `pasy' < ., "*", " ")
        local pas : display %6.3f `pasy'
    }
    di
    di as txt "{hline 19}{c TT}{hline 11}{c TT}{hline 34}{c TT}{hline 9}"
    di as txt _col(2) "Inference" _col(20) "{c |}" _col(22) "Statistic" _col(32) "{c |}" ///
        _col(36) "cv 10%" _col(45) "cv 5%" _col(51) "cv 2.5%" _col(61) "cv 1%"     ///
        _col(67) "{c |}" _col(69) "p-value"
    di as txt "{hline 19}{c +}{hline 11}{c +}{hline 34}{c +}{hline 9}"
    if "`bootstrap'" != "none" {
        if "`bootstrap'" == "frwild" local rl "FR wild bootstrap"
        else local rl "Sieve wild boot."
        di as txt _col(2) "`rl'" _col(20) "{c |}" as res _col(22) %9.4f `eta'          ///
            as txt _col(32) "{c |}" as res _col(34) %8.4f `cvb10' _col(42) %8.4f `cvb5' ///
            _col(50) %8.4f `cvb2p5' _col(58) %8.4f `cvb1'                              ///
            as txt _col(67) "{c |}" as res _col(69) %6.3f `pboot' as txt "`sb'"
    }
    if `doasy' {
        if "`cvused'" == "shin" local rl "Shin (1994) Tab. 1"
        else local rl "Asympt. (simul.)"
        di as txt _col(2) "`rl'" _col(20) "{c |}" as res _col(22) %9.4f `eta'          ///
            as txt _col(32) "{c |}" as res _col(34) %8.4f `cva10' _col(42) %8.4f `cva5' ///
            _col(50) %8.4f `cva2p5' _col(58) %8.4f `cva1'                              ///
            as txt _col(67) "{c |}" as res _col(69) "`pas'" as txt "`sa'"
    }
    if "`bootstrap'" == "none" & !`doasy' {
        di as txt _col(2) "(no inference)" _col(20) "{c |}" as res _col(22) %9.4f `eta' ///
            as txt _col(32) "{c |}" _col(67) "{c |}"
    }
    di as txt "{hline 19}{c BT}{hline 11}{c BT}{hline 34}{c BT}{hline 9}"
    di as txt "H0: cointegration (I(0) regression errors); H1: no cointegration."
    di as txt "* rejects H0 at the `lev'% level.  Upper-tail test."
    if "`bootstrap'" == "frwild" {
        if `dn' local rr "DNLS residuals (Hanck & Massing 2025)"
        else local rr "static residuals (Cavaliere & Taylor 2006)"
        di as txt "Bootstrap: y* = " cond(`type' == 1, "e*z", "h(t,x;theta) + e*z") ///
            " on fixed regressors, `rr';"
        di as txt "   valid under variance breaks / nonstationary volatility."
    }
    if "`bootstrap'" == "sieve" {
        di as txt "Sieve wild bootstrap: exploratory (Hanck & Massing 2025, Sect. 4.6);"
        di as txt "   no asymptotic theory."
    }
    if "`cvused'" == "shin" {
        if `qd' == -1 local shcase "standard C (no deterministics)"
        if `qd' == 0  local shcase "demeaned C_mu"
        if `qd' == 1  local shcase "detrended C_tau"
        di as txt "Asymptotic: Shin (1994) Table 1, " as res "`shcase'" as txt ", m = " as res `m' ///
            as txt "; p-value interpolated"
        di as txt "   between the 90-99% fractiles, bounds outside. Homoskedastic limit:"
        di as txt "   invalid under variance breaks (Cavaliere & Taylor 2006); use the bootstrap."
        if !`dn' {
            di as txt "   Static OLS residuals: Shin's Theorem 1 needs strictly exogenous regressors;"
            di as txt "   use the DOLS estimator (Theorem 2) otherwise."
        }
        if `cvlev' >= . {
            di as txt "   (level(`level') lies outside the tabulated fractiles: no star from Table 1)"
        }
    }
    else if `doasy' {
        di as txt "Asymptotic: Shin (1994) homoskedastic limit simulated (T = 500, " ///
            as res `asyreps' as txt " draws);"
        di as txt "   invalid under variance breaks (Cavaliere & Taylor 2006)."
    }
    }
    if `fails' > 0 {
        di as txt "Note: " as res `fails' as txt " bootstrap sample(s) failed (NLS non-convergence) and were redrawn."
    }

    // ---------------- graph / saving (before return matrix moves) ----------
    if "`graph'" != "" {
        preserve
        qui clear
        qui svmat double `prof', name(vp)
        if `"`graphname'"' == "" local graphname "cointvol_nullcoint"
        twoway (line vp2 vp1, lcolor(navy) lwidth(medthick))                         ///
            (function y = x, range(0 1) lcolor(cranberry) lpattern(dash)),            ///
            title("Empirical variance profile of the residuals", size(medium))        ///
            subtitle("`elab'", size(small))                                           ///
            xtitle("s (fraction of the sample)", size(small))                         ///
            ytitle("variance profile rho(s)", size(small))                            ///
            legend(order(1 "estimated profile" 2 "homoskedasticity (45-degree line)") ///
                size(small) rows(1)) xlabel(0(0.2)1) ylabel(0(0.2)1, angle(0))        ///
            note("Hanck & Massing (2025) eq. (28); deviations from the diagonal indicate variance changes.", ///
                size(vsmall)) graphregion(color(white)) plotregion(color(white))      ///
            name(`graphname', replace)
        restore
    }
    if `"`saving'"' != "" & "`bootstrap'" != "none" {
        preserve
        qui clear
        qui svmat double `boot', names(col)
        qui gen long rep = _n
        order rep
        label variable eta_boot "bootstrap KPSS/Shin statistic"
        qui save `saving'
        restore
    }
    else if `"`saving'"' != "" {
        di as txt "(note: saving() ignored with bootstrap(none))"
    }

    // ---------------- stored results --------------------------------------
    return scalar eta       = `eta'
    return scalar p_boot    = `pboot'
    return scalar p_asy     = `pasy'
    return scalar cv_boot_10 = `cvb10'
    return scalar cv_boot_5  = `cvb5'
    return scalar cv_boot_1  = `cvb1'
    return scalar cv_asy_10  = `cva10'
    return scalar cv_asy_5   = `cva5'
    return scalar cv_asy_1   = `cva1'
    return scalar cv_boot_2p5 = `cvb2p5'
    return scalar cv_asy_2p5  = `cva2p5'
    return scalar p_asy_bound = `pbound'
    return scalar omega2    = `om2'
    return scalar ssr       = `ssr'
    return scalar N         = `N'
    return scalar T         = `T'
    return scalar m         = `m'
    return scalar K         = `leads'
    return scalar lags      = `lags'
    return scalar bwidth    = `bwidth'
    return scalar level     = `level'
    if `iscs' {
        return scalar cs_stat  = `cs_stat'
        return scalar cs_p     = `cs_p'
        return scalar cs_pbonf = `cs_pb'
        return scalar cs_b     = `cs_b'
        return scalar cs_M     = `cs_M'
        return scalar cs_bw    = `cs_bw'
        return scalar cs_cv10  = `cs_cv10'
        return scalar cs_cv5   = `cs_cv5'
        return scalar cs_cv2p5 = `cs_cv25'
        return scalar cs_cv1   = `cs_cv1'
        return scalar cslag    = `cslag'
        if `csbfix' >= . {
            return scalar cs_bmin = `csbmin'
            return scalar cs_bmax = `csbmax'
            return scalar mvwidth = `mvwidth'
        }
    }
    if "`bootstrap'" != "none" {
        return scalar reps  = `reps'
        return scalar fails = `fails'
    }
    if "`bootstrap'" == "sieve" {
        return scalar sieve_p = `psel'
    }
    if `doasy' {
        return scalar asyreps = `asyreps'
    }
    if `type' == 1 & `pd' > 1 {
        return scalar degree = `pd'
    }
    if `type' == 2 & "`slope'" != "" {
        return scalar slope = `slv'
    }
    if `type' == 3 {
        return scalar threshold = `bvec'[1, `k']
        return scalar trim      = `trim'
    }
    return local depvar     "`depvar'"
    return local indepvars  "`indepvars'"
    return local model      "`mname'"
    return local trend      "`trend'"
    return local estimator  "`estimator'"
    return local lrv        "`lrv'"
    return local bootstrap  "`bootstrap'"
    return local multiplier "`multiplier'"
    return local pvalue     "`pvalue'"
    return local seed       `"`seed'"'
    return local cv         "`cvused'"
    return local method     "`method'"
    if `type' == 2 return local transvar "`transvar'"
    if `type' == 3 return local thrvar   "`qvar'"
    return local cmd        "cointvol nullcoint"
    return matrix stats   = `stats'
    return matrix b       = `bvec'
    return matrix profile = `prof'
    if "`cvused'" == "shin" {
        return matrix shin_table = `shtab'
    }
    if `iscs' {
        return matrix cs_blocks = `csblk'
        if `csbfix' >= . {
            return matrix cs_mv = `csmv'
        }
    }
    if "`bootstrap'" != "none" {
        return matrix boot = `boot'
    }
end
