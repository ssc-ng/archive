*! mvardlurt_multivariate  version 1.1.2  03oct2026
*! Multivariate ARDL unit root test with two or more covariates
*! Based on Sam, McNown, Goh and Goh (2024), Studies in Economics and Econometrics
*! Author : Yusuf Toyin Yusuf, Kwara State University (yusuf.yusuf@kwasu.edu.ng)
*! Reporting style (tables, stars, example file) follows Roudane's mvardlurt (2026)

capture program drop mvardlurt_multivariate
program define mvardlurt_multivariate, eclass sortpreserve
    version 14

    // ---------------------------------------------------------------------
    // 1. SYNTAX
    // ---------------------------------------------------------------------
    syntax varlist(min=2 numeric) [if] [in] [,       ///
        Case(integer 3)                              /// 1=none 3=intercept 5=intercept+trend
        MAXLag(integer 4)                            /// maximum lag searched
        REPS(integer 1000)                           /// bootstrap replications
        IC(string)                                   /// aic | bic
        FIXLag(numlist integer >=0 min=2)            /// p q   or   p q1 ... qk
        Level(cilevel)                               /// decision level (default 95)
        SEED(integer 12345)                          ///
        CONTemp                                      /// add contemporaneous D.x
        NOGraph DIag NOTable NOBoot                  ///
        STAR NOStar                                  ///
        SAVEPATH(string) NODisplay ]

    // ---------------------------------------------------------------------
    // 2. VALIDATION
    // ---------------------------------------------------------------------
    gettoken depvar indepvars : varlist
    local indepvars = strtrim("`indepvars'")
    local k : word count `indepvars'

    local dup : list indepvars & depvar
    if "`dup'" != "" {
        di as err "the dependent variable cannot also be a covariate"
        exit 198
    }
    if !inlist(`case', 1, 3, 5) {
        di as err "case() must be 1 (none), 3 (intercept) or 5 (intercept + trend)"
        exit 198
    }
    if "`ic'" == "" local ic "aic"
    local ic = lower("`ic'")
    if !inlist("`ic'", "aic", "bic") {
        di as err "ic() must be aic or bic"
        exit 198
    }
    if `maxlag' < 0 | `maxlag' > 12 {
        di as err "maxlag() must be between 0 and 12"
        exit 198
    }
    if `reps' < 100 {
        di as err "reps() must be at least 100"
        exit 198
    }
    if "`star'" != "" & "`nostar'" != "" {
        di as err "options star and nostar may not be combined"
        exit 198
    }

    // manual lags:  p q  (common q)   or   p q1 ... qk
    local manual 0
    local fix_p ""
    local fix_q ""
    if "`fixlag'" != "" {
        local manual 1
        local nfix : word count `fixlag'
        local kp1 = `k' + 1
        if `nfix' != 2 & `nfix' != `kp1' {
            di as err "fixlag() needs 2 numbers (p q) or `kp1' numbers (p q1 ... q`k')"
            exit 198
        }
        local fix_p : word 1 of `fixlag'
        forvalues i = 1/`k' {
            if `nfix' == 2 {
                local qq : word 2 of `fixlag'
            }
            else {
                local qq : word `=`i'+1' of `fixlag'
            }
            local fix_q "`fix_q' `qq'"
        }
        local fix_q = strtrim("`fix_q'")
    }

    qui tsset
    local timevar  "`r(timevar)'"
    local panelvar "`r(panelvar)'"
    local tdelta   "`r(tdelta)'"
    if "`panelvar'" != "" {
        di as err "mvardlurt_multivariate is for time-series data, not panel data"
        exit 198
    }

    marksample touse
    qui count if `touse'
    local Tfull = r(N)
    if `Tfull' < 30 {
        di as err "too few observations (`Tfull'); at least 30 are needed"
        exit 2001
    }
    sort `timevar'

    qui su `timevar' if `touse', meanonly
    local tmin = r(min)
    local tmax = r(max)
    local tfmt : format `timevar'
    local tstart : di `tfmt' `tmin'
    local tend   : di `tfmt' `tmax'
    local tstart = strtrim("`tstart'")
    local tend   = strtrim("`tend'")

    local casename "No deterministic terms"
    if `case' == 3 local casename "Intercept only"
    if `case' == 5 local casename "Intercept and trend"

    // ---------------------------------------------------------------------
    // 3. ESTIMATION AND LAG SEARCH (Mata); BOOTSTRAP IN ITS OWN FILE
    // ---------------------------------------------------------------------
    _mvardlurt_multivariate_load, boot

    tempvar esamp
    qui gen byte `esamp' = 0
    tempname BB VV CV ICT RES

    set seed `seed'
    if `manual' == 0 & "`nodisplay'" == "" {
        di as txt _n _col(3) "Searching ARDL lags with " upper("`ic'") ///
            " (p = 0..`maxlag', common q = 0..`maxlag')..."
    }
    if "`noboot'" == "" & "`nodisplay'" == "" {
        di as txt _col(3) "Residual bootstrap: `reps' replications, `k' covariate(s)..."
    }

    local mvu_err ""
    local opt_p ""
    local opt_q ""
    local cnames ""
    capture noisily mata: mvu_run()
    if _rc {
        di as err "Mata engine failed (rc = " _rc ")."
        di as err "If you have just used {bf:mata clear}, run {bf:discard} and try again."
        exit 498
    }
    if "`mvu_err'" == "1" {
        di as err "the estimation sample has gaps in the time variable"
        di as err "the bootstrap needs consecutive observations; use tsfill or restrict the sample"
        exit 198
    }
    if "`mvu_err'" == "2" {
        di as err "no ARDL specification could be estimated; reduce maxlag() or the number of covariates"
        exit 2001
    }
    if "`mvu_err'" == "3" {
        di as err "too few observations for the requested lag structure"
        exit 2001
    }

    // residual bootstrap (separate file: _mvardlurt_multivariate_boot.ado)
    tempname INFO
    matrix `INFO' = J(1, 4, .)
    if "`noboot'" == "" {
        _mvardlurt_multivariate_boot, reps(`reps') alpha(`=1-`level'/100') ///
            tstat(`=el(`RES',1,1)') fstat(`=el(`RES',1,2)')
        matrix `CV'   = r(cv)
        matrix `INFO' = r(info)
        matrix `RES'[1, 13] = el(`INFO', 1, 1)
        matrix `RES'[1, 14] = el(`INFO', 1, 2)
        matrix `RES'[1, 15] = el(`INFO', 1, 3)
        matrix `RES'[1, 16] = el(`INFO', 1, 4)
    }

    // ---------------------------------------------------------------------
    // 4. POST RESULTS
    // ---------------------------------------------------------------------
    local nobs = el(`RES', 1, 3)
    local mpar = el(`RES', 1, 4)
    local dfr  = el(`RES', 1, 11)

    capture matrix colnames `BB' = `cnames'
    if _rc {
        local cnames ""
        forvalues j = 1/`mpar' {
            local cnames "`cnames' b`j'"
        }
        matrix colnames `BB' = `cnames'
    }
    matrix rownames `BB' = y1
    matrix rownames `VV' = `cnames'
    matrix colnames `VV' = `cnames'

    ereturn post `BB' `VV', esample(`esamp') obs(`nobs') dof(`dfr') depname("D.`depvar'")

    ereturn scalar tstat   = el(`RES', 1, 1)
    ereturn scalar fstat   = el(`RES', 1, 2)
    ereturn scalar rss     = el(`RES', 1, 5)
    ereturn scalar ll      = el(`RES', 1, 6)
    ereturn scalar aic     = el(`RES', 1, 7)
    ereturn scalar bic     = el(`RES', 1, 8)
    ereturn scalar r2      = el(`RES', 1, 9)
    ereturn scalar r2_a    = el(`RES', 1, 10)
    ereturn scalar df_r    = `dfr'
    ereturn scalar rmse    = sqrt(el(`RES', 1, 5) / `dfr')
    ereturn scalar B_t     = el(`RES', 1, 13)
    ereturn scalar B_f     = el(`RES', 1, 14)
    ereturn scalar p_t     = el(`RES', 1, 15)
    ereturn scalar p_f     = el(`RES', 1, 16)
    ereturn scalar opt_p   = `opt_p'
    ereturn scalar k       = `k'
    ereturn scalar case    = `case'
    ereturn scalar reps    = `reps'
    ereturn scalar maxlag  = `maxlag'
    ereturn scalar level   = `level'
    ereturn scalar alpha   = 1 - `level'/100
    ereturn scalar boot    = ("`noboot'" == "")
    ereturn scalar T       = `Tfull'
    ereturn scalar seed    = `seed'
    ereturn scalar contemp = ("`contemp'" != "")
    ereturn scalar stars   = ("`nostar'" == "")

    ereturn local cmd        "mvardlurt_multivariate"
    ereturn local cmdline    "mvardlurt_multivariate `0'"
    ereturn local title      "Multivariate ARDL unit root test"
    ereturn local depvar     "`depvar'"
    ereturn local indepvars  "`indepvars'"
    ereturn local opt_q      "`opt_q'"
    ereturn local casename   "`casename'"
    ereturn local ic         "`ic'"
    ereturn local t_start    "`tstart'"
    ereturn local t_end      "`tend'"
    ereturn local manual     "`manual'"
    ereturn local predict    "mvardlurt_multivariate_p"

    matrix rownames `CV' = t_stat F_stat
    matrix colnames `CV' = a10 a05 a025 a01 decision
    ereturn matrix cv = `CV'
    if `manual' == 0 {
        ereturn matrix ic_table = `ICT'
    }

    // ---------------------------------------------------------------------
    // 5. OUTPUT
    // ---------------------------------------------------------------------
    if "`nodisplay'" == "" {
        _mvardlurt_multivariate_display, `notable'
    }
    if "`diag'" != "" {
        mvardlurt_multivariate_diag
    }
    if "`nograph'" == "" {
        capture noisily mvardlurt_multivariate_graph
        if _rc di as txt _col(3) "(graphs could not be drawn; rc = " _rc ")"
    }
    if "`savepath'" != "" {
        _mvardlurt_multivariate_save, path("`savepath'")
    }
end
