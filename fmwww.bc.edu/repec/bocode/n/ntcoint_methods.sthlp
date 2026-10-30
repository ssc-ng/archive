{smcl}
{* *! version 1.0.0  27oct2026}{...}
{vieweralsosee "ntcoint" "help ntcoint"}{...}
{viewerjumpto "The model" "ntcoint_methods##model"}{...}
{viewerjumpto "The statistic" "ntcoint_methods##stat"}{...}
{viewerjumpto "Limiting behaviour" "ntcoint_methods##limits"}{...}
{viewerjumpto "Critical values" "ntcoint_methods##cv"}{...}
{viewerjumpto "A discrepancy in the replication package" "ntcoint_methods##discrepancy"}{...}
{viewerjumpto "Bootstrap" "ntcoint_methods##boot"}{...}
{viewerjumpto "Step-to-equation map" "ntcoint_methods##map"}{...}
{viewerjumpto "Departures from the authors' code" "ntcoint_methods##departures"}{...}
{viewerjumpto "Validation" "ntcoint_methods##validation"}{...}

{title:Title}

{phang}
{bf:ntcoint methods} {hline 2} Derivation, step-to-equation map and validation
evidence for {helpb ntcoint}

{pstd}
Throughout, {bf:(Pn)} refers to equation {it:n} of Hualde and Olmo (2026) and
{bf:(OAn)} to equation {it:n} of its online appendix.


{marker model}{title:The model}

{pstd}
The observable 2x1 vector x_t is generated, after reordering, by the triangular
system (P2)-(P3)

{p 8 8 2}Delta(x_t - mu_t) = u_t,{break}
u_t = B * diag(Delta^(1-d1), Delta^(1-d2)) * v_t,{p_end}

{pstd}
with B unit upper triangular with (1,2) element {it:b}, v_t a zero-mean I(0)
process satisfying Assumption 1 (a linear process with summable coefficients,
finite fourth cumulants and nonsingular long-run covariance), and mu_t a
constant or a constant plus linear trend. The memory parameters d1 {ul:<} d2,
each in {0,1}, index the state of nature:

{p2colset 8 30 32 2}{...}
{p2col :{bf:d1=1, d2=1}, any b}no cointegration (NC), both series I(1){p_end}
{p2col :{bf:d1=0, d2=1}, b=0}trivial cointegration (TC): x1 is I(0), x2 is I(1),
and (1,0)' is a cointegrating vector{p_end}
{p2col :{bf:d1=0, d2=1}, b!=0}{bf:nontrivial} cointegration (NTC): both I(1),
cointegrating vector (1,-b) with no zero entry{p_end}
{p2col :{bf:d1=0, d2=0}, any b}full cointegration (FC): both series
stationary, cointegrating rank 2{p_end}
{p2colreset}{...}

{pstd}
H0 is the union NC {c 136} TC {c 136} FC; H1 is NTC. Note that H0 is a union of
three quite different regimes {hline 2} this is why a single-step test is worth
having, and why sequential procedures built from unit-root and cointegration
tests struggle to be both correctly sized and consistent.


{marker stat}{title:The statistic}

{pstd}
{bf:Step 1. Remove deterministics.} Without {opt trend}, x^c_it = x_it - xbar_i.
With {opt trend}, x^tr_it is the residual from the ordinary least squares
regression of x_it on (1, t)', which is (OA2).

{pstd}
{bf:Step 2. The sample correlation.} (P11),

{p 8 8 2}rhat = sum(x^c_1t x^c_2t) / sqrt( sum(x^c_1t)^2 * sum(x^c_2t)^2 ).{p_end}

{pstd}
Equivalently, standardize both series and regress one on the other without a
constant; the slope {it:is} rhat and the normalized residual sum of squares is
D = 1 - rhat^2, which is (P12). D is already invariant to the ordering of the
two variables, and it is the raw ingredient of the test.

{pstd}
{bf:Step 3. Long-run covariances at two bandwidths.} Form u_t = Delta x_t, demean
it, and compute the kernel estimate (P16)-(P17)

{p 8 8 2}Omegahat(lambda) = sum_j w(j/K) * Gammahat(j),   K = C * T^lambda,{p_end}

{pstd}
with w the Parzen kernel. Two bandwidths are used, a slow one lambda1 and a fast
one lambda2, with 0 < lambda2 < lambda1 < 1/3. The upper bound 1/3 comes from
Theorems 9 and 10 of Chapter 5 of Hannan (1970), which give the variance rate
O_p(T^lambda * T^-((1-lambda)/2)) and the bias rate O_p(T^(-2*lambda)) for these
estimates; 1/3 is what makes the remainder term in the proof of Theorem 2(iii)
negligible. The Parzen choice is not cosmetic: it satisfies the kernel condition
(Assumption K) of Kheifets and Phillips (2023) on which the proofs of (P30),
(P31), (P41) and (P42) rest, it keeps Omegahat positive semi-definite, and it
guarantees SCR {ul:>} 0 in finite samples. The Tukey-Hanning kernel satisfies
Assumption K but not the last property.

{pstd}
{bf:Step 4. The long-run correlation.} (P18)-(P19),

{p 8 8 2}rhohat^2 = max( A + B , 0 ),{p_end}
{p 8 8 2}A = Omega12(l1)^2 / ( Omega11(l2) Omega22(l2) ),{p_end}
{p 8 8 2}B = [ Omega11(l2)Omega22(l2) - Omega11(l1)Omega22(l1) ] / [ Omega11(l2)Omega22(l2) ],{p_end}

{pstd}
so that

{p 8 8 2}1 - rhohat^2 = [ Omega11(l1)Omega22(l1) - Omega12(l1)^2 ] / [ Omega11(l2)Omega22(l2) ].{p_end}

{pstd}
{cmd:ntcoint} computes this last expression directly and truncates it {it:above}
at 1, which is algebraically identical to truncating rhohat^2 below at 0. The
authors' {cmd:D_test.m} writes the same truncation as {cmd:min(1,rhoden)}.

{pstd}
Why two bandwidths? With a single one (lambda1 = lambda2 = lambda, equation
(P20)) the estimator is consistent and the test behaves well almost everywhere,
but under full cointegration with a particular dependence structure the ratio
(1 - rhat^2)/(1 - rhohat^2) can tend to a value below the critical value, so the
test rejects H0 with probability approaching one although the data are merely
stationary. The slow/fast pair makes 1 - rhohat^2 shrink at a {it:different}
rate from 1 - rhat^2 under FC, which sends SCR to +infinity and restores correct
size. This is Remark 2.2 and Theorem 2(iv). If the two bandwidths round to the
same integer, that mechanism is gone, and {cmd:ntcoint} says so.

{pstd}
{bf:Step 5. The statistic.} (P15), SCR = (1 - rhat^2) / (1 - rhohat^2). In the
trend case this is (OA8) with the demeaned autocovariance (OA9).


{marker limits}{title:Limiting behaviour}

{pstd}
Theorem 2 (and Theorem S2 for the trend case) gives, as T -> infinity:

{p2colset 8 34 36 2}{...}
{p2col :{bf:NC}}SCR -> A(rho) in distribution{p_end}
{p2col :{bf:TC}}T^(2(lambda2-lambda1)) SCR -> 1, so SCR -> +infinity{p_end}
{p2col :{bf:NTC}}SCR = O_p(T^(2*lambda1 - 1)) -> 0{p_end}
{p2col :{bf:FC}}T^(4(lambda2-lambda1)) SCR -> (1-r^2)/(1-rho_Bv^2) > 0, so SCR -> +infinity{p_end}
{p2colreset}{...}

{pstd}
Rejecting for small SCR therefore gives a test that is correctly sized under all
three components of H0 and consistent against H1. The price of the normalization
is visible in the NTC rate: SCR vanishes at T^(2*lambda1 - 1), slower than the
T^-1 of the unnormalized D. That is the content of Remark 2.3.


{marker cv}{title:Critical values}

{pstd}
Under NC the limit is the random variable A(rho) of (P14), which depends on the
nuisance parameter rho. Let V1, V2 be independent standard Brownian motions on
[0,1], write Vt_i for the demeaned path, and set

{p 8 8 2}a1 = int Vt1^2,  a2 = int Vt2^2,  c = int Vt1 Vt2,  m_i = int s Vt_i(s) ds.{p_end}

{pstd}
Then (P14) reduces to

{p 8 8 2}{bf:A(rho) = (a1 a2 - c^2) / ( e * a2 )},{break}
{bf:e = (1-rho^2) a1 + 2 rho sqrt(1-rho^2) c + rho^2 a2}.{p_end}

{pstd}
The trend-case functional A^tr(rho) of the online appendix, written there as a
ratio B / C(rho) with several twelves and a twenty-four, is {it:the same
expression} evaluated at the trend-adjusted moments

{p 8 8 2}a_i^tr = a_i - 12 m_i^2,   c^tr = c - 12 m_1 m_2.{p_end}

{pstd}
The reduction is exact: expanding a1^tr a2^tr - (c^tr)^2 reproduces the
appendix's B term by term, and C(rho) equals e^tr * a2^tr.

{pstd}
{cmd:ntcoint} ships tables of the 10%, 5% and 1% quantiles of A(rho) and
A^tr(rho) over rho = -1 (0.001) 1, simulated with 200,000 Brownian paths of
1,000 steps and symmetrized in rho (the distribution depends on |rho| only,
Remark 1.1). The {bf:plug-in} value is the table entry at rhohat; the
{bf:conservative} value is the infimum over rho, attained at |rho| = 1, which is
(P22):

{p 8 8 2}Pr( A(rho) {ul:<} cv ) {ul:<} Pr( A(rho) {ul:<} cv(rho) ) = alpha.{p_end}

{pstd}
Our conservative values are

{p 8 8 2}constant case: 0.1592 (10%), 0.1084 (5%), 0.0559 (1%){break}
trend case:    0.2935 (10%), 0.2202 (5%), 0.1296 (1%){p_end}


{marker discrepancy}{title:A discrepancy in the replication package}

{pstd}
The article prints 0.139, 0.096 and 0.040 for the constant case and 0.274,
0.196 and 0.124 for the trend case, matching the {it:thr_asy1.txt} and
{it:thr_asy2.txt} tables in its replication package. Those values are {bf:3 to
29 percent below} the ones implied by (P14). The gap is far outside Monte Carlo
error: at 200,000 replications our quantiles have a standard error near 0.001,
so the difference at |rho| = 1 is about 30 standard errors.

{pstd}
The closed form above was checked three independent ways before this was
concluded:

{phang2}1. against a brute-force evaluation of (P14) {hline 2} simulating the
Brownian paths, forming the combination sqrt(1-rho^2)Vt1 + rho Vt2, and taking
the ratio literally as written {hline 2} on the same seed. The two agree to
1e-5.{p_end}

{phang2}2. against the online appendix's B and C(rho) by algebraic
expansion.{p_end}

{phang2}3. against the {it:finite-sample} SCR statistic simulated under no
cointegration at T = 500, 2,000 and 10,000, computed by the same code path the
test itself uses. Those quantiles land on the asymptotic ones, and equally far
from the shipped tables.{p_end}

{pstd}
Two further features of the shipped tables point the same way. They are
asymmetric in the sign of rho by 5 to 12 percent, although Remark 1.1 proves the
distribution depends on |rho| only; yet adjacent rows differ by just 0.4
percent. That combination {hline 2} locally smooth, globally asymmetric {hline 2}
is what one gets from a single shared set of simulated paths with a modest
number of replications, since A(rho) and A(-rho) differ path by path even though
their distributions coincide.

{pstd}
Because H0 is rejected when SCR is {it:small}, critical values that are too
small make the conservative and plug-in tests {bf:undersized}. This is
consistent with the online appendix's own remark that the conservative version
"tends to be undersized".

{pstd}
{cmd:ntcoint} therefore offers both. {opt cvtable(exact)}, the default, follows
the paper's equations. {opt cvtable(authors)} ships the replication package's
tables verbatim and reproduces the article's printed decisions. Neither is
hidden from the user, and the output header always says which is in force.


{marker boot}{title:Bootstrap}

{pstd}
Section 3 of the online appendix gives the algorithm, which {cmd:ntcoint}
follows with {opt btype(1)}:

{phang2}{bf:Step 1.} Compute the single-bandwidth long-run correlation (OA10),
rho_theta = Omega12(lambda1) / sqrt( Omega11(lambda1) Omega22(lambda1) ).{p_end}
{phang2}{bf:Step 2.} Draw independent standard normal e1, e2 and set
u*_1t = sqrt(1 - rho_theta^2) e1t + rho_theta e2t, u*_2t = e2t.{p_end}
{phang2}{bf:Step 3.} Cumulate to a bivariate random walk x*, discarding 500
burn-in draws as the authors' {cmd:boots_crit.m} does.{p_end}
{phang2}{bf:Step 4.} Recompute the {it:entire} statistic on x*, including both
kernel estimates. This matters: a resampling test must replicate the whole
statistic, denominator included, or it will not have the right size.{p_end}
{phang2}{bf:Step 5.} The p-value is the fraction of bootstrap statistics at or
below the observed one. Reject when it is at or below alpha.{p_end}

{pstd}
Theorem S3 establishes validity: under NC the bootstrap statistic converges
weakly in probability to A(rho) and the p-value is uniform on [0,1]; under TC
and FC the p-value tends to 1 (correct size); under NTC it tends to 0
(consistency).

{pstd}
{opt btype(2)} reuses the denominator from the observed sample instead of
recomputing it, mirroring the second branch of the authors' {cmd:boots_crit.m}.
It is faster and is provided for comparison, but Theorem S3 does not cover it.

{pstd}
Where the authors return the ceil(B*alpha)-th order statistic as a critical
value, {cmd:ntcoint} returns the p-value and compares it with alpha. The two
decisions agree up to ties; the p-value is simply more informative.


{marker map}{title:Step-to-equation map}

{col 5}{bf:Code}{col 30}{bf:Equation}{col 48}{bf:What it does}
{hline 76}
{col 5}ntc_detrend{col 30}P sec.3 / OA2{col 48}remove constant, or (1,t)
{col 5}ntc_stat, r{col 30}P11{col 48}sample correlation
{col 5}ntc_stat, 1-r^2{col 30}P12{col 48}the D statistic
{col 5}ntc_kw{col 30}P sec.3{col 48}Parzen kernel weights
{col 5}ntc_hac{col 30}P16-P17 / OA9{col 48}long-run covariance at K
{col 5}ntc_stat, om{col 30}P18-P19{col 48}1 - rhohat^2, two bandwidths
{col 5}ntc_stat, scr{col 30}P15 / OA8{col 48}SCR
{col 5}ntc_stat, st[4]{col 30}OA10{col 48}rho_theta for the bootstrap
{col 5}ntc_readcv + idx{col 30}P14, Thm 2(i){col 48}plug-in cv, A(rhohat)
{col 5}cv[1,.]{col 30}P22{col 48}conservative cv, A(+-1)
{col 5}ntc_boot{col 30}OA sec.3, Thm S3{col 48}bootstrap p-value
{col 5}cvgen, ntc_A{col 30}P14 / OA A^tr{col 48}simulate the cv tables
{hline 76}


{marker departures}{title:Departures from the authors' code}

{pstd}
Where the paper's equations and the replication code disagree, {cmd:ntcoint}
follows the equations and records the choice here.

{phang}
{bf:1. Detrending.} (OA2) defines the trend-case residual as the OLS residual
from a regression on (1, t)' {it:jointly}. The authors' {cmd:D_test.m} regresses
on t alone, without a constant, and only then subtracts the mean. Sequential is
not the same as joint, and the two differ in finite samples. {cmd:ntcoint} uses
the joint regression.

{phang}
{bf:2. Trend origin.} {cmd:D_test.m} uses the index 501:T+500 for the trend.
That is harmless inside the bootstrap, where 500 burn-in draws really are
discarded, but the same code is applied to the observed data, where there is no
burn-in; combined with the missing constant, the origin shift is not innocuous.
{cmd:ntcoint} uses 1:T.

{phang}
{bf:3. Numerator divisor.} {cmd:D_test.m} standardizes with a divisor of T-1 and
then averages squared residuals with a divisor of T, so its numerator is
((T-1)/T)(1 - rhat^2) rather than 1 - rhat^2. {cmd:ntcoint} uses the exact
quantity. The difference is O(1/T) and reaches 2 percent at T = 50.

{phang}
{bf:4. Demeaning the differences.} (P17) sums Delta x without demeaning in the
constant case, while (OA9) demeans. The authors' {cmd:hac.m} always demeans.
{cmd:ntcoint} always demeans too: under mu_t = mu the mean of Delta x is zero
anyway, and demeaning is the safer finite-sample choice.

{phang}
{bf:5. Bandwidth rounding.} K_i = round(C T^lambda_i), as in {cmd:hac.m}.
{cmd:ntcoint} adds a warning when the two round to the same integer, which
happens for T below roughly 350 at the default exponents and silently disables
the two-bandwidth mechanism.

{phang}
{bf:6. Critical values.} See {help ntcoint_methods##discrepancy:above}.


{marker validation}{title:Validation}

{pstd}
{bf:Table 4 of the paper is reproduced exactly.} Running {cmd:ntcoint} on the
euro-area yield data with the default settings returns all 42 reported values
{hline 2} 21 short-run correlations and 21 long-run correlations {hline 2} to
every printed digit. For example (3m,1y) gives r = 0.9898 and rho = 0.4540
against the published 0.989 and 0.454; (5y,7y) gives 0.9932 and 0.9762 against
0.993 and 0.976; (10y,30y) gives 0.9867 and 0.8239 against 0.987 and 0.824.
This fixes the statistic, the kernel, the bandwidths and the data simultaneously.

{pstd}
{bf:Table 3 is reproduced in 18 of 21 pairs at 10% and 20 of 21 at 5%} when run
with {opt cvtable(authors)}. Of the disagreements, (3m,10y) is a bootstrap
boundary call, p = 0.092 against a 0.10 threshold and inside Monte Carlo error
at 500 replications. The other two appear to be errors in the article: for
(5y,30y) at 10% it reports a plug-in rejection, but its own Table 4 value
rhohat = 0.651 and its own thr_asy1 table give a critical value of 0.179
against SCR = 0.2197, which is not a rejection; for (2y,30y) it reports a
bootstrap rejection where we obtain p = 0.166. These cells are documented, not
engineered around.

{pstd}
{bf:The paper's own Monte Carlo is recovered.} On DGP1 of the online appendix at
the 10% level, {cmd:ntcoint_example.do} returns rejection frequencies of exactly
0.000 under trivial and full cointegration at both T = 100 and T = 200, matching
the published 0.000; power under NTC of 0.98 at T = 100 and 1.00 at T = 200
against the published 0.978 and 0.999; and bootstrap size under no cointegration
of 0.220 at T = 100 against the published 0.222. The plug-in version is somewhat
more oversized than the published figure at T = 100, which is the expected
consequence of using the larger, equation-consistent critical values.


{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}


{title:Also see}

{psee}
{bf:{help ntcoint:help ntcoint}}
{p_end}
