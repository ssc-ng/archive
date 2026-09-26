*! version 1.0.0  September, 2026  Shoya Ishimaru
program twfedec, rclass
	version 15

	capture which reghdfe
	if _rc {
		di as error "twfedec requires reghdfe; install it with"
		di as error "  ssc install require"
		di as error "  ssc install ftools"
		di as error "  ssc install reghdfe"
		exit 199
	}

	syntax varlist(min=2 numeric fv ts) [if] [in] [aw fw pw] ///
		[, TINVariant(varlist numeric fv) VCE(string) GRaph GRAPHOPTions(string asis) FORmat(string)]

	gettoken y rest : varlist
	gettoken d w : rest
	foreach v in y d {
		capture confirm numeric variable ``v''
		if _rc {
			di as error "the outcome and the treatment must be plain numeric variables; ``v'' is not"
			exit 198
		}
	}
	if "`y'"=="`d'" {
		di as error "the outcome and the treatment must be different variables"
		exit 198
	}
	fvrevar `w', list
	local wbase `r(varlist)'
	foreach v of local wbase {
		if "`v'"=="`d'" | "`v'"=="`y'" {
			di as error "time-varying covariates must not contain the outcome or the treatment"
			exit 198
		}
	}
	if "`format'"=="" {
		local format "%10.6f"
	}
	capture confirm numeric format `format'
	if _rc {
		di as error "format() must be a numeric display format, such as %10.6f"
		exit 198
	}
	if `"`graphoptions'"'!="" {
		local graph graph
	}

	capture quietly xtset
	if _rc | "`r(panelvar)'"=="" | "`r(timevar)'"=="" {
		di as error "data must be xtset with both a panel variable and a time variable; see help xtset"
		exit 459
	}
	local ivar `r(panelvar)'
	local tvar `r(timevar)'
	local tdelta = r(tdelta)

	if "`vce'"=="" {
		local vce "cluster `ivar'"
	}

	// The internal reghdfe calls would otherwise leave an auxiliary regression in e().
	tempname esthold
	_estimates hold `esthold', restore nullok

	marksample touse
	markout `touse' `ivar' `tvar'
	if "`tinvariant'"!="" {
		fvrevar `tinvariant', list
		markout `touse' `r(varlist)'
	}

	// The regression weight must be constant within unit: then unit-demeaning is unaffected
	// by the weights and Theorem 2.2 holds with every sum over units weighted by it.
	// marksample has already excluded zero and missing weights and rejected negative ones.
	tempvar wt
	if "`weight'"!="" {
		quietly gen double `wt' `exp' if `touse'
		local wexp [`weight'=`wt']
	}
	else {
		quietly gen double `wt' = 1 if `touse'
	}

	// Expand factor-variable and time-series terms on the full data, so that lags reach
	// periods outside the estimation sample.
	fvrevar `w'
	local wcols `r(varlist)'
	local ccols
	if "`tinvariant'"!="" {
		fvrevar `tinvariant'
		local ccols `r(varlist)'
	}

	preserve
	quietly keep if `touse'
	quietly count
	if r(N)==0 {
		error 2000
	}

	// Balanced panel on consecutive periods
	tempvar t tag nper
	quietly summarize `tvar', meanonly
	local tlo = r(min)
	quietly gen double `t' = (`tvar' - `tlo')/`tdelta' + 1
	capture assert abs(`t' - round(`t'))<1e-6
	if _rc {
		di as error "`tvar' takes values off the xtset delta grid (delta = `tdelta')"
		exit 459
	}
	quietly replace `t' = round(`t')
	capture isid `ivar' `t'
	if _rc {
		di as error "`ivar' and `tvar' do not uniquely identify the observations"
		exit 459
	}
	quietly summarize `t', meanonly
	local T = r(max)
	quietly egen byte `tag' = tag(`t')
	quietly count if `tag'
	if r(N)<`T' {
		di as error "the time variable `tvar' has gaps in the estimation sample;"
		di as error "twfedec requires consecutive periods (in units of the xtset delta)"
		exit 459
	}
	sort `ivar' `t'
	quietly by `ivar': gen long `nper' = _N
	capture assert `nper'==`T'
	if _rc {
		di as error "the panel is unbalanced in the estimation sample (after if/in and missing values);"
		di as error "twfedec requires every unit to be observed in all `T' periods"
		exit 459
	}
	quietly count
	local NT = r(N)
	local N = `NT'/`T'
	if `T'<2 | `N'<2 {
		di as error "twfedec requires at least two units and two periods"
		exit 459
	}
	capture by `ivar': assert `wt'==`wt'[1]
	if _rc {
		di as error "weights must be constant within each unit (`ivar')"
		exit 459
	}

	// Time-invariant covariates: each column gets period-specific coefficients. A column that
	// is constant across units is already spanned by the period effects, so it is dropped.
	local cuse
	foreach v of local ccols {
		capture by `ivar': assert `v'==`v'[1]
		if _rc {
			di as error "tinvariant() variables must be constant within each unit (`ivar'); `tinvariant' is not"
			exit 459
		}
		quietly summarize `v', meanonly
		if r(min)<r(max) {
			local cuse `cuse' `v'
		}
	}
	// Collinear columns span nothing new but would be counted as parameters by reghdfe.
	if "`cuse'"!="" {
		quietly _rmcoll `cuse'
		local cuse
		foreach v in `r(varlist)' {
			if substr("`v'",1,2)!="o." {
				local cuse `cuse' `v'
			}
		}
	}
	local absfd `t'
	local absfe `ivar' `t'
	if "`cuse'"!="" {
		local absfd `t'##c.(`cuse')
		// In the TWFE regression the period-invariant part of the C slopes is spanned by the unit
		// effects, which reghdfe does not detect. Slopes for periods 2..T only span the same space;
		// the period-1 slope variable is then constant, which reghdfe drops from its parameter count.
		local cz
		foreach v of local cuse {
			tempvar z
			quietly gen double `z' = `v'*(`t'>1)
			local cz `cz' `z'
		}
		local absfe `ivar' `t'##c.(`cz')
	}
	local nw : word count `wcols'
	local K = `T'-1

	tempname bwfe dwfe bwfd dwfd fd
	// TWFE regressions
	quietly reghdfe `y' `d' `wcols' `wexp', absorb(`absfe') vce(`vce') tolerance(1e-14)
	_twfedec_nobs `NT' "TWFE regression"
	_twfedec_omitted `d'
	if r(omitted) {
		di as error "the treatment is collinear with the fixed effects and covariates; the TWFE coefficient is not identified"
		exit 459
	}
	local b_fe = _b[`d']
	local se_fe = _se[`d']
	local vcetype `"`e(vce)'"'
	if "`e(clustvar)'"!="" {
		local vcetype `"`vcetype' (`e(clustvar)')"'
	}
	if `nw'>0 {
		matrix `bwfe' = J(1,`nw',0)
		forvalues j = 1/`nw' {
			local v : word `j' of `wcols'
			matrix `bwfe'[1,`j'] = _b[`v']
		}
		quietly reghdfe `d' `wcols' `wexp', absorb(`absfe') tolerance(1e-14)
		_twfedec_nobs `NT' "TWFE regression of the treatment on the covariates"
		matrix `dwfe' = J(1,`nw',0)
		forvalues j = 1/`nw' {
			local v : word `j' of `wcols'
			matrix `dwfe'[1,`j'] = _b[`v']
		}
	}

	// k-period FD regressions
	tempvar dy dd sk r u ut dwd dwb prod
	quietly gen double `dy' = .
	quietly gen double `dd' = .
	quietly gen byte `sk' = .
	local dwcols
	forvalues j = 1/`nw' {
		tempvar dw`j'
		quietly gen double `dw`j'' = .
		local dwcols `dwcols' `dw`j''
	}
	matrix `fd' = J(`K',4,.)
	matrix colnames `fd' = b se weight nobs
	local rn
	forvalues k = 1/`K' {
		local rn `rn' `k'
	}
	matrix rownames `fd' = `rn'
	local sumS = 0
	local sumA = 0
	local unident
	forvalues k = 1/`K' {
		// _n+k must be the same unit k periods later, whatever order reghdfe left behind
		sort `ivar' `t'
		quietly replace `sk' = (`t' + `k' <= `T')
		quietly by `ivar': replace `dy' = `y'[_n+`k'] - `y'
		quietly by `ivar': replace `dd' = `d'[_n+`k'] - `d'
		forvalues j = 1/`nw' {
			local v : word `j' of `wcols'
			quietly by `ivar': replace `dw`j'' = `v'[_n+`k'] - `v'
		}
		local nk = `N'*(`T'-`k')

		quietly reghdfe `dy' `dd' `dwcols' `wexp' if `sk', absorb(`absfd') vce(`vce') tolerance(1e-14)
		_twfedec_nobs `nk' "`k'-period FD regression"
		_twfedec_omitted `dd'
		if r(omitted) {
			local unident `unident' `k'
		}
		else {
			matrix `fd'[`k',1] = _b[`dd']
			matrix `fd'[`k',2] = _se[`dd']
		}
		matrix `fd'[`k',4] = `nk'
		if `nw'>0 {
			matrix `bwfd' = J(1,`nw',0)
			forvalues j = 1/`nw' {
				matrix `bwfd'[1,`j'] = _b[`dw`j'']
			}
		}

		// S_k and the numerator of A are weighted sums computed here from residuals,
		// so they do not depend on how reghdfe normalizes the weights.
		capture drop `r'
		quietly reghdfe `dd' `dwcols' `wexp' if `sk', absorb(`absfd') tolerance(1e-14) residuals(`r')
		_twfedec_nobs `nk' "`k'-period FD regression of the treatment"
		capture drop `prod'
		quietly gen double `prod' = `wt'*`r'^2 if `sk'
		quietly summarize `prod', meanonly
		local S = r(sum)
		if `nw'>0 {
			// With W: S_k = R_k + sum (dW'dwfd) * resid(u_k) and
			// A_k = sum resid(u_k) * dW'(bwfd - bwfe), where u_k = dW'(dwfd - dwfe);
			// derivation in markdown/twfedec_spec.md.
			matrix `dwfd' = J(1,`nw',0)
			forvalues j = 1/`nw' {
				matrix `dwfd'[1,`j'] = _b[`dw`j'']
			}
			capture drop `u' `ut' `dwd' `dwb'
			quietly gen double `u' = 0 if `sk'
			quietly gen double `dwd' = 0 if `sk'
			quietly gen double `dwb' = 0 if `sk'
			forvalues j = 1/`nw' {
				quietly replace `u' = `u' + `dw`j''*(`dwfd'[1,`j'] - `dwfe'[1,`j']) if `sk'
				quietly replace `dwd' = `dwd' + `dw`j''*`dwfd'[1,`j'] if `sk'
				quietly replace `dwb' = `dwb' + `dw`j''*(`bwfd'[1,`j'] - `bwfe'[1,`j']) if `sk'
			}
			quietly reghdfe `u' `wexp' if `sk', absorb(`absfd') tolerance(1e-14) residuals(`ut')
			_twfedec_nobs `nk' "`k'-period residualization of the covariate term"
			quietly replace `prod' = `wt'*`dwd'*`ut' if `sk'
			quietly summarize `prod', meanonly
			local S = `S' + r(sum)
			quietly replace `prod' = `wt'*`ut'*`dwb' if `sk'
			quietly summarize `prod', meanonly
			local sumA = `sumA' + r(sum)
		}
		matrix `fd'[`k',3] = `S'
		local sumS = `sumS' + `S'
	}

	if `sumS'<=0 {
		di as error "the weights are not defined: their denominator (sum of S_k) is not positive"
		exit 459
	}
	local b_wavg = 0
	local absterm = 0
	local negw = 0
	forvalues k = 1/`K' {
		matrix `fd'[`k',3] = `fd'[`k',3]/`sumS'
		if `fd'[`k',3]<0 {
			local negw = 1
		}
		if `fd'[`k',1]<. {
			local b_wavg = `b_wavg' + `fd'[`k',3]*`fd'[`k',1]
			local absterm = `absterm' + abs(`fd'[`k',3]*`fd'[`k',1])
		}
	}
	local adj = `sumA'/`sumS'
	local check = `b_fe' - (`b_wavg' + `adj')

	// Display
	di ""
	di as text " TWFE coefficient as a weighted average of k-period FD coefficients"
	di as text " Outcome (Y): " as result "`y'"
	di as text " Treatment (D): " as result "`d'"
	di as text " Time-varying covariates (W): " as result strtrim("`w'")
	di as text " Time-invariant covariates (C): " as result "`tinvariant'"
	di as text " Panel: " as result "`ivar'" as text ", time: " as result "`tvar'" ///
		as text "; " as result `N' as text " units, " as result `T' as text " periods"
	if "`weight'"!="" {
		di as text " Weights: " as result "[`weight'`exp']"
	}
	foreach s in b_fe se_fe b_wavg adj {
		local `s'_s : display `format' ``s''
		local `s'_s = strtrim("``s'_s'")
	}
	di as text " TWFE coefficient (StdErr): " as result "`b_fe_s'" as text "    (" as result "`se_fe_s'" as text ")"
	di as text " Weighted average of FD: " as result "`b_wavg_s'"
	di as text " Adjustment term: " as result "`adj_s'"
	matlist `fd', title("k-period FD coefficients and weights") rowtitle(k) ///
		cspec(& %4s | `format' & `format' & `format' & %8.0f &) rspec(--`=(`K'-1)*"&"'-)
	di ""
	di as text " VCE type: `vcetype'"
	if abs(`check') > 1e-8*max(abs(`b_fe'), `absterm', abs(`adj')) {
		di as error " Warning: TWFE - (weighted average of FD + adjustment term) = " %9.2e `check' ","
		di as error "  larger than expected from rounding error."
	}
	if `negw' {
		di as text " Note: some weights are negative (possible with time-varying covariates)."
	}
	if "`unident'"!="" {
		di as text " Note: the FD coefficient is not identified at k = `unident' (the treatment change is"
		di as text "  collinear with the period effects and covariates); it is excluded from the weighted average."
	}

	if "`graph'"!="" {
		_twfedec_graph `fd' `b_fe' `b_wavg' `nw' `"`graphoptions'"'
	}
	restore

	return scalar b_fe = `b_fe'
	return scalar se_fe = `se_fe'
	return scalar b_wavg = `b_wavg'
	return scalar adj = `adj'
	return scalar check = `check'
	return scalar N = `N'
	return scalar T = `T'
	return local depvar "`y'"
	return local treatment "`d'"
	return local covariates "`w'"
	return local tinvariant "`tinvariant'"
	return local vce "`vcetype'"
	return local wtype "`weight'"
	return local wexp "`exp'"
	return matrix fd = `fd'
end

// Error unless the last reghdfe call used exactly the expected number of observations;
// reghdfe silently drops singletons and observations with missing values in vce() variables,
// either of which would break the balanced-panel algebra.
program _twfedec_nobs
	args expected what
	quietly count if e(sample)
	if r(N)!=`expected' {
		di as error "reghdfe used " r(N) " observations in the `what' instead of `expected';"
		di as error "check for missing values in the vce() variables"
		exit 459
	}
end

program _twfedec_omitted, rclass
	args v
	tempname b
	matrix `b' = e(b)
	local names : colnames `b'
	return scalar omitted = (strpos(" `names' ", " o.`v' ")>0) | (strpos(" `names' ", " `v' ")==0)
end

program _twfedec_graph
	args fd b_fe b_wavg nw graphoptions
	local K = rowsof(`fd')
	drop _all
	quietly svmat double `fd', names(col)
	quietly gen k = _n
	quietly gen double hi = b + se
	quietly gen double lo = b - se
	local xhi = `K' + 0.5
	local bfe : display %21.0g `b_fe'
	local bav : display %21.0g `b_wavg'
	// Weight-axis labels must include 0, the base of the bars
	quietly summarize weight, meanonly
	_natscale `=min(0, r(min))' `=max(0, r(max))' 5
	local wlab `r(min)'(`r(delta)')`r(max)'
	local avgline
	local order 4 "TWFE" 3 "FD" 1 "Weight"
	local cmin = `b_fe'
	local cmax = `b_fe'
	if `nw'>0 {
		local avgline (function y = `bav', range(0.5 `xhi') yaxis(1) lpattern(solid) lcolor(red) lwidth(medthick))
		local order 4 "TWFE" 5 "Weighted avg." 3 "FD" 1 "Weight"
		local cmin = min(`cmin', `b_wavg')
		local cmax = max(`cmax', `b_wavg')
	}
	// The zero line is a reference for the coefficients, so it is drawn only when zero lies
	// within the range of what is plotted on the coefficient axis.
	foreach v in b hi lo {
		quietly summarize `v', meanonly
		if r(N) {
			local cmin = min(`cmin', r(min))
			local cmax = max(`cmax', r(max))
		}
	}
	local zline
	if `cmin'<=0 & `cmax'>=0 {
		local zline yline(0, axis(1) lpattern(dot) lcolor(black))
	}
	twoway (bar weight k, yaxis(2) barwidth(0.8) color(orange) lwidth(none) base(0)) ///
		(rcap hi lo k, yaxis(1) lcolor(navy) lwidth(medthick)) ///
		(scatter b k, yaxis(1) msymbol(D) mcolor(navy)) ///
		(function y = `bfe', range(0.5 `xhi') yaxis(1) lpattern(dash) lcolor(black) lwidth(thick)) ///
		`avgline' ///
		, `zline' ///
		ytitle("Coefficients", axis(1)) ytitle("Weights", axis(2)) xtitle("Gap (periods)") ///
		ylabel(, axis(1) angle(0)) ylabel(`wlab', axis(2) angle(0)) yscale(alt axis(1)) yscale(alt axis(2)) ///
		legend(order(`order') rows(1) position(6)) graphregion(color(white)) ///
		`graphoptions'
end
