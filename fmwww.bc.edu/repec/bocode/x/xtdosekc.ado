*! xtdosekc 1.0.0  23nov2026
*! Dynamic nonlinear panel EKC: difference-of-sigmoids curve + stochastic trends
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*
* Implements Amoroso, C., Garcia-Martos, C. and Koopman, S. J. (2026).
*   A dynamic nonlinear panel decomposition model for the global
*   Environmental Kuznets Curve. The Econometrics Journal, utag037.
*
* Step -> equation map (full map in: help xtdosekc_methods)
*   dos_curve      eq (2.1)-(2.2)  gamma*[sig(x;c1,s1) - sig(x;c2,s2)]
*   dos_obj_ssr    eq (3.2)        static NLS (single equation, FE, FE + trends)
*   dos_obj_dyn    eq (3.3)-(3.5)  z = y - DoS, mu_i concentrated by sample means
*   dos_llf        eq (3.6)-(3.9)  exact-diffuse Kalman filter, local level
*   dos_obj_dyn    eq (3.10)-(3.11) penalised objective, P_snr and P_ekc
*   dos_lbfgsb     Sec 3.2         L-BFGS-B (Byrd et al. 1995), R optim() port
*   dos_kfs        eq (3.12)       Kalman smoother -> tau_it, Var(tau_it)
*   dos_boot       Sec 3.4         Stoffer-Wall whitened-innovations bootstrap
*   dos_tp         Sec 2.1         turning point x* (Brent, R optimize())
*   dos_diag       Fig 5, Table 3  ACF(1), Ljung-Box, ADF (tseries), Shapiro-Wilk

program define xtdosekc
    version 15.0
    if replay() {
        if ("`e(cmd)'" != "xtdosekc") error 301
        _xtdosekc_disp `0'
        exit
    }
    gettoken sub rest : 0, parse(" ,")
    if inlist("`sub'", "sens", "sensitivity") {
        _xtdosekc_sens `rest'
    }
    else if inlist("`sub'", "compare", "comparison") {
        _xtdosekc_compare `rest'
    }
    else if inlist("`sub'", "illustrate", "illus", "illustration") {
        _xtdosekc_illus `rest'
    }
    else if inlist("`sub'", "integ", "integration") {
        _xtdosekc_integ `rest'
    }
    else {
        _xtdosekc_est `0'
    }
end

* =====================================================================
*  Estimation
* =====================================================================
program define _xtdosekc_est, eclass sortpreserve
    version 15.0
    syntax varlist(min=2 max=2 numeric) [if] [in] [,          ///
        MODel(string) SHift(varname numeric) INIT(numlist)      ///
        FROM(name) LSNR(real 1e6) LEKC(real 1e6) CLB(real -1e300) ///
        SNRatio(real 0.5) GAMMAPen(real 1) GAMMALB(real 1)      ///
        SMIN(real 1e-3) SMAX(real 5) SHBound(real 2)            ///
        LSMIN(real -10) LSEMAX(real -0.7) LSNMAX(real -2.5)     ///
        FACTR(real 1e7) MAXIter(integer -1) NDEPS(real 1e-3)    ///
        LMM(integer 5) REPS(integer 0) SEED(string)             ///
        GMAXboot(real 15) SHMINboot(real -1.5)                  ///
        MAXTries(integer 0) NODOTS Level(cilevel) DFM(integer 2) ///
        GENerate(name) REPLACE IDLabel(varname) GRoup(varname)  ///
        GRaph(string) GNAME(string) GEXPort(string)             ///
        COLors(string asis) EXPscale(real 0) TEX(string)        ///
        NOTABle NODIAG TRACE ]

    * ---- model
    if "`model'" == "" local model "dynamic"
    local model = lower("`model'")
    if inlist("`model'", "dyn", "dynamic", "tw", "twoway", "kalman") local model "dynamic"
    else if inlist("`model'", "static", "fe", "fixed", "pooled") local model "static"
    else if inlist("`model'", "trend", "fetrend", "lineartrend", "dt") local model "trend"
    else if inlist("`model'", "country", "univariate", "single", "unit") local model "country"
    else {
        di as err "model() must be one of dynamic, static, trend, country"
        exit 198
    }
    if "`shift'" != "" & "`model'" != "dynamic" {
        di as err "shift() is only allowed with model(dynamic)"
        exit 198
    }
    if `reps' > 0 & "`model'" != "dynamic" {
        di as err "reps() (state-space bootstrap) is only available for model(dynamic)"
        exit 198
    }
    if `reps' < 0 | `lmm' < 1 | `factr' <= 0 | `ndeps' <= 0 {
        di as err "invalid optimiser or bootstrap setting"
        exit 198
    }

    * ---- panel structure
    capture xtset
    if _rc {
        di as err "data must be {bf:xtset} (panel and time variables)"
        exit 459
    }
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if "`ivar'" == "" | "`tvar'" == "" {
        di as err "data must be {bf:xtset} with both a panel and a time variable"
        exit 459
    }
    marksample touse
    if "`shift'" != "" markout `touse' `shift'
    gettoken y x : varlist
    local x = trim("`x'")
    sort `ivar' `tvar'
    tempvar nt dt first
    qui by `ivar': gen long `nt' = sum(`touse')
    qui by `ivar': replace `nt' = `nt'[_N]
    qui summ `nt' if `touse', meanonly
    if r(N) == 0 error 2000
    if r(min) != r(max) {
        di as err "xtdosekc requires a balanced panel (same number of periods per unit)"
        exit 459
    }
    local T = r(max)
    qui count if `touse'
    local NT = r(N)
    local N = `NT' / `T'
    qui by `ivar': gen double `dt' = `tvar' - `tvar'[_n-1] if `touse' & `touse'[_n-1]
    qui summ `dt', meanonly
    if r(N) != `NT' - `N' | r(min) != r(max) {
        di as err "periods must be consecutive and common to all units (no gaps)"
        exit 459
    }
    if `T' < 10 {
        di as err "at least 10 time periods are required"
        exit 2001
    }
    qui by `ivar': gen byte `first' = `touse' & (_n == 1 | !`touse'[_n-1])

    * ---- unit labels
    local units ""
    local ids ""
    qui levelsof `ivar' if `first', local(ids)
    tempvar obsno
    qui gen long `obsno' = _n
    foreach u of local ids {
        qui summ `obsno' if `ivar' == `u' & `first', meanonly
        local o = r(min)
        if "`idlabel'" != "" {
            capture confirm string variable `idlabel'
            if !_rc local lb = `idlabel'[`o']
            else {
                local lv = `idlabel'[`o']
                local lb : label (`idlabel') `lv'
            }
        }
        else {
            local lb : label (`ivar') `u'
        }
        local lb = strtoname(`"`lb'"', 0)
        local units "`units' `lb'"
    }
    local units = trim("`units'")

    * ---- component variables
    foreach v in mu curve tau taulo tauhi fit sfit res sp {
        tempvar v_`v'
        qui gen double `v_`v'' = .
    }
    if "`seed'" != "" set seed `seed'
    local nodots_ "`nodots'"
    if "`trace'" != "" local nodots "nodots"

    _xd_cleanup
    capture noisily mata: dos_main()
    if _rc {
        local rc = _rc
        _xd_cleanup
        exit `rc'
    }

    * ---- Shapiro-Wilk per unit (Stata swilk = Royston, as R shapiro.test)
    tempname DG
    matrix `DG' = __xd_diag , J(`N', 2, .)
    if "`nodiag'" == "" {
        local i 0
        foreach u of local ids {
            local ++i
            capture qui swilk `v_res' if `touse' & `ivar' == `u'
            if !_rc {
                matrix `DG'[`i', 7] = r(W)
                matrix `DG'[`i', 8] = r(p)
            }
        }
    }
    matrix rownames `DG' = `units'
    matrix colnames `DG' = mu_i acf1 lb_q lb_p adf_stat adf_p sw_w sw_p

    * ---- assemble e()
    tempname b V TB
    local shiftlab ""
    if "`model'" == "dynamic" {
        if "`shift'" != "" {
            local pn "gamma c1 c2 c2_shift s1 s2 sig_eps sig_eta"
            local rn "gamma c1 c2 c2_shift s1 s2 sig_eps sig_eta q_ratio c2_minus_c1 c2_minus_c2shift xstar xstar_shift xstar_gap int_xstar int_xstar_shift"
            local kp 8
        }
        else {
            local pn "gamma c1 c2 s1 s2 sig_eps sig_eta"
            local rn "gamma c1 c2 s1 s2 sig_eps sig_eta q_ratio c2_minus_c1 xstar int_xstar"
            local kp 7
        }
        matrix `TB' = __xd_tab
        matrix rownames `TB' = `rn'
        matrix colnames `TB' = est se lo hi pr_le0
        matrix `b' = `TB'[1..`kp', 1]'
        matrix colnames `b' = `pn'
        local hasV 0
        capture confirm scalar __xd_kept
        if !_rc {
            if __xd_kept > 1 {
                mata: st_matrix("`V'", variance(st_matrix("__xd_dd")[., 1..`kp']))
                matrix rownames `V' = `pn'
                matrix colnames `V' = `pn'
                local hasV 1
            }
        }
        if `hasV' ereturn post `b' `V', esample(`touse') obs(`NT') depname(`y')
        else ereturn post `b', esample(`touse') obs(`NT') depname(`y')
        ereturn matrix table = `TB'
        ereturn scalar ll = __xd_ll
        ereturn scalar ll_unpen = __xd_llu
        ereturn scalar penalty = __xd_pen
        ereturn scalar ssr = __xd_ssr
        ereturn scalar lsnr = `lsnr'
        ereturn scalar lekc = `lekc'
        ereturn scalar snratio = `snratio'
        ereturn scalar gammapen = `gammapen'
        ereturn scalar reps = `reps'
        ereturn scalar kept = 0
        ereturn scalar ndisc = __xd_ndisc
        capture confirm scalar __xd_kept
        if !_rc {
            ereturn scalar kept = __xd_kept
            ereturn scalar discard_rate = __xd_ndisc / (__xd_kept + __xd_ndisc)
            tempname DR DD
            matrix `DR' = __xd_draws
            matrix colnames `DR' = `pn'
            matrix `DD' = __xd_dd
            matrix colnames `DD' = `rn'
            ereturn matrix draws = `DR'
            ereturn matrix boot = `DD'
        }
        ereturn scalar level = `level'
        tempname TAU VT
        matrix `TAU' = __xd_tau
        matrix colnames `TAU' = `units'
        matrix `VT' = __xd_vtau
        ereturn matrix tau = `TAU'
        ereturn matrix vtau = `VT'
        capture confirm matrix __xd_load
        if !_rc {
            tempname LD FH EG
            matrix `LD' = __xd_load
            matrix rownames `LD' = `units'
            matrix `FH' = __xd_fac
            matrix `EG' = __xd_eig
            matrix colnames `EG' = eigenvalue share cumshare
            ereturn matrix loadings = `LD'
            ereturn matrix factors = `FH'
            ereturn matrix eigen = `EG'
        }
        local shiftlab "`shift'"
    }
    else if "`model'" == "country" {
        tempname CT
        matrix `CT' = __xd_country
        matrix rownames `CT' = `units'
        matrix colnames `CT' = mu gamma c1 c2 s1 s2 ssr fail iter mse
        matrix `b' = `CT'[1..., 2]'
        matrix colnames `b' = `units'
        ereturn post `b', esample(`touse') obs(`NT') depname(`y')
        ereturn matrix country = `CT'
        ereturn scalar ssr = __xd_ssr
    }
    else {
        matrix `TB' = __xd_tab
        matrix rownames `TB' = gamma c1 c2 s1 s2 c2_minus_c1 xstar
        matrix colnames `TB' = est se lo hi pr_le0
        matrix `b' = `TB'[1..5, 1]'
        matrix colnames `b' = gamma c1 c2 s1 s2
        ereturn post `b', esample(`touse') obs(`NT') depname(`y')
        ereturn matrix table = `TB'
        ereturn scalar ssr = __xd_ssr
        ereturn scalar ll = __xd_ll
        ereturn scalar int_xstar = __xd_tpint
        tempname DL
        matrix `DL' = __xd_delta
        matrix rownames `DL' = `units'
        if "`model'" == "trend" ereturn matrix delta = `DL'
    }
    if "`model'" != "country" {
        tempname RAW MU GR
        matrix `RAW' = __xd_raw
        matrix `MU' = __xd_mu
        matrix rownames `MU' = `units'
        matrix `GR' = __xd_grid
        ereturn matrix raw = `RAW'
        ereturn matrix mu = `MU'
        ereturn matrix grid = `GR'
        ereturn scalar converged = (__xd_fail == 0)
        ereturn scalar fail = __xd_fail
        ereturn scalar iterations = __xd_iter
        ereturn scalar nfg = __xd_nfg
    }
    ereturn matrix diag = `DG'
    ereturn scalar N_g = `N'
    ereturn scalar T = `T'
    ereturn scalar xmin = __xd_xmin
    ereturn scalar xmax = __xd_xmax
    ereturn scalar factr = `factr'
    ereturn scalar expscale = `expscale'
    ereturn local units "`units'"
    ereturn local ivar "`ivar'"
    ereturn local tvar "`tvar'"
    ereturn local depvar "`y'"
    ereturn local indepvar "`x'"
    ereturn local shift "`shiftlab'"
    ereturn local model "`model'"
    ereturn local optimizer "L-BFGS-B"
    ereturn local title "Difference-of-sigmoids EKC panel model"
    ereturn local cmdline `"xtdosekc `0'"'
    ereturn local cmd "xtdosekc"
    _xd_cleanup

    * ---- output
    if "`notable'" == "" _xtdosekc_disp, `nodiag'

    if "`generate'" != "" {
        if "`model'" == "dynamic" local glist "mu curve tau taulo tauhi fit sfit res sp"
        else if "`model'" == "trend" local glist "mu curve tau fit res sp"
        else local glist "mu curve fit res sp"
        foreach v of local glist {
            local nm "`generate'_`v'"
            if "`v'" == "sp" local nm "`generate'_struct"
            if "`v'" == "tau" & "`model'" == "trend" local nm "`generate'_trend"
            if "`replace'" != "" capture drop `nm'
            qui gen double `nm' = `v_`v'' if e(sample)
        }
        di as txt _n "(generated: " as res "`generate'_*" as txt ")"
    }
    if `"`graph'"' != "" {
        _xtdosekc_graph `graph', y(`y') x(`x') ivar(`ivar') tvar(`tvar')     ///
            mu(`v_mu') curve(`v_curve') tau(`v_tau') taulo(`v_taulo')         ///
            tauhi(`v_tauhi') fit(`v_fit') sfit(`v_sfit') res(`v_res')         ///
            sp(`v_sp') group(`group') gname(`gname') gexport(`gexport')       ///
            colors(`colors')
    }
    if `"`tex'"' != "" _xtdosekc_tex `"`tex'"'
end

program define _xd_cleanup
    foreach s in kept ndisc ll llu pen ssr fail iter nfg xmin xmax N T tpint tp peak {
        capture scalar drop __xd_`s'
    }
    foreach m in draws dd tab raw mu tau vtau diag load fac eig grid delta country illus cd {
        capture matrix drop __xd_`m'
    }
end

* =====================================================================
*  Display
* =====================================================================
program define _xd_cell
    args v fmt w
    if "`w'" == "" local w 10
    if missing(`v') di as txt %`w's "--" _c
    else di as res %`w'.`fmt'f `v' _c
end

program define _xd_stars, rclass
    args p
    local s ""
    if !missing(`p') {
        if `p' < 0.10 local s "*"
        if `p' < 0.05 local s "**"
        if `p' < 0.01 local s "***"
    }
    return local s "`s'"
end

program define _xd_trow
    args lab r test short
    tempname T
    matrix `T' = e(table)
    local est = `T'[`r', 1]
    local se  = `T'[`r', 2]
    local lo  = `T'[`r', 3]
    local hi  = `T'[`r', 4]
    local pr  = `T'[`r', 5]
    di as txt %17s "`lab'" " {c |}" _c
    _xd_cell `est' 4 11
    if "`short'" != "" {
        di ""
        exit
    }
    _xd_cell `se' 4 11
    di as txt "   " _c
    _xd_cell `lo' 4 9
    _xd_cell `hi' 4 9
    if "`test'" != "" & !missing(`pr') {
        local p2 = 2 * min(`pr', 1 - `pr')
        if `p2' == 0 {
            local p2 = 1 / max(e(kept), 1)
            _xd_stars `p2'
            di as txt "   <" as res %6.4f `p2' as txt " `r(s)'" _c
        }
        else {
            _xd_stars `p2'
            di as res %10.4f `p2' as txt " `r(s)'" _c
        }
    }
    di ""
end

program define _xtdosekc_disp
    syntax [, NODIAG]
    local m "`e(model)'"
    local lev = cond(missing(e(level)), 95, e(level))
    di ""
    if "`m'" == "dynamic" {
        di as txt "{bf:Dynamic nonlinear panel EKC: difference-of-sigmoids + stochastic trends}"
    }
    else if "`m'" == "static" {
        di as txt "{bf:Static nonlinear panel EKC: difference-of-sigmoids, fixed effects}"
    }
    else if "`m'" == "trend" {
        di as txt "{bf:Static nonlinear panel EKC: fixed effects + country linear trends}"
    }
    else {
        di as txt "{bf:Single-equation difference-of-sigmoids EKC, country by country}"
    }
    di as txt "Amoroso, Garcia-Martos & Koopman (2026), {it:The Econometrics Journal}"
    di as txt "{hline 78}"
    di as txt "Dependent var. : " as res %-22s "`e(depvar)'" as txt "  Number of obs   = " as res %9.0f e(N)
    di as txt "Income var.    : " as res %-22s "`e(indepvar)'" as txt "  Number of units = " as res %9.0f e(N_g)
    di as txt "Panel / time   : " as res %-22s "`e(ivar)' / `e(tvar)'" as txt "  Time periods    = " as res %9.0f e(T)
    if "`m'" == "dynamic" {
        local spec "global (pooled c2)"
        if "`e(shift)'" != "" local spec "regional (c2 shifted: `e(shift)'!=0)"
        local cv "converged"
        if e(fail) != 0 local cv "NOT converged (code `=e(fail)')"
        di as txt "Specification  : " as res %-22s "`spec'" as txt "  Bootstrap reps  = " as res %9.0f e(kept)
        di as txt "Estimator      : " as res "penalised profile ML, exact-diffuse Kalman filter"
        di as txt "Optimiser      : " as res "L-BFGS-B, `cv', " e(iterations) " iterations"
        di as txt "Penalties      : " as res "lambda_snr = " %8.0g e(lsnr) ", lambda_ekc = " %8.0g e(lekc) ///
            as txt "  (sigma_eta <= " as res e(snratio) as txt " sigma_eps, gamma >= " as res e(gammapen) as txt ")"
        di as txt "{hline 18}{c TT}{hline 59}"
        if e(kept) > 1 {
            di as txt %17s "" " {c |}   Estimate  Boot. SE      [`lev'% perc. CI]       Boot. p"
        }
        else {
            di as txt %17s "" " {c |}   Estimate  Boot. SE      [`lev'% perc. CI]"
        }
        di as txt "{hline 18}{c +}{hline 59}"
        local R = ("`e(shift)'" != "")
        di as txt %17s "DoS curve" " {c |}"
        _xd_trow "gamma" 1
        _xd_trow "c1 (growth)" 2
        _xd_trow "c2 (green)" 3
        if `R' {
            _xd_trow "c2 (shift group)" 4
            _xd_trow "s1" 5
            _xd_trow "s2" 6
            local o 6
        }
        else {
            _xd_trow "s1" 4
            _xd_trow "s2" 5
            local o 5
        }
        di as txt %17s "Noise / trends" " {c |}"
        _xd_trow "sigma_eps" `=`o'+1'
        _xd_trow "sigma_eta" `=`o'+2'
        _xd_trow "q = eta/eps" `=`o'+3'
        di as txt %17s "Contrasts" " {c |}"
        _xd_trow "c2 - c1" `=`o'+4' test
        if `R' {
            _xd_trow "c2 - c2(shift)" `=`o'+5' test
        }
        di as txt %17s "Turning point" " {c |}"
        tempname T
        matrix `T' = e(table)
        if `R' {
            local rt = `o' + 6
            local it1 = `T'[`o'+9, 1]
            local it2 = `T'[`o'+10, 1]
        }
        else {
            local rt = `o' + 5
            local it1 = `T'[`o'+6, 1]
        }
        if `it1' == 1 _xd_trow "x*" `rt'
        else di as txt %17s "x*" " {c |}" %11s "--" "  (maximum at the edge of the income range)"
        if `R' {
            if `it2' == 1 _xd_trow "x*(shift)" `=`rt'+1'
            else di as txt %17s "x*(shift)" " {c |}" %11s "--" "  (maximum at the edge of the income range)"
            _xd_trow "x* - x*(shift)" `=`rt'+2' test
        }
        di as txt "{hline 18}{c BT}{hline 59}"
        di as txt "Log-likelihood (penalised) = " as res %10.3f e(ll) ///
           as txt "   unpenalised = " as res %10.3f e(ll_unpen) as txt "   penalty = " as res %8.3f e(penalty)
        if e(kept) > 1 {
            di as txt "Bootstrap: Stoffer-Wall whitened innovations, " as res e(kept) as txt " kept, " ///
               as res e(ndisc) as txt " discarded (" as res %4.1f 100 * e(discard_rate) as txt "%)."
            di as txt "Boot. p: two-sided bootstrap p-value of the contrast against 0;" ///
               " *** p<0.01, ** p<0.05, * p<0.10."
            if e(penalty) > 0 {
                di as txt "sigma rows: the SNR penalty binds in re-estimation, so their bootstrap"
                di as txt "distribution is shifted (as in the paper, which reports no SE for them)."
            }
        }
        else {
            di as txt "Standard errors: specify {bf:reps(#)} (paper: reps(500)) for the state-space bootstrap."
        }
        if e(expscale) > 0 & `it1' == 1 {
            local lv = exp(`T'[`rt', 1]) * e(expscale)
            di as txt "Turning point in levels: exp(x*) x " e(expscale) " = " as res %12.0fc `lv'
            if `R' {
                local lv2 = exp(`T'[`rt'+1, 1]) * e(expscale)
                di as txt "                 shift group: exp(x*) x " e(expscale) " = " as res %12.0fc `lv2' ///
                   as txt "  (ratio " as res %5.3f `lv' / `lv2' as txt ")"
            }
        }
    }
    else if "`m'" == "country" {
        di as txt "Estimator      : " as res "NLS per unit, L-BFGS-B (R optim defaults)"
        di as txt "{hline 18}{c TT}{hline 72}"
        di as txt %17s "Unit" " {c |}" %10s "mu" %10s "gamma" %10s "c1" %10s "c2" %10s "s1" %10s "s2" %11s "SSR" " conv"
        di as txt "{hline 18}{c +}{hline 72}"
        tempname C
        matrix `C' = e(country)
        local un "`e(units)'"
        forvalues i = 1/`=rowsof(`C')' {
            local lb : word `i' of `un'
            local lb = subinstr("`lb'", "_", " ", .)
            di as txt %17s abbrev("`lb'", 17) " {c |}" _c
            _xd_cell `C'[`i',1] 4
            _xd_cell `C'[`i',2] 4
            if `C'[`i',5] < 1e-4 _xd_cell . 4
            else _xd_cell `C'[`i',3] 4
            if `C'[`i',6] < 1e-4 _xd_cell . 4
            else _xd_cell `C'[`i',4] 4
            _xd_cell `C'[`i',5] 4
            _xd_cell `C'[`i',6] 4
            _xd_cell `C'[`i',7] 5 11
            di as txt "  " cond(`C'[`i',8] == 0, "yes", "no")
        }
        di as txt "{hline 18}{c BT}{hline 72}"
        di as txt "c_j reported as -- when s_j < 1e-4 (logistic flat, location not identified; Table 1)."
    }
    else {
        di as txt "Estimator      : " as res "nonlinear least squares, L-BFGS-B" ///
           as txt ", " cond(e(converged) == 1, "converged", "NOT converged") ", " e(iterations) " iterations"
        di as txt "{hline 18}{c TT}{hline 22}"
        di as txt %17s "" " {c |}   Estimate"
        di as txt "{hline 18}{c +}{hline 22}"
        _xd_trow "gamma" 1 "" short
        _xd_trow "c1 (growth)" 2 "" short
        _xd_trow "c2 (green)" 3 "" short
        _xd_trow "s1" 4 "" short
        _xd_trow "s2" 5 "" short
        _xd_trow "c2 - c1" 6 "" short
        if e(int_xstar) == 1 _xd_trow "x*" 7 "" short
        else di as txt %17s "x*" " {c |}" %11s "--" "  (maximum at the edge of the income range)"
        di as txt "{hline 18}{c BT}{hline 22}"
        di as txt "SSR = " as res %10.5f e(ssr) as txt "   RMSE = " as res %8.5f sqrt(e(ssr) / e(N)) ///
           as txt "   Gaussian log-likelihood = " as res %10.3f e(ll)
        if "`m'" == "trend" {
            di as txt _n "Country linear trend slopes (delta_i):"
            tempname DL
            matrix `DL' = e(delta)
            local un "`e(units)'"
            local line ""
            forvalues i = 1/`=rowsof(`DL')' {
                local lb : word `i' of `un'
                di as txt %16s abbrev(subinstr("`lb'", "_", " ", .), 16) " " as res %9.4f `DL'[`i', 1] _c
                if mod(`i', 3) == 0 di ""
            }
            di ""
        }
    }
    if "`nodiag'" == "" _xtdosekc_dtab
end

program define _xtdosekc_dtab
    tempname D
    matrix `D' = e(diag)
    local un "`e(units)'"
    local m "`e(model)'"
    di ""
    if "`m'" == "dynamic" di as txt "{bf:Fixed effects and residual diagnostics} (residual = y - mu_i - DoS - tau_it; Table 3)"
    else di as txt "{bf:Fixed effects and residual diagnostics} (static residuals; Figure 5)"
    di as txt "{hline 18}{c TT}{hline 61}"
    di as txt %17s "Unit" " {c |}" %10s "mu_i" %10s "ACF(1)" %13s "Ljung-Box p" %12s "ADF p" %15s "Shapiro-Wilk p"
    di as txt "{hline 18}{c +}{hline 61}"
    local nrej 0
    local nlb 0
    forvalues i = 1/`=rowsof(`D')' {
        local lb : word `i' of `un'
        local lb = subinstr("`lb'", "_", " ", .)
        local ap = `D'[`i', 6]
        local st ""
        if `ap' < 0.05 {
            local st "**"
            local ++nrej
        }
        if `D'[`i', 4] >= 0.05 local ++nlb
        di as txt %17s abbrev("`lb'", 17) " {c |}" as res %10.3f `D'[`i', 1] %10.3f `D'[`i', 2] ///
           %13.4f `D'[`i', 4] %10.4f `ap' as txt %-2s "`st'" as res %15.4f `D'[`i', 8]
    }
    di as txt "{hline 18}{c BT}{hline 61}"
    di as txt "ADF: tseries::adf.test(k = 1), constant + trend, p interpolated in [0.01, 0.10];"
    di as txt "** rejects the unit root at 5%.  ADF rejections: " as res "`nrej'/`=rowsof(`D')'" ///
       as txt ";  Ljung-Box(1) non-rejections: " as res "`nlb'/`=rowsof(`D')'"
end

* =====================================================================
*  Graphs
* =====================================================================
program define _xtdosekc_graph
    syntax anything(name=types), Y(varname) X(varname) IVAR(varname) TVAR(varname) ///
        [MU(string) CURVE(string) TAU(string) TAULO(string) TAUHI(string) FIT(string) ///
         SFIT(string) RES(string) SP(string) GRoup(string) GNAME(string)                ///
         GEXPort(string) COLors(string asis)]
    if "`gname'" == "" local gname "xtdosekc"
    if `"`colors'"' == "" {
        local colors `""74 20 134" "102 166 30" "122 1 119" "197 27 138" "255 215 0" "8 48 107" "8 81 156" "255 127 14" "240 59 32" "33 113 181" "227 26 28" "247 104 161" "127 39 4" "66 146 198" "152 0 67" "0 158 115" "177 89 40" "128 128 128""'
    }
    local nc : word count `colors'
    local m "`e(model)'"
    local types = lower(`"`types'"')
    if strpos(" `types' ", " all ") {
        if "`m'" == "dynamic" local types "data fit curve trends decomp diag dfm boot"
        else if "`m'" == "country" local types "data fit decomp diag"
        else local types "data fit curve decomp diag"
    }
    local un "`e(units)'"
    qui levelsof `ivar' if e(sample), local(ids)
    local i 0
    foreach u of local ids {
        local ++i
        local id`i' `u'
        local w = mod(`i' - 1, `nc') + 1
        local col`i' : word `w' of `colors'
        local lab`i' : word `i' of `un'
        local lab`i' = subinstr("`lab`i''", "_", " ", .)
        local grp`i' 1
        if "`group'" != "" {
            qui summ `group' if `ivar' == `u' & e(sample), meanonly
            local grp`i' = (r(mean) != 0)
        }
    }
    local N `i'
    local gopt "graphregion(color(white)) plotregion(lcolor(gs10))"
    local yl : variable label `y'
    if `"`yl'"' == "" local yl "`y'"
    local xl : variable label `x'
    if `"`xl'"' == "" local xl "`x'"
    local legrows = ceil(`N' / 8)

    foreach g of local types {
        * --------------------------------------------------- data (Figure 2)
        if "`g'" == "data" {
            preserve
            qui keep if e(sample)
            qui keep `ivar' `tvar' `y' `x' `group'
            qui expand 2
            qui bysort `ivar' `tvar': gen byte __k = _n
            qui gen double __v = cond(__k == 1, `y', `x')
            label define __kl 1 `"`yl'"' 2 `"`xl'"', replace
            label values __k __kl
            local pl ""
            local lg ""
            forvalues j = 1/`N' {
                local lp "solid"
                if "`group'" != "" & `grp`j'' == 0 local lp "dash"
                local pl `"`pl' (line __v `tvar' if `ivar' == `id`j'', sort lcolor("`col`j''") lwidth(medthick) lpattern(`lp'))"'
                local lg `"`lg' `j' "`lab`j''""'
            }
            twoway `pl', by(__k, yrescale note("") `gopt' legend(pos(6))) ///
                legend(order(`lg') rows(`legrows') size(small) symxsize(6)) ///
                ytitle("") xtitle("") name(`gname'_data, replace)
            restore
        }
        * --------------------------------------------------- fit (Figures 3-4)
        else if "`g'" == "fit" {
            local pl ""
            local lg ""
            forvalues j = 1/`N' {
                local k = 2 * `j'
                local pl `"`pl' (scatter `y' `x' if `ivar' == `id`j'' & e(sample), mcolor("`col`j''%35") msize(vsmall) msymbol(O))"'
                local pl `"`pl' (line `sfit' `x' if `ivar' == `id`j'' & e(sample), sort lcolor("`col`j''") lwidth(medthick))"'
                local lg `"`lg' `k' "`lab`j''""'
            }
            local ttl "Country fits: mu_i + DoS(x)"
            if "`m'" == "country" local ttl "Single-equation DoS fits"
            if "`m'" == "trend" local ttl "Fits: mu_i + delta_i t + DoS(x)"
            twoway `pl', `gopt' legend(order(`lg') rows(`legrows') size(small) pos(6)) ///
                ytitle(`"`yl'"') xtitle(`"`xl'"') title("`ttl'", size(medium)) ///
                name(`gname'_fit, replace)
        }
        * --------------------------------------------------- curve (Figures 6-7)
        else if "`g'" == "curve" & "`m'" != "country" {
            tempname G TB
            matrix `G' = e(grid)
            matrix `TB' = e(table)
            preserve
            qui keep if e(sample)
            qui keep `ivar' `x' `sp'
            if _N < 300 qui set obs 300
            qui svmat double `G', name(__g)
            local pl ""
            forvalues j = 1/`N' {
                local pl `"`pl' (scatter `sp' `x' if `ivar' == `id`j'', mcolor("`col`j''%45") msize(small) msymbol(O) mlwidth(none))"'
            }
            local np = `N'
            local xls ""
            if "`m'" == "dynamic" {
                if "`e(shift)'" != "" {
                    local pl `"`pl' (line __g2 __g1, lcolor(gs6) lwidth(thick)) (line __g3 __g1, lcolor("0 114 178") lwidth(thick))"'
                    local lgd `"legend(order(`=`np'+2' "Shift group (`e(shift)')" `=`np'+1' "Global curve") rows(1) pos(12) size(small))"'
                    if `TB'[15, 1] == 1 local xls "`xls' xline(`=`TB'[12,1]', lpattern(dash) lcolor(gs6) lwidth(medthick))"
                    if `TB'[16, 1] == 1 local xls "`xls' xline(`=`TB'[13,1]', lpattern(dash) lcolor("0 114 178") lwidth(medthick))"
                }
                else {
                    local pl `"`pl' (line __g2 __g1, lcolor(black) lwidth(thick))"'
                    local lgd "legend(off)"
                    if `TB'[11, 1] == 1 local xls "xline(`=`TB'[10,1]', lpattern(dash) lcolor(black) lwidth(medthick))"
                }
                local yt "Structural emissions: y - mu_i - tau_it"
            }
            else {
                local pl `"`pl' (line __g2 __g1, lcolor(black) lwidth(thick))"'
                local lgd "legend(off)"
                if e(int_xstar) == 1 local xls "xline(`=`TB'[7,1]', lpattern(dash) lcolor(black) lwidth(medthick))"
                local yt "y - mu_i (- delta_i t)"
            }
            twoway `pl', `gopt' `lgd' `xls' ytitle("`yt'") xtitle(`"`xl'"') ///
                title("Structural DoS curve", size(medium)) name(`gname'_curve, replace)
            restore
        }
        * --------------------------------------------------- trends (Figure 8)
        else if "`g'" == "trends" & "`m'" == "dynamic" {
            twoway (rarea `taulo' `tauhi' `tvar' if e(sample), color(gs13) lwidth(none))   ///
                   (line `tau' `tvar' if e(sample), lcolor(black) lwidth(medthick)),     ///
                   by(`ivar', note("") legend(off) `gopt' title("Smoothed stochastic trends tau_it (`=e(level)'% band)", size(medium))) ///
                   yline(0, lpattern(dash) lcolor(gs8)) ytitle("tau (log deviation)") xtitle("") ///
                   name(`gname'_trends, replace)
        }
        * --------------------------------------------------- decomposition (new)
        else if "`g'" == "decomp" {
            local l2 "mu + DoS"
            local pl3 ""
            if "`m'" == "dynamic" {
                local pl3 `"(line `fit' `tvar' if e(sample), lcolor("0 114 178") lwidth(medthick))"'
                local lg `"order(1 "Observed" 2 "mu_i + DoS(x)" 3 "mu_i + DoS(x) + tau_it") rows(1)"'
            }
            else local lg `"order(1 "Observed" 2 "Fitted") rows(1)"'
            twoway (scatter `y' `tvar' if e(sample), mcolor(gs6) msize(vsmall))                ///
                   (line `sfit' `tvar' if e(sample), lcolor("215 25 28") lpattern(dash))         ///
                   `pl3', by(`ivar', note("") yrescale legend(pos(6)) `gopt'                     ///
                   title("Decomposition of `y'", size(medium))) xlabel(#3, labsize(small))       ///
                   ylabel(#3, labsize(small) angle(0)) legend(`lg' size(small))                  ///
                   ytitle("") xtitle("") name(`gname'_decomp, replace)
        }
        * --------------------------------------------------- diagnostics (Figure 5)
        else if "`g'" == "diag" {
            tempname D
            matrix `D' = e(diag)
            local TT = e(T)
            preserve
            qui clear
            qui svmat double `D', name(__d)
            qui gen int __i = _n
            forvalues j = 1/`N' {
                label define __ul `j' "`lab`j''", add
            }
            label values __i __ul
            local band = 1.96 / sqrt(`TT')
            local ttl1 "1. Serial correlation (ACF-1)"
            local ttl2 "2. Ljung-Box test (white noise)"
            local ttl3 "3. ADF test (stationarity)"
            local ttl4 "4. Shapiro-Wilk (normality)"
            local sub1 "Ideal: inside dashed bands"
            local sub2 "Ideal: above dashed line"
            local sub3 "Ideal: below dashed line"
            local sub4 "Ideal: above dashed line"
            local cv1 "__d2"
            local cv2 "__d4"
            local cv3 "__d6"
            local cv4 "__d8"
            local gl ""
            forvalues q = 1/4 {
                local pl ""
                forvalues j = 1/`N' {
                    local ms "O"
                    if `grp`j'' == 0 local ms "T"
                    local pl `"`pl' (scatter `cv`q'' __i if __i == `j', mcolor("`col`j''") msymbol(`ms') msize(medlarge))"'
                }
                if `q' == 1 local ref "yline(0, lcolor(gs8)) yline(-`band' `band', lpattern(dash) lcolor(gs6))"
                else local ref "yline(0.05, lpattern(dash) lcolor(black))"
                twoway `pl', `gopt' legend(off) `ref' xlabel(1(1)`N', valuelabel angle(90) labsize(small)) ///
                    xtitle("") ytitle("") title("`ttl`q''", size(medsmall)) subtitle("`sub`q''", size(small)) ///
                    name(__xdg`q', replace) nodraw
                local gl "`gl' __xdg`q'"
            }
            graph combine `gl', cols(2) `gopt' name(`gname'_diag, replace) ///
                note("Circles: group = 1; triangles: group = 0 (option group())", size(vsmall))
            graph drop `gl'
            restore
        }
        * --------------------------------------------------- DFM loadings (Figure 9)
        else if "`g'" == "dfm" & "`m'" == "dynamic" {
            capture confirm matrix e(loadings)
            if _rc continue
            tempname L E
            matrix `L' = e(loadings)
            matrix `E' = e(eigen)
            preserve
            qui clear
            qui svmat double `L', name(__l)
            qui gen int __i = _n
            forvalues j = 1/`N' {
                label define __ul `j' "`lab`j''", add
            }
            label values __i __ul
            local gl ""
            forvalues q = 1/`=colsof(`L')' {
                local sh = 100 * `E'[`q', 2]
                twoway (bar __l`q' __i if __l`q' >= 0, horizontal color("44 123 182") barwidth(.7)) ///
                       (bar __l`q' __i if __l`q' < 0, horizontal color("215 25 28") barwidth(.7)), ///
                       `gopt' legend(off) ylabel(1(1)`N', valuelabel angle(0) labsize(small)) ///
                       xline(0, lcolor(gs6)) ytitle("") xtitle("Loading") ///
                       title("Factor `q' (`: di %4.1f `sh''% of trend variance)", size(medsmall)) ///
                       name(__xdf`q', replace) nodraw
                local gl "`gl' __xdf`q'"
            }
            graph combine `gl', rows(1) `gopt' name(`gname'_dfm, replace) ///
                title("Dynamic factor loadings of the stochastic trends (Pena-Box)", size(medium))
            graph drop `gl'
            restore
        }
        * --------------------------------------------------- bootstrap distributions
        else if "`g'" == "boot" & "`m'" == "dynamic" {
            if e(kept) < 2 continue
            tempname DD TB
            matrix `DD' = e(boot)
            matrix `TB' = e(table)
            preserve
            qui clear
            qui svmat double `DD', name(__b)
            if "`e(shift)'" != "" {
                local vl "1 3 4 11 12 13"
                local nl `""gamma" "c2" "c2 (shift group)" "c2 - c2(shift)" "x*" "x*(shift)""'
            }
            else {
                local vl "1 2 3 9 10 5"
                local nl `""gamma" "c1" "c2" "c2 - c1" "x*" "s2""'
            }
            local gl ""
            local q 0
            foreach c of local vl {
                local ++q
                local nm : word `q' of `nl'
                local ev = `TB'[`c', 1]
                twoway (histogram __b`c', color("8 81 156%50") lcolor(white)), `gopt' ///
                    xline(`ev', lcolor("215 25 28") lwidth(medthick)) title("`nm'", size(medsmall)) ///
                    xtitle("") ytitle("") legend(off) name(__xdb`q', replace) nodraw
                local gl "`gl' __xdb`q'"
            }
            graph combine `gl', cols(3) `gopt' name(`gname'_boot, replace) ///
                title("Bootstrap distributions (`=e(kept)' draws; red = estimate)", size(medium))
            graph drop `gl'
            restore
        }
        else continue
        if "`gexport'" != "" {
            capture graph export "`gname'_`g'.`gexport'", name(`gname'_`g') replace
        }
    }
end

* =====================================================================
*  LaTeX export of the main table
* =====================================================================
program define _xtdosekc_tex
    args fn
    * NB: '$' is never stored in a macro (Stata would re-expand it); labels are
    * written between separate "`D'" tokens.
    local D = char(36)
    tempname fh T D2
    file open `fh' using `"`fn'"', write replace text
    local m "`e(model)'"
    file write `fh' "\begin{table}[htbp]" _n "\centering" _n
    if "`m'" == "dynamic" {
        matrix `T' = e(table)
        local R = ("`e(shift)'" != "")
        file write `fh' "\caption{Dynamic DoS EKC model with stochastic trends}" _n
        file write `fh' "\begin{tabular*}{\textwidth}{@{\extracolsep{\fill}}lcc@{}}" _n "\hline\hline" _n
        file write `fh' " & Est. & SE \\" _n "\hline" _n
        if `R' {
            local rows "1 2 3 4 5 6 7 8 10 11 12 13 14"
            local labs `""\gamma" "c_1" "c_2" "c_2^{Eur}" "s_1" "s_2" "\sigma_\epsilon" "\sigma_\eta" "c_2 - c_1" "c_2 - c_2^{Eur}" "x^{\ast}" "x^{\ast}_{Eur}" "x^{\ast} - x^{\ast}_{Eur}""'
        }
        else {
            local rows "1 2 3 4 5 6 7 9 10"
            local labs `""\gamma" "c_1" "c_2" "s_1" "s_2" "\sigma_\epsilon" "\sigma_\eta" "c_2 - c_1" "x^{\ast}""'
        }
        local q 0
        foreach r of local rows {
            local ++q
            local lb : word `q' of `labs'
            local e1 : di %9.3f `T'[`r', 1]
            local s1 "--"
            if !missing(`T'[`r', 2]) local s1 : di %9.3f `T'[`r', 2]
            file write `fh' "`D'" "`lb'" "`D'" " & `=trim("`e1'")' & `=trim("`s1'")' \\" _n
        }
        file write `fh' "\hline" _n "Log-likelihood & `: di %9.2f e(ll)' & \\" _n
    }
    else if "`m'" == "country" {
        matrix `T' = e(country)
        file write `fh' "\caption{Estimated parameters for the static univariate model}" _n
        file write `fh' "\begin{tabular*}{\textwidth}{@{\extracolsep{\fill}}lrrrrrr@{}}" _n "\hline\hline" _n
        file write `fh' "Country & " "`D'" "\mu" "`D'" " & " "`D'" "\gamma" "`D'" " & " "`D'" "c_1" "`D'" " & " ///
            "`D'" "c_2" "`D'" " & " "`D'" "s_1" "`D'" " & " "`D'" "s_2" "`D'" " \\" _n "\hline" _n
        local un "`e(units)'"
        forvalues i = 1/`=rowsof(`T')' {
            local lb : word `i' of `un'
            local lb = subinstr("`lb'", "_", " ", .)
            local line "`lb'"
            forvalues j = 1/6 {
                local v = `T'[`i', `j']
                if `j' == 3 & `T'[`i', 5] < 1e-4 local v = .
                if `j' == 4 & `T'[`i', 6] < 1e-4 local v = .
                if missing(`v') local line "`line' & --"
                else local line "`line' & `: di %9.4f round(`v', .001)'"
            }
            file write `fh' "`line' \\" _n
        }
    }
    else {
        matrix `T' = e(table)
        file write `fh' "\caption{Static DoS EKC panel model}" _n
        file write `fh' "\begin{tabular*}{\textwidth}{@{\extracolsep{\fill}}lc@{}}" _n "\hline\hline" _n
        local labs `""\gamma" "c_1" "c_2" "s_1" "s_2" "c_2 - c_1" "x^{\ast}""'
        forvalues r = 1/7 {
            local lb : word `r' of `labs'
            file write `fh' "`D'" "`lb'" "`D'" " & `: di %9.3f `T'[`r', 1]' \\" _n
        }
        file write `fh' "\hline" _n "Log-likelihood & `: di %9.2f e(ll)' \\" _n
    }
    file write `fh' "\hline\hline" _n "\end{tabular*}" _n "\end{table}" _n _n
    matrix `D2' = e(diag)
    file write `fh' "\begin{table}[htbp]" _n "\centering" _n
    file write `fh' "\caption{Country-specific fixed effects and residual diagnostics}" _n
    file write `fh' "\begin{tabular*}{\textwidth}{@{\extracolsep{\fill}}lcccc@{}}" _n "\hline\hline" _n
    file write `fh' "Country & " "`D'" "\hat{\mu}_i" "`D'" " & Ljung-Box (" "`D'" "p" "`D'" "-val) & ADF Test (" ///
        "`D'" "p" "`D'" "-val) & Shapiro-Wilk (" "`D'" "p" "`D'" "-val) \\" _n "\hline" _n
    local un "`e(units)'"
    forvalues i = 1/`=rowsof(`D2')' {
        local lb : word `i' of `un'
        local lb = subinstr("`lb'", "_", " ", .)
        local st ""
        if `D2'[`i', 6] < 0.05 local st "**"
        file write `fh' "`lb' & `: di %6.3f `D2'[`i',1]' & `: di %6.4f `D2'[`i',4]' & `: di %6.4f `D2'[`i',6]'`st' & `: di %6.4f `D2'[`i',8]' \\" _n
    }
    file write `fh' "\hline\hline" _n "\end{tabular*}" _n
    file write `fh' "\footnotesize \textbf{Note:} Asterisks (**) denote rejection of the unit root null hypothesis at the 5\% significance level." _n
    file write `fh' "\end{table}" _n
    file close `fh'
    di as txt `"(LaTeX tables written to `fn')"'
end

* =====================================================================
*  Penalty sensitivity (Online Appendix S1.2, Tables S1-S2)
* =====================================================================
program define _xtdosekc_sens, rclass
    version 15.0
    syntax varlist(min=2 max=2 numeric) [if] [in] [, LSNRgrid(numlist) LEKCgrid(numlist) ///
        LSNR(real 1e6) LEKC(real 1e6) MAXIter(integer 10000) *]
    if "`lsnrgrid'" == "" local lsnrgrid "0 1e2 1e4 1e6 1e8 1e10"
    if "`lekcgrid'" == "" local lekcgrid "0 1e3 1e6"
    tempname hold
    _estimates hold `hold', restore nullok
    foreach tab in snr ekc {
        if "`tab'" == "snr" local grid "`lsnrgrid'"
        else local grid "`lekcgrid'"
        local nc : word count `grid'
        tempname S
        matrix `S' = J(12, `nc', .)
        local j 0
        foreach v of local grid {
            local ++j
            if "`tab'" == "snr" {
                local ls = `v'
                local le = `lekc'
            }
            else {
                local ls = `lsnr'
                local le = `v'
            }
            qui _xtdosekc_est `varlist' `if' `in', model(dynamic) lsnr(`ls') lekc(`le') ///
                maxiter(`maxiter') notable nodiag dfm(0) `options'
            tempname T
            matrix `T' = e(table)
            local R = ("`e(shift)'" != "")
            matrix `S'[1, `j'] = `ls'
            matrix `S'[2, `j'] = `le'
            matrix `S'[3, `j'] = _b[gamma]
            matrix `S'[4, `j'] = _b[c1]
            matrix `S'[5, `j'] = _b[c2]
            if `R' matrix `S'[6, `j'] = _b[c2_shift]
            matrix `S'[7, `j'] = 2 * ln(_b[sig_eps])
            matrix `S'[8, `j'] = 2 * ln(_b[sig_eta])
            matrix `S'[9, `j'] = _b[sig_eta] / _b[sig_eps]
            matrix `S'[10, `j'] = e(ll_unpen)
            matrix `S'[11, `j'] = e(ll)
            matrix `S'[12, `j'] = e(converged)
        }
        matrix rownames `S' = lambda_snr lambda_ekc gamma c1 c2 c2_shift log_s2eps log_s2eta q_ratio ll ll_pen converged
        if "`tab'" == "snr" {
            di _n as txt "{bf:Table S1. Sensitivity to the signal-to-noise penalty weight} (lambda_ekc = " `lekc' ")"
        }
        else {
            di _n as txt "{bf:Table S2. Sensitivity to the amplitude penalty weight} (lambda_snr = " `lsnr' ")"
        }
        local w = 14 + 11 * `nc'
        di as txt "{hline `w'}"
        di as txt %14s "" _c
        forvalues j = 1/`nc' {
            di as txt %11s "(`j')" _c
        }
        di ""
        local rl `""lambda_snr" "lambda_ekc" "gamma" "c1" "c2" "c2 (shift)" "log s2_eps" "log s2_eta" "q-ratio" "Log-lik" "Log-lik (pen)" "converged""'
        forvalues r = 1/12 {
            local lb : word `r' of `rl'
            di as txt %14s "`lb'" _c
            forvalues j = 1/`nc' {
                if `r' <= 2 di as res %11.0g `S'[`r', `j'] _c
                else if `r' == 12 di as res %11.0f `S'[`r', `j'] _c
                else if `r' >= 10 di as res %11.2f `S'[`r', `j'] _c
                else _xd_cell `S'[`r',`j'] 3 11
            }
            di ""
        }
        di as txt "{hline `w'}"
        return matrix `tab' = `S'
    }
end

* =====================================================================
*  Baseline comparison (Online Appendix S2.1, Tables S3-S5)
* =====================================================================
program define _xtdosekc_compare, rclass
    version 15.0
    syntax varlist(min=2 max=2 numeric) [if] [in] [, FEFrom(name) TRENDFrom(name) SHift(varname) *]
    tempname hold P DG
    _estimates hold `hold', restore nullok
    matrix `P' = J(7, 3, .)
    matrix `DG' = J(5, 3, .)
    local j 0
    foreach mdl in static trend dynamic {
        local ++j
        local fr ""
        if "`mdl'" == "static" & "`fefrom'" != "" local fr "from(`fefrom')"
        if "`mdl'" == "trend" & "`trendfrom'" != "" local fr "from(`trendfrom')"
        local sh ""
        if "`mdl'" == "dynamic" & "`shift'" != "" local sh "shift(`shift')"
        qui _xtdosekc_est `varlist' `if' `in', model(`mdl') `fr' `sh' notable dfm(0) `options'
        matrix `P'[1, `j'] = _b[gamma]
        matrix `P'[2, `j'] = _b[c1]
        matrix `P'[3, `j'] = _b[c2]
        matrix `P'[4, `j'] = _b[s1]
        matrix `P'[5, `j'] = _b[s2]
        matrix `P'[6, `j'] = e(ll)
        matrix `P'[7, `j'] = e(N)
        tempname D
        matrix `D' = e(diag)
        local n = rowsof(`D')
        local ar 0
        local lb 0
        local sa 0
        forvalues i = 1/`n' {
            if `D'[`i', 6] < 0.05 local ++ar
            if `D'[`i', 4] >= 0.05 local ++lb
            local sa = `sa' + `D'[`i', 2]
        }
        matrix `DG'[1, `j'] = sqrt(e(ssr) / e(N))
        matrix `DG'[2, `j'] = `sa' / `n'
        matrix `DG'[3, `j'] = `ar'
        matrix `DG'[4, `j'] = `lb'
        matrix `DG'[5, `j'] = `n'
        if "`mdl'" == "static" local llfe = e(ll)
        if "`mdl'" == "trend" {
            local lldt = e(ll)
            tempname DL
            matrix `DL' = e(delta)
            local un "`e(units)'"
        }
    }
    matrix rownames `P' = gamma c1 c2 s1 s2 loglik N
    matrix colnames `P' = fixed_effects fe_linear_trends fe_stochastic_trends
    matrix rownames `DG' = rmse mean_acf1 adf_rejections lb_nonrejections units
    matrix colnames `DG' = fixed_effects fe_linear_trends fe_stochastic_trends
    local N = `DG'[5, 1]
    local lr = 2 * (`lldt' - `llfe')
    local lrp = chi2tail(`N', `lr')
    di _n as txt "{bf:Table S3. Structural parameters under alternative treatments of the country baseline}"
    di as txt "{hline 16}{c TT}{hline 48}"
    di as txt %15s "" " {c |}" %16s "Fixed effects" %16s "+ Linear trends" %16s "+ Stoch. trends"
    di as txt "{hline 16}{c +}{hline 48}"
    local rl "gamma c1 c2 s1 s2"
    forvalues r = 1/5 {
        local lb : word `r' of `rl'
        di as txt %15s "`lb'" " {c |}" as res %16.3f `P'[`r',1] %16.3f `P'[`r',2] %16.3f `P'[`r',3]
    }
    di as txt %15s "Log-likelihood" " {c |}" as res %16.2f `P'[6,1] %16.2f `P'[6,2] %16.2f `P'[6,3]
    di as txt "{hline 16}{c BT}{hline 48}"
    di as txt "LR test, linear trends vs fixed effects: chi2(" as res `N' as txt ") = " as res %9.2f `lr' ///
       as txt "  p = " as res %6.4f `lrp'
    di as txt "Dynamic column: penalised log-likelihood of the stochastic-trend model."
    di _n as txt "{bf:Table S5. Residual diagnostics under alternative treatments of the baseline}"
    di as txt "{hline 26}{c TT}{hline 48}"
    di as txt %25s "" " {c |}" %16s "Fixed effects" %16s "+ Linear trends" %16s "+ Stoch. trends"
    di as txt "{hline 26}{c +}{hline 48}"
    di as txt %25s "RMSE" " {c |}" as res %16.4f `DG'[1,1] %16.4f `DG'[1,2] %16.4f `DG'[1,3]
    di as txt %25s "Mean ACF(1)" " {c |}" as res %16.3f `DG'[2,1] %16.3f `DG'[2,2] %16.3f `DG'[2,3]
    di as txt %25s "ADF rejections" " {c |}" as res %16s "`=`DG'[3,1]'/`N'" %16s "`=`DG'[3,2]'/`N'" %16s "`=`DG'[3,3]'/`N'"
    di as txt %25s "Ljung-Box non-rejections" " {c |}" as res %16s "`=`DG'[4,1]'/`N'" %16s "`=`DG'[4,2]'/`N'" %16s "`=`DG'[4,3]'/`N'"
    di as txt "{hline 26}{c BT}{hline 48}"
    di _n as txt "{bf:Table S4. Country-specific deterministic trend slopes (delta_i)}"
    forvalues i = 1/`=rowsof(`DL')' {
        local lb : word `i' of `un'
        di as txt %16s abbrev(subinstr("`lb'", "_", " ", .), 16) " " as res %9.4f `DL'[`i', 1] _c
        if mod(`i', 3) == 0 di ""
    }
    di ""
    return matrix params = `P'
    return matrix diag = `DG'
    return matrix delta = `DL'
    return scalar lr = `lr'
    return scalar lr_p = `lrp'
    return scalar lr_df = `N'
end

* =====================================================================
*  Integration properties (Online Appendix, Tables S6-S7)
* =====================================================================
program define _xtdosekc_integ, rclass sortpreserve
    version 15.0
    syntax varlist(min=1 numeric) [if] [in] [, Lags(integer 0) DLags(integer 0) ///
        PLags(integer 4) NOPANEL IDLabel(varname)]
    capture xtset
    if _rc {
        di as err "data must be {bf:xtset}"
        exit 459
    }
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    marksample touse
    sort `ivar' `tvar'
    qui levelsof `ivar' if `touse', local(ids)
    local nv : word count `varlist'
    local N : word count `ids'
    tempname U
    matrix `U' = J(`N', 2 * `nv' + 2, .)
    local i 0
    local rn ""
    foreach u of local ids {
        local ++i
        if "`idlabel'" != "" {
            qui count if `ivar' < `u'
            local o = r(N) + 1
            capture confirm string variable `idlabel'
            if !_rc local lb = `idlabel'[`o']
            else local lb : label (`idlabel') `=`idlabel'[`o']'
        }
        else local lb : label (`ivar') `u'
        local rn "`rn' `=strtoname("`lb'", 0)'"
        local k 0
        foreach v of local varlist {
            local ++k
            qui dfuller `v' if `touse' & `ivar' == `u', trend lags(`lags')
            matrix `U'[`i', 2 * `k' - 1] = r(p)
            qui dfuller D.`v' if `touse' & `ivar' == `u', lags(`dlags')
            matrix `U'[`i', 2 * `k'] = r(p)
        }
        if `nv' >= 2 {
            gettoken v1 rest : varlist
            gettoken v2 : rest
            tempvar e
            qui regress `v1' `v2' if `touse' & `ivar' == `u'
            local TT = e(N)
            qui predict double `e' if e(sample), resid
            qui dfuller `e' if `touse' & `ivar' == `u', noconstant lags(`lags')
            matrix `U'[`i', 2 * `nv' + 1] = r(Zt)
            local cv5 = -3.33613 - 6.1101 / `TT' - 6.823 / `TT'^2
            matrix `U'[`i', 2 * `nv' + 2] = `cv5'
            drop `e'
        }
    }
    matrix rownames `U' = `rn'
    di _n as txt "{bf:Table S6. Univariate integration and cointegration tests} (ADF p-values, MacKinnon)"
    local w = 16 + 22 * `nv' + cond(`nv' >= 2, 20, 0)
    di as txt "{hline `w'}"
    di as txt %16s "Unit" _c
    foreach v of local varlist {
        di as txt %11s abbrev("`v'", 9) " lev" %7s "diff" _c
    }
    if `nv' >= 2 di as txt %12s "EG stat" _c
    di ""
    di as txt "{hline `w'}"
    forvalues i = 1/`N' {
        local lb : word `i' of `rn'
        di as txt %16s abbrev(subinstr("`lb'", "_", " ", .), 16) _c
        forvalues k = 1/`nv' {
            foreach c in `=2*`k'-1' `=2*`k'' {
                local p = `U'[`i', `c']
                local s = cond(`p' <= 0.05, "**", "  ")
                di as res %9.4f `p' as txt "`s'" _c
            }
        }
        if `nv' >= 2 {
            local z = `U'[`i', 2 * `nv' + 1]
            local s ""
            if `z' < `U'[`i', 2 * `nv' + 2] local s "**"
            di as res %12.3f `z' as txt "`s'" _c
        }
        di ""
    }
    di as txt "{hline `w'}"
    di as txt "Levels: constant + trend, lags(`lags'); differences: constant, lags(`dlags')."
    if `nv' >= 2 di as txt "EG: DF t on residuals of `v1' on `v2' (with constant); ** beyond MacKinnon (2010) 5% critical value."
    return matrix univariate = `U'
    if "`nopanel'" == "" {
        di _n as txt "{bf:Table S7. Panel cross-sectional dependence and unit-root tests}"
        di as txt "{hline 66}"
        di as txt %14s "Variable" %13s "CD stat" %9s "p" %11s "LLC t*" %9s "p" %10s "IPS W" %9s "p" _c
        di ""
        di as txt "{hline 66}"
        tempname PT
        matrix `PT' = J(`nv', 6, .)
        local k 0
        foreach v of local varlist {
            local ++k
            qui count if `touse'
            local TT = r(N) / `N'
            mata: st_matrix("__xd_cd", dos_cd(colshape(st_data(., "`v'", "`touse'"), `TT')'))
            matrix `PT'[`k', 1] = __xd_cd[1, 1]
            matrix `PT'[`k', 2] = __xd_cd[1, 2]
            capture qui xtunitroot llc `v' if `touse', trend lags(aic `plags')
            if !_rc {
                matrix `PT'[`k', 3] = r(tds)
                matrix `PT'[`k', 4] = r(p_tds)
            }
            capture qui xtunitroot ips `v' if `touse', trend lags(aic `plags')
            if !_rc {
                matrix `PT'[`k', 5] = r(wtbar)
                matrix `PT'[`k', 6] = r(p_wtbar)
            }
            di as txt %14s abbrev("`v'", 14) _c
            forvalues c = 1/6 {
                local f "%9.4f"
                if mod(`c', 2) == 1 local f "%11.3f"
                if missing(`PT'[`k', `c']) di as txt %10s "--" _c
                else di as res `f' `PT'[`k', `c'] _c
            }
            di ""
        }
        di as txt "{hline 66}"
        di as txt "CD: Pesaran (2004). LLC (bias-adjusted t*) and IPS (W-t-bar): trend, lags(aic `plags')."
        di as txt "For CIPS (Pesaran 2007) see the SSC commands {bf:xtcips} or {bf:multipurt}."
        _xd_cleanup
        matrix colnames `PT' = cd cd_p llc llc_p ips ips_p
        return matrix panel = `PT'
    }
end

* =====================================================================
*  DoS illustration (Figure 1)
* =====================================================================
program define _xtdosekc_illus, rclass
    version 15.0
    syntax [, C1(real 2.5) S1(real 1.5) C2(real 8) S2(real 3) GAMma(real 1) ///
        RANGE(numlist min=2 max=2 ascending) NPoints(integer 300) GNAME(string) GEXPort(string)]
    if "`range'" == "" local range "0 10"
    gettoken lo hi : range
    if "`gname'" == "" local gname "xtdosekc_illus"
    mata: dos_illus(`gamma', `c1', `s1', `c2', `s2', `lo', `hi', `npoints')
    local tp = __xd_tp
    local pk = __xd_peak
    tempname G
    matrix `G' = __xd_illus
    preserve
    qui clear
    qui svmat double `G', name(__i)
    local gopt "graphregion(color(white)) plotregion(lcolor(gs10)) ylabel(none) xlabel(none) xtitle("") ytitle("")"
    twoway line __i2 __i1, lcolor(black) lwidth(thick) `gopt' title("Economic growth: {&sigma}{sub:1}", size(medsmall)) name(__xi1, replace) nodraw
    twoway line __i3 __i1, lcolor(black) lwidth(thick) `gopt' title("Green transition: {&sigma}{sub:2}", size(medsmall)) name(__xi2, replace) nodraw
    twoway line __i4 __i1, lcolor(black) lwidth(thick) `gopt' xline(`tp', lpattern(dash) lcolor(black)) ///
        title("DoS: {&gamma}({&sigma}{sub:1} - {&sigma}{sub:2})", size(medsmall)) name(__xi3, replace) nodraw
    graph combine __xi1 __xi2 __xi3, rows(1) graphregion(color(white)) ysize(2.2) xsize(7) ///
        b1title("Economic development (e.g. log GDP per capita)", size(small)) ///
        l1title("Emissions effect", size(small)) name(`gname', replace)
    graph drop __xi1 __xi2 __xi3
    if "`gexport'" != "" capture graph export "`gname'.`gexport'", name(`gname') replace
    restore
    di as txt "DoS turning point: x* = " as res %8.4f `tp' as txt "   peak = " as res %8.4f `pk' ///
       as txt "   (c1 = `c1', s1 = `s1', c2 = `c2', s2 = `s2', gamma = `gamma')"
    _xd_cleanup
    return scalar xstar = `tp'
    return scalar peak = `pk'
end

mata:

// =====================================================================
//  xtdosekc Mata engine
//  Difference-of-sigmoids (DoS) EKC with country stochastic trends
//  Amoroso, Garcia-Martos and Koopman (2026), Econometrics Journal
// =====================================================================

struct dos_data {
    real matrix Y
    real matrix X
    real scalar model
    real scalar regional
    real rowvector eur
    real scalar lsnr
    real scalar lekc
    real scalar snr
    real scalar gpen
    real colvector tt
    real scalar nfev
    real scalar trace
    real rowvector trf
}

struct dos_lb {
    real scalar m
    real scalar col
    real scalar head
    real scalar itail
    real scalar iupdat
    real scalar updatd
    real scalar theta
    real matrix ws
    real matrix wy
    real matrix sy
    real matrix ss
    real matrix wt
    real matrix wn
    real matrix snd
}

struct dos_ls {
    real scalar brackt
    real scalar stage
    real scalar ginit
    real scalar gtest
    real scalar gx
    real scalar gy
    real scalar finit
    real scalar fx
    real scalar fy
    real scalar stx
    real scalar sty
    real scalar stmin
    real scalar stmax
    real scalar width
    real scalar width1
    string scalar task
}

// ---------------------------------------------------------------------
//  Model pieces: eq. (2.2) logistic, eq. (2.1) DoS curve
// ---------------------------------------------------------------------
real matrix dos_curve(real matrix X, real scalar g, real scalar c1,
                      real rowvector c2, real scalar s1, real scalar s2)
{
    return(g :* (1 :/ (1 :+ exp(-s1 :* (X :- c1))) - 1 :/ (1 :+ exp(-s2 :* (X :- c2)))))
}

// exact-diffuse local-level log-likelihood, eq. (3.9); t = 1 is the diffuse step
real scalar dos_llf(real matrix Z, real scalar se2, real scalar sn2)
{
    real scalar T, N, t, P, F, K, ll
    real rowvector a, v
    T = rows(Z)
    N = cols(Z)
    a = Z[1, .]
    P = se2 + sn2
    ll = 0
    for (t = 2; t <= T; t++) {
        v = Z[t, .] - a
        F = P + se2
        K = P / F
        ll = ll - 0.5 * (N * (ln(2 * pi()) + ln(F)) + quadsum(v :* v) / F)
        a = a + K :* v
        P = P * (1 - K) + sn2
    }
    return(ll)
}

// unpack dynamic parameters -> natural ones
void dos_unpack(struct dos_data scalar D, real rowvector p, real scalar g,
                real scalar c1, real scalar c2, real scalar sh, real scalar s1,
                real scalar s2, real scalar se, real scalar sn)
{
    g = p[1]
    c1 = p[2]
    c2 = p[3]
    if (D.regional) {
        sh = p[4]
        s1 = p[5]
        s2 = p[6]
        se = exp(p[7])
        sn = exp(p[8])
    }
    else {
        sh = 0
        s1 = p[4]
        s2 = p[5]
        se = exp(p[6])
        sn = exp(p[7])
    }
}

real rowvector dos_c2row(struct dos_data scalar D, real scalar c2, real scalar sh)
{
    return(c2 :+ sh :* D.eur)
}

// penalised negative profile log-likelihood S_v(psi), eqs (3.3)-(3.11)
real scalar dos_obj_dyn(struct dos_data scalar D, real rowvector p)
{
    real scalar g, c1, c2, sh, s1, s2, se, sn, ll, pen
    real matrix U
    dos_unpack(D, p, g, c1, c2, sh, s1, s2, se, sn)
    if (c1 >= c2) return(1e10)
    if (D.regional) {
        if (c1 >= c2 + sh) return(1e10)
    }
    U = D.Y - dos_curve(D.X, g, c1, dos_c2row(D, c2, sh), s1, s2)
    U = U :- mean(U)
    ll = dos_llf(U, se * se, sn * sn)
    pen = 0
    if (sn > se * D.snr) pen = pen + D.lsnr * (sn - se * D.snr)^2
    if (g < D.gpen) pen = pen + D.lekc * (D.gpen - g)^2
    return(-ll + pen)
}

// static models: SSR objective, eq. (3.2) (R parameterisation c2 = c1 + diff + 1e-3)
real scalar dos_obj_ssr(struct dos_data scalar D, real rowvector p)
{
    real scalar N, k, g, c1, c2, s1, s2
    real rowvector mu, de
    real matrix E
    N = cols(D.Y)
    if (D.model == 4) {
        mu = p[|1 \ N|]
        de = p[|N + 1 \ 2 * N|]
        k = 2 * N
    }
    else {
        mu = p[|1 \ N|]
        de = J(1, N, 0)
        k = N
    }
    g  = p[k + 1]
    c1 = p[k + 2]
    c2 = p[k + 2] + p[k + 3] + 1e-3
    s1 = p[k + 4]
    s2 = p[k + 5]
    // NB: Mata parses  a :- b - c  as  a :- (b - c); keep explicit brackets
    E = (D.Y :- mu) - (D.tt * de) - dos_curve(D.X, g, c1, J(1, N, c2), s1, s2)
    return(quadsum(E :* E))
}

real scalar dos_obj(struct dos_data scalar D, real rowvector p)
{
    D.nfev = D.nfev + 1
    if (D.model == 1) return(dos_obj_dyn(D, p))
    return(dos_obj_ssr(D, p))
}

// R optim() central finite differences, honouring the box (optim.c fmingr)
real rowvector dos_grad(struct dos_data scalar D, real rowvector x,
                        real rowvector l, real rowvector u, real scalar ndeps)
{
    real scalar n, i, eps, epsused, tmp, v1, v2
    real rowvector g, xx
    n = cols(x)
    g = J(1, n, 0)
    xx = x
    for (i = 1; i <= n; i++) {
        eps = ndeps
        epsused = ndeps
        tmp = x[i] + eps
        if (tmp > u[i]) {
            tmp = u[i]
            epsused = tmp - x[i]
        }
        xx[i] = tmp
        v1 = dos_obj(D, xx)
        tmp = x[i] - eps
        if (tmp < l[i]) {
            tmp = l[i]
            eps = x[i] - tmp
        }
        xx[i] = tmp
        v2 = dos_obj(D, xx)
        g[i] = (v1 - v2) / (epsused + eps)
        xx[i] = x[i]
    }
    return(g)
}

// ---------------------------------------------------------------------
//  L-BFGS-B (Byrd, Lu, Nocedal and Zhu 1995), port of R's lbfgsb.c (v2.3)
// ---------------------------------------------------------------------
real scalar dos_dpofa(real matrix A, real scalar off, real scalar n)
{
    real scalar j, k, i, s, t
    for (j = 1; j <= n; j++) {
        s = 0
        for (k = 1; k <= j - 1; k++) {
            t = A[off + k, off + j]
            for (i = 1; i <= k - 1; i++) {
                t = t - A[off + i, off + k] * A[off + i, off + j]
            }
            t = t / A[off + k, off + k]
            A[off + k, off + j] = t
            s = s + t * t
        }
        s = A[off + j, off + j] - s
        if (s <= 0) return(j)
        A[off + j, off + j] = sqrt(s)
    }
    return(0)
}

// job 1: solve T x = b (T upper);  job 11: solve T' x = b (T upper)
real scalar dos_dtrsl(real matrix T, real scalar n, real colvector b, real scalar job)
{
    real scalar i, j, jj, temp, s
    if (n < 1) return(0)
    for (i = 1; i <= n; i++) {
        if (T[i, i] == 0) return(i)
    }
    if (job == 1) {
        b[n] = b[n] / T[n, n]
        for (jj = 2; jj <= n; jj++) {
            j = n - jj + 1
            temp = -b[j + 1]
            for (i = 1; i <= j; i++) {
                b[i] = b[i] + temp * T[i, j + 1]
            }
            b[j] = b[j] / T[j, j]
        }
    }
    else {
        b[1] = b[1] / T[1, 1]
        for (j = 2; j <= n; j++) {
            s = 0
            for (i = 1; i <= j - 1; i++) {
                s = s + T[i, j] * b[i]
            }
            b[j] = (b[j] - s) / T[j, j]
        }
    }
    return(0)
}

real scalar dos_bmv(struct dos_lb scalar S, real colvector v, real colvector p)
{
    real scalar col, i, k, i2, sum, info
    real colvector b
    real matrix W
    col = S.col
    p = J(2 * S.m, 1, 0)
    if (col == 0) return(0)
    p[col + 1] = v[col + 1]
    for (i = 2; i <= col; i++) {
        i2 = col + i
        sum = 0
        for (k = 1; k <= i - 1; k++) {
            sum = sum + S.sy[i, k] * v[k] / S.sy[k, k]
        }
        p[i2] = v[i2] + sum
    }
    W = S.wt
    b = p[|col + 1 \ 2 * col|]
    info = dos_dtrsl(W, col, b, 11)
    if (info != 0) return(info)
    p[|col + 1 \ 2 * col|] = b
    for (i = 1; i <= col; i++) {
        p[i] = v[i] / sqrt(S.sy[i, i])
    }
    b = p[|col + 1 \ 2 * col|]
    info = dos_dtrsl(W, col, b, 1)
    if (info != 0) return(info)
    p[|col + 1 \ 2 * col|] = b
    for (i = 1; i <= col; i++) {
        p[i] = -p[i] / sqrt(S.sy[i, i])
    }
    for (i = 1; i <= col; i++) {
        sum = 0
        for (k = i + 1; k <= col; k++) {
            sum = sum + S.sy[k, i] * p[col + k] / S.sy[i, i]
        }
        p[i] = p[i] + sum
    }
    return(0)
}

void dos_hpsolb(real scalar n, real rowvector t, real rowvector iorder, real scalar iheap)
{
    real scalar k, i, j, ddum, indxin, out, indxou, go
    if (iheap == 0) {
        for (k = 2; k <= n; k++) {
            ddum = t[k]
            indxin = iorder[k]
            i = k
            go = 1
            while (go) {
                go = 0
                if (i > 1) {
                    j = floor(i / 2)
                    if (ddum < t[j]) {
                        t[i] = t[j]
                        iorder[i] = iorder[j]
                        i = j
                        go = 1
                    }
                }
            }
            t[i] = ddum
            iorder[i] = indxin
        }
    }
    if (n > 1) {
        i = 1
        out = t[1]
        indxou = iorder[1]
        ddum = t[n]
        indxin = iorder[n]
        go = 1
        while (go) {
            go = 0
            j = i + i
            if (j <= n - 1) {
                if (t[j + 1] < t[j]) j = j + 1
                if (t[j] < ddum) {
                    t[i] = t[j]
                    iorder[i] = iorder[j]
                    i = j
                    go = 1
                }
            }
        }
        t[i] = ddum
        iorder[i] = indxin
        t[n] = out
        iorder[n] = indxou
    }
}

real scalar dos_projgr(real rowvector x, real rowvector g, real rowvector l,
                       real rowvector u, real rowvector nbd)
{
    real scalar i, gi, s
    s = 0
    for (i = 1; i <= cols(x); i++) {
        gi = g[i]
        if (nbd[i] != 0) {
            if (gi < 0) {
                if (nbd[i] >= 2) {
                    if (x[i] - u[i] > gi) gi = x[i] - u[i]
                }
            }
            else {
                if (nbd[i] <= 2) {
                    if (x[i] - l[i] < gi) gi = x[i] - l[i]
                }
            }
        }
        if (abs(gi) > s) s = abs(gi)
    }
    return(s)
}

real scalar dos_cauchy(struct dos_lb scalar S, real rowvector x, real rowvector l,
    real rowvector u, real rowvector nbd, real rowvector g, real rowvector iorder,
    real rowvector iwhere, real rowvector t, real rowvector d, real rowvector xcp,
    real colvector c, real scalar nint, real scalar sbgnrm, real scalar epsmch)
{
    real scalar n, m, col, col2, bnded, nfree, nbreak, ibkmin, bkmin, f1, f2, f2org
    real scalar i, j, neggi, tl, tu, xlower, xupper, pointr, dtm, tsum, nleft, it
    real scalar tj, tj0, ibp, dt, dibp, zibp, dibp2, wmc, wmp, wmw, info, found, allfix
    real colvector p, v, wbp
    n = cols(x)
    m = S.m
    col = S.col
    col2 = 2 * col
    if (sbgnrm <= 0) {
        xcp = x
        return(0)
    }
    bnded = 1
    nfree = n + 1
    nbreak = 0
    ibkmin = 0
    bkmin = 0
    f1 = 0
    tl = 0
    tu = 0
    p = J(2 * m, 1, 0)
    v = J(2 * m, 1, 0)
    wbp = J(2 * m, 1, 0)
    for (i = 1; i <= n; i++) {
        neggi = -g[i]
        if (iwhere[i] != 3 & iwhere[i] != -1) {
            if (nbd[i] <= 2) tl = x[i] - l[i]
            if (nbd[i] >= 2) tu = u[i] - x[i]
            xlower = (nbd[i] <= 2 & tl <= 0)
            xupper = (nbd[i] >= 2 & tu <= 0)
            iwhere[i] = 0
            if (xlower) {
                if (neggi <= 0) iwhere[i] = 1
            }
            else if (xupper) {
                if (neggi >= 0) iwhere[i] = 2
            }
            else {
                if (abs(neggi) <= 0) iwhere[i] = -3
            }
        }
        pointr = S.head
        if (iwhere[i] != 0 & iwhere[i] != -1) {
            d[i] = 0
        }
        else {
            d[i] = neggi
            f1 = f1 - neggi * neggi
            for (j = 1; j <= col; j++) {
                p[j] = p[j] + S.wy[i, pointr] * neggi
                p[col + j] = p[col + j] + S.ws[i, pointr] * neggi
                pointr = mod(pointr, m) + 1
            }
            if (nbd[i] <= 2 & nbd[i] != 0 & neggi < 0) {
                nbreak = nbreak + 1
                iorder[nbreak] = i
                t[nbreak] = tl / (-neggi)
                if (nbreak == 1 | t[nbreak] < bkmin) {
                    bkmin = t[nbreak]
                    ibkmin = nbreak
                }
            }
            else if (nbd[i] >= 2 & neggi > 0) {
                nbreak = nbreak + 1
                iorder[nbreak] = i
                t[nbreak] = tu / neggi
                if (nbreak == 1 | t[nbreak] < bkmin) {
                    bkmin = t[nbreak]
                    ibkmin = nbreak
                }
            }
            else {
                nfree = nfree - 1
                iorder[nfree] = i
                if (abs(neggi) > 0) bnded = 0
            }
        }
    }
    if (S.theta != 1 & col > 0) {
        p[|col + 1 \ col2|] = S.theta :* p[|col + 1 \ col2|]
    }
    xcp = x
    if (nbreak == 0 & nfree == n + 1) return(0)
    c = J(2 * m, 1, 0)
    f2 = -S.theta * f1
    f2org = f2
    if (col > 0) {
        info = dos_bmv(S, p, v)
        if (info != 0) return(info)
        f2 = f2 - quadsum(v[|1 \ col2|] :* p[|1 \ col2|])
    }
    dtm = -f1 / f2
    tsum = 0
    nint = 1
    allfix = 0
    if (nbreak > 0) {
        nleft = nbreak
        it = 1
        tj = 0
        found = 0
        while (found == 0) {
            tj0 = tj
            if (it == 1) {
                tj = bkmin
                ibp = iorder[ibkmin]
            }
            else {
                if (it == 2) {
                    if (ibkmin != nbreak) {
                        t[ibkmin] = t[nbreak]
                        iorder[ibkmin] = iorder[nbreak]
                    }
                }
                dos_hpsolb(nleft, t, iorder, it - 2)
                tj = t[nleft]
                ibp = iorder[nleft]
            }
            dt = tj - tj0
            if (dtm < dt) {
                found = 1
                break
            }
            tsum = tsum + dt
            nleft = nleft - 1
            it = it + 1
            dibp = d[ibp]
            d[ibp] = 0
            if (dibp > 0) {
                zibp = u[ibp] - x[ibp]
                xcp[ibp] = u[ibp]
                iwhere[ibp] = 2
            }
            else {
                zibp = l[ibp] - x[ibp]
                xcp[ibp] = l[ibp]
                iwhere[ibp] = 1
            }
            if (nleft == 0 & nbreak == n) {
                dtm = dt
                allfix = 1
                break
            }
            nint = nint + 1
            dibp2 = dibp * dibp
            f1 = f1 + dt * f2 + dibp2 - S.theta * dibp * zibp
            f2 = f2 - S.theta * dibp2
            if (col > 0) {
                c[|1 \ col2|] = c[|1 \ col2|] + dt :* p[|1 \ col2|]
                pointr = S.head
                for (j = 1; j <= col; j++) {
                    wbp[j] = S.wy[ibp, pointr]
                    wbp[col + j] = S.theta * S.ws[ibp, pointr]
                    pointr = mod(pointr, m) + 1
                }
                info = dos_bmv(S, wbp, v)
                if (info != 0) return(info)
                wmc = quadsum(c[|1 \ col2|] :* v[|1 \ col2|])
                wmp = quadsum(p[|1 \ col2|] :* v[|1 \ col2|])
                wmw = quadsum(wbp[|1 \ col2|] :* v[|1 \ col2|])
                p[|1 \ col2|] = p[|1 \ col2|] - dibp :* wbp[|1 \ col2|]
                f1 = f1 + dibp * wmc
                f2 = f2 + 2 * dibp * wmp - dibp2 * wmw
            }
            if (epsmch * f2org > f2) f2 = epsmch * f2org
            if (nleft > 0) {
                dtm = -f1 / f2
            }
            else {
                if (bnded) {
                    f1 = 0
                    f2 = 0
                    dtm = 0
                }
                else {
                    dtm = -f1 / f2
                }
                found = 1
            }
        }
    }
    if (allfix == 0) {
        if (dtm <= 0) dtm = 0
        tsum = tsum + dtm
        xcp = xcp + tsum :* d
    }
    if (col > 0) {
        c[|1 \ col2|] = c[|1 \ col2|] + dtm :* p[|1 \ col2|]
    }
    return(0)
}

void dos_freev(real scalar n, real scalar nfree, real rowvector index,
    real scalar nenter, real scalar ileave, real rowvector indx2,
    real rowvector iwhere, real scalar wrk, real scalar updatd,
    real scalar cnstnd, real scalar iter)
{
    real scalar i, k, iact
    nenter = 0
    ileave = n + 1
    if (iter > 0 & cnstnd) {
        for (i = 1; i <= nfree; i++) {
            k = index[i]
            if (iwhere[k] > 0) {
                ileave = ileave - 1
                indx2[ileave] = k
            }
        }
        for (i = 1 + nfree; i <= n; i++) {
            k = index[i]
            if (iwhere[k] <= 0) {
                nenter = nenter + 1
                indx2[nenter] = k
            }
        }
    }
    wrk = (ileave < n + 1 | nenter > 0 | updatd)
    nfree = 0
    iact = n + 1
    for (i = 1; i <= n; i++) {
        if (iwhere[i] <= 0) {
            nfree = nfree + 1
            index[nfree] = i
        }
        else {
            iact = iact - 1
            index[iact] = i
        }
    }
}

real scalar dos_formk(struct dos_lb scalar S, real scalar n, real scalar nsub,
    real rowvector ind, real scalar nenter, real scalar ileave,
    real rowvector indx2, real scalar updatd)
{
    real scalar m, col, head, jy, js, q, pbegin, pend, dbegin, dend, iy, is, ipntr, jpntr
    real scalar temp1, temp2, temp3, temp4, k, k1, i, upcl, is1, js1, col2, info
    real matrix W1, W
    real colvector b
    m = S.m
    col = S.col
    head = S.head
    W1 = S.snd
    W = S.wn
    if (updatd) {
        if (S.iupdat > m) {
            for (jy = 1; jy <= m - 1; jy++) {
                js = m + jy
                for (q = 0; q < m - jy; q++) {
                    W1[jy + q, jy] = W1[jy + 1 + q, jy + 1]
                }
                for (q = 0; q < m - jy; q++) {
                    W1[js + q, js] = W1[js + 1 + q, js + 1]
                }
                for (q = 0; q < m - 1; q++) {
                    W1[m + 1 + q, jy] = W1[m + 2 + q, jy + 1]
                }
            }
        }
        pbegin = 1
        pend = nsub
        dbegin = nsub + 1
        dend = n
        iy = col
        is = m + col
        ipntr = head + col - 1
        if (ipntr > m) ipntr = ipntr - m
        jpntr = head
        for (jy = 1; jy <= col; jy++) {
            js = m + jy
            temp1 = 0
            temp2 = 0
            temp3 = 0
            for (k = pbegin; k <= pend; k++) {
                k1 = ind[k]
                temp1 = temp1 + S.wy[k1, ipntr] * S.wy[k1, jpntr]
            }
            for (k = dbegin; k <= dend; k++) {
                k1 = ind[k]
                temp2 = temp2 + S.ws[k1, ipntr] * S.ws[k1, jpntr]
                temp3 = temp3 + S.ws[k1, ipntr] * S.wy[k1, jpntr]
            }
            W1[iy, jy] = temp1
            W1[is, js] = temp2
            W1[is, jy] = temp3
            jpntr = mod(jpntr, m) + 1
        }
        jy = col
        jpntr = head + col - 1
        if (jpntr > m) jpntr = jpntr - m
        ipntr = head
        for (i = 1; i <= col; i++) {
            is = m + i
            temp3 = 0
            for (k = pbegin; k <= pend; k++) {
                k1 = ind[k]
                temp3 = temp3 + S.ws[k1, ipntr] * S.wy[k1, jpntr]
            }
            ipntr = mod(ipntr, m) + 1
            W1[is, jy] = temp3
        }
        upcl = col - 1
    }
    else {
        upcl = col
    }
    ipntr = head
    for (iy = 1; iy <= upcl; iy++) {
        is = m + iy
        jpntr = head
        for (jy = 1; jy <= iy; jy++) {
            js = m + jy
            temp1 = 0
            temp2 = 0
            temp3 = 0
            temp4 = 0
            for (k = 1; k <= nenter; k++) {
                k1 = indx2[k]
                temp1 = temp1 + S.wy[k1, ipntr] * S.wy[k1, jpntr]
                temp2 = temp2 + S.ws[k1, ipntr] * S.ws[k1, jpntr]
            }
            for (k = ileave; k <= n; k++) {
                k1 = indx2[k]
                temp3 = temp3 + S.wy[k1, ipntr] * S.wy[k1, jpntr]
                temp4 = temp4 + S.ws[k1, ipntr] * S.ws[k1, jpntr]
            }
            W1[iy, jy] = W1[iy, jy] + temp1 - temp3
            W1[is, js] = W1[is, js] - temp2 + temp4
            jpntr = mod(jpntr, m) + 1
        }
        ipntr = mod(ipntr, m) + 1
    }
    ipntr = head
    for (is = m + 1; is <= m + upcl; is++) {
        jpntr = head
        for (jy = 1; jy <= upcl; jy++) {
            temp1 = 0
            temp3 = 0
            for (k = 1; k <= nenter; k++) {
                k1 = indx2[k]
                temp1 = temp1 + S.ws[k1, ipntr] * S.wy[k1, jpntr]
            }
            for (k = ileave; k <= n; k++) {
                k1 = indx2[k]
                temp3 = temp3 + S.ws[k1, ipntr] * S.wy[k1, jpntr]
            }
            if (is <= jy + m) {
                W1[is, jy] = W1[is, jy] + temp1 - temp3
            }
            else {
                W1[is, jy] = W1[is, jy] - temp1 + temp3
            }
            jpntr = mod(jpntr, m) + 1
        }
        ipntr = mod(ipntr, m) + 1
    }
    for (iy = 1; iy <= col; iy++) {
        is = col + iy
        is1 = m + iy
        for (jy = 1; jy <= iy; jy++) {
            js = col + jy
            js1 = m + jy
            W[jy, iy] = W1[iy, jy] / S.theta
            W[js, is] = W1[is1, js1] * S.theta
        }
        for (jy = 1; jy <= iy - 1; jy++) {
            W[jy, is] = -W1[is1, jy]
        }
        for (jy = iy; jy <= col; jy++) {
            W[jy, is] = W1[is1, jy]
        }
        W[iy, iy] = W[iy, iy] + S.sy[iy, iy]
    }
    S.snd = W1
    info = dos_dpofa(W, 0, col)
    if (info != 0) {
        S.wn = W
        return(-1)
    }
    col2 = 2 * col
    for (js = col + 1; js <= col2; js++) {
        b = W[|1, js \ col, js|]
        info = dos_dtrsl(W, col, b, 11)
        W[|1, js \ col, js|] = b
    }
    for (is = col + 1; is <= col2; is++) {
        for (js = is; js <= col2; js++) {
            W[is, js] = W[is, js] + quadsum(W[|1, is \ col, is|] :* W[|1, js \ col, js|])
        }
    }
    info = dos_dpofa(W, col, col)
    S.wn = W
    if (info != 0) return(-2)
    return(0)
}

real scalar dos_cmprlb(struct dos_lb scalar S, real scalar n, real rowvector x,
    real rowvector g, real rowvector z, real rowvector r, real colvector c,
    real rowvector index, real scalar nfree, real scalar cnstnd)
{
    real scalar i, j, k, pointr, a1, a2, info, col, m
    real colvector wa
    col = S.col
    m = S.m
    if (cnstnd == 0 & col > 0) {
        r = -g
        return(0)
    }
    for (i = 1; i <= nfree; i++) {
        k = index[i]
        r[i] = -S.theta * (z[k] - x[k]) - g[k]
    }
    info = dos_bmv(S, c, wa)
    if (info != 0) return(-8)
    pointr = S.head
    for (j = 1; j <= col; j++) {
        a1 = wa[j]
        a2 = S.theta * wa[col + j]
        for (i = 1; i <= nfree; i++) {
            k = index[i]
            r[i] = r[i] + S.wy[k, pointr] * a1 + S.ws[k, pointr] * a2
        }
        pointr = mod(pointr, m) + 1
    }
    return(0)
}

real scalar dos_subsm(struct dos_lb scalar S, real scalar nsub, real rowvector ind,
    real rowvector l, real rowvector u, real rowvector nbd, real rowvector x,
    real rowvector d, real scalar iword)
{
    real scalar col, m, i, j, k, pointr, temp1, temp2, col2, info, jy, js
    real scalar alpha, dk, ibd
    real colvector wv
    real matrix W
    col = S.col
    m = S.m
    if (nsub <= 0) return(0)
    wv = J(2 * col, 1, 0)
    pointr = S.head
    for (i = 1; i <= col; i++) {
        temp1 = 0
        temp2 = 0
        for (j = 1; j <= nsub; j++) {
            k = ind[j]
            temp1 = temp1 + S.wy[k, pointr] * d[j]
            temp2 = temp2 + S.ws[k, pointr] * d[j]
        }
        wv[i] = temp1
        wv[col + i] = S.theta * temp2
        pointr = mod(pointr, m) + 1
    }
    col2 = 2 * col
    W = S.wn
    info = dos_dtrsl(W, col2, wv, 11)
    if (info != 0) return(info)
    for (i = 1; i <= col; i++) {
        wv[i] = -wv[i]
    }
    info = dos_dtrsl(W, col2, wv, 1)
    if (info != 0) return(info)
    pointr = S.head
    for (jy = 1; jy <= col; jy++) {
        js = col + jy
        for (i = 1; i <= nsub; i++) {
            k = ind[i]
            d[i] = d[i] + S.wy[k, pointr] * wv[jy] / S.theta + S.ws[k, pointr] * wv[js]
        }
        pointr = mod(pointr, m) + 1
    }
    for (i = 1; i <= nsub; i++) {
        d[i] = d[i] / S.theta
    }
    alpha = 1
    temp1 = alpha
    ibd = 0
    for (i = 1; i <= nsub; i++) {
        k = ind[i]
        dk = d[i]
        if (nbd[k] != 0) {
            if (dk < 0 & nbd[k] <= 2) {
                temp2 = l[k] - x[k]
                if (temp2 >= 0) {
                    temp1 = 0
                }
                else if (dk * alpha < temp2) {
                    temp1 = temp2 / dk
                }
            }
            else if (dk > 0 & nbd[k] >= 2) {
                temp2 = u[k] - x[k]
                if (temp2 <= 0) {
                    temp1 = 0
                }
                else if (dk * alpha > temp2) {
                    temp1 = temp2 / dk
                }
            }
            if (temp1 < alpha) {
                alpha = temp1
                ibd = i
            }
        }
    }
    if (alpha < 1) {
        dk = d[ibd]
        k = ind[ibd]
        if (dk > 0) {
            x[k] = u[k]
            d[ibd] = 0
        }
        else if (dk < 0) {
            x[k] = l[k]
            d[ibd] = 0
        }
    }
    for (i = 1; i <= nsub; i++) {
        k = ind[i]
        x[k] = x[k] + alpha * d[i]
    }
    iword = (alpha < 1)
    return(0)
}

void dos_matupd(struct dos_lb scalar S, real rowvector d, real rowvector r,
    real scalar rr, real scalar dr, real scalar stp, real scalar dtd)
{
    real scalar m, j, q, pointr, col
    m = S.m
    if (S.iupdat <= m) {
        S.col = S.iupdat
        S.itail = mod(S.head + S.iupdat - 2, m) + 1
    }
    else {
        S.itail = mod(S.itail, m) + 1
        S.head = mod(S.head, m) + 1
    }
    S.ws[., S.itail] = d'
    S.wy[., S.itail] = r'
    S.theta = rr / dr
    col = S.col
    if (S.iupdat > m) {
        for (j = 1; j <= col - 1; j++) {
            for (q = 1; q <= j; q++) {
                S.ss[q, j] = S.ss[q + 1, j + 1]
            }
            for (q = 0; q < col - j; q++) {
                S.sy[j + q, j] = S.sy[j + 1 + q, j + 1]
            }
        }
    }
    pointr = S.head
    for (j = 1; j <= col - 1; j++) {
        S.sy[col, j] = quadsum(d' :* S.wy[., pointr])
        S.ss[j, col] = quadsum(S.ws[., pointr] :* d')
        pointr = mod(pointr, m) + 1
    }
    if (stp == 1) {
        S.ss[col, col] = dtd
    }
    else {
        S.ss[col, col] = stp * stp * dtd
    }
    S.sy[col, col] = dr
}

real scalar dos_formt(struct dos_lb scalar S)
{
    real scalar col, i, j, k, k1, ddum, info
    real matrix W
    col = S.col
    W = S.wt
    for (j = 1; j <= col; j++) {
        W[1, j] = S.theta * S.ss[1, j]
    }
    for (i = 2; i <= col; i++) {
        for (j = i; j <= col; j++) {
            k1 = min((i, j)) - 1
            ddum = 0
            for (k = 1; k <= k1; k++) {
                ddum = ddum + S.sy[i, k] * S.sy[j, k] / S.sy[k, k]
            }
            W[i, j] = ddum + S.theta * S.ss[i, j]
        }
    }
    info = dos_dpofa(W, 0, col)
    S.wt = W
    if (info != 0) return(-3)
    return(0)
}

void dos_dcstep(real scalar stx, real scalar fx, real scalar dx, real scalar sty,
    real scalar fy, real scalar dy, real scalar stp, real scalar fp, real scalar dp,
    real scalar brackt, real scalar stpmin, real scalar stpmax)
{
    real scalar sgnd, theta, s, gam, p, q, r, stpc, stpq, stpf
    sgnd = dp * (dx / abs(dx))
    if (fp > fx) {
        theta = 3 * (fx - fp) / (stp - stx) + dx + dp
        s = max((abs(theta), abs(dx), abs(dp)))
        gam = s * sqrt((theta / s)^2 - (dx / s) * (dp / s))
        if (stp < stx) gam = -gam
        p = (gam - dx) + theta
        q = ((gam - dx) + gam) + dp
        r = p / q
        stpc = stx + r * (stp - stx)
        stpq = stx + ((dx / ((fx - fp) / (stp - stx) + dx)) / 2) * (stp - stx)
        if (abs(stpc - stx) < abs(stpq - stx)) {
            stpf = stpc
        }
        else {
            stpf = stpc + (stpq - stpc) / 2
        }
        brackt = 1
    }
    else if (sgnd < 0) {
        theta = 3 * (fx - fp) / (stp - stx) + dx + dp
        s = max((abs(theta), abs(dx), abs(dp)))
        gam = s * sqrt((theta / s)^2 - (dx / s) * (dp / s))
        if (stp > stx) gam = -gam
        p = (gam - dp) + theta
        q = ((gam - dp) + gam) + dx
        r = p / q
        stpc = stp + r * (stx - stp)
        stpq = stp + (dp / (dp - dx)) * (stx - stp)
        if (abs(stpc - stp) > abs(stpq - stp)) {
            stpf = stpc
        }
        else {
            stpf = stpq
        }
        brackt = 1
    }
    else if (abs(dp) < abs(dx)) {
        theta = 3 * (fx - fp) / (stp - stx) + dx + dp
        s = max((abs(theta), abs(dx), abs(dp)))
        gam = (theta / s)^2 - (dx / s) * (dp / s)
        if (gam < 0) gam = 0
        gam = s * sqrt(gam)
        if (stp > stx) gam = -gam
        p = (gam - dp) + theta
        q = (gam + (dx - dp)) + gam
        r = p / q
        if (r < 0 & gam != 0) {
            stpc = stp + r * (stx - stp)
        }
        else if (stp > stx) {
            stpc = stpmax
        }
        else {
            stpc = stpmin
        }
        stpq = stp + (dp / (dp - dx)) * (stx - stp)
        if (brackt) {
            if (abs(stpc - stp) < abs(stpq - stp)) {
                stpf = stpc
            }
            else {
                stpf = stpq
            }
            if (stp > stx) {
                stpf = min((stp + 0.66 * (sty - stp), stpf))
            }
            else {
                stpf = max((stp + 0.66 * (sty - stp), stpf))
            }
        }
        else {
            if (abs(stpc - stp) > abs(stpq - stp)) {
                stpf = stpc
            }
            else {
                stpf = stpq
            }
            stpf = min((stpmax, stpf))
            stpf = max((stpmin, stpf))
        }
    }
    else {
        if (brackt) {
            theta = 3 * (fp - fy) / (sty - stp) + dy + dp
            s = max((abs(theta), abs(dy), abs(dp)))
            gam = s * sqrt((theta / s)^2 - (dy / s) * (dp / s))
            if (stp > sty) gam = -gam
            p = (gam - dp) + theta
            q = ((gam - dp) + gam) + dy
            r = p / q
            stpc = stp + r * (sty - stp)
            stpf = stpc
        }
        else if (stp > stx) {
            stpf = stpmax
        }
        else {
            stpf = stpmin
        }
    }
    if (fp > fx) {
        sty = stp
        fy = fp
        dy = dp
    }
    else {
        if (sgnd < 0) {
            sty = stx
            fy = fx
            dy = dx
        }
        stx = stp
        fx = fp
        dx = dp
    }
    stp = stpf
}

// More-Thuente line search (MINPACK-2 dcsrch), reverse communication
void dos_dcsrch(struct dos_ls scalar L, real scalar f, real scalar g, real scalar stp,
    real scalar ftol, real scalar gtol, real scalar xtol, real scalar stpmin,
    real scalar stpmax)
{
    real scalar ftest, fm, fxm, fym, gm, gxm, gym, xtrapl, xtrapu
    real scalar stx, fx, gx, sty, fy, gy, brackt, stmin, stmax
    xtrapl = 1.1
    xtrapu = 4
    if (L.task == "START") {
        if (stp < stpmin) {
            L.task = "ERROR"
            return
        }
        if (stp > stpmax) {
            L.task = "ERROR"
            return
        }
        if (g >= 0) {
            L.task = "ERROR"
            return
        }
        L.brackt = 0
        L.stage = 1
        L.finit = f
        L.ginit = g
        L.gtest = ftol * L.ginit
        L.width = stpmax - stpmin
        L.width1 = L.width / 0.5
        L.stx = 0
        L.fx = L.finit
        L.gx = L.ginit
        L.sty = 0
        L.fy = L.finit
        L.gy = L.ginit
        L.stmin = 0
        L.stmax = stp + xtrapu * stp
        L.task = "FG"
        return
    }
    ftest = L.finit + stp * L.gtest
    if (L.stage == 1 & f <= ftest & g >= 0) L.stage = 2
    if (L.brackt & (stp <= L.stmin | stp >= L.stmax)) L.task = "WARNING"
    if (L.brackt & L.stmax - L.stmin <= xtol * L.stmax) L.task = "WARNING"
    if (stp == stpmax & f <= ftest & g <= L.gtest) L.task = "WARNING"
    if (stp == stpmin & (f > ftest | g >= L.gtest)) L.task = "WARNING"
    if (f <= ftest & abs(g) <= gtol * (-L.ginit)) L.task = "CONVERGENCE"
    if (L.task == "WARNING" | L.task == "CONVERGENCE") return
    stx = L.stx
    fx = L.fx
    gx = L.gx
    sty = L.sty
    fy = L.fy
    gy = L.gy
    brackt = L.brackt
    stmin = L.stmin
    stmax = L.stmax
    if (L.stage == 1 & f <= fx & f > ftest) {
        fm = f - stp * L.gtest
        fxm = fx - stx * L.gtest
        fym = fy - sty * L.gtest
        gm = g - L.gtest
        gxm = gx - L.gtest
        gym = gy - L.gtest
        dos_dcstep(stx, fxm, gxm, sty, fym, gym, stp, fm, gm, brackt, stmin, stmax)
        fx = fxm + stx * L.gtest
        fy = fym + sty * L.gtest
        gx = gxm + L.gtest
        gy = gym + L.gtest
    }
    else {
        dos_dcstep(stx, fx, gx, sty, fy, gy, stp, f, g, brackt, stmin, stmax)
    }
    if (brackt) {
        if (abs(sty - stx) >= 0.66 * L.width1) stp = stx + 0.5 * (sty - stx)
        L.width1 = L.width
        L.width = abs(sty - stx)
    }
    if (brackt) {
        stmin = min((stx, sty))
        stmax = max((stx, sty))
    }
    else {
        stmin = stp + xtrapl * (stp - stx)
        stmax = stp + xtrapu * (stp - stx)
    }
    if (stp < stpmin) stp = stpmin
    if (stp > stpmax) stp = stpmax
    if ((brackt & (stp <= stmin | stp >= stmax)) | (brackt & stmax - stmin <= xtol * stmax)) stp = stx
    L.stx = stx
    L.fx = fx
    L.gx = gx
    L.sty = sty
    L.fy = fy
    L.gy = gy
    L.brackt = brackt
    L.stmin = stmin
    L.stmax = stmax
    L.task = "FG"
}

void dos_lbreset(struct dos_lb scalar S)
{
    S.col = 0
    S.head = 1
    S.theta = 1
    S.iupdat = 0
    S.updatd = 0
}

// driver: minimise dos_obj over the box [l,u]; returns x, sets f, fail, iter, nfg
//   fail = 0 converged, 1 maxit reached, 51 warning, 52 abnormal termination
real rowvector dos_lbfgsb(struct dos_data scalar D, real rowvector x0,
    real rowvector l, real rowvector u, real rowvector nbd, real scalar factr,
    real scalar maxit, real scalar m, real scalar ndeps, real scalar fout,
    real scalar fail, real scalar niter, real scalar nfg)
{
    struct dos_lb scalar S
    struct dos_ls scalar L
    real scalar n, i, epsmch, tol, iter, nfgv, nint, nfree, f, fold, sbgnrm, info
    real scalar iback, ifun, gd, gdold, stp, dtd, dnorm, stpmx, rr, dr, ddum
    real scalar cnstnd, boxed, wrk, nenter, ileave, iword, a1, a2, skipcp
    real scalar lsfail, newx, driter, outer
    real rowvector x, g, z, r, d, t, index, iwhere, indx2
    real colvector c

    n = cols(x0)
    x = x0
    epsmch = epsilon(1)
    tol = factr * epsmch
    S.m = m
    S.itail = 0
    dos_lbreset(S)
    S.ws = J(n, m, 0)
    S.wy = J(n, m, 0)
    S.sy = J(m, m, 0)
    S.ss = J(m, m, 0)
    S.wt = J(m, m, 0)
    S.wn = J(2 * m, 2 * m, 0)
    S.snd = J(2 * m, 2 * m, 0)
    z = J(1, n, 0)
    r = J(1, n, 0)
    d = J(1, n, 0)
    t = J(1, n, 0)
    c = J(2 * m, 1, 0)
    index = J(1, n, 0)
    iwhere = J(1, n, 0)
    indx2 = J(1, n, 0)
    iter = 0
    nfgv = 0
    nint = 0
    nfree = n
    info = 0
    iback = 0
    ifun = 0
    stp = 0
    gd = 0
    gdold = 0
    dtd = 0
    dnorm = 0
    stpmx = 0
    wrk = 0
    nenter = 0
    ileave = 0
    fail = 0
    driter = 0
    L.task = "START"

    // active(): project x0 on the box, initialise iwhere
    cnstnd = 0
    boxed = 1
    for (i = 1; i <= n; i++) {
        if (nbd[i] > 0) {
            if (nbd[i] <= 2 & x[i] <= l[i]) {
                if (x[i] < l[i]) x[i] = l[i]
            }
            else if (nbd[i] >= 2 & x[i] >= u[i]) {
                if (x[i] > u[i]) x[i] = u[i]
            }
        }
    }
    for (i = 1; i <= n; i++) {
        if (nbd[i] != 2) boxed = 0
        if (nbd[i] == 0) {
            iwhere[i] = -1
        }
        else {
            cnstnd = 1
            if (nbd[i] == 2 & u[i] - l[i] <= 0) {
                iwhere[i] = 3
            }
            else {
                iwhere[i] = 0
            }
        }
    }

    f = dos_obj(D, x)
    if (f >= .) {
        fail = 99
        fout = f
        niter = 0
        nfg = 1
        return(x)
    }
    g = dos_grad(D, x, l, u, ndeps)
    nfgv = 1
    sbgnrm = dos_projgr(x, g, l, u, nbd)
    if (sbgnrm <= 0) {
        fout = f
        niter = 0
        nfg = nfgv
        return(x)
    }

    outer = 1
    while (outer) {
        // ---- L222
        iword = -1
        skipcp = 0
        if (cnstnd == 0 & S.col > 0) {
            z = x
            wrk = S.updatd
            nint = 0
            skipcp = 1
        }
        if (skipcp == 0) {
            info = dos_cauchy(S, x, l, u, nbd, g, indx2, iwhere, t, d, z, c, nint, sbgnrm, epsmch)
            if (info != 0) {
                info = 0
                dos_lbreset(S)
                continue
            }
            dos_freev(n, nfree, index, nenter, ileave, indx2, iwhere, wrk, S.updatd, cnstnd, iter)
        }
        // ---- L333
        if (nfree != 0 & S.col != 0) {
            if (wrk) info = dos_formk(S, n, nfree, index, nenter, ileave, indx2, S.updatd)
            if (info != 0) {
                info = 0
                dos_lbreset(S)
                continue
            }
            info = dos_cmprlb(S, n, x, g, z, r, c, index, nfree, cnstnd)
            if (info == 0) info = dos_subsm(S, nfree, index, l, u, nbd, z, r, iword)
            if (info != 0) {
                info = 0
                dos_lbreset(S)
                continue
            }
        }
        // ---- L555: search direction
        d = z - x
        // ---- lnsrlb, initial part
        dtd = quadsum(d :* d)
        dnorm = sqrt(dtd)
        stpmx = 1e10
        if (cnstnd) {
            if (iter == 0) {
                stpmx = 1
            }
            else {
                for (i = 1; i <= n; i++) {
                    a1 = d[i]
                    if (nbd[i] != 0) {
                        if (a1 < 0 & nbd[i] <= 2) {
                            a2 = l[i] - x[i]
                            if (a2 >= 0) {
                                stpmx = 0
                            }
                            else if (a1 * stpmx < a2) {
                                stpmx = a2 / a1
                            }
                        }
                        else if (a1 > 0 & nbd[i] >= 2) {
                            a2 = u[i] - x[i]
                            if (a2 <= 0) {
                                stpmx = 0
                            }
                            else if (a1 * stpmx > a2) {
                                stpmx = a2 / a1
                            }
                        }
                    }
                }
            }
        }
        if (iter == 0 & boxed == 0) {
            stp = min((1 / dnorm, stpmx))
        }
        else {
            stp = 1
        }
        t = x
        r = g
        fold = f
        ifun = 0
        iback = 0
        L.task = "START"
        lsfail = 0
        newx = 0
        while (newx == 0 & lsfail == 0) {
            // L556
            gd = quadsum(g :* d)
            if (ifun == 0) {
                gdold = gd
                if (gd >= 0) {
                    info = -4
                    lsfail = 1
                    break
                }
            }
            dos_dcsrch(L, f, gd, stp, 1e-3, 0.9, 0.1, 0, stpmx)
            if (L.task != "CONVERGENCE" & L.task != "WARNING") {
                ifun = ifun + 1
                nfgv = nfgv + 1
                iback = ifun - 1
                if (stp == 1) {
                    x = z
                }
                else {
                    x = stp :* d + t
                }
                if (info != 0 | iback >= 20) {
                    lsfail = 1
                    break
                }
                f = dos_obj(D, x)
                if (f >= .) {
                    fail = 99
                    fout = f
                    niter = iter
                    nfg = nfgv
                    return(t)
                }
                g = dos_grad(D, x, l, u, ndeps)
            }
            else {
                newx = 1
            }
        }
        if (lsfail) {
            x = t
            g = r
            f = fold
            if (S.col == 0) {
                if (info == 0) {
                    info = -9
                    nfgv = nfgv - 1
                }
                iter = iter + 1
                fail = 52
                break
            }
            else {
                if (info == 0) nfgv = nfgv - 1
                info = 0
                dos_lbreset(S)
                continue
            }
        }
        // ---- new iterate
        iter = iter + 1
        sbgnrm = dos_projgr(x, g, l, u, nbd)
        if (D.trace == 2) D.trf = (D.trf, f)
        if (D.trace == 1) printf("iter %4.0f  f = %21.15f  stp = %12.6g  nfgv = %g  sbg = %g\n", iter, f, stp, nfgv, sbgnrm)
        driter = driter + 1
        if (driter > maxit) {
            fail = 1
            break
        }
        // ---- L777: termination tests
        if (sbgnrm <= 0) break
        ddum = max((abs(fold), abs(f), 1))
        if (fold - f <= tol * ddum) break
        r = g - r
        rr = quadsum(r :* r)
        if (stp == 1) {
            dr = gd - gdold
            ddum = -gdold
        }
        else {
            dr = (gd - gdold) * stp
            d = stp :* d
            ddum = -gdold * stp
        }
        if (dr <= epsmch * ddum) {
            S.updatd = 0
        }
        else {
            S.updatd = 1
            S.iupdat = S.iupdat + 1
            dos_matupd(S, d, r, rr, dr, stp, dtd)
            info = dos_formt(S)
            if (info != 0) {
                info = 0
                dos_lbreset(S)
            }
        }
    }
    fout = f
    niter = driter
    nfg = nfgv
    return(x)
}

// ---------------------------------------------------------------------
//  Kalman filter and smoother, exact diffuse local level, eqs (3.6)-(3.8), (3.12)
//  (Durbin and Koopman 2012, ch. 4-5).  Variances are common to all series,
//  so P_t, F_t, K_t are scalars shared by the N trends.
// ---------------------------------------------------------------------
void dos_kfs(real matrix Z, real scalar se2, real scalar sn2, real matrix A,
             real matrix V, real colvector Pt, real colvector Ft,
             real colvector Kt, real matrix TAU, real colvector VT)
{
    real scalar T, N, t, L, Nn
    real rowvector r
    T = rows(Z)
    N = cols(Z)
    A = J(T, N, 0)
    V = J(T, N, 0)
    Pt = J(T, 1, 0)
    Ft = J(T, 1, se2)
    Kt = J(T, 1, 0)
    V[1, .] = Z[1, .]
    if (T >= 2) {
        A[2, .] = Z[1, .]
        Pt[2] = se2 + sn2
    }
    for (t = 2; t <= T; t++) {
        V[t, .] = Z[t, .] - A[t, .]
        Ft[t] = Pt[t] + se2
        Kt[t] = Pt[t] / Ft[t]
        if (t < T) {
            A[t + 1, .] = A[t, .] + Kt[t] :* V[t, .]
            Pt[t + 1] = Pt[t] * (1 - Kt[t]) + sn2
        }
    }
    TAU = J(T, N, .)
    VT = J(T, 1, .)
    r = J(1, N, 0)
    Nn = 0
    for (t = T; t >= 2; t--) {
        L = 1 - Kt[t]
        r = V[t, .] :/ Ft[t] + L :* r
        Nn = 1 / Ft[t] + L * L * Nn
        TAU[t, .] = A[t, .] + Pt[t] :* r
        VT[t] = Pt[t] - Pt[t] * Pt[t] * Nn
    }
    TAU[1, .] = Z[1, .] + se2 :* r
    VT[1] = se2 - se2 * se2 * Nn
}

// ---------------------------------------------------------------------
//  Turning point x* of the DoS (Section 2.1): R optimize(maximum = TRUE),
//  i.e. Brent's fmin on -f over [lo, hi] with tol = eps^(1/4)
// ---------------------------------------------------------------------
real scalar dos_dosv(real scalar x, real scalar g, real scalar c1, real scalar c2,
                     real scalar s1, real scalar s2)
{
    return(g * (1 / (1 + exp(-s1 * (x - c1))) - 1 / (1 + exp(-s2 * (x - c2)))))
}

real rowvector dos_tp(real scalar g, real scalar c1, real scalar c2, real scalar s1,
                      real scalar s2, real scalar lo, real scalar hi)
{
    real scalar c, a, b, d, e, p, q, r, u, v, w, x, t2, fu, fv, fw, fx, xm
    real scalar eps, tol1, tol3, tol
    c = (3 - sqrt(5)) * 0.5
    tol = epsilon(1)^0.25
    eps = sqrt(epsilon(1))
    a = lo
    b = hi
    v = a + c * (b - a)
    w = v
    x = v
    d = 0
    e = 0
    fx = -dos_dosv(x, g, c1, c2, s1, s2)
    fv = fx
    fw = fx
    tol3 = tol / 3
    while (1) {
        xm = (a + b) * 0.5
        tol1 = eps * abs(x) + tol3
        t2 = tol1 * 2
        if (abs(x - xm) <= t2 - (b - a) * 0.5) break
        p = 0
        q = 0
        r = 0
        if (abs(e) > tol1) {
            r = (x - w) * (fx - fv)
            q = (x - v) * (fx - fw)
            p = (x - v) * q - (x - w) * r
            q = (q - r) * 2
            if (q > 0) {
                p = -p
            }
            else {
                q = -q
            }
            r = e
            e = d
        }
        if (abs(p) >= abs(q * 0.5 * r) | p <= q * (a - x) | p >= q * (b - x)) {
            if (x < xm) {
                e = b - x
            }
            else {
                e = a - x
            }
            d = c * e
        }
        else {
            d = p / q
            u = x + d
            if (u - a < t2 | b - u < t2) {
                d = tol1
                if (x >= xm) d = -d
            }
        }
        if (abs(d) >= tol1) {
            u = x + d
        }
        else if (d > 0) {
            u = x + tol1
        }
        else {
            u = x - tol1
        }
        fu = -dos_dosv(u, g, c1, c2, s1, s2)
        if (fu <= fx) {
            if (u < x) {
                b = x
            }
            else {
                a = x
            }
            v = w
            w = x
            x = u
            fv = fw
            fw = fx
            fx = fu
        }
        else {
            if (u < x) {
                a = u
            }
            else {
                b = u
            }
            if (fu <= fw | w == x) {
                v = w
                fv = fw
                w = u
                fw = fu
            }
            else if (fu <= fv | v == x | v == w) {
                v = u
                fv = fu
            }
        }
    }
    return((x, dos_dosv(x, g, c1, c2, s1, s2), (x > lo + 1e-3 & x < hi - 1e-3)))
}

// ---------------------------------------------------------------------
//  Residual diagnostics (Figure 5, Table 3): ACF(1), Ljung-Box(1),
//  tseries::adf.test(k = 1) with its interpolated p-value
// ---------------------------------------------------------------------
real scalar dos_approx(real rowvector xv, real rowvector yv, real scalar x0)
{
    real scalar n, i
    n = cols(xv)
    if (x0 >= .) return(.)
    if (x0 <= xv[1]) return(yv[1])
    if (x0 >= xv[n]) return(yv[n])
    for (i = 1; i < n; i++) {
        if (x0 <= xv[i + 1]) {
            return(yv[i] + (yv[i + 1] - yv[i]) * (x0 - xv[i]) / (xv[i + 1] - xv[i]))
        }
    }
    return(yv[n])
}

real rowvector dos_adf(real colvector x, real scalar kk)
{
    real scalar k, n, stat, i, pv
    real colvector y, yt, xt1, tt, e, b
    real matrix X, XXi, tab
    real rowvector tT, tp, ipl
    k = kk + 1
    y = x[|2 \ rows(x)|] - x[|1 \ rows(x) - 1|]
    n = rows(y)
    yt = y[|k \ n|]
    xt1 = x[|k \ n|]
    tt = (k::n)
    X = (xt1, J(rows(yt), 1, 1), tt)
    for (i = 1; i <= k - 1; i++) {
        X = (X, y[|k - i \ n - i|])
    }
    XXi = invsym(quadcross(X, X))
    b = XXi * quadcross(X, yt)
    e = yt - X * b
    stat = b[1] / sqrt((quadsum(e :* e) / (rows(yt) - cols(X))) * XXi[1, 1])
    tab = (4.38, 3.95, 3.60, 3.24, 1.14, 0.80, 0.50, 0.15 \
           4.15, 3.80, 3.50, 3.18, 1.19, 0.87, 0.58, 0.24 \
           4.04, 3.73, 3.45, 3.15, 1.22, 0.90, 0.62, 0.28 \
           3.99, 3.69, 3.43, 3.13, 1.23, 0.92, 0.64, 0.31 \
           3.98, 3.68, 3.42, 3.13, 1.24, 0.93, 0.65, 0.32 \
           3.96, 3.66, 3.41, 3.12, 1.25, 0.94, 0.66, 0.33)
    tab = -tab
    tT = (25, 50, 100, 250, 500, 1e5)
    tp = (0.01, 0.025, 0.05, 0.1, 0.9, 0.95, 0.975, 0.99)
    ipl = J(1, 8, .)
    for (i = 1; i <= 8; i++) {
        ipl[i] = dos_approx(tT, tab[., i]', n)
    }
    pv = dos_approx(ipl, tp, stat)
    return((stat, pv))
}

real rowvector dos_ljungbox(real colvector x)
{
    real scalar n, r1, Q
    real colvector d
    n = rows(x)
    d = x :- mean(x)
    r1 = quadsum(d[|1 \ n - 1|] :* d[|2 \ n|]) / quadsum(d :* d)
    Q = n * (n + 2) * r1 * r1 / (n - 1)
    return((r1, Q, chi2tail(1, Q)))
}

// R quantile(type = 7)
real scalar dos_q7(real colvector v, real scalar p)
{
    real colvector s
    real scalar n, h, lo
    s = select(v, v :< .)
    n = rows(s)
    if (n == 0) return(.)
    s = sort(s, 1)
    h = (n - 1) * p + 1
    lo = floor(h)
    if (lo >= n) return(s[n])
    return(s[lo] + (h - lo) * (s[lo + 1] - s[lo]))
}

real scalar dos_sd(real colvector v)
{
    real colvector s
    s = select(v, v :< .)
    if (rows(s) < 2) return(.)
    return(sqrt(variance(s)))
}

// per-unit diagnostics of a T x N residual matrix: acf1, LB Q, LB p, ADF stat, ADF p
real matrix dos_diag(real matrix R)
{
    real scalar i
    real matrix M
    real rowvector a, b
    M = J(cols(R), 5, .)
    for (i = 1; i <= cols(R); i++) {
        a = dos_ljungbox(R[., i])
        b = dos_adf(R[., i], 1)
        M[i, .] = (a, b)
    }
    return(M)
}

// ---------------------------------------------------------------------
//  Stoffer and Wall (1991) whitened-innovations bootstrap, Section 3.4
//  (R/01_helper_functions.R: prepare_bootstrap, generate_y_star, run_bootstrap)
// ---------------------------------------------------------------------
real matrix dos_boot(struct dos_data scalar D, real rowvector phat, real rowvector x0,
    real rowvector l, real rowvector u, real rowvector nbd, real scalar factr,
    real scalar maxit, real scalar m, real scalar ndeps, real scalar B,
    real scalar gmax, real scalar shmin, real scalar maxtries, real scalar ndisc,
    real scalar dots)
{
    struct dos_data scalar Ds
    real scalar g, c1, c2, sh, s1, s2, se, sn, T, N, i, t, kept, tries, fo, fl, it, nf, bad
    real matrix C, U, Z, A, V, TAU, Vr, Ev, W, E, Vs, Zs, draws, Ss
    real colvector Pt, Ft, Kt, VT, w, lam
    real rowvector mu, zp, p
    dos_unpack(D, phat, g, c1, c2, sh, s1, s2, se, sn)
    T = rows(D.Y)
    N = cols(D.Y)
    C = dos_curve(D.X, g, c1, dos_c2row(D, c2, sh), s1, s2)
    U = D.Y - C
    mu = mean(U)
    Z = U :- mu
    dos_kfs(Z, se * se, sn * sn, A, V, Pt, Ft, Kt, TAU, VT)
    Vr = V[|2, 1 \ T, N|]
    Ss = variance(Vr)
    symeigensystem(Ss, Ev, lam)
    if (min(lam) <= 0) {
        errprintf("bootstrap: innovation covariance not positive definite (needs N < T - 1)\n")
        exit(error(3352))
    }
    W = Vr * (Ev * diag(1 :/ sqrt(lam)) * Ev')
    W = W :- mean(W)
    Ss = Ev * diag(sqrt(lam)) * Ev'
    w = vec(W)
    draws = J(B, cols(phat), .)
    Ds = D
    Ds.trace = 0
    kept = 0
    tries = 0
    ndisc = 0
    if (maxtries <= 0) maxtries = 10 * B
    while (kept < B & tries < maxtries) {
        tries = tries + 1
        E = colshape(w[ceil(runiform((T - 1) * N, 1) :* rows(w))], N)
        Vs = E * Ss
        Zs = J(T, N, 0)
        zp = J(1, N, 0)
        for (i = 1; i <= T - 1; i++) {
            t = i + 1
            Zs[t, .] = zp + Vs[i, .]
            zp = zp + Kt[t] :* Vs[i, .]
        }
        Ds.Y = (Zs + C) :+ mu
        p = dos_lbfgsb(Ds, x0, l, u, nbd, factr, maxit, m, ndeps, fo, fl, it, nf)
        bad = (fl != 0)
        if (bad == 0) bad = (missing(p) > 0)
        if (bad == 0) bad = (p[1] > gmax)
        if (bad == 0 & D.regional) bad = (p[4] < shmin)
        if (bad) {
            ndisc = ndisc + 1
            if (dots) {
                printf("{txt}x")
                displayflush()
            }
            continue
        }
        kept = kept + 1
        draws[kept, .] = p
        if (dots) {
            printf("{txt}.")
            if (mod(kept, 50) == 0) printf("{txt} %5.0f\n", kept)
            displayflush()
        }
    }
    if (dots) printf("\n")
    if (kept < B) draws = draws[|1, 1 \ max((kept, 1)), cols(phat)|]
    return(draws)
}

// natural parameters + contrasts + turning points from a raw dynamic vector
real rowvector dos_derive(struct dos_data scalar D, real rowvector p, real scalar lo,
                          real scalar hi)
{
    real scalar g, c1, c2, sh, s1, s2, se, sn
    real rowvector t1, t2
    dos_unpack(D, p, g, c1, c2, sh, s1, s2, se, sn)
    t1 = dos_tp(g, c1, c2, s1, s2, lo, hi)
    if (D.regional) {
        t2 = dos_tp(g, c1, c2 + sh, s1, s2, lo, hi)
        return((g, c1, c2, c2 + sh, s1, s2, se, sn, sn / se, c2 - c1, -sh,
                t1[1], t2[1], t1[1] - t2[1], t1[3], t2[3]))
    }
    return((g, c1, c2, s1, s2, se, sn, sn / se, c2 - c1, t1[1], t1[3]))
}

// R-style start: quantile(min(x):max(x), p)
real scalar dos_seqq(real colvector x, real scalar p)
{
    real colvector s
    s = (min(x) :+ (0::floor(max(x) - min(x) + 1e-10)))
    return(dos_q7(s, p))
}

// ---------------------------------------------------------------------
//  Main driver called from xtdosekc.ado
// ---------------------------------------------------------------------
void dos_main()
{
    struct dos_data scalar D
    string scalar model, tu, shv
    real scalar T, N, i
    real colvector y, x, sv
    real matrix SH
    tu = st_local("touse")
    model = st_local("model")
    T = strtoreal(st_local("T"))
    N = strtoreal(st_local("N"))
    y = st_data(., st_local("y"), tu)
    x = st_data(., st_local("x"), tu)
    D.Y = colshape(y, T)'
    D.X = colshape(x, T)'
    D.tt = (1::T)
    D.nfev = 0
    D.trace = (st_local("trace") != "")
    D.trf = J(1, 0, .)
    shv = st_local("shift")
    D.regional = (shv != "")
    D.eur = J(1, N, 0)
    if (D.regional) {
        sv = st_data(., shv, tu)
        SH = colshape(sv, T)
        for (i = 1; i <= N; i++) {
            if (max(SH[i, .]) != min(SH[i, .])) {
                errprintf("shift() must be constant within each panel unit\n")
                exit(error(459))
            }
        }
        D.eur = (SH[., 1] :!= 0)'
        if (sum(D.eur) == 0 | sum(D.eur) == N) {
            errprintf("shift() must select some but not all units\n")
            exit(error(459))
        }
    }
    D.lsnr = strtoreal(st_local("lsnr"))
    D.lekc = strtoreal(st_local("lekc"))
    D.snr = strtoreal(st_local("snratio"))
    D.gpen = strtoreal(st_local("gammapen"))
    D.model = 1
    if (model == "dynamic") dos_run_dyn(D)
    else if (model == "country") dos_run_country(D)
    else dos_run_static(D, model)
}

real rowvector dos_numlist(string scalar s)
{
    string rowvector t
    t = tokens(s)
    if (cols(t) == 0) return(J(1, 0, .))
    return(strtoreal(t))
}

void dos_store(string scalar v, string scalar tu, real matrix M)
{
    if (v == "") return
    st_store(., v, tu, vec(M))
}

void dos_run_dyn(struct dos_data scalar D)
{
    real scalar T, N, xmin, xmax, factr, maxit, lmm, ndeps, f, fail, it, nfg, k
    real scalar g, c1, c2, sh, s1, s2, se, sn, ll, pen, B, ndisc, z, lev, r, j
    real rowvector x0, l, u, nbd, p, init, est, mu, lam, dr
    real matrix C, U, Z, A, V, TAU, RES, DG, draws, DD, TB, Ev, LD, FH, G
    real colvector Pt, Ft, Kt, VT, ord
    string scalar tu
    T = rows(D.Y)
    N = cols(D.Y)
    tu = st_local("touse")
    xmin = min(D.X)
    xmax = max(D.X)
    factr = strtoreal(st_local("factr"))
    maxit = strtoreal(st_local("maxiter"))
    if (maxit < 0) maxit = 2000
    lmm = strtoreal(st_local("lmm"))
    ndeps = strtoreal(st_local("ndeps"))
    init = dos_numlist(st_local("init"))
    if (D.regional) {
        x0 = (3.7, 1.1, 4.5, -0.5, 1, 4.5, 0.03, 0.02)
        k = 8
    }
    else {
        x0 = (3.7, 1.1, 4.5, 1, 4.5, 0.03, 0.02)
        k = 7
    }
    if (cols(init) > 0) {
        if (cols(init) != k) {
            if (D.regional) {
                errprintf("init() requires 8 values: gamma c1 c2 shift s1 s2 sigma_eps sigma_eta\n")
            }
            else {
                errprintf("init() requires 7 values: gamma c1 c2 s1 s2 sigma_eps sigma_eta\n")
            }
            exit(error(198))
        }
        x0 = init
    }
    x0[k - 1] = ln(x0[k - 1])
    x0[k] = ln(x0[k])
    // lower bound of c1, c2: min(x) of the estimation sample, or clb()
    if (strtoreal(st_local("clb")) > -1e299) {
        l = (strtoreal(st_local("gammalb")), strtoreal(st_local("clb")), strtoreal(st_local("clb")))
    }
    else {
        l = (strtoreal(st_local("gammalb")), xmin, xmin)
    }
    u = (1e300, 1e300, 1e300)
    nbd = (1, 1, 1)
    if (D.regional) {
        l = (l, -strtoreal(st_local("shbound")))
        u = (u, strtoreal(st_local("shbound")))
        nbd = (nbd, 2)
    }
    l = (l, strtoreal(st_local("smin")), strtoreal(st_local("smin")), strtoreal(st_local("lsmin")), strtoreal(st_local("lsmin")))
    u = (u, strtoreal(st_local("smax")), strtoreal(st_local("smax")), strtoreal(st_local("lsemax")), strtoreal(st_local("lsnmax")))
    nbd = (nbd, 2, 2, 2, 2)
    p = dos_lbfgsb(D, x0, l, u, nbd, factr, maxit, lmm, ndeps, f, fail, it, nfg)
    dos_unpack(D, p, g, c1, c2, sh, s1, s2, se, sn)
    C = dos_curve(D.X, g, c1, dos_c2row(D, c2, sh), s1, s2)
    U = D.Y - C
    mu = mean(U)
    Z = U :- mu
    dos_kfs(Z, se * se, sn * sn, A, V, Pt, Ft, Kt, TAU, VT)
    ll = dos_llf(Z, se * se, sn * sn)
    pen = f + ll
    RES = Z - TAU
    DG = dos_diag(RES)
    est = dos_derive(D, p, xmin, xmax)
    // ---- bootstrap
    B = strtoreal(st_local("reps"))
    ndisc = 0
    DD = J(0, cols(est), .)
    if (B > 0) {
        if (N >= T - 1) {
            errprintf("bootstrap requires N < T - 1 (innovation covariance)\n")
            exit(error(459))
        }
        if (st_local("nodots") == "") printf("{txt}Bootstrap replications ({res}%g{txt}): . = kept, x = discarded\n", B)
        draws = dos_boot(D, p, x0, l, u, nbd, factr, maxit, lmm, ndeps, B,
            strtoreal(st_local("gmaxboot")), strtoreal(st_local("shminboot")),
            strtoreal(st_local("maxtries")), ndisc, (st_local("nodots") == ""))
        DD = J(rows(draws), cols(est), .)
        for (j = 1; j <= rows(draws); j++) {
            DD[j, .] = dos_derive(D, draws[j, .], xmin, xmax)
        }
        st_matrix("__xd_draws", draws)
        st_matrix("__xd_dd", DD)
        st_numscalar("__xd_kept", rows(draws))
    }
    st_numscalar("__xd_ndisc", ndisc)
    // ---- table: Est, SE, lo, hi, Pr*(<=0)
    lev = strtoreal(st_local("level")) / 100
    TB = J(cols(est), 5, .)
    TB[., 1] = est'
    if (rows(DD) > 1) {
        for (j = 1; j <= cols(est); j++) {
            TB[j, 2] = dos_sd(DD[., j])
            TB[j, 3] = dos_q7(DD[., j], (1 - lev) / 2)
            TB[j, 4] = dos_q7(DD[., j], 1 - (1 - lev) / 2)
            TB[j, 5] = mean(DD[., j] :<= 0)
        }
    }
    st_matrix("__xd_tab", TB)
    st_matrix("__xd_raw", p)
    st_matrix("__xd_mu", mu')
    st_matrix("__xd_tau", TAU)
    st_matrix("__xd_vtau", VT)
    st_matrix("__xd_diag", (mu', DG))
    st_numscalar("__xd_ll", -f)
    st_numscalar("__xd_ssr", quadsum(RES :* RES))
    st_numscalar("__xd_llu", ll)
    st_numscalar("__xd_pen", pen)
    st_numscalar("__xd_fail", fail)
    st_numscalar("__xd_iter", it)
    st_numscalar("__xd_nfg", nfg)
    st_numscalar("__xd_xmin", xmin)
    st_numscalar("__xd_xmax", xmax)
    st_numscalar("__xd_N", N)
    st_numscalar("__xd_T", T)
    // ---- dynamic factor model on the trends (Pena and Box 1987)
    r = strtoreal(st_local("dfm"))
    if (r > N) r = N
    if (r >= 1 & N >= 2) {
        symeigensystem(variance(TAU), Ev, lam)
        ord = order(-lam', 1)
        Ev = Ev[., ord]
        lam = lam[ord]
        for (j = 1; j <= N; j++) {
            if (sum(Ev[., j]) < 0) Ev[., j] = -Ev[., j]
        }
        LD = Ev[|1, 1 \ N, r|] :* sqrt(lam[|1 \ r|])
        FH = TAU * Ev[|1, 1 \ N, r|]
        st_matrix("__xd_load", LD)
        st_matrix("__xd_fac", FH)
        st_matrix("__xd_eig", (lam \ lam :/ sum(lam) \ runningsum(lam) :/ sum(lam))')
    }
    // ---- curve grid for plots
    G = J(300, 3, .)
    G[., 1] = rangen(xmin, xmax, 300)
    for (j = 1; j <= 300; j++) {
        G[j, 2] = dos_dosv(G[j, 1], g, c1, c2, s1, s2)
        if (D.regional) G[j, 3] = dos_dosv(G[j, 1], g, c1, c2 + sh, s1, s2)
    }
    st_matrix("__xd_grid", G)
    // ---- series back to Stata
    z = invnormal(1 - (1 - lev) / 2)
    dos_store(st_local("v_mu"), tu, J(T, 1, 1) * mu)
    dos_store(st_local("v_curve"), tu, C)
    dos_store(st_local("v_tau"), tu, TAU)
    dos_store(st_local("v_taulo"), tu, TAU :- z :* sqrt(VT))
    dos_store(st_local("v_tauhi"), tu, TAU :+ z :* sqrt(VT))
    dos_store(st_local("v_fit"), tu, (C :+ mu) + TAU)
    dos_store(st_local("v_sfit"), tu, C :+ mu)
    dos_store(st_local("v_res"), tu, RES)
    dos_store(st_local("v_sp"), tu, (D.Y :- mu) - TAU)
}

void dos_run_static(struct dos_data scalar D, string scalar model)
{
    real scalar T, N, xmin, xmax, factr, maxit, lmm, ndeps, f, fail, it, nfg, K, a, b
    real scalar g, c1, c2, s1, s2, ssr, ll, n, j
    real rowvector x0, l, u, nbd, p, mu, de, tp, fr
    real matrix C, F, RES, DG, TR, G
    string scalar tu, frm
    T = rows(D.Y)
    N = cols(D.Y)
    tu = st_local("touse")
    xmin = min(D.X)
    xmax = max(D.X)
    factr = strtoreal(st_local("factr"))
    maxit = strtoreal(st_local("maxiter"))
    if (maxit < 0) maxit = 10000
    lmm = strtoreal(st_local("lmm"))
    ndeps = strtoreal(st_local("ndeps"))
    D.model = 2
    if (model == "trend") D.model = 4
    a = dos_seqq(vec(D.X), 0.25)
    b = dos_seqq(vec(D.X), 0.7)
    if (D.model == 4) {
        x0 = (mean(D.Y), J(1, N, 0), max(D.Y) - min(D.Y), a, b - a, 1, 1)
        K = 2 * N
    }
    else {
        x0 = (mean(D.Y), max(D.Y) - min(D.Y), a, b - a, 1, 1)
        K = N
    }
    frm = st_local("from")
    if (frm != "") {
        fr = st_matrix(frm)
        if (rows(fr) != 1 | cols(fr) != K + 5) {
            errprintf("from() must be a 1 x %g row vector for model(%s)\n", K + 5, model)
            exit(error(503))
        }
        x0 = fr
    }
    l = (J(1, K, -1e300), J(1, 5, 1e-6))
    u = J(1, K + 5, 1e300)
    nbd = (J(1, K, 0), J(1, 5, 1))
    p = dos_lbfgsb(D, x0, l, u, nbd, factr, maxit, lmm, ndeps, f, fail, it, nfg)
    mu = p[|1 \ N|]
    de = J(1, N, 0)
    if (D.model == 4) de = p[|N + 1 \ 2 * N|]
    g = p[K + 1]
    c1 = p[K + 2]
    c2 = p[K + 2] + p[K + 3] + 1e-3
    s1 = p[K + 4]
    s2 = p[K + 5]
    C = dos_curve(D.X, g, c1, J(1, N, c2), s1, s2)
    TR = D.tt * de
    F = (C :+ mu) + TR
    RES = D.Y - F
    ssr = quadsum(RES :* RES)
    n = T * N
    ll = -n / 2 * (ln(2 * pi()) + ln(ssr / n) + 1)
    DG = dos_diag(RES)
    tp = dos_tp(g, c1, c2, s1, s2, xmin, xmax)
    st_matrix("__xd_tab", ((g, c1, c2, s1, s2, c2 - c1, tp[1])', J(7, 4, .)))
    st_matrix("__xd_raw", p)
    st_matrix("__xd_mu", mu')
    st_matrix("__xd_delta", de')
    st_matrix("__xd_diag", (mu', DG))
    st_numscalar("__xd_ssr", ssr)
    st_numscalar("__xd_ll", ll)
    st_numscalar("__xd_tpint", tp[3])
    st_numscalar("__xd_fail", fail)
    st_numscalar("__xd_iter", it)
    st_numscalar("__xd_nfg", nfg)
    st_numscalar("__xd_xmin", xmin)
    st_numscalar("__xd_xmax", xmax)
    st_numscalar("__xd_N", N)
    st_numscalar("__xd_T", T)
    G = J(300, 3, .)
    G[., 1] = rangen(xmin, xmax, 300)
    for (j = 1; j <= 300; j++) {
        G[j, 2] = dos_dosv(G[j, 1], g, c1, c2, s1, s2)
    }
    st_matrix("__xd_grid", G)
    dos_store(st_local("v_mu"), tu, J(T, 1, 1) * mu)
    dos_store(st_local("v_curve"), tu, C)
    dos_store(st_local("v_tau"), tu, TR)
    dos_store(st_local("v_fit"), tu, F)
    dos_store(st_local("v_sfit"), tu, F)
    dos_store(st_local("v_res"), tu, RES)
    dos_store(st_local("v_sp"), tu, (D.Y :- mu) - TR)
}

void dos_run_country(struct dos_data scalar D)
{
    struct dos_data scalar D1
    real scalar T, N, i, factr, maxit, lmm, ndeps, f, fail, it, nfg, a, b
    real rowvector x0, l, u, nbd, p
    real matrix CT, F, RES, DG, fr, C, MU
    string scalar tu, frm
    T = rows(D.Y)
    N = cols(D.Y)
    tu = st_local("touse")
    factr = strtoreal(st_local("factr"))
    maxit = strtoreal(st_local("maxiter"))
    if (maxit < 0) maxit = 2000
    lmm = strtoreal(st_local("lmm"))
    ndeps = strtoreal(st_local("ndeps"))
    frm = st_local("from")
    fr = J(0, 6, .)
    if (frm != "") {
        fr = st_matrix(frm)
        if (rows(fr) != N | cols(fr) != 6) {
            errprintf("from() must be an N x 6 matrix (mu gamma c1 c2gap s1 s2), N = %g\n", N)
            exit(error(503))
        }
    }
    D1 = D
    D1.model = 3
    D1.tt = D.tt
    l = (-1e300, 1e-6, 1e-6, 1e-6, 1e-6, 1e-6)
    u = J(1, 6, 1e300)
    nbd = (0, 1, 1, 1, 1, 1)
    CT = J(N, 10, .)
    F = J(T, N, .)
    C = J(T, N, .)
    MU = J(T, N, .)
    for (i = 1; i <= N; i++) {
        D1.Y = D.Y[., i]
        D1.X = D.X[., i]
        if (rows(fr) > 0) {
            x0 = fr[i, .]
        }
        else {
            a = dos_seqq(D1.X, 0.25)
            b = dos_seqq(D1.X, 0.7)
            x0 = (mean(D1.Y), max(D1.Y) - min(D1.Y), a, b - a, 1, 1)
        }
        p = dos_lbfgsb(D1, x0, l, u, nbd, factr, maxit, lmm, ndeps, f, fail, it, nfg)
        CT[i, .] = (p[1], p[2], p[3], p[3] + p[4] + 1e-3, p[5], p[6], f, fail, it, f / T)
        C[., i] = dos_curve(D1.X, p[2], p[3], p[3] + p[4] + 1e-3, p[5], p[6])
        MU[., i] = J(T, 1, p[1])
        F[., i] = C[., i] :+ p[1]
    }
    RES = D.Y - F
    DG = dos_diag(RES)
    st_matrix("__xd_country", CT)
    st_matrix("__xd_diag", (CT[., 1], DG))
    st_numscalar("__xd_ssr", quadsum(RES :* RES))
    st_numscalar("__xd_N", N)
    st_numscalar("__xd_T", T)
    st_numscalar("__xd_xmin", min(D.X))
    st_numscalar("__xd_xmax", max(D.X))
    dos_store(st_local("v_mu"), tu, MU)
    dos_store(st_local("v_curve"), tu, C)
    dos_store(st_local("v_fit"), tu, F)
    dos_store(st_local("v_sfit"), tu, F)
    dos_store(st_local("v_res"), tu, RES)
    dos_store(st_local("v_sp"), tu, D.Y - MU)
}

// DoS illustration (Figure 1)
void dos_illus(real scalar g, real scalar c1, real scalar s1, real scalar c2,
               real scalar s2, real scalar lo, real scalar hi, real scalar n)
{
    real matrix G
    real scalar j
    real rowvector t
    G = J(n, 4, .)
    G[., 1] = rangen(lo, hi, n)
    for (j = 1; j <= n; j++) {
        G[j, 2] = 1 / (1 + exp(-s1 * (G[j, 1] - c1)))
        G[j, 3] = 1 / (1 + exp(-s2 * (G[j, 1] - c2)))
        G[j, 4] = g * (G[j, 2] - G[j, 3])
    }
    t = dos_tp(g, c1, c2, s1, s2, lo, hi)
    st_matrix("__xd_illus", G)
    st_numscalar("__xd_tp", t[1])
    st_numscalar("__xd_peak", t[2])
}

// Pesaran (2004) CD statistic for a T x N matrix
real rowvector dos_cd(real matrix X)
{
    real scalar N, T, i, j, s, cd
    real matrix R
    T = rows(X)
    N = cols(X)
    R = correlation(X)
    s = 0
    for (i = 1; i <= N - 1; i++) {
        for (j = i + 1; j <= N; j++) {
            s = s + R[i, j]
        }
    }
    cd = sqrt(2 * T / (N * (N - 1))) * s
    return((cd, 2 * normal(-abs(cd)), s / (N * (N - 1) / 2)))
}

end
