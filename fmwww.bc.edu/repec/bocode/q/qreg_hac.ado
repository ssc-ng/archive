*! 1.0.0 Ariel Linden 18Nov2026

program qreg_hac, eclass
	version 13
	if replay() {
		if ("`e(cmd)'" != "qreg_hac") error 301
		Replay `0'
		exit
	}
	Estimate `0'
end

program Estimate, eclass
	version 13, missing
	local cmdline : copy local 0

	// put the data in panel/time order before -syntax- evaluates time-series operators in the varlist
	_ts timevar panvar, sort panel
	if "`timevar'" == "" {
		di as err "qreg_hac requires the data to be {bf:tsset}"
		exit 459
	}

	syntax varlist(numeric fv ts) [iw pw] [if] [in] [,	///
		Quantile(real 0.5)								///
		LAG(string)										///
		KERnel(string)									///
		PHI(string)										///
		BWidth(string)									///
		DENsity(string)									///
		WLSiter(integer 1)								///
		Level(cilevel)									///
		NOLOg LOg * ]

	_get_diopts diopts options, `options'
	OptimizeParse opopts options, `options'
	if "`options'" != "" {
		local k : word count `options'
		local options : list retokenize options
		local options : subinstr local options " " ", "
		di as err "{p}" plural(`k',"option") " {bf:`options'} " ///
		 plural(`k',"is","are") " not allowed{p_end}"
		exit 198
	}

	// quantile
	local quant = `quantile'
	if (`quant' >= 1) local quant = `quant'/100
	if `quant' <= 0 | `quant' >= 1 {
		di as err "{bf:quantile(`quantile')} is out of range"
		exit 198
	}
	if `wlsiter' < 1 {
		di as err "{bf:wlsiter(`wlsiter')} must be a positive integer"
		exit 198
	}

	// HAC kernel
	local kernel = lower(strtrim("`kernel'"))
	// default kernel: QS with the automatic bandwidth, Bartlett (Newey-West weights) when the user specifies lag(#)
	if "`kernel'" == "" {
		local lagtmp = lower(strtrim("`lag'"))
		if ("`lagtmp'" == "" | "`lagtmp'" == "auto") local kernel qs
		else local kernel bartlett
	}
	if inlist("`kernel'", "bar", "bart", "bartl", "bartle", "bartlet") local kernel bartlett
	if inlist("`kernel'", "par", "parz", "parze") local kernel parzen
	if inlist("`kernel'", "quadraticspectral", "quadratic") local kernel qs
	if !inlist("`kernel'", "bartlett", "parzen", "qs") {
		di as err "{bf:kernel()} must be {bf:bartlett}, {bf:parzen}, or {bf:qs}"
		exit 198
	}

	// lag: # or auto (default)
	local lag = lower(strtrim("`lag'"))
	if ("`lag'" == "" | "`lag'" == "auto") {
		local lagin = -1
		local lagmethod auto
	}
	else {
		capture confirm integer number `lag'
		if _rc | real("`lag'") < 0 {
			di as err "{bf:lag()} must be {bf:auto} or a nonnegative integer"
			exit 198
		}
		local lagin = real("`lag'")
		local lagmethod user
	}

	// phi method for the automatic bandwidth
	local phi = lower(strtrim("`phi'"))
	if ("`phi'" == "") local phi bc
	if !inlist("`phi'", "bc", "sample") {
		di as err "{bf:phi()} must be {bf:bc} or {bf:sample}"
		exit 198
	}
	if "`lagmethod'" == "user" & "`phi'" != "bc" {
		di as txt "note: {bf:phi()} ignored with user-specified {bf:lag()}"
	}

	// density bandwidth (Powell sandwich)
	local bwidth = lower(strtrim("`bwidth'"))
	if inlist("`bwidth'", "", "hs", "hsh", "hshe", "hshea", "hsheat", "hsheath", "hsheathe") local bwidth hsheather
	if inlist("`bwidth'", "bo", "bof", "bofi", "bofin", "bofing", "bofinge") local bwidth bofinger
	if inlist("`bwidth'", "ch", "cha", "cham", "chamb", "chambe", "chamber", "chamberl", "chamberla", "chamberlai") local bwidth chamberlain
	if !inlist("`bwidth'", "hsheather", "bofinger", "chamberlain") {
		di as err "{bf:bwidth()} must be {bf:hsheather}, {bf:bofinger}, or {bf:chamberlain}"
		exit 198
	}

	// density method for D: fitted (default) or kernel
	local density = lower(strtrim("`density'"))
	if inlist("`density'", "", "fit", "fitt", "fitte") local density fitted
	if inlist("`density'", "ker", "kern", "kerne") local density kernel
	if !inlist("`density'", "fitted", "kernel") {
		di as err "{bf:density()} must be {bf:fitted} or {bf:kernel}"
		exit 198
	}

	// weights: pweights are treated as iweights (as in -qreg-)
	if "`weight'" != "" {
		local wweight iweight
		local weights [`wweight'`exp']
	}

	// time-series structure
	qui tsset
	local tdelta = r(tdelta)

	marksample touse
	markout `touse' `timevar' `panvar', strok

	qui count if `touse'
	local N = r(N)
	if (!`N') error 2000
	if (`N'<=2) error 2001

	gettoken dep0 indep0 : varlist

	// convert time-series-operated terms to temporary variables
	// (_qreg and _qregwls do not accept ts operators)
	// names are restored after estimation
	local dep `dep0'
	if strpos("`dep0'", ".") {
		tsrevar `dep0'
		local dep `r(varlist)'
	}
	local tmap_t
	local tmap_o
	local indep
	if "`indep0'" != "" {
		fvexpand `indep0' if `touse'
		local indep0x `r(varlist)'
		foreach v of local indep0x {
			// split each expanded term at "#"; in every component,
			// replace a time-series-operated variable by a temporary
			// variable while keeping its factor-variable prefix, e.g.
			// L.y -> __t   cL.y -> c.__t   1L.grp -> 1.__t
			local term
			local rest "`v'"
			while "`rest'" != "" {
				local p = strpos("`rest'", "#")
				if `p' {
					local comp = substr("`rest'", 1, `p'-1)
					local rest = substr("`rest'", `p'+1, .)
					local sep "#"
				}
				else {
					local comp "`rest'"
					local rest
					local sep
				}
				// component = head "." var; head = [fv prefix][ts ops]
				local ists 0
				local dp = strrpos("`comp'", ".")
				if `dp' > 1 {
					local head = substr("`comp'", 1, `dp'-1)
					local vname = substr("`comp'", `dp'+1, .)
					local pre
					local rem "`head'"
					if inrange(substr("`head'", 1, 1), "0", "9") {
						local ii = 1
						while inrange(substr("`head'", `ii', 1), "0", "9") {
							local ++ii
						}
						while inlist(substr("`head'", `ii', 1), "b", "o", "n") {
							local ++ii
						}
						local pre = substr("`head'", 1, `ii'-1)
						local rem = substr("`head'", `ii', .)
					}
					else if substr("`head'", 1, 1) == "c" {
						local pre c
						local rem = substr("`head'", 2, .)
						if substr("`rem'", 1, 1) == "o" {
							local pre co
							local rem = substr("`rem'", 2, .)
						}
					}
					if (substr("`rem'", 1, 1) == ".") local rem = substr("`rem'", 2, .)
					local ists = regexm("`rem'", "^[LFDSlfds][LFDSlfds0-9]*$")
				}
				if `ists' {
					// canonical operator string: upper case, "L1" -> "L"
					local rem = upper("`rem'")
					local ops
					local ii = 1
					while `ii' <= length("`rem'") {
						local ch = substr("`rem'", `ii', 1)
						local ++ii
						local num
						while inrange(substr("`rem'", `ii', 1), "0", "9") {
							local num `num'`=substr("`rem'", `ii', 1)'
							local ++ii
						}
						if ("`num'" == "1") local num
						local ops `ops'`ch'`num'
					}
					local tsv `ops'.`vname'
					local pos : list posof "`tsv'" in tmap_o
					if `pos' {
						local tv : word `pos' of `tmap_t'
					}
					else {
						tsrevar `tsv'
						local tv `r(varlist)'
						local tmap_t `tmap_t' `tv'
						local tmap_o `tmap_o' `tsv'
					}
					if ("`pre'" != "") local comp `pre'.`tv'
					else               local comp `tv'
				}
				local term `term'`comp'`sep'
			}
			local indep `indep' `term'
		}
	}

	_rmcoll `indep' `weights' if `touse'
	local indep `r(varlist)'
	local varlist `dep' `indep'

	// point estimates: identical to -qreg-
	tempvar r i
	qui gen `c(obs_t)' `i' = _n

	_qregwls `varlist' `weights' if `touse', r(`r') ///
		iterate(`wlsiter') quant(`quant') `log' `nolog'

	_parse_iterlog, `log' `nolog'
	local log "`s(nolog)'"
	if ("`log'"!="") local qui quietly

	sort `r' `i'
	drop `r'

	`qui' _qreg `varlist' if `touse' `weights', quant(`quant') `opopts'
	if r(convcode) != 1 {
		di as err "convergence not achieved."
		local rc = 430
	}
	else local rc = 0

	tempname b rq rsd msd sum_w
	mat `b' = e(b)
	scalar `rq'    = r(q_v)
	scalar `rsd'   = r(sum_rdev)
	scalar `msd'   = r(sum_adev)
	scalar `sum_w' = r(sum_w)
	drop `i'

	// residuals
	tempvar xb res
	qui _predict double `xb' if `touse', xb
	qui gen double `res' = `dep' - `xb' if `touse'

	// weight variable
	local wvar
	if "`weight'" != "" {
		tempvar wvar
		qui gen double `wvar' `exp' if `touse'
	}

	// density estimate for D (as in qreg's VCE_fitted / VCE_kernel)
	tempname alpha band irq sd kband
	scalar `alpha' = 1 - `level'/100
	mata: qreg_hac_bwidth(`N', `quant', "`bwidth'", `=`alpha'')
	scalar `band' = r(bwidth)
	if (`quant'-`band' <= 0 | `quant'+`band' >= 1) {
		di as err "{p}VCE computation failed; try a different " ///
		 "{bf:bwidth()}{p_end}"
		exit 498
	}
	local wts
	if ("`weight'" != "") local wts [iw=`wvar']
	tempvar fi
	if "`density'" == "fitted" {
		// Hendricks-Koenker: difference quotient of fitted quantiles
		tempvar xb_l xb_u
		qui _qreg `varlist' if `touse' `wts', quant(`=`quant'-`band'') `opopts'
		if r(convcode) != 1 {
			di as err "{p}VCE computation failed; try increasing the " ///
			 "maximum number of iterations{p_end}"
			exit 498
		}
		qui _predict double `xb_l' if `touse', xb
		qui _qreg `varlist' if `touse' `wts', quant(`=`quant'+`band'') `opopts'
		if r(convcode) != 1 {
			di as err "{p}VCE computation failed; try increasing the " ///
			 "maximum number of iterations{p_end}"
			exit 498
		}
		qui _predict double `xb_u' if `touse', xb
		qui gen double `fi' = `xb_u' - `xb_l' if `touse'
		qui replace `fi' = cond(`fi' > sqrt(c(epsdouble)), (2*`band')/`fi', 0) if `touse'
		scalar `kband' = 1
	}
	else {
		// Powell: Epanechnikov kernel on the residuals
		if "`weight'" != "" {
			qui _pctile `res' if `touse' [iw=`wvar'], percentiles(25 75)
			scalar `irq' = r(r2) - r(r1)
			qui sum `res' if `touse' [iw=`wvar']
		}
		else {
			qui sum `res' if `touse', detail
			scalar `irq' = r(p75) - r(p25)
		}
		scalar `sd' = r(sd)
		scalar `kband' = min(`sd', `irq'/1.34) * ///
			(invnormal(`quant'+`band') - invnormal(`quant'-`band'))
		if missing(`kband') | `kband' <= 0 {
			di as err "{p}VCE computation failed; try a different " ///
			 "{bf:bwidth()}{p_end}"
			exit 498
		}
		qui gen double `fi' = `res'/`kband' if `touse'
		qui replace `fi' = (0.75*(1 - 0.2*`fi'^2)/sqrt(5)) * ///
			(abs(`fi') < sqrt(5)) / `kband' if `touse'
	}

	// design for the sandwich: non-omitted columns only
	local names : colfullnames `b'
	local k : word count `names'
	_ms_omit_info `b'
	tempname omit
	mat `omit' = r(omit)
	local keep
	local xmat
	forvalues j = 1/`k' {
		local nm : word `j' of `names'
		local isom = el(`omit', 1, `j') | ///
			regexm("`nm'", "[0-9]+(b|o|bo|ob)\.") | ///
			regexm("`nm'", "(^|#)o\.")
		if !`isom' {
			local keep `keep' `j'
			if "`nm'" != "_cons" {
				// column j of the design, built exactly as Stata builds xb
				tempname ej
				tempvar xc
				mat `ej' = J(1, `k', 0)
				mat `ej'[1, `j'] = 1
				mat colnames `ej' = `names'
				qui matrix score double `xc' = `ej' if `touse'
				local xmat `xmat' `xc'
			}
		}
	}

	// HAC sandwich
	tempname V
	mata: qreg_hac_vce("`touse'", "`panvar'", "`timevar'", "`res'",   ///
		"`wvar'", "`xmat'", `quant', "`fi'", "`kernel'",          ///
		`lagin', "`phi'", `tdelta', "`keep'", `k', "`V'")

	local S      = r(S)
	local Tbar   = r(Tbar)
	local nseg   = r(nseg)
	local minseg = r(minseg)
	local ngaps  = r(ngaps)
	local npan   = r(npan)
	local maxlag = r(maxlag)
	local phicap = r(phicap)
	local Scap   = r(Scap)
	local phi1   = r(phi1)

	if `ngaps' > `npan' - 1 {
		di
		di as txt "Number of gaps in sample = " as res `ngaps' - `npan' + 1
		di as txt "note: HAC autocovariances restarted at each gap."
	}
	if (`phicap') di as txt "note: estimated score autocorrelation " ///
		"truncated to |phi| <= 0.99 for bandwidth selection"
	if (`Scap')   di as txt "note: automatic bandwidth truncated at the " ///
		"shortest segment length (n = `minseg')"
	if "`lagmethod'" == "user" & `lagin'+1 > sqrt(`Tbar') {
		di as txt "note: {bf:lag(`lagin')} exceeds sqrt(T), where T = " ///
		 "`=strtrim(string(`Tbar', "%9.1f"))' is the mean segment length;"
		di as txt "      HAC standard errors may be unreliable"
	}

	// restore original names
	local nt : word count `tmap_t'
	forvalues j = 1/`nt' {
		local tv : word `j' of `tmap_t'
		local ov : word `j' of `tmap_o'
		// prefix + ".temp" -> prefix + "L.y" (e.g. c, co, 1, 0b, o);
		// then any bare temp -> "L.y"
		local names : subinstr local names ".`tv'" "`ov'", all
		local names : subinstr local names "`tv'" "`ov'", all
	}
	mat colnames `b' = `names'
	mat rownames `V' = `names'
	mat colnames `V' = `names'

	ereturn post `b' `V', esample(`touse')
	_post_vce_rank
	local df_r = `N' - e(rank)
	local df_m = e(rank) - 1

	ereturn local depvar     "`dep0'"
	ereturn local timevar    "`timevar'"
	ereturn local panelvar   "`panvar'"
	ereturn local vce        "hac"
	ereturn local vcetype    "HAC"
	ereturn local hac_kernel "`kernel'"
	ereturn local lagmethod  "`lagmethod'"
	if ("`lagmethod'" == "auto") ereturn local phimethod "`phi'"
	ereturn local bwmethod   "`bwidth'"
	ereturn local denmethod  "`density'"
	if ("`density'" == "kernel") ereturn local kernel "epanechnikov"
	ereturn scalar hac_bw    = `S'
	if ("`kernel'" != "qs") ereturn scalar lag = `maxlag'
	if ("`lagmethod'" == "auto") ereturn scalar phi1 = `phi1'
	ereturn scalar Tbar      = `Tbar'
	ereturn scalar N_seg     = `nseg'
	ereturn scalar N_g       = `npan'
	ereturn scalar minseg    = `minseg'
	ereturn scalar bwidth    = `band'
	if ("`density'" == "kernel") ereturn scalar kbwidth = `kband'
	ereturn scalar df_m      = `df_m'
	ereturn scalar df_r      = `df_r'
	ereturn scalar N         = `N'
	ereturn scalar sum_w     = `sum_w'
	ereturn scalar q_v       = `rq'
	ereturn scalar q         = `quant'
	ereturn scalar sum_rdev  = `rsd'
	ereturn scalar sum_adev  = `msd'
	ereturn scalar r2_p      = 1 - (`msd'/`rsd')
	ereturn scalar convcode  = `rc'
	if "`weight'" != "" {
		ereturn local wexp  = "`exp'"
		ereturn local wtype = "`weight'"
	}
	ereturn local properties   "b V"
	ereturn local marginsnotok stdp stddp residuals
	ereturn local predict      "qreg_p"
	ereturn local cmdline      `"qreg_hac `cmdline'"'
	ereturn local cmd          "qreg_hac"

	// leave the data in panel/time order for -predict-
	sort `panvar' `timevar'
	ereturn repost, buildfvinfo

	Replay, `diopts' level(`level')
end

program define Replay
	syntax [, Level(cilevel) * ]

	_get_diopts diopts options, `options'
	if "`options'" != "" {
		local k : word count `options'
		di as err "{p}" plural(`k',"option") " {bf:`options'} " ///
		 plural(`k',"is","are") " not allowed{p_end}"
		exit 198
	}
	if ("`e(hac_kernel)'" == "bartlett") local kname "Bartlett"
	else if ("`e(hac_kernel)'" == "parzen") local kname "Parzen"
	else local kname "Quadratic spectral"

	if (e(q) == 0.5) local title "Median regression with HAC standard errors"
	else local title "Quantile regression with HAC standard errors"

	di
	di as txt "`title'" ///
	 _col(49) "Number of obs" _col(67) "= " as res %10.0fc e(N)
	di as txt "Time variable: " as res "`=abbrev("`e(timevar)'", 20)'" ///
	 _col(49) as txt "Number of panels" _col(67) "= " as res %10.0fc e(N_g)
	if "`e(panelvar)'" != "" {
		di as txt "Panel variable: " as res "`=abbrev("`e(panelvar)'", 20)'" ///
		 _col(49) as txt "Mean segment T" _col(67) "= " as res %10.1f e(Tbar)
	}
	else {
		di as txt _col(49) "Mean segment T" _col(67) "= " as res %10.1f e(Tbar)
	}
	if (e(q) == 0.5) di as txt _col(49) "Pseudo R2" _col(67) "= " as res %10.4f e(r2_p)
	else {
		di as txt "Quantile (tau): " as res "`=strtrim(string(e(q), "%9.0g"))'" ///
		 _col(49) as txt "Pseudo R2" _col(67) "= " as res %10.4f e(r2_p)
	}
	di
	di as txt "Raw sum of deviations = " as res %9.0g e(sum_rdev) ///
	 as txt " (about " as res "`=strtrim(string(e(q_v), "%9.0g"))'" as txt ")"
	di as txt "Min sum of deviations = " as res %9.0g e(sum_adev)
	di
	di as txt "HAC kernel: " as res "`kname'" ///
	 _col(49) as txt "Bandwidth" _col(67) "= " as res %10.0f e(hac_bw)
	di

	_coef_table, `diopts' level(`level')

	error e(convcode)
end

program define OptimizeParse, sclass
	syntax namelist(max=2) [, ITERate(passthru) NOLOg LOg trace *]

	gettoken c_opopts c_opts : namelist

	local opts `options'
	if "`iterate'" != "" {
		local 0, `iterate'
		cap syntax, iterate(integer)
		local rc = _rc
		if (!`rc') local rc = (`iterate'<=0)
		if `rc' {
			di as err "{p}{bf:iterate({it:#})} must be a " ///
			 "nonnegative integer{p_end}"
			exit 198
		}
		local iterate iterate(`iterate')
	}
	c_local `c_opopts' `iterate' `log'`nolog' `trace'
	c_local `c_opts' `"`opts'"'
end

mata:

// bandwidth for the Powell density estimator (copied from qreg.ado)
void qreg_hac_bwidth(real scalar n, real scalar tau, string scalar method,
	|real scalar alpha)
{
	real scalar z, invtau, h

	invtau = invnormal(tau)
	if (method=="hsheather") {
		z = invnormal(1-alpha/2)
		h = (n^(-1/3))*(z^(2/3))*
			(1.5*normalden(invtau)^2/(2*invtau^2+1))^(1/3)
	}
	else if (method=="bofinger") {
		h = n^(-1/5)*((4.5*normalden(invtau)^4)/(2*invtau^2+1)^2)^(1/5)
	}
	else {
		z = invnormal(1-alpha/2)
		h = z*sqrt(n^(-1)*tau*(1-tau))
	}
	st_rclear()
	st_numscalar("r(bwidth)", h)
}

// segments: a new segment starts at each panel change or time gap
real matrix qreg_hac_segs(real colvector pid, real colvector t,
	real scalar tdelta)
{
	real scalar n, i, s
	real matrix segs

	n    = rows(pid)
	segs = J(0, 2, .)
	s    = 1
	for (i=2; i<=n; i++) {
		if (pid[i] != pid[i-1] | reldif(t[i]-t[i-1], tdelta) > 1e-8) {
			segs = (segs \ (s, i-1))
			s = i
		}
	}
	segs = (segs \ (s, n))
	return(segs)
}

// HAC lag-window weights
real scalar qreg_hac_kw(string scalar kern, real scalar x)
{
	real scalar ax, a

	ax = abs(x)
	if (kern == "bartlett") {
		return(ax < 1 ? 1 - ax : 0)
	}
	else if (kern == "parzen") {
		if (ax <= 0.5) return(1 - 6*ax^2 + 6*ax^3)
		if (ax <= 1)   return(2*(1 - ax)^3)
		return(0)
	}
	// quadratic spectral
	if (ax == 0) return(1)
	a = 6*pi()*x/5
	return(25/(12*pi()^2*x^2) * (sin(a)/a - cos(a)))
}

// AR(1) coefficient and innovation s.d., pooled over segments
real rowvector qreg_hac_ar1(real colvector y, real matrix segs,
	real scalar Tbar)
{
	real scalar    g, i1, i2, s1, s2, d, ml, mc
	real colvector yl, yc, dl, dc, er

	s1 = 0
	s2 = 0
	for (g=1; g<=rows(segs); g++) {
		i1 = segs[g, 1]
		i2 = segs[g, 2]
		if (i2 - i1 + 1 < 2) continue
		yl = y[(i1::(i2-1)), 1]
		yc = y[((i1+1)::i2), 1]
		ml = sum(yl) / rows(yl)
		mc = sum(yc) / rows(yc)
		dl = yl :- ml
		dc = yc :- mc
		s1 = s1 + sum(dl :* dc)
		s2 = s2 + sum(dl :* dl)
	}
	if (s2 <= 0 | Tbar <= 1) return((., .))
	d  = (s1/s2)*Tbar/(Tbar - 1) + 1/(Tbar - 1)
	er = J(0, 1, .)
	for (g=1; g<=rows(segs); g++) {
		i1 = segs[g, 1]
		i2 = segs[g, 2]
		if (i2 - i1 + 1 < 2) continue
		yl = y[(i1::(i2-1)), 1]
		yc = y[((i1+1)::i2), 1]
		mc = sum(yc) / rows(yc)
		er = (er \ ((yc :- mc) :- (d :* yl)))
	}
	return((d, sqrt(variance(er))))
}

void qreg_hac_vce(string scalar tousev, string scalar panv,
	string scalar timev, string scalar resv, string scalar wv,
	string scalar xvars, real scalar tau, string scalar fiv,
	string scalar kern, real scalar lagin, string scalar phim,
	real scalar tdelta, string scalar keepstr, real scalar kfull,
	string scalar Vname)
{
	real colvector t, pid, r, w, o, ind, psi, ls, cur, prv
	real colvector phi, sig2, keep, xp, kv
	real matrix    X, Z, segs, Zg, G, Meat, D, H, Vs, Vf
	real scalar    n, k, eps, nseg, minseg, Tbar, S, g, s1, s2, ng
	real scalar    j, kw, a, rho, q, phih, rx, num, den, theta
	real scalar    phicap, Scap, maxlag, npan, dd, phi1
	real rowvector ar

	t   = st_data(., timev, tousev)
	pid = (panv != "") ? st_data(., panv, tousev) : J(rows(t), 1, 1)
	r   = st_data(., resv, tousev)
	w   = (wv != "") ? st_data(., wv, tousev) : J(rows(t), 1, 1)
	X   = (xvars != "") ? st_data(., tokens(xvars), tousev) : J(rows(t), 0, .)
	X   = (X, J(rows(t), 1, 1))

	o   = order((pid, t), (1, 2))
	t   = t[o]
	pid = pid[o]
	r   = r[o]
	w   = w[o]
	X   = X[o, .]

	n = rows(r)
	k = cols(X)

	// quantile score: tau - I(e < 0), as in Galvao and Yoon's code
	eps = 1e-10 * mean(abs(r))
	ind = (r :< -eps)
	psi = tau :- ind
	Z   = (w :* psi) :* X

	segs   = qreg_hac_segs(pid, t, tdelta)
	nseg   = rows(segs)
	ls     = (segs[., 2] - segs[., 1]) :+ 1
	minseg = min(ls)
	Tbar   = n / nseg
	npan   = rows(uniqrows(pid))

	// within-segment (t, t-1) pairs
	cur = J(0, 1, .)
	prv = J(0, 1, .)
	for (g=1; g<=nseg; g++) {
		if (ls[g] >= 2) {
			cur = (cur \ ((segs[g,1]+1)::segs[g,2]))
			prv = (prv \ (segs[g,1]::(segs[g,2]-1)))
		}
	}

	phicap = 0
	Scap   = 0
	phi1   = .
	if (lagin >= 0) {
		if (lagin >= minseg) {
			errprintf("lag(%g) is too large: the shortest segment has n = %g\n",
				lagin, minseg)
			exit(198)
		}
		S = lagin + 1
	}
	else {
		if (rows(cur) == 0) {
			errprintf("no segment has two or more consecutive observations\n")
			exit(2001)
		}
		phi  = J(k, 1, .)
		sig2 = J(k, 1, .)
		if (phim == "sample") {
			// AR(1) of each score column (Galvao and Yoon's ar1())
			for (a=1; a<=k; a++) {
				ar = qreg_hac_ar1(Z[., a], segs, Tbar)
				phi[a]  = ar[1]
				sig2[a] = ar[2]^2
			}
			phi1 = mean(select(phi, phi :< .))
		}
		else {
			// Galvao and Yoon (2024) bivariate-normal estimator
			ar   = qreg_hac_ar1(r, segs, Tbar)
			rho  = ar[1]
			if (rho >= .) {
				errprintf("cannot estimate the residual autocorrelation\n")
				exit(498)
			}
			rho  = max((min((rho, 0.99)), -0.99))
			q    = invnormal(tau)
			phih = binormal(q, q, rho) - tau^2
			if (abs(phih) < 1e-8) phih = 0
			phih = phih / (tau*(1 - tau))
			phi1 = phih
			for (a=1; a<=k; a++) {
				xp = w :* X[., a]
				if (all(X[., a] :== X[1, a])) rx = 1
				else {
					// uncentered lag-1 autocorrelation of the regressor
					dd = sum(xp[prv]:^2)
					rx = (dd > 0) ? sum(xp[cur]:*xp[prv]) / dd : .
				}
				if (rx < .) {
					ar      = qreg_hac_ar1(Z[., a], segs, Tbar)
					phi[a]  = phih * rx
					sig2[a] = ar[2]^2
				}
			}
		}
		for (a=1; a<=k; a++) {
			if (phi[a] < . & abs(phi[a]) > 0.99) {
				phi[a] = sign(phi[a]) * 0.99
				phicap = 1
			}
		}
		num = 0
		den = 0
		for (a=1; a<=k; a++) {
			if (phi[a] < . & sig2[a] < . & sig2[a] > 0) {
				if (kern == "bartlett") {
					num = num + 4*phi[a]^2*sig2[a]^2 /
					      ((1 - phi[a])^6 * (1 + phi[a])^2)
				}
				else {
					num = num + 4*phi[a]^2*sig2[a]^2 / (1 - phi[a])^8
				}
				den = den + sig2[a]^2 / (1 - phi[a])^4
			}
		}
		theta = (den > 0) ? num / den : 0
		if (kern == "bartlett")    S = 1.1447 * (theta*Tbar)^(1/3)
		else if (kern == "parzen") S = 2.6614 * (theta*Tbar)^(1/5)
		else                       S = 1.3221 * (theta*Tbar)^(1/5)
		// integer bandwidth, at least 1 (as in Galvao and Yoon's code)
		S = round(S)
		if (S < 1 | S >= .) S = 1
		if (S > minseg) {
			S = minseg
			Scap = 1
		}
	}

	// long-run variance of the scores, within segments only
	Meat = J(k, k, 0)
	for (g=1; g<=nseg; g++) {
		s1 = segs[g, 1]
		s2 = segs[g, 2]
		ng = s2 - s1 + 1
		Zg = Z[|s1, 1 \ s2, k|]
		Meat = Meat + cross(Zg, Zg)
		if (S > 0 & S < .) {
			for (j=1; j<=ng-1; j++) {
				kw = qreg_hac_kw(kern, j/S)
				if (kw == 0) {
					if (kern != "qs") break
					continue
				}
				G = cross(Zg[|1, 1 \ ng-j, k|], Zg[|j+1, 1 \ ng, k|])
				Meat = Meat + kw*(G + G')
			}
		}
	}

	// D = sum_t w_t f_t x_t x_t' (fitted or Powell density, built in Stata)
	kv = st_data(., fiv, tousev)
	kv = kv[o]
	D  = cross(X, w :* kv, X)
	H  = invsym(D)
	Vs = H * Meat * H
	Vs = (Vs + Vs') / 2

	keep = strtoreal(tokens(keepstr))'
	Vf   = J(kfull, kfull, 0)
	for (a=1; a<=rows(keep); a++) {
		for (j=1; j<=rows(keep); j++) Vf[keep[a], keep[j]] = Vs[a, j]
	}
	st_matrix(Vname, Vf)

	if (kern == "qs") maxlag = .
	else              maxlag = ceil(S) - 1

	st_rclear()
	st_numscalar("r(S)", S)
	st_numscalar("r(Tbar)", Tbar)
	st_numscalar("r(nseg)", nseg)
	st_numscalar("r(minseg)", minseg)
	st_numscalar("r(ngaps)", nseg - 1)
	st_numscalar("r(npan)", npan)
	st_numscalar("r(maxlag)", maxlag)
	st_numscalar("r(phicap)", phicap)
	st_numscalar("r(Scap)", Scap)
	st_numscalar("r(phi1)", phi1)
}

end
exit