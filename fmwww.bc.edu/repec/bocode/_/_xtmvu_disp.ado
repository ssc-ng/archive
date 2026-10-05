*! _xtmvu_disp  v1.0.0  03oct2026  display routine of xtmvardlurt_multivariate
program define _xtmvu_disp
	version 14
	syntax [, UNITs NOUnits]
	tempname P U
	matrix `P' = e(panel)
	matrix `U' = e(unit)
	local alpha = e(alpha)
	local pct = 100*e(alpha)
	local N = e(N_units)
	local k = e(k)
	local B = e(reps)

	di
	di as text "{hline 78}"
	di as result "  Panel Multivariate ARDL Unit Root and Cointegration Test"
	di as text   "  Extension of Sam, McNown, Goh and Goh (2024); bootstrap inference"
	di as text "{hline 78}"
	di as text "  Dependent variable : " as result "`e(depvar)'"
	di as text "  Covariates (k=`k')  : " as result "`e(indepvars)'"
	di as text "  Panel / time       : " as result "`e(panelvar)' / `e(timevar)'"
	di as text "  Deterministics     : " as result "`e(casename)'"
	di as text "  Lag order          : " as result "`e(lagmethod)'"
	di as text "  Units used         : " as result `N' as text "   T per unit: min " as result e(T_min) as text ", avg " as result %5.1f e(T_avg) as text ", max " as result e(T_max)
	if e(N_dropped) > 0 {
		di as text "  Units dropped      : " as result e(N_dropped) as text " (too few observations for the model)"
	}
	local bt "independent resampling of units"
	if e(csd_boot) == 1 local bt "cross-section resampling (common time index)"
	di as text "  Bootstrap          : " as result `B' as text " draws, " as result "`bt'"
	di as text "  CD test (Pesaran)  : " as result %7.3f e(CD) as text "  (p = " as result %5.3f e(CD_p) as text ")   csd(`e(csdmode)')"
	di as text "  Decision level     : " as result `pct' "%"
	di as text "{hline 78}"

	// ------------------------------------------------ Table 1: panel statistics
	di
	di as text "{hline 78}"
	di as result "  Table 1: Panel test statistics (bootstrap p-values)"
	di as text "{hline 78}"
	di as text "  Statistic" _col(33) "Value" _col(46) "p-value" _col(58) "CV(`pct'%)" _col(71) "Sig."
	di as text "{hline 78}"
	local n1 "t-bar (group mean)"
	local n2 "Fisher (t)"
	local n3 "Inverse-normal (t)"
	local n4 "F-bar (group mean)"
	local n5 "Fisher (F)"
	local n6 "Inverse-normal (F)"
	forvalues i = 1/6 {
		local st = `P'[`i',1]
		local pp = `P'[`i',2]
		local cv = `P'[`i',7]
		local sg ""
		if `pp' < .10  local sg "+"
		if `pp' < .05  local sg "*"
		if `pp' < .025 local sg "**"
		if `pp' < .01  local sg "***"
		if `i' == 4 di as text "  {hline 74}"
		di as text "  `n`i''" _col(30) as result %10.4f `st' _col(44) %9.4f `pp' _col(56) %10.4f `cv' _col(71) as result "`sg'"
	}
	di as text "{hline 78}"
	di as text "  t-statistics: lower tail (reject for small values); Fisher: upper tail;"
	di as text "  F-statistics: upper tail; inverse-normal: lower tail."
	di as text "  Sig.: *** 1%  ** 2.5%  * 5%  + 10% (bootstrap p-value)."

	// ------------------------------------------------ Table 2: decision
	di
	di as text "{hline 78}"
	di as result "  Table 2: Panel decision (four-case framework)"
	di as text "{hline 78}"
	di as text "  Statistics used" _col(34) "t-test" _col(46) "F-test" _col(58) "Case"
	di as text "{hline 78}"
	local d1 "t-bar / F-bar (group mean)"
	local d2 "Fisher combination"
	local d3 "Inverse-normal combination"
	local romans "I II III IV"
	forvalues j = 1/3 {
		local ti = `j'
		local fi = `j' + 3
		local tr = (`P'[`ti',2] < `alpha')
		local fr = (`P'[`fi',2] < `alpha')
		local cs = 1 + `tr' + 2*`fr'
		local cname : word `cs' of `romans'
		local ttxt = cond(`tr',"Reject","No rej")
		local ftxt = cond(`fr',"Reject","No rej")
		di as text "  `d`j''" _col(34) "`ttxt'" _col(46) "`ftxt'" _col(58) as result "`cname'"
		if `j' == 1 local mcase = `cs'
	}
	di as text "{hline 78}"
	di as text "  I   neither rejects : nonstationary, no cointegration"
	di as text "  II  t rejects only  : stationary, I(0)"
	di as text "  III F rejects only  : degenerate lagged y (possibly I(2))"
	di as text "  IV  both reject     : nonstationary, cointegration"
	di as text "{hline 78}"
	local concl "CASE I: unit root, no evidence of cointegration."
	if `mcase' == 2 local concl "CASE II: dependent variable is stationary, I(0)."
	if `mcase' == 3 local concl "CASE III: degenerate case (lagged covariates matter, lagged y does not)."
	if `mcase' == 4 local concl "CASE IV: unit root in y with cointegration between y and the covariates."
	di as text "  Conclusion (group-mean statistics, `pct'% level):"
	di as result "  `concl'"
	if e(case) == 4 {
		di as text "  Note (Case 4): the F-test includes the restricted trend, so a"
		di as text "  trend-stationary y can also be flagged as Case IV."
	}

	// ------------------------------------------------ Table 3: units
	local showu = 0
	if `N' <= 30 local showu = 1
	if "`units'" != "" local showu = 1
	if "`nounits'" != "" local showu = 0
	local c1 0
	local c2 0
	local c3 0
	local c4 0
	forvalues i = 1/`N' {
		local cc = `U'[`i',9]
		local c`cc' = `c`cc'' + 1
	}
	di
	di as text "{hline 78}"
	di as result "  Table 3: Unit-level results"
	di as text "{hline 78}"
	di as text "  Case shares (units):  I = `c1'   II = `c2'   III = `c3'   IV = `c4'   (of `N')"
	if `showu' {
		di as text "{hline 78}"
		di as text "  Unit" _col(14) "T" _col(20) "p" _col(25) "q" _col(32) "t-stat" _col(44) "F-stat" _col(54) "p(t)" _col(64) "p(F)" _col(73) "Case"
		di as text "{hline 78}"
		forvalues i = 1/`N' {
			local uid = `U'[`i',1]
			local cc = `U'[`i',9]
			local cname : word `cc' of `romans'
			di as text %-11.0g `uid' _col(12) as result %4.0f `U'[`i',2] _col(19) %3.0f `U'[`i',3] _col(24) %3.0f `U'[`i',4] _col(30) %9.3f `U'[`i',5] _col(42) %9.3f `U'[`i',6] _col(53) %6.3f `U'[`i',7] _col(63) %6.3f `U'[`i',8] _col(73) "`cname'"
		}
	}
	else {
		di as text "  (use option -units- to list all `N' units)"
	}
	di as text "{hline 78}"

	// ------------------------------------------------ warnings
	if e(N_dropped) > 0 {
		di as text "  Note: " e(N_dropped) " unit(s) dropped (too few observations)."
	}
	if "`e(ic)'" != "" & strpos("`e(lagmethod)'","fixed") == 0 {
		if e(searchratio) < 3 {
			di as err "  Warning: fewer than 3 observations per parameter in the largest model searched;"
			di as err "  F-test p-values may be oversized. Lower maxlag() or use fixlag()."
		}
	}
	else {
		if e(minratio) < 3 {
			di as err "  Warning: fewer than 3 observations per parameter; results may be unreliable."
		}
	}
	if `N' >= 100 {
		di as text "  Note: with 100 or more units the group t statistics can be mildly oversized;"
		di as text "  compare with the F-based and inverse-normal statistics."
	}
	di as text "  Valid when each unit has at most one cointegrating relation."
	di as text "{hline 78}"
end
