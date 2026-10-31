*! version 1.0.0  25oct2026  Yusuf Toyin Yusuf (Kwara State University)
*! polyreg: regression on a polychoric principal-component (or factor) index,
*! with bootstrap inference that re-estimates the index in every replication,
*! so that standard errors account for the generated-regressor problem.
*! Requires polycorr (polycorr, polyindex).

program define polyreg, eclass
	version 14

	if replay() {
		if `"`e(cmd)'"' != "polyreg" error 301
		Display `0'
		exit
	}
	local cmdline `"polyreg `0'"'

	capture which polyindex
	if _rc {
		di as err "polyreg requires polyindex (package polycorr); type {bf:net install polycorr}"
		exit 199
	}

	syntax varlist(numeric fv ts min=1) [if] [in] [fweight aweight pweight] , ///
		INDex(varlist numeric min=2)                                       ///
		[ MODel(string) REPS(integer 199) CLuster(varname) SEED(string)    ///
		  QUANTiles(integer 0) NCOMP(integer 1) METHod(passthru)           ///
		  ROTate(passthru) CATmax(passthru) ORDinal(passthru)              ///
		  CONTinuous(passthru) PDfix Level(cilevel) noDOTS ]

	if "`model'" == "" local model regress
	local model = lower("`model'")
	if !inlist("`model'", "regress", "logit", "probit", "poisson") {
		di as err "model() must be regress, logit, probit or poisson"
		exit 198
	}
	if `reps' < 20 {
		di as err "reps() must be at least 20 (199 or more recommended)"
		exit 198
	}
	if `quantiles' == 1 | `quantiles' < 0 {
		di as err "quantiles() must be 0 (continuous index) or at least 2"
		exit 198
	}
	if `quantiles' > 1 & `ncomp' > 1 {
		di as err "quantiles() uses the first component only; specify ncomp(1)"
		exit 198
	}
	if "`seed'" != "" set seed `seed'

	gettoken depvar xvars : varlist
	_fv_check_depvar `depvar'
	local both : list index & xvars
	if "`both'" != "" {
		di as err "`both' appear both in index() and among the regressors"
		exit 198
	}

	marksample touse
	markout `touse' `index'
	if "`cluster'" != "" markout `touse' `cluster', strok
	quietly count if `touse'
	if r(N) < 20 error 2001
	local wgt
	if "`weight'" != "" local wgt "[`weight'`exp']"
	local vceopt = cond("`cluster'" != "", "vce(cluster `cluster')", "vce(robust)")

	* --------------------------------------------- full-sample index and model
	tempname bfull Vnaive Bm
	local stub __prx
	local qv   __prxq
	forvalues c = 1/`ncomp' {
		capture drop `stub'`c'
	}
	capture drop `qv'
	quietly polyindex `index' if `touse' `wgt', gen(`stub') ncomp(`ncomp') ///
		`method' `rotate' `catmax' `ordinal' `continuous' `pdfix'
	local ivars
	forvalues c = 1/`ncomp' {
		local ivars `ivars' `stub'`c'
	}
	if `quantiles' > 1 {
		quietly xtile `qv' = `stub'1 if `touse' `wgt', nq(`quantiles')
		local rhs i.`qv'
	}
	else local rhs `ivars'

	capture quietly `model' `depvar' `rhs' `xvars' if `touse' `wgt', `vceopt'
	if _rc {
		di as err "`model' failed on the full sample"
		exit _rc
	}
	matrix `bfull'  = e(b)
	matrix `Vnaive' = e(V)
	local N     = e(N)
	local nb    = colsof(`bfull')
	local names : colfullnames `bfull'

	* --------------------------------------------- bootstrap
	matrix `Bm' = J(`reps', `nb', .)
	local ok 0
	if "`dots'" == "" di as txt "Bootstrap replications (" as res `reps' as txt "): " _c
	forvalues r = 1/`reps' {
		preserve
		quietly keep if `touse'
		if "`cluster'" != "" bsample, cluster(`cluster')
		else                 bsample
		forvalues c = 1/`ncomp' {
			capture drop `stub'`c'
		}
		capture drop `qv'
		capture quietly polyindex `index' `wgt', gen(`stub') ncomp(`ncomp') ///
			`method' `rotate' `catmax' `ordinal' `continuous' `pdfix'
		local rc = _rc
		if !`rc' & `quantiles' > 1 {
			capture quietly xtile `qv' = `stub'1 `wgt', nq(`quantiles')
			local rc = _rc
		}
		if !`rc' {
			capture quietly `model' `depvar' `rhs' `xvars' `wgt'
			local rc = _rc
		}
		if !`rc' {
			tempname br
			matrix `br' = e(b)
			if colsof(`br') == `nb' {
				local nmr : colfullnames `br'
				if "`nmr'" == "`names'" {
					forvalues j = 1/`nb' {
						matrix `Bm'[`r', `j'] = `br'[1, `j']
					}
					local ++ok
				}
				else local rc 1
			}
			else local rc 1
		}
		restore
		if "`dots'" == "" {
			if `rc' di as err "x" _c
			else    di as txt "." _c
		}
	}
	if "`dots'" == "" di
	if `ok' < 10 {
		di as err "only `ok' successful replications"
		exit 498
	}

	tempname Vb ci
	mata: pr_bootvar("`Bm'", "`Vb'", "`ci'", `level')
	matrix colnames `Vb' = `names'
	matrix rownames `Vb' = `names'
	matrix colnames `ci' = `names'
	matrix rownames `ci' = ll ul

	* keep the full-sample index variables for the user
	forvalues c = 1/`ncomp' {
		label variable `stub'`c' "polyreg: polychoric index `c'"
	}
	if `quantiles' > 1 label variable `qv' "polyreg: quantile group of polychoric index 1"

	ereturn post `bfull' `Vb', esample(`touse') obs(`N') depname(`depvar')
	ereturn scalar reps     = `reps'
	ereturn scalar reps_ok  = `ok'
	ereturn scalar level    = `level'
	ereturn scalar ncomp    = `ncomp'
	ereturn scalar quantiles = `quantiles'
	if "`cluster'" != "" {
		tempvar tg
		quietly egen byte `tg' = tag(`cluster') if e(sample)
		quietly count if `tg' == 1
		ereturn scalar N_clust = r(N)
		ereturn local clustvar "`cluster'"
	}
	ereturn local model     "`model'"
	ereturn local index     "`index'"
	ereturn local indexvars "`ivars'"
	ereturn local xvars     "`xvars'"
	ereturn local depvar    "`depvar'"
	ereturn local vce       "bootstrap"
	ereturn local vcetype   "Bootstrap"
	if "`weight'" != "" {
		ereturn local wtype "`weight'"
		ereturn local wexp  `"`exp'"'
	}
	ereturn local title "`model' on a polychoric index (index re-estimated in each replication)"
	ereturn local cmdline `"`cmdline'"'
	ereturn matrix V_naive = `Vnaive'
	ereturn matrix ci_percentile = `ci'
	ereturn matrix b_boot = `Bm'
	ereturn local cmd "polyreg"

	Display, level(`level')
end

program define Display
	syntax [, Level(cilevel)]
	di
	di as txt "`e(title)'"
	di as txt "Number of obs = " as res %9.0fc e(N) as txt "   Replications = " as res e(reps_ok) ///
		as txt " of " as res e(reps) cond("`e(clustvar)'" != "", "   (resampling clusters of `e(clustvar)')", "")
	ereturn display, level(`level')
	tempname b V Vn
	matrix `b'  = e(b)
	matrix `V'  = e(V)
	matrix `Vn' = e(V_naive)
	local names : colfullnames `b'
	di as txt "Index terms: bootstrap vs naive standard errors (naive treats the index as data)"
	di as txt "{hline 66}"
	di as txt "Term" _col(30) "Coef." _col(40) "Boot SE" _col(50) "Naive SE" _col(61) "Ratio"
	di as txt "{hline 66}"
	local j 0
	foreach nm of local names {
		local ++j
		if strpos("`nm'", "__prx") {
			local se  = sqrt(`V'[`j', `j'])
			local sen = sqrt(`Vn'[`j', `j'])
			if `sen' > 0 & `sen' < . {
				di as txt %-28s abbrev("`nm'", 28) as res _col(27) %9.4f `b'[1, `j'] ///
					_col(38) %9.4f `se' _col(49) %9.4f `sen' _col(59) %7.3f `se'/`sen'
			}
		}
	}
	di as txt "{hline 66}"
	di as txt "Ratio > 1: the naive standard error understates uncertainty from estimating the index."
end

version 14
capture mata: mata drop pr_*()
mata:
mata set matastrict on

void pr_bootvar(string scalar bn, string scalar vn, string scalar cin, real scalar level)
{
	real matrix B, V, ci
	real colvector x
	real scalar j, a, n, lo, hi
	B  = st_matrix(bn)
	B  = select(B, rowmissing(B) :== 0)
	V  = variance(B)
	ci = J(2, cols(B), .)
	a  = (1 - level/100)/2
	for (j = 1; j <= cols(B); j++) {
		x  = sort(B[., j], 1)
		n  = rows(x)
		lo = max((1, floor(a*(n + 1))))
		hi = min((n, ceil((1 - a)*(n + 1))))
		ci[., j] = (x[lo] \ x[hi])
	}
	st_matrix(vn, V)
	st_matrix(cin, ci)
}

end
