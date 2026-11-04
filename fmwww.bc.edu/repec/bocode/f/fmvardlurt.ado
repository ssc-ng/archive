*! fmvardlurt  version 1.0.0  13oct2026
*! Fourier multivariate ARDL unit-root and cointegration test with any number of covariates
*! Extends Sam, McNown, Goh and Goh (2025) with the Fourier terms of Enders and Lee (2012)
*! Bootstrap: joint null, no drift and no Fourier component in the generating process,
*!            lag and frequency search repeated in every draw
*! Author : Yusuf Toyin Yusuf, Kwara State University (yusuf.yusuf@kwasu.edu.ng)

capture program drop fmvardlurt
program define fmvardlurt, eclass sortpreserve
    version 14

    if replay() {
        if "`e(cmd)'" != "fmvardlurt" error 301
        syntax [, NOTable]
        _fmvardlurt_display, `notable'
        exit
    }

    syntax varlist(min=2 numeric) [if] [in] [,   ///
        Case(integer 3)                              /// 3 intercept, 5 intercept + trend
        MAXLag(integer 2)                            /// largest lag searched
        IC(string)                                   /// bic (default) | aic
        FIXLag(numlist integer >=0 min=2)            /// p q  or  p q1 ... qk
        KMAX(integer 3)                              /// largest frequency searched
        FREQ(numlist integer >=0 max=1)              /// fixed frequency; freq(0) = no Fourier terms
        NOCONTemp                                    /// drop contemporaneous D.x
        REPS(integer 999)                            ///
        SEED(integer 12345)                          ///
        Level(cilevel)                               ///
        NORESelect NOBoot                            ///
        NOTable NODisplay DIag NOGraph ]

    // ---------------------------------------------------------------------
    // validation
    // ---------------------------------------------------------------------
    gettoken depvar indepvars : varlist
    local indepvars = strtrim("`indepvars'")
    local k : word count `indepvars'
    local dup : list indepvars & depvar
    if "`dup'" != "" {
        di as err "the dependent variable cannot also be a covariate"
        exit 198
    }
    if !inlist(`case', 3, 5) {
        di as err "case() must be 3 (intercept) or 5 (intercept and trend)"
        exit 198
    }
    if "`ic'" == "" local ic "bic"
    local ic = lower("`ic'")
    if !inlist("`ic'", "aic", "bic") {
        di as err "ic() must be aic or bic"
        exit 198
    }
    if `maxlag' < 0 | `maxlag' > 8 {
        di as err "maxlag() must be between 0 and 8"
        exit 198
    }
    if `kmax' < 1 | `kmax' > 5 {
        di as err "kmax() must be between 1 and 5"
        exit 198
    }
    if "`freq'" != "" {
        if `freq' > 5 {
            di as err "freq() must be between 0 and 5"
            exit 198
        }
    }
    else local freq "."
    if `reps' < 99 {
        di as err "reps() must be at least 99"
        exit 198
    }
    local contemp = cond("`nocontemp'" == "", "contemp", "")

    local manual 0
    local fix_p 0
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
            if `nfix' == 2 local qq : word 2 of `fixlag'
            else           local qq : word `=`i'+1' of `fixlag'
            local fix_q "`fix_q' `qq'"
        }
        local fix_q = strtrim("`fix_q'")
    }
    else {
        forvalues i = 1/`k' {
            local fix_q "`fix_q' 0"
        }
        local fix_q = strtrim("`fix_q'")
    }

    qui tsset
    local timevar  "`r(timevar)'"
    local panelvar "`r(panelvar)'"
    local tdelta   "`r(tdelta)'"
    if "`panelvar'" != "" {
        di as err "fmvardlurt is for a single time series; the data are xtset as a panel"
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
    local tfmt : format `timevar'
    local tstart : di `tfmt' r(min)
    local tend   : di `tfmt' r(max)
    local tstart = strtrim("`tstart'")
    local tend   = strtrim("`tend'")
    local casename = cond(`case' == 3, "Intercept", "Intercept and trend")

    // ---------------------------------------------------------------------
    // estimation (Mata)
    // ---------------------------------------------------------------------
    _fmvardlurt_load
    tempvar esamp
    qui gen byte `esamp' = 0
    tempname BB VV ICT RES CVB INFO
    local fmv_err ""
    local opt_p ""
    local opt_q ""
    local opt_k ""
    local cnames ""
    capture noisily mata: fmv_run()
    if _rc {
        di as err "Mata engine failed (rc = " _rc "); if you have just used {bf:mata clear}, type {bf:discard} and retry"
        exit 498
    }
    if "`fmv_err'" == "1" {
        di as err "the estimation sample has gaps in the time variable"
        exit 198
    }
    if "`fmv_err'" == "2" {
        di as err "no specification could be estimated; reduce maxlag(), kmax() or the number of covariates"
        exit 2001
    }
    if "`fmv_err'" == "3" {
        di as err "too few observations for the requested lag structure"
        exit 2001
    }

    // ---------------------------------------------------------------------
    // bootstrap
    // ---------------------------------------------------------------------
    matrix `CVB'  = J(3, 5, .)
    matrix `INFO' = J(1, 4, .)
    if "`noboot'" == "" {
        if "`nodisplay'" == "" {
            di as txt _n _col(3) "Bootstrap: `reps' replications (joint null; lag and frequency search repeated)..."
        }
        local alpha    = 1 - `level'/100
        local tstat    = el(`RES', 1, 1)
        local fstat    = el(`RES', 1, 2)
        local ffstat   = el(`RES', 1, 3)
        local reselect = ("`noreselect'" == "")
        set seed `seed'
        capture noisily mata: fmv_boot_run()
        if _rc {
            di as err "bootstrap failed (rc = " _rc ")"
            exit 498
        }
        if "`fmv_err'" == "4" {
            di as err "bootstrap failed: fewer than 50 valid replications"
            exit 498
        }
    }

    // ---------------------------------------------------------------------
    // post results
    // ---------------------------------------------------------------------
    local nobs = el(`RES', 1, 4)
    local mpar = el(`RES', 1, 5)
    local dfr  = el(`RES', 1, 12)
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

    ereturn scalar tstat  = el(`RES', 1, 1)
    ereturn scalar fstat  = el(`RES', 1, 2)
    ereturn scalar ffstat = el(`RES', 1, 3)
    ereturn scalar rss    = el(`RES', 1, 6)
    ereturn scalar ll     = el(`RES', 1, 7)
    ereturn scalar aic    = el(`RES', 1, 8)
    ereturn scalar bic    = el(`RES', 1, 9)
    ereturn scalar r2     = el(`RES', 1, 10)
    ereturn scalar r2_a   = el(`RES', 1, 11)
    ereturn scalar df_r   = `dfr'
    ereturn scalar B      = el(`INFO', 1, 1)
    ereturn scalar p_t    = el(`INFO', 1, 2)
    ereturn scalar p_f    = el(`INFO', 1, 3)
    ereturn scalar p_ff   = el(`INFO', 1, 4)
    ereturn scalar opt_p  = `opt_p'
    ereturn scalar freq   = `opt_k'
    ereturn scalar kmax   = `kmax'
    ereturn scalar k      = `k'
    ereturn scalar case   = `case'
    ereturn scalar reps   = `reps'
    ereturn scalar maxlag = `maxlag'
    ereturn scalar level  = `level'
    ereturn scalar alpha  = 1 - `level'/100
    ereturn scalar boot   = ("`noboot'" == "")
    ereturn scalar reselect = ("`noreselect'" == "")
    ereturn scalar contemp  = ("`contemp'" != "")
    ereturn scalar T      = `Tfull'
    ereturn scalar seed   = `seed'
    ereturn local cmd       "fmvardlurt"
    ereturn local cmdline   "fmvardlurt `0'"
    ereturn local title     "Fourier multivariate ARDL unit-root test"
    ereturn local depvar    "`depvar'"
    ereturn local indepvars "`indepvars'"
    ereturn local opt_q     "`opt_q'"
    ereturn local casename  "`casename'"
    ereturn local ic        "`ic'"
    local lagtxt = cond(`manual', "fixed", "selected")
    local frqtxt = cond("`freq'" == ".", "selected", "fixed")
    ereturn local lags      "`lagtxt'"
    ereturn local freqsel   "`frqtxt'"
    ereturn local t_start   "`tstart'"
    ereturn local t_end     "`tend'"
    ereturn local predict   "fmvardlurt_p"
    matrix rownames `CVB' = t F F_fourier
    matrix colnames `CVB' = a10 a05 a025 a01 decision
    ereturn matrix cv = `CVB'
    ereturn matrix ic_table = `ICT'

    // ---------------------------------------------------------------------
    // output
    // ---------------------------------------------------------------------
    if "`nodisplay'" == "" _fmvardlurt_display, `notable'
    if "`diag'" != "" fmvardlurt_diag
    if "`nograph'" == "" & "`noboot'" == "" {
        capture noisily fmvardlurt_graph
        if _rc di as txt _col(3) "(graphs could not be drawn; rc = " _rc ")"
    }
end
