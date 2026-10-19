{smcl}
{* *! version 1.0.0  12oct2026}{...}
{vieweralsosee "xtdyngcce" "help xtdyngcce"}{...}
{vieweralsosee "xtdyncce" "help xtdyncce"}{...}
{vieweralsosee "xtgcce" "help xtgcce"}{...}
{viewerjumpto "Model" "xtdyngcce_methods##model"}{...}
{viewerjumpto "Part I: dynamic CCE" "xtdyngcce_methods##partI"}{...}
{viewerjumpto "Bias corrections" "xtdyngcce_methods##bias"}{...}
{viewerjumpto "Inference" "xtdyngcce_methods##inference"}{...}
{viewerjumpto "Part II: generalized CCE" "xtdyngcce_methods##partII"}{...}
{viewerjumpto "Step to equation map" "xtdyngcce_methods##map"}{...}
{viewerjumpto "Decisions the papers leave open" "xtdyngcce_methods##decisions"}{...}
{viewerjumpto "Validation" "xtdyngcce_methods##validation"}{...}
{viewerjumpto "Author" "xtdyngcce_methods##author"}{...}

{title:Title}

{phang}
{bf:xtdyngcce methods} {hline 2} Derivations, equation map and validation


{marker model}{...}
{title:Model}

{pstd}
Both commands start from a panel with an unobserved common factor structure,

{p 8 8 2}
y(i,t) = w(i,t)'delta + gamma(i)'f(t) + e(i,t),

{pstd}
where f(t) is an R-vector of unobserved common factors and gamma(i) the
unit-specific loadings. If the omitted factors are correlated with the
regressors, ignoring them makes every estimator of delta inconsistent, however
long the time series.

{pstd}
The CCE idea of Pesaran (2006) is to approximate f(t) by cross-section averages
of the observed variables, which are linear in the factors by construction.
Writing Q for the T x c matrix of those averages and M = I - Q(Q'Q)^(-1)Q' for
the associated residual maker, the pooled CCE estimator is

{p 8 8 2}
deltahat = [ sum_i W(i)'M W(i) ]^(-1) [ sum_i W(i)'M y(i) ].

{pstd}
{cmd:xtdyngcce} never forms M explicitly; it applies
{cmd:M Z = Z - Q (Q'Q)^(-1) Q'Z}, which is O(T c k) rather than O(T^2 k).


{marker partI}{...}
{title:Part I: dynamic CCE (xtdyncce)}

{pstd}
With a lagged dependent variable, w(i,t) = [y(i,t-1), x(i,t)']'. The pooled CCE
estimator then admits the asymptotic expansion (JST equation 2.12)

{p 8 8 2}
sqrt(NT)(deltahat - delta0) = xi(0) + xi(perp) + sqrt(N/T) b1 + sqrt(T/N) b2 + r,

{pstd}
with four distinct pieces that any valid inference procedure must account for:

{p 6 10 2}
{bf:xi(0)} {space 4}asymptotically normal, driven by the innovations e(i,t).

{p 6 10 2}
{bf:xi(perp)} {space 1}asymptotically normal, driven by factor-approximation
error. It is {it:absent} in the pure AR(1) model but present as soon as extra
regressors enter. A clustered sandwich does not capture it.

{p 6 10 2}
{bf:b1} {space 7}the Nickell bias, of order 1/T, from the correlation between
the projected lagged dependent variable and the innovations.

{p 6 10 2}
{bf:b2} {space 7}the factor-approximation bias, of order 1/N.

{pstd}
{bf:The augmentation.} {cmd:xtdyncce} uses
Q = [1, ybar(t), ybar(t-1), xbar(t), xbar(t-1)], which is the augmentation the
source paper adopts throughout. Including the lag of xbar symmetrises the
treatment of y and x and aligns the implementation with Chudik and Pesaran
(2015) and De Vos and Everaert (2021). The constant is always present.

{pstd}
{bf:The recursive-design wild bootstrap.} For each replication:

{p 8 10 2}
1. Compute loadings and residuals from the fitted model,{break}
{space 3}gammahat(i) = (sum_t fhat fhat')^(-1) sum_t fhat (y - w'deltahat),{break}
{space 3}ehat(i,t) = y(i,t) - w(i,t)'deltahat - gammahat(i)'fhat(t).

{p 8 10 2}
2. Set y*(i,0) = y(i,0).

{p 8 10 2}
3. Regenerate y* {it:recursively},{break}
{space 3}y*(i,t) = ahat y*(i,t-1) + bhat'x(i,t) + gammahat(i)'fhat(t) + omega(i,t) ehat(i,t),{break}
{space 3}with omega Rademacher by default.

{p 8 10 2}
4. {bf:Re-estimate the cross-section averages from the bootstrap data} and
refit CCEP.

{pstd}
Steps 3 and 4 are what distinguish this from a residual wild bootstrap. The
additional regressors x(i,t) are deliberately held fixed across replications,
following the source paper; this is also the reason the bootstrap cannot
replicate xi(perp) and b2 exactly in the model with regressors, which is why
studentization is needed.

{pstd}
{bf:Why y*(i,0) = y(i,0) matters.} With that initialisation the bootstrap
cross-section average satisfies ybar*(t) = ybar(t) + sum_j ahat^j omegabar
ehat(t-j), so ybar*(t) stays consistent for ybar(t) and the only latent factor
in the bootstrap world is consistently estimable. A different initialisation
breaks that argument; {cmd:initial()} is therefore not offered.


{marker bias}{...}
{title:Bias corrections}

{pstd}
{bf:HPJ} {hline 1} Dhaene and Jochmans (2015). Split the sample in two halves,
refit, and combine:

{p 8 8 2}
deltahat(hpj) = 2 deltahat - (deltahat(1) + deltahat(2))/2.

{pstd}
{bf:The cross-section averages are recomputed inside each half-panel.} This is
essential and is why applying a general split-panel jackknife to data that were
partialled once on the full sample is {it:not} the same estimator: partialling
once and then splitting never lets the averages move with the subsample. When T
is odd the middle period is included in both halves.

{pstd}
{bf:AN} {hline 1} Moon and Weidner (2017), Definition 1 and Corollary 4.5. The
weak-exogeneity bias is estimated with a truncation kernel,

{p 8 8 2}
B1(k) = (1/N) sum_i sum_{t<s, s-t<=M} [P(Q)](t,s) ehat(i,t) w(k,i,s),

{pstd}
where P(Q) = Q(Q'Q)^(-1)Q' is the projection on the averages, and

{p 8 8 2}
deltahat(an) = deltahat + Sigmahat^(-1) B1 / T.

{pstd}
The default bandwidth is M = 1, following Hahn and Kuersteiner's own
recommendation for short panels. Set it with {cmd:anbw()}.

{pstd}
{bf:DVS} {hline 1} De Vos and Everaert (2021), equations (18) to (21). This is
the only correction that is consistent for {it:fixed} T. It solves

{p 8 8 2}
deltahat = m(delta0),{break}
m(delta0) = delta0 - T^(-1) s2(delta0) Sigmahat^(-1) q1 upsilon(rho0, H),

{pstd}
with upsilon(rho,H) = sum_{t=1}^{T-1} rho^(t-1) sum_{s=t+1}^{T} h(s,s-t),
H = Q(Q'Q)^(-1)Q', q1 = [1, 0...]' and
s2(delta0) = 1/(N(T-c)) sum_i ||M(y(i) - W(i)delta0)||^2. {cmd:xtdyncce} solves
it by the fixed-point iteration
delta0 <- deltahat + T^(-1) s2(delta0) Sigmahat^(-1) q1 upsilon, which is
algebraically the same solution as the minimum-distance form in the paper.

{pstd}
The bias loads on q1, i.e. only on the autoregressive direction; the slopes on
the exogenous regressors are distorted only through their correlation with the
lagged dependent variable. The DVS correction is derived under
{it:homoskedasticity}; this is a documented limitation of the method, not of
the implementation.


{marker inference}{...}
{title:Inference}

{pstd}
{bf:CCM} {hline 1} the clustered sandwich of Arellano (1987). It estimates the
variance of xi(0) only. In the pure AR(1) model that is the whole first-order
variance, so it suffices (JST Remark 6). With regressors it omits xi(perp) and
understates uncertainty.

{pstd}
{bf:Leave-one-out jackknife} {hline 1} JST equation (4.4),

{p 8 8 2}
Avar = ((N-1)/N) sum_i (deltahat(-i) - deltabar)(deltahat(-i) - deltabar)'.

{pstd}
{bf:Within every deltahat(-i) the factor estimates also omit unit i.} Dropping
a cluster from the regression while leaving the averages unchanged gives a
different, and wrong, object. The scaling is the "conventional" jackknife in
the sense of Hansen (2026).

{pstd}
{bf:Iterated bootstrap and studentization} {hline 1} JST equation (4.6),
following Heller and Jochmans (2026). The jackknife cannot be applied directly
inside the bootstrap world, because deleting unit i there reintroduces factor
uncertainty from x(i,t) that the bootstrap deliberately switched off. Instead a
second round of D draws is run inside each of the B first-round draws, giving
the bootstrap-world standard error and hence

{p 8 8 2}
t*(b) = (deltahat*(b) - deltahat) / se*(deltahat*(b)).

{pstd}
The reported interval is
[deltahat - q(1-a)(t*) se(jack), deltahat - q(a)(t*) se(jack)], where the
{it:real-world} scale se(jack) is the leave-one-out jackknife standard error.
That is why {cmd:vce(rdwb)} reports a jackknife standard error rather than the
bootstrap standard deviation.

{pstd}
{bf:Every bootstrap draw carries the same bias correction.} JST appendix A.1.2
is explicit: with a bias-corrected estimator the bootstrap must produce a set
of {it:bias-corrected} draws. {cmd:xtdyncce} applies the same correction inside
every replication (and inside every second-round replication). Without it, t*
is centred at the replicated bias rather than at zero and the interval misses
the truth - a failure we reproduced and fixed during development.

{pstd}
{bf:Median bias correction} {hline 1} Higgins and Jochmans (2024). The point
estimate is replaced by 2 deltahat - median(draws). It is on by default with
{cmd:vce(rdwb)}, matching the source paper. The equal-tailed reverse-percentile
interval needs no shift, because its own midpoint 2 deltahat - q(0.5) {it:is}
the median-corrected estimate; the studentized interval is built around the
corrected estimate directly.

{pstd}
{bf:Sophisticated factors} {hline 1} JST equation (4.8). The naive proxies
fhat = [ybar, ybar(-1), xbar, xbar(-1)] have 2K elements where the true factor
vector has K, so K directions are asymptotically redundant. The restricted
proxies are fddot(t) = zbar(t) - Ahat'zbar(t-1). The source paper requires Ahat
to come from the {it:multi-equation VAR(1) estimated by CCEP}, so
{cmd:xtdyncce} fits each equation of z(i,t) = A'z(i,t-1) + Gamma(i)'f(t) + e by
CCEP against the same augmentation, rather than regressing the aggregates on
their own lags.


{marker partII}{...}
{title:Part II: generalized CCE (xtgcce)}

{pstd}
For heterogeneous slopes the auxiliary regression is (LSB equation 7)

{p 8 8 2}
y(i,t) = b(i)'x(i,t) + d(i)'zbar(t) + phi(t)'xbar_a(i) + eps(i,t),

{pstd}
with zbar(t) the cross-section averages of (y, x) and
xbar_a(i) = (1, xbar(i)')' the time-series averages of the regressors plus a
constant. The closed form is

{p 8 8 2}
bhat = [X'(M(xbar_a) kron M(zbar)) X]^(-1) X'(M(xbar_a) kron M(zbar)) Y,

{pstd}
with X block diagonal, and bhat(MG) = (1/N) sum_i bhat(i).

{pstd}
{bf:Why the time-series average works.} Write xbar(i) = gamma(i) fbar + vbar(i).
Projecting the loading lambda(i) on xbar(i) gives lambda(i) = Pi xbar(i) + xi(i)
with, by construction, E[gamma(i) xi(i)] approximately zero. Substituting,

{p 8 8 2}
y(i,t) = b(i)'x(i,t) + phi(t) xbar(i) + (xi(i) f(t) + u(i,t)),

{pstd}
and the new composite error is now (almost) uncorrelated with x(i,t), whereas
in the CCE regression the error contains lambda(i) f(t) with lambda(i)
correlated with gamma(i). That correlation is the source of CCE's
inconsistency when the rank condition fails.

{pstd}
{bf:Computation.} The Kronecker product is NT x NT and is never formed. Since
M(zbar) acts within a unit and M(xbar_a) across units, block (i,j) of the
system matrix is [M(xbar_a)](i,j) times Xtil(i)'Xtil(j), where
Xtil(i) = M(zbar) x(i). {cmd:xtgcce} builds the (Nk) x (Nk) Gram matrix with a
single cross-product and multiplies it elementwise by M(xbar_a) expanded by a
k x k block of ones. The slopes are estimated {it:jointly}: the across-unit
projection couples them, so this is not a per-unit regression.

{pstd}
{bf:ybar(i) is excluded} from xbar_a(i). The reduced form for y gives
y(i,t) = (gamma(i) b(i) + lambda(i))'f(t) + ..., so the time-series average of
y mixes lambda(i) with gamma(i)b(i) and proxies nothing (LSB Remark 2).

{pstd}
{bf:Jackknife.} LSB equation (14) drops unit i from X, Y and xbar_a but keeps
zbar(t) at its {it:full-sample} value, because zbar(t) proxies a factor that
does not vary across i. Equation (15) then gives
Omegahat = (N-1) sum_i (bhat(MG,-i) - bbar)(.)', estimating the variance of
sqrt(N)(bhat - b0), so Avar(bhat) = Omegahat/N.


{marker map}{...}
{title:Step to equation map}

{pstd}
Each Mata function and the equation it implements.

{p2colset 5 34 36 2}{...}
{p2col :{bf:Function}}{bf:Source}{p_end}
{p2col :{cmd:xtdg_csa()}}JST section 3.1 (augmentation){p_end}
{p2col :{cmd:xtdg_mq()}}residual maker, never forms M{p_end}
{p2col :{cmd:xtdg_ccep()}}JST equation (2.6){p_end}
{p2col :{cmd:xtdg_ccm()}}Arellano (1987) clustered sandwich{p_end}
{p2col :{cmd:xtdg_loadres()}}JST equations (3.1)-(3.2), (4.1)-(4.2){p_end}
{p2col :{cmd:xtdg_hpj()}}Dhaene and Jochmans (2015){p_end}
{p2col :{cmd:xtdg_an()}}Moon and Weidner (2017) Def. 1, Cor. 4.5{p_end}
{p2col :{cmd:xtdg_dvs()}}De Vos and Everaert (2021) eq. (18)-(21){p_end}
{p2col :{cmd:xtdg_wild()}}wild weights; JST use Rademacher{p_end}
{p2col :{cmd:xtdg_draw1()}}JST Algorithm 1, steps 2-4{p_end}
{p2col :{cmd:xtdg_bc()}}JST appendix A.1.2 (per-draw correction){p_end}
{p2col :{cmd:xtdg_rdwb()}}JST Algorithm 1 / 2{p_end}
{p2col :{cmd:xtdg_rdwb2()}}JST equation (4.6), iterated bootstrap{p_end}
{p2col :{cmd:xtdg_soph()}}JST equation (4.8), restricted factors{p_end}
{p2col :{cmd:xtdg_loovar()}}JST equation (4.4){p_end}
{p2col :{cmd:xtdg_gcce()}}LSB equations (7)-(8){p_end}
{p2col :{cmd:xtdg_gccefit()}}LSB closed form, blockwise{p_end}
{p2col :{cmd:xtdg_gcceloo()}}LSB equations (14)-(15){p_end}
{p2colreset}{...}


{marker decisions}{...}
{title:Decisions the papers leave open}

{pstd}
Where a source paper is silent, {cmd:xtdyngcce} follows the paper's own
practice and documents the choice. These are the substantive ones.

{p 6 8 2}
{bf:1. Jackknife scaling.} JST equation (4.4) is ambiguous in the extracted
text between (N-1)/N and (N-1). The implementation uses the "conventional"
jackknife of Hansen (2026), (N-1)/N, for {cmd:xtdyncce}; {cmd:xtgcce} uses the
(N-1) form that LSB equation (15) states explicitly, with Avar = Omegahat/N.

{p 6 8 2}
{bf:2. Augmentation.} crlags(1), constant always included - JST's own choice.
Deeper lags are allowed but are outside the proved asymptotics.

{p 6 8 2}
{bf:3. Bootstrap initialisation.} y*(i,0) = y(i,0), as the paper specifies and
for the reason given above. Not user-changeable.

{p 6 8 2}
{bf:4. Wild weights.} Rademacher by default, which is what JST run. Mammen and
normal are offered as robustness checks only.

{p 6 8 2}
{bf:5. AN bandwidth.} M = 1 by default, following Hahn and Kuersteiner's
recommendation for short panels. Moon and Weidner require M to grow with T;
set {cmd:anbw()} accordingly when T is large.

{p 6 8 2}
{bf:6. Odd T in HPJ.} The middle period enters both halves. A warning about
degrees of freedom is not issued automatically; note that at T = 20 each half
has roughly 10 observations and very few effective degrees of freedom.

{p 6 8 2}
{bf:7. Unbalanced panels.} Units whose span differs from the modal span are
dropped and the count is reported; interior gaps are an error. Neither paper
provides theory for unbalanced CCE.

{p 6 8 2}
{bf:8. Rank condition.} Assumed to hold in {cmd:xtdyncce} (JST Remark 4 defers
the deficient case). No test is performed and none is invented.


{marker validation}{...}
{title:Validation}

{pstd}
Both commands were validated against the source papers' own Monte Carlo
designs with known true parameters.

{pstd}
{bf:xtdyncce} on the JST ARX(1) design (alpha = 0.6, beta = 0.4, theta = 0.5,
two factors, N = 100, T = 50), one replication:

{p2colset 8 26 28 2}{...}
{p2col :{bf:Estimator}}{bf:alphahat}{p_end}
{p2col :CCEP (uncorrected)}0.5677{p_end}
{p2col :CCEP-AN}0.5811{p_end}
{p2col :CCEP-DVS}0.5930{p_end}
{p2col :CCEP-HPJ}0.6206{p_end}
{p2col :RD-WB + median bc}0.5882{p_end}
{p2col :RD-WB studentized + HPJ}0.6024{p_end}
{p2colreset}{...}

{pstd}
The ordering reproduces the source paper: the uncorrected estimator is biased
downward, DVS is the best analytical correction, and the recommended
combination of a bias-corrected estimator with the recursive-design bootstrap
recovers the true value. The leave-one-out jackknife standard error is about
1.8 times the clustered one, which is the gap attributable to xi(perp).

{pstd}
{bf:xtgcce} on the LSB designs, averaged over 100 replications (paper values in
brackets, bias x 10):

{p2colset 8 30 32 2}{...}
{p2col :{bf:Design}}{bf:CCE}{space 6}{bf:GCCE}{space 5}{bf:Oracle}{p_end}
{p2col :DGP 1, N=T=100 (rank holds)}0.31 [0.22]{space 1}0.11 [0.03]{space 1}0.11{p_end}
{p2col :DGP 2, N=T=50 (rank fails)}1.84{space 7}0.15{space 7}-0.03{p_end}
{p2col :DGP 2, N=T=100 (rank fails)}1.87 [2.18]{space 1}0.23 [0.06]{space 1}0.15{p_end}
{p2colreset}{...}

{pstd}
Under DGP 2 the CCE bias does not shrink as N doubles, which is inconsistency;
GCCE tracks the infeasible oracle to within Monte Carlo error. Under DGP 1 all
three agree, as the asymptotic equivalence result requires.

{pstd}
The shipped example file {cmd:xtdyngcce_example.do} reproduces these checks on
your own machine.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
See also: {helpb xtdyngcce}, {helpb xtdyncce}, {helpb xtgcce}.
