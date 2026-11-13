{smcl}
{* *! version 1.0.0  12nov2026}{...}
{vieweralsosee "indsat" "help indsat"}{...}
{vieweralsosee "indsat methods" "help indsat_methods"}{...}
{vieweralsosee "indsat postestimation" "help indsat_postestimation"}{...}
{vieweralsosee "indsat ardl" "help indsat_ardl"}{...}
{viewerjumpto "Overview" "indsat_types##overview"}{...}
{viewerjumpto "Decision table" "indsat_types##table"}{...}
{viewerjumpto "IIS" "indsat_types##iis"}{...}
{viewerjumpto "SIS" "indsat_types##sis"}{...}
{viewerjumpto "Super / ultra" "indsat_types##super"}{...}
{viewerjumpto "TIS, QIS, CIS" "indsat_types##tis"}{...}
{viewerjumpto "MIS" "indsat_types##mis"}{...}
{viewerjumpto "DIS and PIS" "indsat_types##dis"}{...}
{viewerjumpto "BIS" "indsat_types##bis"}{...}
{viewerjumpto "UIS" "indsat_types##uis"}{...}
{viewerjumpto "Algorithms" "indsat_types##alg"}{...}
{viewerjumpto "Target size" "indsat_types##alpha"}{...}
{viewerjumpto "Recipes" "indsat_types##recipes"}{...}
{title:Title}

{phang}
{bf:indsat types} {hline 2} Which indicator saturation to use, and when


{marker overview}{...}
{title:Overview}

{pstd}
Every saturation type adds a full set of candidate indicators {it:d_j(t)}, one starting at each
date {it:j}, to the model and lets general-to-specific selection keep the few that matter.
The types differ only in the {it:shape} of {it:d_j(t)}, so the choice of type is a statement about
what kind of instability you expect: a one-off blip, a permanent shift in the mean, a change
of slope, a change in a slope coefficient, or a shock with a known profile.
Choosing the shape that matches the true break gives the highest power ({it:potency}) for
the same false-detection rate ({it:gauge}); see Castle, Doornik, Hendry & Pretis (2015) and
Pretis, Schneider, Smerdon & Hendry (2016).

{pstd}
The impulse is the building block: a step is a partial sum of impulses, a broken trend is a
partial sum of steps. IIS can therefore {it:approximate} any break, but needs one indicator per
affected observation; the matching shape needs only one, which is why it is more powerful.


{marker table}{...}
{title:Decision table}

{p2colset 5 27 29 2}{...}
{p2col:{it:Expected feature}}{it:Use}{p_end}
{p2line}
{p2col:one-off outliers, strikes, holidays, data errors}{bf:iis}{p_end}
{p2col:robust estimation of {it:beta}}{bf:iis} (+ {bf:varcorr}), {bf:algorithm(split|mstep)}{p_end}
{p2col:permanent shift in the mean/level}{bf:sis}{p_end}
{p2col:shifts and outliers, unknown mix}{bf:super} (= {bf:iis sis}){p_end}
{p2col:change in the growth rate (kink)}{bf:tis}{p_end}
{p2col:level, outliers and kinks together}{bf:ultra} (= {bf:iis sis tis}){p_end}
{p2col:accelerating / curving trend after a date}{bf:qis}, {bf:cis} (small samples: caution){p_end}
{p2col:a slope coefficient changes}{bf:mis(}{it:varlist}{bf:)}{p_end}
{p2col:all coefficients change at the same date}{bf:sis mis(}{it:varlist}{bf:) common}{p_end}
{p2col:a spike that is reversed next period}{bf:dis}{p_end}
{p2col:two linked outliers {it:j} periods apart}{bf:pis(}{it:j}{bf:)}{p_end}
{p2col:a shock with a known decay shape}{bf:bis(volcanic)}, {bf:bis(tc)}, {bf:bis(ramp)}, {bf:bis(, shape())}{p_end}
{p2col:your own candidate dummies / many regressors (K > T)}{bf:uis(}{it:varlist}{bf:)}{p_end}
{p2col:plain GETS model selection, no indicators}{bf:select}{p_end}
{p2line}
{p2colreset}{...}


{marker iis}{...}
{title:IIS {hline 2} impulse indicator saturation ({bf:iis})}

{pstd}
{it:Indicator:} {it:I_j(t)} = 1 if {it:t = j}, 0 otherwise ({it:T} candidates).{break}
{it:Detects:} additive outliers in the error, one-period shocks, measurement errors, holidays,
strikes, natural disasters, policy announcements with a one-period effect.{break}
{it:Use when:} you want estimates of {it:beta} that are robust to a fraction of contaminated
observations, or you need a record of which dates are outliers. Under the null of no
outliers IIS is a 1-step Huber-skip M-estimator (Johansen & Nielsen 2009): the efficiency
loss is tiny ({bf:indsat gauge}), so IIS is cheap insurance.{break}
{it:Tests that go with it:} {bf:estat outlier} (Jiao-Pretis proportion and Poisson count),
{bf:estat distort} (does outlier removal change {it:beta}?), {bf:indsat loop} (scaling tests).{break}
{it:Caution:} a long location shift is captured by a run of impulses; if you see consecutive
impulses with similar signs, switch to {bf:sis} or {bf:super}.


{marker sis}{...}
{title:SIS {hline 2} step indicator saturation ({bf:sis})}

{pstd}
{it:Indicator:} {it:S_j(t)} = 1 if {it:t >= j} ({bf:sisform(up)}, default, as in R {it:gets}) or
{it:S_j(t)} = 1 if {it:t <= j} ({bf:sisform(down)}, Autometrics/Castle et al. 2015). The coefficient
is the size of the shift at {it:j}.{break}
{it:Detects:} location shifts (level breaks) of unknown number, size and timing:
policy-regime changes, currency pegs, tax changes, institutional reforms, measurement-method
changes, the Nile flow after 1898, the seat-belt law of 1983.{break}
{it:Use when:} the mean of the series (or the intercept of the model) may shift and stay
shifted. SIS dominates Bai-Perron-type procedures when breaks are many, of unknown number,
or close to the sample ends, and it is valid in dynamic models.{break}
{it:Tests:} {bf:estat dates} (regime table), {bf:estat test} (periods where the level differs
from a hypothesised value), {bf:estat biascorr} (post-selection bias correction).{break}
{it:Caution:} SIS has a slightly larger gauge variance than IIS (Nielsen & Qian 2025); a
smaller target size (alpha = 1/T or below) is recommended. Use {bf:sisform(down)} for
forecasting, because then no step extends into the forecast period.


{marker super}{...}
{title:Super and ultra saturation ({bf:super}, {bf:ultra})}

{pstd}
{bf:super} = {bf:iis sis}: searches impulses and steps together (Ericsson 2011; Kurle 2025).
Use it when outliers and level shifts may coexist, which is the typical case in macro,
energy and climate series, and when you do not want an outlier to be mistaken for a shift
or vice versa.{break}
{bf:ultra} = {bf:iis sis tis}: adds broken trends (Ericsson, Dore & Butt 2022). Use it for
trending series (log levels, temperatures, CO2) in which the trend may kink.{break}
{it:Caution:} more candidate sets raise the expected number of false retentions
(alpha times the number of candidates); tighten {bf:tpval()} accordingly.


{marker tis}{...}
{title:TIS, QIS, CIS {hline 2} broken trends ({bf:tis}, {bf:qis}, {bf:cis})}

{pstd}
{it:Indicator:} {it:T_j(t) = (t - j + 1) 1(t >= j)}; {bf:qis} squares and {bf:cis} cubes it.{break}
{it:Detects:} changes in the slope of a deterministic trend: growth slowdowns, productivity
breaks, the post-1970s warming trend, the inflation surge of 2021-2022 (Castle, Doornik &
Hendry 2026, who use one large forecast error to estimate a new broken trend).{break}
{it:Use when:} the series is trending and the {it:rate} of change, not the level, shifts.
Combine with {bf:sis} when both level and slope may break.{break}
{it:Caution:} broken trends are highly collinear; {bf:indsat} rescales them during the search
(t-ratios are scale invariant) and reports coefficients in original units. QIS/CIS are
extremely collinear: the default block size falls to 15 and 8; keep samples moderate.


{marker mis}{...}
{title:MIS {hline 2} multiplicative indicator saturation ({bf:mis(}{it:varlist}{bf:)})}

{pstd}
{it:Indicator:} {it:x_t S_j(t)} for each variable in {it:varlist} (which must be a regressor).{break}
{it:Detects:} breaks in slope coefficients: changes in the Taylor-rule response to inflation
(Stillwagon 2025), changes in pass-through, elasticities or betas, and, with {bf:mis(L.y)},
changes in persistence.{break}
{it:Use when:} you suspect parameter instability in a specific coefficient. It is the
saturation analogue of Bai-Perron partial structural change, but does not need the number of
breaks or trimming. {bf:estat plot} shows the estimated coefficient path with a band.{break}
{it:Option {bf:common}:} imposes the same break dates on the intercept (if {bf:sis}) and all MIS
coefficients, as OxRegimes/Autometrics "common break dates": candidate dates are those
retained separately; date blocks are removed by backward elimination on their Wald F-test.
Use it for regime-switching interpretations (e.g. Fed chairs).


{marker dis}{...}
{title:DIS and PIS {hline 2} differenced and pairwise impulses ({bf:dis}, {bf:pis(}{it:j}{bf:)})}

{pstd}
{bf:dis}: {it:Z_j = I_j - I_(j-1)} (zero-sum pair; Ericsson 2011). Detects a blip that is
offset in the next period: timing errors, purchases brought forward before a tax change,
production shifted between months, mis-dated observations. One indicator replaces two
impulses with opposite signs.{break}
{bf:pis(}{it:j}{bf:)}: {it:P_i = I_i + I_(i+j)} (Ericsson 2011). {bf:pis(1)} captures an additive
(measurement) outlier in an AR(1) model, which affects two consecutive residuals
(Johansen & Nielsen 2016, Sec. 1); {bf:pis(4)}/{bf:pis(12)} link the same quarter/month in
consecutive years.


{marker bis}{...}
{title:BIS {hline 2} designed break functions ({bf:bis(}{it:shape}{bf:)})}

{pstd}
{it:Indicator:} a pre-specified profile {it:d(1),...,d(L)} starting at each date (Pretis et al. 2016).{break}
{bf:bis(volcanic} [{bf:, gamma(}#{bf:) length(}#{bf:)}]{bf:)}: the energy-balance response to a volcanic
aerosol shock, eq. (31) of Pretis et al. (2016): a sudden drop and smooth recovery.{break}
{bf:bis(tc} [{bf:, delta(}0.7{bf:)}]{bf:)}: the TRAMO/X-13 "transitory change", {it:delta^k} (Marczak & Proietti
2016): a shock that dies out geometrically.{break}
{bf:bis(ramp} [{bf:, length(}#{bf:)}]{bf:)}: a linear recovery.{break}
{bf:bis(, shape(}{it:numlist}{bf:))}: any profile, e.g. the path of a past pandemic wave (path indicator
saturation, Castle et al. 2020).{break}
{it:Use when:} theory or experience tells you how a shock propagates; detection power is
much higher than with impulses when the profile is right.


{marker uis}{...}
{title:UIS {hline 2} user-specified indicators ({bf:uis(}{it:varlist}{bf:)})}

{pstd}
Searches over any set of candidate variables with the same block algorithm: known event
dummies of uncertain relevance, seasonal impulses, or many candidate regressors when there
are more variables than observations ({it:K > T}). Combine with {bf:select} to also select over
the model regressors.


{marker alg}{...}
{title:Which algorithm?}

{p2colset 5 27 29 2}{...}
{p2col:{bf:algorithm(gets)}}default; multi-path block search of R {it:gets} (Pretis, Reade & Sucarrat 2018);
reproduces {it:gets::isat} numerically; all indicator types.{p_end}
{p2col:{bf:algorithm(split)}}split-half IIS of Hendry, Johansen & Santos (2008) / Johansen & Nielsen (2009),
or split-half SIS of Nielsen & Qian (2025); the estimators of the asymptotic theory; fast; good as a
benchmark and for teaching.{p_end}
{p2col:{bf:algorithm(mstep)}}m-step Huber-skip (robustified least squares), Johansen & Nielsen (2016,
Alg. 1); a robust-regression view of IIS.{p_end}
{p2colreset}{...}


{marker alpha}{...}
{title:Choosing the target size (tpval)}

{pstd}
Under the null of no breaks, about {it:alpha} times the number of candidates are retained by
chance. The rule {bf:tpval(}1/T{bf:)} keeps one false indicator on average per saturating set;
{bf:tpval(0.001)} (the {it:gets} default) is conservative; Nielsen & Qian (2025) recommend a small
gauge for SIS because it reduces post-selection bias. Use {helpb indsat_gauge:indsat gauge} to see the cut-off,
the expected count and its Poisson probabilities, and {helpb indsat_loop:indsat loop} to check that results are
stable across target sizes.


{marker recipes}{...}
{title:Recipes}

{phang2}{cmd:. regress y x1 x2}{space 22}// your usual model ...{p_end}
{phang2}{cmd:. indsat, super tpval(0.01)}{space 12}// ... then saturate it{p_end}
{phang2}{cmd:. use indsat_nile, clear}{p_end}
{phang2}{cmd:. indsat flow, sis tpval(0.01)}{space 18}// level shifts (1898 dam){p_end}
{phang2}{cmd:. indsat flow, super tpval(0.01)}{space 16}// shifts + outliers{p_end}
{phang2}{cmd:. use indsat_seatbelts, clear}{p_end}
{phang2}{cmd:. indsat ldriverskilled lkms lpetrol, ar(1 12) super tpval(0.005)}{p_end}
{phang2}{cmd:. indsat ldriverskilled lkms lpetrol, ar(1) mis(lpetrol) sis common tpval(0.005)}{p_end}
{phang2}{cmd:. indsat y, ultra tpval(0.005)}{space 20}// trending series{p_end}
{phang2}{cmd:. indsat temp, bis(volcanic) tpval(0.01)}{space 9}// designed breaks{p_end}
{phang2}{cmd:. indsat fe, iis sis}{space 25}// forecast errors: forecast-bias analysis{p_end}
{phang2}{cmd:. estat bias, constant}{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
