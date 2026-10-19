*! xtdyngcce_mata 1.0.0  12oct2026
*! Mata engine shared by xtdyncce and xtgcce
*! Dr Merwan Roudane -- merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Loading this ado compiles the Mata library. Both commands run
*   qui xtdyngcce_mata
* once at start-up so the functions are guaranteed to be in memory.
*
* STEP -> EQUATION MAP  (full version in xtdyngcce_methods.sthlp)
* ---------------------------------------------------------------------
*  xtdg_csa()      F-hat = [ybar,ybar(-1),Xbar,Xbar(-1)] + const
*                                             JST(2026) sec. 3.1
*  xtdg_ccep()     CCEP                       JST(2026) eq. (2.6)
*  xtdg_loadres()  loadings + residuals       JST(2026) eq. (3.1)-(3.2)
*                                             / (4.1)-(4.2) if bias-corr.
*  xtdg_soph()     restricted factors         JST(2026) eq. (4.8)
*  xtdg_rdwb()     recursive design WB        JST(2026) Algorithm 1 / 2
*  xtdg_hpj()      half-panel jackknife       Dhaene-Jochmans (2015)
*  xtdg_an()       analytical B1 correction   Moon-Weidner (2017)
*                                             Definition 1, Corollary 4.5
*  xtdg_dvs()      fixed-T minimum distance   De Vos-Everaert (2021)
*                                             eq. (18)-(21)
*  xtdg_loovar()   leave-one-out jackknife    JST(2026) eq. (4.4)
*  xtdg_gcce()     GCCE-MG                    Lu-Su-Ba (2026) eq. (7)-(8)
*  xtdg_gcceloo()  GCCE jackknife variance    Lu-Su-Ba (2026) eq. (14)-(15)
* ---------------------------------------------------------------------

capture program drop xtdyngcce_mata
program define xtdyngcce_mata
	version 14.0
	* no-op: loading this file compiles the Mata block below
end

version 14.0

mata:
// NOTE: no `mata clear' here. Clearing would destroy the user's own Mata
// objects, and - during ado autoload - the functions compiled a moment
// earlier by the calling command.

// =====================================================================
// SECTION 1 -- helpers
// =====================================================================

// Symmetric inverse with a generalized-inverse fallback for benign
// collinearity (a constant partialled out against a dummy, etc.).
real matrix xtdg_inv(real matrix A)
{
	real matrix B

	B = invsym(A)
	if (hasmissing(B)) {
		B = pinv(A)
	}
	if (diag0cnt(B) == rows(A)) {
		B = pinv(A)
	}
	return(B)
}

// Lag a T x c matrix by one period. Row 1 takes the supplied values.
real matrix xtdg_lag1(real matrix Z, real rowvector z0)
{
	real matrix L
	real scalar T

	T = rows(Z)
	L = J(T, cols(Z), 0)
	L[1, .] = z0
	if (T > 1) {
		L[(2..T), .] = Z[(1..T-1), .]
	}
	return(L)
}

// Significance stars from a p-value.
string scalar xtdg_star(real scalar p)
{
	if (p < 0.01) {
		return("***")
	}
	if (p < 0.05) {
		return("** ")
	}
	if (p < 0.10) {
		return("*  ")
	}
	return("   ")
}

// =====================================================================
// SECTION 2 -- cross-sectional averages
// JST(2026) sec. 3.1: Fhat = [ybar, ybar(-1), Xbar, Xbar(-1)].
// The constant is always among the columns of Fhat (JST appendix A.1.2).
// =====================================================================

// Y   : T x N
// XP  : pointer rowvector of k matrices, each T x N
// yb0 : scalar, cross-sectional mean of y(i,0)   (pre-sample)
// xb0 : 1 x k, cross-sectional means of x(i,0)   (pre-sample)
// nlag: number of lags of the averages (JST use 1)
real matrix xtdg_csa(real matrix Y, pointer(real matrix) rowvector XP,
                     real scalar yb0, real rowvector xb0,
                     real scalar nlag, real scalar wantcons)
{
	real matrix Q, Zb, Lc, prev
	real rowvector z0
	real scalar T, N, k, j, l

	T = rows(Y)
	N = cols(Y)
	k = length(XP)

	Zb = rowsum(Y) :/ N
	for (j = 1; j <= k; j++) {
		Zb = Zb , (rowsum(*XP[j]) :/ N)
	}

	Q = Zb
	if (nlag >= 1) {
		z0   = (yb0, xb0)
		prev = Zb
		for (l = 1; l <= nlag; l++) {
			if (l == 1) {
				Lc = xtdg_lag1(prev, z0)
			}
			else {
				Lc = xtdg_lag1(prev, prev[1, .])
			}
			Q    = Q , Lc
			prev = Lc
		}
	}
	if (wantcons == 1) {
		Q = J(T, 1, 1) , Q
	}
	return(Q)
}

// Residual maker:  M_Q Z = Z - Q (Q'Q)^-1 Q' Z   (never forms M)
real matrix xtdg_mq(real matrix Q, real matrix QQi, real matrix Z)
{
	return(Z - Q * (QQi * quadcross(Q, Z)))
}

// Sophisticated restricted factors, JST(2026) eq. (4.8):
//     fddot_t = zbar_t - Ahat' zbar_(t-1)
// JST sec. 4.3 is explicit that Ahat must come from the MULTI-EQUATION
// VAR(1) estimated by CCEP -- not from an OLS regression of the
// aggregates on their own lags.  Each equation of
//     z_it = A' z_(i,t-1) + Gamma_i' f_t + e_it
// is therefore fitted by CCEP against the SAME augmentation Q.
real matrix xtdg_soph(real matrix Y, pointer(real matrix) rowvector XP,
                      real matrix Q, real scalar wantcons)
{
	real matrix Zb, ZbL, A, F, Sg, Eh
	pointer(real matrix) rowvector ZP, ZL
	real colvector aj
	real scalar T, N, k, K1, j, m

	T  = rows(Y)
	N  = cols(Y)
	k  = length(XP)
	K1 = k + 1

	// z_it stacked as K1 panels of T x N, and their one-period lags
	ZP = J(1, K1, NULL)
	ZP[1] = &Y
	for (j = 1; j <= k; j++) {
		ZP[j + 1] = XP[j]
	}

	// CCEP of each z-equation on the K1 lagged z's
	A = J(K1, K1, 0)
	for (m = 1; m <= K1; m++) {
		ZL = J(1, K1, NULL)
		for (j = 1; j <= K1; j++) {
			ZL[j] = &(xtdg_lag1(*ZP[j], (*ZP[j])[1, .]))
		}
		aj = xtdg_ccep(*ZP[m], J(1, 1, 0), ZL, Q, 0, Sg = ., Eh = .)
		A[., m] = aj
	}

	Zb = rowsum(Y) :/ N
	for (j = 1; j <= k; j++) {
		Zb = Zb , (rowsum(*XP[j]) :/ N)
	}
	ZbL = xtdg_lag1(Zb, Zb[1, .])
	F   = Zb - ZbL * A
	// drop the degenerate first row contribution by re-seeding it
	F[1, .] = Zb[1, .] :- Zb[1, .]
	if (wantcons == 1) {
		F = J(T, 1, 1) , F
	}
	return(F)
}

// Assemble W_i = [ y(i,t-1) , x(i,t) ]   (T x kw).  T is passed in so
// the pure AR(1) case (k == 0, XP empty) is handled without subscripting.
real matrix xtdg_wi(real matrix YL, pointer(real matrix) rowvector XP,
                    real scalar hasar, real scalar i, real scalar T)
{
	real matrix Wi
	real scalar k, j

	k  = length(XP)
	Wi = J(T, k + hasar, 0)
	if (hasar == 1) {
		Wi[., 1] = YL[., i]
	}
	for (j = 1; j <= k; j++) {
		Wi[., hasar + j] = (*XP[j])[., i]
	}
	return(Wi)
}

// =====================================================================
// SECTION 3 -- the CCEP estimator, JST(2026) eq. (2.6)
//   dhat = (sum_i Wi' M Wi)^-1 (sum_i Wi' M yi)
// =====================================================================

real colvector xtdg_ccep(real matrix Y, real matrix YL,
                         pointer(real matrix) rowvector XP,
                         real matrix Q, real scalar hasar,
                         real matrix Sigma, real matrix Ehat)
{
	real matrix QQi, Wi, MWi, Myi, A, b
	real colvector dhat
	real scalar T, N, k, kw, i

	T  = rows(Y)
	N  = cols(Y)
	k  = length(XP)
	kw = k + hasar

	QQi = xtdg_inv(quadcross(Q, Q))
	A   = J(kw, kw, 0)
	b   = J(kw, 1, 0)

	for (i = 1; i <= N; i++) {
		Wi  = xtdg_wi(YL, XP, hasar, i, T)
		MWi = xtdg_mq(Q, QQi, Wi)
		Myi = xtdg_mq(Q, QQi, Y[., i])
		A   = A + quadcross(MWi, MWi)
		b   = b + quadcross(MWi, Myi)
	}

	Sigma = A :/ (N * T)
	dhat  = xtdg_inv(A) * b

	Ehat = J(T, N, 0)
	for (i = 1; i <= N; i++) {
		Wi = xtdg_wi(YL, XP, hasar, i, T)
		Ehat[., i] = xtdg_mq(Q, QQi, Y[., i] - Wi * dhat)
	}
	return(dhat)
}

// Clustered (Arellano 1987) sandwich -- the "CCM" of JST section 4.2.
real matrix xtdg_ccm(real matrix Y, real matrix YL,
                     pointer(real matrix) rowvector XP,
                     real matrix Q, real scalar hasar,
                     real colvector dhat)
{
	real matrix QQi, Wi, MWi, ei, A, Om
	real scalar T, N, k, kw, i

	T  = rows(Y)
	N  = cols(Y)
	k  = length(XP)
	kw = k + hasar

	QQi = xtdg_inv(quadcross(Q, Q))
	A   = J(kw, kw, 0)
	Om  = J(kw, kw, 0)

	for (i = 1; i <= N; i++) {
		Wi  = xtdg_wi(YL, XP, hasar, i, T)
		MWi = xtdg_mq(Q, QQi, Wi)
		ei  = xtdg_mq(Q, QQi, Y[., i]) - MWi * dhat
		A   = A + quadcross(MWi, MWi)
		Om  = Om + quadcross(MWi, ei) * quadcross(ei, MWi)
	}
	A = xtdg_inv(A)
	return(A * Om * A :* (N / (N - 1)))
}

// =====================================================================
// SECTION 4 -- loadings and residuals for the bootstrap DGP
// JST(2026) eq. (3.1)-(3.2); eq. (4.1)-(4.2) when dhat is bias-corrected
// =====================================================================

void xtdg_loadres(real matrix Y, real matrix YL,
                  pointer(real matrix) rowvector XP,
                  real matrix Q, real scalar hasar, real colvector dhat,
                  real matrix Eps, real matrix Gf)
{
	real matrix QQi, Wi, R
	real colvector gi
	real scalar T, N, i

	T   = rows(Y)
	N   = cols(Y)
	QQi = xtdg_inv(quadcross(Q, Q))

	Eps = J(T, N, 0)
	Gf  = J(T, N, 0)

	for (i = 1; i <= N; i++) {
		Wi = xtdg_wi(YL, XP, hasar, i, T)
		R  = Y[., i] - Wi * dhat
		gi = QQi * quadcross(Q, R)
		Gf[., i]  = Q * gi
		Eps[., i] = R - Gf[., i]
	}
}

// =====================================================================
// SECTION 6 -- bias corrections
// =====================================================================

// --- HPJ, Dhaene-Jochmans (2015) -------------------------------------
// dhat_hpj = 2*dhat - (dhat_1 + dhat_2)/2, the cross-sectional averages
// RECOMPUTED inside each half-panel. (Partialling once on the full
// sample and then splitting is NOT the same estimator -- see
// xtdyngcce_methods.sthlp, "Why not xtspj".)
real colvector xtdg_hpj(real matrix Y, real matrix YL,
                        pointer(real matrix) rowvector XP,
                        real scalar hasar, real colvector dfull,
                        real scalar yb0, real rowvector xb0,
                        real scalar nlag, real scalar wantcons,
                        real scalar overlap)
{
	real matrix Y1, Y2, YL1, YL2, Q1, Q2, Sg, Eh
	pointer(real matrix) rowvector X1, X2
	real colvector d1, d2
	real rowvector xb02
	real scalar T, k, j, h1, s2, yb02

	T  = rows(Y)
	k  = length(XP)

	h1 = floor(T / 2)
	s2 = h1 + 1
	if (mod(T, 2) == 1) {
		if (overlap == 1) {
			h1 = h1 + 1
		}
	}

	Y1  = Y[(1..h1), .]
	Y2  = Y[(s2..T), .]
	YL1 = J(1, 1, 0)
	YL2 = J(1, 1, 0)
	if (hasar == 1) {
		YL1 = YL[(1..h1), .]
		YL2 = YL[(s2..T), .]
	}

	X1 = J(1, k, NULL)
	X2 = J(1, k, NULL)
	for (j = 1; j <= k; j++) {
		X1[j] = &((*XP[j])[(1..h1), .])
		X2[j] = &((*XP[j])[(s2..T), .])
	}

	// pre-sample averages for the second half are period s2-1
	yb02 = mean(Y[s2 - 1, .]')
	xb02 = J(1, k, 0)
	for (j = 1; j <= k; j++) {
		xb02[j] = mean((*XP[j])[s2 - 1, .]')
	}

	Q1 = xtdg_csa(Y1, X1, yb0,  xb0,  nlag, wantcons)
	Q2 = xtdg_csa(Y2, X2, yb02, xb02, nlag, wantcons)

	d1 = xtdg_ccep(Y1, YL1, X1, Q1, hasar, Sg = ., Eh = .)
	d2 = xtdg_ccep(Y2, YL2, X2, Q2, hasar, Sg = ., Eh = .)

	return(2 :* dfull - (d1 + d2) :/ 2)
}

// --- AN, Moon-Weidner (2017) Definition 1 + Corollary 4.5 ------------
//   B1_k = (1/N) sum_i sum_{t=1}^{T-1} sum_{s=t+1}^{T}
//              Gamma((s-t)/M) [P_f]_ts ehat_it X_k,is
//   dhat* = dhat + What^-1 ( T^-1 B1 )
// In the CCEP setting P_f is the projection on the cross-sectional
// averages, P_Q = Q(Q'Q)^-1 Q'. Gamma is the truncation kernel, so the
// inner sum runs over 1 <= s-t <= M.
real colvector xtdg_an(real matrix Y, real matrix YL,
                       pointer(real matrix) rowvector XP,
                       real matrix Q, real scalar hasar,
                       real colvector dhat, real matrix Sigma,
                       real matrix Ehat, real scalar M)
{
	real matrix QQi, P, Wi, PT
	real colvector B1
	real scalar T, N, k, kw, i, j, t, s, smax, acc

	T  = rows(Y)
	N  = cols(Y)
	k  = length(XP)
	kw = k + hasar

	QQi = xtdg_inv(quadcross(Q, Q))
	P   = Q * QQi * Q'

	// truncated upper-triangular weights: PT[t,s] = P[t,s] if 1<=s-t<=M
	PT = J(T, T, 0)
	for (t = 1; t <= T - 1; t++) {
		smax = t + M
		if (smax > T) {
			smax = T
		}
		for (s = t + 1; s <= smax; s++) {
			PT[t, s] = P[t, s]
		}
	}

	B1 = J(kw, 1, 0)
	for (i = 1; i <= N; i++) {
		Wi = xtdg_wi(YL, XP, hasar, i, T)
		// sum_t sum_s PT[t,s] ehat_it W[s,j]  =  ehat_i' PT W_i
		B1 = B1 + (quadcross(Ehat[., i], PT * Wi))'
	}
	B1 = B1 :/ N

	return(dhat + xtdg_inv(Sigma) * (B1 :/ T))
}

// --- DVS, De Vos-Everaert (2021) eq. (18)-(21) -----------------------
//   dhat = m(d0),  m(d0) = d0 - T^-1 s2(d0) Sigma^-1 q1 upsilon(rho0,H)
//   upsilon(rho,H) = sum_{t=1}^{T-1} rho^(t-1) sum_{s=t+1}^{T} h_{s,s-t}
//   s2(d0)         = 1/(N(T-c)) sum_i || M(y_i - W_i d0) ||^2
// Solved as the fixed point d0 <- dhat + T^-1 s2(d0) Sigma^-1 q1 ups.
real colvector xtdg_dvs(real matrix Y, real matrix YL,
                        pointer(real matrix) rowvector XP,
                        real matrix Q, real scalar hasar,
                        real colvector dhat, real matrix Sigma,
                        real scalar maxit, real scalar tol,
                        real scalar conv, real scalar ups_out)
{
	real matrix QQi, H, Wi, Si, Rz
	real colvector d0, dnew, q1, hsum
	real scalar T, N, k, kw, c, i, t, s, ups, s2, rho, it, dif, acc, done

	T  = rows(Y)
	N  = cols(Y)
	k  = length(XP)
	kw = k + hasar
	c  = cols(Q)

	conv    = 0
	ups_out = 0
	if (hasar == 0) {
		conv = 1
		return(dhat)
	}
	if (T <= c) {
		conv = -1
		return(dhat)
	}

	QQi = xtdg_inv(quadcross(Q, Q))
	H   = Q * QQi * Q'
	Si  = xtdg_inv(Sigma)

	// hsum[t] = sum_{s=t+1}^{T} h_{s,s-t}, precomputed once
	hsum = J(T - 1, 1, 0)
	for (t = 1; t <= T - 1; t++) {
		acc = 0
		for (s = t + 1; s <= T; s++) {
			acc = acc + H[s, s - t]
		}
		hsum[t] = acc
	}

	q1    = J(kw, 1, 0)
	q1[1] = 1

	d0   = dhat
	done = 0
	for (it = 1; it <= maxit; it++) {
		if (done == 0) {

			rho = d0[1]
			if (abs(rho) >= 0.9999) {
				rho = sign(rho) * 0.9999
			}

			ups = 0
			for (t = 1; t <= T - 1; t++) {
				ups = ups + (rho^(t - 1)) * hsum[t]
			}

			s2 = 0
			for (i = 1; i <= N; i++) {
				Wi = xtdg_wi(YL, XP, hasar, i, T)
				Rz = xtdg_mq(Q, QQi, Y[., i] - Wi * d0)
				s2 = s2 + quadcross(Rz, Rz)
			}
			s2 = s2 / (N * (T - c))

			dnew = dhat + (s2 / T) :* (Si * q1) :* ups
			dif  = max(abs(dnew - d0))
			d0   = dnew
			if (dif < tol) {
				conv    = 1
				ups_out = ups
				done    = 1
			}
		}
	}
	if (conv == 0) {
		ups_out = ups
	}
	return(d0)
}

// =====================================================================
// SECTION 5 -- recursive-design wild bootstrap, JST Algorithm 1 / 2
// The regressors x are held FIXED (JST sec. 3.1); y* is regenerated
// recursively and the cross-sectional averages are RE-ESTIMATED from
// the bootstrap data every draw (JST step 4). That re-estimation is
// what separates RD-WB from a residual wild bootstrap.
// =====================================================================

// Wild weights, T x N.  wtype: 1 Rademacher (JST's own choice),
// 2 Mammen two-point, 3 standard normal.
real matrix xtdg_wild(real scalar T, real scalar N, real scalar wtype)
{
	real matrix Pm
	real scalar pm

	if (wtype == 1) {
		return((runiform(T, N) :> 0.5) :* 2 :- 1)
	}
	if (wtype == 2) {
		pm = (sqrt(5) + 1) / (2 * sqrt(5))
		Pm = (runiform(T, N) :< pm)
		return(Pm :* (-(sqrt(5) - 1) / 2) + (1 :- Pm) :* ((sqrt(5) + 1) / 2))
	}
	return(rnormal(T, N, 0, 1))
}

// ONE recursive-design draw.  Given the DGP pieces (alpha, Xb = beta'x,
// Gf = gamma_i' f_t, Eps) it regenerates y* recursively from
// y*(i,0) = y(i,0), RE-ESTIMATES the cross-sectional averages from the
// bootstrap data, and returns the CCEP estimate of that draw.
// Ys_out / YLs_out hand the bootstrap panel back for a second round.
real colvector xtdg_draw1(real scalar alpha, real matrix Xb,
                          real matrix Gf, real matrix Eps,
                          pointer(real matrix) rowvector XP,
                          real scalar hasar, real rowvector y0,
                          real scalar yb0, real rowvector xb0,
                          real scalar nlag, real scalar wantcons,
                          real scalar wtype, real scalar soph,
                          real matrix Q0,
                          real matrix Ys_out, real matrix YLs_out,
                          real matrix Qs_out, real matrix Sg_out,
                          real matrix Eh_out)
{
	real matrix Om, U
	real scalar T, N, t

	T = rows(Eps)
	N = cols(Eps)

	Om = xtdg_wild(T, N, wtype)
	U  = Xb + Gf + Om :* Eps

	Ys_out  = J(T, N, 0)
	YLs_out = J(T, N, 0)
	if (hasar == 1) {
		YLs_out[1, .] = y0
		Ys_out[1, .]  = alpha :* y0 + U[1, .]
		for (t = 2; t <= T; t++) {
			YLs_out[t, .] = Ys_out[t-1, .]
			Ys_out[t, .]  = alpha :* Ys_out[t-1, .] + U[t, .]
		}
	}
	else {
		Ys_out = U
	}

	if (soph == 1) {
		Qs_out = xtdg_soph(Ys_out, XP, Q0, wantcons)
	}
	else {
		Qs_out = xtdg_csa(Ys_out, XP, yb0, xb0, nlag, wantcons)
	}

	return(xtdg_ccep(Ys_out, YLs_out, XP, Qs_out, hasar, Sg_out = ., Eh_out = .))
}

// beta' x_it -- fixed across all replications (JST sec. 3.1)
real matrix xtdg_xb(pointer(real matrix) rowvector XP, real colvector dhat,
                    real scalar hasar, real scalar T, real scalar N)
{
	real matrix Xb
	real scalar k, j

	k  = length(XP)
	Xb = J(T, N, 0)
	for (j = 1; j <= k; j++) {
		Xb = Xb + (*XP[j]) :* dhat[hasar + j]
	}
	return(Xb)
}

// --- per-draw bias correction, JST appendix A.1.2 --------------------
// "we proceed with the bootstrap, but now obtain a set of bias-corrected
//  estimates".  Each bootstrap replication must receive the SAME
//  correction as the observed estimate, otherwise the studentized
//  statistic is not centred at zero and the interval misses.
// bcode: 0 none, 1 HPJ, 2 AN, 3 DVS
real colvector xtdg_bc(real matrix Yd, real matrix YLd,
                       pointer(real matrix) rowvector XP, real matrix Qd,
                       real scalar hasar, real colvector draw,
                       real matrix Sgd, real matrix Ehd,
                       real scalar yb0, real rowvector xb0,
                       real scalar nlag, real scalar wantcons,
                       real scalar bcode, real scalar anbw,
                       real scalar dvsit, real scalar dvstol)
{
	real scalar cv, up

	if (bcode == 1) {
		return(xtdg_hpj(Yd, YLd, XP, hasar, draw, yb0, xb0, nlag,
		                wantcons, 1))
	}
	if (bcode == 2) {
		return(xtdg_an(Yd, YLd, XP, Qd, hasar, draw, Sgd, Ehd, anbw))
	}
	if (bcode == 3) {
		return(xtdg_dvs(Yd, YLd, XP, Qd, hasar, draw, Sgd, dvsit,
		                dvstol, cv = ., up = .))
	}
	return(draw)
}

// First-round RD-WB.  Returns B x kw draws, each carrying the same bias
// correction as the observed estimate (bcode).
real matrix xtdg_rdwb(real matrix Y, pointer(real matrix) rowvector XP,
                      real scalar hasar, real colvector dhat,
                      real matrix Gf, real matrix Eps, real matrix Q0,
                      real rowvector y0, real scalar yb0,
                      real rowvector xb0, real scalar nlag,
                      real scalar wantcons, real scalar B,
                      real scalar wtype, real scalar soph,
                      real scalar bcode, real scalar anbw,
                      real scalar dvsit, real scalar dvstol,
                      real scalar trace)
{
	real matrix Xb, Bdraw, Ys, YLs, Qs, Sgd, Ehd
	real colvector db
	real scalar T, N, k, kw, b, alpha

	T  = rows(Y)
	N  = cols(Y)
	k  = length(XP)
	kw = k + hasar

	alpha = 0
	if (hasar == 1) {
		alpha = dhat[1]
	}
	Xb    = xtdg_xb(XP, dhat, hasar, T, N)
	Bdraw = J(B, kw, .)

	for (b = 1; b <= B; b++) {
		db = xtdg_draw1(alpha, Xb, Gf, Eps, XP, hasar, y0, yb0, xb0,
		                nlag, wantcons, wtype, soph, Q0,
		                Ys = ., YLs = ., Qs = ., Sgd = ., Ehd = .)
		if (bcode > 0) {
			db = xtdg_bc(Ys, YLs, XP, Qs, hasar, db, Sgd, Ehd, yb0,
			             xb0, nlag, wantcons, bcode, anbw, dvsit, dvstol)
		}
		Bdraw[b, .] = db'

		if (trace == 1) {
			if (mod(b, 100) == 0) {
				printf("{txt}    bootstrap draw %f of %f\n", b, B)
				displayflush()
			}
		}
	}
	return(Bdraw)
}

// ITERATED (double) RD-WB, JST(2026) eq. (4.6), following Heller &
// Jochmans (2026).  For each of the B first-round draws a second round
// of D draws runs INSIDE the bootstrap world, giving the bootstrap-world
// standard error and hence the studentized statistic
//     t*_b = (dhat*_b - dhat) / se*(dhat*_b).
// Both rounds hold the regressors fixed, which is what makes the
// iteration applicable here (JST sec. 4.2).
real matrix xtdg_rdwb2(real matrix Y, pointer(real matrix) rowvector XP,
                       real scalar hasar, real colvector dhat,
                       real matrix Gf, real matrix Eps, real matrix Q0,
                       real rowvector y0, real scalar yb0,
                       real rowvector xb0, real scalar nlag,
                       real scalar wantcons, real scalar B,
                       real scalar D, real scalar wtype,
                       real scalar soph, real scalar bcode,
                       real scalar anbw, real scalar dvsit,
                       real scalar dvstol, real scalar trace,
                       real matrix Tstat)
{
	real matrix Xb, Bdraw, Ys, YLs, Qs, Sgd, Ehd, Eps2, Gf2, Xb2, Inner
	real matrix Ys2, YLs2, Qs2, Sg2, Eh2
	real colvector db, dd
	real rowvector sd
	real scalar T, N, k, kw, b, dix, j, alpha, alpha2

	T  = rows(Y)
	N  = cols(Y)
	k  = length(XP)
	kw = k + hasar

	alpha = 0
	if (hasar == 1) {
		alpha = dhat[1]
	}
	Xb    = xtdg_xb(XP, dhat, hasar, T, N)
	Bdraw = J(B, kw, .)
	Tstat = J(B, kw, .)

	for (b = 1; b <= B; b++) {

		db = xtdg_draw1(alpha, Xb, Gf, Eps, XP, hasar, y0, yb0, xb0,
		                nlag, wantcons, wtype, soph, Q0,
		                Ys = ., YLs = ., Qs = ., Sgd = ., Ehd = .)
		if (bcode > 0) {
			db = xtdg_bc(Ys, YLs, XP, Qs, hasar, db, Sgd, Ehd, yb0,
			             xb0, nlag, wantcons, bcode, anbw, dvsit, dvstol)
		}
		Bdraw[b, .] = db'

		// second round inside the bootstrap world
		xtdg_loadres(Ys, YLs, XP, Qs, hasar, db, Eps2 = ., Gf2 = .)
		alpha2 = 0
		if (hasar == 1) {
			alpha2 = db[1]
		}
		Xb2   = xtdg_xb(XP, db, hasar, T, N)
		Inner = J(D, kw, .)
		for (dix = 1; dix <= D; dix++) {
			dd = xtdg_draw1(alpha2, Xb2, Gf2, Eps2, XP, hasar, y0, yb0,
			                xb0, nlag, wantcons, wtype, soph, Qs,
			                Ys2 = ., YLs2 = ., Qs2 = ., Sg2 = ., Eh2 = .)
			if (bcode > 0) {
				dd = xtdg_bc(Ys2, YLs2, XP, Qs2, hasar, dd, Sg2, Eh2,
				             yb0, xb0, nlag, wantcons, bcode, anbw,
				             dvsit, dvstol)
			}
			Inner[dix, .] = dd'
		}

		sd = J(1, kw, .)
		for (j = 1; j <= kw; j++) {
			sd[j] = sqrt(variance(Inner[., j]))
			if (sd[j] > 0) {
				Tstat[b, j] = (db[j] - dhat[j]) / sd[j]
			}
		}

		if (trace == 1) {
			if (mod(b, 20) == 0) {
				printf("{txt}    iterated bootstrap draw %f of %f\n", b, B)
				displayflush()
			}
		}
	}
	return(Bdraw)
}

// =====================================================================
// SECTION 7 -- leave-one-out jackknife variance, JST(2026) eq. (4.4)
// Critical: the cross-sectional averages are recomputed WITHOUT unit i,
// not merely the regression. summclust / a cluster jackknife on the
// partialled data does NOT do this.
// =====================================================================

real matrix xtdg_loovar(real matrix Y, real matrix YL,
                        pointer(real matrix) rowvector XP,
                        real scalar hasar, real scalar yb0,
                        real rowvector xb0, real scalar nlag,
                        real scalar wantcons, real scalar trace,
                        real matrix D_out)
{
	real matrix Yi, YLi, Qi, Sg, Eh, V
	pointer(real matrix) rowvector Xi
	real colvector di, dbar
	real rowvector keep
	real scalar T, N, k, kw, i, j

	T  = rows(Y)
	N  = cols(Y)
	k  = length(XP)
	kw = k + hasar

	D_out = J(N, kw, .)

	for (i = 1; i <= N; i++) {
		if (i == 1) {
			keep = (2..N)
		}
		else if (i == N) {
			keep = (1..(N-1))
		}
		else {
			keep = ((1..(i-1)), ((i+1)..N))
		}

		Yi  = Y[., keep]
		YLi = J(1, 1, 0)
		if (hasar == 1) {
			YLi = YL[., keep]
		}
		Xi = J(1, k, NULL)
		for (j = 1; j <= k; j++) {
			Xi[j] = &((*XP[j])[., keep])
		}
		Qi = xtdg_csa(Yi, Xi, yb0, xb0, nlag, wantcons)
		di = xtdg_ccep(Yi, YLi, Xi, Qi, hasar, Sg = ., Eh = .)
		D_out[i, .] = di'

		if (trace == 1) {
			if (mod(i, 50) == 0) {
				printf("{txt}    jackknife unit %f of %f\n", i, N)
				displayflush()
			}
		}
	}

	dbar = (colsum(D_out) :/ N)'
	V = J(kw, kw, 0)
	for (i = 1; i <= N; i++) {
		V = V + (D_out[i, .]' - dbar) * (D_out[i, .]' - dbar)'
	}
	// "conventional" jackknife scaling in the sense of Hansen (2026)
	V = V :* ((N - 1) / N)
	return(V)
}

// =====================================================================
// SECTION 8 -- GCCE, Lu-Su-Ba (2026)
// eq. (7):  y_it = b_i' x_it + d_i' zbar_t + phi_t' xbar^a_i + e_it
// eq. (8):  bhat_MG = (1/N) sum_i bhat_i
//   bhat = [X'(M_xbar^a kron M_zbar) X]^-1 X'(M_xbar^a kron M_zbar) Y
// X is block diagonal, so block (i,j) of the system matrix is
//   [M_xbar^a]_ij * (Xtil_i' Xtil_j),  Xtil_i = M_zbar x_i.
// The NT x NT Kronecker is NEVER formed.
// Remark 2 of the paper: xbar^a_i = (1, xbar_i')' EXCLUDES ybar_i,
// because ybar_i mixes lambda_i with gamma_i beta_i and proxies nothing.
// =====================================================================

// Returns the Nk x 1 stacked coefficient vector; Bi_out is N x k.
real colvector xtdg_gccefit(real matrix Y, pointer(real matrix) rowvector XP,
                            real matrix Zb, real matrix Xa,
                            real matrix Bi_out)
{
	real matrix Gz, Xt, Yt, Gr, Hr, A, Ak, Ar, S, rhs
	real colvector bst
	real scalar T, N, k, i, j

	T = rows(Y)
	N = cols(Y)
	k = length(XP)

	// --- M_zbar within units ----------------------------------------
	Gz = xtdg_inv(quadcross(Zb, Zb))
	Yt = Y - Zb * (Gz * quadcross(Zb, Y))               // T x N
	Xt = J(T, N * k, 0)                                  // T x (N*k)
	for (j = 1; j <= k; j++) {
		S = (*XP[j]) - Zb * (Gz * quadcross(Zb, *XP[j]))
		for (i = 1; i <= N; i++) {
			Xt[., (i-1)*k + j] = S[., i]
		}
	}

	// --- Gram blocks -------------------------------------------------
	Gr = quadcross(Xt, Xt)      // (Nk) x (Nk), block (i,j) = Xt_i' Xt_j
	Hr = quadcross(Xt, Yt)      // (Nk) x N,    block (i,j) = Xt_i' yt_j

	// --- M_xbar^a across units ---------------------------------------
	A  = I(N) - Xa * (xtdg_inv(quadcross(Xa, Xa)) * Xa')   // N x N
	Ak = A # J(k, k, 1)                                     // (Nk)x(Nk)
	Ar = A # J(k, 1, 1)                                     // (Nk)x N

	S   = Gr :* Ak
	rhs = rowsum(Hr :* Ar)

	bst    = xtdg_inv(S) * rhs
	Bi_out = colshape(bst, k)
	return(bst)
}

// Full GCCE-MG estimate.
real colvector xtdg_gcce(real matrix Y, pointer(real matrix) rowvector XP,
                         real matrix Bi_out, real matrix Zb, real matrix Xa)
{
	real colvector bst
	real scalar T, N, k, j

	T = rows(Y)
	N = cols(Y)
	k = length(XP)

	// zbar_t : cross-sectional averages of (y, x) -- T x (k+1)
	Zb = rowsum(Y) :/ N
	for (j = 1; j <= k; j++) {
		Zb = Zb , (rowsum(*XP[j]) :/ N)
	}
	// xbar^a_i = (1, xbar_i')' -- N x (k+1); ybar_i deliberately absent
	Xa = J(N, 1, 1)
	for (j = 1; j <= k; j++) {
		Xa = Xa , (colsum(*XP[j]) :/ T)'
	}

	bst = xtdg_gccefit(Y, XP, Zb, Xa, Bi_out = .)
	return((colsum(Bi_out) :/ N)')
}

// Leave-one-out jackknife variance, Lu-Su-Ba (2026) eq. (14)-(15).
// NOTE: the paper keeps zbar_t at its FULL-sample value inside the
// leave-one-out fit ("we treat zbar_t as a proxy for the unobserved
// factor that does not vary across i"); only X, Y and xbar^a drop unit i.
real matrix xtdg_gcceloo(real matrix Y, pointer(real matrix) rowvector XP,
                         real matrix Zb, real colvector bmg,
                         real scalar trace, real matrix D_out)
{
	real matrix Yi, Xai, Bi, V
	pointer(real matrix) rowvector Xi
	real colvector bi, bbar
	real rowvector keep
	real scalar T, N, k, i, j

	T = rows(Y)
	N = cols(Y)
	k = length(XP)

	D_out = J(N, k, .)

	for (i = 1; i <= N; i++) {
		if (i == 1) {
			keep = (2..N)
		}
		else if (i == N) {
			keep = (1..(N-1))
		}
		else {
			keep = ((1..(i-1)), ((i+1)..N))
		}

		Yi = Y[., keep]
		Xi = J(1, k, NULL)
		for (j = 1; j <= k; j++) {
			Xi[j] = &((*XP[j])[., keep])
		}
		Xai = J(N - 1, 1, 1)
		for (j = 1; j <= k; j++) {
			Xai = Xai , (colsum(*Xi[j]) :/ T)'
		}

		// zbar kept at its full-sample value (paper, footnote 5)
		bi = xtdg_gccefit(Yi, Xi, Zb, Xai, Bi = .)
		D_out[i, .] = (colsum(Bi) :/ (N - 1))

		if (trace == 1) {
			if (mod(i, 25) == 0) {
				printf("{txt}    jackknife unit %f of %f\n", i, N)
				displayflush()
			}
		}
	}

	bbar = (colsum(D_out) :/ N)'
	V = J(k, k, 0)
	for (i = 1; i <= N; i++) {
		V = V + (D_out[i, .]' - bbar) * (D_out[i, .]' - bbar)'
	}
	// eq. (15): Omegahat = (N-1) sum_i (.)(.)',  Avar(bhat_MG) = Omega/N
	V = V :* (N - 1)
	return(V)
}


// =====================================================================
// Driver for xtdyncce
// =====================================================================

void xtdyncce_work(string scalar yname, string scalar lyname,
                   string scalar xnames, string scalar lxnames,
                   string scalar touse, string scalar ivar,
                   string scalar tvar,
                   real scalar hasar, real scalar crlags,
                   real scalar wantcons,
                   string scalar biasadj, real scalar anbw,
                   real scalar dvsit, real scalar dvstol,
                   string scalar vce, real scalar B, real scalar D,
                   real scalar wtype, real scalar soph, real scalar stud,
                   real scalar medbc, real scalar level, real scalar trc,
                   string scalar bname, string scalar Vname,
                   string scalar BDname, string scalar LOname,
                   string scalar HIname, string scalar DJname)
{
	real matrix Y, YL, XL, Q, Sg, Eh, V, Bd, Dj, Eps, Gf, Tst
	pointer(real matrix) rowvector XP
	real colvector d0, d, dd, tmp, drep
	real rowvector y0, xb0, lo, hi, se
	real scalar T, N, k, kw, i, j, b, yb0, cv, up, a, lq, uq, bcode
	string rowvector xs
	real matrix raw, Xall

	// ---- read the data as T x N blocks ------------------------------
	raw = st_data(., yname, touse)
	N   = rows(uniqrows(st_data(., ivar, touse)))
	T   = rows(raw) / N
	Y   = colshape(raw, T)'

	YL = J(1, 1, 0)
	y0 = J(1, N, 0)
	yb0 = 0
	if (hasar == 1) {
		YL  = colshape(st_data(., lyname, touse), T)'
		y0  = YL[1, .]
		yb0 = mean(YL[1, .]')
	}
	else {
		y0  = Y[1, .]
		yb0 = mean(Y[1, .]')
	}

	xs = tokens(xnames)
	k  = length(xs)
	kw = k + hasar
	XP = J(1, k, NULL)
	xb0 = J(1, k, 0)
	if (k > 0) {
		Xall = st_data(., xs, touse)
		XL   = st_data(., tokens(lxnames), touse)
		for (j = 1; j <= k; j++) {
			XP[j] = &(colshape(Xall[., j], T)')
			tmp   = colshape(XL[., j], T)'[1, .]'
			if (hasmissing(tmp)) {
				xb0[j] = mean((*XP[j])[1, .]')
			}
			else {
				xb0[j] = mean(tmp)
			}
		}
	}

	// ---- cross-sectional averages, JST sec. 3.1 ---------------------
	Q = xtdg_csa(Y, XP, yb0, xb0, crlags, wantcons)

	// ---- CCEP, JST eq. (2.6) ----------------------------------------
	d0 = xtdg_ccep(Y, YL, XP, Q, hasar, Sg = ., Eh = .)
	d  = d0

	// ---- bias correction --------------------------------------------
	if (biasadj == "hpj") {
		d = xtdg_hpj(Y, YL, XP, hasar, d0, yb0, xb0, crlags, wantcons, 1)
	}
	else if (biasadj == "an") {
		d = xtdg_an(Y, YL, XP, Q, hasar, d0, Sg, Eh, anbw)
	}
	else if (biasadj == "dvs") {
		d = xtdg_dvs(Y, YL, XP, Q, hasar, d0, Sg, dvsit, dvstol, cv = ., up = .)
		if (cv != 1) {
			printf("{err}warning: DVS fixed point not converged in %f iterations\n", dvsit)
		}
	}

	// ---- variance ----------------------------------------------------
	Bd = J(1, 1, .)
	Dj = J(1, 1, .)
	lo = J(1, kw, .)
	hi = J(1, kw, .)
	a  = (100 - level) / 200

	if (vce == "ccm") {
		V  = xtdg_ccm(Y, YL, XP, Q, hasar, d)
		se = sqrt(diagonal(V))'
		lo = d' :- invnormal(1 - a) :* se
		hi = d' :+ invnormal(1 - a) :* se
	}
	else if (vce == "jackknife") {
		if (trc == 1) {
			printf("{txt}  leave-one-out jackknife over %f panels ...\n", N)
			displayflush()
		}
		V  = xtdg_loovar(Y, YL, XP, hasar, yb0, xb0, crlags, wantcons, trc, Dj = .)
		se = sqrt(diagonal(V))'
		lo = d' :- invnormal(1 - a) :* se
		hi = d' :+ invnormal(1 - a) :* se
	}
	else {
		// ---- recursive-design wild bootstrap, JST Algorithm 1 / 2 ---
		// Algorithm 2 when d is bias-corrected: the loadings and
		// residuals are rebuilt from the CORRECTED coefficients
		// (JST eq. (4.1)-(4.2)).  Every bootstrap draw then receives
		// the SAME correction (JST appendix A.1.2) so that the
		// studentized statistic is centred at zero.
		xtdg_loadres(Y, YL, XP, Q, hasar, d, Eps = ., Gf = .)

		bcode = 0
		if (biasadj == "hpj") {
			bcode = 1
		}
		if (biasadj == "an") {
			bcode = 2
		}
		if (biasadj == "dvs") {
			bcode = 3
		}

		if (stud == 1) {
			if (trc == 1) {
				printf("{txt}  iterated RD-WB: %f x %f draws ...\n", B, D)
				displayflush()
			}
			Bd = xtdg_rdwb2(Y, XP, hasar, d, Gf, Eps, Q, y0, yb0, xb0,
			                crlags, wantcons, B, D, wtype, soph, bcode,
			                anbw, dvsit, dvstol, trc, Tst = .)
			// JST sec. 4.2: the REAL-world scale is the leave-one-out
			// jackknife (eq. 4.4); the bootstrap supplies only the
			// quantiles of the studentized statistic.
			V  = xtdg_loovar(Y, YL, XP, hasar, yb0, xb0, crlags,
			                 wantcons, 0, Dj = .)
			se = sqrt(diagonal(V))'
		}
		else {
			if (trc == 1) {
				printf("{txt}  recursive-design wild bootstrap, %f draws ...\n", B)
				displayflush()
			}
			Bd  = xtdg_rdwb(Y, XP, hasar, d, Gf, Eps, Q, y0, yb0, xb0,
			                crlags, wantcons, B, wtype, soph, bcode,
			                anbw, dvsit, dvstol, trc)
			Tst = J(B, kw, .)
			V   = J(kw, kw, 0)
			for (j = 1; j <= kw; j++) {
				V[j, j] = variance(Bd[., j])
			}
			se = sqrt(diagonal(V))'
		}

		lq = ceil(a * B)
		uq = ceil((1 - a) * B)
		if (lq < 1) {
			lq = 1
		}
		if (uq > B) {
			uq = B
		}

		// Median bias correction (Higgins & Jochmans 2024) FIRST, so the
		// studentized interval is centred on the reported estimate.
		// The equal-tailed reverse percentile interval needs no shift:
		// its own midpoint 2d - q(0.5) IS the median-corrected estimate.
		drep = d
		if (medbc == 1) {
			for (j = 1; j <= kw; j++) {
				tmp     = sort(Bd[., j], 1)
				drep[j] = 2 * d[j] - tmp[ceil(0.5 * B)]
			}
		}

		for (j = 1; j <= kw; j++) {
			if (stud == 1) {
				// JST appendix A.1.2: t* is formed from
				// (dhat* - dhat), so the studentized interval must be
				// centred on THAT dhat -- the (possibly bias-corrected)
				// CCEP estimate -- not on a separately median-shifted
				// point estimate.  Mixing the two centres displaces the
				// interval by the bias and destroys coverage.
				tmp   = sort(Tst[., j], 1)
				lo[j] = d[j] - tmp[uq] * se[j]
				hi[j] = d[j] - tmp[lq] * se[j]
			}
			else {
				tmp   = sort(Bd[., j], 1)
				lo[j] = 2 * d[j] - tmp[uq]
				hi[j] = 2 * d[j] - tmp[lq]
			}
		}
		d = drep
	}

	// ---- hand back ----------------------------------------------------
	st_matrix(bname,  d')
	st_matrix(Vname,  V)
	st_matrix(LOname, lo)
	st_matrix(HIname, hi)
	st_matrix(BDname, Bd)
	st_matrix(DJname, Dj)
}


// =====================================================================
// Driver for xtgcce
// =====================================================================

void xtgcce_work(string scalar yname, string scalar xnames,
                 string scalar touse, string scalar ivar,
                 real scalar dojack, real scalar docce,
                 real scalar level, real scalar trc,
                 string scalar bname, string scalar Vname,
                 string scalar BIname, string scalar LOname,
                 string scalar HIname, string scalar DJname,
                 string scalar BCname)
{
	real matrix Y, Bi, Zb, Xa, V, Dj, Xall, Xi, Bc
	pointer(real matrix) rowvector XP
	real colvector b, bcce, bb
	real rowvector lo, hi, se
	real scalar T, N, k, i, j, a

	// ---- read as T x N blocks ---------------------------------------
	Y = st_data(., yname, touse)
	N = rows(uniqrows(st_data(., ivar, touse)))
	T = rows(Y) / N
	Y = colshape(Y, T)'

	XP   = J(1, 0, NULL)
	Xall = st_data(., tokens(xnames), touse)
	k    = cols(Xall)
	XP   = J(1, k, NULL)
	for (j = 1; j <= k; j++) {
		XP[j] = &(colshape(Xall[., j], T)')
	}

	// ---- GCCE-MG, Lu-Su-Ba eq. (7)-(8) ------------------------------
	b = xtdg_gcce(Y, XP, Bi = ., Zb = ., Xa = .)

	// ---- variance ----------------------------------------------------
	a  = (100 - level) / 200
	lo = J(1, k, .)
	hi = J(1, k, .)
	Dj = J(1, 1, .)
	V  = J(k, k, 0)

	if (dojack == 1) {
		if (trc == 1) {
			printf("{txt}  leave-one-out jackknife over %f panels ...\n", N)
			displayflush()
		}
		// eq. (15): Omegahat estimates the variance of sqrt(N)(b - b0),
		// so Avar(bhat_MG) = Omegahat / N.
		V  = xtdg_gcceloo(Y, XP, Zb, b, trc, Dj = .) :/ N
		se = sqrt(diagonal(V))'
		lo = b' :- invnormal(1 - a) :* se
		hi = b' :+ invnormal(1 - a) :* se
	}

	// ---- optional conventional CCE-MG for comparison -----------------
	Bc = J(1, k, .)
	if (docce == 1) {
		bcce = J(k, 1, 0)
		for (i = 1; i <= N; i++) {
			Xi = J(T, k, 0)
			for (j = 1; j <= k; j++) {
				Xi[., j] = (*XP[j])[., i]
			}
			Xi = Xi , J(T, 1, 1) , Zb
			bb = xtdg_inv(quadcross(Xi, Xi)) * quadcross(Xi, Y[., i])
			bcce = bcce + bb[(1..k)]
		}
		Bc = (bcce :/ N)'
	}

	st_matrix(bname,  b')
	st_matrix(Vname,  V)
	st_matrix(BIname, Bi)
	st_matrix(LOname, lo)
	st_matrix(HIname, hi)
	st_matrix(DJname, Dj)
	st_matrix(BCname, Bc)
}

end
