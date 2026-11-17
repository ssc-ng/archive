{smcl}
{* *! version 2.0.0  15nov2026}{...}
{vieweralsosee "[R] regress" "help regress"}{...}
{vieweralsosee "[TS] newey" "help newey"}{...}
{vieweralsosee "[XT] xtreg" "help xtreg"}{...}
{viewerjumpto "Syntax" "cgemod##syntax"}{...}
{viewerjumpto "Description" "cgemod##description"}{...}
{viewerjumpto "SAM layout" "cgemod##sam"}{...}
{viewerjumpto "SAM workflow" "cgemod##samtools"}{...}
{viewerjumpto "The model" "cgemod##model"}{...}
{viewerjumpto "Shocks" "cgemod##shocks"}{...}
{viewerjumpto "Options" "cgemod##options"}{...}
{viewerjumpto "Scenario manager" "cgemod##scenario"}{...}
{viewerjumpto "Model diagnostics" "cgemod##check"}{...}
{viewerjumpto "Validation suite" "cgemod##validate"}{...}
{viewerjumpto "Elasticity estimation" "cgemod##elast"}{...}
{viewerjumpto "Stored results" "cgemod##results"}{...}
{viewerjumpto "Examples" "cgemod##examples"}{...}
{viewerjumpto "References" "cgemod##references"}{...}
{title:Title}

{phang}
{bf:cgemod} {hline 2} Computable general equilibrium (CGE) modelling from a social accounting matrix,
with recursive dynamics, systematic sensitivity analysis, model diagnostics, and econometric
estimation of trade and substitution elasticities with residual diagnostics and remedies


{marker syntax}{...}
{title:Syntax}

{pstd}Build, check and balance a social accounting matrix (SAM)

{p 8 16 2}
{cmd:cgemod sam} {varlist} {ifin}{cmd:,} {opt lab:el(varname)} [{opt name(matname)} {opt bal:ance}
{opt tol:erance(#)} {opt max:iter(#)} {opt nolist}]

{p 8 16 2}
{cmd:cgemod sam,} {opt mat:rix(matname)} [{opt name(matname)} {opt bal:ance} {opt tol:erance(#)}
{opt max:iter(#)} {opt nolist}]

{pstd}Import a SAM from Excel or CSV and detect account roles from the names

{p 8 16 2}
{cmd:cgemod samimport using} {it:filename} [{cmd:,} {opt sheet(name)} {opt cellr:ange(range)}
{opt name(matname)}
{opt merge(SOURCE=DESTINATION ...)} {opt labelc:ol(#)} {opt noroles} {opt nolist}]

{pstd}Generate a balanced synthetic SAM of any size (for testing, teaching and performance benchmarks)

{p 8 16 2}
{cmd:cgemod samgen,} {opt sec:tors(#)} [{opt hou:seholds(#)} {opt seed(#)} {opt name(matname)} {opt nolist}]

{pstd}Audit a SAM: accounting identities, largest gaps, negative cells, GDP from both sides

{p 8 16 2}
{cmd:cgemod samcheck,} {opt sam(matname)} [{opt act:ivities(names)} {opt com:modities(names)}
{opt fac:tors(names)}
{opt hou:seholds(names)} {opt ent:erprises(names)} {opt gov:ernment(name)} {opt row(name)} {opt sav:inv(name)}
{opt tax:es(names)} {opt mar:gins(name)} {opt stock:s(name)} {opt top(#)}
{opt log(filename)} {opt notab:le}]

{pstd}Balance a SAM: sign-preserving cross-entropy (GRAS) or RAS, with locked cells, reliability weights and
control totals

{p 8 16 2}
{cmd:cgemod sambalance,} {opt sam(matname)} [{opt meth:od(gras|ras)} {opt name(matname)} {opt fix(matname)}
{opt fixacc:ounts(names)} {opt fixtot:als(names)} {opt weight:s(matname)} {opt tot:als(spec)}
{opt tol:erance(#)}
{opt max:iter(#)} {opt top(#)} {opt comp:are(filename[, replace])} {opt log(filename)} {opt notab:le}]

{pstd}Monitor a new SAM against a benchmark SAM: drift alerts

{p 8 16 2}
{cmd:cgemod sammonitor,} {opt sam(matname)} {opt bench:mark(matname)} [{opt thr:eshold(#)} {opt top(#)}
{opt log(filename)} {opt notab:le}]

{pstd}Export a SAM to Excel, CSV or a GAMS include file

{p 8 16 2}
{cmd:cgemod samexport,} {opt sam(matname)} [{opt exc:el(filename)} {opt csv(filename)} {opt gams(filename)}
{opt pri:or(matname)} {opt replace}]

{pstd}Calibrate the model

{p 8 16 2}
{cmd:cgemod calibrate,} {opt sam(matname)} [{opt act:ivities(names)} {opt com:modities(names)}
{opt fac:tors(names)} {opt hou:seholds(names)} {opt ent:erprises(names)} {opt gov:ernment(name)}
{opt row(name)}
{opt sav:inv(name)} {opt mar:gins(name)} {opt stock:s(name)} {it:calibrate_options}]

{pstd}Account roles may be omitted when the SAM was read with {cmd:cgemod samimport}; any role given overrides
the detected one.

{pstd}Comparative-static simulation

{p 8 16 2}
{cmd:cgemod sim} [{cmd:,} {it:shock_options} {opt tit:le(string)} {opt sav:ing(filename[, replace])}
{opt notab:le}]

{pstd}Recursive-dynamic baseline and policy paths

{p 8 16 2}
{cmd:cgemod dynamic,} {opt per:iods(#)} [{opt lab:or(factors)} {opt cap:ital(factors)} {opt lgr:owth(spec)}
{opt tfpgr:owth(spec)} {opt gdpg:rowth(#)} {opt popg:rowth(spec)} {opt pop:ulation(spec)} {opt ggr:owth(#)}
{opt fsavgr:owth(#)}
{opt pubs:hare(#)} {opt pubd:ep(#)} {opt pube:las(spec)} {opt pubinv(#)} {opt educ:om(commodity)}
{opt edul:abor(factors)}
{opt edue:las(#)} {opt edud:ep(#)} {opt debt0(#)} {opt depr:ec(#)} {opt rate(#)} {opt mob:ility(#)}
{opt start(#)}
{it:shock_options} {opt sav:ing(filename[, replace])} {opt notab:le}]

{pstd}Systematic sensitivity analysis of a simulation to the elasticities

{p 8 16 2}
{cmd:cgemod ssa,} {it:shock_options} [{opt elas:ticities(list)} {opt range(#)} {opt dist:ribution(type)}
{opt meth:od(type)} {opt rep:s(#)} {opt seed(#)} {opt bysec:tor} {opt sav:ing(filename[, replace])}
{opt notab:le}]

{pstd}Scenario manager: define, run and compare policy scenarios, export tables, graphs and a dashboard

{p 8 16 2}
{cmd:cgemod scenario define} {it:name} [{cmd:,} {it:shock_options} {opt clos:ure(closure_options)}
{opt desc:ription(text)} {opt replace}]

{p 8 16 2}
{cmd:cgemod scenario run} [{it:names}] [{cmd:,} {opt pov:erty(poverty_options)} {opt notab:le}]

{p 8 16 2}
{cmd:cgemod scenario} {cmd:list} | {cmd:table} | {cmd:drop} {it:names}|{cmd:_all}

{p 8 16 2}
{cmd:cgemod scenario graph} [{cmd:,} {opt ind:icators(names)} {opt hou:seholds} {opt tit:le(text)}
{opt name(name)} {opt sav:ing(filename)}]

{p 8 16 2}
{cmd:cgemod scenario export using} {it:filename}{cmd:.}{c -(}{cmd:html}|{cmd:xlsx}|{cmd:csv}{c )-} [{cmd:,}
{opt replace} {opt tit:le(text)}]

{pstd}Model diagnostics

{p 8 16 2}
{cmd:cgemod check} [{cmd:,} {opt notab:le}]

{pstd}Validation suite

{p 8 16 2}
{cmd:cgemod validate} [{cmd:,} {opt step:s(#)} {opt perf:ormance} {opt size:s(numlist)} {opt notab:le}]

{pstd}Compare the last simulation with external results (replication)

{p 8 16 2}
{cmd:cgemod compare using} {it:filename} [{cmd:,} {opt var:iable(varname)} {opt val:ue(varname)}
{opt sheet(name)}
{opt tol:erance(#)} {opt top(#)} {opt notab:le}]

{pstd}Poverty and inequality: link the last simulation to a household survey

{p 8 16 2}
{cmd:cgemod poverty} {ifin}{cmd:,} {opt group(varname)} {opt welf:are(varname)} {opt line(#|varname)}
[{opt weight(varname)}
{opt hhs:ize(varname)} {opt meth:od(ev|real|income)} {opt sources(var=FACTOR ...)} {opt trans:fers(varlist)}
{opt map(code=HOUSEHOLD ...)} {opt by(varname)} {opt gen:erate(newvar)} {opt dyn:amic} {opt notab:le}]

{pstd}Describe the calibrated model

{p 8 16 2}
{cmd:cgemod describe}

{pstd}Estimate an elasticity with residual diagnostics and remedies

{p 8 16 2}
{cmd:cgemod elast} {it:depvar} {it:pricevar} [{it:controls}] {ifin} [{cmd:,} {it:elast_options}]


{marker description}{...}
{title:Description}

{pstd}
{cmd:cgemod} calibrates and solves a standard single-country, open-economy CGE model directly from a
balanced SAM held in a Stata matrix. The model belongs to the family of the IFPRI standard model
(Lofgren, Harris and Robinson 2002) and the PEP-1-1 model (Decaluw{c e'} et al. 2013): CES value added,
Leontief intermediate inputs, CET allocation of output between exports and domestic sales, Armington
substitution between imports and domestic goods, Cobb-Douglas or linear-expenditure-system (LES)
household demand, a government, the rest of the world, and a savings-investment account, with a
choice of macro and factor-market closures.

{pstd}
Computation follows ideas in the R packages {it:CGE} and {it:GE} (Li 2019), which describe an economy by
demand and supply coefficients with nested Cobb-Douglas, CES and Leontief demand and simulate time paths.
{cmd:cgemod} differs in that it (i) calibrates every parameter from a SAM, (ii) writes all CES and CET
functions in calibrated share form, so that the benchmark is reproduced exactly for any elasticity,
(iii) solves the model as a square system in prices and activity levels with a damped Newton method
in Mata instead of iterative price adjustment, (iv) adds standard closures, welfare measurement
(equivalent variation), recursive dynamics, Gaussian-quadrature or Monte Carlo sensitivity analysis and
a battery of model checks, and (v) estimates the elasticities that feed the model, with diagnostics
for normality, heteroskedasticity, serial correlation, misspecification, parameter stability,
cross-sectional dependence, multicollinearity and endogeneity, and remedies for those problems.

{pstd}
Note that a calibrated CGE model has no residuals: regression diagnostics apply to the {it:estimation}
of its elasticities ({cmd:cgemod elast}), whereas the robustness of model {it:results} is assessed with
{cmd:cgemod check}, {cmd:cgemod validate} and {cmd:cgemod ssa}.

{pstd}
The user manual ({cmd:cgemod_manual.pdf}), a tour of all subcommands ({cmd:cgemod_example.do}) and a
six-module
training course with exercises ({cmd:cgemod_training.do}) are installed with {cmd:net get cgemod}. The
certification
script {cmd:cgemod_cert.do} and the unit tests {cmd:cgemod_unittest.do} verify an installation.


{marker sam}{...}
{title:SAM layout}

{pstd}
Rows receive and columns pay. Activities and commodities are separate accounts and need not be equal in
number:
an activity may produce several commodities and a commodity may be produced by several activities (make
matrix).
Flows must be in the following cells (payer {c -}> receiver); any other nonzero cell stops calibration with a
list
of the offending cells. "Institutions" are households and enterprises.

{p2colset 8 34 36 2}{...}
{p2col:Activity {c -}>}commodities (intermediates), factors (value added), government or tax accounts
(activity taxes){p_end}
{p2col:Commodity {c -}>}producing activities (make matrix, incl. exports), rest of world (imports, c.i.f.),
tax accounts (sales taxes; tariff accounts; export-tax accounts), government (sales taxes), margin account
(trade and transport margins){p_end}
{p2col:Margin account {c -}>}the commodities that supply margin services{p_end}
{p2col:Factor {c -}>}institutions, government or tax accounts (factor taxes), rest of world (factor income
shares){p_end}
{p2col:Household {c -}>}commodities (consumption), activities (home consumption at producer prices),
government or tax accounts (direct taxes), savings-investment, other institutions, rest of world (transfers
abroad){p_end}
{p2col:Enterprise {c -}>}government or tax accounts (direct taxes), savings-investment, other institutions,
rest of world (dividends abroad){p_end}
{p2col:Government {c -}>}commodities (consumption), institutions (transfers), savings-investment (savings),
rest of world (interest, transfers){p_end}
{p2col:Rest of world {c -}>}commodities (exports, f.o.b.), factors, institutions, government,
savings-investment (foreign savings){p_end}
{p2col:Savings-investment {c -}>}commodities (fixed investment), stock-change account; a negative government
or foreign saving may be shown as a payment from savings-investment{p_end}
{p2col:Stock-change account {c -}>}commodities (stock changes, held fixed in quantity){p_end}
{p2col:Tax account {c -}>}government{p_end}
{p2colreset}{...}

{pstd}
Payments by commodities to a tax account are tariffs if the account is listed in {opt tariff()},
export taxes if it is listed in {opt exptax()}, and sales taxes otherwise. Payments by activities to any
tax account are activity taxes, and payments by households are direct taxes. Each commodity must have
A commodity may be imported but not produced (no domestic sales) or produced only for export; stock
changes are kept as a separate account ({opt stocks()}), or can be merged into investment with
{cmd:samimport, merge(DSTK=S_I)}. {cmd:cgemod sam, balance} is a quick RAS
balance; {cmd:cgemod sambalance} (see {help cgemod##samtools:SAM workflow}) is the full tool.


{marker samimport}{...}
{title:SAM import and replication}

{pstd}
{bf:samimport} reads a SAM from Excel, CSV or tab-delimited text (.tab, as distributed on IFPRI's Dataverse)
laid
out as in a spreadsheet: account names in the first row and in column {opt labelcol()} (default 1; use
{cmd:labelcol(2)} when the first column holds descriptions and the second the account codes, and
{opt cellrange()}
to skip title rows), blank cells read as zero, thousands separators removed, and rows or columns
labelled TOTAL ignored. Columns are matched to rows by name, so their order may differ. Names are made valid
Stata
names (for example {cmd:a-maiz} becomes {cmd:a_maiz}). {opt merge()} adds one account to another, for example
stock
changes to savings-investment.

{pstd}
Account roles are detected from common naming conventions, including prefixed names ({cmd:A_AGR}, {cmd:C_AGR},
{cmd:HH_RUR}, {cmd:TAX_TAR}) and the IFPRI convention of paired names without separators
({cmd:amaiz}/{cmd:cmaiz},
{cmd:flab}, {cmd:hhd}, {cmd:ent}, {cmd:gov}, {cmd:row}, {cmd:s_i}, {cmd:trc}, {cmd:mtax}, {cmd:etax},
{cmd:dtax}).
The detected roles are displayed, returned in {cmd:r()} and used by {cmd:cgemod calibrate} when roles are not
given.
Always check them.

{pstd}
{bf:compare} checks the last {cmd:cgemod sim} against results from another implementation, for example the
IFPRI standard model or PEP model run in GAMS. The file (CSV, Excel or Stata) needs a string variable of
result
names and a numeric variable of percentage changes. Names follow the pattern RGDP, RABS, RCONS, RINV, REXP,
RIMP, EXR,
CPI, X_{it:activity}, VA_{it:activity}, PA_{it:activity}, QX_ QD_ QE_ QM_ QQ_ PD_ PX_ PQ_ PE_
PM_{it:commodity},
EMP_ WF_ YF_{it:factor}, YH_ EH_ EV_ EVPCT_{it:household}. Results whose absolute difference exceeds
{opt tolerance()}
(default 0.001 percentage points) are counted as failures, and {cmd:r(status)} is REPLICATED or DIFFERENCES.
The files
{cmd:cgemod_sam_ext.csv} and {cmd:cgemod_ext_reference.csv} provide a worked replication against an
independent
implementation of the model under four closures.

{marker samtools}{...}
{title:SAM workflow: audit, balancing, monitoring, export}

{pstd}
Generic matrix balancers ({cmd:mstdize}, {cmd:ipf}) rescale a table to given margins. The SAM tools in
{cmd:cgemod}
are built around the requirements of SAM work: they keep negative entries, respect cells and totals known to
be exact,
report how much the data were changed, warn when new data drift from a benchmark, and keep an audit trail. A
typical
daily workflow is {cmd:samcheck} {c -}> {cmd:sambalance} {c -}> {cmd:sammonitor} {c -}> {cmd:samexport}, with
{opt log()}
recording each run.

{pstd}
{bf:samcheck} lists the accounts with the largest receipt-payment gaps (gap and gap as % of the account
total), negative
cells and empty accounts. If account roles are given, it reports each accounting identity by group
(activities: revenue =
cost; commodities: supply = demand; factors; households; government; rest of world; savings = investment; tax
accounts),
names the account with the largest gap in each group, and computes GDP at market prices from the income side
(value added plus net indirect taxes) and the expenditure side (market and home consumption + G + I + stock
changes + X - M).

{pstd}
{bf:sambalance, method(gras)} (the default; {cmd:ce} is a synonym) finds the balanced SAM X closest to the
prior SAM A in
the weighted cross-entropy sense, minimising sum w_ij |a_ij| (z_ij ln z_ij - z_ij + 1) with z_ij = x_ij/a_ij,
subject to
row total = column total for every account and to any control totals. Each cell keeps its sign, so negative
savings,
net taxes or stock changes stay negative, as in the GRAS method (Junius and Oosterhaven 2003; Lenzen, Wood and
Gallego
2007), and zero cells stay zero. Reliability weights w_ij (default 1) make trusted cells move less; cells in
{opt fix()} or in the rows and columns of {opt fixaccounts()} are not changed at all. The problem is solved
through its
dual by Newton's method; with control totals for every account and no negative cells the solution coincides
with RAS.
{bf:method(ras)} applies classical RAS; negative cells are first moved to the transposed cell.

{pstd}
After balancing, the command reports the largest gap before and after, the Kullback-Leibler divergence between
the
structures (absolute cell shares) of the prior and balanced SAM, the mean and largest absolute % change of
nonzero cells,
the number of cells changed by more than 5%, sign changes, the cross-entropy objective, the largest change in
a locked
cell, and the cells with the largest adjustments.

{pstd}
{bf:sammonitor} compares a new SAM with a benchmark (accounts are matched by name) and raises flags for: cells
deviating
by more than {opt threshold()} percent (default 25), new nonzero cells, vanished cells, sign changes, account
totals
deviating by more than the threshold, accounts added or missing, and imbalance in the new SAM. It reports the
Kullback-Leibler divergence and the mean absolute % deviation, lists the largest drifts, and returns
{cmd:r(status)}
= OK or ALERT, which can stop a scheduled do-file with {cmd:assert "`r(status)'" == "OK"}.

{pstd}
{bf:log(filename)} appends one record per run to a Stata dataset (created if absent) with the date, time,
user,
command, SAM name and all diagnostics, giving an audit trail across runs. {bf:compare()} saves a cell-by-cell
dataset
of values before and after balancing.

{pstd}
{bf:samexport} writes the SAM to an Excel workbook (sheet SAM, plus sheets prior and change when {opt prior()}
is given,
and an info sheet with the export date and balance statistics), to a CSV file for Python or R, or to a GAMS
include file
defining set {cmd:ac}, alias {cmd:acp} and parameter {cmd:SAM(ac,acp)}.

{dlgtab:sambalance options}

{phang}{opt fix(matname)} K x K matrix; nonzero entries mark cells that must not change.{p_end}
{phang}{opt fixaccounts(names)} locks every cell in the rows and columns of these accounts (each must already
balance).{p_end}
{phang}{opt fixtotals(names)} keeps the totals of these accounts at the average of their current row and
column totals.{p_end}
{phang}{opt weights(matname)} K x K matrix of positive reliability weights; a cell with weight 10 resists
change ten times
as strongly as a cell with weight 1.{p_end}
{phang}{opt totals(spec)} control totals: a list such as {cmd:"ROW=112 GOV=85"} or a 1 x K matrix whose column
names are
account names.{p_end}
{phang}{opt name(matname)} balanced matrix; default {it:sam}{cmd:_bal}. {opt top(#)} number of cells listed
(default 10).{p_end}


{marker model}{...}
{title:The model}

{pstd}
Benchmark prices are normalised to one (sales-tax-inclusive composite prices equal 1+tq), so benchmark
quantities equal SAM values. The equations, written in calibrated share form, are:

{p 8 12 2}{bf:Production.} X(a) is Leontief in value added VA(a) and intermediates; VA(a) is CES in factors
with
elasticity {opt sigmava()} and productivity TFP(a); zero profit: PX(1-ta) = PVA*iva + sum_c
PQ(c)*ica(c,a).{p_end}
{p 8 12 2}{bf:Make matrix.} Each activity produces commodities in fixed proportions of its marketed output;
the
output of a commodity is a CES aggregate of the supplies of its producers with elasticity {opt sigmax()}
(default 4),
so activity prices PA can differ from commodity producer prices. Home consumption is valued at the activity
price and
is part of household LES demand.{p_end}
{p 8 12 2}{bf:Exports.} Output is allocated between exports QE and domestic sales QD by a CET function with
elasticity {opt omega()}; PE = pwe*EXR*(1-te).{p_end}
{p 8 12 2}{bf:Imports.} Absorption QQ is a CES (Armington) aggregate of imports QM and QD with elasticity
{opt sigmaq()}; PM = pwm*EXR*(1+tm). Trade margins are a fixed quantity of margin services per unit of
domestic
sales and per unit of imports, so the Armington choice is made between margin-inclusive prices
PDD = PD + m*PMG and PM + m*PMG, where PMG is the price of the margin bundle; PQ = PQA*(1+tq).{p_end}
{p 8 12 2}{bf:Factors.} Each factor is mobile (one wage, fixed supply), sector-specific (fixed use by
sector, sector rents adjust) or unemployed (fixed wage, employment adjusts).{p_end}
{p 8 12 2}{bf:Factor income.} Factor taxes (payments from factors to tax accounts) are levied at fixed rates
and
factor payments to the rest of the world are fixed in foreign currency; the remaining factor income is
distributed
to institutions and the government in fixed shares.{p_end}
{p 8 12 2}{bf:Institutions.} Households and enterprises receive factor income, government transfers (indexed
to
the CPI), transfers from abroad (fixed in foreign currency) and transfers from other institutions, which are
fixed
shares of the payer's income after direct tax and savings; transfers abroad are such shares too. The resulting
linear system of institutional incomes is solved at every evaluation. Enterprises do not consume. Households:
direct tax rate ty; savings rate mps; LES demand
C = gamma + beta/PQ*(EH - sum PQ*gamma), which is Cobb-Douglas when {cmd:frisch(-1)} and all income
elasticities are one.{p_end}
{p 8 12 2}{bf:Government.} Revenue from all taxes, factor income and foreign transfers; real
consumption fixed (scalable by {opt gadj()}); savings = revenue - spending.{p_end}
{p 8 12 2}{bf:Rest of world.} Balance of payments in foreign currency.{p_end}
{p 8 12 2}{bf:Stock changes} are fixed in quantity and financed from savings.{p_end}
{p 8 12 2}{bf:Savings-investment.} Total savings = value of investment and stock changes + WALRAS, where the
slack WALRAS
must be zero at a solution (Walras' law check). The CPI is the numeraire.{p_end}

{pstd}
The unknowns are domestic prices, activity levels, factor prices (or sector rents), the exchange rate
(or foreign savings), the investment or savings adjustment factor, the direct-tax adjustment (if
government savings are fixed) and WALRAS. All other variables are explicit functions of these, which
keeps the system small (roughly two equations per sector). It is solved by Newton's method with a
forward-difference Jacobian and a backtracking line search.

{pstd}{bf:Relation to the IFPRI standard model.} The equations follow Appendix A of Lofgren, Harris and
Robinson (2002):
price, production, trade, institution and system-constraint blocks, the treatment of factor taxes and factor
payments abroad, margins on domestic sales and imports, fixed stock changes, transfers between institutions,
and
the closure set. Remaining differences: (i) a SAM with a single margin account does not separate margins on
imports, domestic sales and exports, so one rate per commodity applies to imports and domestic sales and
export
margins are zero; (ii) home consumption is valued at the activity price rather than at commodity-specific
producer
prices, which is identical for single-product activities; (iii) transfers from households and enterprises to
the
rest of the world are fixed shares of their disposable income; (iv) payments from enterprises to the
government
are treated as direct taxes. Sales taxes are levied on the price net of tax, which changes the meaning of the
rate in {cmd:tq()} shocks but not the benchmark or any other result.

{pstd}{bf:Closures}{p_end}
{p2colset 8 36 38 2}{...}
{p2col:{cmd:exchange(flexible)}}fixed foreign savings, flexible exchange rate (default){p_end}
{p2col:{cmd:exchange(fixed)}}fixed exchange rate, flexible foreign savings{p_end}
{p2col:{cmd:gsav(flexible)}}fixed tax rates, flexible government savings (default){p_end}
{p2col:{cmd:gsav(fixed)}}fixed real government savings, direct-tax rates scaled by TINSADJ{p_end}
{p2col:{cmd:siclosure(savings)}}savings-driven investment: quantities scaled by IADJ (default){p_end}
{p2col:{cmd:siclosure(investment)}}fixed real investment, household savings rates scaled by (1+MPSADJ){p_end}
{p2col:{cmd:wagecurve()}, {cmd:unemployed()}, {cmd:specific()}}labour and capital market closures by
factor{p_end}

{pstd}{bf:Quotas and price caps} are complementarity conditions (a rent or subsidy is zero when the constraint
is
slack and positive when it binds). They are solved jointly with the rest of the model by writing each
condition
with the Fischer-Burmeister function (Fischer 1992), so binding and non-binding cases need no special
handling.{p_end}
{p2colreset}{...}


{marker shocks}{...}
{title:Shocks}

{pstd}
Shock options take a list of tokens of the form {it:name}{cmd:=}{it:#} (set), {it:name}{cmd:*}{it:#}
(multiply) or {it:name}{cmd:+}{it:#} (add). Omitting {it:name} (as in {cmd:*0.5}) applies the operation to
all elements. Names are account names from the SAM.

{p2colset 8 26 28 2}{...}
{p2col:{opt tm()}}tariff rates by commodity, e.g. {cmd:tm(*0)} removes all tariffs{p_end}
{p2col:{opt tq()}}sales-tax rates by commodity{p_end}
{p2col:{opt te()}}export-tax rates by commodity{p_end}
{p2col:{opt ta()}}activity-tax rates by activity{p_end}
{p2col:{opt ty()}}direct-tax rates by household{p_end}
{p2col:{opt pwm()}}world import prices by commodity, e.g. {cmd:pwm(C_IND*1.2)}{p_end}
{p2col:{opt pwe()}}world export prices by commodity{p_end}
{p2col:{opt tfp()}}value-added productivity by activity{p_end}
{p2col:{opt fs()}}factor supplies (sector-specific factors are scaled in every sector){p_end}
{p2col:{opt wf()}}fixed wages of unemployed or sector-specific factors{p_end}
{p2col:{opt gadj(#)}}scale of real government consumption (benchmark 1){p_end}
{p2col:{opt fsav(#)}}foreign savings in foreign currency (with {cmd:exchange(flexible)}){p_end}
{p2col:{opt tmsched(spec)}}a tariff schedule: a list such as {cmd:"C_IND=0.05 C_AGR=0"} or a 1 x n matrix of
new rates with commodity column names (for example an AfCFTA liberalisation schedule){p_end}
{p2col:{opt ctax(#)}}carbon tax per unit of emissions, in SAM currency units at benchmark prices (indexed to
the CPI); it raises purchaser prices of emitting commodities and costs of activities with process
emissions{p_end}
{p2col:{opt mquota(spec)}}import quotas as multiples of benchmark imports, e.g. {cmd:mquota(C_IND=0.9)}; a
binding quota creates a rent (a premium on the import price) collected by the government{p_end}
{p2col:{opt xquota(spec)}}export quotas as multiples of benchmark exports, with a rent on the export
price{p_end}
{p2col:{opt pcap(spec)}}caps on purchaser prices relative to the CPI, as multiples of benchmark prices; a
binding cap is financed by a government subsidy{p_end}
{p2col:{opt qg(spec)}}real government consumption by commodity, e.g. {cmd:qg(C_EDUC*1.2)}{p_end}
{p2col:{opt gsavshare(#)}}fiscal rule: government savings equal this share of GDP at factor cost (negative for
a deficit); requires {cmd:gsav(fixed)}{p_end}
{p2colreset}{...}


{marker options}{...}
{title:Options}

{dlgtab:cgemod sam}

{phang}{opt label(varname)} string variable holding the account names; the numeric variables in
{varlist} must be the SAM columns in the same order as the rows. Names are converted to valid Stata
names (for example {cmd:A-AGR} becomes {cmd:A_AGR}).{p_end}
{phang}{opt matrix(matname)} checks (and with {opt balance} balances) an existing matrix.{p_end}
{phang}{opt name(matname)} name of the resulting matrix; default {cmd:CGESAM}.{p_end}
{phang}{opt balance} balances the SAM with RAS to targets equal to the average of row and column
totals.{p_end}
{phang}{opt tolerance(#)} and {opt maxiter(#)} control the RAS iterations; defaults 1e-9 (relative to the
SAM total) and 5000.{p_end}
{phang}{opt nolist} suppresses the table of account totals.{p_end}

{dlgtab:cgemod calibrate}

{phang}{opt taxes(names)}, {opt tariff(names)}, {opt exptax(names)} tax accounts (see
{help cgemod##sam:SAM layout}).{p_end}
{phang}{opt sigmava(spec)}, {opt sigmaq(spec)}, {opt omega(spec)} value-added, Armington and CET
elasticities; defaults 0.8, 2 and 2. {it:spec} is a number for all sectors, a list such as
{cmd:"1.5 C_AGR=0.9"} (a bare number sets all, then named entries override), or the name of a
1 x n matrix whose column names are sector names, such as the matrix filled by
{cmd:cgemod elast, store()}.{p_end}
{phang}{opt enterprises(names)} enterprise accounts; {opt margins(name)} the trade-margin account;
{opt stocks(name)}
the stock-change account.{p_end}
{phang}{opt sigmax(spec)} elasticity of substitution between producers of the same commodity (default
4).{p_end}
{phang}{opt frisch(#)} Frisch parameter of the LES; default -1 gives Cobb-Douglas demand.{p_end}
{phang}{opt incelas(spec)} income elasticities by commodity (normalised so that budget shares sum to one);
use together with {opt frisch()}.{p_end}
{phang}{opt specific(factors)} sector-specific factors; {opt unemployed(factors)} factors with a fixed
wage.{p_end}
{phang}{opt wagecurve(factors)} factors whose real wage and unemployment rate are linked by a wage curve
u = u0 (W/CPI)^(-1/e) (Blanchflower and Oswald 1994): employment = labour force x (1 - u). {opt urate(spec)}
gives
the benchmark unemployment rates u0 (default 0.1) and {opt elasw(spec)} the wage-curve elasticity e (default
0.1),
by factor name or as one number for all.{p_end}
{phang}{opt emissions(spec)} benchmark emissions from the domestic use of each commodity (for example
{cmd:emissions(c_petr=45 c_coal=12)}), in any physical unit; emissions are proportional to absorption.
{opt pemissions(spec)} process emissions by activity, proportional to output. These enable
{opt ctax()}.{p_end}
{phang}{opt fiscal(dirtax|transfers|salestax|spending)} the instrument that adjusts when government savings
are
fixed ({cmd:gsav(fixed)}): a proportional scaling of direct-tax rates (default), a scaling of government
transfers
to households and enterprises, a uniform point change in sales-tax rates, or a scaling of real government
consumption. Combined with {opt ctax()} this gives revenue-neutral carbon taxes with alternative
recycling.{p_end}
{phang}{opt exchange()}, {opt gsav()}, {opt siclosure()} closures, described above.{p_end}
{phang}{opt tolerance(#)} convergence criterion on the largest scaled residual (default 1e-10);
{opt maxiter(#)} Newton iterations (default 100).{p_end}
{phang}{opt solver(newton|broyden)} the nonlinear solver. {cmd:newton} (default) recomputes the Jacobian by
finite differences at every iteration. {cmd:broyden} computes it once and then updates it with Broyden's
(1965)
rank-one formula, recomputing it only if a step fails; each iteration then costs one model evaluation instead
of
one per unknown, which makes large models (hundreds of sectors) much faster. Both use a backtracking line
search
(Dennis and Schnabel 1983) and reach the same solution; {cmd:cgemod validate} checks this.{p_end}
{phang}{opt notable} suppresses the table of benchmark structure.{p_end}

{dlgtab:cgemod sim}

{phang}{opt title()} labels the output; {opt saving()} saves sector results (% changes) as a dataset;
{opt notable} suppresses output.{p_end}

{dlgtab:cgemod dynamic}

{pstd}
Solves a sequence of within-period equilibria, in the tradition of recursive-dynamic models such as the IFPRI
dynamic
model (Diao and Thurlow 2012), the World Bank's MANAGE and MAMS (Lofgren, Cicowiez and Diaz-Bonilla 2013).
Between
periods, the supplies of {opt labor()} factors grow at {opt lgrowth()} (by factor), productivity grows at
{opt tfpgrowth()} (by activity), the population of each household group grows at {opt popgrowth()}
(subsistence
consumption and per-person government transfers grow with it; {opt population()} gives benchmark populations
used to
form the population and per-capita indicators, by default consumption shares), real government consumption
grows at
{opt ggrowth()} and foreign savings at {opt fsavgrowth()}, and the stock of {opt capital()}
factors accumulates as K(t+1) = (1-{opt deprec()})K(t) + real investment(t). Capital services equal the
stock times ({opt rate()} + {opt deprec()}), which is consistent with the benchmark rental. With
sector-specific capital, new investment is allocated in proportion to capital income adjusted by
relative rents, with responsiveness {opt mobility()} (Lofgren et al. 2002; Diao and Thurlow 2012).

{pstd}
{bf:Calibrated baseline.} With {opt gdpgrowth(#)} the baseline is calibrated: in every period an economy-wide
productivity factor (reported as TFPX) is solved so that real GDP grows at exactly the target rate, on top of
the
sector-specific rates in {opt tfpgrowth()}. The policy path uses the same productivity path, so differences
between the
paths are due to the policy alone.

{pstd}
{bf:Public capital.} {opt pubshare()} is the share of total investment that is public; public capital
accumulates
with depreciation {opt pubdep()} and raises the productivity of each activity with elasticity {opt pubelas()}.
{opt pubinv(#)} adds public investment equal to # times benchmark GDP from period {opt start()} in the policy
path;
it is government spending and is financed according to the fiscal closure (by default a larger deficit, which
crowds
out private investment; with {cmd:gsav(fixed) fiscal(...)} by taxes, transfers or other spending).

{pstd}
{bf:Human capital.} Real government consumption of {opt educom()} accumulates into a stock (depreciation
{opt edudep()}) that raises the efficiency of the {opt edulabor()} factors with elasticity {opt eduelas()}.
Raise
education spending with the shock option {opt qg()}, for example {cmd:qg(C_EDUC*1.2)}.

{pstd}
{bf:SDG indicators.} Each period reports population and GDP per capita indices, emissions, public and
education
capital, the debt stock and debt/GDP. {cmd:cgemod poverty, dynamic} follows poverty and inequality along both
paths.
The baseline path has no shock; the policy path applies the shock options from period {opt start()}
(default 1). Results report the baseline, the policy path and percentage deviations, with the
equivalent variation of the policy relative to the baseline in each period. Government savings, the government
debt
stock (starting from {opt debt0(#)}, default 0, and rising with every deficit) and debt as a percentage of GDP
are
also reported; their deviations are differences in levels.{p_end}

{dlgtab:cgemod ssa}

{phang}{opt elasticities()} any of {cmd:sigmava sigmaq omega frisch}; default
{cmd:sigmava sigmaq omega}.{p_end}
{phang}{opt range(#)} relative half-range of the elasticity distribution; default 0.5 (that is,
+/-50%).{p_end}
{phang}{opt distribution()} {cmd:uniform} (default), {cmd:triangular} or {cmd:normal} (standard deviation
range/2,
truncated at -95%).{p_end}
{phang}{opt method(quadrature)} (default) uses Stroud's degree-3 Gaussian quadrature with 2k points for k
independent parameters, which reproduces the mean and variance of results with very few solutions
(Arndt 1996; DeVuyst and Preckel 1997). {opt method(montecarlo)} draws {opt reps()} parameter vectors
and reports 5th and 95th percentiles.{p_end}
{phang}{opt bysector} perturbs each sector's elasticity independently; by default one factor per
elasticity type scales all sectors.{p_end}

{dlgtab:cgemod elast}

{phang}{it:depvar} and {it:pricevar} should be in logs: for {cmd:type(armington)} ln(QM/QD) on ln(PD/PM);
for {cmd:type(cet)} ln(QE/QD) on ln(PE/PD); for {cmd:type(va)} ln(K/L) on ln(w/r). The coefficient on
{it:pricevar} is the elasticity. Time-series operators are allowed.{p_end}
{phang}{opt dynamic} adds the lagged dependent variable (partial adjustment); the long-run elasticity
b/(1-rho) is reported with a delta-method standard error.{p_end}
{phang}{opt trend} adds a linear trend. {opt re} uses random effects for panel data.{p_end}
{phang}{opt iv(varlist)} treats {it:pricevar} as endogenous and estimates by 2SLS (or FE-2SLS), with tests of
endogeneity, instrument strength and overidentification.{p_end}
{phang}{opt remedy()} {cmd:auto} (default) chooses a remedy from the diagnostics; {cmd:none}, {cmd:robust},
{cmd:newey}, {cmd:prais}, {cmd:bootstrap}, {cmd:break} (time series) and {cmd:cluster}, {cmd:dk}, {cmd:cce}
(panels)
impose one.{p_end}
{phang}{opt lags(#)} lags for the Breusch-Godfrey test and the HAC estimators; default automatic.{p_end}
{phang}{opt reps(#)} bootstrap replications for the sup-F p-value and {cmd:remedy(bootstrap)}; default
499.{p_end}
{phang}{opt trim(#)} trimming for the break-date search; default 0.15. {opt nosupf} skips the sup-F
test.{p_end}
{phang}{opt sector(name)} and {opt store(matname)} store the estimate (long-run if {opt dynamic}, post-break
if a
break is modelled) in column {it:name} of a 1 x n matrix that {cmd:cgemod calibrate} can read.{p_end}


{marker poverty}{...}
{title:Poverty and inequality (cgemod poverty)}

{pstd}
{cmd:cgemod poverty} is a top-down microsimulation in the tradition of Bourguignon, Bussolo and Pereira da
Silva (2008).
The household survey in memory is linked to the last {cmd:cgemod sim}: each survey household belongs to one
SAM
household group ({opt group()}, a string variable holding SAM account names, or a numeric variable with
{opt map()}).
Its welfare measure ({opt welfare()}, for example consumption per person or per adult equivalent) changes
by:{p_end}
{p2colset 8 26 28 2}{...}
{p2col:{cmd:method(ev)}}the equivalent variation of its group as a share of consumption (default){p_end}
{p2col:{cmd:method(real)}}the change in its group's consumption deflated by the group's own price index
(Laspeyres, benchmark budget shares){p_end}
{p2col:{cmd:method(income)}}its own income composition: each income source in {opt sources()} changes with the
income of the
corresponding factor, transfers in {opt transfers()} with the CPI, and the result is deflated by the group
price index; households
therefore fare differently within a group according to how they earn their income{p_end}
{p2colreset}{...}
{pstd}
The command reports the Foster-Greer-Thorbecke (1984) headcount, gap and severity indices, the Gini
coefficient and mean
welfare before and after the shock, nationally, by SAM group, and by {opt by()}. Population weights are
{opt weight()}
times {opt hhsize()}. {opt line()} is a number or a variable (for example regional lines). {opt generate()}
saves the
simulated welfare. The example survey {cmd:cgemod_survey.dta} is simulated; its groups match the households of
the
example SAMs.

{pstd}
With {opt dynamic}, the command uses the last {cmd:cgemod dynamic} run instead: in every period the welfare of
each survey
household grows with real consumption per person of its SAM group, on the baseline and on the policy path, and
the
headcount, gap, severity and Gini indices are reported for both paths ({cmd:r(path)}).

{marker samgen}{...}
{title:Synthetic SAMs (cgemod samgen)}

{pstd}{cmd:cgemod samgen} builds a balanced SAM with {opt sectors()} activities and commodities, labour and
capital,
{opt households()} household groups (default 2), a government with sales-tax, tariff and direct-tax accounts,
a savings-investment account and the rest of the world. Flows are generated by a deterministic rule indexed by
{opt seed()}, so the same call always gives the same SAM on every computer; the SAM is balanced by
construction (no
RAS step), and household and foreign savings are positive. Account names follow the conventions that
{cmd:cgemod samimport} recognises, so the roles are detected and {cmd:cgemod calibrate, sam(}{it:name}{cmd:)}
needs
no role options. Use it to teach, to test closures, and to benchmark the solvers on large models.{p_end}


{marker scenario}{...}
{title:Scenario manager (cgemod scenario)}

{pstd}Policy analysis rarely stops at one simulation. {cmd:cgemod scenario define} stores a named scenario:
the
shocks of {cmd:cgemod sim} and, optionally, a different closure in {opt closure()} (any of {opt exchange()},
{opt gsav()}, {opt siclosure()} and {opt fiscal()}). Scenarios with their own closure are solved on a model
recalibrated with the calibration options last used and the new closure; the original model is restored
afterwards. {cmd:cgemod scenario run} solves the scenarios named (all by default) and collects, scenario by
scenario, the macroeconomic results, output by activity, household equivalent variation (in levels and in % of
base spending) and the change in average factor returns. A scenario that fails to solve is reported and leaves
missing values; the others are still run.{p_end}

{pstd}With {opt poverty()}, the household survey in memory is linked to each scenario through
{cmd:cgemod poverty} with the options given (for example
{cmd:poverty(group(group) welfare(pcexp) weight(weight)}
{cmd:line(167.8))}), and the headcount, gap, severity and Gini after each scenario are added to the
comparison.{p_end}

{pstd}{cmd:cgemod scenario table} redisplays the comparison; {cmd:graph} draws grouped bars of chosen macro
indicators (default RGDP RCONS RINV REXP RIMP) or, with {opt households}, of household welfare; {cmd:export}
writes the results to Excel (one sheet per block plus the scenario definitions), to a long CSV file (block,
item,
scenario, value), or to a self-contained HTML dashboard with charts and tables that can be opened in any
browser
and shared with decision makers. Scenario definitions are kept in global macros {cmd:CGEMOD_scen} and
{cmd:CGEMOD_scs_}{it:name}, so a do-file that defines them documents the analysis.{p_end}


{marker check}{...}
{title:Model diagnostics (cgemod check)}

{pstd}{cmd:cgemod check} reports pass/fail results for: SAM balance; exact replication of the benchmark;
admissible parameters (positive elasticities, savings and tax rates in [0,1), positive supernumerary
income); full rank and conditioning of the Jacobian; convergence under a test shock (+10% import
prices); Walras' law (zero slack); price homogeneity (doubling the numeraire, fixed exchange rate and
fixed wages leaves quantities unchanged and doubles prices); and uniqueness, by re-solving the test
shock from five perturbed starting points.{p_end}


{marker validate}{...}
{title:Validation suite (cgemod validate)}

{pstd}{cmd:cgemod validate} complements {cmd:cgemod check} with the tests that the CGE literature uses to
judge
whether a model is free of coding and closure errors (Dixon and Rimmer 2013):{p_end}
{phang2}1. a battery of standard shocks (import and export prices, tariff removal, productivity, government
spending, direct taxes, foreign savings): each must solve, satisfy Walras' law and keep the numeraire;{p_end}
{phang2}2. path independence: tariff removal applied in {opt steps()} increments (default 5) must reach the
same
equilibrium as the one-step shock;{p_end}
{phang2}3. symmetry: +1% and -1% import-price shocks must give mirror-image effects up to second-order
terms;{p_end}
{phang2}4. solver agreement: the Newton and Broyden solvers must find the same solution;{p_end}
{phang2}5. homogeneity of degree zero under a non-trivial shock (numeraire, fixed wages and fixed exchange
rate
multiplied by 3);{p_end}
{phang2}6. units invariance: the whole SAM multiplied by 1,000 must give the same percentage results.{p_end}

{pstd}With {opt performance}, synthetic SAMs with {opt sizes()} sectors (default 10 25 50) are generated,
calibrated
and solved for tariff removal with both solvers, and the number of unknowns, times, iterations and Jacobian
evaluations are reported. The model in memory is restored after the tests.{p_end}


{marker elast}{...}
{title:Elasticity estimation: diagnostics and remedies}

{p2colset 8 40 42 2}{...}
{p2col:{bf:Problem}}{bf:Test (data type) {c -}> remedy under remedy(auto)}{p_end}
{p2col:Non-normality}Jarque-Bera, Shapiro-Wilk {c -}> bootstrap standard errors if N < 50 and no serial
correlation{p_end}
{p2col:Heteroskedasticity}Koenker-Breusch-Pagan, White-type with squares (ts, cs); modified Wald for groupwise
heteroskedasticity (panel) {c -}> robust (ts, cs) or cluster-robust (panel){p_end}
{p2col:Serial correlation}Breusch-Godfrey, Durbin-Watson (ts); Wooldridge (panel) {c -}> Newey-West HAC (ts)
or cluster-robust (panel); {cmd:prais} on request{p_end}
{p2col:Misspecification}RESET with squared and cubed fitted values {c -}> note recommending {opt dynamic},
{opt trend} or nonlinear terms{p_end}
{p2col:Instability}CUSUM of recursive residuals; sup-F with unknown break date and fixed-regressor
wild-bootstrap p-value {c -}> intercept and slope shift at the estimated break date{p_end}
{p2col:Cross-sectional dependence}Pesaran CD (panel) {c -}> Driscoll-Kraay standard errors; {cmd:remedy(cce)}
for the CCE pooled estimator{p_end}
{p2col:Multicollinearity}variance inflation factors (within-transformed for panels) {c -}> warning{p_end}
{p2col:Endogeneity}with {opt iv()}: score/Durbin test, first-stage F, Sargan test {c -}> 2SLS with the chosen
covariance{p_end}
{p2col:Spurious regression}ADF t on residuals (ts), reported for comparison with Engle-Granger critical
values{p_end}
{p2colreset}{...}

{pstd}All tests use the 5% level. The final model is displayed in full and its results remain in
{cmd:e()}.{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:cgemod sim} stores in {cmd:r()}: matrices {cmd:r(macro)} (benchmark, simulation, % change or level
change),
{cmd:r(sector)} (activities: % changes in X, VA, PA and marketed output XM). {cmd:r(macro)} also has rows EMIS
(% change in
emissions), CREV (carbon-tax revenue), QREV (quota rents), SUBS (price-cap subsidies) and FISCADJ (the fiscal
adjuster);
{cmd:r(factor)} has the unemployment rate (urate) of wage-curve factors; {cmd:r(commodity)} (QX, QD, QE, QM,
QQ),
{cmd:r(prices)} (PD, PX, PQ, PE, PM), {cmd:r(factor)} and
{cmd:r(household)} (income and consumption changes, EV in levels and as % of consumption); scalars
{cmd:r(iterations)}, {cmd:r(jacobians)}, {cmd:r(max_resid)}, {cmd:r(walras)}.{p_end}
{pstd}{cmd:cgemod dynamic}: {cmd:r(baseline)}, {cmd:r(policy)}, {cmd:r(deviation)}; columns t, RGDP, RABS,
RCONS, RINV,
REXP, RIMP, EXR, CPI, FS_{it:factor}, X_{it:activity}, GSAV, DEBT, DEBTGDP, POP, RGDPPC, EMIS, KG, KE, TFPX
(and EV in
{cmd:r(deviation)}).{p_end}
{pstd}{cmd:cgemod poverty}: {cmd:r(poverty)} (P0, P1, P2, Gini, mean: before, after, change), {cmd:r(groups)},
{cmd:r(by)}, {cmd:r(N)}.{p_end}
{pstd}{cmd:cgemod ssa}: matrices {cmd:r(ssa)} (point, mean, sd, min, max, lower, upper, same-sign %) and
{cmd:r(draws)}
(parameter perturbations and results for each solution); scalars {cmd:r(ndraws)} and {cmd:r(failed)}.{p_end}
{pstd}{cmd:cgemod scenario run}: matrices {cmd:r(macro)} (rows as in {cmd:cgemod sim}, change column),
{cmd:r(sector)},
{cmd:r(ev)}, {cmd:r(evpct)}, {cmd:r(wage)} and, with {opt poverty()}, {cmd:r(poverty)}, one column per
scenario;
macros {cmd:r(scenarios)} and {cmd:r(failed)}.{p_end}
{pstd}{cmd:cgemod validate}: {cmd:r(passed)}, {cmd:r(failed)}, {cmd:r(results)} (1 = pass, by test) and, with
{opt performance}, {cmd:r(performance)} (sectors, unknowns, calibration time, Newton time, iterations and
Jacobians,
Broyden time and iterations, largest gap between the two solutions).{p_end}
{pstd}{cmd:cgemod samgen}: {cmd:r(accounts)}, {cmd:r(total)}, {cmd:r(name)}.{p_end}
{pstd}{cmd:cgemod check}: {cmd:r(passed)}, {cmd:r(failed)}, {cmd:r(cond)}, {cmd:r(walras)},
{cmd:r(homog)}.{p_end}
{pstd}{cmd:cgemod samimport}: {cmd:r(accounts)}, {cmd:r(maxdiff)}, and detected roles {cmd:r(activities)},
{cmd:r(commodities)},
{cmd:r(factors)}, {cmd:r(households)}, {cmd:r(enterprises)}, {cmd:r(government)}, {cmd:r(row)},
{cmd:r(savinv)}, {cmd:r(taxes)},
{cmd:r(tariff)}, {cmd:r(exptax)}, {cmd:r(margins)}, {cmd:r(stocks)}, {cmd:r(unassigned)}.{p_end}
{pstd}{cmd:cgemod compare}: {cmd:r(compared)}, {cmd:r(unmatched)}, {cmd:r(failed)}, {cmd:r(maxdiff)},
{cmd:r(worst)}, {cmd:r(status)}.{p_end}
{pstd}{cmd:cgemod calibrate}: {cmd:r(activities)}, {cmd:r(commodities)}, {cmd:r(enterprises)},
{cmd:r(sectors)}, {cmd:r(factors)}, {cmd:r(households)}, {cmd:r(bench_resid)}, {cmd:r(closure)}.{p_end}
{pstd}{cmd:cgemod samcheck}: {cmd:r(accounts)}, {cmd:r(total)}, {cmd:r(maxgap)}, {cmd:r(worst)},
{cmd:r(negative)}, {cmd:r(empty)},
{cmd:r(gdp_income)}, {cmd:r(gdp_exp)}, {cmd:r(stamp)}.{p_end}
{pstd}{cmd:cgemod sambalance}: {cmd:r(imb_before)}, {cmd:r(imb_after)}, {cmd:r(kl)}, {cmd:r(mape)},
{cmd:r(maxpct)},
{cmd:r(cells_gt5pct)}, {cmd:r(signflips)}, {cmd:r(entropy)}, {cmd:r(fixed)}, {cmd:r(targets)},
{cmd:r(iterations)},
{cmd:r(converged)}, {cmd:r(method)}, {cmd:r(name)}, {cmd:r(stamp)}.{p_end}
{pstd}{cmd:cgemod sammonitor}: {cmd:r(alerts)}, {cmd:r(status)}, {cmd:r(kl)}, {cmd:r(mape)},
{cmd:r(cells_over)}, {cmd:r(new_cells)},
{cmd:r(vanished)}, {cmd:r(signflips)}, {cmd:r(totals_over)}, {cmd:r(missing_accounts)}, {cmd:r(imbalance)},
{cmd:r(stamp)}.{p_end}
{pstd}{cmd:cgemod sam}: {cmd:r(accounts)}, {cmd:r(total)}, {cmd:r(maxdiff)} and, with {opt balance},
{cmd:r(maxdiff_before)}, {cmd:r(iterations)}, {cmd:r(converged)}.{p_end}
{pstd}{cmd:cgemod elast}: {cmd:r(elast)}, {cmd:r(se)}, {cmd:r(elast_base)}, {cmd:r(elast_lr)},
{cmd:r(elast_post)},
{cmd:r(elast_used)}, test statistics and p-values ({cmd:r(jb_p)}, {cmd:r(bp_p)}, {cmd:r(white_p)},
{cmd:r(bg_p)},
{cmd:r(dw)}, {cmd:r(cusum)}, {cmd:r(supf_p)}, {cmd:r(breakdate)}, {cmd:r(reset_p)}, {cmd:r(vif_max)},
{cmd:r(cd_p)},
{cmd:r(mwald_p)}, {cmd:r(wooldridge_p)}), and {cmd:r(remedy)}.{p_end}


{marker examples}{...}
{title:Examples}

{pstd}Load and check the illustrative SAM{p_end}
{phang2}{cmd:. use cgemod_sam3, clear}{p_end}
{phang2}{cmd:. cgemod sam a_agr-tax_dir, label(account) name(SAM3)}{p_end}

{pstd}SAM workflow: audit, balance with locked tax cells and a control total, monitor, export{p_end}
{phang2}{cmd:. cgemod samcheck, sam(SAM3) activities(A_AGR A_IND A_SER) commodities(C_AGR C_IND C_SER)}
{cmd:factors(LAB CAP) households(HH_RUR HH_URB) government(GOV) row(ROW) savinv(S_I) taxes(TAX_ACT TAX_SAL}
{cmd:TAX_TAR TAX_EXP TAX_DIR)}{p_end}
{phang2}{cmd:. cgemod sambalance, sam(NEW) fixaccounts(TAX_DIR) totals(ROW=112) log(samaudit) compare(changes,}
{cmd:replace)}{p_end}
{phang2}{cmd:. cgemod sammonitor, sam(NEW_bal) benchmark(SAM3) threshold(20) log(samaudit)}{p_end}
{phang2}{cmd:. cgemod samexport, sam(NEW_bal) prior(NEW) excel(sam2026.xlsx) gams(sam2026.inc) replace}{p_end}

{pstd}Import a richer SAM from a spreadsheet, calibrate with detected roles, and replicate reference
results{p_end}
{phang2}{cmd:. cgemod samimport using cgemod_sam_ext.csv, name(EXT)}{p_end}
{phang2}{cmd:. cgemod calibrate, sam(EXT)}{p_end}
{phang2}{cmd:. cgemod sim, tm(*0)}{p_end}
{phang2}{cmd:. cgemod compare using cgemod_ext_reference.csv, value(default)}{p_end}

{pstd}Labour market with a wage curve; carbon tax recycled through transfers; import quota; fiscal rule{p_end}
{phang2}{cmd:. cgemod calibrate, sam(EXT) wagecurve(LAB) urate(0.15) elasw(0.1)}{p_end}
{phang2}{cmd:. cgemod sim, tm(*0)}{p_end}
{phang2}{cmd:. cgemod calibrate, sam(EXT) emissions(C_OIL=50) pemissions(A_IND=10) gsav(fixed)}
{cmd:fiscal(transfers)}{p_end}
{phang2}{cmd:. cgemod sim, ctax(0.2)}{p_end}
{phang2}{cmd:. cgemod sim, tm(*0) mquota(C_IND=0.95)}{p_end}
{phang2}{cmd:. cgemod calibrate, sam(EXT) gsav(fixed) fiscal(spending)}{p_end}
{phang2}{cmd:. cgemod sim, gsavshare(-0.02)}{p_end}

{pstd}A calibrated 5% growth baseline with population, public and human capital, and a public investment
programme{p_end}
{phang2}{cmd:. cgemod dynamic, periods(10) labor(LAB) capital(CAP) lgrowth(LAB=0.025) gdpgrowth(0.05)}
{cmd:popgrowth(0.03) pubshare(0.3) pubelas(0.1) educom(C_SER) edulabor(LAB) eduelas(0.2) debt0(100)}
{cmd:pubinv(0.01)}{p_end}
{phang2}{cmd:. use cgemod_survey, clear}{p_end}
{phang2}{cmd:. cgemod poverty, group(group) welfare(pcexp) weight(weight) hhsize(hhsize) line(167.8)}
{cmd:dynamic}{p_end}

{pstd}Compare scenarios, including one under a fixed exchange rate, and export a dashboard{p_end}
{phang2}{cmd:. cgemod samimport using cgemod_sam_ext.csv, name(EXT)}{p_end}
{phang2}{cmd:. cgemod calibrate, sam(EXT)}{p_end}
{phang2}{cmd:. cgemod scenario define free, tm(*0) description("Remove all tariffs")}{p_end}
{phang2}{cmd:. cgemod scenario define free_fix, tm(*0) closure(exchange(fixed))}{p_end}
{phang2}{cmd:. cgemod scenario define oil, pwm(C_OIL*1.3)}{p_end}
{phang2}{cmd:. cgemod scenario run}{p_end}
{phang2}{cmd:. cgemod scenario graph, households}{p_end}
{phang2}{cmd:. cgemod scenario export using results.html, replace}{p_end}

{pstd}Validate the model and benchmark the solvers on large synthetic SAMs{p_end}
{phang2}{cmd:. cgemod validate, performance sizes(25 50 100)}{p_end}
{phang2}{cmd:. cgemod samgen, sectors(200) households(10)}{p_end}
{phang2}{cmd:. cgemod calibrate, sam(GENSAM) solver(broyden)}{p_end}

{pstd}Poverty effects of tariff removal on a household survey{p_end}
{phang2}{cmd:. cgemod sim, tm(*0)}{p_end}
{phang2}{cmd:. use cgemod_survey, clear}{p_end}
{phang2}{cmd:. cgemod poverty, group(group) welfare(pcexp) weight(weight) hhsize(hhsize) line(167.8)}
{cmd:by(region)}{p_end}
{phang2}{cmd:. cgemod poverty, group(group) welfare(pcexp) weight(weight) hhsize(hhsize) line(167.8)}
{cmd:method(income) sources(inc_lab=LAB inc_cap=CAP) transfers(inc_trans)}{p_end}

{pstd}Calibrate{p_end}
{phang2}{cmd:. cgemod calibrate, sam(SAM3) activities(A_AGR A_IND A_SER) commodities(C_AGR C_IND C_SER)}
{cmd:factors(LAB CAP) households(HH_RUR HH_URB) government(GOV) row(ROW) savinv(S_I) taxes(TAX_ACT TAX_SAL}
{cmd:TAX_DIR) tariff(TAX_TAR) exptax(TAX_EXP)}{p_end}
{phang2}{cmd:. cgemod check}{p_end}

{pstd}Remove all tariffs; raise world industrial import prices by 20%{p_end}
{phang2}{cmd:. cgemod sim, tm(*0) title(Tariff removal)}{p_end}
{phang2}{cmd:. cgemod sim, pwm(C_IND*1.2)}{p_end}

{pstd}Sensitivity of the tariff experiment to the elasticities{p_end}
{phang2}{cmd:. cgemod ssa, tm(*0) range(0.5)}{p_end}
{phang2}{cmd:. cgemod ssa, tm(*0) method(montecarlo) reps(500) seed(123) bysector}{p_end}

{pstd}Recursive dynamics: tariff removal from period 2{p_end}
{phang2}{cmd:. cgemod dynamic, periods(10) labor(LAB) capital(CAP) lgrowth(0.03) tfpgrowth(0.01) start(2)}
{cmd:tm(*0)}{p_end}

{pstd}Estimate an Armington elasticity and use it in the model{p_end}
{phang2}{cmd:. use cgemod_tsdata, clear}{p_end}
{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. cgemod elast ln_qm_qd ln_pd_pm ln_gdp, type(armington) sector(C_IND) store(SIGQ)}{p_end}
{phang2}{cmd:. cgemod calibrate, ... sigmaq(SIGQ)}{p_end}

{pstd}Panel estimation with cross-sectional dependence{p_end}
{phang2}{cmd:. use cgemod_paneldata, clear}{p_end}
{phang2}{cmd:. xtset sector year}{p_end}
{phang2}{cmd:. cgemod elast ln_qm_qd ln_pd_pm, type(armington)}{p_end}
{phang2}{cmd:. cgemod elast ln_qm_qd ln_pd_pm, type(armington) remedy(cce)}{p_end}


{marker references}{...}
{title:References}

{phang}Andrews, D. W. K. 1993. Tests for parameter instability and structural change with unknown change
point. {it:Econometrica} 61: 821{c -}856.{p_end}
{phang}Armington, P. S. 1969. A theory of demand for products distinguished by place of production.
{it:IMF Staff Papers} 16: 159{c -}178.{p_end}
{phang}Arndt, C. 1996. An introduction to systematic sensitivity analysis via Gaussian quadrature. GTAP
Technical Paper No. 2, Purdue University.{p_end}
{phang}Blanchflower, D. G., and A. J. Oswald. 1994. {it:The Wage Curve}. Cambridge, MA: MIT Press.{p_end}
{phang}Bourguignon, F., M. Bussolo, and L. A. Pereira da Silva, eds. 2008.
{it:The Impact of Macroeconomic Policies on Poverty and Income Distribution: Macro-Micro Evaluation Techniques}
{it:and Tools}. Washington, DC: World Bank and Palgrave Macmillan.{p_end}
{phang}Breusch, T. S. 1978. Testing for autocorrelation in dynamic linear models.
{it:Australian Economic Papers} 17: 334{c -}355.{p_end}
{phang}Broyden, C. G. 1965. A class of methods for solving nonlinear simultaneous equations.
{it:Mathematics of Computation} 19: 577{c -}593.{p_end}
{phang}Brown, R. L., J. Durbin, and J. M. Evans. 1975. Techniques for testing the constancy of regression
relationships over time. {it:Journal of the Royal Statistical Society, Series B} 37: 149{c -}192.{p_end}
{phang}Decaluw{c e'}, B., A. Lemelin, V. Robichaud, and H. Maisonnave. 2013. PEP-1-1: The PEP standard
single-country, static CGE model. Partnership for Economic Policy.{p_end}
{phang}Dervis, K., J. de Melo, and S. Robinson. 1982. {it:General Equilibrium Models for Development Policy}.
Cambridge: Cambridge University Press.{p_end}
{phang}Dennis, J. E., and R. B. Schnabel. 1983.
{it:Numerical Methods for Unconstrained Optimization and Nonlinear Equations}. Englewood Cliffs, NJ:
Prentice-Hall.{p_end}
{phang}DeVuyst, E. A., and P. V. Preckel. 1997. Sensitivity analysis revisited: A quadrature-based approach.
{it:Journal of Policy Modeling} 19: 175{c -}185.{p_end}
{phang}Diao, X., and J. Thurlow. 2012. A recursive dynamic computable general equilibrium model. In
{it:Strategies and Priorities for African Agriculture}, ed. X. Diao, J. Thurlow, S. Benin, and S. Fan.
Washington, DC: International Food Policy Research Institute.{p_end}
{phang}Dixon, P. B., and M. T. Rimmer. 2013. Validation in computable general equilibrium modeling. In
{it:Handbook of Computable General Equilibrium Modeling}, vol. 1B, ed. P. B. Dixon and D. W. Jorgenson,
1271{c -}1330. Amsterdam: North-Holland.{p_end}
{phang}Driscoll, J. C., and A. C. Kraay. 1998. Consistent covariance matrix estimation with spatially
dependent panel data. {it:Review of Economics and Statistics} 80: 549{c -}560.{p_end}
{phang}Fischer, A. 1992. A special Newton-type optimization method. {it:Optimization} 24: 269{c -}284.{p_end}
{phang}Foster, J., J. Greer, and E. Thorbecke. 1984. A class of decomposable poverty measures.
{it:Econometrica} 52: 761{c -}766.{p_end}
{phang}Godfrey, L. G. 1978. Testing against general autoregressive and moving average error models when the
regressors include lagged dependent variables. {it:Econometrica} 46: 1293{c -}1301.{p_end}
{phang}Greene, W. H. 2000. {it:Econometric Analysis}. 4th ed. Upper Saddle River, NJ: Prentice Hall.{p_end}
{phang}Hansen, B. E. 2000. Testing for structural change in conditional models. {it:Journal of Econometrics}
97: 93{c -}115.{p_end}
{phang}Jarque, C. M., and A. K. Bera. 1987. A test for normality of observations and regression residuals.
{it:International Statistical Review} 55: 163{c -}172.{p_end}
{phang}Junius, T., and J. Oosterhaven. 2003. The solution of updating or regionalizing a matrix with both
positive and negative entries. {it:Economic Systems Research} 15: 87{c -}96.{p_end}
{phang}Koenker, R. 1981. A note on studentizing a test for heteroscedasticity. {it:Journal of Econometrics}
17: 107{c -}112.{p_end}
{phang}Lenzen, M., R. Wood, and B. Gallego. 2007. Some comments on the GRAS method.
{it:Economic Systems Research} 19: 461{c -}465.{p_end}
{phang}Li, W. 2019. {it:General Equilibrium and Structural Dynamics: Perspectives of New Structural}
{it:Economics}. Beijing: Economic Science Press.{p_end}
{phang}Lofgren, H., R. L. Harris, and S. Robinson. 2002.
{it:A Standard Computable General Equilibrium (CGE) Model in GAMS}. Microcomputers in Policy Research 5.
Washington, DC: International Food Policy Research Institute.{p_end}
{phang}Lofgren, H., M. Cicowiez, and C. Diaz-Bonilla. 2013. MAMS: A computable general equilibrium model for
developing country strategy analysis. In {it:Handbook of Computable General Equilibrium Modeling}, vol. 1A,
ed. P. B. Dixon and D. W. Jorgenson, 159{c -}276. Amsterdam: North-Holland.{p_end}
{phang}Mathiesen, L. 1985. Computation of economic equilibria by a sequence of linear complementarity
problems. {it:Mathematical Programming Study} 23: 144{c -}162.{p_end}
{phang}Newey, W. K., and K. D. West. 1987. A simple, positive semi-definite, heteroskedasticity and
autocorrelation consistent covariance matrix. {it:Econometrica} 55: 703{c -}708.{p_end}
{phang}Pesaran, M. H. 2006. Estimation and inference in large heterogeneous panels with a multifactor error
structure. {it:Econometrica} 74: 967{c -}1012.{p_end}
{phang}Pesaran, M. H. 2015. Testing weak cross-sectional dependence in large panels. {it:Econometric Reviews}
34: 1089{c -}1117.{p_end}
{phang}Ramsey, J. B. 1969. Tests for specification errors in classical linear least-squares regression
analysis. {it:Journal of the Royal Statistical Society, Series B} 31: 350{c -}371.{p_end}
{phang}Robinson, S., A. Cattaneo, and M. El-Said. 2001. Updating and estimating a social accounting matrix
using cross entropy methods. {it:Economic Systems Research} 13: 47{c -}64.{p_end}
{phang}Shoven, J. B., and J. Whalley. 1992. {it:Applying General Equilibrium}. Cambridge: Cambridge University
Press.{p_end}
{phang}Wooldridge, J. M. 2002. {it:Econometric Analysis of Cross Section and Panel Data}. Cambridge, MA: MIT
Press.{p_end}


{title:Citation}

{pstd}Yusuf, Y. T., and A. A. Kilishi. 2026. {cmd:cgemod}: Stata module for computable general equilibrium
modelling,
SAM balancing, microsimulation and scenario analysis. Version 2.0.0.{p_end}


{title:Authors}

{pstd}Yusuf Toyin Yusuf{p_end}
{pstd}Department of Economics and Development Studies, Kwara State University, Malete, Nigeria{p_end}
{pstd}{browse "mailto:ytoyinyusuf@gmail.com":ytoyinyusuf@gmail.com}{p_end}

{pstd}A. A. Kilishi{p_end}
{pstd}Department of Economics, Faculty of Social Sciences, University of Ilorin, Ilorin, Nigeria{p_end}
{pstd}{browse "mailto:meetkilishi@yahoo.com":meetkilishi@yahoo.com}{p_end}
