{smcl}
{* *! version 1.0.0  12nov2026}{...}
{vieweralsosee "indsat" "help indsat"}{...}
{vieweralsosee "indsat types" "help indsat_types"}{...}
{vieweralsosee "indsat postestimation" "help indsat_postestimation"}{...}
{viewerjumpto "Model" "indsat_methods##model"}{...}
{viewerjumpto "Indicators" "indsat_methods##ind"}{...}
{viewerjumpto "GETS search" "indsat_methods##gets"}{...}
{viewerjumpto "Split-half and m-step" "indsat_methods##split"}{...}
{viewerjumpto "Gauge and corrections" "indsat_methods##gauge"}{...}
{viewerjumpto "Tests" "indsat_methods##tests"}{...}
{viewerjumpto "Paths and the path test" "indsat_methods##path"}{...}
{viewerjumpto "Validation" "indsat_methods##valid"}{...}
{viewerjumpto "Step-to-equation map" "indsat_methods##map"}{...}
{title:Title}

{phang}
{bf:indsat methods} {hline 2} Formulas, algorithms and their sources


{marker model}{...}
{title:1. Saturated model}

{pstd}
For {it:t = 1,...,T}, {it:y_t = beta'x_t + sum_j gamma_j d_j(t) + e_t}, {it:e_t ~ IN(0, sigma^2)},
with {it:x_t} the regressors (constant, lags of {it:y} from {cmd:ar()}, {it:indepvars}) and
{it:D = (d_1,...,d_T)} a saturating set of indicators (Pretis et al. 2016, eqs. 2-3).
{it:H0}: all {it:gamma_j = 0}. The number of columns of {it:(X, D)} exceeds {it:T}, so the model is estimated
by selection over blocks of {it:D}.


{marker ind}{...}
{title:2. Indicator sets}

{p2colset 5 18 20 2}{...}
{p2col:IIS}{it:I_j(t) = 1(t = j)}, j = 1..T (Hendry, Johansen & Santos 2008){p_end}
{p2col:SIS up}{it:S_j(t) = 1(t >= j)}, j = 2..T ({it:gets}){p_end}
{p2col:SIS down}{it:S_j(t) = 1(t <= j)}, j = 1..T-1 (Castle et al. 2015, Autometrics){p_end}
{p2col:TIS}{it:T_j(t) = (t-j+1) 1(t >= j)}, j = 2..T ({it:gets}); QIS, CIS: powers 2, 3 (Ericsson 2011){p_end}
{p2col:MIS}{it:x_kt S_j(t)}, j = 2..T (Kitov & Tabor 2015; Pretis et al. 2016 Tab. 1){p_end}
{p2col:DIS}{it:I_j(t) - I_(j-1)(t)}, j = 2..T (Ericsson 2011){p_end}
{p2col:PIS(h)}{it:I_i(t) + I_(i+h)(t)}, i = 1..T-h (Ericsson 2011){p_end}
{p2col:BIS}{it:d_j(t) = d(t-j+1)} for {it:1 <= t-j+1 <= L}; {it:d} designed (Pretis et al. 2016, eq. 3){p_end}
{p2col:volcanic}{it:d(t) = exp(-t) (1-1/gamma)^-1 [exp(t(1-1/gamma)) - 1]}, t = 1..L, eq. (31) with C/theta = 1, scaled to max 1{p_end}
{p2col:TC}{it:d(t) = delta^(t-1)} (TRAMO/X-13 transitory change; Marczak & Proietti 2016){p_end}
{p2colreset}{...}
{pstd}
TIS/QIS/CIS columns are scaled to unit maximum during the search (t-ratios are invariant) and
rescaled in the final model.


{marker gets}{...}
{title:3. Block search and multi-path GETS (algorithm(gets))}

{pstd}
Port of {it:gets::isat} 0.40 (Pretis, Reade & Sucarrat 2018; Sucarrat 2021):{p_end}
{phang2}(a) For each set with {it:m} columns: blocks = ceil(max(2, m/(ratio m - k), m/min(ratio T, maxblock))), contiguous,
of size ceil(m/blocks).{p_end}
{phang2}(b) In each block, the GUM {it:(X, D_b)} is cleaned of collinear columns (pivoted QR, tolerance {opt tol()}) and
reduced by multi-path GETS with {it:X} kept: one path starts by deleting each insignificant indicator; along a path
the least significant variable is deleted until all remaining have p < tpval; distinct terminal models (and the GUM)
are compared by the information criterion
{it:IC = -2 logL/T + penalty}, with {it:logL = -T/2 log(2 pi s^2) - RSS/(2 s^2)}, {it:s^2 = RSS/(T-k)} (as in {it:gets}).{p_end}
{phang2}(c) Block survivors are reduced again by GETS; if they cannot be estimated (k + survivors >= T) an
interleaved additional block search is run.{p_end}
{phang2}(d) Survivors of all sets are combined and reduced by a final GETS; the final model is estimated by OLS with
the chosen covariance (ordinary, White HC0, or Newey-West with round(T^(1/4)) Bartlett lags).{p_end}
{phang2}(e) Optional diagnostic guard: a deletion is reversed if the Ljung-Box AR/ARCH or Jarque-Bera test rejects.{p_end}
{phang2}(f) {opt common}: candidate dates = retained SIS/MIS dates; dates closer than the number of parameters per
date are merged; date blocks {it:(S_tau, x_1 S_tau, ...)} are deleted backwards by Wald F-tests (OxRegimes
{it:JointSelection}).{p_end}


{marker split}{...}
{title:4. Split-half and m-step algorithms}

{pstd}
{bf:Split-half IIS} (Johansen & Nielsen 2009, Sec. 2.2.2): estimate on each half {it:I_1, I_2} by OLS with
{it:s_j^2 = RSS_j/T_j}; scaled forecast errors {it:v_t = (y_t - b_j'x_t)/w_t}, {it:w_t^2 = s_j^2 (1 + x_t'(X_j'X_j)^-1 x_t)}
for t in the other half; robustified LS on {it:|v_t| <= c} with {it:s^2 = (psi/tau) RSS/n_good}; a second
round with the robustified estimators gives the IIS estimator. {it:c = Phi^-1(1 - alpha/2)}.{p_end}
{pstd}
{bf:Split-half SIS} (Nielsen & Qian 2025, Alg. 2.2): within-half slope estimates; a shift at {it:i+1} is declared if
{it:|Dy_i - b_j'Dx_i| >= sqrt(2) s_j w_(j,i) c}, {it:Dy_i = y_i - y_(i+1)},
{it:w^2 = 1 + Dx_i'{2 sum (x_k - xbar_j)(x_k - xbar_j)'}^-1 Dx_i}; the final model re-estimates with the steps.{p_end}
{pstd}
{bf:m-step Huber-skip} (Johansen & Nielsen 2016, Alg. 1): from full-sample OLS, iterate {it:m} times
{it:v_t = 1(|y_t - b'x_t| <= c s)}, LS on {it:v_t = 1}, {it:s^2 = (psi/tau) RSS/sum v_t}.{p_end}


{marker gauge}{...}
{title:5. Gauge and Johansen-Nielsen factors}

{pstd}
With {it:c} the two-sided normal cut-off, {it:psi = Phi(c) - Phi(-c)}, {it:tau = psi - 2c phi(c)},
{it:chi = 3psi - 2c(c^2+3)phi(c)}:{p_end}
{phang2}consistency factor {it:xi = sqrt(psi/tau)} (sigma; JN 2009, eq. 2.6){p_end}
{phang2}efficiency of {it:beta}: {it:eta_m^2 = [((1-r^m)/((1-r)psi))^2 + 2 (1-r^m)/((1-r)psi) r^m] tau + r^(2m)}, {it:r = 2c phi(c)/psi}
(JN 2016, eq. 37; {it:gets::isvareffcor}){p_end}
{phang2}gauge variance (normal theory): {it:Var(gauge) = [psi(1-psi) + eta_gamma]/T} with
{it:rho = (c^2 - tau/psi) c phi(c)/tau} (JN 2016, Part II; {it:gets::vargaugeiis}){p_end}
{phang2}Poisson theory: number of false impulses ~ Poisson(alpha T) (JN 2016, Part II; Nielsen & Qian 2025).{p_end}


{marker tests}{...}
{title:6. Tests}

{phang2}{bf:Outlier proportion} (Jiao & Pretis): {it:z = (n_IIS/T - alpha)/sd(gauge)} ~ N(0,1).{p_end}
{phang2}{bf:Outlier count}: exact Poisson test of {it:n_IIS} against {it:alpha T} (as R {it:poisson.test}).{p_end}
{phang2}{bf:Scaling sum/sup} ({helpb indsat_loop:indsat loop}): {it:sqrt(T)(gauge_k - alpha_k)} over a grid of {it:alpha_k}; the sum is normal with
the covariance of {it:gets::outlierscaletest}; the sup p-value is simulated from the Gaussian limit.{p_end}
{phang2}{bf:Distortion} (Jiao, Pretis & Schwarz): {it:H = T d'[avar1 T rho1 V]^-1 d}, {it:d = b_IIS - b_OLS}, chi2(k),
{it:V = (T_rob/T)(rho1 varsigma)^-1 V_IIS}; bootstrap on the clean sample as {it:gets::distorttestboot}.{p_end}
{phang2}{bf:Bias correction} (Hendry & Krolzig 2005; Pretis 2018): {it:b(1 - r(t)/t)} for {it:|t| > c},
{it:r(t) = [phi(c-t) - phi(-c-t)]/[1 - Phi(c-t) + Phi(-c-t)]}; the 2-step version re-evaluates {it:r} at {it:t - r(t)}.{p_end}
{phang2}{bf:Constancy / forecast bias} ({cmd:estat bias}): F-test that all retained indicators (and the constant) are zero
(Ericsson & Reisman 2012).{p_end}
{phang2}{bf:Diagnostics} ({cmd:estat diag}): Breusch-Godfrey AR 1-q (F), Engle ARCH 1-q (F), Jarque-Bera, Doornik-Hansen
(1994), White heteroskedasticity on squares of the non-indicator regressors, RESET with squares and cubes of the fit.{p_end}


{marker path}{...}
{title:7. Coefficient path and the path test (isattest)}

{pstd}
The deterministic (intercept) path is {it:mu_t = a_t'theta}, where {it:a_t} holds the values at {it:t} of the constant and
all retained non-MIS indicators and {it:theta} their coefficients; {it:se(mu_t) = sqrt(a_t'V a_t)} exactly. The long-run
path with AR terms is {it:mu_t/(1 - sum rho)}, with delta-method standard errors. MIS coefficient paths are
{it:beta_x + sum_j b_j 1(t >= tau_j)}.{p_end}
{pstd}
{bf:Deviation from gets.} {it:gets::isatvar} orders indicators by start date and uses the variance of the cumulative
sum of the first {it:i} coefficients, which after a retained impulse keeps adding that impulse's variance to later
dates. {cmd:indsat} uses the exact {it:a_t'V a_t} (e.g. Nile 1899-1907: s.e. = sigma/3 = 36.6, the textbook s.e. of a
9-year regime mean; {it:gets} gives 117.6). Point estimates of the path are identical.{p_end}
{pstd}
{cmd:estat test} (Pretis 2016 {it:isattest}): {it:CI_t = mu_t +/- t_(T-N)(cipval) se_t}; periods with {it:CI_t} entirely above
or below {it:hnull} are reported as significant bias; {cmd:biascorr} applies the 2-step correction to {it:mu_t}.{p_end}


{marker valid}{...}
{title:8. Validation}

{pstd}
Against R {it:gets} 0.40 on identical data, {cmd:indsat} reproduces retained indicators (including their order), coefficients,
standard errors (ordinary, White, Newey-West), the number of estimations, the Jiao-Pretis proportion and count tests,
the distortion statistic and {it:isat loop}/{it:outlierscaletest}, for IIS, SIS, TIS, AR terms, AIC/SC, the additional block
search, the Nile series and simulated DGPs. The script {cmd:indsat_validate.do} (with {cmd:indsat_validate.R}) repeats the comparison.{p_end}


{marker map}{...}
{title:9. Step-to-equation map}

{p2colset 5 34 36 2}{...}
{p2col:{it:Code (Mata in indsat.ado)}}{it:Source}{p_end}
{p2line}
{p2col:indsat_makeM()}Pretis et al. (2016) eq. (3), Tab. 1; Ericsson (2011){p_end}
{p2col:indsat_isblock()}gets ISMatricesLoop; Santos et al. (2008) split generalised{p_end}
{p2col:indsat_getsfun()}gets getsFun; Hoover & Perez (1999); Doornik (2009){p_end}
{p2col:indsat_ols(), indsat_icval()}gets ols() methods 3-5; infocrit(){p_end}
{p2col:indsat_dropvar()}gets dropvar() (LINPACK dqrdc2 rule){p_end}
{p2col:indsat_addblock()}gets ISadditionalblocksearch{p_end}
{p2col:indsat_splitiis()}Johansen & Nielsen (2009) Sec. 2.2.2, eqs. (2.5)-(2.9){p_end}
{p2col:indsat_splitsis()}Nielsen & Qian (2025) Alg. 2.2, eqs. (15)-(18){p_end}
{p2col:indsat_mstep()}Johansen & Nielsen (2016) Alg. 1, eqs. (14)-(16){p_end}
{p2col:indsat_vargauge()}Johansen & Nielsen (2016) Part II; gets vargaugeiis{p_end}
{p2col:indsat_poistest()}R poisson.test (two-sided){p_end}
{p2col:indsat_common()}OxRegimes RgSaturation::JointSelection{p_end}
{p2col:indsate_path(), indsate_isattest()}gets isatvar/isattest (exact variance){p_end}
{p2col:indsate_bc()}gets biascorr; Hendry & Krolzig (2005){p_end}
{p2col:indsate_distort()}gets distorttest; Jiao, Pretis & Schwarz{p_end}
{p2col:indsatl_scale()}gets outlierscaletest; Jiao & Pretis{p_end}
{p2line}
{p2colreset}{...}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
