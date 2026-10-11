*! mispauto 1.0.1  07oct2026
* Discriminating between autocorrelation and misspecification in regression analysis
* Dr Merwan Roudane -- merwanroudane920@gmail.com -- github.com/merwanroudane
*
* Four published strategies in one command:
*   thursby     Thursby (1981)  REStat 63:117-123   DW + RESET + LRS, 8-cell rule
*   godfrey     Godfrey (1987)  REStat 69:128-134   ordered sequence (a)->(d)
*   ghutton     Godfrey & Hutton (1994) EL 44:359-364  Sargan J then Hausman
*   knottnerus  Knottnerus (1985) REStat 67:175-177 blind-spot diagnostics
*   all         all of the above + a side-by-side verdict table
*
* Abbreviated step -> equation map (full map: help mispauto methods)
*   thursby   : (1) base model; (2) UTE; (3) nonlinear restrictions;
*               (4) LR = -T ln(S2u/S2r); (6) a** = 1-sqrt(1-a*);
*               (8) a* = 1-(1-a)^(1/3); p.118 table = 8-cell decision rule
*   godfrey   : (7)-(8) augmented model; (9) V(theta-hat);
*               (10) robust Wald with the White-Domowitz Sigma_j;
*               (11) AR(1+q) alternative; (18) auxiliary autoregression;
*               sec.III(d) t-test of rho=0; sec.IV lagged-dependent route
*   ghutton   : (1)-(3) EV/S model; (10)/(11) Hausman; (13) J = n*R2u;
*               (14) Wald equivalence; sec.2 level 1-(1-pJ)(1-pH)
*   knottnerus: (8) R = -rho1*rho2/(1-rho2); (12) plim(b3*b1+b2)=0;
*               (15) plim T^-1 sum(u_t u_t-1) = g1*(g2-g1^2)
*
* Supporting sources implemented rather than cited:
*   Imhof (1961) Biometrika 48:419-426   eq.(3.2) exact DW p-value, trapezoid
*   White & Domowitz (1984) Ectrca 52:143-161  eq.(4.2) truncation-lag choice
*   Durbin (1970) Ectrca 38:410-421      eq.(11) h-test
*   Thursby & Schmidt (1977) JASA 72:635-641   POX/POY/TS/PC test variables
*   Porter & Kashyap (1984) EL 14:229-233      their Table 3 modified RESET

program define mispauto, rclass
	version 14.0

	gettoken sub 0 : 0, parse(" ,")
	local lsub = length("`sub'")

	if `"`sub'"' == "" {
		di as err "subcommand required"
		di as err `"{p 4 4 2}specify {bf:thursby}, {bf:godfrey}, "' ///
			`"{bf:ghutton}, {bf:knottnerus} or {bf:all}; "' ///
			`"see {helpb mispauto}{p_end}"'
		exit 198
	}
	if `"`sub'"' == bsubstr("thursby", 1, max(2, `lsub')) {
		_mpa_thursby `0'
	}
	else if `"`sub'"' == bsubstr("godfrey", 1, max(2, `lsub')) {
		_mpa_godfrey `0'
	}
	else if `"`sub'"' == bsubstr("ghutton", 1, max(2, `lsub')) {
		_mpa_ghutton `0'
	}
	else if `"`sub'"' == bsubstr("knottnerus", 1, max(2, `lsub')) {
		_mpa_knott `0'
	}
	else if `"`sub'"' == bsubstr("all", 1, max(2, `lsub')) {
		_mpa_all `0'
	}
	else {
		di as err `"invalid subcommand {bf:`sub'}"'
		di as err `"{p 4 4 2}specify {bf:thursby}, {bf:godfrey}, "' ///
			`"{bf:ghutton}, {bf:knottnerus} or {bf:all}{p_end}"'
		exit 198
	}
	return add
end


*===============================================================================
* THURSBY (1981)
*===============================================================================
program define _mpa_thursby, rclass
	syntax [anything] [if] [in] [,                           ///
		LEVel(real 5)                                    ///
		RESETVars(string)                                ///
		RESETPowers(numlist integer min=1 max=6 >=2 sort) ///
		RESETMod                                         ///
		DWSide(string) DWP(string) MAXTdw(integer 1000)  ///
		SLRS RTEmethod(string) noMISS0                   ///
		Graph Name(string) NOTABLE ]

	_mpa_ckopt side  "`dwside'"    "lower upper two"
	local dwside "`r(v)'"
	_mpa_ckopt dwp   "`dwp'"       "imhof normal"
	local dwp    "`r(v)'"
	_mpa_ckopt rte   "`rtemethod'" "durbin corc prais"
	local rte    "`r(v)'"
	_mpa_ckopt rvars "`resetvars'" "pox poy ts pc"
	local rvars  "`r(v)'"
	if `level' <= 0 | `level' >= 50 {
		di as err "level() must lie strictly between 0 and 50 (percent)"
		exit 198
	}
	if "`resetpowers'" == "" local resetpowers 2 3 4

	_mpa_getmodel `"`anything'"'
	local dv   "`r(depvar)'"
	local ivs  "`r(indeps)'"
	local post = r(post)

	tempvar touse
	mark `touse' `if' `in'
	markout `touse' `dv' `ivs'
	_mpa_cktime
	local tvar "`r(timevar)'"
	markout `touse' `tvar'
	if `post' qui replace `touse' = 0 if !e(sample)
	_mpa_ckgaps `touse'

	* protect the caller's estimation results: every subcommand refits
	* internally, and _mpa_ute in particular leaves the UTE in e() with
	* temporary regressors that a later postestimation call would read
	tempname _ehold
	capture _estimates hold `_ehold', restore nullok

	qui count if `touse'
	local T = r(N)
	local k : word count `ivs'
	if `T' < 3 * (`k' + 2) {
		di as err "too few observations (`T') for a `k'-regressor strategy"
		di as err "{p 4 4 2}the strategy needs the base model, the UTE with" ///
			" `=2*`k'+1' regressors, and the RESET augmentation{p_end}"
		exit 2001
	}

	* adjusted levels: eq.(8) across the three procedures, eq.(6) within LRS
	local a      = `level' / 100
	local astar  = 1 - (1 - `a')^(1/3)
	local a2star = 1 - sqrt(1 - `astar')
	if "`slrs'" != "" local a2star = `astar'

	*--- D : Durbin-Watson on eq.(1) --------------------------------------
	tempvar e1
	qui regress `dv' `ivs' if `touse'
	qui predict double `e1' if `touse', resid
	_mpa_dw `dv' `ivs', touse(`touse') resid(`e1') side(`dwside') ///
		method(`dwp') maxt(`maxtdw')
	local dw = r(dw)
	local dw_p = r(p)
	local dwmeth "`r(method)'"
	local Dsig = (`dw_p' < `astar')

	*--- R : RESET on eq.(1) ----------------------------------------------
	_mpa_reset `dv' `ivs', touse(`touse') powers(`resetpowers') ///
		vars(`rvars') `resetmod'
	local rF = r(F)
	local rdf = r(df)
	local rdfr = r(df_r)
	local r_p = r(p)
	local rpow "`r(powers)'"
	local rset "`r(vars)'"
	local rrho = r(rho)
	local Rsig = (`r_p' < `astar')

	*--- L : LRS = Durbin S-test on eq.(2), then the LR of eq.(4) ----------
	_mpa_lrs `dv' `ivs', touse(`touse') level(`a2star') `miss0' ///
		rte(`rte') `slrs'
	local sF = r(s_F)
	local s_p = r(s_p)
	local sdf = r(s_df)
	local lr = r(lr)
	local lr_p = r(lr_p)
	local lrdf = r(lr_df)
	local rho = r(rho)
	local Ssig = r(s_sig)
	local LRsig = r(lr_sig)
	local Lsig = r(lrs_sig)

	*--- the 8-cell decision rule (Thursby 1981, p.118) -------------------
	if `Rsig' {
		local verdict "MS"
	}
	else if `Lsig' {
		local verdict "NAR"
	}
	else if `Dsig' {
		local verdict "AR(1)"
	}
	else {
		local verdict "NP"
	}
	local cD = "D"
	local cR = "R"
	local cL = "L"
	if `Dsig' local cD = "D'"
	if `Rsig' local cR = "R'"
	if `Lsig' local cL = "L'"
	local cell "`cD' `cR' `cL'"

	if "`notable'" == "" {
		_mpa_hdr "Thursby (1981) test strategy" "`dv'" `T' `k' `level'
		di as text "{p 4 4 2}Overall level allocated by eq.(8): each of the" ///
			" three procedures at {bf:" %6.4f `=100*`astar'' "%}; by eq.(6)" ///
			" each of the two LRS tests at {bf:" %6.4f `=100*`a2star'' ///
			"%}.{p_end}"
		di ""
		di as text "{hline 13}{c TT}{hline 64}"
		di as text "   Procedure {c |}" _col(23) "Statistic" _col(39) "df" ///
			_col(50) "p-value" _col(63) "Outcome"
		di as text "{hline 13}{c +}{hline 64}"
		_mpa_row "DW  (D)"   `dw' "."              `dw_p' `Dsig'
		_mpa_sub "nonrandom disturbances or misspecification"
		_mpa_row "RESET (R)" `rF' "`rdf', `rdfr'"  `r_p'  `Rsig'
		_mpa_sub "misspecification (`rset', powers `rpow')"
		di as text "{hline 13}{c +}{hline 64}"
		_mpa_row "  S-test"  `sF' "`sdf'"          `s_p'  `Ssig'
		if "`slrs'" == "" {
			_mpa_row "  LR eq.(4)" `lr' "`lrdf'"   `lr_p' `LRsig'
		}
		else {
			di as text _col(4) "LR eq.(4)" _col(14) "{c |}" ///
				as txt _col(21) "skipped ({bf:slrs})"
		}
		_mpa_row "LRS   (L)" . "."                 . `Lsig'
		_mpa_sub "misspecification or non-AR(1) autocorrelation"
		di as text "{hline 13}{c BT}{hline 64}"
		di as text "   DW p-value: `dwmeth', `dwside' tail." ///
			_col(45) "rho-hat from the UTE = " as res %7.4f `rho'
		if "`resetmod'" != "" {
			di as text "   RESET modified per Porter & Kashyap (1984)," ///
				" rho-hat = " as res %7.4f `rrho'
		}
		di ""
		di as text "   Outcome pattern {bf:`cell'}   ==>   diagnosis: " ///
			as res "{bf:`verdict'}"
		_mpa_verdict "`verdict'"
		di ""
		if `LRsig' & "`slrs'" == "" {
			di as text "{p 4 7 2}{bf:Caution (Knottnerus 1985, eq.12):} the" ///
				" restrictions the LR stage tests are satisfied by {it:any}" ///
				" stationary error process, so plim(b3*b1+b2)=0 and the" ///
				" asymptotic power of this stage equals its nominal size." ///
				" Treat a rejection here as a small-sample signal only, and" ///
				" run {bf:mispauto knottnerus} before acting on it.{p_end}"
		}
		if `Rsig' {
			di as text "{p 4 7 2}{bf:Caution (Porter & Kashyap 1984):} this" ///
				" RESET is not robust to autocorrelation. At a nominal 5%" ///
				" level they find 77% false rejections at T=200 when the" ///
				" regressor and the error are both AR(0.95). Confirm with" ///
				" {bf:mispauto godfrey}, or re-run with {bf:resetmod}.{p_end}"
		}
	}

	* graphs BEFORE any return-matrix move
	if "`graph'" != "" {
		_mpa_gcorr `e1', touse(`touse') n(`T') name(`name') ///
			title("Thursby (1981): residual correlogram") ///
			note("Diagnosis: `verdict'   (pattern `cell')")
	}

	return local cmd      "mispauto"
	return local subcmd   "thursby"
	return local depvar   "`dv'"
	return local indeps   "`ivs'"
	return local verdict  "`verdict'"
	return local pattern  "`cell'"
	return local resetvars "`rset'"
	return local resetpowers "`rpow'"
	return local dwmethod "`dwmeth'"
	return scalar N          = `T'
	return scalar k          = `k'
	return scalar level      = `level'
	return scalar alpha_each  = `astar'
	return scalar alpha_lrs   = `a2star'
	return scalar dw         = `dw'
	return scalar p_dw       = `dw_p'
	return scalar sig_dw     = `Dsig'
	return scalar F_reset    = `rF'
	return scalar df_reset   = `rdf'
	return scalar df_r_reset = `rdfr'
	return scalar p_reset    = `r_p'
	return scalar sig_reset  = `Rsig'
	return scalar F_s        = `sF'
	return scalar p_s        = `s_p'
	return scalar sig_s      = `Ssig'
	return scalar lr         = `lr'
	return scalar df_lr      = `lrdf'
	return scalar p_lr       = `lr_p'
	return scalar sig_lr     = `LRsig'
	return scalar sig_lrs    = `Lsig'
	return scalar rho        = `rho'
end


*===============================================================================
* GODFREY (1987)
*===============================================================================
program define _mpa_godfrey, rclass
	syntax [anything] [if] [in] [,                           ///
		LEVel(real 5) LEVels(numlist min=3 max=3 >0 <50) ///
		RESETVars(string)                                ///
		RESETPowers(numlist integer min=1 max=6 >=2 sort) ///
		TRUNCate(string) KERnel(string) WDRule(string)   ///
		Q(integer -1) P(integer 1) DTEst(string)         ///
		LAGDep Graph Name(string) NOTABLE ]

	_mpa_ckopt kern  "`kernel'"    "truncated bartlett"
	local kern "`r(v)'"
	_mpa_ckopt dtst  "`dtest'"     "t dw"
	local dtst "`r(v)'"
	_mpa_ckopt rvars "`resetvars'" "pox poy ts pc"
	local rvars "`r(v)'"
	if "`resetpowers'" == "" local resetpowers 2 3 4
	if `p' < 1 {
		di as err "p() must be 1 or more"
		exit 198
	}

	_mpa_getmodel `"`anything'"'
	local dv  "`r(depvar)'"
	local ivs "`r(indeps)'"
	local post = r(post)

	tempvar touse
	mark `touse' `if' `in'
	markout `touse' `dv' `ivs'
	_mpa_cktime
	local tvar "`r(timevar)'"
	markout `touse' `tvar'
	if `post' qui replace `touse' = 0 if !e(sample)
	_mpa_ckgaps `touse'

	tempname _ehold
	capture _estimates hold `_ehold', restore nullok

	qui count if `touse'
	local T = r(N)
	local k : word count `ivs'

	_mpa_period
	local per = r(period)
	local perlab "`r(label)'"
	if `q' < 0 local q = max(1, `per' - 1)

	* ---- truncation lag j : auto (White-Domowitz), seasonal, or a number
	if "`truncate'" == "" local truncate "auto"
	local wdl = .
	local wdj = .
	local wdp = .
	if "`truncate'" == "auto" {
		_mpa_ckopt wdrule "`wdrule'" "last first"
		local wdr "`r(v)'"
		_mpa_wdtrunc `dv' `ivs', touse(`touse') level(`level') rule(`wdr')
		local j   = r(l)
		local wdj = r(stat_joint)
		local wdp = r(p_joint)
		local wdl = r(maxlag)
		local trlab "auto, White-Domowitz eq.4.2, `wdr' significant lag of 1-`wdl'"
	}
	else if "`truncate'" == "seasonal" {
		local j = `per'
		if `per' <= 1 local j = floor(4 * (`T'/100)^(2/9))
		local j = max(1, `j')
		local trlab "seasonal"
	}
	else {
		capture confirm integer number `truncate'
		if _rc {
			di as err "truncate() must be auto, seasonal or a nonnegative integer"
			exit 198
		}
		local j = `truncate'
		if `j' < 0 {
			di as err "truncate() must be nonnegative"
			exit 198
		}
		local trlab "user-specified"
	}

	* ---- Bonferroni level allocation (Godfrey, sec.III)
	if "`levels'" != "" {
		tokenize `levels'
		local ab = `1'/100
		local ac = `2'/100
		local ad = `3'/100
	}
	else {
		local ab = `level'/300
		local ac = `level'/300
		local ad = `level'/300
	}
	local aover = `ab' + `ac' + `ad'

	local npdw 0
	local rkb = .
	if "`lagdep'" != "" {
		_mpa_godfrey_ld `dv' `ivs', touse(`touse') q(`q') ///
			powers(`resetpowers') vars(`rvars')
		local bstat = r(b_stat)
		local b_p = r(b_p)
		local bdf = r(b_df)
		local cstat = r(c_stat)
		local c_p = r(c_p)
		local cdf = r(c_df)
		local dstat = r(d_stat)
		local d_p = r(d_p)
		local rpow "`resetpowers'"
		local rset "`rvars'"
		local blab "LR  (b)"
		local clab "LR  (c)"
		local dlab "h   (d)"
		local rkb = `bdf'
	}
	else {
		_mpa_robreset `dv' `ivs', touse(`touse') powers(`resetpowers') ///
			vars(`rvars') truncate(`j') kernel(`kern')
		local bstat = r(stat)
		local b_p = r(p)
		local bdf = r(df)
		local rkb = r(rank)
		local npdw = r(nonpd)
		local rpow "`r(powers)'"
		local rset "`r(vars)'"
		local blab "Wald (b)"

		_mpa_arseq `dv' `ivs', touse(`touse') p(`p') q(`q')
		local cstat = r(F)
		local c_p = r(p)
		local cdf = r(df)
		local clab "F   (c)"

		_mpa_rhotest `dv' `ivs', touse(`touse') method(`dtst') maxt(1000)
		local dstat = r(stat)
		local d_p = r(p)
		local dlab "`r(label)'"
	}

	local bsig = (`b_p' < `ab')
	local csig = (`c_p' < `ac')
	local dsig = (`d_p' < `ad')

	* stop at the first rejection; adopt the last hypothesis not rejected
	if `bsig' {
		local hyp "(a)"
		local verdict "MS+ARMA"
	}
	else if `csig' {
		local hyp "(b)"
		local verdict "NAR"
	}
	else if `dsig' {
		local hyp "(c)"
		local verdict "AR(1)"
	}
	else {
		local hyp "(d)"
		local verdict "NP"
	}

	if "`notable'" == "" {
		_mpa_hdr "Godfrey (1987) ordered test sequence" "`dv'" `T' `k' `level'
		di as text "{p 4 4 2}Hypotheses are ordered from the least to the most" ///
			" restrictive. Testing stops at the first rejection and the last" ///
			" hypothesis not rejected is adopted, so the overall level is at" ///
			" most the sum of the three: {bf:" %6.4f `=100*`aover'' "%}.{p_end}"
		di as text "{p 4 4 2}Truncation j = {bf:`j'} (`trlab'), q = {bf:`q'}," ///
			" p = {bf:`p'}, kernel = {bf:`kern'}; the data appear" ///
			" {bf:`perlab'} (period `per').{p_end}"
		di ""
		di as text "{hline 13}{c TT}{hline 64}"
		di as text "     Test    {c |}" _col(23) "Statistic" _col(39) "df" ///
			_col(50) "p-value" _col(63) "Outcome"
		di as text "{hline 13}{c +}{hline 64}"
		_mpa_row "`blab'" `bstat' "`bdf'" `b_p' `bsig'
		_mpa_sub "H0(b): regression function correctly specified"
		_mpa_row "`clab'" `cstat' "`cdf'" `c_p' `csig'
		_mpa_sub "H0(c): errors AR(`p'), not AR(`=`p'+`q'')/ARMA(`p',`q')"
		_mpa_row "`dlab'" `dstat' "." `d_p' `dsig'
		_mpa_sub "H0(d): errors serially independent"
		di as text "{hline 13}{c BT}{hline 64}"
		if "`truncate'" == "auto" & `wdj' < . {
			di as text "   White-Domowitz joint test of lags 1-`wdl': chi2 = " ///
				as res %8.3f `wdj' as text ", p = " as res %6.4f `wdp'
		}
		if `npdw' {
			di ""
			di as text "{p 4 7 2}{bf:Warning:} the Sigma_j covariance matrix" ///
				" was not positive definite -- the truncated kernel of" ///
				" eq.(10) is not guaranteed PSD. A spectral generalized" ///
				" inverse of rank `rkb' was used in place of rank `bdf', and" ///
				" the p-value uses rank `rkb' degrees of freedom. Consider" ///
				" {bf:kernel(bartlett)}, which is PSD by construction.{p_end}"
		}
		di ""
		di as text "   Hypothesis adopted: " as res "{bf:`hyp'}" as text ///
			"   ==>   diagnosis: " as res "{bf:`verdict'}"
		_mpa_verdict "`verdict'"
	}

	if "`graph'" != "" {
		tempvar eg
		qui regress `dv' `ivs' if `touse'
		qui predict double `eg' if `touse', resid
		_mpa_gcorr `eg', touse(`touse') n(`T') name(`name') seasonal(`per') ///
			title("Godfrey (1987): residual correlogram") ///
			note("Adopted `hyp' -> `verdict'   (j=`j', q=`q')")
	}

	return local cmd     "mispauto"
	return local subcmd  "godfrey"
	return local depvar  "`dv'"
	return local indeps  "`ivs'"
	return local verdict "`verdict'"
	return local hypothesis "`hyp'"
	return local resetvars "`rset'"
	return local resetpowers "`rpow'"
	return local kernel  "`kern'"
	return local trunctype "`trlab'"
	return local period  "`perlab'"
	return scalar N      = `T'
	return scalar k      = `k'
	return scalar level  = `level'
	return scalar alpha_overall = `aover'
	return scalar truncate = `j'
	return scalar wd_maxlag = `wdl'
	return scalar wd_joint  = `wdj'
	return scalar wd_p      = `wdp'
	return scalar q      = `q'
	return scalar p      = `p'
	return scalar stat_b = `bstat'
	return scalar df_b   = `bdf'
	return scalar rank_b = `rkb'
	return scalar p_b    = `b_p'
	return scalar sig_b  = `bsig'
	return scalar nonpd  = `npdw'
	return scalar stat_c = `cstat'
	return scalar df_c   = `cdf'
	return scalar p_c    = `c_p'
	return scalar sig_c  = `csig'
	return scalar stat_d = `dstat'
	return scalar p_d    = `d_p'
	return scalar sig_d  = `dsig'
end


*===============================================================================
* GODFREY & HUTTON (1994)
*===============================================================================
program define _mpa_ghutton, rclass
	_iv_parse `0'
	local dv    "`s(lhs)'"
	local exog  "`s(exog)'"
	local endog "`s(endog)'"
	local inst  "`s(inst)'"
	local 0     `"`s(zero)'"'

	syntax [if] [in] [, LEVel(real 5) PJ(real -1) PH(real -1) ///
		HAUSman(string) NOTABLE ]

	_mpa_ckopt haus "`hausman'" "contrast augmented"
	local hmeth "`r(v)'"
	if "`endog'" == "" | "`inst'" == "" {
		di as err "syntax is: mispauto ghutton depvar [exog] (endog = instruments)"
		exit 198
	}
	if `pj' < 0 local pj = `level'/2
	if `ph' < 0 local ph = `level'/2

	tempvar touse
	mark `touse' `if' `in'
	markout `touse' `dv' `exog' `endog' `inst'
	qui count if `touse'
	local T = r(N)

	local k1 : word count `exog'
	local k2 : word count `endog'
	local ni : word count `inst'
	local kk = `k1' + `k2' + 1
	local pp = `ni' + `k1' + 1
	local novr = `pp' - `kk'
	if `novr' < 1 {
		di as err "the equation is exactly identified, so J = 0 in every sample"
		di as err "{p 4 4 2}stage 1 needs p > k (Godfrey & Hutton 1994, below" ///
			" eq.13): supply at least `=`k2'+1' excluded instruments for" ///
			" `k2' endogenous regressor(s){p_end}"
		exit 481
	}

	* protect e() with estimates store, NOT _estimates hold, because the
	* built-in hausman uses the estimates-store system itself
	tempname ehold olsest ivest
	capture estimates store `ehold'
	local hadest = (_rc == 0)

	*--- stage 1 : J = n * R2u of the IV residual on all instruments, eq.(13)
	capture noisily qui ivregress 2sls `dv' `exog' (`endog' = `inst') if `touse'
	if _rc {
		if `hadest' capture estimates restore `ehold'
		di as err "the 2SLS fit failed; check the instrument list"
		exit 498
	}
	qui estimates store `ivest'
	qui estat overid
	local J = r(sargan)
	local Jdf = r(df)
	local J_p = chi2tail(`Jdf', `J')
	local Jsig = (`J_p' < `pj'/100)

	*--- stage 2 : Hausman test of Omega = 0, only if stage 1 is passed
	local H = .
	local Hdf = .
	local H_p = .
	local Hsig = 0
	local stage2 = 1 - `Jsig'
	local hfail 0
	if `stage2' {
		if "`hmeth'" == "contrast" {
			qui regress `dv' `exog' `endog' if `touse'
			qui estimates store `olsest'
			capture qui hausman `ivest' `olsest', equations(1:1)
			if _rc == 0 {
				local H = r(chi2)
				local Hdf = r(df)
				local H_p = r(p)
			}
			else {
				local hfail 1
			}
		}
		else {
			qui estimates restore `ivest'
			capture qui estat endogenous
			if _rc == 0 {
				local H = r(durbin)
				local Hdf = r(df)
				local H_p = r(p_durbin)
			}
			else {
				local hfail 1
			}
		}
		if `hfail' {
			di as err "the Hausman stage could not be computed; try the" ///
				" other hausman() method"
		}
		else {
			local Hsig = (`H_p' < `ph'/100)
		}
	}
	local aover = 1 - (1 - `pj'/100) * (1 - `ph'/100)

	if `Jsig' {
		local verdict "RESPEC"
	}
	else if `Hsig' {
		local verdict "EV/S"
	}
	else {
		local verdict "OLS"
	}

	if "`notable'" == "" {
		_mpa_hdr "Godfrey & Hutton (1994) two-stage EV/S procedure" ///
			"`dv'" `T' `kk' `level'
		di as text "{p 4 4 2}General to specific: Omega is first left" ///
			" unrestricted (stage 1) and then set to zero (stage 2). The two" ///
			" statistics are asymptotically independent under the stage-2" ///
			" null, so the overall level is 1-(1-pJ)(1-pH) = {bf:" ///
			%6.4f `=100*`aover'' "%}.{p_end}"
		di as text "{p 4 4 2}k = `kk', p = `pp', overidentifying restrictions" ///
			" = {bf:`novr'}.  Endogenous: {bf:`endog'}.{p_end}"
		di ""
		di as text "{hline 15}{c TT}{hline 62}"
		di as text "     Stage    {c |}" _col(25) "Statistic" _col(40) "df" ///
			_col(51) "p-value" _col(64) "Outcome"
		di as text "{hline 15}{c +}{hline 62}"
		_mpa_row2 "1. J (Sargan)" `J' "`Jdf'" `J_p' `Jsig'
		_mpa_sub2 "H0: EV/S model adequate and instruments valid"
		if `stage2' & `hfail' == 0 {
			_mpa_row2 "2. Hausman" `H' "`Hdf'" `H_p' `Hsig'
			_mpa_sub2 "H0: Omega = 0 (no simultaneity, no measurement error)"
		}
		else if `stage2' == 0 {
			di as text _col(4) "2. Hausman" _col(16) "{c |}" ///
				as txt _col(23) "{bf:not reached} -- stage 1 rejected"
		}
		di as text "{hline 15}{c BT}{hline 62}"
		di ""
		di as text "   Diagnosis: " as res "{bf:`verdict'}"
		_mpa_verdict "`verdict'"
	}

	capture estimates drop `ivest'
	capture estimates drop `olsest'
	if `hadest' {
		capture estimates restore `ehold'
		capture estimates drop `ehold'
	}

	return local cmd     "mispauto"
	return local subcmd  "ghutton"
	return local depvar  "`dv'"
	return local exog    "`exog'"
	return local endog   "`endog'"
	return local inst    "`inst'"
	return local verdict "`verdict'"
	return local hausman "`hmeth'"
	return scalar N      = `T'
	return scalar k      = `kk'
	return scalar p_inst = `pp'
	return scalar n_overid = `novr'
	return scalar level  = `level'
	return scalar alpha_overall = `aover'
	return scalar J      = `J'
	return scalar df_J   = `Jdf'
	return scalar p_J    = `J_p'
	return scalar sig_J  = `Jsig'
	return scalar H      = `H'
	return scalar df_H   = `Hdf'
	return scalar p_H    = `H_p'
	return scalar sig_H  = `Hsig'
	return scalar stage2 = `stage2'
end


*===============================================================================
* KNOTTNERUS (1985)
*===============================================================================
program define _mpa_knott, rclass
	syntax [anything] [if] [in] [, LAGs(integer 0) LEVel(real 5) ///
		Graph Name(string) NOTABLE ]

	_mpa_getmodel `"`anything'"'
	local dv  "`r(depvar)'"
	local ivs "`r(indeps)'"
	local post = r(post)

	tempvar touse
	mark `touse' `if' `in'
	markout `touse' `dv' `ivs'
	_mpa_cktime
	local tvar "`r(timevar)'"
	markout `touse' `tvar'
	if `post' qui replace `touse' = 0 if !e(sample)
	_mpa_ckgaps `touse'

	tempname _ehold
	capture _estimates hold `_ehold', restore nullok

	qui count if `touse'
	local T = r(N)
	local k : word count `ivs'

	_mpa_period
	local per = r(period)
	local perlab "`r(label)'"
	if `lags' <= 0 local lags = max(4, 2 * `per')
	if `lags' > `T' - `k' - 2 local lags = `T' - `k' - 2
	if `lags' < 2 {
		di as err "too few observations for the Knottnerus diagnostics"
		exit 2001
	}

	tempvar e1
	qui regress `dv' `ivs' if `touse'
	qui predict double `e1' if `touse', resid

	tempname AC
	mata: mpa_acf("`e1'", "`touse'", `lags', "`AC'")
	local g1 = `AC'[1,2]
	local g2 = `AC'[2,2]
	local blind = `g1' * (`g2' - `g1'^2)
	local seg = 1 / sqrt(`T')

	* eq.(8) : AR(2) fit of the residuals
	tempvar le1 l2e1
	qui gen double `le1'  = L.`e1'  if `touse'
	qui gen double `l2e1' = L2.`e1' if `touse'
	qui regress `e1' `le1' `l2e1' if `touse', noconstant
	local rho1 = _b[`le1']
	local rho2 = _b[`l2e1']
	local Rknot = .
	local g1imp = .
	local g2imp = .
	if abs(1 - `rho2') > 1e-10 {
		local Rknot = -`rho1' * `rho2' / (1 - `rho2')
		local g1imp = `rho1' / (1 - `rho2')
		local g2imp = `rho2' + `rho1' * `g1imp'
	}

	* eq.(12) : plim(b3*b1 + b2) = 0 for any stationary process
	_mpa_ute `dv' `ivs', touse(`touse')
	local nlr = r(nlr)
	local nlrse = r(nlr_se)
	local nlrz = .
	if `nlrse' > 0 & `nlrse' < . local nlrz = `nlr' / `nlrse'

	* pure seasonal autocorrelation : the case the strategies cannot see
	local sF = .
	local sp = .
	local sdf = .
	if `per' > 1 & `T' > 3 * `per' + `k' + 5 {
		_mpa_seas `e1', touse(`touse') period(`per')
		local sF = r(F)
		local sp = r(p)
		local sdf = r(df)
	}

	local nwarn 0
	if "`notable'" == "" {
		_mpa_hdr "Knottnerus (1985) blind-spot diagnostics" "`dv'" `T' `k' `level'
		di as text "{p 4 4 2}These quantities say {it:when the other three" ///
			" strategies can be trusted on this series}. They are" ///
			" diagnostics, not a decision rule.{p_end}"
		di ""
		di as text "{hline 46}{c TT}{hline 31}"
		di as text "   Quantity" _col(47) "{c |}" _col(55) "Value" ///
			_col(69) "Source"
		di as text "{hline 46}{c +}{hline 31}"
		_mpa_krow "gamma(1), first-order residual autocorr." `g1' "sec.III"
		_mpa_krow "gamma(2), second-order residual autocorr." `g2' "sec.III"
		_mpa_krow "gamma(2) - gamma(1)^2" `=`g2'-`g1'^2' "eq.(15)"
		_mpa_krow "gamma(1)*[gamma(2)-gamma(1)^2]" `blind' "eq.(15)"
		di as text _col(47) "{c |}" as txt _col(51) ///
			"+-" %6.4f `seg' " = 1/sqrt(T), the yardstick"
		di as text "{hline 46}{c +}{hline 31}"
		_mpa_krow "rho(1) from an AR(2) fit of the residuals" `rho1' "eq.(7)"
		_mpa_krow "rho(2) from an AR(2) fit of the residuals" `rho2' "eq.(7)"
		_mpa_krow "R = -rho1*rho2/(1-rho2)" `Rknot' "eq.(8)"
		_mpa_krow "gamma(1) implied = rho1/(1-rho2)" `g1imp' "fn.2"
		_mpa_krow "gamma(2) implied = rho2+rho1*gamma1" `g2imp' "fn.2"
		di as text "{hline 46}{c +}{hline 31}"
		_mpa_krow "b3*b1 + b2 from Thursby's UTE" `nlr' "eq.(12)"
		_mpa_krow "   its z-ratio (the plim is zero)" `nlrz' "eq.(12)"
		if `sp' < . {
			di as text "{hline 46}{c +}{hline 31}"
			_mpa_krow "seasonal F at lags `per', `=2*`per'', `=3*`per''" `sF' "Godfrey sec.III"
			_mpa_krow "   its p-value" `sp' "Godfrey sec.III"
		}
		di as text "{hline 46}{c BT}{hline 31}"
		di ""
		di as text "   {bf:Blind-spot warnings for this series}"
		if abs(`g1') < 2 * `seg' {
			local ++nwarn
			di as text "{p 4 7 2}`nwarn'. {bf:gamma(1) is not distinguishable" ///
				" from zero.} Knottnerus sec.II and fn.1: any error process" ///
				" with E(e_t e_t-1)=0 is invisible both to Durbin-Watson and" ///
				" to Durbin's S-test, so Thursby's strategy reports {bf:NP}" ///
				" however badly the errors are autocorrelated. Pure seasonal" ///
				" autocorrelation is the leading case.{p_end}"
		}
		if abs(`g2' - `g1'^2) < 2 * `seg' & abs(`g1') >= 2 * `seg' {
			local ++nwarn
			di as text "{p 4 7 2}`nwarn'. {bf:gamma(2) is close to" ///
				" gamma(1)^2.} Knottnerus sec.IV: Durbin's S-test is then" ///
				" insignificant while DW is significant, so Thursby's" ///
				" strategy labels genuinely non-AR(1) errors {bf:AR(1)}.{p_end}"
		}
		if `sp' < `level'/100 & `sp' < . {
			local ++nwarn
			di as text "{p 4 7 2}`nwarn'. {bf:Seasonal autocorrelation is" ///
				" significant} (F = " %7.3f `sF' ", p = " %6.4f `sp' ")." ///
				" This is exactly the case Knottnerus showed Thursby's" ///
				" procedure cannot detect. Use {bf:mispauto godfrey} with" ///
				" q at least `=`per'-1', which is Godfrey's (1987) fix.{p_end}"
		}
		if abs(`nlrz') < 1.96 | `nlrz' >= . {
			local ++nwarn
			di as text "{p 4 7 2}`nwarn'. {bf:b3*b1+b2 is indistinguishable" ///
				" from zero}, as Knottnerus eq.(12) predicts for {it:any}" ///
				" stationary error process. The LR stage of Thursby's LRS" ///
				" therefore carries no information here: its asymptotic power" ///
				" equals its nominal size. Prefer {bf:slrs}.{p_end}"
		}
		if `nwarn' == 0 {
			di as text "{p 4 7 2}None. gamma(1) is measurable, gamma(2)" ///
				" differs from gamma(1)^2, and no seasonal autocorrelation" ///
				" was found, so this series is in none of the three blind" ///
				" spots Knottnerus identified.{p_end}"
		}
	}
	else {
		if abs(`g1') < 2 * `seg' local ++nwarn
		if abs(`g2' - `g1'^2) < 2 * `seg' & abs(`g1') >= 2 * `seg' local ++nwarn
		if `sp' < `level'/100 & `sp' < . local ++nwarn
		if abs(`nlrz') < 1.96 | `nlrz' >= . local ++nwarn
	}

	if "`graph'" != "" {
		local gn = "gamma(1)=" + string(`g1', "%6.4f") ///
			+ "   gamma(2)-gamma(1)^2=" + string(`g2'-`g1'^2, "%6.4f") ///
			+ "   band=" + string(1.96*`seg', "%6.4f")
		_mpa_gcorr `e1', touse(`touse') n(`T') name(`name') seasonal(`per') ///
			title("Knottnerus (1985): where the strategies go blind") ///
			note("`gn'")
	}

	return local cmd    "mispauto"
	return local subcmd "knottnerus"
	return local depvar "`dv'"
	return local indeps "`ivs'"
	return local period "`perlab'"
	return scalar N      = `T'
	return scalar k      = `k'
	return scalar lags   = `lags'
	return scalar periodicity = `per'
	return scalar gamma1 = `g1'
	return scalar gamma2 = `g2'
	return scalar g2_g1sq = `g2' - `g1'^2
	return scalar blind  = `blind'
	return scalar se_gamma = `seg'
	return scalar rho1   = `rho1'
	return scalar rho2   = `rho2'
	return scalar R      = `Rknot'
	return scalar gamma1_implied = `g1imp'
	return scalar gamma2_implied = `g2imp'
	return scalar nlr    = `nlr'
	return scalar nlr_se = `nlrse'
	return scalar nlr_z  = `nlrz'
	return scalar F_seas = `sF'
	return scalar df_seas = `sdf'
	return scalar p_seas = `sp'
	return scalar n_warnings = `nwarn'
	return matrix ac = `AC'
end


*===============================================================================
* ALL
*===============================================================================
program define _mpa_all, rclass
	* parse an instrument list only when a varlist was actually supplied;
	* _iv_parse errors on an empty one, which would break postestimation use
	local dv    ""
	local exog  ""
	local endog ""
	local inst  ""
	gettoken tk1 : 0, parse(" ,")
	local novl 0
	if `"`tk1'"' == "" | `"`tk1'"' == "," local novl 1
	if `"`tk1'"' == "if" | `"`tk1'"' == "in" local novl 1
	if `novl' == 0 {
		_iv_parse `0'
		local dv    "`s(lhs)'"
		local exog  "`s(exog)'"
		local endog "`s(endog)'"
		local inst  "`s(inst)'"
		local 0     `"`s(zero)'"'
	}

	syntax [if] [in] [, LEVel(real 5) Graph Name(string) NOTABLE ]

	local ivs "`exog' `endog'"
	if "`ivs'" == "" {
		_mpa_getmodel ""
		local dv  "`r(depvar)'"
		local ivs "`r(indeps)'"
	}

	if "`notable'" == "" {
		di ""
		di as text "{hline 78}"
		di as text "  mispauto all" _col(22) ///
			"four strategies on the same equation"
		di as text "{hline 78}"
	}

	mispauto thursby `dv' `ivs' `if' `in', level(`level') `notable'
	local v1 "`r(verdict)'"
	local c1 "`r(pattern)'"

	mispauto godfrey `dv' `ivs' `if' `in', level(`level') `notable'
	local v2 "`r(verdict)'"
	local h2 "`r(hypothesis)'"

	local v3 "not run"
	local p3 = .
	if "`endog'" != "" & "`inst'" != "" {
		mispauto ghutton `dv' `exog' (`endog' = `inst') `if' `in', ///
			level(`level') `notable'
		local v3 "`r(verdict)'"
		local p3 = r(p_J)
	}

	mispauto knottnerus `dv' `ivs' `if' `in', level(`level') `notable'
	local nw = r(n_warnings)
	local g1 = r(gamma1)
	local gd = r(g2_g1sq)
	local ps = r(p_seas)

	local r3 = "stage-1 J p = " + string(`p3', "%6.4f")
	if "`v3'" == "not run" local r3 "no (endog = insts) given"
	local kread = "gamma1 = " + string(`g1', "%6.4f")

	if "`notable'" == "" {
		di ""
		di as text "{hline 78}"
		di as text "  Side-by-side verdicts" _col(58) "overall level " ///
			as res %5.2f `level' as text "%"
		di as text "{hline 14}{c TT}{hline 20}{c TT}{hline 42}"
		di as text "   Strategy  {c |}  Diagnosis" _col(37) "{c |}  Reading"
		di as text "{hline 14}{c +}{hline 20}{c +}{hline 42}"
		_mpa_arow "Thursby 81"  "`v1'"            "pattern `c1'"
		_mpa_arow "Godfrey 87"  "`v2'"            "adopted `h2'"
		_mpa_arow "G-Hutton 94" "`v3'"            "`r3'"
		_mpa_arow "Knottnerus"  "`nw' warning(s)" "`kread'"
		di as text "{hline 14}{c BT}{hline 20}{c BT}{hline 42}"
		di ""
		if "`v1'" != "`v2'" {
			di as text "{p 4 7 2}{bf:The two autocorrelation strategies disagree.}" ///
				" Godfrey (1987) is the later procedure and was built to be" ///
				" robust to precisely the non-robustness Knottnerus (1985)" ///
				" exposed in Thursby's, so {bf:`v2'} is the better-supported" ///
				" reading. Thursby's RESET uses no autocorrelation-consistent" ///
				" covariance matrix, and Porter & Kashyap (1984) measured up to" ///
				" 77% false detections of misspecification from that at T=200." ///
				"{p_end}"
		}
		else {
			di as text "{p 4 7 2}Both autocorrelation strategies agree on" ///
				" {bf:`v1'}.{p_end}"
		}
		if `nw' > 0 {
			di as text "{p 4 7 2}{bf:Read the Knottnerus block first} --" ///
				" `nw' blind-spot warning(s) were raised for this series, so at" ///
				" least one of the verdicts above may be unreliable.{p_end}"
		}
	}

	return local cmd    "mispauto"
	return local subcmd "all"
	return local depvar "`dv'"
	return local indeps "`ivs'"
	return local v_thursby "`v1'"
	return local v_godfrey "`v2'"
	return local v_ghutton "`v3'"
	return local pattern   "`c1'"
	return local hypothesis "`h2'"
	return scalar level  = `level'
	return scalar n_warnings = `nw'
	return scalar gamma1 = `g1'
	return scalar g2_g1sq = `gd'
	return scalar p_seas = `ps'
	return scalar agree  = ("`v1'" == "`v2'")
end


*===============================================================================
* COMPONENT TESTS
*===============================================================================

* --- Durbin-Watson with an exact (Imhof 1961) or large-sample p-value --------
program define _mpa_dw, rclass
	syntax anything, Touse(name) Resid(name) ///
		[ side(string) method(string) maxt(integer 1000) ]
	gettoken dv ivs : anything

	tempvar dsq ssq
	qui gen double `dsq' = (`resid' - L.`resid')^2 if `touse'
	qui summ `dsq' if `touse', meanonly
	local num = r(sum)
	qui gen double `ssq' = `resid' * `resid' if `touse'
	qui summ `ssq' if `touse', meanonly
	local den = r(sum)
	if `den' <= 0 {
		di as err "the residual sum of squares is zero; DW is undefined"
		exit 498
	}
	local dw = `num' / `den'

	qui count if `touse'
	local T = r(N)
	local k : word count `ivs'

	local plo = .
	local phi = .
	local meth "`method'"
	if "`method'" == "imhof" {
		if `T' <= `maxt' {
			tempname PP
			capture mata: mpa_dwexact("`ivs'", "`touse'", `dw', "`PP'")
			if _rc == 0 {
				local plo = `PP'[1,1]
				local phi = `PP'[1,2]
			}
		}
		else {
			di as text "{p 4 7 2}note: T = `T' exceeds maxtdw(`maxt'), so the" ///
				" large-sample p-value is used instead of the exact one" ///
				" (the exact route needs a T x T eigendecomposition). Raise" ///
				" {bf:maxtdw()} to force it.{p_end}"
		}
	}
	if `plo' >= . {
		local z = (1 - `dw'/2) * sqrt(`T')
		local plo = normal(-`z')
		local phi = normal(`z')
		local meth "normal"
	}
	else {
		local meth "exact (Imhof)"
	}

	local p = `plo'
	if "`side'" == "upper" local p = `phi'
	if "`side'" == "two"   local p = 2 * min(`plo', `phi')
	if `p' > 1 local p = 1

	return scalar dw = `dw'
	return scalar p  = `p'
	return scalar p_lower = `plo'
	return scalar p_upper = `phi'
	return scalar N  = `T'
	return scalar k  = `k'
	return local  method "`meth'"
end

* --- RESET, with the four Thursby-Schmidt (1977) test-variable sets ---------
program define _mpa_reset, rclass
	syntax anything, Touse(name) ///
		[ powers(numlist) vars(string) resetmod ]
	gettoken dv ivs : anything

	qui count if `touse'
	local T = r(N)
	local k : word count `ivs'
	local rho = .

	* automatic degradation of the power set when df run out
	local p1 "`powers'"
	local f4 4
	local f3 3
	local p2 : list p1 - f4
	local p3 : list p2 - f3

	local ok 0
	forvalues s = 1/3 {
		if `ok' == 0 {
			local ps "`p`s''"
			if "`ps'" != "" {
				capture drop __mpa_z*
				_mpa_zbuild `dv' `ivs', touse(`touse') powers(`ps') ///
					vars(`vars')
				local m = r(m)
				local zl "`r(zlist)'"
				if `m' > 0 & `T' - `k' - `m' - 1 >= 10 {
					if "`resetmod'" == "" {
						capture qui regress `dv' `ivs' `zl' if `touse'
					}
					else {
						* Porter & Kashyap (1984) Table 3: estimate rho in
						* both models by one-step Cochrane-Orcutt, then test
						capture qui prais `dv' `ivs' if `touse', corc twostep nodw
						if _rc == 0 {
							local rho = e(rho)
							tempvar yq
							qui gen double `yq' = `dv' - `rho'*L.`dv' if `touse'
							local xq
							local jj 0
							foreach v of local ivs {
								local ++jj
								qui gen double __mpa_q`jj' = ///
									`v' - `rho'*L.`v' if `touse'
								local xq "`xq' __mpa_q`jj'"
							}
							local jj 0
							foreach v of local zl {
								local ++jj
								qui gen double __mpa_r`jj' = ///
									`v' - `rho'*L.`v' if `touse'
								local zq "`zq' __mpa_r`jj'"
							}
							capture qui regress `yq' `xq' `zq' if `touse'
							local zl "`zq'"
						}
					}
					if _rc == 0 {
						capture qui testparm `zl'
						if _rc == 0 {
							local ok 1
							local used "`ps'"
							local F = r(F)
							local df = r(df)
							local dfr = r(df_r)
							local pv = r(p)
						}
					}
				}
			}
		}
	}
	capture drop __mpa_z*
	capture drop __mpa_q*
	capture drop __mpa_r*
	if `ok' == 0 {
		di as err "RESET is not computable: too few residual degrees of freedom"
		di as err "{p 4 4 2}with `k' regressors and T = `T' even the squares" ///
			" alone exhaust the sample; reduce the model, or narrow" ///
			" {bf:resetpowers()}{p_end}"
		exit 2001
	}

	return scalar F    = `F'
	return scalar df   = `df'
	return scalar df_r = `dfr'
	return scalar p    = `pv'
	return scalar rho  = `rho'
	return local powers "`used'"
	return local vars   "`vars'"
end

* --- build the RESET test variables as __mpa_z1 ... -------------------------
program define _mpa_zbuild, rclass
	syntax anything, Touse(name) [ powers(numlist) vars(string) ]
	gettoken dv ivs : anything
	if "`vars'" == "" local vars pox

	local m 0
	local zlist

	if "`vars'" == "poy" {
		* Ramsey (1969): powers of the fitted values
		tempvar yh
		qui regress `dv' `ivs' if `touse'
		qui predict double `yh' if `touse', xb
		_mpa_pow `yh' "yhat" "`powers'" `touse' `m'
		local m = r(m)
		local zlist "`r(zlist)'"
	}
	else if "`vars'" == "ts" {
		* truncated Taylor series: squares and cross products of X
		local i 0
		foreach v of local ivs {
			local ++i
			local jj 0
			foreach w of local ivs {
				local ++jj
				if `jj' >= `i' {
					capture confirm numeric variable `v'
					local rc1 = _rc
					capture confirm numeric variable `w'
					if `rc1' == 0 & _rc == 0 {
						local ++m
						qui gen double __mpa_z`m' = `v' * `w' if `touse'
						label var __mpa_z`m' "`v'*`w'"
						local zlist "`zlist' __mpa_z`m'"
					}
				}
			}
		}
	}
	else if "`vars'" == "pc" {
		* powers of the principal components of X
		local nv : word count `ivs'
		if `nv' < 2 {
			di as err "resetvars(pc) needs at least two regressors"
			di as err "{p 4 4 2}principal components of a single variable" ///
				" are that variable rescaled, so the test variables would" ///
				" be identical to {bf:resetvars(pox)}; use that instead" ///
				"{p_end}"
			exit 198
		}
		capture qui pca `ivs' if `touse'
		if _rc == 0 {
			capture qui predict double __mpa_pc* if `touse', score
			if _rc == 0 {
				unab pcl : __mpa_pc*
				local i 0
				foreach v of local pcl {
					local ++i
					_mpa_pow `v' "pc`i'" "`powers'" `touse' `m'
					local m = r(m)
					local zlist "`zlist' `r(zlist)'"
				}
			}
		}
		capture drop __mpa_pc*
		if `m' == 0 {
			di as err "resetvars(pc) failed: the principal components could not be computed"
			di as err "{p 4 4 2}check for collinear or constant regressors," ///
				" or use {bf:resetvars(pox)}{p_end}"
			exit 498
		}
	}
	else {
		* POX: powers of the included regressors -- Thursby & Schmidt's
		* recommended set and Thursby (1981)'s choice.  Each regressor is
		* rescaled to [0,1] first, which leaves the joint F numerically
		* unchanged (see help mispauto methods) but conditions the design.
		foreach v of local ivs {
			capture confirm numeric variable `v'
			if _rc == 0 {
				qui summ `v' if `touse', meanonly
				local lo = r(min)
				local hi = r(max)
				local isbin 0
				capture assert `v' == 0 | `v' == 1 | `v' >= . if `touse'
				if _rc == 0 local isbin 1
				if `hi' > `lo' & `isbin' == 0 {
					tempvar sc
					qui gen double `sc' = (`v' - `lo')/(`hi' - `lo') if `touse'
					_mpa_pow `sc' "`v'" "`powers'" `touse' `m'
					local m = r(m)
					local zlist "`zlist' `r(zlist)'"
					drop `sc'
				}
			}
		}
	}
	return scalar m = `m'
	return local zlist "`zlist'"
end

* --- generate powers of one variable into __mpa_z<n> -----------------------
program define _mpa_pow, rclass
	args v lab pw touse m
	local zlist
	foreach j of numlist `pw' {
		local ++m
		qui gen double __mpa_z`m' = `v'^`j' if `touse'
		label var __mpa_z`m' "`lab'^`j'"
		local zlist "`zlist' __mpa_z`m'"
	}
	return scalar m = `m'
	return local zlist "`zlist'"
end

* --- Thursby's UTE, eq.(2) : rho-hat and b3*b1+b2 with its SE --------------
program define _mpa_ute, rclass
	syntax anything, Touse(name)
	gettoken dv ivs : anything

	capture drop __mpa_l*
	local lagl
	local j 0
	foreach v of local ivs {
		local ++j
		qui gen double __mpa_lx`j' = L.`v' if `touse'
		local lagl "`lagl' __mpa_lx`j'"
	}
	qui gen double __mpa_ly = L.`dv' if `touse'

	capture qui regress `dv' `ivs' `lagl' __mpa_ly if `touse'
	if _rc {
		capture drop __mpa_l*
		return scalar nlr = .
		return scalar nlr_se = .
		return scalar rho = .
		return scalar rss_u = .
		exit
	}
	local rho = _b[__mpa_ly]
	local ssu = e(rss)
	local Tu  = e(N)

	local v1  : word 1 of `ivs'
	local lv1 : word 1 of `lagl'
	local nlr = .
	local nlrse = .
	capture qui nlcom (_b[__mpa_ly]*_b[`v1'] + _b[`lv1'])
	if _rc == 0 {
		tempname bb VV
		matrix `bb' = r(b)
		matrix `VV' = r(V)
		local nlr   = `bb'[1,1]
		local nlrse = sqrt(`VV'[1,1])
	}
	capture drop __mpa_l*

	return scalar nlr    = `nlr'
	return scalar nlr_se = `nlrse'
	return scalar rho    = `rho'
	return scalar rss_u  = `ssu'
	return scalar N      = `Tu'
end

* --- LRS : Durbin's S-test on eq.(2), then the LR of eq.(4) ----------------
program define _mpa_lrs, rclass
	syntax anything, Touse(name) ///
		[ level(real 0.025) miss0 rte(string) slrs ]
	gettoken dv ivs : anything
	local k : word count `ivs'

	capture drop __mpa_l*
	local lagl
	local j 0
	foreach v of local ivs {
		local ++j
		qui gen double __mpa_lx`j' = L.`v' if `touse'
		local lagl "`lagl' __mpa_lx`j'"
	}
	qui gen double __mpa_ly = L.`dv' if `touse'

	capture qui regress `dv' `ivs' `lagl' __mpa_ly if `touse'
	if _rc {
		capture drop __mpa_l*
		di as err "the unrestricted transformed equation (2) could not be fitted"
		exit 498
	}
	local rho = _b[__mpa_ly]
	local ssu = e(rss)
	local Tu  = e(N)

	* step 1 : Durbin's S-test -- regress the residual on its own lag AND the
	* right-hand-side variables of (2), then test the lagged residual.  That
	* is exactly what estat durbinalt, lags(1) computes.
	local sF = .
	local s_p = .
	local sdf = 1
	capture qui estat durbinalt, lags(1) small `miss0'
	if _rc == 0 {
		tempname mF mp
		matrix `mF' = r(F)
		matrix `mp' = r(p)
		local sF  = `mF'[1,1]
		local s_p = `mp'[1,1]
	}
	local Ssig = 0
	if `s_p' < `level' local Ssig = 1

	* steps 2-4 : restricted fit, then eq.(4)
	local lr = .
	local lr_p = .
	local lrdf = `k'
	if "`slrs'" == "" {
		local ssr
		if "`rte'" == "corc" | "`rte'" == "prais" {
			local cc
			if "`rte'" == "corc" local cc "corc"
			capture qui prais `dv' `ivs' if `touse', `cc' nodw
			if _rc == 0 local ssr = e(rss)
		}
		else {
			* Durbin's transform, exactly as Thursby step 3 writes it
			tempvar yt
			qui gen double `yt' = `dv' - `rho'*L.`dv' if `touse'
			local xt
			local j 0
			foreach v of local ivs {
				local ++j
				qui gen double __mpa_xt`j' = `v' - `rho'*L.`v' if `touse'
				local xt "`xt' __mpa_xt`j'"
			}
			capture qui regress `yt' `xt' if `touse'
			if _rc == 0 local ssr = e(rss)
			capture drop __mpa_xt*
		}
		if "`ssr'" != "" & `ssu' > 0 {
			local lr = -`Tu' * ln(`ssu' / `ssr')
			if `lr' < 0 local lr = 0
			local lr_p = chi2tail(`k', `lr')
		}
	}
	local LRsig = 0
	if `lr_p' < `level' local LRsig = 1

	* LRS rejects if S rejects, or if S accepts and LR rejects
	local Lsig = 0
	if `Ssig' local Lsig = 1
	if `Ssig' == 0 & `LRsig' == 1 local Lsig = 1

	capture drop __mpa_l*
	return scalar s_F    = `sF'
	return scalar s_p    = `s_p'
	return scalar s_df   = `sdf'
	return scalar s_sig  = `Ssig'
	return scalar lr     = `lr'
	return scalar lr_p   = `lr_p'
	return scalar lr_df  = `lrdf'
	return scalar lr_sig = `LRsig'
	return scalar lrs_sig = `Lsig'
	return scalar rho    = `rho'
	return scalar rss_u  = `ssu'
end

* --- Godfrey eq.(10) : autocorrelation-robust Wald test of alpha = 0 -------
program define _mpa_robreset, rclass
	syntax anything, Touse(name) ///
		[ powers(numlist) vars(string) truncate(integer 4) kernel(string) ]
	gettoken dv ivs : anything

	qui count if `touse'
	local T = r(N)
	local k : word count `ivs'

	local p1 "`powers'"
	local f4 4
	local f3 3
	local p2 : list p1 - f4
	local p3 : list p2 - f3

	local ok 0
	forvalues s = 1/3 {
		if `ok' == 0 {
			local ps "`p`s''"
			if "`ps'" != "" {
				capture drop __mpa_z*
				_mpa_zbuild `dv' `ivs', touse(`touse') powers(`ps') vars(`vars')
				local m = r(m)
				local zl "`r(zlist)'"
				if `m' > 0 & `T' - `k' - `m' - 1 >= 10 {
					local ok 1
					local used "`ps'"
				}
			}
		}
	}
	if `ok' == 0 {
		capture drop __mpa_z*
		di as err "the robust check of (b) is not computable: too few residual df"
		exit 2001
	}

	local stat = .
	local pv = .
	local rk = `m'
	local npd 0
	if "`kernel'" == "bartlett" {
		local lg = max(1, `truncate')
		capture qui newey `dv' `ivs' `zl' if `touse', lag(`lg')
		if _rc == 0 {
			capture qui testparm `zl'
			if _rc == 0 {
				local stat = r(F) * r(df)
				local pv = chi2tail(`m', `stat')
			}
		}
	}
	else {
		tempname RES
		capture mata: mpa_hacwald("`dv'", "`ivs'", "`zl'", "`touse'", ///
			`truncate', "`RES'")
		if _rc == 0 {
			local stat = `RES'[1,1]
			local rk   = `RES'[1,2]
			local npd  = `RES'[1,3]
			if `rk' > 0 local pv = chi2tail(`rk', `stat')
		}
	}
	capture drop __mpa_z*

	if `stat' >= . {
		di as err "the autocorrelation-robust check of (b) could not be computed"
		exit 498
	}

	return scalar stat  = `stat'
	return scalar df    = `m'
	return scalar rank  = `rk'
	return scalar nonpd = `npd'
	return scalar p     = `pv'
	return local powers "`used'"
	return local vars   "`vars'"
end

* --- White & Domowitz (1984) eq.(4.2) : choose the truncation lag ----------
program define _mpa_wdtrunc, rclass
	syntax anything, Touse(name) [ level(real 5) maxlag(integer -1) rule(string) ]
	gettoken dv ivs : anything
	if "`rule'" == "" local rule "last"

	qui count if `touse'
	local T = r(N)
	* Theorem 3.5 requires l = o(T^(1/3))
	if `maxlag' < 0 local maxlag = max(1, floor(`T'^(1/3)) - 1)

	tempname WD
	capture mata: mpa_wdtrunc("`dv'", "`ivs'", "`touse'", `maxlag', "`WD'")
	if _rc {
		return scalar l = 1
		return scalar maxlag = `maxlag'
		return scalar stat_joint = .
		return scalar p_joint = .
		exit
	}

	* Sequential rule with Bonferroni-adjusted levels (White & Domowitz
	* sec.4, final paragraph: "sequential tests of conservative size can be
	* constructed by using Bonferroni bounds").
	*
	* rule(last) -- the default -- sets j to the LARGEST significant lag, not
	* to the lag before the first insignificant one.  The "stop at the first
	* insignificant lag" reading fails on exactly the process this package
	* exists to diagnose: for a pure seasonal error, lag 1 is insignificant
	* (gamma(1)=0) while lag s is large, so a first-stop rule returns j=0 and
	* throws away the autocorrelation entirely.  rule(first) is available for
	* the strict reading.
	local alev = `level' / (100 * `maxlag')
	local l 0
	local lfirst 0
	local stop 0
	local sj 0
	local dj 0
	forvalues t = 1/`maxlag' {
		local pt = `WD'[`t',4]
		local sj = `sj' + `WD'[`t',2]
		local dj = `dj' + `WD'[`t',3]
		local sig = 0
		if `pt' < `alev' & `pt' < . local sig = 1
		if `sig' local l = `t'
		if `stop' == 0 {
			if `sig' {
				local lfirst = `t'
			}
			else {
				local stop 1
			}
		}
	}
	if "`rule'" == "first" local l = `lfirst'
	local pjoint = .
	if `dj' > 0 local pjoint = chi2tail(`dj', `sj')

	return scalar l = `l'
	return scalar l_first = `lfirst'
	return scalar maxlag = `maxlag'
	return scalar alpha_each = `alev'
	return scalar stat_joint = `sj'
	return scalar df_joint = `dj'
	return scalar p_joint = `pjoint'
	return matrix wd = `WD'
end

* --- Godfrey eq.(18) : AR(p) against AR(p+q) ------------------------------
program define _mpa_arseq, rclass
	syntax anything, Touse(name) [ p(integer 1) q(integer 3) ]
	gettoken dv ivs : anything

	tempvar e
	qui regress `dv' `ivs' if `touse'
	qui predict double `e' if `touse', resid

	* eq.(18) regresses e on its OWN LAGS ONLY; the regressors are
	* deliberately excluded (Godfrey's argument fixes beta at b), which is
	* what distinguishes this from Breusch-Godfrey and estat durbinalt
	capture drop __mpa_e*
	local keep
	local test
	forvalues j = 1/`=`p'+`q'' {
		qui gen double __mpa_e`j' = L`j'.`e' if `touse'
		if `j' <= `p' {
			local keep "`keep' __mpa_e`j'"
		}
		else {
			local test "`test' __mpa_e`j'"
		}
	}
	capture qui regress `e' `keep' `test' if `touse', noconstant
	if _rc {
		capture drop __mpa_e*
		di as err "the AR(p) against AR(p+q) test could not be computed"
		exit 498
	}
	capture qui testparm `test'
	if _rc {
		capture drop __mpa_e*
		di as err "the AR(p) against AR(p+q) restrictions could not be tested"
		exit 498
	}
	local F = r(F)
	local df = r(df)
	local dfr = r(df_r)
	local pv = r(p)
	capture drop __mpa_e*

	return scalar F    = `F'
	return scalar df   = `df'
	return scalar df_r = `dfr'
	return scalar p    = `pv'
end

* --- Godfrey sec.III(d) : serial independence against AR(1) --------------
program define _mpa_rhotest, rclass
	syntax anything, Touse(name) [ method(string) maxt(integer 1000) ]
	gettoken dv ivs : anything

	tempvar e
	qui regress `dv' `ivs' if `touse'
	qui predict double `e' if `touse', resid

	if "`method'" == "dw" {
		_mpa_dw `dv' `ivs', touse(`touse') resid(`e') side(lower) ///
			method(imhof) maxt(`maxt')
		return scalar stat = r(dw)
		return scalar p    = r(p)
		return local label "DW  (d)"
		exit
	}
	capture drop __mpa_e1
	qui gen double __mpa_e1 = L.`e' if `touse'
	qui regress `e' __mpa_e1 if `touse', noconstant
	local t  = _b[__mpa_e1] / _se[__mpa_e1]
	local pv = 2 * ttail(e(df_r), abs(`t'))
	capture drop __mpa_e1
	return scalar stat = `t'
	return scalar p    = `pv'
	return local label "t   (d)"
end

* --- Godfrey sec.IV : the lagged-dependent-variable route ----------------
program define _mpa_godfrey_ld, rclass
	syntax anything, Touse(name) [ q(integer 3) powers(numlist) vars(string) ]
	gettoken dv ivs : anything

	* Durbin's h (eq.11) needs the variance of the coefficient on L.depvar
	local ldv ""
	foreach v of local ivs {
		if "`v'" == "L.`dv'" | "`v'" == "l.`dv'" local ldv "`v'"
	}
	if "`ldv'" == "" {
		di as err "option {bf:lagdep} requires {bf:L.`dv'} among the regressors"
		di as err "{p 4 4 2}Godfrey (1987) sec.IV and Durbin (1970) eq.(11) are" ///
			" for models that actually contain a lagged dependent variable;" ///
			" without one, drop {bf:lagdep} and use the default route{p_end}"
		exit 198
	}

	di as text "{p 4 7 2}note: {bf:lagdep} selected. The White-Domowitz results" ///
		" are unavailable with a lagged dependent variable, so Godfrey's" ///
		" sec.IV route is used: the error model is imposed as AR(1+`q') and" ///
		" the hypotheses are tested by likelihood ratio.{p_end}"

	local arl
	forvalues j = 1/`=1+`q'' {
		local arl "`arl' `j'"
	}

	tempname mu mr m1
	local bstat = .
	local bdf = .
	local b_p = .
	local cstat = .
	local cdf = .
	local c_p = .

	capture drop __mpa_z*
	_mpa_zbuild `dv' `ivs', touse(`touse') powers(`powers') vars(`vars')
	local zl "`r(zlist)'"

	capture qui arima `dv' `ivs' `zl' if `touse', ar(`arl') nolog
	local rcu = _rc
	if `rcu' == 0 qui estimates store `mu'
	capture qui arima `dv' `ivs' if `touse', ar(`arl') nolog
	local rcr = _rc
	if `rcr' == 0 qui estimates store `mr'
	if `rcu' == 0 & `rcr' == 0 {
		capture qui lrtest `mu' `mr'
		if _rc == 0 {
			local bstat = r(chi2)
			local bdf = r(df)
			local b_p = r(p)
		}
	}
	capture drop __mpa_z*

	capture qui arima `dv' `ivs' if `touse', ar(1) nolog
	if _rc == 0 & `rcr' == 0 {
		qui estimates store `m1'
		capture qui lrtest `mr' `m1'
		if _rc == 0 {
			local cstat = r(chi2)
			local cdf = r(df)
			local c_p = r(p)
		}
	}

	* (d) Durbin's h-test, eq.(11) of Durbin (1970)
	tempvar e le
	qui regress `dv' `ivs' if `touse'
	local vb = (_se[`ldv'])^2
	qui predict double `e' if `touse', resid
	qui gen double `le' = L.`e' if `touse'
	qui regress `e' `le' if `touse', noconstant
	local ah = _b[`le']
	qui count if `touse'
	local T = r(N)
	local dstat = .
	local d_p = .
	if `T' * `vb' < 1 {
		local dstat = `ah' * sqrt(`T' / (1 - `T' * `vb'))
		local d_p = 2 * normal(-abs(`dstat'))
	}
	else {
		di as text "{p 4 7 2}note: T*V(b) >= 1, so Durbin's h is not defined" ///
			" (Durbin 1970, below eq.11). The (d) row is left missing.{p_end}"
	}

	capture estimates drop `mu'
	capture estimates drop `mr'
	capture estimates drop `m1'

	return scalar b_stat = `bstat'
	return scalar b_df   = `bdf'
	return scalar b_p    = `b_p'
	return scalar c_stat = `cstat'
	return scalar c_df   = `cdf'
	return scalar c_p    = `c_p'
	return scalar d_stat = `dstat'
	return scalar d_p    = `d_p'
end

* --- pure seasonal autocorrelation in the residuals ---------------------
program define _mpa_seas, rclass
	syntax anything, Touse(name) [ period(integer 4) ]
	local e "`anything'"
	capture drop __mpa_s*
	local sl
	forvalues j = 1/3 {
		local lg = `j' * `period'
		qui gen double __mpa_s`j' = L`lg'.`e' if `touse'
		local sl "`sl' __mpa_s`j'"
	}
	capture qui regress `e' `sl' if `touse', noconstant
	if _rc == 0 {
		capture qui testparm `sl'
	}
	if _rc {
		capture drop __mpa_s*
		return scalar F = .
		return scalar p = .
		return scalar df = .
		exit
	}
	local F = r(F)
	local df = r(df)
	local pv = r(p)
	capture drop __mpa_s*
	return scalar F  = `F'
	return scalar df = `df'
	return scalar p  = `pv'
end


*===============================================================================
* HELPERS
*===============================================================================

* --- generic option validator ------------------------------------------
program define _mpa_ckopt, rclass
	args nm val ok
	local d : word 1 of `ok'
	if "`val'" == "" local val "`d'"
	local hit 0
	foreach w of local ok {
		if "`val'" == "`w'" local hit 1
	}
	if `hit' == 0 {
		di as err "`nm'() must be one of: `ok'"
		exit 198
	}
	return local v "`val'"
end

* --- varlist from the command line, or read the model back from e() -----
program define _mpa_getmodel, rclass
	args any
	if `"`any'"' != "" {
		gettoken dv ivs : any
		unab dv  : `dv'
		unab ivs : `ivs'
		if "`ivs'" == "" {
			di as err "at least one independent variable is required"
			exit 102
		}
		return local depvar "`dv'"
		return local indeps "`ivs'"
		return scalar post = 0
		exit
	}
	if "`e(cmd)'" == "" {
		di as err "no estimation results found"
		di as err "{p 4 4 2}either give {it:depvar indepvars} on the command" ///
			" line, or fit the model with {bf:regress} first{p_end}"
		exit 301
	}
	if !inlist("`e(cmd)'", "regress", "newey", "prais", "ivregress") {
		di as err "mispauto cannot run as postestimation after {bf:`e(cmd)'}"
		di as err "{p 4 4 2}supported: {bf:regress}, {bf:newey}, {bf:prais}," ///
			" {bf:ivregress}; otherwise give the varlist explicitly{p_end}"
		exit 301
	}
	local dv "`e(depvar)'"
	local iv : colnames e(b)
	local iv : subinstr local iv "_cons" "", word
	local iv : list retokenize iv
	if "`iv'" == "" {
		di as err "no regressors found in e(b)"
		exit 301
	}
	return local depvar "`dv'"
	return local indeps "`iv'"
	return scalar post = 1
end

program define _mpa_cktime, rclass
	capture qui tsset
	if _rc {
		di as err "the data must be {bf:tsset} before using mispauto"
		exit 459
	}
	local tv "`r(timevar)'"
	local pv "`r(panelvar)'"
	if "`tv'" == "" {
		di as err "the data must be {bf:tsset} before using mispauto"
		exit 459
	}
	if "`pv'" != "" {
		di as err "mispauto is a time-series command"
		di as err "{p 4 4 2}the data are {bf:xtset} as a panel; these four" ///
			" strategies are all derived for a single time series{p_end}"
		exit 459
	}
	return local timevar "`tv'"
end

program define _mpa_ckgaps
	args touse
	capture qui tsreport if `touse', report
	if _rc == 0 {
		if r(N_gaps) > 0 {
			di as text "{p 4 7 2}{bf:note:} the sample has " as res r(N_gaps) ///
				as text " gap(s). Every statistic here is built from lagged" ///
				" residuals, so gaps cost observations and the exact" ///
				" Durbin-Watson distribution no longer applies.{p_end}"
		}
	}
end

program define _mpa_period, rclass
	qui tsset
	local u1 "`r(unit1)'"
	local per 1
	local lab "annual or undated"
	if "`u1'" == "y" local lab "yearly"
	if "`u1'" == "h" {
		local per 2
		local lab "half-yearly"
	}
	if "`u1'" == "q" {
		local per 4
		local lab "quarterly"
	}
	if "`u1'" == "m" {
		local per 12
		local lab "monthly"
	}
	if "`u1'" == "w" {
		local per 52
		local lab "weekly"
	}
	if "`u1'" == "d" {
		local per 7
		local lab "daily"
	}
	return scalar period = `per'
	return local label "`lab'"
end

program define _mpa_hdr
	args ttl dv T k lev
	di ""
	di as text "{hline 78}"
	di as text "  `ttl'"
	di as text "{hline 78}"
	di as text "  Dependent variable: " as res "`dv'" as text _col(46) ///
		"Observations = " as res `T'
	di as text "  Regressors (k) = " as res `k' as text _col(46) ///
		"Nominal overall level = " as res %5.2f `lev' as text "%"
	di ""
end

program define _mpa_row
	args lab stat df p sig
	local st ""
	if `p' < 0.10 local st "*"
	if `p' < 0.05 local st "**"
	if `p' < 0.01 local st "***"
	local out "accept"
	if `sig' local out "reject"
	local sv "        ."
	if `stat' < . local sv = string(`stat', "%9.4f")
	local pv "       ."
	if `p' < . local pv = string(`p', "%7.4f")
	di as text _col(4) "`lab'" _col(14) "{c |}" ///
		as res _col(23) "`sv'" ///
		as text _col(38) "`df'" ///
		as res _col(49) "`pv'" "`st'" ///
		as text _col(63) "`out'"
end

program define _mpa_row2
	args lab stat df p sig
	local st ""
	if `p' < 0.10 local st "*"
	if `p' < 0.05 local st "**"
	if `p' < 0.01 local st "***"
	local out "accept"
	if `sig' local out "reject"
	local sv "        ."
	if `stat' < . local sv = string(`stat', "%9.4f")
	local pv "       ."
	if `p' < . local pv = string(`p', "%7.4f")
	di as text _col(4) "`lab'" _col(16) "{c |}" ///
		as res _col(25) "`sv'" ///
		as text _col(39) "`df'" ///
		as res _col(50) "`pv'" "`st'" ///
		as text _col(64) "`out'"
end

program define _mpa_sub
	args txt
	di as text _col(14) "{c |}" as txt _col(19) "{it:`txt'}"
end

program define _mpa_sub2
	args txt
	di as text _col(16) "{c |}" as txt _col(21) "{it:`txt'}"
end

program define _mpa_krow
	args lab val ref
	local vv "         ."
	if `val' < . local vv = string(`val', "%11.5f")
	di as text _col(4) "`lab'" _col(47) "{c |}" ///
		as res _col(51) "`vv'" as text _col(69) "`ref'"
end

program define _mpa_arow
	args lab verd read
	di as text _col(4) "`lab'" _col(15) "{c |}" ///
		as res _col(19) "`verd'" as text _col(35) "{c |}" ///
		as txt _col(39) "`read'"
end

* --- decode a verdict into a label and the recommended response ---------
program define _mpa_verdict, rclass
	args v
	local lb ""
	local rp ""
	if "`v'" == "NP" {
		local lb "no problem with the regression"
		local rp "Report the OLS estimates as they stand."
	}
	if "`v'" == "AR(1)" {
		local lb "first-order autoregressive disturbances"
		local rp "Re-estimate allowing for AR(1) errors: {bf:prais} for Prais-Winsten, or {bf:prais, corc} for Cochrane-Orcutt."
	}
	if "`v'" == "NAR" {
		local lb "non-white-noise disturbances other than AR(1)"
		local rp "Do {it:not} apply an AR(1) correction. Identify the process first with {bf:corrgram}, {bf:ac} and {bf:pac}, then either model it ({bf:arima}) or keep OLS with an autocorrelation-consistent covariance matrix ({bf:newey}). Amemiya's (1973) GLS with an estimated autocovariance matrix is the estimator Godfrey recommends here."
	}
	if "`v'" == "MS" {
		local lb "misspecification: an omitted variable or the wrong functional form"
		local rp "Do {it:not} correct for autocorrelation -- respecify. A significant RESET says the conditional mean is wrong, and an AR(1) correction would leave the estimator inconsistent."
	}
	if "`v'" == "MS+ARMA" {
		local lb "hypothesis (a): regression function misspecified, errors ARMA of unknown order"
		local rp "Respecify the regression function. Because the check of (b) used an autocorrelation-consistent covariance matrix, this rejection is not an artifact of serial correlation."
	}
	if "`v'" == "RESPEC" {
		local lb "stage 1 rejected: the EV/S formulation and/or the instruments are inadequate"
		local rp "Do {it:not} present IV estimates. A significant J means the overidentifying restrictions fail, so instrumenting does not repair the equation; reconsider the specification and the validity of the excluded instruments."
	}
	if "`v'" == "EV/S" {
		local lb "errors in variables or simultaneity"
		local rp "Present the IV estimates: stage 1 accepted the EV/S formulation and stage 2 rejected Omega = 0."
	}
	if "`v'" == "OLS" {
		local lb "no simultaneity and no measurement error"
		local rp "Present the OLS estimates: here they are consistent and efficient relative to IV."
	}
	if "`lb'" == "" {
		local lb "`v'"
		local rp "See {bf:help mispauto}."
	}
	di as text "{p 4 7 2}(`lb'){p_end}"
	di as text "{p 4 7 2}" as res "Response: " as text "`rp'{p_end}"
	return local label "`lb'"
	return local resp  "`rp'"
end

* --- graph : residual correlogram with Bartlett bands ------------------
program define _mpa_gcorr
	syntax anything, Touse(name) N(integer) ///
		[ name(string) title(string) note(string) seasonal(integer 0) ]
	local e "`anything'"

	local L = min(24, floor(`n'/4))
	if `L' < 2 {
		di as text "{p 4 7 2}note: too few observations to draw a correlogram.{p_end}"
		exit
	}
	tempname AC
	mata: mpa_acf("`e'", "`touse'", `L', "`AC'")

	local gname "mispauto_corr"
	if "`name'" != "" local gname "`name'"

	preserve
	clear
	qui svmat double `AC', name(mpa)
	qui gen double bnd = 1.96 / sqrt(`n')
	qui gen double nbnd = -bnd

	* highlight the seasonal lags only when the periodicity is known and at
	* least one such lag is in range; otherwise the extra series would show
	* as an empty key in the legend
	local nseas 0
	local seasplot
	local seaskey
	if `seasonal' > 1 {
		qui gen double acs = .
		qui replace acs = mpa2 if mod(mpa1, `seasonal') == 0
		qui count if acs < .
		local nseas = r(N)
		if `nseas' > 0 {
			local seasplot `"(bar acs mpa1, barwidth(0.62) color(cranberry))"'
			local seaskey `"2 "seasonal lag (every `seasonal')" 3"'
		}
	}
	if `nseas' == 0 {
		local seaskey "2"
	}

	* thin the x-axis ticks so the labels stay readable
	local step = 1
	if `L' > 16 local step = 2
	if `L' > 32 local step = 4

	capture graph twoway                                                  ///
		(bar mpa2 mpa1, barwidth(0.62) color(navy))                   ///
		`seasplot'                                                    ///
		(line bnd mpa1, lpattern(dash) lcolor(gs7) lwidth(medthin))   ///
		(line nbnd mpa1, lpattern(dash) lcolor(gs7) lwidth(medthin)), ///
		  legend(order(1 "residual autocorrelation" `seaskey'         ///
			"{c 177}1.96/{&radic}T") rows(1) size(small)           ///
			pos(6) ring(1) region(lstyle(none)) symxsize(6))      ///
		  yline(0, lcolor(black) lwidth(thin))                        ///
		  xtitle("Lag", size(small))                                  ///
		  ytitle("Residual autocorrelation", size(small))             ///
		  xlabel(`step'(`step')`L', labsize(small) grid glpattern(dot)) ///
		  ylabel(, labsize(small) angle(horizontal) format(%4.1f))    ///
		  title("`title'", size(medsmall) color(black))               ///
		  note("`note'", size(vsmall))                                ///
		  graphregion(color(white) margin(medium))                    ///
		  plotregion(color(white) margin(zero))                       ///
		  xsize(7) ysize(4.2)                                         ///
		  name(`gname', replace) nodraw
	local grc = _rc
	restore
	if `grc' == 0 {
		graph display `gname'
	}
	else {
		di as text "{p 4 7 2}note: the correlogram could not be drawn.{p_end}"
	}
end


*===============================================================================
* MATA ENGINE
* Inside mata use // comments only -- a * comment line is parsed as
* multiplication and breaks the compile at ado-load.
*===============================================================================
version 14.0
mata:

// ---------------------------------------------------------------------------
// Imhof (1961) eq.(3.2) integrand, central case with x = 0:
//   theta(u) = 0.5 * sum(atan(h_i u)),  rho(u) = prod(1 + h_i^2 u^2)^(1/4)
// ---------------------------------------------------------------------------
real scalar mpa_imhofint(real scalar u, real colvector h)
{
	real scalar th, lr
	if (u <= 0) {
		return(0.5 * sum(h))
	}
	th = 0.5 * sum(atan(h * u))
	lr = 0.25 * sum(log(1 :+ (h:^2) * (u * u)))
	return(sin(th) / (u * exp(lr)))
}

// ---------------------------------------------------------------------------
// F(0) = P(sum h_i chi2_1 <= 0) = 1/2 - (1/pi) * integral_0^inf
//
// Two details taken from Imhof himself:
//  * the upper limit U comes from his truncation bound.  With all h_r = 1 and
//    m terms, k = m/2 and |t_U| <= 1/(pi * k * U^k * prod|h_r|^(1/2)), so U
//    is solved directly for the target error instead of being searched for.
//  * the TRAPEZOIDAL rule is used, not Simpson's.  Imhof reports that "to
//    achieve a given accuracy, longer steps are permissible with the
//    trapezoidal rule than with Simpson's rule", and that accuracy degrades
//    as the degree of the approximating polynomial rises; his Table 1 is
//    computed with the trapezoid alone.  The step is halved until two
//    consecutive results agree, which is the procedure he describes.
// ---------------------------------------------------------------------------
real scalar mpa_imhof_cdf(real colvector hin)
{
	real colvector h
	real scalar m, kk, eps, lsum, lU, U, n, i, u, S, I, Iold, done, p, nmax
	h = select(hin, abs(hin) :> 1e-12)
	m = rows(h)
	if (m < 1) {
		return(.)
	}
	kk = m / 2
	eps = 1e-9
	lsum = 0.5 * sum(log(abs(h)))
	lU = (-log(pi() * kk * eps) - lsum) / kk
	U = exp(lU)
	if (U < 10) {
		U = 10
	}
	if (U > 1e8) {
		U = 1e8
	}
	n = 256
	nmax = 262144
	Iold = .
	I = .
	done = 0
	while (done == 0) {
		u = U / n
		S = 0.5 * mpa_imhofint(0, h) + 0.5 * mpa_imhofint(U, h)
		for (i = 1; i <= n - 1; i++) {
			S = S + mpa_imhofint(i * u, h)
		}
		I = S * u
		if (Iold < .) {
			if (abs(I - Iold) < eps) {
				done = 1
			}
		}
		if (done == 0) {
			Iold = I
			n = n * 2
			if (n > nmax) {
				done = 1
			}
		}
	}
	p = 0.5 - I / pi()
	if (p < 0) {
		p = 0
	}
	if (p > 1) {
		p = 1
	}
	return(p)
}

// ---------------------------------------------------------------------------
// Exact Durbin-Watson tail probabilities.
// d = e'Ae/e'e with e = My, so P(d <= d0) = P(sum (lam_i - d0) xi_i <= 0),
// where the lam_i are the eigenvalues of Q'AQ and Q is an orthonormal basis
// of range(M) (the eigenvectors of the idempotent M with eigenvalue one).
// ---------------------------------------------------------------------------
void mpa_dwexact(string scalar xv, string scalar tv, real scalar d0,
                 string scalar outnm)
{
	real matrix X, M, A, V, Q, NU, AQ
	real colvector L, lam, h
	real rowvector idx, Lr
	real scalar T, i, plo
	X = st_data(., tokens(xv), tv)
	T = rows(X)
	X = X, J(T, 1, 1)
	M = I(T) - X * invsym(quadcross(X, X)) * X'
	M = makesymmetric(M)
	A = J(T, T, 0)
	for (i = 1; i <= T; i++) {
		A[i, i] = 2
	}
	A[1, 1] = 1
	A[T, T] = 1
	for (i = 1; i <= T - 1; i++) {
		A[i, i + 1] = -1
		A[i + 1, i] = -1
	}
	symeigensystem(M, V, Lr)
	idx = selectindex(Lr :> 0.5)
	if (cols(idx) < 1) {
		st_matrix(outnm, (., .))
		return
	}
	Q = V[., idx]
	AQ = A * Q
	NU = makesymmetric(quadcross(Q, AQ))
	lam = symeigenvalues(NU)'
	h = lam :- d0
	plo = mpa_imhof_cdf(h)
	st_matrix(outnm, (plo, 1 - plo))
}

// ---------------------------------------------------------------------------
// Godfrey (1987) eq.(10): Wald test of alpha = 0 with the White-Domowitz
// Sigma_j, whose (t,s) element is e_t e_s for |t-s| <= j and zero otherwise.
// Hence W'Sigma_j W = Gamma_0 + sum_{tau=1}^{j} (Gamma_tau + Gamma_tau').
// The truncated kernel is not guaranteed positive semi-definite, so a
// spectral generalized inverse keeping the positive eigenvalues is used and
// the rank actually used is reported back.
// ---------------------------------------------------------------------------
void mpa_hacwald(string scalar yv, string scalar xv, string scalar zv,
                 string scalar tv, real scalar j, string scalar outnm)
{
	real matrix W, X, Z, WW, iWW, Mid, G, Vv, Vaa, P, Pk, Gi, W1, W2
	real colvector y, th, e, aa, Lk, E1
	real rowvector Lr, keep
	real scalar T, kk, m, tau, stat, rk, npd, tolr, b
	y = st_data(., tokens(yv), tv)
	X = st_data(., tokens(xv), tv)
	Z = st_data(., tokens(zv), tv)
	T = rows(X)
	m = cols(Z)
	// the m test variables are placed last so that R = (0, I_m) selects them
	W = X, J(T, 1, 1), Z
	kk = cols(W)
	WW = quadcross(W, W)
	iWW = invsym(WW)
	th = iWW * quadcross(W, y)
	e = y - W * th
	Mid = quadcross(W, (e:^2) :* W)
	for (tau = 1; tau <= j; tau++) {
		if (tau < T) {
			b = T - tau
			E1 = e[(tau + 1)..T] :* e[1..b]
			W1 = W[(tau + 1)..T, .]
			W2 = E1 :* W[1..b, .]
			G = quadcross(W1, W2)
			Mid = Mid + G + G'
		}
	}
	Vv = iWW * Mid * iWW
	Vaa = makesymmetric(Vv[(kk - m + 1)..kk, (kk - m + 1)..kk])
	aa = th[(kk - m + 1)..kk]
	symeigensystem(Vaa, P, Lr)
	tolr = 1e-10 * max(abs(Lr))
	if (tolr <= 0) {
		tolr = 1e-20
	}
	keep = selectindex(Lr :> tolr)
	rk = cols(keep)
	npd = 0
	if (rk < m) {
		npd = 1
	}
	if (rk < 1) {
		st_matrix(outnm, (., 0, 1))
		return
	}
	Pk = P[., keep]
	Lk = Lr[keep]'
	Gi = Pk * diag(1 :/ Lk) * Pk'
	stat = aa' * Gi * aa
	st_matrix(outnm, (stat, rk, npd))
}

// ---------------------------------------------------------------------------
// White & Domowitz (1984) eq.(4.2): for each lag tau, regress e_t e_{t-tau}
// on the distinct elements of the outer product x_t x'_{t-tau} (the gradient
// of a linear f is x_t) and form (n - tau) * R2_0, the constant-UNADJUSTED
// R-squared, which is asymptotically chi2(k_tau).  Returns one row per lag:
// (tau, stat, df, p).
// ---------------------------------------------------------------------------
void mpa_wdtrunc(string scalar yv, string scalar xv, string scalar tv,
                 real scalar maxl, string scalar outnm)
{
	real matrix X, XS, R, PSI, PP, iPP
	real colvector y, b, e, d, fit, bb
	real rowvector Lr
	real scalar T, k, tau, i, jj, n, den, rss, r2, df, c, nc
	y = st_data(., tokens(yv), tv)
	X = st_data(., tokens(xv), tv)
	T = rows(X)
	XS = X, J(T, 1, 1)
	k = cols(XS)
	b = invsym(quadcross(XS, XS)) * quadcross(XS, y)
	e = y - XS * b
	R = J(maxl, 4, .)
	for (tau = 1; tau <= maxl; tau++) {
		R[tau, 1] = tau
		n = T - tau
		if (n > k * k + 5) {
			d = e[(tau + 1)..T] :* e[1..n]
			PSI = J(n, k * k, 0)
			c = 0
			for (i = 1; i <= k; i++) {
				for (jj = 1; jj <= k; jj++) {
					c = c + 1
					PSI[., c] = XS[(tau + 1)..T, i] :* XS[1..n, jj]
				}
			}
			PP = quadcross(PSI, PSI)
			Lr = symeigenvalues(makesymmetric(PP))
			nc = 0
			if (cols(Lr) > 0) {
				nc = cols(selectindex(Lr :> 1e-10 * max(abs(Lr))))
			}
			iPP = invsym(PP)
			bb = iPP * quadcross(PSI, d)
			fit = PSI * bb
			rss = quadcross(d - fit, d - fit)
			den = quadcross(d, d)
			if (den > 0 & nc > 0) {
				r2 = 1 - rss / den
				if (r2 < 0) {
					r2 = 0
				}
				df = nc
				R[tau, 2] = n * r2
				R[tau, 3] = df
				R[tau, 4] = chi2tail(df, n * r2)
			}
		}
	}
	st_matrix(outnm, R)
	st_matrixcolstripe(outnm, (J(4, 1, ""), ("lag" \ "stat" \ "df" \ "p")))
}

// ---------------------------------------------------------------------------
// Residual autocorrelations with Bartlett standard errors.
// Columns: lag, gamma_hat, Bartlett se, z = gamma_hat/se.
// ---------------------------------------------------------------------------
void mpa_acf(string scalar ev, string scalar tv, real scalar S,
             string scalar outnm)
{
	real colvector e
	real matrix R
	real scalar T, s, num, den, g, cum, se
	e = st_data(., ev, tv)
	e = select(e, e :< .)
	T = rows(e)
	den = quadcross(e, e)
	R = J(S, 4, .)
	cum = 0
	for (s = 1; s <= S; s++) {
		R[s, 1] = s
		if (s < T & den > 0) {
			num = quadcross(e[(s + 1)..T], e[1..(T - s)])
			g = num / den
			se = sqrt((1 + 2 * cum) / T)
			R[s, 2] = g
			R[s, 3] = se
			R[s, 4] = g / se
			cum = cum + g * g
		}
	}
	st_matrix(outnm, R)
	st_matrixcolstripe(outnm, (J(4, 1, ""), ("lag" \ "ac" \ "se" \ "z")))
}

end
