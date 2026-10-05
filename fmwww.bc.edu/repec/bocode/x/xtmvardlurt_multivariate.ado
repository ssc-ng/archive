*! xtmvardlurt_multivariate  v1.0.0  03oct2026
*! Panel multivariate ARDL unit root test with cointegration (F) test
*! Extends Sam, McNown, Goh and Goh (2024) to panels; any number of covariates;
*! cross-sectional dependence handled by a cross-section residual bootstrap.
*! Author: Yusuf Toyin Yusuf, Kwara State University (yusuf.yusuf@kwasu.edu.ng)
program define xtmvardlurt_multivariate, eclass sortpreserve
	version 14
	syntax varlist(min=2 numeric) [if] [in] [, Case(integer 3) MAXLag(integer 3) IC(string) FIXLag(numlist integer >=0 min=2 max=2) REPS(integer 999) SEED(integer 12345) Level(cilevel) CSD(string) UNITs NOUnits GRaph NODisplay ]

	// ------------------------------------------------------------ checks
	if !inlist(`case',3,4,5) {
		di as err "case() must be 3, 4 or 5"
		exit 198
	}
	if `maxlag' < 0 | `maxlag' > 8 {
		di as err "maxlag() must be between 0 and 8"
		exit 198
	}
	if `reps' < 99 {
		di as err "reps() must be at least 99"
		exit 198
	}
	local ic = lower("`ic'")
	if "`ic'" == "" local ic "bic"
	if !inlist("`ic'","aic","bic") {
		di as err "ic() must be aic or bic"
		exit 198
	}
	local csd = lower("`csd'")
	if "`csd'" == "" local csd "auto"
	if !inlist("`csd'","auto","on","off") {
		di as err "csd() must be auto, on or off"
		exit 198
	}
	local csdmode = cond("`csd'"=="on",1,cond("`csd'"=="off",0,2))
	local crit = cond("`ic'"=="aic",1,2)
	local fp 0
	local fq 0
	local lagtxt "`ic' (re-selected in every bootstrap draw), maxlag=`maxlag'"
	if "`fixlag'" != "" {
		local crit 0
		local fp : word 1 of `fixlag'
		local fq : word 2 of `fixlag'
		local lagtxt "fixed: p=`fp', q=`fq'"
	}
	capture quietly xtset
	if _rc {
		di as err "data must be xtset (panel variable and time variable)"
		exit 459
	}
	local pv "`r(panelvar)'"
	local tv "`r(timevar)'"
	if "`pv'" == "" | "`tv'" == "" {
		di as err "data must be xtset (panel variable and time variable)"
		exit 459
	}

	gettoken depvar indepvars : varlist
	local k : word count `indepvars'
	marksample touse
	markout `touse' `pv' `tv'
	quietly count if `touse'
	if r(N) == 0 error 2000

	// ------------------------------------------------------------ run
	_xtmvu_load
	quietly sort `pv' `tv'
	local alpha = 1 - `level'/100
	set seed `seed'
	scalar _xmu_rc = 0
	capture noisily mata: xmu_panel_run("`varlist'","`pv'","`tv'","`touse'",`case',`maxlag',`crit',`fp',`fq',`reps',`csdmode',`alpha')
	if _rc {
		di as err "estimation engine failed (rc = " _rc ")"
		exit _rc
	}
	if scalar(_xmu_rc) == 459 {
		di as err "unit " scalar(_xmu_badunit) " of `pv' has gaps in `tv'; fill them (tsfill) or restrict the sample"
		exit 459
	}
	if scalar(_xmu_rc) == 198 {
		di as err "fewer than 2 units have enough observations for the chosen model"
		di as err "reduce maxlag()/the number of covariates, or use fixlag()"
		exit 198
	}

	// ------------------------------------------------------------ post
	tempname U P
	matrix `U' = _xmu_unit
	matrix `P' = _xmu_panel
	matrix colnames `U' = unit T p q t_stat F_stat p_t p_F case
	matrix colnames `P' = stat pvalue cv10 cv05 cv025 cv01 cv_alpha
	matrix rownames `P' = tbar fisher_t invnorm_t Fbar fisher_F invnorm_F
	ereturn post , esample(`touse')
	ereturn scalar N_units   = scalar(_xmu_N)
	ereturn scalar N_dropped = scalar(_xmu_Ndrop)
	ereturn scalar T_min     = scalar(_xmu_Tmin)
	ereturn scalar T_max     = scalar(_xmu_Tmax)
	ereturn scalar T_avg     = scalar(_xmu_Tavg)
	ereturn scalar k         = `k'
	ereturn scalar case      = `case'
	ereturn scalar reps      = `reps'
	ereturn scalar maxlag    = `maxlag'
	ereturn scalar level     = `level'
	ereturn scalar alpha     = `alpha'
	ereturn scalar seed      = `seed'
	ereturn scalar CD        = scalar(_xmu_CD)
	ereturn scalar CD_p      = scalar(_xmu_CDp)
	ereturn scalar csd_boot  = scalar(_xmu_shared)
	ereturn scalar balanced  = scalar(_xmu_balanced)
	ereturn scalar minratio  = scalar(_xmu_minratio)
	ereturn scalar searchratio = scalar(_xmu_searchratio)
	ereturn scalar tbar      = `P'[1,1]
	ereturn scalar p_tbar    = `P'[1,2]
	ereturn scalar Fbar      = `P'[4,1]
	ereturn scalar p_Fbar    = `P'[4,2]
	ereturn matrix unit  = `U'
	ereturn matrix panel = `P'
	ereturn local cmd        "xtmvardlurt_multivariate"
	ereturn local cmdline    "xtmvardlurt_multivariate `0'"
	ereturn local depvar     "`depvar'"
	ereturn local indepvars  "`indepvars'"
	ereturn local panelvar   "`pv'"
	ereturn local timevar    "`tv'"
	ereturn local ic         "`ic'"
	ereturn local lagmethod  "`lagtxt'"
	ereturn local csdmode    "`csd'"
	local cn "Case 5 (unrestricted intercept and trend)"
	if `case' == 3 local cn "Case 3 (unrestricted intercept)"
	if `case' == 4 local cn "Case 4 (unrestricted intercept, restricted trend)"
	ereturn local casename   "`cn'"

	// ------------------------------------------------------------ output
	if "`nodisplay'" == "" {
		_xtmvu_disp, `units' `nounits'
	}
	if "`graph'" != "" {
		xtmvardlurt_multivariate_graph
	}
end
