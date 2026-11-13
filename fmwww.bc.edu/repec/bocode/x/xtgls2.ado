*! xtgls2 version 2.0 - 09 Nov 2026
*! Manh Hoang-Ba (hbmanh9492@gmail.com)
*! Ref.: Kiefer (1980); Wooldridge (2002, 2010)
*
* Version 1.1 to allow iterated GLS.
* Version 1.2 cov(h) and (fe or fd) are not specified together,
*				and correct number of iterations.
* Version 1.3 to allow combination with bootstrap command.
* Version 1.4 to speed up IGLS; allow IC and lrtest after IGLS; 
*				and fix rounding error in FEGLS and FDGLS.
* Version 1.5 to allow robust and re options.
* Version 1.6 return data whenever an error arises.
* Version 1.7 correct Wald statistic when cluster/robust specified
*			  and disable minus option
* Version 2.0  * correct R-squared between/overall
*              * estimation, iterated GLS, robust and cluster-robust variances
*                are all coded in Mata; no dependence on -xtgls- or -xtglsr-
*              * re now really uses the RE (Swamy-Arora) residuals to build Omega
*                instead the POLS residuals
*              * strict balance check (same set of time values in every panel)
*              * aweight and pweight allowed
*              * robust / cluster() no longer silently ignore each other
*              * by: allowed (byable)


cap program drop xtgls2
program define xtgls2, eclass byable(onecall)
	version 11

	if replay() {
		if _by() error 190
		if "`e(cmd)'" != "xtgls2" error 301
		syntax [, Level(cilevel)]
		xtgls2_display, level(`level')
		exit
	}
	if _by() local by "by `_byvars'`_byrc0':"
	`by' xtgls2_estimate `0'
end


*------------------------------------------------------------------------------
*  Estimation (Stata layer: parse, sample, variables) -> calls Mata
*------------------------------------------------------------------------------
cap program drop xtgls2_estimate
program define xtgls2_estimate, eclass byable(recall)
	version 11

	syntax varlist(min=2 fv ts) [if] [in] [aw pw] [, ///
		PGLS OLS FE FD RE ///
		Robust CLuster(varname) ///
		NOConstant nmk ///
		Level(cilevel) ///
		IGLS ITERate(int 300) TOLerance(real 1e-7) ///
		NOLOg ]

	// ---- model -------------------------------------------------------------
	if "`ols'" != "" local pgls pgls			// ols = old name of pgls
	local nmod = ("`pgls'"!="") + ("`fe'"!="") + ("`fd'"!="") + ("`re'"!="")
	if `nmod' > 1 {
		di as err "specify only one of {bf:pgls}, {bf:re}, {bf:fe} or {bf:fd}"
		exit 198
	}
	if "`fe'" != ""      local model fe
	else if "`fd'" != "" local model fd
	else if "`re'" != "" local model re
	else                 local model pgls
	local mcode = cond("`model'"=="pgls", 1, cond("`model'"=="re", 2, ///
				cond("`model'"=="fe", 3, 4)))

	if `iterate' < 1 {
		di as err "iterate() must be positive"
		exit 198
	}
	if `tolerance' <= 0 {
		di as err "tolerance() must be positive"
		exit 198
	}

	if "`model'" == "fe" | "`model'" == "fd" local noconstant noconstant
	local hascons = ("`noconstant'" == "")

	// ---- weights -----------------------------------------------------------
	if "`weight'" != "" & "`model'" == "re" {
		di as err "weights are not allowed with {bf:re}"
		exit 101
	}
	local wt = cond("`weight'"=="aweight", 1, cond("`weight'"=="pweight", 2, 0))
	local dorobust = ("`robust'" != "" | "`cluster'" != "" | "`weight'" == "pweight")

	// ---- panel structure ---------------------------------------------------
	qui xtset
	local ivar  "`r(panelvar)'"
	local tvar  "`r(timevar)'"
	local tdelta = r(tdelta)
	if "`ivar'" == "" {
		di as err "data must be {bf:xtset} before using this command"
		exit 459
	}
	if "`tvar'" == "" {
		di as err "time variable not set; use {bf:xtset} {it:panelvar} {it:timevar}"
		exit 459
	}

	// ---- estimation sample -------------------------------------------------
	tempvar touse wvar clid
	mark `touse' `if' `in'
	markout `touse' `varlist'
	if "`cluster'" != "" markout `touse' `cluster', strok
	if "`weight'" != "" {
		qui gen double `wvar' `exp'
		qui replace `touse' = 0 if missing(`wvar')
		qui count if `wvar' < 0 & `touse'
		if r(N) {
			di as err "negative weights encountered"
			exit 402
		}
		qui replace `touse' = 0 if `wvar' == 0
	}
	qui count if `touse'
	if r(N) == 0 error 2000

	// ---- variables ---------------------------------------------------------
	gettoken depvar indeps : varlist
	_fv_check_depvar `depvar'

	_rmcoll `indeps' if `touse', `noconstant' expand
	local terms `r(varlist)'

	// drop base levels / omitted terms
	local nterms : word count `terms'
	tempname om
	matrix `om' = J(1, `nterms', 0)
	matrix colnames `om' = `terms'
	_ms_omit_info `om'
	matrix `om' = r(omit)
	local est_terms
	forvalues j = 1/`nterms' {
		if `om'[1,`j'] == 0 {
			local est_terms `est_terms' `: word `j' of `terms''
		}
	}

	fvrevar `depvar'
	local yvar `r(varlist)'
	// build the variables from the FULL expanded list, exactly
	// as returned by _rmcoll, then keep the positions of the estimated terms
	fvrevar `terms'
	local allx `r(varlist)'
	local xvars
	local est_chk
	forvalues j = 1/`nterms' {
		if `om'[1,`j'] == 0 {
			local v : word `j' of `allx'
			local xvars `xvars' `v'
			qui summarize `v' if `touse', meanonly
			if r(min) == 0 & r(max) == 0 {
				di as err "term `: word `j' of `terms'' is identically zero in the estimation sample"
				exit 498
			}
		}
	}

	local clidarg ""
	if "`cluster'" != "" {
		qui egen long `clid' = group(`cluster') if `touse'
		local clidarg "`clid'"
	}
	local wvararg ""
	if `wt' > 0 local wvararg "`wvar'"

	// ---- Mata engine -------------------------------------------------------
	tempname b V Sigma kept info
	local xtgls2_msg
	local xtgls2_rc
	mata: xtgls2_main("`yvar'", "`xvars'", "`est_terms'", ///
		"`touse'", "`ivar'", "`tvar'", "`wvararg'", "`clidarg'", ///
		`mcode', `hascons', `wt', ///
		`dorobust', ("`igls'" != ""), `iterate', `tolerance', ///
		("`nmk'" != ""), ("`nolog'" == ""), `tdelta', ///
		"`b'", "`V'", "`Sigma'", "`kept'", "`info'")
	
	if "`xtgls2_rc'" != "" {
		di as err `"`xtgls2_msg'"'
		exit `xtgls2_rc'
	}

	// ---- coefficient names (omit what Mata removed) ------------------------
	local bnames
	local j 0
	foreach t of local est_terms {
		local ++j
		if `kept'[1,`j'] == 1 local bnames `bnames' `t'
	}
	if `hascons' {
		local ++j
		if `kept'[1,`j'] == 1 local bnames `bnames' _cons
	}
	matrix colnames `b' = `bnames'
	matrix colnames `V' = `bnames'
	matrix rownames `V' = `bnames'

	// ---- post --------------------------------------------------------------
	local nobs = `info'[1, colnumb(`info', "N")]
	ereturn post `b' `V', esample(`touse') obs(`nobs') depname(`depvar')
	ereturn matrix Sigma = `Sigma'

	local cn : colnames `info'
	local j 0
	foreach c of local cn {
		local ++j
		if "`c'" != "N" & !missing(`info'[1,`j']) {
			ereturn scalar `c' = `info'[1,`j']
		}
	}
	ereturn scalar level = `level'

	ereturn local cmd      "xtgls2"
	ereturn local cmdline  "xtgls2 `0'"
	ereturn local title    "Generalized least squares (Wooldridge)"
	ereturn local depvar   "`depvar'"
	ereturn local ivar     "`ivar'"
	ereturn local tvar     "`tvar'"
	ereturn local model    "`model'"
	ereturn local chi2type "Wald"
	ereturn local predict  "xtgls2_p"
	ereturn local properties "b V"
	if "`igls'" != "" ereturn local igls "igls"
	if `wt' > 0 {
		ereturn local wtype "`weight'"
		ereturn local wexp  "`exp'"
	}
	if `dorobust' {
		ereturn local vcetype "Robust"
		if "`cluster'" != "" ereturn local clustvar "`cluster'"
		else                 ereturn local clustvar "`ivar'"
	}

	xtgls2_display, level(`level')
end


*------------------------------------------------------------------------------
*  Display
*------------------------------------------------------------------------------
cap program drop xtgls2_display
program define xtgls2_display
	version 11
	syntax [, Level(cilevel)]

	if "`e(model)'" == "pgls" {
		local model_  "Pooled"
		local model_sf "PGLS"
	}
	if "`e(model)'" == "fe" {
		local model_  "Fixed-effects"
		local model_sf "FEGLS"
	}
	if "`e(model)'" == "fd" {
		local model_  "First-difference"
		local model_sf "FDGLS"
	}
	if "`e(model)'" == "re" {
		local model_  "Random-effects"
		local model_sf "REGLS"
	}

	if e(chi2) > 999999 local cfmt `"%10.0g"'
	else                local cfmt `"%10.3f"'

	di
	di in gr "`model_' Generalized Least Squares (`model_sf') regression" _n
	if "`e(wtype)'" != "" {
		di in gr _col(6) "Weights:" in ye _col(23) "[`e(wtype)'`e(wexp)']"
	}

	di in gr "Estimated covariances:" ///
		in ye _col(25) %3.0fc e(n_cv) ///
		in gr _col(49) `"Number of obs"' _col(67) `"= "' in ye %10.0fc e(N)

	di in gr "R-squared:" ///
		in gr _col(49) `"Number of groups"' _col(67) `"= "' in ye %10.0fc e(N_g)

	di in gr _col(6) "Within" _col(15) "= " in ye %7.4f e(r2_w) ///
		in gr _col(49) `"Time periods"' _col(67) "= " in ye %10.0fc e(N_t)

	di in gr _col(6) "Between" _col(15) "= " in ye %7.4f e(r2_b) ///
		in gr _col(49) `"Wald chi2("' in ye e(df) in gr `")"' ///
		in gr _col(67) `"= "' in ye `cfmt' e(chi2)

	di in gr _col(6) "Overall" _col(15) "= " in ye %7.4f e(r2_o) ///
		in gr _col(49) `"Prob > chi2"' _col(67) `"= "' ///
		in ye %10.4f chi2tail(e(df), e(chi2))

	di

	ereturn display, level(`level') noemptycells

	di as txt "{bf:Note:} Reported R-squared values are not used for model comparison"
	di as txt "      and serve only as measures of predictive ability on the original data."
end


*------------------------------------------------------------------------------
*  Mata engine
*
*  Layout used throughout: observations are sorted by (panel, time), the panel
*  must be balanced, and the data are then re-ordered "t-major":
*  row (t-1)*N + i  holds panel i at (the t-th) time period.  With this layout
*       (A (x) I_N) * M          = sum over periods of A[r,s]*M[slab s]
*       sum_i X_i' W y_i         = X' (W (x) I_N) y
*  can be computed without ever forming a Kronecker product.
*
*  Every estimator is "GLS on transformed data":
*       pgls, re : A = I_T                    (Omega is T x T)
*       fe       : A = Helmert (T-1) x T      (A A' = I, A'A = I - jj'/T)
*       fd       : A = first-difference       (T-1) x T
*  and  Omega_hat = N^-1 sum_i uhat_i uhat_i' with uhat the first-step residuals
*       (OLS on transformed data; RE residuals for re; RE = Swamy-Arora).
*  For fe, Omega_hat of the demeaned residuals is T x T of rank T-1; working with
*  the Helmert basis is identical to using its generalized inverse, but without
*  numerical rank problems.
*------------------------------------------------------------------------------
mata:

void xtgls2_fail(string scalar msg, real scalar rc)
{
	st_local("xtgls2_msg", msg)
	st_local("xtgls2_rc", strofreal(rc))
}

real colvector xtgls2_tperm(real scalar N, real scalar T)
{
	real colvector rr, base
	real scalar t
	rr   = J(N*T, 1, .)
	base = (0::(N-1)) :* T
	for (t=1; t<=T; t++) rr[|(t-1)*N+1 \ t*N|] = base :+ t
	return(rr)
}

// (A (x) I_N) * M  for a t-major matrix M with cols(A)*N rows
real matrix xtgls2_kron(real matrix A, real matrix M, real scalar N)
{
	real scalar To, Tt, r, s, c
	real matrix R
	To = rows(A); Tt = cols(A); c = cols(M)
	R = J(To*N, c, 0)
	for (r=1; r<=To; r++) {
		for (s=1; s<=Tt; s++) {
			if (A[r,s] != 0) {
				R[|(r-1)*N+1, 1 \ r*N, c|] = R[|(r-1)*N+1, 1 \ r*N, c|] + A[r,s] * M[|(s-1)*N+1, 1 \ s*N, c|]
			}
		}
	}
	return(R)
}

real matrix xtgls2_helmert(real scalar T)
{
	real matrix H
	real scalar r
	H = J(T-1, T, 0)
	for (r=1; r<=T-1; r++) {
		H[r, 1..r] = J(1, r, 1/sqrt(r*(r+1)))
		H[r, r+1]  = -r/sqrt(r*(r+1))
	}
	return(H)
}

real matrix xtgls2_fd(real scalar T)
{
	real matrix D
	real scalar r
	D = J(T-1, T, 0)
	for (r=1; r<=T-1; r++) {
		D[r, r]   = -1
		D[r, r+1] = 1
	}
	return(D)
}

// panel means of a t-major vector, expanded back to t-major
real colvector xtgls2_dmv(real colvector v, real scalar T)
{
	real matrix Mv
	Mv = rowshape(v, T)
	return(colshape(Mv :- mean(Mv), 1))
}

real matrix xtgls2_dm(real matrix M, real scalar T)
{
	real matrix R
	real scalar j
	R = J(rows(M), cols(M), .)
	for (j=1; j<=cols(M); j++) R[., j] = xtgls2_dmv(M[., j], T)
	return(R)
}

// expand an N x 1 vector of panel values to t-major
real colvector xtgls2_exp(real colvector v, real scalar T)
{
	return(colshape(J(T, 1, 1) * v', 1))
}

// fe/fd (and the RE within step): columns that must be dropped AFTER the transformation.
//  (i)  numerically zero columns (time-invariant regressors);
//  (ii) exact collinearity created by the transformation, e.g. a variable that is a
//       deterministic function of time (age, experience = a_i + t) together with a full
//       set of (T-1) time dummies: not collinear in levels, but Delta x is a combination of
//       the differenced (or demeaned) dummies.  Columns are checked in the given order with
//       an explicit sequential pivot on the correlation-scaled Gram matrix,
//       pivot_j = 1 - g' inv(G_kept) g = 1 - R2 of column j on the kept ones,
//       so later columns are the ones omitted (as in regress).
real rowvector xtgls2_keep(real matrix Xs, real matrix Xraw)
{
	real rowvector ssr, sst, keep, ix, kk
	real matrix G, Gs
	real colvector d, g
	real scalar k, j, piv
	k   = cols(Xs)
	ssr = colsum(Xraw :^ 2)
	sst = colsum(Xs :^ 2)
	keep = (sst :> 1e-24 * ssr) :& (ssr :> 0)
	ix = select(1..k, keep)
	if (length(ix) == 0) return(keep)
	G  = cross(Xs[., ix], Xs[., ix])
	d  = sqrt(diagonal(G))
	Gs = G :/ (d * d')
	kk = J(1, 0, .)
	for (j=1; j<=cols(Gs); j++) {
		if (length(kk) == 0) piv = 1
		else {
			g   = Gs[kk, j]
			piv = 1 - g' * invsym(Gs[kk, kk]) * g
		}
		if (piv > 1e-10) kk = (kk, j)
		else keep[1, ix[j]] = 0
	}
	return(keep)
}

// RSS of y on X by SVD-based projection, and rank(X); used by the RE first step
void xtgls2_proj(real matrix X, real colvector y, real scalar rss, real scalar kr)
{
	real rowvector nrm
	real matrix Xn
	if (cols(X) == 0) {
		rss = sum(y :^ 2)
		kr  = 0
		return
	}
	nrm = sqrt(colsum(X :^ 2))
	nrm = nrm + (nrm :== 0)
	Xn  = X :/ nrm
	kr  = rank(Xn)
	rss = sum((y - Xn * pinv(Xn) * y) :^ 2)
}

// Omega_hat = N^-1 sum_i u_i u_i'   (u t-major, To periods)
real matrix xtgls2_omega(real colvector u, real scalar N, real scalar To)
{
	real matrix U, Om
	U  = rowshape(u, To)
	Om = U * U' / N
	Om = (Om + Om') / 2
	return(Om)
}

// descriptive R-squared = squared (weighted) correlation
real scalar xtgls2_r2(real colvector a, real colvector b, real colvector w)
{
	real scalar sw, ma, mb, cab, vaa, vbb
	sw  = sum(w)
	ma  = sum(w :* a) / sw
	mb  = sum(w :* b) / sw
	cab = sum(w :* (a :- ma) :* (b :- mb))
	vaa = sum(w :* (a :- ma) :^ 2)
	vbb = sum(w :* (b :- mb) :^ 2)
	if (vaa <= 0 | vbb <= 0) return(.)
	return(cab^2 / (vaa * vbb))
}

// First step of RE-GLS: one-way random effects, Swamy-Arora variance components
// (same formulas as -xtreg, re-).  Returns residuals v = y - X b_RE.
real scalar xtgls2_re(real colvector y, real matrix X, real scalar N, real scalar T,
	real scalar cpos, real matrix v, real matrix b,
	real scalar sige, real scalar sigu, real scalar theta)
{
	real scalar k, j, Kw, Kb, rssw, rssb, se2, sB2, sc2, NT
	real matrix Xwd, Xb, Xq
	real colvector yb, ywd, yq
	real rowvector ix

	NT = N * T
	k  = cols(X)

	// between quantities
	yb = mean(rowshape(y, T))'
	Xb = J(N, k, .)
	for (j=1; j<=k; j++) Xb[., j] = mean(rowshape(X[., j], T))'

	// within regression on the slope columns
	if (cpos == 0) ix = 1..k
	else           ix = select(1..k, (1..k) :!= cpos)
	ywd = xtgls2_dmv(y, T)
	if (length(ix) > 0) {
		Xwd = xtgls2_dm(X[., ix], T)
		Xwd = Xwd :* xtgls2_keep(Xwd, X[., ix])		// time-invariant columns -> exactly 0
		xtgls2_proj(Xwd, ywd, rssw, Kw)
	}
	else {
		rssw = sum(ywd :^ 2)
		Kw   = 0
	}
	if (NT - N - Kw <= 0) {
		xtgls2_fail("re: not enough degrees of freedom to estimate sigma_e", 498)
		return(1)
	}
	se2 = rssw / (NT - N - Kw)

	// between regression (with constant, if any)
	xtgls2_proj(Xb, yb, rssb, Kb)
	if (N - Kb <= 0) {
		xtgls2_fail("re: too few panels to run the between regression", 498)
		return(1)
	}
	sB2  = rssb / (N - Kb)
	sc2  = max((0, sB2 - se2 / T))
	if (sc2 > 0) theta = 1 - sqrt(se2 / (se2 + T * sc2))
	else         theta = 0

	// RE estimator = OLS on quasi-demeaned data
	yq = y - theta * xtgls2_exp(yb, T)
	Xq = X
	for (j=1; j<=k; j++) Xq[., j] = X[., j] - theta * xtgls2_exp(Xb[., j], T)
	b  = invsym(cross(Xq, Xq)) * cross(Xq, yq)
	v  = y - X * b
	sige = sqrt(se2)
	sigu = sqrt(sc2)
	return(0)
}


void xtgls2_main(string scalar ydep, string scalar xvars, string scalar tnames, string scalar touse,
	string scalar ivar, string scalar tvar, string scalar wvar, string scalar clvar,
	real scalar model, real scalar hascons, real scalar wtype,
	real scalar dorobust, real scalar igls, real scalar maxit, real scalar tol,
	real scalar nmk, real scalar dolog, real scalar tdelta,
	string scalar nb, string scalar nV, string scalar nS,
	string scalar nkept, string scalar ninfo)
{
	real scalar N, T, To, Tu, k, ncol, nobs, iter, diff, conv, cpos, Gc, adj
	real scalar chi2, df, ll, qf, lnd, sige, sigu, theta, tgap, nclust, ncv
	real scalar r2o, r2w, r2b, t, i
	real matrix idt, X0, X, Xw, Xs, A, Om, Wm, Z, Ainv, V, B, S, pinfo, tmat
	real matrix wmat, cmat, cinfo, Vs, Vsi, Sig, sc
	real colvector p, y0, Y, wv, cl, wn, sw, rr, clunit, Ti, yw, ys, b, b0, bprev
	real colvector u, Wu, xb, cs, o, wm, yb, xbm, sv, bs, bad
	real rowvector keep, ix, tref, sl, vals
	string rowvector names, tn
	real scalar nnote, itpr, j
	string scalar msg
	real colvector ib

	// ---- read ----------------------------------------------------------
	idt = st_data(., (ivar, tvar), touse)
	if (rows(idt) == 0) {
		xtgls2_fail("no observations", 2000)
		return
	}
	y0 = st_data(., ydep, touse)
	X0 = st_data(., tokens(xvars), touse)
	if (wtype > 0) wv = st_data(., wvar, touse)
	else           wv = J(rows(y0), 1, 1)
	if (clvar != "") cl = st_data(., clvar, touse)
	else             cl = J(rows(y0), 1, 1)

	// ---- sort and strict balance check ----------------------------------
	p   = order(idt, (1, 2))
	idt = idt[p, .]
	y0  = y0[p]
	X0  = X0[p, .]
	wv  = wv[p]
	cl  = cl[p]

	pinfo = panelsetup(idt, 1)
	N  = rows(pinfo)
	Ti = pinfo[., 2] - pinfo[., 1] :+ 1
	T  = Ti[1]
	if (min(Ti) != max(Ti)) {
		msg = "panels must be balanced: the number of observations per panel ranges from " + strofreal(min(Ti)) + " to " + strofreal(max(Ti))
		msg = msg + " in the estimation sample (check missing values, if/in and weights)"
		xtgls2_fail(msg, 459)
		return
	}
	if (T < 2) {
		xtgls2_fail("at least 2 time periods per panel are required", 459)
		return
	}
	tmat = rowshape(idt[., 2], N)
	bad  = (rowsum(tmat :!= tmat[1, .]) :> 0)
	if (any(bad)) {
		ib = select(1::N, bad)
		i  = ib[1]
		msg = "panels must be balanced: every panel must have the same set of time values, but panel " + strofreal(idt[pinfo[i, 1], 1])
		msg = msg + " differs from the first panel (" + strofreal(sum(bad)) + " panel(s) differ; check missing values, if/in and weights)"
		xtgls2_fail(msg, 459)
		return
	}
	tref = tmat[1, .]
	tgap = any(abs((tref[2..T] - tref[1..(T-1)]) :- tdelta) :> 1e-8 * max((1, abs(tdelta))))

	// weights must be constant within panel unless it is aweight with pgls
	if (wtype > 0) {
		wmat = rowshape(wv, N)
		if ((wtype == 2 | model != 1) & any(rowmax(wmat) :!= rowmin(wmat))) {
			xtgls2_fail("weights must be constant within panel with pweight, fe, fd and re (only aweight with pgls may vary within panel)", 407)
			return
		}
	}
	if (clvar != "") {
		cmat = rowshape(cl, N)
		if (any(rowmax(cmat) :!= rowmin(cmat))) {
			xtgls2_fail("cluster() variable must be constant within panel", 459)
			return
		}
		clunit = cmat[., 1]
	}
	else clunit = (1::N)

	// ---- t-major layout ---------------------------------------------------
	rr = xtgls2_tperm(N, T)
	Y  = y0[rr]
	X  = X0[rr, .]
	wv = wv[rr]
	if (hascons) X = (X, J(rows(X), 1, 1))
	if (wtype > 0) wn = wv :/ mean(wv)
	else           wn = J(rows(Y), 1, 1)
	sw   = sqrt(wn)
	ncol = cols(X)

	// ---- transformation ---------------------------------------------------
	Xw = X :* sw
	yw = Y :* sw
	if      (model == 3) A = xtgls2_helmert(T)
	else if (model == 4) A = xtgls2_fd(T)
	else                 A = I(T)
	To = rows(A)
	Tu = (model == 4 ? T - 1 : T)
	if (model <= 2) {
		Xs = Xw
		ys = yw
	}
	else {
		Xs = xtgls2_kron(A, Xw, N)
		ys = xtgls2_kron(A, yw, N)
	}

	// pgls and re apply no transformation: the factor/collinearity screening done by
	// _rmcoll before the call is complete, so nothing more is dropped here
	if (model <= 2) keep = J(1, ncol, 1)
	else            keep = xtgls2_keep(Xs, Xw)
	ix   = select(1..ncol, keep)
	k    = length(ix)
	if (k == 0) {
		xtgls2_fail("no regressors left after removing collinear variables", 498)
		return
	}
	// ---- notes (before any iteration output) -----------------------------
	tn = tokens(tnames)
	if (hascons) tn = (tn, "_cons")
	nnote = sum(keep :== 0) + (model == 4 & tgap)
	if (nnote > 0) {
		printf("\n")
		for (j=1; j<=ncol; j++) {
			if (keep[j] == 0) {
				printf("{txt}note: {bf:%s} omitted because of collinearity (after the %s transformation)\n", tn[j], (model == 3 ? "fe" : "fd"))
			}
		}
		if (model == 4 & tgap) printf("{txt}note: time periods are not equally spaced; first differences are taken between consecutive observed periods\n")
	}
	X  = X[., ix]
	Xw = Xw[., ix]
	Xs = Xs[., ix]
	cpos = 0
	if (hascons) {
		if (keep[ncol]) cpos = k
	}
	if (N < To) {
		msg = "Omega is To x To and needs at least as many panels as time periods used (N = " + strofreal(N) + " < " + strofreal(To) + "): Omega would be singular"
		xtgls2_fail(msg, 498)
		return
	}

	// ---- first step: residuals used to build Omega ------------------------
	sige = .; sigu = .; theta = .
	if (model == 2) {
		if (xtgls2_re(Y, X, N, T, cpos, u, b0, sige, sigu, theta)) return
	}
	else {
		b0 = invsym(cross(Xs, Xs)) * cross(Xs, ys)
		u  = ys - Xs * b0
	}

	// ---- (iterated) GLS ---------------------------------------------------
	iter = 0
	itpr = 0
	diff = tol + 1
	while (iter < maxit & diff > tol) {
		if (!igls) diff = 0

		Om = xtgls2_omega(u, N, To)
		Wm = invsym(Om)
		if (any(diagonal(Wm) :== 0)) {
			xtgls2_fail("the estimated error covariance matrix is singular", 498)
			return
		}
		Z    = xtgls2_kron(Wm, (Xs, ys), N)
		Ainv = invsym(cross(Xs, Z[., 1..k]))
		if (any(diagonal(Ainv) :== 0)) {
			xtgls2_fail("X'inv(Omega)X is singular: the regressors are collinear", 498)
			return
		}
		b = Ainv * cross(Xs, Z[., k+1])

		if (iter > 0) {
			diff = mreldif(b, bprev)
			if (dolog) {
				if (itpr == 0) {
					printf("\n")
					itpr = 1
				}
				printf("{txt}Iteration %g:  tolerance = {res}%12.7g\n", iter, diff)
			}
		}
		bprev = b
		u     = ys - Xs * b
		iter  = iter + 1
	}
	conv = (diff <= tol)
	if (!conv) {
		if (itpr == 0) printf("\n")
		printf("{err}convergence not achieved\n")
	}

	// ---- variance ---------------------------------------------------------
	nobs = N * Tu
	if (dorobust) {
		Wu = xtgls2_kron(Wm, u, N)
		S  = Xs :* Wu
		sc = J(N, k, 0)
		for (t=1; t<=To; t++) sc = sc + S[|(t-1)*N+1, 1 \ t*N, k|]
		o     = order(clunit, 1)
		cs    = clunit[o]
		sc    = sc[o, .]
		cinfo = panelsetup(cs, 1)
		Gc    = rows(cinfo)
		if (Gc < 2) {
			xtgls2_fail("at least 2 clusters are required for robust standard errors", 498)
			return
		}
		B = J(k, k, 0)
		for (i=1; i<=Gc; i++) {
			sv = colsum(panelsubmatrix(sc, i, cinfo))'
			B  = B + sv * sv'
		}
		adj = Gc / (Gc - 1)
		if (nmk) adj = adj * (nobs - 1) / (nobs - k)
		V = adj * Ainv * B * Ainv
		nclust = Gc
	}
	else {
		V = Ainv
		if (nmk) V = V * nobs / (nobs - k)
		nclust = .
	}
	V = (V + V') / 2

	// ---- Wald test of all slopes -----------------------------------------
	chi2 = .; df = 0
	if (cpos == 0) sl = 1..k
	else           sl = select(1..k, (1..k) :!= cpos)
	if (length(sl) > 0) {
		bs  = b[sl, 1]
		Vs  = V[sl, sl]
		Vsi = invsym(Vs)
		chi2 = bs' * Vsi * bs
		df   = sum(diagonal(Vsi) :!= 0)
	}

	// ---- log likelihood (as -xtgls- : only for iterated GLS, no weights) --
	ll = .
	if (igls & wtype == 0) {
		qf  = sum(u :* xtgls2_kron(Wm, u, N))
		lnd = 2 * sum(ln(diagonal(cholesky(Om))))
		ll  = -0.5 * (N * To * ln(2 * pi()) + N * lnd + qf)
	}

	// ---- descriptive R-squared on the original data -----------------------
	xb  = X * b
	r2o = xtgls2_r2(Y, xb, wn)
	r2w = xtgls2_r2(xtgls2_dmv(Y, T), xtgls2_dmv(xb, T), wn)
	yb  = mean(rowshape(Y, T))'
	xbm = mean(rowshape(xb, T))'
	wm  = mean(rowshape(wn, T))'
	r2b = xtgls2_r2(yb, xbm, wm)

	// ---- Sigma reported in the original T x T basis for fe ----------------
	if (model == 3) Sig = A' * Om * A
	else            Sig = Om
	ncv = To * (To + 1) / 2

	// ---- return to Stata ---------------------------------------------------
	vals  = (nobs, N, Tu, To, ncv, k, df, nobs - ncv - k, chi2, k, ll,
		(igls ? N * To : .), (igls ? ncv + k : .), (conv ? 0 : 430),
		r2o, r2w, r2b, nclust, iter, sige, sigu, theta, tgap)
	names = ("N", "N_g", "N_t", "T_o", "n_cv", "n_cf", "df", "df_pear", "chi2",
		"rank", "ll", "N_ic", "df_ic", "rc", "r2_o", "r2_w", "r2_b", "N_clust",
		"iterations", "sigma_e", "sigma_u", "theta", "tgap")
	st_matrix(ninfo, vals)
	st_matrixcolstripe(ninfo, (J(cols(names), 1, ""), names'))
	st_matrix(nb, b')
	st_matrix(nV, V)
	st_matrix(nS, Sig)
	st_matrix(nkept, keep)
}

end
