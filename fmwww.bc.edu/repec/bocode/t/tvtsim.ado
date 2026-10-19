*! tvtsim 1.0.0  13oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Simulate a threshold model with a time-varying threshold.
*!
*! WHY THIS IS A SHIPPED COMMAND AND NOT A TEST FIXTURE. Every validation
*! study in this library needs data from a KNOWN threshold path, and every
*! one of the source papers specifies its own designs in its own notation.
*! Writing those by hand once per study is how a Monte Carlo ends up
*! testing a different DGP from the one it claims. Here each published
*! design is written once, named after the paper that defines it, and the
*! certification suites and the user get the same generator.
*!
*! The designs are those of
*!   Yang, L., C. Lee and I.-P. Chen (2021) Journal of Time Series Analysis
*!     42(4):406-430, doi:10.1111/jtsa.12574, equations (16)-(23)
*!   Lee, Y. and Y. Wang (2024) Econometric Theory 40(3):608-651,
*!     doi:10.1017/S0266466622000512, section 4
*!
*! See tvtsim.sthlp.

program define tvtsim, rclass
    version 15

    syntax [, N(integer 200)                       ///
              MODel(string)                        ///
              G0(real 0.5) G1(real 1) G2(real 1)   ///
              K(integer 1)                         ///
              B1(numlist min=2 max=2)              ///
              B2(numlist min=2 max=2)              ///
              Sigma(real 1)                        ///
              XSd(real 2)                          ///
              SEED(string)                         ///
              CLEAR ]

    if "`model'" == "" local model fourier
    local model = lower("`model'")
    local known fourier constant shift3 shift1 logistic twodip none
    local ok 0
    foreach m of local known {
        if "`model'" == "`m'" local ok 1
    }
    if !`ok' {
        display as error "unknown {bf:model(`model')}"
        display as error "it must be one of: `known'"
        display as error ""
        display as error "  fourier   a Fourier threshold, Yang-Lee-Chen" ///
            " Case 1(a)"
        display as error "  constant  a constant threshold at 0, Case 1(b)"
        display as error "  shift3    1, then 0.8 over the middle third," ///
            " then 1 -- Case 2(a)"
        display as error "  shift1    0.8, then 1 after 0.8T -- Case 2(b)"
        display as error "  logistic  a smooth logistic path -- Case 2(c)"
        display as error "  twodip    two smooth dips -- Case 2(d)"
        display as error "  none      no threshold at all (a linear model)"
        exit 198
    }
    if `n' < 10 {
        display as error "{bf:n()} must be at least 10"
        exit 198
    }
    if `sigma' <= 0 {
        display as error "{bf:sigma()} must be positive"
        exit 198
    }
    if `k' < 1 {
        display as error "{bf:k()} must be a positive integer"
        exit 198
    }

    * the paper's experiment 1 defaults: b11 = b21 = 10, b12 = 10, b22 = 20
    if "`b1'" == "" local b1 10 10
    if "`b2'" == "" local b2 10 20
    local b11 : word 1 of `b1'
    local b12 : word 2 of `b1'
    local b21 : word 1 of `b2'
    local b22 : word 2 of `b2'

    if "`clear'" != "" clear
    quietly describe
    if r(N) > 0 | r(k) > 0 {
        display as error "data in memory would be lost; specify" ///
            " {bf:clear}"
        exit 4
    }

    if "`seed'" != "" set seed `seed'

    quietly set obs `n'
    quietly generate int t = _n
    quietly tsset t

    * ---- the threshold path. Equations (17)-(22) of the paper, except
    *      "none", which has no threshold at all.
    quietly generate double gamma = .
    if "`model'" == "fourier" {
        quietly replace gamma = `g0' + `g1'*sin(2*_pi*`k'*t/`n') ///
                                     + `g2'*cos(2*_pi*`k'*t/`n')
    }
    if "`model'" == "constant" {
        quietly replace gamma = 0
    }
    if "`model'" == "shift3" {
        quietly replace gamma = 1
        quietly replace gamma = 0.8 if t >= `n'/3 & t <= 2*`n'/3
    }
    if "`model'" == "shift1" {
        quietly replace gamma = 0.8
        quietly replace gamma = 1 if t > 0.8*`n'
    }
    if "`model'" == "logistic" {
        quietly replace gamma = ///
            -1/(1 + exp(0.0005*(t - 0.75*`n')*(t - 0.2*`n'))) + 1.5
    }
    if "`model'" == "twodip" {
        * Equation (22) is printed with unbalanced brackets in the paper
        * AND in its Figure 1 caption. Two readings balance it; Figure 1(d)
        * settles the matter, because its two dips are UNEQUAL -- about 0
        * at 0.75T and about 0.5 at 0.2T -- which only this reading, with
        * the 1.5 multiplying the first bracket alone, can produce. See
        * validation/tvthresh/tvtfourier_equation_map.md.
        quietly replace gamma = 1.5*(1 - exp(-0.002*(t - 0.75*`n')^2)) ///
                              - exp(-0.001*(t - 0.2*`n')^2)
    }
    if "`model'" == "none" {
        quietly replace gamma = .
    }

    * ---- the data. (q, e) are standard normal and x is N(0, xsd^2),
    *      which is the paper's (16): x ~ N(0, 2^2), q and e ~ N(0,1).
    quietly generate double x = rnormal()*`xsd'
    quietly generate double q = rnormal()
    quietly generate double e = rnormal()*`sigma'

    quietly generate byte lower = .
    if "`model'" == "none" {
        quietly generate double y = `b11' + `b12'*x + e
    }
    else {
        quietly replace lower = (q <= gamma)
        quietly generate double y = cond(lower, `b11' + `b12'*x, ///
                                                `b21' + `b22'*x) + e
    }

    label variable t     "time"
    label variable y     "dependent variable"
    label variable x     "regressor"
    label variable q     "threshold variable"
    label variable gamma "TRUE threshold path"
    label variable lower "1 if in the lower regime"
    label variable e     "disturbance"

    quietly count if lower == 1
    local nlow = r(N)

    display as text "{hline 64}"
    display as text "tvtsim: " as result "`model'" as text ", n = " ///
        as result `n'
    display as text "{hline 64}"
    if "`model'" == "none" {
        display as text "  no threshold: y = " as result `b11' ///
            as text " + " as result `b12' as text "*x + e"
    }
    else {
        display as text "  lower regime (q <= gamma):  y = " ///
            as result `b11' as text " + " as result `b12' as text "*x + e"
        display as text "  upper regime (q >  gamma):  y = " ///
            as result `b21' as text " + " as result `b22' as text "*x + e"
        display as text "  observations below the threshold: " ///
            as result `nlow' as text " of " as result `n'
        if "`model'" == "fourier" {
            display as text "  gamma(t) = " as result `g0' ///
                as text " + " as result `g1' as text "*sin(2*pi*" ///
                as result `k' as text "*t/" as result `n' as text ")" ///
                " + " as result `g2' as text "*cos(...)"
        }
    }
    display as text "  sigma = " as result `sigma' ///
        as text ",  x ~ N(0, " as result `xsd' as text "^2)"
    display as text "{hline 64}"

    return scalar N       = `n'
    return scalar N_lower = `nlow'
    return scalar g0      = `g0'
    return scalar g1      = `g1'
    return scalar g2      = `g2'
    return scalar k       = `k'
    return scalar b11     = `b11'
    return scalar b12     = `b12'
    return scalar b21     = `b21'
    return scalar b22     = `b22'
    return scalar sigma   = `sigma'
    return local  model   "`model'"
end
