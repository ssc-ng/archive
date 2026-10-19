*! tvtindex 1.0.0  13oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Smoothed least squares for a threshold on a LINEAR INDEX of observed
*! variables, so discrete variables can split the sample and the threshold
*! estimate is ASYMPTOTICALLY NORMAL.
*!
*! Seo, M. and O. Linton (2005) "A Smoothed Least Squares Estimator For
*!   Threshold Regression Models", LSE working paper; published as Seo and
*!   Linton (2007), Journal of Econometrics 141(2):704-735,
*!   doi:10.1016/j.jeconom.2006.11.002
*!
*! Clean-room -- no code ships with this paper.
*! See validation/tvthresh/tvtindex_equation_map.md.

program define tvtindex, eclass sortpreserve
    version 15

    if replay() {
        if "`e(cmd)'" != "tvtindex" {
            display as error "last estimates not found"
            exit 301
        }
        Display `0'
        exit
    }

    syntax varlist(numeric fv min=1) [if] [in] ,    ///
        THReshvar(varname numeric)                  ///
        [ Ivars(varlist numeric)                    ///
          SHiftvars(varlist numeric)                ///
          noCONStant                                ///
          BWidth(real -1)                           ///
          GRIDn(integer 41)                         ///
          REFine(integer 4)                         ///
          IRange(numlist min=2 max=2)               ///
          HAC(integer 0)                            ///
          Level(cilevel) ]

    gettoken depv xvars : varlist

    * ------------------------------------------------------------- checks
    if `gridn' < 3 {
        display as error "{bf:gridn()} must be at least 3"
        exit 198
    }
    if `refine' < 0 {
        display as error "{bf:refine()} cannot be negative"
        exit 198
    }
    if `hac' < 0 {
        display as error "{bf:hac()} cannot be negative"
        exit 198
    }
    if `bwidth' != -1 & `bwidth' <= 0 {
        display as error "{bf:bwidth()} must be positive"
        display as error "the default is log(n)/sqrt(n), the paper's own" ///
            " choice"
        exit 198
    }

    marksample touse
    markout `touse' `depv' `xvars' `threshvar' `ivars' `shiftvars'
    quietly count if `touse'
    local nobs = r(N)

    local nx : word count `xvars'
    local ni : word count `ivars'
    local ns : word count `shiftvars'
    local kk = `nx' + ("`constant'" == "")
    local kt = cond("`shiftvars'"=="", `kk', `ns' + ("`constant'" == ""))
    if `nobs' < 2*(`kk' + `kt' + `ni' + 1) + 10 {
        display as error "too few observations (`nobs') for" ///
            " `=`kk'+`kt'+`ni'+1' parameters"
        exit 2001
    }

    foreach v of local xvars {
        if "`v'" == "`threshvar'" {
            continue
        }
    }
    if `ni' > 2 {
        display as error "{bf:ivars()} holds `ni' variables, so the search" ///
            " is over a `=`ni'+1'-dimensional"
        display as error "index. The paper's own applications use one or two."
        exit 198
    }
    foreach v of local ivars {
        if "`v'" == "`threshvar'" {
            display as error "`threshvar' is already the index's leading" ///
                " variable, with its"
            display as error "coefficient normalised to 1; it cannot also" ///
                " be in {bf:ivars()}."
            exit 198
        }
    }

    local qvar "`threshvar'"
    local noconstant "`constant'"
    local irange "`irange'"
    _tvt_drop

    mata: tvt_index()

    tempname SN SSR SSR0 BW THR KN KT KZ NEV RC NHI KMIN KMAX
    scalar `SN'   = __tvt_ix_sn
    scalar `SSR'  = __tvt_ix_ssr
    scalar `SSR0' = __tvt_ix_ssr0
    scalar `BW'   = __tvt_ix_bw
    scalar `THR'  = __tvt_ix_thr
    scalar `KN'   = __tvt_ix_k
    scalar `KT'   = __tvt_ix_kt
    scalar `KZ'   = __tvt_ix_kz
    scalar `NEV'  = __tvt_ix_nev
    scalar `RC'   = __tvt_ix_rc
    scalar `NHI'  = __tvt_ix_nhi
    scalar `KMIN' = __tvt_ix_kmin
    scalar `KMAX' = __tvt_ix_kmax
    tempname BM VM G2M IDXM
    matrix `BM'   = __tvt_ix_b
    matrix `VM'   = __tvt_ix_V
    matrix `G2M'  = __tvt_ix_g2
    matrix `IDXM' = __tvt_ix_idx
    _tvt_drop

    * -------------------------------------------------------- the names
    local svar "`shiftvars'"
    if "`svar'" == "" local svar "`xvars'"
    local nm
    if "`constant'" == "" local nm base:_cons
    foreach v of local xvars {
        local nm `nm' base:`v'
    }
    if "`constant'" == "" local nm `nm' shift:_cons
    foreach v of local svar {
        local nm `nm' shift:`v'
    }
    local nm `nm' index:_cons
    foreach v of local ivars {
        local nm `nm' index:`v'
    }
    matrix colnames `BM' = `nm'
    matrix colnames `VM' = `nm'
    matrix rownames `VM' = `nm'
    if `ni' > 0 matrix colnames `G2M' = _cons `ivars'
    else        matrix colnames `G2M' = _cons

    ereturn post `BM' `VM', esample(`touse') depname(`depv') obs(`nobs')
    ereturn scalar N        = `nobs'
    ereturn scalar sn       = `SN'
    ereturn scalar ssr      = `SSR'
    ereturn scalar ssr_lin  = `SSR0'
    ereturn scalar bwidth   = `BW'
    ereturn scalar threshold = `THR'
    ereturn scalar k_base   = `KN'
    ereturn scalar k_shift  = `KT'
    ereturn scalar k_index  = `KZ'
    ereturn scalar n_eval   = `NEV'
    ereturn scalar N_above  = `NHI'
    ereturn scalar N_below  = `nobs' - `NHI'
    ereturn scalar K_min    = `KMIN'
    ereturn scalar K_max    = `KMAX'
    ereturn scalar gridn    = `gridn'
    ereturn scalar refine   = `refine'
    ereturn scalar hac      = `hac'
    ereturn scalar vfailed  = `RC'
    ereturn local  cmd       "tvtindex"
    ereturn local  cmdline   "tvtindex `0'"
    ereturn local  depvar    "`depv'"
    ereturn local  indepvars "`xvars'"
    ereturn local  shiftvars "`svar'"
    ereturn local  threshvar "`threshvar'"
    ereturn local  ivars     "`ivars'"
    ereturn local  title     "Smoothed LS threshold regression on an index"
    ereturn local  vcetype   = cond(`hac'>0, "HAC", "Robust")
    ereturn matrix gamma2 = `G2M'
    ereturn matrix path   = `IDXM'

    Display, level(`level')
end

* ---------------------------------------------------------------------
program define Display
    version 15
    syntax [, Level(cilevel) ]

    local iv "`e(ivars)'"
    local ni : word count `iv'

    display ""
    display as text "`e(title)'" ///
        _col(52) "Number of obs" _col(68) "=" _col(71) as result %9.0fc e(N)
    display as text "Seo and Linton (2005)" ///
        _col(52) as text "Bandwidth" _col(68) "=" ///
        _col(71) as result %9.5f e(bwidth)
    display as text "Index leads on: " as result "`e(threshvar)'" ///
        _col(52) as text "Criterion evals" _col(68) "=" ///
        _col(71) as result %9.0fc e(n_eval)
    display ""
    display as text "{hline 78}"
    display as text "  The regime is decided by the sign of a LINEAR INDEX:"
    local eq = "    index = `e(threshvar)' + " + string(e(threshold)*-1, "%9.0g")
    forvalues j = 1/`ni' {
        local zz : word `j' of `iv'
        local cf = _b[index:`zz']
        local sgn = cond(`cf' < 0, " - ", " + ")
        local eq = "`eq'" + "`sgn'" + string(abs(`cf'), "%9.0g") + " `zz'"
    }
    if `ni' == 0 {
        display as text "    index = `e(threshvar)' - " as result ///
            %9.0g e(threshold)
        display as text "  so the shift applies where " as result ///
            "`e(threshvar)' > " %9.0g e(threshold)
    }
    else {
        display as text "`eq'"
        display as text "  and the shift applies where that index is" ///
            " POSITIVE."
    }
    display as text "    observations above / below" _col(34) as result ///
        %6.0f e(N_above) as text " /" as result %6.0f e(N_below)
    display as text "{hline 78}"

    ereturn display, level(`level')

    display as text "{hline 78}"
    display as text "  SSR: linear " as result %12.4f e(ssr_lin) ///
        as text "   smoothed threshold " as result %12.4f e(ssr)
    display as text "{hline 78}"
    display as text "  {bf:base} is the coefficient in the lower regime;" ///
        " {bf:shift} is what is ADDED"
    display as text "  where the index is positive. {bf:index} holds the" ///
        " threshold parameters,"
    display as text "  and their standard errors are the point of this" ///
        " estimator: the"
    display as text "  threshold estimate is ASYMPTOTICALLY NORMAL, so" ///
        " those t-statistics"
    display as text "  are ordinary ones. {bf:index:_cons} is minus the" ///
        " threshold level."
    if e(vfailed) {
        display as text "{hline 78}"
        display as error "  The Hessian in the index parameters was not" ///
            " invertible, so NO"
        display as error "  standard errors are reported for them. The" ///
            " criterion is flat or"
        display as error "  the optimum sits at a saddle: try a larger" ///
            " {bf:bwidth()}, or more"
        display as error "  {bf:refine()} rounds."
    }
    if e(K_min) < -0.05 | e(K_max) > 1.05 {
        display as text "{hline 78}"
        display as text "  Note: the kernel took values in [" as result ///
            %6.3f e(K_min) as text ", " as result %6.3f e(K_max) ///
            as text "]. K is a"
        display as text "  HIGHER-ORDER smoothed indicator, so it is not" ///
            " monotone and may"
        display as text "  leave [0,1]. That is the paper's own kernel," ///
            " not a defect."
    }
    display as text "{hline 78}"
    display as text "  The bandwidth is " as result %8.5f e(bwidth) ///
        as text ". SMALLER IS BETTER for estimation here:"
    display as text "  the rate is sqrt(n/bandwidth), the opposite of a" ///
        " density bandwidth."
end
