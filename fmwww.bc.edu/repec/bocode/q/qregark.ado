*! 1.0.0  Ariel Linden 22Nov2026

program define qregark, eclass
	version 13

	if replay() {
		if "`e(cmd)'" != "qregark" {
			di as err "results for {bf:qregark} not found"
			exit 301
		}
		Display `0'
		exit
	}

	Estimate `0'
end

program define Display
	syntax [, Level(cilevel) *]
	_get_diopts diopts options, `options'
	if "`options'" != "" {
		local k : word count `options'
		di as err "{p}" plural(`k',"option") " {bf:`options'} " ///
		 plural(`k',"is","are") " not allowed{p_end}"
		exit 198
	}

	di
	di as txt "`e(title)'" ///
		_col(49) "Number of obs" _col(67) "=" ///
		_col(69) as res %10.0fc e(N)
	if (e(q) != 0.5) {
		di as txt "Quantile (tau): " as res "`=strtrim(string(e(q), "%9.0g"))'" _c
	}
	di as txt _col(49) "Wald chi2(" as res e(df_m) as txt ")" ///
		_col(67) "=" _col(70) as res %9.2f e(chi2)
	di as txt _col(49) "Prob > chi2" ///
		_col(67) "=" _col(70) as res %9.4f e(p)
	di
	di as txt "Log likelihood" _col(16) "=" as res %11.8g e(ll) ///
		as txt _col(49) "Sigma" _col(67) "=" _col(70) as res %9.0g e(sigma)
	di

	_coef_table, `diopts' level(`level')
	local qlab = strtrim(string(e(q), "%9.0g"))
	if e(biascorrect) != 1 & "`e(noconstant)'" == "" {
		di as txt "{p 0 6 2}Note: {bf:_cons} is the baseline level of the " ///
		 "`qlab' quantile; the structural intercept is in "               ///
		 "{bf:e(b0_struct)}.{p_end}"
	}
	if e(biascorrect) == 1 {
		if ("`e(noconstant)'" == "") local cnote "; {bf:_cons} is the baseline level of the `qlab' quantile, adjusted for small-sample bias (structural intercept in {bf:e(b0_struct)})"
		di as txt "{p 0 6 2}Note: AR coefficients bias-corrected by simulation-based " ///
		 "calibration`cnote'.{p_end}"
	}
	if "`e(vce)'" == "bootstrap" {
		di as txt "{p 0 6 2}Note: standard errors from " as res e(N_reps) ///
		 as txt " residual-bootstrap replications.{p_end}"
	}

	// autocorrelations of residuals (not shown with coeflegend)
	if !strpos("`diopts'", "coefl") & !missing(e(ac_res1)) {
		local col0 = 20
		local colw = 10
		di
		di as txt "Autocorrelations of residuals:"
		di
		di as txt _col(`col0') _continue
		forvalues j = 1/`e(p_lag)' {
			local colpos = `col0' + (`j'-1)*`colw'
			di as txt _col(`colpos') %9s "lag `j'" _continue
		}
		di
		di as txt "  Untransformed:" _continue
		forvalues j = 1/`e(p_lag)' {
			local colpos = `col0' + (`j'-1)*`colw'
			di as txt _col(`colpos') as res %9.4f e(ac_res`j') _continue
		}
		di
		di as txt "  Transformed:  " _continue
		forvalues j = 1/`e(p_lag)' {
			local colpos = `col0' + (`j'-1)*`colw'
			di as txt _col(`colpos') as res %9.4f e(ac_inn`j') _continue
		}
		di
	}
end

program define Estimate, eclass
	version 13, missing
	local cmdline : copy local 0

	// put the data in panel/time order before -syntax- evaluates any
	// time-series operators in the varlist
	_ts timevar panvar, sort panel
	if "`timevar'" == "" {
		di as err "qregark requires the data to be {bf:tsset}"
		exit 459
	}

	syntax varlist(numeric fv ts) [if] [in]		///
		, LAG(integer)							///
		[ Quantile(real 0.5)					///
		  noCONstant							///
		  START(string)							///
		  from(string)							///
		  VCE(string)							///
		  BWidth(string)						///
		  ITERate(integer 10000)				///
		  TOLerance(real 1e-8)					///
		  NOLOg									///
		  BIAScorrect							///
		  CORC									///
		  Level(cilevel)						///
		  * ]

	_get_diopts diopts options, `options'
	if "`options'" != "" {
		local k : word count `options'
		local options : list retokenize options
		di as err "{p}" plural(`k',"option") " {bf:`options'} " ///
		 plural(`k',"is","are") " not allowed{p_end}"
		exit 198
	}

	// checks
	if `lag' < 1 {
		di as err "{bf:lag()} must be >= 1"
		exit 198
	}
	local quant = `quantile'
	if (`quant' >= 1) local quant = `quant'/100
	if `quant' <= 0 | `quant' >= 1 {
		di as err "{bf:quantile(`quantile')} is out of range"
		exit 198
	}
	if `tolerance' <= 0 {
		di as err "{bf:tolerance()} must be positive"
		exit 198
	}
	if `iterate' < 1 {
		di as err "{bf:iterate()} must be a positive integer"
		exit 198
	}

	// starting values: ols (default) or median
	local start = lower(strtrim("`start'"))
	if inlist("`start'", "", "ls", "lse", "ol") local start ols
	if inlist("`start'", "med", "medi", "media", "mr") local start median
	if !inlist("`start'", "ols", "median") {
		di as err "{bf:start()} must be {bf:ols} or {bf:median}"
		exit 198
	}
	if `"`from'"' != "" {
		capture confirm matrix `from'
		if _rc {
			di as err "{bf:from()} must name a matrix"
			exit 198
		}
	}

	// vce: iid (default) or bootstrap[, reps(#) seed(#)]
	_parse comma vtype vopts : vce
	local vtype = lower(strtrim("`vtype'"))
	if inlist("`vtype'", "", "oim") local vtype iid
	if inlist("`vtype'", "boot", "boots", "bootst", "bootstr", "bootstra") local vtype bootstrap
	if !inlist("`vtype'", "iid", "bootstrap") {
		di as err "{bf:vce()} must be {bf:iid} or {bf:bootstrap}"
		exit 198
	}
	local reps 500
	local seed
	if "`vtype'" == "bootstrap" {
		// parse in a subprogram so that -syntax- does not reset varlist, [if][in]
		ParseBoot `vopts'
		if `reps' < 2 {
			di as err "{bf:reps()} must be an integer greater than 1"
			exit 198
		}
		if ("`seed'" != "") set seed `seed'
	}
	else if `"`vopts'"' != "" {
		di as err "{bf:vce(iid)} does not allow suboptions"
		exit 198
	}

	if "`biascorrect'" != "" & "`vtype'" == "bootstrap" {
		di as err "{bf:biascorrect} may not be combined with {bf:vce(bootstrap)}"
		exit 198
	}

	// density bandwidth for the sparsity
	local bwidth = lower(strtrim("`bwidth'"))
	if inlist("`bwidth'", "", "hs", "hsh", "hshe", "hshea", "hsheat", "hsheath", "hsheathe") local bwidth hsheather
	if inlist("`bwidth'", "bo", "bof", "bofi", "bofin", "bofing", "bofinge") local bwidth bofinger
	if inlist("`bwidth'", "ch", "cha", "cham", "chamb", "chambe", "chamber", "chamberl", "chamberla", "chamberlai") local bwidth chamberlain
	if !inlist("`bwidth'", "hsheather", "bofinger", "chamberlain") {
		di as err "{bf:bwidth()} must be {bf:hsheather}, {bf:bofinger}, or {bf:chamberlain}"
		exit 198
	}

	// time-series structure
	qui tsset
	local tdelta = r(tdelta)

	marksample touse
	markout `touse' `timevar' `panvar', strok

	qui count if `touse'
	if r(N) <= `lag' + 1 {
		di as err "insufficient observations"
		exit 2001
	}

	gettoken dep0 indep0 : varlist
	if "`indep0'" == "" & "`constant'" != "" {
		di as err "no regressors and {bf:noconstant} specified: empty model"
		exit 198
	}

	// convert time-series-operated terms to temporary variables
	local dep `dep0'
	if strpos("`dep0'", ".") {
		tsrevar `dep0'
		local dep `r(varlist)'
	}
	local tmap_t
	local tmap_o
	local indep
	if "`indep0'" != "" {
		fvexpand `indep0' if `touse'
		local indep0x `r(varlist)'
		foreach v of local indep0x {
			// split each expanded term at "#"; in every component
			local term
			local rest "`v'"
			while "`rest'" != "" {
				local p = strpos("`rest'", "#")
				if `p' {
					local comp = substr("`rest'", 1, `p'-1)
					local rest = substr("`rest'", `p'+1, .)
					local sep "#"
				}
				else {
					local comp "`rest'"
					local rest
					local sep
				}
				local ists 0
				local dp = strrpos("`comp'", ".")
				if `dp' > 1 {
					local head = substr("`comp'", 1, `dp'-1)
					local vname = substr("`comp'", `dp'+1, .)
					local pre
					local rem "`head'"
					if inrange(substr("`head'", 1, 1), "0", "9") {
						local ii = 1
						while inrange(substr("`head'", `ii', 1), "0", "9") {
							local ++ii
						}
						while inlist(substr("`head'", `ii', 1), "b", "o", "n") {
							local ++ii
						}
						local pre = substr("`head'", 1, `ii'-1)
						local rem = substr("`head'", `ii', .)
					}
					else if substr("`head'", 1, 1) == "c" {
						local pre c
						local rem = substr("`head'", 2, .)
						if substr("`rem'", 1, 1) == "o" {
							local pre co
							local rem = substr("`rem'", 2, .)
						}
					}
					if (substr("`rem'", 1, 1) == ".") local rem = substr("`rem'", 2, .)
					local ists = regexm("`rem'", "^[LFDSlfds][LFDSlfds0-9]*$")
				}
				if `ists' {
					local rem = upper("`rem'")
					local ops
					local ii = 1
					while `ii' <= length("`rem'") {
						local ch = substr("`rem'", `ii', 1)
						local ++ii
						local num
						while inrange(substr("`rem'", `ii', 1), "0", "9") {
							local num `num'`=substr("`rem'", `ii', 1)'
							local ++ii
						}
						if ("`num'" == "1") local num
						local ops `ops'`ch'`num'
					}
					local tsv `ops'.`vname'
					local pos : list posof "`tsv'" in tmap_o
					if `pos' {
						local tv : word `pos' of `tmap_t'
					}
					else {
						tsrevar `tsv'
						local tv `r(varlist)'
						local tmap_t `tmap_t' `tv'
						local tmap_o `tmap_o' `tsv'
					}
					if ("`pre'" != "") local comp `pre'.`tv'
					else               local comp `tv'
				}
				local term `term'`comp'`sep'
			}
			local indep `indep' `term'
		}
		_rmcoll `indep' if `touse', `constant' expand
		local indep `r(varlist)'
	}

	// coefficient names and design columns (non-omitted only)
	local names `indep'
	if ("`constant'" == "") local names `names' _cons
	local k : word count `names'
	local kx : word count `indep'
	local keep
	local xmat
	forvalues j = 1/`k' {
		local nm : word `j' of `names'
		local isom = regexm("`nm'", "[0-9]+(b|o|bo|ob)\.") | ///
			regexm("`nm'", "(^|#)o\.")
		if !`isom' {
			local keep `keep' `j'
			if "`nm'" != "_cons" {
				// column j, built exactly as Stata builds xb
				tempname ej
				tempvar xc
				mat `ej' = J(1, `kx', 0)
				mat `ej'[1, `j'] = 1
				mat colnames `ej' = `indep'
				qui matrix score double `xc' = `ej' if `touse'
				local xmat `xmat' `xc'
			}
		}
	}
	local kk : word count `keep'

	// starting values
	tempname b0
	if `"`from'"' != "" {
		if colsof(`from') != `k' + `lag' {
			di as err "{bf:from()} must have " `k' + `lag' " columns"
			exit 503
		}
		mat `b0' = J(1, `kk' + `lag', 0)
		local c = 0
		foreach j of local keep {
			local ++c
			mat `b0'[1, `c'] = `from'[1, `j']
		}
		forvalues j = 1/`lag' {
			mat `b0'[1, `kk' + `j'] = `from'[1, `k' + `j']
		}
		local start from
	}
	else if "`start'" == "median" {
		qui qreg `dep' `xmat' if `touse', quantile(.5) `constant'
		mat `b0' = e(b)
	}
	else mat `b0' = J(1, 1, .)

	// estimation
	sort `panvar' `timevar'
	tempname bh Vh brep phiu
	if "`biascorrect'" != "" {
		// the bias correction is simulation based: use a fixed internal
		// seed so that results are reproducible, and restore the user's
		// random-number state afterwards
		local rngst `c(rngstate)'
		local rngcmd rngstate
		if "`rngst'" == "" {
			local rngst `c(seed)'
			local rngcmd seed
		}
		set seed 20261121
	}
	capture noisily mata: qregark_main("`touse'", "`panvar'", "`timevar'", ///
		"`dep'", "`xmat'", ("`constant'" == ""), `lag', `quant',   ///
		`tdelta', "`b0'", "`start'", `tolerance', `iterate',       ///
		"`bwidth'", 1 - `level'/100, ("`vtype'" == "bootstrap"),   ///
		`reps', ("`nolog'" == ""), ("`biascorrect'" != ""),         ///
		"`bh'", "`Vh'", "`brep'", "`phiu'", ("`corc'" == ""))
	local mrc = _rc
	if ("`biascorrect'" != "") set `rngcmd' `rngst'
	if (`mrc') exit `mrc'

	local N       = r(N)
	local nseg    = r(nseg)
	local npan    = r(npan)
	local ngaps   = r(ngaps)
	local conv    = r(converged)
	local niter   = r(niter)
	local sigma   = r(sigma)
	local ll      = r(ll)
	local sumadev = r(sum_adev)
	local spars   = r(sparsity)
	local band    = r(bwidth)
	local stat    = r(stationary)
	local nfail   = r(nfail)
	tempname r_b0s
	scalar `r_b0s' = r(b0_struct)
	tempname r_b0u
	scalar `r_b0u' = r(b0_unadj)
	local capped  = r(capped)
	local atlim   = r(at_limit)
	local phibnd  = r(phi_bound)
	local sumrho  = r(sum_rho)
	local chi2    = r(chi2)
	local df_m    = r(df_m)

	if `ngaps' > 0 {
		di ""
		di as txt "Number of gaps in sample = " as res `ngaps' ///
			as txt "   (gap count includes panel changes)"
		di as txt "note: computations for rho restarted at each gap."
	}
	if !`conv' {
		di as txt "{p}Warning: EM algorithm did not converge within " ///
		 "iterate(`iterate'). Results may be unreliable; consider "   ///
		 "increasing iterate() or supplying from().{p_end}"
	}
	if !`stat' {
		di as txt "note: the estimated AR(`lag') process is not stationary"
	}
	if "`vtype'" == "bootstrap" & `nfail' > 0 {
		di as txt "note: `nfail' bootstrap replications did not converge"
	}

	// full-length b and V (zeros for omitted terms)
	local arnames
	forvalues j = 1/`lag' {
		local arnames `arnames' ar:rho`j'
	}
	local kf = `k' + `lag'
	tempname b V
	mat `b' = J(1, `kf', 0)
	mat `V' = J(`kf', `kf', 0)
	local pos
	foreach j of local keep {
		local pos `pos' `j'
	}
	forvalues j = 1/`lag' {
		local pos `pos' `=`k' + `j''
	}
	local np : word count `pos'
	forvalues r = 1/`np' {
		local pr : word `r' of `pos'
		mat `b'[1, `pr'] = `bh'[1, `r']
		forvalues c = 1/`np' {
			local pc : word `c' of `pos'
			mat `V'[`pr', `pc'] = `Vh'[`r', `c']
		}
	}

	// restore original names
	local nt : word count `tmap_t'
	forvalues j = 1/`nt' {
		local tv : word `j' of `tmap_t'
		local ov : word `j' of `tmap_o'
		local names : subinstr local names ".`tv'" "`ov'", all
		local names : subinstr local names "`tv'" "`ov'", all
	}
	local eqname `dep0'
	if (strpos("`dep0'", ".")) local eqname = strtoname("`dep0'")
	local colnames
	foreach v of local names {
		local colnames `colnames' `eqname':`v'
	}
	local colnames `colnames' `arnames'
	mat colnames `b' = `colnames'
	mat colnames `V' = `colnames'
	mat rownames `V' = `colnames'

	if "`vtype'" == "bootstrap" {
		// percentile confidence intervals on the full-length vector
		tempname cip
		mat `cip' = J(2, `kf', 0)
		forvalues r = 1/`np' {
			local pr : word `r' of `pos'
			mat `cip'[1, `pr'] = `brep'[1, `r']
			mat `cip'[2, `pr'] = `brep'[2, `r']
		}
		mat colnames `cip' = `colnames'
		mat rownames `cip' = ll ul
	}

	ereturn post `b' `V', depname(`dep0') obs(`N') esample(`touse')

	if ("`corc'" == "") local mlab "Prais-Winsten"
	else                local mlab "conditional ML"
	if (`quant' == 0.5) local title "Median AR(`lag') regression, `mlab'"
	else local title "Quantile AR(`lag') regression, `mlab'"

	ereturn local cmd        "qregark"
	ereturn local predict    "qregark_p"
	ereturn local cmdline    `"qregark `cmdline'"'
	ereturn local title      "`title'"
	ereturn local timevar    "`timevar'"
	ereturn local panelvar   "`panvar'"
	ereturn local noconstant "`constant'"
	ereturn local start      "`start'"
	if ("`corc'" == "") ereturn local method "pw"
	else                ereturn local method "corc"
	ereturn local bwmethod   "`bwidth'"
	ereturn local vce        "`vtype'"
	if ("`vtype'" == "bootstrap") ereturn local vcetype "Bootstrap"
	ereturn local properties "b V"

	ereturn scalar N          = `N'
	ereturn scalar q          = `quant'
	ereturn scalar p_lag      = `lag'
	ereturn scalar ll         = `ll'
	ereturn scalar sigma      = `sigma'
	ereturn scalar sum_adev   = `sumadev'
	ereturn scalar df_m       = `df_m'
	ereturn scalar chi2       = `chi2'
	ereturn scalar p          = chi2tail(`df_m', `chi2')
	ereturn scalar N_g        = `npan'
	ereturn scalar N_seg      = `nseg'
	ereturn scalar ngaps      = `ngaps'
	ereturn scalar iterations = `niter'
	ereturn scalar converged  = `conv'
	ereturn scalar tolerance  = `tolerance'
	ereturn scalar stationary = `stat'
	ereturn scalar at_limit   = `atlim'
	ereturn scalar biascorrect = ("`biascorrect'" != "")
	if ("`constant'" == "") ereturn scalar b0_struct = `r_b0s'
	if "`biascorrect'" != "" {
		if ("`constant'" == "") ereturn scalar b0_unadjusted = `r_b0u'
		ereturn scalar capped    = `capped'
		ereturn scalar phi_bound = `phibnd'
		ereturn scalar sum_rho   = `sumrho'
		local arn
		forvalues j = 1/`lag' {
			local arn `arn' rho`j'
		}
		mat colnames `phiu' = `arn'
		ereturn matrix rho_uncorrected = `phiu'
	}
	if "`vtype'" == "iid" {
		ereturn scalar sparsity = `spars'
		ereturn scalar bwidth   = `band'
	}
	else {
		ereturn scalar N_reps    = `reps'
		ereturn scalar N_misreps = `nfail'
		ereturn matrix ci_percentile = `cip'
	}

	// leave the data in panel/time order so that -predict- with time-series operators works after estimation
	sort `panvar' `timevar'
	ereturn repost, buildfvinfo

	// autocorrelations at lags 1..p of the residuals (y - xb) and of the innovations (y - one-step conditional quantile)
	tempvar smpl ures uinn
	qui gen byte `smpl' = e(sample)
	qui predict double `ures' if `smpl', residuals
	qui predict double `uinn' if `smpl', innovations
	forvalues j = 1/`lag' {
		capture qui correlate `ures' L`j'.`ures' if `smpl'
		if (_rc) ereturn scalar ac_res`j' = .
		else     ereturn scalar ac_res`j' = r(rho)
		capture qui correlate `uinn' L`j'.`uinn' if `smpl'
		if (_rc) ereturn scalar ac_inn`j' = .
		else     ereturn scalar ac_inn`j' = r(rho)
	}


	Display, `diopts' level(`level')
end

program define ParseBoot
	syntax [, Reps(integer 500) SEED(string)]
	c_local reps `reps'
	c_local seed `seed'
end

mata:

// segments: break at panel changes and time gaps
real matrix qregark_segs(real colvector pid, real colvector t, real scalar delta)
{
	real matrix    segs
	real scalar    n, i, s
	n = rows(t)
	segs = J(0, 2, .)
	s = 1
	for (i=2; i<=n; i++) {
		if (pid[i] != pid[i-1] | t[i] - t[i-1] != delta) {
			segs = (segs \ (s, i-1))
			s = i
		}
	}
	return((segs \ (s, n)))
}

// contributing rows: positions q+1, ..., end of each segment
real colvector qregark_contrib(real matrix segs, real scalar q)
{
	real colvector C
	real scalar    g
	C = J(0, 1, .)
	for (g=1; g<=rows(segs); g++) {
		if (segs[g,2] - segs[g,1] + 1 > q) C = (C \ ((segs[g,1]+q)::segs[g,2]))
	}
	return(C)
}

// AR filter: v_t - sum_j phi_j v_{t-j}, t in C
real matrix qregark_filt(real matrix v, real colvector phi, real colvector C)
{
	real matrix out
	real scalar j
	out = v[C, .]
	for (j=1; j<=rows(phi); j++) out = out - phi[j]*v[C :- j, .]
	return(out)
}

real matrix qregark_lags(real colvector e, real scalar q, real colvector C)
{
	real matrix E
	real scalar j
	E = J(rows(C), q, .)
	for (j=1; j<=q; j++) E[., j] = e[C :- j]
	return(E)
}

//************************************
// EM algorithm of Tian et al. (2018)
//************************************
void qregark_em(real colvector y, real matrix X, real colvector C,
	real scalar q, real scalar tau, real colvector b, real colvector p,
	real scalar tol, real scalar maxit, real scalar conv,
	real scalar niter, real scalar showlog)
{
	real scalar    t1, t2, c, m, sc, fl, it, ch, stconv, stage
	real colvector eps, eta, a, d, Yh, bn, pn, pold, pnew
	real matrix    Xh, XW, E, EW

	t1 = (1-2*tau)/(tau*(1-tau))
	t2 = 2/(tau*(1-tau))
	c  = sqrt(t1^2 + 2*t2)
	m  = rows(C)
	eps = y - X*b
	eta = qregark_filt(eps, p, C)
	sc  = mean(abs(eta))
	if (sc <= 0 | sc >= .) sc = 1
	fl = 1e-2
	niter = 0
	stage = 0
	while (1) {
		stage++
		stconv = 0
		for (it=1; it<=maxit; it++) {
			niter++
			a  = rowmax((abs(eta), J(m, 1, fl*sc)))
			d  = c :/ a
			Yh = qregark_filt(y, p, C)
			Xh = qregark_filt(X, p, C)
			XW = (Xh :* d)'
			bn = invsym(XW*Xh) * (XW*Yh - t1*colsum(Xh)')
			eps = y - X*bn
			E  = qregark_lags(eps, q, C)
			EW = (E :* d)'
			pn = invsym(EW*E) * (EW*eps[C] - t1*colsum(E)')
			eta = qregark_filt(eps, pn, C)
			pold = (b \ p)
			pnew = (bn \ pn)
			ch = max(abs(pnew - pold) :/ (abs(pold) :+ 1))
			b = bn
			p = pn
			if (ch < tol) {
				stconv = 1
				break
			}
		}
		if (showlog) {
			printf("{txt}EM stage %2.0f: floor = %8.0e   iterations = %6.0f   sum of deviations = {res}%12.0g\n",
				stage, fl, min((it, maxit)),
				sum(eta :* (tau :- (eta :< 0))))
			displayflush()
		}
		if (stage >= 9) {
			conv = stconv
			break
		}
		fl = 10^(-(stage+2))
	}
}

// percentile with the default definition of -_pctile- (x sorted)
real scalar qregark_pct(real colvector x, real scalar P)
{
	real scalar n, W, i
	n = rows(x)
	W = n*P/100
	i = floor(W)
	if (i <= 0) return(x[1])
	if (i >= n) return(x[n])
	if (W == i) return((x[i] + x[i+1])/2)
	return(x[i+1])
}

real scalar qregark_bw(real scalar n, real scalar tau, string scalar method,
	real scalar alpha)
{
	real scalar z, it
	it = invnormal(tau)
	if (method == "hsheather") {
		z = invnormal(1-alpha/2)
		return(n^(-1/3)*z^(2/3)*(1.5*normalden(it)^2/(2*it^2+1))^(1/3))
	}
	else if (method == "bofinger") {
		return(n^(-1/5)*((4.5*normalden(it)^4)/(2*it^2+1)^2)^(1/5))
	}
	z = invnormal(1-alpha/2)
	return(z*sqrt(n^(-1)*tau*(1-tau)))
}

// largest modulus of the AR companion-matrix eigenvalues
real scalar qregark_maxroot(real colvector p)
{
	real matrix A
	real scalar q
	q = rows(p)
	A = J(q, q, 0)
	A[1, .] = p'
	if (q > 1) A[|2,1 \ q,q-1|] = I(q-1)
	return(max(abs(eigenvalues(A))))
}

// shrink phi toward zero until the process is stationary (max root < .99)
real colvector qregark_stationary(real colvector p, | real scalar capsum)
{
	real colvector r
	real scalar    s, lo, hi, i
	// scale phi down to the largest multiple with max root below .99
	s = 1
	if (qregark_maxroot(p) >= .99) {
		lo = 0
		hi = 1
		for (i=1; i<=40; i++) {
			s = (lo + hi)/2
			if (qregark_maxroot(p*s) < .99) lo = s
			else hi = s
		}
		s = lo
	}
	r = p*s
	if (args() == 2) {
		if (capsum < . & sum(r) > capsum) r = r*(capsum/sum(r))
	}
	return(r)
}

// adaptive upper bound for sum(phi)
real scalar qregark_adaptcap(real colvector phat, real matrix X,
	real colvector C, real matrix segs, real matrix U, real scalar burn,
	real scalar pw, real matrix F)
{
	real rowvector grid
	real colvector d
	real matrix    P
	real scalar    q, i, m, mold
	q = rows(phat)
	if (sum(phat) <= 0) return(.)
	d = phat/sum(phat)
	mold = .
	grid = (.5, .6, .7, .8, .85, .9, .95, .99)
	P = J(0, 0, .)
	for (i=1; i<=cols(grid); i++) {
		P = qregark_cls(qregark_simar(U, qregark_stationary(d*grid[i]),
			segs, burn), X, C, q, (i == 1 ? 20 : 5), P, pw, F)
		m = sum(mean(P))
		if (i > 1) {
			if ((m - mold)/(grid[i] - grid[i-1]) < .5) return(grid[i-1])
		}
		mold = m
	}
	return(grid[cols(grid)])
}

// AR(q) errors from innovations U (one column per series)
real matrix qregark_simar(real matrix U, real colvector p, real matrix segs,
	real scalar burn)
{
	real matrix    E, W
	real scalar    g, len, tot, pos, t, j, q, S, n
	q = rows(p)
	S = cols(U)
	n = segs[rows(segs), 2]
	E = J(n, S, 0)
	pos = 0
	for (g=1; g<=rows(segs); g++) {
		len = segs[g,2] - segs[g,1] + 1
		tot = len + burn
		W = J(tot, S, 0)
		for (t=1; t<=tot; t++) {
			W[t, .] = U[pos+t, .]
			for (j=1; j<=q; j++) {
				if (t - j >= 1) W[t, .] = W[t, .] + p[j]*W[t-j, .]
			}
		}
		E[|segs[g,1],1 \ segs[g,2],S|] = W[|burn+1,1 \ tot,S|]
		pos = pos + tot
	}
	return(E)
}

// Gaussian least squares for AR(q) regression errors
real matrix qregark_cls(real matrix Y, real matrix X, real colvector C,
	real scalar q, real scalar iters, real matrix P0, real scalar pw,
	real matrix F)
{
	pointer(real matrix) matrix MM, XY
	real matrix    P, B, A, Er, L, R, Li
	real colvector bv, r
	real rowvector a, xf
	real scalar    k, S, i, j, it, s, ii, f, rr, jj, yf
	k = cols(X)
	S = cols(Y)
	MM = J(q+1, q+1, NULL)
	XY = J(q+1, q+1, NULL)
	for (i=0; i<=q; i++) {
		for (j=0; j<=q; j++) {
			MM[i+1, j+1] = &(cross(X[C :- i, .], X[C :- j, .]))
			XY[i+1, j+1] = &(cross(X[C :- i, .], Y[C :- j, .]))
		}
	}
	P = (rows(P0) == S ? P0 : J(S, q, 0))
	for (it=1; it<=iters; it++) {
		B = J(k, S, .)
		for (s=1; s<=S; s++) {
			a = (1, -P[s, .])
			A = J(k, k, 0)
			bv = J(k, 1, 0)
			for (i=1; i<=q+1; i++) {
				for (j=1; j<=q+1; j++) {
					A  = A  + a[i]*a[j]*(*MM[i, j])
					bv = bv + a[i]*a[j]*(*XY[i, j])[., s]
				}
			}
			if (pw) {
				Li = qregark_linv(qregark_stationary(P[s, .]'))
				for (f=1; f<=rows(F); f++) {
					rr = F[f, 1]
					jj = F[f, 2]
					xf = Li[|jj,1 \ jj,jj|]*X[|rr-jj+1,1 \ rr,k|]
					yf = Li[|jj,1 \ jj,jj|]*Y[|rr-jj+1,s \ rr,s|]
					A  = A  + xf'*xf
					bv = bv + xf'*yf
				}
			}
			B[., s] = lusolve(A, bv)
		}
		Er = Y - X*B
		L = J((q+1)*(q+1), S, .)
		ii = 0
		for (i=0; i<=q; i++) {
			for (j=0; j<=q; j++) {
				ii++
				L[ii, .] = colsum(Er[C :- i, .] :* Er[C :- j, .])
			}
		}
		for (s=1; s<=S; s++) {
			R = J(q, q, .)
			r = J(q, 1, .)
			for (i=1; i<=q; i++) {
				r[i] = L[i+1, s]
				for (j=1; j<=q; j++) R[i, j] = L[i*(q+1) + j + 1, s]
			}
			P[s, .] = lusolve(R, r)'
		}
	}
	return(P)
}

// indirect-inference bias correction
real colvector qregark_ii(real colvector phat, real matrix X, real colvector C,
	real matrix segs, real matrix U, real scalar burn, real scalar iters,
	real matrix Jac, real scalar capsum, real scalar capped, real scalar pw,
	real matrix F)
{
	real colvector p, mb, pj, tg
	real matrix    P, Pj
	real scalar    it, j, q, h
	q = rows(phat)
	p = qregark_stationary(phat, capsum)
	tg = p
	// first pass from zero; later passes warm-started from the previous simulated estimates
	P = J(0, 0, .)
	for (it=1; it<=iters; it++) {
		P = qregark_cls(qregark_simar(U, p, segs, burn), X, C, q,
			(it == 1 ? 20 : 5), P, pw, F)
		tg = p + (phat - mean(P)')
		p = qregark_stationary(tg, capsum)
	}
	capped = (max(abs(p - tg)) > 1e-12)
	h = .02
	P = qregark_cls(qregark_simar(U, p, segs, burn), X, C, q, 5, P, pw, F)
	mb = mean(P)'
	Jac = J(q, q, .)
	for (j=1; j<=q; j++) {
		pj = p
		pj[j] = pj[j] + h
		Pj = qregark_cls(qregark_simar(U, pj, segs, burn), X, C, q, 5, P, pw, F)
		Jac[., j] = (mean(Pj)' - mb)/h
	}
	return(p)
}

// delta-method variance after the correction
real matrix qregark_adjV(real matrix V, real matrix G, real matrix Jac,
	real scalar k)
{
	real matrix    H, B, Ji, A, U, Vt
	real colvector sv
	real scalar    q
	q = cols(Jac)
	H = cross(G, G)
	B = -lusolve(H[|1,1 \ k,k|], H[|1,k+1 \ k,k+q|])
	// inverse of the derivative of the simulated mean of the AR estimates with respect to the true coefficients
	U  = .
	sv = .
	Vt = .
	svd(Jac, U, sv, Vt)
	sv = rowmax((sv, J(rows(sv), 1, .5)))
	Ji = Vt'*diag(1:/sv)*U'
	A = I(k+q)
	A[|1,k+1 \ k,k+q|] = B*(Ji - I(q))
	A[|k+1,k+1 \ k+q,k+q|] = Ji
	return(A*V*A')
}

// EM for the regression coefficients with the AR coefficients held fixed
void qregark_emfixed(real colvector y, real matrix X, real colvector C,
	real scalar q, real scalar tau, real colvector b, real colvector p,
	real scalar tol, real scalar maxit)
{
	real scalar    t1, t2, c, m, sc, fl, it, ch, stage
	real colvector eps, eta, a, d, Yh, bn
	real matrix    Xh, XW
	t1 = (1-2*tau)/(tau*(1-tau))
	t2 = 2/(tau*(1-tau))
	c  = sqrt(t1^2 + 2*t2)
	m  = rows(C)
	Yh = qregark_filt(y, p, C)
	Xh = qregark_filt(X, p, C)
	eta = Yh - Xh*b
	sc  = mean(abs(eta))
	if (sc <= 0 | sc >= .) sc = 1
	fl = 1e-2
	stage = 0
	while (1) {
		stage++
		for (it=1; it<=maxit; it++) {
			a  = rowmax((abs(eta), J(m, 1, fl*sc)))
			d  = c :/ a
			XW = (Xh :* d)'
			bn = invsym(XW*Xh) * (XW*Yh - t1*colsum(Xh)')
			eta = Yh - Xh*bn
			ch = max(abs(bn - b) :/ (abs(b) :+ 1))
			b = bn
			if (ch < tol) break
		}
		if (stage >= 9) break
		fl = 10^(-(stage+2))
	}
}

//******************************
// Prais-Winsten-type estimator
//******************************
// inverse Cholesky factor of Var(eps_1, ..., eps_q)/sigma_eta^2
real matrix qregark_linv(real colvector p)
{
	real matrix    A, K, S, L
	real colvector e
	real scalar    q
	q = rows(p)
	A = J(q, q, 0)
	A[1, .] = p'
	if (q > 1) A[|2,1 \ q,q-1|] = I(q-1)
	K = I(q*q) - (A # A)
	e = J(q*q, 1, 0)
	e[1] = 1
	S = colshape(lusolve(K, e)', q)
	S = (S + S')/2
	L = cholesky(S)
	if (hasmissing(L)) return(J(q, q, .))
	return(solvelower(L, I(q)))
}

// first-block rows
real matrix qregark_first(real matrix segs, real scalar q)
{
	real matrix    F
	real scalar    g, j, len
	F = J(0, 2, .)
	for (g=1; g<=rows(segs); g++) {
		len = segs[g,2] - segs[g,1] + 1
		for (j=1; j<=min((q, len)); j++) F = (F \ (segs[g,1]+j-1, j))
	}
	return(F)
}

// transformed system
real matrix qregark_tr(real matrix v, real colvector p, real colvector C,
	real matrix F, real scalar pw, real matrix Li)
{
	real matrix    out, Vf
	real scalar    f, r, j, c
	out = qregark_filt(v, p, C)
	if (!pw) return(out)
	c  = cols(v)
	Vf = J(rows(F), c, .)
	for (f=1; f<=rows(F); f++) {
		r = F[f, 1]
		j = F[f, 2]
		Vf[f, .] = Li[|j,1 \ j,j|]*v[|r-j+1,1 \ r,c|]
	}
	return((Vf \ out))
}

// staged IRLS (the EM of Tian et al. with phi fixed) for the check-loss
real scalar qregark_irls(real colvector Yh, real matrix Xh, real scalar tau,
	real colvector b, real scalar tol, real scalar maxit)
{
	real scalar    t1, t2, c, m, sc, fl, it, ch, stage
	real colvector eta, a, d, bn
	real matrix    XW
	t1 = (1-2*tau)/(tau*(1-tau))
	t2 = 2/(tau*(1-tau))
	c  = sqrt(t1^2 + 2*t2)
	m  = rows(Yh)
	eta = Yh - Xh*b
	sc  = mean(abs(eta))
	if (sc <= 0 | sc >= .) sc = 1
	fl = 1e-2
	stage = 0
	while (1) {
		stage++
		for (it=1; it<=maxit; it++) {
			a  = rowmax((abs(eta), J(m, 1, fl*sc)))
			d  = c :/ a
			XW = (Xh :* d)'
			bn = invsym(XW*Xh) * (XW*Yh - t1*colsum(Xh)')
			eta = Yh - Xh*bn
			ch = max(abs(bn - b) :/ (abs(b) :+ 1))
			b = bn
			if (ch < tol) break
		}
		if (stage >= 9) break
		fl = 10^(-(stage+2))
	}
	return(sum(eta :* (tau :- (eta :< 0))))
}

// Prais-Winsten profile objective at phi: check loss of the transformed system
real scalar qregark_pwobj(real colvector p, real colvector y, real matrix X,
	real colvector C, real matrix F, real scalar tau, real colvector d,
	real colvector b, real scalar tol, real scalar maxit)
{
	real matrix    Li, Xt
	real colvector Yt, bw
	real scalar    v
	if (qregark_maxroot(p) >= .995) return(1e300)
	Li = qregark_linv(p)
	if (hasmissing(Li)) return(1e300)
	Yt = qregark_tr(y, p, C, F, 1, Li)
	Yt[|1 \ rows(F)|] = Yt[|1 \ rows(F)|] - d[F[., 2], 1]
	Xt = qregark_tr(X, p, C, F, 1, Li)
	bw = b
	v = qregark_irls(Yt, Xt, tau, bw, tol, min((maxit, 1000)))
	if (v < .) b = bw
	else v = 1e300
	return(v)
}

// Nelder-Mead minimisation of the profile objective over phi
real colvector qregark_nm(real colvector p0, real scalar step,
	real colvector y, real matrix X, real colvector C, real matrix F,
	real scalar tau, real colvector d, real colvector b, real scalar tol,
	real scalar maxit, real scalar fbest, real scalar conv, real scalar nev)
{
	real matrix    Xs
	real colvector f, o, xc, xr, xe, xo, v
	real scalar    q, i, fr, fe, fo, maxev, ev
	q = rows(p0)
	Xs = J(q, q+1, .)
	f  = J(q+1, 1, .)
	Xs[., 1] = p0
	f[1] = qregark_pwobj(p0, y, X, C, F, tau, d, b, tol, maxit)
	for (i=1; i<=q; i++) {
		v = p0
		v[i] = v[i] + step
		if (qregark_maxroot(v) >= .995) v[i] = p0[i] - step
		Xs[., i+1] = v
		f[i+1] = qregark_pwobj(v, y, X, C, F, tau, d, b, tol, maxit)
	}
	ev = q + 1
	maxev = 300*q
	conv = 0
	while (ev < maxev) {
		o  = order(f, 1)
		Xs = Xs[., o']
		f  = f[o]
		if (f[q+1] - f[1] <= 1e-9*(abs(f[1]) + 1e-10) &
		    max(abs(Xs[|1,2 \ q,q+1|] :- Xs[., 1])) < 1e-6) {
			conv = 1
			break
		}
		xc = rowsum(Xs[|1,1 \ q,q|])/q
		xr = xc + (xc - Xs[., q+1])
		fr = qregark_pwobj(xr, y, X, C, F, tau, d, b, tol, maxit)
		ev++
		if (fr < f[1]) {
			xe = xc + 2*(xc - Xs[., q+1])
			fe = qregark_pwobj(xe, y, X, C, F, tau, d, b, tol, maxit)
			ev++
			if (fe < fr) {
				Xs[., q+1] = xe
				f[q+1] = fe
			}
			else {
				Xs[., q+1] = xr
				f[q+1] = fr
			}
		}
		else if (fr < f[q]) {
			Xs[., q+1] = xr
			f[q+1] = fr
		}
		else {
			if (fr < f[q+1]) xo = xc + .5*(xr - xc)
			else             xo = xc + .5*(Xs[., q+1] - xc)
			fo = qregark_pwobj(xo, y, X, C, F, tau, d, b, tol, maxit)
			ev++
			if (fo < min((fr, f[q+1]))) {
				Xs[., q+1] = xo
				f[q+1] = fo
			}
			else {
				for (i=2; i<=q+1; i++) {
					Xs[., i] = Xs[., 1] + .5*(Xs[., i] - Xs[., 1])
					f[i] = qregark_pwobj(Xs[., i], y, X, C, F, tau, d, b, tol, maxit)
					ev++
				}
			}
		}
	}
	o  = order(f, 1)
	nev = nev + ev
	fbest = f[o[1]]
	return(Xs[., o[1]])
}

// Prais-Winsten fit
void qregark_pwfit(real colvector y, real matrix X, real colvector C,
	real matrix F, real scalar q, real scalar tau, real colvector p,
	real colvector b, real colvector d, real scalar tol, real scalar maxit,
	real scalar conv, real scalar nev)
{
	real matrix    S0
	real colvector pb, bb, pt, bt, ps
	real scalar    fb, ft, i, r, cv
	ps = qregark_stationary(p)
	S0 = ps
	if (q == 1) {
		pb = ps
		bb = b
		fb = qregark_pwobj(pb, y, X, C, F, tau, d, bb, tol, maxit)
		for (r=-.9; r<=.951; r=r+.1) {
			bt = b
			ft = qregark_pwobj(r, y, X, C, F, tau, d, bt, tol, maxit)
			nev++
			if (ft < fb) {
				fb = ft
				pb = r
			}
		}
		if (pb != ps) S0 = (S0, pb)
	}
	else S0 = (S0, J(q, 1, 0), (.5 \ J(q-1, 1, 0)))
	fb = 1e300
	for (i=1; i<=cols(S0); i++) {
		bt = b
		pt = qregark_nm(S0[., i], .1, y, X, C, F, tau, d, bt, tol, maxit,
			ft, cv, nev)
		if (ft < fb) {
			fb = ft
			pb = pt
			bb = bt
		}
	}
	// restart from the best point with a smaller simplex
	pt = qregark_nm(pb, .05, y, X, C, F, tau, d, bb, tol, maxit, ft, cv, nev)
	if (ft <= fb) pb = pt
	conv = cv
	p = pb
	ft = qregark_pwobj(p, y, X, C, F, tau, d, bb, tol, maxit)
	b = bb
}

// offsets of the first-block rows
real colvector qregark_pwoff(real colvector eta, real colvector p,
	real scalar tau)
{
	real matrix    U, E, Z, Li
	real colvector d
	string scalar  st
	real scalar    q, m, L, Ns, i
	q  = rows(p)
	m  = rows(eta)
	Li = qregark_linv(p)
	if (hasmissing(Li)) return(J(q, 1, 0))
	Ns = 2000
	L  = 100 + q
	st = rseed()
	rseed(20261122)
	U  = colshape(eta[ceil(m*runiform(L*Ns, 1))], Ns)
	rseed(st)
	E  = qregark_simar(U, p, (1, L), 0)
	Z  = Li*E[|L-q+1,1 \ L,Ns|]
	d  = J(q, 1, .)
	for (i=1; i<=q; i++) d[i] = qregark_pct(sort(Z[i, .]', 1), 100*tau)
	return(d)
}

// complete Prais-Winsten fit from the conditional estimates
void qregark_pwfull(real colvector y, real matrix X, real colvector C,
	real matrix F, real scalar q, real scalar tau, real colvector p,
	real colvector b, real colvector d, real scalar tol, real scalar maxit,
	real scalar conv, real scalar nev)
{
	real colvector eta
	real scalar    pass, fb
	d = J(q, 1, 0)
	nev = 0
	for (pass=1; pass<=3; pass++) {
		if (pass == 1) {
			qregark_pwfit(y, X, C, F, q, tau, p, b, d, tol, maxit, conv, nev)
		}
		else {
			// re-estimate the offsets, then refine locally from the current estimates
			eta = qregark_filt(y - X*b, p, C)
			d = qregark_pwoff(eta, p, tau)
			p = qregark_nm(p, .05, y, X, C, F, tau, d, b, tol, maxit, fb, conv, nev)
			fb = qregark_pwobj(p, y, X, C, F, tau, d, b, tol, maxit)
		}
	}
}

// beta given phi for the Prais-Winsten system (offsets re-estimated)
void qregark_pwfixed(real colvector y, real matrix X, real colvector C,
	real matrix F, real scalar tau, real colvector p, real colvector b,
	real colvector d, real scalar tol, real scalar maxit)
{
	real colvector eta
	real scalar    pass, v
	for (pass=1; pass<=2; pass++) {
		eta = qregark_filt(y - X*b, p, C)
		d = qregark_pwoff(eta, p, tau)
		v = qregark_pwobj(p, y, X, C, F, tau, d, b, tol, maxit)
	}
}

// baseline level of the tau-th quantile, reported as _cons in place of the structural intercept
void qregark_base(real colvector y, real matrix X, real colvector b,
	real colvector p, real colvector eta, real matrix segs, real scalar tau,
	real scalar adj, real colvector C, real matrix F, real scalar pw,
	real matrix Li, real scalar b0m, real scalar b0u, real scalar vq)
{
	real matrix    Usim, Es, Xt, Et, Bs, W
	real colvector w, qv, qw
	real scalar    n, k, kx, m, Ns, Ntot, c, qbias
	string scalar  st
	n  = rows(y)
	k  = cols(X)
	kx = k - 1
	m  = rows(eta)
	w  = (kx > 0 ? y - X[|1,1 \ n,kx|]*b[|1 \ kx|] : y)
	b0u = qregark_pct(sort(w, 1), 100*tau)
	Ns = 1000
	Ntot = sum(segs[., 2] - segs[., 1] :+ 1) + 100*rows(segs)
	st = rseed()
	rseed(20261123)
	Usim = J(Ntot, Ns, .)
	for (c=1; c<=Ns; c++) Usim[., c] = eta[ceil(m*runiform(Ntot, 1))]
	rseed(st)
	Es = qregark_simar(Usim, p, segs, 100)
	qv = J(Ns, 1, .)
	for (c=1; c<=Ns; c++) qv[c] = qregark_pct(sort(Es[., c], 1), 100*tau)
	vq = variance(qv)
	b0m = b0u
	if (adj) {
		Xt = qregark_tr(X, p, C, F, pw, Li)
		Et = qregark_tr(Es, p, C, F, pw, Li)
		Bs = invsym(cross(Xt, Xt))*cross(Xt, Et)
		W  = (kx > 0 ? Es - X[|1,1 \ n,kx|]*Bs[|1,1 \ kx,Ns|] : Es)
		qw = J(Ns, 1, .)
		for (c=1; c<=Ns; c++) qw[c] = qregark_pct(sort(W[., c], 1), 100*tau)
		qbias = mean(qw) - qregark_pct(sort(vec(Es), 1), 100*tau)
		b0m = b0u - qbias
	}
}

// variance matrix with the intercept replaced by the baseline level
real matrix qregark_baseV(real matrix V, real matrix X, real scalar k,
	real scalar q, real scalar vq)
{
	real matrix    Vn
	real rowvector xbar
	real scalar    kx, j
	kx = k - 1
	Vn = V
	if (kx > 0) {
		xbar = mean(X[|1,1 \ rows(X),kx|])
		for (j=1; j<=k+q; j++) {
			if (j != k) Vn[k, j] = -xbar*V[|1,j \ kx,j|]
		}
		Vn[., k] = Vn[k, .]'
		Vn[k, k] = vq + xbar*V[|1,1 \ kx,kx|]*xbar'
	}
	else {
		Vn[k, .] = J(1, k+q, 0)
		Vn[., k] = J(k+q, 1, 0)
		Vn[k, k] = vq
	}
	return(Vn)
}

void qregark_main(string scalar tousev, string scalar panv, string scalar timev,
	string scalar depv, string scalar xvars, real scalar cons, real scalar q,
	real scalar tau, real scalar delta, string scalar b0name,
	string scalar start, real scalar tol, real scalar maxit,
	string scalar bwmeth, real scalar alpha, real scalar boot,
	real scalar reps, real scalar showlog, real scalar bc,
	string scalar bname, string scalar Vname, string scalar cname,
	string scalar phiuname, real scalar pw)
{
	real colvector y, pid, t, C, b, p, eps, eta, nb, ystar, epsstar, etastar,
	               idx, bs, ps, v, ev
	real matrix    X, segs, E, G, V, B, Xh, cip, comp, S
	real scalar    n, k, m, conv, niter, sc, h, s, sigma, ll, ngaps, npan,
	               r, i, j, cs, nis, nib, nfail, kx, stat, chi2, alevel,
	               b0s, b0m, vq, Ntot, capsum, capped, atlim
	real rowvector b0
	real colvector pu, w
	real matrix    Jac, U, F, Li, Xt
	real colvector d, rr, rF, rh, pj
	real scalar    mt, nev, cpw, nF, b0u, hh, fbt

	y = st_data(., depv, tousev)
	n = rows(y)
	X = (xvars != "" ? st_data(., tokens(xvars), tousev) : J(n, 0, .))
	if (cons) X = (X, J(n, 1, 1))
	k = cols(X)
	t = st_data(., timev, tousev)
	pid = (panv != "" ? st_data(., panv, tousev) : J(n, 1, 1))

	segs = qregark_segs(pid, t, delta)
	C = qregark_contrib(segs, q)
	m = rows(C)
	F = (pw ? qregark_first(segs, q) : J(0, 2, .))
	Li = J(0, 0, .)
	nF = rows(F)
	mt = m + nF
	if (m <= k + q) {
		errprintf("insufficient observations\n")
		exit(2001)
	}
	npan  = rows(uniqrows(pid))
	ngaps = rows(segs) - 1

	// starting values
	b0 = st_matrix(b0name)
	if (start == "from") {
		b = b0[1, 1..k]'
		p = b0[1, (k+1)..(k+q)]'
	}
	else {
		if (start == "median") b = b0'
		else                   b = invsym(cross(X, X)) * cross(X, y)
		eps = y - X*b
		E = qregark_lags(eps, q, C)
		p = invsym(cross(E, E)) * cross(E, eps[C])
	}

	conv  = 0
	niter = 0
	nis   = 0
	nib   = 0
	qregark_em(y, X, C, q, tau, b, p, tol, maxit, conv, niter, showlog)
	d = J(q, 1, 0)
	if (pw) {
		// Prais-Winsten: profile minimisation over phi, started from the conditional (Tian et al.) estimates
		cpw = 0
		nev = 0
		qregark_pwfull(y, X, C, F, q, tau, p, b, d, tol, maxit, cpw, nev)
		conv = conv & cpw
		if (showlog) {
			Li = qregark_linv(p)
			rh = qregark_tr(y - X*b, p, C, F, 1, Li)
			rh[|1 \ nF|] = rh[|1 \ nF|] - d[F[., 2], 1]
			printf("{txt}Prais-Winsten: function evaluations = %6.0f   sum of deviations = {res}%12.0g\n",
				nev, sum(rh :* (tau :- (rh :< 0))))
			displayflush()
		}
	}

	// AR coefficients at the limit of the estimator's parameter space (largest root .995)
	atlim = (qregark_maxroot(p) >= .9949)
	st_numscalar("r(at_limit)", atlim)

	if (bc) {
		// indirect-inference bias correction of the AR coefficients
		pu = p
		Ntot = sum(segs[., 2] - segs[., 1] :+ 1) + 50*rows(segs)
		U = rnormal(Ntot, 500, 0, 1)
		Jac = J(q, q, .)
		capsum = qregark_adaptcap(pu, X, C, segs, U, 50, pw, F)
		// never correct below the uncorrected estimate
		if (capsum < .) capsum = max((capsum, sum(pu)))
		capped = 0
		if (qregark_maxroot(pu) >= .99) {
			// uncorrected roots at or beyond the stationarity limit used by the correction
			p = pu
			capped = 1
			capsum = sum(pu)
			Jac = I(q)
		}
		else {
			p = qregark_ii(pu, X, C, segs, U, 50, 8, Jac, capsum, capped, pw, F)
			// regression coefficients given the corrected AR coefficients
			if (pw) qregark_pwfixed(y, X, C, F, tau, p, b, d, tol, maxit)
			else    qregark_emfixed(y, X, C, q, tau, b, p, tol, maxit)
		}
		if (showlog) {
			printf("{txt}Bias correction: sum of AR coefficients %9.4f -> %9.4f%s\n",
				sum(pu), sum(p), (capped ? " (at bound)" : ""))
			displayflush()
		}
	}

	eps = y - X*b
	eta = qregark_filt(eps, p, C)
	// all residuals of the estimating system
	if (pw) {
		Li = qregark_linv(p)
		rh = qregark_tr(eps, p, C, F, 1, Li)
		rF = rh[|1 \ nF|] - d[F[., 2], 1]
		rr = (rF \ eta)
	}
	else rr = eta
	sc  = mean(abs(rr))
	sigma = sum(rr :* (tau :- (rr :< 0))) / mt
	ll = mt*ln(tau*(1-tau)/sigma) - mt

	// stationarity: companion-matrix eigenvalues inside the unit circle
	comp = J(q, q, 0)
	comp[1, .] = p'
	if (q > 1) comp[|2,1 \ q,q-1|] = I(q-1)
	stat = (max(abs(eigenvalues(comp))) < 1)

	nfail = 0
	b0s = .
	b0u = .
	if (!boot) {
		// iid sandwich
		Xh = qregark_filt(X, p, C)
		E  = qregark_lags(eps, q, C)
		G  = (Xh, E)
		if (pw) {
			// first-block rows: d r/d beta = -Li X, d r/d phi numerically
			Xt = qregark_tr(X, p, C, F, 1, Li)
			Xt = Xt[|1,1 \ nF,k|]
			E  = J(nF, q, .)
			hh = 1e-6
			for (j=1; j<=q; j++) {
				pj = p
				pj[j] = pj[j] + hh
				rh = qregark_tr(eps, pj, C, F, 1, qregark_linv(pj))
				E[., j] = -(rh[|1 \ nF|] - d[F[., 2], 1] - rF)/hh
			}
			G = ((Xt, E) \ G)
		}
		// the Prais-Winsten optimum over phi is located by Nelder-Mead (tolerance 1e-6)
		nb = sort(select(rr, abs(rr) :>= (pw ? 1e-5 : 1e-7)*sc), 1)
		h  = qregark_bw(rows(nb), tau, bwmeth, alpha)
		if (tau - h < 0 | tau + h > 1) {
			errprintf("VCE computation failed; try a different bwidth()\n")
			exit(498)
		}
		s = (qregark_pct(nb, 100*(tau+h)) - qregark_pct(nb, 100*(tau-h)))/(2*h)
		if (s < epsilon(1)) {
			errprintf("sparsity estimate is too small; standard errors cannot be computed\n")
			exit(498)
		}
		V = tau*(1-tau)*s^2*invsym(cross(G, G))
		if (bc) {
			// delta-method adjustment for the correction step
			V = qregark_adjV(V, G, Jac, k)
			st_numscalar("r(capped)", capped)
			st_numscalar("r(phi_bound)", capsum)
			st_numscalar("r(sum_rho)", sum(p))
			st_matrix(phiuname, pu')
		}
		if (cons) {
			// report the baseline level of the tau-th quantile as _cons
			b0s = b[k]
			qregark_base(y, X, b, p, eta, segs, tau, bc, C, F, pw, Li, b0m, b0u, vq)
			V = qregark_baseV(V, X, k, q, vq)
			b[k] = b0m
		}
		st_numscalar("r(sparsity)", s)
		st_numscalar("r(bwidth)", h)
	}
	else {
		// residual bootstrap
		B = J(reps, k+q, .)
		if (showlog) {
			printf("\n{txt}Bootstrap replications ({res}%g{txt})\n", reps)
			displayflush()
		}
		for (r=1; r<=reps; r++) {
			idx = ceil(m*runiform(m, 1))
			etastar = eta[idx]
			epsstar = eps
			for (i=1; i<=m; i++) {
				j = C[i]
				epsstar[j] = etastar[i]
				for (cs=1; cs<=q; cs++) epsstar[j] = epsstar[j] + p[cs]*epsstar[j-cs]
			}
			ystar = X*b + epsstar
			bs = b
			ps = p
			if (pw) {
				// Prais-Winsten refit
				cpw = 0
				nev = 0
				ps = qregark_nm(p, .05, ystar, X, C, F, tau, d, bs, tol, maxit,
					fbt, cpw, nev)
				fbt = qregark_pwobj(ps, ystar, X, C, F, tau, d, bs, tol, maxit)
				// re-estimate the first-block offsets in each replication
				rh = qregark_pwoff(qregark_filt(ystar - X*bs, ps, C), ps, tau)
				ps = qregark_nm(ps, .05, ystar, X, C, F, tau, rh, bs, tol,
					maxit, fbt, cpw, nev)
				fbt = qregark_pwobj(ps, ystar, X, C, F, tau, rh, bs, tol, maxit)
				nis = cpw
			}
			else qregark_em(ystar, X, C, q, tau, bs, ps, tol, maxit, nis, nib, 0)
			if (!nis) nfail++
			// baseline level of the tau-th quantile in place of the structural intercept
			if (cons) {
				w = (k > 1 ? ystar - X[|1,1 \ n,k-1|]*bs[|1 \ k-1|] : ystar)
				bs[k] = qregark_pct(sort(w, 1), 100*tau)
			}
			B[r, .] = (bs \ ps)'
			if (showlog) {
				printf(".")
				if (mod(r, 50) == 0) printf(" %5.0f\n", r)
				displayflush()
			}
		}
		if (showlog & mod(reps, 50) != 0) printf("\n")
		V = variance(B)
		if (cons) {
			b0s = b[k]
			w = (k > 1 ? y - X[|1,1 \ n,k-1|]*b[|1 \ k-1|] : y)
			b[k] = qregark_pct(sort(w, 1), 100*tau)
			b0u = b[k]
		}
		alevel = 100*alpha/2
		cip = J(2, k+q, .)
		for (j=1; j<=k+q; j++) {
			v = sort(B[., j], 1)
			cip[1, j] = qregark_pct(v, alevel)
			cip[2, j] = qregark_pct(v, 100 - alevel)
		}
		st_matrix(cname, cip)
	}

	// Wald test of the non-constant regression coefficients
	kx = k - cons
	if (kx > 0) {
		S = V[|1,1 \ kx,kx|]
		chi2 = b[|1 \ kx|]' * invsym(S) * b[|1 \ kx|]
	}
	else chi2 = 0

	st_numscalar("r(b0_struct)", b0s)
	st_numscalar("r(b0_unadj)", b0u)
	st_matrix(bname, (b \ p)')
	st_matrix(Vname, (V + V')/2)
	st_numscalar("r(N)", mt)
	st_numscalar("r(nseg)", rows(segs))
	st_numscalar("r(npan)", npan)
	st_numscalar("r(ngaps)", ngaps)
	st_numscalar("r(converged)", conv)
	st_numscalar("r(niter)", niter)
	st_numscalar("r(sigma)", sigma)
	st_numscalar("r(ll)", ll)
	st_numscalar("r(sum_adev)", sigma*mt)
	st_numscalar("r(stationary)", stat)
	st_numscalar("r(nfail)", nfail)
	st_numscalar("r(chi2)", chi2)
	st_numscalar("r(df_m)", kx)
}

end
