*! tvthomog 1.0.0  13oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Test whether a threshold is CONSTANT. The gateway command of TVTHRESH:
*! fail to reject and an ordinary constant-threshold command is the right
*! tool; reject and the rest of this library is what the data need.
*!
*! Lee, Y. and Y. Wang (2024) Econometric Theory 40(3):608-651,
*!   doi:10.1017/S0266466622000512  (DOI verified via Crossref 2026-10-13)
*!
*! See tvthomog.sthlp and validation/tvthresh/tvthomog_equation_map.md.

program define tvthomog, rclass sortpreserve
    version 15

    syntax varlist(numeric fv ts min=1) [if] [in] ,  ///
        THReshvar(varname numeric ts)                ///
        [ TRIM(real 0.10)                            ///
          GRIDn(integer 0)                           ///
          MINObs(integer 0)                          ///
          noCONStant                                 ///
          Direction(integer 0)                       ///
          DVector(numlist)                           ///
          BWidth(real -1)                            ///
          Level(cilevel) ]

    * ------------------------------------------------------------ checks
    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        display as error "the paper uses tau = 0.1, which is the default"
        exit 198
    }
    if `minobs' < 0 {
        display as error "{bf:minobs()} cannot be negative"
        exit 198
    }
    if `bwidth' != -1 & `bwidth' <= 0 {
        display as error "{bf:bwidth()} must be positive"
        display as error "omit it for the paper's rule of thumb,"
        display as error "sqrt(1/12) * n^(-1/5)"
        exit 198
    }

    * ----------------------------------------------------------- sample
    gettoken depv xvars : varlist
    marksample touse
    markout `touse' `depv' `xvars' `threshvar'
    quietly count if `touse'
    local nobs = r(N)
    if `nobs' < 40 {
        display as error "too few observations (`nobs'); this test needs at" ///
            " least 40"
        display as error "the statistic is a functional of two Brownian"
        display as error "bridges estimated nonparametrically, and it has"
        display as error "no useful size in a short sample"
        exit 2001
    }

    local hascons = cond("`constant'"=="", 1, 0)
    if "`xvars'" == "" & !`hascons' {
        display as error "with {bf:noconstant} there must be at least one" ///
            " regressor"
        exit 198
    }

    * the direction vector v of the paper's footnote 3: v is a USER choice,
    * "guided by the empirical context". Their tipping-point application
    * (sec. 5) takes v = (1,0,...,0)', which is what direction(j) gives --
    * e_j, the jth switching coefficient on its own. Their Monte Carlo
    * (sec. 4) instead takes v proportional to (1, 1/E[x2^2])', a weighted
    * combination, which is what dvector() is for. The limit does not
    * depend on v as long as v'v = 1 (Theorem 1), so the test is valid
    * either way; power is not invariant, and the paper's choice is the one
    * to use when reproducing the paper.
    local kx : word count `xvars'
    local kfull = `kx' + `hascons'
    if `direction' != 0 & "`dvector'" != "" {
        display as error "{bf:direction()} and {bf:dvector()} both set the" ///
            " same object, v"
        display as error "direction(j) is shorthand for the unit vector" ///
            " e_j; dvector() gives v"
        display as error "outright. Specify one."
        exit 198
    }
    if "`dvector'" != "" {
        local nv : word count `dvector'
        if `nv' != `kfull' {
            display as error "{bf:dvector()} has `nv' element" ///
                cond(`nv'==1, "", "s") " but the model has `kfull'" ///
                " switching"
            display as error "coefficient" cond(`kfull'==1, "", "s") ": " ///
                "`xvars'" cond(`hascons', " _cons", "")
            display as error "The constant comes {bf:last}, as it does in" ///
                " e(b). The paper writes"
            display as error "x = (1, x2)' with the constant first, so a" ///
                " v taken from the paper"
            display as error "must be reordered."
            exit 198
        }
    }
    else {
        if `direction' == 0 local direction 1
        if `direction' < 1 | `direction' > `kfull' {
            display as error "{bf:direction()} must be between 1 and" ///
                " `kfull', the number of"
            display as error "switching coefficients (the regressors" ///
                cond(`hascons', " plus the constant", "") ")"
            exit 198
        }
    }

    * ---- locals the engine reads
    local qvar  "`threshvar'"
    local vpos  `direction'
    local dvec  "`dvector'"
    _tvt_drop

    mata: tvt_thomog()

    * ---- harvest EVERY engine result before anything else runs. A later
    *      r-class or e-class command would replace r()/e() wholesale, and
    *      a value read after that comes back missing with no error.
    tempname CT GAM
    scalar `CT'  = __tvt_ho_ct
    scalar `GAM' = __tvt_ho_gam
    local ssr  = __tvt_ho_ssr
    local r0   = __tvt_ho_r0
    local g0   = __tvt_ho_g0
    local bw   = __tvt_ho_bw
    local nn   = __tvt_ho_n
    local kk   = __tvt_ho_k
    local ng   = __tvt_ho_ng
    local isp  = __tvt_ho_isp
    local sing = __tvt_ho_sing
    local rcnd = __tvt_ho_rcond
    local vpos = __tvt_ho_vpos
    tempname B VV
    matrix `B'  = __tvt_ho_b
    matrix `VV' = __tvt_ho_v
    _tvt_drop

    if `CT' >= . {
        if `sing' < . {
            display as error "the smoothed design moment D(r) is not" ///
                " invertible at rank `sing'"
            display as error "(reciprocal condition number " ///
                %8.1e `rcnd' ", after equilibrating out the"
            display as error "column scales; the guard is 1e-12)."
            display as error ""
            display as error "D(r) = E[x x' | q = Q(r)] is estimated from" ///
                " the observations whose"
            display as error "rank in `threshvar' is near that point. A" ///
                " regressor that is"
            display as error "constant -- or collinear with another --" ///
                " locally, over that stretch"
            display as error "of the threshold variable, makes D(r)" ///
                " degenerate {bf:even when the}"
            display as error "{bf:full-sample design matrix has full" ///
                " rank}. A dummy that switches"
            display as error "on only in one tail of `threshvar' is the" ///
                " usual cause."
            display as error ""
            display as error "Drop that regressor, or {bf:raise}" ///
                " {bf:trim()} so the affected tail is"
            display as error "excluded. Lowering {bf:trim()} makes it" ///
                " worse, not better."
            exit 498
        }
        * `isp' is missing when the engine declined before it was computed.
        * The `isp' < . test is not redundant: in Stata missing is LARGER
        * than every number, so a bare `isp' >= `nn' is true for missing and
        * would route an unrelated failure into this message.
        if `isp' < . & (`isp' == 0 | `isp' >= `nn') {
            display as error "the CT statistic is not defined on these" ///
                " data: one of the two"
            display as error "blocks of the statistic is empty."
            display as error ""
            display as error "The estimated threshold is at " ///
                as result %9.6g `GAM' as error ", rank " ///
                as result %5.3f `r0' as error " of " ///
                as result "`threshvar'" as error ","
            display as error "which rescales to g(r0) = " ///
                as result %10.3e `g0' as error ". The statistic averages" ///
                " over a grid of"
            display as error as result "`nn'" as error " points split at" ///
                " floor(g(r0) x N) = " as result `isp' as error ", so one" ///
                " side has no points"
            display as error "and the average over it is 0/0."
            display as error ""
            display as error "This is a discretisation limit, not a" ///
                " violation of the test's"
            display as error "conditions -- the threshold is inside the" ///
                " trimmed range. It"
            display as error "happens when the threshold is driven onto" ///
                " the lowest or highest"
            display as error "admissible candidate, which in turn happens" ///
                " when the fitted"
            display as error "model is badly misspecified. {bf:A larger" ///
                " sample is the fix};"
            display as error "{bf:raising} {bf:trim()} also helps, by" ///
                " moving the boundary inward."
            exit 498
        }
        display as error "the CT statistic is not defined on these data."
        display as error "The usual cause is the estimated threshold sitting"
        display as error "at the edge of the trimmed range: the paper needs"
        display as error "r0 strictly inside (tau, 1-tau), and at the edge"
        display as error "the standardisation divides by zero. Widen the"
        display as error "sample, lower {bf:trim()}, or check that the"
        display as error "threshold variable really does split the sample."
        exit 498
    }

    * ---------------------------------------------------- the critical values
    * Lee and Wang (2024) Table 1. The limit is the Cramer-von Mises
    * functional of a TWO-dimensional standard Brownian bridge,
    * integral_0^1 B2(t)'B2(t) dt, so the values are pivotal and tabulated --
    * nothing is bootstrapped here.
    *
    * The table's header is P(limit > cv), so the 0.950 column is the 5%
    * critical value. Read the other way round the test would be sized at
    * 95%, and the certification suite checks the direction explicitly.
    local cv80 = 0.467
    local cv85 = 0.527
    local cv90 = 0.600
    local cv925 = 0.666
    local cv95 = 0.745
    local cv975 = 0.888
    local cv99 = 1.067

    * the level actually asked for
    local cvuse = .
    local lvl = `level'
    if `lvl' == 90 local cvuse = `cv90'
    if `lvl' == 95 local cvuse = `cv95'
    if `lvl' == 99 local cvuse = `cv99'
    if `cvuse' >= . {
        * a level with no tabulated value: report the three standard ones
        * rather than interpolate a critical value the paper does not give
        local lvl 95
        local cvuse = `cv95'
        local interp 1
    }

    local rej = cond(`CT' > `cvuse', 1, 0)

    * -------------------------------------------------------------- display
    display ""
    display as text "Test of a homogeneous (constant) threshold" ///
        _col(52) "Number of obs" _col(68) "=" _col(71) as result %9.0fc `nn'
    display as text "Lee and Wang (2024), the CT test" ///
        _col(52) "Candidates" _col(68) "=" _col(71) as result %9.0f `ng'
    display as text "Threshold variable: " as result "`threshvar'" ///
        _col(52) as text "Bandwidth" _col(68) "=" ///
        _col(71) as result %9.5f `bw'
    display ""
    display as text "  H0: the threshold is the same for every observation"
    display as text "  H1: it is not"
    display as text "{hline 72}"
    display as text "  Threshold under H0" _col(34) as result %14.6g `GAM'
    display as text "  its quantile rank r0" _col(34) as result %14.4f `r0'
    display as text "  rescaled split g(r0)" _col(34) as result %14.4f `g0'
    display as text "  SSR under H0" _col(34) as result %14.4f `ssr'
    if "`dvector'" != "" {
        display as text "  direction v" _col(34) as result ///
            "   weighted (dvector)"
    }
    else {
        local vnames `xvars'
        if `hascons' local vnames `vnames' _cons
        local vnm : word `vpos' of `vnames'
        display as text "  direction v" _col(34) as result %14s "e(`vnm')"
    }
    display as text "{hline 72}"
    display as text "  CT statistic" _col(34) as result %14.4f `CT'
    display as text "{hline 72}"
    display as text "  Critical values (Lee-Wang Table 1; pivotal, not" ///
        " bootstrapped)"
    display as text "     10%" _col(14) as result %8.3f `cv90' ///
        as text _col(26) "5%" _col(32) as result %8.3f `cv95' ///
        as text _col(44) "1%" _col(50) as result %8.3f `cv99'
    display as text "{hline 72}"
    if `rej' {
        display as text "  " as result "REJECTED" as text " at the `lvl'%" ///
            " level: the threshold is {bf:not} constant."
        display as text "  A constant-threshold model is misspecified here." ///
            " Which of the"
        display as text "  time-varying specifications fits is a separate" ///
            " question --"
        display as text "  see {helpb tvthresh_choose}. This test says the" ///
            " threshold moves;"
        display as text "  it does {bf:not} estimate how."
    }
    else {
        display as text "  Not rejected at the `lvl'% level: no evidence" ///
            " against a constant"
        display as text "  threshold. A constant-threshold command is the" ///
            " right tool, and"
        display as text "  it is the more efficient one -- see" ///
            " {helpb tvthresh_choose}."
        display as text "  Failing to reject is not proof of constancy:" ///
            " the test has"
        display as text "  little power against a threshold that drifts" ///
            " slowly, which"
        display as text "  is exactly the case a Fourier specification is" ///
            " built for."
    }
    * A weakly conditioned D(r) is not the same thing as a singular one.
    * The refusal above fires only when the inverse carries no information
    * at all; between that and a healthy design there is a continuum, and a
    * regressor that is nearly constant over a stretch of the threshold
    * variable sits in it. Such a fit is computable and the test is still
    * valid, but a(r) is estimated imprecisely over that stretch, so the
    * user is told rather than left to find out.
    if `rcnd' < 1e-6 & `rcnd' < . {
        display as text ""
        display as text "  {bf:Note.} The smoothed design moment D(r) is" ///
            " weakly conditioned"
        display as text "  somewhere in the trimmed range (worst" ///
            " reciprocal condition"
        display as text "  number " as result %8.1e `rcnd' as text ///
            ", in global column units; a clean design is near 1)."
        display as text "  Some regressor is nearly constant, or nearly" ///
            " collinear with"
        display as text "  another, over part of the range of" ///
            " `threshvar' -- a dummy"
        display as text "  confined to one tail is the usual cause. The" ///
            " test remains"
        display as text "  valid, but the statistic is estimated" ///
            " imprecisely there."
        display as text "  Consider dropping that regressor or raising" ///
            " {bf:trim()}."
        display as text "  {cmd:r(rcond)} holds the number."
    }
    if "`interp'" != "" {
        display as text ""
        display as text "  ({bf:level(`level')} has no tabulated critical" ///
            " value in the paper."
        display as text "   Reported at 5%. Interpolating a critical value" ///
            " the paper"
        display as text "   does not give would be inventing it.)"
    }

    * --------------------------------------------------------- stored results
    return scalar CT        = `CT'
    return scalar gamma     = `GAM'
    return scalar reject    = `rej'
    return scalar level     = `lvl'
    return scalar cv        = `cvuse'
    return scalar cv90      = `cv90'
    return scalar cv95      = `cv95'
    return scalar cv99      = `cv99'
    return scalar r0        = `r0'
    return scalar g0        = `g0'
    return scalar ssr       = `ssr'
    return scalar bandwidth = `bw'
    return scalar N         = `nn'
    return scalar k         = `kk'
    return scalar n_grid    = `ng'
    return scalar trim      = `trim'
    return scalar direction = `vpos'
    return scalar i_split   = `isp'
    return scalar rcond     = `rcnd'
    return local  threshvar "`threshvar'"
    return local  depvar    "`depv'"
    return local  indepvars "`xvars'"
    return local  cmd       "tvthomog"
    return matrix v = `VV'
    return matrix b = `B'
end
