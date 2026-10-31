*! version 1.0.0  21oct2026  Yusuf Toyin Yusuf (Kwara State University)
*! polysem: confirmatory factor analysis of ordinal (and mixed) indicators by
*! diagonally weighted least squares on polychoric correlations, with robust
*! (sandwich) standard errors and mean- and variance-adjusted test statistics.
*! Requires polycorr.

program define polysem, eclass
	version 14

	if replay() {
		if `"`e(cmd)'"' != "polysem" error 301
		Display `0'
		exit
	}
	local cmdline `"polysem `0'"'

	capture which polycorr
	if _rc {
		di as err "polysem requires polycorr; type {bf:net install polycorr}"
		exit 199
	}

	* ------------------------------------------- factor specifications
	local m 0
	local allv
	while 1 {
		local 0 = strtrim(`"`0'"')
		if substr(`"`0'"', 1, 1) != "(" continue, break
		gettoken spec 0 : 0, match(par)
		gettoken fname rest : spec, parse(":")
		local fname = strtrim(`"`fname'"')
		gettoken colon rest : rest, parse(":")
		if "`colon'" != ":" {
			di as err "factor specification must have the form (name: varlist)"
			exit 198
		}
		confirm name `fname'
		unab ivars : `rest'
		local nind : word count `ivars'
		local ++m
		local f`m' `fname'
		local v`m' `ivars'
		local allv `allv' `ivars'
		local fnames `fnames' `fname'
	}
	if `m' == 0 {
		di as err "no factor specifications found; use (name: varlist) ..."
		exit 198
	}
	local dupf : list dups fnames
	if "`dupf'" != "" {
		di as err "factor name(s) repeated: `dupf'"
		exit 198
	}
	local allv : list uniq allv
	local k : word count `allv'

	syntax [if] [in] [fweight aweight pweight iweight] ///
		[, ESTimator(string) ORTHogonal vce(passthru) SVY PAIRwise    ///
		   CATmax(passthru) ORDinal(passthru) CONTinuous(passthru)      ///
		   Level(cilevel) ITERate(integer 500) TOLerance(real 1e-10) ]

	if "`estimator'" == "" local estimator dwls
	local estimator = lower("`estimator'")
	if !inlist("`estimator'", "dwls", "uls", "wls") {
		di as err "estimator() must be dwls, uls or wls"
		exit 198
	}
	forvalues f = 1/`m' {
		local nind : word count `v`f''
		if `nind' < 2 | (`m' == 1 & `nind' < 3) {
			di as err "factor `f`f'' needs at least " cond(`m' == 1, "3", "2") " indicators"
			exit 459
		}
	}

	* ------------------------------------------- polychoric step
	local wgt
	if "`weight'" != "" local wgt "[`weight'`exp']"
	quietly polycorr `allv' `if' `in' `wgt', `vce' `svy' `pairwise' ///
		`catmax' `ordinal' `continuous' notable
	if "`e(vce)'" == "none" {
		di as err "polycorr returned no covariance matrix"
		exit 498
	}
	tempname r V Pat b Vb L Phi Th Res
	tempvar touse
	matrix `r' = e(b)
	matrix `V' = e(V)
	local N      = e(N)
	local types  `e(types)'
	local pvce   `e(vce)'
	local pvcet  `e(vcetype)'
	local pclust `e(clustvar)'
	local Nclust = e(N_clust)
	local dfr    = e(df_r)
	quietly gen byte `touse' = e(sample)
	mata: st_local("nmiss", strofreal(missing(st_matrix("`r'"))))
	if `nmiss' > 0 {
		di as err "some correlations could not be estimated; see {bf:polycorr}"
		exit 498
	}

	matrix `Pat' = J(`k', `m', 0)
	forvalues f = 1/`m' {
		foreach v of local v`f' {
			local j : list posof "`v'" in allv
			matrix `Pat'[`j', `f'] = 1
		}
	}

	* ------------------------------------------- DWLS / ULS / WLS
	local orth = ("`orthogonal'" != "")
	mata: ps_fit("`r'", "`V'", "`Pat'", `orth', "`estimator'", `iterate', ///
		`tolerance', `N', "`b'", "`Vb'", "`L'", "`Phi'", "`Th'", "`Res'")

	* ------------------------------------------- stripes
	local cn
	forvalues f = 1/`m' {
		forvalues j = 1/`k' {
			if `Pat'[`j', `f'] {
				local v : word `j' of `allv'
				local cn `cn' `f`f'':`v'
			}
		}
	}
	if !`orth' & `m' > 1 {
		forvalues f = 1/`=`m'-1' {
			forvalues g = `=`f'+1'/`m' {
				local nm `f`f''_`f`g''
				if length("`nm'") > 32 local nm phi`f'_`g'
				local cn `cn' corr:`nm'
			}
		}
	}
	matrix colnames `b'  = `cn'
	matrix colnames `Vb' = `cn'
	matrix rownames `Vb' = `cn'
	matrix rownames `L'   = `allv'
	matrix colnames `L'   = `fnames'
	matrix rownames `Phi' = `fnames'
	matrix colnames `Phi' = `fnames'
	matrix rownames `Th'  = `allv'
	matrix colnames `Th'  = uniqueness
	matrix rownames `Res' = `allv'
	matrix colnames `Res' = `allv'

	if "`pvce'" == "svy" ereturn post `b' `Vb', esample(`touse') obs(`N') dof(`dfr')
	else                 ereturn post `b' `Vb', esample(`touse') obs(`N')

	ereturn scalar k_var    = `k'
	ereturn scalar k_factor = `m'
	ereturn scalar iter     = `ps_iter'
	ereturn scalar converged = `ps_conv'
	ereturn scalar chi2     = `ps_Tmv'
	ereturn scalar df_m     = `ps_df'
	ereturn scalar p        = `ps_pmv'
	ereturn scalar chi2_ms  = `ps_Tm'
	ereturn scalar p_ms     = `ps_pm'
	ereturn scalar chi2_raw = `ps_T'
	ereturn scalar chi2_bs  = `ps_TBmv'
	ereturn scalar df_bs    = `ps_dfB'
	ereturn scalar cfi      = `ps_cfi'
	ereturn scalar tli      = `ps_tli'
	ereturn scalar rmsea    = `ps_rmsea'
	ereturn scalar srmr     = `ps_srmr'
	ereturn scalar heywood  = `ps_heywood'
	ereturn scalar level    = `level'
	if "`pvce'" == "cluster" ereturn scalar N_clust = `Nclust'

	ereturn local factors   "`fnames'"
	forvalues f = 1/`m' {
		ereturn local ind`f' "`v`f''"
	}
	ereturn local indicators "`allv'"
	ereturn local types     "`types'"
	ereturn local estimator "`estimator'"
	ereturn local vce       "`pvce'"
	ereturn local vcetype   "`pvcet'"
	if "`pclust'" != "" ereturn local clustvar "`pclust'"
	if `orth' ereturn local structure "orthogonal"
	else      ereturn local structure "oblique"
	if "`weight'" != "" {
		ereturn local wtype "`weight'"
		ereturn local wexp  `"`exp'"'
	}
	ereturn local title   "Ordinal confirmatory factor analysis (polychoric `=upper("`estimator'")')"
	ereturn local cmdline `"`cmdline'"'
	ereturn matrix Lambda = `L'
	ereturn matrix Phi    = `Phi'
	ereturn matrix Theta  = `Th'
	ereturn matrix resid  = `Res'
	ereturn local cmd "polysem"

	Display, level(`level')
end

program define Display
	syntax [, Level(cilevel)]
	di
	di as txt "`e(title)'" _col(54) "Number of obs" _col(68) "= " as res %9.0fc e(N)
	di as txt "Indicators: " as res e(k_var) as txt "   Factors: " as res e(k_factor) ///
		as txt "  (`e(structure)')" _col(54) "Iterations" _col(68) "= " as res %9.0f e(iter)
	if "`e(vce)'" == "cluster" {
		di as txt "Std. err. adjusted for " as res e(N_clust) as txt " clusters in `e(clustvar)'"
	}
	ereturn display, level(`level')
	di as txt "Model fit" _col(30) "statistic" _col(44) "df" _col(52) "p-value"
	di as txt "{hline 62}"
	di as txt "Mean- and variance-adjusted" _col(28) as res %11.3f e(chi2) _col(40) %6.0f e(df_m) _col(50) %9.4f e(p)
	di as txt "Mean-adjusted (scaled)" _col(28) as res %11.3f e(chi2_ms) _col(40) %6.0f e(df_m) _col(50) %9.4f e(p_ms)
	di as txt "Baseline (adjusted)" _col(28) as res %11.3f e(chi2_bs) _col(40) %6.0f e(df_bs)
	di as txt "{hline 62}"
	di as txt "CFI = " as res %6.4f e(cfi) as txt "   TLI = " as res %6.4f e(tli) ///
		as txt "   RMSEA = " as res %6.4f e(rmsea) as txt "   SRMR = " as res %6.4f e(srmr)
	if e(heywood) > 0 {
		di as err "warning: " e(heywood) " negative uniqueness(es) (Heywood case); see e(Theta)"
	}
	if !e(converged) di as err "warning: convergence not achieved"
end

version 14
capture mata: mata drop ps_*()
mata:
mata set matastrict on

void ps_sigdelta(real colvector th, real matrix Lidx, real matrix FG,
                 real scalar k, real scalar m, real colvector s, real matrix D)
{
	real matrix L, Phi, S, LP
	real scalar nl, nf, q, p, i, j, a, f, g

	nl  = rows(Lidx)
	nf  = rows(FG)
	L   = J(k, m, 0)
	for (q = 1; q <= nl; q++) L[Lidx[q, 1], Lidx[q, 2]] = th[q]
	Phi = I(m)
	for (q = 1; q <= nf; q++) {
		Phi[FG[q, 1], FG[q, 2]] = th[nl + q]
		Phi[FG[q, 2], FG[q, 1]] = th[nl + q]
	}
	S  = L * Phi * L'
	LP = L * Phi
	s  = J(k*(k - 1)/2, 1, .)
	D  = J(k*(k - 1)/2, nl + nf, 0)
	p  = 0
	for (i = 1; i <= k - 1; i++) {
		for (j = i + 1; j <= k; j++) {
			p++
			s[p] = S[i, j]
			for (q = 1; q <= nl; q++) {
				a = Lidx[q, 1]
				f = Lidx[q, 2]
				if (a == i) D[p, q] = D[p, q] + LP[j, f]
				if (a == j) D[p, q] = D[p, q] + LP[i, f]
			}
			for (q = 1; q <= nf; q++) {
				f = FG[q, 1]
				g = FG[q, 2]
				D[p, nl + q] = L[i, f]*L[j, g] + L[i, g]*L[j, f]
			}
		}
	}
}

real scalar ps_obj(real colvector r, real matrix W, real colvector th, real matrix Lidx,
                   real matrix FG, real scalar k, real scalar m)
{
	real colvector s, e
	real matrix D
	ps_sigdelta(th, Lidx, FG, k, m, s, D)
	e = r - s
	return(e' * W * e)
}

void ps_fit(string scalar rn, string scalar vn, string scalar patn, real scalar orth,
            string scalar est, real scalar maxit, real scalar tol, real scalar N,
            string scalar bn, string scalar vbn, string scalar ln, string scalar phn,
            string scalar thn, string scalar ren)
{
	real colvector r, th, s, e, step, uq
	real matrix V, Pat, W, D, A, Acov, U, UV, Lidx, FG, L, Phi, Res, S, WB
	real scalar k, m, P, nl, nf, q, it, F0, t, T, df, tr1, tr2, a, bsh, Tmv, Tm
	real scalar TB, dfB, aB, bB, TBmv, cfi, tli, rmsea, srmr, i, j, p, f, g, conv

	r   = st_matrix(rn)'
	V   = st_matrix(vn)
	Pat = st_matrix(patn)
	k   = rows(Pat)
	m   = cols(Pat)
	P   = rows(r)

	Lidx = J(0, 2, .)
	for (f = 1; f <= m; f++) {
		for (i = 1; i <= k; i++) {
			if (Pat[i, f]) Lidx = Lidx \ (i, f)
		}
	}
	FG = J(0, 2, .)
	if (!orth) {
		for (f = 1; f <= m - 1; f++) {
			for (g = f + 1; g <= m; g++) FG = FG \ (f, g)
		}
	}
	nl = rows(Lidx)
	nf = rows(FG)
	q  = nl + nf
	df = P - q
	if (df < 0) {
		errprintf("model is not identified: %g parameters, %g correlations\n", q, P)
		exit(459)
	}

	if (est == "dwls")     W = diag(1 :/ diagonal(V))
	else if (est == "uls") W = I(P)
	else {
		W = invsym(V)
		if (diag0cnt(W) > 0) {
			errprintf("e(V) is singular; WLS is not available, use DWLS\n")
			exit(506)
		}
	}

	th   = J(nl, 1, 0.7) \ J(nf, 1, 0)
	conv = 0
	for (it = 1; it <= maxit; it++) {
		ps_sigdelta(th, Lidx, FG, k, m, s, D)
		e    = r - s
		F0   = e' * W * e
		step = lusolve(D' * W * D, D' * W * e)
		if (hasmissing(step)) break
		t = 1
		while (t > 1e-8) {
			if (ps_obj(r, W, th + t*step, Lidx, FG, k, m) <= F0) break
			t = t/2
		}
		th = th + t*step
		if (max(abs(t*step)) < tol) {
			conv = 1
			break
		}
	}
	if (it > maxit) it = maxit

	ps_sigdelta(th, Lidx, FG, k, m, s, D)
	e    = r - s
	A    = invsym(D' * W * D)
	Acov = A * D' * W * V * W * D * A
	Acov = (Acov + Acov')/2

	/* residual-based statistic and its moment adjustments */
	T   = e' * W * e
	U   = W - W * D * A * D' * W
	UV  = U * V
	tr1 = trace(UV)
	tr2 = trace(UV * UV)
	if (df > 0) {
		a   = sqrt(df / tr2)
		bsh = df - a * tr1
		Tmv = a * T + bsh
		Tm  = T * df / tr1
	}
	else {
		Tmv = 0
		Tm  = 0
	}

	/* baseline: all correlations zero */
	WB   = W
	TB   = r' * WB * r
	dfB  = P
	aB   = sqrt(dfB / trace(WB * V * WB * V))
	bB   = dfB - aB * trace(WB * V)
	TBmv = aB * TB + bB

	cfi   = 1 - max((Tmv - df, 0)) / max((Tmv - df, TBmv - dfB, 1e-12))
	tli   = ((TBmv/dfB) - (df > 0 ? Tmv/df : 1)) / ((TBmv/dfB) - 1)
	rmsea = (df > 0 ? sqrt(max((0, (Tmv - df)/(df*(N - 1))))) : 0)
	srmr  = sqrt(sum(e:^2) / (P + k))

	/* Lambda, Phi, uniquenesses, residual matrix */
	L = J(k, m, 0)
	for (q = 1; q <= nl; q++) L[Lidx[q, 1], Lidx[q, 2]] = th[q]
	Phi = I(m)
	for (q = 1; q <= nf; q++) {
		Phi[FG[q, 1], FG[q, 2]] = th[nl + q]
		Phi[FG[q, 2], FG[q, 1]] = th[nl + q]
	}
	S  = L * Phi * L'
	uq = 1 :- diagonal(S)
	Res = J(k, k, 0)
	p = 0
	for (i = 1; i <= k - 1; i++) {
		for (j = i + 1; j <= k; j++) {
			p++
			Res[i, j] = e[p]
			Res[j, i] = e[p]
		}
	}

	st_matrix(bn, th')
	st_matrix(vbn, Acov)
	st_matrix(ln, L)
	st_matrix(phn, Phi)
	st_matrix(thn, uq)
	st_matrix(ren, Res)
	st_local("ps_iter",    strofreal(it))
	st_local("ps_conv",    strofreal(conv))
	st_local("ps_T",       strofreal(T, "%21.0g"))
	st_local("ps_Tmv",     strofreal(Tmv, "%21.0g"))
	st_local("ps_Tm",      strofreal(Tm, "%21.0g"))
	st_local("ps_df",      strofreal(df))
	st_local("ps_pmv",     strofreal(df > 0 ? chi2tail(df, Tmv) : ., "%21.0g"))
	st_local("ps_pm",      strofreal(df > 0 ? chi2tail(df, Tm) : ., "%21.0g"))
	st_local("ps_TBmv",    strofreal(TBmv, "%21.0g"))
	st_local("ps_dfB",     strofreal(dfB))
	st_local("ps_cfi",     strofreal(cfi, "%21.0g"))
	st_local("ps_tli",     strofreal(tli, "%21.0g"))
	st_local("ps_rmsea",   strofreal(rmsea, "%21.0g"))
	st_local("ps_srmr",    strofreal(srmr, "%21.0g"))
	st_local("ps_heywood", strofreal(sum(uq :< 0)))
}

end
