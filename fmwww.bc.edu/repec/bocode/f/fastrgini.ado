*! version 1.1  09oct2026  L. Chauvel -- built on the logic of fastgini 1.0 (Z. Sajaia, 2007)
*! G     : Gini of y
*! rG    : Gini of 1/y (reciprocal Gini, Ryu 2013 "pgini")
*! mG    : (G + rG)/2              bilateral level   (lG in the paper)
*! sG    : (G - rG)/(G + rG)       signed orientation (oG in the paper)
*! A2    : Atkinson eps=2 = 1 - 1/(E(y)E(1/y)), reciprocal-invariant benchmark
*! p_pd  : (1 - rG)/2  quantile below which marginal progressive transfers lower rG and mG
*! fastrgini y0 y1 : comparison on the common sample; with jk, paired jackknife s.e. of differences

program define fastrgini, rclass
    version 10
    syntax varlist(numeric min=1 max=2) [if] [in] [pweight fweight aweight iweight] ///
        [, BIN(numlist integer min=1 max=1 >0) noCHeck JK Level(cilevel)]

    local nv : word count `varlist'
    marksample touse
    if missing("`check'") {
        foreach v of local varlist {
            quietly count if `v' <= 0 & `touse'
            if r(N) > 0 {
                display as text "Warning: `v' has " r(N) " values <= 0. Not used in calculations"
            }
            quietly replace `touse' = 0 if `v' <= 0
        }
    }

    if "`jk'" != "" & "`bin'" != "" {
        display as error "options jk and bin may not be combined"
        exit 198
    }
    if inlist("`weight'", "aweight", "iweight") {
        display as text "(`weight's treated as pweights)"
        local weight "pweight"
    }

    tempvar w
    if "`exp'" != "" quietly generate double `w' `exp' if `touse'
    else             quietly generate double `w' = 1  if `touse'
    if "`weight'" == "fweight" {
        capture assert `w' == int(`w') & `w' >= 0 if `touse'
        if _rc {
            display as error "frequency weights must be nonnegative integers"
            exit 401
        }
    }
    quietly replace `touse' = 0 if `w' <= 0 | missing(`w')
    quietly count if `touse'
    local ct = r(N)
    if `ct' == 0 error 2000

    local pw = ("`weight'" == "pweight")
    tempname RES SE
    mata: _fastrgini_call("`varlist'", "`w'", "`touse'", `pw', ("`jk'" != ""), ///
        strtoreal("`bin'"), "`RES'", "`SE'")

    local names G rG mG sG A2 p_pd
    local labG    "G     Gini of y"
    local labrG   "rG    Gini of 1/y"
    local labmG   "mG    (G+rG)/2"
    local labsG   "sG    (G-rG)/(G+rG)"
    local labA2   "A2    Atkinson(2)"
    local labp_pd "p_pd  (1-rG)/2"
    tempname z
    scalar `z' = invnormal((100 + `level')/200)
    local lvl = strsubdp("`level'")

    *======================== one variable =====================================
    if `nv' == 1 {
        display as text _n "Gini family for `varlist'" _col(52) "Number of obs = " as result %9.0g `ct'
        if "`bin'" != "" display as text "(computed on `bin' log-scale bins)"
        if "`jk'" == "" {
            display as text "{hline 26}{c TT}{hline 12}"
            display as text %-26s "" "{c |}" %11s "Estimate"
            display as text "{hline 26}{c +}{hline 12}"
            local r = 0
            foreach s of local names {
                local ++r
                display as text %-26s "`lab`s''" "{c |}" as result %11.7f `RES'[`r',1]
            }
            display as text "{hline 26}{c BT}{hline 12}"
        }
        else {
            display as text "{hline 26}{c TT}{hline 50}"
            display as text %-26s "" "{c |}" %11s "Estimate" %11s "Jk s.e." ///
                %27s "[`lvl'% Conf. Interval]"
            display as text "{hline 26}{c +}{hline 50}"
            local r = 0
            foreach s of local names {
                local ++r
                display as text %-26s "`lab`s''" "{c |}" as result ///
                    %11.7f `RES'[`r',1] %11.7f `SE'[`r',1] ///
                    %13.7f `RES'[`r',1] - `z'*`SE'[`r',1] %13.7f `RES'[`r',1] + `z'*`SE'[`r',1]
            }
            display as text "{hline 26}{c BT}{hline 50}"
        }
        local r = 0
        foreach s of local names {
            local ++r
            return scalar `s' = `RES'[`r',1]
            if "`jk'" != "" return scalar se_`s' = `SE'[`r',1]
        }
        matrix `RES' = `RES'[1..6, 1]
        matrix colnames `RES' = `varlist'
        matrix rownames `RES' = `names'
        if "`jk'" != "" {
            matrix `SE' = `SE'[1..6, 1]
            matrix colnames `SE' = `varlist'
            matrix rownames `SE' = `names'
            return matrix se = `SE'
        }
        return matrix results = `RES'
    }

    *======================== two variables ====================================
    else {
        local v1 : word 1 of `varlist'
        local v2 : word 2 of `varlist'
        display as text _n "Gini family: `v1' vs `v2' (common sample)" ///
            _col(52) "Number of obs = " as result %9.0g `ct'
        if "`bin'" != "" display as text "(computed on `bin' log-scale bins, separately for each variable)"
        local a1 = abbrev("`v1'", 10)
        local a2 = abbrev("`v2'", 10)
        if "`jk'" == "" {
            display as text "{hline 26}{c TT}{hline 48}"
            display as text %-26s "" "{c |}" %12s "`a1'" %12s "`a2'" %12s "Diff" %12s "% change"
            display as text "{hline 26}{c +}{hline 48}"
            local r = 0
            foreach s of local names {
                local ++r
                display as text %-26s "`lab`s''" "{c |}" as result ///
                    %12.7f `RES'[`r',1] %12.7f `RES'[`r',2] %12.7f `RES'[`r',3] %12.3f `RES'[`r',4]
            }
            display as text "{hline 26}{c BT}{hline 48}"
            display as text "Diff = `v2' - `v1';  % change = 100*(`v2'/`v1' - 1)"
        }
        else {
            display as text "{hline 26}{c TT}{hline 62}"
            display as text %-26s "" "{c |}" %12s "`a1'" %12s "`a2'" %12s "Diff" ///
                %12s "Jk s.e." %8s "z" %6s "P>|z|"
            display as text "{hline 26}{c +}{hline 62}"
            local r = 0
            foreach s of local names {
                local ++r
                local zz = `RES'[`r',3]/`SE'[`r',3]
                display as text %-26s "`lab`s''" "{c |}" as result ///
                    %12.7f `RES'[`r',1] %12.7f `RES'[`r',2] %12.7f `RES'[`r',3] ///
                    %12.7f `SE'[`r',3] %8.2f `zz' %6.3f 2*normal(-abs(`zz'))
                display as text %-26s "" "{c |}" as text ///
                    %12s "(" + string(`SE'[`r',1], "%8.6f") + ")" ///
                    %12s "(" + string(`SE'[`r',2], "%8.6f") + ")"
            }
            display as text "{hline 26}{c BT}{hline 62}"
            display as text "Diff = `v2' - `v1'; s.e. in parentheses; paired jackknife (same deletions in both)"
        }
        * returns: scalars for each variable and the differences
        local r = 0
        foreach s of local names {
            local ++r
            return scalar `s'_1 = `RES'[`r',1]
            return scalar `s'_2 = `RES'[`r',2]
            return scalar d_`s' = `RES'[`r',3]
            if "`jk'" != "" return scalar se_d_`s' = `SE'[`r',3]
        }
        matrix colnames `RES' = `v1' `v2' diff pct_change
        matrix rownames `RES' = `names'
        if "`jk'" != "" {
            matrix colnames `SE' = `v1' `v2' diff pct_change
            matrix rownames `SE' = `names'
            return matrix se = `SE'
        }
        return matrix results = `RES'
    }
    return scalar N = `ct'
    if "`weight'" != "" {
        quietly summarize `w' if `touse', meanonly
        return scalar sum_w = r(sum)
    }
end

mata:

// Weighted Gini on x sorted ascending: g = 1 - 2A/(W X),
// A = sum_k w_k (S_{k-1} + w_k x_k / 2), S = cumulative w*x.
// Leave-one-out (jk): pw=1 deletes the whole observation,
// pw=0 deletes one unit (frequency weights; w=1 when unweighted).
void _frg_gini(real colvector x, real colvector w, real scalar pw,
               real scalar jk, real matrix g, real matrix gi)
{
    real colvector wx, Sw, Swx, Wb, Sb, Ap
    real scalar W, X, A, n

    n   = rows(x)
    wx  = w :* x
    Sw  = runningsum(w)
    Swx = runningsum(wx)
    Wb  = Sw  - w
    Sb  = Swx - wx
    W   = Sw[n]
    X   = Swx[n]
    A   = quadsum(w :* Sb + w :* wx :* 0.5)
    g   = 1 - 2*A/(W*X)
    gi  = J(0, 1, .)
    if (jk) {
        if (pw) {
            Ap = A :- w:*Sb :- w:*wx:*0.5 :- wx:*(W :- Sw)
            gi = 1 :- 2*Ap :/ ((W :- w) :* (X :- wx))
        }
        else {
            Ap = A :- Sb :- x:*(W :- Wb :- 0.5)
            gi = 1 :- 2*Ap :/ ((W - 1) :* (X :- x))
        }
    }
}

// Estimates (6 x 1) and, with jk, leave-one-out values (n x 6) in the
// ORIGINAL observation order, so that two variables can be paired.
void _frg_one(real colvector x0, real colvector w0, real scalar pw,
              real scalar jk, real scalar bin, real matrix est, real matrix E)
{
    real colvector x, w, p, lx, b, xb, wb, mu_i, mr_i
    real matrix g, r, g_i, r_i
    real scalar n, W, X, XR, lo, hi, k, j
    real matrix Es

    x = x0
    w = w0
    if (!missing(bin)) {                   // aggregate on equal-width log bins
        lx = ln(x)
        lo = min(lx)
        hi = max(lx)
        if (hi > lo) {
            b  = floor((lx :- lo) :/ ((hi - lo)/bin)) :+ 1
            b  = b :- (b :> bin)
            xb = J(bin, 1, 0)
            wb = J(bin, 1, 0)
            for (k = 1; k <= rows(x); k++) {
                j     = b[k]
                wb[j] = wb[j] + w[k]
                xb[j] = xb[j] + w[k]*x[k]
            }
            p = select((1::bin), wb :> 0)
            w = wb[p]
            x = xb[p] :/ w                    // bin represented by its weighted mean
        }
    }

    p = order(x, 1)
    x = x[p]
    w = w[p]
    n = rows(x)

    g = .
    r = .
    g_i = J(0, 1, .)
    r_i = J(0, 1, .)
    _frg_gini(x, w, pw, jk, g, g_i)
    _frg_gini(1 :/ x[n..1], w[n..1], pw, jk, r, r_i)

    W  = quadsum(w)
    X  = quadsum(w :* x)
    XR = quadsum(w :/ x)
    est = (g \ r \ (g + r)/2 \ (g - r)/(g + r) \ 1 - W*W/(X*XR) \ (1 - r)/2)

    E = J(0, 6, .)
    if (jk) {
        r_i = r_i[n..1]
        if (pw) {
            mu_i = (X :- w:*x)  :/ (W :- w)
            mr_i = (XR :- w:/x) :/ (W :- w)
        }
        else {
            mu_i = (X :- x)     :/ (W - 1)
            mr_i = (XR :- 1:/x) :/ (W - 1)
        }
        Es = (g_i, r_i, (g_i + r_i):/2, (g_i - r_i):/(g_i + r_i),
              1 :- 1:/(mu_i:*mr_i), (1 :- r_i):/2)
        E = J(n, 6, .)
        E[p, .] = Es                          // back to original order
    }
}

real scalar _frg_jkse(real colvector e, real colvector w, real scalar pw)
{
    real matrix MV
    real scalar n, W

    n = rows(e)
    if (pw) {
        MV = quadmeanvariance(e)
        return(sqrt(MV[2, 1]*(n - 1)^2/n))
    }
    W  = quadsum(w)
    MV = quadmeanvariance(e, w)
    return(sqrt(MV[2, 1]*(W - 1)^2/W))
}

void _fastrgini_call(string scalar vlist, string scalar wvar, string scalar touse,
                     real scalar pw, real scalar jk, real scalar bin,
                     string scalar resname, string scalar sename)
{
    real matrix D, E1, E2, Ed, Ep, RES, SE, e1, e2
    real colvector w
    real scalar nv, k

    nv = cols(tokens(vlist))
    D  = st_data(., (tokens(vlist), wvar), touse)
    w  = D[., nv + 1]

    e1 = J(0, 1, .)
    e2 = J(0, 1, .)
    E1 = J(0, 6, .)
    E2 = J(0, 6, .)
    _frg_one(D[., 1], w, pw, jk, bin, e1, E1)
    if (nv == 1) {
        RES = e1
        SE  = J(6, 1, .)
        if (jk) for (k = 1; k <= 6; k++) SE[k, 1] = _frg_jkse(E1[., k], w, pw)
    }
    else {
        _frg_one(D[., 2], w, pw, jk, bin, e2, E2)
        RES = (e1, e2, e2 - e1, 100*(e2 :/ e1 :- 1))
        SE  = J(6, 4, .)
        if (jk) {
            Ed = E2 - E1
            Ep = 100*(E2 :/ E1 :- 1)
            for (k = 1; k <= 6; k++) {
                SE[k, 1] = _frg_jkse(E1[., k], w, pw)
                SE[k, 2] = _frg_jkse(E2[., k], w, pw)
                SE[k, 3] = _frg_jkse(Ed[., k], w, pw)
                SE[k, 4] = _frg_jkse(Ep[., k], w, pw)
            }
        }
    }
    st_matrix(resname, RES)
    st_matrix(sename, SE)
}

end
