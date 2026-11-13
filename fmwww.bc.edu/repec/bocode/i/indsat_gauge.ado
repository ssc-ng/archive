*! indsat_gauge 1.0.0  12nov2026
*! Theory calculator for indicator saturation: cut-offs, gauge, its variance, Poisson
*! probabilities and the Johansen-Nielsen consistency / efficiency factors
*! Author: Dr Merwan Roudane  (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*  Santos-Hendry-Johansen (2008); Johansen-Nielsen (2009, 2016); Castle-Doornik-Hendry (2012)

program define indsat_gauge, rclass
    version 14.0
    syntax , T(integer) [ TPvals(numlist >0 <1) M(integer 1) ]
    if ("`tpvals'"=="") local tpvals "0.05 0.025 0.01 `=1/`t'' 0.005 0.001"
    numlist "`tpvals'"
    local grid "`r(numlist)'"
    local grid : list uniq grid
    local K : word count `grid'
    tempname G
    matrix `G' = J(`K', 10, .)
    di
    di as text "{bf:Indicator saturation under the null of no outliers/breaks} (T = `t', m = `m')"
    di as text "{hline 90}"
    di as text %8s "alpha" %7s "c" %9s "E[#]" %9s "sd(#)" %9s "P(0)" %9s "P(>=3)" %10s "sd(gauge)" %9s "xi" %9s "eta_m" %10s "Eff(beta)"
    di as text "{hline 90}"
    local i 0
    foreach a of local grid {
        local ++i
        mata: indsatg_calc(`a', `t', `m')
        matrix `G'[`i',1] = `a'
        matrix `G'[`i',2] = r(c)
        matrix `G'[`i',3] = `a'*`t'
        matrix `G'[`i',4] = r(sdn)
        matrix `G'[`i',5] = r(p0)
        matrix `G'[`i',6] = r(p3)
        matrix `G'[`i',7] = r(sdg)
        matrix `G'[`i',8] = r(xi)
        matrix `G'[`i',9] = r(eta)
        matrix `G'[`i',10] = 1/r(eta)^2
        di as res %8.4f `a' %7.3f r(c) %9.3f `a'*`t' %9.3f r(sdn) %9.4f r(p0) %9.4f r(p3) %10.5f r(sdg) %9.4f r(xi) %9.4f r(eta) %10.4f 1/r(eta)^2
    }
    di as text "{hline 90}"
    di as text "c = two-sided normal cut-off; E[#] = alpha*T false impulses (Santos-Hendry-Johansen 2008);"
    di as text "sd(#), sd(gauge): Johansen-Nielsen (2016) normal theory for the m-step gauge; P(0), P(>=3): Poisson(alpha*T);"
    di as text "xi = sigma consistency factor sqrt(psi/tau) (JN 2009); eta_m = s.e. inflation of beta after m steps;"
    di as text "Eff(beta) = 1/eta_m^2 efficiency relative to OLS. Rule of thumb: alpha = 1/T keeps one false impulse on average."
    matrix colnames `G' = alpha c expected sd_count p0 p3plus sd_gauge xi eta eff
    return matrix gauge = `G'
end

version 14.0
mata:
void indsatg_calc(real scalar alpha, real scalar T, real scalar m)
{
    real scalar c, fc, psi, tau, chi, rho, k, m1, eta1, etag, viis, rhob, eta
    c = abs(invnormal(alpha/2))
    fc = normalden(c)
    psi = normal(c) - normal(-c)
    tau = psi - 2*c*fc
    chi = 3*psi - 2*c*(c^2 + 3)*fc
    rho = (c^2 - tau/psi)*c*fc/tau
    k = 3
    m1 = m - 1
    eta1 = (((1 - rho^m1)/((1 - rho)*tau))^2 + 2*((1 - rho^m1)/((1 - rho)*tau))*rho^m1)*(chi - tau^2/psi)/(k - 1) + rho^(2*m1)
    etag = (c*fc)^2*eta1*(k - 1) + 2*c*fc*rho^(m - 1)*(tau - psi)
    viis = psi*(1 - psi) + etag
    rhob = 2*c*fc/psi
    eta = sqrt((((1 - rhob^m)/((1 - rhob)*psi))^2 + 2*(1 - rhob^m)/((1 - rhob)*psi)*rhob^m)*tau + rhob^(2*m))
    st_numscalar("r(c)", c)
    st_numscalar("r(sdg)", sqrt(viis/T))
    st_numscalar("r(sdn)", sqrt(viis*T))
    st_numscalar("r(p0)", poissonp(alpha*T, 0))
    st_numscalar("r(p3)", poissontail(alpha*T, 3))
    st_numscalar("r(xi)", 1/sqrt(tau/psi))
    st_numscalar("r(eta)", eta)
}
end
