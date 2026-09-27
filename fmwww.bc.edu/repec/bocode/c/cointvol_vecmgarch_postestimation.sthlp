{smcl}
{* *! version 0.1.0  26sep2026}{...}
{vieweralsosee "cointvol vecmgarch" "help cointvol_vecmgarch"}{...}
{vieweralsosee "cointvol" "help cointvol"}{...}
{vieweralsosee "cointvol garchrank" "help cointvol_garchrank"}{...}
{viewerjumpto "Description" "cointvol_vecmgarch_postestimation##description"}{...}
{viewerjumpto "predict" "cointvol_vecmgarch_postestimation##predict"}{...}
{viewerjumpto "estat" "cointvol_vecmgarch_postestimation##estat"}{...}
{viewerjumpto "Examples" "cointvol_vecmgarch_postestimation##examples"}{...}
{viewerjumpto "Stored results" "cointvol_vecmgarch_postestimation##results"}{...}
{viewerjumpto "Author" "cointvol_vecmgarch_postestimation##author"}{...}
{title:Title}

{phang}
{bf:cointvol vecmgarch postestimation} {hline 2} Postestimation tools for
{helpb cointvol_vecmgarch:cointvol vecmgarch}


{marker description}{...}
{title:Description}

{pstd}
After {cmd:cointvol vecmgarch} the following are available:

{synoptset 18}{...}
{synopt:{cmd:predict}}fitted values, residuals, conditional (co)variances, ECTs{p_end}
{synopt:{cmd:estat moments}}stationarity and fourth-moment conditions{p_end}
{synopt:{cmd:estat garchx}}LR, Wald and LM tests of GARCH and GARCH-X (Lee 1994){p_end}
{synopt:{cmd:estat diagonal}}Wald test of a diagonal BEKK / no spill-overs{p_end}
{synopt:{cmd:estat effgain}}Seo (2007) partial efficiency gains of the QMLE of beta{p_end}
{synopt:{cmd:estat ranklr}}LR rank tests in the VAR-GARCH (BDV 1997){p_end}
{synopt:{cmd:estat archlm}}ARCH-LM tests on the standardised residuals{p_end}
{synopt:{cmd:estat ic}, {cmd:estat vce}}standard {helpb estat} subcommands{p_end}
{synopt:{cmd:test}, {cmd:lincom}, {cmd:nlcom}}Wald inference with {cmd:e(V)} (robust by default){p_end}

{pstd}
All subcommands read the model from {cmd:e()} and rebuild the recursions from the data in
memory on the estimation window; {cmd:estat garchx} and {cmd:estat ranklr} re-estimate
restricted models and restore the results in memory afterwards.


{marker predict}{...}
{title:Syntax for predict}

{p 8 16 2}
{cmd:predict} {dtype} {newvar} {ifin} [{cmd:,} {it:statistic} {opt eq:uation(eqlist)}]

{synoptset 18 tabbed}{...}
{synopthdr:statistic}
{synoptline}
{synopt:{opt xb}}fitted dX_i (default){p_end}
{synopt:{opt r:esiduals}}residual e_i{p_end}
{synopt:{opt stdr:esid}}e_i / sqrt(h_ii){p_end}
{synopt:{opt v:ariance}}conditional variance h_ii,t{p_end}
{synopt:{opt sd}}conditional standard deviation sqrt(h_ii,t){p_end}
{synopt:{opt cov:ariance}}conditional covariance h_ij,t; {cmd:equation(}i j{cmd:)}{p_end}
{synopt:{opt corr:elation}}conditional correlation; {cmd:equation(}i j{cmd:)}{p_end}
{synopt:{opt ect}}error-correction term beta_j#'Z1_t; {cmd:equation(}j{cmd:)}{p_end}
{synopt:{opt logl:ik}}log-likelihood contribution l_t{p_end}
{synoptline}
{p 4 6 2}
{opt equation()} takes equation numbers ({cmd:#1} or {cmd:1}), variable names, or {cmd:D_}{it:name};
default equation 1 (equations 1 2 for covariance and correlation). Predictions are produced for
observations in {cmd:e(sample)} only, because the variance recursion runs over the whole sample.
The sum of {cmd:loglik} equals {cmd:e(ll)}.


{marker estat}{...}
{title:Syntax for estat}

{p 8 16 2}{cmd:estat moments}{p_end}
{p 8 16 2}{cmd:estat garchx}{p_end}
{p 8 16 2}{cmd:estat diagonal}{p_end}
{p 8 16 2}{cmd:estat effgain}{p_end}
{p 8 16 2}{cmd:estat ranklr} [{cmd:,} {opt l:evel(#)}]{p_end}
{p 8 16 2}{cmd:estat archlm} [{cmd:,} {opt l:ags(numlist)}]{p_end}

{dlgtab:estat moments}

{pstd}
Covariance stationarity: for {cmd:dbekk}/{cmd:bekk} the moduli of the eigenvalues of
sum A_i#A_i + sum G_j#G_j must be below 1 (BDV 1997, eq. 8; Engle & Kroner 1995, Prop. 2.7);
{cmd:ecccgarch}: eigenvalues of A + B; univariate-type models: the sum of the ARCH and GARCH
coefficients per equation. Fourth moments of the own-variance GARCH recursion: spectral radius
of E(A_t # A_t) for the GARCH companion matrix with E eta{c 94}4 = kappa, which for GARCH(1,1)
equals kappa a{c 94}2 + 2ab + b{c 94}2 (Bollerslev 1986; Sin, Mi & Ling 2024, Ass. 2.4), reported for
kappa = 3 and for the sample kurtosis of the standardised residuals. For {cmd:dbekk} the own
coefficients are a_i{c 94}2 and b_i{c 94}2. The implied unconditional covariance (when it exists) is
compared with the residual covariance. {it:Original}: BDV (1997); Bollerslev (1986).

{dlgtab:estat garchx}

{pstd}
Lee (1994) Tables 1 and 3. Model 1 = homoskedastic ECM ({cmd:e(ll_0)}), Model 2 = ECM with the
GARCH model, Model 3 = ECM with GARCH-X. If the model in memory has {opt garchx()}, Model 2 is
re-estimated without the X term; LR(2 vs 1) has df = number of dynamic variance parameters
(4 for a bivariate diagonal BEKK) and LR(3 vs 2) df = number of D elements (3 when p = 2), and
the robust Wald test of D = 0 uses {cmd:e(V)}. The LM test regresses e_it{c 94}2 - h_ii,t on
z{c 94}2_(t-1) (no constant), T R{c 94}2 uncentred ~ chi2(1), with h_ii from the model without X
("GARCH[1,1]-X") and from a constant variance ("ARCH[0]-X"). {bf:Caveats}: LR and LM rely on
normality (Lee 1994, fn 3); with the D'D form the score is zero at D = 0 and the information
matrix is singular, so tests of D = 0 are non-standard (typically conservative LR). Requires
error-correction terms. {it:Original}: Lee (1994).

{dlgtab:estat diagonal}

{pstd}
Robust Wald tests that the off-diagonal elements of all A_i, of all G_j, and of both are zero
({cmd:bekk}; BDV 1997, Table 5), or that the ARCH matrix A has no spill-overs
({cmd:ecccgarch}; {it:Extended implementation}).

{dlgtab:estat effgain}

{pstd}
Seo (2007, eq. 21) partial efficiency gains g_j = [s_j + (kappa_j - 1)H_j] / [s_j + 2H_j]{c 94}2
with s_j = E(s2_jt) E(1/s2_jt), H_j = sum_k h_jk{c 94}2 E(s2bar_j e{c 94}2_(j,t-k)/s2_jt{c 94}2), h_jk the
MA(infinity) coefficients of the variance in lagged squared errors (psi phi{c 94}(k-1) for
GARCH(1,1)) and kappa_j the kurtosis of the standardised error; expectations are sample means.
g_j < 1 means the joint QMLE of beta beats Johansen RRR. Exact for {cmd:trigarch}
({it:Original}); applied to the own-variance recursion for {cmd:cccgarch}, {cmd:darch},
{cmd:dbekk} ({it:Extended implementation}, approximate).

{dlgtab:estat ranklr}

{pstd}
Re-estimates the VAR-GARCH at ranks r = 0,...,p (same variance model, lags and trend) and
reports LR(r|p) = 2[logL(p) - logL(r)] with p-values and 5% critical values from the asymptotic
Johansen trace distribution of the chosen deterministic case. Following BDV (1997, Sec. 4.2)
this validity is {bf:conjectured}, not proved; Sin, Mi & Ling (2024) show the limit is in
general non-standard - see {helpb cointvol_garchrank:cointvol garchrank}. {opt garchx(ect)} is
dropped in the refits. This subcommand fits p+1 models and can be slow.

{dlgtab:estat archlm}

{pstd}
Engle's LM test: n R{c 94}2 from the regression of z{c 94}2_it on a constant and q of its lags,
z_it = e_it/sqrt(h_ii,t) (for {cmd:trigarch} the orthogonalised errors); {opt lags()} default
1 5 10 (as in Lee 1994 and WLL 2005, Table 11).


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. cointvol vecmgarch x1 x2, lags(2) rank(1) variance(dbekk) garchx(ect)}{p_end}
{phang2}{cmd:. predict double h1, variance equation(1)}{p_end}
{phang2}{cmd:. predict double rho12, correlation equation(1 2)}{p_end}
{phang2}{cmd:. predict double z, ect}{p_end}
{phang2}{cmd:. estat moments}{p_end}
{phang2}{cmd:. estat garchx}{p_end}
{phang2}{cmd:. estat archlm, lags(1 5)}{p_end}
{phang2}{cmd:. test [_ce1]x2 = -1}{p_end}
{phang2}{cmd:. cointvol vecmgarch x1 x2, lags(2) rank(1) variance(trigarch)}{p_end}
{phang2}{cmd:. estat effgain}{p_end}
{phang2}{cmd:. estat ranklr}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:estat moments}: {cmd:r(rho)}, {cmd:r(eig)}, {cmd:r(moments)}, {cmd:r(Sigma_u)},
{cmd:r(Sigma_e)}, {cmd:r(kappa)}.{p_end}
{pstd}{cmd:estat garchx}: {cmd:r(ll_1)}, {cmd:r(ll_2)}, {cmd:r(ll_3)}, {cmd:r(lr21)}, {cmd:r(df21)},
{cmd:r(p21)}, {cmd:r(lr32)}, {cmd:r(df32)}, {cmd:r(p32)}, {cmd:r(wald)}, {cmd:r(wald_df)},
{cmd:r(wald_p)}, {cmd:r(lm)}.{p_end}
{pstd}{cmd:estat diagonal}: {cmd:r(chi2)}, {cmd:r(df)}, {cmd:r(p)} (and {cmd:_A}, {cmd:_G} versions).{p_end}
{pstd}{cmd:estat effgain}: {cmd:r(effgain)}.{p_end}
{pstd}{cmd:estat ranklr}: {cmd:r(ranklr)}, {cmd:r(rank_sel)}.{p_end}
{pstd}{cmd:estat archlm}: {cmd:r(archlm)}.{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
{p_end}
