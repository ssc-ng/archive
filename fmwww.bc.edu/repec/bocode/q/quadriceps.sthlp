{smcl}
{* *! version 0.1.2  24sep2026}{...}
{vieweralsosee "[R] net" "help net"}{...}
{vieweralsosee "[M-5] bufio()" "help mata bufio()"}{...}
{viewerjumpto "Syntax" "quadriceps##syntax"}{...}
{viewerjumpto "Description" "quadriceps##description"}{...}
{viewerjumpto "Options" "quadriceps##options"}{...}
{viewerjumpto "Remarks" "quadriceps##remarks"}{...}
{viewerjumpto "Mata functions" "quadriceps##mata"}{...}
{viewerjumpto "Examples" "quadriceps##examples"}{...}
{viewerjumpto "Stored results" "quadriceps##results"}{...}
{viewerjumpto "References" "quadriceps##references"}{...}
{viewerjumpto "Author" "quadriceps##author"}{...}
{title:Title}

{phang}
{bf:quadriceps} {hline 2} Positive-weight cubature rules for the Gaussian weight ({bf:ghpos}) and
the cube ({bf:lepos})


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:ghpos} {it:d} [{it:q}] [{cmd:,} {it:options}]

{p 8 16 2}
{cmd:lepos} {it:d} [{it:q}] [{cmd:,} {it:options}]

{p 8 16 2}
{cmd:quadriceps} {cmd:nnodes} {it:family} {it:d} [{it:q}] [{cmd:,} {opt p(#)} {opt prag:matic}]

{p 8 16 2}
{cmd:quadriceps} {cmd:ruleinfo} {it:family} {it:d} [{it:q}] [{cmd:,} {opt p(#)} {opt prag:matic}]

{p 8 16 2}
{cmd:quadriceps} {cmd:check} {it:family} {it:d} [{it:q}] [{cmd:,} {opt p(#)} {opt prag:matic}]

{p 8 16 2}
{cmd:quadriceps} {cmd:rules} [{it:family}]

{p 8 16 2}
{cmd:quadriceps} {cmd:version}

{pstd}
where {it:family} is {cmd:gh} (standard normal density on R^{it:d}) or {cmd:le} (uniform density
on [0,1]^{it:d}); {cmd:ghpos} is the same as {cmd:quadriceps gh}, and {cmd:lepos} the same as
{cmd:quadriceps le}.

{synoptset 22 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Rule}
{synopt:{opt p(#)}}the degree of exactness, instead of {it:q}{p_end}
{synopt:{opt prag:matic}}fall back to the cheapest tensor product when no stored rule covers the request{p_end}
{synopt:{opt nonorm:alize}}use the conventions of the classical Gauss rules: weight exp(-|x|^2), or the plain integral over [-1,1]^{it:d}{p_end}

{syntab:Output}
{synopt:{opt frame(name)}}put the rule in frame {it:name}; default {cmd:quadriceps}{p_end}
{synopt:{opt rep:lace}}overwrite frame {it:name} if it exists{p_end}
{synopt:{opt mat:rix(name)}}also store the rule as Stata matrix {it:name}{p_end}
{synopt:{opt mata(X w)}}also store the nodes and weights as Mata matrices {it:X} and {it:w}{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
A cubature rule of degree {it:p} in {it:d} dimensions is a set of {it:n} nodes x_i in R^{it:d}
and weights w_i > 0 such that sum_i w_i f(x_i) equals the integral of f against the weight
function for every polynomial f of total degree at most {it:p}. The product of {it:q}-node
one-dimensional Gauss rules does this for {it:p} = 2{it:q} - 1 with {it:q}^{it:d} nodes. The
rules stored in this package, the smallest positive-weight rules known to the author, do it with
far fewer: for example 244 nodes instead of 3125 for the Gaussian weight at {it:d} = 5,
{it:q} = 5.

{pstd}
{cmd:ghpos} {it:d} {it:q} returns a rule for the standard normal density N(0, I_{it:d}), the
counterpart of the {it:q}-node Gauss-Hermite rule: it is exact to degree {it:p} = 2{it:q} - 1,
replaces the {it:q}^{it:d}-node product grid, and for {it:d} = 1 is the {it:q}-node Gauss-Hermite
rule itself. {cmd:lepos} {it:d} {it:q} does the same for the uniform density on [0,1]^{it:d}
and the Gauss-Legendre rule. A rule can be asked for by its degree instead, with {opt p(#)};
give {it:q} or {opt p()}, not both. Rules are stored at odd degrees, and a request is served by
the smallest stored rule of degree at least {it:p}, so an even {it:p} gets the rule for
{it:p} + 1.

{pstd}
The rule goes into a frame ({opt frame()}, by default the frame {cmd:quadriceps}, which is
overwritten on every call), as variables {cmd:x1} ... {cmd:x}{it:d} and {cmd:w}, one node per
observation; the weights are all strictly positive and, by default, sum to 1. Options put a copy
in a Stata matrix or in Mata. The current data are not touched.

{pstd}
Rules are stored for 2 <= {it:d} <= 5, up to a degree that depends on the family and on {it:d}
({cmd:quadriceps rules} lists them). Elsewhere, {cmd:ghpos} and {cmd:lepos} stop with return
code 499 unless {opt pragmatic} is given.

{pstd}
{cmd:quadriceps nnodes} reports the number of nodes of the rule {cmd:ghpos} or {cmd:lepos}
would return, without building it. {cmd:quadriceps ruleinfo} describes that rule: its tensor
factors, if any, and the published source of every rule that is not the author's own, which is
whom to cite. {cmd:quadriceps check} builds the rule and measures its largest relative
monomial error. {cmd:quadriceps rules} lists the stored rules of a family.

{pstd}
This is the Stata twin of Quadriceps.jl (Julia), quadriceps-py (Python) and quadriceps-r (R),
which share their data, conventions and function names. The rules are those of the Zenodo
deposit named under {help quadriceps##references:References}.


{marker options}{...}
{title:Options}

{dlgtab:Rule}

{phang}
{opt p(#)} asks for a rule by its degree of exactness, {it:#} >= 0, instead of by {it:q}.
{cmd:ghpos} {it:d} {it:q} is the same as {cmd:ghpos} {it:d}{cmd:, p(}2{it:q} - 1{cmd:)}.

{phang}
{opt pragmatic} says what to do when no stored rule covers the request. Without it, the command
stops with return code 499 and a message that says how far the stored rules go. With it, the
command returns the cheapest tensor product of lower-dimensional rules: the split of {it:d}
into stored rules and one-dimensional Gauss rules that needs the fewest nodes. Such a product
is a valid positive-weight rule of the requested degree; it is just not small, though it is
much smaller than the plain product grid whenever a stored rule can be a factor. A request
that a stored rule covers returns that stored rule, with or without {opt pragmatic}.

{phang}
{opt nonormalize} changes the weight function to the convention of the classical Gauss rules.
By default the weight is a probability density, which is what an expectation needs: for
{cmd:ghpos} the standard normal density (2 pi)^(-{it:d}/2) exp(-|x|^2/2), for {cmd:lepos} the
uniform density on [0,1]^{it:d}; the weights sum to 1 and the rule computes E f(Z) or
E f(U). With {opt nonormalize}, {cmd:ghpos} integrates against exp(-|x|^2), as Gauss-Hermite
does, and the weights sum to pi^({it:d}/2); {cmd:lepos} computes the plain integral over
[-1,1]^{it:d}, as Gauss-Legendre does, and the weights sum to 2^{it:d}.

{dlgtab:Output}

{phang}
{opt frame(name)} names the frame that receives the rule. The default is the frame
{cmd:quadriceps}, which the command creates and, on later calls, overwrites without asking. Any
other frame must not exist, or {opt replace} must be given. The frame is not made current;
use {cmd:frame} {it:name}{cmd::} or {cmd:cwf} to work in it.

{phang}
{opt replace} allows {opt frame()} to overwrite an existing frame.

{phang}
{opt matrix(name)} also stores the rule as the Stata matrix {it:name}, {it:n} x ({it:d} + 1),
with columns {cmd:x1} ... {cmd:x}{it:d} and {cmd:w}. Stata matrices have at most
{cmd:c(max_matsize)} rows (11,000 in Stata/SE and Stata/MP), which the largest stored rules
exceed; the frame has no such limit.

{phang}
{opt mata(X w)} also stores the nodes as the {it:n} x {it:d} Mata matrix {it:X} and the weights
as the Mata column vector {it:w}.


{marker remarks}{...}
{title:Remarks}

{pstd}
{ul:Accuracy.} Rules are stored in double precision, each the rounding of an 80-digit rule, so
what remains of its error is rounding: the largest relative monomial error over all monomials of
degree at most {it:p} is below 5.2e-15 for every GH rule and below 4.5e-16 for every Le rule.
All weights are positive, and all nodes of the Le rules lie strictly inside the cube. The
measured value of each rule is in the {cmd:relerr} column of {cmd:quadriceps rules};
{cmd:quadriceps check} recomputes it. One-dimensional Gauss rules are computed by the
Golub-Welsch eigenvalue method in Mata.

{pstd}
{ul:Other distributions.} For Y ~ N(mu, L L') use the nodes mu + L x_i with the same weights: in
Mata, {cmd:X * L' :+ mu'}. For a box, rescale the columns of the Le nodes.

{pstd}
{ul:Whose rules these are.} Most stored rules were computed by the author. Some are, or descend
from, rules published by others; {cmd:quadriceps ruleinfo} names the source of such a rule,
which should be cited when the rule is used. The file {cmd:NOTICE.md} in the repository has the
details and the license notices that travel with the derived rules.

{pstd}
{ul:Data.} All rules are in one binary file, {cmd:quadriceps_rules.bin}, with the catalog
{cmd:quadriceps_index.tsv} next to it, both installed along the ado-path. The file is
byte-identical to the data file of the Julia, Python and R packages; its format is specified in
{cmd:FORMAT.md} in the repository.


{marker mata}{...}
{title:Mata functions}

{pstd}
The same rules are available directly in Mata once the package has been loaded (any call of
{cmd:quadriceps}, for instance {cmd:quadriceps version}, does that):

{p 8 12 2}{cmd:ghpos(}{it:d}{cmd:,} {it:q}{cmd:,} {it:X}{cmd:,} {it:w} [{cmd:,} {it:normalize}{cmd:,} {it:pragmatic}]{cmd:)}{p_end}
{p 8 12 2}{cmd:lepos(}{it:d}{cmd:,} {it:q}{cmd:,} {it:X}{cmd:,} {it:w} [{cmd:,} {it:normalize}{cmd:,} {it:pragmatic}]{cmd:)}{p_end}
{p 8 12 2}{cmd:quadriceps_rule(}{it:family}{cmd:,} {it:d}{cmd:,} {it:p}{cmd:,} {it:pragmatic}{cmd:,} {it:normalize}{cmd:,} {it:X}{cmd:,} {it:w}{cmd:)}{p_end}
{p 8 12 2}{it:n} {cmd:= quadriceps_nnodes(}{it:family}{cmd:,} {it:d}{cmd:,} {it:p}{cmd:,} {it:pragmatic}{cmd:)}{p_end}
{p 8 12 2}{it:F} {cmd:= quadriceps_ruleinfo(}{it:family}{cmd:,} {it:d}{cmd:,} {it:p}{cmd:,} {it:pragmatic}{cmd:,} {it:origins}{cmd:)}{p_end}
{p 8 12 2}{it:err} {cmd:= quadriceps_exactness(}{it:X}{cmd:,} {it:w}{cmd:,} {it:p}{cmd:,} {it:family}{cmd:)}{p_end}

{pstd}
{cmd:ghpos()} and {cmd:lepos()} fill {it:X} ({it:n} x {it:d}, one node per row) and {it:w}
({it:n} x 1); {it:normalize} (default 1) and {it:pragmatic} (default 0) are as the options.
{cmd:quadriceps_rule()} is the same with the degree {it:p} in place of {it:q} and the family
{cmd:"gh"} or {cmd:"le"} as a string. {cmd:quadriceps_ruleinfo()} returns one row per tensor
factor, columns {it:d}, {it:p}, {it:n} and {it:source_id} (-1 for a Gauss rule), and fills
{it:origins} with the origin text of each factor. {cmd:quadriceps_exactness()} is the largest
relative monomial error of any rule, for the normalized weight of {it:family}.

{pstd}
Example: {cmd:mata: ghpos(3, 4, X=., w=.)} and then {cmd:mata: w' * (X[,1]:^2 :* X[,2]:^4)}
gives E[Z1^2 Z2^4] = 3.


{marker examples}{...}
{title:Examples}

{pstd}The GH rule of degree 7 in three dimensions: 27 nodes instead of the 64 of the product grid{p_end}
{phang2}{cmd:. ghpos 3 4}{p_end}
{phang2}{cmd:. frame quadriceps: gen double f = w * x1^2 * x2^4}{p_end}
{phang2}{cmd:. frame quadriceps: summarize f, meanonly}{p_end}
{phang2}{cmd:. display r(sum)}{space 20}E[Z1^2 Z2^4] = 3{p_end}

{pstd}The same rule, requested by its degree{p_end}
{phang2}{cmd:. ghpos 3, p(7)}{p_end}

{pstd}A rule on the unit square, degree 9: 17 nodes instead of 25{p_end}
{phang2}{cmd:. lepos 2 5, frame(square) replace}{p_end}

{pstd}The same rule for the plain integral over [-1,1]^2, as a Stata matrix{p_end}
{phang2}{cmd:. lepos 2 5, nonormalize matrix(R)}{p_end}
{phang2}{cmd:. matrix list R}{p_end}

{pstd}No stored rule in seven dimensions; the fallback is a product (d = 2) x (d = 5){p_end}
{phang2}{cmd:. ghpos 7 5}{p_end}
{phang2}{cmd:. ghpos 7 5, pragmatic}{p_end}
{phang2}{cmd:. quadriceps nnodes gh 10 3, pragmatic}{p_end}
{phang2}{cmd:. quadriceps ruleinfo gh 7 5, pragmatic}{p_end}

{pstd}What is stored, and how exact a rule is{p_end}
{phang2}{cmd:. quadriceps rules le}{p_end}
{phang2}{cmd:. quadriceps check gh 5 11}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:ghpos}, {cmd:lepos} and {cmd:quadriceps gh}|{cmd:le} store the following in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(n)}}number of nodes{p_end}
{synopt:{cmd:r(d)}}dimension{p_end}
{synopt:{cmd:r(p)}}degree requested (the rule is exact at least to this degree){p_end}
{synopt:{cmd:r(normalize)}}1 unless {opt nonormalize} was given{p_end}
{synopt:{cmd:r(pragmatic)}}1 if {opt pragmatic} was given{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(family)}}{cmd:gh} or {cmd:le}{p_end}
{synopt:{cmd:r(frame)}}the frame holding the rule{p_end}

{pstd}
{cmd:quadriceps nnodes} stores {cmd:r(n)}, {cmd:r(d)}, {cmd:r(p)} and {cmd:r(family)}.
{cmd:quadriceps check} stores those and {cmd:r(err)}, the largest relative monomial error.
{cmd:quadriceps ruleinfo} stores those and

{synoptset 16 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(nfactors)}}number of tensor factors (1 for a single stored rule){p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(origin}{it:k}{cmd:)}}origin of factor {it:k}: {cmd:own}, {cmd:Gauss}, or the published source{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(factors)}}one row per factor: {cmd:d}, {cmd:p}, {cmd:n}, {cmd:source_id}{p_end}


{marker references}{...}
{title:References}

{phang}
Pinkse, J. 2026. Positive weight Hermite and Legendre quadrature rules.
arXiv:2609.26840, {browse "https://doi.org/10.5281/zenodo.22904159"}.

{phang}
Pinkse, J. 2026. Positive weight Hermite and Legendre quadrature rules: the rules (data deposit).
Zenodo, {browse "https://doi.org/10.5281/zenodo.22881864"}.

{phang}
Golub, G. H., and J. H. Welsch. 1969. Calculation of Gauss quadrature rules.
{it:Mathematics of Computation} 23: 221-230.


{marker author}{...}
{title:Author}

{pstd}
Joris Pinkse, Penn State. Bug reports and questions:
{browse "https://github.com/NittanyLion/quadriceps-stata/issues"}. The Julia, Python and R
twins are at {browse "https://github.com/NittanyLion"}.
