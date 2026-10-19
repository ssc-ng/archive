{smcl}
{* *! version 1.0.0  13oct2026}{...}
{vieweralsosee "[TS] tsset" "help tsset"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "tvthresh" "help tvthresh"}{...}
{vieweralsosee "tvthresh choose" "help tvthresh_choose"}{...}
{vieweralsosee "tvtcotar" "help tvtcotar"}{...}
{viewerjumpto "Syntax" "tvtcotrk##syntax"}{...}
{viewerjumpto "Description" "tvtcotrk##description"}{...}
{viewerjumpto "A kink, not a jump" "tvtcotrk##kink"}{...}
{viewerjumpto "Options" "tvtcotrk##options"}{...}
{viewerjumpto "The three tests" "tvtcotrk##tests"}{...}
{viewerjumpto "Choices the paper leaves open" "tvtcotrk##choices"}{...}
{viewerjumpto "Examples" "tvtcotrk##examples"}{...}
{viewerjumpto "Stored results" "tvtcotrk##results"}{...}
{viewerjumpto "Validation" "tvtcotrk##validation"}{...}
{viewerjumpto "References" "tvtcotrk##references"}{...}
{viewerjumpto "Author" "tvtcotrk##author"}{...}
{title:Title}

{phang}
{bf:tvtcotrk} {hline 2} Conditional threshold regression kink


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:tvtcotrk} {depvar} {it:kinkvar} [{it:covariates}] {ifin}
[{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt mmin(#)}}smallest memory searched; default {cmd:mmin(3)}{p_end}
{synopt :{opt mmax(#)}}largest memory searched; default
{cmd:mmax(15)}{p_end}
{synopt :{opt trim(#)}}minimum share each side; default
{cmd:trim(0.15)}{p_end}
{synopt :{opt reps(#)}}wild bootstrap replications; default {cmd:reps(0)},
which gives {bf:no p-values}{p_end}
{synopt :{opt level(#)}}confidence level{p_end}
{synoptline}
{p 4 6 2}
The second variable is the {bf:kink variable}; any further variables are
ordinary covariates. A constant is always included.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:tvtcotrk} fits

{p 8 8 2}
{it:y_t} = {it:b1}({it:x_t} - {it:mu_t}({it:c}))_- +
{it:b2}({it:x_t} - {it:mu_t}({it:c}))_+ + {it:b3'z_t} + {it:e_t}

{pstd}
where (a)_- is min(a,0), (a)_+ is max(a,0), and the kink point
{it:mu_t}({it:c}) is the ({it:m}{bf:·}{it:c})-th smallest of the last
{it:m} values of {it:x}. Both {it:m} and {it:c} are {bf:estimated}.

{pstd}
So the relation between {it:y} and {it:x} has one slope while {it:x} is
below its recent {it:c}-quantile and another slope above it, and the two
join continuously.


{marker kink}{...}
{title:A kink, not a jump}

{pstd}
This is the continuous sibling of {helpb tvtcotar}. The threshold device is
identical {hline 2} a rolling empirical quantile of the kink variable's own
recent past {hline 2} but what happens at the threshold is different, and so
is almost everything else:

{p2colset 8 26 28 2}{...}
{p2col :}{bf:tvtcotar}{space 8}{bf:tvtcotrk}{p_end}
{p2col :at the threshold}a jump{space 12}a kink, continuous{p_end}
{p2col :{it:m}}fixed by you{space 5}{bf:estimated}{p_end}
{p2col :timing}{it:x_{c -(}t-d{c )-}} vs {it:mu_{c -(}t-d-1{c )-}}{space 1}{bf:contemporaneous}{p_end}
{p2col :bootstrap}re-estimates nothing{space 0}{bf:re-runs the search}{p_end}
{p2colreset}{...}

{pstd}
The timing difference is substantive, not notational: {cmd:tvtcotar}'s window
{bf:excludes} the current observation, this one {bf:includes} it. So this
command's indicator is not a lagged version of the other's.

{pstd}
{bf:Choose between them on what you believe happens at the boundary.} If
crossing the threshold shifts the level of the relation, that is a jump and
{helpb tvtcotar} is the model. If it changes the slope while the relation
stays continuous {hline 2} a response that steepens once a variable passes
its recent norm {hline 2} that is a kink and this is the model. Fitting a
jump to a kink, or the reverse, misstates the economics even when the fit
looks acceptable.


{marker options}{...}
{title:Options}

{phang}
{opt mmin(#)} and {opt mmax(#)} bound the memory {it:m}, which this model
{bf:estimates} rather than taking from you. The paper searches
{cmd:mmin(3) mmax(15)}, glossed as "three days to half a month". Widening
the range costs time roughly in proportion to the sum of the candidate
memories, since the grid for {it:c} is {bf:{it:m} points for each {it:m}}.

{phang}
{opt trim(#)} requires at least this share of observations on each side of
the kink. {bf:The paper states no trimming rule}; this is an implementation
decision, defaulted to 0.15 by analogy with {helpb tvtcotar}. It matters
because the design degenerates as {it:c} approaches 1, where the upper part
is zero except where {it:x} is the window maximum.

{phang}
{opt reps(#)} sets the wild bootstrap replications. {bf:The default 0 gives
no p-values.} Be aware of the cost: every replication re-runs the whole
({it:m},{it:c}) search {bf:and} Hansen's constant-threshold grid, twice over
{hline 2} once for each of the two null models. That is the price of
bootstrapping a supremum honestly.


{marker tests}{...}
{title:The three tests}

{pstd}
Two questions, three statistics.

{phang}
{bf:Is there a kink at all?} Two statistics answer this, because there are
two alternatives. {bf:F1C} compares the linear model with Hansen's
{it:constant}-threshold kink; {bf:F1T} compares it with the full CoTRK
model, taking a supremum over ({it:m},{it:c}).

{phang}
{bf:Does the kink point move?} {bf:F2} compares Hansen's constant-threshold
kink with CoTRK. This is the question that justifies using this command
rather than an ordinary regression kink.

{pstd}
{bf:The paper's rule is to reject linearity if EITHER F1C or F1T rejects.}
That is reported, with a caution the paper does not give: {bf:two tests at
the 5% level is not one test at the 5% level}. The pair rejects a true null
more often than either alone. If you need a stated size, use one of them and
say which.

{pstd}
{bf:F2 can come out NEGATIVE, and that is not a bug.} A negative F-like
statistic looks alarming, so it is worth saying why it happens: {bf:CoTRK
does not nest the constant-threshold model}. A rolling quantile is never
exactly constant, so when the truth really is a fixed kink point, Hansen's
model can fit better than CoTRK and the SSR difference turns the other way.
On simulated constant-threshold data F2 came out at about -85 here, against
+229 when the threshold genuinely moved. Read a negative F2 as what it is:
no evidence whatever that the threshold moves. The test rejects for large
values, so the bootstrap handles it correctly without special-casing.

{pstd}
All three have non-standard null distributions, so p-values come from a
fixed-regressor wild bootstrap: the regressors and every threshold surface
are held fixed and only the residuals are re-weighted by normal draws, but
the {bf:parameter search is redone} on each replication. That matters: the
observed statistics are suprema over a grid and enjoy the corresponding
selection advantage. Freezing the selected ({it:m},{it:c}) would ignore it
and over-reject.


{marker choices}{...}
{title:Choices the paper leaves open}

{pstd}
Three, all of which change the numbers and none of which is the author's.
They are stated here rather than buried.

{phang}
{bf:The effective sample, and it is the consequential one.} The criterion is
written as a sum over all {it:t}, which cannot be meant literally:
{it:mu_t}({it:c}) does not exist before {it:t} = {it:m}, and {it:m} is the
parameter being searched. Scoring candidates on different-length samples
would penalise a larger {it:m} purely for having fewer terms and make the
comparison meaningless. {bf:The sample is therefore fixed at
{cmd:mmax()}+1 onwards for every candidate}, so all of them are scored on
exactly the same rows.

{phang}
{bf:Trimming.} None is specified; see {opt trim()} above.

{phang}
{bf:Flooring.} {it:m}{bf:·}{it:c} is floored, as in {helpb tvtcotar}.

{pstd}
The paper also does not state how many bootstrap replications its own
simulation tables used, nor how Hansen's grid is trimmed for F1C and F2. The
usual quantile-trimmed grid over the observed {it:x} is used here.


{marker examples}{...}
{title:Examples}

{pstd}A kink in {it:y} against {it:x}, controlling for {it:z}.{p_end}
{phang2}{cmd:. tvtcotrk y x z}{p_end}

{pstd}With p-values. {bf:This is slow} {hline 2} see {opt reps()}.{p_end}
{phang2}{cmd:. tvtcotrk y x z, reps(499)}{p_end}

{pstd}A narrower memory range, which is much faster.{p_end}
{phang2}{cmd:. tvtcotrk y x z, mmin(3) mmax(8) reps(499)}{p_end}

{pstd}Did the kink point actually move? Read F2, and compare the two
SSRs.{p_end}
{phang2}{cmd:. display e(ssr_const), e(ssr), e(F2)}{p_end}

{pstd}Where did the estimated kink sit?{p_end}
{phang2}{cmd:. display "m=" e(m) "  c=" e(c)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:tvtcotrk} is {bf:e-class}.

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}, {cmd:e(N_eff)}}observations, and those used{p_end}
{synopt:{cmd:e(m)}, {cmd:e(c)}}the estimated memory and percentile{p_end}
{synopt:{cmd:e(share_hi)}}share at or above the kink point{p_end}
{synopt:{cmd:e(gamma_const)}}Hansen's constant kink point, for
comparison{p_end}
{synopt:{cmd:e(ssr)}, {cmd:e(ssr_const)}, {cmd:e(ssr_lin)}}the three fits{p_end}
{synopt:{cmd:e(F1C)}, {cmd:e(F1T)}, {cmd:e(F2)}}the three statistics{p_end}
{synopt:{cmd:e(p_F1C)}, {cmd:e(p_F1T)}, {cmd:e(p_F2)}}bootstrap
p-values{p_end}
{synopt:{cmd:e(n_cand)}, {cmd:e(n_feasible)}}grid points, and those passing
{opt trim()}{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}{cmd:below}, {cmd:above}, {cmd:_cons}, then
the covariates{p_end}
{synopt:{cmd:e(grid)}}one row per ({it:m},{it:c}): feasibility, SSR,
share{p_end}

{pstd}
{bf:No interval is reported for} {it:m} {bf:or} {it:c}, because the paper
derives no asymptotic distribution for them. In its simulations they are
recovered {it:exactly} at moderate sample sizes, which is a stronger
statement than an interval would be.


{marker validation}{...}
{title:Validation}

{pstd}
No code ships with this paper and none exists, so validation is against its
published Table 1. The estimator reproduces it, including the property that
matters most: at {it:T} = 500 the memory and the percentile are recovered
{bf:exactly in every replication}, standard deviation 0.000 for both,
matching the paper. That is a pass/fail property, not a number to match
approximately, and it is reached here already at {it:T} = 200.

{pstd}
One discrepancy was found and traced rather than excused. The kink-slope
standard deviations came out at half the paper's while the other
coefficients matched to within 5%. A factor of two on exactly the two slopes
points at the scale of the kink variable, and a direct two-scale run
confirmed it: {bf:the paper's simulation used a standard deviation of 1 for
that variable although it writes N(0,4)}, which reads as 2. At standard
deviation 1 every column of Table 1 is reproduced. See
{bf:validation/tvthresh/tvtcotrk_equation_map.md}.


{marker references}{...}
{title:References}

{phang}
Yang, L. Conditional Threshold Regression Kink (CoTRK). SSRN Working Paper.
{browse "https://doi.org/10.2139/ssrn.4704637":doi:10.2139/ssrn.4704637}

{phang}
Hansen, B. E. 2017. Regression kink with an unknown threshold. {it:Journal
of Business & Economic Statistics} 35(2): 228-240.
{browse "https://doi.org/10.1080/07350015.2015.1073595":doi:10.1080/07350015.2015.1073595}

{phang}
Hansen, B. E. 1996. Inference when a nuisance parameter is not identified
under the null hypothesis. {it:Econometrica} 64(2): 413-430.
{browse "https://doi.org/10.2307/2171789":doi:10.2307/2171789}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
Help:  {helpb tvthresh}, {helpb tvthresh_choose}, {helpb tvtcotar},
{helpb tvtmathar}
{p_end}
