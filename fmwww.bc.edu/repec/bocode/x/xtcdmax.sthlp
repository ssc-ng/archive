{smcl}
{* *! version 1.0.0  25oct2026}{...}
{viewerjumpto "Syntax" "xtcdmax##syntax"}{...}
{viewerjumpto "Description" "xtcdmax##description"}{...}
{viewerjumpto "Options" "xtcdmax##options"}{...}
{viewerjumpto "Remarks" "xtcdmax##remarks"}{...}
{viewerjumpto "Stored results" "xtcdmax##results"}{...}
{viewerjumpto "Examples" "xtcdmax##examples"}{...}
{viewerjumpto "References" "xtcdmax##references"}{...}
{title:Title}

{p 4 8 2}
{bf:xtcdmax} {hline 2} Sum-type, max-type and combined tests of cross-sectional independence that
allow for serial correlation


{marker syntax}{...}
{title:Syntax}

{p 4 8 2}Residuals of the last estimation

{p 8 16 2}
{cmd:xtcdmax} {ifin} [{cmd:,} {it:options}]

{p 4 8 2}One variable (demeaned by unit unless {cmd:nodemean})

{p 8 16 2}
{cmd:xtcdmax} {varname} {ifin} [{cmd:,} {it:options}]

{p 4 8 2}Residuals of unit-by-unit regressions of {it:depvar} on {it:indepvars}

{p 8 16 2}
{cmd:xtcdmax} {depvar} {indepvars} {ifin} [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt lag:s(#)}}Bartlett lags of the long-run correlations; default floor(4 (T_ij/100)^(2/9)) for each
pair{p_end}
{synopt:{opt mint(#)}}minimum number of common periods for a pair; default {cmd:8}{p_end}
{synopt:{opt nodem:ean}}do not demean {it:varname} by unit{p_end}
{synopt:{opt nod:isplay}}suppress output{p_end}
{synoptline}
{p 4 4 2}
The data must be {helpb xtset}. Unbalanced panels are allowed.


{marker description}{...}
{title:Description}

{p 4 4 2}
The CD test of Pesaran (2015) averages the pairwise correlations of the residuals. It has power
against dense dependence, many weak correlations in the same direction, but little against sparse
dependence, a few strongly correlated pairs, or correlations of both signs that cancel. It also
over-rejects when the residuals are serially correlated, because the variance of a correlation
between two autocorrelated series exceeds 1/T. {cmd:xtcdmax} reports:

{p 8 12 2}
1. {bf:CD}, the Pesaran test, for reference;

{p 8 12 2}
2. {bf:CD, long-run standardized}: each correlation is divided by its long-run standard error
(Bartlett 1946), estimated from the products of the two series' autocorrelations with Bartlett
weights;

{p 8 12 2}
3. {bf:SN}, a one-sided sum test whose variance follows Wang, Liu, Feng and Ma (2023) (balanced
panels);

{p 8 12 2}
4. {bf:MAX}, a max-type test: for each pair the long-run standardized squared correlation
z_ij^2/T_ij is compared with the Beta(1/2, (T_ij - 2)/2) distribution of a squared correlation
between independent Gaussian series, and the smallest p-value is adjusted for the number of
pairs by the Sidak correction;

{p 8 12 2}
5. {bf:Fisher}, the combination -2 ln p(CD long-run) - 2 ln p(MAX) ~ chi2(4), since sum- and
max-type statistics are asymptotically independent (Feng et al. 2022).

{p 4 4 2}
The pair with the most significant correlation is reported.


{marker options}{...}
{title:Options}

{phang}{opt lags(#)} sets the number of autocorrelations used for the long-run correlations;
{cmd:lags(0)} gives the iid standardization.

{phang}{opt mint(#)} sets the minimum number of common periods; units with fewer observations and
pairs with fewer common periods are dropped.

{phang}{opt nodemean} uses {it:varname} as it is.


{marker remarks}{...}
{title:Remarks}

{p 4 4 2}
In the simulations of the accompanying article (residuals of unit regressions with N = 20 to 100
and T = 50 or 100, 2,000 replications), the Pesaran CD test rejected a true null of independence
in 12-16% of samples at the 5% level when all residuals followed an AR(1) with coefficient 0.6;
the long-run standardized CD, SN, MAX and Fisher tests rejected in 1.5-9.6%. Against one strongly
correlated pair among N = 50 units, CD rejected in at most 10% of samples and MAX in 44-99.5%.

{p 4 4 2}
After common correlated effects (CCE) estimation, all tests of this kind are biased by the
cross-section averages in the residuals (Juodis and Reese 2022); {helpb xtcsddiag} reports the
CDw test for that case.


{marker results}{...}
{title:Stored results}

{p 4 4 2}{cmd:xtcdmax} stores in {cmd:r()} the scalars {cmd:N}, {cmd:T}, {cmd:pairs}, {cmd:CD},
{cmd:p_CD}, {cmd:CDlr}, {cmd:p_CDlr}, {cmd:MAX}, {cmd:p_MAX}, {cmd:FISHER}, {cmd:p_FISHER},
{cmd:SN} and {cmd:p_SN} (balanced panels), {cmd:balanced}, {cmd:M} (lags, if set), {cmd:id_i},
{cmd:id_j} and {cmd:rho_max} (the most significant pair), {cmd:mean_absrho}, {cmd:T_min}; the
macros {cmd:ivar} and {cmd:tvar}; and the matrix {cmd:r(table)}.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. use xtcsddiag_apec, clear}{p_end}
{phang2}{cmd:. xtset id year}{p_end}
{phang2}{cmd:. generate lnEF = ln(EF)}{p_end}
{phang2}{cmd:. xtcdmax lnEF NET GLB}{p_end}
{phang2}{cmd:. xtreg lnEF NET GLB i.year, fe}{p_end}
{phang2}{cmd:. xtcdmax}{p_end}


{marker references}{...}
{title:References}

{p 4 8 2}Bartlett, M. S. 1946. On the theoretical specification and sampling properties of autocorrelated
time-series. {it:Supplement to the Journal of the Royal Statistical Society} 8: 27-41.{p_end}
{p 4 8 2}Feng, L., T. Jiang, B. Liu, and W. Xiong. 2022. Max-sum tests for cross-sectional independence of
high-dimensional panel data. {it:Annals of Statistics} 50(2). doi:10.1214/21-AOS2142.{p_end}
{p 4 8 2}Juodis, A., and S. Reese. 2022. The incidental parameters problem in testing for remaining
cross-section correlation. {it:Journal of Business and Economic Statistics} 40: 1191-1203.{p_end}
{p 4 8 2}Pesaran, M. H. 2015. Testing weak cross-sectional dependence in large panels.
{it:Econometric Reviews} 34: 1089-1117.{p_end}
{p 4 8 2}Wang, H., B. Liu, L. Feng, and Y. Ma. Forthcoming. Fisher's combined probability test for
cross-sectional independence in panel data models with serial correlation. {it:Statistica Sinica}.
doi:10.5705/ss.202023.0348.{p_end}


{title:Author}

{p 4 4 2}Yusuf Toyin Yusuf, Department of Economics and Development Studies, Kwara State University, Malete,
Nigeria.
yusuf.yusuf@kwasu.edu.ng{p_end}

{title:Also see}

{p 4 4 2}{helpb xtcsddiag}, {helpb xtcollin} (same package){p_end}
