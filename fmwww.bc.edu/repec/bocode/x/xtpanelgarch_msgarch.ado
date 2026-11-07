*! xtpanelgarch_msgarch 1.0.0  06nov2026
*! Casarin, Costantini & Osuntuyi (2024) Bayesian nonparametric panel Markov-switching GARCH
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*
* Step -> equation map (Casarin, Costantini and Osuntuyi 2024, JBES 42: 135-146; arXiv:2012.10124 Appendix A)
*   model           y_it = mu_i(s) + sigma_it e_it; sigma2_it = g_i(s) + a_i(s) u2_i,t-1 + b_i(s) sigma2_i,t-1  (1)-(5)
*   prior           P_i rows ~ Dir(phi r_k), r_k ~ Dir(1/K) (6)-(7); first stage (8)-(9); PY(nu, psi, H0) (10)-(16)
*   Gibbs step 1    stick-breaking V and slice U (A.1, eqs. 29-30)
*   step 2          transition rows Dir(phi r_k + n_i,k) (31); r_k MH with Dir(d + m_k) proposal (34)
*   step 3          atoms: mu* conjugate normal (35); g*, a*, b* exact beta full conditionals by griddy-Gibbs
*                   (the paper's inverse-cdf form (36)-(37) omits the Beta normalising constants)
*   step 4          mu_i: MH, normal mixture proposal (39); (g,a,b)_i: MH with the Nakatsuma-Ardia
*                   linearised proposal (41)-(50); full Hastings ratio of the asymmetric mixture proposal
*   step 5          state paths: MH with Klaassen-collapsed FFBS proposal (A.5, eqs. 52-57; Billio,
*                   Casarin and Osuntuyi 2016, sec. 3.2.5)
*   step 6          cluster allocations D_ik (A.6)
*   identification  mu_i1 > mu_i2 > ... (sec. 4.2)

program define xtpanelgarch_msgarch, eclass
    version 14.0
    if replay() {
        if ("`e(cmd)'" != "xtpanelgarch" | "`e(subcmd)'" != "msgarch") error 301
        _xtpg_ms_display `0'
        exit
    }
    syntax varname(ts) [if] [in] , [ STATes(integer 2) BURN(integer 1000) DRAWs(integer 2000) ///
        THIN(integer 1) SEED(integer 12345) NU(real 0) PSI(real 10) PHI(real 10) MUSD(real -1) ///
        R(real 100) noLOG ]
    if `states' < 1 | `states' > 4 {
        di as err "states() must be between 1 and 4"
        exit 198
    }
    if `nu' < 0 | `nu' >= 1 | `psi' <= -`nu' {
        di as err "Pitman-Yor parameters need 0 <= nu < 1 and psi > -nu"
        exit 198
    }
    local showlog = ("`log'" == "")
    qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if "`ivar'" == "" | "`tvar'" == "" {
        di as err "data must be {bf:xtset} with a panel and a time variable"
        exit 459
    }
    local tdelta = r(tdelta)
    marksample touse
    local yorig "`varlist'"
    tsrevar `varlist'
    local y "`r(varlist)'"
    _xtpg_balance `touse' `ivar' `tvar' `tdelta' "xtpanelgarch msgarch"
    local N = r(N)
    local T = r(T)
    local t0 = r(t0)
    local units "`r(units)'"
    tempname Y
    mata: _xtpg_getE("`y'", "`touse'", `N', "`Y'")
    if `musd' <= 0 {
        qui sum `y' if `touse'
        local musd = 0.25 * r(sd)
    }
    local K = `states'
    if `showlog' di as txt _n "BNP panel MS-GARCH: K = `K' regimes, PY(`nu', `psi'), burn-in `burn', draws `draws'"
    mata: _xtpg_ms_fit("`Y'", `K', `burn', `draws', `thin', `seed', `nu', `psi', `phi', `musd', `r', `showlog')

    tempname PM SP NC CO AV PR AC b V
    matrix `PM' = __xtpg_post
    matrix `AV' = __xtpg_avg
    mata: _xtpg_br_post("`AV'", "`AV'", "`b'", "`V'")
    mata: _xtpg_subvec("`b'", 4 * `K')
    mata: _xtpg_submat("`V'", 4 * `K')
    local names ""
    foreach p in mu gamma alpha beta {
        forvalues k = 1/`K' {
            local names "`names' `p':s`k'"
        }
    }
    matrix colnames `b' = `names'
    matrix colnames `V' = `names'
    matrix rownames `V' = `names'
    local pn ""
    foreach p in mu gamma alpha beta {
        forvalues k = 1/`K' {
            local pn "`pn' `p'`k'"
        }
    }
    matrix colnames `PM' = `pn'
    matrix rownames `PM' = `units'
    qui count if `touse'
    local nobs = r(N)
    ereturn post `b' `V', esample(`touse') depname(`yorig') obs(`nobs')
    ereturn scalar states = `K'
    ereturn scalar N_g = `N'
    ereturn scalar T = `T'
    ereturn scalar t0 = `t0'
    ereturn scalar tdelta = `tdelta'
    ereturn scalar burn = `burn'
    ereturn scalar draws = `draws'
    ereturn scalar thin = `thin'
    ereturn scalar seed = `seed'
    ereturn scalar nu = `nu'
    ereturn scalar psi = `psi'
    ereturn scalar phi = `phi'
    ereturn local cmd "xtpanelgarch"
    ereturn local subcmd "msgarch"
    ereturn local title "BNP panel Markov-switching GARCH (Casarin-Costantini-Osuntuyi)"
    ereturn local cov "none"
    ereturn local depvar "`yorig'"
    ereturn local ivar "`ivar'"
    ereturn local tvar "`tvar'"
    ereturn local units "`units'"
    ereturn local predict "xtpanelgarch_p"
    ereturn local estat_cmd "xtpanelgarch_estat"
    ereturn matrix post = `PM'
    ereturn matrix sprob = __xtpg_sprob
    ereturn matrix nclusters = __xtpg_ncl
    ereturn matrix cocluster = __xtpg_cocl
    ereturn matrix P = __xtpg_P
    ereturn matrix acceptance = __xtpg_acc
    ereturn matrix draws_avg = `AV'
    _xtpg_ms_display
end

program define _xtpg_ms_display, rclass
    local K = e(states)
    di _n as txt "`e(title)'"
    di as txt _col(52) "Number of series" _col(68) "=" as res %9.0f e(N_g)
    di as txt "Regimes K = " as res `K' as txt ", PY(nu = " as res e(nu) as txt ", psi = " as res e(psi) as txt ")" _col(52) "Time periods" _col(68) "=" as res %9.0f e(T)
    di as txt "Gibbs/MH: burn-in " as res e(burn) as txt ", draws " as res e(draws) as txt ", thin " as res e(thin) _col(52) "Seed" _col(68) "=" as res %9.0f e(seed)
    tempname A NC AC
    matrix `A' = e(draws_avg)
    matrix `NC' = e(nclusters)
    matrix `AC' = e(acceptance)
    di as txt "{hline 78}"
    di as txt "Cross-sectional average of unit parameters by regime (posterior mean, sd, 95% interval)"
    di as txt "{hline 78}"
    local j 0
    foreach p in mu gamma alpha beta {
        forvalues k = 1/`K' {
            local ++j
            mata: _xtpg_br_summ("`A'", `j', 0.025, 0.975)
            di as txt "  `p'" _col(10) "regime `k'" as res _col(24) %10.4f r(m) _col(36) %9.4f r(s) _col(48) %9.4f r(l) %10.4f r(u)
        }
    }
    di as txt "{hline 78}"
    di as txt "Number of clusters per regime (posterior)"
    forvalues k = 1/`K' {
        mata: _xtpg_ms_ncl("`NC'", `k')
        di as txt "  regime `k': MAP = " as res r(map) as txt ", mean = " as res %5.2f r(mean) as txt ", P(MAP) = " as res %5.3f r(pmap)
    }
    di as txt "{hline 78}"
    di as txt "MH acceptance rates: states " as res %5.3f `AC'[1,1] as txt ", means " as res %5.3f `AC'[1,2] as txt ", GARCH " as res %5.3f `AC'[1,3]
    di as txt "Unit posterior means: e(post); transition matrices: e(P); smoothed regime probabilities: e(sprob);"
    di as txt "co-clustering probabilities (stacked by regime): e(cocluster)"
end
