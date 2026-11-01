{smcl}
{* *! version 0.6.1 27oct2026}{...}
{vieweralsosee "ci" "help ci"}{...}
{viewerjumpto "Syntax" "newcombe11##syntax"}{...}
{viewerjumpto "Description" "newcombe11##description"}{...}
{viewerjumpto "Methods" "newcombe11##methods"}{...}
{viewerjumpto "Options" "newcombe11##options"}{...}
{viewerjumpto "Stored results" "newcombe11##results"}{...}
{viewerjumpto "Examples" "newcombe11##examples"}{...}

{title:Title}

{pstd}
{cmd:newcombe11} -- Eleven confidence intervals for the difference
between two independent binomial proportions
{p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{cmd:newcombe11} {it:x1 n1 x2 n2}
[{cmd:,} {opt method(#)} {opt all} {opt level(#)}]
{p_end}

{p 8 12 2}
{cmd:newcombe11} {it:outcome}{cmd:,} {opt by(group)}
[{opt method(#)} {opt all} {opt level(#)}]
{p_end}

{pstd}
{it:x1} and {it:x2} are integer counts of successes.
{it:n1} and {it:n2} are positive integer sample sizes.
In dataset syntax, {it:outcome} must be coded 0/1 and
{it:group} must identify exactly two numeric groups.
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:newcombe11} calculates confidence intervals for the
risk difference, {it:p1 - p2}, between two independent
binomial proportions, using the eleven methods numbered
in Newcombe (1998). The default is method 10, the
combination of uncorrected Wilson score intervals,
with 95% confidence.
{p_end}

{pstd}
In immediate syntax, group 1 is {it:x1/n1}.
In dataset syntax, group 1 is the smaller observed numeric
value of {it:group}; group 2 is the larger value.
Observations with missing outcome or group are excluded.
Changing group coding can reverse the sign of the difference.
The output explicitly identifies the numeric code of each group
and displays its value label, if defined. The difference always
subtracts the larger-coded group's proportion from the
smaller-coded group's proportion. Labels do not change this order.
In immediate syntax, the two groups follow the supplied argument order.
{p_end}

{marker methods}{...}
{title:Methods}

{p 4 8 2}
1. Wald -- Uncorrected normal approximation
{p_end}
{p 4 8 2}
2. Wald CC -- Wald with continuity correction
{p_end}
{p 4 8 2}
3. Haldane -- Haldane method
{p_end}
{p 4 8 2}
4. Jeffreys-Perks -- Jeffreys-Perks method
{p_end}
{p 4 8 2}
5. Mee -- Score method of Mee
{p_end}
{p 4 8 2}
6. Miettinen-Nurminen -- Score method
{p_end}
{p 4 8 2}
7. Profile -- Profile-likelihood method
{p_end}
{p 4 8 2}
8. Tail exact -- Tail-area profile, full tie probability
{p_end}
{p 4 8 2}
9. Tail mid-p -- Tail-area profile, half tie probability
{p_end}
{p 4 8 2}
10. Wilson -- Combination of Wilson score intervals
{p_end}
{p 4 8 2}
11. Wilson CC -- Combination of continuity-corrected
Wilson score intervals
{p_end}

{pstd}
Methods 1-4 are truncated to [-1,1] when necessary.
Methods 5-9 use numerical procedures. Methods 10 and 11
combine separate Wilson intervals geometrically.
Method 11 follows Newcombe's 1999 correction: with
continuity correction, only the first (geometric)
expressions for the endpoint offsets are valid.
{p_end}

{marker options}{...}
{title:Options}

{phang}
{opt method(#)} selects the method to display (1-11).
Default is 10. All eleven intervals are calculated
and returned in {cmd:r(ci)}, subject to the limit below.
{p_end}

{phang}
{opt all} displays all eleven intervals.
{p_end}

{phang}
{opt level(#)} specifies the nominal confidence percentage,
strictly between 0 and 100. Default is 95.
{p_end}

{phang}
{opt by(group)} specifies the numeric grouping variable
in dataset syntax. Exactly two groups are required,
and nonmissing outcomes must be 0 or 1.
{p_end}

{title:Computational limit for methods 8 and 9}

{pstd}
Methods 8 and 9 enumerate possible binomial outcomes
and can be computationally expensive. Version 0.6.1
calculates them only if
{cmd:(n1+1)*(n2+1) <= 10000}.
Beyond this limit, their endpoints are missing in
{cmd:r(ci)}. Selecting method 8 or 9 prints an explanatory
message. Other methods remain available. This is an
implementation limit, not a theoretical restriction.
{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:newcombe11} is an {cmd:rclass} command.
{p_end}

{p 4 8 2}
{cmd:r(ci)} -- 11 x 2 matrix. Rows 1-11 correspond to
methods 1-11; columns are {cmd:lb} and {cmd:ub}.
{p_end}
{p 4 8 2}
{cmd:r(lb)}, {cmd:r(ub)} -- selected interval endpoints
(possibly missing).
{p_end}
{p 4 8 2}
{cmd:r(diff)} -- observed difference {it:x1/n1 - x2/n2}.
{p_end}
{p 4 8 2}
{cmd:r(p1)}, {cmd:r(p2)} -- observed proportions.
{p_end}
{p 4 8 2}
{cmd:r(x1)}, {cmd:r(n1)}, {cmd:r(x2)}, {cmd:r(n2)} -- counts.
{p_end}
{p 4 8 2}
{cmd:r(level)} -- nominal confidence percentage.
{p_end}
{p 4 8 2}
{cmd:r(method)} -- selected method number.
{p_end}

{marker examples}{...}
{title:Examples}

{p 4 8 2}
{stata "newcombe11 9 10 3 10":. newcombe11 9 10 3 10}
{p_end}
{p 4 8 2}
{stata "newcombe11 9 10 3 10, all":. newcombe11 9 10 3 10, all}
{p_end}
{p 4 8 2}
{stata "newcombe11 9 10 3 10, method(11) level(95)":. newcombe11 9 10 3 10, method(11) level(95)}
{p_end}
{p 4 8 2}
{cmd:. matrix list r(ci)}
{p_end}
{p 4 8 2}
{cmd:. scalar lower = r(lb)}
{p_end}
{p 4 8 2}
{cmd:. newcombe11 outcome, by(group) method(6)}
{p_end}
{pstd}
Self-contained example with value labels (dataset syntax):
{p_end}
{p 4 8 2}
{cmd:. preserve}
{p_end}
{p 4 8 2}
{cmd:. clear}
{p_end}
{p 4 8 2}
{cmd:. input byte outcome byte group}
{p_end}
{p 4 8 2}
{cmd:1 1}
{p_end}
{p 4 8 2}
{cmd:0 1}
{p_end}
{p 4 8 2}
{cmd:1 2}
{p_end}
{p 4 8 2}
{cmd:0 2}
{p_end}
{p 4 8 2}
{cmd:end}
{p_end}
{p 4 8 2}
{cmd:. label define dept 1 "Surgery" 2 "Medical"}
{p_end}
{p 4 8 2}
{cmd:. label values group dept}
{p_end}
{p 4 8 2}
{cmd:. newcombe11 outcome, by(group)}
{p_end}
{p 4 8 2}
{cmd:. restore}
{p_end}
{pstd}
Here the difference is Surgery minus Medical, because 1 is
smaller than 2. Relabeling the categories does not change the sign.
{p_end}


{title:Interpretation and limitations}

{pstd}
The parameter is a difference of proportions, not an odds
ratio or relative risk. Coverage probability is defined
under repeated sampling. Mean coverage close to nominal
does not imply nominal coverage at every parameter point.
In particular, "exact" in method 8 describes its tail-area
construction, not a universal minimum-coverage guarantee.
{p_end}

{pstd}
Actual coverage and interval width can vary substantially,
especially for small samples and proportions near 0 or 1.
Wald intervals can have severe undercoverage. Method 11
is often more conservative than method 10, but neither
method is uniformly superior in all settings.
{p_end}

{pstd}
The command assumes independent binomial samples with
fixed denominators. The difference is measured in proportion
units (multiply by 100 for percentage points). It is not designed
for paired binary observations, clustered data, or dependent samples.
{p_end}

{title:Installation}

{pstd}
After the package has been published in the SSC archive,
install it by typing:
{p_end}

{p 8 12 2}
{cmd:. ssc install newcombe11}
{p_end}

{pstd}
To check the installed command and open its documentation, type:
{p_end}

{p 8 12 2}
{cmd:. which newcombe11}
{p_end}
{p 8 12 2}
{cmd:. help newcombe11}
{p_end}

{pstd}
The Mata routines are included in the ado file; no separate
Mata source file is required.
{p_end}

{title:References}

{pstd}
Newcombe RG. Interval estimation for the difference
between independent proportions: comparison of eleven
methods. {it:Statistics in Medicine}. 1998;17:873-890.
{p_end}

{pstd}
Newcombe RG. Correction. {it:Statistics in Medicine}.
1999;18(10):1293.
{p_end}

{pstd}
The implementation of Method 11 (continuity-corrected Wilson)
follows the corrected expressions published in Newcombe's
1999 erratum.
{p_end}

{title:Author and acknowledgments}

{pstd}
Silvano Andorno is the responsible author and maintainer of
{cmd:newcombe11}. Development, documentation and testing
were assisted by ChatGPT (OpenAI). The author is responsible
for verification and any distribution of the software.
{p_end}

{pstd}
Maintainer email: silvano.andorno@uniupo.it
Alternative contact: silvano.andorno@gmail.com
{p_end}
