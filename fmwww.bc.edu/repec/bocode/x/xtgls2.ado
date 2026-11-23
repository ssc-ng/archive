*! xtgls2 version 2.1 - 22 Nov 2026
*! Manh Hoang-Ba (hbmanh9492@gmail.com)
*! Ref.: Kiefer (1980); Arellano and Bover (1995); Wooldridge (2002, 2010)
*
* Version 1.1 to allow iterated GLS.
* Version 1.2 cov(h) and (fe or fd) are not specified together,
*				and correct number of iterations.
* Version 1.3 to allow combination with bootstrap command.
* Version 1.4 to speed up IGLS; allow IC and lrtest after IGLS; 
*				and fix rounding error in FEGLS and FDGLS.
* Version 1.5 to allow robust and re options.
* Version 1.6 return data whenever an error arises.
* Version 1.7 correct Wald statistic when cluster/robust specified
*			  and disable minus option
* Version 2.0  * correct R-squared between/overall
*              * estimation, iterated GLS, robust and cluster-robust variances
*                are all coded in Mata; no dependence on -xtgls- or -xtglsr-
*              * re now really uses the RE (Swamy-Arora) residuals to build Omega
*                instead the POLS residuals
*              * strict balance check (same set of time values in every panel)
*              * aweight and pweight allowed
*              * robust / cluster() no longer silently ignore each other
*              * by: allowed (byable)
* Version 2.1  * work on unbalanced panels
*              * Omega is estimated pairwise:
*                    Omega[t,s] = sum_i s_it s_is u_it u_is / N_ts 
*                    (T = number of distinct time values of the sample)
*              * Omega not positive definite: when a sub-matrix that is
*                     actually used fails, the whole Omega is repaired by 
*                     a spectral floor (options nopdfix, pdfloor(#)).
*              * fegls: panel i is demeaned over its own observed periods
*                     and Helmert-transformed (T_i-1 rows).
*              * fdgls: FD are taken over calendar neighbours
*                    (t - delta); factor variables are not allowed.
*              * add predict , scores (equation-level score r_it; 
*                     the unit score is sum_t x_it r_it)
*              * allow margins, vce(unconditional)

cap program drop xtgls2
program define xtgls2, eclass byable(onecall)
	version 11

	if replay() {
		if _by() error 190
		if "`e(cmd)'" != "xtgls2" error 301
		syntax [, Level(cilevel)]
		xtgls2_display, level(`level')
		exit
	}
	if _by() local by "by `_byvars'`_byrc0':"
	`by' xtgls2_estimate `0'
end


*------------------------------------------------------------------------------
*  Estimation (Stata layer: parse, sample, variables) -> calls Mata
*------------------------------------------------------------------------------
cap program drop xtgls2_estimate
program define xtgls2_estimate, eclass byable(recall)
	version 11

	syntax varlist(min=2 fv ts) [if] [in] [aw pw] [, ///
		Pgls OLS FEgls FDgls REgls ///
		Robust CLuster(varname) ///
		NOConstant nmk ///
		Level(cilevel) ///
		IGLS ITERate(int 300) TOLerance(real 1e-7) ///
		NOLOg NOPDfix PDFloor(real 0.01) COV(string) ]

	local fvops = ("`s(fvops)'" == "true")
	if `pdfloor' <= 0 | `pdfloor' >= 1 {
		di as err "pdfloor() must be between 0 and 1"
		exit 198
	}
	local dopdfix = ("`nopdfix'" == "")
	gettoken dv0 iv0 : varlist
	if regexm(" `iv0' ", "(^| )[ci]b?[0-9]*\.") | strpos("`iv0'", "#") local fvops 1

	// ---- model -------------------------------------------------------------
	local fe "`fegls'"
	local fd "`fdgls'"
	local re "`regls'"
	if "`ols'" != "" local pgls pgls			// ols = old name of pgls
	local nmod = ("`pgls'"!="") + ("`fe'"!="") + ("`fd'"!="") + ("`re'"!="")
	if `nmod' > 1 {
		di as err "specify only one of {bf:pgls}, {bf:regls}, {bf:fegls} or {bf:fdgls}"
		exit 198
	}
	if "`fe'" != ""      local model fegls
	else if "`fd'" != "" local model fdgls
	else if "`re'" != "" local model regls
	else                 local model pgls
	local mcode = cond("`model'"=="pgls", 1, cond("`model'"=="regls", 2, ///
				cond("`model'"=="fegls", 3, 4)))
	if "`model'" == "fdgls" & `fvops' {
		di as err "factor variables not allowed with first-differenced model"
		exit 198
	}

	if `iterate' < 1 {
		di as err "iterate() must be positive"
		exit 198
	}
	if `tolerance' <= 0 {
		di as err "tolerance() must be positive"
		exit 198
	}

	if "`model'" == "fegls" | "`model'" == "fdgls" local noconstant noconstant
	local hascons = ("`noconstant'" == "")

	// ---- weights -----------------------------------------------------------
	if "`weight'" != "" & "`model'" == "regls" {
		di as err "weights are not allowed with {bf:regls}"
		exit 101
	}
	local wt = cond("`weight'"=="aweight", 1, cond("`weight'"=="pweight", 2, 0))
	local dorobust = ("`robust'" != "" | "`cluster'" != "" | "`weight'" == "pweight")

	// ---- panel structure ---------------------------------------------------
	qui xtset
	local ivar  "`r(panelvar)'"
	local tvar  "`r(timevar)'"
	local tdelta = r(tdelta)
	if "`ivar'" == "" {
		di as err "data must be {bf:xtset} before using this command"
		exit 459
	}
	if "`tvar'" == "" {
		di as err "time variable not set; use {bf:xtset} {it:panelvar} {it:timevar}"
		exit 459
	}

	// ---- estimation sample -------------------------------------------------
	tempvar touse wvar clid
	mark `touse' `if' `in'
	markout `touse' `varlist'
	if "`cluster'" != "" markout `touse' `cluster', strok
	if "`weight'" != "" {
		qui gen double `wvar' `exp'
		qui replace `touse' = 0 if missing(`wvar')
		qui count if `wvar' < 0 & `touse'
		if r(N) {
			di as err "negative weights encountered"
			exit 402
		}
		qui replace `touse' = 0 if `wvar' == 0
	}
	qui count if `touse'
	if r(N) == 0 error 2000

	// ---- variables ---------------------------------------------------------
	gettoken depvar indeps : varlist
	_fv_check_depvar `depvar'

	_rmcoll `indeps' if `touse', `noconstant' expand
	local terms `r(varlist)'

	// drop base levels / omitted terms
	local nterms : word count `terms'
	tempname om
	matrix `om' = J(1, `nterms', 0)
	matrix colnames `om' = `terms'
	_ms_omit_info `om'
	matrix `om' = r(omit)
	local est_terms
	forvalues j = 1/`nterms' {
		if `om'[1,`j'] == 0 {
			local est_terms `est_terms' `: word `j' of `terms''
		}
	}

	fvrevar `depvar'
	local yvar `r(varlist)'
	fvrevar `terms'
	local allx `r(varlist)'
	local xvars
	local est_chk
	forvalues j = 1/`nterms' {
		if `om'[1,`j'] == 0 {
			local v : word `j' of `allx'
			local xvars `xvars' `v'
			qui summarize `v' if `touse', meanonly
			if r(min) == 0 & r(max) == 0 {
				di as err "term `: word `j' of `terms'' is identically zero in the estimation sample"
				exit 498
			}
		}
	}

	local clidarg ""
	if "`cluster'" != "" {
		qui egen long `clid' = group(`cluster') if `touse'
		local clidarg "`clid'"
	}
	local wvararg ""
	if `wt' > 0 local wvararg "`wvar'"
/*
	// ---- the Mata library must match this ado file --------------------------
	local xtgls2_mv
	capture mata: st_local("xtgls2_mv", xtgls2_mataver())
	if _rc | "`xtgls2_mv'" != "2.1" {
		di as err "the Mata library {bf:lxtgls2.mlib} is missing or does not match xtgls2.ado (library version 2.1 needed)"
		di as err "reinstall the package or type {stata mata mlib index} and try again"
		exit 499
	}
*/
	// ---- Mata engine -------------------------------------------------------
	tempname b V Omega Omega0 kept info tdiff Vmb
	local xtgls2_msg
	local xtgls2_rc
	mata: xtgls2_main("`yvar'", "`xvars'", "`est_terms'", ///
		"`touse'", "`ivar'", "`tvar'", "`wvararg'", "`clidarg'", ///
		`mcode', `hascons', `wt', ///
		`dorobust', ("`igls'" != ""), `iterate', `tolerance', ///
		("`nmk'" != ""), ("`nolog'" == ""), `tdelta', `dopdfix', `pdfloor', ///
		"`b'", "`V'", "`Omega'", "`kept'", "`info'", "`Omega0'", "`tdiff'", "`Vmb'")
	
	if "`xtgls2_rc'" != "" {
		di as err `"`xtgls2_msg'"'
		exit `xtgls2_rc'
	}

	// ---- coefficient names (omit what Mata removed) ------------------------
	local bnames
	local j 0
	foreach t of local est_terms {
		local ++j
		if `kept'[1,`j'] == 1 {
			if "`model'" == "fdgls" local bnames `bnames' D.`t'
			else                 local bnames `bnames' `t'
		}
	}
	if `hascons' {
		local ++j
		if `kept'[1,`j'] == 1 local bnames `bnames' _cons
	}
	matrix colnames `b' = `bnames'
	matrix colnames `V' = `bnames'
	matrix rownames `V' = `bnames'
	matrix colnames `Vmb' = `bnames'
	matrix rownames `Vmb' = `bnames'

	// ---- post --------------------------------------------------------------
	local nobs = `info'[1, colnumb(`info', "N")]
	local depname "`depvar'"
	if "`model'" == "fdgls" local depname "D.`depvar'"
	ereturn post `b' `V', esample(`touse') obs(`nobs') depname(`depname')
	ereturn matrix Omega  = `Omega'		// T x T (rank T-1 in FEGLS)
	ereturn matrix Omega0 = `Omega0'	// T0 x T0
	ereturn matrix V_modelbased = `Vmb'
	if "`model'" == "fdgls" ereturn matrix tdiff = `tdiff'

	local cn : colnames `info'
	local j 0
	foreach c of local cn {
		local ++j
		if "`c'" != "N" & !missing(`info'[1,`j']) {
			ereturn scalar `c' = `info'[1,`j']
		}
	}
	ereturn scalar level = `level'

	ereturn local cmd      "xtgls2"
	ereturn local cmdline  "xtgls2 `0'"
	ereturn local title    "General GLS estimator (Kiefer-Wooldridge)"
	ereturn local depvar   "`depname'"
	ereturn local ivar     "`ivar'"
	ereturn local tvar     "`tvar'"
	ereturn local model    "`model'"
	ereturn local chi2type "Wald"
	ereturn local predict  "xtgls2_p"
	ereturn local marginsok "XB default"
	
	local mprop
	if "`model'" != "fdgls" local mprop nochainrule
	if "`nmk'" != "" local mprop `mprop' minus
	if "`mprop'" != "" ereturn local marginsprop "`mprop'"
	ereturn local properties "b V"
	if "`igls'" != "" ereturn local igls "igls"
	if `wt' > 0 {
		ereturn local wtype "`weight'"
		ereturn local wexp  "`exp'"
	}
	if `dorobust' {
		ereturn local vcetype "Robust"
		ereturn local vce "cluster"
		if "`cluster'" != "" ereturn local clustvar "`cluster'"
		else                 ereturn local clustvar "`ivar'"
	}

	xtgls2_display, level(`level')
end


*------------------------------------------------------------------------------
*  Display
*------------------------------------------------------------------------------
cap program drop xtgls2_display
program define xtgls2_display
	version 11
	syntax [, Level(cilevel)]

	if "`e(model)'" == "pgls" {
		local model_  "Pooled"
		local model_sf "PGLS"
	}
	if "`e(model)'" == "fegls" {
		local model_  "Fixed-effects"
		local model_sf "FEGLS"
	}
	if "`e(model)'" == "fdgls" {
		local model_  "First-difference"
		local model_sf "FDGLS"
	}
	if "`e(model)'" == "regls" {
		local model_  "Random-effects"
		local model_sf "REGLS"
	}

	if e(chi2) > 999999 local cfmt `"%10.0g"'
	else                local cfmt `"%10.3f"'

	di
	di in gr "`model_' Generalized Least Squares (`model_sf') regression" _n
	di in gr "Estimated covariances:" ///
		in ye _col(25) %3.0fc e(n_cv) ///
		in gr _col(49) `"Number of obs"' _col(67) `"= "' in ye %10.0fc e(N)

	di in gr "Group variable:" in ye _col(17) abbrev("`e(ivar)'", 15) ///
		in gr _col(49) `"Number of groups"' _col(67) `"= "' in ye %10.0fc e(N_g)

	di
	di in gr "R-squared:" ///
		in gr _col(49) `"Obs per group:"'

	di in gr _col(6) "Within" _col(14) "= " in ye %6.4f e(r2_w) ///
		in gr _col(63) "min" _col(67) "= " in ye %10.0fc e(g_min)

	di in gr _col(6) "Between" _col(14) "= " in ye %6.4f e(r2_b) ///
		in gr _col(63) "avg" _col(67) "= " in ye %10.1fc e(g_avg)

	di in gr _col(6) "Overall" _col(14) "= " in ye %6.4f e(r2_o) ///
		in gr _col(63) "max" _col(67) "= " in ye %10.0fc e(g_max)

	di
	di in gr _col(49) `"Wald chi2("' in ye e(df) in gr `")"' ///
		in gr _col(67) `"= "' in ye `cfmt' e(chi2)

	di in gr _col(49) `"Prob > chi2"' _col(67) `"= "' ///
		in ye %10.4f chi2tail(e(df), e(chi2))

	di

	ereturn display, level(`level') noemptycells

	di as txt "note: reported R-squared values are not used for model comparison"
	di as txt "      and serve only as measures of predictive ability on the original data."
end
