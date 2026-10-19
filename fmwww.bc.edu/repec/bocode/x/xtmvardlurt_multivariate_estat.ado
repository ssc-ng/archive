*! xtmvardlurt_multivariate_estat  v1.0.6  11oct2026
*! Post-estimation (estat) for xtmvardlurt_multivariate:
*!   estat diagnostics | paneltests | collinearity | cases | lags | unitdata
*! Author: Yusuf Toyin Yusuf, Kwara State University (yusuf.yusuf@kwasu.edu.ng)
program define xtmvardlurt_multivariate_estat, rclass
	version 14
	if "`e(cmd)'" != "xtmvardlurt_multivariate" {
		di as err "last estimates not found: run xtmvardlurt_multivariate first"
		exit 301
	}
	gettoken sub 0 : 0, parse(" ,")
	local len = strlen("`sub'")
	if `len' >= 3 & "`sub'" == substr("diagnostics", 1, `len') {
		_xtmvu_estat_diag `0'
		return add
	}
	else if `len' >= 3 & "`sub'" == substr("paneltests", 1, `len') {
		_xtmvu_estat_panel `0'
		return add
	}
	else if `len' >= 3 & "`sub'" == substr("collinearity", 1, `len') {
		_xtmvu_estat_col `0'
		return add
	}
	else if `len' >= 3 & "`sub'" == substr("cases", 1, `len') {
		_xtmvu_estat_cases `0'
		return add
	}
	else if `len' >= 3 & "`sub'" == substr("lags", 1, `len') {
		_xtmvu_estat_lags `0'
		return add
	}
	else if `len' >= 5 & "`sub'" == substr("unitdata", 1, `len') {
		_xtmvu_estat_unitdata `0'
	}
	else {
		di as err "estat `sub' is not available after xtmvardlurt_multivariate"
		di as err "subcommands: diagnostics, paneltests, collinearity, cases, lags, unitdata"
		exit 198
	}
end

// ---------------------------------------------------------------------------
// estat diagnostics: CD test, residual serial correlation per unit, degrees of freedom
// ---------------------------------------------------------------------------
program define _xtmvu_estat_diag, rclass
	version 14
	syntax [, ALL]
	tempname U D
	matrix `U' = e(unit)
	local N = rowsof(`U')
	local k = e(k)
	local case = e(case)
	local ntr = (`case' == 4 | `case' == 5)
	local fixed = (strpos("`e(lagmethod)'", "fixed") > 0)
	local mlag = e(maxlag)

	di
	di as text "{hline 78}"
	di as result "  Diagnostics after xtmvardlurt_multivariate"
	di as text "{hline 78}"

	// ---- 1. cross-sectional dependence
	di as text "  1. Cross-sectional dependence (Pesaran 2004 CD test on the ARDL residuals)"
	di as text "     CD = " as result %8.3f e(CD) as text "    p-value = " as result %6.4f e(CD_p)
	if e(csd_boot) == 1 {
		di as text "     Bootstrap used: cross-section resampling (common time index across units)"
	}
	else {
		di as text "     Bootstrap used: independent resampling within each unit"
	}
	if e(CD_p) < 0.05 & e(csd_boot) == 0 {
		di as err "     The CD test rejects but independent resampling was used (csd(off));"
		di as err "     consider csd(auto) or csd(on)."
	}
	if e(CD_p) >= 0.05 & e(csd_boot) == 1 {
		di as text "     (The CD test does not reject; cross-section resampling was forced by csd(on).)"
	}

	// ---- 2. serial correlation and degrees of freedom, unit by unit
	local nrej 0
	local minratio .
	forvalues i = 1/`N' {
		local pp = `U'[`i',3]
		local qq = `U'[`i',4]
		local TT = `U'[`i',2]
		local s0 = cond(`fixed', max(`pp', `qq') + 1, `mlag' + 1)
		local nn = `TT' - `s0'
		local mm = 2 + 2*`k' + `ntr' + `pp' + `qq'*`k'
		local ratio_`i' = `nn'/`mm'
		if `ratio_`i'' < `minratio' local minratio = `ratio_`i''
		local bgp = `U'[`i',10]
		if `bgp' < 0.05 local nrej = `nrej' + 1
	}
	local pb = 1
	if `nrej' > 0 local pb = binomialtail(`N', `nrej', 0.05)
	local share = `nrej'/`N'

	di
	di as text "  2. Residual serial correlation (Breusch-Godfrey LM test, order 1) and model size"
	local showall = ("`all'" != "" | `N' <= 40)
	if `showall' {
		di as text "     " "Unit" _col(18) "T" _col(24) "p" _col(28) "q" _col(33) "obs/param" _col(46) "BG p"
		forvalues i = 1/`N' {
			local uid = `U'[`i',1]
			local flag ""
			if `U'[`i',10] < 0.05 local flag "*"
			di as text "     " %-12.0g `uid' _col(17) as result %4.0f `U'[`i',2] _col(23) %2.0f `U'[`i',3] _col(27) %2.0f `U'[`i',4] _col(33) %7.2f `ratio_`i'' _col(44) %7.4f `U'[`i',10] as text " `flag'"
		}
		di as text "     * rejects at 5%"
	}
	else {
		di as text "     (more than 40 units: only the units that reject are listed; use option all for every unit)"
		forvalues i = 1/`N' {
			if `U'[`i',10] < 0.05 {
				local uid = `U'[`i',1]
				di as text "     unit " as result %-10.0g `uid' as text " BG p = " as result %7.4f `U'[`i',10] as text "   obs/param = " as result %6.2f `ratio_`i''
			}
		}
	}
	di
	di as text "     Units rejecting at 5%: " as result `nrej' as text " of " as result `N' as text "  (about 5% expected by chance;"
	di as text "     binomial p-value for this many rejections = " as result %6.4f `pb' as text ")"
	if `minratio' < .  {
		di as text "     Smallest observations per parameter: " as result %5.2f `minratio'
	}

	// ---- 3. other residual tests: units rejecting at 5%
	capture matrix `D' = e(diag)
	if _rc == 0 {
		local tn2 "Breusch-Godfrey, order 1"
		local tn3 "Breusch-Godfrey, order 2"
		local tn4 "Jarque-Bera (normality)"
		local tn5 "Breusch-Pagan/Koenker (heteroskedasticity)"
		local tn6 "ARCH(1)"
		local tn7 "RESET (squares and cubes of fitted values)"
		local mt2 "yes"
		local mt3 "yes"
		local mt4 "no"
		local mt5 "no"
		local mt6 "no"
		local mt7 "info"
		di
		di as text "  3. Residual tests, share of units rejecting at 5%"
		di as text "     " "Test" _col(52) "Rejects" _col(62) "Binom. p" _col(73) "Matters"
		forvalues j = 2/7 {
			local rj`j' 0
			forvalues i = 1/`N' {
				if `D'[`i',`j'] < 0.05 local rj`j' = `rj`j'' + 1
			}
			local pb`j' = 1
			if `rj`j'' > 0 local pb`j' = binomialtail(`N', `rj`j'', 0.05)
			di as text "     " "`tn`j''" _col(52) as result %3.0f `rj`j'' as text " of " as result %-4.0f `N' _col(62) %6.4f `pb`j'' as text _col(73) "`mt`j''"
		}
		di as text "     Matters: yes = the bootstrap relies on it; no = simulations show size is unaffected;"
		di as text "     info = may point to omitted terms. Expect about 5% rejections by chance."
		return scalar rej_bg2 = `rj3'
		return scalar rej_jb = `rj4'
		return scalar rej_bp = `rj5'
		return scalar rej_arch = `rj6'
		return scalar rej_reset = `rj7'
	}

	// ---- 3b. collinearity among the stationary regressors
	capture confirm matrix e(pdiag)
	if _rc == 0 {
		di
		di as text "  Collinearity (VIF among the stationary regressors; details: estat collinearity)"
		if e(vif_n) > 0 {
			di as err "     VIF above 10 in " e(vif_n) " of `N' units (largest " %5.1f e(vif_max) "). Size is not affected in simulations,"
			di as err "     but F-side power may be lower and coefficients imprecise: consider dropping or combining covariates."
		}
		else {
			di as text "     No unit has a VIF above 10 among the stationary regressors (largest " as result %5.1f e(vif_max) as text ")."
		}
		return scalar vif_n = e(vif_n)
		return scalar vif_max = e(vif_max)
	}

	// ---- 4. reading of the results
	di
	di as text "  4. Reading"
	if `share' >= 0.30 {
		di as err "     Residual serial correlation in 30% or more of the units. The bootstrap assumes"
		di as err "     serially uncorrelated residuals, so p-values may be unreliable. Add lags, for"
		di as err "     example fixlag(1 1) or ic(bic) maxlag(2), and compare the conclusions."
	}
	else if `pb' < 0.05 {
		di as text "     More rejections than chance alone gives. Compare with one more lag (fixlag or maxlag)."
	}
	else {
		di as text "     No sign of leftover serial correlation at the chosen lags."
	}
	if `minratio' < 1.5 {
		di as err "     Some models are nearly saturated (under 1.5 observations per parameter):"
		di as err "     use fewer covariates or lags."
	}
	if e(T_min) < 35 {
		di as text "     With T below 35 and many parameters the Breusch-Godfrey test over-rejects;"
		di as text "     treat the flags as a prompt to compare lag choices."
	}
	di as text "     Panel-level versions of these tests: estat paneltests; multicollinearity: estat collinearity."
	di as text "     Non-normal or heteroskedastic residuals did not distort the bootstrap size in"
	di as text "     simulations (heavy tails, a variance break, ARCH(1)); the bootstrap does not need them."
	di as text "     Structural breaks are NOT tested: a level shift in y is a single spike in the"
	di as text "     differenced equation, which residual tests cannot see (a CUSUM test had no power in"
	di as text "     simulations), and it can produce false F-test rejections. Check each series for breaks."
	di as text "{hline 78}"

	return scalar CD = e(CD)
	return scalar CD_p = e(CD_p)
	return scalar bg_n = `nrej'
	return scalar bg_share = `share'
	return scalar bg_binom_p = `pb'
	return scalar min_ratio = `minratio'
end

// ---------------------------------------------------------------------------
// combination of unit-level p-values (Fisher; inverse normal) for one column of e(diag)
// returns r(F) r(pF) r(Z) r(pZ) r(nrej)
// ---------------------------------------------------------------------------
program define _xtmvu_comb, rclass
	version 14
	args col
	tempname D
	matrix `D' = e(diag)
	local N = rowsof(`D')
	local sf 0
	local sz 0
	local nrej 0
	forvalues i = 1/`N' {
		local pv = `D'[`i',`col']
		if `pv' < 1e-15 local pv = 1e-15
		if `pv' > 1 - 1e-15 local pv = 1 - 1e-15
		local sf = `sf' - 2*ln(`pv')
		local sz = `sz' + invnormal(`pv')
		if `D'[`i',`col'] < 0.05 local nrej = `nrej' + 1
	}
	local z = `sz'/sqrt(`N')
	return scalar F    = `sf'
	return scalar df   = 2*`N'
	return scalar pF   = chi2tail(2*`N', `sf')
	return scalar Z    = `z'
	return scalar pZ   = normal(`z')
	return scalar nrej = `nrej'
	return scalar N    = `N'
end

// ---------------------------------------------------------------------------
// estat paneltests: panel serial correlation, normality and heteroskedasticity
// ---------------------------------------------------------------------------
program define _xtmvu_estat_panel, rclass
	version 14
	syntax
	capture confirm matrix e(pdiag)
	if _rc {
		di as err "e(pdiag) not found: re-run xtmvardlurt_multivariate with version 1.0.6 or later"
		exit 301
	}
	tempname D PD
	matrix `D'  = e(diag)
	matrix `PD' = e(pdiag)
	local N = rowsof(`D')

	di
	di as text "{hline 78}"
	di as result "  Panel residual tests after xtmvardlurt_multivariate"
	di as text "{hline 78}"
	di as text "  Residuals: ARDL residuals of the `N' units. Each unit is tested, then the unit"
	di as text "  p-values are combined (Fisher chi2(2N); inverse-normal Z, rejects for large negative Z)."

	// ---- 1. serial correlation
	di
	di as text "  1. Panel serial correlation (Breusch-Godfrey)"
	di as text "     " "Test" _col(24) "Fisher chi2" _col(38) "p" _col(47) "Inv.-normal Z" _col(63) "p" _col(72) "Units rej."
	local r = 0
	foreach c in 2 3 {
		local lab = cond(`c'==2, "BG order 1", "BG order 2")
		_xtmvu_comb `c'
		di as text "     " "`lab'" _col(24) as result %9.2f r(F) _col(36) %7.4f r(pF) _col(48) %9.3f r(Z) _col(61) %7.4f r(pZ) _col(72) %3.0f r(nrej) as text " of " as result `N'
		return scalar bg`=`c'-1'_F  = r(F)
		return scalar bg`=`c'-1'_pF = r(pF)
		return scalar bg`=`c'-1'_Z  = r(Z)
		return scalar bg`=`c'-1'_pZ = r(pZ)
	}

	// ---- 2. normality
	local Sn 0
	local Ss 0
	local Sk 0
	forvalues i = 1/`N' {
		local ni = `PD'[`i',2]
		local Sn = `Sn' + `ni'
		local Ss = `Ss' + `ni'*`PD'[`i',3]
		local Sk = `Sk' + `ni'*`PD'[`i',4]
	}
	local skew = `Ss'/`Sn'
	local kurt = `Sk'/`Sn'
	local jb = `Sn'*(`skew'^2/6 + (`kurt'-3)^2/24)
	local pjb = chi2tail(2, `jb')
	di
	di as text "  2. Panel normality (Jarque-Bera)"
	local Snf = string(`Sn', "%9.0fc")
	di as text "     Pooled over units (residuals standardised unit by unit; `Snf' residuals):"
	di as text "       skewness = " as result %7.4f `skew' as text "   kurtosis = " as result %7.4f `kurt' as text "   JB chi2(2) = " as result %8.3f `jb' as text "   p = " as result %6.4f `pjb'
	_xtmvu_comb 4
	di as text "     Unit tests combined:  Fisher chi2(" as result r(df) as text ") = " as result %8.2f r(F) as text " p = " as result %6.4f r(pF) as text "   Z = " as result %7.3f r(Z) as text " p = " as result %6.4f r(pZ)
	di as text "       units rejecting at 5%: " as result r(nrej) as text " of " as result `N'
	return scalar jb_pooled   = `jb'
	return scalar jb_pooled_p = `pjb'
	return scalar skew        = `skew'
	return scalar kurt        = `kurt'
	return scalar jb_F        = r(F)
	return scalar jb_pF       = r(pF)
	return scalar jb_Z        = r(Z)
	return scalar jb_pZ       = r(pZ)

	// ---- 3. heteroskedasticity
	di
	di as text "  3. Panel heteroskedasticity"
	di as text "     " "Test" _col(30) "Fisher chi2" _col(43) "p" _col(51) "Inv.-normal Z" _col(66) "p" _col(74) "Rej."
	foreach c in 5 6 {
		local lab = cond(`c'==5, "Breusch-Pagan/Koenker", "ARCH(1)")
		_xtmvu_comb `c'
		di as text "     " "`lab'" _col(30) as result %9.2f r(F) _col(41) %7.4f r(pF) _col(52) %9.3f r(Z) _col(64) %7.4f r(pZ) _col(74) %3.0f r(nrej)
		local nm = cond(`c'==5, "bp", "arch")
		return scalar `nm'_F  = r(F)
		return scalar `nm'_pF = r(pF)
		return scalar `nm'_Z  = r(Z)
		return scalar `nm'_pZ = r(pZ)
	}
	// groupwise: Bartlett test of equal residual variances across units
	local sdf 0
	local sw 0
	local sl 0
	local sinv 0
	forvalues i = 1/`N' {
		local dfi = `PD'[`i',6]
		local s2i = `PD'[`i',5]
		local sdf = `sdf' + `dfi'
		local sw  = `sw' + `dfi'*`s2i'
		local sl  = `sl' + `dfi'*ln(`s2i')
		local sinv = `sinv' + 1/`dfi'
	}
	local sp2 = `sw'/`sdf'
	local C = 1 + (`sinv' - 1/`sdf')/(3*(`N'-1))
	local bart = (`sdf'*ln(`sp2') - `sl')/`C'
	local pbart = chi2tail(`N'-1, `bart')
	di as text "     Equal residual variance across units (Bartlett):  chi2(" as result `N'-1 as text ") = " as result %8.2f `bart' as text "  p = " as result %6.4f `pbart'
	return scalar bartlett   = `bart'
	return scalar bartlett_p = `pbart'

	// ---- reading
	di
	di as text "  Reading"
	di as text "     The combined tests treat the units as independent. With cross-sectional dependence"
	di as text "     (CD test p = " as result %6.4f e(CD_p) as text ") they over-reject; read them as a guide, not as exact tests."
	return scalar CD_p = e(CD_p)
	di as text "     Serial correlation is the one that matters for the bootstrap: if it is rejected, add lags."
	di as text "     Non-normality and heteroskedasticity did not change the bootstrap size in simulations"
	di as text "     (heavy tails, a variance break, ARCH(1)). The Bartlett test is sensitive to non-normality, and"
	di as text "     different residual variances across units are expected: each unit is bootstrapped on its own."
	di as text "{hline 78}"
	return scalar N = `N'
end

// ---------------------------------------------------------------------------
// estat collinearity: variance inflation factors and condition number, unit by unit
// ---------------------------------------------------------------------------
program define _xtmvu_estat_col, rclass
	version 14
	syntax [, ALL]
	capture confirm matrix e(pdiag)
	if _rc {
		di as err "e(pdiag) not found: re-run xtmvardlurt_multivariate with version 1.0.6 or later"
		exit 301
	}
	tempname PD
	matrix `PD' = e(pdiag)
	local N = rowsof(`PD')
	local k = e(k)
	local vnames "`e(indepvars)'"
	local cvst = 8 + `k'
	local ccnd = 9 + `k'

	// panel summary by regressor
	di
	di as text "{hline 78}"
	di as result "  Multicollinearity after xtmvardlurt_multivariate (variance inflation factors)"
	di as text "{hline 78}"
	di as text "  VIF of the lagged-level regressors, by unit (mean, maximum, units with VIF above 10)"
	di as text "     " "Regressor" _col(30) "Mean" _col(40) "Max" _col(50) "Units > 10"
	forvalues j = 0/`k' {
		local col = 7 + `j'
		local sm 0
		local mx 0
		local n10 0
		forvalues i = 1/`N' {
			local v = `PD'[`i',`col']
			local sm = `sm' + `v'
			if `v' > `mx' local mx = `v'
			if `v' > 10 local n10 = `n10' + 1
		}
		local nm = cond(`j'==0, "L.`e(depvar)' (lagged y)", "L." + word("`vnames'", `j'))
		di as text "     " "`nm'" _col(30) as result %7.2f (`sm'/`N') _col(38) %8.2f `mx' _col(53) %4.0f `n10' as text " of " as result `N'
		return scalar vif_mean`j' = `sm'/`N'
		return scalar vif_max`j'  = `mx'
	}
	local sm 0
	local mx 0
	local n10 0
	local cm 0
	local cmx 0
	local nc30 0
	forvalues i = 1/`N' {
		local v = `PD'[`i',`cvst']
		local c = `PD'[`i',`ccnd']
		local sm = `sm' + `v'
		local cm = `cm' + `c'
		if `v' > `mx' local mx = `v'
		if `c' > `cmx' local cmx = `c'
		if `v' > 10 local n10 = `n10' + 1
		if `c' > 30 local nc30 = `nc30' + 1
	}
	di as text "  Largest VIF among the stationary regressors (lags of D.y, D.x, contemporaneous D.x)"
	di as text "     " "Largest VIF" _col(30) as result %7.2f (`sm'/`N') _col(38) %8.2f `mx' _col(53) %4.0f `n10' as text " of " as result `N'
	di as text "  Condition number of the scaled design matrix (Belsley; above 30 = near-collinearity)"
	di as text "     " "Condition number" _col(30) as result %7.1f (`cm'/`N') _col(38) %8.1f `cmx' _col(53) %4.0f `nc30' as text " of " as result `N'
	return scalar vif_stat_mean = `sm'/`N'
	return scalar vif_stat_max  = `mx'
	return scalar vif_stat_n10  = `n10'
	return scalar cond_mean     = `cm'/`N'
	return scalar cond_max      = `cmx'
	return scalar cond_n30      = `nc30'

	// unit table
	di
	local showall = ("`all'" != "" | `N' <= 40)
	if `showall' {
		di as text "     " "Unit" _col(18) "max VIF(levels)" _col(36) "VIF(stationary)" _col(54) "Cond. no."
		forvalues i = 1/`N' {
			local mxl 0
			forvalues j = 0/`k' {
				local v = `PD'[`i',7+`j']
				if `v' > `mxl' local mxl = `v'
			}
			local uid = `PD'[`i',1]
			di as text "     " as result %-12.0g `uid' _col(20) %9.2f `mxl' _col(38) %9.2f `PD'[`i',`cvst'] _col(54) %9.1f `PD'[`i',`ccnd']
		}
	}
	else {
		di as text "     (more than 40 units: use option all for the unit table)"
	}
	di
	di as text "  Reading"
	di as text "     The lagged levels of I(1) series share stochastic trends, so large VIFs among them are"
	di as text "     usual and mainly reflect that. The VIF of the stationary regressors is the better sign of"
	di as text "     trouble: above 10 means imprecise coefficients and possibly lower F-side power (the size is"
	di as text "     not affected in simulations). The condition number includes the I(1) levels and the constant,"
	di as text "     so it is often above 30 without any problem. Remedies: drop or combine covariates, or use"
	di as text "     fewer lags."
	di as text "{hline 78}"
	return scalar N = `N'
end

// ---------------------------------------------------------------------------
// estat cases: four-case classification of the units
// ---------------------------------------------------------------------------
program define _xtmvu_estat_cases, rclass
	version 14
	syntax [, noLIST]
	tempname U
	matrix `U' = e(unit)
	local N = rowsof(`U')
	local pct = 100*e(alpha)
	forvalues c = 1/4 {
		local n`c' 0
		local ids`c' ""
	}
	forvalues i = 1/`N' {
		local cc = `U'[`i',9]
		local n`cc' = `n`cc'' + 1
		local uid = `U'[`i',1]
		local ids`cc' "`ids`cc'' `uid'"
	}
	local nm1 "I   neither test rejects (no relationship)"
	local nm2 "II  t rejects only (y stationary)"
	local nm3 "III F rejects only (degenerate / I(2) case)"
	local nm4 "IV  both reject (cointegration)"

	di
	di as text "{hline 78}"
	di as result "  Unit-level four-case classification (`pct'% level)"
	di as text "{hline 78}"
	di as text "  Case" _col(48) "Units" _col(58) "Share"
	di as text "{hline 78}"
	forvalues c = 1/4 {
		local sh = `n`c''/`N'
		di as text "  `nm`c''" _col(48) as result %5.0f `n`c'' _col(58) %6.1f (100*`sh') as text " %"
		return scalar n_case`c' = `n`c''
		return scalar share_case`c' = `sh'
	}
	di as text "{hline 78}"
	if "`list'" == "" {
		forvalues c = 1/4 {
			if `n`c'' > 0 & `n`c'' <= 60 {
				di as text "{p 2 12 2}Case `c': `ids`c''{p_end}"
			}
			else if `n`c'' > 60 {
				di as text "{p 2 12 2}Case `c': " as result `n`c'' as text " units (list suppressed; use estat unitdata){p_end}"
			}
		}
		di as text "{hline 78}"
	}
	return scalar N = `N'
end

// ---------------------------------------------------------------------------
// estat lags: distribution of the lags used (selected or fixed)
// ---------------------------------------------------------------------------
program define _xtmvu_estat_lags, rclass
	version 14
	syntax
	tempname U
	matrix `U' = e(unit)
	local N = rowsof(`U')
	local mp 0
	local mq 0
	local sp 0
	local sq 0
	forvalues i = 1/`N' {
		local pp = `U'[`i',3]
		local qq = `U'[`i',4]
		if `pp' > `mp' local mp = `pp'
		if `qq' > `mq' local mq = `qq'
		local sp = `sp' + `pp'
		local sq = `sq' + `qq'
	}
	local mx = max(`mp', `mq')
	forvalues l = 0/`mx' {
		local cp`l' 0
		local cq`l' 0
	}
	forvalues i = 1/`N' {
		local pp = `U'[`i',3]
		local qq = `U'[`i',4]
		local cp`pp' = `cp`pp'' + 1
		local cq`qq' = `cq`qq'' + 1
	}
	di
	di as text "{hline 78}"
	di as result "  Lags used by unit: `e(lagmethod)'"
	di as text "{hline 78}"
	di as text "  Lag" _col(12) "p (lags of D.y)" _col(34) "q (lags of D.x, each covariate)"
	di as text "{hline 78}"
	forvalues l = 0/`mx' {
		di as text "  `l'" _col(16) as result %4.0f `cp`l'' _col(40) %4.0f `cq`l''
	}
	di as text "{hline 78}"
	di as text "  Mean" _col(14) as result %6.2f (`sp'/`N') _col(38) %6.2f (`sq'/`N')
	di as text "{hline 78}"
	return scalar mean_p = `sp'/`N'
	return scalar mean_q = `sq'/`N'
	return scalar max_p = `mp'
	return scalar max_q = `mq'
end

// ---------------------------------------------------------------------------
// estat unitdata: unit-level results as a dataset (for tables in papers)
// ---------------------------------------------------------------------------
program define _xtmvu_estat_unitdata
	version 14
	syntax [, SAVing(string) replace clear]
	if `"`saving'"' == "" & "`clear'" == "" {
		di as err "specify saving(filename) or clear"
		exit 198
	}
	tempname U
	matrix `U' = e(unit)
	if "`clear'" == "" preserve
	quietly clear
	quietly svmat double `U', names(col)
	quietly gen str3 case_label = ""
	quietly replace case_label = "I"   if case == 1
	quietly replace case_label = "II"  if case == 2
	quietly replace case_label = "III" if case == 3
	quietly replace case_label = "IV"  if case == 4
	label variable unit "unit identifier"
	label variable T "observations in the unit"
	label variable p "lags of D.y"
	label variable q "lags of D.x (each covariate)"
	label variable t_stat "t statistic on the lagged level of y"
	label variable F_stat "F statistic on the lagged levels of x (and trend, case 4)"
	label variable p_t "bootstrap p-value, t"
	label variable p_F "bootstrap p-value, F"
	label variable case "four-case classification (1=I ... 4=IV)"
	label variable bg_p "Breusch-Godfrey (order 1) p-value of the ARDL residuals"
	label variable case_label "case label"
	if `"`saving'"' != "" {
		quietly save `"`saving'"', `replace'
		di as text "unit-level results saved to " as result `"`saving'"'
	}
	if "`clear'" != "" {
		di as text "unit-level results are now in memory (`=_N' units)"
	}
end
