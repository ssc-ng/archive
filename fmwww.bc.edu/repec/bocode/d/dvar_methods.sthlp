{smcl}
{* *! version 1.0.0  26nov2026}{...}
{vieweralsosee "dvar" "help dvar"}{...}
{viewerjumpto "Model" "dvar_methods##model"}{...}
{viewerjumpto "Estimation" "dvar_methods##estimation"}{...}
{viewerjumpto "Inference" "dvar_methods##inference"}{...}
{viewerjumpto "Sampling" "dvar_methods##sampling"}{...}
{viewerjumpto "DIRF" "dvar_methods##dirf"}{...}
{viewerjumpto "Forecast evaluation" "dvar_methods##forecast"}{...}
{viewerjumpto "Kernel model" "dvar_methods##kernel"}{...}
{viewerjumpto "Step map" "dvar_methods##map"}{...}
{viewerjumpto "Replication code" "dvar_methods##code"}{...}
{viewerjumpto "Author" "dvar_methods##author"}{...}
{title:Title}

{phang}
{bf:dvar methods} {hline 2} Methods and formulas for {helpb dvar}


{marker model}{...}
{title:1. Model (Wang, Oka and Zhu 2025, Section 2)}

{pstd}
Y_t = (Y_1t, ..., Y_Jt)' is a J-vector and Z_t = (Y_t-1', ..., Y_t-p')' holds
its lags. The object of interest is the conditional joint distribution
F(Y_t | Z_t). Define

{p 8 8 2}
X_1t = (1, Z_t')',  X_jt = (1, Z_t', Y_1t, ..., Y_j-1,t)',  j = 2, ..., J.

{pstd}
By the {it:distribution factorisation}, eq. (1),

{p 8 8 2}
F(Y_t | Z_t) = rho( F(Y_1t|X_1t), ..., F(Y_Jt|X_Jt) ).

{pstd}
For J = 2 this is F(Y_t|Z_t) = integral F(Y_2t|X_2t) dF(Y_1t|X_1t). Each
conditional marginal follows the distribution-regression model, eq. (2):

{p 8 8 2}
F(y_j | x_j) = Lambda( phi_j(x_j)' theta_j(y_j) ),

{pstd}
with a known link Lambda (logit or probit) and a separate coefficient vector
for every threshold y_j. {cmd:dvar} uses phi_j(x) = x.


{marker estimation}{...}
{title:2. Estimation (Section 3.1)}

{pstd}
{bf:Thresholds.} The grid is the K = {opt grid()} empirical quantiles
k/(K+1), k = 1..K, of each variable over the sample, computed with the MATLAB
{cmd:quantile} rule (positions (i-0.5)/n with linear interpolation), as in the
replication code.

{pstd}
{bf:Binary regressions, eq. (6).} For every j and threshold y,

{p 8 8 2}
theta_j(y) = argmax (1/T) sum_t [ 1{Y_jt <= y} ln Lambda(x'theta) + 1{Y_jt > y} ln(1 - Lambda(x'theta)) ].

{pstd}
With {opt lambda()} > 0 the criterion is that of MATLAB {cmd:lassoglm}, used
in the replication code (alpha = 0.2, lambda = 0.0005):

{p 8 8 2}
(1/T) Deviance(theta) + lambda [ (1-alpha)/2 ||theta_-0||^2 + alpha ||theta_-0||_1 ],

{pstd}
on standardised regressors, with an unpenalised intercept. It is minimised by
penalised iteratively reweighted least squares. The L1 term enters through
the local quadratic approximation |b| ~ b^2/(2|b_old|) (Fan and Li 2001), and
step-halving guarantees that the criterion decreases at every step. With
{cmd:lambda(0)} the estimator is the plain maximum-likelihood logit/probit:
it reproduces {helpb logit} to all reported digits. Thresholds at which
1{Y <= y} is constant in the sample get intercept -/+30 (F = 0 or 1).

{pstd}
{bf:Rearrangement.} For each covariate value the fitted values over the grid,
Lambda(x'theta_j(y_1)), ..., Lambda(x'theta_j(y_K)), are sorted. This is
the rearrangement of Chernozhukov, Fernandez-Val and Galichon (2009) on a
grid and yields a monotone conditional CDF, eq. (7).

{pstd}
{bf:Multi-step (local projection).} For horizon h, Y_t+h is regressed on
(1, Y_t, ..., Y_t-p+1) with the same DR machinery (direct multi-step
forecasting, Jorda 2005). Row r of the design is
Y = D(r+p+h-1) and Z = (D(r), ..., D(r+p-1)), exactly as in {cmd:VariablesT.m}.


{marker inference}{...}
{title:3. Inference (Section 3.2)}

{pstd}
Theorem 1: sqrt(T)(theta_hat - theta) converges to a Gaussian process with
covariance kernel H(y)^-1 Sigma(y,y') H(y')^-1, where H is the Hessian of the
population log-likelihood and Sigma is the long-run covariance of the scores

{p 8 8 2}
psi_t = [Lambda(x_t'theta) - 1{Y_jt <= y}] R(x_t'theta) x_t,  R = lambda/(Lambda(1-Lambda)).

{pstd}
{cmd:dvar fit} reports the pointwise sandwich H^-1 Sigma H^-1 / T, with Sigma
estimated by Newey-West with Bartlett weights and {opt hac()} lags. For logit,
R = 1 and H = E[p(1-p) x x']. For probit, H = E[phi^2/(Phi(1-Phi)) x x'].
Uniform bands and inference on functionals (DIRF, QIRF) use the moving-block
bootstrap that the paper suggests (Kunsch 1989; Appendix B.5: block length 8,
500 replications). In {cmd:dvar irf}, every DR system (h = 0 and each local
projection) is re-estimated on block-resampled rows, and the draws reuse the
same uniforms so that only estimation uncertainty is resampled.


{marker sampling}{...}
{title:4. Sampling the joint distribution (Appendix B.1, Algorithm 1)}

{pstd}
For s = 1..S: set x_1 = (1, z')', draw u ~ U(0,1), set
y_1 = min{ y in grid : F_hat(y | x_1) >= u }, append y_1 to x, and repeat for
j = 2..J. Because the rearranged CDF at a point is the sorted vector of fitted
values, y_j is the threshold whose index is 1 + #{k : Lambda(x'theta_j(y_k)) < u}.
No explicit sort is needed. A uniform above F(y_K) is mapped to y_K.


{marker dirf}{...}
{title:5. Distributional impulse responses (Section 2.2)}

{pstd}
Baseline: F(Y_t+h | Z_t) = integral F(Y_t+h | Y_t, Z_t) dF(Y_t | Z_t).
Counterfactual: F*(Y_t+h | Z_t) = integral F(Y_t+h | Y_t, Z_t) dG(Y_t | Z_t), where
G = rho(F_1, ..., G_i, ..., F_J) replaces the i-th factor. Definition 1:

{p 8 8 2}
DIR_h = F* - F (joint),  DIR_jh = F*_j - F_j (marginal, eq. 5),

{p 8 8 2}
MIRF_jh = E*[Y_j,t+h] - E[Y_j,t+h],  QIRF_jh(tau) = Q*_j(tau) - Q_j(tau).

{pstd}
Implementation, following {cmd:Main_CounterFactual.m}:

{p 8 12 2}
(a) h = 0: draw Y_t from F(Y_t | Z_t) (model with {opt inlags()} lags);{p_end}
{p 8 12 2}
(b) counterfactual: coordinates before i keep their draws, coordinate i is
drawn from G, and coordinates after i are re-drawn from their DR conditionals
given the new values;{p_end}
{p 8 12 2}
(c) h >= 1: the conditioning row at the shock date, whose last block
Y_t is replaced by the draws from (a) or (b), feeds the local projection
F(Y_t+h | Y_t, Z_t) ({opt lags()} lags), and Y_t+h is drawn by Algorithm 1;{p_end}
{p 8 12 2}
(d) quantiles (MATLAB rule), mean, sd (n-1), skewness and kurtosis
(MATLAB definitions) of the baseline and counterfactual draws, and the ECDF
difference on the threshold grid.{p_end}

{pstd}
Baseline and counterfactual use the same uniforms (common random numbers), so
Diff has no independent simulation noise.


{marker forecast}{...}
{title:6. Forecast evaluation (Section 4.2)}

{pstd}
For each origin o the systems are estimated on rows whose outcome date is at
most o (expanding window), and the h-step predictive distributions are
evaluated at Y_o+h:

{p 8 12 2}
PIT = F_hat_j(Y_j,o+h | z_o) from the {it:marginal} DR of Y_j on Z only, as
{cmd:Beta1} in the code, evaluated at the nearest threshold;{p_end}
{p 8 12 2}
QS(tau) = (y - Q(tau))(tau - 1{y < Q(tau)});{p_end}
{p 8 12 2}
CRPS = integral (F(y) - 1{Y <= y})^2 dy by the trapezoid rule over the grid;{p_end}
{p 8 12 2}
LogS = -mean ln f(y), where f is a Gaussian KDE of the joint draws with
bandwidth 1.06 T^(-1/(5+dim Z)) sd(Y), as in {cmd:DR_fore.m};{p_end}
{p 8 12 2}
joint LogS: sum over j of ln f_j(y_j | x_j), with the earlier coordinates
fixed at their realised values;{p_end}
{p 8 12 2}
Rossi and Sekhposyan (2019): KS = sqrt(P) sup_r |F_P(r) - r|, 5% critical value
1.34, bands r +/- 1.34/sqrt(P).{p_end}


{marker kernel}{...}
{title:7. Kernel model (Adrian, Boyarchenko and Giannone 2021)}

{pstd}
Eq. (1)-(3): p(y|x) = sum_t K_wy(y - y_t) K_wx(x - x_t) / sum_t K_wx(x - x_t), with
Gaussian product kernels and bandwidths w = c sd for every variable and lag.
Draw from this mixture as follows: pick training period t with probability
proportional to K_wx(x - x_t), then set y = y_t + w_y * N(0, I). This is exact
sampling from (1); the paper's Algorithm 1 approximates it on a grid. Paths
are propagated by updating x with the drawn y. With {opt cvgrid()}, c maximises
the mean out-of-sample one-step log predictive density (their Figure 2). The
perturbation for density impulse responses (Algorithm 3) follows the
triangular logic of Section 5: later coordinates are re-drawn from eq. (4),
p_i(y_i | x, y_-i).


{marker map}{...}
{title:8. Step-to-equation map}

{p2colset 5 30 32 2}{...}
{p2col:Mata function}paper{p_end}
{p2line}
{p2col:{cmd:dvar_lpdata}}Sec. 2.1, X_jt; {cmd:VariablesT.m}{p_end}
{p2col:{cmd:dvar_grid, dvar_mq}}threshold grid; MATLAB {cmd:quantile}{p_end}
{p2col:{cmd:dvar_fitstd}}eq. (2), (6); {cmd:DR_est_lasso.m} ({cmd:lassoglm}){p_end}
{p2col:{cmd:dvar_pobj}}penalised criterion of {cmd:lassoglm}{p_end}
{p2col:{cmd:dvar_fitsys}}eq. (1), (8): J factors; marginal version = {cmd:Beta1}{p_end}
{p2col:{cmd:dvar_cdfrow}}eq. (7) + rearrangement{p_end}
{p2col:{cmd:dvar_draw}}Appendix B.1, Algorithm 1{p_end}
{p2col:{cmd:dvar_sandwich}}Theorem 1{p_end}
{p2col:{cmd:dvar_cfdraw}}G of Sec. 2.2 / 4.4{p_end}
{p2col:{cmd:dvar_irfflat}}eqs. (3)-(5), MIRF, QIRF; Tables 1-2{p_end}
{p2col:{cmd:dvar_mbb}}Appendix B.5{p_end}
{p2col:{cmd:dvar_fc_main}}Sec. 4.2; {cmd:DVAR_Outsample.m}, {cmd:DR_fore.m}{p_end}
{p2col:{cmd:dvar_kde2, dvar_nmodes}}Figure 4 contours; multimodality count{p_end}
{p2col:{cmd:dvar_kdraw, dvar_klogd}}ABG (2021) eqs. (1)-(4), Algorithms 1, 3{p_end}
{p2col:{cmd:dvar_palette}}MATLAB Parula (64 stops), jet, turbo, ...{p_end}
{p2colreset}{...}


{marker code}{...}
{title:9. Differences from the MATLAB replication code}

{pstd}
{cmd:dvar} follows the paper's equations where the published code departs
from them. Each deviation is listed so that results can be compared.

{p 8 12 2}
1. {it:Out-of-sample window.} {cmd:DVAR_Outsample.m} calls
{cmd:DR_est_lasso(Xt,Yt,y,T1,lambda)} with the full-sample size {cmd:T1}
inside the expanding-window loop, so its "out-of-sample" forecasts use future
data. {cmd:dvar forecast} re-estimates on the data available at each origin;
the option {opt fullsample} reproduces the code.{p_end}
{p 8 12 2}
2. {it:Inverse CDF.} {cmd:DR_fore.m} picks the threshold whose CDF is
{it:nearest} to u; {cmd:Main_CounterFactual.m} picks the first threshold with
F > u, but returns the {it:lowest} threshold when u exceeds every F (a
{cmd:max} over an all-false row). {cmd:dvar} uses the generalised inverse of
Algorithm 1 throughout and maps such u to the highest threshold.{p_end}
{p 8 12 2}
3. {it:Correlation.} {cmd:Main_Insample.m} plots {cmd:cov()} although Figure 3
is labelled a correlation. {cmd:dvar fit, insample} reports correlations.{p_end}
{p 8 12 2}
4. {it:Ordering.} The replication {cmd:Data.xlsx} stores GDP, NFCI, FEDFUNDs,
while the paper and the plotting code order NFCI, GDP, rate. The counterfactual
shock hits the last variable (the rate), so this ordering does not affect h = 0;
the paper (Appendix B.2) finds the forecasts insensitive to it.{p_end}
{p 8 12 2}
5. {it:Estimation windows.} The code estimates the h = 0 model up to 2024q1 and
the local projections up to 2019q4. Use {opt lpend(2019q4)} to reproduce
this.{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
{p_end}
