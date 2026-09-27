{smcl}
{* *! version 0.1.0  26sep2026}{...}
{vieweralsosee "cointvol" "help cointvol"}{...}
{vieweralsosee "cointvol rank" "help cointvol_rank"}{...}
{vieweralsosee "cointvol adaptive" "help cointvol_adaptive"}{...}
{vieweralsosee "[TS] varsoc" "help varsoc"}{...}
{viewerjumpto "Syntax" "cointvol_select##syntax"}{...}
{viewerjumpto "Description" "cointvol_select##description"}{...}
{viewerjumpto "Options" "cointvol_select##options"}{...}
{viewerjumpto "Methods and formulas" "cointvol_select##methods"}{...}
{viewerjumpto "Remarks" "cointvol_select##remarks"}{...}
{viewerjumpto "Examples" "cointvol_select##examples"}{...}
{viewerjumpto "Stored results" "cointvol_select##results"}{...}
{viewerjumpto "References" "cointvol_select##references"}{...}
{viewerjumpto "Author" "cointvol_select##author"}{...}
{title:Title}

{p2colset 5 25 27 2}{...}
{p2col:{bf:cointvol select} {hline 2}}Joint or sequential selection of the VAR lag order and the
cointegration rank in heteroskedastic VAR models, standard or adaptive{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:cointvol select} {varlist} {ifin}{cmd:,} {opt max:lag(#)} [{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{p2coldent:* {opt max:lag(#)}}maximum lag order K of the VAR in levels{p_end}
{synopt:{opt tr:end(dcase)}}{cmd:none}, {cmd:rconstant} (default), {cmd:rtrend};
extended: {cmd:constant}, {cmd:trend}{p_end}

{syntab:Selection}
{synopt:{opt ic(list)}}criteria: any of {cmd:bic}, {cmd:hqc}, {cmd:aic}; default all three{p_end}
{synopt:{opt proc:edure(type)}}{cmd:joint} or {cmd:sequential}; default {cmd:joint} with
{cmd:rank(ic)}, else {cmd:sequential}{p_end}
{synopt:{opt rank(method)}}rank step of the sequential procedure: {cmd:ic} (default),
{cmd:cp}, {cmd:plr}, {cmd:iid}, {cmd:wild}; with {opt adaptive}: {cmd:ic}, {cmd:cp},
{cmd:wild}, {cmd:vbs}{p_end}

{syntab:Adaptive (BCDT 2023)}
{synopt:{opt adap:tive}}use the adaptive information criteria ALS-IC with kernel volatility{p_end}
{synopt:{opt bw(cv|#)}}bandwidth as a fraction of the sample; default {cmd:cv}{p_end}
{synopt:{opt ker:nel(gauss)}}Gaussian kernel (only choice){p_end}

{syntab:Bootstrap}
{synopt:{opt r:eps(#)}}replications for {cmd:rank(iid|wild|vbs)}; default {cmd:399}{p_end}
{synopt:{opt seed(string)}}random-number seed{p_end}
{synopt:{opt mult:iplier(type)}}wild-bootstrap multipliers {cmd:gauss} (default),
{cmd:rademacher}, {cmd:mammen} (non-adaptive only){p_end}
{synopt:{opt nodots}}suppress the replication dots{p_end}

{syntab:Other}
{synopt:{opt l:evel(#)}}level of the sequential tests; default {cmd:c(level)}{p_end}
{synopt:{opt tol:erance(#)}}switching-algorithm tolerance (adaptive); default 1e-7{p_end}
{synopt:{opt iter:ate(#)}}switching-algorithm iteration cap (adaptive); default 1000{p_end}
{synoptline}
{p 4 6 2}* {opt maxlag()} is required. The data must be {helpb tsset} (not a panel) with no
gaps.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:cointvol select} determines the lag order k and the cointegration rank r of a VAR in
levels, allowing for conditional and nonstationary (unconditional) heteroskedasticity.

{pstd}
{it:Standard criteria} (Cavaliere, De Angelis, Rahbek and Taylor 2018, CDRT): the Gaussian
information criteria IC(k,r) are computed on a grid k = 1,...,K, r = 0,...,p. The joint
procedure chooses the grid minimum; the sequential procedure first chooses k from the
unrestricted VAR and then chooses r by the same criterion, by Cheng-Phillips IC(1,r), or by the
Johansen trace test sequence with the estimated lag (asymptotic, iid bootstrap, or wild
bootstrap, CDRT Algorithm 1). BIC and HQC are consistent for (k0, r0) under heteroskedasticity
of both types; AIC is not. CDRT recommend the wild-bootstrap sequence with the BIC lag and the
joint BIC.

{pstd}
{it:Adaptive criteria} ({opt adaptive}; Boswijk, Cavaliere, De Angelis and Taylor 2023, BCDT):
the Gaussian likelihood is evaluated with a kernel estimate Sigma_t of the time-varying
covariance matrix (from the VAR(K) residuals), maximised by generalized reduced-rank regression.
Under nonstationary volatility these ALS-IC select the lag and rank more often correctly; the
rank step can also use the adaptive PLR bootstrap test (volatility or wild bootstrap).

{pstd}
The output shows the IC(k,r) grid of each criterion with its minimum, a summary of the selected
(k, r) by each procedure, and, when requested, the sequential rank-test tables.


{marker options}{...}
{title:Options}

{phang}
{opt maxlag(#)} maximum lag order K >= 1 of the VAR in levels. All models are estimated on the
common sample t = K+1,...,T. Original: CDRT (2018) eq. (3.7).

{phang}
{opt trend(dcase)}: {cmd:none} (case i), {cmd:rconstant} (case ii, default), {cmd:rtrend}
(case iii: restricted trend plus unrestricted constant) are the cases of CDRT and BCDT.
{cmd:constant} (unrestricted constant) and {cmd:trend} (unrestricted trend) are Extended
implementation: the parameter count adds p (resp. 2p) unrestricted deterministic coefficients.

{phang}
{opt ic(list)}: penalties c_T = 2 (AIC), log T (BIC), 2 log log T (HQC), T the effective sample.
Original: CDRT eqs. (3.4)-(3.6); BCDT Sec. 3.

{phang}
{opt procedure(type)}: {cmd:joint} = argmin over (k, r) (CDRT eq. 3.7; BCDT eq. 3.4);
{cmd:sequential} = k-hat = argmin_k IC(k,p) (CDRT eqs. 3.10-3.11; BCDT eq. 3.5), then the rank
by {opt rank()}. Both sets of results are always computed and displayed; {opt procedure()}
decides which pair is returned in r(k_{it:ic}) and r(r_{it:ic}).

{phang}
{opt rank(method)}: {cmd:ic} r-hat = argmin_r IC(k-hat, r) (CDRT eqs. 3.12-3.13; BCDT eq. 3.9);
{cmd:cp} r-hat = argmin_r IC(1, r) (Cheng and Phillips; CDRT eq. 3.14);
{cmd:plr} Johansen trace sequence with k-hat and asymptotic p-values (CDRT eq. 3.15);
{cmd:iid} / {cmd:wild} the same with the iid / wild bootstrap of CDRT Algorithm 1;
with {opt adaptive}, {cmd:vbs} / {cmd:wild} the adaptive PLR sequence with volatility / wild
bootstrap (BCDT eqs. 3.6-3.8). The test sequence stops at the first r whose p-value exceeds
1-level/100. When the criteria select different k-hat, the tests are run for each k-hat.

{phang}
{opt adaptive} uses ALS-IC (BCDT). {opt bw(cv|#)} sets the kernel bandwidth h as a fraction of
the sample (h_obs = T h observations); {cmd:cv} = leave-one-out cross-validation (Boswijk and Zu
2022, eq. 20). {opt kernel(gauss)}: Gaussian kernel (the kernel is not specified in BCDT; the
Gaussian kernel of Boswijk and Zu 2022 is used).

{phang}
{opt reps(#)} bootstrap replications (default 399 as in CDRT); {opt seed()} seed;
{opt multiplier()} wild-bootstrap multipliers (CDRT use Gaussian); {opt nodots}.

{phang}
{opt level(#)} significance level of the sequential tests (1-level/100).

{phang}
{opt tolerance(#)}, {opt iterate(#)} control the switching algorithm used by ALS-IC.


{marker methods}{...}
{title:Methods and formulas}

{pstd}
{bf:Model} (CDRT eq. 2.1): dX_t = alpha beta' X(t-1) + sum(i=1..k-1) Gamma_i dX(t-i)
+ alpha rho' D_t + phi d_t + e_t, with e_t = sigma_t z_t, sigma_t = sigma(t/T) and
conditionally heteroskedastic z_t (CDRT Assumption H). Cases: (i) no deterministics,
(ii) D_t = 1, (iii) D_t = t, d_t = 1.

{pstd}
{bf:Standard IC} (CDRT eq. 3.3). For each k the reduced-rank regression on the common sample
gives |S00(k)| and eigenvalues lambda_1(k) > ... and

{p 8 8 2}
IC(k,r) = T log|S00(k)| + T sum(i<=r) log(1 - lambda_i(k)) + c_T pi(k,r),

{p 8 8 2}
pi(k,r) = r(2p - r + n1) + p n2 + p(p+1)/2 + p{c 94}2 (k-1),

{pstd}
with n1 (n2) the number of restricted (unrestricted) deterministic terms: case (i)
r(2p-r) + p(p+1)/2 + p{c 94}2(k-1); case (ii) adds r; case (iii) adds r + p. At r = p this
is IC(k,p) = T log|Sigma(k,p)| + c_T [p(pk+i) + p(p+1)/2], i = 0, 1, 2 (CDRT eq. 3.10).

{pstd}
{bf:Adaptive IC} (BCDT eqs. 3.1-3.5). e_t: OLS residuals of the unrestricted VAR(K) (with the
model's deterministics) on the common sample; Sigma_t = Gaussian-kernel smoother of e_s e_s'
(BCDT eq. 3.3); h by leave-one-out CV. Then

{p 8 8 2}
ALS-IC(k,r) = sum_t log|Sigma_t| + sum_t e_(k,r),t' Sigma_t{c 94}(-1) e_(k,r),t + c_T pi_A(k,r),
{space 2}pi_A(k,r) = pi(k,r) - p(p+1)/2,

{pstd}
where e_(k,r),t are the residuals of the rank-r model with k lags estimated by GLS (r = p),
by the GRRR switching algorithm (0 < r < p), or by GLS on the short-run terms only (r = 0).
The same Sigma_t is used for every (k, r); the constant T p log(2 pi) is omitted.

{pstd}
{bf:Joint} (CDRT eq. 3.7): (k~, r~) = argmin over k = 1..K and r = 0..p.
{bf:Sequential}: k-hat = argmin_k IC(k,p) (eq. 3.11); r-hat = argmin_r IC(k-hat, r)
(eq. 3.13), or IC(1,r) (eq. 3.14), or a test sequence.

{pstd}
{bf:Bootstrap PLR with k-hat} (CDRT Algorithm 1): for r = 0,1,...: (i) estimate the rank-r
model with k-hat lags by reduced-rank regression (all parameters restricted); (ii) recentre the
residuals and generate X*_t recursively from the restricted estimates, deterministics included,
initialised at the data, with e*_t = resampled residuals (iid) or residuals times w_t (wild);
(iii) p* = B{c 94}(-1) sum 1(Q* > Q) with Q the trace statistic at k-hat; (iv) stop at the first
r with p* > 1-level/100. Explosive roots of the bootstrap DGP are ignored (Cavaliere, Taylor and
Trenkler 2015).

{pstd}
{bf:Adaptive PLR bootstrap with k-hat} (BCDT eqs. 3.6-3.8): statistic ALR(r) =
sum_t (e~' Sigma_t{c 94}(-1) e~ - e{c 94}' Sigma_t{c 94}(-1) e{c 94}) (Boswijk and Zu 2022 eq. 13);
the bootstrap DGP uses the conventional (Johansen) rank-r estimates (BCDT eq. 3.7) with
e*_t = Sigma_t{c 94}(1/2) z_t (volatility bootstrap) or e*_t = e~_(r),t w_t (wild bootstrap,
restricted residuals); Sigma_t is not re-estimated.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Original versus extended.} Original (CDRT 2018): standard IC, joint and sequential
procedures, IC(1,r), trace sequences with k-hat and iid / wild bootstrap. Original (BCDT
2023): ALS-IC, joint and sequential, adaptive PLR with VB / WB. Extended implementation:
cases {cmd:constant} and {cmd:trend}; non-Gaussian multipliers; the Cheng-Phillips rank in
the adaptive case.

{pstd}
{bf:Corrections and choices.} (1) CDRT print the case (iii) count with p(p+2)/2; consistency
with their eq. (3.10) (i = 2 at r = p) and BCDT fn. 1 requires r(2p-r+1) + p + p(p+1)/2 +
p{c 94}2(k-1), which is used. The difference is constant in (k, r) and changes no selection.
(2) BCDT print eq. (3.9) with pi(k-hat, p) and argmin over ALS-IC(k-hat, p); the forced reading
(k-hat, r) is used. (3) All (k, r) are evaluated on the common sample t = K+1..T, as required
for comparable likelihoods (implicit in CDRT/BCDT, whose DGPs start at t = 1-K). (4) BCDT do
not state the kernel, the deterministics of the auxiliary VAR(K) or whether residuals are
recentred for the adaptive wild bootstrap; the Gaussian kernel, the model's deterministic
terms and non-recentred restricted residuals are used.

{pstd}
{bf:Recommendations} (CDRT Sec. 5-6; BCDT Sec. 5). Use BIC or HQC; BIC may under-fit k when the
short-run dynamics are weak, HQC may over-fit r. The wild-bootstrap sequence with the BIC lag
is robust in small samples; joint BIC is a good complement. Under volatility shifts, the
adaptive criteria (ALS-BIC, ALS-HQC) and the adaptive PLR bootstrap improve the frequency of
correct selection.

{pstd}
{bf:Stationary covariance.} ALS-IC assumes no conditional heteroskedasticity is modelled; with
purely conditional heteroskedasticity it remains consistent but offers no gain (BCDT Remark 2).


{marker examples}{...}
{title:Examples}

{pstd}Simulated trivariate VAR(2) with one cointegrating vector and a variance break{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 300}{p_end}
{phang2}{cmd:. set seed 7}{p_end}
{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. gen s = cond(t > 200, 3, 1)}{p_end}
{phang2}{cmd:. gen y2 = sum(s*rnormal())}{p_end}
{phang2}{cmd:. gen y3 = sum(s*rnormal())}{p_end}
{phang2}{cmd:. gen y1 = y2 - y3 + s*rnormal()}{p_end}

{pstd}Joint selection by BIC, HQC and AIC{p_end}
{phang2}{cmd:. cointvol select y1 y2 y3, maxlag(4)}{p_end}

{pstd}Sequential: BIC lag, wild-bootstrap trace sequence (CDRT recommendation){p_end}
{phang2}{cmd:. cointvol select y1 y2 y3, maxlag(4) ic(bic) rank(wild) reps(399) seed(1)}{p_end}

{pstd}Adaptive joint criteria{p_end}
{phang2}{cmd:. cointvol select y1 y2 y3, maxlag(4) ic(bic hqc) adaptive}{p_end}

{pstd}Adaptive sequential with the volatility-bootstrap ALR sequence{p_end}
{phang2}{cmd:. cointvol select y1 y2 y3, maxlag(4) ic(bic) adaptive rank(vbs)}{break}
{cmd:reps(199) seed(2)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:cointvol select} stores the following in {cmd:r()} ({it:ic} = bic, hqc, aic as
requested):

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}common effective sample T{p_end}
{synopt:{cmd:r(p)}}number of variables{p_end}
{synopt:{cmd:r(maxlag)}}K{p_end}
{synopt:{cmd:r(level)}}level{p_end}
{synopt:{cmd:r(reps)}}replications (bootstrap rank step){p_end}
{synopt:{cmd:r(h)}, {cmd:r(h_obs)}}bandwidth (fraction, observations) (adaptive){p_end}
{synopt:{cmd:r(cvcrit)}}cross-validation criterion (adaptive){p_end}
{synopt:{cmd:r(k_}{it:ic}{cmd:)}, {cmd:r(r_}{it:ic}{cmd:)}}selected pair for the chosen
procedure and rank method{p_end}
{synopt:{cmd:r(k_joint_}{it:ic}{cmd:)}, {cmd:r(r_joint_}{it:ic}{cmd:)}}joint selection{p_end}
{synopt:{cmd:r(k_seq_}{it:ic}{cmd:)}}sequential lag k-hat{p_end}
{synopt:{cmd:r(r_ic_}{it:ic}{cmd:)}}argmin_r IC(k-hat, r){p_end}
{synopt:{cmd:r(r_cp_}{it:ic}{cmd:)}}argmin_r IC(1, r){p_end}
{synopt:{cmd:r(r_test_}{it:ic}{cmd:)}}rank from the test sequence at k-hat{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:cointvol select}{p_end}
{synopt:{cmd:r(varlist)}, {cmd:r(trend)}, {cmd:r(ic)}}variables, deterministics, criteria{p_end}
{synopt:{cmd:r(procedure)}, {cmd:r(rank)}}procedure and rank method{p_end}
{synopt:{cmd:r(adaptive)}, {cmd:r(bw)}, {cmd:r(kernel)}}adaptive settings{p_end}
{synopt:{cmd:r(multiplier)}, {cmd:r(seed)}}bootstrap settings{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:r(IC_}{it:ic}{cmd:)}}K x (p+1) criterion grid (rows k1.., columns r0..){p_end}
{synopt:{cmd:r(select)}}rows = criteria; columns c_T k_joint r_joint k_seq r_ic r_cp r_test{p_end}
{synopt:{cmd:r(tests)}}test sequences: r, then statistic and p-value for each distinct
k-hat{p_end}


{marker references}{...}
{title:References}

{phang}
Cavaliere, G., L. De Angelis, A. Rahbek, and A. M. R. Taylor. 2018. Determining the
cointegration rank in heteroskedastic VAR models of unknown order. {it:Econometric Theory}
34(2): 349-382.
{browse "https://doi.org/10.1017/S0266466616000335":doi:10.1017/S0266466616000335}.

{phang}
Boswijk, H. P., G. Cavaliere, L. De Angelis, and A. M. R. Taylor. 2023. Adaptive
information-based methods for determining the co-integration rank in heteroskedastic VAR
models. {it:Econometric Reviews} 42(9-10): 725-757.
{browse "https://doi.org/10.1080/07474938.2023.2222633":doi:10.1080/07474938.2023.2222633}.
Working paper: arXiv:2202.02532.

{phang}
Boswijk, H. P., and Y. Zu. 2022. Adaptive testing for cointegration with nonstationary
volatility. {it:Journal of Business & Economic Statistics} 40(2): 744-755.
{browse "https://doi.org/10.1080/07350015.2020.1867558":doi:10.1080/07350015.2020.1867558}.

{phang}
Cavaliere, G., A. Rahbek, and A. M. R. Taylor. 2012. Bootstrap determination of the
co-integration rank in vector autoregressive models. {it:Econometrica} 80(4): 1721-1740.
{browse "https://doi.org/10.3982/ECTA9099":doi:10.3982/ECTA9099}.

{phang}
Cavaliere, G., A. Rahbek, and A. M. R. Taylor. 2014. Bootstrap determination of the
co-integration rank in heteroskedastic VAR models. {it:Econometric Reviews} 33(5-6): 606-650.
{browse "https://doi.org/10.1080/07474938.2013.825175":doi:10.1080/07474938.2013.825175}.

{phang}
Cavaliere, G., A. M. R. Taylor, and C. Trenkler. 2015. Bootstrap co-integration rank testing:
the effect of bias-correcting parameter estimates. {it:Oxford Bulletin of Economics and
Statistics} 77(5): 740-759.
{browse "https://doi.org/10.1111/obes.12090":doi:10.1111/obes.12090}.

{phang}
Cheng, X., and P. C. B. Phillips. 2009. Semiparametric cointegrating rank selection.
{it:Econometrics Journal} 12: S83-S104.
{browse "https://doi.org/10.1111/j.1368-423X.2008.00270.x":doi:10.1111/j.1368-423X.2008.00270.x}.

{phang}
Phillips, P. C. B., and J. W. McFarland. 1997. Forward exchange market unbiasedness: the case
of the Australian dollar since 1984. {it:Journal of International Money and Finance} 16(6):
885-907.
{browse "https://doi.org/10.1016/S0261-5606(97)00011-9":doi:10.1016/S0261-5606(97)00011-9}.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
See also: {helpb cointvol}, {helpb cointvol_rank:cointvol rank},
{helpb cointvol_adaptive:cointvol adaptive}.
{p_end}
