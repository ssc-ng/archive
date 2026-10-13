*! 2.0.0	Ariel Linden 10Oct2026	// fixed exact conditional ML
*! 1.3.1	Ariel Linden 05Oct2026	// fixed moptimize error when if/in excludes observations
*! 1.2.0	Ariel Linden 01Oct2026  // fixed from()
*! 1.1.0	Ariel Linden 29Sep2026	// changed version to 11.0; fixed sort ordering
*! 1.0.0	Ariel Linden 27Jun2026

program define betark, eclass
	version 11.0

	if replay() {
		if "`e(cmd)'" != "betark" {
			di as err "results for {bf:betark} not found"
			exit 301
		}
		Display `0'
		exit
	}

	Estimate `0'
end

program define Display
	syntax [, Level(cilevel) COEFLegend *]
	_get_diopts diopts rest, `options'

	if "`coeflegend'" != "" {
		_coef_table, `diopts' level(`level') coeflegend
		exit
	}

	di
	di as txt "Beta AR(" as res e(p_lag) as txt ") regression, joint conditional ML" ///
		_col(49) "Number of obs" _col(67) "=" ///
		_col(69) as res %10.0fc e(N)
	di as txt _col(49) "Wald chi2(" as res e(df_m) as txt ")" ///
		_col(67) "=" _col(70) as res %9.2f e(chi2)
	di as txt _col(49) "Prob > chi2" ///
		_col(67) "=" _col(70) as res %9.4f e(p)
	di

	di as txt "Link function" _col(16) ":" ///
		_skip(2) as res "g(u) = `e(linkf)'" ///
		as txt _col(49) "[{res:`e(linkt)'}]"
	di as txt "Slink function" _col(16) ":" ///
		_skip(2) as res "g(u) = `e(slinkf)'" ///
		as txt _col(49) "[{res:`e(slinkt)'}]"
	di
	di as txt "Log likelihood" _col(16) "=" as res %11.8g e(ll)
	di

	_coef_table, `diopts' level(`level')
	ml_footnote
end

program define Estimate, eclass
	syntax varlist(numeric fv ts) [if] [in]		///
		, LAG(integer)								///
		[ SCale(varlist numeric fv ts)				///
		  noCONstant								///
		  LInk(string)								///
		  SLInk(string)								///
		  Level(cilevel)							///
		  COEFLegend								///
		  ITERate(integer 1500)						///
		  TOLerance(real 1e-6)						///
		  NOLOg										///
		  from(string)								///
		]

	local cmdline `"betark `0'"'

	if `lag' < 1 {
		di as err "lag() must be >= 1"
		exit 198
	}
	if `tolerance' <= 0 {
		di as err "tolerance() must be positive"
		exit 198
	}
	if `iterate' < 1 {
		di as err "iterate() must be a positive integer"
		exit 198
	}

	marksample touse
	qui count if `touse'
	if r(N) <= 1 {
		di as err "insufficient observations"
		exit 2001
	}

	gettoken depvar indepvars : varlist

	// depvar must be strictly in (0,1), same check as betareg
	qui summarize `depvar' if `touse'
	if r(min) <= 0 | r(max) >= 1 {
		di as err "`depvar' must be greater than zero and less than one"
		exit 459
	}

	// link / slink: identical menu and defaults to betareg
	ParseLink, `link'
	local link  `s(link)'
	local linkf `s(linkf)'
	local linkt `s(linkt)'
	ParseSlink, `slink'
	local slink  `s(slink)'
	local slinkf `s(slinkf)'
	local slinkt `s(slinkt)'

	if "`link'" != "logit" {
		di as err "link(`link') is not yet implemented in betark; only link(logit) is currently supported"
		exit 198
	}
	if "`slink'" != "log" {
		di as err "slink(`slink') is not yet implemented in betark; only slink(log) is currently supported"
		exit 198
	}

	// time variable required: AR(k) needs an explicit ordering
	_ts timevar panvar, panel
	if "`timevar'" == "" {
		di as err "betark requires the data to be tsset"
		exit 459
	}
	local tsdelta = r(tdelta)

	quietly tsreport if `touse'
	local ngaps = r(N_gaps)
	if `ngaps' > 0 {
		di ""
		di as txt "Number of gaps in sample = " as res `ngaps' ///
			as txt "   (gap count includes panel changes)"
		di as txt "note: computations for rho restarted at each gap."
	}

	local nocons_mean = ("`constant'" == "noconstant")
	if "`indepvars'" == "" {
		if `nocons_mean' {
			di as err "no regressors and noconstant specified: empty mean model"
			exit 198
		}
		local indepvars_full ""
		local indepvars_est  ""
	}
	else {
		_rmcoll `indepvars' if `touse', expand `constant'
		local indepvars_full `r(varlist)'
		local indepvars_est ""
		foreach v of local indepvars_full {
			if substr("`v'", 1, 2) != "o." local indepvars_est `indepvars_est' `v'
		}
	}

	// collinearity removal, scale equation (same logic)
	local nocons_scale = 0
	if "`scale'" != "" {
		_rmcoll `scale' if `touse', expand
		local scale_full `r(varlist)'
		local scale_est ""
		foreach v of local scale_full {
			if substr("`v'", 1, 2) != "o." local scale_est `scale_est' `v'
		}
	}
	else {
		local scale_full ""
		local scale_est  ""
	}

	markout `touse' `depvar' `indepvars_est' `scale_est'

	local meannames `indepvars_full'
	if !`nocons_mean' local meannames `meannames' _cons
	local scalenames `scale_full' _cons
	local arnames ""
	forvalues j = 1/`lag' {
		local arnames `arnames' rho`j'
	}

	local k1 : word count `meannames'		// FULL count (display)
	local k2 : word count `scalenames'		// FULL count (display)
	local k3 : word count `arnames'

	local k1_est : word count `indepvars_est'
	if !`nocons_mean' local k1_est = `k1_est' + 1
	local k2_est : word count `scale_est'
	local k2_est = `k2_est' + 1		// scale always has _cons

	// starting values
	sort `panvar' `timevar'
	tempname b_init
	local fast_start = 0
	if `"`from'"' != "" {
		matrix `b_init' = `from'
	}
	else {
		_betark_start `depvar' if `touse', bname(`b_init') lag(`lag') ///
			xvars(`indepvars_est') zvars(`scale_est') `constant'
		local fast_start = 1
	}

	di ""
	quietly count if !`touse'
	local nexcl_rows = r(N)
	forvalues attempt = 1/2 {
	if `attempt' == 2 {
		// fallback if the fit from the fast starting values did not converge
		if !(`conv_post' == 0 & `fast_start') continue, break
		if "`scale_est'" != "" local scaleopt "scale(`scale_est')"
		else                   local scaleopt ""
		capture quietly betareg `depvar' `indepvars_est' if `touse', `constant' `scaleopt'
		if _rc continue, break
		tempname bmean bscale
		matrix `bmean'  = e(b)[1, 1..`k1_est']
		matrix `bscale' = e(b)[1, `k1_est'+1..`k1_est'+`k2_est']
		matrix `b_init' = `bmean', `bscale', J(1, `k3', 0.1/`lag')
		di as txt "note: refitting from static beta-regression starting values"
	}
	if `nexcl_rows' > 0 {
		preserve
		quietly keep if `touse'
	}
	mata: betark_main("`depvar'", "`indepvars_est'", "`scale_est'",	///
	                   `lag', "`touse'", "`timevar'", "`panvar'",		///
	                   `nocons_mean', `k1_est', `k2_est', `k3',		///
	                   `tolerance', `iterate', "`b_init'", `ngaps',		///
	                   ("`nolog'" == ""))

	matrix b_post = r(b)
	matrix V_post = r(V)
	local ll_post    = r(ll)
	local nobs_post  = r(nobs)
	local niter_post = r(niter)
	local conv_post  = r(converged)

	if `nexcl_rows' > 0 {
		restore
	}
	}	// attempt

	if `conv_post' == 0 {
		di as txt "{p}Warning: optimizer did not report convergence within iterate(`iterate'). " ///
		          "Results may be unreliable; consider increasing iterate() or supplying from().{p_end}"
	}

	local allnames_full `meannames' `scalenames' `arnames'
	local k_full : word count `allnames_full'

	tempname b_full V_full
	matrix `b_full' = J(1, `k_full', 0)
	matrix `V_full' = J(`k_full', `k_full', 0)

	local col_f = 0
	local col_r = 0
	foreach v of local allnames_full {
		local col_f = `col_f' + 1
		if substr("`v'", 1, 2) != "o." {
			local col_r = `col_r' + 1
			matrix `b_full'[1, `col_f'] = b_post[1, `col_r']
			local col_f2 = 0
			local col_r2 = 0
			foreach v2 of local allnames_full {
				local col_f2 = `col_f2' + 1
				if substr("`v2'", 1, 2) != "o." {
					local col_r2 = `col_r2' + 1
					matrix `V_full'[`col_f', `col_f2'] = V_post[`col_r', `col_r2']
				}
			}
		}
	}
	matrix b_post = `b_full'
	matrix V_post = `V_full'

	local colnames ""
	foreach v of local meannames {
		local colnames `"`colnames' `depvar':`v'"'
	}
	foreach v of local scalenames {
		local colnames `"`colnames' scale:`v'"'
	}
	foreach v of local arnames {
		local colnames `"`colnames' ar:`v'"'
	}

	matrix colnames b_post = `colnames'
	matrix colnames V_post = `colnames'
	matrix rownames V_post = `colnames'

	ereturn post b_post V_post, depname(`depvar') obs(`nobs_post') esample(`touse')

	ereturn local cmd       "betark"
	ereturn local predict    "betark_p"
	ereturn local cmdline    `"`cmdline'"'
	ereturn local title      "Beta AR(`lag') regression, joint conditional ML"
	ereturn local link       "`link'"
	ereturn local linkf      "`linkf'"
	ereturn local linkt      "`linkt'"
	ereturn local slink      "`slink'"
	ereturn local slinkf     "`slinkf'"
	ereturn local slinkt     "`slinkt'"
	ereturn local timevar    "`timevar'"
	ereturn local panelvar   "`panvar'"
	ereturn local noconstant "`constant'"

	ereturn scalar ll         = `ll_post'
	ereturn scalar N          = `nobs_post'
	ereturn scalar p_lag      = `lag'
	ereturn scalar iterations = `niter_post'
	ereturn scalar converged  = `conv_post'
	ereturn scalar ngaps      = `ngaps'
	ereturn scalar tolerance  = `tolerance'

	if `nocons_mean' {
		ereturn scalar df_m = `k1_est'			// no constant: all mean-eq terms tested
	}
	else {
		ereturn scalar df_m = `k1_est' - 1		// constant present: excluded from the Wald test below
	}

	// Wald test on the mean equation's non-constant coefficients
	if "`indepvars_est'" != "" {
		qui test `indepvars_est'
		ereturn scalar chi2 = r(chi2)
		ereturn scalar p    = chi2tail(e(df_m), e(chi2))
	}
	else {
		ereturn scalar chi2 = 0
		ereturn scalar p    = 1
	}

	Display, level(`level') `coeflegend'
end


// link/slink parsers -- identical menu/defaults to betareg, kept as-is
program define ParseLink, sclass
	syntax [, logit PRObit CLOGlog LOGLog *]
	if `"`options'"' != "" {
		di as err "unrecognized link() function: `options'"
		exit 199
	}
	capture qui opts_exclusive "`logit' `probit' `cloglog' `loglog'"
	if _rc {
		di as err "only one of logit, probit, cloglog, or loglog is allowed"
		exit 198
	}
	local link `logit' `probit' `cloglog' `loglog'
	if "`link'" == "" local link "logit"
	sreturn local link "`link'"
	if "`link'" == "logit" {
		sreturn local linkf "log(u/(1-u))"
		sreturn local linkt "Logit"
	}
	else if "`link'" == "probit" {
		sreturn local linkf "invnormal(u)"
		sreturn local linkt "Probit"
	}
	else if "`link'" == "cloglog" {
		sreturn local linkf "log(-log(1-u))"
		sreturn local linkt "Comp. log-log"
	}
	else if "`link'" == "loglog" {
		sreturn local linkf "-log(-log(u))"
		sreturn local linkt "Log-log"
	}
end

program define ParseSlink, sclass
	syntax [, log root IDENtity *]
	if `"`options'"' != "" {
		di as err "unrecognized slink() function: `options'"
		exit 199
	}
	capture qui opts_exclusive "`identity' `root' `log'"
	if _rc {
		di as err "only one of log, root, or identity is allowed"
		exit 198
	}
	local slink `log' `root' `identity'
	if "`slink'" == "" local slink "log"
	sreturn local slink "`slink'"
	if "`slink'" == "log" {
		sreturn local slinkf "log(u)"
		sreturn local slinkt "Log"
	}
	else if "`slink'" == "root" {
		sreturn local slinkf "sqrt(u)"
		sreturn local slinkt "Square root"
	}
	else if "`slink'" == "identity" {
		sreturn local slinkf "u"
		sreturn local slinkt "Identity"
	}
end


// starting values
program define _betark_start
	syntax varname [if], BNAME(name) LAG(integer) [XVARS(string) ZVARS(string) noCONstant]
	marksample touse
	tempvar ly xb u mu a sq
	tempname bm bs br
	quietly gen double `ly' = logit(`varlist') if `touse'
	quietly regress `ly' `xvars' if `touse', `constant'
	matrix `bm' = e(b)
	quietly predict double `xb' if `touse', xb
	quietly gen double `u'  = `ly' - `xb' if `touse'
	quietly gen double `mu' = invlogit(`xb') if `touse'
	quietly gen double `a'  = `mu'*(1 - `mu') if `touse'
	quietly gen double `sq' = (`varlist' - `mu')^2 if `touse'
	quietly summarize `a', meanonly
	local ma = r(mean)
	quietly summarize `sq', meanonly
	local mb = r(mean)
	local phi = `ma'/`mb' - 1
	if missing(`phi') | `phi' < 1 local phi = 10
	local nz : word count `zvars'
	if `nz' > 0 matrix `bs' = J(1, `nz', 0), ln(`phi')
	else        matrix `bs' = (ln(`phi'))
	local rho_ok = 0
	capture quietly regress `u' L(1/`lag').`u' if `touse', noconstant
	if _rc == 0 {
		matrix `br' = e(b)
		local rho_ok = 1
		forvalues j = 1/`lag' {
			if missing(`br'[1, `j']) local rho_ok = 0
		}
	}
	if !`rho_ok' matrix `br' = J(1, `lag', 0.1/`lag')
	matrix `bname' = `bm', `bs', `br'
end

mata:

real matrix function betark_getsegs(real colvector panid, real colvector tvec)
{
	real matrix    segs
	real scalar    n, i, start
	n = rows(panid)
	segs = J(0, 2, .)
	start = 1
	for (i=2; i<=n; i++) {
		if (panid[i] != panid[i-1] | tvec[i] != tvec[i-1] + 1) {
			segs = (segs \ (start, i-1))
			start = i
		}
	}
	segs = (segs \ (start, n))
	return(segs)
}


// exact conditional log likelihood and coefficient-level gradient
void function betark_llg(real rowvector b, real colvector y,
                           real matrix Xm, real matrix Xs,
                           real colvector seg_start, real colvector seg_end,
                           real scalar p, real scalar wantg,
                           real colvector lnf, real matrix G, real matrix Seq,
                           real matrix Xtil, real colvector contrib)
{
	real scalar    n, k1, k2, q, gg, j
	real rowvector bm, bs, rho
	real colvector eta, lnphi, ly, d, C, xi, mu, phi, okm, okp, yc, mphi, qphi, ms, sstar, sphi, dj
	real matrix    Xt

	n  = rows(y)
	k1 = cols(Xm)
	k2 = cols(Xs)
	q  = k1 + k2 + p
	bm  = b[1..k1]
	bs  = b[(k1+1)..(k1+k2)]
	rho = b[(k1+k2+1)..q]

	// contributing observations: positions p+1, ..., end of each segment
	C = J(0, 1, .)
	for (gg=1; gg<=rows(seg_start); gg++) {
		if (seg_end[gg] - seg_start[gg] + 1 > p) C = (C \ ((seg_start[gg]+p)::seg_end[gg]))
	}

	lnf     = J(n, 1, 0)
	contrib = J(n, 1, 0)
	if (wantg) {
		G    = J(n, q, 0)
		Seq  = J(n, 2+p, 0)
		Xtil = J(n, k1, 0)
	}
	if (rows(C) == 0) return

	eta   = Xm*bm'
	lnphi = Xs*bs'
	ly    = logit(y)
	d     = ly - eta                       // logit-scale deviations

	xi = J(rows(C), 1, 0)
	for (j=1; j<=p; j++) xi = xi + rho[j]*d[C :- j]

	mu  = invlogit(eta[C] + xi)
	okm = (mu :>= 1e-10) :& (mu :<= 1 - 1e-10)
	mu  = rowmin((rowmax((mu, J(rows(C), 1, 1e-10))), J(rows(C), 1, 1 - 1e-10)))
	phi = exp(lnphi[C])
	okp = (phi :>= 1e-6)
	phi = rowmax((phi, J(rows(C), 1, 1e-6)))
	yc   = y[C]
	mphi = mu :* phi
	qphi = (1 :- mu) :* phi

	lnf[C] = lngamma(phi) - lngamma(mphi) - lngamma(qphi) +
	         (mphi :- 1) :* ln(yc) + (qphi :- 1) :* ln(1 :- yc)
	contrib[C] = J(rows(C), 1, 1)

	if (wantg) {
		ms    = digamma(mphi) - digamma(qphi)
		sstar = okm :* phi :* mu :* (1 :- mu) :* (ly[C] - ms)
		sphi  = okp :* phi :* (digamma(phi) - mu :* digamma(mphi) - (1 :- mu) :* digamma(qphi) +
		                       mu :* ln(yc) + (1 :- mu) :* ln(1 :- yc))
		Xt = Xm[C, .]
		for (j=1; j<=p; j++) Xt = Xt - rho[j]*Xm[C :- j, .]
		Xtil[C, .] = Xt
		Seq[C, 1]  = sstar
		Seq[C, 2]  = sphi
		G[C, 1..k1]           = sstar :* Xt
		G[C, (k1+1)..(k1+k2)] = sphi :* Xs[C, .]
		for (j=1; j<=p; j++) {
			dj = sstar :* d[C :- j]
			Seq[C, 2+j]    = dj
			G[C, k1+k2+j]  = dj
		}
	}
}


// general-form (gf1) evaluator
void function betark_gf(transmorphic M, real scalar todo, real rowvector b,
                          real colvector fv, real matrix S, real matrix H)
{
	real colvector y, seg_start, seg_end, perm, lnf, contrib
	real matrix    Xm, Xs, G, Seq, Xtil
	real scalar    p

	y         = moptimize_util_userinfo(M, 1)
	seg_start = moptimize_util_userinfo(M, 2)
	seg_end   = moptimize_util_userinfo(M, 3)
	p         = moptimize_util_userinfo(M, 4)
	perm      = moptimize_util_userinfo(M, 5)
	Xm        = moptimize_util_userinfo(M, 6)
	Xs        = moptimize_util_userinfo(M, 7)

	lnf = contrib = J(0, 1, .)
	G = Seq = Xtil = J(0, 0, .)
	betark_llg(b, y, Xm, Xs, seg_start, seg_end, p, (todo >= 1), lnf, G, Seq, Xtil, contrib)

	fv = J(rows(y), 1, .)
	fv[perm] = lnf
	if (todo >= 1) {
		S = J(rows(G), cols(G), .)
		S[perm, .] = G
	}
}


void function betark_main(string scalar yvar,
                           string scalar xvars,
                           string scalar zvars,
                           real   scalar p,
                           string scalar tousename,
                           string scalar timevar,
                           string scalar panelvar,
                           real   scalar nocons_mean,
                           real   scalar k1,
                           real   scalar k2,
                           real   scalar k3,
                           real   scalar tol,
                           real   scalar maxiter,
                           string scalar b_init_name,
                           real   scalar ngaps_in,
                           real   scalar showlog)
{
	real matrix      data, allsegs, X_mean, X_scale
	real colvector   y, panid, tvec, seg_start, seg_end, p_order
	real rowvector   b0
	real scalar      nobs, converged, ll, nexcl, jj, has_x, has_z, nx, nz, col
	string matrix    allvars
	transmorphic     M

	has_x = (xvars != "")
	has_z = (zvars != "")
	nx    = has_x ? cols(tokens(xvars)) : 0
	nz    = has_z ? cols(tokens(zvars)) : 0

	// load segments/ordering variables plus the mean and scale designs
	if (panelvar != "") allvars = (tousename, panelvar, timevar, yvar)
	else                allvars = (tousename, timevar, yvar)
	if (has_x) allvars = (allvars, tokens(xvars))
	if (has_z) allvars = (allvars, tokens(zvars))

	data = st_data(., allvars)
	data = select(data, data[.,1] :== 1)

	if (panelvar != "") {
		p_order = order(data[|1,1 \ rows(data),3|], (2,3))
		data    = data[p_order, .]
		panid   = data[., 2]
		tvec    = data[., 3]
		y       = data[., 4]
		col     = 4
	}
	else {
		p_order = order(data[.,2], 1)
		data    = data[p_order, .]
		panid   = J(rows(data), 1, 1)
		tvec    = data[., 2]
		y       = data[., 3]
		col     = 3
	}

	if (has_x) {
		X_mean = data[|1,col+1 \ rows(data), col+nx|]
		col = col + nx
	}
	else X_mean = J(rows(data), 0, .)
	if (has_z) {
		X_scale = data[|1,col+1 \ rows(data), col+nz|]
		col = col + nz
	}
	else X_scale = J(rows(data), 0, .)
	// column order matches the coefficient vector (constant last)
	if (!nocons_mean) X_mean = (X_mean, J(rows(data), 1, 1))
	X_scale = (X_scale, J(rows(data), 1, 1))

	nobs    = rows(y)
	allsegs = betark_getsegs(panid, tvec)
	seg_start = allsegs[.,1]
	seg_end   = allsegs[.,2]

	b0 = st_matrix(b_init_name)

	M = moptimize_init()
	moptimize_init_evaluator(M, &betark_gf())
	moptimize_init_evaluatortype(M, "gf1")
	moptimize_init_depvar(M, 1, yvar)
	moptimize_init_touse(M, tousename)

	moptimize_init_eq_n(M, 2 + p)

	moptimize_init_eq_indepvars(M, 1, xvars)
	if (nocons_mean) moptimize_init_eq_cons(M, 1, "off")
	moptimize_init_eq_name(M, 1, yvar)

	moptimize_init_eq_indepvars(M, 2, zvars)
	moptimize_init_eq_name(M, 2, "scale")

	for (jj=1; jj<=p; jj++) {
		moptimize_init_eq_indepvars(M, 2+jj, "")
		moptimize_init_eq_name(M, 2+jj, "ar")
	}

	moptimize_init_userinfo(M, 1, y)
	moptimize_init_userinfo(M, 2, seg_start)
	moptimize_init_userinfo(M, 3, seg_end)
	moptimize_init_userinfo(M, 4, p)
	moptimize_init_userinfo(M, 5, p_order)
	moptimize_init_userinfo(M, 6, X_mean)
	moptimize_init_userinfo(M, 7, X_scale)

	moptimize_init_conv_maxiter(M, maxiter)
	moptimize_init_conv_ptol(M, tol)
	moptimize_init_conv_vtol(M, tol)
	moptimize_init_conv_ignorenrtol(M, "on")
	moptimize_init_technique(M, "nr 5 bhhh 20 nr")
	moptimize_init_singularHmethod(M, "hybrid")
	if (showlog) moptimize_init_trace_value(M, "on")
	else         moptimize_init_trace_value(M, "off")

	if (cols(b0) > 0) {
		moptimize_init_eq_coefs(M, 1, b0[1, 1..k1])
		moptimize_init_eq_coefs(M, 2, b0[1, k1+1..k1+k2])
		for (jj=1; jj<=p; jj++) {
			moptimize_init_eq_coefs(M, 2+jj, b0[1, k1+k2+jj])
		}
	}

	converged = 1
	moptimize(M)
	if (moptimize_result_converged(M) == 0) converged = 0

	ll = moptimize_result_value(M)

	nexcl = 0
	for (jj=1; jj<=rows(seg_start); jj++) {
		if (seg_end[jj]-seg_start[jj]+1 > p) nexcl = nexcl + p
		else                                 nexcl = nexcl + (seg_end[jj]-seg_start[jj]+1)
	}

	st_matrix("r(b)", moptimize_result_coefs(M))
	st_matrix("r(V)", moptimize_result_V(M))
	st_numscalar("r(ll)", ll)
	st_numscalar("r(nobs)", nobs - nexcl)
	st_numscalar("r(niter)", moptimize_result_iterations(M))
	st_numscalar("r(converged)", converged)
}

end
