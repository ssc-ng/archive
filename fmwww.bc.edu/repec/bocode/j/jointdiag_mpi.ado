*! jointdiag_mpi 1.0.0  06oct2026
*! One-sided most-powerful-invariant joint test for AR(1) disturbances
*! AND heteroskedasticity.
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*
*  SOURCE
*   King & Evans (1984), Economics Letters 16, 297-302
*     H0 : u ~ N(0, sigma^2 I)
*     Ha+: u_1 = (1-rho^2)^(-1/2) e_1 ,  u_t = rho u_{t-1} + e_t ,
*          e ~ N(0, sigma^2 D),  D = diag(z_1,...,z_n), 0 < rho < 1
*     eq.(2) : reject H0 for SMALL values of
*                 r(rho1) = u~' Sigma^-1(rho1) u~ / e'e
*              where u~ is the GLS residual under Sigma(rho1) and e the
*              OLS residual.  Theorem 3 of King (1980) makes this MPI
*              against the simple alternative rho = rho1.
*     eq.(3) : the numerator is the OLS sum of squares of the model
*              transformed by R(rho) = D^(-1/2) G(rho)^-1
*     eq.(4)-(5): r(rho1) = sum v_i xi_i^2 / sum xi_i^2 with v_i the
*              non-zero eigenvalues of R(rho1)' M* R(rho1); the exact
*              null distribution follows by solving
*                 Pr[ sum (v_i - r*) xi_i^2 < 0 ] = alpha
*              which we do with Imhof's (1961) numerical inversion in
*              place of the FQUAD subroutine the paper used.
*     Their recommendation (p.299): rho1 = 0.5 against Ha+ and
*     rho1 = -0.5 against Ha-.
*
*  WHY ONE-SIDED: the Bera-Jarque LM test is two-sided, and King & Evans
*  Table 1 shows the power loss that costs -- at rho = 1.0 the one-sided
*  test has power .134 against .082 for the two-sided one.

program define jointdiag_mpi, rclass
    version 14.0

    syntax [anything] [if] [in] [,   ///
        Z(varname numeric)            ///
        RHO1(real 0.5)                ///
        NEGative                      ///
        Level(cilevel)                ///
        NOTABle                       ///
    ]

    _jd_parse `anything' `if' `in'
    local dv "`r(dv)'"
    local iv "`r(iv)'"
    local post = r(post)

    marksample touse, novarlist
    markout `touse' `dv' `iv' `z'
    if (`post') {
        tempvar esamp
        qui gen byte `esamp' = e(sample)
        qui replace `touse' = 0 if `esamp' == 0
    }

    if ("`negative'" != "" & `rho1' > 0) local rho1 = -`rho1'
    if (abs(`rho1') >= 1) {
        di as err "rho1() must lie strictly inside (-1, 1)"
        exit 198
    }
    if ("`z'" != "") {
        qui count if `touse' & `z' <= 0
        if (r(N) > 0) {
            di as err "z() must be strictly positive"
            exit 411
        }
    }

    tempname _h
    capture _estimates hold `_h', restore nullok

    tempname R
    mata: _jd_mpi_core("`dv'", "`iv'", "`z'", "`touse'", `rho1',  ///
                       (100 - `level') / 100, "`R'")

    local rstat = `R'[1,1]
    local rcrit = `R'[2,1]
    local pval  = `R'[3,1]
    local nn    = `R'[4,1]
    local emean = `R'[5,1]
    local evar  = `R'[6,1]

    if ("`notable'" == "") {
        local dir "positive autocorrelation (Ha+)"
        if (`rho1' < 0) local dir "negative autocorrelation (Ha-)"
        local zlab "z_t = 1 (pure AR(1) alternative)"
        if ("`z'" != "") local zlab "z_t = `z'"

        _jd_head "One-sided MPI joint test - King & Evans (1984)"           ///
                 "Model: `dv' on `iv'    (N = `nn')"                         ///
                 "H0: spherical N(0, sigma^2 I)    vs    `dir' AND heteroskedasticity"

        di as txt "  Heteroskedasticity structure : " as res "`zlab'"
        di as txt "  Point of maximum power rho1  : " as res %6.3f `rho1' ///
                  as txt "   (paper recommends +/- 0.5)"
        di as txt "{hline 78}"
        di as txt %-40s "  r(rho1)  test statistic" " {c |}" as res %14.6f `rstat'
        di as txt %-40s "  critical value (reject if BELOW)" " {c |}" as res %14.6f `rcrit'
        di as txt %-40s "  exact p-value (Imhof inversion)" " {c |}" as res %14.4f `pval'
        di as txt "{hline 78}"
        di as txt %-40s "  E[r(rho1)] under H0" " {c |}" as res %14.6f `emean'
        di as txt %-40s "  sd[r(rho1)] under H0" " {c |}" as res %14.6f sqrt(`evar')
        di as txt "{hline 78}"
        _jd_stars `pval'
        if (`rstat' < `rcrit') {
            di as res "  REJECT H0 `r(stars)'" as txt " - the data favour `dir'."
        }
        else {
            di as txt "  Do not reject H0 at the `=100-`level''% level."
        }
        di as txt ""
        di as txt "  The test is {bf:one-sided} and MPI in the neighbourhood of rho1."
        di as txt "  King & Evans (1984) Table 1: the two-sided LM alternative loses"
        di as txt "  roughly a third of its power in samples of this size."
        _jd_foot ""
    }

    return scalar r      = `rstat'
    return scalar crit   = `rcrit'
    return scalar p      = `pval'
    return scalar rho1   = `rho1'
    return scalar Er     = `emean'
    return scalar Vr     = `evar'
    return scalar N      = `nn'
    return local  cmd    "jointdiag mpi"
end



