{smcl}
{* *! version 1.0.0  11nov2026}{...}
{vieweralsosee "xturcoint" "help xturcoint"}{...}
{vieweralsosee "xturcoint lm" "help xturcoint_lm"}{...}
{vieweralsosee "xturcoint fixedt" "help xturcoint_fixedt"}{...}
{vieweralsosee "xturcoint panic" "help xturcoint_panic"}{...}
{vieweralsosee "xturcoint cd" "help xturcoint_cd"}{...}
{vieweralsosee "xturcoint cusum" "help xturcoint_cusum"}{...}
{vieweralsosee "xturcoint adfmin" "help xturcoint_adfmin"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[XT] xtunitroot" "help xtunitroot"}{...}
{vieweralsosee "[XT] xtcointtest" "help xtcointtest"}{...}
{viewerjumpto "Syntax" "xturcoint_mp##syntax"}{...}
{viewerjumpto "Description" "xturcoint_mp##description"}{...}
{viewerjumpto "Options" "xturcoint_mp##options"}{...}
{viewerjumpto "Remarks" "xturcoint_mp##remarks"}{...}
{viewerjumpto "Stored results" "xturcoint_mp##results"}{...}
{viewerjumpto "Examples" "xturcoint_mp##examples"}{...}
{viewerjumpto "References" "xturcoint_mp##references"}{...}
{p 4 4 2}{bf:xturcoint} {c |} {help xturcoint:overview} {c |} {help xturcoint_lm:lm} {c |} {help xturcoint_fixedt:fixedt} {c |} {bf:mp} {c |} {help xturcoint_panic:panic} {c |} {help xturcoint_cd:cd} {c |} {help xturcoint_cusum:cusum} {c |} {help xturcoint_adfmin:adfmin} {c |} {help xturcoint##gauss:GAUSS map}{p_end}
{hline}
{title:Title}

{phang}
{bf:xturcoint mp} {hline 2} Moon-Perron (2004) panel unit-root tests with dynamic common factors


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xturcoint mp} {varname} {ifin} [{cmd:,} {opt mod:el(constant|trend)} {opt f:actors(#)}]

{marker description}{...}
{title:Description}

{pstd}
Moon and Perron (2004) remove the common factors from the pooled autoregression by projecting the data on the
space orthogonal to the estimated factor loadings (principal components of the pooled OLS residuals), and then
compute a bias-corrected pooled estimator rho* using long-run variances estimated with the quadratic-spectral
kernel, AR(1) pre-whitening and the Andrews-Monahan (1992) bandwidth. The two statistics t*_a and t*_b
are N(0,1) under H0 (all panels have a unit root) and reject for large negative values.

{pstd}
This is a port of the GAUSS procedure {cmd:pu_mp04} (carrionlib 1.0.2, pu_mp.src, by T. Yamagata, based on the
MATLAB code of Moon and Perron). Results are identical to GAUSS, including the N > T branch.

{pstd}
The data must be {helpb xtset} with a panel and a time variable and the panel must be
balanced over the estimation sample (no gaps, the same T for every unit).

{marker options}{...}
{title:Options}

{phang}{opt model(constant|trend)}: {cmd:constant} corresponds to GAUSS cases 1-2 and {cmd:trend} to case 3 (the data
are detrended by OLS on (1, t) first). Default {cmd:constant}.

{phang}{opt factors(#)} number of common factors m (default 1). As in GAUSS, m is given by the user; choose it, for
example, with the Bai-Ng criteria reported by {helpb xturcoint_panic:xturcoint panic}. {cmd:factors(0)} (no
de-factoring) is an extension; GAUSS stops with an error for m = 0.

{marker remarks}{...}
{title:Remarks}

{pstd}
As in the original MATLAB/GAUSS code, the constant case ({cmd:model(constant)}) does not demean the data and uses the
bias correction for the no-deterministics case; the AR(1) pre-whitening coefficient is truncated at |0.97| exactly as
in the GAUSS {cmd:LRcov} routine.

{marker results}{...}
{title:Stored results}

{synoptset 20 tabbed}{...}
{synopt:{cmd:r(t_a)}, {cmd:r(p_a)}}t*_a and left-tailed p-value{p_end}
{synopt:{cmd:r(t_b)}, {cmd:r(p_b)}}t*_b and left-tailed p-value{p_end}
{synopt:{cmd:r(rhostar)}}bias-corrected pooled AR coefficient{p_end}
{synopt:{cmd:r(factors)}, {cmd:r(N)}, {cmd:r(T)}}settings (T = periods - 1){p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse pennxrate, clear}{p_end}
{phang2}{cmd:. xtset id year}{p_end}
{phang2}{cmd:. xturcoint mp lnrxrate, factors(1)}{p_end}
{phang2}{cmd:. xturcoint mp lnrxrate, factors(2) model(trend)}{p_end}

{marker references}{...}
{title:References}

{phang}Moon, H. R., and B. Perron. 2004. Testing for a unit root in panels with dynamic factors.
{it:Journal of Econometrics} 122: 81-126. {browse "https://doi.org/10.1016/j.jeconom.2003.10.020":doi:10.1016/j.jeconom.2003.10.020}{p_end}
{phang}Andrews, D. W. K., and J. C. Monahan. 1992. An improved heteroskedasticity and autocorrelation consistent covariance matrix estimator.
{it:Econometrica} 60: 953-966.{p_end}

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane":github.com/merwanroudane}

{title:Also see}

{psee}
{help xturcoint:xturcoint} (overview, list of all tests, map of the GAUSS libraries){break}
Unit root: {help xturcoint_lm:xturcoint lm}, {help xturcoint_fixedt:xturcoint fixedt}, {help xturcoint_mp:xturcoint mp}, {help xturcoint_panic:xturcoint panic}{break}
Pre-test: {help xturcoint_cd:xturcoint cd}{break}
Cointegration: {help xturcoint_cusum:xturcoint cusum}, {help xturcoint_adfmin:xturcoint adfmin}
{p_end}
