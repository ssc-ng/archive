{smcl}
{* *! version 1.0.0  06oct2026}{...}
{vieweralsosee "jointdiag" "help jointdiag"}{...}
{vieweralsosee "jointdiag methods" "help jointdiag_methods"}{...}
{vieweralsosee "jointdiag lm" "help jointdiag_lm"}{...}
{vieweralsosee "jointdiag bc" "help jointdiag_bc"}{...}
{viewerjumpto "Syntax" "jointdiag_nonnest##syntax"}{...}
{viewerjumpto "Description" "jointdiag_nonnest##description"}{...}
{viewerjumpto "Options" "jointdiag_nonnest##options"}{...}
{viewerjumpto "The two variance corrections" "jointdiag_nonnest##corr"}{...}
{viewerjumpto "Interpreting the output" "jointdiag_nonnest##interpret"}{...}
{viewerjumpto "Examples" "jointdiag_nonnest##examples"}{...}
{viewerjumpto "Stored results" "jointdiag_nonnest##results"}{...}

{title:Title}

{phang}
{bf:jointdiag nonnest} {hline 2} Joint test of a non-nested alternative and a
general error specification


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:jointdiag} {cmd:nonnest} {it:depvar} {it:indepvars} {ifin}{cmd:,}
{opth a:lternative(varlist)} [{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth a:lternative(varlist)}}regressors of the non-nested rival model;
{bf:required}{p_end}
{synopt:{opt l:ags(#)}}AR order tested; default {cmd:lags(1)}{p_end}
{synopt:{opt het(varlist)}}the {it:v} variables of the heteroskedasticity
block; default the rival's fitted values{p_end}
{synopt:{opt nosk:ew}}drop the non-normality direction{p_end}
{synopt:{opt l:evel(#)}}confidence level{p_end}
{synopt:{opt notab:le}}suppress the table{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
The standard way to compare two non-nested models is to check the error
assumptions first and then run a non-nested test.  That two-step procedure has
a {bf:pre-testing problem}: the size and power of the second test depend on the
outcome of the first, in a way nobody computes.

{pstd}
Bera, McAleer and Pesaran (1989) remove the problem by testing everything at
once.  Using locally equivalent alternatives they build a single auxiliary
regression whose null is

{p 8 8 2}
{&rho} = 0{space 3}(no serial correlation){break}
{&phi} = 0{space 3}(no heteroskedasticity){break}
{it:c1} = 0{space 2}(normality){break}
{&alpha} = 0{space 2}(the non-nested rival adds nothing)

{pstd}
The {&alpha} regressor is the fitted value from the rival model, i.e. the
Davidson{c 150}MacKinnon {it:J}-test regressor.


{marker options}{...}
{title:Options}

{phang}
{opth alternative(varlist)} lists the regressors of the competing model
{it:H1}.  It is required.  The two models need not be nested and need not even
share regressors; they must not be orthogonal.

{phang}
{opt lags(#)} sets the AR order of the error alternative under the null model.

{phang}
{opt het(varlist)} names the {it:v} variables entering the variance function.
The default uses the rival's fitted values, which is a reasonable
non-constructive choice when you have no prior.

{phang}
{opt noskew} drops the {it:c1} direction.  Use it when the sample is small
enough that the eighth-moment approximation behind the factor-7 correction is
unreliable.


{marker corr}{...}
{title:The two variance corrections}

{pstd}
This is the part of the paper that is easiest to get wrong, and the command
prints both the raw and the corrected numbers so that the size of the
correction is visible.

{pstd}
{bf:Factor 2 on the heteroskedasticity block.}  Var({it:u}{c 94}2 - {it:s}{c 94}2)
= 2{it:s}{c 94}4 under normality, but the ordinary regression formula computes
{it:s}{c 94}4.  The raw F is therefore twice too large.  The authors cite
Godfrey and Wickens (1982, p. 86); it is the same correction as Koenker's
(1981) studentisation.

{pstd}
{bf:Factor 7 on the non-normality block.}  The authors derive the correct
asymptotic variance of the standardised score as 21{it:s}{c 94}8/8, working
through the sixth and eighth moments of the normal, while the regression
formula returns 3{it:s}{c 94}8/8 {c 150} {bf:one seventh of the truth}.  An
uncorrected F here is seven times too large.

{pstd}
So the reported decomposition is

{p 8 8 2}
({it:p0}+1){it:F1} + ({it:q0}/2){it:F2} + (1/7){it:F3}
{space 2}{c 174}{space 2}chi2({it:p0}+{it:q0}+2)


{marker interpret}{...}
{title:Interpreting the output}

{pstd}
{bf:Compare the two panels.}  If the corrected chi-square for a block is much
smaller than its raw F suggests, that block was never significant: you are
seeing the correction do its work.

{pstd}
{bf:The joint row} is the test the paper is about.  A non-rejection licenses
standard regression analysis on the null model, pre-testing problem and all.

{pstd}
{bf:A rejection is deliberately uninformative about the cause.}  The paper's
own closing caveat, reproduced in the output: "if the null is rejected, it is
not possible to infer whether it is rejected because of the non-nested
alternative or through departures from the classical conditions regarding the
disturbances."  To localise it, run {helpb jointdiag_lm:jointdiag lm} on the
null model and the ordinary {it:J} test separately, understanding that you are
then back in the pre-testing world.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}

{pstd}Is an investment equation better explained by income or by consumption?{p_end}
{phang2}{cmd:. jointdiag nonnest dln_inv dln_inc, alternative(dln_consump)}{p_end}

{pstd}Second-order errors, a named variance variable, no skewness block{p_end}
{phang2}{cmd:. jointdiag nonnest dln_inv dln_inc, alternative(dln_consump) ///}{p_end}
{phang2}{cmd:      lags(2) het(dln_consump) noskew}{p_end}


{marker results}{...}
{title:Stored results}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(F1)}, {cmd:r(F2)}, {cmd:r(F3)}}the raw F statistics{p_end}
{synopt:{cmd:r(chi1)}, {cmd:r(chi2)}, {cmd:r(chi3)}}the corrected
chi-squares{p_end}
{synopt:{cmd:r(joint)}, {cmd:r(df)}, {cmd:r(p)}}the joint test{p_end}
{synopt:{cmd:r(N)}}observations{p_end}


{title:References}

{phang}Bera, A. K., M. McAleer, and M. H. Pesaran. 1989.
Joint tests of non-nested models and general error specifications.
BEBR Faculty Working Paper 89-1616, University of Illinois.{p_end}
{phang}Davidson, R., and J. G. MacKinnon. 1981. {it:Econometrica} 49: 781{c 150}793.{p_end}
{phang}Godfrey, L. G., and M. R. Wickens. 1982. In G. C. Chow and P. Corsi (eds),
{it:Evaluating the Reliability of Macroeconomic Models}, 71{c 150}99. Wiley.{p_end}
{phang}Koenker, R. 1981. {it:J. Econometrics} 17: 107{c 150}112.
{browse "https://doi.org/10.1016/0304-4076(81)90062-2"}{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
