{smcl}
{* *! version 1.0.0  03oct2026}{...}
{title:Title}

{p 4 4 2}
{bf:xtmvardlurt_multivariate} {hline 2} Panel multivariate ARDL unit root test with
cointegration test, any number of covariates, with or without cross-sectional dependence


{title:Syntax}

{p 8 16 2}
{cmd:xtmvardlurt_multivariate} {depvar} {indepvars} {ifin} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt c:ase(#)}}deterministics: 3 (unrestricted intercept, default), 4 (restricted trend), 5 (unrestricted trend){p_end}
{synopt:{opt maxl:ag(#)}}largest lag searched, 0-8; default 3{p_end}
{synopt:{opt ic(aic|bic)}}information criterion; default {cmd:bic}{p_end}
{synopt:{opt fixl:ag(p q)}}fixed lags instead of selection: p lags of D.y, q lags of each D.x{p_end}
{synopt:{opt reps(#)}}bootstrap draws; default 999 (minimum 99){p_end}
{synopt:{opt seed(#)}}random-number seed; default 12345{p_end}
{synopt:{opt l:evel(#)}}confidence level; decision level is 100-level; default 95{p_end}
{synopt:{opt csd(auto|on|off)}}cross-section bootstrap; default {cmd:auto}{p_end}
{synopt:{opt unit:s}}list all units (default: listed when N <= 30){p_end}
{synopt:{opt nou:nits}}do not list units{p_end}
{synopt:{opt gr:aph}}draw the panel graph after estimation{p_end}
{synopt:{opt nodisplay}}suppress output{p_end}
{synoptline}
{p 4 4 2}The data must be {cmd:xtset}. Gaps in a unit's time series are not allowed;
unbalanced panels (different start or end dates) are.


{title:Description}

{p 4 4 2}
For each unit the command estimates the multivariate ARDL unit root regression of
Sam, McNown, Goh and Goh (2024),

{p 8 8 2}
D.y = c + [trend] + {it:pi} L.y + {it:delta}'L.x + sum {it:phi}_i L{it:i}D.y + sum {it:Gamma}_j'L{it:j}D.x + {it:omega}'D.x + u,

{p 4 4 2}
and computes the t-statistic on {it:pi} (H0: unit root; lower tail) and the F-statistic on
{it:delta} (H0: no level relationship; upper tail; in Case 4 the trend is included).
The k covariates are unrestricted in number. The unit statistics are combined into
the panel statistics

{p 8 12 2}{bf:t-bar, F-bar}: group means of the unit statistics;{p_end}
{p 8 12 2}{bf:Fisher}: -2 sum ln(p_i) of the unit bootstrap p-values (Maddala-Wu type);{p_end}
{p 8 12 2}{bf:Inverse-normal}: sum Phi^-1(p_i)/sqrt(N) (Choi type).{p_end}

{p 4 4 2}
The four-case framework is applied at the panel level (group-mean, Fisher and
inverse-normal versions) and at the unit level:
I = neither rejects (unit root, no cointegration); II = t rejects only (stationary);
III = F rejects only (degenerate, possibly I(2)); IV = both reject (cointegration).


{title:Bootstrap}

{p 4 4 2}
All p-values and critical values come from a residual bootstrap that imposes the
joint null (pi = 0 and delta = 0, plus the trend in Case 4), uses a drift-free
data-generating process, centres and rescales the residuals, and holds the
covariates at their observed values. Residuals are resampled with a common time
index across units, which preserves cross-sectional dependence; with {cmd:csd(off)}
units are resampled independently, and with {cmd:csd(auto)} (default) the common-index
bootstrap is used when the Pesaran (2004) CD test rejects at 5%. For unbalanced
panels the common index is aligned on calendar time. When lags are selected
({cmd:ic()}), the selection is repeated inside every bootstrap draw.

{p 4 4 2}
Simulations (Monte Carlo study shipped by the author) show size close to 5% for
N = 10-50 units, 1-30 covariates, Cases 3-5, balanced and unbalanced panels, with and
without a common factor, and strong power. Caveats: with 100 or more units the group
t statistics can be mildly oversized; with automatic lag selection and fewer than about
3 observations per parameter of the largest model searched, F-test p-values can be
oversized (the command warns).


{title:Stored results}

{p 4 4 2}Scalars: {cmd:e(N_units)}, {cmd:e(N_dropped)}, {cmd:e(T_min)}, {cmd:e(T_max)}, {cmd:e(T_avg)}, {cmd:e(k)},
{cmd:e(case)}, {cmd:e(reps)}, {cmd:e(maxlag)}, {cmd:e(level)}, {cmd:e(alpha)}, {cmd:e(seed)}, {cmd:e(CD)}, {cmd:e(CD_p)},
{cmd:e(csd_boot)}, {cmd:e(balanced)}, {cmd:e(minratio)}, {cmd:e(searchratio)}, {cmd:e(tbar)}, {cmd:e(p_tbar)}, {cmd:e(Fbar)}, {cmd:e(p_Fbar)}.{p_end}
{p 4 4 2}Matrices: {cmd:e(panel)} (6 x 7: statistic, p-value, critical values at 10%, 5%, 2.5%, 1% and at the decision level;
rows tbar, fisher_t, invnorm_t, Fbar, fisher_F, invnorm_F) and {cmd:e(unit)} (unit, T, p, q, t, F, p_t, p_F, case).{p_end}
{p 4 4 2}Macros: {cmd:e(cmd)}, {cmd:e(cmdline)}, {cmd:e(depvar)}, {cmd:e(indepvars)}, {cmd:e(panelvar)}, {cmd:e(timevar)}, {cmd:e(ic)}, {cmd:e(lagmethod)}, {cmd:e(csdmode)}, {cmd:e(casename)}.{p_end}


{title:Graphs}

{p 8 16 2}{cmd:xtmvardlurt_multivariate_graph} [{cmd:,} {opt sch:eme(name)} {opt nocombine}]{p_end}

{p 4 4 2}Draws the bootstrap distributions of t-bar and F-bar (observed value and critical value marked)
and the unit-level bootstrap p-values.


{title:References}

{p 4 8 2}Sam, C. Y., McNown, R., Goh, S. K. and Goh, K. L. (2024). A multivariate autoregressive distributed lag unit root test.{p_end}
{p 4 8 2}Maddala, G. S. and Wu, S. (1999). A comparative study of unit root tests with panel data and a new simple test. {it:Oxford Bulletin of Economics and Statistics}.{p_end}
{p 4 8 2}Choi, I. (2001). Unit root tests for panel data. {it:Journal of International Money and Finance}.{p_end}
{p 4 8 2}Pesaran, M. H. (2004). General diagnostic tests for cross section dependence in panels.{p_end}


{title:Author}

{p 4 4 2}Yusuf Toyin Yusuf, Kwara State University. yusuf.yusuf@kwasu.edu.ng{p_end}
