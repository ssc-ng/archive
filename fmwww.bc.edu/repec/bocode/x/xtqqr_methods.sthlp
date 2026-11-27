{smcl}
{* *! version 1.0.0  26nov2026}{...}
{vieweralsosee "xtqqr" "help xtqqr"}{...}
{vieweralsosee "xtqqkrls" "help xtqqkrls"}{...}
{vieweralsosee "xtqqplot" "help xtqqplot"}{...}
{viewerjumpto "The QQ model" "xtqqr_methods##qq"}{...}
{viewerjumpto "Panel extension" "xtqqr_methods##panel"}{...}
{viewerjumpto "Step-to-equation map: xtqqr" "xtqqr_methods##mapqq"}{...}
{viewerjumpto "Inference" "xtqqr_methods##inference"}{...}
{viewerjumpto "QQKRLS" "xtqqr_methods##krls"}{...}
{viewerjumpto "Step-to-equation map: xtqqkrls" "xtqqr_methods##mapkrls"}{...}
{viewerjumpto "Validation evidence" "xtqqr_methods##evidence"}{...}
{viewerjumpto "Choices the papers leave open" "xtqqr_methods##open"}{...}
{viewerjumpto "Author" "xtqqr_methods##author"}{...}
{title:Title}

{p 4 4 2}
{bf:xtqqr methods} {hline 2} Equations, implementation map and assumptions of the
panel quantile-on-quantile package


{marker qq}{...}
{title:1. The quantile-on-quantile model (Sim and Zhou 2015)}

{pstd}
Sim and Zhou (2015, eq. 3) write the theta-quantile of the outcome as an
unknown function of the regressor (their theta indexes y and tau indexes
x; {cmd:xtqqr} follows the now-standard applied notation, tau for y and
theta for x):

{p 8 8 2}
Q_tau(y_t | x_t) = beta^tau(x_t) + alpha(tau) z_t

{pstd}
The link function is linearised around x^theta, the theta-quantile of x
(eq. 4-5):

{p 8 8 2}
beta^tau(x_t) ~ b0(tau, theta) + b1(tau, theta) (x_t - x^theta)

{pstd}
and the two coefficients are estimated by the kernel-weighted local
linear quantile regression (the objective after eq. 6)

{p 8 8 2}
min_{b0,b1} Sum_t rho_tau( y_t - b0 - b1 (x_t - x^theta) - alpha z_t ) K( (F_n(x_t) - theta) / h )

{pstd}
with the empirical distribution F_n(x_t) = n^-1 Sum_k 1(x_k < x_t)
(eq. 7), a Gaussian kernel and h = 0.05. Because the kernel acts on ranks,
h is a share of the sample, not a unit of x.


{marker panel}{...}
{title:2. Panel extension}

{pstd}
With panel data (i = 1..N units, t = 1..T periods) the model becomes

{p 8 8 2}
Q_tau(y_it | x_it, z_it, a_i) = a_i + beta^tau(x_it) + z_it' g(tau)

{pstd}
Three treatments of a_i are offered:

{phang2}
{cmd:fe(canay)} {hline 1} Canay (2011): if a_i is a location shift,
a_i is estimated by the within (mean) regression of y on x, z (and time
dummies), a_i-hat = mean_t(y_it - x_it b - z_it'g), and the QQ objective is
applied to y~_it = y_it - a_i-hat. Consistent as N, T -> infinity.{p_end}
{phang2}
{cmd:fe(dummy)} {hline 1} unit dummies inside every local quantile
regression (Koenker 2004 with zero penalty): a_i may vary with tau; needs
large T and a large kernel window.{p_end}
{phang2}
{cmd:fe(none)} {hline 1} pooled QQ (Wu et al. 2021; Hassan et al. 2021).{p_end}

{pstd}
The reference distribution of x can be pooled (x^theta and F_n over all
it) or unit specific (x_i^theta and F_n,i within unit i, the centring
D_it - D_i^theta of Atsalakis et al. 2021).

{pstd}
The quantile-group variant ({cmd:method(groups)}) replaces the local linear
term by indicators of the quantile groups of x:

{p 8 8 2}
Q_tau(y_it | .) = a_i + Sum_{g=2..G} d_g(tau) 1(x_it in group g) + z_it' g(tau)

{pstd}
as in the panel quantile-on-quantile tables of Clance, Gozgor, Gupta and
Lau.


{marker mapqq}{...}
{title:3. Step-to-equation map: xtqqr}

{p2colset 5 30 32 2}{...}
{p2col:{it:Code step}}{it:Equation / source}{p_end}
{p2line}
{p2col:[S1] model}Sim and Zhou (2015) eq. 3, with a_i and z_it{p_end}
{p2col:[S2] x^theta, x - x^theta}eq. 4-5; {cmd:xqq_quant()} (type-7 quantile, = R and Stata _pctile with interpolation){p_end}
{p2col:[S3] F_n(x)}eq. 7, strict inequality, ties share a rank; {cmd:xqq_ecdf()}{p_end}
{p2col:[S4] weights, local QR}objective after eq. 6; weights K((F_n - theta)/h)/h, {helpb qreg} with {cmd:[iw]}{p_end}
{p2col:[S5] unit effects}Canay (2011) two step ({helpb areg}, {cmd:predict, d}) or dummies (Koenker 2004){p_end}
{p2col:[S6] validation}Sim and Zhou (2015) sec. 4; Wu et al. (2021): gamma(tau) = mean_theta b1(tau, theta) vs QR b(tau){p_end}
{p2line}
{p2colreset}{...}

{pstd}
Weights below 1e-8 of the largest weight are set to zero before the
quantile regression; with a Gaussian kernel and h = 0.05 these are
observations more than about 0.3 away from theta on the rank scale, whose
weight is numerically nil. The minimisation is otherwise exact
(linear programming in {cmd:qreg}).


{marker inference}{...}
{title:4. Inference}

{pstd}
For the weighted quantile regression with score psi_it = tau - 1(u_it < 0):

{p 8 8 2}
V = H^-1 J H^-1,   H = (2c)^-1 Sum w_it 1(|u_it| <= c) X_it X_it'

{p 8 8 2}
J = Sum_i s_i s_i',   s_i = Sum_t w_it psi_it X_it     (cluster, Parente and Santos Silva 2016)

{pstd}
{cmd:vce(robust)} sums over observations instead of units, {cmd:vce(iid)}
uses a common density. c follows the Hall-Sheather rule with Koenker's
robust scale, as in {cmd:qreg, vce(robust)}. The sandwich treats the
first-step a_i-hat and the ranks as known; {cmd:vce(bootstrap)} resamples
whole units and re-runs [S2]-[S5] in every replication, so it accounts for
both.


{marker krls}{...}
{title:5. Quantile-on-quantile KRLS}

{pstd}
KRLS (Hainmueller and Hazlett 2014) fits y = K c with the Gaussian kernel
K_ij = exp(-||x_i - x_j||^2 / sigma) on standardised inputs, solving
(K + lambda I) c = y, with lambda chosen by leave-one-out error and
sigma = number of inputs. The pointwise marginal effect of input d at
observation k is

{p 8 8 2}
dy/dx_k^(d) = -(2/sigma) Sum_i c_i exp(-||x_i - x_k||^2/sigma) (x_i^(d) - x_k^(d))

{pstd}
(Adebayo et al. 2024, eq. 1; Sonail et al. 2026, eq. 3), and the average
effect is its sample mean, with analytic variance from Var(c).

{pstd}
QQKRLS (Adebayo et al. 2024, eq. 2) evaluates these effects across the
quantiles of x (theta) and reports quantiles (tau) of them. The paper does
not spell out the regime construction; {cmd:xtqqkrls} follows the
reference implementations (x <= Q_theta(x); KRLS on the regime;
tau-quantile of the pointwise effects) and offers a local band as an
alternative. Sonail et al. (2026, eq. 4) apply it to country-year panels
with weights j_it per cross-section and period, which is the KRLS fit on
the pooled observations of the regime.


{marker mapkrls}{...}
{title:6. Step-to-equation map: xtqqkrls}

{p2colset 5 30 32 2}{...}
{p2col:{it:Code step}}{it:Equation / source}{p_end}
{p2line}
{p2col:[K1] unit / time effects}optional within demeaning (extension; not in the papers){p_end}
{p2col:[K2] theta-regime}x <= Q_theta(x) (reference implementation) or |F_n(x) - theta| <= h{p_end}
{p2col:[K3] KRLS fit}Hainmueller and Hazlett (2014), via {cmd:krls} (SSC){p_end}
{p2col:[K4] pointwise effects}Adebayo et al. (2024) eq. 1; Sonail et al. (2026) eq. 3-4{p_end}
{p2col:[K5] beta(tau, theta)}Adebayo et al. (2024) eq. 2: tau-quantile of the regime's effects{p_end}
{p2col:[K6] cell s.e.}unit-block bootstrap (fast or refit){p_end}
{p2col:[K7] average effect}Hainmueller and Hazlett (2014): mean effect, analytic s.e.{p_end}
{p2line}
{p2colreset}{...}


{marker evidence}{...}
{title:7. Validation evidence}

{pstd}
Simulated panel: y_it = a_i + 0.5x + 0.5x 1(x>0) + 0.3z + (1 + 0.3x 1(x>0)) e,
x_it = 0.7a_i + v_it, so the unit effect is correlated with x. The true
slope is 0.5 for theta with x^theta < 0 and 1 + 0.3 Phi^-1(tau) above.

{p2colset 5 36 38 2}{...}
{p2col:{it:Check}}{it:Result}{p_end}
{p2line}
{p2col:Consistency, 50 -> 400 units}cluster s.e. fall at rate sqrt(N) (0.27 -> 0.095); estimates within about 1.5 s.e. of the truth{p_end}
{p2col:Coverage, h = 0.05, theta = 0.3}mean 0.538 (truth 0.5); MC sd 0.317 vs mean s.e. 0.309; 95% CI coverage 94.5%{p_end}
{p2col:Coverage, h = 0.05, theta = 0.8}mean 0.969 (truth 1); MC sd 0.299 vs mean s.e. 0.315; coverage 94.5%{p_end}
{p2col:Coverage, h = 0.15, theta = 0.3}mean 0.549; MC sd 0.067 vs s.e. 0.056; coverage 82% (smoothing bias){p_end}
{p2col:KRLS, theta = 0.3}pooled: 1.49 (biased by correlated a_i); {cmd:fe(within)}: 0.42 (truth 0.5){p_end}
{p2line}
{p2colreset}{...}

{pstd}
(200 replications, 60 units x 25 periods. The coverage experiment can be
re-run with the last, optional section of {cmd:xtqqr_example.do}.)


{marker open}{...}
{title:8. Choices the papers leave open, and what the package does}

{phang2}
o The standard errors of Sim and Zhou (2015) are not specified for panels:
the package uses the clustered Powell sandwich (Parente and Santos Silva
2016) and a block bootstrap.{p_end}
{phang2}
o Atsalakis et al. (2021) use the linear quantile mixed model of Geraci and
Bottai (2014) with Gauss-Hermite quadrature. That random-effects
likelihood is not implemented; {cmd:xtqqr} reproduces their unit-specific
centring with fixed-effect treatments instead.{p_end}
{phang2}
o The QQKRLS regime is not defined explicitly in Adebayo et al. (2024);
the package follows the reference implementations and documents it.{p_end}
{phang2}
o QQKRLS cell standard errors are not given in the papers: the package
uses a unit-block bootstrap.{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
{p_end}
