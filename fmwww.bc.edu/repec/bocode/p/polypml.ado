*! version 1.0.4  25oct2026  Yusuf Toyin Yusuf (Kwara State University)
*! polypml: joint estimation of all thresholds and polychoric correlations of
*! ordinal variables with missing data, by
*!   method(pml)  pairwise (composite) maximum likelihood, available cases,
*!                Godambe sandwich covariance (consistent under MCAR), or
*!   method(fiml) full-information maximum likelihood (consistent under MAR),
*!                GHK simulator with Halton draws, sandwich covariance.

program define polypml, eclass
	version 14

	if replay() {
		if `"`e(cmd)'"' != "polypml" error 301
		Display `0'
		exit
	}
	local cmdline `"polypml `0'"'

	syntax varlist(numeric min=2) [if] [in] [fweight aweight pweight] ///
		[, METHod(string) vce(string) DRAWs(integer 200)                ///
		   CATmax(integer 10) ORDinal(varlist numeric) Level(cilevel)    ///
		   ITERate(integer 300) TOLerance(real 1e-8) THResholds ]

	if "`method'" == "" local method pml
	local method = lower("`method'")
	if !inlist("`method'", "pml", "fiml") {
		di as err "method() must be pml or fiml"
		exit 198
	}
	local k : word count `varlist'
	local dups : list dups varlist
	if "`dups'" != "" {
		di as err "variable(s) repeated: `dups'"
		exit 198
	}
	if "`method'" == "fiml" & `k' > 20 {
		di as err "method(fiml) allows at most 20 variables"
		exit 198
	}
	if `draws' < 20 {
		di as err "draws() must be at least 20"
		exit 198
	}
	local bad : list ordinal - varlist
	if "`bad'" != "" {
		di as err "ordinal(): `bad' not in varlist"
		exit 198
	}

	local vcetype robust
	local clustvar
	if `"`vce'"' != "" {
		gettoken v1 v2 : vce
		local v2 = trim(`"`v2'"')
		if inlist(`"`v1'"', "robust", "r", "rob", "robu", "robus") local vcetype robust
		else if inlist(`"`v1'"', "cluster", "cl", "clu", "clus", "clust", "cluste") {
			local vcetype cluster
			local clustvar `v2'
			confirm variable `clustvar'
		}
		else {
			di as err "vce() must be robust or cluster clustvar"
			exit 198
		}
	}

	marksample touse, novarlist
	if "`clustvar'" != "" markout `touse' `clustvar', strok
	tempvar nnm wv cid
	quietly egen `nnm' = rownonmiss(`varlist')
	local minobs = cond("`method'" == "pml", 2, 1)
	quietly replace `touse' = 0 if `nnm' < `minobs'
	quietly count if `touse'
	if r(N) < 10 error 2001
	if "`weight'" != "" quietly gen double `wv' `exp' if `touse'
	else                quietly gen double `wv' = 1 if `touse'
	if "`clustvar'" != "" quietly egen long `cid' = group(`clustvar') if `touse'
	local cidn = cond("`clustvar'" != "", "`cid'", "")

	* ordinal check
	foreach v of local varlist {
		if !`: list posof "`v'" in ordinal' {
			quietly tab `v' if `touse'
			if r(r) > `catmax' {
				di as err "`v' has " r(r) " distinct values (> catmax(`catmax')); polypml needs ordinal variables"
				di as err "declare it with ordinal() or raise catmax()"
				exit 459
			}
		}
	}

	tempname b V R tau cats
	mata: pp_main("`varlist'", "`touse'", "`wv'", "`weight'", "`method'",   ///
		"`vcetype'", "`cidn'", `draws', `tolerance', `iterate',             ///
		"`b'", "`V'", "`R'", "`tau'", "`cats'")

	ereturn post `b' `V', esample(`touse') obs(`pp_N')
	ereturn scalar k_var     = `k'
	ereturn scalar n_pairs   = `k'*(`k'-1)/2
	ereturn scalar ll        = `pp_ll'
	ereturn scalar converged = `pp_conv'
	ereturn scalar iter      = `pp_iter'
	ereturn scalar mineig    = `pp_mineig'
	ereturn scalar level     = `level'
	if "`method'" == "fiml" {
		ereturn scalar draws      = `draws'
		ereturn scalar n_patterns = `pp_npat'
	}
	if "`vcetype'" == "cluster" {
		ereturn scalar N_clust = `pp_G'
		ereturn local clustvar "`clustvar'"
	}
	ereturn local method   "`method'"
	ereturn local vce      "`vcetype'"
	ereturn local vcetype  "Robust"
	ereturn local varlist  "`varlist'"
	if "`weight'" != "" {
		ereturn local wtype "`weight'"
		ereturn local wexp  `"`exp'"'
	}
	if "`method'" == "pml" ereturn local title "Polychoric correlations: pairwise maximum likelihood"
	else                   ereturn local title "Polychoric correlations: full-information maximum likelihood"
	ereturn local cmdline `"`cmdline'"'
	ereturn matrix R    = `R'
	ereturn matrix tau  = `tau'
	ereturn matrix cats = `cats'
	ereturn local cmd "polypml"

	Display, level(`level') `thresholds'
end

program define Display
	syntax [, Level(cilevel) THResholds]
	tempname b V
	matrix `b' = e(b)
	matrix `V' = e(V)
	local vars `e(varlist)'
	local k = e(k_var)
	local P = e(n_pairs)
	local q = invnormal(1 - (1 - `level'/100)/2)
	local cil = string(`level') + "% CI"
	di
	di as txt "`e(title)'" _col(57) "Number of obs = " as res %8.0fc e(N)
	if "`e(method)'" == "pml" {
		di as txt "Available-case pairwise likelihood (consistent under MCAR)" _col(57) "Log PL = " as res %13.3f e(ll)
	}
	else {
		di as txt "GHK simulator, " as res e(draws) as txt " Halton draws; " as res e(n_patterns) ///
			as txt " response patterns (MAR)" _col(57) "Log L  = " as res %13.3f e(ll)
	}
	if "`e(vce)'" == "cluster" di as txt "Std. err. adjusted for " as res e(N_clust) as txt " clusters in `e(clustvar)'"
	else                       di as txt "Robust (sandwich) standard errors"
	di as txt "{hline 78}"
	di as txt "Variable 1   Variable 2" _col(35) "rho" _col(43) "Std. err." _col(57) "z" _col(62) "[`cil']"
	di as txt "{hline 78}"
	forvalues p = 1/`P' {
		local eq : word `p' of `: coleq `b''
		local nm : word `p' of `: colnames `b''
		local r  = `b'[1, `p']
		local se = sqrt(`V'[`p', `p'])
		di as txt %-12s abbrev("`eq'", 12) " " %-12s abbrev("`nm'", 12) ///
			as res _col(31) %8.4f `r' _col(43) %8.4f `se' _col(53) %6.2f `r'/`se' ///
			_col(62) %7.4f `r' - `q'*`se' "  " %7.4f `r' + `q'*`se'
	}
	di as txt "{hline 78}"
	if "`thresholds'" != "" {
		di as txt "Thresholds"
		di as txt "{hline 78}"
		local Q = colsof(`b')
		forvalues p = `=`P'+1'/`Q' {
			local eq : word `p' of `: coleq `b''
			local nm : word `p' of `: colnames `b''
			local r  = `b'[1, `p']
			local se = sqrt(`V'[`p', `p'])
			di as txt %-12s abbrev("`eq'", 12) " " %-12s "`nm'" ///
				as res _col(31) %8.4f `r' _col(43) %8.4f `se'
		}
		di as txt "{hline 78}"
	}
	if e(mineig) < . {
		di as txt "Smallest eigenvalue of R = " as res %9.6f e(mineig)
	}
	if !e(converged) di as err "warning: convergence not achieved"
end

version 14
capture mata: mata drop pp_*()
mata:
mata set matastrict on

/* Bivariate normal CDF P(X <= h, Y <= k; r) by the algorithm of Genz (2004),
   used instead of binormal(), which is unreliable as |r| approaches 1 */
real scalar pp_bvn2(real scalar h, real scalar k, real scalar r)
{
	real scalar v, ph, pk
	v  = pp_bvnu(-h, -k, r)
	ph = normal(h)
	pk = normal(k)
	// any bivariate CDF lies within the Frechet bounds; a value outside them is
	// a numerical failure and is reported as missing so that it is never used
	if (v > min((ph, pk)) + 1e-10 | v < ph + pk - 1 - 1e-10 | v >= .) return(.)
	return(min((max((v, max((0, ph + pk - 1)))), min((ph, pk)))))
}

real scalar pp_bvnu(real scalar dh, real scalar dk, real scalar r)
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


real scalar pp_big()
{
	return(10)
}

// sum of N*ln(P); missing if any probability is missing (Mata's sum() skips missings)
real scalar pp_llsum(real matrix N, real matrix P)
{
	if (hasmissing(P)) return(.)
	if (min(P) <= 0) return(.)
	return(sum(N :* ln(P)))
}

/* bivariate normal CDF; arguments at or beyond +/-9.99 are treated as infinite */
real scalar pp_bvn(real scalar h, real scalar k, real scalar r)
{
	if (h <= -9.99 | k <= -9.99) return(0)
	if (h >= 9.99 & k >= 9.99)   return(1)
	if (h >= 9.99)               return(normal(k))
	if (k >= 9.99)               return(normal(h))
	return(pp_bvn2(h, k, r))
}

/* cell probabilities and analytic derivatives for one pair */
void pp_cells(real colvector ta, real colvector tb, real scalar r, real matrix P,
              real matrix Ga, real matrix Gb, real matrix dR)
{
	real colvector A, B
	real matrix F, D, Fa, Fb
	real scalar K1, L1, i, j, s, s2

	A  = (-pp_big() \ ta \ pp_big())
	B  = (-pp_big() \ tb \ pp_big())
	K1 = rows(A)
	L1 = rows(B)
	s2 = 1 - r^2
	s  = sqrt(s2)
	F  = J(K1, L1, 0)
	D  = J(K1, L1, 0)
	Fa = J(K1, L1, 0)
	Fb = J(K1, L1, 0)
	for (i = 1; i <= K1; i++) {
		for (j = 1; j <= L1; j++) {
			F[i, j] = pp_bvn(A[i], B[j], r)
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
}

/* score matrix (nparam x K*L, cells in column-major order) for one pair */
real matrix pp_cellscores(real colvector ta, real colvector tb, real scalar r, real matrix P)
{
	real matrix Ga, Gb, dR, S, M
	real scalar K, L, t
	pp_cells(ta, tb, r, P, Ga, Gb, dR)
	K = rows(ta) + 1
	L = rows(tb) + 1
	S = J(K - 1 + L - 1 + 1, K*L, 0)
	for (t = 1; t <= K - 1; t++) {
		M = J(K, L, 0)
		M[t, .]     = Ga[t, .]
		M[t + 1, .] = -Ga[t, .]
		S[t, .] = vec(M :/ P)'
	}
	for (t = 1; t <= L - 1; t++) {
		M = J(K, L, 0)
		M[., t]     = Gb[., t]
		M[., t + 1] = -Gb[., t]
		S[K - 1 + t, .] = vec(M :/ P)'
	}
	S[K + L - 1, .] = vec(dR :/ P)'
	return(S)
}

real colvector pp_tau(real colvector m)
{
	real colvector cp
	real scalar K
	K  = rows(m)
	cp = runningsum(m) / sum(m)
	cp = cp[|1 \ K-1|]
	cp = cp :* (cp :>= 1e-6) + (1e-6) :* (cp :< 1e-6)
	cp = cp :* (cp :<= 1 - 1e-6) + (1 - 1e-6) :* (cp :> 1 - 1e-6)
	return(invnormal(cp))
}

/* two-step start value for one pair */
real scalar pp_rho0(real matrix N, real colvector ta, real colvector tb)
{
	real scalar a, b, c, d, fc, fd, g, k, f, fb, zb
	real matrix P, Ga, Gb, dR
	fb = .
	zb = 0
	for (k = -12; k <= 12; k++) {
		pp_cells(ta, tb, tanh(k/4), P, Ga, Gb, dR)
		f = pp_llsum(N, P)
		if (f < .) {
			if (fb >= . | f > fb) {
				fb = f
				zb = k/4
			}
		}
	}
	a = zb - .25
	b = zb + .25
	g = (sqrt(5) - 1)/2
	c = b - g*(b - a)
	d = a + g*(b - a)
	pp_cells(ta, tb, tanh(c), P, Ga, Gb, dR)
	fc = pp_llsum(N, P)
	pp_cells(ta, tb, tanh(d), P, Ga, Gb, dR)
	fd = pp_llsum(N, P)
	if (fc >= .) fc = -1e300
	if (fd >= .) fd = -1e300
	while (b - a > 1e-6) {
		if (fc > fd) {
			b = d; d = c; fd = fc
			c = b - g*(b - a)
			pp_cells(ta, tb, tanh(c), P, Ga, Gb, dR)
			fc = pp_llsum(N, P)
			if (fc >= .) fc = -1e300
		}
		else {
			a = c; c = d; fc = fd
			d = a + g*(b - a)
			pp_cells(ta, tb, tanh(d), P, Ga, Gb, dR)
			fd = pp_llsum(N, P)
			if (fd >= .) fd = -1e300
		}
	}
	return(tanh((a + b)/2))
}

/* split natural parameter vector th = (rho_1..rho_P, tau_1..tau_k) */
real colvector pp_tauj(real colvector th, real rowvector off, real scalar P, real scalar j)
{
	return(th[(P + off[j] + 1)::(P + off[j + 1])])
}

real scalar pp_pml_ll(real colvector th, pointer(real matrix) rowvector tabs,
                      real matrix pr, real rowvector off)
{
	real scalar p, P, ll
	real matrix Pm, Ga, Gb, dR
	P  = rows(pr)
	ll = 0
	for (p = 1; p <= P; p++) {
		pp_cells(pp_tauj(th, off, P, pr[p, 1]), pp_tauj(th, off, P, pr[p, 2]), th[p], Pm, Ga, Gb, dR)
		ll = ll + pp_llsum(*tabs[p], Pm)
	}
	return(ll)
}

real scalar pp_valid(real colvector th, real rowvector off, real scalar P, real scalar k)
{
	real scalar j
	real colvector t
	if (max(abs(th[|1 \ P|])) >= 1) return(0)
	for (j = 1; j <= k; j++) {
		t = pp_tauj(th, off, P, j)
		if (rows(t) > 1) {
			if (min(t[|2 \ rows(t)|] - t[|1 \ rows(t) - 1|]) <= 0) return(0)
		}
	}
	return(1)
}

/* parameter indices of a pair in th */
real rowvector pp_ind(real scalar p, real scalar i, real scalar j, real rowvector off, real scalar P)
{
	return(((P + off[i] + 1)..(P + off[i + 1]), (P + off[j] + 1)..(P + off[j + 1]), p))
}

/* --------------------------- FIML helpers --------------------------- */
real colvector pp_halton(real scalar n, real scalar base)
{
	real colvector h
	real scalar i, f, r, kk
	h = J(n, 1, .)
	for (i = 1; i <= n; i++) {
		f  = 1
		r  = 0
		kk = i + 10
		while (kk > 0) {
			f  = f / base
			r  = r + f * mod(kk, base)
			kk = floor(kk / base)
		}
		h[i] = r
	}
	return(h)
}

real matrix pp_cpc2R(real colvector z, real scalar k)
{
	real matrix W
	real scalar i, j, c, ss, v
	W = J(k, k, 0)
	W[1, 1] = 1
	c = 0
	for (i = 2; i <= k; i++) {
		ss = 0
		for (j = 1; j <= i - 1; j++) {
			c++
			v = tanh(z[c]) * sqrt(max((1 - ss, 0)))
			W[i, j] = v
			ss = ss + v^2
		}
		W[i, i] = sqrt(max((1 - ss, 1e-300)))
	}
	return(W * W')
}

real colvector pp_R2cpc(real matrix R)
{
	real matrix W
	real colvector z
	real scalar i, j, c, ss, k
	k = rows(R)
	W = cholesky(R)
	z = J(k*(k - 1)/2, 1, .)
	c = 0
	for (i = 2; i <= k; i++) {
		ss = 0
		for (j = 1; j <= i - 1; j++) {
			c++
			z[c] = atanh(max((min((W[i, j]/sqrt(max((1 - ss, 1e-12))), .999999)), -.999999)))
			ss = ss + W[i, j]^2
		}
	}
	return(z)
}

/* natural th = (rho upper-triangle by rows, thresholds) <-> free parameters */
real colvector pp_nat2free(real colvector th, real rowvector off, real scalar k)
{
	real matrix R
	real colvector f, t
	real scalar P, i, j, p
	P = k*(k - 1)/2
	R = I(k)
	p = 0
	for (i = 1; i <= k - 1; i++) {
		for (j = i + 1; j <= k; j++) {
			p++
			R[i, j] = th[p]
			R[j, i] = th[p]
		}
	}
	f = pp_R2cpc(R)
	for (j = 1; j <= k; j++) {
		t = pp_tauj(th, off, P, j)
		f = f \ t[1]
		if (rows(t) > 1) f = f \ ln(t[|2 \ rows(t)|] - t[|1 \ rows(t) - 1|])
	}
	return(f)
}

real colvector pp_free2nat(real colvector f, real rowvector off, real scalar k)
{
	real matrix R
	real colvector th, seg
	real scalar P, i, j, p, n
	P  = k*(k - 1)/2
	R  = pp_cpc2R(f[|1 \ P|], k)
	th = J(P, 1, .)
	p  = 0
	for (i = 1; i <= k - 1; i++) {
		for (j = i + 1; j <= k; j++) {
			p++
			th[p] = R[i, j]
		}
	}
	for (j = 1; j <= k; j++) {
		n   = off[j + 1] - off[j]
		seg = f[(P + off[j] + 1)::(P + off[j + 1])]
		if (n > 1) seg = runningsum(seg[1] \ exp(seg[|2 \ n|]))
		th = th \ seg
	}
	return(th)
}

/* probability of each response pattern (0 = missing) */
real colvector pp_patprob(real colvector th, real matrix pats, real rowvector off,
                          real scalar k, real matrix Uh)
{
	// probabilities of all response patterns; patterns that share the same set of
	// observed variables are processed together as one matrix (rows = patterns,
	// columns = Halton draws), which avoids a Mata loop over patterns
	real matrix R, C, Lo, Up, Cat, pr, mu, a, b, v, E
	real colvector out, o, rr, code, ucode, T
	real scalar P, p, i, j, l, m, D, g, ng, r
	P = k*(k - 1)/2
	R = I(k)
	p = 0
	for (i = 1; i <= k - 1; i++) {
		for (j = i + 1; j <= k; j++) {
			p++
			R[i, j] = th[p]
			R[j, i] = th[p]
		}
	}
	D     = rows(Uh)
	out   = J(rows(pats), 1, 1)
	code  = (pats :> 0) * (2:^(0::(k - 1)))
	ucode = uniqrows(code)
	for (g = 1; g <= rows(ucode); g++) {
		if (ucode[g] == 0) continue
		rr  = selectindex(code :== ucode[g])
		o   = selectindex(pats[rr[1], .]' :> 0)
		m   = rows(o)
		ng  = rows(rr)
		Cat = pats[rr, o]
		Lo  = J(ng, m, .)
		Up  = J(ng, m, .)
		for (j = 1; j <= m; j++) {
			T = (-1e10 \ pp_tauj(th, off, P, o[j]) \ 1e10)
			Lo[., j] = T[Cat[., j]]
			Up[., j] = T[Cat[., j] :+ 1]
		}
		if (m == 1) {
			out[rr] = normal(Up) - normal(Lo)
		}
		else if (m == 2) {
			r = R[o[1], o[2]]
			for (i = 1; i <= ng; i++) {
				out[rr[i]] = pp_bvn(Up[i, 1], Up[i, 2], r) - pp_bvn(Lo[i, 1], Up[i, 2], r) -
				             pp_bvn(Up[i, 1], Lo[i, 2], r) + pp_bvn(Lo[i, 1], Lo[i, 2], r)
			}
		}
		else {
			C = cholesky(R[o, o])
			if (hasmissing(C)) return(J(rows(pats), 1, .))
			pr = J(ng, D, 1)
			E  = J(ng, D*m, 0)
			for (j = 1; j <= m; j++) {
				mu = J(ng, D, 0)
				for (l = 1; l < j; l++) {
					mu = mu + C[j, l] * E[|1, (l - 1)*D + 1 \ ng, l*D|]
				}
				a  = normal((Lo[., j] :- mu) / C[j, j])
				b  = normal((Up[., j] :- mu) / C[j, j])
				pr = pr :* (b - a)
				if (j == m) continue
				v  = a + Uh[., j]' :* (b - a)
				v = v :* (v :>= 1e-15) + (1e-15) :* (v :< 1e-15)
				v = v :* (v :<= 1 - 1e-15) + (1 - 1e-15) :* (v :> 1 - 1e-15)
				E[|1, (j - 1)*D + 1 \ ng, j*D|] = invnormal(v)
			}
			out[rr] = rowsum(pr) / D
		}
	}
	out = out :* (out :>= 1e-300) + (1e-300) :* (out :< 1e-300)
	return(out)
}

// FIML log likelihood at natural parameters
real scalar pp_fll(real colvector th, real matrix pats, real colvector cnt,
                   real rowvector off, real scalar k, real matrix Uh)
{
	return(pp_llsum(cnt, pp_patprob(th, pats, off, k, Uh)))
}

// pattern-level scores with respect to the free parameters (central differences)
real matrix pp_fscores(real colvector f, real matrix pats, real rowvector off,
                       real scalar k, real matrix Uh)
{
	real matrix S
	real colvector e
	real scalar a, h
	S = J(rows(pats), rows(f), .)
	h = 1e-5
	for (a = 1; a <= rows(f); a++) {
		e    = J(rows(f), 1, 0)
		e[a] = h
		S[., a] = (ln(pp_patprob(pp_free2nat(f + e, off, k), pats, off, k, Uh)) -
		           ln(pp_patprob(pp_free2nat(f - e, off, k), pats, off, k, Uh))) / (2*h)
	}
	return(S)
}

void pp_fiml_eval(real scalar todo, real rowvector f, real matrix pats, real colvector cnt,
                  real rowvector off, real matrix Uh, real scalar v, real rowvector g,
                  real matrix H)
{
	real colvector pr
	real scalar k
	k  = cols(pats)
	pr = pp_patprob(pp_free2nat(f', off, k), pats, off, k, Uh)
	v  = sum(cnt :* ln(pr))
	if (hasmissing(pr)) v = .
}

/* pattern-level numerical scores with respect to natural parameters */
real matrix pp_patscores(real colvector th, real matrix pats, real rowvector off,
                         real scalar k, real matrix Uh)
{
	real matrix S
	real colvector e
	real scalar a, h
	S = J(rows(pats), rows(th), .)
	for (a = 1; a <= rows(th); a++) {
		h    = 1e-5
		e    = J(rows(th), 1, 0)
		e[a] = h
		S[., a] = (ln(pp_patprob(th + e, pats, off, k, Uh)) -
		           ln(pp_patprob(th - e, pats, off, k, Uh))) / (2*h)
	}
	return(S)
}

/* ------------------------------ main ------------------------------ */
void pp_main(string scalar vars, string scalar touse, string scalar wvar,
             string scalar wtype, string scalar method, string scalar vcetype,
             string scalar cidvar, real scalar draws, real scalar tol,
             real scalar maxit, string scalar bn, string scalar vn, string scalar rn,
             string scalar taun, string scalar catsn)
{
	real matrix X, idx, cats, pr, Ht, U, Sp, Hi, Jm, V, R, tau, Uw, T, info, pats, srt, Uh, S, Pm, Tb
	real colvector w, ok, cv, th, g, step, tn, ix, gid, cnt, newg, ord, cid, e, gp, gm, f0, f
	real rowvector K, off, ind, primes
	real scalar n, k, P, j, i, p, q, it, conv, t, ll0, ll, a, h, nb, G, mineig, rc, D, maxK
	string colvector eq, nm
	pointer(real matrix) rowvector tabs
	real scalar gs, ok2, b

	X = st_data(., tokens(vars), touse)
	w = st_data(., wvar, touse)
	n = rows(X)
	k = cols(X)
	P = k*(k - 1)/2

	/* category indices */
	K    = J(1, k, .)
	idx  = J(n, k, 0)
	maxK = 2
	for (j = 1; j <= k; j++) {
		ok = (X[., j] :< .)
		cv = uniqrows(select(X[., j], ok))
		K[j] = rows(cv)
		if (K[j] < 2) {
			errprintf("variable %s is constant\n", tokens(vars)[j])
			exit(459)
		}
		if (K[j] > maxK) maxK = K[j]
		ix = J(n, 1, 1)
		for (i = 1; i < K[j]; i++) ix = ix + (X[., j] :> cv[i])
		idx[., j] = ok :* ix
	}
	cats = J(k, maxK, .)
	for (j = 1; j <= k; j++) {
		cv = uniqrows(select(X[., j], X[., j] :< .))
		cats[j, (1..K[j])] = cv'
	}
	off = 0, runningsum(K :- 1)
	q   = P + off[k + 1]

	/* pair tables and start values */
	pr   = J(P, 2, .)
	tabs = J(1, P, NULL)
	th   = J(q, 1, .)
	for (j = 1; j <= k; j++) {
		ok = (idx[., j] :> 0)
		g  = J(K[j], 1, 0)
		for (i = 1; i <= n; i++) if (ok[i]) g[idx[i, j]] = g[idx[i, j]] + w[i]
		th[(P + off[j] + 1)::(P + off[j + 1])] = pp_tau(g)
	}
	p = 0
	for (i = 1; i <= k - 1; i++) {
		for (j = i + 1; j <= k; j++) {
			p++
			pr[p, .] = (i, j)
			Tb = J(K[i], K[j], 0)
			for (a = 1; a <= n; a++) {
				if (idx[a, i] > 0 & idx[a, j] > 0) Tb[idx[a, i], idx[a, j]] = Tb[idx[a, i], idx[a, j]] + w[a]
			}
			tabs[p] = &(Tb[., .])
			th[p] = pp_rho0(Tb, pp_tauj(th, off, P, i), pp_tauj(th, off, P, j))
		}
	}

	/* ---------------- pairwise ML: Fisher scoring ---------------- */
	conv = 0
	for (it = 1; it <= maxit; it++) {
		g  = J(q, 1, 0)
		Ht = J(q, q, 0)
		for (p = 1; p <= P; p++) {
			S   = pp_cellscores(pp_tauj(th, off, P, pr[p, 1]), pp_tauj(th, off, P, pr[p, 2]), th[p], Pm)
			ind = pp_ind(p, pr[p, 1], pr[p, 2], off, P)
			g[ind']      = g[ind'] + S * vec(*tabs[p])
			Ht[ind, ind] = Ht[ind, ind] + (S :* vec(*tabs[p])') * S'
		}
		step = lusolve(Ht, g)
		if (hasmissing(step)) break
		ll0 = pp_pml_ll(th, tabs, pr, off)
		t   = 1
		while (t > 1e-10) {
			tn = th + t*step
			if (pp_valid(tn, off, P, k)) {
				if (pp_pml_ll(tn, tabs, pr, off) >= ll0 - 1e-10) break
			}
			t = t/2
		}
		if (t <= 1e-10) {
			conv = (max(abs(step)) < 1e-5)
			break
		}
		th = tn
		if (max(abs(t*step)) < tol) {
			conv = 1
			break
		}
	}
	if (it > maxit) it = maxit
	ll = pp_pml_ll(th, tabs, pr, off)

	if (method == "pml") {
		Ht = J(q, q, 0)
		U  = J(n, q, 0)
		for (p = 1; p <= P; p++) {
			i   = pr[p, 1]
			j   = pr[p, 2]
			S   = pp_cellscores(pp_tauj(th, off, P, i), pp_tauj(th, off, P, j), th[p], Pm)
			ind = pp_ind(p, i, j, off, P)
			Ht[ind, ind] = Ht[ind, ind] + (S :* vec(*tabs[p])') * S'
			ok  = selectindex((idx[., i] :> 0) :& (idx[., j] :> 0))
			cv  = idx[ok, i] + (idx[ok, j] :- 1) * K[i]
			U[ok, ind] = U[ok, ind] + S[., cv]'
		}
		Hi = invsym(Ht)
		st_local("pp_npat", ".")
	}
	else {
		/* ---------------- FIML via GHK ---------------- */
		ord  = order(idx, (1..k))
		srt  = idx[ord, .]
		newg = 1 \ (rowsum(srt[|2, 1 \ n, k|] :!= srt[|1, 1 \ n - 1, k|]) :> 0)
		gid  = J(n, 1, .)
		gid[ord] = runningsum(newg)
		pats = select(srt, newg)
		cnt  = J(rows(pats), 1, 0)
		for (i = 1; i <= n; i++) cnt[gid[i]] = cnt[gid[i]] + w[i]
		D  = draws
		Uh = J(D, k, .)
		primes = (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71)
		for (j = 1; j <= k; j++) Uh[., j] = pp_halton(D, primes[j])

		/* make the PML solution a valid correlation matrix before transforming */
		R = I(k)
		p = 0
		for (i = 1; i <= k - 1; i++) {
			for (j = i + 1; j <= k; j++) {
				p++
				R[i, j] = th[p]
				R[j, i] = th[p]
			}
		}
		if (min(symeigenvalues(R)) < 1e-3) {
			R = 0.8*R + 0.2*I(k)
			p = 0
			for (i = 1; i <= k - 1; i++) {
				for (j = i + 1; j <= k; j++) {
					p++
					th[p] = R[i, j]
				}
			}
		}
		f0 = pp_nat2free(th, off, k)

		// Fisher scoring (BHHH) in the free parametrization, started at the PML
		// estimates: the pattern-score cross-product is the information matrix,
		// so a handful of iterations suffice and each costs 2q likelihood calls
		f  = f0
		ll = pp_fll(pp_free2nat(f, off, k), pats, cnt, off, k, Uh)
		if (ll >= .) {
			errprintf("FIML log likelihood cannot be evaluated at the PML starting values\n")
			exit(430)
		}
		printf("{txt}Iteration 0:   log likelihood = {res}%s\n", strofreal(ll, "%12.0g"))
		displayflush()
		conv = 0
		for (it = 1; it <= maxit; it++) {
			S    = pp_fscores(f, pats, off, k, Uh)
			g    = S' * cnt
			Ht   = cross(S, cnt, S)
			step = cholsolve(Ht, g)
			if (hasmissing(step)) step = pinv(Ht) * g
			gs   = g' * step
			if (gs < tol) {
				conv = 1
				it--
				break
			}
			ll0 = ll
			t   = 1
			ok2 = 0
			while (t > 1e-8) {
				tn = f + t*step
				ll = pp_fll(pp_free2nat(tn, off, k), pats, cnt, off, k, Uh)
				if (ll < .) {
					if (ll >= ll0) {
						ok2 = 1
						break
					}
				}
				t = t/2
			}
			if (!ok2) {
				ll   = ll0
				conv = (gs < 1e-4)
				break
			}
			f = tn
			printf("{txt}Iteration %s:   log likelihood = {res}%s\n", strofreal(it), strofreal(ll, "%12.0g"))
			displayflush()
		}
		if (it > maxit) it = maxit
		th = pp_free2nat(f, off, k)

		// Hessian by second differences of the log likelihood in the natural
		// parameters: q(q+1)/2 + q + 1 likelihood evaluations
		printf("{txt}(computing standard errors)\n")
		displayflush()
		h  = 1e-4
		ll = pp_fll(th, pats, cnt, off, k, Uh)
		gp = J(q, 1, .)
		gm = J(q, 1, .)
		Ht = J(q, q, 0)
		for (a = 1; a <= q; a++) {
			e     = J(q, 1, 0)
			e[a]  = h
			gp[a] = pp_fll(th + e, pats, cnt, off, k, Uh)
			gm[a] = pp_fll(th - e, pats, cnt, off, k, Uh)
			Ht[a, a] = -(gp[a] - 2*ll + gm[a]) / (h*h)
		}
		for (a = 1; a <= q - 1; a++) {
			for (b = a + 1; b <= q; b++) {
				e     = J(q, 1, 0)
				e[a]  = h
				e[b]  = h
				Ht[a, b] = -(pp_fll(th + e, pats, cnt, off, k, Uh) - gp[a] - gp[b] + ll) / (h*h)
				Ht[b, a] = Ht[a, b]
			}
		}
		Sp = pp_patscores(th, pats, off, k, Uh)
		Hi = invsym(Ht)
		U  = Sp[gid, .]
		st_local("pp_npat", strofreal(rows(pats)))
	}

	/* ---------------- sandwich ---------------- */
	G = .
	if (vcetype == "cluster") {
		Uw   = w :* U
		cid  = st_data(., cidvar, touse)
		ord  = order(cid, 1)
		info = panelsetup(cid[ord], 1)
		T    = panelsum(Uw[ord, .], info)
		G    = rows(T)
		Jm   = (G/(G - 1)) * cross(T, T)
	}
	else if (wtype == "fweight") {
		Uw = sqrt(w) :* U
		nb = sum(w)
		Jm = (nb/(nb - 1)) * cross(Uw, Uw)
	}
	else {
		Uw = w :* U
		Jm = (n/(n - 1)) * cross(Uw, Uw)
	}
	V = Hi * Jm * Hi
	V = (V + V')/2

	/* ---------------- results ---------------- */
	R   = I(k)
	eq  = J(q, 1, "")
	nm  = J(q, 1, "")
	p   = 0
	for (i = 1; i <= k - 1; i++) {
		for (j = i + 1; j <= k; j++) {
			p++
			R[i, j] = th[p]
			R[j, i] = th[p]
			eq[p] = tokens(vars)[i]
			nm[p] = tokens(vars)[j]
		}
	}
	tau = J(k, maxK - 1, .)
	for (j = 1; j <= k; j++) {
		cv = pp_tauj(th, off, P, j)
		tau[j, (1..rows(cv))] = cv'
		for (i = 1; i <= rows(cv); i++) {
			eq[P + off[j] + i] = "cut_" + strofreal(j)
			nm[P + off[j] + i] = "c" + strofreal(i)
		}
	}
	mineig = min(symeigenvalues(R))
	st_matrix(bn, th')
	st_matrixcolstripe(bn, (eq, nm))
	st_matrix(vn, V)
	st_matrixcolstripe(vn, (eq, nm))
	st_matrixrowstripe(vn, (eq, nm))
	st_matrix(rn, R)
	st_matrixcolstripe(rn, (J(k, 1, ""), tokens(vars)'))
	st_matrixrowstripe(rn, (J(k, 1, ""), tokens(vars)'))
	st_matrix(taun, tau)
	st_matrixrowstripe(taun, (J(k, 1, ""), tokens(vars)'))
	st_matrix(catsn, cats)
	st_matrixrowstripe(catsn, (J(k, 1, ""), tokens(vars)'))
	st_local("pp_N",      strofreal(wtype == "fweight" ? sum(w) : n, "%21.0g"))
	st_local("pp_ll",     strofreal(ll, "%21.0g"))
	st_local("pp_conv",   strofreal(conv))
	st_local("pp_iter",   strofreal(it))
	st_local("pp_mineig", strofreal(mineig, "%21.0g"))
	st_local("pp_G",      strofreal(G))
}

end
