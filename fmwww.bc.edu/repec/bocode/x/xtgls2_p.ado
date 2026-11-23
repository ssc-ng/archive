*! xtgls2_p version 2.1  predict after xtgls2

*  xb        : x*b on the regressors named in e(b)
*              (for fd these are the first-differenced regressors D.x, so xb is the fitted
*               value of D.y; for fe/fd there is no constant and no fixed effect in xb)
*  residuals : e(depvar) - xb  (for fd e(depvar) is D.y; for fe it still contains the fixed effect)
*  scores    : equation-level score r_it used by -margins, vce(unconditional)-: the score of beta
*              for unit i is sum_t x_it*r_it. Not available when aweights vary within panel (pgls)
*              because the estimating function is then not a weighted sum of observation-level scores.

program define xtgls2_p
	version 11
	syntax anything(name=vlist) [if] [in] [, xb Residuals SCores]

	// ---- new variable: [type] name, with name possibly written stub* ------------
	gettoken first rest : vlist
	local typ `c(type)'
	local vname `vlist'
	if inlist("`first'", "byte", "int", "long", "float", "double") {
		local typ `first'
		local vname `rest'
	}
	if `: word count `vname'' != 1 {
		di as err "one new variable name required"
		exit 103
	}
	if substr("`vname'", -1, 1) == "*" {
		local vname = substr("`vname'", 1, length("`vname'") - 1) + "1"
	}
	confirm new variable `vname'

	local nopt : word count `xb' `residuals' `scores'
	if `nopt' > 1 {
		di as err "only one statistic may be specified"
		exit 198
	}

	// ---- xb (default) -------------------------------------------------------------
	if `nopt' == 0 | "`xb'" != "" {
		if `nopt' == 0 di as txt "(option xb assumed; fitted values)"
		_predict `typ' `vname' `if' `in', xb
		label var `vname' "Linear prediction"
		exit
	}

	// ---- residuals ------------------------------------------------------------------
	if "`residuals'" != "" {
		tempvar xbv
		quietly _predict double `xbv' `if' `in', xb
		quietly gen `typ' `vname' = `e(depvar)' - `xbv' `if' `in'
		label var `vname' "Residuals"
		exit
	}

	// ---- scores -----------------------------------------------------------------------
	if "`e(wvary)'" != "" {
		if e(wvary) == 1 {
			di as err "scores are not available when aweights vary within panel"
			exit 498
		}
	}
	local mcode = cond("`e(model)'" == "pgls", 1, ///
			cond(inlist("`e(model)'", "regls", "re"), 2, ///
			cond(inlist("`e(model)'", "fegls", "fe"), 3, 4)))
	local scale 1
	if "`e(wtype)'" != "" & !missing(e(wmean)) local scale = e(wmean)

	tempname bm om td
	matrix `bm' = e(b)
	matrix `om' = e(Omega0)
	if `mcode' == 4 matrix `td' = e(tdiff)

	local bn : colnames e(b)
	local xn
	local hascons 0
	foreach c of local bn {
		if "`c'" == "_cons" local hascons 1
		else                local xn `xn' `c'
	}

	tempvar es
	quietly gen byte `es' = e(sample)
	fvrevar `e(depvar)'
	local yv `r(varlist)'
	local xv
	if "`xn'" != "" {
		fvrevar `xn'
		local xv `r(varlist)'
	}

	tempvar touse
	mark `touse' `if' `in'
	quietly gen double `vname' = .
	local xtgls2_msg
	local xtgls2_rc
	mata: xtgls2_scores("`yv'", "`xv'", "`es'", "`e(ivar)'", "`e(tvar)'", ///
		`mcode', `hascons', `scale', "`bm'", "`om'", "`td'", "`vname'")
	if "`xtgls2_rc'" != "" {
		di as err `"`xtgls2_msg'"'
		drop `vname'
		exit `xtgls2_rc'
	}
	quietly replace `vname' = . if !`touse'
	if "`typ'" != "double" quietly recast `typ' `vname'
	label var `vname' "Equation-level score"
end
