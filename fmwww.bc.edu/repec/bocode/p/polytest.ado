*! version 1.0.4  25oct2026  Yusuf Toyin Yusuf (Kwara State University)
*! polytest: tests of the latent-normality assumption behind polychoric,
*! tetrachoric and polyserial correlations:
*!   - triplet test (three-way tables; covers tetrachoric pairs, df >= 1)
*!   - binned conditional test for polyserial pairs + Jarque-Bera for x
*! with parametric-bootstrap p-values and multiple-testing adjustment.
*! Requires polycorr.

program define polytest, rclass
	version 14
	capture which polycorr
	if _rc {
		di as err "polytest requires polycorr; type {bf:net install polycorr}"
		exit 199
	}

	syntax varlist(numeric min=2) [if] [in] [fweight aweight pweight] ///
		[, TRIPlets POLYserial REPS(integer 199) BINS(integer 5)      ///
		   SEED(string) ADJust(string) MAXTriplets(integer 500)        ///
		   CATmax(passthru) ORDinal(passthru) CONTinuous(passthru) ]

	if "`triplets'" == "" & "`polyserial'" == "" {
		local triplets triplets
		local polyserial polyserial
	}
	if `reps' < 0 {
		di as err "reps() must be nonnegative"
		exit 198
	}
	if `bins' < 2 {
		di as err "bins() must be at least 2"
		exit 198
	}
	if "`adjust'" == "" local adjust holm
	local adjust = lower("`adjust'")
	if !inlist("`adjust'", "holm", "bh", "bonferroni", "none") {
		di as err "adjust() must be holm, bh, bonferroni or none"
		exit 198
	}
	if "`seed'" != "" set seed `seed'

	marksample touse
	local wgt
	if "`weight'" != "" local wgt "[`weight'`exp']"
	quietly polycorr `varlist' if `touse' `wgt', novce `catmax' `ordinal' `continuous'
	local types `e(types)'
	local N = e(N)

	tempvar wv
	if "`weight'" != "" quietly gen double `wv' `exp' if `touse'
	else                quietly gen double `wv' = 1 if `touse'

	local ordl
	local conl
	local k : word count `varlist'
	forvalues j = 1/`k' {
		local t : word `j' of `types'
		if "`t'" == "O" local ordl `ordl' `j'
		else            local conl `conl' `j'
	}
	local nord : word count `ordl'
	local ncon : word count `conl'

	di
	di as txt "Tests of latent normality" _col(51) "Number of obs" _col(67) "= " as res %10.0fc `N'
	di as txt "Bootstrap replications: " as res `reps' _col(51) as txt "Adjustment" _col(67) "= " as res %10s "`adjust'"

	tempname TR PS
	* ------------------------------------------------ triplets
	if "`triplets'" != "" {
		if `nord' < 3 {
			di as txt _n "Triplet test: fewer than three ordinal variables; skipped"
		}
		else {
			local ntr = comb(`nord', 3)
			if `ntr' > `maxtriplets' {
				di as err "`ntr' triplets exceed maxtriplets(`maxtriplets'); raise it or test fewer variables"
				exit 198
			}
			mata: pt_alltriplets("`varlist'", "`touse'", "`wv'", "`weight'", "`ordl'", ///
				`reps', "`adjust'", "`TR'")
			di
			di as txt "Triplet tests (three-way tables vs trivariate normal; two-step estimates)"
			di as txt "{hline 79}"
			di as txt "Variables" _col(37) "df" _col(42) "X2" _col(51) "G2" _col(58) "p>G2" ///
				_col(65) "p(boot)" _col(74) "p(adj)"
			di as txt "{hline 79}"
			forvalues t = 1/`=rowsof(`TR')' {
				local a : word `=`TR'[`t',1]' of `varlist'
				local b : word `=`TR'[`t',2]' of `varlist'
				local c : word `=`TR'[`t',3]' of `varlist'
				local lab = abbrev("`a'", 10) + " " + abbrev("`b'", 10) + " " + abbrev("`c'", 10)
				if `TR'[`t', 11] == 1 {
					di as txt %-34s "`lab'" as err "  R not positive definite; skipped"
					continue
				}
				di as txt %-34s "`lab'" as res %4.0f `TR'[`t',4] %9.2f `TR'[`t',5] %9.2f `TR'[`t',7] ///
					%8.4f `TR'[`t',8] %8.4f `TR'[`t',9] %8.4f `TR'[`t',10]
			}
			di as txt "{hline 79}"
			di as txt "Global min-p test over triplets: p = " as res %6.4f `pt_glob' ///
				as txt "   rejected at 5% after adjustment: " as res `pt_nrej'
			return scalar p_global_trip = `pt_glob'
			return scalar n_reject_trip = `pt_nrej'
			matrix colnames `TR' = v1 v2 v3 df X2 p_X2 G2 p_G2 p_boot p_adj flag
			return matrix triplets = `TR'
		}
	}

	* ------------------------------------------------ polyserial pairs
	if "`polyserial'" != "" {
		if `nord' < 1 | `ncon' < 1 {
			di as txt _n "Polyserial test: needs at least one ordinal and one continuous variable; skipped"
		}
		else {
			mata: pt_allpolyserial("`varlist'", "`touse'", "`wv'", "`weight'", "`ordl'", ///
				"`conl'", `bins', `reps', "`adjust'", "`PS'")
			di
			di as txt "Polyserial tests (`bins' bins of x; conditional ordered-probit fit) and Jarque-Bera for x"
			di as txt "{hline 79}"
			di as txt "x" _col(14) "y" _col(26) "rho" _col(34) "df" _col(40) "X2" _col(48) "p>X2" ///
				_col(55) "p(boot)" _col(63) "p(adj)" _col(71) "p(JB x)"
			di as txt "{hline 79}"
			forvalues t = 1/`=rowsof(`PS')' {
				local a : word `=`PS'[`t',1]' of `varlist'
				local b : word `=`PS'[`t',2]' of `varlist'
				di as txt %-12s abbrev("`a'", 12) " " %-10s abbrev("`b'", 10) ///
					as res %7.3f `PS'[`t',3] %5.0f `PS'[`t',4] %8.2f `PS'[`t',5] %8.4f `PS'[`t',6] ///
					%8.4f `PS'[`t',7] %8.4f `PS'[`t',8] %8.4f `PS'[`t',10]
			}
			di as txt "{hline 79}"
			di as txt "Global min-p test over polyserial pairs: p = " as res %6.4f `pt_globps' ///
				as txt "   rejected at 5% after adjustment: " as res `pt_nrejps'
			return scalar p_global_ps = `pt_globps'
			return scalar n_reject_ps = `pt_nrejps'
			matrix colnames `PS' = x y rho df X2 p_X2 p_boot p_adj JB p_JB
			return matrix polyserial = `PS'
		}
	}
	return scalar N    = `N'
	return scalar reps = `reps'
	return scalar bins = `bins'
	return local adjust "`adjust'"
	return local varlist "`varlist'"
	return local types "`types'"
end

version 14
capture mata: mata drop pt_*()
mata:
mata set matastrict on

/* Bivariate normal CDF P(X <= h, Y <= k; r) by the algorithm of Genz (2004),
   used instead of binormal(), which is unreliable as |r| approaches 1 */
real scalar pt_bvn2(real scalar h, real scalar k, real scalar r)
{
	real scalar v, ph, pk
	v  = pt_bvnu(-h, -k, r)
	ph = normal(h)
	pk = normal(k)
	// any bivariate CDF lies within the Frechet bounds; a value outside them is
	// a numerical failure and is reported as missing so that it is never used
	if (v > min((ph, pk)) + 1e-10 | v < ph + pk - 1 - 1e-10 | v >= .) return(.)
	return(min((max((v, max((0, ph + pk - 1)))), min((ph, pk)))))
}

real scalar pt_bvnu(real scalar dh, real scalar dk, real scalar r)
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
real scalar pt_c_big()
{
	return(10)
}

real colvector pt_c_tau(real colvector m)
{
	real colvector cp
	real scalar K
	K  = rows(m)
	cp = runningsum(m) / sum(m)
	cp = cp[|1 \ K-1|]
	cp = cp :* (cp :>= 1e-12) + (1e-12) :* (cp :< 1e-12)
	cp = cp :* (cp :<= 1 - 1e-12) + (1 - 1e-12) :* (cp :> 1 - 1e-12)
	return(invnormal(cp))
}

real colvector pt_c_index(real colvector y, real colvector cats)
{
	real colvector ix
	real scalar k
	ix = J(rows(y), 1, 1)
	for (k = 1; k < rows(cats); k++) ix = ix + (y :> cats[k])
	return(ix)
}

void pt_c_cells(real colvector ta, real colvector tb, real scalar r,
              real matrix P, real matrix dP)
{
	real colvector A, B
	real matrix F, D
	real scalar i, j, K, L, s2

	A  = (-pt_c_big() \ ta \ pt_c_big())
	B  = (-pt_c_big() \ tb \ pt_c_big())
	K  = rows(A)
	L  = rows(B)
	F  = J(K, L, 0)
	D  = J(K, L, 0)
	s2 = 1 - r^2
	/* first and last grid points are -infinity and +infinity: use exact limits */
	for (i = 1; i <= K; i++) {
		for (j = 1; j <= L; j++) {
			if (i == 1 | j == 1)      F[i, j] = 0
			else if (i == K & j == L) F[i, j] = 1
			else if (i == K)          F[i, j] = normal(B[j])
			else if (j == L)          F[i, j] = normal(A[i])
			else                      F[i, j] = pt_bvn2(A[i], B[j], r)
			if (i > 1 & i < K & j > 1 & j < L) {
				D[i, j] = exp(-(A[i]^2 - 2*r*A[i]*B[j] + B[j]^2)/(2*s2)) / (2*pi()*sqrt(s2))
			}
		}
	}
	P  = F[|2,2 \ K,L|] - F[|1,2 \ K-1,L|] - F[|2,1 \ K,L-1|] + F[|1,1 \ K-1,L-1|]
	dP = D[|2,2 \ K,L|] - D[|1,2 \ K-1,L|] - D[|2,1 \ K,L-1|] + D[|1,1 \ K-1,L-1|]
	P = P :* (P :>= 1e-300) + (1e-300) :* (P :< 1e-300)
}

real scalar pt_c_pc_ll(real matrix N, real colvector ta, real colvector tb, real scalar r)
{
	real matrix P, dP
	pt_c_cells(ta, tb, r, P, dP)
	if (hasmissing(P)) return(.)
	if (min(P) <= 0) return(.)
	return(sum(N :* ln(P)))
}

real scalar pt_c_pc_rho(real matrix N, real colvector ta, real colvector tb,
                      real scalar tol, real scalar zhat)
{
	real scalar a, b, c, d, fc, fd, g, k, f, fb, zb

	/* 25-point grid over atanh(rho) in [-3, 3] brackets the maximum;
	   missing log likelihoods are treated as -infinity */
	fb = .
	zb = 0
	for (k = -12; k <= 12; k++) {
		f = pt_c_pc_ll(N, ta, tb, tanh(.25*k))
		if (f < .) {
			if (fb >= . | f > fb) {
				fb = f
				zb = .25*k
			}
		}
	}
	// the search stays inside |rho| <= .995 unless the likelihood is still
	// rising at the edge of that range (a genuinely extreme correlation)
	a  = (zb <= -3 ? -5 : zb - .25)
	b  = (zb >=  3 ?  5 : zb + .25)
	g  = (sqrt(5) - 1)/2
	c  = b - g*(b - a)
	d  = a + g*(b - a)
	fc = pt_c_pc_ll(N, ta, tb, tanh(c))
	fd = pt_c_pc_ll(N, ta, tb, tanh(d))
	if (fc >= .) fc = -1e300
	if (fd >= .) fd = -1e300
	while (b - a > tol) {
		if (fc > fd) {
			b = d; d = c; fd = fc
			c = b - g*(b - a)
			fc = pt_c_pc_ll(N, ta, tb, tanh(c))
			if (fc >= .) fc = -1e300
		}
		else {
			a = c; c = d; fc = fd
			d = a + g*(b - a)
			fd = pt_c_pc_ll(N, ta, tb, tanh(d))
			if (fd >= .) fd = -1e300
		}
	}
	zhat = (a + b)/2
	return(tanh(zhat))
}

void pt_c_ps_eval(real colvector z, real colvector iy, real colvector tb, real scalar r,
                real colvector ll, real colvector sc)
{
	real scalar L, s
	real colvector Bx, fu, fl, bu, bl, uu, ul, Fu, Fl, du, dl, P

	L  = rows(tb) + 1
	s  = sqrt(1 - r^2)
	Bx = (0 \ tb \ 0)
	fu = (iy :< L)
	fl = (iy :> 1)
	bu = Bx[iy :+ 1]
	bl = Bx[iy]
	uu = (bu :- r*z) / s
	ul = (bl :- r*z) / s
	Fu = fu :* normal(uu) + (1 :- fu)
	Fl = fl :* normal(ul)
	du = fu :* normalden(uu) :* (r*bu :- z) / s^3
	dl = fl :* normalden(ul) :* (r*bl :- z) / s^3
	P  = Fu - Fl
	P = P :* (P :>= 1e-300) + (1e-300) :* (P :< 1e-300)
	ll = ln(P)
	sc = (du - dl) :/ P
}

real scalar pt_c_ps_ll(real colvector z, real colvector iy, real colvector w,
                     real colvector tb, real scalar r)
{
	real colvector ll, sc
	pt_c_ps_eval(z, iy, tb, r, ll, sc)
	if (hasmissing(ll)) return(.)
	return(sum(w :* ll))
}

real scalar pt_c_ps_rho(real colvector z, real colvector iy, real colvector w,
                      real colvector tb, real scalar tol, real scalar zhat)
{
	real scalar a, b, c, d, fc, fd, g, k, f, fb, zb

	/* coarse 37-point grid over atanh(rho) in [-4.5, 4.5] brackets the global maximum;
	   missing log likelihoods are treated as -infinity */
	fb = .
	zb = 0
	for (k = -18; k <= 18; k++) {
		f = pt_c_ps_ll(z, iy, w, tb, tanh(k/4))
		if (f < .) {
			if (fb >= . | f > fb) {
				fb = f
				zb = k/4
			}
		}
	}
	a  = (zb <= -4.5 ? -5 : zb - .25)
	b  = (zb >=  4.5 ?  5 : zb + .25)
	g  = (sqrt(5) - 1)/2
	c  = b - g*(b - a)
	d  = a + g*(b - a)
	fc = pt_c_ps_ll(z, iy, w, tb, tanh(c))
	fd = pt_c_ps_ll(z, iy, w, tb, tanh(d))
	if (fc >= .) fc = -1e300
	if (fd >= .) fd = -1e300
	while (b - a > tol) {
		if (fc > fd) {
			b = d; d = c; fd = fc
			c = b - g*(b - a)
			fc = pt_c_ps_ll(z, iy, w, tb, tanh(c))
			if (fc >= .) fc = -1e300
		}
		else {
			a = c; c = d; fc = fd
			d = a + g*(b - a)
			fd = pt_c_ps_ll(z, iy, w, tb, tanh(d))
			if (fd >= .) fd = -1e300
		}
	}
	zhat = (a + b)/2
	return(tanh(zhat))
}

real colvector pt_c_wtab(real colvector iy, real colvector w, real scalar L)
{
	real colvector m
	real scalar i
	m = J(L, 1, 0)
	for (i = 1; i <= rows(iy); i++) m[iy[i]] = m[iy[i]] + w[i]
	return(m)
}

real colvector pt_c_adjust(real colvector p, string scalar method)
{
	real colvector ok, idx, ps, adj, out
	real scalar m, k

	out = J(rows(p), 1, .)
	ok  = (p :< .)
	m   = sum(ok)
	if (m == 0) return(out)
	idx = select((1::rows(p)), ok)
	ps  = p[idx]
	if (method == "none") {
		out[idx] = ps
		return(out)
	}
	if (method == "bonferroni") {
		out[idx] = rowmin((m*ps, J(m, 1, 1)))
		return(out)
	}
	idx = idx[order(ps, 1)]
	ps  = p[idx]
	adj = J(m, 1, .)
	if (method == "holm") {
		for (k = 1; k <= m; k++) {
			adj[k] = min((1, (m - k + 1)*ps[k]))
			if (k > 1) adj[k] = max((adj[k], adj[k-1]))
		}
	}
	else {                                  /* Benjamini-Hochberg */
		for (k = m; k >= 1; k--) {
			adj[k] = min((1, m*ps[k]/k))
			if (k < m) adj[k] = min((adj[k], adj[k+1]))
		}
	}
	out[idx] = adj
	return(out)
}



/* Gauss-Legendre nodes and weights on [-1, 1] (Golub-Welsch) */
void pt_gl(real scalar n, real colvector x, real colvector w)
{
	real matrix J, V
	real rowvector lam
	real colvector o
	real scalar k, b
	J = J(n, n, 0)
	for (k = 1; k < n; k++) {
		b = k / sqrt(4*k^2 - 1)
		J[k, k + 1] = b
		J[k + 1, k] = b
	}
	symeigensystem(J, V, lam)
	o = order(lam', 1)
	x = lam[o']'
	w = 2 * (V[1, o']'):^2
}

/* trivariate normal CDF by Gauss-Legendre over the first coordinate */
real scalar pt_phi3(real scalar a0, real scalar b, real scalar c, real scalar r12,
                    real scalar r13, real scalar r23, real colvector gx, real colvector gw)
{
	real scalar lo, a, s12, s13, rp, i, sum, v
	real colvector t
	lo = -8.5
	a  = min((a0, 8.5))
	if (a <= lo) return(0)
	t   = lo :+ (a - lo) * (gx :+ 1) / 2
	s12 = sqrt(1 - r12^2)
	s13 = sqrt(1 - r13^2)
	rp  = (r23 - r12*r13) / (s12*s13)
	rp  = max((min((rp, 0.999999)), -0.999999))
	sum = 0
	for (i = 1; i <= rows(t); i++) {
		if (b >= 9.99 & c >= 9.99) v = 1
		else if (b >= 9.99)        v = normal((c - r13*t[i])/s13)
		else if (c >= 9.99)        v = normal((b - r12*t[i])/s12)
		else                       v = pt_bvn2((b - r12*t[i])/s12, (c - r13*t[i])/s13, rp)
		sum = sum + gw[i] * normalden(t[i]) * v
	}
	return((a - lo)/2 * sum)
}

/* K x (L*M) cell probabilities, column index (l-1)*M + m */
real matrix pt_probs(real colvector ta, real colvector tb, real colvector tc,
                     real scalar r12, real scalar r13, real scalar r23,
                     real colvector gx, real colvector gw)
{
	real colvector A, B, C
	real matrix F, P
	real scalar K, L, M, i, j, h, l, m, M1
	A  = (-10 \ ta \ 10)
	B  = (-10 \ tb \ 10)
	C  = (-10 \ tc \ 10)
	K  = rows(A) - 1
	L  = rows(B) - 1
	M  = rows(C) - 1
	M1 = M + 1
	F  = J(K + 1, (L + 1)*M1, 0)
	for (i = 2; i <= K + 1; i++) {
		for (j = 2; j <= L + 1; j++) {
			for (h = 2; h <= M + 1; h++) {
				F[i, (j - 1)*M1 + h] = pt_phi3(A[i], B[j], C[h], r12, r13, r23, gx, gw)
			}
		}
	}
	P = J(K, L*M, 0)
	for (i = 1; i <= K; i++) {
		for (l = 1; l <= L; l++) {
			for (m = 1; m <= M; m++) {
				P[i, (l - 1)*M + m] = (F[i+1, l*M1 + m + 1] - F[i, l*M1 + m + 1] -
				    F[i+1, (l-1)*M1 + m + 1] - F[i+1, l*M1 + m] +
				    F[i, (l-1)*M1 + m + 1] + F[i, l*M1 + m] +
				    F[i+1, (l-1)*M1 + m] - F[i, (l-1)*M1 + m])
			}
		}
	}
	P = P :* (P :>= 1e-300) + (1e-300) :* (P :< 1e-300)
	return(P)
}

/* fit two-step model to a three-way table; returns (X2, G2, flag) and P */
real rowvector pt_fit3(real matrix N3, real scalar L, real scalar M,
                       real colvector gx, real colvector gw, real matrix P)
{
	real scalar K, n, r12, r13, r23, zh, X2, G2, l, m
	real colvector ta, tb, tc, mb, mc
	real matrix N12, N13, N23, E, R
	K   = rows(N3)
	N12 = J(K, L, 0)
	N13 = J(K, M, 0)
	for (l = 1; l <= L; l++) {
		for (m = 1; m <= M; m++) {
			N12[., l] = N12[., l] + N3[., (l - 1)*M + m]
			N13[., m] = N13[., m] + N3[., (l - 1)*M + m]
		}
	}
	N23 = colshape(colsum(N3), M)
	ta  = pt_c_tau(rowsum(N3))
	tb  = pt_c_tau(rowsum(N23))
	tc  = pt_c_tau(colsum(N23)')
	r12 = pt_c_pc_rho(N12, ta, tb, 1e-8, zh)
	r13 = pt_c_pc_rho(N13, ta, tc, 1e-8, zh)
	r23 = pt_c_pc_rho(N23, tb, tc, 1e-8, zh)
	R   = (1, r12, r13 \ r12, 1, r23 \ r13, r23, 1)
	if (min(symeigenvalues(R)) <= 1e-8) {
		P = J(K, L*M, .)
		return((., ., 1))
	}
	P  = pt_probs(ta, tb, tc, r12, r13, r23, gx, gw)
	n  = sum(N3)
	E  = n * P
	X2 = sum(((N3 - E):^2 :/ E) :* (E :> 1e-10))
	G2 = 2 * sum(N3 :* ln((N3 + (N3 :<= 0)) :/ E) :* (N3 :> 0))
	return((X2, G2, 0))
}

void pt_alltriplets(string scalar vars, string scalar touse, string scalar wvar,
                    string scalar wtype, string scalar ordl, real scalar reps,
                    string scalar adjust, string scalar outn)
{
	real matrix X, N3, P, Pb, Nb, out
	real colvector w, ix, iy, iz, cx, cy, cz, gx, gw, pv, draw, Nbv, pa
	real rowvector idx, st, sb
	real scalar a, b, c, t, nt, K, L, M, i, W, nobs, df, cnt, rr, nb, pmin, nf

	X   = st_data(., tokens(vars), touse)
	w   = st_data(., wvar, touse)
	idx = strtoreal(tokens(ordl))
	pt_gl(48, gx, gw)
	W    = sum(w)
	nobs = (wtype == "fweight" ? W : rows(X))
	nt   = comb(cols(idx), 3)
	out  = J(nt, 11, .)
	t    = 0
	for (a = 1; a <= cols(idx) - 2; a++) {
		for (b = a + 1; b <= cols(idx) - 1; b++) {
			for (c = b + 1; c <= cols(idx); c++) {
				t++
				cx = uniqrows(X[., idx[a]])
				cy = uniqrows(X[., idx[b]])
				cz = uniqrows(X[., idx[c]])
				K  = rows(cx)
				L  = rows(cy)
				M  = rows(cz)
				ix = pt_c_index(X[., idx[a]], cx)
				iy = pt_c_index(X[., idx[b]], cy)
				iz = pt_c_index(X[., idx[c]], cz)
				N3 = J(K, L*M, 0)
				for (i = 1; i <= rows(X); i++) {
					N3[ix[i], (iy[i] - 1)*M + iz[i]] = N3[ix[i], (iy[i] - 1)*M + iz[i]] + w[i]
				}
				N3 = N3 * (nobs / W)
				df = K*L*M - K - L - M - 1
				st = pt_fit3(N3, L, M, gx, gw, P)
				out[t, (1..4)] = (idx[a], idx[b], idx[c], df)
				out[t, 11] = st[3]
				if (st[3] == 1) continue
				out[t, 5] = st[1]
				out[t, 6] = chi2tail(df, st[1])
				out[t, 7] = st[2]
				out[t, 8] = chi2tail(df, st[2])
				if (reps > 0) {
					pv  = vec(P) / sum(P)
					nb  = round(nobs)
					cnt = 0
					nf  = 0
					for (rr = 1; rr <= reps; rr++) {
						draw = rdiscrete(nb, 1, pv)
						Nbv  = J(K*L*M, 1, 0)
						for (i = 1; i <= nb; i++) Nbv[draw[i]] = Nbv[draw[i]] + 1
						Nb   = colshape(Nbv, K)'
						sb   = pt_fit3(Nb, L, M, gx, gw, Pb)
						if (sb[3] == 1) continue
						nf++
						cnt = cnt + (sb[2] >= st[2])
					}
					out[t, 9] = (1 + cnt) / (nf + 1)
				}
			}
		}
	}
	pa = (reps > 0 ? out[., 9] : out[., 8])
	out[., 10] = pt_c_adjust(pa, adjust)
	pmin = min(pa)
	st_matrix(outn, out)
	st_local("pt_glob", strofreal(min((1, sum(pa :< .) * pmin)), "%21.0g"))
	st_local("pt_nrej", strofreal(sum((out[., 10] :< .05) :& (out[., 10] :< .))))
}

/* category probabilities given standardized z: n x L */
real matrix pt_condprob(real colvector z, real colvector tb, real scalar r)
{
	real matrix Pm
	real scalar L, l, s
	real colvector up, lo
	L  = rows(tb) + 1
	s  = sqrt(1 - r^2)
	Pm = J(rows(z), L, .)
	lo = J(rows(z), 1, 0)
	for (l = 1; l <= L; l++) {
		up = (l < L ? normal((tb[l] :- r*z)/s) : J(rows(z), 1, 1))
		Pm[., l] = up - lo
		lo = up
	}
	return(Pm)
}

real scalar pt_bx2(real colvector bin, real colvector iy, real colvector w,
                   real matrix Pm, real scalar B, real scalar L)
{
	real matrix O, E
	real scalar i
	O = J(B, L, 0)
	E = J(B, L, 0)
	for (i = 1; i <= rows(iy); i++) {
		O[bin[i], iy[i]] = O[bin[i], iy[i]] + w[i]
		E[bin[i], .]     = E[bin[i], .] + w[i] * Pm[i, .]
	}
	return(sum(((O - E):^2 :/ E) :* (E :> 1e-10)))
}

void pt_allpolyserial(string scalar vars, string scalar touse, string scalar wvar,
                      string scalar wtype, string scalar ordl, string scalar conl,
                      real scalar B, real scalar reps, string scalar adjust,
                      string scalar outn)
{
	real matrix X, Pm, Pb, out, cum
	real colvector w, ws, x, y, z, cy, iy, tb, xs, bin, edge, u, iyb, tbb, pa
	real rowvector io, ic
	real scalar a, b, t, L, W, nobs, mu, sg, rho, zh, X2, df, cnt, rr, rb, Xb, i, n, S, Kt, JB, nf

	X  = st_data(., tokens(vars), touse)
	w  = st_data(., wvar, touse)
	io = strtoreal(tokens(ordl))
	ic = strtoreal(tokens(conl))
	n  = rows(X)
	W  = sum(w)
	nobs = (wtype == "fweight" ? W : n)
	ws = w * (nobs / W)
	out = J(cols(ic) * cols(io), 10, .)
	t = 0
	for (a = 1; a <= cols(ic); a++) {
		x  = X[., ic[a]]
		mu = sum(w :* x) / W
		sg = sqrt(sum(w :* (x :- mu):^2) / W)
		z  = (x :- mu) / sg
		S  = sum(w :* z:^3) / W
		Kt = sum(w :* z:^4) / W
		JB = nobs * (S^2/6 + (Kt - 3)^2/24)
		xs   = sort(x, 1)
		edge = J(B - 1, 1, .)
		for (i = 1; i <= B - 1; i++) edge[i] = xs[ceil(i*n/B)]
		bin = J(n, 1, 1)
		for (i = 1; i <= B - 1; i++) bin = bin + (x :> edge[i])
		for (b = 1; b <= cols(io); b++) {
			t++
			y   = X[., io[b]]
			cy  = uniqrows(y)
			L   = rows(cy)
			iy  = pt_c_index(y, cy)
			tb  = pt_c_tau(pt_c_wtab(iy, w, L))
			rho = pt_c_ps_rho(z, iy, w, tb, 1e-9, zh)
			Pm  = pt_condprob(z, tb, rho)
			X2  = pt_bx2(bin, iy, ws, Pm, B, L)
			df  = B*(L - 1) - L
			out[t, (1..6)] = (ic[a], io[b], rho, df, X2, (df > 0 ? chi2tail(df, X2) : .))
			out[t, 9]  = JB
			out[t, 10] = chi2tail(2, JB)
			if (reps > 0) {
				cum = Pm
				for (i = 2; i <= L; i++) cum[., i] = cum[., i - 1] + Pm[., i]
				cnt = 0
				nf  = 0
				for (rr = 1; rr <= reps; rr++) {
					u   = runiform(n, 1)
					iyb = J(n, 1, 1)
					for (i = 1; i <= L - 1; i++) iyb = iyb + (u :> cum[., i])
					if (rows(uniqrows(iyb)) < L) continue
					tbb = pt_c_tau(pt_c_wtab(iyb, w, L))
					rb  = pt_c_ps_rho(z, iyb, w, tbb, 1e-7, zh)
					Pb  = pt_condprob(z, tbb, rb)
					Xb  = pt_bx2(bin, iyb, ws, Pb, B, L)
					nf++
					cnt = cnt + (Xb >= X2)
				}
				out[t, 7] = (1 + cnt) / (nf + 1)
			}
		}
	}
	pa = (reps > 0 ? out[., 7] : out[., 6])
	out[., 8] = pt_c_adjust(pa, adjust)
	st_matrix(outn, out)
	st_local("pt_globps", strofreal(min((1, sum(pa :< .) * min(pa))), "%21.0g"))
	st_local("pt_nrejps", strofreal(sum((out[., 8] :< .05) :& (out[., 8] :< .))))
}

end
