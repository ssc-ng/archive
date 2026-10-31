*! version 1.1.1  21oct2026  Yusuf Toyin Yusuf (Kwara State University)
*! polyindex: polychoric principal-component / factor index (e.g. asset or
*! wealth index) with quantile groups, bootstrap loading standard errors,
*! household-level score standard errors, ranking-stability diagnostics and
*! comparison with MCA and raw-variable PCA indices.

program define polyindex, rclass
	version 14

	syntax varlist(numeric min=2) [if] [in] [fweight aweight pweight] ///
		[, GENerate(name) NCOMP(integer 1) METHod(string) ROTate(string) ///
		   Quantiles(integer 0) QGENerate(name) REPS(integer 0) SEED(string) ///
		   CLuster(varname) SCOREse(name) COMPare(string)                     ///
		   CATmax(integer 10) ORDinal(varlist numeric)                        ///
		   CONTinuous(varlist numeric) PDfix REPLACE noDOTS ]

	local k : word count `varlist'
	if "`method'" == "" local method pca
	local method = lower("`method'")
	if !inlist("`method'", "pca", "fa") {
		di as err "method() must be pca or fa"
		exit 198
	}
	if "`rotate'" == "" local rotate none
	local rotate = lower("`rotate'")
	if !inlist("`rotate'", "none", "varimax") {
		di as err "rotate() must be none or varimax"
		exit 198
	}
	if "`rotate'" == "varimax" & "`method'" != "fa" {
		di as err "rotate(varimax) requires method(fa)"
		exit 198
	}
	if `ncomp' < 1 | `ncomp' > `k' - ("`method'" == "fa") {
		di as err "ncomp() out of range"
		exit 198
	}
	if `quantiles' == 1 | `quantiles' < 0 {
		di as err "quantiles() must be 0 (none) or at least 2"
		exit 198
	}
	if `quantiles' > 1 & "`qgenerate'" == "" {
		di as err "quantiles() requires qgenerate()"
		exit 198
	}
	if `reps' < 0 {
		di as err "reps() must be nonnegative"
		exit 198
	}
	if "`scorese'" != "" & `reps' < 2 {
		di as err "scorese() requires reps() of at least 2"
		exit 198
	}
	if `reps' > 0 & `reps' < 20 {
		di as txt "(note: reps() below 20 gives unreliable summaries)"
	}
	local compare = lower("`compare'")
	foreach c of local compare {
		if !inlist("`c'", "mca", "pca") {
			di as err "compare() may contain mca and/or pca"
			exit 198
		}
	}
	if "`generate'" != "" {
		forvalues c = 1/`ncomp' {
			if "`replace'" != "" capture drop `generate'`c'
			confirm new variable `generate'`c'
		}
	}
	foreach nv in qgenerate scorese {
		if "``nv''" != "" {
			if "`replace'" != "" capture drop ``nv''
			confirm new variable ``nv''
		}
	}
	if "`seed'" != "" set seed `seed'

	marksample touse
	if "`cluster'" != "" markout `touse' `cluster', strok
	local wgt
	if "`weight'" != "" local wgt "[`weight'`exp']"

	* --------------------------------------------- polychoric matrix
	local oopt = cond("`ordinal'" != "", "ordinal(`ordinal')", "")
	local copt = cond("`continuous'" != "", "continuous(`continuous')", "")
	quietly polycorr `varlist' if `touse' `wgt', catmax(`catmax') ///
		`oopt' `copt' novce `pdfix'

	tempname R tau cats mu sd ev L Wt U
	local types `e(types)'
	local ordl
	local conl
	forvalues j = 1/`k' {
		local t : word `j' of `types'
		local v : word `j' of `varlist'
		if "`t'" == "O" local ordl `ordl' `v'
		else            local conl `conl' `v'
	}
	local oopt = cond("`ordl'" != "", "ordinal(`ordl')", "")
	local copt = cond("`conl'" != "", "continuous(`conl')", "")
	local usedpd 0
	if "`pdfix'" != "" {
		matrix `R' = e(R_pd)
		local usedpd 1
	}
	else {
		matrix `R' = e(R)
		if !e(is_pd) {
			di as txt "(note: R is not positive definite; consider option pdfix)"
		}
	}
	matrix `tau'  = e(tau)
	matrix `cats' = e(cats)
	matrix `mu'   = e(mu)
	matrix `sd'   = e(sd)
	local N = e(N)

	* --------------------------------------------- PCA or factor model
	mata: pi_model("`R'", "`method'", `ncomp', "`rotate'", "`L'", "`Wt'", "`ev'", "`U'")
	local cn
	forvalues c = 1/`ncomp' {
		local cn `cn' comp`c'
	}
	matrix rownames `L'  = `varlist'
	matrix colnames `L'  = `cn'
	matrix rownames `Wt' = `varlist'
	matrix colnames `Wt' = `cn'
	local en
	forvalues c = 1/`k' {
		local en `en' ev`c'
	}
	matrix colnames `ev' = `en'

	local mlab = cond("`method'" == "pca", "Polychoric principal components", ///
		"Polychoric principal-axis factors" + cond("`rotate'" == "varimax", " (varimax)", ""))
	di
	di as txt "`mlab'" _col(51) "Number of obs" _col(67) "= " as res %10.0fc `N'
	di as txt "Correlation matrix: " as res cond(`usedpd', "nearest PD (pdfix)", "polychoric") ///
		_col(51) as txt "Variables" _col(67) "= " as res %10.0f `k'
	di as txt "{hline 58}"
	di as txt "Eigenvalue #" _col(15) "Eigenvalue" _col(30) "Proportion" _col(44) "Cumulative"
	di as txt "{hline 58}"
	local cum 0
	forvalues c = 1/`k' {
		local lam = `ev'[1, `c']
		local cum = `cum' + `lam'/`k'
		di as txt %4.0f `c' as res _col(15) %10.4f `lam' _col(30) %10.4f `lam'/`k' _col(44) %10.4f `cum'
	}
	di as txt "{hline 58}"

	* --------------------------------------------- scores and quantiles
	tempname cs0
	mata: pi_catscores("`cats'", "`tau'", "`cs0'")
	local newv
	forvalues c = 1/`ncomp' {
		if "`generate'" != "" local nm `generate'`c'
		else {
			tempvar t`c'
			local nm `t`c''
		}
		quietly gen double `nm' = .
		local newv `newv' `nm'
	}
	mata: pi_apply("`varlist'", "`touse'", "`cats'", "`cs0'", "`mu'", "`sd'", "`Wt'", "`newv'")
	local first : word 1 of `newv'
	if "`generate'" != "" {
		forvalues c = 1/`ncomp' {
			label variable `generate'`c' "Polychoric `method' score `c'"
		}
	}
	if `quantiles' > 1 {
		quietly xtile `qgenerate' = `first' if `touse' `wgt', nq(`quantiles')
		label variable `qgenerate' "Quantile group (`quantiles') of polychoric score 1"
	}

	* --------------------------------------------- bootstrap
	local repsok 0
	tempname B S
	if `reps' > 0 {
		local nq = cond(`quantiles' > 1, `quantiles', 5)
		matrix `B' = J(`reps', `k', .)
		matrix `S' = J(`reps', 2, .)
		tempvar sb acc1 acc2
		quietly gen double `sb' = .
		quietly gen double `acc1' = 0 if `touse'
		quietly gen double `acc2' = 0 if `touse'
		if "`dots'" == "" di as txt _n "Bootstrap replications (" as res `reps' as txt ")"
		forvalues r = 1/`reps' {
			tempname Rb taub catsb mub sdb Lb Wb evb Ub csb
			preserve
			quietly keep if `touse'
			if "`cluster'" != "" bsample, cluster(`cluster')
			else                 bsample
			capture quietly polycorr `varlist' `wgt', catmax(`catmax') ///
				`oopt' `copt' novce `pdfix'
			local rc = _rc
			if !`rc' {
				if `usedpd' matrix `Rb' = e(R_pd)
				else        matrix `Rb' = e(R)
				matrix `taub'  = e(tau)
				matrix `catsb' = e(cats)
				matrix `mub'   = e(mu)
				matrix `sdb'   = e(sd)
				capture mata: pi_model("`Rb'", "`method'", `ncomp', "`rotate'", "`Lb'", "`Wb'", "`evb'", "`Ub'")
				local rc = _rc
			}
			restore
			if `rc' {
				if "`dots'" == "" di as err "x" _c
				continue
			}
			mata: pi_align("`Lb'", "`Wb'", "`L'")
			mata: pi_catscores("`catsb'", "`taub'", "`csb'")
			mata: pi_mapcats("`cats'", "`cs0'", "`catsb'", "`csb'")
			quietly replace `sb' = .
			mata: pi_apply("`varlist'", "`touse'", "`cats'", "`csb'", "`mub'", "`sdb'", "`Wb'", "`sb'")
			mata: pi_compare("`first'", "`sb'", "`touse'", `nq', "`S'", `r')
			quietly replace `acc1' = `acc1' + `sb'   if `touse'
			quietly replace `acc2' = `acc2' + `sb'^2 if `touse'
			forvalues j = 1/`k' {
				matrix `B'[`r', `j'] = `Lb'[`j', 1]
			}
			local ++repsok
			if "`dots'" == "" di as txt "." _c
		}
		if "`dots'" == "" di
		if "`scorese'" != "" & `repsok' > 1 {
			quietly gen double `scorese' = ///
				sqrt(max(0, (`acc2' - `acc1'^2/`repsok')/(`repsok' - 1))) if `touse'
			label variable `scorese' "Bootstrap std. err. of polychoric score 1"
		}
		* leave the full-sample polycorr results in e()
		quietly polycorr `varlist' if `touse' `wgt', catmax(`catmax') ///
			`oopt' `copt' novce `pdfix'
	}

	* --------------------------------------------- loadings table
	tempname lse
	matrix `lse' = J(`k', 1, .)
	if `repsok' > 1 mata: pi_colsd("`B'", "`lse'")
	di
	di as txt cond("`method'" == "pca", "Loadings (eigenvectors)", "Factor loadings") ///
		cond(`repsok' > 1, "; bootstrap std. err. for column 1", "")
	di as txt "{hline 78}"
	di as txt "Variable" _col(14) "Type" _c
	local ncshow = min(`ncomp', 4)
	forvalues c = 1/`ncshow' {
		di as txt _col(`=12 + 10*`c'') %9s "comp`c'" _c
	}
	local colse = 24 + 10*`ncshow'
	if "`method'" == "fa" {
		di as txt _col(`colse') " uniqueness" _c
		local colse = `colse' + 12
	}
	if `repsok' > 1 di as txt _col(`colse') "  se(comp1)"
	else di
	di as txt "{hline 78}"
	forvalues j = 1/`k' {
		local v : word `j' of `varlist'
		local t : word `j' of `types'
		di as txt %-12s abbrev("`v'", 12) _col(14) cond("`t'" == "O", "ord", "cont") _c
		forvalues c = 1/`ncshow' {
			di as res _col(`=12 + 10*`c'') %9.4f `L'[`j', `c'] _c
		}
		local colse = 26 + 10*`ncshow'
		if "`method'" == "fa" {
			di as res _col(`colse') %9.4f `U'[`j', 1] _c
			local colse = `colse' + 12
		}
		if `repsok' > 1 di as res _col(`colse') %9.4f `lse'[`j', 1]
		else di
	}
	di as txt "{hline 78}"

	if `repsok' > 1 {
		tempname Sok
		mata: pi_dropmiss("`S'", "`Sok'")
		mata: pi_summ("`Sok'")
		di
		di as txt "Ranking stability of score 1 over " as res `repsok' as txt " bootstrap replications"
		di as txt "  Spearman correlation with full-sample score: mean " as res %6.4f `pi_sp_mean' ///
			as txt "  [2.5%, 97.5%] = [" as res %6.4f `pi_sp_lo' as txt ", " as res %6.4f `pi_sp_hi' as txt "]"
		di as txt "  Share of observations changing `nq'-quantile group: mean " as res %6.4f `pi_rc_mean' ///
			as txt "  [2.5%, 97.5%] = [" as res %6.4f `pi_rc_lo' as txt ", " as res %6.4f `pi_rc_hi' as txt "]"
		if "`scorese'" != "" {
			quietly summarize `scorese' if `touse', meanonly
			di as txt "  Household-level std. err. of score 1 stored in " as res "`scorese'" ///
				as txt " (mean " as res %6.4f r(mean) as txt ")"
		}
		return scalar spearman    = `pi_sp_mean'
		return scalar spearman_lo = `pi_sp_lo'
		return scalar spearman_hi = `pi_sp_hi'
		return scalar reclass     = `pi_rc_mean'
		return scalar reclass_lo  = `pi_rc_lo'
		return scalar reclass_hi  = `pi_rc_hi'
		matrix colnames `Sok' = spearman reclass
		return matrix stability = `Sok'
		matrix rownames `lse' = `varlist'
		matrix colnames `lse' = se_comp1
		return matrix load_se = `lse'
		matrix colnames `B' = `varlist'
		return matrix boot_load = `B'
	}

	* --------------------------------------------- comparison indices
	if "`compare'" != "" {
		di
		di as txt "Comparison with alternative indices (Spearman correlation with score 1)"
		di as txt "{hline 58}"
		foreach c of local compare {
			tempvar alt
			local ok 0
			if "`c'" == "pca" {
				capture {
					quietly pca `varlist' if `touse', components(1)
					quietly predict double `alt' if `touse', score
				}
				if !_rc local ok 1
				local lab "PCA on raw variables (Filmer-Pritchett)"
			}
			if "`c'" == "mca" {
				if "`ordl'" == "" {
					di as txt "  MCA: no ordinal variables; skipped"
					continue
				}
				capture {
					quietly mca `ordl' if `touse', dimensions(1)
					quietly predict double `alt' if `touse', dimensions(1)
				}
				if !_rc local ok 1
				local lab "MCA, dimension 1 (ordinal variables only)"
			}
			if `ok' {
				quietly spearman `first' `alt' if `touse'
				local rs = abs(r(rho))
				di as txt "  `lab'" _col(48) as res %8.4f `rs'
				return scalar rho_`c' = `rs'
			}
			else di as txt "  `lab'" _col(48) as err "failed"
		}
		di as txt "{hline 58}"
		di as txt "(absolute values; component signs are arbitrary; comparisons unweighted)"
	}

	return scalar N      = `N'
	return scalar k_var  = `k'
	return scalar ncomp  = `ncomp'
	return scalar reps   = `repsok'
	forvalues c = 1/`k' {
		return scalar lambda`c' = `ev'[1, `c']
	}
	return local  varlist "`varlist'"
	return local  types   "`types'"
	return local  method  "`method'"
	return local  rotate  "`rotate'"
	if "`generate'" != "" return local scores "`newv'"
	if "`method'" == "fa" {
		matrix rownames `U' = `varlist'
		matrix colnames `U' = uniqueness
		return matrix uniqueness = `U'
	}
	return matrix R           = `R'
	return matrix eigenvalues = `ev'
	return matrix weights     = `Wt'
	return matrix loadings    = `L'
end

version 14
capture mata: mata drop pi_*()
mata:
mata set matastrict on

/* eigen-decomposition with eigenvalues in descending order */
void pi_eigen(real matrix R, real matrix V, real rowvector lam)
{
	real colvector o
	symeigensystem(R, V, lam)
	o   = order(lam', -1)
	lam = lam[o']
	V   = V[., o']
}

/* Kaiser-normalized varimax rotation */
real matrix pi_varimax(real matrix L0)
{
	real matrix L, T, Lam, B, U, Vt
	real colvector h, s
	real scalar k, m, d, dold, it

	k = rows(L0)
	m = cols(L0)
	if (m < 2) return(L0)
	h = sqrt(rowsum(L0:^2))
	h = h + (h :<= 0)
	L = L0 :/ h
	T = I(m)
	d = 0
	for (it = 1; it <= 1000; it++) {
		Lam  = L * T
		B    = L' * (Lam:^3 - Lam * diag(colsum(Lam:^2)) / k)
		svd(B, U, s, Vt)
		T    = U * Vt
		dold = d
		d    = sum(s)
		if (d < dold * (1 + 1e-10)) break
	}
	return((L * T) :* h)
}

/* PCA or principal-axis factoring; L loadings, W scoring weights */
void pi_model(string scalar rn, string scalar method, real scalar m,
              string scalar rot, string scalar ln, string scalar wn,
              string scalar evn, string scalar un)
{
	real matrix R, V, Rh, Vh, L, W
	real rowvector lam, lh
	real colvector h, hold, u
	real scalar k, it, c

	R = st_matrix(rn)
	k = rows(R)
	pi_eigen(R, V, lam)
	if (method == "pca") {
		L = V[., (1..m)]
		W = L
		u = J(k, 1, .)
	}
	else {
		h = 1 :- 1 :/ diagonal(invsym(R))
		h = h :* (h :> 0) + 0.01 :* (h :<= 0)
		for (it = 1; it <= 500; it++) {
			hold = h
			Rh = R
			for (c = 1; c <= k; c++) Rh[c, c] = h[c]
			pi_eigen(Rh, Vh, lh)
			lh = lh[(1..m)]
			lh = lh :* (lh :> 0)
			L  = Vh[., (1..m)] :* sqrt(lh)
			h  = rowsum(L:^2)
			h = h :* (h :<= 0.995) + (0.995) :* (h :> 0.995)
			if (max(abs(h - hold)) < 1e-8) break
		}
		if (rot == "varimax") L = pi_varimax(L)
		u = 1 :- rowsum(L:^2)
		W = invsym(R) * L
	}
	for (c = 1; c <= m; c++) {
		if (sum(L[., c]) < 0) {
			L[., c] = -L[., c]
			W[., c] = -W[., c]
		}
	}
	st_matrix(ln, L)
	st_matrix(wn, W)
	st_matrix(evn, lam)
	st_matrix(un, u)
}

/* align bootstrap columns with the reference loadings (order and sign) */
void pi_align(string scalar lbn, string scalar wbn, string scalar l0n)
{
	real matrix Lb, Wb, L0, Lo, Wo, C
	real rowvector used
	real scalar c, j, best, bj, m

	Lb = st_matrix(lbn)
	Wb = st_matrix(wbn)
	L0 = st_matrix(l0n)
	m  = cols(L0)
	C  = L0' * Lb
	used = J(1, m, 0)
	Lo = Lb
	Wo = Wb
	for (c = 1; c <= m; c++) {
		best = -1
		bj   = c
		for (j = 1; j <= m; j++) {
			if (used[j]) continue
			if (abs(C[c, j]) > best) {
				best = abs(C[c, j])
				bj   = j
			}
		}
		used[bj] = 1
		Lo[., c] = Lb[., bj] * (C[c, bj] < 0 ? -1 : 1)
		Wo[., c] = Wb[., bj] * (C[c, bj] < 0 ? -1 : 1)
	}
	st_replacematrix(lbn, Lo)
	st_replacematrix(wbn, Wo)
}

/* conditional means of the latent N(0,1) within each category */
void pi_catscores(string scalar catsn, string scalar taun, string scalar out)
{
	real matrix cats, tau, cs
	real rowvector t
	real scalar j, K, c, lo, hi
	cats = st_matrix(catsn)
	tau  = st_matrix(taun)
	cs   = J(rows(cats), cols(cats), .)
	for (j = 1; j <= rows(cats); j++) {
		K = sum(cats[j, .] :< .)
		if (K < 2) continue
		t = tau[j, (1..(K - 1))]
		for (c = 1; c <= K; c++) {
			lo = (c == 1 ? . : t[c - 1])
			hi = (c == K ? . : t[c])
			cs[j, c] = ((lo == . ? 0 : normalden(lo)) - (hi == . ? 0 : normalden(hi))) /
			           ((hi == . ? 1 : normal(hi)) - (lo == . ? 0 : normal(lo)))
		}
	}
	st_matrix(out, cs)
}

/* map bootstrap category scores onto the full-sample categories;
   categories absent from a bootstrap sample keep their full-sample score */
void pi_mapcats(string scalar cats0n, string scalar cs0n, string scalar catsbn, string scalar csbn)
{
	real matrix c0, s0, cb, sb, out
	real scalar j, c
	real rowvector hit
	c0  = st_matrix(cats0n)
	s0  = st_matrix(cs0n)
	cb  = st_matrix(catsbn)
	sb  = st_matrix(csbn)
	out = s0
	for (j = 1; j <= rows(c0); j++) {
		for (c = 1; c <= cols(c0); c++) {
			if (c0[j, c] >= .) continue
			hit = (cb[j, .] :== c0[j, c])
			if (sum(hit) == 1) out[j, c] = select(sb[j, .], hit)
		}
	}
	st_matrix(csbn, out)
}

/* score = standardized variables (ordinal: category scores) x weights */
void pi_apply(string scalar vars, string scalar touse, string scalar catsn,
              string scalar csn, string scalar mun, string scalar sdn,
              string scalar wn, string scalar newvars)
{
	real matrix X, Z, cats, cs, W, S
	real rowvector mu, sd
	real colvector x, z, idx
	real scalar j, c, K
	string rowvector nv

	X    = st_data(., tokens(vars), touse)
	cats = st_matrix(catsn)
	cs   = st_matrix(csn)
	mu   = st_matrix(mun)
	sd   = st_matrix(sdn)
	W    = st_matrix(wn)
	nv   = tokens(newvars)
	Z    = J(rows(X), cols(X), .)
	for (j = 1; j <= cols(X); j++) {
		x = X[., j]
		if (mu[j] < .) {
			Z[., j] = (x :- mu[j]) / sd[j]
		}
		else {
			z = J(rows(x), 1, .)
			K = sum(cats[j, .] :< .)
			for (c = 1; c <= K; c++) {
				idx = selectindex(x :== cats[j, c])
				if (rows(idx) > 0) z[idx] = J(rows(idx), 1, cs[j, c])
			}
			Z[., j] = z
		}
	}
	S = Z * W[., (1..cols(nv))]
	st_store(., nv, touse, S)
}

/* average ranks (ties share their mean rank) */
real colvector pi_rank(real colvector x)
{
	real colvector o, r
	real scalar n, i, j, a
	n = rows(x)
	o = order(x, 1)
	r = J(n, 1, .)
	i = 1
	while (i <= n) {
		j = i
		while (j < n) {
			if (x[o[j + 1]] != x[o[i]]) break
			j++
		}
		a = (i + j)/2
		r[o[|i \ j|]] = J(j - i + 1, 1, a)
		i = j + 1
	}
	return(r)
}

/* Spearman correlation and share changing quantile group */
void pi_compare(string scalar v0, string scalar vb, string scalar touse,
                real scalar nq, string scalar mat, real scalar row)
{
	real colvector a, b, ra, rb, ga, gb
	real matrix S, C
	real scalar n
	a  = st_data(., v0, touse)
	b  = st_data(., vb, touse)
	n  = rows(a)
	ra = pi_rank(a)
	rb = pi_rank(b)
	ga = ceil(nq * ra / n)
	gb = ceil(nq * rb / n)
	S  = st_matrix(mat)
	C  = correlation((ra, rb))
	S[row, 1] = C[2, 1]
	S[row, 2] = mean(ga :!= gb)
	st_replacematrix(mat, S)
}

void pi_colsd(string scalar bn, string scalar out)
{
	real matrix B, o
	real scalar j
	real colvector x
	B = st_matrix(bn)
	o = J(cols(B), 1, .)
	for (j = 1; j <= cols(B); j++) {
		x = select(B[., j], B[., j] :< .)
		if (rows(x) > 1) o[j] = sqrt(variance(x))
	}
	st_replacematrix(out, o)
}

void pi_dropmiss(string scalar in, string scalar out)
{
	real matrix S
	S = st_matrix(in)
	S = select(S, rowmissing(S) :== 0)
	st_matrix(out, S)
}

real scalar pi_pctile(real colvector x, real scalar p)
{
	real colvector s
	real scalar n, h, lo
	s  = sort(x, 1)
	n  = rows(s)
	h  = (n - 1)*p + 1
	lo = floor(h)
	if (lo >= n) return(s[n])
	return(s[lo] + (h - lo)*(s[lo + 1] - s[lo]))
}

void pi_summ(string scalar sn)
{
	real matrix S
	S = st_matrix(sn)
	st_local("pi_sp_mean", strofreal(mean(S[., 1]), "%21.0g"))
	st_local("pi_sp_lo",   strofreal(pi_pctile(S[., 1], .025), "%21.0g"))
	st_local("pi_sp_hi",   strofreal(pi_pctile(S[., 1], .975), "%21.0g"))
	st_local("pi_rc_mean", strofreal(mean(S[., 2]), "%21.0g"))
	st_local("pi_rc_lo",   strofreal(pi_pctile(S[., 2], .025), "%21.0g"))
	st_local("pi_rc_hi",   strofreal(pi_pctile(S[., 2], .975), "%21.0g"))
}

end
