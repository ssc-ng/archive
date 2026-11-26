*! 1.0.0  Ariel Linden 19Nov2026


program define qregark_p
	version 13

	syntax newvarname [if] [in] [, XB Quantile Residuals Innovations]

	local nopt : word count `xb' `quantile' `residuals' `innovations'
	if `nopt' > 1 {
		di as err "only one of {bf:xb}, {bf:quantile}, {bf:residuals}, " ///
		 "or {bf:innovations} is allowed"
		exit 198
	}
	if (`nopt' == 0) local xb xb

	marksample touse, novarlist

	// the one-step quantile needs the panel/time order
	qui tsset
	local timevar `r(timevar)'
	local panvar  `r(panelvar)'
	sort `panvar' `timevar'

	tempvar xbv
	qui _predict double `xbv', xb equation(#1)

	if "`xb'" != "" {
		gen `typlist' `varlist' = `xbv' if `touse'
		label var `varlist' "Linear prediction"
		exit
	}
	if "`residuals'" != "" {
		gen `typlist' `varlist' = `e(depvar)' - `xbv' if `touse'
		label var `varlist' "Residuals"
		exit
	}

	// one-step conditional quantile
	tempvar ev qv xbs
	qui gen double `xbs' = `xbv'
	if "`e(noconstant)'" == "" & !missing(e(b0_struct)) {
		qui replace `xbs' = `xbv' - [#1]_b[_cons] + e(b0_struct)
	}
	qui gen double `ev' = `e(depvar)' - `xbs'
	qui gen double `qv' = `xbs' if `touse'
	forvalues j = 1/`e(p_lag)' {
		qui replace `qv' = `qv' + [ar]_b[rho`j']*L`j'.`ev' if `touse'
	}
	if "`quantile'" != "" {
		gen `typlist' `varlist' = `qv' if `touse'
		label var `varlist' "One-step conditional quantile"
	}
	else {
		gen `typlist' `varlist' = `e(depvar)' - `qv' if `touse'
		label var `varlist' "Innovations"
	}
end
