*! xtgcce 1.0.0  12oct2026
*! Generalized Common Correlated Effects mean-group estimation
*! Dr Merwan Roudane -- merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Implements Lu, X., Su, L. and Ba, Y. (2026), "On generalized CCE
* estimation", Journal of Econometrics 253, 106183.
* doi:10.1016/j.jeconom.2026.106183
*
* The GCCE-MG estimator augments the CCE regression with the TIME-SERIES
* averages of the regressors, which act as control variables for the
* factor loadings.  It is doubly robust: consistent under either the
* usual CCE rank condition OR the paper's control-variable condition.
*
* STEP -> EQUATION MAP (full version: help xtdyngcce methods)
*   auxiliary regression (7)        y = b_i'x + d_i'zbar_t + phi_t'xbar^a_i
*   closed form                     bhat = [X'(M_xa (x) M_z)X]^-1 X'(...)Y
*   mean group (8)                  bhat_MG = (1/N) sum_i bhat_i
*   leave-one-out jackknife (14)    zbar HELD at its full-sample value
*   variance / CI (15)              Omega = (N-1) sum (.)(.)' ; Avar = Om/N
*   Remark 2                        xbar^a_i = (1, xbar_i')' EXCLUDES ybar_i

capture program drop xtgcce
program define xtgcce, eclass sortpreserve
	version 14.0

	if replay() {
		if ("`e(cmd)'" != "xtgcce") error 301
		syntax [, Level(cilevel) *]
		xtgcce_display, level(`level')
		exit
	}

	syntax varlist(min=2 numeric ts) [if] [in] , 	///
		[										///
		CCE										///
		NOJackknife								///
		Level(cilevel)							///
		GRaph									///
		HISTogram								///
		NAME(string)							///
		TRace									///
		NOTable									///
		MAXUnits(integer 2000)					///
		]

	* ------------------------------------------------------------------
	* 0. Load the Mata engine (verify, do not assume)
	* ------------------------------------------------------------------
	capture mata: xtdg_inv(I(1))
	if _rc {
		capture qui xtdyngcce_mata
		capture mata: xtdg_inv(I(1))
		if _rc {
			capture findfile xtdyngcce_mata.ado
			if !_rc {
				qui do "`r(fn)'"
			}
		}
	}
	capture mata: xtdg_inv(I(1))
	if _rc {
		di as err "the xtdyngcce Mata library could not be loaded;"
		di as err "re-install the package (xtdyngcce_mata.ado is missing)"
		exit 601
	}
	capture mata: mata describe xtgcce_work()
	if _rc {
		capture findfile xtdyngcce_mata.ado
		if !_rc {
			qui do "`r(fn)'"
		}
	}

	gettoken depvar indeps : varlist
	local k : word count `indeps'
	local dojack = ("`nojackknife'" == "")
	local trc    = ("`trace'" != "")
	local docce  = ("`cce'" != "")

	* ------------------------------------------------------------------
	* Panel setup and a balanced sample
	* ------------------------------------------------------------------
	qui xtset
	local ivar "`r(panelvar)'"
	local tvar "`r(timevar)'"
	if ("`ivar'" == "" | "`tvar'" == "") {
		di as err "data must be {help xtset}'d with a panel and a time variable"
		exit 459
	}

	tempvar touse
	marksample touse
	markout `touse' `depvar' `indeps'

	qui count if `touse'
	if (r(N) == 0) {
		di as err "no observations"
		exit 2000
	}

	tempvar ni
	qui bys `touse' `ivar' : gen long `ni' = _N if `touse'
	qui sum `ni' if `touse', meanonly
	local Tmin = r(min)
	local Tmax = r(max)
	local Ndrop = 0
	if (`Tmin' != `Tmax') {
		qui levelsof `ivar' if `touse' & `ni' != `Tmax', local(dropids)
		local Ndrop : word count `dropids'
		qui replace `touse' = 0 if `ni' != `Tmax'
		di as txt "note: `Ndrop' panel(s) dropped -- the GCCE double"
		di as txt "      projection requires a common time grid."
	}

	tempvar tcnt trng
	qui bys `touse' `ivar' (`tvar') : gen long `tcnt' = _N if `touse'
	qui bys `touse' `ivar' (`tvar') : gen double `trng' = `tvar'[_N] - `tvar'[1] + 1 if `touse'
	qui count if `touse' & `tcnt' != `trng'
	if (r(N) > 0) {
		di as err "the estimation sample has gaps in the time dimension"
		exit 459
	}

	qui levelsof `ivar' if `touse', local(idlist)
	local N : word count `idlist'
	local T = `Tmax'

	if (`T' <= `k' + 2) {
		di as err "T = `T' is too small: the within-unit regression needs"
		di as err "more than k + 2 = `=`k'+2' periods"
		exit 2001
	}
	if (`N' < `k' + 3) {
		di as err "too few panels for the across-unit projection"
		exit 2001
	}

	* --- the joint system is (N*k) x (N*k); warn before it hurts ------
	local nk = `N' * `k'
	if (`nk' > `maxunits') {
		di as err "N x k = `nk' exceeds maxunits(`maxunits')."
		di as err "The GCCE system matrix is `nk' x `nk' and the"
		di as err "leave-one-out jackknife solves it `N' times."
		di as err "Raise maxunits() to proceed, or use nojackknife."
		exit 2001
	}
	if (`nk' > 600 & `dojack' == 1) {
		di as txt "note: N x k = `nk'; the leave-one-out jackknife solves"
		di as txt "      a `nk' x `nk' system `N' times. This may take a while."
		di as txt "      Use {cmd:nojackknife} for point estimates only."
	}

	* ------------------------------------------------------------------
	* Estimate
	* ------------------------------------------------------------------
	tempname b V Bi CIlo CIhi Dj bcce
	sort `ivar' `tvar'

	mata: xtgcce_work("`depvar'", "`indeps'", "`touse'", "`ivar'",	///
		`dojack', `docce', `level', `trc',							///
		"`b'", "`V'", "`Bi'", "`CIlo'", "`CIhi'", "`Dj'", "`bcce'")

	matrix colnames `b'    = `indeps'
	matrix rownames `b'    = y1
	matrix colnames `V'    = `indeps'
	matrix rownames `V'    = `indeps'
	matrix colnames `CIlo' = `indeps'
	matrix colnames `CIhi' = `indeps'
	matrix colnames `Bi'   = `indeps'

	qui count if `touse'
	ereturn post `b' `V', depname(`depvar') obs(`r(N)') esample(`touse')

	ereturn local cmd        "xtgcce"
	ereturn local cmdline    "xtgcce `0'"
	ereturn local depvar     "`depvar'"
	ereturn local indeps     "`indeps'"
	ereturn local ivar       "`ivar'"
	ereturn local tvar       "`tvar'"
	ereturn local estimator  "GCCE-MG"
	ereturn local vcetype    "leave-one-out jackknife"
	ereturn local title      "Generalized CCE mean-group estimation"
	ereturn local properties "b V"

	ereturn scalar N_g     = `N'
	ereturn scalar T       = `T'
	ereturn scalar k_x     = `k'
	ereturn scalar level   = `level'
	ereturn scalar jack    = `dojack'
	ereturn scalar N_drop  = `Ndrop'

	ereturn matrix ci_lo = `CIlo'
	ereturn matrix ci_hi = `CIhi'
	ereturn matrix b_i   = `Bi'
	if (`dojack' == 1) {
		ereturn matrix b_loo = `Dj'
	}
	if (`docce' == 1) {
		matrix colnames `bcce' = `indeps'
		ereturn matrix b_cce = `bcce'
	}

	if ("`notable'" == "") {
		xtgcce_display, level(`level')
	}
	if ("`graph'" != "" | "`histogram'" != "") {
		if ("`name'" == "") local name "xtgcce"
		xtgcce_graph, name(`name') `histogram'
	}
end


*=======================================================================
* Display
*=======================================================================
capture program drop xtgcce_display
program define xtgcce_display
	syntax [, Level(cilevel) ]

	local depvar "`e(depvar)'"
	local N = e(N_g)
	local T = e(T)
	local k = e(k_x)

	di ""
	di as txt "{hline 78}"
	di as txt " Generalized Common Correlated Effects (GCCE)" ///
		_col(52) "Number of panels" _col(70) "= " as res %6.0f `N'
	di as txt " Estimator: " as res "GCCE mean group" as txt ///
		_col(52) "Time periods" _col(70) "= " as res %6.0f `T'
	di as txt " Dep. var.: " as res "`depvar'" as txt ///
		_col(52) "Observations" _col(70) "= " as res %6.0f e(N)
	local vl = cond(e(jack) == 1, "leave-one-out jackknife", "none (point estimates only)")
	di as txt " Inference: " as res "`vl'"
	di as txt "{hline 78}"

	local cl = `level'
	di as txt %-16s "`depvar'" _col(17) "{c |}" ///
		_col(21) "Coef." _col(33) "Std. err." _col(46) "z" _col(54) "P>|z|" ///
		_col(62) "[`cl'% conf. int.]"
	di as txt "{hline 17}{c +}{hline 60}"

	tempname b V lo hi
	matrix `b'  = e(b)
	matrix `V'  = e(V)
	matrix `lo' = e(ci_lo)
	matrix `hi' = e(ci_hi)
	local names : colnames `b'

	local j = 0
	foreach nm of local names {
		local ++j
		local co = `b'[1, `j']
		local se = sqrt(`V'[`j', `j'])
		local zz = .
		local pp = .
		if (`se' > 0 & `se' < .) {
			local zz = `co'/`se'
			local pp = 2*normal(-abs(`zz'))
		}
		local st = ""
		if (`pp' < 0.10) local st "*"
		if (`pp' < 0.05) local st "**"
		if (`pp' < 0.01) local st "***"
		di as txt %-16s abbrev("`nm'", 16) _col(17) "{c |}" ///
			as res _col(19) %10.0g `co' _col(32) %10.0g `se' ///
			_col(44) %7.2f `zz' _col(53) %6.3f `pp' ///
			_col(61) %10.0g `lo'[1, `j'] _col(72) %10.0g `hi'[1, `j'] ///
			as txt " `st'"
	}
	di as txt "{hline 17}{c BT}{hline 60}"

	* --- CCE comparison block -----------------------------------------
	capture confirm matrix e(b_cce)
	if (!_rc) {
		tempname bc
		matrix `bc' = e(b_cce)
		di as txt ""
		di as txt " Comparison with the conventional CCE-MG estimator"
		di as txt "{hline 17}{c TT}{hline 44}"
		di as txt %-16s "variable" _col(17) "{c |}" _col(24) "CCE-MG" ///
			_col(38) "GCCE-MG" _col(52) "difference"
		di as txt "{hline 17}{c +}{hline 44}"
		local j = 0
		foreach nm of local names {
			local ++j
			local c1 = `bc'[1, `j']
			local c2 = `b'[1, `j']
			di as txt %-16s abbrev("`nm'", 16) _col(17) "{c |}" ///
				as res _col(22) %10.0g `c1' _col(36) %10.0g `c2' ///
				_col(50) %10.0g `=`c2'-`c1''
		}
		di as txt "{hline 17}{c BT}{hline 44}"
		di as txt " A large gap is evidence that the CCE rank condition fails."
		di as txt " GCCE is consistent either way (Lu, Su & Ba 2026, Thm 3.2)."
	}

	* --- heterogeneity of the unit-specific slopes --------------------
	capture confirm matrix e(b_i)
	if (!_rc) {
		tempname Bi
		matrix `Bi' = e(b_i)
		di as txt ""
		di as txt " Dispersion of the unit-specific slopes b(i)"
		di as txt "{hline 17}{c TT}{hline 50}"
		di as txt %-16s "variable" _col(17) "{c |}" _col(23) "sd" ///
			_col(35) "p10" _col(47) "p50" _col(59) "p90"
		di as txt "{hline 17}{c +}{hline 50}"
		preserve
		qui svmat double `Bi', name(_bgi)
		local j = 0
		foreach nm of local names {
			local ++j
			qui sum _bgi`j', detail
			di as txt %-16s abbrev("`nm'", 16) _col(17) "{c |}" ///
				as res _col(20) %9.0g r(sd) _col(32) %9.0g r(p10) ///
				_col(44) %9.0g r(p50) _col(56) %9.0g r(p90)
		}
		restore
		di as txt "{hline 17}{c BT}{hline 50}"
	}

	di as txt ""
	di as txt " * p<0.10, ** p<0.05, *** p<0.01"
	di as txt " Augmentation: cross-section averages zbar(t) of (" ///
		as res "`depvar'" as txt ", regressors)"
	di as txt "               time-series averages xbar(i) of the regressors" ///
		as txt " + constant"
	di as txt " Note: ybar(i) is deliberately excluded (Lu, Su & Ba 2026, Remark 2)."
	if (e(N_drop) > 0) {
		di as txt " Panels dropped for unbalancedness: " as res e(N_drop)
	}
	di as txt "{hline 78}"
end


*=======================================================================
* Graph
*=======================================================================
capture program drop xtgcce_graph
program define xtgcce_graph
	syntax [, NAME(string) HISTogram ]
	if ("`name'" == "") local name "xtgcce"

	tempname b lo hi Bi
	matrix `b'  = e(b)
	matrix `lo' = e(ci_lo)
	matrix `hi' = e(ci_hi)
	matrix `Bi' = e(b_i)
	local k = colsof(`b')
	local names : colnames `b'
	local lev = e(level)

	preserve
	clear
	qui set obs `k'
	qui gen int    _ord = _n
	qui gen double _cf  = .
	qui gen double _lo  = .
	qui gen double _hi  = .
	qui gen str32  _nm  = ""
	forvalues j = 1/`k' {
		local nm : word `j' of `names'
		qui replace _cf = `b'[1, `j']  in `j'
		qui replace _lo = `lo'[1, `j'] in `j'
		qui replace _hi = `hi'[1, `j'] in `j'
		qui replace _nm = abbrev("`nm'", 20) in `j'
	}
	local lbl
	forvalues j = 1/`k' {
		local tx = _nm[`j']
		local lbl `lbl' `j' "`tx'"
	}
	twoway (rcap _lo _hi _ord, horizontal lcolor(maroon) lwidth(medthick))	///
	       (scatter _ord _cf, msymbol(O) msize(medlarge)					///
	            mcolor(maroon) mlcolor(white) mlwidth(thin)),				///
	       yscale(reverse) ylabel(`lbl', angle(0) nogrid labsize(small))	///
	       xline(0, lcolor(gs10) lpattern(dash))							///
	       xtitle("Mean-group coefficient", size(small)) ytitle("")			///
	       title("GCCE mean-group estimates", size(medium) color(black))	///
	       subtitle("`lev'% jackknife confidence intervals", size(small) color(gs6)) ///
	       legend(off) graphregion(color(white)) plotregion(color(white))	///
	       name(`name'_coef, replace)
	restore

	if ("`histogram'" != "") {
		preserve
		clear
		qui svmat double `Bi', name(_bg)
		local plots
		forvalues j = 1/`k' {
			local nm : word `j' of `names'
			local pt = `b'[1, `j']
			histogram _bg`j', fraction color(maroon%45) lcolor(white)	///
				lwidth(vvthin) xline(`pt', lcolor(navy) lwidth(medthick))	///
				xtitle("`nm'", size(small)) ytitle("Fraction", size(small))	///
				title("") graphregion(color(white))						///
				name(`name'_h`j', replace) nodraw
			local plots `plots' `name'_h`j'
		}
		graph combine `plots',											///
			title("Unit-specific GCCE slopes", size(medium) color(black))	///
			subtitle("blue line = mean group", size(small) color(gs6))	///
			graphregion(color(white)) name(`name'_hist, replace)
		restore
	}
end
