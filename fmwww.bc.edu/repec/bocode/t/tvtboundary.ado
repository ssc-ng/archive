*! tvtboundary 1.0.0  13oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Threshold regression with a threshold BOUNDARY: the threshold is
*! gamma_1 + gamma_2'z_i, a boundary in (q,z) space rather than a point on
*! the q line. Cross-sectional or stationary data.
*!
*! Yu, P. and X. Fan (2020) "Threshold Regression With A Threshold Boundary",
*!   Journal of Business & Economic Statistics,
*!   doi:10.1080/07350015.2020.1740712  (Crossref 2026-10-13)
*!
*! Clean-room from the paper. The archive TRBoundary.zip carries no licence;
*! its MATLAB was read to understand behaviour and RUN to produce
*! _work/reflock/boundary_lock.txt. No line of it is reproduced.
*! See validation/tvthresh/tvtboundary_equation_map.md.

program define tvtboundary, eclass sortpreserve
    version 15

    if replay() {
        if "`e(cmd)'" != "tvtboundary" {
            display as error "last estimates not found"
            exit 301
        }
        Display `0'
        exit
    }

    syntax varlist(numeric fv min=1) [if] [in] ,    ///
        THReshvar(varname numeric)                  ///
        [ Zvars(varlist numeric)                    ///
          noCONStant                                ///
          TRIM(real 0.05)                           ///
          GRIDn(integer 41)                         ///
          REFine(integer 2)                         ///
          G2range(numlist min=2 max=2)              ///
          SIMreps(integer 200)                      ///
          NPI(integer 0)                            ///
          BURNin(integer 500)                       ///
          MESH(integer 16384)                       ///
          Level(cilevel) ]

    gettoken depv xvars : varlist

    * ------------------------------------------------------------- checks
    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        display as error "the authors' own code uses 5% each side," ///
            " which is the default"
        exit 198
    }
    if `gridn' < 3 {
        display as error "{bf:gridn()} must be at least 3"
        exit 198
    }
    if `refine' < 0 {
        display as error "{bf:refine()} cannot be negative"
        exit 198
    }
    if `simreps' < 0 {
        display as error "{bf:simreps()} cannot be negative"
        exit 198
    }
    if `npi' < 0 {
        display as error "{bf:npi()} cannot be negative"
        exit 198
    }
    if `npi' > 0 & `npi' < 200 {
        display as error "{bf:npi()} below 200 cannot support a" ///
            " percentile interval"
        display as error "use at least 200 draws, and preferably 2000"
        exit 198
    }
    if `burnin' < 0 {
        display as error "{bf:burnin()} cannot be negative"
        exit 198
    }
    local m2 = 2^(round(log(`mesh')/log(2)))
    if `mesh' < 256 | `m2' != `mesh' {
        display as error "{bf:mesh()} must be a power of two," ///
            " at least 256"
        display as error "the shipped code uses 16384, which is the default"
        exit 198
    }

    marksample touse
    markout `touse' `depv' `xvars' `threshvar' `zvars'
    quietly count if `touse'
    local nobs = r(N)

    local nx : word count `xvars'
    local nz : word count `zvars'
    local kk = `nx' + ("`constant'" == "")
    if `nobs' < 4*`kk' + 10 {
        display as error "too few observations (`nobs') for `kk'" ///
            " regressors in each of two regimes"
        exit 2001
    }

    foreach v of local xvars {
        if "`v'" == "`threshvar'" {
            display as error "`threshvar' cannot be both a regressor" ///
                " and the threshold variable"
            exit 198
        }
    }
    if `nz' > 2 {
        display as error "{bf:zvars()} holds `nz' variables, so the" ///
            " boundary grid is a `nz'-fold"
        display as error "cartesian product. The paper's own applications" ///
            " use one or two."
        exit 198
    }

    local g2lo
    local g2hi
    if "`g2range'" != "" {
        tokenize `g2range'
        local g2lo `1'
        local g2hi `2'
        if `g2lo' >= `g2hi' {
            display as error "{bf:g2range()} must be increasing"
            exit 198
        }
    }

    local qvar "`threshvar'"
    local noconstant "`constant'"
    local gridn `gridn'
    local draws `npi'
    local burn `burnin'
    _tvt_drop

    if `npi' > 0 {
        display as text "drawing `npi' posterior values (plus `burnin'" ///
            " burn-in) for the interval"
    }

    mata: tvt_boundary()

    tempname G0 SSR SSR0 SSR1 SSR2 S1 S2 N1 N2 NSET NF NC MINN SC PSC HB AR
    scalar `G0'   = __tvt_bd_g0
    scalar `SSR'  = __tvt_bd_ssr
    scalar `SSR0' = __tvt_bd_ssr0
    scalar `SSR1' = __tvt_bd_ssr1
    scalar `SSR2' = __tvt_bd_ssr2
    scalar `S1'   = __tvt_bd_sig1
    scalar `S2'   = __tvt_bd_sig2
    scalar `N1'   = __tvt_bd_n1
    scalar `N2'   = __tvt_bd_n2
    scalar `NSET' = __tvt_bd_nset
    scalar `NF'   = __tvt_bd_nfeas
    scalar `NC'   = __tvt_bd_ncand
    scalar `MINN' = __tvt_bd_minn
    scalar `SC'   = __tvt_bd_score
    scalar `PSC'  = __tvt_bd_pscore
    scalar `HB'   = __tvt_bd_h
    scalar `AR'   = __tvt_bd_arate
    tempname BM VM G2M GTM CIM GSM SIMM
    matrix `BM'  = __tvt_bd_b
    matrix `VM'  = __tvt_bd_V
    matrix `G2M' = __tvt_bd_g2
    matrix `GTM' = __tvt_bd_gt
    matrix `CIM' = __tvt_bd_ci
    matrix `GSM' = __tvt_bd_gsup
    capture matrix `SIMM' = __tvt_bd_sim
    local hassim = (_rc == 0)
    _tvt_drop

    * -------------------------------------------------------- the names
    local nm
    foreach v of local xvars {
        local nm `nm' lower:`v'
    }
    if "`constant'" == "" local nm lower:_cons `nm'
    local nm2
    foreach v of local xvars {
        local nm2 `nm2' upper:`v'
    }
    if "`constant'" == "" local nm2 upper:_cons `nm2'
    matrix colnames `BM' = `nm' `nm2'
    matrix colnames `VM' = `nm' `nm2'
    matrix rownames `VM' = `nm' `nm2'
    if `nz' > 0 {
        matrix colnames `G2M' = `zvars'
    }

    ereturn post `BM' `VM', esample(`touse') depname(`depv') obs(`nobs')
    ereturn scalar N        = `nobs'
    ereturn scalar gamma1   = `G0'
    ereturn scalar N_lower  = `N1'
    ereturn scalar N_upper  = `N2'
    ereturn scalar ssr      = `SSR'
    ereturn scalar ssr_lin  = `SSR0'
    ereturn scalar ssr1     = `SSR1'
    ereturn scalar ssr2     = `SSR2'
    ereturn scalar sigma1   = `S1'
    ereturn scalar sigma2   = `S2'
    ereturn scalar n_set    = `NSET'
    ereturn scalar n_feasible = `NF'
    ereturn scalar n_cand   = `NC'
    ereturn scalar minreg   = `MINN'
    ereturn scalar trim     = `trim'
    ereturn scalar gridn    = `gridn'
    ereturn scalar refine   = `refine'
    ereturn scalar score    = `SC'
    if `simreps' > 0 {
        ereturn scalar p_score = `PSC'
    }
    ereturn scalar simreps  = `simreps'
    ereturn scalar npi      = `npi'
    if `npi' > 0 {
        ereturn scalar bandwidth = `HB'
        ereturn scalar accept    = `AR'
        ereturn scalar mesh      = `mesh'
    }
    ereturn local  cmd       "tvtboundary"
    ereturn local  cmdline   "tvtboundary `0'"
    ereturn local  depvar    "`depv'"
    ereturn local  indepvars "`xvars'"
    ereturn local  threshvar "`threshvar'"
    ereturn local  zvars     "`zvars'"
    ereturn local  title     "Threshold regression with a threshold boundary"
    ereturn local  vcetype   "Robust"
    if `nz' > 0 ereturn matrix gamma2 = `G2M'
    ereturn matrix path = `GTM'
    ereturn matrix supgamma = `GSM'
    if `npi' > 0 {
        ereturn matrix npi_ci = `CIM'
        if `hassim' ereturn matrix npi_draws = `SIMM'
    }

    Display, level(`level')
end

* ---------------------------------------------------------------------
program define Display
    version 15
    syntax [, Level(cilevel) ]

    local zv "`e(zvars)'"
    local nz : word count `zv'
    tempname G2 CI
    if `nz' > 0 matrix `G2' = e(gamma2)
    if e(npi) > 0 matrix `CI' = e(npi_ci)

    display ""
    display as text "`e(title)'" ///
        _col(52) "Number of obs" _col(68) "=" _col(71) as result %9.0fc e(N)
    display as text "Yu and Fan (2020), JBES" ///
        _col(52) as text "Grid points" _col(68) "=" ///
        _col(71) as result %9.0fc e(n_cand)
    display as text "Threshold variable: " as result "`e(threshvar)'" ///
        _col(52) as text "Splits searched" _col(68) "=" ///
        _col(71) as result %9.0fc e(n_feasible)
    display ""
    display as text "{hline 78}"
    if `nz' == 0 {
        display as text "  The threshold is a CONSTANT (no {bf:zvars()}" ///
            " given):"
        display as text "    gamma = " as result %12.6g e(gamma1)
    }
    else {
        local eq = "    gamma(i) = " + string(e(gamma1), "%9.0g")
        forvalues j = 1/`nz' {
            local zz : word `j' of `zv'
            local cf = `G2'[1,`j']
            local sgn = cond(`cf' < 0, " - ", " + ")
            local eq = "`eq'" + "`sgn'" + string(abs(`cf'), "%9.0g") + " `zz'"
        }
        display as text "  The threshold is a BOUNDARY in" ///
            " (`e(threshvar)', `zv') space:"
        display as text "`eq'"
    }
    display as text "{hline 78}"
    display as text "    gamma_1 (intercept)" _col(32) as result %14.6g ///
        e(gamma1)
    if e(npi) > 0 {
        display as text "      posterior interval" _col(32) as result ///
            %12.6g `CI'[1,1] as text " to " as result %12.6g `CI'[1,2]
    }
    forvalues j = 1/`nz' {
        local zz : word `j' of `zv'
        display as text "    gamma_2 (`zz')" _col(32) as result %14.6g ///
            `G2'[1,`j']
        if e(npi) > 0 {
            display as text "      posterior interval" _col(32) as result ///
                %12.6g `CI'[1,`=2*`j'+1'] as text " to " as result ///
                %12.6g `CI'[1,`=2*`j'+2']
        }
    }
    display as text "    observations below / above" _col(34) as result ///
        %6.0f e(N_lower) as text " /" as result %6.0f e(N_upper)
    if e(n_set) > 1 {
        display as text "    identified set averaged over" _col(32) ///
            as result %14.0f e(n_set) as text " points"
    }
    display as text "{hline 78}"

    ereturn display, level(`level')

    display as text "{hline 78}"
    display as text "  SSR: linear " as result %12.4f e(ssr_lin) ///
        as text "   lower " as result %12.4f e(ssr1) ///
        as text "   upper " as result %12.4f e(ssr2)
    display as text "       total " as result %12.4f e(ssr) ///
        as text "   sigma " as result %10.6f e(sigma1) ///
        as text " /" as result %10.6f e(sigma2)
    display as text "{hline 78}"
    display as text "  Score test of NO threshold effect" _col(42) ///
        as result %12.4f e(score)
    if e(simreps) > 0 {
        display as text "    simulated p-value (" as result e(simreps) ///
            as text " draws)" _col(42) as result %12.4f e(p_score)
    }
    else {
        display as text "    no p-value: {bf:simreps(0)} was specified"
    }
    display as text "{hline 78}"
    if e(npi) > 0 {
        display as text "  Interval: NONPARAMETRIC POSTERIOR," ///
            " `=e(npi)' draws, bandwidth " ///
            as result %6.4f e(bandwidth)
        display as text "  acceptance rate " as result %5.3f e(accept) ///
            as text " (0.2-0.5 is healthy; far outside that, the"
        display as text "  chain is not exploring and the interval is" ///
            " not trustworthy)"
    }
    else {
        display as text "  {bf:No interval for the threshold is reported.}" ///
            " Specify {bf:npi(#)}."
    }
    display as text "{hline 78}"
    display as text "  Do NOT invert the likelihood ratio for this" ///
        " threshold. The paper proves"
    display as text "  that method invalid for a boundary; the" ///
        " nonparametric posterior"
    display as text "  interval that {bf:npi()} gives is the one it" ///
        " licenses."
end
