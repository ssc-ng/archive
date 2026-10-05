*! _xtmvu_mata  v1.0.0  03oct2026  Yusuf Toyin Yusuf
*! Mata engine: panel multivariate ARDL unit root / cointegration test
*! (extends Sam, McNown, Goh and Goh 2024).  Loaded with -do- by _xtmvu_load.
mata:
mata set matastrict off

real scalar xmu_loaded()
{
	return(1)
}

// columns of the F-test (1-based, in the design matrix)
real rowvector xmu_fidx(real scalar k, real scalar cs)
{
	real rowvector f
	f = (2..k+1)
	if (cs==4) f = f, (k+3)
	return(f)
}

real colvector xmu_dy(real colvector y)
{
	real scalar T
	real colvector dy
	T = rows(y)
	dy = J(T,1,.)
	dy[|2\T|] = y[|2\T|] - y[|1\T-1|]
	return(dy)
}

// design matrix: [Ly, Lx(k), const, (trend), Dy lags(p), DX lags(q*k), DX contemporaneous(k)]
// dependent rows are s0+1..T (s0 = number of pre-sample rows)
real matrix xmu_Z(real colvector y, real matrix X, real scalar p, real scalar q, real scalar cs, real scalar s0)
{
	real scalar T, k, n, j
	real colvector idx, dy
	real matrix Z, dX
	T = rows(y); k = cols(X); n = T - s0
	idx = (s0+1::T)
	dy = xmu_dy(y)
	dX = J(T,k,.)
	dX[|2,1\T,k|] = X[|2,1\T,k|] - X[|1,1\T-1,k|]
	Z = y[idx :- 1], X[idx :- 1, .], J(n,1,1)
	if (cs==4 | cs==5) Z = Z, idx
	for (j=1; j<=p; j++) Z = Z, dy[idx :- j]
	for (j=1; j<=q; j++) Z = Z, dX[idx :- j, .]
	Z = Z, dX[idx, .]
	return(Z)
}

// (t on Ly, F on fidx columns, rss, m)
real rowvector xmu_stats(real matrix Z, real colvector dep, real rowvector fidx)
{
	real scalar n, m, rss, s2, t, F
	real matrix A
	real colvector b, r, bf
	n = rows(Z); m = cols(Z)
	A = invsym(cross(Z,Z))
	b = A*cross(Z,dep)
	r = dep - Z*b
	rss = cross(r,r)
	s2 = rss/(n-m)
	t = b[1]/sqrt(s2*A[1,1])
	bf = b[fidx',1]
	F = (bf' * invsym(A[fidx,fidx]) * bf) / (s2*cols(fidx))
	return((t, F, rss, m))
}

// lag selection on a common sample (first maxlag+1 rows are pre-sample); crit 1=AIC 2=BIC
real rowvector xmu_select(real colvector y, real matrix X, real scalar maxlag, real scalar cs, real scalar crit)
{
	real scalar p, q, s0, n, m, ic, best, pen, bp, bq, rss, T
	real matrix Z, A
	real colvector dep, b, r, dy
	T = rows(y)
	s0 = maxlag + 1
	n = T - s0
	pen = (crit==1 ? 2 : ln(n))
	dy = xmu_dy(y)
	dep = dy[|s0+1\T|]
	best = .; bp = .; bq = .
	for (p=0; p<=maxlag; p++) {
		for (q=0; q<=maxlag; q++) {
			Z = xmu_Z(y,X,p,q,cs,s0)
			m = cols(Z)
			if (m > n-8) continue
			A = invsym(cross(Z,Z))
			b = A*cross(Z,dep)
			r = dep - Z*b
			rss = cross(r,r)
			ic = n*ln(rss/n) + pen*m
			if (best==. | ic < best) {
				best = ic; bp = p; bq = q
			}
		}
	}
	return((bp,bq))
}

// one-unit bootstrap: joint null (pi=0, delta=0 [, trend=0 in Case 4]), drift-free generating
// process, residuals centred/rescaled and resampled with the supplied index matrix ridx (B x n).
// resel=1: lags are re-selected inside every draw (all (p,q) up to maxlag, criterion crit).
real matrix xmu_bunit(real colvector y, real matrix X, real scalar p, real scalar q, real scalar cs, real scalar s0, real scalar B, real matrix ridx, real scalar resel, real scalar maxlag, real scalar crit)
{
	real scalar T, k, n, m, ntr, b, j, l, t, v, pp_, qq, ic, best, pen, mm, bt, bF
	real rowvector keep, kidx, posd, posf, fidx, st
	real colvector dep, br, er, fp, phi, ys, dys, idx, dy
	real matrix Z, Zr, Zs, Zb, out
	T = rows(y); k = cols(X); ntr = (cs==4 | cs==5)
	Z = xmu_Z(y,X,p,q,cs,s0)
	n = rows(Z); m = cols(Z)
	dy = xmu_dy(y)
	dep = dy[|s0+1\T|]
	idx = (s0+1::T)
	fidx = xmu_fidx(k,cs)
	if (cs==4) keep = (k+2), (k+4..m)
	else keep = (k+2..m)
	Zr = Z[., keep]
	br = invsym(cross(Zr,Zr))*cross(Zr,dep)
	er = dep - Zr*br
	er = (er :- mean(er)) * sqrt(n/(n-cols(Zr)))
	kidx = J(1,m,0)
	kidx[keep] = (1..cols(keep))
	posf = (k+3+ntr+p..m)
	fp = Z[., posf] * br[kidx[posf]',1]
	if (p>0) {
		posd = (k+3+ntr..k+2+ntr+p)
		phi = br[kidx[posd]',1]
	}
	else {
		posd = J(1,0,.)
		phi = J(0,1,.)
	}
	pen = (crit==1 ? 2 : ln(n))
	ys = J(T,1,0); dys = J(T,1,0)
	ys[|1\s0|] = y[|1\s0|]
	if (s0>=2) dys[|2\s0|] = y[|2\s0|] - y[|1\s0-1|]
	out = J(B,2,.)
	for (b=1; b<=B; b++) {
		for (j=1; j<=n; j++) {
			t = s0 + j
			v = fp[j] + er[ridx[b,j]]
			for (l=1; l<=p; l++) v = v + phi[l]*dys[t-l]
			dys[t] = v
			ys[t] = ys[t-1] + v
		}
		if (resel==0) {
			Zs = Z
			Zs[.,1] = ys[idx :- 1]
			for (l=1; l<=p; l++) Zs[., posd[l]] = dys[idx :- l]
			st = xmu_stats(Zs, dys[idx], fidx)
			out[b,1] = st[1]; out[b,2] = st[2]
		}
		else {
			best = .
			for (pp_=0; pp_<=maxlag; pp_++) {
				for (qq=0; qq<=maxlag; qq++) {
					Zb = xmu_Z(ys,X,pp_,qq,cs,s0)
					mm = cols(Zb)
					if (mm > n-8) continue
					st = xmu_stats(Zb, dys[idx], fidx)
					ic = n*ln(st[3]/n) + pen*mm
					if (best==. | ic < best) {
						best = ic; bt = st[1]; bF = st[2]
					}
				}
			}
			out[b,1] = bt; out[b,2] = bF
		}
	}
	return(out)
}

real colvector xmu_cap(real colvector x, real scalar cap)
{
	return(x :* (x :< cap) :+ cap :* (x :>= cap))
}

// quantile of a bootstrap distribution (lower=1: lower-tail critical value, 0: upper-tail)
real scalar xmu_cv(real colvector x, real scalar a, real scalar lower)
{
	real colvector s
	real scalar B, i
	s = sort(x,1)
	B = rows(s)
	if (lower) i = max((1, ceil(a*B)))
	else i = min((B, max((1, ceil((1-a)*B)))))
	return(s[i])
}

real scalar xmu_pval(real scalar obs, real colvector star, real scalar upper)
{
	real scalar B
	B = rows(star)
	if (upper) return((1 + sum(star :>= obs))/(B+1))
	return((1 + sum(star :<= obs))/(B+1))
}

void xmu_panel_run(string scalar vars, string scalar pv, string scalar tv, string scalar touse, real scalar cs, real scalar maxlag, real scalar crit, real scalar fp_, real scalar fq_, real scalar B, real scalar csdmode, real scalar alpha)
{
	external real colvector xmu_tbs, xmu_fbs
	string rowvector names
	real matrix data, info, Rc, U, ridx, Cd, tstar, Fstar, ptstar, pFstar, PAN, UNI, X, Z, bs
	real colvector id, tm, y, tt, dep, dy, kept, ok, ra, rb, r, b, tobs, Fobs, pt, pF, rk, rkF
	real colvector tbs_, fbs_, ftobs_s, intobs_s, tstat_s
	real rowvector fidx, pq, st
	real scalar N0, Nk, i, u, k, ntr, tmin, tmax, Tspan, s0, n, m, p, q, Ti, cstart, a, c, ia, ib, Tij, rho, CD, shared, balanced, nmax, cap, bad
	real scalar tbar_o, fish_t_o, invn_t_o, Fbar_o, fish_F_o, invn_F_o, nrow, minratio, maxm
	real colvector tbar_s, fish_t_s, invn_t_s, Fbar_s, fish_F_s, invn_F_s
	real rowvector cvs
	real matrix Rho

	st_numscalar("_xmu_rc", 0)
	names = tokens(vars)
	data = st_data(., names, touse)
	id = st_data(., pv, touse)
	tm = st_data(., tv, touse)
	k = cols(data) - 1
	ntr = (cs==4 | cs==5)
	info = panelsetup(id, 1)
	N0 = rows(info)
	tmin = min(tm); tmax = max(tm); Tspan = tmax - tmin + 1
	fidx = xmu_fidx(k, cs)

	U = J(N0, 10, 0)
	Rc = J(Tspan, N0, .)
	for (i=1; i<=N0; i++) {
		y = data[|info[i,1],1 \ info[i,2],1|]
		X = data[|info[i,1],2 \ info[i,2],k+1|]
		tt = tm[|info[i,1] \ info[i,2]|]
		Ti = rows(y)
		if (Ti > 1) {
			if (any((tt[|2\Ti|] - tt[|1\Ti-1|]) :!= 1)) {
				st_numscalar("_xmu_rc", 459)
				st_numscalar("_xmu_badunit", id[info[i,1]])
				return
			}
		}
		if (crit > 0) s0 = maxlag + 1
		else s0 = max((fp_, fq_)) + 1
		n = Ti - s0
		if (crit > 0) {
			if (n - (2*k+2+ntr) < 8) continue
			pq = xmu_select(y, X, maxlag, cs, crit)
			if (pq[1] == .) continue
			p = pq[1]; q = pq[2]
		}
		else {
			p = fp_; q = fq_
		}
		Z = xmu_Z(y, X, p, q, cs, s0)
		m = cols(Z)
		if (n - m < 8) continue
		dy = xmu_dy(y)
		dep = dy[|s0+1\Ti|]
		st = xmu_stats(Z, dep, fidx)
		b = invsym(cross(Z,Z))*cross(Z,dep)
		r = dep - Z*b
		cstart = tt[1] - tmin + 1
		Rc[|cstart+s0,i \ cstart+Ti-1,i|] = r
		U[i,.] = (1, p, q, n, m, st[1], st[2], cstart, s0, Ti)
	}
	kept = selectindex(U[.,1] :== 1)
	Nk = rows(kept)
	if (Nk < 2) {
		st_numscalar("_xmu_rc", 198)
		return
	}

	// Pesaran (2004) CD test on the ARDL residuals (pairwise, overlap >= 5)
	CD = 0
	for (a=1; a<Nk; a++) {
		for (c=a+1; c<=Nk; c++) {
			ia = kept[a]; ib = kept[c]
			ok = selectindex((Rc[.,ia] :!= .) :& (Rc[.,ib] :!= .))
			Tij = rows(ok)
			if (Tij >= 5) {
				ra = Rc[ok,ia]; rb = Rc[ok,ib]
				Rho = correlation((ra,rb))
				rho = Rho[1,2]
				if (rho != .) CD = CD + sqrt(Tij)*rho
			}
		}
	}
	CD = sqrt(2/(Nk*(Nk-1))) * CD

	if (csdmode == 1) shared = 1
	else if (csdmode == 0) shared = 0
	else shared = (abs(CD) > invnormal(0.975))
	balanced = (min(U[kept,8]) == max(U[kept,8])) & (min(U[kept,4]) == max(U[kept,4]))
	nmax = max(U[kept,4])
	if (shared) {
		if (balanced) Cd = floor(nmax*runiform(B,nmax)) :+ 1
		else Cd = floor(Tspan*runiform(B,nmax)) :+ 1
	}

	tstar = J(B, Nk, .)
	Fstar = J(B, Nk, .)
	for (u=1; u<=Nk; u++) {
		i = kept[u]
		y = data[|info[i,1],1 \ info[i,2],1|]
		X = data[|info[i,1],2 \ info[i,2],k+1|]
		p = U[i,2]; q = U[i,3]; n = U[i,4]; s0 = U[i,9]; cstart = U[i,8]
		if (shared) {
			if (balanced) ridx = Cd[., (1..n)]
			else {
				ridx = Cd[., (1..n)] :- (cstart + s0) :+ 1
				bad = 0
				ridx = ridx :* ((ridx :>= 1) :& (ridx :<= n)) :+ (floor(n*runiform(B,n)) :+ 1) :* (1 :- ((ridx :>= 1) :& (ridx :<= n)))
			}
		}
		else ridx = floor(n*runiform(B,n)) :+ 1
		bs = xmu_bunit(y, X, p, q, cs, s0, B, ridx, (crit>0), maxlag, crit)
		tstar[.,u] = bs[.,1]
		Fstar[.,u] = bs[.,2]
	}

	tobs = U[kept,6]
	Fobs = U[kept,7]
	pt = ((1 :+ colsum(tstar :<= tobs'))/(B+1))'
	pF = ((1 :+ colsum(Fstar :>= Fobs'))/(B+1))'
	ptstar = J(B, Nk, .)
	pFstar = J(B, Nk, .)
	for (u=1; u<=Nk; u++) {
		rk = invorder(order(tstar[.,u],1))
		ptstar[.,u] = rk/(B+1)
		rkF = invorder(order(Fstar[.,u],1))
		pFstar[.,u] = (B :- rkF :+ 1)/(B+1)
	}
	cap = 1 - 0.5/(B+1)

	tbar_o = mean(tobs)
	fish_t_o = -2*sum(ln(pt))
	invn_t_o = sum(invnormal(xmu_cap(pt,cap)))/sqrt(Nk)
	Fbar_o = mean(Fobs)
	fish_F_o = -2*sum(ln(pF))
	invn_F_o = sum(invnormal(xmu_cap(pF,cap)))/sqrt(Nk)
	tbar_s = rowsum(tstar)/Nk
	fish_t_s = -2*rowsum(ln(ptstar))
	invn_t_s = rowsum(invnormal(ptstar))/sqrt(Nk)
	Fbar_s = rowsum(Fstar)/Nk
	fish_F_s = -2*rowsum(ln(pFstar))
	invn_F_s = rowsum(invnormal(pFstar))/sqrt(Nk)

	// panel matrix: stat, p-value, cv10, cv05, cv025, cv01, cv(alpha); rows tbar fish_t invn_t Fbar fish_F invn_F
	PAN = J(6,7,.)
	PAN[1,1] = tbar_o;   PAN[1,2] = xmu_pval(tbar_o,  tbar_s,   0)
	PAN[2,1] = fish_t_o; PAN[2,2] = xmu_pval(fish_t_o, fish_t_s, 1)
	PAN[3,1] = invn_t_o; PAN[3,2] = xmu_pval(invn_t_o, invn_t_s, 0)
	PAN[4,1] = Fbar_o;   PAN[4,2] = xmu_pval(Fbar_o,  Fbar_s,   1)
	PAN[5,1] = fish_F_o; PAN[5,2] = xmu_pval(fish_F_o, fish_F_s, 1)
	PAN[6,1] = invn_F_o; PAN[6,2] = xmu_pval(invn_F_o, invn_F_s, 0)
	cvs = (0.10, 0.05, 0.025, 0.01, alpha)
	for (c=1; c<=5; c++) {
		PAN[1,2+c] = xmu_cv(tbar_s,   cvs[c], 1)
		PAN[2,2+c] = xmu_cv(fish_t_s, cvs[c], 0)
		PAN[3,2+c] = xmu_cv(invn_t_s, cvs[c], 1)
		PAN[4,2+c] = xmu_cv(Fbar_s,   cvs[c], 0)
		PAN[5,2+c] = xmu_cv(fish_F_s, cvs[c], 0)
		PAN[6,2+c] = xmu_cv(invn_F_s, cvs[c], 1)
	}

	UNI = J(Nk, 9, .)
	for (u=1; u<=Nk; u++) {
		i = kept[u]
		UNI[u,1] = id[info[i,1]]
		UNI[u,2] = U[i,10]
		UNI[u,3] = U[i,2]
		UNI[u,4] = U[i,3]
		UNI[u,5] = tobs[u]
		UNI[u,6] = Fobs[u]
		UNI[u,7] = pt[u]
		UNI[u,8] = pF[u]
		UNI[u,9] = 1 + (pt[u] < alpha) + 2*(pF[u] < alpha)
	}

	// diagnostics: obs per parameter (selected model) and for the largest model searched
	minratio = min(U[kept,4] :/ U[kept,5])
	maxm = 1 + k + 1 + ntr + maxlag + maxlag*k + k
	st_matrix("_xmu_unit", UNI)
	st_matrix("_xmu_panel", PAN)
	st_numscalar("_xmu_N", Nk)
	st_numscalar("_xmu_Ndrop", N0 - Nk)
	st_numscalar("_xmu_CD", CD)
	st_numscalar("_xmu_CDp", 2*(1 - normal(abs(CD))))
	st_numscalar("_xmu_shared", shared)
	st_numscalar("_xmu_balanced", balanced)
	st_numscalar("_xmu_Tmin", min(U[kept,10]))
	st_numscalar("_xmu_Tmax", max(U[kept,10]))
	st_numscalar("_xmu_Tavg", mean(U[kept,10]))
	st_numscalar("_xmu_minratio", minratio)
	st_numscalar("_xmu_searchratio", min(U[kept,4])/maxm)
	st_numscalar("_xmu_k", k)
	xmu_tbs = tbar_s
	xmu_fbs = Fbar_s
}

// data for the graph command
void xmu_to_data(string scalar umat)
{
	external real colvector xmu_tbs, xmu_fbs
	real matrix U
	real scalar B, Nk, nobs
	real rowvector ix
	U = st_matrix(umat)
	B = rows(xmu_tbs)
	Nk = rows(U)
	nobs = max((B, Nk))
	st_addobs(nobs)
	ix = st_addvar("double", ("tbs","fbs","uidx","ut","uF","upt","upF"))
	st_store((1::B), ix[1], xmu_tbs)
	st_store((1::B), ix[2], xmu_fbs)
	st_store((1::Nk), ix[3], (1::Nk))
	st_store((1::Nk), ix[4], U[.,5])
	st_store((1::Nk), ix[5], U[.,6])
	st_store((1::Nk), ix[6], U[.,7])
	st_store((1::Nk), ix[7], U[.,8])
}

end
