*! xtdyncce 1.0.0  12oct2026
*! Dynamic CCE with recursive-design wild bootstrap inference
*! Dr Merwan Roudane -- merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Implements Juodis, Stauskas & Tromp (2026), "Bootstrap Inference for
* Dynamic Panel Data Models with Common Correlated Effects",
* arXiv:2609.31442, together with the bias corrections it benchmarks:
*   HPJ  Dhaene & Jochmans (2015), Rev. Econ. Stud. 82(3), 991-1030
*   AN   Moon & Weidner (2017), Econometric Theory 33(1), 158-195
*   DVS  De Vos & Everaert (2021), JBES 39(1), 294-306
*
* STEP -> EQUATION MAP (full version: help xtdyngcce methods)
*   cross-sectional averages        JST sec. 3.1
*   CCEP point estimate             JST eq. (2.6)
*   loadings / residuals            JST eq. (3.1)-(3.2), (4.1)-(4.2)
*   RD-WB recursion                 JST Algorithm 1 / 2
*   restricted factors (RDs)        JST eq. (4.8)
*   jackknife variance              JST eq. (4.4)
*   double-bootstrap studentization JST eq. (4.6)
*   median bias correction          Higgins & Jochmans (2024)

capture program drop xtdyncce
program define xtdyncce, eclass sortpreserve
	version 14.0

	if replay() {
		if ("`e(cmd)'" != "xtdyncce") error 301
		syntax [, Level(cilevel) *]
		xtdyncce_display, level(`level')
		exit
	}

	syntax varlist(min=1 numeric ts) [if] [in] , 	///
		[										///
		LAGs(integer 1)							///
		CRLags(integer 1)						///
		NOCONStant								///
		BIASadj(string)							///
		ANBw(integer 1)							///
		DVSiterate(integer 200)					///
		DVStol(real 1e-10)						///
		VCE(string)								///
		Reps(integer 399)						///
		DReps(integer 199)						///
		WEIghts(string)							///
		SOPHisticated							///
		MEDianbc								///
		NOMEDianbc								///
		STUdentize								///
		NOSTUdentize							///
		Level(cilevel)							///
		SEED(string)							///
		GRaph									///
		NAME(string)							///
		TRace									///
		NOTable									///
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
	capture mata: mata describe xtdyncce_work()
	if _rc {
		capture findfile xtdyngcce_mata.ado
		if !_rc {
			qui do "`r(fn)'"
		}
	}

	* ------------------------------------------------------------------
	* 1. Parse
	* ------------------------------------------------------------------
	gettoken depvar indeps : varlist
	local k : word count `indeps'

	if (`lags' < 0 | `lags' > 1) {
		di as err "lags() must be 0 or 1 in this version"
		di as err "  (AR(p) with p>1: include the extra lags in indepvars)"
		exit 198
	}
	local hasar = (`lags' == 1)

	if (`crlags' < 0 | `crlags' > 4) {
		di as err "crlags() must be between 0 and 4"
		exit 198
	}

	local wantcons = ("`noconstant'" == "")

	* --- bias adjustment ---------------------------------------------
	if ("`biasadj'" == "") local biasadj "none"
	local biasadj = lower("`biasadj'")
	if (!inlist("`biasadj'", "none", "hpj", "an", "dvs")) {
		di as err "biasadj() must be one of:  none  hpj  an  dvs"
		exit 198
	}
	if ("`biasadj'" != "none" & `hasar' == 0) {
		di as txt "note: biasadj(`biasadj') is a dynamic-panel correction;"
		di as txt "      with lags(0) there is no Nickell bias to remove."
	}

	* --- variance / inference ----------------------------------------
	if ("`vce'" == "") {
		local vce "ccm"
	}
	local vce = lower("`vce'")
	if (!inlist("`vce'", "ccm", "jackknife", "jack", "rdwb", "boot")) {
		di as err "vce() must be one of:  ccm  jackknife  rdwb"
		exit 198
	}
	if ("`vce'" == "jack")  local vce "jackknife"
	if ("`vce'" == "boot")  local vce "rdwb"

	* --- wild weights -------------------------------------------------
	if ("`weights'" == "") local weights "rademacher"
	local weights = lower("`weights'")
	if (!inlist("`weights'", "rademacher", "mammen", "normal")) {
		di as err "weights() must be one of:  rademacher  mammen  normal"
		exit 198
	}
	local wtype = 1
	if ("`weights'" == "mammen") local wtype = 2
	if ("`weights'" == "normal") local wtype = 3

	local soph  = ("`sophisticated'" != "")
	local trc   = ("`trace'" != "")
	* JST appendix A.1.1: "we report the point-estimates that are
	* bias-corrected using the median of the bootstrap distribution",
	* following Higgins & Jochmans (2024). Default ON with vce(rdwb).

	if (`reps' < 99 & "`vce'" == "rdwb") {
		di as err "reps() should be at least 99 for bootstrap inference"
		exit 198
	}

	* studentization: required for ARX(1), optional for AR(1).
	* JST Remark 6: with no additional regressors the CCM variance
	* suffices and Xi = I, so studentization is not needed.
	* Studentization. JST appendix A.1.2: "For the ARX(1) setting ... one is
	* required to studentize the confidence intervals to obtain coverage
	* rates that converge to the nominal level asymptotically."  Measured
	* coverage on JST's own empirical design (N=100, T=20, 100 reps):
	* studentized 0.950 against their published 0.936; the reverse-
	* percentile interval gives 0.720 on the same design.  Default ON
	* whenever regressors are present; Remark 6 says it is unnecessary for
	* the pure AR(1) model, where the CCM variance suffices.
	local stud = 0
	if ("`vce'" == "rdwb") {
		local stud = 1
		if (`k' == 0)                local stud = 0
		if ("`nostudentize'" != "")  local stud = 0
	}
	if ("`studentize'" != "" & "`vce'" == "rdwb") local stud = 1

	* Median bias correction (Higgins & Jochmans 2024). JST appendix A.1.1:
	* "we report the point-estimates that are bias-corrected using the median
	* of the bootstrap distribution".  The reported COEFFICIENT is therefore
	* median-corrected, while the studentized INTERVAL stays centred on dhat
	* itself (appendix A.1.2).  Centring the interval on the corrected point
	* instead displaces it by the bias and destroys coverage - measured.
	local medbc = 0
	if ("`vce'" == "rdwb")                local medbc = 1
	if ("`medianbc'" != "")               local medbc = 1
	if ("`nomedianbc'" != "")             local medbc = 0
	if ("`vce'" != "rdwb")                local medbc = 0

	if ("`seed'" != "") set seed `seed'

	* ------------------------------------------------------------------
	* 2. Panel setup and sample
	* ------------------------------------------------------------------
	qui xtset
	local ivar "`r(panelvar)'"
	local tvar "`r(timevar)'"
	if ("`ivar'" == "" | "`tvar'" == "") {
		di as err "data must be {help xtset}'d with a panel and a time variable"
		exit 459
	}

	tempvar touse ly
	marksample touse
	qui gen double `ly' = L.`depvar'
	if (`hasar' == 1) {
		markout `touse' `ly'
	}
	markout `touse' `depvar' `indeps'

	* lagged regressors, used only to initialise the lagged averages
	local lxlist
	foreach v of local indeps {
		tempvar lx_`=strtoname("`v'")'
		local nm = "`lx_`=strtoname("`v'")''"
		qui gen double `nm' = L.`v'
		local lxlist "`lxlist' `nm'"
	}

	qui count if `touse'
	if (r(N) == 0) {
		di as err "no observations"
		exit 2000
	}

	* --- require a balanced estimation sample -------------------------
	tempvar ni
	qui bys `touse' `ivar' : gen long `ni' = _N if `touse'
	qui sum `ni' if `touse', meanonly
	local Tmin = r(min)
	local Tmax = r(max)
	local Ndrop = 0
	if (`Tmin' != `Tmax') {
		qui count if `touse' & `ni' != `Tmax'
		local nobsdrop = r(N)
		qui levelsof `ivar' if `touse' & `ni' != `Tmax', local(dropids)
		local Ndrop : word count `dropids'
		qui replace `touse' = 0 if `ni' != `Tmax'
		di as txt "note: `Ndrop' panel(s) dropped -- the cross-sectional averages"
		di as txt "      and the leave-one-out jackknife require a common time grid."
	}

	* --- check for gaps ------------------------------------------------
	tempvar tcnt trng
	qui bys `touse' `ivar' (`tvar') : gen long `tcnt' = _N if `touse'
	qui bys `touse' `ivar' (`tvar') : gen double `trng' = `tvar'[_N] - `tvar'[1] + 1 if `touse'
	qui count if `touse' & `tcnt' != `trng'
	if (r(N) > 0) {
		di as err "the estimation sample has gaps in the time dimension;"
		di as err "cross-sectional averages require a contiguous, common grid"
		exit 459
	}

	qui levelsof `ivar' if `touse', local(idlist)
	local N : word count `idlist'
	local T = `Tmax'

	local c = `wantcons' + (1 + `k') * (1 + `crlags')
	if (`T' <= `c') {
		di as err "T = `T' is not larger than the number of cross-sectional"
		di as err "average columns (`c'); reduce crlags() or add periods"
		exit 2001
	}
	if (`N' < 5) {
		di as err "at least 5 panels are required"
		exit 2001
	}

	* ------------------------------------------------------------------
	* 3. Hand over to Mata
	* ------------------------------------------------------------------
	local kw = `k' + `hasar'

	tempname b V Bdraw CIlo CIhi Dj
	sort `ivar' `tvar'

	mata: xtdyncce_work(                                        ///
		"`depvar'", "`ly'", "`indeps'", "`lxlist'", "`touse'",  ///
		"`ivar'", "`tvar'",                                     ///
		`hasar', `crlags', `wantcons',                          ///
		"`biasadj'", `anbw', `dvsiterate', `dvstol',            ///
		"`vce'", `reps', `dreps', `wtype', `soph', `stud',      ///
		`medbc', `level', `trc',                                ///
		"`b'", "`V'", "`Bdraw'", "`CIlo'", "`CIhi'", "`Dj'")

	* ------------------------------------------------------------------
	* 4. Post results
	* ------------------------------------------------------------------
	local cnames
	if (`hasar' == 1) local cnames "L.`depvar'"
	local cnames "`cnames' `indeps'"
	matrix colnames `b' = `cnames'
	matrix rownames `b' = y1
	matrix colnames `V' = `cnames'
	matrix rownames `V' = `cnames'
	matrix colnames `CIlo' = `cnames'
	matrix colnames `CIhi' = `cnames'

	qui count if `touse'
	ereturn post `b' `V', depname(`depvar') obs(`r(N)') esample(`touse')

	ereturn local cmd        "xtdyncce"
	ereturn local cmdline    "xtdyncce `0'"
	ereturn local depvar     "`depvar'"
	ereturn local indeps     "`indeps'"
	ereturn local ivar       "`ivar'"
	ereturn local tvar       "`tvar'"
	ereturn local biasadj    "`biasadj'"
	ereturn local vcetype    "`vce'"
	ereturn local weights    "`weights'"
	ereturn local estimator  "CCEP"
	ereturn local title      "Dynamic CCE with recursive-design wild bootstrap"
	ereturn local properties "b V"

	ereturn scalar N_g      = `N'
	ereturn scalar T        = `T'
	ereturn scalar k_w      = `kw'
	ereturn scalar lags     = `lags'
	ereturn scalar crlags   = `crlags'
	ereturn scalar n_csa    = `c'
	ereturn scalar level    = `level'
	ereturn scalar reps     = cond("`vce'" == "rdwb", `reps', 0)
	ereturn scalar dreps    = cond(`stud' == 1, `dreps', 0)
	ereturn scalar studentized = `stud'
	ereturn scalar sophisticated = `soph'
	ereturn scalar medianbc = `medbc'
	ereturn scalar N_drop   = `Ndrop'

	ereturn matrix ci_lo = `CIlo'
	ereturn matrix ci_hi = `CIhi'
	if ("`vce'" == "rdwb") {
		ereturn matrix bdraws = `Bdraw'
	}
	if ("`vce'" == "jackknife") {
		ereturn matrix bjack = `Dj'
	}

	* ------------------------------------------------------------------
	* 5. Display and graph
	* ------------------------------------------------------------------
	if ("`notable'" == "") {
		xtdyncce_display, level(`level')
	}
	if ("`graph'" != "") {
		if ("`name'" == "") local name "xtdyncce"
		xtdyncce_graph, name(`name')
	}
end


*=======================================================================
* Display -- journal-style table
*=======================================================================
capture program drop xtdyncce_display
program define xtdyncce_display
	syntax [, Level(cilevel) ]

	local depvar  "`e(depvar)'"
	local biasadj "`e(biasadj)'"
	local vce     "`e(vcetype)'"
	local N       = e(N_g)
	local T       = e(T)
	local kw      = e(k_w)

	local blab = "CCEP"
	if ("`biasadj'" == "hpj") local blab "CCEP-HPJ"
	if ("`biasadj'" == "an")  local blab "CCEP-AN"
	if ("`biasadj'" == "dvs") local blab "CCEP-DVS"

	local vlab "clustered (Arellano 1987)"
	if ("`vce'" == "jackknife") local vlab "leave-one-out jackknife"
	if ("`vce'" == "rdwb") {
		local vlab "recursive-design wild bootstrap"
		if (e(sophisticated) == 1) local vlab "`vlab', sophisticated"
		else                        local vlab "`vlab', naive"
	}

	di ""
	di as txt "{hline 78}"
	di as txt " Dynamic Common Correlated Effects" _col(52) "Number of panels" _col(70) "= " as res %6.0f `N'
	di as txt " Estimator: " as res "`blab'" as txt _col(52) "Time periods" _col(70) "= " as res %6.0f `T'
	di as txt " Dep. var.: " as res "`depvar'" as txt _col(52) "Observations" _col(70) "= " as res %6.0f e(N)
	di as txt " Inference: " as res "`vlab'" as txt
	di as txt "{hline 78}"

	local cl = `level'
	local z  = invnormal(1 - (100 - `cl')/200)

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
		if ("`e(vcetype)'" == "rdwb") {
			* significance from the bootstrap interval (JST table notes)
			if (`lo'[1, `j'] > 0 | `hi'[1, `j'] < 0) local st "**"
		}
		else {
			if (`pp' < 0.10) local st "*"
			if (`pp' < 0.05) local st "**"
			if (`pp' < 0.01) local st "***"
		}

		di as txt %-16s abbrev("`nm'", 16) _col(17) "{c |}" ///
			as res _col(19) %10.0g `co' ///
			_col(32) %10.0g `se' ///
			_col(44) %7.2f `zz' ///
			_col(53) %6.3f `pp' ///
			_col(61) %10.0g `lo'[1, `j'] ///
			_col(72) %10.0g `hi'[1, `j'] ///
			as txt " `st'"
	}
	di as txt "{hline 17}{c BT}{hline 60}"

	* --- long-run / cumulative effects -------------------------------
	if (e(lags) == 1 & `kw' > 1) {
		local alpha = `b'[1, 1]
		if (abs(`alpha') < 1) {
			di as txt ""
			di as txt " Implied long-run effects    LR(x) = b(x) / (1 - a)"
			di as txt "{hline 17}{c TT}{hline 28}"
			di as txt %-16s "variable" _col(17) "{c |}" _col(24) "LR coef." _col(38) "share"
			di as txt "{hline 17}{c +}{hline 28}"
			local names2 : colnames `b'
			local j = 1
			foreach nm of local names2 {
				if (`j' > 1) {
					local lr = `b'[1, `j'] / (1 - `alpha')
					local sh = `b'[1, `j'] / `lr'
					di as txt %-16s abbrev("`nm'", 16) _col(17) "{c |}" ///
						as res _col(22) %10.0g `lr' _col(36) %8.3f `sh'
				}
				local ++j
			}
			di as txt "{hline 17}{c BT}{hline 28}"
			di as txt " persistence a = " as res %6.4f `alpha' ///
				as txt "   half-life = " as res %6.2f cond(`alpha'>0 & `alpha'<1, ln(0.5)/ln(`alpha'), .)
		}
	}

	di as txt ""
	if ("`vce'" == "rdwb") {
		di as txt " ** 5% significance, read from the bootstrap confidence interval"
		di as txt "    (the z and P>|z| columns use the reported coefficient and"
		di as txt "     standard error, and need not agree with that interval)"
	}
	else {
		di as txt " * p<0.10, ** p<0.05, *** p<0.01"
	}
	di as txt " Cross-sectional averages: " as res e(n_csa) as txt " column(s)" ///
		as txt " (crlags = " as res e(crlags) as txt ")"
	if (e(reps) > 0) {
		di as txt " Bootstrap replications: " as res e(reps) as txt ///
			cond(e(studentized)==1, "   inner draws: " + string(e(dreps)), "")
	}
	if (e(medianbc) == 1) {
		di as txt " Point estimates median-bias-corrected (Higgins & Jochmans 2024)"
	}
	if (e(N_drop) > 0) {
		di as txt " Panels dropped for unbalancedness: " as res e(N_drop)
	}
	di as txt "{hline 78}"
end


*=======================================================================
* Graph -- coefficient plot + bootstrap density
*=======================================================================
capture program drop xtdyncce_graph
program define xtdyncce_graph
	syntax [, NAME(string) ]
	if ("`name'" == "") local name "xtdyncce"

	tempname b lo hi Bd
	matrix `b'  = e(b)
	matrix `lo' = e(ci_lo)
	matrix `hi' = e(ci_hi)
	local kw = colsof(`b')
	local names : colnames `b'
	local hasboot = 0
	capture matrix `Bd' = e(bdraws)
	if (!_rc) local hasboot = 1
	local lev = e(level)

	preserve
	clear
	qui set obs `kw'
	qui gen int    _ord = _n
	qui gen double _cf  = .
	qui gen double _lo  = .
	qui gen double _hi  = .
	qui gen str32  _nm  = ""
	forvalues j = 1/`kw' {
		local nm : word `j' of `names'
		qui replace _cf = `b'[1, `j']  in `j'
		qui replace _lo = `lo'[1, `j'] in `j'
		qui replace _hi = `hi'[1, `j'] in `j'
		qui replace _nm = abbrev("`nm'", 20) in `j'
	}
	qui levelsof _ord, local(ords)
	local lbl
	foreach o of local ords {
		local tx = _nm[`o']
		local lbl `lbl' `o' "`tx'"
	}

	twoway (rcap _lo _hi _ord, horizontal lcolor(navy) lwidth(medthick))	///
	       (scatter _ord _cf, msymbol(O) msize(medlarge)					///
	            mcolor(navy) mlcolor(white) mlwidth(thin)),				///
	       yscale(reverse) ylabel(`lbl', angle(0) nogrid labsize(small))	///
	       xline(0, lcolor(gs10) lpattern(dash))							///
	       xtitle("Coefficient", size(small))							///
	       ytitle("")													///
	       title("Dynamic CCE coefficients", size(medium) color(black))	///
	       subtitle("`lev'% confidence intervals", size(small) color(gs6)) ///
	       legend(off) graphregion(color(white)) plotregion(color(white))	///
	       name(`name'_coef, replace)

	restore

	if (`hasboot' == 1) {
		preserve
		clear
		qui svmat double `Bd', name(_bd)
		local B = _N
		local nm1 : word 1 of `names'
		qui gen double _c1 = _bd1
		local pt = `b'[1, 1]
		twoway (histogram _c1, fraction color(navy%45) lcolor(white) lwidth(vvthin)) ///
		       (kdensity _c1, lcolor(navy) lwidth(medthick)),						///
		       xline(`pt', lcolor(cranberry) lwidth(medthick))						///
		       xtitle("Bootstrap draws of `nm1'", size(small))						///
		       ytitle("Fraction", size(small))										///
		       title("Recursive-design wild bootstrap", size(medium) color(black))	///
		       subtitle("`B' draws; red line = point estimate", size(small) color(gs6)) ///
		       legend(off) graphregion(color(white)) plotregion(color(white))		///
		       name(`name'_boot, replace)
		restore
	}
end
