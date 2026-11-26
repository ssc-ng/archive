*! version 1.0.0  23nov2026  Rodrigo Taborda

program define bj
	version 18

	syntax varlist(min=1 numeric ts) [if] [in] [, ///
		LAGs(numlist integer max=1 >0)            /// lags for ac and pac
		LEVel(cilevel)                            /// confidence level
		ID                                        /// identification only
		ORDer(numlist integer min=2 max=2 >=0)    /// ARMA(p,q) to estimate
		ARIMA(string asis)                        /// full arima specification
		HORizon(numlist integer max=1 >0)         /// forecast periods
		noLABel                                   /// subtitle: name, not label
		noINFO                                    /// no information panels
		noTESTs                                   /// no unit root / ARMA panel
		INFOtext(string asis)                     /// extra lines in the panel
		DFLags(integer 0)                         /// lags in dfuller
		SOCopts(string asis)                      /// options for arimasoc
		EXPort(string asis)                       /// export figures (pdf)
		TItle(string asis)                        /// combined graphs
		SUBtitle(string asis)                     /// identification output
		ESTSUBtitle(string asis)                  /// estimation output
		NOTE(string asis)                         ///
		CAPtion(string asis)                      ///
		TSOPTs(string asis)                       /// options for tsline
		ACOPTs(string asis)                       /// options for ac
		PACOPTs(string asis)                      /// options for pac
		COMBOPTs(string asis)                     /// options for graph combine
		NAME(string asis)                         ///
		SAVing(string asis)                       ///
		]
	* note: "optionally off" options are declared with a LOWERCASE "no"
	* (noLABel, noINFO, noTESTs); syntax then stores the result in the local
	* WITHOUT "no": nolabel -> `label', noinfo -> `info', notests -> `tests'.
	* Declared with an uppercase N (NOINFO), they would be ordinary options
	* stored in `noinfo', and `info' would always be empty

	* ---- time-series structure --------------------------------------------
	quietly tsset                     // error 111 if data are not tsset
	local timevar `r(timevar)'
	local tsfmt   `r(tsfmt)'
	local unit    `r(unit)'
	local tdelta = r(tdelta)

	* ---- dependent and independent variables ------------------------------
	* bj depvar [indepvars]: the identification output analyzes depvar only;
	* indepvars enter the estimation (ARIMAX) in stage 2
	gettoken depvar indepvars : varlist
	local varlist `depvar'

	* ---- sample -----------------------------------------------------------
	* identification sample: depvar nonmissing (covariates checked later)
	marksample touse, novarlist
	markout `touse' `depvar'
	quietly count if `touse'
	if r(N) == 0 error 2000

	* effective start and end dates of the estimation sample
	quietly summarize `timevar' if `touse', meanonly
	local tstart = strtrim(string(r(min), "`tsfmt'"))
	local tend   = strtrim(string(r(max), "`tsfmt'"))

	* ---- variable label for the default subtitles ------------------------
	* strip time-series operators: D.y -> y ; DS12.y -> y
	local basevar = substr("`varlist'", strrpos("`varlist'", ".") + 1, .)
	local varlab : variable label `basevar'
	* double quotes inside a label would break the subtitle: use ' instead
	local varlab : subinstr local varlab `"""' "'", all

	* ---- descriptive statistics of the series (effective sample) ---------
	* summarize accepts time-series operators: statistics of D.y if D.y
	local vfmt : format `basevar'
	quietly summarize `varlist' if `touse'
	local nobs   = r(N)
	local s_n    = strtrim(string(r(N),    "%12.0fc"))
	local s_mean = strtrim(string(r(mean), "`vfmt'"))
	local s_sd   = strtrim(string(r(sd),   "`vfmt'"))
	local s_min  = strtrim(string(r(min),  "`vfmt'"))
	local s_max  = strtrim(string(r(max),  "`vfmt'"))

	if "`label'" != "" | `"`varlab'"' == "" {
		local varlab `varlist'                    // no label: D.y
	}
	else if "`basevar'" != "`varlist'" {
		local varlab `"`varlab' (`varlist')"'     // label + operator
	}

	* ---- build option strings ---------------------------------------------
	if "`lags'" != "" local lagsopt lags(`lags')

	* same title in both outputs; subtitle names the stage
	if `"`title'"'    == "" local title    `""Box - Jenkins modelling strategy""'
	* subtitle in two lines: stage on the first line, variable on the second
	if `"`subtitle'"' == "" local subtitle `""Identification" "`varlab'""'
	if `"`estsubtitle'"' == "" {
		local estsubtitle `""Estimation, diagnosis and forecast" "`varlab'""'
	}
	* the whole option is built at once, as with subtitle(): a local
	* defined as "a" "b" would lose its outer quotes
	local subopt    subtitle(`subtitle')
	local estsubopt subtitle(`estsubtitle')
	if `"`note'"'     != "" local noteopt note(`note')
	if `"`caption'"'  != "" local capopt  caption(`caption')

	* default name of the identification output: bj_id
	if `"`name'"' == "" {
		local gname bj_id
		local name `gname', replace
	}
	else {
		_parse comma gname rest : name            // "mygraph, replace"
		local gname `gname'                       // -> mygraph
	}
	local nameopt name(`name')
	if `"`saving'"' != "" local savopt saving(`saving')

	* ---- export: file names and options -------------------------------------
	* export("folder/file", replace) ; no extension -> .pdf
	* identification -> file.pdf ; estimation -> file_est.pdf
	if `"`export'"' != "" {
		_parse comma expfile expopts : export
		local expfile `expfile'                   // removes outer quotes
		gettoken comma expopts : expopts, parse(",")
		if !regexm(`"`expfile'"', "\.[A-Za-z]+$") {
			local expfile `"`expfile'.pdf"'
		}
		if regexm(`"`expfile'"', "^(.*)(\.[A-Za-z]+)$") {
			local expfile_est = regexs(1) + "_est" + regexs(2)
		}
	}

	* ---- ARMA search for arimasoc -----------------------------------------
	* maximum AR and MA orders by frequency (tsset unit): 0.5 x the
	* seasonal period s, rounded up; unless the user sets maxar() /
	* maxma() in socopts(); other units keep the arimasoc default (2)
	*   daily s=7 -> 4 ; weekly s=52 -> 26, capped at 8 ;
	*   monthly s=12 -> 6 ; quarterly s=4 -> 2 ; halfyearly s=2 -> 1 ;
	*   yearly s=1 -> 1
	if      "`unit'" == "daily"      local armaxdef 4
	else if "`unit'" == "weekly"     local armaxdef 8
	else if "`unit'" == "monthly"    local armaxdef 6
	else if "`unit'" == "quarterly"  local armaxdef 2
	else if "`unit'" == "halfyearly" local armaxdef 1
	else if "`unit'" == "yearly"     local armaxdef 1
	else                             local armaxdef 2
	local socall `socopts'
	if !strpos(`"`socopts'"', "maxar") local socall `socall' maxar(`armaxdef')
	if !strpos(`"`socopts'"', "maxma") local socall `socall' maxma(`armaxdef')

	* ---- information panels: contents ---------------------------------------
	* panel 1 (below the ACF): description of the data
	local info1_title `""Data description""'
	local info1_labels `""Start" "End" "Frequency" "Observations" "Mean" "Std. dev." "Min" "Max""'
	local info1_values `""`tstart'" "`tend'" "`unit'" "`s_n'" "`s_mean'" "`s_sd'" "`s_min'" "`s_max'""'

	* panel 2 (below the PACF): unit root tests and ARMA model selection
	* computed only when the information row is shown and notests is not
	* specified
	if "`info'" == "" & "`tests'" == "" {

		* Dickey-Fuller test, three deterministic specifications
		*   none     : no constant, no trend       (dfuller, noconstant)
		*   constant : constant                    (dfuller)
		*   trend    : constant and linear trend   (dfuller, trend)
		* value shown: Z(t) and the 5% critical value; H0: unit root
		local dfopts   `""noconstant" "" "trend""'
		local dfvalues
		forvalues j = 1/3 {
			local dfopt : word `j' of `dfopts'
			capture quietly dfuller `varlist' if `touse', `dfopt' lags(`dflags')
			if _rc == 0 {
				local zt = strtrim(string(r(Zt), "%9.2f"))
				if r(cv_5) < . {
					local cv = strtrim(string(r(cv_5), "%9.2f"))
					local dfvalues `"`dfvalues' "`zt' (cv `cv')""'
				}
				else if r(p) < . {
					local pv = strtrim(string(r(p), "%9.3f"))
					local dfvalues `"`dfvalues' "`zt' (p `pv')""'
				}
				else {
					local dfvalues `"`dfvalues' "`zt'""'
				}
			}
			else {
				local dfvalues `"`dfvalues' "n/a""'
			}
		}

		* ARMA(p,q) selection with arimasoc (Stata 18): selected model by
		* AIC, BIC and HQIC, and the value of each criterion for that model
		local armavalues `""n/a" "n/a" "n/a" "n/a""'
		capture quietly arimasoc `varlist' `indepvars' if `touse', `socall'
		if _rc == 0 {
			local armax = r(ar_max)
			local mamax = r(ma_max)
			local sel_aic  `r(aic_sel)'
			local sel_bic  `r(bic_sel)'
			local sel_hqic `r(hqic_sel)'
			tempname soc
			matrix `soc' = r(table)

			* the selected model has the minimum of each criterion
			local armavalues `""max AR `armax', MA `mamax'""'
			foreach ic in aic bic hqic {
				local icname = upper("`ic'")
				local col = colnumb(`soc', "`icname'")
				local best = .
				if `col' < . {
					forvalues i = 1/`=rowsof(`soc')' {
						local best = min(`best', `soc'[`i', `col'])
					}
				}
				if `best' < . {
					local bestfmt = strtrim(string(`best', "%12.1fc"))
					local armavalues `"`armavalues' "`sel_`ic''  `bestfmt'""'
				}
				else {
					local armavalues `"`armavalues' "`sel_`ic''""'
				}
			}
		}

		local info2_title  `""Unit root and ARMA selection""'
		local info2_labels `""DF none" "DF constant" "DF trend" "DF lags" "ARMA search" "AIC" "BIC" "HQIC""'
		local info2_values `"`dfvalues' "`dflags'" `armavalues'"'
		local info2_header `""DF: Z(t) (5% critical value); H0: unit root""'
	}

	* ---- figure size: letter proportion (8.5 x 11) ------------------------
	* three rows of equal height: series | AC PAC | panels
	* noinfo: two rows, 8.5 x 7.33 (same row height, 11 / 3 x 2)
	* placed before `combopts' so that the user can override it
	* (fysize() on the combined rows was tried and shrank the series row)
	if "`info'" == "" local sizeopt xsize(8.5) ysize(11)
	else              local sizeopt xsize(8.5) ysize(7.33)

	* =======================================================================
	* STAGE 1: identification -> output bj_id
	* =======================================================================
	* iscale(1) in the inner combines: text is not shrunk twice, so the
	* series, ACF and PACF keep the same relative text size; only the final
	* combine scales the text, equally for all rows
	tempname g_ts g_ac g_pac g_acpac g_info1 g_info2 g_inforow

	capture noisily {
		* default color navy (RGB 26 71 111); user options come after
		tsline `varlist' if `touse', nodraw                   ///
			xtitle("") lcolor(navy)                 ///
			`tsopts' name(`g_ts')

		* default titles AC / PAC, no y-axis title, navy spikes and very small
		* markers; placed before `acopts' / `pacopts' so that the user can
		* override them
		local acpacstyle lcolor(navy) mcolor(navy) msize(vsmall)

		ac `varlist' if `touse', nodraw                       ///
			`lagsopt' level(`level')                          ///
			title("AC") ytitle("") `acpacstyle'     ///
			`acopts' name(`g_ac')

		pac `varlist' if `touse', nodraw                      ///
			`lagsopt' level(`level')                          ///
			title("PAC") ytitle("") `acpacstyle'    ///
			`pacopts' name(`g_pac')

		* step 1: AC and PAC side by side
		graph combine `g_ac' `g_pac', rows(1) iscale(1)       ///
			nodraw name(`g_acpac')

		* information row: panel 1 below the ACF, panel 2 below the PACF
		if "`info'" == "" {
			_bj_textpanel, name(`g_info1') title(`info1_title')   ///
				labels(`info1_labels') values(`info1_values')     ///
				note(`infotext')

			if "`tests'" == "" {
				_bj_textpanel, name(`g_info2') title(`info2_title')   ///
					labels(`info2_labels') values(`info2_values')     ///
					header(`info2_header') valuex(0.45)
			}
			else {
				* notests: empty cell, so that panel 1 keeps the ACF width
				twoway scatteri 0 0, msymbol(none)                    ///
					xscale(off) yscale(off)                           ///
					xlabel(none, nogrid) ylabel(none, nogrid)         ///
					legend(off) plotregion(style(none))               ///
					graphregion(color(white))                         ///
					nodraw name(`g_info2')
			}

			* step 2: the two text panels side by side
			graph combine `g_info1' `g_info2', rows(1) iscale(1)  ///
				nodraw name(`g_inforow')
			local inforow `g_inforow'
		}

		* step 3: series on top, AC|PAC in the middle, panels at the bottom,
		* in ONE combine so that the three rows get the same height
		* iscale(0.5): smaller text in the final figure; before `combopts'
		graph combine `g_ts' `g_acpac' `inforow', cols(1)     ///
			`sizeopt' iscale(0.5)             ///
			title(`title') `subopt' `noteopt'                 ///
			`capopt' `combopts' `nameopt' `savopt'

		if `"`export'"' != "" {
			graph export `"`expfile'"', name(`gname') `expopts'
		}
	}
	local rc = _rc

	* ---- always remove the intermediate graphs ----------------------------
	foreach g in `g_ts' `g_ac' `g_pac' `g_acpac' `g_info1' `g_info2' `g_inforow' {
		capture graph drop `g'
	}
	if `rc' exit `rc'

	* =======================================================================
	* STAGE 2: estimation, diagnostic checking and forecast -> output bj_est
	* skipped with option id
	* =======================================================================
	if "`id'" == "" {

		* ---- estimation sample: depvar and covariates nonmissing ------------
		if "`indepvars'" != "" {
			markout `touse' `indepvars'
			quietly count if `touse'
			if r(N) == 0 error 2000
			local nobs = r(N)
		}

		* ---- model ----------------------------------------------------------
		* arima(): full arima specification given by the user, passed as is
		* order(p q): shortcut for arima(p,0,q)
		* none of them: the ARMA(p,q) selected by BIC in arimasoc
		if `"`arima'"' != "" & "`order'" != "" {
			display as error "bj: specify either arima() or order(), not both"
			exit 198
		}
		if `"`arima'"' != "" {
			local armaspec `arima'
			local modeltxt `"user specification `arima'"'
		}
		else {
			if "`order'" != "" {
				local p : word 1 of `order'
				local q : word 2 of `order'
				local modelsrc "user"
			}
			else {
				if "`sel_bic'" == "" {
					capture quietly arimasoc `varlist' `indepvars' if `touse', `socall'
					if _rc == 0 local sel_bic `r(bic_sel)'
				}
				* r(bic_sel) is a string such as ARMA(1,1)
				if regexm("`sel_bic'", "([0-9]+)[^0-9]+([0-9]+)") {
					local p = regexs(1)
					local q = regexs(2)
					local modelsrc "selected by BIC"
				}
				else {
					display as error "bj: no ARMA model could be selected; specify order(p q) or arima()"
					exit 498
				}
			}
			local armaspec arima(`p',0,`q')
			local modeltxt "ARMA(`p',`q'), `modelsrc'"
		}

		* integrated model: arima(p,d,q) with d > 0, or sarima(P,D,Q,s) with
		* D > 0; fitted values and forecast are then predicted in levels of
		* depvar (predict, y); predict, mse refers to the differenced series,
		* so no forecast band is drawn
		local integ 0
		if ustrregexm(`"`armaspec'"', "(^|[^s])arima\(\s*\d+\s*,\s*(\d+)") {
			if real(ustrregexs(2)) > 0 local integ 1
		}
		if ustrregexm(`"`armaspec'"', "sarima\(\s*\d+\s*,\s*(\d+)") {
			if real(ustrregexs(1)) > 0 local integ 1
		}
		local ytype = cond(`integ', "y", "xb")

		* ---- forecast settings ---------------------------------------------
		* horizon: horizon(#) if given, otherwise 5% of the observations;
		* the forecast panel shows the last h observed periods and the h
		* forecast periods, added with tsappend; dynamic forecast from the
		* first period after the sample
		if "`horizon'" != "" {
			local h `horizon'
			local hsrc "user"
		}
		else {
			local h = max(1, ceil(0.05 * `nobs'))
			local hsrc "5% of obs."
		}
		local z = invnormal(1 - (1 - `level' / 100) / 2)
		local ename bj_est

		* ---- lags for Ljung-Box and McLeod-Li -------------------------------
		* 2 x seasonal period s; yearly 5; other units 10; at most N/4
		if      "`unit'" == "daily"      local lblags 14
		else if "`unit'" == "weekly"     local lblags 104
		else if "`unit'" == "monthly"    local lblags 24
		else if "`unit'" == "quarterly"  local lblags 8
		else if "`unit'" == "halfyearly" local lblags 4
		else if "`unit'" == "yearly"     local lblags 5
		else                             local lblags 10
		local lblags = max(1, min(`lblags', floor(`nobs' / 4)))

		tempname g_fit g_fc g_res g_hist g_diag g_qq g_row1 g_row2 g_row3

		* tsappend adds observations: work on a preserved copy of the data
		preserve
		capture noisily {
			tempvar obs fit res fc fcmse fclo fchi
			quietly generate double `obs' = `varlist' if `touse'

			* covariates: copied into temporary variables, so that their
			* values after the sample can be filled in for the forecast
			* (indepvars may contain time-series operators)
			local xvars
			foreach x of local indepvars {
				tempvar xv
				quietly generate double `xv' = `x'
				local xvars `xvars' `xv'
			}

			quietly arima `varlist' `xvars' if `touse', `armaspec'
			quietly predict double `fit' if `touse', `ytype'
			quietly predict double `res' if `touse', residuals

			* ---- residual diagnostics (before tsappend) ---------------------
			* Ljung-Box on the residuals: H0 white noise
			* value shown: Q (5% critical value, p-value); the critical value
			* is the chi2 quantile with r(df) degrees of freedom:
			* invchi2tail(df, 0.05); H0 is rejected when Q > cv
			local lbtest "n/a"
			capture quietly wntestq `res' if `touse' == 1, lags(`lblags')
			if _rc == 0 {
				local lbtest = strtrim(string(r(stat), "%9.2f")) + " (cv " ///
					+ strtrim(string(invchi2tail(r(df), 0.05), "%9.2f"))    ///
					+ ", p " + strtrim(string(r(p), "%5.3f")) + ")"
			}

			* McLeod-Li: Ljung-Box on the squared residuals; H0 no ARCH
			tempvar res2
			quietly generate double `res2' = `res'^2 if `touse' == 1
			local mltest "n/a"
			capture quietly wntestq `res2' if `touse' == 1, lags(`lblags')
			if _rc == 0 {
				local mltest = strtrim(string(r(stat), "%9.2f")) + " (cv " ///
					+ strtrim(string(invchi2tail(r(df), 0.05), "%9.2f"))    ///
					+ ", p " + strtrim(string(r(p), "%5.3f")) + ")"
			}

			* mean, standard deviation, skewness and kurtosis
			quietly summarize `res' if `touse' == 1, detail
			local r_mean = strtrim(string(r(mean),     "%9.3g"))
			local r_sd   = strtrim(string(r(sd),       "%9.3g"))
			local r_skew = strtrim(string(r(skewness), "%5.2f"))
			local r_kurt = strtrim(string(r(kurtosis), "%5.2f"))

			* Jarque-Bera: JB = n/6 * (S^2 + (K - 3)^2 / 4) ~ chi2(2);
			* H0 normality; computed from summarize, detail (S skewness,
			* K kurtosis); value shown: JB (5% critical value, p-value)
			local jbstat = r(N) / 6 * (r(skewness)^2 + (r(kurtosis) - 3)^2 / 4)
			local jbtest = strtrim(string(`jbstat', "%9.2f")) + " (cv "        ///
				+ strtrim(string(invchi2tail(2, 0.05), "%9.2f"))               ///
				+ ", p " + strtrim(string(chi2tail(2, `jbstat'), "%5.3f")) + ")"

			local diag_title  `""Residual diagnostics""'
			local diag_header `""Q (5% cv, p); H0: white noise (Ljung-Box), no ARCH (McLeod-Li)""'
			local diag_note   `""McLeod-Li: Ljung-Box test on the squared residuals." "Jarque-Bera: H0 normality, from skewness and kurtosis; chi2(2).""'
			local diag_labels `""Mean" "Std. dev." "Ljung-Box Q(`lblags')" "McLeod-Li Q(`lblags')" "Skewness (normal 0)" "Kurtosis (normal 3)" "Jarque-Bera""'
			local diag_values `""`r_mean'" "`r_sd'" "`lbtest'" "`mltest'" "`r_skew'" "`r_kurt'" "`jbtest'""'

			quietly summarize `timevar' if `touse', meanonly
			local tlast  = r(max)                     // last observed period
			local tfc    = `tlast' + `tdelta'         // first forecast period
			local tfend  = `tlast' + `h' * `tdelta'   // last forecast period
			local twin   = `tlast' - `h' * `tdelta'   // window: t > twin

			* forecast periods: h periods after the sample, added with
			* tsappend when they are not already in memory. Covariates: the
			* values after the sample supplied by the user are kept; missing
			* values are held at the last value in the sample
			local hx = `h'
			quietly summarize `timevar', meanonly
			if r(max) < `tfend' {
				quietly tsappend, add(`=round((`tfend' - r(max)) / `tdelta')')
			}
			local xheld 0
			foreach xv of local xvars {
				quietly summarize `xv' if `timevar' == `tlast', meanonly
				local xlast = r(mean)
				quietly count if missing(`xv') & inrange(`timevar', `tfc', `tfend')
				if r(N) > 0 local xheld 1
				quietly replace `xv' = `xlast' if missing(`xv') ///
					& inrange(`timevar', `tfc', `tfend')
			}

			quietly predict double `fc', `ytype' dynamic(`tfc')
			if !`integ' {
				quietly predict double `fcmse', mse dynamic(`tfc')
				quietly generate double `fclo' = `fc' - `z' * sqrt(`fcmse') ///
					if inrange(`timevar', `tfc', `tfend')
				quietly generate double `fchi' = `fc' + `z' * sqrt(`fcmse') ///
					if inrange(`timevar', `tfc', `tfend')
			}

			* covariates in the model line of the note
			local covnote
			if "`indepvars'" != "" local covnote " Covariates: `indepvars'."

			* forecast line of the note
			local xtxt
			if "`indepvars'" != "" {
				if `xheld' local xtxt "; covariates held at their last value"
				else       local xtxt "; covariate values supplied by the user"
			}
			if `integ' {
				local fcnote "Forecast: `hx' periods (`hsrc'), dynamic, in levels`xtxt'; no band (MSE only for the differenced series)."
			}
			else {
				local fcnote "Forecast: `hx' periods (`hsrc'), dynamic, `level'% band`xtxt'."
			}

			* note: observations added by tsappend have `touse' missing,
			* which Stata treats as true; hence `touse' == 1 below

			* row 1, left (65% of the width): observed and fitted; widths 65/35
			* come from fxsize(100) and fxsize(54), since 35 / 65 = 0.54
			twoway (line `obs' `timevar' if `touse' == 1, lcolor(navy))      ///
				(line `fit' `timevar' if `touse' == 1, lcolor(red)),      ///
				title("Observed and fitted") xtitle("") ytitle("")           ///
				legend(order(1 "Observed" 2 "Fitted") rows(1) size(small)    ///
					position(6))                                             ///
				fxsize(100) nodraw name(`g_fit')

			* row 1, right (35%): last h observed periods and the forecast
			* (band only for models without differencing)
			local fcband
			if !`integ' {
				local fcband (rarea `fchi' `fclo' `timevar'              ///
					if inrange(`timevar', `tfc', `tfend'), color(gs13))
			}
			twoway `fcband'                                              ///
				(line `obs' `timevar' if `touse' == 1 & `timevar' > `twin', ///
					lcolor(navy))                                        ///
				(line `fc' `timevar' if inrange(`timevar', `tfc', `tfend'), ///
					lcolor(red)),                                        ///
				title("Forecast") xtitle("") ytitle("") legend(off)      ///
				xline(`tlast', lpattern(dash) lcolor(gs8))               ///
				fxsize(54) nodraw name(`g_fc')

			* row 2, left (65%): residuals over time
			twoway line `res' `timevar' if `touse' == 1, lcolor(navy)        ///
				yline(0, lpattern(dash) lcolor(gs8))                         ///
				title("Residuals") xtitle("") ytitle("")                     ///
				fxsize(100) nodraw name(`g_res')

			* row 2, right (35%): histogram of the residuals, normal density
			histogram `res' if `touse' == 1, normal                          ///
				fcolor(navy) lcolor(white) normopts(lcolor(red))          ///
				title("Residuals distribution") xtitle("") ytitle("")        ///
				fxsize(54) nodraw name(`g_hist')

			* row 3, left (65%): table of residual diagnostics
			_bj_textpanel, name(`g_diag') title(`diag_title')               ///
				labels(`diag_labels') values(`diag_values')                 ///
				header(`diag_header') note(`diag_note')                      ///
				valuex(0.45) gopts(fxsize(100))

			* row 3, right (35%): normal Q-Q plot of the residuals
			qnorm `res' if `touse' == 1, mcolor(navy) msize(vsmall)        ///
				rlopts(lcolor(red))                                          ///
				title("Normal Q-Q plot") xtitle("") ytitle("")               ///
				fxsize(54) nodraw name(`g_qq')

			graph combine `g_fit' `g_fc', rows(1) iscale(1)                 ///
				nodraw name(`g_row1')
			graph combine `g_res' `g_hist', rows(1) iscale(1)               ///
				nodraw name(`g_row2')
			graph combine `g_diag' `g_qq', rows(1) iscale(1)                ///
				nodraw name(`g_row3')

			* three rows of equal height: letter proportion, as bj_id
			graph combine `g_row1' `g_row2' `g_row3', cols(1)               ///
				xsize(8.5) ysize(11) iscale(0.5)                            ///
				title(`title') `estsubopt'                                  ///
				note(`"Model: `modeltxt'.`covnote'"' "`fcnote'",              ///
					size(vsmall))                                           ///
				`combopts' name(`ename', replace)

			if `"`export'"' != "" {
				graph export `"`expfile_est'"', name(`ename') `expopts'
			}
		}
		local rc = _rc
		restore

		foreach g in `g_fit' `g_fc' `g_res' `g_hist' `g_diag' `g_qq' `g_row1' `g_row2' `g_row3' {
			capture graph drop `g'
		}
		if `rc' exit `rc'
	}
end


* ===========================================================================
* _bj_textpanel: boxed two-column table (label | value) drawn as a graph
*   name()    graph name
*   title()   panel title, above the box
*   labels()  "label 1" "label 2" ...   (left column)
*   values()  "value 1" "value 2" ...   (right column, same number)
*   note()    optional lines below the box
*   valuex()  horizontal position of the value column (0-1); default 0.55
*   header()  optional first line inside the box, across both columns
*   gopts()   other twoway options, e.g. fxsize()
* ===========================================================================
program define _bj_textpanel
	version 18

	syntax , NAME(name) LABels(string asis) VALues(string asis) ///
		[ TItle(string asis) NOTE(string asis) VALUEX(real 0.55)  ///
		  HEADer(string asis) GOPTs(string asis) ]

	* rows on a 0-1 vertical scale, from top to bottom; with header(),
	* the first slot holds the header and the table starts in slot 2
	local nrows : word count `labels'
	local first = cond(`"`header'"' != "", 1, 0)
	local nslots = `nrows' + `first'
	local labtext
	local valtext
	if `first' {
		local y = 1 - 0.5 / `nslots'
		local labtext `"`y' 0.08 `header'"'
	}
	forvalues i = 1/`nrows' {
		local y = 1 - (`i' + `first' - 0.5) / `nslots'
		local lab : word `i' of `labels'
		local val : word `i' of `values'
		local labtext `"`labtext' `y' 0.08 "`lab'""'
		local valtext `"`valtext' `y' `valuex' "`val'""'
	}

	if `"`title'"' != "" local titleopt title(`title', size(medsmall))
	if `"`note'"'  != "" local noteopt  note(`note', size(small))

	* no axes, no grid lines, white background; the box is the plot region
	* frame: fcolor() only fills (color() would also paint the outline
	* white); lstyle/lpattern force a visible solid navy line
	twoway scatteri 0 0 1 1, msymbol(none)                    ///
		text(`labtext', placement(east) size(medsmall))       ///
		text(`valtext', placement(east) size(medsmall))       ///
		xscale(off range(0 1)) yscale(off range(0 1))         ///
		xlabel(none, nogrid) ylabel(none, nogrid)             ///
		legend(off) `titleopt' `noteopt'                      ///
		plotregion(fcolor(white) lstyle(foreground)           ///
			lpattern(solid) lcolor(navy) lwidth(medthin)      ///
			margin(zero))                                     ///
		graphregion(color(white)) `gopts'                     ///
		nodraw name(`name')
end
