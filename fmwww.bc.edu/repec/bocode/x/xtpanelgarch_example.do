* xtpanelgarch_example.do  --  worked examples and validation checks
* Dr Merwan Roudane (merwanroudane920@gmail.com), github.com/merwanroudane
clear
set more off

* ---------------------------------------------------------------------------
* 1. N = 1: cg reproduces Stata's arch (GARCH(1,1), constant mean)
* ---------------------------------------------------------------------------
webuse wpi1, clear
gen dlw = D.ln_wpi
gen id = 1
xtset id t
arch dlw if t > tq(1960q2), arch(1) garch(1)
scalar ll_arch = e(ll)
xtpanelgarch cg dlw if t > tq(1960q2), arch(1) garch(1) vce(opg)
di as txt "arch ll = " %12.6f ll_arch "   cg ll = " %12.6f e(ll)

* ---------------------------------------------------------------------------
* 2. Grunfeld: CG (2001, sec. 7.1) pre-tests and Model D
* ---------------------------------------------------------------------------
webuse grunfeld, clear
keep if inlist(company, 1, 2, 3, 4, 8)
xtset company year
xtpanelgarch pretest invest mvalue kstock, haclags(2)
xtpanelgarch cg invest mvalue kstock, arch(1) model(A) nolog
estimates store A
xtpanelgarch cg invest mvalue kstock, arch(1) model(D) nolog
estimates store D
lrtest A D
estat diagnostics, lags(4)
estat volatility, sd

* ---------------------------------------------------------------------------
* 3. Simulated feasible panel GARCH (Asai 2023, sec. 3.3 design), N = 5, T = 500
* ---------------------------------------------------------------------------
set seed 12345
mata:
void xtpg_example_dgp(real scalar n, real scalar T)
{
    real matrix Sig, H, u, x, y
    real scalar t, i, j, burn
    burn = 200
    Sig = J(n, n, .)
    for (i = 1; i <= n; i = i + 1) {
        for (j = 1; j <= n; j = j + 1) Sig[i, j] = (-0.4)^abs(i - j)
    }
    H = Sig
    u = J(T + burn, n, 0)
    x = runiform(T + burn, n)
    y = J(T + burn, n, 0)
    for (t = 1; t <= T + burn; t = t + 1) {
        if (t > 1) H = 0.02 * Sig + 0.04 * u[t - 1, .]' * u[t - 1, .] + 0.94 * H
        u[t, .] = (cholesky(H) * rnormal(n, 1, 0, 1))'
        if (t > 1) y[t, .] = (1..n) / n + 0.6 * y[t - 1, .] + x[t, .] + u[t, .]
    }
    st_matrix("XTPG_Y", y[(burn + 1)..(T + burn), .])
    st_matrix("XTPG_X", x[(burn + 1)..(T + burn), .])
}
xtpg_example_dgp(5, 500)
end
clear
set obs 500
gen t = _n
forvalues i = 1/5 {
    gen double y`i' = XTPG_Y[_n, `i']
    gen double x`i' = XTPG_X[_n, `i']
}
reshape long y x, i(t) j(id)
xtset id t
* truth: phi = .6, beta = 1, alpha_i = i/5, gamma = .04, phi_garch = .94
xtpanelgarch vt y L.y x
estat pd
xtpanelgarch vt y L.y x, ccp
estat correlation
* full ML with common covariance dynamics (CG 2006 Model 2) on the same data
xtpanelgarch cg y L.y x, arch(1) garch(1) model(D) cov(common) nolog
estat pd

* ---------------------------------------------------------------------------
* 4. Composite likelihood (Pakel, Shephard and Sheppard 2011), N = 20, T = 1000
* ---------------------------------------------------------------------------
set seed 54321
mata:
void xtpg_example_pss(real scalar N, real scalar T)
{
    real matrix y
    real rowvector g, rho, eps, h
    real scalar t, ut
    g = 0.02 :+ 0.03 * runiform(1, N)
    rho = 0.5 :+ 0.4 * runiform(1, N)
    y = J(T, N, .)
    h = g
    for (t = 1; t <= T; t = t + 1) {
        ut = rnormal(1, 1, 0, 1)
        eps = rho * ut + sqrt(1 :- rho :^ 2) :* rnormal(1, N, 0, 1)
        if (t > 1) h = g * 0.02 + 0.05 * y[t - 1, .] :^ 2 + 0.93 * h
        y[t, .] = sqrt(h) :* eps
    }
    st_matrix("XTPG_R", y)
}
xtpg_example_pss(20, 1000)
end
clear
set obs 1000
gen t = _n
forvalues i = 1/20 {
    gen double r`i' = XTPG_R[_n, `i']
}
reshape long r, i(t) j(id)
xtset id t
* truth: alpha = .05, beta = .93
xtpanelgarch cl r, macgyver

* ---------------------------------------------------------------------------
* 5. Panel ARMA-GARCH (Su and Zhu 2024, DGP 5.1), N = 30, T = 150
* ---------------------------------------------------------------------------
set seed 2024
mata:
void xtpg_example_sz(real scalar N, real scalar T)
{
    real matrix y, x, u, h
    real rowvector mu, om
    real scalar t, burn
    burn = 100
    mu = rnormal(1, N, 0, 1)
    om = 1 :+ 2 * runiform(1, N)
    x = rnormal(T + burn, N, 0, 1)
    y = J(T + burn, N, 0)
    u = J(T + burn, N, 0)
    h = J(T + burn, N, 0)
    for (t = 1; t <= T + burn; t = t + 1) {
        if (t == 1) h[t, .] = om
        if (t > 1) h[t, .] = om * 0.4 + 0.2 * u[t - 1, .] :^ 2 + 0.4 * h[t - 1, .]
        u[t, .] = sqrt(h[t, .]) :* rnormal(1, N, 0, 1)
        if (t == 1) y[t, .] = mu + 3 * x[t, .] + u[t, .]
        if (t > 1) y[t, .] = mu + 3 * x[t, .] + 0.3 * y[t - 1, .] + 0.3 * u[t - 1, .] + u[t, .]
    }
    st_matrix("XTPG_Y", y[(burn + 1)..(T + burn), .])
    st_matrix("XTPG_X", x[(burn + 1)..(T + burn), .])
}
xtpg_example_sz(30, 150)
end
clear
set obs 150
gen t = _n
forvalues i = 1/30 {
    gen double y`i' = XTPG_Y[_n, `i']
    gen double x`i' = XTPG_X[_n, `i']
}
reshape long y x, i(t) j(id)
xtset id t
* truth: beta = 3, phi = .3, psi = .3, tau = .2, nu = .4
xtpanelgarch armagarch y x, ar(1) ma(1) arch(1) garch(1) bias(jackknife)
estat effects

* ---------------------------------------------------------------------------
* 6. Panel quantile GARCH (Zhu, Li, Zhang and Li 2026, DGP 12), N = 20, T = 800
* ---------------------------------------------------------------------------
set seed 2026
mata:
void xtpg_example_qg(real scalar N, real scalar T)
{
    real matrix y
    real scalar t, i, burn, u, q, b, w, a, TT
    real colvector ay, pw
    burn = 200
    TT = T + burn
    y = J(TT, N, 0)
    for (t = 1; t <= TT; t = t + 1) {
        for (i = 1; i <= N; i = i + 1) {
            u = runiform(1, 1)
            q = invnormal(u)
            w = 0.3 * q
            a = 0.75 * q
            b = 0.2 + 0.01 * abs(u - 0.5)
            if (i <= N / 2) {
                w = 0.6 * q
                a = 0.35 * q
                b = 0.6 + 0.05 * abs(u - 0.5)
            }
            y[t, i] = w
            if (t >= 2) {
                ay = abs(y[(t - 1)::1, i])
                pw = b :^ (0::(t - 2))
                y[t, i] = w + a * cross(pw, ay)
            }
        }
    }
    st_matrix("XTPG_Q", y[(burn + 1)..TT, .])
}
xtpg_example_qg(20, 800)
end
clear
set obs 800
gen t = _n
forvalues i = 1/20 {
    gen double r`i' = XTPG_Q[_n, `i']
}
reshape long r, i(t) j(id)
xtset id t
* truth at tau = .05: units 1-10 (w,a,b) = (-.987,-.576,.623); units 11-20 (-.493,-1.234,.205)
xtpanelgarch qgarch r, quantile(0.05)
predict double var05, quantile

* ---------------------------------------------------------------------------
* 7. Hierarchical GARCH (Brownlees 2019), small design: N = 40, T = 400
* ---------------------------------------------------------------------------
set seed 1695649
mata:
void xtpg_example_hg(real scalar N, real scalar T)
{
    real matrix R
    real colvector f, b, h, l, x1
    real scalar t, i, hm, hi, e2
    x1 = rnormal(N, 1, 0, 1)
    b = 1 :+ 0.2 * x1 + sqrt(0.05) * rnormal(N, 1, 0, 1)
    h = exp(-7 :+ 0.2 * x1 + sqrt(0.10) * rnormal(N, 1, 0, 1))
    l = normal(-1.5 :+ sqrt(0.05) * rnormal(N, 1, 0, 1))
    f = J(T, 1, 0)
    hm = 1e-3
    for (t = 1; t <= T; t = t + 1) {
        if (t > 1) hm = 1e-5 + 0.02 * f[t - 1]^2 + 0.97 * hm
        f[t] = sqrt(hm) * rnormal(1, 1, 0, 1)
    }
    R = J(T, N, 0)
    for (i = 1; i <= N; i = i + 1) {
        hi = h[i]
        e2 = h[i]
        for (t = 1; t <= T; t = t + 1) {
            if (t > 1) hi = 0.01 * h[i] + 0.99 * (l[i] * e2 + (1 - l[i]) * hi)
            e2 = hi * rnormal(1, 1, 0, 1)^2
            R[t, i] = b[i] * f[t] + sign(runiform(1, 1) - 0.5) * sqrt(e2)
        }
    }
    st_matrix("XTPG_HR", R)
    st_matrix("XTPG_HF", f)
    st_matrix("XTPG_HX", x1)
}
xtpg_example_hg(40, 400)
end
clear
set obs 400
gen t = _n
gen double mkt = XTPG_HF[_n, 1]
forvalues i = 1/40 {
    gen double r`i' = XTPG_HR[_n, `i']
}
reshape long r, i(t) j(id)
gen double size = XTPG_HX[id, 1]
xtset id t
xtpanelgarch hgarch r, characteristics(size) factor(mkt) fixpi(0.99) draws(50) nolog

* ---------------------------------------------------------------------------
* 8. Bayesian clustering (Bauwens and Rombouts 2007), J = 40, T = 600, G = 2
* ---------------------------------------------------------------------------
set seed 2007
mata:
void xtpg_example_br(real scalar N, real scalar T)
{
    real matrix Y
    real scalar i, t, g, h, a, b
    Y = J(T, N, 0)
    for (i = 1; i <= N; i = i + 1) {
        a = 0.04
        b = 0.90
        if (i > N / 2) {
            a = 0.20
            b = 0.40
        }
        h = 1
        for (t = 1; t <= T; t = t + 1) {
            if (t > 1) h = (1 - a - b) + a * Y[t - 1, i]^2 + b * h
            Y[t, i] = sqrt(h) * rnormal(1, 1, 0, 1)
        }
    }
    st_matrix("XTPG_BR", Y)
}
xtpg_example_br(40, 600)
end
clear
set obs 600
gen t = _n
forvalues i = 1/40 {
    gen double y`i' = XTPG_BR[_n, `i']
}
reshape long y, i(t) j(id)
xtset id t
xtpanelgarch cluster y, groups(2) alphaprior(.001 .10 .10 .30) betaprior(.60 .98 .20 .70) burn(100) draws(300) nolog

* ---------------------------------------------------------------------------
* 9. BNP panel MS-GARCH (Casarin, Costantini and Osuntuyi 2024), N = 10, T = 200
* ---------------------------------------------------------------------------
set seed 2020
mata:
void xtpg_example_ms(real scalar N, real scalar T)
{
    real matrix Y
    real scalar i, t, k, h, u2
    real rowvector mu, g
    mu = (1, -1)
    g = (0.1, 0.5)
    Y = J(T, N, 0)
    for (i = 1; i <= N; i = i + 1) {
        k = 1
        h = 0.5
        u2 = 0.5
        for (t = 1; t <= T; t = t + 1) {
            if (t > 1) {
                if (runiform(1, 1) > 0.97) k = 3 - k
            }
            h = g[k] + 0.05 * u2 + 0.8 * h
            Y[t, i] = mu[k] + sqrt(h) * rnormal(1, 1, 0, 1)
            u2 = (Y[t, i] - mu[k])^2
        }
    }
    st_matrix("XTPG_MS", Y)
}
xtpg_example_ms(10, 200)
end
clear
set obs 200
gen t = _n
forvalues i = 1/10 {
    gen double y`i' = XTPG_MS[_n, `i']
}
reshape long y, i(t) j(id)
xtset id t
xtpanelgarch msgarch y, states(2) burn(200) draws(300) nolog
