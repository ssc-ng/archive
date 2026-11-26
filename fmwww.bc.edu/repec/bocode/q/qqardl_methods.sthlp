{smcl}
{* *! version 1.1.0  25nov2026}{...}
{vieweralsosee "qqardl" "help qqardl"}{...}
{viewerjumpto "Step map" "qqardl_methods##map"}{...}
{viewerjumpto "Quantile series" "qqardl_methods##qser"}{...}
{viewerjumpto "ARDL step" "qqardl_methods##ardl"}{...}
{viewerjumpto "Non-uniqueness" "qqardl_methods##nonunique"}{...}
{viewerjumpto "Validation" "qqardl_methods##validation"}{...}
{viewerjumpto "Choices" "qqardl_methods##choices"}{...}
{title:Title}

{p2colset 5 22 24 2}{...}
{p2col:{bf:qqardl methods} {hline 2}}Methods and formulas for {helpb qqardl}{p_end}
{p2colreset}{...}


{marker map}{...}
{title:Step -> equation map (Destek et al. 2025 numbering)}

{p2colset 5 12 14 2}{...}
{p2col:S1}Quantile series of y at tau and of x at theta {hline 1} Li (2022);
R {bf:qfa}: {cmd:qdft()}, {cmd:tqr.fit()}, {cmd:qdft2qser()}{p_end}
{p2col:S2}Bounds-test regression and F test of g1 = g2 = 0 {hline 1} Eqs. (1)-(3);
Pesaran, Shin and Smith (2001); p-values of Kripfganz and Schneider (2020);
cointegration if p < 0.10 (p. 4){p_end}
{p2col:S3}Error-correction form, lags fixed at 1 {hline 1} Eq. (4); Jordan and
Philips (2018){p_end}
{p2col:S4}ECT d0 and short run d1 for all pairs; long run for cointegrated pairs
{hline 1} p. 4 and Figs. 6-8{p_end}
{p2col:S5}Grid of (tau, theta) pairs {hline 1} Eq. (5) and footnote 1: 0.05, 0.10,
0.20, ..., 0.90, 0.95{p_end}
{p2colreset}{...}


{marker qser}{...}
{title:S1. The quantile series (QSER)}

{pstd}
Let y(1), ..., y(n) be the series.  For each Fourier frequency f(k) = k/n,
k = 1, ..., floor(n/2), and each quantile level tau, the trigonometric quantile
regression

{p 8 8 2}
Q_tau(y(t)) = c0 + c1(k) cos(2 pi f(k) t) + c2(k) sin(2 pi f(k) t),  t = 1, ..., n

{pstd}
is estimated (only the cosine term at f = 0.5).  The quantile discrete Fourier
transform (QDFT) is n q_tau at frequency 0, where q_tau is the sample quantile
(R type 7), (n/2)(c1 - i c2) at the frequencies below 0.5, n c1 at f = 0.5, and the
complex conjugates at the mirrored frequencies.  The quantile series is the real
part of the inverse discrete Fourier transform divided by n.  Written in real form,
with s = t - 1,

{p 8 8 2}
QSER_tau(t) = q_tau + sum_k [ c1(k) cos(2 pi k s/n) + c2(k) sin(2 pi k s/n) ]
+ c1(n/2) (-1){c 94}s  (last term for even n only),

{pstd}
which is what {cmd:qqardl} computes.  This reproduces, operation by operation,
{cmd:qfa::qser(y, tau)}.  Each quantile regression is solved by the Frisch-Newton
interior-point algorithm (Koenker and Ng 2005), a Mata port of {bf:quantreg}'s
{cmd:rq.fit.fnb}.


{marker ardl}{...}
{title:S2-S4. Bounds test and error-correction form on the quantile series}

{pstd}
With Y = QSER of y at tau and X = QSER of x at theta, the bounds test uses Eq. (1),

{p 8 8 2}
D.Y(t) = c + sum_{i=1..a} w(i) D.Y(t-i) + sum_{j=1..b} v(j) D.X(t-j)
+ g1 Y(t-1) + g2 X(t-1) + e(t),   a = b = 1 by default ({opt btlags()}),

{pstd}
estimated by OLS over t = max(a,b)+2, ..., n.  The statistic is the Wald F test of
g1 = g2 = 0 with the classical variance; p-values come from
{cmd:ardlbounds, case(3) k(1) n(N) sr(a+b)}, upper I(1) bound.  A pair is
cointegrated when p < 0.10 (equivalently F above the 10% I(1) critical value).

{pstd}
The coefficients come from the error-correction form, Eq. (4),

{p 8 8 2}
D.Y(t) = a0 + d0 Y(t-1) + d1 D.X(t) + b1 X(t-1) + e(t)

{pstd}
(with {opt lags(p q)}: p-1 lagged differences of Y and q differences of X,
D.X(t) ... D.X(t-q+1)).  ECT = d0, short run = d1, long run = -b1/d0 with
delta-method variance g'Vg, g = (b1/d0{c 94}2, -1/d0); {opt lrtype(beta)} reports b1
itself.  Destek et al. (2025) describe b1 as "the long-run coefficient" but
interpret the reported values as elasticities, which is the multiplier -b1/d0;
both are available.  {opt btest(ecm)} computes the bounds test from Eq. (4)
instead, with sr((p-1)+q).


{marker nonunique}{...}
{title:Non-unique trigonometric quantile regressions}

{pstd}
When n is composite, some frequencies k have regressors cos(2 pi k t/n),
sin(2 pi k t/n) taking only a few distinct values (e.g. k = n/4 gives 0 and +-1;
the Nyquist frequency gives +-1).  The quantile-regression linear program then has
a whole interval of optimal solutions.  R's {bf:quantreg} ("br" simplex), used by
{bf:qfa}, returns an arbitrary vertex of that set (sometimes the k-th and sometimes
the (k+1)-th order statistic); the interior-point solver used here returns its
centre.  Both are exact minimisers of the same objective; for odd prime n the
problem does not arise and the series coincide with R.


{marker validation}{...}
{title:Validation (files in the validation folder of the package source)}

{p2colset 5 40 42 2}{...}
{p2col:Frisch-Newton vs Stata {cmd:qreg}}max coefficient difference 1e-10{p_end}
{p2col:QSER vs R {cmd:qfa::qser}, n = 101}max difference 1.8e-6{p_end}
{p2col:QSER regressions, n = 120 (300 fits)}same check loss as {cmd:qreg} (gap 6e-8);
37 fits non-unique{p_end}
{p2col:Eq. (1) vs {cmd:regress} + {cmd:test}}F identical (1e-13); p-values identical
to {cmd:ardlbounds}{p_end}
{p2col:Eq. (4) vs {cmd:regress} and {cmd:ardl, ec}}ECT, SR, LR identical (1e-15){p_end}
{p2colreset}{...}


{marker choices}{...}
{title:Choices where the published description is silent}

{phang}1. Both regressions are estimated by OLS on the quantile series (Destek et al.
2025, p. 3: "runs the ARDL(1,1) model on these estimated quantile series").{p_end}
{phang}2. The long run is reported as the multiplier -b1/d0 by default; see
{opt lrtype()}.{p_end}
{phang}3. Bounds-test p-values: Kripfganz and Schneider (2020) finite-sample
response surfaces, the closest available implementation of "p < 0.1 or
F > I(1) 10% critical value".{p_end}
{phang}4. The authors' R code is not public; when available it will be used as a
numerical cross-check.{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
{p_end}
