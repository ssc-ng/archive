*! version 1.1.4  25oct2026  Yusuf Toyin Yusuf (Kwara State University)
*! polycorr: polychoric, polyserial and Pearson correlations with a joint
*! (robust / cluster / survey) covariance matrix, normality diagnostics,
*! multiple-testing adjustment and positive-definite repair.

program define polycorr, eclass properties(mi svyb svyj)
	version 14

	capture mata: (void) pc_big()
	if _rc {
		di as err "polycorr's Mata functions are not loaded; type {bf:discard} and retry"
		exit 3499
	}

	if replay() {
		if `"`e(cmd)'"' != "polycorr" error 301
		Display `0'
		exit
	}

	local cmdline `"polycorr `0'"'

	syntax varlist(numeric min=2) [if] [in] [fweight aweight pweight iweight] ///
		[, CATmax(integer 10) ORDinal(varlist numeric) CONTinuous(varlist numeric) ///
		   PAIRwise vce(string) SVY Level(cilevel) ADJust(string)            ///
		   FITreps(integer 0) SEED(string) PDfix NOVCE TOLerance(real 1e-9)   ///
		   FIT MATrix noTABle CIFZ ]

	* ---------------------------------------------------------------- checks
	local nvars : word count `varlist'
	local dups : list dups varlist
	if "`dups'" != "" {
		di as err "variable(s) repeated in varlist: `dups'"
		exit 198
	}
	if `catmax' < 2 {
		di as err "catmax() must be at least 2"
		exit 198
	}
	if `fitreps' < 0 {
		di as err "fitreps() must be nonnegative"
		exit 198
	}
	if `tolerance' <= 0 | `tolerance' > 1e-3 {
		di as err "tolerance() must be in (0, 1e-3]"
		exit 198
	}
	foreach opt in ordinal continuous {
		local bad : list `opt' - varlist
		if "`bad'" != "" {
			di as err "`opt'(): `bad' not in varlist"
			exit 198
		}
	}
	local both : list ordinal & continuous
	if "`both'" != "" {
		di as err "`both' specified in both ordinal() and continuous()"
		exit 198
	}
	if "`adjust'" == "" local adjust holm
	local adjust = lower("`adjust'")
	if !inlist("`adjust'", "holm", "bh", "bonferroni", "none") {
		di as err "adjust() must be holm, bh, bonferroni or none"
		exit 198
	}
	if "`seed'" != "" set seed `seed'

	* ------------------------------------------------------------------ vce
	local vcetype robust
	local clustvar
	if `"`vce'"' != "" {
		gettoken v1 v2 : vce
		local v2 = trim(`"`v2'"')
		if inlist(`"`v1'"', "robust", "r", "rob", "robu", "robus") {
			local vcetype robust
		}
		else if inlist(`"`v1'"', "cluster", "cl", "clu", "clus", "clust", "cluste") {
			local vcetype cluster
			local clustvar `v2'
			confirm variable `clustvar'
			local nc : word count `clustvar'
			if `nc' != 1 {
				di as err "vce(cluster) requires exactly one variable"
				exit 198
			}
		}
		else if `"`v1'"' == "none" {
			local novce novce
		}
		else {
			di as err `"vce(`vce') not allowed; use robust, cluster clustvar or none"'
			exit 198
		}
	}

	* ------------------------------------------------------------------ svy
	local strvar
	local psuvar
	if "`svy'" != "" {
		if "`weight'" != "" {
			di as err "weights not allowed with svy; set them with {bf:svyset}"
			exit 101
		}
		if "`clustvar'" != "" {
			di as err "options svy and vce(cluster) may not be combined"
			exit 184
		}
		quietly svyset
		if `"`r(settings)'"' == ", clear" | `"`r(settings)'"' == "" {
			di as err "data not svyset"
			exit 119
		}
		local swvar   `r(wvar)'
		local swtype  `r(wtype)'
		local psuvar  `r(su1)'
		local strvar  `r(strata1)'
		if "`psuvar'" == "_n" local psuvar
		if `"`r(fpc1)'"' != "" {
			di as txt "(note: finite population correction ignored)"
		}
		if "`r(stages)'" != "" {
			if `r(stages)' > 1 di as txt "(note: only the first sampling stage is used)"
		}
		if "`swvar'" != "" {
			local weight pweight
			local exp "= `swvar'"
		}
		local vcetype svy
	}

	* --------------------------------------------------------------- sample
	if "`pairwise'" != "" marksample touse, novarlist
	else                  marksample touse
	if "`clustvar'" != "" markout `touse' `clustvar', strok
	if "`svy'" != "" {
		if "`strvar'" != "" markout `touse' `strvar', strok
		if "`psuvar'" != "" markout `touse' `psuvar', strok
		if "`swvar'"  != "" quietly replace `touse' = 0 if `swvar' <= 0
	}
	if "`pairwise'" != "" {
		tempvar nnm
		quietly egen `nnm' = rownonmiss(`varlist')
		quietly replace `touse' = 0 if `nnm' < 2
	}
	quietly count if `touse'
	if r(N) < 3 error 2001

	tempvar wv cid sid pid
	if "`weight'" != "" quietly gen double `wv' `exp' if `touse'
	else                quietly gen double `wv' = 1 if `touse'
	if "`clustvar'" != "" quietly egen long `cid' = group(`clustvar') if `touse'
	if "`strvar'"   != "" quietly egen long `sid' = group(`strvar')   if `touse'
	if "`psuvar'"   != "" quietly egen long `pid' = group(`psuvar')   if `touse'
	local cidn = cond("`clustvar'" != "", "`cid'", "")
	local sidn = cond("`strvar'"   != "", "`sid'", "")
	local pidn = cond("`psuvar'"   != "", "`pid'", "")

	local nv  = ("`novce'" != "")
	local pw  = ("`pairwise'" != "")
	local pd  = ("`pdfix'" != "")

	* --------------------------------------------------------------- engine
	tempname b V R Rpd Se Pv Npair pairs fitm cif tau cats mu sd
	local mnames `b' `V' `R' `Rpd' `Se' `Pv' `Npair' `pairs' `fitm' `cif' `tau' `cats' `mu' `sd'

	mata: pc_main("`varlist'", "`touse'", "`wv'", "`weight'", `catmax', ///
		"`ordinal'", "`continuous'", `pw', "`vcetype'", "`cidn'",       ///
		"`sidn'", "`pidn'", `nv', `fitreps', `tolerance', "`adjust'",   ///
		`pd', `level', "`mnames'")

	* ------------------------------------------------------------------ post
	* pairs at the boundary (flag = 1) have no finite standard error; post 0
	if !`nv' {
		mata: st_replacematrix("`V'", editmissing(st_matrix("`V'"), 0))
	}
	if `nv'                     ereturn post `b', esample(`touse') obs(`pc_N')
	else if "`vcetype'" == "svy" ereturn post `b' `V', esample(`touse') obs(`pc_N') dof(`=`pc_G' - `pc_H'')
	else                        ereturn post `b' `V', esample(`touse') obs(`pc_N')

	ereturn scalar k_var    = `nvars'
	ereturn scalar n_pairs  = `pc_npairs'
	ereturn scalar level    = `level'
	ereturn scalar catmax   = `catmax'
	ereturn scalar mineig   = `pc_mineig'
	ereturn scalar is_pd    = `pc_ispd'
	ereturn scalar n_fit    = `pc_nfit'
	ereturn scalar p_global = `pc_pglobal'
	ereturn scalar n_reject = `pc_nreject'
	ereturn scalar fitreps  = `fitreps'
	ereturn scalar n_bound  = `pc_nbound'
	if "`vcetype'" == "cluster" ereturn scalar N_clust  = `pc_G'
	if "`vcetype'" == "svy" {
		ereturn scalar N_strata = `pc_H'
		ereturn scalar N_psu    = `pc_G'
		ereturn scalar df_r     = `pc_G' - `pc_H'
	}
	if `pd' {
		ereturn scalar pd_iter   = `pc_pditer'
		ereturn scalar pd_maxchg = `pc_pdchg'
	}

	ereturn local types     "`pc_types'"
	ereturn local varlist   "`varlist'"
	ereturn local deletion  = cond(`pw', "pairwise", "listwise")
	ereturn local adjust    "`adjust'"
	if "`weight'" != "" {
		ereturn local wtype "`weight'"
		ereturn local wexp  `"`exp'"'
	}
	if `nv' {
		ereturn local vce "none"
	}
	else {
		ereturn local vce "`vcetype'"
		if "`vcetype'" == "robust"  ereturn local vcetype "Robust"
		if "`vcetype'" == "cluster" {
			ereturn local vcetype  "Robust"
			ereturn local clustvar "`clustvar'"
		}
		if "`vcetype'" == "svy" {
			ereturn local vcetype "Linearized"
			ereturn local strata  "`strvar'"
			ereturn local psu     "`psuvar'"
		}
	}
	ereturn local title   "Polychoric, polyserial and Pearson correlations"
	ereturn local cmdline `"`cmdline'"'

	ereturn matrix R      = `R'
	if `pd' ereturn matrix R_pd = `Rpd'
	if !`nv' {
		ereturn matrix Se     = `Se'
		ereturn matrix P      = `Pv'
		ereturn matrix ci_fz  = `cif'
	}
	ereturn matrix N_pair = `Npair'
	ereturn matrix pairs  = `pairs'
	ereturn matrix fit    = `fitm'
	ereturn matrix tau    = `tau'
	ereturn matrix cats   = `cats'
	ereturn matrix mu     = `mu'
	ereturn matrix sd     = `sd'

	ereturn local predict "polycorr_p"
	ereturn local cmd     "polycorr"

	Display, level(`level') `fit' `matrix' `table' `cifz'
end

program define polycorr_p
	di as err "predict is not available after polycorr"
	exit 198
end

* ======================================================================
program define Display
	syntax [, Level(cilevel) FIT MATrix noTABle CIFZ]

	tempname b V pairs fitm
	matrix `b'     = e(b)
	matrix `pairs' = e(pairs)
	matrix `fitm'  = e(fit)
	local hasV = ("`e(vce)'" != "none")
	if `hasV' matrix `V' = e(V)
	if "`cifz'" != "" & `hasV' {
		tempname cz
		matrix `cz' = e(ci_fz)
		if `level' != e(level) {
			di as txt "(note: Fisher-z limits are stored at level(" e(level) "); level() ignored)"
			local level = e(level)
		}
	}
	local vars `e(varlist)'
	local types `e(types)'
	local P = colsof(`b')
	local q = invnormal(1 - (1 - `level'/100)/2)
	if "`e(vce)'" == "svy" local q = invttail(e(df_r), (1 - `level'/100)/2)

	di
	di as txt "`e(title)'" _col(51) "Number of obs" _col(67) "= " as res %10.0fc e(N)
	di as txt "Deletion: " as res "`e(deletion)'" _col(51) as txt "Variables" _col(67) "= " as res %10.0f e(k_var)
	local vlab = cond(`hasV', "`e(vce)'", "none")
	if "`e(vce)'" == "cluster" local vlab "cluster `e(clustvar)'"
	di as txt "VCE: " as res "`vlab'" _col(51) as txt "Pairs" _col(67) "= " as res %10.0f e(n_pairs)
	if "`e(vce)'" == "cluster" {
		di as txt _col(51) "Clusters" _col(67) "= " as res %10.0f e(N_clust)
	}
	if "`e(vce)'" == "svy" {
		di as txt _col(51) "Strata / PSUs" _col(67) "= " as res %4.0f e(N_strata) as txt " / " as res %4.0f e(N_psu)
	}

	if "`table'" == "" {
		local cil = string(`level') + cond("`cifz'" != "", "% CI, Fisher z", "% CI")
		di as txt "{hline 78}"
		di as txt "Variable 1   Variable 2   Type" _col(37) "rho" _col(44) "Std. err." ///
			_col(57) "z" _col(62) "[`cil']"
		di as txt "{hline 78}"
		forvalues p = 1/`P' {
			local i  = `pairs'[`p', 1]
			local j  = `pairs'[`p', 2]
			local tp = `pairs'[`p', 3]
			local fl = `pairs'[`p', 5]
			local v1 : word `i' of `vars'
			local v2 : word `j' of `vars'
			local tn = cond(`tp' == 1, "polychoric", cond(`tp' == 2, "polyserial", "Pearson"))
			local star = cond(`fl' > 0, " *", "")
			local r  = `b'[1, `p']
			if `hasV' {
				local se = sqrt(`V'[`p', `p'])
				local z  = `r'/`se'
				local lo = `r' - `q'*`se'
				local hi = `r' + `q'*`se'
				if "`cifz'" != "" {
					local lo = `cz'[`p', 1]
					local hi = `cz'[`p', 2]
				}
				di as txt %-12s abbrev("`v1'", 12) " " %-12s abbrev("`v2'", 12) " " %-10s "`tn'" ///
					as res _col(35) %7.4f `r' _col(44) %8.4f `se' _col(54) %6.2f `z' ///
					_col(62) %7.4f `lo' "  " %7.4f `hi' ///
					as txt "`star'"
			}
			else {
				di as txt %-12s abbrev("`v1'", 12) " " %-12s abbrev("`v2'", 12) " " %-10s "`tn'" ///
					as res _col(35) %7.4f `r' as txt "`star'"
			}
		}
		di as txt "{hline 78}"
		if e(n_bound) > 0 & e(n_bound) < . {
			di as txt "* estimate at or near the boundary |rho| = 1 (sparse or empty cells);"
			di as txt "  standard error and test are unreliable for this pair"
		}
	}

	if e(n_fit) > 0 {
		di as txt "Bivariate normality (`e(n_fit)' polychoric pairs with df > 0): " _c
		di as txt "global min-p test p = " as res %6.4f e(p_global)
		di as txt "  pairs rejected at 5% after `e(adjust)' adjustment: " as res e(n_reject)
	}
	else {
		di as txt "Bivariate normality: no testable polychoric pairs (2x2 tables have df = 0)"
	}
	if e(mineig) < . {
		di as txt "Smallest eigenvalue of R = " as res %9.6f e(mineig) _c
		if e(is_pd) di as txt "  (positive definite)"
		else        di as txt "  " as err "(not positive definite)" as txt "; see option {bf:pdfix}"
	}
	if "`e(vce)'" == "svy" {
		di as txt "(confidence intervals use t(" as res e(df_r) as txt ") critical values)"
	}

	if "`fit'" != "" & e(n_fit) > 0 {
		local fr = e(fitreps)
		di
		di as txt "Tests of bivariate normality for polychoric pairs"
		di as txt "{hline 78}"
		di as txt "Variable 1   Variable 2      X2(df)   p>X2     G2   p>G2  p(adj)  RMSEA" _c
		if `fr' > 0 di as txt "  p(boot)"
		else        di
		di as txt "{hline 78}"
		forvalues p = 1/`P' {
			if `fitm'[`p', 2] < . & `fitm'[`p', 2] > 0 {
				local i = `pairs'[`p', 1]
				local j = `pairs'[`p', 2]
				local v1 : word `i' of `vars'
				local v2 : word `j' of `vars'
				local dfs = "(" + string(`fitm'[`p', 2]) + ")"
				di as txt %-12s abbrev("`v1'", 12) " " %-12s abbrev("`v2'", 12) ///
					as res %7.2f `fitm'[`p', 1] as txt %-5s "`dfs'" ///
					as res %6.3f `fitm'[`p', 3] " " %6.2f `fitm'[`p', 4] " " %6.3f `fitm'[`p', 5] ///
					" " %6.3f `fitm'[`p', 6] " " %6.3f `fitm'[`p', 7] _c
				if `fr' > 0 di as res "   " %6.3f `fitm'[`p', 8]
				else        di
			}
		}
		di as txt "{hline 78}"
		di as txt "X2 = Pearson, G2 = likelihood ratio; p(adj) adjusts p>G2 (`e(adjust)')."
	}

	if "`matrix'" != "" {
		di
		di as txt "Correlation matrix e(R)"
		matrix list e(R), format(%7.4f) noheader
		capture confirm matrix e(R_pd)
		if !_rc {
			di
			di as txt "Nearest positive-definite correlation matrix e(R_pd)"
			matrix list e(R_pd), format(%7.4f) noheader
		}
	}
end

* ======================================================================
version 14
capture mata: mata drop pc_*()
mata:
mata set matastrict on

/* Bivariate normal CDF P(X <= h, Y <= k; r) by the algorithm of Genz (2004),
   used instead of binormal(), which is unreliable as |r| approaches 1 */
real scalar pc_bvn2(real scalar h, real scalar k, real scalar r)
{
	real scalar v, ph, pk
	v  = pc_bvnu(-h, -k, r)
	ph = normal(h)
	pk = normal(k)
	// any bivariate CDF lies within the Frechet bounds; a value outside them is
	// a numerical failure and is reported as missing so that it is never used
	if (v > min((ph, pk)) + 1e-10 | v < ph + pk - 1 - 1e-10 | v >= .) return(.)
	return(min((max((v, max((0, ph + pk - 1)))), min((ph, pk)))))
}

real scalar pc_bvnu(real scalar dh, real scalar dk, real scalar r)
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


real scalar pc_big()
{
	return(10)
}

/* thresholds from (weighted) category totals */
real colvector pc_tau(real colvector m)
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

/* category index (1..K) of each observation */
real colvector pc_index(real colvector y, real colvector cats)
{
	real colvector ix
	real scalar k
	ix = J(rows(y), 1, 1)
	for (k = 1; k < rows(cats); k++) ix = ix + (y :> cats[k])
	return(ix)
}

/* cell probabilities and their derivative with respect to rho */
void pc_cells(real colvector ta, real colvector tb, real scalar r,
              real matrix P, real matrix dP)
{
	real colvector A, B
	real matrix F, D
	real scalar i, j, K, L, s2

	A  = (-pc_big() \ ta \ pc_big())
	B  = (-pc_big() \ tb \ pc_big())
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
			else                      F[i, j] = pc_bvn2(A[i], B[j], r)
			if (i > 1 & i < K & j > 1 & j < L) {
				D[i, j] = exp(-(A[i]^2 - 2*r*A[i]*B[j] + B[j]^2)/(2*s2)) / (2*pi()*sqrt(s2))
			}
		}
	}
	P  = F[|2,2 \ K,L|] - F[|1,2 \ K-1,L|] - F[|2,1 \ K,L-1|] + F[|1,1 \ K-1,L-1|]
	dP = D[|2,2 \ K,L|] - D[|1,2 \ K-1,L|] - D[|2,1 \ K,L-1|] + D[|1,1 \ K-1,L-1|]
	P = P :* (P :>= 1e-300) + (1e-300) :* (P :< 1e-300)
}

real scalar pc_pc_ll(real matrix N, real colvector ta, real colvector tb, real scalar r)
{
	real matrix P, dP
	pc_cells(ta, tb, r, P, dP)
	// Mata's sum() skips missing values; a missing cell probability must not count as zero
	if (hasmissing(P)) return(.)
	if (min(P) <= 0) return(.)
	return(sum(N :* ln(P)))
}

real scalar pc_pc_ms(real matrix N, real colvector ta, real colvector tb, real scalar r)
{
	real matrix P, dP
	pc_cells(ta, tb, r, P, dP)
	return(sum(N :* dP :/ P) / sum(N))
}

/* golden-section maximisation over z = atanh(rho) in [-5, 5] */
real scalar pc_pc_rho(real matrix N, real colvector ta, real colvector tb,
                      real scalar tol, real scalar zhat)
{
	real scalar a, b, c, d, fc, fd, g, k, f, fb, zb

	/* 25-point grid over atanh(rho) in [-3, 3] brackets the maximum;
	   missing log likelihoods are treated as -infinity */
	fb = .
	zb = 0
	for (k = -12; k <= 12; k++) {
		f = pc_pc_ll(N, ta, tb, tanh(.25*k))
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
	fc = pc_pc_ll(N, ta, tb, tanh(c))
	fd = pc_pc_ll(N, ta, tb, tanh(d))
	if (fc >= .) fc = -1e300
	if (fd >= .) fd = -1e300
	while (b - a > tol) {
		if (fc > fd) {
			b = d; d = c; fd = fc
			c = b - g*(b - a)
			fc = pc_pc_ll(N, ta, tb, tanh(c))
			if (fc >= .) fc = -1e300
		}
		else {
			a = c; c = d; fc = fd
			d = a + g*(b - a)
			fd = pc_pc_ll(N, ta, tb, tanh(d))
			if (fd >= .) fd = -1e300
		}
	}
	zhat = (a + b)/2
	return(tanh(zhat))
}

/* polyserial: log-likelihood contributions and rho-scores */
void pc_ps_eval(real colvector z, real colvector iy, real colvector tb, real scalar r,
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

real scalar pc_ps_ll(real colvector z, real colvector iy, real colvector w,
                     real colvector tb, real scalar r)
{
	real colvector ll, sc
	pc_ps_eval(z, iy, tb, r, ll, sc)
	if (hasmissing(ll)) return(.)
	return(sum(w :* ll))
}

real scalar pc_ps_ms(real colvector z, real colvector iy, real colvector w,
                     real colvector tb, real scalar r)
{
	real colvector ll, sc
	pc_ps_eval(z, iy, tb, r, ll, sc)
	return(sum(w :* sc) / sum(w))
}

real scalar pc_ps_rho(real colvector z, real colvector iy, real colvector w,
                      real colvector tb, real scalar tol, real scalar zhat)
{
	real scalar a, b, c, d, fc, fd, g, k, f, fb, zb

	/* coarse 37-point grid over atanh(rho) in [-4.5, 4.5] brackets the global maximum;
	   missing log likelihoods are treated as -infinity */
	fb = .
	zb = 0
	for (k = -18; k <= 18; k++) {
		f = pc_ps_ll(z, iy, w, tb, tanh(k/4))
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
	fc = pc_ps_ll(z, iy, w, tb, tanh(c))
	fd = pc_ps_ll(z, iy, w, tb, tanh(d))
	if (fc >= .) fc = -1e300
	if (fd >= .) fd = -1e300
	while (b - a > tol) {
		if (fc > fd) {
			b = d; d = c; fd = fc
			c = b - g*(b - a)
			fc = pc_ps_ll(z, iy, w, tb, tanh(c))
			if (fc >= .) fc = -1e300
		}
		else {
			a = c; c = d; fc = fd
			d = a + g*(b - a)
			fd = pc_ps_ll(z, iy, w, tb, tanh(d))
			if (fd >= .) fd = -1e300
		}
	}
	zhat = (a + b)/2
	return(tanh(zhat))
}

/* step for numerical derivatives in rho that stays inside (-1, 1) */
real scalar pc_hstep(real scalar r)
{
	return(min((1e-5, (1 - abs(r))/4)))
}

/* --------------------------------------------------------------------
   One pair.  x, y, w are the pair-complete observations.
   ox, oy: 1 = ordinal, 0 = continuous.
   Returns rho; IF (influence function for each observation); type;
   flag (1 = boundary, 2 = degenerate); fit = (X2, df, pX2, G2, pG2, ., RMSEA, pboot)
   -------------------------------------------------------------------- */
real scalar pc_pair(real colvector x, real colvector y, real colvector w,
                    real scalar ox, real scalar oy, real scalar tol,
                    real scalar novce, real scalar fitreps, real scalar nobs,
                    real colvector IF, real scalar type, real scalar flag,
                    real rowvector fit)
{
	real scalar n, W, rho, zhat, h, H, G, j, K, L, i, mu, sg, df, X2, G2, b, cntG
	real scalar Gb, nb
	real colvector cx, cy, ix, iy, ta, tb, s, corr, e, psi, z, ll, sc, zx, zy
	real colvector pv, draw, Nbv, tab, tbb
	real matrix N, P, dP, Ns, E, Nb, Pb, dPb, Eb

	n    = rows(x)
	W    = sum(w)
	flag = 0
	fit  = J(1, 8, .)
	IF   = J(n, 1, 0)

	/* ---------------- polyserial: put the continuous variable in x */
	if (ox == 1 & oy == 0) {
		pc_swap(x, y)
		ox = 0
		oy = 1
	}

	/* ---------------- polychoric */
	if (ox == 1 & oy == 1) {
		type = 1
		cx = uniqrows(x)
		cy = uniqrows(y)
		K  = rows(cx)
		L  = rows(cy)
		if (K < 2 | L < 2) {
			flag = 2
			return(.)
		}
		ix = pc_index(x, cx)
		iy = pc_index(y, cy)
		N  = J(K, L, 0)
		for (i = 1; i <= n; i++) N[ix[i], iy[i]] = N[ix[i], iy[i]] + w[i]
		ta  = pc_tau(rowsum(N))
		tb  = pc_tau(colsum(N)')
		rho = pc_pc_rho(N, ta, tb, tol, zhat)
		if (abs(zhat) > 4.9 | (min(N) <= 0 & abs(rho) > .95)) flag = 1

		pc_cells(ta, tb, rho, P, dP)

		/* goodness of fit against the bivariate normal */
		df = K*L - K - L
		if (df > 0) {
			Ns = N * (nobs / W)
			E  = nobs * P
			X2 = sum(((Ns - E):^2 :/ E) :* (E :> 1e-10))
			G2 = 2 * sum(Ns :* ln((Ns + (Ns :<= 0)) :/ E) :* (Ns :> 0))
			fit[1] = X2
			fit[2] = df
			fit[3] = chi2tail(df, X2)
			fit[4] = G2
			fit[5] = chi2tail(df, G2)
			fit[7] = sqrt(max((0, (G2 - df)/(df*(nobs - 1)))))
			if (fitreps > 0) {
				pv   = vec(P) / sum(P)
				nb   = round(nobs)
				cntG = 0
				for (b = 1; b <= fitreps; b++) {
					draw = rdiscrete(nb, 1, pv)
					Nbv  = J(K*L, 1, 0)
					for (i = 1; i <= nb; i++) Nbv[draw[i]] = Nbv[draw[i]] + 1
					Nb   = colshape(Nbv, K)'
					tab  = pc_tau(rowsum(Nb))
					tbb  = pc_tau(colsum(Nb)')
					(void) pc_pc_rho(Nb, tab, tbb, 1e-6, zhat)
					pc_cells(tab, tbb, tanh(zhat), Pb, dPb)
					Eb = nb * Pb
					Gb = 2 * sum(Nb :* ln((Nb + (Nb :<= 0)) :/ Eb) :* (Nb :> 0))
					cntG = cntG + (Gb >= G2)
				}
				fit[8] = (1 + cntG) / (fitreps + 1)
			}
		}

		if (novce) return(rho)

		s    = vec(dP :/ P)
		s    = s[ix + (iy :- 1)*K]
		h    = pc_hstep(rho)
		H    = (pc_pc_ms(N, ta, tb, rho + h) - pc_pc_ms(N, ta, tb, rho - h)) / (2*h)
		corr = J(n, 1, 0)
		for (j = 1; j <= K - 1; j++) {
			e    = J(K - 1, 1, 0)
			e[j] = 1e-5
			G    = (pc_pc_ms(N, ta + e, tb, rho) - pc_pc_ms(N, ta - e, tb, rho)) / 2e-5
			psi  = ((x :<= cx[j]) :- normal(ta[j])) / normalden(ta[j])
			corr = corr + G * psi
		}
		for (j = 1; j <= L - 1; j++) {
			e    = J(L - 1, 1, 0)
			e[j] = 1e-5
			G    = (pc_pc_ms(N, ta, tb + e, rho) - pc_pc_ms(N, ta, tb - e, rho)) / 2e-5
			psi  = ((y :<= cy[j]) :- normal(tb[j])) / normalden(tb[j])
			corr = corr + G * psi
		}
		IF = -(s + corr) / H
		return(rho)
	}

	/* ---------------- polyserial: x continuous, y ordinal */
	if (ox == 0 & oy == 1) {
		type = 2
		cy = uniqrows(y)
		L  = rows(cy)
		mu = sum(w :* x) / W
		sg = sqrt(sum(w :* (x :- mu):^2) / W)
		if (L < 2 | sg <= 0) {
			flag = 2
			return(.)
		}
		iy  = pc_index(y, cy)
		tb  = pc_tau(pc_wtab(iy, w, L))
		z   = (x :- mu) / sg
		rho = pc_ps_rho(z, iy, w, tb, tol, zhat)
		if (abs(zhat) > 4.9) flag = 1
		if (novce) return(rho)

		pc_ps_eval(z, iy, tb, rho, ll, sc)
		h    = pc_hstep(rho)
		H    = (pc_ps_ms(z, iy, w, tb, rho + h) - pc_ps_ms(z, iy, w, tb, rho - h)) / (2*h)
		G    = (pc_ps_ms((x :- (mu + 1e-5*sg))/sg, iy, w, tb, rho) -
		        pc_ps_ms((x :- (mu - 1e-5*sg))/sg, iy, w, tb, rho)) / (2e-5*sg)
		corr = G * (x :- mu)
		G    = (pc_ps_ms((x :- mu)/(sg*(1 + 1e-5)), iy, w, tb, rho) -
		        pc_ps_ms((x :- mu)/(sg*(1 - 1e-5)), iy, w, tb, rho)) / (2e-5*sg)
		corr = corr + G * (((x :- mu):^2 :- sg^2) / (2*sg))
		for (j = 1; j <= L - 1; j++) {
			e    = J(L - 1, 1, 0)
			e[j] = 1e-5
			G    = (pc_ps_ms(z, iy, w, tb + e, rho) - pc_ps_ms(z, iy, w, tb - e, rho)) / 2e-5
			psi  = ((y :<= cy[j]) :- normal(tb[j])) / normalden(tb[j])
			corr = corr + G * psi
		}
		IF = -(sc + corr) / H
		return(rho)
	}

	/* ---------------- Pearson */
	type = 3
	zx = x :- sum(w :* x)/W
	zy = y :- sum(w :* y)/W
	if (sum(w :* zx:^2) <= 0 | sum(w :* zy:^2) <= 0) {
		flag = 2
		return(.)
	}
	zx  = zx / sqrt(sum(w :* zx:^2)/W)
	zy  = zy / sqrt(sum(w :* zy:^2)/W)
	rho = sum(w :* zx :* zy) / W
	if (abs(rho) > 0.9999) flag = 1
	if (!novce) IF = zx :* zy - (rho/2) * (zx:^2 + zy:^2)
	return(rho)
}

void pc_swap(real colvector a, real colvector b)
{
	real colvector t
	t = a
	a = b
	b = t
}

real colvector pc_wtab(real colvector iy, real colvector w, real scalar L)
{
	real colvector m
	real scalar i
	m = J(L, 1, 0)
	for (i = 1; i <= rows(iy); i++) m[iy[i]] = m[iy[i]] + w[i]
	return(m)
}

/* multiple-testing adjustment of a column of p-values (missing ignored) */
real colvector pc_adjust(real colvector p, string scalar method)
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

/* Higham (2002) nearest correlation matrix, then a small eigenvalue floor */
real matrix pc_nearcorr(real matrix A, real scalar it, real scalar maxchg)
{
	real matrix Y, Rk, X, dS, Vv, Yold
	real rowvector L
	real colvector d
	real scalar k, maxit

	maxit = 500
	Y  = A
	dS = J(rows(A), cols(A), 0)
	for (it = 1; it <= maxit; it++) {
		Yold = Y
		Rk   = Y - dS
		symeigensystem(Rk, Vv, L)
		L    = L :* (L :> 0)
		X    = Vv * diag(L) * Vv'
		X    = (X + X')/2
		dS   = X - Rk
		Y    = X
		for (k = 1; k <= rows(Y); k++) Y[k, k] = 1
		if (max(abs(Y - Yold)) < 1e-10) break
	}
	symeigensystem(Y, Vv, L)
	L = L :* (L :>= 1e-6) + (1e-6) :* (L :< 1e-6)
	X = Vv * diag(L) * Vv'
	d = sqrt(diagonal(X))
	Y = X :/ (d * d')
	Y = (Y + Y')/2
	maxchg = max(abs(Y - A))
	return(Y)
}

/* --------------------------------------------------------------------
   Main routine called by polycorr.ado
   -------------------------------------------------------------------- */
void pc_main(string scalar vars, string scalar touse, string scalar wvar,
             string scalar wtype, real scalar catmax, string scalar ordv,
             string scalar contv, real scalar pairwise, string scalar vcetype,
             string scalar cidvar, string scalar sidvar, string scalar pidvar,
             real scalar novce, real scalar fitreps, real scalar tol,
             string scalar adjust, real scalar pdfix, real scalar level,
             string scalar mnames)
{
	string rowvector vn, ol, cl, mn, types
	string colvector stripe1, stripe2
	real matrix X, R, Se, Pv, Npair, pairs, fitm, cif, tau, cats, Psi, V, Rpd, T, info, Zs, Zh
	real colvector w, ok, x, y, ww, IF, padj, cid, sid, pid, ord, cv, keep, us
	real rowvector isord, mu, sd, b, fit, ev
	real scalar k, P, i, j, p, n, ntot, tp, fl, rho, nobs, W, maxK, q, G, H, h, nh, it, chg
	real scalar nfit, pglob, nrej, mineig, nb, zq

	vn = tokens(vars)
	ol = tokens(ordv)
	cl = tokens(contv)
	mn = tokens(mnames)
	k  = cols(vn)
	P  = k*(k - 1)/2

	st_view(X, ., vn, touse)
	st_view(w, ., wvar, touse)
	ntot = rows(X)

	/* ------------- variable types, thresholds, category values */
	isord = J(1, k, 0)
	mu    = J(1, k, .)
	sd    = J(1, k, .)
	types = J(1, k, "")
	maxK  = 2
	for (j = 1; j <= k; j++) {
		ok = (X[., j] :< .)
		cv = uniqrows(select(X[., j], ok))
		if (rows(cv) < 2) {
			errprintf("variable %s is constant in the estimation sample\n", vn[j])
			exit(459)
		}
		isord[j] = (rows(cv) <= catmax)
		if (anyof(ol, vn[j])) isord[j] = 1
		if (anyof(cl, vn[j])) isord[j] = 0
		if (isord[j] & rows(cv) > maxK) maxK = rows(cv)
		types[j] = (isord[j] ? "O" : "C")
	}
	tau  = J(k, maxK - 1, .)
	cats = J(k, maxK, .)
	for (j = 1; j <= k; j++) {
		ok = (X[., j] :< .)
		x  = select(X[., j], ok)
		ww = select(w, ok)
		W  = sum(ww)
		if (isord[j]) {
			cv = uniqrows(x)
			cats[j, (1..rows(cv))]     = cv'
			tau[j, (1..(rows(cv) - 1))] = pc_tau(pc_wtab(pc_index(x, cv), ww, rows(cv)))'
		}
		else {
			mu[j] = sum(ww :* x)/W
			sd[j] = sqrt(sum(ww :* (x :- mu[j]):^2)/W)
		}
	}

	/* ------------- pairs */
	b     = J(1, P, .)
	pairs = J(P, 5, .)
	fitm  = J(P, 8, .)
	Npair = J(k, k, .)
	R     = I(k)
	if (!novce) Psi = J(ntot, P, 0)
	keep  = J(ntot, 1, 0)
	stripe1 = J(P, 1, "")
	stripe2 = J(P, 1, "")

	p = 0
	for (i = 1; i <= k - 1; i++) {
		for (j = i + 1; j <= k; j++) {
			p++
			ok   = (X[., i] :< .) :& (X[., j] :< .)
			keep = keep :| ok
			x    = select(X[., i], ok)
			y    = select(X[., j], ok)
			ww   = select(w, ok)
			W    = sum(ww)
			nobs = (wtype == "fweight" ? W : rows(x))
			rho  = pc_pair(x, y, ww, isord[i], isord[j], tol, novce, fitreps,
			               nobs, IF, tp, fl, fit)
			b[p] = rho
			R[i, j] = rho
			R[j, i] = rho
			Npair[i, j] = nobs
			Npair[j, i] = nobs
			pairs[p, .] = (i, j, tp, nobs, fl)
			fitm[p, .]  = fit
			stripe1[p]  = vn[i]
			stripe2[p]  = vn[j]
			if (!novce & rho < .) {
				if (wtype == "fweight" & vcetype == "robust")
					Psi[selectindex(ok), p] = sqrt(ww) :* IF / W
				else
					Psi[selectindex(ok), p] = ww :* IF / W
			}
		}
	}
	for (j = 1; j <= k; j++) Npair[j, j] = .

	/* ------------- normality: adjustment and global test */
	padj = pc_adjust(fitm[., 5], adjust)
	fitm[., 6] = padj
	nfit  = sum(fitm[., 5] :< .)
	pglob = .
	nrej  = 0
	if (nfit > 0) {
		pglob = min((1, nfit * min(fitm[., 5])))
		nrej  = sum((padj :< 0.05) :& (padj :< .))
	}

	/* ------------- variance */
	q  = invnormal(1 - (1 - level/100)/2)
	G  = .
	H  = .
	Se = J(k, k, .)
	Pv = J(k, k, .)
	cif = J(P, 2, .)
	if (!novce) {
		Psi = select(Psi, keep)
		n   = rows(Psi)
		if (vcetype == "robust") {
			nb = (wtype == "fweight" ? sum(select(w, keep)) : n)
			V  = (nb/(nb - 1)) * cross(Psi, Psi)
		}
		else if (vcetype == "cluster") {
			cid  = select(st_data(., cidvar, touse), keep)
			ord  = order(cid, 1)
			info = panelsetup(cid[ord], 1)
			T    = panelsum(Psi[ord, .], info)
			G    = rows(T)
			if (G < 2) {
				errprintf("at least two clusters are required\n")
				exit(459)
			}
			V    = (G/(G - 1)) * cross(T, T)
		}
		else {                                         /* svy linearization */
			if (sidvar != "") sid = select(st_data(., sidvar, touse), keep)
			else              sid = J(n, 1, 1)
			if (pidvar != "") pid = select(st_data(., pidvar, touse), keep)
			else              pid = (1::n)
			ord  = order((sid, pid), (1, 2))
			sid  = sid[ord]
			pid  = pid[ord]
			Zs   = Psi[ord, .]
			cv   = runningsum(1 \ ((sid[|2 \ n|] :!= sid[|1 \ n-1|]) :| (pid[|2 \ n|] :!= pid[|1 \ n-1|])))
			info = panelsetup(cv, 1)                   /* PSU blocks */
			T    = panelsum(Zs, info)
			us   = sid[info[., 1]]                     /* stratum of each PSU */
			info = panelsetup(us, 1)                   /* strata blocks of PSUs */
			H    = rows(info)
			G    = rows(T)
			V    = J(P, P, 0)
			for (h = 1; h <= H; h++) {
				Zh = T[|info[h, 1], 1 \ info[h, 2], P|]
				nh = rows(Zh)
				if (nh < 2) {
					errprintf("stratum with a single PSU detected; variance not estimable\n")
					exit(460)
				}
				Zh = Zh :- mean(Zh)
				V  = V + (nh/(nh - 1)) * cross(Zh, Zh)
			}
			q = invttail(G - H, (1 - level/100)/2)
		}
		V = (V + V')/2
		p = 0
		for (i = 1; i <= k - 1; i++) {
			for (j = i + 1; j <= k; j++) {
				p++
				Se[i, j] = sqrt(V[p, p])
				Se[j, i] = Se[i, j]
				Pv[i, j] = 2*normal(-abs(b[p]/Se[i, j]))
				if (vcetype == "svy") Pv[i, j] = 2*ttail(G - H, abs(b[p]/Se[i, j]))
				Pv[j, i] = Pv[i, j]
				if (b[p] < . & abs(b[p]) < 1) {
					zq = Se[i, j] / (1 - b[p]^2)
					cif[p, .] = (tanh(atanh(b[p]) - q*zq), tanh(atanh(b[p]) + q*zq))
				}
			}
		}
	}

	/* ------------- positive definiteness */
	mineig = .
	Rpd    = J(k, k, .)
	it     = .
	chg    = .
	if (!hasmissing(R)) {
		ev     = symeigenvalues(R)
		mineig = min(ev)
		if (pdfix) Rpd = pc_nearcorr(R, it, chg)
	}
	else if (pdfix) {
		errprintf("note: R contains missing correlations; pdfix not applied\n")
	}

	/* ------------- write back */
	st_matrix(mn[1], b)
	st_matrixcolstripe(mn[1], (stripe1, stripe2))
	st_matrixrowstripe(mn[1], ("", "rho"))
	if (!novce) {
		st_matrix(mn[2], V)
		st_matrixcolstripe(mn[2], (stripe1, stripe2))
		st_matrixrowstripe(mn[2], (stripe1, stripe2))
	}
	st_matrix(mn[3], R)
	st_matrix(mn[5], Se)
	st_matrix(mn[6], Pv)
	st_matrix(mn[7], Npair)
	for (i = 3; i <= 7; i++) {
		if (i == 4) continue
		st_matrixcolstripe(mn[i], (J(k, 1, ""), vn'))
		st_matrixrowstripe(mn[i], (J(k, 1, ""), vn'))
	}
	if (pdfix) {
		st_matrix(mn[4], Rpd)
		st_matrixcolstripe(mn[4], (J(k, 1, ""), vn'))
		st_matrixrowstripe(mn[4], (J(k, 1, ""), vn'))
	}
	st_matrix(mn[8], pairs)
	st_matrixcolstripe(mn[8], (J(5, 1, ""), ("var1", "var2", "type", "N", "flag")'))
	st_matrixrowstripe(mn[8], (stripe1, stripe2))
	st_matrix(mn[9], fitm)
	st_matrixcolstripe(mn[9], (J(8, 1, ""), ("X2", "df", "p_X2", "G2", "p_G2", "p_adj", "RMSEA", "p_boot")'))
	st_matrixrowstripe(mn[9], (stripe1, stripe2))
	st_matrix(mn[10], cif)
	st_matrixcolstripe(mn[10], (J(2, 1, ""), ("lb", "ub")'))
	st_matrixrowstripe(mn[10], (stripe1, stripe2))
	st_matrix(mn[11], tau)
	st_matrixrowstripe(mn[11], (J(k, 1, ""), vn'))
	st_matrix(mn[12], cats)
	st_matrixrowstripe(mn[12], (J(k, 1, ""), vn'))
	st_matrix(mn[13], mu)
	st_matrixcolstripe(mn[13], (J(k, 1, ""), vn'))
	st_matrix(mn[14], sd)
	st_matrixcolstripe(mn[14], (J(k, 1, ""), vn'))

	nb = (wtype == "fweight" ? sum(select(w, keep)) : sum(keep))
	st_local("pc_N",       strofreal(nb, "%21.0g"))
	st_local("pc_npairs",  strofreal(P))
	st_local("pc_mineig",  strofreal(mineig, "%21.0g"))
	st_local("pc_ispd",    strofreal(mineig > 1e-10 & mineig < .))
	st_local("pc_nfit",    strofreal(nfit))
	st_local("pc_pglobal", strofreal(pglob, "%21.0g"))
	st_local("pc_nreject", strofreal(nrej))
	st_local("pc_nbound",  strofreal(sum(pairs[., 5] :== 1)))
	st_local("pc_G",       strofreal(G))
	st_local("pc_H",       strofreal(H))
	st_local("pc_pditer",  strofreal(it))
	st_local("pc_pdchg",   strofreal(chg, "%21.0g"))
	st_local("pc_types",   invtokens(types))
}

end
