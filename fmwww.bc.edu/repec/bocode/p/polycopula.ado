*! version 1.1.5  25oct2026  Yusuf Toyin Yusuf (Kwara State University)
*! polycopula: copula-based association for pairs of ordinal variables
*! (Gaussian = polychoric, Frank, Clayton, Gumbel; rotated for negative
*! dependence), with two-step robust SEs, Kendall's tau, normal-equivalent
*! correlation, AIC/BIC, G2 fit and Vuong tests against the Gaussian copula.
*! Option robust: robust polychoric correlation (Welz, Mair & Alfons C-estimator)
*! that downweights cells with large Pearson residuals (e.g. careless responding).
*! Requires polycorr.

program define polycopula, rclass
	version 14
	capture which polycorr
	if _rc {
		di as err "polycopula requires polycorr; type {bf:net install polycorr}"
		exit 199
	}
	syntax varlist(numeric min=2) [if] [in] [fweight aweight pweight] ///
		[, COPulas(string) CATmax(passthru) ORDinal(passthru) Level(cilevel) ///
		   ROBust CUToff(real 0.6) ]
	if `cutoff' <= 0 {
		di as err "cutoff() must be positive"
		exit 198
	}

	if "`copulas'" == "" local copulas gaussian frank clayton gumbel
	local copulas = lower("`copulas'")
	local fams
	foreach c of local copulas {
		if !inlist("`c'", "gaussian", "frank", "clayton", "gumbel") {
			di as err "copulas() may contain gaussian, frank, clayton, gumbel"
			exit 198
		}
		local fams `fams' `c'
	}
	local fams : list uniq fams
	if !`: list posof "gaussian" in fams' local fams gaussian `fams'

	marksample touse
	local wgt
	if "`weight'" != "" local wgt "[`weight'`exp']"
	quietly polycorr `varlist' if `touse' `wgt', novce `catmax' `ordinal'
	if strpos("`e(types)'", "C") {
		di as err "polycopula requires ordinal variables; some exceed catmax() (types: `e(types)')"
		di as err "use catmax() or ordinal() to declare them ordinal"
		exit 459
	}
	local N = e(N)
	tempvar wv
	if "`weight'" != "" quietly gen double `wv' `exp' if `touse'
	else                quietly gen double `wv' = 1 if `touse'

	tempname T
	mata: pq_main("`varlist'", "`touse'", "`wv'", "`weight'", "`fams'", `level', "`T'")

	local k : word count `varlist'
	local nf : word count `fams'
	di
	di as txt "Copula models for ordinal pairs (two-step; robust SEs)" _col(56) "Number of obs = " as res %8.0fc `N'
	local row 0
	local rn
	forvalues i = 1/`=`k'-1' {
		forvalues j = `=`i'+1'/`k' {
			local a : word `i' of `varlist'
			local b : word `j' of `varlist'
			di
			di as txt "Pair: " as res "`a'" as txt " and " as res "`b'"
			di as txt "{hline 86}"
			di as txt "Copula" _col(11) "theta" _col(20) "s.e." _col(28) "tau" _col(35) "s.e." ///
				_col(43) "rho*" _col(51) "logL" _col(61) "AIC" _col(68) "G2(df)" _col(78) "Vuong z"
			di as txt "{hline 86}"
			local best = .
			local bestaic = .
			forvalues f = 1/`nf' {
				local rr = `row' + `f'
				if `T'[`rr', 10] < `bestaic' {
					local bestaic = `T'[`rr', 10]
					local best `f'
				}
			}
			forvalues f = 1/`nf' {
				local ++row
				local fn : word `f' of `fams'
				local lab = "`fn'" + cond(`T'[`row', 3] == 1, "-r", "")
				local star = cond(`f' == `best', "*", " ")
				local g2 = string(`T'[`row', 12], "%6.1f") + "(" + string(`T'[`row', 13]) + ")"
				di as txt %-9s "`lab'" as res %8.3f `T'[`row', 4] %8.3f `T'[`row', 5] ///
					%7.3f `T'[`row', 6] %8.3f `T'[`row', 7] %7.3f `T'[`row', 8] ///
					%10.1f `T'[`row', 9] %9.1f `T'[`row', 10] as txt "`star'" as res %9s "`g2'" _c
				if "`fn'" == "gaussian" di
				else di as res %8.2f `T'[`row', 15]
				local rn `rn' `a'_`b':`fn'
			}
			di as txt "{hline 86}"
		}
	}
	di as txt "-r: rotated by 90 degrees for negative dependence.  * smallest AIC."
	di as txt "rho* = sin(pi tau/2), the Gaussian correlation with the same Kendall's tau."
	di as txt "Vuong z > 1.96: copula fits better than Gaussian; z < -1.96: worse."

	if "`robust'" != "" {
		tempname RB
		mata: pq_robustall("`varlist'", "`touse'", "`wv'", `cutoff', "`RB'")
		di
		di as txt "Robust polychoric correlations (C-estimator, cutoff c = " as res `cutoff' as txt ")"
		di as txt "{hline 78}"
		di as txt "Variable 1   Variable 2      rho(ML)   rho(robust)   Std. err.   cells down"
		di as txt "{hline 78}"
		local p 0
		forvalues i = 1/`=`k'-1' {
			forvalues j = `=`i'+1'/`k' {
				local ++p
				local a : word `i' of `varlist'
				local b : word `j' of `varlist'
				di as txt %-12s abbrev("`a'", 12) " " %-12s abbrev("`b'", 12) ///
					as res _col(28) %9.4f `RB'[`p', 2] _col(42) %9.4f `RB'[`p', 3] ///
					_col(55) %9.4f `RB'[`p', 4] _col(70) %5.0f `RB'[`p', 5] ///
					cond(`RB'[`p', 6] == 0, "  (not converged)", "")
			}
		}
		di as txt "{hline 78}"
		di as txt "Cells with Pearson ratio f/p above 1 + c are downweighted; with c -> infinity the"
		di as txt "estimator is maximum likelihood with thresholds and rho estimated jointly."
		matrix colnames `RB' = pair rho_ml rho_robust se_robust cells_down converged
		return matrix robust = `RB'
		return scalar cutoff = `cutoff'
	}

	matrix colnames `T' = pair family rotated theta se tau se_tau rho_star ll aic bic G2 df p_G2 vuong p_vuong
	capture matrix rownames `T' = `rn'
	return matrix table = `T'
	return scalar N = `N'
	return local copulas "`fams'"
	return local varlist "`varlist'"
end

version 14
capture mata: mata drop pq_*()
mata:
mata set matastrict on

/* Bivariate normal CDF P(X <= h, Y <= k; r) by the algorithm of Genz (2004),
   used instead of binormal(), which is unreliable as |r| approaches 1 */
real scalar pq_bvn2(real scalar h, real scalar k, real scalar r)
{
	real scalar v, ph, pk
	v  = pq_bvnu(-h, -k, r)
	ph = normal(h)
	pk = normal(k)
	// any bivariate CDF lies within the Frechet bounds; a value outside them is
	// a numerical failure and is reported as missing so that it is never used
	if (v > min((ph, pk)) + 1e-10 | v < ph + pk - 1 - 1e-10 | v >= .) return(.)
	return(min((max((v, max((0, ph + pk - 1)))), min((ph, pk)))))
}

real scalar pq_bvnu(real scalar dh, real scalar dk, real scalar r)
{
	real scalar tp, h, k, hk, bvn, hs, asr, sn, i, s, as2, a, bs, c, d, b, xs, rs
	real rowvector w, x
	tp = 2*pi()
	h  = dh
	k  = dk
	if (abs(r) < .3) {
		w = (0.1713244923791705, 0.3607615730481384, 0.4679139345726904)
		x = (-0.9324695142031522, -0.6612093864662647, -0.2386191860831970)
	}
	else if (abs(r) < .75) {
		w = (0.04717533638651177, 0.1069393259953183, 0.1600783285433464, 0.2031674267230659, 0.2334925365383547, 0.2491470458134029)
		x = (-0.9815606342467191, -0.9041172563704750, -0.7699026741943050, -0.5873179542866171, -0.3678314989981802, -0.1252334085114692)
	}
	else {
		w = (0.01761400713915212, 0.04060142980038694, 0.06267204833410906, 0.08327674157670475, 0.1019301198172404, 0.1181945319615184, 0.1316886384491766, 0.1420961093183821, 0.1491729864726037, 0.1527533871307259)
		x = (-0.9931285991850949, -0.9639719272779138, -0.9122344282513259, -0.8391169718222188, -0.7463319064601508, -0.6360536807265150, -0.5108670019508271, -0.3737060887154196, -0.2277858511416451, -0.07652652113349733)
	}
	hk  = h*k
	bvn = 0
	if (abs(r) < .925) {
		hs  = (h*h + k*k)/2
		asr = asin(r)
		for (i = 1; i <= cols(w); i++) {
			for (s = -1; s <= 1; s = s + 2) {
				sn  = sin(asr*(s*x[i] + 1)/2)
				bvn = bvn + w[i]*exp((sn*hk - hs)/(1 - sn*sn))
			}
		}
		return(bvn*asr/(2*tp) + normal(-h)*normal(-k))
	}
	if (r < 0) {
		k  = -k
		hk = -hk
	}
	if (abs(r) < 1) {
		as2 = (1 - r)*(1 + r)
		a   = sqrt(as2)
		bs  = (h - k)^2
		c   = (4 - hk)/8
		d   = (12 - hk)/16
		bvn = a*exp(-(bs/as2 + hk)/2)*(1 - c*(bs - as2)*(1 - d*bs/5)/3 + c*d*as2*as2/5)
		if (hk > -160) {
			b   = sqrt(bs)
			bvn = bvn - exp(-hk/2)*sqrt(tp)*normal(-b/a)*b*(1 - c*bs*(1 - d*bs/5)/3)
		}
		a = a/2
		for (i = 1; i <= cols(w); i++) {
			for (s = -1; s <= 1; s = s + 2) {
				xs  = (a*(s*x[i] + 1))^2
				rs  = sqrt(1 - xs)
				asr = -(bs/xs + hk)/2
				if (asr > -100) {
					bvn = bvn + a*w[i]*exp(asr)*(exp(-hk*xs/(2*(1 + rs)^2))/rs - (1 + c*xs*(1 + d*xs)))
				}
			}
		}
		bvn = -bvn/tp
	}
	if (r > 0) return(bvn + normal(-max((h, k))))
	bvn = -bvn
	if (k > h) {
		if (h < 0) bvn = bvn + normal(k) - normal(h)
		else       bvn = bvn + normal(-h) - normal(-k)
	}
	return(bvn)
}


/* ---- helpers copied from polycorr (Mata functions are not shared across ado-files) ---- */
real colvector pq_c_index(real colvector y, real colvector cats)
{
	real colvector ix
	real scalar k
	ix = J(rows(y), 1, 1)
	for (k = 1; k < rows(cats); k++) ix = ix + (y :> cats[k])
	return(ix)
}



real scalar pq_C(string scalar fam, real scalar u, real scalar v, real scalar th, real scalar rot)
{
	if (rot) return(u - pq_C(fam, u, 1 - v, th, 0))
	if (u <= 0 | v <= 0) return(0)
	if (u >= 1) return(v)
	if (v >= 1) return(u)
	if (fam == "gaussian") return(pq_bvn2(invnormal(u), invnormal(v), th))
	if (fam == "frank") {
		if (abs(th) < 1e-8) return(u*v)
		// same as the textbook form, rearranged to avoid cancellation at large |theta|
		return(-ln((exp(-th*(u + v)) + exp(-th) - exp(-th*u) - exp(-th*v)) / (exp(-th) - 1)) / th)
	}
	if (fam == "clayton") return((u^(-th) + v^(-th) - 1)^(-1/th))
	return(exp(-((-ln(u))^th + (-ln(v))^th)^(1/th)))
}

real matrix pq_cells(string scalar fam, real colvector F, real colvector G,
                     real scalar th, real scalar rot)
{
	real colvector U, V
	real matrix Cm, P
	real scalar i, j, K, L
	U  = (0 \ F \ 1)
	V  = (0 \ G \ 1)
	K  = rows(U)
	L  = rows(V)
	Cm = J(K, L, 0)
	for (i = 1; i <= K; i++) {
		for (j = 1; j <= L; j++) Cm[i, j] = pq_C(fam, U[i], V[j], th, rot)
	}
	P = Cm[|2,2 \ K,L|] - Cm[|1,2 \ K-1,L|] - Cm[|2,1 \ K,L-1|] + Cm[|1,1 \ K-1,L-1|]
	P = P :* (P :>= 1e-300) + (1e-300) :* (P :< 1e-300)
	return(P)
}

real scalar pq_par(string scalar fam, real scalar z)
{
	if (fam == "gaussian") return(tanh(z))
	if (fam == "frank")    return(z)
	if (fam == "clayton")  return(exp(z))
	return(1 + exp(z))
}

real rowvector pq_range(string scalar fam)
{
	if (fam == "gaussian") return((-5, 5))
	if (fam == "frank")    return((-60, 60))
	if (fam == "clayton")  return((-8, 4))
	return((-10, 4))
}

real scalar pq_ll(real matrix N, string scalar fam, real colvector F, real colvector G,
                  real scalar th, real scalar rot)
{
	real matrix P
	P = pq_cells(fam, F, G, th, rot)
	if (hasmissing(P)) return(.)
	if (min(P) <= 0) return(.)
	return(sum(N :* ln(P)))
}

real scalar pq_golden(real matrix N, string scalar fam, real colvector F, real colvector G,
                      real scalar rot)
{
	real scalar a, b, c, d, fc, fd, g, k, f, fb, zb, st
	real rowvector rg
	rg = pq_range(fam)
	st = (rg[2] - rg[1]) / 40
	fb = .
	zb = (rg[1] + rg[2])/2
	for (k = 1; k <= 39; k++) {
		f = pq_ll(N, fam, F, G, pq_par(fam, rg[1] + k*st), rot)
		if (f < .) {
			if (fb >= . | f > fb) {
				fb = f
				zb = rg[1] + k*st
			}
		}
	}
	a  = max((rg[1], zb - st))
	b  = min((rg[2], zb + st))
	g  = (sqrt(5) - 1)/2
	c  = b - g*(b - a)
	d  = a + g*(b - a)
	fc = pq_ll(N, fam, F, G, pq_par(fam, c), rot)
	fd = pq_ll(N, fam, F, G, pq_par(fam, d), rot)
	if (fc >= .) fc = -1e300
	if (fd >= .) fd = -1e300
	while (b - a > 1e-9) {
		if (fc > fd) {
			b = d; d = c; fd = fc
			c = b - g*(b - a)
			fc = pq_ll(N, fam, F, G, pq_par(fam, c), rot)
			if (fc >= .) fc = -1e300
		}
		else {
			a = c; c = d; fc = fd
			d = a + g*(b - a)
			fd = pq_ll(N, fam, F, G, pq_par(fam, d), rot)
			if (fd >= .) fd = -1e300
		}
	}
	return(pq_par(fam, (a + b)/2))
}

/* Debye function D1(t) = (1/t) int_0^t s/(e^s - 1) ds, 48-point Gauss-Legendre */
real scalar pq_D1(real scalar t)
{
	real matrix Jm, V
	real rowvector lam
	real colvector x, w, s, f
	real scalar k, b, n
	if (abs(t) < 1e-8) return(1)
	n  = 48
	Jm = J(n, n, 0)
	for (k = 1; k < n; k++) {
		b = k / sqrt(4*k^2 - 1)
		Jm[k, k + 1] = b
		Jm[k + 1, k] = b
	}
	symeigensystem(Jm, V, lam)
	x = lam'
	w = 2 * (V[1, .]'):^2
	s = t * (x :+ 1) / 2
	f = s :/ (exp(s) :- 1)
	return(sum(w :* f) / 2)
}

real scalar pq_tau(string scalar fam, real scalar th, real scalar rot)
{
	real scalar t
	if (fam == "gaussian")     t = 2/pi() * asin(th)
	else if (fam == "clayton") t = th/(th + 2)
	else if (fam == "gumbel")  t = 1 - 1/th
	else                       t = (abs(th) < 1e-8 ? 0 : 1 - 4/th*(1 - pq_D1(th)))
	return(rot ? -t : t)
}

real scalar pq_ms(real matrix N, string scalar fam, real colvector F, real colvector G,
                  real scalar th, real scalar rot, real scalar h)
{
	real matrix D
	D = (ln(pq_cells(fam, F, G, th + h, rot)) - ln(pq_cells(fam, F, G, th - h, rot))) / (2*h)
	return(sum(N :* D) / sum(N))
}

/* one copula for one pair: returns result row and per-observation log-likelihood */
real rowvector pq_fit(real colvector x, real colvector y, real colvector w, real scalar nobs,
                      string scalar fam, real scalar rot, real colvector lli)
{
	real colvector cx, cy, ix, iy, F, G, s, corr, d, IF, Dv, Lv
	real matrix N, P, D
	real scalar K, L, i, W, th, h, H, Gk, k, e, se, tau, dt, ll, G2, df, ht, n

	n  = rows(x)
	W  = sum(w)
	cx = uniqrows(x)
	cy = uniqrows(y)
	K  = rows(cx)
	L  = rows(cy)
	ix = pq_c_index(x, cx)
	iy = pq_c_index(y, cy)
	N  = J(K, L, 0)
	for (i = 1; i <= n; i++) N[ix[i], iy[i]] = N[ix[i], iy[i]] + w[i]
	F  = runningsum(rowsum(N)) / W
	F  = F[|1 \ K-1|]
	G  = runningsum(colsum(N)') / W
	G  = G[|1 \ L-1|]

	th = pq_golden(N, fam, F, G, rot)
	P  = pq_cells(fam, F, G, th, rot)
	Lv = vec(ln(P))
	lli = Lv[ix + (iy :- 1)*K]

	/* two-step influence function for theta */
	h  = 1e-5 * max((1, abs(th)))
	if (fam == "clayton" & th - h <= 0) h = th/4
	if (fam == "gumbel" & th - h <= 1)  h = (th - 1)/4
	if (fam == "gaussian") h = min((h, (1 - abs(th))/4))
	D  = (ln(pq_cells(fam, F, G, th + h, rot)) - ln(pq_cells(fam, F, G, th - h, rot))) / (2*h)
	Dv = vec(D)
	s  = Dv[ix + (iy :- 1)*K]
	H  = (pq_ms(N, fam, F, G, th + h, rot, h) - pq_ms(N, fam, F, G, th - h, rot, h)) / (2*h)
	corr = J(n, 1, 0)
	e  = 1e-6
	for (k = 1; k <= K - 1; k++) {
		d    = J(K - 1, 1, 0)
		d[k] = e
		Gk   = (pq_ms(N, fam, F + d, G, th, rot, h) - pq_ms(N, fam, F - d, G, th, rot, h)) / (2*e)
		corr = corr + Gk * ((x :<= cx[k]) :- F[k])
	}
	for (k = 1; k <= L - 1; k++) {
		d    = J(L - 1, 1, 0)
		d[k] = e
		Gk   = (pq_ms(N, fam, F, G + d, th, rot, h) - pq_ms(N, fam, F, G - d, th, rot, h)) / (2*e)
		corr = corr + Gk * ((y :<= cy[k]) :- G[k])
	}
	IF = -(s + corr) / H
	se = sqrt(n/(n - 1) * sum((w :* IF / W):^2))

	tau = pq_tau(fam, th, rot)
	ht  = h
	dt  = (pq_tau(fam, th + ht, rot) - pq_tau(fam, th - ht, rot)) / (2*ht)
	ll  = sum(N :* ln(P)) * (nobs / W)
	G2  = 2 * sum((N*(nobs/W)) :* ln(((N + (N :<= 0))*(nobs/W)) :/ (nobs*P)) :* (N :> 0))
	df  = K*L - K - L
	return((th, se, tau, abs(dt)*se, sin(pi()*tau/2), ll, -2*ll + 2, -2*ll + ln(nobs), G2, df,
	        (df > 0 ? chi2tail(df, G2) : .)))
}

void pq_main(string scalar vars, string scalar touse, string scalar wvar, string scalar wtype,
             string scalar famlist, real scalar level, string scalar outn)
{
	real matrix X, out
	real colvector w, x, y, lg, lc, dd
	real rowvector r, rg
	string rowvector fams
	real scalar k, i, j, f, row, nf, nobs, rot, W, vz, n, p

	X    = st_data(., tokens(vars), touse)
	w    = st_data(., wvar, touse)
	fams = tokens(famlist)
	k    = cols(X)
	nf   = cols(fams)
	n    = rows(X)
	W    = sum(w)
	nobs = (wtype == "fweight" ? W : n)
	out  = J(k*(k - 1)/2 * nf, 16, .)
	row  = 0
	p    = 0
	for (i = 1; i <= k - 1; i++) {
		for (j = i + 1; j <= k; j++) {
			p++
			x  = X[., i]
			y  = X[., j]
			rg = pq_fit(x, y, w, nobs, "gaussian", 0, lg)
			rot = (rg[1] < 0)
			for (f = 1; f <= nf; f++) {
				row++
				if (fams[f] == "gaussian") {
					r  = rg
					lc = lg
				}
				else {
					r = pq_fit(x, y, w, nobs, fams[f], rot * (fams[f] != "frank"), lc)
				}
				out[row, 1] = p
				out[row, 2] = f
				out[row, 3] = (fams[f] == "clayton" | fams[f] == "gumbel") * rot
				out[row, (4..14)] = r
				if (fams[f] != "gaussian") {
					dd = lc - lg
					vz = sqrt(nobs) * mean(dd, w) / sqrt(variance(dd, w))
					out[row, 15] = vz
					out[row, 16] = 2*normal(-abs(vz))
				}
			}
		}
	}
	st_matrix(outn, out)
}

/* ---------------- robust polychoric (Welz, Mair & Alfons) ---------------- */
void pq_rcells(real colvector ta, real colvector tb, real scalar r, real matrix P,
               real matrix Dm)
{
	real colvector A, B
	real matrix F, D, Fa, Fb, Ga, Gb, dR, M
	real scalar K1, L1, K, L, i, j, s, s2, t, q

	A  = (-10 \ ta \ 10)
	B  = (-10 \ tb \ 10)
	K1 = rows(A)
	L1 = rows(B)
	K  = K1 - 1
	L  = L1 - 1
	s2 = 1 - r^2
	s  = sqrt(s2)
	F  = J(K1, L1, 0)
	D  = J(K1, L1, 0)
	Fa = J(K1, L1, 0)
	Fb = J(K1, L1, 0)
	for (i = 1; i <= K1; i++) {
		for (j = 1; j <= L1; j++) {
			if (i == 1 | j == 1)        F[i, j] = 0
			else if (i == K1 & j == L1) F[i, j] = 1
			else if (i == K1)           F[i, j] = normal(B[j])
			else if (j == L1)           F[i, j] = normal(A[i])
			else                        F[i, j] = pq_bvn2(A[i], B[j], r)
			if (i > 1 & i < K1 & j > 1 & j < L1) {
				D[i, j] = exp(-(A[i]^2 - 2*r*A[i]*B[j] + B[j]^2)/(2*s2)) / (2*pi()*s)
			}
			if (i > 1 & i < K1) {
				if (j == 1)       Fa[i, j] = 0
				else if (j == L1) Fa[i, j] = normalden(A[i])
				else              Fa[i, j] = normalden(A[i]) * normal((B[j] - r*A[i])/s)
			}
			if (j > 1 & j < L1) {
				if (i == 1)       Fb[i, j] = 0
				else if (i == K1) Fb[i, j] = normalden(B[j])
				else              Fb[i, j] = normalden(B[j]) * normal((A[i] - r*B[j])/s)
			}
		}
	}
	P  = F[|2,2 \ K1,L1|] - F[|1,2 \ K1-1,L1|] - F[|2,1 \ K1,L1-1|] + F[|1,1 \ K1-1,L1-1|]
	P = P :* (P :>= 1e-300) + (1e-300) :* (P :< 1e-300)
	dR = D[|2,2 \ K1,L1|] - D[|1,2 \ K1-1,L1|] - D[|2,1 \ K1,L1-1|] + D[|1,1 \ K1-1,L1-1|]
	Ga = Fa[|2,2 \ K1-1,L1|] - Fa[|2,1 \ K1-1,L1-1|]
	Gb = Fb[|2,2 \ K1,L1-1|] - Fb[|1,2 \ K1-1,L1-1|]
	q  = K - 1 + L - 1 + 1
	Dm = J(q, K*L, 0)
	for (t = 1; t <= K - 1; t++) {
		M = J(K, L, 0)
		M[t, .]     = Ga[t, .]
		M[t + 1, .] = -Ga[t, .]
		Dm[t, .] = vec(M)'
	}
	for (t = 1; t <= L - 1; t++) {
		M = J(K, L, 0)
		M[., t]     = Gb[., t]
		M[., t + 1] = -Gb[., t]
		Dm[K - 1 + t, .] = vec(M)'
	}
	Dm[q, .] = vec(dR)'
}

real colvector pq_rnat(real colvector p, real scalar K, real scalar L)
{
	real colvector a, b
	a = p[1]
	if (K > 2) a = runningsum(p[1] \ exp(p[|2 \ K - 1|]))
	b = p[K]
	if (L > 2) b = runningsum(p[K] \ exp(p[|K + 1 \ K + L - 2|]))
	return(a \ b \ tanh(p[K + L - 1]))
}

real scalar pq_rloss(real colvector thn, real matrix f, real scalar K, real scalar L, real scalar c)
{
	real matrix P, Dm, z, ph
	pq_rcells(thn[|1 \ K - 1|], thn[|K \ K + L - 2|], thn[K + L - 1], P, Dm)
	z  = f :/ P :- 1
	ph = (z :<= c) :* ((z :+ 1) :* ln(z :+ 1 :+ (z :<= -1))) +
	     (z :> c)  :* ((z :+ 1) * (ln(c + 1) + 1) :- c :- 1)
	if (hasmissing(ph) | hasmissing(P)) return(.)
	return(sum(ph :* P))
}

void pq_reval(real scalar todo, real rowvector p, real matrix f, real scalar K,
              real scalar L, real scalar c, real scalar v, real rowvector g, real matrix H)
{
	v = -pq_rloss(pq_rnat(p', K, L), f, K, L, c)
}

real colvector pq_rgrad(real colvector thn, real matrix f, real scalar K, real scalar L,
                        real scalar c)
{
	real matrix P, Dm
	real colvector psi
	pq_rcells(thn[|1 \ K - 1|], thn[|K \ K + L - 2|], thn[K + L - 1], P, Dm)
	psi = vec(f :/ P)
	psi = psi :* (psi :<= 1 + c) + (1 + c) :* (psi :> 1 + c)
	return(Dm * psi)
}

/* returns (rho_ml, rho_robust, se_robust, cells_down, converged) */
real rowvector pq_robust(real colvector x, real colvector y, real colvector w, real scalar c)
{
	real colvector cx, cy, ix, iy, F, G, p0, thn, e, act, IF, cell, Fr, Gr
	real matrix N, f, P, Dm, Hg, M
	real scalar K, L, n, W, i, q, a, h, rml, rc, conv, nd, m0
	transmorphic S

	n  = rows(x)
	W  = sum(w)
	cx = uniqrows(x)
	cy = uniqrows(y)
	K  = rows(cx)
	L  = rows(cy)
	ix = pq_c_index(x, cx)
	iy = pq_c_index(y, cy)
	N  = J(K, L, 0)
	for (i = 1; i <= n; i++) N[ix[i], iy[i]] = N[ix[i], iy[i]] + w[i]
	f  = N / W
	F  = runningsum(rowsum(N)) / W
	F  = F[|1 \ K-1|]
	G  = runningsum(colsum(N)') / W
	G  = G[|1 \ L-1|]
	rml = pq_golden(N, "gaussian", F, G, 0)
	Fr = invnormal(F)
	Gr = invnormal(G)
	p0 = Fr[1]
	if (K > 2) p0 = p0 \ ln(Fr[|2 \ K - 1|] - Fr[|1 \ K - 2|])
	p0 = p0 \ Gr[1]
	if (L > 2) p0 = p0 \ ln(Gr[|2 \ L - 1|] - Gr[|1 \ L - 2|])
	p0 = p0 \ atanh(max((min((rml, .995)), -.995)))

	S = optimize_init()
	optimize_init_evaluator(S, &pq_reval())
	optimize_init_evaluatortype(S, "d0")
	optimize_init_technique(S, "bfgs")
	optimize_init_which(S, "max")
	optimize_init_argument(S, 1, f)
	optimize_init_argument(S, 2, K)
	optimize_init_argument(S, 3, L)
	optimize_init_argument(S, 4, c)
	optimize_init_params(S, p0')
	optimize_init_conv_maxiter(S, 300)
	// the loss is an average over cells (order 1, not order n), so the default
	// value tolerance stops too early; tighten value and parameter tolerances
	optimize_init_conv_vtol(S, 1e-14)
	optimize_init_conv_ptol(S, 1e-10)
	optimize_init_tracelevel(S, "none")
	rc   = _optimize(S)
	conv = (rc == 0 & optimize_result_converged(S))
	thn  = pq_rnat(optimize_result_params(S)', K, L)

	/* influence function of the estimating equation sum psi_c dP_c/dtheta = 0 */
	q  = rows(thn)
	Hg = J(q, q, .)
	for (a = 1; a <= q; a++) {
		h    = 1e-6
		e    = J(q, 1, 0)
		e[a] = h
		Hg[., a] = (pq_rgrad(thn + e, f, K, L, c) - pq_rgrad(thn - e, f, K, L, c)) / (2*h)
	}
	pq_rcells(thn[|1 \ K - 1|], thn[|K \ K + L - 2|], thn[q], P, Dm)
	act = vec((f :/ P) :< 1 + c)
	M   = -luinv(Hg) * (Dm :* (act :/ vec(P))')
	m0  = M[q, .] * vec(f)
	cell = ix + (iy :- 1)*K
	IF  = M[q, cell]' :- m0
	nd  = sum((vec(f) :> 0) :& (act :== 0))
	return((rml, thn[q], sqrt(n/(n - 1) * sum((w :* IF / W):^2)), nd, conv))
}

void pq_robustall(string scalar vars, string scalar touse, string scalar wvar,
                  real scalar c, string scalar outn)
{
	real matrix X, out
	real colvector w
	real scalar k, i, j, p
	X   = st_data(., tokens(vars), touse)
	w   = st_data(., wvar, touse)
	k   = cols(X)
	out = J(k*(k - 1)/2, 6, .)
	p   = 0
	for (i = 1; i <= k - 1; i++) {
		for (j = i + 1; j <= k; j++) {
			p++
			out[p, .] = (p, pq_robust(X[., i], X[., j], w, c))
		}
	}
	st_matrix(outn, out)
}

end
