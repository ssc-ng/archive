*! xtgmmfa     - Fixed-T linear GMM for factor-augmented panels (Juodis & Sarafidis)
*! version 2.0 - 29/10/2026 
*! author: Manh Hoang-Ba, hbmanh9492@gmail.com

cap program drop xtgmmfa
program define xtgmmfa, eclass sortpreserve
    version 13

    if replay() {
        if "`e(cmd)'" != "xtgmmfa" {
            di in red "last estimates not found"
            exit 301
        }
        syntax [, Level(cilevel)]
        mhb_display, level(`level')
        exit
    }

*-- 1. parse varlist, repeated gmmvars(), other options
    syntax varlist(num fv ts) [fweight aweight pweight/] [if] [in] [, *]
    local mhb_cmdline xtgmmfa `0'
    local mhb_wtype "`weight'"
    local mhb_wexp `"`exp'"'
    local mhb_varlist `varlist'
    marksample mhb_touse, novarlist

    tempname mhb_tn_spec mhb_tn_opt mhb_tn_b mhb_tn_V mhb_tn_Fe mhb_tn_theta mhb_tn_Vtheta mhb_tn_wt
    tempname mhb_ts_J mhb_ts_Jdf mhb_ts_rkD mhb_ts_sumw mhb_ts_ncand mhb_ts_bic mhb_ts_Le mhb_ts_N mhb_ts_G mhb_ts_T mhb_ts_zeta mhb_ts_d mhb_ts_rank mhb_ts_np mhb_ts_nobs mhb_ts_dfr mhb_ts_wa mhb_ts_wa_df mhb_ts_wb mhb_ts_wb_df mhb_ts_vbad mhb_ts_Tmin mhb_ts_Tavg mhb_ts_Tmax
    local mhb_specmat_init 1
    local mhb_zvars ""
    local mhb_zexpr ""

*_	clone from xtabond2.ado
    local 0 `", `options'"'
    syntax [, GMMvars(string asis) *]
    local mhb_ng 0
    while `"`gmmvars'"' != "" {
        local ++mhb_ng
        mhb_pgmm `gmmvars'
        local mhb_lo   = r(lo)
        local mhb_hi   = r(hi)
        local mhb_col  = r(col)
        local mhb_pres = r(pres)
        local mhb_gv `r(vars)'
        _rmcoll `mhb_gv' if `mhb_touse'
        local mhb_gv `r(varlist)'
        foreach mhb_tk in `mhb_gv' {
            if substr("`mhb_tk'", 1, 2) == "o." {
                continue
            }
            local mhb_ix 0
            local mhb_c 0
            foreach mhb_e of local mhb_zexpr {
                local ++mhb_c
                if "`mhb_e'" == "`mhb_tk'" {
                    local mhb_ix `mhb_c'
                }
            }
            if `mhb_ix' == 0 {
                fvrevar `mhb_tk'
                local mhb_zvars `mhb_zvars' `r(varlist)'
                local mhb_zexpr `mhb_zexpr' `mhb_tk'
                local mhb_ix : word count `mhb_zexpr'
            }
            if `mhb_specmat_init' {
                matrix `mhb_tn_spec' = ///
                    (`mhb_ix', `mhb_lo', `mhb_hi', `mhb_col', `mhb_pres')
                local mhb_specmat_init 0
            }
            else {
                matrix `mhb_tn_spec' = `mhb_tn_spec' \ ///
                    (`mhb_ix', `mhb_lo', `mhb_hi', `mhb_col', `mhb_pres')
            }
        }
        local 0 `", `options'"'
        syntax [, GMMvars(string asis) *]
    }
    if `mhb_ng' == 0 {
        di in red "at least one gmmvars() is required"
        exit 198
    }

    local 0 `", `options'"'
    syntax [, UNOFactors(string asis) IVvars(varlist ts fv) Wmat(integer 2) Robust ///
              CLuster(varname) Level(cilevel) NOCONStant OBSFactors(varlist ts fv) ///
              rho(real 0.75) small]
    if !inlist(`wmat', 1, 2) {
        di in red "wmat(`wmat') invalid"
        exit 198
    }
    if `rho' <= 0 {
        di in red "rho must be positive"
        exit 198
    }

*-- 2. parse unofactors(Vlist, options)
    local 0 `"`unofactors'"'
    syntax [anything(name=mhb_vlist)] [, Wvar(varname) BSS TYpe(integer 1) Lmax(integer 2) ///
              SEEd(integer 120) Power(integer 0) ER NOREGressor LE(integer -1)]
    local mhb_wvar `wvar'
    local mhb_type `type'
    local mhb_lmax `lmax'
    local mhb_seed `seed'
    local mhb_power `power'
    local mhb_bss = ("`bss'" != "")
    local mhb_er  = ("`er'" != "")
    local mhb_le  = `le'
    local mhb_noreg "`noregressor'"
    if `mhb_le' == -1 {
        local mhb_le .
    }
    if !inlist(`mhb_type', 1, 2, 3) {
        di in red "type(`mhb_type') invalid"
        exit 198
    }

*-- 3. panel setup, variables, sample
    qui xtset
    local mhb_pv "`r(panelvar)'"
    local mhb_tv "`r(timevar)'"
    local mhb_delta = `r(tdelta)'
    if "`mhb_pv'" == "" {
        di in red "data must be xtset"
        exit 459
    }
    markout `mhb_touse' `mhb_pv' `mhb_tv'
    if "`cluster'" != "" {
        markout `mhb_touse' `cluster'
    }

*-- sampling weights (must be constant within panel)
    local mhb_wcode 0
    local mhb_swvar ""
    if "`mhb_wtype'" != "" {
        tempvar mhb_sw mhb_swmin mhb_swmax
        qui gen double `mhb_sw' = `mhb_wexp' if `mhb_touse'
        markout `mhb_touse' `mhb_sw'
        qui count if `mhb_touse' & `mhb_sw' < 0
        if r(N) > 0 {
            di in red "negative weights not allowed"
            exit 402
        }
        * zero weights are dropped
        qui replace `mhb_touse' = 0 if `mhb_sw' == 0
        if "`mhb_wtype'" == "fweight" {
            qui count if `mhb_touse' & `mhb_sw' != int(`mhb_sw')
            if r(N) > 0 {
                di in red "frequency weights must be integers"
                exit 401
            }
        }
        qui egen double `mhb_swmin' = min(`mhb_sw') if `mhb_touse', by(`mhb_pv')
        qui egen double `mhb_swmax' = max(`mhb_sw') if `mhb_touse', by(`mhb_pv')
        qui count if `mhb_touse' & (`mhb_swmax' - `mhb_swmin') > 1e-9*abs(`mhb_swmax')
        if r(N) > 0 {
            di in red "weights must be constant within panel"
            exit 101
        }
        if "`mhb_wtype'" == "fweight" {
            local mhb_wcode 1
        }
        else if "`mhb_wtype'" == "aweight" {
            local mhb_wcode 2
        }
        else {
            local mhb_wcode 3
        }
        local mhb_swvar `mhb_sw'
    }

    local mhb_cons = ("`noconstant'" == "")
    local mhb_nocons ""
    if !`mhb_cons' {
        local mhb_nocons nocons
    }
    * drop collinear regressors (omitted variables are flagged o.)
    _rmcoll `mhb_varlist' if `mhb_touse', `mhb_nocons'
    local mhb_rl "`r(varlist)'"
    gettoken mhb_first : mhb_rl
    if substr("`mhb_first'", 1, 2) == "o." {
        di in red "dependent variable is omitted because of collinearity"
        exit 198
    }
    local mhb_varlist ""
    foreach mhb_tk of local mhb_rl {
        if substr("`mhb_tk'", 1, 2) != "o." {
            local mhb_varlist `mhb_varlist' `mhb_tk'
        }
    }
    fvexpand `mhb_varlist' if `mhb_touse'
    local mhb_names "`r(varlist)'"
    gettoken mhb_depname mhb_regnames : mhb_names
    fvrevar `mhb_varlist' if `mhb_touse'
	local mhb_varlist_fv `r(varlist)'
    gettoken mhb_dep mhb_xvars : mhb_varlist_fv
    local mhb_nreg : word count `mhb_xvars'

    tempvar mhb_es mhb_i mhb_tp mhb_one
    qui gen byte `mhb_es' = `mhb_touse'
    markout `mhb_es' `mhb_dep' `mhb_xvars'
    qui gen byte `mhb_one' = 1
    if `mhb_cons' {
        local mhb_xvars `mhb_xvars' `mhb_one'
        local mhb_regnames `mhb_regnames' _cons
        local mhb_zvars `mhb_zvars' `mhb_one'
        local mhb_zexpr `mhb_zexpr' _cons
        local mhb_ix : word count `mhb_zexpr'
        matrix `mhb_tn_spec' = `mhb_tn_spec' \ (`mhb_ix', 0, 0, 1, 0)
    }
    if "`ivvars'" != "" {
        if `mhb_cons' {
            _rmcoll `ivvars' `mhb_one' if `mhb_touse', noconstant
        }
        else {
            _rmcoll `ivvars' if `mhb_touse'
        }
        local mhb_ivl `r(varlist)'
        foreach mhb_tk in `mhb_ivl' {
            if substr("`mhb_tk'", 1, 2) == "o." | "`mhb_tk'" == "`mhb_one'" {
                continue
            }
            fvrevar `mhb_tk'
            local mhb_zvars `mhb_zvars' `r(varlist)'
            local mhb_zexpr `mhb_zexpr' `mhb_tk'
            local mhb_ix : word count `mhb_zexpr'
            matrix `mhb_tn_spec' = `mhb_tn_spec' \ (`mhb_ix', 0, 0, 1, 0)
        }
    }

    * factor proxy variables: Vlist plus (Y, X) unless noregressor
    local mhb_xnames = subinstr("`mhb_regnames'", "_cons", "", .)
    if "`mhb_vlist'" == "" {
        if "`mhb_noreg'" != "" {
            di in red "noregressor cannot be specified with an empty Vlist."
            di in red "unofactors(`unofactors') invalid."
            exit 198
        }
        local mhb_vexpr `mhb_depname' `mhb_xnames'
    }
    else {
        if "`mhb_noreg'" != "" {
            local mhb_vexpr `mhb_vlist'
        }
        else {
            local mhb_vexpr `mhb_vlist' `mhb_depname' `mhb_xnames'
        }
    }
    fvrevar `mhb_vexpr' if `mhb_touse'
    local mhb_vvars `r(varlist)'
    qui _rmcoll `mhb_vvars' if `mhb_touse', nocons forcedrop
    local mhb_vvars `r(varlist)'
    if `mhb_type' == 1 {
        gettoken mhb_v1 mhb_vrest : mhb_vvars
        local mhb_vvars `mhb_v1'
    }
    local mhb_vtmp ""
    local mhb_vout 0
    foreach mhb_vi of local mhb_vvars {
        qui xtsum `mhb_vi' if `mhb_touse'
        if r(sd_w) == 0 {
            local ++mhb_vout
        }
        else {
            local mhb_vtmp `mhb_vtmp' `mhb_vi'
        }
    }
    if `mhb_vout' > 0 {
        di in red "Vlist (including y and X) must be time-varying."
        di in red "`mhb_vout' time-invariant variables are dropped."
    }
    local mhb_vvars `mhb_vtmp'
    if "`mhb_vvars'" == "" {
        di in red "no time-varying variable available to construct factor proxies"
        exit 198
    }

    local mhb_hvars ""
    if "`obsfactors'" != "" {
        _rmcoll `obsfactors' if `mhb_touse', `mhb_nocons'
        local mhb_ol ""
        foreach mhb_tk in `r(varlist)' {
            if substr("`mhb_tk'", 1, 2) != "o." {
                local mhb_ol `mhb_ol' `mhb_tk'
            }
        }
        if "`mhb_ol'" != "" {
            fvrevar `mhb_ol' if `mhb_touse'
            local mhb_hvars `r(varlist)'
        }
    }
    else {
        local mhb_hvars ""
    }

    qui egen long `mhb_i' = group(`mhb_pv') if `mhb_touse'
    qui sum `mhb_tv' if `mhb_touse', meanonly
    qui gen long `mhb_tp' = round((`mhb_tv' - r(min)) / `mhb_delta') + 1 if `mhb_touse'

    local mhb_clvar `cluster'
    if "`mhb_clvar'" != "" {
        qui xtsum `mhb_clvar' if `mhb_touse'
        if r(sd_w) > 0 {
            di in red "cluster variable must be time-invariant within panel"
            exit 198
        }
    }

*-- 4. option matrix for Mata (read by name)
    local mhb_robust  = ("`robust'" != "")
    local mhb_small   = ("`small'" != "")
    matrix `mhb_tn_opt' = (`mhb_cons', `mhb_type', `mhb_power', `mhb_lmax', `mhb_bss', ///
                         `mhb_er', `mhb_le', `wmat', `mhb_robust', ///
                         `mhb_small', `rho', `mhb_seed', `mhb_wcode')

    local mhb_idvar `mhb_i'
    local mhb_tpvar `mhb_tp'

*-- 5. estimate
    preserve
    qui keep if `mhb_touse'
    qui keep `mhb_i' `mhb_tp' `mhb_dep' `mhb_xvars' `mhb_zvars' `mhb_vvars' `mhb_wvar' ///
             `mhb_hvars' `mhb_clvar' `mhb_swvar' `mhb_touse'
    mata: mhb_estimate()
    restore

*-- 6. post results (same names as the original xtgmmfa, plus new ones)
    matrix colnames `mhb_tn_b' = `mhb_regnames'
    matrix colnames `mhb_tn_V' = `mhb_regnames'
    matrix rownames `mhb_tn_V' = `mhb_regnames'
    local mhb_dof ""
    if `mhb_small' {
        local mhb_dof "dof(`=scalar(`mhb_ts_dfr')')"
    }
    ereturn post `mhb_tn_b' `mhb_tn_V', esample(`mhb_es') depname(`mhb_depname') ///
        obs(`=scalar(`mhb_ts_nobs')') `mhb_dof'

    ereturn matrix Fe_hat = `mhb_tn_Fe'
    ereturn matrix theta  = `mhb_tn_theta'
    ereturn matrix Vtheta = `mhb_tn_Vtheta'
    ereturn matrix spec   = `mhb_tn_spec'

    * unit weights actually used (stored only if they fit in a Stata matrix)
    if "`mhb_wtype'" != "" {
        cap confirm matrix `mhb_tn_wt'
        if _rc == 0 {
            ereturn matrix wt = `mhb_tn_wt'
        }
        else {
            di in gr "(note: weights not stored in e(wt); number of units exceeds matsize)"
        }
    }

    ereturn scalar N_g    = scalar(`mhb_ts_N')
    ereturn scalar Tmax   = scalar(`mhb_ts_Tmax')
    ereturn scalar Tmin   = scalar(`mhb_ts_Tmin')
    ereturn scalar Tbar   = scalar(`mhb_ts_Tavg')
    ereturn scalar Teq    = scalar(`mhb_ts_T')
    ereturn scalar k      = `mhb_nreg' + `mhb_cons'
    ereturn scalar r_ga   = scalar(`mhb_ts_rank')
    ereturn scalar n_par  = scalar(`mhb_ts_np')
    ereturn scalar j      = scalar(`mhb_ts_zeta')
    ereturn scalar d      = scalar(`mhb_ts_d')
    ereturn scalar j_s    = scalar(`mhb_ts_J')
    ereturn scalar j_df   = scalar(`mhb_ts_Jdf')
    ereturn scalar rank_D = scalar(`mhb_ts_rkD')
    ereturn scalar sum_w  = scalar(`mhb_ts_sumw')
    if `mhb_bss' {
        ereturn scalar n_cand = scalar(`mhb_ts_ncand')
    }
    ereturn scalar j_p    = chi2tail(scalar(`mhb_ts_Jdf'), scalar(`mhb_ts_J'))
    ereturn scalar Le     = scalar(`mhb_ts_Le')
    ereturn scalar bic    = scalar(`mhb_ts_bic')
    ereturn scalar type   = `mhb_type'
    ereturn scalar G      = scalar(`mhb_ts_G')
    ereturn scalar v_bad  = scalar(`mhb_ts_vbad')
	
    ereturn scalar df_m   = scalar(`mhb_ts_wa_df')
	ereturn scalar df_b_m   = scalar(`mhb_ts_wb_df')
	
    if `mhb_small' {
        ereturn scalar df_r     = scalar(`mhb_ts_dfr')
        ereturn scalar F        = scalar(`mhb_ts_wa')/e(df_m)
        ereturn scalar F_p      = Ftail(e(df_m), e(df_r), e(F))
        ereturn scalar F_b      = scalar(`mhb_ts_wb')/e(df_b_m)
        ereturn scalar F_b_p    = Ftail(e(df_b_m), e(df_r), e(F_b))		
        ereturn local small "small"
    }
    else {
        ereturn scalar chi2     = scalar(`mhb_ts_wa')
        ereturn scalar chi2_p   = chi2tail(e(df_m), e(chi2))
        ereturn scalar chi2_b   = scalar(`mhb_ts_wb')
        ereturn scalar chi2_b_p = chi2tail(e(df_b_m), e(chi2_b))		
    }

    * two-step only
    if "`mhb_clvar'" != "" {
        ereturn local clustvar "`mhb_clvar'"
        ereturn scalar N_clust = scalar(`mhb_ts_G')
        ereturn local vcetype "WC-Robust"
    }
    else if `mhb_robust' {
        ereturn local clustvar "`mhb_pv'"
        ereturn scalar N_clust = scalar(`mhb_ts_N')
        ereturn local vcetype "WC-Robust"
    }
    ereturn local gmmstep "twostep"
    if "`mhb_wtype'" != "" {
        ereturn local wtype "`mhb_wtype'"
        ereturn local wexp "= `mhb_wexp'"
    }
    ereturn local overid "Hansen"
    if `mhb_le' < . {
        ereturn local stat_note "Specified Le"
    }
    else if `mhb_bss' {
        ereturn local stat_note "Selected Le (BIC)"
    }
    else if `mhb_er' {
        ereturn local stat_note "Estimated Le (ER)"
    }
    else {
        ereturn local stat_note "Estimated Le (GR)"
    }
    if `mhb_bss' {
        ereturn local method "Best-Subset Selection (BSS)"
    }
    else {
        ereturn local method "Regularization"
    }
    if `mhb_cons' {
        ereturn local constant "hasconstant"
    }
    else {
        ereturn local constant "noconstant"
    }
    ereturn local tvar "`mhb_tv'"
    ereturn local ivar "`mhb_pv'"
    ereturn local cmdline "`mhb_cmdline'"
    ereturn local cmd "xtgmmfa"


    mhb_display, level(`level')
end

/*------------------------------------------------------------------------------
    Parse one gmmvars(varlist [, lag(a b) mlag(#) collapse presample])
------------------------------------------------------------------------------*/
cap program drop mhb_pgmm
program define mhb_pgmm, rclass
    version 13
    syntax varlist(ts fv) [, LAG(numlist missingokay min=2 max=2) MLAG(integer -1) ///
                             COLlapse PREsample]
    if "`lag'" == "" {
        if `mlag' > 0 {
            local mhb_lo 0
            local mhb_hi = `mlag' - 1
        }
        else {
            local mhb_lo 0
            local mhb_hi .
        }
    }
    else {
        tokenize `lag'
        local mhb_lo `1'
        local mhb_hi `2'
    }
    if "`mhb_hi'" != "." {
        if `mhb_lo' > `mhb_hi' {
            di in red "lag() invalid: lower limit exceeds upper limit"
            exit 198
        }
    }
    return local vars `varlist'
    return scalar lo   = `mhb_lo'
    return scalar hi   = `mhb_hi'
    return scalar col  = ("`collapse'" != "")
    return scalar pres = ("`presample'" != "")
end

/*------------------------------------------------------------------------------
    Display results
------------------------------------------------------------------------------*/
cap program drop mhb_display
program define mhb_display
    version 13
    syntax [, Level(cilevel)]

    if e(wald_a) > 999999 {
        local mhb_cfmt `"%10.0g"'
    }
    else {
        local mhb_cfmt `"%10.3f"'
    }

    di
    di in gr "Fixed-T Factor-Augmented Panel Data Regression" _n
    di in gr "Estimator:"   _col(15) in ye "Asymptotically linear `e(gmmstep)' GMM"
    di in gr "Method:"      _col(15) in ye "`e(method)'"
    di in gr "Reference:"   _col(15) in ye "Juodis & Sarafidis (2022)" _n

    di in gr "Number of instruments"  ///
        _col(25) "= " in ye %10.0g e(j)    ///
        _col(49) in gr "Number of obs" ///
        _col(67) "= " in ye %10.0g e(N)

    di in gr "Total coefficients" ///
        _col(25) "= " in ye %10.0g e(r_ga) ///
        _col(49) in gr "Number of groups" ///
        _col(67) "= " in ye %10.0g e(N_g)
    di
    di in gr "`e(stat_note)'" ///
        _col(25) "= " in ye %10.0g e(Le) ///
        _col(49) in gr "Time periods:" ///
        _col(63) "min" _col(67) "= " in ye %10.0g e(Tmin)

    di in gr "BIC" ///
        _col(25) "= " in ye %10.4f e(bic) ///		
        _col(63) in gr "avg" _col(67) "=  " in ye %9.1f e(Tbar)

    di  ///
        _col(63) in gr "max" _col(67) "= " in ye %10.0g e(Tmax)
    di
    if "`e(small)'" == "" {
		di in gr "`e(overid)' chi2(" ///
			in ye e(j_df) ///
			in gr ")" ///
			_col(25) "= " in ye %10.4f e(j_s) ///
			_col(49) in gr "Wald chi2(" ///
            in ye e(df_m) ///
            in gr ")" ///
            _col(67) "= " in ye `mhb_cfmt' e(chi2)
        local mhb_wald_p = e(chi2_p)
        local mhb_wald_l "Prob > chi2"
    }
    else {
		di in gr "`e(overid)' chi2(" ///
			in ye e(j_df) ///
			in gr ")" ///
			_col(25) "= " in ye %10.4f e(j_s) ///
			_col(49) in gr "F(" ///
            in ye e(df_m) ///
            in gr ", " ///
            in ye e(df_r) ///
            in gr ")" ///
            _col(67) "= " in ye `mhb_cfmt' e(F)
        local mhb_wald_p = e(F_p)
        local mhb_wald_l "Prob > F"
    }
		
    di in gr "Prob > chi2" ///
        _col(25) "= " in ye %10.4f e(j_p) ///		
        _col(49) in gr "`mhb_wald_l'" ///
        _col(67) "= " in ye %10.4f `mhb_wald_p'
		
    if "`e(small)'" == "" {
		di  ///
			_col(49) in gr "Wald chi2(" ///
            in ye e(df_b_m) ///
            in gr ")" ///
            _col(67) "= " in ye `mhb_cfmt' e(chi2_b)
        local mhb_wald_b_p = e(chi2_b_p)
        local mhb_wald_b_l "Prob > chi2"
    }
    else {
		di ///
			_col(49) in gr "F(" ///
            in ye e(df_b_m) ///
            in gr ", " ///
            in ye e(df_r) ///
            in gr ")" ///
            _col(67) "= " in ye `mhb_cfmt' e(F_b)
        local mhb_wald_b_p = e(F_b_p)
        local mhb_wald_b_l "Prob > F"
    }
	
    di ///		
        _col(49) in gr "`mhb_wald_b_l'" ///
        _col(67) "= " in ye %10.4f `mhb_wald_b_p'	
		
    di
    ereturn display, level(`level') noemptycells

    if e(v_bad) == 1 {
        di in red "Warning: non-positive or missing variance for some coefficient (ill-conditioned weighting matrix)."
    }
end



/*==============================================================================
  VERSION HISTORY  (xtgmmfa)
  
  ver 1.0 - 31/12/2025
          - First contribution
  ver 2.0 - 29/10/2026
          - Recode mata functions to upspeed --> require STATA 13 or newer.
          - Repeatable gmmvars(); new sub-options lag(a b), collapse, presample.
          - Two-step only (drop onestep option).
          - [fweight aweight pweight] are allowed
		  - Rank(Delta)-based J df
		  - Stops if Delta is singular of Rank(Delta) < N.o. moments.
		  - Correct dof and F statistic when small specified.
		  - Correct moments in unbalanced panels (online appendix S1.1).
		  - Reset initial weighting matrix C for every candidate in BSS.

==============================================================================*/
