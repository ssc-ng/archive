{smcl}
{* *! version 1.0.0 24sep2026}{...}
{title:sreg_rgen — Generate stratified randomized experiments}

{p 4 4 2}
Generates observed outcomes, treatment assignments, strata indicators,
cluster identifiers, cluster sizes and covariates for stratified randomized
experiments under covariate-adaptive randomization (CAR).

{title:Syntax}
{p 8 8 2}
{cmd:sreg_rgen, n(}{it:#}{cmd:)}
[{cmd:individual} {cmd:strata(}{it:#}{cmd:)} {cmd:nmax(}{it:#}{cmd:)}
{cmd:tau(}{it:numlist}{cmd:)} {cmd:gamma(}{it:numlist}{cmd:)}
{cmd:nocovariates} {cmd:smallstrata} {cmd:mixedstrata}
{cmd:k(}{it:#}{cmd:)} {cmd:nsmall(}{it:#}{cmd:)}
{cmd:treatsizes(}{it:numlist}{cmd:)}
{cmd:allocation(}{it:matrix}{cmd:)}
{cmd:stratumeffects(}{it:numlist}{cmd:)}
{cmd:treatmenteffects(}{it:matrix}{cmd:)} {cmd:clear}]

{title:Options}
{p 4 4 2}
{cmd:n()} is the number of assignment units: clusters by default, people with
{cmd:individual}. Cluster sizes are uniformly distributed over 10,20,...,{cmd:nmax()},
which defaults to 50 and must be a multiple of 10.

{p 4 4 2}
{cmd:strata()} defaults to 10 large-stratum bins. Empty bins are possible.
{cmd:tau()} lists active treatment effects; default 0 (one active arm).
Control is always coded 0. {cmd:gamma()} supplies exactly three coefficients,
default .4 .2 1, on the stratification variable and two covariates.
{cmd:nocovariates} omits x_1 and x_2. It also removes their outcome
contribution for individual assignment, but only hides them for clusters.

{p 4 4 2}
{cmd:smallstrata} sorts assignment units by the latent stratification variable
and makes consecutive blocks of {cmd:k()} units (default 3). {cmd:n()} must
be divisible by k. {cmd:treatsizes()} specifies integer arm counts, control
first, summing to k. For this design the default is {cmd:1 1 1}; with one
active arm, explicitly specify, for example, {cmd:treatsizes(2 1)}.

{p 4 4 2}
{cmd:mixedstrata} independently generates small and large components.
{cmd:nsmall()} defaults to floor(n/(2*k))*k. Small component size must be
positive, less than n, and divisible by k. There must be more small strata
than large bins, and n-nsmall must exceed strata*k. The default arm counts
are as equal as possible, with remainder units assigned to earlier arms.
Do not combine {cmd:smallstrata} and {cmd:mixedstrata}.

{p 4 4 2}
Custom allocations and effects require {cmd:individual} and large strata.
{cmd:allocation()} names a strictly positive matrix with strata rows and one
column per arm, control first; rows sum to one. Active counts are floor(p*n_s),
and control receives the remainder. {cmd:stratumeffects()} adds a common
shift per stratum. {cmd:treatmenteffects()} names a strata-by-active-arms
matrix that replaces tau within each stratum; it does not add to tau.

{p 4 4 2}
{cmd:clear} permits replacing data in memory. Failed validation preserves data.
Use {cmd:set seed} for reproducibility.

{title:Generated variables}
{p 4 4 2}
Y (outcome), S (stratum), D (arm), x_1 and x_2 (unless omitted).
Cluster designs additionally contain G_id and Ng, the cluster ID and size.
Mixed designs have disjoint cluster and stratum IDs across components.

{title:Stored results}
{p 4 4 2}
r(N): observations; r(N_units): assignment units; r(N_treatments): active arms;
r(cluster): cluster flag; r(n_small): small-component units; r(design):
large, small, or mixed. Estimation is a separate call to {help sreg}.

{title:Examples}
{phang}{cmd:set seed 2026}
{phang}{cmd:sreg_rgen, n(600) individual strata(5) tau(.5 .8) clear}
{phang}{cmd:sreg Y x_1 x_2, treatment(D) strata(S)}
{phang}{cmd:sreg_rgen, n(120) tau(.2 .8) smallstrata clear}
{phang}{cmd:sreg Y x_1 x_2, treatment(D) strata(S) cluster(G_id) clustersize(Ng) smallstrata k(3)}

{title:Estimation requirements}
{p 4 4 2}
Small or sparse generated designs need not satisfy the estimator's stronger
cell-size and even-number-of-matched-strata requirements.

{title:Project and software}

{p 4 4 2}
This is the Stata version of the R package sreg, implemented natively in
Stata and Mata. R is not required to use this package.

{p 4 4 2}
{browse "https://sreg-project.github.io":Project website}
{break}
{browse "https://github.com/jutrifonov/sreg-stata":Stata GitHub repository}
{break}
{browse "https://github.com/jutrifonov/sreg":R package}
