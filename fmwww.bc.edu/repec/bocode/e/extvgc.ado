*! extvgc 1.0.0  25nov2026
*! Extreme time-varying Granger-causality test (EX-TVGC)
*! Hong, Guo & Zhao (2025), Research in International Business and Finance 77, 102994
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! GitHub: https://github.com/merwanroudane
*!
*! Step -> equation map (full map in: help extvgc methods)
*!   shocks eps = D.x (or the variables themselves, -differenced-) ... Eq.(1)
*!   common thresholds q = max_k Q_k(theta2), q_v = min_k Q_k(theta1) Eq.(2)
*!     (threshold(zero): q = q_v = 0, Hatemi-J 2012 split = AS-TVGC of Hong et al. 2022)
*!   extreme +, extreme -, normal shocks ........................ Eqs.(3)-(5)
*!   cumulative components ......................................... Eqs.(6)-(7)
*!   LA-VAR(p+d) with constant and trend .......................... Eqs.(8)-(9),(13)
*!   lag order p by HJC (or AIC/SBC/HQC) .............................. Eq.(12)
*!   Wald exW = (R phi)'[R(Sigma (x) (U'QU)^-1)R']^-1 (R phi), Sigma=e'e/T Eq.(18)
*!   forward / rolling / recursive-evolving sup statistic SEW_t ...... Eq.(19)
*!   restricted-VAR residual bootstrap, max over control window ..... Eqs.(20)-(22)

program define extvgc, rclass
    version 14.0
    syntax varlist(min=2 max=2 numeric ts) [if] [in] [,           ///
        THeta(real 0.1)          THReshold(string)                  ///
        DIFFerenced              NOCUMulate                         ///
        CAUSEshocks(string)      DEPshocks(string)   noOVERall      ///
        WINdow(integer 0)        CONTrol(integer 12)                ///
        ALGorithm(string)        D(integer 1)        noTRend        ///
        Lags(integer 0)          MAXLag(integer 8)   IC(string)     ///
        LAGMode(string)                                             ///
        REPs(integer 499)        SEED(integer 12345) RESample(string) ///
        Level(integer 95)        MINDur(integer 1)                  ///
        DESCriptive              DIAGnostics         noEPISodes     ///
        noGRaph                  GENerate(name)      SAVing(string) ///
        ]

    // ------------------------------------------------------------ checks
    qui tsset
    local tvar "`r(timevar)'"
    local tfmt "`r(tsfmt)'"
    if "`tvar'" == "" {
        di as err "data must be {cmd:tsset}"
        exit 459
    }
    if "`r(panelvar)'" != "" {
        di as err "extvgc is for a single time series; data are panel-tsset"
        exit 459
    }
    marksample touse
    qui count if `touse'
    local T = r(N)
    qui tsreport if `touse'
    if r(N_gaps) > 0 {
        di as err "the estimation sample has gaps in `tvar'; extvgc needs consecutive observations"
        exit 459
    }
    if `theta' <= 0 | `theta' >= 0.5 {
        di as err "theta() must lie in (0, 0.5); theta2 = 1 - theta"
        exit 198
    }
    if !inlist(`level', 90, 95, 99) {
        di as err "level() must be 90, 95 or 99"
        exit 198
    }
    if "`threshold'" == "" local threshold common
    local threshold = lower("`threshold'")
    if !inlist("`threshold'", "common", "own", "zero") {
        di as err "threshold() must be {bf:common}, {bf:own} or {bf:zero}"
        exit 198
    }
    if "`algorithm'" == "" local algorithm recursive
    local algorithm = lower("`algorithm'")
    if substr("recursive", 1, max(3, length("`algorithm'"))) == "`algorithm'" local algorithm recursive
    if substr("forward",   1, max(3, length("`algorithm'"))) == "`algorithm'" local algorithm forward
    if substr("rolling",   1, max(3, length("`algorithm'"))) == "`algorithm'" local algorithm rolling
    if !inlist("`algorithm'", "recursive", "forward", "rolling") {
        di as err "algorithm() must be {bf:recursive}, {bf:forward} or {bf:rolling}"
        exit 198
    }
    local algo = cond("`algorithm'"=="recursive", 1, cond("`algorithm'"=="forward", 2, 3))
    if "`resample'" == "" local resample indep
    local resample = lower("`resample'")
    if !inlist("`resample'", "indep", "joint") {
        di as err "resample() must be {bf:indep} or {bf:joint}"
        exit 198
    }
    if "`lagmode'" == "" local lagmode common
    local lagmode = lower("`lagmode'")
    if !inlist("`lagmode'", "common", "pair") {
        di as err "lagmode() must be {bf:common} or {bf:pair}"
        exit 198
    }
    if "`ic'" == "" local ic hjc
    local ic = lower("`ic'")
    local icnum = 0
    if "`ic'" == "aic"                      local icnum 1
    if inlist("`ic'", "sbc", "bic", "sic")  local icnum 2
    if inlist("`ic'", "hqc", "hq", "hqic")  local icnum 3
    if "`ic'" == "hjc"                      local icnum 4
    if `icnum' == 0 {
        di as err "ic() must be one of aic, sbc (bic), hqc, hjc"
        exit 198
    }
    if `d' < 0 | `lags' < 0 | `maxlag' < 1 | `control' < 1 | `reps' < 0 | `mindur' < 1 {
        di as err "d(), lags(), maxlag(), control(), reps() and mindur() must be non-negative (maxlag, control, mindur >= 1)"
        exit 198
    }

    // shock lists: codes 1 = extreme positive, 2 = extreme negative, 3 = normal
    local zero = ("`threshold'" == "zero")
    if "`causeshocks'" == "" local causeshocks pos neg nor
    if "`depshocks'"   == "" local depshocks   pos neg nor
    // zero threshold: every change is positive or negative, the normal
    // component is empty (Hatemi-J 2012; AS-TVGC of Hong et al. 2022)
    local userc = ("`causeshocks'" != "pos neg nor")
    local userd = ("`depshocks'" != "pos neg nor")
    foreach w in cause dep {
        local codes
        foreach s of local `w'shocks {
            local s = lower("`s'")
            local c = 0
            if inlist("`s'", "pos", "positive", "+", "ext+")  local c 1
            if inlist("`s'", "neg", "negative", "-", "ext-")  local c 2
            if inlist("`s'", "nor", "normal", "#", "norm")    local c 3
            if `c' == 0 {
                di as err "`w'shocks(): unknown shock `s' (use pos neg nor)"
                exit 198
            }
            if `zero' & `c' == 3 {
                if `user`=substr("`w'",1,1)'' {
                    di as err "threshold(zero) has no normal component; `w'shocks() takes pos and/or neg"
                    exit 198
                }
                continue
            }
            local codes `codes' `c'
        }
        local `w'codes : list uniq codes
    }

    tokenize `varlist'
    local depvar  `1'
    local causvar `2'
    local dshort = abbrev("`depvar'", 10)
    local cshort = abbrev("`causvar'", 10)

    // pair list: overall first (Fig. 2), then cause x dep (Fig. 3 order)
    local pairspec
    local npairs 0
    if "`overall'" != "nooverall" {
        local pairspec 0 0
        local ++npairs
    }
    foreach c of local causecodes {
        foreach dd of local depcodes {
            local pairspec `pairspec' `c' `dd'
            local ++npairs
        }
    }

    // ------------------------------------------------------------ data
    tempname Y TV
    qui mkmat `depvar' `causvar' if `touse', matrix(`Y')
    qui mkmat `tvar' if `touse', matrix(`TV')

    local diffl = ("`differenced'" != "")
    local cuml  = ("`nocumulate'" == "")
    local trnd  = ("`trend'" != "notrend")
    local joint = ("`resample'" == "joint")
    local common = cond("`threshold'" == "zero", 2, ("`threshold'" == "common"))
    local lagpair = ("`lagmode'" == "pair")

    // ------------------------------------------------------------ engine
    mata: _extvgc_run("`Y'", `diffl', `cuml', `theta', `common', `d', `trnd', ///
        `window', `control', `algo', `reps', `seed', `joint', `lags', `maxlag', ///
        `icnum', `lagpair', "`pairspec'")
    // Mata leaves: _xv_S (T x npairs SEW by observation), _xv_sum (npairs x 9),
    // _xv_thr (2 x 2 thresholds), _xv_E (T x 2 shocks by observation),
    // _xv_ic (4 x 1 lag chosen by AIC SBC HQC HJC on the overall system),
    // scalars _xv_tau0, _xv_Teps
    tempname S SUM THR EPS ICT
    matrix `S'   = _xv_S
    matrix `SUM' = _xv_sum
    matrix `THR' = _xv_thr
    matrix `EPS' = _xv_E
    matrix `ICT' = _xv_ic
    local tau0 = scalar(_xv_tau0)
    local Teps = scalar(_xv_Teps)
    capture matrix drop _xv_S _xv_sum _xv_thr _xv_E _xv_ic
    capture scalar drop _xv_tau0 _xv_Teps

    // labels per pair
    local cvcol = cond(`level'==90, 5, cond(`level'==95, 6, 7))
    forvalues j = 1/`npairs' {
        local c  : word `=2*`j'-1' of `pairspec'
        local dd : word `=2*`j''   of `pairspec'
        _extvgc_lab `c' `zero'
        local cl "`r(lab)'"
        local cs "`r(sup)'"
        _extvgc_lab `dd' `zero'
        local dl "`r(lab)'"
        local ds "`r(sup)'"
        if `c' == 0 {
            local lab_`j' "Overall"
            local tok_`j' "all"
            local gt_`j' `"{it:`causvar'} {&rarr} {it:`depvar'}  (overall)"'
        }
        else {
            local lab_`j' "`cl' => `dl'"
            local tok_`j' = substr("pnz", `c', 1) + substr("pnz", `dd', 1)
            local gt_`j' `"{it:`causvar'}{sup:`cs'} {&rarr} {it:`depvar'}{sup:`ds'}"'
        }
    }

    // ------------------------------------------------------------ tables
    local alglab = proper("`algorithm'") + cond(`algo'==1, " evolving", cond(`algo'==2, " expanding", " window"))
    di
    di as txt "{hline 78}"
    di as txt "{bf:Extreme time-varying Granger-causality test (EX-TVGC)}"
    di as txt "Hong, Guo & Zhao (2025), {it:Res. Int. Bus. Finance} 77, 102994"
    di as txt "{hline 78}"
    di as txt " H0: " as res "`causvar'" as txt " (shock) does not Granger-cause " as res "`depvar'" as txt " (shock)"
    if `common' == 2 di as txt " Pair = shock of {it:`causvar'} => shock of {it:`depvar'};  Pos / Neg = positive / negative changes"
    else di as txt " Pair = shock of {it:`causvar'} => shock of {it:`depvar'};  Ext+ / Ext- = extreme, Normal = q_v <= e <= q"
    di as txt "{hline 78}"
    di as txt " Shocks e:            " as res cond(`diffl', "variables as given (differenced)", "first differences of the levels")
    if `common' != 2 di as txt " Quantiles:           " as res "theta1 = " %4.2f `theta' "   theta2 = " %4.2f 1-`theta'
    if `common' == 2 {
        di as txt " Thresholds (zero):   " as res "q = q_v = 0  (all positive vs all negative changes; Hatemi-J 2012)"
    }
    else if `common' == 1 {
        di as txt " Thresholds (common): " as res "q = " %9.4f `THR'[1,1] as txt "   q_v = " as res %9.4f `THR'[2,1]
    }
    else {
        di as txt " Thresholds (own):    " as res "`dshort': [" %8.4f `THR'[2,1] ", " %8.4f `THR'[1,1] "]   `cshort': [" %8.4f `THR'[2,2] ", " %8.4f `THR'[1,2] "]"
    }
    di as txt " Components:          " as res cond(`cuml', "cumulative sums, Eq.(6)", "not cumulated (stationary use)")
    di as txt " LA-VAR:              " as res "p + d,  d = `d',  " cond(`trnd', "constant + trend", "constant")
    if `lags' > 0 {
        di as txt " Lag order p:         " as res "fixed at `lags'"
    }
    else {
        di as txt " Lag order p:         " as res upper("`ic'") " (max `maxlag'), " cond(`lagpair', "selected per pair", "selected on the overall system")
    }
    di as txt " Algorithm:           " as res "`alglab'" as txt "    min. window = " as res "`tau0'" as txt " obs"
    di as txt " Bootstrap:           " as res "`reps'" as txt " reps, control window = " as res "`control'" as txt " obs, resampling = " as res "`resample'"
    di as txt " Sample:              " as res "`T'" as txt " obs (`Teps' shocks)"

    di
    di as txt "{hline 78}"
    di as txt _col(2) "{ralign 16:Pair}" _col(20) "{ralign 3:p}" _col(25) "{ralign 9:max SEW}" ///
        _col(35) "{ralign 10:at}" _col(46) "{ralign 8:CV 90%}" _col(55) "{ralign 8:CV 95%}" ///
        _col(64) "{ralign 8:CV 99%}" _col(73) "{ralign 5:#rej}"
    di as txt "{hline 78}"
    forvalues j = 1/`npairs' {
        local pj   = `SUM'[`j', 1]
        local mx   = `SUM'[`j', 3]
        local at   = `SUM'[`j', 4]
        local c90  = `SUM'[`j', 5]
        local c95  = `SUM'[`j', 6]
        local c99  = `SUM'[`j', 7]
        local nrej = 0
        forvalues r = 1/`T' {
            if `S'[`r', `j'] < . & `S'[`r', `j'] > `SUM'[`j', `cvcol'] local ++nrej
        }
        local star ""
        if `mx' > `c90' local star "*"
        if `mx' > `c95' local star "**"
        if `mx' > `c99' local star "***"
        local atlab = "."
        if `at' < . local atlab = string(`TV'[`at', 1], "`tfmt'")
        local nrej_`j' = `nrej'
        di as txt _col(2) "{ralign 16:`lab_`j''}" as res _col(20) %3.0f `pj' _col(25) %9.3f `mx' ///
            _col(35) "{ralign 10:`atlab'}" _col(46) %8.3f `c90' _col(55) %8.3f `c95' ///
            _col(64) %8.3f `c99' _col(73) %5.0f `nrej' " `star'"
    }
    di as txt "{hline 78}"
    di as txt " max SEW: largest SEW_t over the sample; * ** *** max SEW above the 90/95/99% CV."
    di as txt " #rej: number of dates with SEW_t above the `level'% bootstrap CV (Eq. 22)."

    // ---- episodes (dates where H0 is rejected), like the dating in Section 3.3
    tempname EP
    local nep 0
    if "`episodes'" != "noepisodes" {
        di
        di as txt "{bf:Causality episodes} (SEW_t > `level'% CV, at least `mindur' obs)"
        di as txt "{hline 78}"
        di as txt _col(2) "{ralign 16:Pair}" _col(22) "{ralign 12:Start}" _col(36) "{ralign 12:End}" ///
            _col(50) "{ralign 8:Length}" _col(60) "{ralign 10:Peak SEW}"
        di as txt "{hline 78}"
        forvalues j = 1/`npairs' {
            local cv = `SUM'[`j', `cvcol']
            local inrun 0
            local any 0
            forvalues r = 1/`=`T'+1' {
                local on 0
                if `r' <= `T' {
                    if `S'[`r', `j'] < . & `S'[`r', `j'] > `cv' local on 1
                }
                if `on' & !`inrun' {
                    local inrun 1
                    local rs = `r'
                    local pk = `S'[`r', `j']
                }
                else if `on' & `inrun' {
                    if `S'[`r', `j'] > `pk' local pk = `S'[`r', `j']
                }
                else if !`on' & `inrun' {
                    local inrun 0
                    local re = `r' - 1
                    local len = `re' - `rs' + 1
                    if `len' >= `mindur' {
                        local any 1
                        local ++nep
                        matrix `EP' = nullmat(`EP') \ (`j', `TV'[`rs',1], `TV'[`re',1], `len', `pk')
                        di as txt _col(2) "{ralign 16:`lab_`j''}" as res ///
                            _col(22) "{ralign 12:`=string(`TV'[`rs',1], "`tfmt'")'}" ///
                            _col(36) "{ralign 12:`=string(`TV'[`re',1], "`tfmt'")'}" ///
                            _col(50) %8.0f `len' _col(60) %10.3f `pk'
                    }
                }
            }
            if !`any' {
                di as txt _col(2) "{ralign 16:`lab_`j''}" _col(22) "{it:no episode}"
            }
        }
        di as txt "{hline 78}"
    }

    // ---- optional Table 1 / 2 / 3 of the paper
    if "`descriptive'" != "" {
        _extvgc_desc `EPS' "`dshort'" "`cshort'"
    }
    if "`diagnostics'" != "" {
        _extvgc_diag `Y' `diffl' `cuml' `theta' `common' "`pairspec'" `npairs' "`dshort'" "`cshort'" `ICT' `maxlag'
    }

    // ------------------------------------------------------------ generate
    if "`generate'" != "" {
        forvalues j = 1/`npairs' {
            capture confirm new variable `generate'_`tok_`j''
            if _rc {
                di as err "variable `generate'_`tok_`j'' already exists"
                exit 110
            }
        }
        tempvar obsno
        qui gen long `obsno' = sum(`touse') if `touse'
        forvalues j = 1/`npairs' {
            qui gen double `generate'_`tok_`j'' = .
            forvalues r = 1/`T' {
                if `S'[`r', `j'] < . qui replace `generate'_`tok_`j'' = `S'[`r', `j'] if `obsno' == `r'
            }
            label var `generate'_`tok_`j'' "SEW_t: `lab_`j''  (CV`level' = `=string(`SUM'[`j',`cvcol'], "%9.3f")')"
        }
    }

    // ------------------------------------------------------------ graphs
    if "`graph'" != "nograph" {
        local gtitles
        forvalues j = 1/`npairs' {
            local gtitles `"`gtitles' `"`gt_`j''"'"'
        }
        _extvgc_graphs `S' `SUM' `TV' `EPS' `THR' `npairs' `cvcol' `level' "`tfmt'" ///
            "`depvar'" "`causvar'" "`overall'" `"`gtitles'"' `"`saving'"'
    }

    // ------------------------------------------------------------ returns
    local rn
    forvalues j = 1/`npairs' {
        local rn `rn' `tok_`j''
    }
    matrix colnames `SUM' = p tau0 maxSEW obs_max cv90 cv95 cv99 nstat nrej
    forvalues j = 1/`npairs' {
        matrix `SUM'[`j', 9] = `nrej_`j''
    }
    matrix rownames `SUM' = `rn'
    matrix colnames `S'   = `rn'
    matrix rownames `ICT' = AIC SBC HQC HJC
    matrix colnames `THR' = `depvar' `causvar'
    matrix rownames `THR' = upper lower
    if `nep' > 0 {
        matrix colnames `EP' = pair start end length peak
        return matrix episodes = `EP'
    }
    return matrix lagorder   = `ICT'
    return matrix thresholds = `THR'
    return matrix sew        = `S'
    return matrix results    = `SUM'
    return scalar N       = `T'
    return scalar theta   = `theta'
    return scalar window  = `tau0'
    return scalar control = `control'
    return scalar reps    = `reps'
    return scalar d       = `d'
    return scalar level   = `level'
    return local  pairs     "`rn'"
    return local  algorithm "`algorithm'"
    return local  threshold "`threshold'"
    return local  depvar    "`depvar'"
    return local  causvar   "`causvar'"
    return local  cmd       "extvgc"
end


program define _extvgc_lab, rclass
    args c zero
    if "`zero'" == "" local zero 0
    if `c' == 1 {
        return local lab = cond(`zero', "Pos", "Ext+")
        return local sup "+"
    }
    else if `c' == 2 {
        return local lab = cond(`zero', "Neg", "Ext-")
        return local sup "{&minus}"
    }
    else if `c' == 3 {
        return local lab "Normal"
        return local sup "#"
    }
    else {
        return local lab "Level"
        return local sup ""
    }
end


// ---------------------------------------------------------------- Table 1
program define _extvgc_desc
    args E dl cl
    preserve
    qui drop _all
    qui svmat double `E', name(_e)
    qui drop if _e1 >= . | _e2 >= .
    qui gen long _t = _n
    qui tsset _t
    di
    di as txt "{bf:Table 1. Descriptive statistics of the shocks e}"
    di as txt "{hline 50}"
    di as txt _col(2) "{lalign 10:Statistic}" _col(16) "{ralign 15:`dl'}" _col(34) "{ralign 15:`cl'}"
    di as txt "{hline 50}"
    foreach st in max min mean sd skewness kurtosis {
        local lbl = cond("`st'"=="sd", "Std.", proper(substr("`st'", 1, 4)) + ".")
        qui summarize _e1, detail
        local v1 = r(`st')
        qui summarize _e2, detail
        local v2 = r(`st')
        di as txt _col(2) "{lalign 10:`lbl'}" as res _col(16) %15.4f `v1' _col(34) %15.4f `v2'
    }
    // Jarque-Bera
    forvalues k = 1/2 {
        qui summarize _e`k', detail
        local n = r(N)
        local jb`k' = `n'/6 * (r(skewness)^2 + (r(kurtosis)-3)^2/4)
        local jbp`k' = chi2tail(2, `jb`k'')
        local jbs`k' = cond(`jbp`k''<0.01, "***", cond(`jbp`k''<0.05, "**", cond(`jbp`k''<0.10, "*", "")))
        // ADF with constant, lag by AIC up to Schwert's rule
        local pmax = floor(12*(`n'/100)^(0.25))
        local best = .
        local bl 0
        forvalues l = 0/`pmax' {
            local aug
            if `l' > 0 local aug L(1/`l')D._e`k'
            qui regress D._e`k' L._e`k' `aug' if _t > `pmax' + 1
            local aic = -2*e(ll) + 2*e(rank)
            if `aic' < `best' {
                local best = `aic'
                local bl = `l'
            }
        }
        qui dfuller _e`k', lags(`bl')
        local adf`k' = r(Zt)
        local adfp`k' = r(p)
        local adfs`k' = cond(`adfp`k''<0.01, "***", cond(`adfp`k''<0.05, "**", cond(`adfp`k''<0.10, "*", "")))
        // KPSS (level stationarity), Bartlett kernel, l = floor(4(T/100)^(1/4))
        mata: st_local("kp`k'", strofreal(_extvgc_kpss(st_data(., "_e`k'"))))
        local kps`k' = cond(`kp`k''>0.739, "***", cond(`kp`k''>0.463, "**", cond(`kp`k''>0.347, "*", "")))
    }
    di as txt _col(2) "{lalign 10:JB}" as res _col(16) %12.4f `jb1' "{lalign 3:`jbs1'}" _col(34) %12.4f `jb2' "{lalign 3:`jbs2'}"
    di as txt _col(2) "{lalign 10:ADF}" as res _col(16) %12.4f `adf1' "{lalign 3:`adfs1'}" _col(34) %12.4f `adf2' "{lalign 3:`adfs2'}"
    di as txt _col(2) "{lalign 10:KPSS}" as res _col(16) %12.4f `kp1' "{lalign 3:`kps1'}" _col(34) %12.4f `kp2' "{lalign 3:`kps2'}"
    di as txt "{hline 50}"
    di as txt " * ** *** 10/5/1%. JB: normality; ADF (constant, AIC lag): H0 unit root;"
    di as txt " KPSS (level, Bartlett, l = floor(4(T/100)^0.25)): H0 stationarity."
    restore
end


// ---------------------------------------------------------------- Tables 2 and 3
program define _extvgc_diag, rclass
    args Y diffl cuml theta common pairspec npairs dl cl ICT maxlag
    di
    di as txt "{bf:Table 2. Multivariate normality and multivariate ARCH, VAR(1) per pair}"
    di as txt "{hline 70}"
    di as txt _col(2) "{ralign 16:Pair}" _col(22) "{ralign 11:DH chi2(4)}" _col(34) "{ralign 8:p}" ///
        _col(45) "{ralign 11:ARCH chi2(9)}" _col(58) "{ralign 8:p}"
    di as txt "{hline 70}"
    forvalues j = 1/`npairs' {
        local c  : word `=2*`j'-1' of `pairspec'
        local dd : word `=2*`j''   of `pairspec'
        local zz = (`common' == 2)
        _extvgc_lab `c' `zz'
        local cl2 "`r(lab)'"
        _extvgc_lab `dd' `zz'
        local dl2 "`r(lab)'"
        local lab = cond(`c'==0, "Overall", "`cl2' => `dl2'")
        mata: _extvgc_resid1("`Y'", `diffl', `cuml', `theta', `common', `c', `dd')
        // _xv_R : residuals of the VAR(1); _xv_arch: (LM, df, p)
        preserve
        qui drop _all
        qui svmat double _xv_R, name(_r)
        capture qui mvtest normality _r1 _r2, stats(dhansen)
        local dh = .
        local dhp = .
        if !_rc {
            local dh  = r(chi2_dh)
            local dhp = r(p_dh)
        }
        restore
        local lm  = _xv_arch[1,1]
        local lmp = _xv_arch[1,3]
        di as txt _col(2) "{ralign 16:`lab'}" as res _col(22) %11.3f `dh' _col(34) %8.4f `dhp' ///
            _col(45) %11.3f `lm' _col(58) %8.4f `lmp'
        capture matrix drop _xv_R _xv_arch
    }
    di as txt "{hline 70}"
    di as txt " Doornik-Hansen (2008) multivariate normality; multivariate ARCH(1) LM"
    di as txt " (Lutkepohl 2005, Sec. 16.5). Rejections motivate the bootstrap (Hatemi-J 2012)."
    di
    di as txt "{bf:Table 3. Lag order of the overall VAR (max `maxlag')}"
    di as txt "{hline 46}"
    di as txt _col(2) "{ralign 8:AIC}" _col(12) "{ralign 8:SBC}" _col(22) "{ralign 8:HQC}" _col(32) "{ralign 8:HJC}"
    di as txt "{hline 46}"
    di as res _col(2) %8.0f `ICT'[1,1] _col(12) %8.0f `ICT'[2,1] _col(22) %8.0f `ICT'[3,1] _col(32) %8.0f `ICT'[4,1]
    di as txt "{hline 46}"
    di as txt " HJC = (SBC + HQC)/2, Hatemi-J (2003), Eq.(12)."
end


// ---------------------------------------------------------------- graphs
program define _extvgc_graphs
    args S SUM TV EPS THR npairs cvcol level tfmt depvar causvar overall gtitles saving
    preserve
    qui drop _all
    local T = rowsof(`S')
    qui set obs `T'
    qui svmat double `TV', name(_tv)
    rename _tv1 _time
    format _time `tfmt'
    qui svmat double `S', name(_s)
    qui svmat double `EPS', name(_e)

    // ---- Fig. 1 style: shocks with thresholds
    local qu1 = `THR'[1,1]
    local ql1 = `THR'[2,1]
    local qu2 = `THR'[1,2]
    local ql2 = `THR'[2,2]
    local lp "Extreme +"
    local ln "Extreme {&minus}"
    if `qu1' == 0 & `ql1' == 0 & `qu2' == 0 & `ql2' == 0 {
        local lp "Positive"
        local ln "Negative"
    }
    local k 0
    foreach v in `depvar' `causvar' {
        local ++k
        qui gen byte _x`k' = cond(_e`k' > `qu`k'', 1, cond(_e`k' < `ql`k'', 2, 3)) if _e`k' < .
        twoway (spike _e`k' _time if _x`k'==3, lcolor(gs10)) ///
               (spike _e`k' _time if _x`k'==1, lcolor(cranberry)) ///
               (spike _e`k' _time if _x`k'==2, lcolor(navy)) ///
               , yline(`qu`k'', lpattern(dash) lcolor(cranberry)) ///
                 yline(`ql`k'', lpattern(dash) lcolor(navy)) yline(0, lcolor(gs12)) ///
                 legend(order(2 "`lp'" 3 "`ln'" 1 "Normal") rows(1) size(small) position(6) region(lcolor(none))) ///
                 title("{it:`v'}: shocks and thresholds", size(medsmall)) ytitle("") xtitle("") ///
                 graphregion(color(white)) plotregion(lcolor(black)) ///
                 name(_xvsh`k', replace) nodraw
    }
    graph combine _xvsh1 _xvsh2, cols(1) graphregion(color(white)) ///
        title("Extreme, normal shocks (Eqs. 3-5)", size(medium)) name(extvgc_shocks, replace)

    // ---- SEW_t panels with the bootstrap CV and shaded rejection periods
    local glist
    forvalues j = 1/`npairs' {
        local cv  = `SUM'[`j', `cvcol']
        local c90 = `SUM'[`j', 5]
        qui summarize _s`j', meanonly
        local top = max(r(max), `cv') * 1.08
        qui gen double _sh`j' = `top' if _s`j' > `cv' & _s`j' < .
        qui gen double _cv`j' = `cv' if _s`j' < .
        local gt : word `j' of `gtitles'
        local leg legend(off)
        if `j' == 1 & "`overall'" != "nooverall" {
            local leg legend(order(2 "SEW{sub:t}" 3 "`level'% bootstrap CV" 1 "H{sub:0} rejected") rows(1) size(small) position(6) region(lcolor(none)))
        }
        twoway (bar _sh`j' _time, barwidth(1) color(gs13) lwidth(none)) ///
               (line _s`j' _time, lcolor(navy) lwidth(medthin)) ///
               (line _cv`j' _time, lcolor(cranberry) lpattern(dash)) ///
               , `leg' ///
                 title(`"`gt'"', size(medsmall)) ytitle("") xtitle("") ///
                 yscale(range(0 `top')) ylabel(#4, angle(0) labsize(small)) xlabel(#4, labsize(small)) ///
                 graphregion(color(white)) plotregion(lcolor(black)) ///
                 name(_xvg`j', replace) nodraw
        local glist `glist' _xvg`j'
    }
    if "`overall'" != "nooverall" {
        capture graph drop extvgc_overall
        graph rename _xvg1 extvgc_overall
        graph display extvgc_overall
        local glist : subinstr local glist "_xvg1" "", word
    }
    local ng : word count `glist'
    if `ng' > 0 {
        local nc = cond(`ng' >= 9, 3, cond(`ng' >= 4, 2, 1))
        graph combine `glist', cols(`nc') graphregion(color(white)) ///
            title("Extreme time-varying Granger causality: {it:`causvar'} {&rarr} {it:`depvar'}", size(medsmall)) ///
            note("Solid: SEW{sub:t} (sup Wald, Eq. 19); dashed: `level'% bootstrap CV (Eq. 22); shaded: H{sub:0} rejected." ///
                 "Superscripts: + extreme positive, {&minus} extreme negative, # normal shocks. Hong, Guo & Zhao (2025).", size(vsmall)) ///
            imargin(small) name(extvgc_pairs, replace) xsize(9) ysize(7)
        if `"`saving'"' != "" graph save extvgc_pairs `"`saving'"', replace
    }
    restore
end


// ====================================================================== Mata
version 14.0
mata:

// empirical quantile, plotting position (k - 0.5)/n (MATLAB quantile)
real scalar _extvgc_q(real colvector x, real scalar p)
{
    real colvector s
    real scalar n, h, lo

    s = sort(x, 1)
    n = rows(s)
    h = n*p + 0.5
    if (h <= 1) return(s[1])
    if (h >= n) return(s[n])
    lo = floor(h)
    return(s[lo] + (h - lo)*(s[lo+1] - s[lo]))
}

// thresholds: row 1 = upper (extreme +), row 2 = lower (extreme -), Eq.(2)
real matrix _extvgc_thr(real matrix E, real scalar theta, real scalar common)
{
    real matrix Q
    real scalar k

    // common == 2: zero threshold (Hatemi-J 2012 positive / negative split)
    if (common == 2) return(J(2, cols(E), 0))
    Q = J(2, cols(E), .)
    for (k = 1; k <= cols(E); k++) {
        Q[1, k] = _extvgc_q(E[., k], 1 - theta)
        Q[2, k] = _extvgc_q(E[., k], theta)
    }
    if (common == 1) {
        Q[1, .] = J(1, cols(E), max(Q[1, .]))
        Q[2, .] = J(1, cols(E), min(Q[2, .]))
    }
    return(Q)
}

// one component: type 0 = all shocks, 1 = extreme +, 2 = extreme -, 3 = normal
real colvector _extvgc_one(real colvector e, real scalar qu, real scalar ql, ///
                           real scalar type, real scalar cuml)
{
    real colvector keep, c

    keep = J(rows(e), 1, 1)
    if (type == 1) keep = (e :> qu)
    if (type == 2) keep = (e :< ql)
    if (type == 3) keep = (e :>= ql) :* (e :<= qu)
    c = e :* keep
    if (cuml) c = runningsum(c)
    return(c)
}

// pair system: column 1 = depvar component, column 2 = causvar component
real matrix _extvgc_pair(real matrix E, real matrix Q, real scalar cc, ///
                         real scalar dc, real scalar cuml)
{
    return((_extvgc_one(E[., 1], Q[1, 1], Q[2, 1], dc, cuml), ///
            _extvgc_one(E[., 2], Q[1, 2], Q[2, 2], cc, cuml)))
}

real matrix _extvgc_lagmat(real matrix Z, real scalar p)
{
    real scalar N, j
    real matrix L

    N = rows(Z)
    L = J(N - p, 0, .)
    for (j = 1; j <= p; j++) {
        L = L, Z[p+1-j..N-j, .]
    }
    return(L)
}

// lag selection on a fixed sample T - maxlag (Hatemi-J 2003; GAUSS lag_length2)
// ic: 1 AIC, 2 SBC, 3 HQC, 4 HJC.  Intercept only, as in Hatemi-J (2003).
real scalar _extvgc_lagsel(real matrix Z, real scalar maxlag, real scalar ic)
{
    real scalar n, N, Tc, p, best, bestp, val, ldv, sbc, hqc
    real matrix Lm, Y, X, A, R

    n = cols(Z)
    N = rows(Z)
    best = .
    bestp = 1
    if (N - maxlag < 2*n*maxlag + 5) return(1)
    Lm = _extvgc_lagmat(Z, maxlag)
    Y  = Z[maxlag+1..N, .]
    Tc = rows(Y)
    for (p = maxlag; p >= 1; p--) {
        X = J(Tc, 1, 1), Lm[., 1..p*n]
        A = invsym(X'X) * (X'Y)
        R = Y - X*A
        ldv = ln(det((R'R) / Tc))
        sbc = ldv + (1/Tc)*(n*n*p + n)*ln(Tc)
        hqc = ldv + (2/Tc)*(n*n*p + n)*ln(ln(Tc))
        val = .
        if (ic == 1) val = ldv + (2/Tc)*(n*n*p + n)
        if (ic == 2) val = sbc
        if (ic == 3) val = hqc
        if (ic == 4) val = (sbc + hqc)/2
        if (best >= . | val <= best) {
            best = val
            bestp = p
        }
    }
    return(bestp)
}

// LA-VAR design for the depvar equation, Eq.(8), in the numerically stable
// but EQUIVALENT parameterisation
//     Dz1_t = c + a t + g0' z_{t-1} + sum_{j=1}^{m-1} g_j' Dz_{t-j} + u_t ,
// m = p + d.  It spans the same space as [1, t, z_{t-1}, ..., z_{t-m}] and
// has the same residuals; the levels coefficients are
//     b_1 = g0 + g1,  b_j = g_j - g_{j-1} (2 <= j <= m-1),  b_m = -g_{m-1},
// so H0: b_1 = ... = b_p = 0 (cause) is the linear restriction built by
// _extvgc_R.  The Wald statistic is invariant to this nonsingular
// reparameterisation; the gain is conditioning (no near-collinear level lags).
real matrix _extvgc_design(real matrix Z, real scalar p, real scalar d, real scalar trend)
{
    real scalar N, m, j
    real matrix X

    N = rows(Z)
    m = p + d
    X = J(N - m, 1, 1)
    if (trend) X = X, ((m+1::N) :/ N)
    X = X, Z[m..N-1, .]
    for (j = 1; j <= m - 1; j++) {
        X = X, (Z[m+1-j..N-j, .] - Z[m-j..N-j-1, .])
    }
    return((X, Z[m+1..N, 1] - Z[m..N-1, 1]))
}

// restriction matrix R (p x q) for H0: levels coefficients of the cause on
// lags 1..p are zero, expressed in the design's parameterisation
real matrix _extvgc_R(real scalar p, real scalar m, real scalar trend, real scalar q)
{
    real matrix R
    real scalar r, off

    R = J(p, q, 0)
    off = 1 + trend
    for (r = 1; r <= p; r++) {
        if (r == 1) {
            R[1, off + 2] = 1
            if (m >= 2) R[1, off + 4] = R[1, off + 4] + 1
        }
        if (r >= 2) {
            if (r <= m - 1) R[r, off + 2 + 2*r] = 1
            R[r, off + 2 + 2*(r-1)] = R[r, off + 2 + 2*(r-1)] - 1
        }
    }
    return(R)
}

// running cross-products: row t+1 = sum_{s<=t} vec(w_s w_s')'
real matrix _extvgc_cumcp(real matrix W)
{
    real scalar R, k, t
    real matrix CC
    real rowvector w

    R = rows(W)
    k = cols(W)
    CC = J(R + 1, k*k, 0)
    for (t = 1; t <= R; t++) {
        w = W[t, .]
        CC[t+1, .] = CC[t, .] + vec(w'*w)'
    }
    return(CC)
}

// Wald exW on design rows a..b, Eq.(18): Sigma = e'e/T, restriction R b = 0
real scalar _extvgc_w(real matrix CC, real scalar a, real scalar b, ///
                      real scalar k, real matrix Rm)
{
    real matrix M, iXX, V
    real colvector Xy, bb, bR
    real scalar q, ssr, s2

    M   = colshape(CC[b+1, .] - CC[a, .], k)
    q   = k - 1
    iXX = invsym(M[1..q, 1..q])
    Xy  = M[1..q, k]
    bb  = iXX * Xy
    ssr = M[k, k] - Xy' * bb
    s2  = ssr / (b - a + 1)
    if (s2 <= 0) return(.)
    bR  = Rm * bb
    V   = s2 :* (Rm * iXX * Rm')
    return(bR' * invsym(V) * bR)
}

// statistic sequence over end rows tau0..R. algo 1 recursive (sup), 2 forward, 3 rolling
real colvector _extvgc_seq(real matrix CC, real scalar k, real matrix Rm, ///
                           real scalar R, real scalar tau0, real scalar algo)
{
    real scalar nE, e, r2, r1, w, best
    real colvector S

    nE = R - tau0 + 1
    S = J(nE, 1, .)
    for (e = 1; e <= nE; e++) {
        r2 = tau0 + e - 1
        if (algo == 1) {
            best = -1
            for (r1 = 1; r1 <= r2 - tau0 + 1; r1++) {
                w = _extvgc_w(CC, r1, r2, k, Rm)
                if (w < .) {
                    if (w > best) best = w
                }
            }
            if (best >= 0) S[e] = best
        }
        if (algo == 2) S[e] = _extvgc_w(CC, 1, r2, k, Rm)
        if (algo == 3) S[e] = _extvgc_w(CC, r2 - tau0 + 1, r2, k, Rm)
    }
    return(S)
}

// bootstrap critical values (90, 95, 99%), Eqs.(20)-(22)
real rowvector _extvgc_boot(real matrix Z, real scalar p, real scalar d, ///
       real scalar trend, real scalar tau0, real scalar taub, real scalar B, ///
       real scalar algo, real scalar joint)
{
    real scalar N, m, Lb, b, t, j, nres, k
    real matrix L, X, Xr, Y, E, Zb, W, CC, A
    real colvector b1, b2, keep, mx, idx1, idx2, S
    real matrix Rm
    real rowvector zt

    N = rows(Z)
    m = p + d
    // restricted VAR(p) with intercept: depvar equation excludes causvar lags
    L = _extvgc_lagmat(Z, p)
    X = J(N - p, 1, 1), L
    Y = Z[p+1..N, .]
    keep = J(cols(X), 1, 1)
    for (j = 1; j <= p; j++) {
        keep[1 + (j - 1)*2 + 2] = 0
    }
    Xr = select(X, keep')
    b1 = J(cols(X), 1, 0)
    b1[selectindex(keep)] = invsym(Xr'Xr) * (Xr'Y[., 1])
    b2 = invsym(X'X) * (X'Y[., 2])
    A  = (b1, b2)
    E  = Y - X*A
    nres = rows(E)

    Lb = m + tau0 + taub - 1
    Rm = _extvgc_R(p, m, trend, 1 + trend + 2*m)
    mx = J(B, 1, .)
    for (b = 1; b <= B; b++) {
        idx1 = floor(runiform(Lb, 1) :* nres) :+ 1
        idx2 = idx1
        if (!joint) idx2 = floor(runiform(Lb, 1) :* nres) :+ 1
        Zb = J(Lb, 2, 0)
        Zb[1..p, .] = Z[1..p, .]
        for (t = p + 1; t <= Lb; t++) {
            zt = 1
            for (j = 1; j <= p; j++) {
                zt = zt, Zb[t - j, .]
            }
            Zb[t, .] = zt * A + (E[idx1[t], 1], E[idx2[t], 2])
        }
        W  = _extvgc_design(Zb, p, d, trend)
        k  = cols(W)
        CC = _extvgc_cumcp(W)
        S  = _extvgc_seq(CC, k, Rm, rows(W), tau0, algo)
        mx[b] = max(S)
    }
    mx = select(mx, mx :< .)
    if (rows(mx) == 0) return((., ., .))
    return((_extvgc_q(mx, 0.90), _extvgc_q(mx, 0.95), _extvgc_q(mx, 0.99)))
}

// shocks from the input matrix: first differences, or the data themselves
real matrix _extvgc_shocks(real matrix Y, real scalar diffl)
{
    if (diffl) return(Y)
    return(Y[2..rows(Y), .] - Y[1..rows(Y)-1, .])
}

void _extvgc_run(string scalar Yname, real scalar diffl, real scalar cuml,
                 real scalar theta, real scalar common, real scalar d,
                 real scalar trend, real scalar window, real scalar taub,
                 real scalar algo, real scalar B, real scalar seed,
                 real scalar joint, real scalar lagfix, real scalar maxlag,
                 real scalar ic, real scalar lagpair, string scalar pairspec)
{
    real matrix Y, E, Q, Z, W, CC, Sall, SUM, Eobs, ICT, Zall
    real colvector ps, S, mi
    real matrix mw, Rm
    real scalar T, Te, off, np, j, cc, dc, p, pall, tau0, k, R, r, im, i
    real rowvector cv

    Y  = st_matrix(Yname)
    T  = rows(Y)
    E  = _extvgc_shocks(Y, diffl)
    Te = rows(E)
    off = T - Te
    Q  = _extvgc_thr(E, theta, common)

    ps = strtoreal(tokens(pairspec))'
    np = rows(ps) / 2

    // lag order on the overall (undecomposed) system, all criteria for Table 3
    Zall = _extvgc_pair(E, Q, 0, 0, cuml)
    ICT = J(4, 1, .)
    for (i = 1; i <= 4; i++) {
        ICT[i] = _extvgc_lagsel(Zall, maxlag, i)
    }
    pall = ICT[ic]
    if (lagfix > 0) pall = lagfix

    tau0 = window
    if (tau0 <= 0) tau0 = floor(Te * (0.01 + 1.8/sqrt(Te)))

    Sall = J(T, np, .)
    SUM  = J(np, 9, .)
    rseed(seed)
    for (j = 1; j <= np; j++) {
        cc = ps[2*j - 1]
        dc = ps[2*j]
        Z  = _extvgc_pair(E, Q, cc, dc, cuml)
        p  = pall
        if (lagfix <= 0 & lagpair) p = _extvgc_lagsel(Z, maxlag, ic)
        W  = _extvgc_design(Z, p, d, trend)
        k  = cols(W)
        R  = rows(W)
        if (tau0 < k + 2 | tau0 > R) {
            errprintf("minimum window (%g) must lie between %g and %g for pair %g\n", tau0, k + 2, R, j)
            exit(198)
        }
        Rm = _extvgc_R(p, p + d, trend, k - 1)
        CC = _extvgc_cumcp(W)
        S  = _extvgc_seq(CC, k, Rm, R, tau0, algo)
        // design row r corresponds to shock row (p+d)+r, observation off+(p+d)+r
        for (r = 1; r <= rows(S); r++) {
            Sall[off + p + d + tau0 + r - 1, j] = S[r]
        }
        cv = (., ., .)
        if (B > 0) cv = _extvgc_boot(Z, p, d, trend, tau0, taub, B, algo, joint)
        im = .
        if (rows(S) > 0) {
            maxindex(editmissing(S, -1), 1, mi, mw)
            im = off + p + d + tau0 + mi[1] - 1
        }
        SUM[j, .] = (p, tau0, max(S), im, cv, rows(S), .)
    }
    Eobs = J(T, 2, .)
    Eobs[off+1..T, .] = E
    st_matrix("_xv_S", Sall)
    st_matrix("_xv_sum", SUM)
    st_matrix("_xv_thr", Q)
    st_matrix("_xv_E", Eobs)
    st_matrix("_xv_ic", ICT)
    st_numscalar("_xv_tau0", tau0)
    st_numscalar("_xv_Teps", Te)
}

// VAR(1) residuals of one pair + multivariate ARCH(1) LM (Table 2)
void _extvgc_resid1(string scalar Yname, real scalar diffl, real scalar cuml,
                    real scalar theta, real scalar common, real scalar cc, real scalar dc)
{
    real matrix Y, E, Q, Z, X, R, U, Xa, B, Ua, S0, S1
    real scalar N, n, T2, lm, df, t

    Y = st_matrix(Yname)
    E = _extvgc_shocks(Y, diffl)
    Q = _extvgc_thr(E, theta, common)
    Z = _extvgc_pair(E, Q, cc, dc, cuml)
    N = rows(Z)
    X = J(N - 1, 1, 1), Z[1..N-1, .]
    R = Z[2..N, .] - X * (invsym(X'X) * (X'Z[2..N, .]))
    st_matrix("_xv_R", R)
    // vech(u_t u_t') regressed on a constant and vech(u_{t-1} u_{t-1}')
    n = cols(R)
    U = J(rows(R), n*(n+1)/2, .)
    for (t = 1; t <= rows(R); t++) {
        U[t, .] = vech(R[t, .]' * R[t, .])'
    }
    T2 = rows(U) - 1
    Xa = J(T2, 1, 1), U[1..T2, .]
    Ua = U[2..T2+1, .]
    B  = invsym(Xa'Xa) * (Xa'Ua)
    S1 = (Ua - Xa*B)' * (Ua - Xa*B) / T2
    S0 = (Ua :- mean(Ua))' * (Ua :- mean(Ua)) / T2
    lm = 0.5*T2*n*(n+1) - T2*trace(S1*invsym(S0))
    df = n*n*(n+1)*(n+1)/4
    st_matrix("_xv_arch", (lm, df, chi2tail(df, lm)))
}

// KPSS level-stationarity statistic, Bartlett kernel
real scalar _extvgc_kpss(real colvector x)
{
    real colvector e, s
    real scalar n, l, lr, j, g

    x = select(x, x :< .)
    n = rows(x)
    e = x :- mean(x)
    s = runningsum(e)
    l = floor(4*(n/100)^0.25)
    lr = (e'e)/n
    for (j = 1; j <= l; j++) {
        g = (e[j+1..n]' * e[1..n-j]) / n
        lr = lr + 2*(1 - j/(l + 1))*g
    }
    return((s's) / (n*n*lr))
}

end
