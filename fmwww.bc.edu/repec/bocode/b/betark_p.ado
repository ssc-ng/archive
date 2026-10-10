*! 2.0.0 	Ariel Linden 30Sep2026  // added clinear and CI options to mimic predictnl
*! 1.1.0 	Ariel Linden 29Sep2026  // changed version to 11.0; fixed sort ordering
*! 1.0.0	Ariel Linden 27Jun2026

program define betark_p
	version 11.0
	if `"`e(cmd)'"' != "betark" {
		error 301
	}
	syntax newvarname [if] [in]		///
		[, CMean					///
		   CVARiance				///
		   CLinear					///
		   xb						///
		   XBSCAle					///
		   CI(namelist min=2 max=2) ///
		   REPs(integer 100)		///
		   LEVel(cilevel)			///
		   SEED(integer -1)			///
		]

	marksample touse, novarlist

	local case : word count `cmean' `cvariance' `clinear' `xb' `xbscale'
	if `case' > 1 {
		di as err "only one {it:statistic} may be specified"
		exit 498
	}
	if `case' == 0 {
		local cmean cmean
		di as txt "(option {bf:cmean} assumed)"
	}

	if `"`ci'"' != "" & (`"`xb'"' != "" | `"`xbscale'"' != "") {
		di as err "{bf:ci()} is not needed for {bf:xb}/{bf:xbscale}: these"
		di as err "do not depend on lagged outcomes, so {bf:predictnl}'s"
		di as err "delta-method {bf:ci()} option already works for them."
		exit 498
	}

	if `"`xb'"' != "" {
		_predict `typlist' `varlist' if `touse', xb equation(`e(depvar)')
		label var `varlist' "Linear prediction in `e(depvar)' equation (no AR adjustment)"
	}
	else if `"`xbscale'"' != "" {
		_predict `typlist' `varlist' if `touse', xb equation(scale)
		label var `varlist' "Linear prediction in scale equation"
	}
	else if `"`cmean'"' != "" {
		PredictCmean `typlist' `varlist', touse(`touse')
		label var `varlist' "Conditional (AR-adjusted, one-step-ahead) mean of `e(depvar)'"
		local statopt cmean
	}
	else if `"`clinear'"' != "" {
		PredictCmean `typlist' `varlist', touse(`touse') linear
		label var `varlist' "Conditional (AR-adjusted) linear predictor (logit scale) of `e(depvar)'"
		local statopt clinear
	}
	else if `"`cvariance'"' != "" {
		PredictCvar `typlist' `varlist', touse(`touse')
		label var `varlist' "Conditional (AR-adjusted) variance of `e(depvar)'"
		local statopt cvariance
	}

	if `"`ci'"' != "" {
		BetarkKRCI `ci', touse(`touse') stat(`statopt') ///
			reps(`reps') level(`level') seed(`seed')
	}
end


program define PredictCmean
	syntax newvarname [, touse(string) LINEAR]
	local vtyp : copy local typlist
	local varn : copy local varlist
	local dv `"`e(depvar)'"'

	local p = 0
	capture local rtest1 = _b[ar:rho1]
	if _rc == 0 {
		local p = 1
		capture local rtest2 = _b[ar:rho2]
		if _rc == 0 {
			local p = 2
			capture local rtest3 = _b[ar:rho3]
			if _rc == 0 local p = 3
		}
	}

	tempvar xb eta xi xicomplete
	quietly _predict double `xb' if `touse', xb equation(`dv')

	quietly gen double `xi' = 0 if `touse'
	quietly gen byte `xicomplete' = 1 if `touse'

	forvalues k = 1/`p' {
		tempvar lagy lagxb term
		quietly gen double `lagy'  = L`k'.`dv' if `touse'
		quietly gen double `lagxb' = L`k'.`xb' if `touse'
		quietly gen double `term'  = _b[ar:rho`k'] * (logit(`lagy') - `lagxb') if `touse'
		quietly replace `xi' = `xi' + `term' if `touse' & !missing(`term')
		quietly replace `xicomplete' = 0 if `touse' & missing(`term')
	}

	quietly gen double `eta' = `xb' + `xi' if `touse' & `xicomplete'
	quietly replace `eta' = `xb' if `touse' & !`xicomplete'

	if "`linear'" != "" {
		quietly gen `vtyp' `varn' = `eta' if `touse'
	}
	else {
		quietly gen `vtyp' `varn' = invlogit(`eta') if `touse'
	}
end


program define PredictCvar
	syntax newvarname [, touse(string)]
	tempvar mu_p phi_p
	PredictCmean `typlist' `mu_p', touse(`touse')

	tempvar zb
	quietly _predict double `zb' if `touse', xb equation(scale)
	quietly gen double `phi_p' = exp(`zb') if `touse'

	quietly gen `typlist' `varlist' = `mu_p'*(1-`mu_p')/(1+`phi_p') if `touse'
end


program define BetarkKRCI
	syntax newvarlist(min=2 max=2), touse(string) stat(string) ///
		reps(integer) level(real) seed(integer)

	tokenize `varlist'
	local lclname `1'
	local uclname `2'
	confirm new variable `lclname' `uclname'

	if `seed' != -1 {
		set seed `seed'
	}

	tempname b0 V0
	matrix `b0' = e(b)
	matrix `V0' = e(V)

	mata: st_local("__cholok", strofreal(!hasmissing(cholesky(st_matrix("`V0'")))))
	if "`__cholok'" != "1" {
		di as err "betark: e(V) is not positive definite; cannot compute a simulation-based CI"
		exit 506
	}
	mata: st_matrix("`V0'", cholesky(st_matrix("`V0'")))

	local bnames : colnames `b0'
	local beqs   : coleq `b0'
	local kb = colsof(`b0')

	tempname Draws
	mata: __betark_kr_draws("`b0'", "`V0'", `reps', "`Draws'")

	quietly count if `touse'
	local Nobs = r(N)
	if `Nobs' == 0 {
		di as err "betark: no observations in the estimation sample"
		exit 2000
	}

	mata: __betark_kr_store = J(`Nobs', `reps', .)

	quietly forvalues r = 1/`reps' {
		tempname bi
		matrix `bi' = `Draws'[`r', 1..`kb']
		if `r' == 1 & (rowsof(`bi') != 1 | colsof(`bi') != `kb') {
			noisily di as err "betark: internal error -- unexpected draw dimensions (got " ///
				rowsof(`bi') "x" colsof(`bi') ", expected 1x`kb')"
			exit 503
		}
		matrix colnames `bi' = `bnames'
		matrix coleq    `bi' = `beqs'
		BetarkRepost `bi'

		tempvar draw
		if "`stat'" == "cmean" {
			PredictCmean double `draw', touse(`touse')
		}
		else if "`stat'" == "clinear" {
			PredictCmean double `draw', touse(`touse') linear
		}
		else if "`stat'" == "cvariance" {
			PredictCvar double `draw', touse(`touse')
		}
		mata: st_view(__betark_kr_col=., ., "`draw'", "`touse'")
		mata: __betark_kr_store[., `r'] = __betark_kr_col
		drop `draw'
	}

	BetarkRepost `b0'

	local alpha = (100 - `level') / 200
	mata: __betark_kr_percentiles(__betark_kr_store, `alpha', ///
		"`lclname'", "`uclname'", "`touse'")
	mata: mata drop __betark_kr_store __betark_kr_col

	label var `lclname' "KR simulation lower CI bound (reps=`reps')"
	label var `uclname' "KR simulation upper CI bound (reps=`reps')"
end


program define BetarkRepost, eclass
	args bvec
	ereturn repost b = `bvec'
end


version 11.0
mata:
void __betark_kr_draws(string scalar bname, string scalar Lname,
                        real scalar reps, string scalar outname)
{
	real matrix b0, L, Z, draws
	real scalar i

	b0 = st_matrix(bname)
	L  = st_matrix(Lname)
	Z  = rnormal(reps, cols(b0), 0, 1)
	draws = J(reps, cols(b0), .)
	for (i=1; i<=reps; i++) {
		draws[i,.] = b0 + Z[i,.] * L'
	}
	st_matrix(outname, draws)
}

void __betark_kr_percentiles(real matrix X, real scalar alpha,
                              string scalar lclname, string scalar uclname,
                              string scalar touselist)
{
	real scalar n, m, i
	real colvector lcl, ucl, row

	n = rows(X)
	lcl = J(n,1,.)
	ucl = J(n,1,.)
	for (i=1; i<=n; i++) {
		row = sort(select(X[i,]', X[i,]' :!= .), 1)
		m = length(row)
		if (m > 0) {
			lcl[i] = row[ceil(alpha*m)]
			ucl[i] = row[ceil((1-alpha)*m)]
		}
	}
	st_store(., st_addvar("double", lclname), touselist, lcl)
	st_store(., st_addvar("double", uclname), touselist, ucl)
}
end
