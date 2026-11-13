*! xtgls2_p version 2.0  predict after xtgls2
*  xb        : x*b on the ORIGINAL (untransformed) regressors
*              (for fe/fd there is no constant and no fixed effect in xb)
*  residuals : depvar - xb  (for fe/fd this still contains the unit effect c_i)
program define xtgls2_p
	version 11
	syntax newvarlist(max=1) [if] [in] [, xb Residuals]

	local nopt : word count `xb' `residuals'
	if `nopt' > 1 {
		di as err "only one statistic may be specified"
		exit 198
	}
	if `nopt' == 0 | "`xb'" != "" {
		if `nopt' == 0 di as txt "(option xb assumed; fitted values)"
		_predict `typlist' `varlist' `if' `in', xb
		label var `varlist' "Linear prediction"
		exit
	}

	tempvar xbv
	quietly _predict double `xbv' `if' `in', xb
	quietly gen `typlist' `varlist' = `e(depvar)' - `xbv' `if' `in'
	label var `varlist' "Residuals"
end
