*! Internal analytical ordinary-mode adapter; public inference is composed later.
*! Requires csdid 2.0.2 (MIT license), installed separately.
program define _cdid_ordinary, rclass
    version 19.5
    syntax varlist(numeric fv min=1) [if] [in], TIME(varname numeric) GVAR(varname numeric) ///
        [IVAR(varname numeric) RCS ALLOWUNBALANCED WVAR(varname numeric) ///
        METHOD(string) CONTROLgroup(string) BASEperiod(string) ANTICIPation(integer 0) FIXweights(string)]
    if "`method'" == "" local method "dr"
    if "`controlgroup'" == "" local controlgroup "nevertreated"
    if "`baseperiod'" == "" local baseperiod "varying"
    if !inlist("`method'","dr","reg","ipw") {
        display as error "method() must be dr, reg or ipw in ordinary mode"
        exit 198
    }
    if !inlist("`controlgroup'","nevertreated","notyettreated") {
        display as error "controlgroup() must be nevertreated or notyettreated"
        exit 198
    }
    if !inlist("`baseperiod'","varying","universal") {
        display as error "baseperiod() must be varying or universal"
        exit 198
    }
    if `anticipation'<0 {
        display as error "anticipation() must be a nonnegative integer"
        exit 198
    }
    if !inlist("`fixweights'","","first_period","base_period","varying") {
        display as error "fixweights() must be first_period, base_period or varying in ordinary mode"
        exit 198
    }
    local isrcs = ("`rcs'" != "")
    if !`isrcs' & "`ivar'"=="" {
        display as error "panel data require ivar(); specify rcs for repeated cross-sections"
        exit 198
    }
    if `isrcs' & inlist("`fixweights'","first_period","base_period") {
        display as error "fixweights(first_period) and fixweights(base_period) are not available with repeated cross-sections (rcs)"
        exit 198
    }
    capture mata: mata describe cdid_ordinary_collect()
    if _rc {
        display as error "the Mata library of cdid is not loaded; type mata: mata mlib index"
        exit 499
    }
    capture quietly findfile csdid.ado
    if _rc {
        display as error "ordinary mode requires the csdid package, version 2.0.2; see help cdid for installation"
        exit 499
    }
    local backend_path `"`r(fn)'"'
    tempname header
    file open `header' using `"`backend_path'"', read text
    file read `header' firstline
    file close `header'
    if !regexm(`"`firstline'"',"csdid[ ]+2[.]0[.]2([ ]|$)") {
        display as error "ordinary mode requires csdid version 2.0.2; another version is installed"
        exit 499
    }
    local caller_sort_rng `"`c(sortrngstate)'"'
    tempname held
    tempvar heldsample requested touse sourcerow sample backend_time backend_group normalization_sample
    _estimates hold `held', restore nullok varname(`heldsample')
    preserve
    capture noisily {
    quietly mark `requested' `if' `in'
    quietly generate byte `touse' = `requested'
    quietly generate double `sourcerow' = _n
    local input_N = _N
    quietly count if `requested'
    local requested_N = r(N)
    mata: cdid_ordinary_input_guard("`ivar'","`time'","`gvar'","`requested'")
    // Keep original names/data for identity maps; shift only backend copies.
    quietly generate double `backend_time' = `time'
    quietly generate double `backend_group' = `gvar'
    tempname calendar_shift
    mata: st_numscalar("`calendar_shift'",cdid_ordinary_calendar("`time'","`gvar'","`requested'", ///
        "`backend_time'","`backend_group'",`anticipation'))
    local panelopts "bal(full)"
    local backend_ivar "ivar(`ivar')"
    if "`allowunbalanced'" != "" local panelopts "bal(none)"
    if `isrcs' {
        * did validates an optional ID, then replaces it by observation IDs.
        * Do not inherit csdid's stricter global-uniqueness rule for RCS ivar.
        if "`ivar'" != "" quietly markout `touse' `ivar'
        local backend_ivar ""
        local panelopts "rcs bal(none)"
    }
    // Source faster-mode normalizes after finite required/design rows and before
    // cohort/control/support and panel-balance settling. Zero weights stay valid.
    quietly generate byte `normalization_sample' = `touse'
    quietly fvrevar `varlist'
    local normalization_design "`r(varlist)'"
    quietly markout `normalization_sample' `normalization_design' `time' `gvar' `ivar' `wvar'
    local normalization_mean = 1
    if "`wvar'"!="" {
        quietly summarize `wvar' if `normalization_sample', meanonly
        local normalization_mean = r(mean)
    }
    local weightopt ""
    if "`wvar'" != "" local weightopt "[iw=`wvar']"
    local fixedopt ""
    if "`fixweights'" != "" local fixedopt "fix_weights(`fixweights')"
    * csdid prints its warnings in the error style, which -quietly- does not
    * suppress; its options (bal()) are not those of cdid. Run it under
    * -capture- and rerun it visibly only to report a failure.
    local csdid_call `"csdid `varlist' if `touse' `weightopt', time(`backend_time') gvar(`backend_group') `backend_ivar' `panelopts' `controlgroup' base_period(`baseperiod') method(`method') anticipation(`anticipation') `fixedopt' pscoretrim(.995) analytical pointwise level(95) storeall"'
    capture quietly `csdid_call'
    if _rc {
        local csdid_rc = _rc
        display as error "ordinary-mode estimation, computed by csdid, stopped with the message below"
        display as error "(in csdid's message, bal(none) corresponds to the allowunbalanced option of cdid)"
        capture noisily quietly `csdid_call'
        exit `csdid_rc'
    }
    if "`e(version)'"!="2.0.2" | "`e(cmd)'"!="csdid" | e(bstrap)!=0 | e(cband)!=0 | e(level)!=95 {
        display as error "csdid did not return the expected results; reinstall csdid version 2.0.2"
        exit 498
    }
    local engine_stamp ""
    mata: st_local("engine_stamp",csdid_mlib_version())
    if substr("`engine_stamp'",1,6)!="2.0.2|" {
        display as error "the Mata library of csdid is not version 2.0.2; reinstall csdid version 2.0.2"
        exit 498
    }
    quietly generate byte `sample' = e(sample)
    if "`panelopts'" == "bal(full)" {
        tempvar period_tag unit_tag unit_nobs
        quietly egen byte `period_tag' = tag(`time') if `normalization_sample'
        quietly count if `period_tag' == 1
        local n_periods = r(N)
        quietly egen long `unit_nobs' = total(`normalization_sample'), by(`ivar')
        quietly egen byte `unit_tag' = tag(`ivar') if `normalization_sample'
        quietly count if `unit_tag' == 1 & `unit_nobs' < `n_periods'
        if r(N) > 0 {
            display as text "note: `r(N)' unit(s) not observed in every period were dropped;" ///
                " specify allowunbalanced to keep them"
        }
    }
    tempname cells inf V Va units mapping groups used excluded source_units source_calendar
    mata: cdid_ordinary_collect("`ivar'",`isrcs',st_numscalar("`calendar_shift'"),"`sourcerow'","`requested'","`sample'", ///
        "`cells'","`inf'","`V'","`Va'","`units'","`mapping'","`groups'","`used'","`excluded'")
    mata: cdid_ord_extraction_metadata("`units'","`used'","`time'",`normalization_mean',"`source_units'","`source_calendar'")
    local units_N = e(N_units)
    local rows_N = e(N)
    local actual_mode "`e(panel_mode)'"
    local actual_path "`e(compute_path)'"
    local d1 = ("`method'"=="dr" & ("`actual_mode'"!="panel" | "`fixweights'"=="varying"))
    }
    local ordinary_rc=_rc
    restore
    _estimates unhold `held'
    quietly set sortrngstate `caller_sort_rng'
    if `ordinary_rc' exit `ordinary_rc'
    matrix colnames `cells' = group time base role available att se event n_treat_t n_treat_pre n_control_t n_control_pre
    matrix colnames `mapping' = unit_id source_row input_id
    return clear
    return matrix cells = `cells'
    return matrix inffunc = `inf'
    return matrix V = `V'
    return matrix V_analytical = `Va'
    return matrix unit_group = `units'
    return matrix unit_index = `mapping'
    return matrix source_units = `source_units'
    return matrix source_calendar = `source_calendar'
    return scalar weight_normalization_mean = `normalization_mean'
    return scalar source_weight_factor = 1/`normalization_mean'
    return local source_weight_law "weights normalized to mean one over nonmissing rows before balancing; panel weights taken from each unit's first period"
    return matrix group_prob = `groups'
    return matrix sample_rows = `used'
    if `requested_N'>`rows_N' return matrix excluded_rows = `excluded'
    return scalar N_input = `input_N'
    return scalar N_requested = `requested_N'
    return scalar N_rows = `rows_N'
    return scalar N_excluded = `requested_N'-`rows_N'
    return scalar N_not_requested = `input_N'-`requested_N'
    return scalar N = `units_N'
    return scalar D1_exception = `d1'
    return scalar bstrap = 0
    return scalar cband = 0
    return scalar level = 95
    return scalar anticipation = `anticipation'
    return scalar rcs_requested = `isrcs'
    return scalar allow_unbalanced_requested = ("`allowunbalanced'"!="")
    return scalar calendar_shift = scalar(`calendar_shift')
    return scalar pscoretrim = .995
    return scalar pscore_cap = 1-1e-6
    return local backend "csdid"
    return local backend_version "2.0.2"
    return local backend_path `"`backend_path'"'
    return local engine_stamp "`engine_stamp'"
    return local method "`method'"
    return local control_group "`controlgroup'"
    return local base_period "`baseperiod'"
    return local fix_weights "`fixweights'"
    return local panel_mode "`actual_mode'"
    return local compute_path "`actual_path'"
    return local share_metadata "unit weights and cohort shares for ordinary aggregation"
    return local covariance_scale "V_analytical=N*V; ordinary retained-unit IF denominator"
    return local inference "analytical pointwise inference"
end
