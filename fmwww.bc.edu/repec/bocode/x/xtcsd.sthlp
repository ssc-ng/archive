{smcl}
{* *! version 1.1.2  19oct2026}{...}
{* 19Oct2026}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Related commands" "help xtreg"}{...}
{viewerjumpto "Syntax" "xtcsd##syntax"}{...}
{viewerjumpto "Description" "xtcsd##description"}{...}
{viewerjumpto "Options" "xtcsd##options"}{...}
{viewerjumpto "Remarks" "xtcsd##remarks"}{...}
{viewerjumpto "Examples" "xtcsd##examples"}{...}
{viewerjumpto "References" "xtcsd##references"}{...}
{viewerjumpto "Authors" "xtcsd##authors"}{...}
{hline}
help for {hi:xtcsd} {right:(Updated October 19, 2026; WU Lianghai, AHUT)}
{hline}

{title:Title}

{p 4 4 2}
{bf:xtcsd} {hline 2} Test for cross-sectional dependence
in panel data models
{p_end}

{title:Version}

{p 4 4 2}
Version 1.1.2, updated October 19, 2026, by WU Lianghai
(AHUT).
{p_end}

{marker syntax}{...}
{title:Syntax}

{p 4 4 2}
{cmd:xtcsd} {cmd:,} [{cmdab:pes:aran} | {cmdab:fri:edman} |
{cmdab:fre:es}] [{cmd:abs} {cmd:show}]
{p_end}

{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:xtcsd} is a post-estimation command for testing
cross-sectional dependence after {help xtreg} with the
{cmd:fe} or {cmd:re} estimator. The data must be declared
as panel data with {help xtset}. One of the options
{cmd:pesaran}, {cmd:friedman}, or {cmd:frees} must be
specified.
{p_end}

{p 4 4 2}
The command is designed for panel data with small T and
large N. It implements the Pesaran (2004) CD test, the
Friedman (1937) test, and the Frees (1995, 2004) Q test.
The null hypothesis is cross-sectional independence.
{p_end}

{marker options}{...}
{title:Options}

{p 4 8 2}
{cmd:pesaran} computes the Pesaran (2004) CD test. The
statistic is asymptotically standard normal. The command
supports balanced and unbalanced panels, but every pair of
cross-sectional units must have at least three common time
periods. If some pairs have fewer observations, the command
stops with error 2001 (insufficient observations). For
highly unbalanced panels, use {help xtcd2} instead.
{p_end}

{p 4 8 2}
{cmd:friedman} computes the Friedman (1937) test. For
unbalanced panels, only time periods available for all
cross-sectional units are used.
{p_end}

{p 4 8 2}
{cmd:frees} computes the Frees (1995, 2004) Q test. The
distribution is T-asymptotic. For unbalanced panels, only
time periods available for all cross-sectional units are
used.
{p_end}

{p 4 8 2}
{cmd:abs} reports the average absolute value of the
off-diagonal elements of the residual correlation matrix.
{p_end}

{p 4 8 2}
{cmd:show} displays the cross-sectional correlation matrix
of the residuals.
{p_end}

{marker remarks}{...}
{title:Remarks}

{p 4 4 2}
The command uses {cmd:predict, e} after {cmd:xtreg}. The
results therefore refer to the residuals from the estimated
fixed-effects or random-effects model.
{p_end}

{p 4 4 2}
For unbalanced panels, the {cmd:pesaran} option requires at
least three common observations for every pair of units. A
common reason for error 2001 is that some firms have only
one or two usable observations, or that two firms have only
one or two years in common. In that case, either restrict
the sample to a balanced panel or use {help xtcd2}, which
implements the Pesaran CD test for unbalanced panels.
{p_end}

{p 4 4 2}
The {cmd:friedman} and {cmd:frees} options use only the
time periods for which all units have observations. They
are therefore not suitable when the panel is severely
unbalanced.
{p_end}

{p 4 4 2}
Version 1.1.2 includes compatibility fixes for Stata 18 and
later: the cumulative standard normal distribution is
computed with {cmd:normal()} rather than the obsolete
{cmd:norm()} function, and functions are no longer
evaluated inside matrix element assignments.
{p_end}

{marker examples}{...}
{title:Examples}

{p 4 4 2}Setup:{p_end}
{p 8 8 2}{cmd:webuse grunfeld, clear}{p_end}
{p 8 8 2}{cmd:xtset company year}{p_end}

{p 4 4 2}
Fixed-effects model and Pesaran test:
{p_end}
{p 8 8 2}{cmd:xtreg invest mvalue kstock, fe}{p_end}
{p 8 8 2}{cmd:xtcsd, pesaran}{p_end}

{p 4 4 2}
Show the correlation matrix and average absolute
correlation:
{p_end}
{p 8 8 2}{cmd:xtcsd, pesaran show abs}{p_end}

{p 4 4 2}Friedman and Frees tests:{p_end}
{p 8 8 2}{cmd:xtcsd, friedman}{p_end}
{p 8 8 2}{cmd:xtcsd, frees}{p_end}

{p 4 4 2}Random-effects model:{p_end}
{p 8 8 2}{cmd:xtreg invest mvalue kstock, re}{p_end}
{p 8 8 2}{cmd:xtcsd, frees}{p_end}

{marker references}{...}
{title:References}

{p 4 8 2}
De Hoyos, R.E., and V. Sarafidis. 2006. Testing for
cross-sectional dependence in panel-data models.
{it:Stata Journal} 6(4): 482-496.
{p_end}

{p 4 8 2}
Frees, E.W. 1995. Assessing cross-sectional correlations
in panel data. {it:Journal of Econometrics} 64: 393-414.
{p_end}

{p 4 8 2}
Frees, E.W. 2004.
{it:Longitudinal and Panel Data: Analysis and Applications in the Social Sciences}.
Cambridge: Cambridge University Press.
{p_end}

{p 4 8 2}
Friedman, M. 1937. The use of ranks to avoid the
assumption of normality implicit in the analysis of
variance.
{it:Journal of the American Statistical Association}
32: 675-701.
{p_end}

{p 4 8 2}
Pesaran, M.H. 2004. General diagnostic tests for cross
section dependence in panels. Cambridge Working Papers in
Economics 0435, University of Cambridge.
{p_end}

{p 4 8 2}
Sarafidis, V., and R.E. De Hoyos. 2006. On testing for
cross sectional dependence in panel data models. Mimeo,
University of Cambridge.
{p_end}

{title:Acknowledgements}

{p 4 8 2}
The original code benefited from the {help xttest2} command
by Christopher Baum. Thanks to David Drukker for useful
suggestions.
{p_end}

{marker authors}{...}
{title:Authors}

{p 4 8 2}Original authors:{p_end}
{p 8 8 2}
Rafael E. De Hoyos, Faculty of Economics,
University of Cambridge.
{p_end}
{p 8 8 2}
Vasilis Sarafidis, Discipline of Econometrics and
Business Statistics, University of Sydney.
{p_end}

{p 4 8 2}Modified by (Stata 18 update and maintenance):{p_end}
{p 8 8 2}
WU Lianghai
{p_end}
{p 8 8 2}
School of Business
{p_end}
{p 8 8 2}
Anhui University of Technology (AHUT)
{p_end}
{p 8 8 2}
Ma'anshan, Anhui, China
{p_end}
{p 8 8 2}
Email: agd2010@yeah.net
{p_end}
{p 8 8 2}
October 19, 2026
{p_end}

{title:Also see}

{p 4 8 2}
Manual: {hi:[U] 23 Estimation and post-estimation commands};
{hi:[XT] xtreg}
{p_end}
{p 4 8 2}
Online: {help xtreg}, {help xttest2}, {help xtcd2},
{help xtscc}, {help xtdcce2}
{p_end}
